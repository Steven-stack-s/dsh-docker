# 02 · Authentication & Remote Access

> [English](02-authentication-remote-access.md) | [简体中文](../zh-CN/02-认证与远程访问.md)

The default configuration is **intranet direct access** (no auth plugin installed): port `3080` is mapped to the host, reachable only within the LAN.
For **remote access across networks** (public internet, off-site), follow this guide to add authentication and use a reverse proxy.

## 1. Access Overview

| Method | Security | Use case |
|---|---|---|
| Local access (`127.0.0.1:3080`) | Highest | Browser on the same machine |
| Intranet direct access (`http://<内网IP>:3080`) | High (no auth, relies on intranet isolation) | LAN usage |
| SSH tunnel | High (encrypted) | Temporary single-user access from outside |
| Reverse proxy + dsh-remote auth | High (auth layer + HTTPS) | Long-term remote access |

> Browser limitation: some features of `dsh web` (e.g. `crypto.randomUUID`, settings) require a **secure context**
> (HTTPS or localhost). If you hit related errors when accessing the intranet directly by IP, that is the browser's security
> policy; use `localhost`, an SSH tunnel, or HTTPS via a reverse proxy instead.

## 2. Add dsh-remote Authentication (Optional, Recommended for Remote Access)

The [dsh-remote](https://github.com/xgone/dsh-remote) plugin provides **username/password + MFA (TOTP)** authentication;
`/api`, WebSocket, and privileged methods are only allowed after a successful login.

```bash
# Install the plugin (plugin & account data go into the /data/dsh volume, survive container rebuilds)
docker exec dsh dsh plugin --profile web add @xgone/dsh-remote
docker restart dsh
```

### 2.1 Create the First Admin (loopback Only, to Prevent Remote Registration)

Run on the **host machine**:

```bash
curl -s -X POST http://127.0.0.1:3080/auth/bootstrap \
  -H 'Content-Type: application/json' \
  -d '{"username":"你的用户名","password":"你的密码"}'
# Expected response: {"ok":true,...,"user":{...}}
```

> Skip this step if you already created an admin in [01](01-quick-start.md).

### 2.2 Log In and Enable MFA

- Visit `http://<主机>:3080` and log in with your account
- Settings → Login & Account → Two-factor authentication (MFA) → scan the QR code with Google Authenticator / 1Password
- **MFA is mandatory**: if exposed to the public internet via a reverse proxy, the auth layer is the only line of defense

## 3. SSH Tunnel (Temporary Single-User Access from Outside)

```bash
# Local port forwarding: map remote 3080 to local 3080
ssh -L 3080:127.0.0.1:3080 你的账号@主机IP
# Then open http://127.0.0.1:3080 in the browser
```

Works wherever Windows/Mac/Linux ship with a built-in `ssh` — no extra configuration needed.

## 4. Reverse Proxy + HTTPS (Long-Term Remote Access, Recommended)

Using Caddy (automatic HTTPS) as an example; Nginx works the same way:

```bash
# Caddyfile (the domain must resolve to the host; ports 80/443 open)
你的域名.com {
    reverse_proxy 127.0.0.1:3080
}
```

```bash
# Run Caddy with Docker
docker run -d --name caddy \
  -p 80:80 -p 443:443 \
  -v /path/to/Caddyfile:/etc/caddy/Caddyfile \
  -v caddy_data:/data \
  caddy:2
```

> Before exposing through a reverse proxy, make sure dsh-remote is installed and MFA is enabled (see Section 2).

## 5. Security Checklist

- [ ] Remote access: strong password + **MFA (TOTP)**
- [ ] Do not map `3080` directly to the public internet (when no auth is added)
- [ ] Third-party plugins have full permissions; review their source before installing
- [ ] Back up regularly (see [03](03-upgrade-maintenance.md))
