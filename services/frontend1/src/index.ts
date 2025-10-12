// A tiny static file server with a proxy to your Bun items backend.
// - Serves ./index.html at http://localhost:8081
// - Proxies /v1/* -> BACKEND_ORIGIN/v1/*
//
// TLS note:
// If your BACKEND_ORIGIN uses a self-signed/invalid cert, you can set
//   INSECURE_TLS=1
// to skip verification for the proxy request (Bun's fetch supports TLS options).
// Prefer adding a proper CA bundle in production.

const STATIC_PORT = Number(process.env.FRONTEND_PORT || 8081);
// const BACKEND_ORIGIN = process.env.BACKEND_ORIGIN || "http://localhost:8080";
const BACKEND_ORIGIN = process.env.BACKEND_ORIGIN || "https://items.5.78.158.102.sslip.io";

const INSECURE_TLS = process.env.INSECURE_TLS === "1";

function notFound() {
  return new Response("Not found", { status: 404 });
}

async function proxy(req: Request) {
  const url = new URL(req.url);
  const target = BACKEND_ORIGIN + url.pathname + (url.search || "");

  // Forward method/headers/body to backend.
  // When INSECURE_TLS=1, pass Bun TLS options to skip cert verification.
  const init: RequestInit & { tls?: any } = {
    method: req.method,
    headers: req.headers,
    body: req.body,
    // Important for streaming bodies
    // @ts-ignore - Bun supports 'duplex' on RequestInit
    duplex: "half",
  };

  if (INSECURE_TLS) {
    // Bun-specific TLS options for fetch
    init.tls = { rejectUnauthorized: false };
  }

  return fetch(target, init);
}

function serveFile(path: string, type = "text/html") {
  try {
    const file = Bun.file(path);
    return new Response(file, { headers: { "content-type": type } });
  } catch {
    return notFound();
  }
}

const handle: (req: Request) => Promise<Response> | Response = async (req) => {
  const url = new URL(req.url);
  const path = url.pathname;

  // Proxy all /v1/* requests to the backend
  if (path.startsWith("/v1/") || path === "/v1") {
    return proxy(req);
  }

  // Serve index.html and any static assets
  if (path === "/" || path === "/index.html") {
    return serveFile(import.meta.dir + "/index.html", "text/html; charset=utf-8");
  }

  return notFound();
};

const server = Bun.serve({ port: STATIC_PORT, fetch: handle });
console.log(`Frontend available at http://localhost:${server.port}`);
console.log(`Proxying /v1 -> ${BACKEND_ORIGIN}/v1 (INSECURE_TLS=${INSECURE_TLS ? "1" : "0"})`);
