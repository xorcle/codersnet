local internet = require("internet")
local shell = require("shell")

local updater = {
  DEBUG = false;
}
function updater:log(...)
  if self.DEBUG then print(...) end
end

function updater:flush(resource)
  repeat table.remove(resource, 1) until #resource == 0
end

function updater:sync(resource, url)
  resource.url = url

  local success, source = pcall(internet.request, resource.url, {t=os.time()})
  if not success then return nil end

  for html in source do
    if resource:search(html) then
      return true
    end
  end

  return false
end

function updater:run(path)
  updater:log("Directory set to: " .. path)
  for n, file in ipairs(Pastebin) do
    print("["..n.."]: " .. file.path)
  end
end;

--[[ -- Repositories ------------------------------------------------------- ]]
local pastebin = {
  url = '';
  buffer = '';
  source_url = "https://pastebin.com/raw/";
}

function pastebin:search(chunk)
  local head, head_end = string.find(self.buffer, '<table class="maintable">', 0, true)
  local tail, tail_end = string.find(self.buffer, '</table>', head_end, true)
  if not head or not tail then
    self.buffer = self.buffer .. string.gsub(chunk, "\t", "")
    return false
  end
  self.buffer = string.sub(self.buffer, head_end, tail)

  updater:log("Indexing " .. self.url)
  for line in string.gmatch(self.buffer, '[^\r\n]+') do
    for id, name in string.gmatch(line, '[%.]*<a href="/(%w+)">(%g+)</a>[%.]*') do
      updater:log(" ▪ [" .. id .. "]: " .. name)
      table.insert(self, {
        id=id;
        url=self.source_url..id;
        path=name;
      })
    end
  end

  self.buffer = ""
  return true
end

--[[ -- Command-Line Interface --------------------------------------------- ]]
local args, options = shell.parse(...)
updater.DEBUG = true
if updater:sync(pastebin, args[1] or "https://pastebin.com/u/throwawayrobot") then
  updater:run(args[2] or '.')
end
