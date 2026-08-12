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

# 动态获取源码树中所有 include/inc/src 目录作为头文件查找路径
INCLUDES_DIRS = $(shell find $(PKG_BUILD_DIR) -type d \( -name "inc" -o -name "include" -o -name "src" \) ! -path "*/openssl*" ! -path "*/test*")
COMMON_INCLUDES = $(patsubst %,-I%,$(INCLUDES_DIRS))

AIRUPNP_INCLUDES := \
	$(COMMON_INCLUDES) \
	-I$(STAGING_DIR)/usr/include/upnp \
	-I$(STAGING_DIR)/usr/include/ixml

AIRCAST_INCLUDES := \
	$(COMMON_INCLUDES)

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/bin

	# 1. 编译 airupnp: 仅编译各类 src/ 目录下的 C 源文件，排除 aircast、内置 openssl 及 test 目录
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) $(AIRUPNP_INCLUDES) \
		`find $(PKG_BUILD_DIR) -type f -path "*/src/*.c" ! -path "*/aircast/*" ! -path "*/libopenssl/*" ! -path "*/openssl/*" ! -path "*/test/*" ! -path "*/bin/*" ! -path "*/build/*"` \
		-o $(PKG_BUILD_DIR)/bin/airupnp \
		$(TARGET_LDFLAGS) \
		-lupnp -lixml -lssl -lcrypto -lpthread -lsoxr -lFLAC -latomic -lm

	# 2. 编译 aircast: 仅编译各类 src/ 目录下的 C 源文件，排除 airupnp、内置 openssl 及 test 目录
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) $(AIRCAST_INCLUDES) \
		`find $(PKG_BUILD_DIR) -type f -path "*/src/*.c" ! -path "*/airupnp/*" ! -path "*/libopenssl/*" ! -path "*/openssl/*" ! -path "*/test/*" ! -path "*/bin/*" ! -path "*/build/*"` \
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
