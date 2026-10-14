#!/usr/bin/env node
// Agent-neutral port of ~/.config/opencode/tools/image_generation.ts and the Codex
// foundry-imagegen skill. Dependency-free stdio MCP server exposing one tool,
// `image_generation`, backed by the Azure Foundry gpt-image deployment and
// authenticated with the active `az login` session. Any MCP-capable agent
// (Claude Code, Codex, OpenCode) can register it.
//
// Configuration (set in each agent's MCP server env, which stays out of the dotfiles repo):
//   IMAGE_OUTPUT_DIR         Default output dir, relative to the project (default: .generated-images)
//   AZURE_IMAGE_BASE_URL     Foundry endpoint, e.g. https://<resource>.services.ai.azure.com/openai/v1 (required)
//   AZURE_IMAGE_DEPLOYMENT   Image deployment (default: gpt-image-2-1)
//   AZURE_IMAGE_API_VERSION  API version (default: 2025-04-01-preview)
//   AZURE_IMAGE_TENANT       Tenant passed to `az account get-access-token`

import { execFile } from "node:child_process"
import fs from "node:fs/promises"
import os from "node:os"
import path from "node:path"
import readline from "node:readline"
import { promisify } from "node:util"

const run = promisify(execFile)

const BASE_URL = process.env.AZURE_IMAGE_BASE_URL?.replace(/\/+$/, "")
const DEPLOYMENT = process.env.AZURE_IMAGE_DEPLOYMENT || "gpt-image-2-1"
const API_VERSION = process.env.AZURE_IMAGE_API_VERSION || "2025-04-01-preview"
const TENANT = process.env.AZURE_IMAGE_TENANT
const OUTPUT_DIR = process.env.IMAGE_OUTPUT_DIR || ".generated-images"
const TOKEN_RESOURCE = "https://cognitiveservices.azure.com"
// Inline previews above this size are downscaled with sips so the tool result stays small.
const PREVIEW_MAX_BYTES = 1_000_000
const PREVIEW_MAX_EDGE = 1024

const TOOL = {
  name: "image_generation",
  description:
    "Generate or edit images with the Azure Foundry gpt-image-2-1 deployment (az login auth). If imagePath is provided, the tool edits that image; otherwise it generates a new image. Optional referenceImagePaths are sent with imagePath as multipart image[] inputs for logos/style/product references. Defaults to PNG output. The generated image is returned inline (downscaled preview for large files) so you can see it directly, and the saved file path is included for reading or further edits. Relative paths resolve against the current project directory.",
  inputSchema: {
    type: "object",
    properties: {
      prompt: { type: "string", minLength: 1, description: "Prompt describing the image to create or the edit to apply." },
      imagePath: { type: "string", description: "Existing PNG/JPG image path to edit. Omit this to generate a new image." },
      referenceImagePaths: {
        type: "array",
        items: { type: "string", minLength: 1 },
        description:
          "Optional PNG/JPG reference images for edit mode, such as logos or style references. Use an array even for one reference. Requires imagePath.",
      },
      maskPath: { type: "string", description: "Optional PNG mask path for edits. The mask applies to imagePath." },
      outputPath: {
        type: "string",
        description: `Output file path. Defaults to ${OUTPUT_DIR}/azure-image-<timestamp>.<format>. For n > 1, -1, -2, etc. is appended.`,
      },
      size: { type: "string", default: "1024x1024", description: "Requested image size, for example 1024x1024 or GPT-Image-2 multiples-of-16 sizes." },
      quality: { type: "string", enum: ["low", "medium", "high"], default: "high", description: "Generation quality." },
      n: { type: "integer", minimum: 1, maximum: 10, default: 1, description: "Number of images to create." },
      format: { type: "string", enum: ["png", "jpeg"], default: "png", description: "Output image format. Prefer png unless JPEG is specifically needed." },
      transparentBackground: { type: "boolean", default: false, description: "Request a transparent background. Only applies to PNG." },
      jpegCompression: { type: "integer", minimum: 0, maximum: 100, description: "JPEG-only compression level, 0-100. Ignored unless format is jpeg." },
      inputFidelity: { type: "string", enum: ["low", "high"], default: "high", description: "Edit fidelity for preserving imagePath features. Ignored when imagePath is omitted." },
    },
    required: ["prompt"],
    additionalProperties: false,
  },
}

