FROM ricwang/docker-wechat:base

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
