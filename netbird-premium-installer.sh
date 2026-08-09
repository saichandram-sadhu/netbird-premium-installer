#!/bin/bash
# NetBird Premium 1-Click Installer
# Features: Animated Download Page, Basic Auth Dashboard, Auto-TLS via Traefik

set -e

echo "================================================="
echo "   NetBird Premium VPN - 1-Click Installer"
echo "================================================="

# 1. Collect Variables
read -p "Enter your Domain Name (e.g., vpn.mydomain.com): " DOMAIN
read -p "Enter Let's Encrypt Email (for SSL certs): " LE_EMAIL
read -p "Enter Dashboard Admin Username: " DASH_USER
read -s -p "Enter Dashboard Admin Password: " DASH_PASS
echo ""

# 2. Setup Dependencies
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and Docker Compose first."
    exit 1
fi

# 3. Generate Basic Auth Hash
echo "Generating secure credentials..."
# Use an alpine container with apache2-utils to generate the htpasswd hash
DASH_HASH=$(docker run --rm xmartlabs/htpasswd -nbB "$DASH_USER" "$DASH_PASS")
# Escape dollar signs for docker-compose file
DASH_HASH_ESCAPED=$(echo "$DASH_HASH" | sed 's/\$/\$\$/g')

# 4. Create Directories
echo "Setting up directories..."
mkdir -p /opt/netbird/download-page
cd /opt/netbird

# 5. Write config.yaml
echo "Writing NetBird Server config..."
cat > config.yaml <<EOF
server:
  listenAddress: ":80"
  exposedAddress: "https://${DOMAIN}:443"
  stunPorts:
    - 3478
  metricsPort: 9090
  healthcheckAddress: ":9000"
  logLevel: "info"
  logFile: "console"

  authSecret: "$(head -c 32 /dev/urandom | base64)"
  dataDir: "/var/lib/netbird"

  auth:
    issuer: "https://${DOMAIN}/oauth2"
    signKeyRefreshEnabled: true
    dashboardRedirectURIs:
      - "https://${DOMAIN}/nb-auth"
      - "https://${DOMAIN}/nb-silent-auth"
    cliRedirectURIs:
      - "http://localhost:53000/"

  reverseProxy:
    trustedHTTPProxies:
      - "172.30.0.10/32"

  store:
    engine: "sqlite"
    encryptionKey: "$(head -c 32 /dev/urandom | base64)"
EOF

# 6. Write dashboard.env
echo "Writing Dashboard config..."
cat > dashboard.env <<EOF
NETBIRD_MGMT_API_ENDPOINT=https://${DOMAIN}
NETBIRD_MGMT_GRPC_API_ENDPOINT=https://${DOMAIN}
AUTH_AUDIENCE=netbird-dashboard
AUTH_CLIENT_ID=netbird-dashboard
AUTH_CLIENT_SECRET=
AUTH_AUTHORITY=https://${DOMAIN}/oauth2
USE_AUTH0=false
AUTH_SUPPORTED_SCOPES=openid profile email groups
AUTH_REDIRECT_URI=/nb-auth
AUTH_SILENT_REDIRECT_URI=/nb-silent-auth
NGINX_SSL_PORT=443
LETSENCRYPT_DOMAIN=none
EOF

# 7. Write NGINX config for download page
echo "Writing Download Page NGINX config..."
cat > download-page/nginx.conf <<'EOF'
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

