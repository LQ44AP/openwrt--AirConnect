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
	-ffunction-sections \
	-fdata-sections \
	$(FPIC)

# 全局头文件搜索路径 (覆盖所有可能存在的子模块与上游库路径)
COMMON_INCLUDES := \
	-I$(PKG_BUILD_DIR) \
	-I$(PKG_BUILD_DIR)/tools \
	-I$(PKG_BUILD_DIR)/tools/inc \
	-I$(PKG_BUILD_DIR)/tools/src \
	-I$(PKG_BUILD_DIR)/c-tools \
	-I$(PKG_BUILD_DIR)/c-tools/inc \
	-I$(PKG_BUILD_DIR)/c_tools \
	-I$(PKG_BUILD_DIR)/c_tools/inc \
	-I$(PKG_BUILD_DIR)/libcodecs/include \
	-I$(PKG_BUILD_DIR)/libcodecs/src \
	-I$(PKG_BUILD_DIR)/c_codecs/include \
	-I$(PKG_BUILD_DIR)/c_codecs/src \
	-I$(PKG_BUILD_DIR)/libraop/src \
	-I$(PKG_BUILD_DIR)/libmdns/src

AIRUPNP_INCLUDES := \
	$(COMMON_INCLUDES) \
	-I$(PKG_BUILD_DIR)/airupnp/src \
	-I$(PKG_BUILD_DIR)/airupnp/src/inc \
	-I$(STAGING_DIR)/usr/include/upnp \
	-I$(STAGING_DIR)/usr/include/ixml

AIRCAST_INCLUDES := \
	$(COMMON_INCLUDES) \
	-I$(PKG_BUILD_DIR)/aircast/src \
	-I$(PKG_BUILD_DIR)/aircast/src/inc

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/bin

	# 1. 编译 airupnp (编译所有公共组件与 airupnp 源码，排除 aircast)
	$(TARGET_CC)$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)$(AIRUPNP_INCLUDES) \
		`find $(PKG_BUILD_DIR) -type f -name "*.c" ! -path "*/aircast/*" ! -path "*/bin/*" ! -path "*/build/*"` \
		-o $(PKG_BUILD_DIR)/bin/airupnp \
		$(TARGET_LDFLAGS) \
		-lupnp -lixml -lssl -lcrypto -lpthread -lsoxr -lFLAC -latomic -lm

	# 2. 编译 aircast (编译所有公共组件与 aircast 源码，排除 airupnp)
	$(TARGET_CC)$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)$(AIRCAST_INCLUDES) \
		`find $(PKG_BUILD_DIR) -type f -name "*.c" ! -path "*/airupnp/*" ! -path "*/bin/*" ! -path "*/build/*"` \
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
