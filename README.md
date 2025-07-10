### V1版哪吒面板，自动备份。

### Sealos Cloud官网：[点击进入Sealos Cloud官网註册](https://cloud.sealos.run/?uid=tkiqhrqlz3) 邀请码：tkiqhrqlz3  册时输入此推荐码即可双方各得 10元余额奖励！

### 没有WEBDAV存储去这里：[点击进入InfiniCLOUD官网註册](https://infini-cloud.net/en) 邀请码：PPMZC  注册时输入此推荐码即可获得5GB免费InfiniCLOUD存储！

搭建好的效果：https://www.nezha.app.tc

安装好第一件事，**必须进面板改密码**

Docker镜像地址
```
ghcr.io/vipmc838/sealos-cloud/nezha-v1:latest
```

### 前置准备
1. **CloudFlare开启GRPC流量代理**

2. **设置 Tunnel Public hostname**

  - Type: `HTTPS`
  - URL: `localhost:443`
  - Additional application settings
    - TLS
      - No TLS Verify: `on`
      - HTTP2 connection: `on`
  - **记录 argo 域名和 token 备用**

3. **WEBDAV存储**

  - Turn on Apps Connection  打开应用程序连接
  - WebDAV Connection URL  WebDAV 连接 URL	https://gima.teracloud.jp/dav/
  - Connection ID  连接 ID WEBDAV用户名
  - Apps Password  应用程序密码 WEBDAV密码
  - 进入File Browser 新建文件夹 WebDAV 连接 URL	https://gima.teracloud.jp/dav/backup/

  
必须设置的变量

| 变量 | 值 | 备注 |
| --- | --- | --- |
ARGO_AUTH | 1.像eyJhIjoi.......类似,映射端口，只需要80端口就行了 | 2.从[cloudflared Tunnels](https://one.dash.cloudflare.com/)获取的 Argo Token | 
ARGO_DOMAIN | 哪吒的访问域名,格式：`www.abc.com` | 用于面板访问和探针上报使用 |
WEBDAV_URL | 填写你的WEBDAV地址 | 用于哪吒配置文件备份 |
WEBDAV_USER | 填写你的WEBDAV用户名 | 用于哪吒配置文件备份 |
WEBDAV_PASS | 填写你的WEBDAV密码 | 用于哪吒配置文件备份 |
NZ_UUID | 面板当前所在的agent的uuid | 用于监测面板docker的状态 |
NZ_CLIENT_SECRET | 哪吒面板的.yaml文件设置的固定key | 文件中的agentsecretkey所对应的参数 默认:kxU90rEPN7XsgDJp0qCG87UGdFYoTFkE|
NZ_TLS | 哪吒面板的TLS | 启用 TLS（true/false） 默认:false|
DASHBOARD_VERSION | 需要部署的探针等级,格式：`v1.12.2`| 默认:最新版本。 |


#### 第一次安装 Agent 不上线的，要备份后拿到config.yaml文件设置的固定key，文件中的agentsecretkey所对应的参数 填写NZ_CLIENT_SECRET重启后才能上线。

#### 每天中午2点和晚上2点自动备份。

#### 手动备份进入ssh：
```
cd / && ./backup.sh backup
```
