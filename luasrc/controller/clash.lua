module("luci.controller.clash", package.seeall)
local fs = require "nixio.fs"
local http = require "luci.http"
local uci = require "luci.model.uci".cursor()

dofile "/usr/share/clash/init_env_conf.lua"


function index()

	if not nixio.fs.access("/etc/config/clash") then
		return
	end

	local page = entry({ "admin", "services", "clash" }, alias("admin", "services", "clash", "overview"), _("Clash"), 1)
	page.dependent = true
	page.acl_depends = { "luci-app-clash" }

	entry({ "admin", "services", "clash", "overview" }, cbi("clash/overview"), _("Overview"), 10).leaf = true
	entry({ "admin", "services", "clash", "client" }, cbi("clash/client/client"), _("Client"), 20).leaf = true

	entry({ "admin", "services", "clash", "config" }, firstchild(), _("Config"), 25)
	entry({ "admin", "services", "clash", "config", "import" }, cbi("clash/config/import"), _("Import Config"), 25).leaf = true
	entry({ "admin", "services", "clash", "config", "config" }, cbi("clash/config/config"), _("Select Config"), 30).leaf = true

	entry({ "admin", "services", "clash", "config", "create" }, cbi("clash/config/create"), _("Create Config"), 35).leaf = true
	entry({ "admin", "services", "clash", "proxyprovider" }, cbi("clash/config/proxy_provider"), nil).leaf = true
	entry({ "admin", "services", "clash", "servers" }, cbi("clash/config/servers-config"), nil).leaf = true
	entry({ "admin", "services", "clash", "ruleprovider" }, cbi("clash/config/rule_provider"), nil).leaf = true
	entry({ "admin", "services", "clash", "rules" }, cbi("clash/config/rules"), nil).leaf = true
	entry({ "admin", "services", "clash", "pgroups" }, cbi("clash/config/groups"), nil).leaf = true
	entry({ "admin", "services", "clash", "rulemanager" }, cbi("clash/config/ruleprovider_manager"), nil).leaf = true

	entry({ "admin", "services", "clash", "settings" }, firstchild(), _("Settings"), 40)
	entry({ "admin", "services", "clash", "settings", "port" }, cbi("clash/dns/port"), _("Proxy Ports"), 60).leaf = true
	entry({ "admin", "services", "clash", "settings", "geoip" }, cbi("clash/geoip/geoip"), _("Update GeoIP"), 80).leaf = true
	entry({ "admin", "services", "clash", "settings", "grules" }, cbi("clash/game/game-settings"), _("Game Rules"), 91).dependent = false
	entry({ "admin", "services", "clash", "g-rules" }, cbi("clash/game/game-rule"), nil).leaf = true
	entry({ "admin", "services", "clash", "settings", "other" }, cbi("clash/other"), _("Other Settings"), 92).leaf = true
	entry({ "admin", "services", "clash", "ip-rules" }, cbi("clash/config/ip-rules"), nil).leaf = true
	entry({ "admin", "services", "clash", "settings", "dns" }, firstchild(), _("DNS Settings"), 65)
	entry({ "admin", "services", "clash", "settings", "dns", "dns" }, cbi("clash/dns/dns"), _("Clash DNS"), 70).leaf = true
	entry({ "admin", "services", "clash", "settings", "dns", "advance" }, cbi("clash/dns/advance"), _("Advance DNS"), 75).leaf = true

	entry({ "admin", "services", "clash", "update" }, cbi("clash/update/update"), _("Update"), 45).leaf = true
	entry({ "admin", "services", "clash", "log" }, cbi("clash/logs/log"), _("Log"), 50).leaf = true

	entry({ "admin", "services", "clash", "check_status" }, call("check_status")).leaf = true
	entry({ "admin", "services", "clash", "ping" }, call("act_ping")).leaf = true
	entry({ "admin", "services", "clash", "readlog" }, call("action_read")).leaf = true
	entry({ "admin", "services", "clash", "status" }, call("action_status")).leaf = true
	entry({ "admin", "services", "clash", "check_update_log" }, call("check_update_log")).leaf = true
	entry({ "admin", "services", "clash", "dlnupdate" }, call("dl_n_update")).leaf = true
	entry({ "admin", "services", "clash", "start" }, call("do_start")).leaf = true
	entry({ "admin", "services", "clash", "stop" }, call("do_stop")).leaf = true
	entry({ "admin", "services", "clash", "reload" }, call("do_reload")).leaf = true
	entry({ "admin", "services", "clash", "geo" }, call("geoip_check")).leaf = true
	entry({ "admin", "services", "clash", "geoipupdate" }, call("geoip_update")).leaf = true
	entry({ "admin", "services", "clash", "check_geoip" }, call("check_geoip_log")).leaf = true
	entry({ "admin", "services", "clash", "core_dl_check" }, call("check_core_update")).leaf = true
	entry({ "admin", "services", "clash", "logstatus" }, call("logstatus_check")).leaf = true
	entry({ "admin", "services", "clash", "conf" }, call("action_conf")).leaf = true
	entry({ "admin", "services", "clash", "update_config" }, call("action_update")).leaf = true
	entry({ "admin", "services", "clash", "game_rule" }, call("action_update_rule")).leaf = true
	entry({ "admin", "services", "clash", "ruleproviders" }, call("action_update_rule_providers")).leaf = true
	entry({ "admin", "services", "clash", "ping_check" }, call("action_ping_status")).leaf = true

