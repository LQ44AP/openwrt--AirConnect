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
  DEPENDS:=+libpthread +libopenssl +libnghttp2 +libstdcpp
endef

define Package/airconnect/description
  AirConnect allows AirPlay audio streaming to UPnP/Sonos and Chromecast devices.
endef

TARGET_CFLAGS += $(FPIC) -D_GNU_SOURCE
TARGET_LDFLAGS += -lpthread -lssl -lcrypto -lm

define Build/Compile
	# 在根目录下直接编译 airupnp 和 aircast
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		CROSS="$(TARGET_CROSS)" \
		bin/airupnp bin/aircast
endef

define Package/airconnect/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d

	# 安装编译好的二进制文件
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/airupnp $(1)/usr/bin/airupnp
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/aircast $(1)/usr/bin/aircast

	# 安装 init.d 启动脚本
	$(INSTALL_BIN) ./files/airconnect.init $(1)/etc/init.d/airconnect
endef

$(eval $(call BuildPackage,airconnect))
