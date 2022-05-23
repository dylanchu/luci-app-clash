---@diagnostic disable: lowercase-global
-- core
CORE_CLASH = "/tmp/clash_core"
CORE_CLASH_TUN = "/etc/clash/clashtun/clash_core"
CORE_CLASH_DTUN = "/etc/clash/dtun/clash_core"

CORE_DOWNLOADED_FLAG = "/tmp/clash_flag_core_down_complete"

-- log
LOG_FILE = "/tmp/clash_log.txt"
REAL_LOG = "/tmp/clash_real_log.txt"

CORE_NAMES = {
	"Vernesong clash core - clash",
	"Dreamacro clash core - clash",
	"Frainzy1477 clashr core - clash",
	"comzyh clash tun core - clash(ctun)",
	"Dreamacro clash tun core - clash(premium)",
}
CORE_DOWNLOAD_URLS = {
	"https://github.com/vernesong/OpenClash/releases/tag/Clash",
	"https://github.com/Dreamacro/clash/releases/latest",
	"https://github.com/frainzy1477/clash_dev/releases/latest",
	"https://github.com/comzyh/clash/releases/latest",
	"https://github.com/Dreamacro/clash/releases/tag/premium",
}

-- geoip
GEOIP_FILE = "/etc/clash/Country.mmdb"
GEOIP_GH_REPO_RELEASE_URL = "https://github.com/Dreamacro/maxmind-geoip/releases"
GEOIP_DOWNLOAD_URL = "https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/Country.mmdb"


font_red   = [[<font color="red">]]
font_green = [[<font color="green">]]
font_blue  = [[<font color="blue">]]
font_off   = [[</font>]]
bold_on    = [[<strong>]]
bold_off   = [[</strong>]]
