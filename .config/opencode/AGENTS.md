# Global Agent Rules

## SearXNG Search

If `searxng` searches fail with connection errors, start the containers:

```bash
cd ~/searxng-local && podman-compose up -d
```

## Shell Commands

Use `fd` instead of `find` for file searches. On this system, `find` is aliased to `fd`.
