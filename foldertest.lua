require 'nn'
require 'image'
require 'InstanceNormalization'
require 'src/utils'

local cmd = torch.CmdLine()

cmd:option('-input_image', '', 'Image to stylize.')
cmd:option('-image_size', 0, 'Resize input image to. Do not resize if 0.')
cmd:option('-model_t7', '', 'Path to trained model.')
cmd:option('-save_path', 'stylized.png', 'Path to save stylized image.')
cmd:option('-cpu', false, 'use this flag to run on CPU')
cmd:option('-input_dir', '')
cmd:option('-output_dir', '')

local params = cmd:parse(arg)

-- Load model and set type
local model = torch.load(params.model_t7)

if params.cpu then 
  tp = 'torch.FloatTensor'
else
  require 'cutorch'
  require 'cunn'
  require 'cudnn'

  tp = 'torch.CudaTensor'
  model = cudnn.convert(model, cudnn)
end

model:type(tp)
model:evaluate()



--function
local function run_image(in_path, out_path)


 local img = image.load(in_path, 3):float()
 if params.image_size > 0 then
  img = image.scale(img, params.image_size, params.image_size)
 end


-- Stylize
 if cutorch then cutorch.synchronize() end
local input = img:add_dummy()
local stylized = model:forward(input:type(tp)):double()
if cutorch then cutorch.synchronize() end
stylized = deprocess(stylized[1])
print('Writing output image to ' .. out_path)

-- Save
image.save(out_path, torch.clamp(stylized,0,1))

end


--image true or false
local IMAGE_EXTS = {'jpg', 'jpeg', 'png', 'ppm', 'pgm'}
function is_image_file(filename)
  -- Hidden file are not images
  if string.sub(filename, 1, 1) == '.' then
    return false
  end
  -- Check against a list of known image extensions
  local ext = string.lower(paths.extname(filename) or "")
  for _, image_ext in ipairs(IMAGE_EXTS) do
    if ext == image_ext then
      return true
    end
  end
  return false
end



--- Load image from dir

for fn in paths.files(params.input_dir) do

      if is_image_file(fn) then
      local in_path = paths.concat(params.input_dir, fn)
      local out_path = paths.concat(params.output_dir, fn)
      run_image(in_path, out_path)
  end
end