function parseArgs(input) {
  const args = { size: "1024x1024", quality: "high", n: 1, format: "png", transparentBackground: false, inputFidelity: "high", ...input }
  const oneOf = (key, values) => {
    if (!values.includes(args[key])) throw new Error(`${key} must be one of ${values.join(", ")}`)
  }
  if (typeof args.prompt !== "string" || !args.prompt.trim()) throw new Error("prompt is required")
  oneOf("quality", ["low", "medium", "high"])
  oneOf("format", ["png", "jpeg"])
  oneOf("inputFidelity", ["low", "high"])
  if (!Number.isInteger(args.n) || args.n < 1 || args.n > 10) throw new Error("n must be an integer from 1 to 10")
  if (args.jpegCompression !== undefined && (!Number.isInteger(args.jpegCompression) || args.jpegCompression < 0 || args.jpegCompression > 100)) {
    throw new Error("jpegCompression must be an integer from 0 to 100")
  }
  args.imagePath = args.imagePath?.trim() || undefined
  args.maskPath = args.maskPath?.trim() || undefined
  args.referenceImagePaths = (args.referenceImagePaths ?? []).map((item) => String(item).trim()).filter(Boolean)
  if (args.referenceImagePaths.length && !args.imagePath) {
    throw new Error("referenceImagePaths require imagePath because reference images are only supported for edits")
  }
  if (args.maskPath && !args.imagePath) throw new Error("maskPath requires imagePath")
  if (args.transparentBackground && args.format !== "png") throw new Error("transparentBackground requires format=png")
  return args
}

async function accessToken() {
  const tenant = TENANT ? ["--tenant", TENANT] : []
  try {
    const { stdout } = await run(
      "az",
      ["account", "get-access-token", ...tenant, "--resource", TOKEN_RESOURCE, "--query", "accessToken", "--output", "tsv"],
      { maxBuffer: 10 * 1024 * 1024 },
    )
    const token = stdout.trim()
    if (!token) throw new Error("empty token")
    return token
  } catch (error) {
    throw new Error(`Azure CLI token acquisition failed; run az login. (${error.stderr?.trim() || error.message})`)
  }
}

function usesDeploymentEndpoint(api) {
  return api.includes(".openai.azure.com") || api.includes(".services.ai.azure.com") || !api.endsWith("/v1")
}

function endpoint(api, action) {
  if (!usesDeploymentEndpoint(api)) return `${api}/images/${action}`
  const root = api.replace(/\/openai(?:\/v1)?$/i, "")
  return `${root}/openai/deployments/${encodeURIComponent(DEPLOYMENT)}/images/${action}?api-version=${encodeURIComponent(API_VERSION)}`
}

function resolvePath(file, directory) {
  const expanded = file.startsWith("~/") ? path.join(os.homedir(), file.slice(2)) : file
  return path.resolve(directory, expanded)
}

async function imageFile(filePath, directory) {
  const absolute = resolvePath(filePath, directory)
  const ext = path.extname(absolute).toLowerCase()
  const type = ext === ".jpg" || ext === ".jpeg" ? "image/jpeg" : ext === ".png" ? "image/png" : undefined
  if (!type) throw new Error(`Unsupported input image format for ${filePath}; use PNG or JPEG`)
  return new File([await fs.readFile(absolute)], path.basename(absolute), { type })
}

function outputPaths(outputPath, count, format, directory) {
  const target = outputPath
    ? resolvePath(outputPath, directory)
    : path.join(resolvePath(OUTPUT_DIR, directory), `azure-image-${new Date().toISOString().replace(/[:.]/g, "-")}.${format}`)
  const parsed = path.parse(target)
  return Array.from({ length: count }, (_, index) =>
    count === 1 ? target : path.join(parsed.dir, `${parsed.name}-${index + 1}${parsed.ext || `.${format}`}`),
  )
}

async function parseResponse(response) {
  const text = await response.text()
  let body = {}
  if (text) {
    try {
      body = JSON.parse(text)
    } catch {
      body = { message: text }
    }
  }
  if (response.ok) return body
  const message = body?.error?.message ?? body?.message ?? text
  throw new Error(`Azure image request failed (${response.status} ${response.statusText}): ${message}`)
}

async function saveImages(data, outputPath, format, directory) {
  const images = data?.data ?? []
  if (images.length === 0) throw new Error("Azure image response did not include any image data")
  const files = outputPaths(outputPath, images.length, format, directory)
  await Promise.all(
    images.map(async (image, index) => {
      if (!image.b64_json) throw new Error(`Azure image response item ${index + 1} did not include b64_json`)
      await fs.mkdir(path.dirname(files[index]), { recursive: true })
      await fs.writeFile(files[index], Buffer.from(image.b64_json, "base64"))
    }),
  )
  return files
}

async function preview(file, format) {
  const original = await fs.readFile(file)
  const mimeType = format === "jpeg" ? "image/jpeg" : "image/png"
  if (original.length <= PREVIEW_MAX_BYTES || process.platform !== "darwin") {
    return { type: "image", mimeType, data: original.toString("base64") }
  }
  const tmp = path.join(os.tmpdir(), `image-generation-preview-${process.pid}-${Date.now()}.jpg`)
  try {
    await run("sips", ["-Z", String(PREVIEW_MAX_EDGE), "-s", "format", "jpeg", "-s", "formatOptions", "85", file, "--out", tmp])
    return { type: "image", mimeType: "image/jpeg", data: (await fs.readFile(tmp)).toString("base64") }
  } catch {
    return { type: "image", mimeType, data: original.toString("base64") }
  } finally {
    await fs.rm(tmp, { force: true })
  }
}

