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
*Please read the comments carefully for a description of each function, and toggle them (true/false) as needed.*
```
_G.SendNotifications = true
_G.ConsoleLogs = true

_G.Ignore = {
    workspace:WaitForChild("Map", 5)
}

_G.Settings = {
    Players = {
        ["Ignore Me"] = true,        -- false = GOD MODE: Tối ưu luôn cả bản thân 
        ["Ignore Others"] = true,    -- false = Tối ưu người chơi khác
        ["Ignore Tools"] = true      -- true = Giữ nguyên vũ khí/tool không bị xóa hoặc làm xấu
    },
    Meshes = {
        NoMesh = true,               -- true = Xóa ID lưới (SpecialMesh)
        NoTexture = true,            -- true = Xóa Texture của lưới
        Destroy = false              -- true = GOD MODE: Destroy hoàn toàn SpecialMesh/DataModelMesh
    },
    Images = {
        Invisible = true,            -- true = Làm trong suốt Decal/Texture/ShirtGraphic
        Destroy = false              -- true = GOD MODE: Destroy Decal/Texture/ShirtGraphic
    },
    Explosions = {
        Smaller = true,              -- true = Giảm áp lực & bán kính nổ
        Invisible = true,            -- true = Làm tàng hình vụ nổ
        Destroy = false              -- true = GOD MODE: Destroy Explosion
    },
    Particles = {
        Invisible = true,            -- true = Tắt ParticleEmitter, Trail, Smoke, Fire, Sparkles
        Destroy = false              -- true = GOD MODE: Destroy hoàn toàn các hiệu ứng hạt
    },
    TextLabels = {
        LowerQuality = true,         -- true = Hạ chất lượng font, tắt RichText/TextScaled
        Invisible = false,           -- true = Ẩn TextLabel trong Workspace
        Destroy = false              -- true = GOD MODE: Destroy TextLabel trong Workspace
    },
    MeshParts = {
        LowerQuality = true,         -- true = Giảm RenderFidelity về Performance
        Invisible = false,           -- true = Làm trong suốt MeshPart
        NoTexture = true,            -- true = Xóa TextureID của MeshPart
        NoMesh = false,              -- true = Ẩn lưới MeshPart
        Destroy = false              -- true = GOD MODE: Destroy MeshPart (cực mạnh, tối ưu FPS tối đa)
    },
    Other = {
        ["FPS Cap"] = 999,                  -- Mở khóa FPS (vd 999, 144, 240,.. nhưng nên đặt theo tần số quét màn hình nhé ae)
        ["No Camera Effects"] = true,       -- true = Tắt toàn bộ PostEffect (Bloom, Blur, SunRays...)
        ["No Clothes"] = false,             -- true = GOD MODE: Xóa sạch quần áo, phụ kiện, tóc, CharacterMesh, BodyColors
        ["Low Water Graphics"] = true,      -- true = Giảm tối đa đồ họa nước Terrain
        ["No Shadows"] = true,              -- true = Tắt bóng đổ toàn cầu (Global Shadows)
        ["Low Rendering"] = true,           -- true = Hạ QualityLevel & MeshPartDetailLevel xuống thấp nhất
        ["Low Quality Parts"] = true,       -- true = Đổi vật liệu Part thành SmoothPlastic & tắt phản chiếu
        ["Low Quality Models"] = true,      -- true = Đặt Model LevelOfDetail thành StreamingMesh
        ["Reset Materials"] = true,         -- true = Tắt 2022 Materials & xóa tùy chỉnh MaterialService
        ["Lower Quality MeshParts"] = true, -- true = Tối ưu chi tiết MeshPart
        ["Mute Sounds"] = false,            -- true = GOD MODE: Tắt toàn bộ âm thanh & ngăn phát nhạc/sound
        ["Optimize Lighting"] = false,      -- true = GOD MODE: Nuke lighting (xóa Sky, Atmosphere, Clouds, Light) & làm phẳng ánh sáng
        ClearNilInstances = true,           -- true = GOD MODE: Dọn dẹp các instance nil để giải phóng RAM
        AutoReapply = false,                -- true = Tự động quét lại định kỳ để tối ưu các object mới spawn
        AutoReapplyInterval = 15            -- Chu kỳ quét lại tự động (đơn vị tính bằng giây)
    }
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/boost.lua"))()
```
