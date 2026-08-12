include $(TOPDIR)/rules.mk

PKG_NAME:=airconnect
PKG_VERSION:=1.11.2
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/philippe44/AirConnect.git
PKG_SOURCE_VERSION:=$(PKG_VERSION)
PKG_MIRROR_HASH:=skip
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBMODULES:=1

PKG_MAINTAINER:=Philippe <philippe_44@outlook.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/airupnp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AirPlay to UPnP/Sonos bridge
  URL:=https://github.com/philippe44/AirConnect
  DEPENDS:=+libpthread +libopenssl +libnghttp2 +libupnp +libflac +libsoxr +libatomic
endef

define Package/aircast
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AirPlay to Chromecast bridge
  URL:=https://github.com/philippe44/AirConnect
  DEPENDS:=+libpthread +libopenssl +libnghttp2 +libflac +libsoxr +libatomic
endef

# 平台宏与头文件定义
TARGET_CFLAGS += \
	-D_GNU_SOURCE \
	-DLINUX \
	-DPOSIX \
	-DNDEBUG \
	-DLOOPBACK_AUDIO \
	-DNO_EXTERNAL_CONFIG \
	-ffunction-sections \
	-fdata-sections \
	$(FPIC)

TARGET_LDFLAGS += \
	-Wl,--gc-sections \
	-lssl \
	-lcrypto \
	-lpthread \
	-lsoxr \
	-lFLAC \
	-latomic \
	-lm

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/bin

	# 1. 编译 airupnp (进入 airupnp 源码目录由内置规则构建)
	$(MAKE) -C $(PKG_BUILD_DIR)/airupnp/src -f Makefile \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -I$(STAGING_DIR)/usr/include/upnp -I$(STAGING_DIR)/usr/include/ixml" \
		LDFLAGS="$(TARGET_LDFLAGS) -lupnp -lixml" \
		BUILD_DIR="$(PKG_BUILD_DIR)/bin" \
		EXECUTABLE="$(PKG_BUILD_DIR)/bin/airupnp"

	# 2. 编译 aircast (进入 aircast 源码目录由内置规则构建)
	$(MAKE) -C $(PKG_BUILD_DIR)/aircast/src -f Makefile \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		BUILD_DIR="$(PKG_BUILD_DIR)/bin" \
		EXECUTABLE="$(PKG_BUILD_DIR)/bin/aircast"
endef

define Package/airupnp/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/airupnp $(1)/usr/bin/airupnp
	if [ -f ./files/airupnp.init ]; then \
		$(INSTALL_BIN) ./files/airupnp.init $(1)/etc/init.d/airupnp ; \
	fi
endef

define Package/aircast/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/aircast $(1)/usr/bin/aircast
	if [ -f ./files/aircast.init ]; then \
		$(INSTALL_BIN) ./files/aircast.init $(1)/etc/init.d/aircast ; \
	fi
endef

$(eval $(call BuildPackage,airupnp))
$(eval $(call BuildPackage,aircast))
