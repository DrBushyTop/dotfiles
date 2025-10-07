-- debug-moon.lua

local inspect = require("hs.inspect")

-- 1) List all attached USB devices and their IDs
print("=== USB Devices ===")
for i, dev in ipairs(hs.usb.attachedDevices()) do
    print(string.format("%d) %s — VendorID: %d, ProductID: %d",
        i, dev.productName, dev.vendorID, dev.productID))
end
-- :contentReference[oaicite:0]{index=0}

-- 2) Watch *all* keyDown events and dump their raw data + keyCode
hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
    local raw = e:getRawEventData()    -- low-level HID info :contentReference[oaicite:1]{index=1}
    print("–– keyDown Event ––")
    print(" keyCode:", e:getKeyCode())
    print(" flags  :", inspect(e:getFlags()))
    print(" raw    :", inspect(raw.CGEventData or raw))

    -- (on some versions it’s raw.CGEventData.flags etc.)
    return false  -- allow the event through
end):start()
