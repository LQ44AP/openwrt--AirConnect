include $(TOPDIR)/rules.mk

PKG_NAME:=airconnect
PKG_VERSION:=1.11.2
PKG_RELEASE:=3

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
  DEPENDS:=+libpthread +libopenssl +libnghttp2 +libstdcpp
endef

define Package/airconnect/description
  AirConnect allows AirPlay audio streaming to UPnP/Sonos and Chromecast devices.
  Compiled from source for cross-platform targets including mipsle.
endef

TARGET_CFLAGS += $(FPIC) -D_GNU_SOURCE
TARGET_LDFLAGS += -lpthread -lssl -lcrypto -lm

define Build/Compile
	# 交叉编译 airupnp 源码
	$(MAKE) -C $(PKG_BUILD_DIR)/airupnp \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		CROSS="$(TARGET_CROSS)"

	# 交叉编译 aircast 源码
	$(MAKE) -C $(PKG_BUILD_DIR)/aircast \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		CROSS="$(TARGET_CROSS)"
endef

define Package/airconnect/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d

	# 安装二进制文件
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/airupnp/bin/airupnp $(1)/usr/bin/airupnp 2>/dev/null || \
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/airupnp/airupnp $(1)/usr/bin/airupnp 2>/dev/null || true

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aircast/bin/aircast $(1)/usr/bin/aircast 2>/dev/null || \
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aircast/aircast $(1)/usr/bin/aircast 2>/dev/null || true

	# 安装 init.d 启动脚本
	$(INSTALL_BIN) ./files/airconnect.init $(1)/etc/init.d/airconnect
endef

$(eval $(call BuildPackage,airconnect))
