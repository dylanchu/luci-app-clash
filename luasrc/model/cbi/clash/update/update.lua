local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local uci  = require("luci.model.uci").cursor()
local http = luci.http
local m, r, k

dofile "/usr/share/clash/init_env_conf.lua"


ko = Map("clash")
ko.reset = false
ko.submit = false
sul = ko:section(TypedSection, "clash", translate("Manual Upload"))
sul.anonymous = true
sul.addremove = false
o = sul:option(FileUpload, "")

local tmp_str = '' .. bold_on .. translate("Manually download clash core from links below then unzip and upload") .. bold_off .. ' '
for idx, v in ipairs(CORE_NAMES) do
	tmp_str = tmp_str .. "<br />" .. translatef("<a href=\"%s\" target=\"_blank\">%s</a>", translate(CORE_DOWNLOAD_URLS[idx]), v)
end
o.description = tmp_str


o.title = translate("  ")
o.template = "clash/upload_core"
um = sul:option(DummyValue, "", nil)
um.template = "clash/clash_dvalue"

local fd, cssr

http.setfilehandler(
	function(meta, chunk, eof)
		local fp = HTTP.formvalue("file_type")
		if not fd then
			if not meta then return end

			if fp == "clash" then
				if meta and chunk then fd = nixio.open(CORE_CLASH, "w") end
			elseif fp == "clashctun" then
				if meta and chunk then fd = nixio.open(CORE_CLASH_TUN, "w") end
			elseif fp == "clashdtun" then
				if meta and chunk then fd = nixio.open(CORE_CLASH_DTUN, "w") end
			end

			if not fd then
				um.value = translate("upload file error.")
				return
			end
		end
		if chunk and fd then
			fd:write(chunk)
		end
		if eof and fd then
			fd:close()
			fd = nil

			local chmod_tpl = "chmod 755 %s 2>&1 &"
			local cmd_version_tpl = "sh /usr/share/clash/core_download.sh update_version %s %s"
			local l_str_saved = translate("File saved to")
			if fp == "clash" then
				SYS.exec(string.format(chmod_tpl, CORE_CLASH))
				SYS.exec(string.format(cmd_version_tpl, CORE_CLASH, "core"))
				um.value = l_str_saved .. ': ' .. CORE_CLASH
			elseif fp == "clashctun" then
				SYS.exec(string.format(chmod_tpl, CORE_CLASH_TUN))
				SYS.exec(string.format(cmd_version_tpl, CORE_CLASH_TUN, "core_tun"))
				um.value = l_str_saved .. ': ' .. CORE_CLASH_TUN
			elseif fp == "clashdtun" then
				SYS.exec(string.format(chmod_tpl, CORE_CLASH_DTUN))
				SYS.exec(string.format(cmd_version_tpl, CORE_CLASH_DTUN, "core_dtun"))
				um.value = l_str_saved .. ': ' .. CORE_CLASH_DTUN
			end

		end
	end
)

if luci.http.formvalue("upload") then
	local f = luci.http.formvalue("ulfile")
	if #f <= 0 then
		um.value = translate("No specify upload file.")
	end
end


m = Map("clash")
m:section(SimpleSection).template = "clash/update"
m.pageaction = false

k = Map("clash")
s = k:section(TypedSection, "clash", translate("Download Online"))
s.anonymous = true

o = s:option(Value, "url_dcore")
o.title = translate("Download Url")
o.description = translate('Only support ".tar" file and original file inside package should be named to "clash_core".')
o.placeholder = translate("https://example.com/link/clash-core.tar")

o = s:option(ListValue, "dcore", translate("Core Type"))
o.default = "clashcore"
o:value("1", translate("clash"))
o:value("3", translate("clash(ctun)"))
o:value("4", translate("clash(premium)"))

o = s:option(Value, "dcore_comments")
o.title = translate("Comments")

-- local cpu_model = SYS.exec("opkg status libc 2>/dev/null |grep 'Architecture' |awk -F ': ' '{print $2}' 2>/dev/null")
-- o = s:option(ListValue, "download_core", translate("Select Core"))
-- o.description = translate("CPU Model") .. ': ' .. font_green .. bold_on .. cpu_model .. bold_off .. font_off .. ' '
-- o:value("linux-armv7")
-- o:value("linux-mipsle-softfloat")

o = s:option(Button, "down_core")
o.inputtitle = translate("Save")
o.title = luci.util.pcdata(translate("Save"))
o.inputstyle = "reload"
o.write = function()
	k.uci:commit("clash")
end

o = s:option(Button, "download")
o.title = translate("Download & Update")
o.template = "clash/core_check"


return m, ko, k