# 8. Write the Premium Animated Download Page HTML
echo "Writing Premium Download Page HTML..."
cat > download-page/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NetBird VPN — Download & Connect Securely</title>
    <meta name="description" content="Download NetBird VPN client for Windows, macOS, Linux, Android & iOS. Connect to your private network securely in seconds.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #06060b;
            --bg-card: rgba(255, 255, 255, 0.025);
            --bg-card-hover: rgba(255, 255, 255, 0.05);
            --border-subtle: rgba(255, 255, 255, 0.06);
            --border-hover: rgba(255, 255, 255, 0.12);
            --text-primary: #f4f4f5;
            --text-secondary: #a1a1aa;
            --text-muted: #71717a;
            --accent-orange: #f57722;
            --accent-orange-glow: rgba(245, 119, 34, 0.15);
            --accent-green: #22c55e;
            --glass-bg: rgba(255, 255, 255, 0.03);
            --glass-border: rgba(255, 255, 255, 0.08);
            --radius-lg: 20px;
            --radius-md: 14px;
            --radius-sm: 10px;
        }
        *{margin:0;padding:0;box-sizing:border-box}
        html{scroll-behavior:smooth}
        body{font-family:'Inter',-apple-system,BlinkMacSystemFont,sans-serif;background:var(--bg-primary);color:var(--text-primary);min-height:100vh;overflow-x:hidden;-webkit-font-smoothing:antialiased}

        .aurora{position:fixed;inset:0;z-index:0;overflow:hidden;pointer-events:none}
        .aurora__orb{position:absolute;border-radius:50%;filter:blur(80px);opacity:.4;will-change:transform}
        .aurora__orb--1{width:600px;height:600px;background:radial-gradient(circle,rgba(245,119,34,.35),transparent 70%);top:-10%;left:-5%;animation:o1 20s ease-in-out infinite}
        .aurora__orb--2{width:500px;height:500px;background:radial-gradient(circle,rgba(99,102,241,.3),transparent 70%);top:20%;right:-10%;animation:o2 25s ease-in-out infinite}
        .aurora__orb--3{width:450px;height:450px;background:radial-gradient(circle,rgba(6,182,212,.25),transparent 70%);bottom:10%;left:20%;animation:o3 22s ease-in-out infinite}
        .aurora__orb--4{width:350px;height:350px;background:radial-gradient(circle,rgba(168,85,247,.2),transparent 70%);bottom:30%;right:15%;animation:o4 18s ease-in-out infinite}
        @keyframes o1{0%,100%{transform:translate(0,0) scale(1)}25%{transform:translate(80px,60px) scale(1.1)}50%{transform:translate(40px,120px) scale(.95)}75%{transform:translate(-40px,80px) scale(1.05)}}
        @keyframes o2{0%,100%{transform:translate(0,0) scale(1)}33%{transform:translate(-100px,50px) scale(1.15)}66%{transform:translate(-60px,-80px) scale(.9)}}
        @keyframes o3{0%,100%{transform:translate(0,0) scale(1)}25%{transform:translate(60px,-60px) scale(1.1)}50%{transform:translate(-40px,-30px) scale(.95)}75%{transform:translate(30px,40px) scale(1.05)}}
        @keyframes o4{0%,100%{transform:translate(0,0) scale(1)}50%{transform:translate(-70px,50px) scale(1.2)}}

        .grain{position:fixed;inset:0;z-index:1;pointer-events:none;opacity:.03;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");background-repeat:repeat;background-size:256px}

        .page{position:relative;z-index:2;max-width:1080px;margin:0 auto;padding:0 24px}

        .navbar{display:flex;align-items:center;justify-content:space-between;padding:20px 0;border-bottom:1px solid var(--border-subtle)}
        .navbar__brand{display:flex;align-items:center;gap:12px;text-decoration:none}
        .navbar__logo{width:36px;height:36px}
        .navbar__logo svg{width:100%;height:100%}
        .navbar__name{font-size:20px;font-weight:700;background:linear-gradient(135deg,#f57722,#ff9a44);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
        .navbar__badge{font-size:11px;font-weight:600;color:var(--accent-green);background:rgba(34,197,94,.1);border:1px solid rgba(34,197,94,.2);padding:4px 10px;border-radius:20px;display:flex;align-items:center;gap:6px}
        .navbar__badge::before{content:'';width:6px;height:6px;background:var(--accent-green);border-radius:50%;animation:pd 2s ease-in-out infinite}
        @keyframes pd{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.5;transform:scale(.8)}}

        .hero{text-align:center;padding:80px 0 60px}
        .hero__eyebrow{display:inline-flex;align-items:center;gap:8px;font-size:13px;font-weight:600;color:var(--accent-orange);background:var(--accent-orange-glow);border:1px solid rgba(245,119,34,.2);padding:6px 16px;border-radius:100px;margin-bottom:28px;animation:fid .6s ease-out}
        .hero__title{font-size:clamp(36px,6vw,64px);font-weight:900;line-height:1.1;letter-spacing:-.03em;margin-bottom:20px;animation:fiu .7s ease-out .1s both}
        .hero__title-gradient{background:linear-gradient(135deg,#fff 0%,#e4e4e7 40%,#a1a1aa 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
        .hero__title-accent{background:linear-gradient(135deg,#f57722,#ff6b35,#ffaa44);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
        .hero__subtitle{font-size:clamp(16px,2.5vw,20px);color:var(--text-secondary);max-width:560px;margin:0 auto 40px;line-height:1.6;animation:fiu .7s ease-out .2s both}
        .hero__stats{display:flex;justify-content:center;gap:48px;animation:fiu .7s ease-out .3s both}
        .hero__stat{text-align:center}
        .hero__stat-value{font-size:24px;font-weight:800}
        .hero__stat-label{font-size:11px;color:var(--text-muted);text-transform:uppercase;letter-spacing:1px;margin-top:4px}

        .detected{text-align:center;margin-bottom:48px;animation:fiu .7s ease-out .4s both}
        .detected__card{display:inline-flex;flex-direction:column;align-items:center;gap:20px;background:linear-gradient(135deg,rgba(245,119,34,.06),rgba(245,119,34,.02));border:1px solid rgba(245,119,34,.15);border-radius:var(--radius-lg);padding:36px 56px;position:relative;overflow:hidden}
        .detected__card::before{content:'';position:absolute;top:0;left:0;right:0;height:1px;background:linear-gradient(90deg,transparent,rgba(245,119,34,.5),transparent)}
        .detected__os-icon{width:56px;height:56px;display:flex;align-items:center;justify-content:center}
        .detected__os-icon svg{width:48px;height:48px}
        .detected__text{font-size:14px;color:var(--text-secondary)}
        .detected__os{font-weight:700;color:var(--text-primary)}
        .detected__btn{display:inline-flex;align-items:center;gap:10px;padding:16px 36px;background:linear-gradient(135deg,#f57722,#e86a1a);color:#fff;font-size:16px;font-weight:700;border:none;border-radius:var(--radius-md);cursor:pointer;text-decoration:none;transition:all .3s cubic-bezier(.4,0,.2,1);box-shadow:0 4px 24px rgba(245,119,34,.3);position:relative;overflow:hidden}
        .detected__btn::before{content:'';position:absolute;inset:0;background:linear-gradient(135deg,transparent,rgba(255,255,255,.15) 50%,transparent);transform:translateX(-100%);transition:transform .5s}
        .detected__btn:hover{transform:translateY(-2px) scale(1.02);box-shadow:0 8px 40px rgba(245,119,34,.4)}
        .detected__btn:hover::before{transform:translateX(100%)}

        .section-label{display:flex;align-items:center;gap:12px;margin-bottom:24px}
        .section-label__text{font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:1.5px;color:var(--text-muted);white-space:nowrap}
        .section-label__line{flex:1;height:1px;background:var(--border-subtle)}

        .bento{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:64px;animation:fiu .7s ease-out .5s both}
        .bento__card{background:var(--bg-card);border:1px solid var(--border-subtle);border-radius:var(--radius-lg);padding:32px 28px;transition:all .4s cubic-bezier(.4,0,.2,1);position:relative;overflow:hidden;cursor:default}
        .bento__card::before{content:'';position:absolute;top:0;left:0;right:0;height:2px;background:linear-gradient(90deg,transparent,var(--ca,#f57722),transparent);opacity:0;transition:opacity .4s}
        .bento__card::after{content:'';position:absolute;inset:0;background:radial-gradient(600px circle at var(--mx,50%) var(--my,50%),rgba(255,255,255,.04),transparent 40%);opacity:0;transition:opacity .3s}
        .bento__card:hover{background:var(--bg-card-hover);border-color:var(--border-hover);transform:translateY(-4px);box-shadow:0 24px 64px rgba(0,0,0,.4)}
        .bento__card:hover::before{opacity:1}
        .bento__card:hover::after{opacity:1}
        .bento__card-inner{position:relative;z-index:1}

        .pi{width:64px;height:64px;border-radius:16px;display:flex;align-items:center;justify-content:center;margin-bottom:24px;transition:transform .3s ease}
        .pi svg{width:34px;height:34px;filter:drop-shadow(0 2px 8px rgba(0,0,0,.3))}
        .bento__card:hover .pi{transform:scale(1.1) translateY(-2px)}

        .bento__card[data-platform="windows"]{--ca:#00adef}
        .bento__card[data-platform="windows"] .pi{background:linear-gradient(135deg,rgba(0,173,239,.15),rgba(0,173,239,.05));border:1px solid rgba(0,173,239,.15)}
        .bento__card[data-platform="macos"]{--ca:#a855f7}
        .bento__card[data-platform="macos"] .pi{background:linear-gradient(135deg,rgba(168,85,247,.15),rgba(168,85,247,.05));border:1px solid rgba(168,85,247,.15)}
        .bento__card[data-platform="linux"]{--ca:#f59e0b}
        .bento__card[data-platform="linux"] .pi{background:linear-gradient(135deg,rgba(245,158,11,.15),rgba(245,158,11,.05));border:1px solid rgba(245,158,11,.15)}
        .bento__card[data-platform="android"]{--ca:#3ddc84}
        .bento__card[data-platform="android"] .pi{background:linear-gradient(135deg,rgba(61,220,132,.15),rgba(61,220,132,.05));border:1px solid rgba(61,220,132,.15)}
        .bento__card[data-platform="ios"]{--ca:#007aff}
        .bento__card[data-platform="ios"] .pi{background:linear-gradient(135deg,rgba(0,122,255,.15),rgba(0,122,255,.05));border:1px solid rgba(0,122,255,.15)}

        .bento__title{font-size:18px;font-weight:700;margin-bottom:6px}
        .bento__desc{font-size:13px;color:var(--text-muted);line-height:1.5;margin-bottom:20px}
        .bento__btn{display:inline-flex;align-items:center;gap:8px;padding:10px 20px;border-radius:var(--radius-sm);font-size:13px;font-weight:600;text-decoration:none;transition:all .25s;border:none;cursor:pointer}
        .bento__btn--primary{background:linear-gradient(135deg,var(--ca,#f57722),color-mix(in srgb,var(--ca,#f57722) 70%,white));color:#fff}
        .bento__btn--primary:hover{transform:translateY(-1px);box-shadow:0 6px 24px color-mix(in srgb,var(--ca) 25%,transparent);filter:brightness(1.1)}
        .bento__btn--secondary{background:rgba(255,255,255,.05);color:var(--text-secondary);border:1px solid var(--border-subtle)}
        .bento__btn--secondary:hover{background:rgba(255,255,255,.08);color:var(--text-primary);border-color:var(--border-hover)}
        .bento__btn svg{width:14px;height:14px}

        .bento__terminal{background:rgba(0,0,0,.5);border:1px solid rgba(255,255,255,.06);border-radius:var(--radius-sm);padding:14px 16px;margin-bottom:16px;font-family:'JetBrains Mono',monospace;font-size:12px;color:var(--accent-green);line-height:1.6;overflow-x:auto;position:relative}
        .bento__terminal-prompt{color:var(--text-muted);user-select:none}
        .bento__terminal-copy{position:absolute;top:8px;right:8px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);color:var(--text-muted);padding:4px 10px;border-radius:6px;font-size:11px;font-family:'Inter',sans-serif;font-weight:600;cursor:pointer;transition:all .2s}
        .bento__terminal-copy:hover{background:rgba(255,255,255,.1);color:var(--text-primary)}

        .guide{margin-bottom:64px}
        .guide__container{background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:var(--radius-lg);overflow:hidden}
        .guide__header{padding:32px 36px 0}
        .guide__title{font-size:24px;font-weight:800;margin-bottom:6px;display:flex;align-items:center;gap:12px}
        .guide__title svg{width:28px;height:28px;color:var(--accent-orange)}
        .guide__subtitle{font-size:14px;color:var(--text-muted);margin-bottom:28px}
        .guide__tabs{display:flex;gap:2px;padding:0 36px;border-bottom:1px solid var(--border-subtle);overflow-x:auto}
        .guide__tab{padding:12px 20px;font-size:13px;font-weight:600;color:var(--text-muted);background:none;border:none;border-bottom:2px solid transparent;cursor:pointer;transition:all .25s;display:flex;align-items:center;gap:8px;white-space:nowrap}
        .guide__tab:hover{color:var(--text-secondary)}
        .guide__tab--active{color:var(--accent-orange);border-bottom-color:var(--accent-orange)}
        .guide__tab svg{width:18px;height:18px}
        .guide__content{padding:32px 36px}
        .guide__panel{display:none}
        .guide__panel--active{display:block;animation:fi .3s ease}
        @keyframes fi{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}

        .step{display:flex;gap:20px;margin-bottom:32px;position:relative}
        .step:last-child{margin-bottom:0}
        .step::before{content:'';position:absolute;left:18px;top:44px;bottom:-32px;width:1px;background:linear-gradient(to bottom,var(--border-subtle),transparent)}
        .step:last-child::before{display:none}
        .step__number{flex-shrink:0;width:36px;height:36px;border-radius:50%;background:var(--accent-orange-glow);border:1px solid rgba(245,119,34,.25);color:var(--accent-orange);font-weight:700;font-size:14px;display:flex;align-items:center;justify-content:center}
        .step__body h4{font-size:16px;font-weight:700;margin-bottom:8px}
        .step__body p{font-size:14px;color:var(--text-muted);line-height:1.6}

        .url-box{display:flex;align-items:center;gap:12px;background:rgba(0,0,0,.4);border:1px solid var(--glass-border);border-radius:var(--radius-sm);padding:14px 18px;margin-top:12px}
        .url-box__url{font-family:'JetBrains Mono',monospace;font-size:14px;color:var(--accent-orange);flex:1;word-break:break-all;user-select:all}
        .url-box__copy{flex-shrink:0;background:var(--accent-orange-glow);color:var(--accent-orange);border:1px solid rgba(245,119,34,.2);padding:8px 18px;border-radius:8px;cursor:pointer;font-size:13px;font-weight:600;font-family:'Inter',sans-serif;transition:all .2s}
        .url-box__copy:hover{background:rgba(245,119,34,.25)}

        .cmd-block{background:rgba(0,0,0,.5);border:1px solid rgba(255,255,255,.06);border-radius:var(--radius-sm);padding:16px 18px;margin-top:12px;font-family:'JetBrains Mono',monospace;font-size:13px;color:var(--accent-green);line-height:1.6;overflow-x:auto;position:relative}
        .cmd-block__prompt{color:var(--text-muted);user-select:none}
        .cmd-block__copy{position:absolute;top:10px;right:10px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.1);color:var(--text-muted);padding:4px 12px;border-radius:6px;font-size:11px;font-family:'Inter',sans-serif;font-weight:600;cursor:pointer;transition:all .2s}
        .cmd-block__copy:hover{background:rgba(255,255,255,.1);color:var(--text-primary)}

        .security{margin-bottom:64px}
        .security__grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}
        .security__item{background:var(--bg-card);border:1px solid var(--border-subtle);border-radius:var(--radius-md);padding:28px;text-align:center;transition:all .3s}
        .security__item:hover{border-color:var(--border-hover);transform:translateY(-2px)}
        .security__icon{margin-bottom:14px;display:flex;justify-content:center}
        .security__icon svg{width:36px;height:36px}
        .security__label{font-size:14px;font-weight:600;margin-bottom:4px}
        .security__desc{font-size:12px;color:var(--text-muted);line-height:1.5}

        .footer{text-align:center;padding:32px 0 48px;border-top:1px solid var(--border-subtle)}
        .footer__text{font-size:13px;color:var(--text-muted)}
        .footer__brand{color:var(--accent-orange);font-weight:700}

        @keyframes fiu{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:translateY(0)}}
        @keyframes fid{from{opacity:0;transform:translateY(-16px)}to{opacity:1;transform:translateY(0)}}

        @media(max-width:768px){.bento{grid-template-columns:1fr}.hero__stats{gap:24px;flex-wrap:wrap}.hero{padding:60px 0 40px}.detected__card{padding:28px 24px}.guide__tabs{padding:0 20px}.guide__content{padding:24px 20px}.guide__header{padding:24px 20px 0}.security__grid{grid-template-columns:1fr}.navbar__badge{display:none}}
        @media(min-width:769px) and (max-width:1024px){.bento{grid-template-columns:repeat(2,1fr)}}
        @media(prefers-reduced-motion:reduce){.aurora__orb{animation:none}*{animation-duration:.01ms!important}}
    </style>
</head>
<body>
<div class="aurora"><div class="aurora__orb aurora__orb--1"></div><div class="aurora__orb aurora__orb--2"></div><div class="aurora__orb aurora__orb--3"></div><div class="aurora__orb aurora__orb--4"></div></div>
<div class="grain"></div>
<div class="page">

    <nav class="navbar">
        <a href="#" class="navbar__brand">
            <div class="navbar__logo"><svg viewBox="0 0 32 32" fill="none"><path d="M16 3L4 9.5l12 6.5 12-6.5L16 3z" fill="#f57722"/><path d="M4 22.5l12 6.5 12-6.5" stroke="#f57722" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none" opacity=".6"/><path d="M4 16l12 6.5 12-6.5" stroke="#f57722" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none" opacity=".8"/></svg></div>
            <span class="navbar__name">NetBird</span>
        </a>
        <div class="navbar__badge">Server Online</div>
    </nav>

    <section class="hero">
        <div class="hero__eyebrow">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            Private & Secure VPN Network
        </div>
        <h1 class="hero__title">
            <span class="hero__title-gradient">Download </span>
            <span class="hero__title-accent">NetBird</span><br>
            <span class="hero__title-gradient">& Connect Securely</span>
        </h1>
        <p class="hero__subtitle">Install NetBird on your device and connect to your private network in one click. Fast, encrypted, and zero-trust.</p>
        <div class="hero__stats">
            <div class="hero__stat"><div class="hero__stat-value">WireGuard®</div><div class="hero__stat-label">Encryption</div></div>
            <div class="hero__stat"><div class="hero__stat-value">P2P</div><div class="hero__stat-label">Direct Connect</div></div>
            <div class="hero__stat"><div class="hero__stat-value">Zero Trust</div><div class="hero__stat-label">Security Model</div></div>
        </div>
    </section>

    <section class="detected" id="detected-section" style="display:none;">
        <div class="detected__card">
            <div class="detected__os-icon" id="detected-icon"></div>
            <div><div class="detected__text">We detected you're using <span class="detected__os" id="detected-os">Windows</span></div></div>
            <a href="#" class="detected__btn" id="detected-btn">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                <span id="detected-btn-text">Download for Windows</span>
            </a>
        </div>
    </section>

    <div class="section-label"><span class="section-label__text">All Platforms</span><div class="section-label__line"></div></div>

    <div class="bento" id="bento-grid">

        <!-- Windows -->
        <div class="bento__card" data-platform="windows">
            <div class="bento__card-inner">
                <div class="pi">
                    <svg viewBox="0 0 88 88" fill="none"><rect x="2" y="2" width="38" height="38" rx="4" fill="#00ADEF"/><rect x="48" y="2" width="38" height="38" rx="4" fill="#00ADEF"/><rect x="2" y="48" width="38" height="38" rx="4" fill="#00ADEF"/><rect x="48" y="48" width="38" height="38" rx="4" fill="#00ADEF"/></svg>
                </div>
                <div class="bento__title">Windows</div>
                <div class="bento__desc">Desktop client for Windows 10/11 (64-bit). Connect and disconnect instantly from the system tray.</div>
                <a href="https://pkgs.netbird.io/windows/x64" class="bento__btn bento__btn--primary" target="_blank">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                    Download .exe
                </a>
            </div>
        </div>

        <!-- macOS -->
        <div class="bento__card" data-platform="macos">
            <div class="bento__card-inner">
                <div class="pi">
                    <svg viewBox="0 0 24 24" fill="#a855f7"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                </div>
                <div class="bento__title">macOS</div>
                <div class="bento__desc">Native app for Mac (Intel & Apple Silicon). Quick access from the menu bar.</div>
                <div style="display:flex;gap:8px;flex-wrap:wrap;">
                    <a href="https://pkgs.netbird.io/macos/amd64" class="bento__btn bento__btn--primary" target="_blank">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                        Intel .pkg
                    </a>
                    <a href="https://pkgs.netbird.io/macos/arm64" class="bento__btn bento__btn--secondary" target="_blank">Apple Silicon</a>
                </div>
            </div>
        </div>

        <!-- Linux -->
        <div class="bento__card" data-platform="linux">
            <div class="bento__card-inner">
                <div class="pi">
                    <svg viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>
                </div>
                <div class="bento__title">Linux</div>
                <div class="bento__desc">Supports Ubuntu, Debian, Fedora, CentOS & more. Install via terminal:</div>
                <div class="bento__terminal">
                    <button class="bento__terminal-copy" onclick="copyText('curl -fsSL https://pkgs.netbird.io/install.sh | sh', this)">Copy</button>
                    <span class="bento__terminal-prompt">$</span> curl -fsSL https://pkgs.netbird.io/install.sh | sh
                </div>
            </div>
        </div>

        <!-- Android -->
        <div class="bento__card" data-platform="android">
            <div class="bento__card-inner">
                <div class="pi">
                    <svg viewBox="0 0 24 24" fill="#3ddc84"><path d="M6 18c0 .55.45 1 1 1h1v3.5c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5V19h2v3.5c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5V19h1c.55 0 1-.45 1-1V8H6v10zM3.5 8C2.67 8 2 8.67 2 9.5v7c0 .83.67 1.5 1.5 1.5S5 17.33 5 16.5v-7C5 8.67 4.33 8 3.5 8zm17 0c-.83 0-1.5.67-1.5 1.5v7c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5v-7c0-.83-.67-1.5-1.5-1.5zm-4.97-5.84l1.3-1.3c.2-.2.2-.51 0-.71-.2-.2-.51-.2-.71 0l-1.48 1.48A5.84 5.84 0 0012 1c-.96 0-1.86.23-2.66.63L7.85.15c-.2-.2-.51-.2-.71 0-.2.2-.2.51 0 .71l1.31 1.31A5.983 5.983 0 006 7h12c0-2.21-1.2-4.15-2.97-5.84zM10 5H9V4h1v1zm5 0h-1V4h1v1z"/></svg>
                </div>
                <div class="bento__title">Android</div>
                <div class="bento__desc">Secure VPN on your phone or tablet. Download directly from Google Play Store.</div>
                <a href="https://play.google.com/store/apps/details?id=io.netbird.client" class="bento__btn bento__btn--primary" target="_blank">
                    <svg viewBox="0 0 24 24" fill="currentColor"><path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 01-.61-.92V2.734a1 1 0 01.609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-1.4l2.584 1.496a1 1 0 010 1.394l-2.585 1.496-2.548-2.548 2.548-2.838zM5.864 2.658L16.8 8.99l-2.302 2.302-8.634-8.634z"/></svg>
                    Google Play
                </a>
            </div>
        </div>

        <!-- iOS -->
        <div class="bento__card" data-platform="ios">
            <div class="bento__card-inner">
                <div class="pi">
                    <svg viewBox="0 0 24 24" fill="#007aff"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                </div>
                <div class="bento__title">iPhone / iPad</div>
                <div class="bento__desc">Supports iOS 15 and above. Download from the App Store and connect instantly.</div>
                <a href="https://apps.apple.com/app/netbird-p2p-vpn/id6469329339" class="bento__btn bento__btn--primary" target="_blank">
                    <svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                    App Store
                </a>
            </div>
        </div>
    </div>

    <section class="guide">
        <div class="section-label"><span class="section-label__text">Setup Guide</span><div class="section-label__line"></div></div>
        <div class="guide__container">
            <div class="guide__header">
                <h2 class="guide__title">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M14.7 6.3a1 1 0 000 1.4l1.6 1.6a1 1 0 001.4 0l3.77-3.77a6 6 0 01-7.94 7.94l-6.91 6.91a2.12 2.12 0 01-3-3l6.91-6.91a6 6 0 017.94-7.94l-3.76 3.76z"/></svg>
                    How to Connect
                </h2>
                <p class="guide__subtitle">Choose your platform and follow the steps — connected in under 2 minutes.</p>
            </div>
            <div class="guide__tabs">
                <button class="guide__tab guide__tab--active" onclick="switchTab('desktop')" data-tab="desktop">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg> Desktop
                </button>
                <button class="guide__tab" onclick="switchTab('mobile')" data-tab="mobile">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="5" y="2" width="14" height="20" rx="2"/><path d="M12 18h.01"/></svg> Mobile
                </button>
                <button class="guide__tab" onclick="switchTab('linux')" data-tab="linux">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg> Linux (Terminal)
                </button>
            </div>
            <div class="guide__content">
                <div class="guide__panel guide__panel--active" id="panel-desktop">
                    <div class="step"><div class="step__number">1</div><div class="step__body"><h4>Download & Install the Client</h4><p>Download the installer for your OS above and run it (Windows: .exe, macOS: .pkg).</p></div></div>
                    <div class="step"><div class="step__number">2</div><div class="step__body"><h4>Set the Management URL</h4><p>Open the app's <strong>Settings</strong> and paste this URL:</p><div class="url-box"><span class="url-box__url">https://${DOMAIN}</span><button class="url-box__copy" onclick="copyText('https://${DOMAIN}',this)">Copy</button></div></div></div>
                    <div class="step"><div class="step__number">3</div><div class="step__body"><h4>Log In & Connect</h4><p>Click <strong>Connect</strong> — a login page opens in your browser. Enter your <strong>email</strong> and <strong>password</strong>, and you're securely connected!</p></div></div>
                </div>
                <div class="guide__panel" id="panel-mobile">
                    <div class="step"><div class="step__number">1</div><div class="step__body"><h4>Install the App</h4><p><strong>Android:</strong> Search "NetBird" on Google Play Store<br><strong>iOS:</strong> Search "NetBird" on the App Store</p></div></div>
                    <div class="step"><div class="step__number">2</div><div class="step__body"><h4>Set the Server URL</h4><p>Open the app → tap <strong>Settings</strong> → paste this into <strong>Management URL</strong>:</p><div class="url-box"><span class="url-box__url">https://${DOMAIN}</span><button class="url-box__copy" onclick="copyText('https://${DOMAIN}',this)">Copy</button></div></div></div>
                    <div class="step"><div class="step__number">3</div><div class="step__body"><h4>Connect!</h4><p>Go back to the main screen → toggle <strong>Connect</strong> on → log in with email & password → VPN is now active!</p></div></div>
                </div>
                <div class="guide__panel" id="panel-linux">
                    <div class="step"><div class="step__number">1</div><div class="step__body"><h4>Install NetBird</h4><p>Run this command in your terminal:</p><div class="cmd-block"><button class="cmd-block__copy" onclick="copyText('curl -fsSL https://pkgs.netbird.io/install.sh | sh',this)">Copy</button><span class="cmd-block__prompt">$</span> curl -fsSL https://pkgs.netbird.io/install.sh | sh</div></div></div>
                    <div class="step"><div class="step__number">2</div><div class="step__body"><h4>Connect to VPN</h4><p>After installation, run:</p><div class="cmd-block"><button class="cmd-block__copy" onclick="copyText('netbird up --management-url https://${DOMAIN}',this)">Copy</button><span class="cmd-block__prompt">$</span> netbird up --management-url https://${DOMAIN}</div></div></div>
                    <div class="step"><div class="step__number">3</div><div class="step__body"><h4>Authenticate in Browser</h4><p>A URL will appear in the terminal — open it in your browser and log in with your <strong>email & password</strong>. You'll see "connected" in the terminal.</p></div></div>
                    <div class="step"><div class="step__number">4</div><div class="step__body"><h4>Verify Connection</h4><p>Check your status anytime:</p><div class="cmd-block"><button class="cmd-block__copy" onclick="copyText('netbird status',this)">Copy</button><span class="cmd-block__prompt">$</span> netbird status</div></div></div>
                </div>
            </div>
        </div>
    </section>

    <section class="security">
        <div class="section-label"><span class="section-label__text">Why NetBird?</span><div class="section-label__line"></div></div>
        <div class="security__grid">
            <div class="security__item"><div class="security__icon"><svg viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="1.8" stroke-linecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg></div><div class="security__label">End-to-End Encrypted</div><div class="security__desc">Military-grade encryption powered by WireGuard® protocol</div></div>
            <div class="security__item"><div class="security__icon"><svg viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="1.8" stroke-linecap="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg></div><div class="security__label">Ultra Fast P2P</div><div class="security__desc">Direct peer-to-peer connections with no middleman</div></div>
            <div class="security__item"><div class="security__icon"><svg viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg></div><div class="security__label">Zero Trust Network</div><div class="security__desc">Every device is verified, every single time</div></div>
        </div>
    </section>

    <footer class="footer"><p class="footer__text">Powered by <span class="footer__brand">NetBird</span> · Self-Hosted Private Network</p></footer>
</div>

<script>
(function(){
    const ua=navigator.userAgent.toLowerCase(),p=navigator.platform?.toLowerCase()||'';
    const svgs={
        windows:'<svg viewBox="0 0 88 88" fill="none" width="48" height="48"><rect x="2" y="2" width="38" height="38" rx="4" fill="#00ADEF"/><rect x="48" y="2" width="38" height="38" rx="4" fill="#00ADEF"/><rect x="2" y="48" width="38" height="38" rx="4" fill="#00ADEF"/><rect x="48" y="48" width="38" height="38" rx="4" fill="#00ADEF"/></svg>',
        macos:'<svg viewBox="0 0 24 24" fill="#a855f7" width="48" height="48"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>',
        linux:'<svg viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" width="48" height="48"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>',
        android:'<svg viewBox="0 0 24 24" fill="#3ddc84" width="48" height="48"><path d="M6 18c0 .55.45 1 1 1h1v3.5c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5V19h2v3.5c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5V19h1c.55 0 1-.45 1-1V8H6v10zM3.5 8C2.67 8 2 8.67 2 9.5v7c0 .83.67 1.5 1.5 1.5S5 17.33 5 16.5v-7C5 8.67 4.33 8 3.5 8zm17 0c-.83 0-1.5.67-1.5 1.5v7c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5v-7c0-.83-.67-1.5-1.5-1.5zm-4.97-5.84l1.3-1.3c.2-.2.2-.51 0-.71-.2-.2-.51-.2-.71 0l-1.48 1.48A5.84 5.84 0 0012 1c-.96 0-1.86.23-2.66.63L7.85.15c-.2-.2-.51-.2-.71 0-.2.2-.2.51 0 .71l1.31 1.31A5.983 5.983 0 006 7h12c0-2.21-1.2-4.15-2.97-5.84zM10 5H9V4h1v1zm5 0h-1V4h1v1z"/></svg>',
        ios:'<svg viewBox="0 0 24 24" fill="#007aff" width="48" height="48"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>'
    };
    let os=null;
    if(/android/.test(ua))os={name:'Android',svg:svgs.android,btn:'Download for Android',url:'https://play.google.com/store/apps/details?id=io.netbird.client',p:'android'};
    else if(/iphone|ipad|ipod/.test(ua))os={name:'iOS',svg:svgs.ios,btn:'Download for iOS',url:'https://apps.apple.com/app/netbird-p2p-vpn/id6469329339',p:'ios'};
    else if(/win/.test(p)||/windows/.test(ua))os={name:'Windows',svg:svgs.windows,btn:'Download for Windows',url:'https://pkgs.netbird.io/windows/x64',p:'windows'};
    else if(/mac/.test(p)||/macintosh/.test(ua))os={name:'macOS',svg:svgs.macos,btn:'Download for macOS',url:'https://pkgs.netbird.io/macos/amd64',p:'macos'};
    else if(/linux/.test(p)||/linux/.test(ua))os={name:'Linux',svg:svgs.linux,btn:'Install on Linux',url:'#bento-grid',p:'linux'};
    if(os){
        document.getElementById('detected-section').style.display='';
        document.getElementById('detected-icon').innerHTML=os.svg;
        document.getElementById('detected-os').textContent=os.name;
        document.getElementById('detected-btn-text').textContent=os.btn;
        document.getElementById('detected-btn').href=os.url;
        const c=document.querySelector('[data-platform="'+os.p+'"]');
        if(c){c.style.order='-1';c.style.borderColor='rgba(245,119,34,.2)';}
    }
})();

function switchTab(t){
    document.querySelectorAll('.guide__tab').forEach(x=>x.classList.remove('guide__tab--active'));
    document.querySelectorAll('.guide__panel').forEach(x=>x.classList.remove('guide__panel--active'));
    document.querySelector('[data-tab="'+t+'"]').classList.add('guide__tab--active');
    document.getElementById('panel-'+t).classList.add('guide__panel--active');
}
function copyText(t,b){navigator.clipboard.writeText(t).then(()=>{const o=b.textContent;b.textContent='Copied ✓';b.style.color='#22c55e';setTimeout(()=>{b.textContent=o;b.style.color='';},2000);})}
document.querySelectorAll('.bento__card').forEach(c=>{c.addEventListener('mousemove',e=>{const r=c.getBoundingClientRect();c.style.setProperty('--mx',((e.clientX-r.left)/r.width*100)+'%');c.style.setProperty('--my',((e.clientY-r.top)/r.height*100)+'%');})});
if('IntersectionObserver' in window){const o=new IntersectionObserver(e=>{e.forEach(x=>{if(x.isIntersecting){x.target.style.opacity='1';x.target.style.transform='translateY(0)';o.unobserve(x.target);}});},{threshold:.1});document.querySelectorAll('.guide,.security').forEach(el=>{el.style.opacity='0';el.style.transform='translateY(30px)';el.style.transition='opacity .6s,transform .6s';o.observe(el);})}
</script>
</body>
</html>
EOF

# 9. Write docker-compose.yml
echo "Writing docker-compose.yml..."
cat > docker-compose.yml <<EOF
services:
  # Traefik reverse proxy (automatic TLS via Let's Encrypt)
  traefik:
    image: traefik:v3.6
    container_name: netbird-traefik
    restart: unless-stopped
    networks:
      netbird:
        ipv4_address: 172.30.0.10
    command:
      - "--log.level=INFO"
      - "--accesslog=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=netbird"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.websecure.allowACMEByPass=true"
      - "--entrypoints.websecure.transport.respondingTimeouts.readTimeout=0"
      - "--entrypoints.websecure.transport.respondingTimeouts.writeTimeout=0"
      - "--entrypoints.websecure.transport.respondingTimeouts.idleTimeout=0"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--certificatesresolvers.letsencrypt.acme.email=\${LE_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--serverstransport.forwardingtimeouts.responseheadertimeout=0s"
      - "--serverstransport.forwardingtimeouts.idleconntimeout=0s"
    ports:
      - '443:443'
      - '80:80'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - netbird_traefik_letsencrypt:/letsencrypt
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"

  # Download page (public - no auth)
  download-page:
    image: nginx:alpine
    container_name: netbird-download
    restart: unless-stopped
    networks: [netbird]
    volumes:
      - ./download-page/index.html:/usr/share/nginx/html/index.html:ro
      - ./download-page/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    labels:
      - traefik.enable=true
      - traefik.http.routers.netbird-download.rule=Host(\`\${DOMAIN}\`) && PathPrefix(\`/download\`)
      - traefik.http.routers.netbird-download.entrypoints=websecure
      - traefik.http.routers.netbird-download.tls=true
      - traefik.http.routers.netbird-download.tls.certresolver=letsencrypt
      - traefik.http.routers.netbird-download.service=download-page
      - traefik.http.routers.netbird-download.priority=200
      - traefik.http.routers.netbird-download.middlewares=download-strip
      - traefik.http.middlewares.download-strip.stripprefix.prefixes=/download
      - traefik.http.services.download-page.loadbalancer.server.port=80
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "1"

  # UI dashboard (protected with Basic Auth)
  dashboard:
    image: netbirdio/dashboard:latest
    container_name: netbird-dashboard
    restart: unless-stopped
    networks: [netbird]
    env_file:
      - ./dashboard.env
    labels:
      - traefik.enable=true
      - traefik.http.routers.netbird-dashboard.rule=Host(\`\${DOMAIN}\`)
      - traefik.http.routers.netbird-dashboard.entrypoints=websecure
      - traefik.http.routers.netbird-dashboard.tls=true
      - traefik.http.routers.netbird-dashboard.tls.certresolver=letsencrypt
      - traefik.http.routers.netbird-dashboard.service=dashboard
      - traefik.http.routers.netbird-dashboard.priority=1
      # Basic Auth middleware - Dashboard lock
      - traefik.http.routers.netbird-dashboard.middlewares=dashboard-auth
      - "traefik.http.middlewares.dashboard-auth.basicauth.users=\${DASH_USER}:\${DASH_HASH_ESCAPED}"
      - traefik.http.services.dashboard.loadbalancer.server.port=80
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"

  # Combined server (Management + Signal + Relay + STUN)
  netbird-server:
    image: netbirdio/netbird-server:latest
    container_name: netbird-server
    restart: unless-stopped
    networks: [netbird]
    ports:
      - '3478:3478/udp'
    volumes:
      - netbird_data:/var/lib/netbird
      - ./config.yaml:/etc/netbird/config.yaml
    command: ["--config", "/etc/netbird/config.yaml"]
    labels:
      - traefik.enable=true
      - traefik.http.routers.netbird-grpc.rule=Host(\`\${DOMAIN}\`) && (PathPrefix(\`/signalexchange.SignalExchange/\`) || PathPrefix(\`/management.ManagementService/\`) || PathPrefix(\`/management.ProxyService/\`))
      - traefik.http.routers.netbird-grpc.entrypoints=websecure
      - traefik.http.routers.netbird-grpc.tls=true
      - traefik.http.routers.netbird-grpc.tls.certresolver=letsencrypt
      - traefik.http.routers.netbird-grpc.service=netbird-server-h2c
      - traefik.http.routers.netbird-grpc.priority=100
      - traefik.http.routers.netbird-backend.rule=Host(\`\${DOMAIN}\`) && (PathPrefix(\`/relay\`) || PathPrefix(\`/ws-proxy/\`) || PathPrefix(\`/api\`) || PathPrefix(\`/oauth2\`))
      - traefik.http.routers.netbird-backend.entrypoints=websecure
      - traefik.http.routers.netbird-backend.tls=true
      - traefik.http.routers.netbird-backend.tls.certresolver=letsencrypt
      - traefik.http.routers.netbird-backend.service=netbird-server
      - traefik.http.routers.netbird-backend.priority=100
      - traefik.http.services.netbird-server.loadbalancer.server.port=80
      - traefik.http.services.netbird-server-h2c.loadbalancer.server.port=80
      - traefik.http.services.netbird-server-h2c.loadbalancer.server.scheme=h2c
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"

volumes:
  netbird_data:
  netbird_traefik_letsencrypt:

networks:
  netbird:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/24
          gateway: 172.30.0.1
EOF

# 10. Start Docker Compose
echo "Starting NetBird containers..."
docker compose pull
docker compose up -d

echo "================================================="
echo "✅ Deployment Successful!"
echo "Your secure VPN dashboard is available at: https://${DOMAIN}"
echo "Your download page is available at:        https://${DOMAIN}/download"
echo "Login username: ${DASH_USER}"
echo "================================================="
