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
  DEPENDS:=+libpthread +libopenssl +libupnp +libflac +libsoxr +libatomic
endef

define Package/aircast
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AirPlay to Chromecast bridge
  URL:=https://github.com/philippe44/AirConnect
  DEPENDS:=+libpthread +libopenssl +libflac +libsoxr +libatomic
endef

TARGET_CFLAGS += \
	-D_GNU_SOURCE \
	-DLINUX \
	-DPOSIX \
	-DNDEBUG \
	-DLOOPBACK_AUDIO \
	-DNO_EXTERNAL_CONFIG \
	-Wno-deprecated-declarations \
	-ffunction-sections \
	-fdata-sections \
	$(FPIC)

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/bin

	# 1. 编译 airupnp: 在执行阶段动态提取所有包含 .h 文件的目录作为 -I 参数
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) \
		`find $(PKG_BUILD_DIR) -type f -name "*.h" ! -path "*/aircast/*" ! -path "*/openssl/*" ! -path "*/test/*" -exec dirname {} + | sort -u | sed 's/^/-I/'` \
		-I$(STAGING_DIR)/usr/include/upnp \
		-I$(STAGING_DIR)/usr/include/ixml \
		`find $(PKG_BUILD_DIR) -type f -name "*.c" ! -path "*/aircast/*" ! -path "*/libopenssl/*" ! -path "*/openssl/*" ! -path "*/test/*" ! -path "*/bin/*" ! -path "*/build/*"` \
		-o $(PKG_BUILD_DIR)/bin/airupnp \
		$(TARGET_LDFLAGS) \
		-lupnp -lixml -lssl -lcrypto -lpthread -lsoxr -lFLAC -latomic -lm

	# 2. 编译 aircast
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) \
		`find $(PKG_BUILD_DIR) -type f -name "*.h" ! -path "*/airupnp/*" ! -path "*/openssl/*" ! -path "*/test/*" -exec dirname {} + | sort -u | sed 's/^/-I/'` \
		`find $(PKG_BUILD_DIR) -type f -name "*.c" ! -path "*/airupnp/*" ! -path "*/libopenssl/*" ! -path "*/openssl/*" ! -path "*/test/*" ! -path "*/bin/*" ! -path "*/build/*"` \
		-o $(PKG_BUILD_DIR)/bin/aircast \
		$(TARGET_LDFLAGS) \
		-lssl -lcrypto -lpthread -lsoxr -lFLAC -latomic -lm
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
