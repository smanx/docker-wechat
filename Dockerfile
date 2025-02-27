FROM jlesage/baseimage-gui:ubuntu-24.04-v4

# 替换APT源为清华源
RUN sed -i 's@/archive.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i 's@/security.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/ubuntu/@g' /etc/apt/sources.list.d/ubuntu.sources

# 安装必要依赖
RUN apt update && \
    apt install -y language-pack-zh-hans fonts-noto-cjk-extra curl \
    shared-mime-info desktop-file-utils libxcb1 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-randr0 libxcb-render0 libxcb-render-util0 libxcb-shape0 \
    libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xkb1 libxcb-xinerama0 \
    libxcb-xkb1 libxcb-glx0 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libcups2 \
    libdbus-1-3 libfontconfig1 libgbm1 libgcc1 libgdk-pixbuf2.0-0 libglib2.0-0 \
    libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
    libxcomposite1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxss1 libxtst6 libatomic1 libxcomposite1 libxrender1 libxrandr2 libxkbcommon-x11-0 \
    libfontconfig1 libdbus-1-3 libnss3 libx11-xcb1 libasound2t64 libtiff-dev && \
    # 清理工作
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN LIBTIFF_PATH=$(find /usr/lib -name "libtiff.so" | head -n 1) && \
    if [ -n "$LIBTIFF_PATH" ]; then \
        ln -s "$LIBTIFF_PATH" "${LIBTIFF_PATH%.so}.so.5"; \
    fi

# 生成微信图标
RUN APP_ICON_URL=https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico && \
    install_app_icon.sh "$APP_ICON_URL"
    
# 设置应用名称
RUN set-cont-env APP_NAME "Wechat"

# 获取系统架构信息
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        PACKAGE_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        PACKAGE_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    # 下载微信安装包
    curl -O "$PACKAGE_URL" && \
    PACKAGE_NAME=$(basename "$PACKAGE_URL") && \
    dpkg -i "$PACKAGE_NAME" 2>&1 | tee /tmp/wechat_install.log && \
    rm "$PACKAGE_NAME"

RUN echo '#!/bin/sh' > /startapp.sh && \
    echo 'exec /usr/bin/wechat' >> /startapp.sh && \
    chmod +x /startapp.sh

VOLUME /root/.xwechat
VOLUME /root/xwechat_files
VOLUME /root/downloads

# 配置微信版本号
RUN set-cont-env APP_VERSION "$(grep -o 'Unpacking wechat ([0-9.]*)' /tmp/wechat_install.log | sed 's/Unpacking wechat (\(.*\))/\1/')"
