include $(TOPDIR)/rules.mk

PKG_NAME:=airconnect
PKG_VERSION:=1.11.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/philippe44/AirConnect/tar.gz/$(PKG_VERSION)?
PKG_HASH:=skip
PKG_BUILD_DIR:=$(BUILD_DIR)/AirConnect-$(PKG_VERSION)

PKG_MAINTAINER:=Philippe <philippe_44@outlook.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

# ==================== AirUPnP 包定义 ====================
define Package/airupnp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AirPlay to UPnP/Sonos bridge (Built from source)
  URL:=https://github.com/philippe44/AirConnect
  DEPENDS:=+libpthread +libopenssl +libnghttp2 +libupnp +libflac +libsoxr +libatomic
endef

define Package/airupnp/description
  AirPlay audio streaming bridge to UPnP/Sonos players, compiled from source.
endef

# ==================== AirCast 包定义 ====================
define Package/aircast
  SECTION:=net
  CATEGORY:=Network
  TITLE:=AirPlay to Chromecast bridge (Built from source)
  URL:=https://github.com/philippe44/AirConnect
  DEPENDS:=+libpthread +libopenssl +libnghttp2 +libflac +libsoxr +libatomic
endef

define Package/aircast/description
  AirPlay audio streaming bridge to Chromecast players, compiled from source.
endef

# 通用头文件路径
TARGET_CPPFLAGS += \
	-I$(PKG_BUILD_DIR)/common \
	-I$(PKG_BUILD_DIR)/common/crosstools/src \
	-I$(PKG_BUILD_DIR)/common/libraop/src \
	-I$(PKG_BUILD_DIR)/common/libmdns/src \
	-I$(PKG_BUILD_DIR)/common/libcodecs/include \
	-I$(STAGING_DIR)/usr/include/upnp \
	-I$(STAGING_DIR)/usr/include/ixml

# 编译优化与通用宏
TARGET_CFLAGS += \
	-D_GNU_SOURCE \
	-DNDEBUG \
	-DLOOPBACK_AUDIO \
	-DNO_EXTERNAL_CONFIG \
	-ffunction-sections \
	-fdata-sections \
	$(FPIC)

# 动态链接库与死代码裁剪
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

	# 1. 纯源码编译 airupnp
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) \
		-I$(PKG_BUILD_DIR)/airupnp/src/inc \
		-I$(PKG_BUILD_DIR)/airupnp/src \
		$(PKG_BUILD_DIR)/airupnp/src/*.c \
		$(PKG_BUILD_DIR)/common/crosstools/src/*.c \
		$(PKG_BUILD_DIR)/common/libraop/src/*.c \
		$(PKG_BUILD_DIR)/common/libmdns/src/*.c \
		$(PKG_BUILD_DIR)/common/libcodecs/src/*.c \
		-o $(PKG_BUILD_DIR)/bin/airupnp \
		$(TARGET_LDFLAGS) -lupnp -lixml

	# 2. 纯源码编译 aircast
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) \
		-I$(PKG_BUILD_DIR)/aircast/src/inc \
		-I$(PKG_BUILD_DIR)/aircast/src \
		$(PKG_BUILD_DIR)/aircast/src/*.c \
		$(PKG_BUILD_DIR)/common/crosstools/src/*.c \
		$(PKG_BUILD_DIR)/common/libraop/src/*.c \
		$(PKG_BUILD_DIR)/common/libmdns/src/*.c \
		$(PKG_BUILD_DIR)/common/libcodecs/src/*.c \
		-o $(PKG_BUILD_DIR)/bin/aircast \
		$(TARGET_LDFLAGS)
endef

# ==================== AirUPnP 安装与封包 ====================
define Package/airupnp/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/airupnp $(1)/usr/bin/airupnp
	if [ -f ./files/airupnp.init ]; then \
		$(INSTALL_BIN) ./files/airupnp.init $(1)/etc/init.d/airupnp ; \
	fi
endef

# ==================== AirCast 安装与封包 ====================
define Package/aircast/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/aircast $(1)/usr/bin/aircast
	if [ -f ./files/aircast.init ]; then \
		$(INSTALL_BIN) ./files/aircast.init $(1)/etc/init.d/aircast ; \
	fi
endef

$(eval $(call BuildPackage,airupnp))
$(eval $(call BuildPackage,aircast))
