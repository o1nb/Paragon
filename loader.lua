local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function httpGet(url)
	local suc, res = pcall(function()
		if request then
			local r = request({Url = url, Method = 'GET'})
			return r and r.StatusCode == 200 and r.Body or nil
		end
		return game:HttpGet(url, true)
	end)
	return suc and res or nil
end

local function downloadFile(path, func)
	if not isfile(path) then
		local res = httpGet('https://raw.githubusercontent.com/o1nb/Paragon/'..readfile('Paragonv4/profiles/commit.txt')..'/'..select(1, path:gsub('Paragonv4/', '')))
		if not res or res == '404: Not Found' then
			error('Failed to download: '..path)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'Paragonv4', 'Paragonv4/games', 'Paragonv4/profiles', 'Paragonv4/assets', 'Paragonv4/libraries', 'Paragonv4/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local subbed = httpGet('https://github.com/o1nb/Paragon')
	local commit = subbed and subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('Paragonv4/profiles/commit.txt') and readfile('Paragonv4/profiles/commit.txt') or '') ~= commit then
		wipeFolder('Paragonv4')
		wipeFolder('Paragonv4/games')
		wipeFolder('Paragonv4/guis')
		wipeFolder('Paragonv4/libraries')
	end
	writefile('Paragonv4/profiles/commit.txt', commit)
end

return loadstring(downloadFile('Paragonv4/main.lua'), 'main')()
