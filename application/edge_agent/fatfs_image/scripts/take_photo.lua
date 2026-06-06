local board_manager = require("board_manager")
local camera        = require("camera")
local image         = require("image")
local storage       = require("storage")

local TAG    = "[take_photo]"
local WIDTH  = 160   -- QQVGA — liten JPEG = färre tokens för inspect_image
local HEIGHT = 120
local OUT    = storage.join_path(storage.get_root_dir(), "inbox/sigge_view.jpg")

local camera_started = false
local function cleanup()
  if camera_started then pcall(camera.close); camera_started = false end
end

local paths, err = board_manager.get_camera_paths()
if not paths then
  print(TAG .. " ERROR get_camera_paths: " .. tostring(err))
  return "camera paths failed"
end

local ok, e = pcall(camera.open, paths.dev_path, {
  format = {"JPEG", "YUYV", "RGBP"},
  width = WIDTH, height = HEIGHT, nearest = true,
})
if not ok then
  print(TAG .. " ERROR camera.open: " .. tostring(e))
  return "camera open failed"
end
camera_started = true

local run_ok, run_err = xpcall(function()
  local frame <close> = camera.get_frame(3000)
  local jpeg  <close> = image.convert(frame, image.JPEG)
  image.save_file(OUT, jpeg)
  local info = frame:info()
  print(string.format("%s %dx%d saved to %s", TAG, info.width, info.height, OUT))
end, debug.traceback)

cleanup()
if not run_ok then error(run_err) end
return OUT