function resultText(files, directory, args, mode) {
  const list = files
    .map((file) => {
      const relative = path.relative(directory, file)
      return relative.startsWith("..") || path.isAbsolute(relative) ? `- ${file}` : `- ${file} (${relative})`
    })
    .join("\n")
  return [
    `Saved ${files.length} image${files.length === 1 ? "" : "s"}:`,
    list,
    ...(mode === "edit"
      ? [
          "",
          `Primary edit image: ${args.imagePath}`,
          `Reference image inputs: ${args.referenceImagePaths.length ? args.referenceImagePaths.join(", ") : "none"}`,
        ]
      : []),
    "",
    `Mode: ${mode} | Deployment: ${DEPLOYMENT} | Size: ${args.size} | Quality: ${args.quality}`,
    `The generated image${files.length === 1 ? " is" : "s are"} attached to this tool result and visible to you directly. The path${files.length === 1 ? "" : "s"} above can be used with the Read tool or for further edits.`,
  ].join("\n")
}

async function generate(input, signal) {
  const args = parseArgs(input)
  if (!BASE_URL) throw new Error("AZURE_IMAGE_BASE_URL is not set in this MCP server's environment")
  const directory = process.cwd()
  const mode = args.imagePath ? "edit" : "generate"
  const headers = { authorization: `Bearer ${await accessToken()}` }

  const body = {
    ...(usesDeploymentEndpoint(BASE_URL) ? {} : { model: DEPLOYMENT }),
    prompt: args.prompt,
    n: args.n,
    size: args.size,
    quality: args.quality,
    output_format: args.format,
    background: args.transparentBackground ? "transparent" : "auto",
    ...(args.format === "jpeg" && args.jpegCompression !== undefined ? { output_compression: args.jpegCompression } : {}),
  }

  let response
  if (mode === "generate") {
    response = await fetch(endpoint(BASE_URL, "generations"), {
      method: "POST",
      headers: { ...headers, "content-type": "application/json" },
      body: JSON.stringify(body),
      signal,
    })
  } else {
    const form = new FormData()
    for (const [key, value] of Object.entries({ ...body, input_fidelity: args.inputFidelity })) form.append(key, String(value))
    if (args.referenceImagePaths.length) {
      form.append("image[]", await imageFile(args.imagePath, directory))
      for (const reference of args.referenceImagePaths) form.append("image[]", await imageFile(reference, directory))
    } else {
      form.append("image", await imageFile(args.imagePath, directory))
    }
    if (args.maskPath) form.append("mask", await imageFile(args.maskPath, directory))
    response = await fetch(endpoint(BASE_URL, "edits"), { method: "POST", headers, body: form, signal })
  }

  const files = await saveImages(await parseResponse(response), args.outputPath, args.format, directory)
  return {
    content: [
      { type: "text", text: resultText(files, directory, args, mode) },
      ...(await Promise.all(files.map((file) => preview(file, args.format)))),
    ],
  }
}

// Minimal MCP stdio transport: newline-delimited JSON-RPC 2.0.
const inflight = new Map()
process.stdout.on("error", () => process.exit(0))

function send(message) {
  process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", ...message })}\n`)
}

async function handle(message) {
  const { id, method, params } = message
  if (method === "notifications/cancelled") {
    inflight.get(params?.requestId)?.abort()
    return
  }
  if (id === undefined) return
  try {
    if (method === "initialize") {
      return send({
        id,
        result: {
          protocolVersion: params?.protocolVersion ?? "2025-06-18",
          capabilities: { tools: {} },
          serverInfo: { name: "image-generation", version: "1.0.0" },
        },
      })
    }
    if (method === "ping") return send({ id, result: {} })
    if (method === "tools/list") return send({ id, result: { tools: [TOOL] } })
    if (method === "tools/call") {
      if (params?.name !== TOOL.name) return send({ id, error: { code: -32602, message: `Unknown tool: ${params?.name}` } })
      const controller = new AbortController()
      inflight.set(id, controller)
      try {
        return send({ id, result: await generate(params.arguments ?? {}, controller.signal) })
      } catch (error) {
        return send({ id, result: { isError: true, content: [{ type: "text", text: `Error: ${error?.message ?? error}` }] } })
      } finally {
        inflight.delete(id)
      }
    }
    send({ id, error: { code: -32601, message: `Method not found: ${method}` } })
  } catch (error) {
    send({ id, error: { code: -32603, message: String(error?.message ?? error) } })
  }
}

readline.createInterface({ input: process.stdin }).on("line", (line) => {
  if (!line.trim()) return
  let message
  try {
    message = JSON.parse(line)
  } catch {
    return send({ id: null, error: { code: -32700, message: "Parse error" } })
  }
  handle(message)
})
