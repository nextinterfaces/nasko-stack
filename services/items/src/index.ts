// src/index.ts
type Item = { id: number; name: string };

let items: Item[] = [{ id: 1, name: "first" }];

const PORT = Number(process.env.PORT || 8080);
const API_PREFIX = "/v1";

function json(data: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(data), {
    headers: { "content-type": "application/json" },
    ...init,
  });
}

function notFound() {
  return json({ error: "not found" }, { status: 404 });
}

const openapi = {
  openapi: "3.0.3",
  info: { title: "items API", version: "1.0.0", description: "Simple items service built with Bun" },
  servers: [{ url: API_PREFIX }],
  paths: {
    "/health": {
      get: {
        summary: "Health check",
        responses: {
          "200": {
            description: "OK",
            content: { "application/json": { schema: { type: "object", properties: { status: { type: "string" } } } } },
          },
        },
      },
    },
    "/items": {
      get: {
        summary: "List items",
        responses: {
          "200": {
            description: "Array of items",
            content: { "application/json": { schema: { type: "object", properties: { items: { type: "array", items: { $ref: "#/components/schemas/Item" } } } } } },
          },
        },
      },
      post: {
        summary: "Create item",
        requestBody: {
          required: true,
          content: { "application/json": { schema: { type: "object", properties: { name: { type: "string" } }, required: ["name"] } } },
        },
        responses: {
          "201": { description: "Created", content: { "application/json": { schema: { $ref: "#/components/schemas/Item" } } } },
          "400": { description: "Invalid input" },
        },
      },
    },
  },
  components: {
    schemas: { Item: { type: "object", properties: { id: { type: "integer" }, name: { type: "string" } }, required: ["id", "name"] } },
  },
} as const;

const swaggerHtml = `<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>items API – Swagger UI</title>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
  </head>
  <body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
      window.onload = () => {
        window.ui = SwaggerUIBundle({ url: '${API_PREFIX}/openapi.json', dom_id: '#swagger-ui' });
      };
    </script>
  </body>
</html>`;

const swaggerResponse = new Response(swaggerHtml, { headers: { "content-type": "text/html; charset=utf-8" } });

async function handle(req: Request): Promise<Response> {
  const url = new URL(req.url);
  let path = url.pathname;

  // Swagger UI & OpenAPI JSON
  if (path === "/docs" && req.method === "GET") return swaggerResponse;
  if (path === `${API_PREFIX}/openapi.json` && req.method === "GET") return json(openapi);

  if (!path.startsWith(API_PREFIX)) return notFound();
  path = path.slice(API_PREFIX.length) || "/";

  if (path === "/health" && req.method === "GET") return json({ status: "ok" });
  if (path === "/items" && req.method === "GET") return json({ items });

  if (path === "/items" && req.method === "POST") {
    try {
      const body = (await req.json()) as Partial<Item>;
      if (!body?.name || typeof body.name !== "string") return json({ error: "name required" }, { status: 400 });
      const nextId = (items.at(-1)?.id ?? 0) + 1;
      const item = { id: nextId, name: body.name };
      items.push(item);
      return json(item, { status: 201 });
    } catch {
      return json({ error: "invalid json" }, { status: 400 });
    }
  }

  return notFound();
}

const server = Bun.serve({ port: PORT, fetch: handle });
console.log(`items service listening on http://localhost:${server.port}`);
console.log(`Swagger UI: http://localhost:${server.port}/docs`);
