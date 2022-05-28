include $(TOPDIR)/rules.mk 

PKG_NAME:=luci-app-clash
PKG_VERSION:=v1.8.0.6
PKG_MAINTAINER:=dylanchu

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=2. Clash For OpenWRT
	TITLE:=LuCI app for clash
	DEPENDS:=+luci-base +wget +iptables +coreutils-base64 +coreutils +coreutils-nohup +bash +ipset +libustream-openssl +curl +jsonfilter +ca-certificates +iptables-mod-tproxy +kmod-tun
	PKGARCH:=all
	MAINTAINER:=dylanchu
endef

define Package/$(PKG_NAME)/description
	Luci Interface for clash with small ROM device support.
endef

define Build/Prepare
	po2lmo ${CURDIR}/po/zh-cn/clash.po ${CURDIR}/po/zh-cn/clash.zh-cn.lmo
	$(CP) $(CURDIR)/root $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/luasrc $(PKG_BUILD_DIR)
	rm -rf $(PKG_BUILD_DIR)/root/usr/share/clash/dashboard
	chmod 0755 $(PKG_BUILD_DIR)/root/etc/init.d/clash
	find $(PKG_BUILD_DIR)/root -name *.sh | xargs chmod 0755
	find $(PKG_BUILD_DIR)/root -name *.lua | xargs chmod 0755
	chmod 0755 $(PKG_BUILD_DIR)/luasrc -R
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/clash
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for clash"
    /etc/init.d/clash disable
    /etc/init.d/clash stop
    echo "Removing firewall rule for clash"
	uci -q batch <<-EOF >/dev/null
	delete firewall.clash
	commit firewall
EOF
fi

exit 0
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh
/etc/init.d/clash disable 2>/dev/null
if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/dnsmasq.d/custom_list.conf 2>/dev/null
	rm -rf /tmp/dnsmasq.clash 2>/dev/null
	mv /etc/config/clash /etc/config/clash.bak 2>/dev/null
	rm -rf /usr/lib/lua/luci/model/cbi/clash 2>/dev/null
	rm -rf /usr/lib/lua/luci/view/clash 2>/dev/null
	rm -rf /usr/share/clash/web 2>/dev/null
	rm -rf /tmp/clash_new_version_meta 2>/dev/null
	mkdir -p /tmp/clash_tmp_dir 2>/dev/null
	mv /usr/share/clash/config/sub/config.yaml /tmp/clash_tmp_dir/config.bak1 2>/dev/null
	mv /usr/share/clash/config/upload/config.yaml /tmp/clash_tmp_dir/config.bak2 2>/dev/null
	mv /usr/share/clash/config/custom/config.yaml /tmp/clash_tmp_dir/config.bak3 2>/dev/null
	mv /usr/share/clash/rule.yaml /tmp/clash_tmp_dir/rule.bak 2>/dev/null
fi


exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -rf /tmp/luci*
	mv /etc/config/clash.bak /etc/config/clash 2>/dev/null
	mv /tmp/clash_tmp_dir/config.bak1 /usr/share/clash/config/sub/config.yaml 2>/dev/null
	mv /tmp/clash_tmp_dir/config.bak2 /usr/share/clash/config/upload/config.yaml 2>/dev/null
	mv /tmp/clash_tmp_dir/config.bak3 /usr/share/clash/config/custom/config.yaml 2>/dev/null
	mv /tmp/clash_tmp_dir/rule.bak /usr/share/clash/rule.yaml 2>/dev/null
	rmdir /tmp/clash_tmp_dir 2>/dev/null
	/etc/init.d/clash disable 2>/dev/null
fi
/etc/init.d/clash disable 2>/dev/null

exit 0
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/clash/backup
	$(INSTALL_DIR) $(1)/usr/share/clash/config
	$(INSTALL_DIR) $(1)/usr/share/clash/config/sub
	$(INSTALL_DIR) $(1)/usr/share/clash/config/upload
	$(INSTALL_DIR) $(1)/usr/share/clash/config/custom

	$(INSTALL_DIR) $(1)/etc/clash/dashboard
	$(INSTALL_DIR) $(1)/etc/clash/clashtun
	$(INSTALL_DIR) $(1)/etc/clash/dtun
	$(INSTALL_DIR) $(1)/etc/clash/provider
	$(INSTALL_DIR) $(1)/etc/clash/proxyprovider
	$(INSTALL_DIR) $(1)/etc/clash/ruleprovider

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n

	$(CP) $(PKG_BUILD_DIR)/root/etc/* $(1)/etc/
	$(CP) $(PKG_BUILD_DIR)/root/usr/share/* $(1)/usr/share/
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/

	$(CP) ./po/zh-cn/clash.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