end

local fss = require "luci.clash"

local function download_rule_provider()
	local filename = luci.http.formvalue("filename")
	local status = luci.sys.call(string.format('/usr/share/clash/create/clash_rule_provider.sh "%s" >/dev/null 2>&1', filename))
	return status
end

function action_update_rule_providers()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		rulep = download_rule_provider();
	})
end

local function uhttp_port()
	local uhttp_port = luci.sys.exec("uci get uhttpd.main.listen_http |awk -F ':' '{print $NF}'")
	if uhttp_port ~= "80" then
		return ":" .. uhttp_port
	end
end

local function download_rule()
	local filename = luci.http.formvalue("filename")
	local rule_file_dir = "/usr/share/clash/rules/g_rules/" .. filename
	luci.sys.call(string.format('sh /usr/share/clash/clash_game_rule.sh "%s" >/dev/null 2>&1', filename))
	if not fss.isfile(rule_file_dir) then
		return "0"
	else
		return "1"
	end
end

function action_update_rule()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		game_rule = download_rule()
	})
end

function action_update()
	local cmd_tpl = "kill $(pgrep /usr/share/clash/update.sh) ; (bash /usr/share/clash/update.sh >>%s 2>&1) &"
	luci.sys.exec(string.format(cmd_tpl, LOG_FILE))
end

local function in_use()
	return luci.sys.exec("uci get clash.config.config_type")
end

local function conf_path()
	if nixio.fs.access(string.sub(luci.sys.exec("uci get clash.config.use_config"), 1, -2)) then
		return fss.basename(string.sub(luci.sys.exec("uci get clash.config.use_config"), 1, -2))
	else
		return ""
	end
end

local function typeconf()
	return luci.sys.exec("uci get clash.config.config_type")
end

function action_conf()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		conf_path = conf_path(),
		typeconf = typeconf()

	})
end

local function dash_port()
	return luci.sys.exec("uci get clash.config.dash_port 2>/dev/null")
end

local function dash_pass()
	return luci.sys.exec("uci get clash.config.dash_pass 2>/dev/null")
end

local function is_running()
	return luci.sys.call("pidof clash_core >/dev/null") == 0
end

local function is_web()
	return luci.sys.call("pidof clash_core >/dev/null") == 0
end

local function localip()
	return luci.sys.exec("uci get network.lan.ipaddr")
end

-- region version begin
local function app_version()
	return luci.sys.exec("sed -n 1p /usr/share/clash/luci_version")
end

local function get_core_ver(core_path, name)
	if nixio.fs.access(core_path) then
		local ver = luci.sys.exec(core_path .. " -v 2>/dev/null |awk -F ' ' '{print $2}'")
		if ver ~= "" then
			return ver
		else
			local cmd_tpl = "grep -w %s %s | awk -F '=' '{print $2}' 2>/dev/null"
			return luci.sys.exec(string.format(cmd_tpl, name, CORE_VERSON_META_FILE))
		end
	else
		return "na"
	end
end

local function check_new_versions()
	return luci.sys.exec("sh /usr/share/clash/check_new_versions.sh")
end

local function get_new_ver(name)
	local cmd_tpl = "grep -w %s %s | awk -F '=' '{print $2}' 2>/dev/null"
	local ver = luci.sys.exec(string.format(cmd_tpl, name, NEW_VERSON_META_FILE))
	return ver or ""
end
-- region version end

local function e_mode()
	return luci.sys.exec("egrep '^ {0,}enhanced-mode' /etc/clash/config.yaml |grep enhanced-mode: |awk -F ': ' '{print $2}'")
end

local function readlog()
	local cmd_tpl = "sed -n '$p' %s 2>/dev/null"
	local ret = luci.sys.exec(string.format(cmd_tpl, REAL_LOG))
	return ret or ""
end

local function geo_date()
	return os.date("%Y-%m-%d %H:%M:%S", fss.mtime(GEOIP_FILE))
end

local function update_process_check()
	if nixio.fs.access("/var/run/core_update_error") then
		return "err"
	elseif nixio.fs.access("/var/run/core_update") then
		return "fin"
	elseif nixio.fs.access(CORE_DOWNLOADED_FLAG) then
		return "wip"
	end
end

function action_read()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		readlog = readlog();
	})
end

function check_core_update()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		dlcheck = update_process_check();
	})
end

