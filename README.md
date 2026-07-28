# LOADER MENU (RECOMMEND):
```cmd
loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/loader.lua"))()
```
- or manually select the script below

---

## ESP Script:
```cmd
loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/ESP.lua"))()
```
---
## Music Player Script:
```cmd
loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/Music-Player.lua"))()
```
---
## sUNC Test Suite Script:
```cmd
loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/sUNC-TestSuite.lua"))()
```
---
## Aimbot Script:
```cmd
loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/Aimbot.lua"))()
```
---
## Speedhack & Super Jump:
```cmd
loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/SpeedAndJumpModifier.lua"))()
```
---
## Aura Script:
```cmd
loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/Aura.lua"))()
```
---
## Potato Graphics Fix lag
```cmd
_G.SendNotifications = true
_G.ConsoleLogs = true

_G.Ignore = {
    workspace:WaitForChild("Map") -- Không tối ưu Map
}

_G.Settings = {
    Players = {
        ["Ignore Me"] = true,       -- True = Không làm xấu/mất nhân vật của bản thân
        ["Ignore Others"] = false,  -- False = Tối ưu người chơi khác
        ["Ignore Tools"] = true
    },
    Meshes = { NoMesh = false, NoTexture = true, Destroy = false },
    Images = { Invisible = true, Destroy = false },
    Explosions = { Smaller = true, Invisible = false, Destroy = false },
    Particles = { Invisible = true, Destroy = true },
    TextLabels = { LowerQuality = true, Invisible = false, Destroy = false },
    MeshParts = { LowerQuality = true, Invisible = false, NoTexture = true, NoMesh = false, Destroy = false },
    Other = {
        ["FPS Cap"] = 999,          -- Mở khóa FPS
        ["No Camera Effects"] = true,
        ["No Clothes"] = false,      -- Để false nếu không muốn biến mọi người thành đầu trọc/trần truồng xD
        ["Low Water Graphics"] = true,
        ["No Shadows"] = true,
        ["Low Rendering"] = true,
        ["Low Quality Parts"] = true,
        ["Low Quality Models"] = true,
        ["Reset Materials"] = true,
        ["Lower Quality MeshParts"] = true,
        ["Mute Sounds"] = false,
        ["Optimize Lighting"] = true,
        ClearNilInstances = false
    }
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/boost.lua"))()
```
