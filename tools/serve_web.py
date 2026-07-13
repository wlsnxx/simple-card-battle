#!/usr/bin/env python3
"""Serve o build web local para teste em navegador/celular da rede.

Uso:
    python tools/serve_web.py [--port 8082] [--dir godot/build/web]

- HTTPS automático se tools/cert.pem + tools/key.pem existirem
  (gere com tools/scripts/generate_cert.sh — iOS Safari exige HTTPS
  para features como Web Share API e service workers).
- gzip on-the-fly para .wasm/.pck/.js (builds Godot são grandes).
- Cache desabilitado (sempre serve a build mais recente).
"""
import argparse
import gzip
import http.server
import os
import ssl
import sys

GZIP_TYPES = {".wasm", ".pck", ".js", ".html", ".json"}


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        # Descomente para builds multi-thread (COOP/COEP). A build
        # single-thread (recomendada p/ iOS Safari) NÃO precisa.
        # self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        # self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def send_head(self):
        path = self.translate_path(self.path)
        ext = os.path.splitext(path)[1]
        if ext in GZIP_TYPES and os.path.isfile(path) and "gzip" in self.headers.get("Accept-Encoding", ""):
            with open(path, "rb") as f:
                data = gzip.compress(f.read(), compresslevel=6)
            self.send_response(200)
            self.send_header("Content-Type", self.guess_type(path))
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            import io
            return io.BytesIO(data)
        return super().send_head()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8082)
    ap.add_argument("--dir", default="godot/build/web")
    args = ap.parse_args()

    if not os.path.isdir(args.dir):
        print(f"❌ build não encontrada em {args.dir} — exporte a preset Web antes.")
        return 1
    os.chdir(args.dir)

    httpd = http.server.ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    scheme = "http"
    cert = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cert.pem")
    key = os.path.join(os.path.dirname(os.path.abspath(__file__)), "key.pem")
    if os.path.exists(cert) and os.path.exists(key):
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(cert, key)
        httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
        scheme = "https"

    print(f"🌐 Servindo {os.getcwd()} em {scheme}://localhost:{args.port}")
    print(f"   No celular (mesma rede): {scheme}://<IP-desta-máquina>:{args.port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
