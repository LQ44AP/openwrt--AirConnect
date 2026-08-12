include $(TOPDIR)/rules.mk

PKG_NAME:=airconnect
PKG_VERSION:=1.11.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/philippe44/AirConnect/tar.gz/$(PKG_VERSION)?
PKG_HASH:=skip

PKG_MAINTAINER:=Philippe <philippe_44@outlook.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/airconnect
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AirPlay to Chromecast and UPnP/Sonos bridge
  URL:=https://github.com/philippe44/AirConnect
  DEPENDS:=+libpthread +libopenssl +libnghttp2
endef

define Package/airconnect/description
  AirConnect allows AirPlay audio streaming to UPnP/Sonos and Chromecast devices.
  Includes automated binary selection for mips, mipsle, aarch64, arm, and x86_64.
endef

# 跳过源码编译，直接使用 bin 目录下的目标架构二进制
define Build/Compile
endef

define Package/airconnect/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d

	# 识别架构并安装对应的二进制文件
	case "$(ARCH)" in \
		mipsel|mipsle) \
			UPNP_BIN=$$(ls $(PKG_BUILD_DIR)/bin/airupnp*mipsle* 2>/dev/null | head -n 1) ; \
			CAST_BIN=$$(ls $(PKG_BUILD_DIR)/bin/aircast*mipsle* 2>/dev/null | head -n 1) ; \
			;; \
		mips) \
			UPNP_BIN=$$(ls $(PKG_BUILD_DIR)/bin/airupnp-mips 2>/dev/null | head -n 1) ; \
			CAST_BIN=$$(ls $(PKG_BUILD_DIR)/bin/aircast-mips 2>/dev/null | head -n 1) ; \
			;; \
		aarch64|arm64) \
			UPNP_BIN=$$(ls $(PKG_BUILD_DIR)/bin/airupnp*aarch64* $(PKG_BUILD_DIR)/bin/airupnp*arm64* 2>/dev/null | head -n 1) ; \
			CAST_BIN=$$(ls $(PKG_BUILD_DIR)/bin/aircast*aarch64* $(PKG_BUILD_DIR)/bin/aircast*arm64* 2>/dev/null | head -n 1) ; \
			;; \
		arm) \
			UPNP_BIN=$$(ls $(PKG_BUILD_DIR)/bin/airupnp*arm* 2>/dev/null | grep -v '64' | head -n 1) ; \
			CAST_BIN=$$(ls $(PKG_BUILD_DIR)/bin/aircast*arm* 2>/dev/null | grep -v '64' | head -n 1) ; \
			;; \
		x86_64) \
			UPNP_BIN=$$(ls $(PKG_BUILD_DIR)/bin/airupnp*x86-64* $(PKG_BUILD_DIR)/bin/airupnp*x86_64* 2>/dev/null | head -n 1) ; \
			CAST_BIN=$$(ls $(PKG_BUILD_DIR)/bin/aircast*x86-64* $(PKG_BUILD_DIR)/bin/aircast*x86_64* 2>/dev/null | head -n 1) ; \
			;; \
		i386|x86) \
			UPNP_BIN=$$(ls $(PKG_BUILD_DIR)/bin/airupnp*x86 2>/dev/null | head -n 1) ; \
			CAST_BIN=$$(ls $(PKG_BUILD_DIR)/bin/aircast*x86 2>/dev/null | head -n 1) ; \
			;; \
		*) \
			echo "Unsupported architecture: $(ARCH)" ; \
			exit 1 ; \
			;; \
	esac ; \
	if [ -n "$$UPNP_BIN" ]; then $(INSTALL_BIN) $$UPNP_BIN $(1)/usr/bin/airupnp; fi ; \
	if [ -n "$$CAST_BIN" ]; then $(INSTALL_BIN) $$CAST_BIN $(1)/usr/bin/aircast; fi ;

	# 安装 init.d 脚本
	if [ -f ./files/airconnect.init ]; then \
		$(INSTALL_BIN) ./files/airconnect.init $(1)/etc/init.d/airconnect ; \
	fi
endef

$(eval $(call BuildPackage,airconnect))