local function geoipcheck()
	if nixio.fs.access("/var/run/geoip_update_error") then
		return "0"
	elseif nixio.fs.access("/var/run/geoip_update") then
		return "1"
	elseif nixio.fs.access("/var/run/geoip_down_complete") then
		return "2"
	end
end

function geoip_check()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		geoipcheck = geoipcheck();
	})
end

function check_status()
	check_new_versions()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		current_version = app_version(),
		clash_core = get_core_ver(CORE_CLASH, "core"),
		clashtun_core = get_core_ver(CORE_CLASH_TUN, "core_tun"),
		dtun_core = get_core_ver(CORE_CLASH_DTUN, "core_dtun"),
		new_version = get_new_ver("app"),
		new_core_ver = get_new_ver("core"),
		new_tun_core_ver = get_new_ver("core_tun"),
		new_dtun_core = get_new_ver("core_dtun"),
		conf_path = conf_path(),
		typeconf = typeconf()
	})
end

function action_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		web = is_web(),
		clash = is_running(),
		localip = localip(),
		dash_port = dash_port(),
		current_version = app_version(),
		new_version = get_new_ver("app"),
		new_core_ver = get_new_ver("core"),
		new_tun_core_ver = get_new_ver("core_tun"),
		new_dtun_core = get_new_ver("core_dtun"),
		clash_core = get_core_ver(CORE_CLASH, "core"),
		dtun_core = get_core_ver(CORE_CLASH_DTUN, "core_dtun"),
		dash_pass = dash_pass(),
		clashtun_core = get_core_ver(CORE_CLASH_TUN, "core_tun"),
		e_mode = e_mode(),
		in_use = in_use(),
		conf_path = conf_path(),
		uhttp_port = uhttp_port(),
		typeconf = typeconf()
	})
end

function action_ping_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		ping_enable = ping_enable()
	})
end

function act_ping()
	local e = {}
	e.index = luci.http.formvalue("index")
	e.ping = luci.sys.exec("ping -c 1 -W 1 -w 5 %q 2>&1 | grep -o 'time=[0-9]*.[0-9]' | awk -F '=' '{print$2}'" % luci.http.formvalue("domain"))
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function geoip_update()
	fs.writefile("/var/run/geoiplog", "0")
	luci.sys.exec("(rm /var/run/geoip_update_error ;  touch /var/run/geoip_update ; sh /usr/share/clash/geoip.sh >/tmp/geoip_update.txt 2>&1  || touch /var/run/geoip_update_error ;rm /var/run/geoip_update) &")
end

function dl_n_update()
	fs.writefile("/var/run/clashlog", "0")
	luci.sys.call("rm /var/run/core_update_error ;  touch /var/run/core_update")
	luci.sys.exec("(sh /usr/share/clash/core_download.sh dl_n_update >/tmp/clash_update.txt 2>&1  || touch /var/run/core_update_error ;rm /var/run/core_update) &")
end

function do_start()
	luci.sys.exec('uci set clash.config.enable="1" && uci commit clash')
	luci.sys.exec("/etc/init.d/clash restart 2>&1 &")
end

function do_stop()
	luci.sys.exec('uci set clash.config.enable="0" && uci commit clash')
	luci.sys.exec("/etc/init.d/clash stop 2>&1 &")
end

function do_reload()
	if luci.sys.call("pidof clash_core >/dev/null") == 0 then
		luci.sys.exec("/etc/init.d/clash reload 2>&1 &")
	end
end

function check_update_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp = tonumber(fs.readfile("/var/run/clashlog")) or 0
	local a = ""
	local f = io.open("/tmp/clash_update.txt", "r+")
	if f then
		f:seek("set", fdp)
		a = f:read(2048000) or ""
		fdp = f:seek()
		fs.writefile("/var/run/clashlog", tostring(fdp))
		f:close()
	end
	if fs.access("/var/run/core_update") then
		luci.http.write(a)
	else
		luci.http.write(a .. "\0")
	end
end

function check_geoip_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp = tonumber(fs.readfile("/var/run/geoiplog")) or 0
	local a = ""
	local f = io.open("/tmp/geoip_update.txt", "r+")
	if f then
		f:seek("set", fdp)
		a = f:read(2048000) or ""
		fdp = f:seek()
		fs.writefile("/var/run/geoiplog", tostring(fdp))
		f:close()
	end
	if fs.access("/var/run/geoip_update") then
		luci.http.write(a)
	else
		luci.http.write(a .. "\0")
	end
end

function logstatus_check()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local fdp = tonumber(fs.readfile("/usr/share/clash/logstatus_check")) or 0
	local a = ""
	local f = io.open(LOG_FILE, "r+")
	if f then
		f:seek("set", fdp)
		a = f:read(2048000) or ""
		fdp = f:seek()
		fs.writefile("/usr/share/clash/logstatus_check", tostring(fdp))
		f:close()
	end
	if fs.access("/var/run/logstatus") then
		luci.http.write(a)
	else
		luci.http.write(a .. "\0")
	end
end
