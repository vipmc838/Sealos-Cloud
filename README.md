### V1版哪吒面板，自动备份。

安装好第一件事，**必须进面板改密码**

Docker镜像地址
```
ghcr.io/vipmc838/sealos-cloud/nezha-v1:latest
```
必须设置的变量

| 变量 | 值 | 备注 |
| --- | --- | --- |
ARGO_AUTH | 1.像eyJhIjoi.......类似,映射端口，只需要80端口就行了 | 2.从[cloudflared Tunnels](https://one.dash.cloudflare.com/)获取的 Argo Token | 
ARGO_DOMAIN | 哪吒的访问域名,格式：`www.abc.com` | 用于面板访问和探针上报使用 |
WEBDAV_URL | 填写你的WEBDAV地址 | 用于哪吒配置文件备份 |
WEBDAV_USER | 填写你的WEBDAV用户名 | 用于哪吒配置文件备份 |
WEBDAV_PASS | 填写你的WEBDAV密码 | 用于哪吒配置文件备份 |
NZ_UUID | 面板当前所在的agent的uuid | 用于监测面板docker的状态 |
NZ_CLIENT_SECRET | 哪吒面板的.yaml文件设置的固定key | 文件中的agentsecretkey所对应的参数 |
NZ_TLS | 哪吒面板的TLS | 启用 TLS（true/false） |
DASHBOARD_VERSION | 需要部署的探针等级,格式：`v1.12.2`| 不填:最新版本。 |
