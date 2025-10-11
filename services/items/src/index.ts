// src/index.ts
type Item = { id: number; name: string };

let items: Item[] = [{ id: 1, name: "first" }];

const PORT = Number(process.env.PORT || 8080);

function json(data: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(data), {
    headers: { "content-type": "application/json" },
    ...init,
  });
}

function notFound() {
  return json({ error: "not found" }, { status: 404 });
}

async function handle(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const { pathname } = url;

  if (pathname === "/health" && req.method === "GET") {
    return json({ status: "ok" });
  }

  if (pathname === "/items" && req.method === "GET") {
    return json({ items });
  }

  if (pathname === "/items" && req.method === "POST") {
    try {
      const body = (await req.json()) as Partial<Item>;
      if (!body?.name || typeof body.name !== "string") {
        return json({ error: "name required" }, { status: 400 });
      }
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

const server = Bun.serve({
  port: PORT,
  fetch: handle,
});

console.log(`items service listening on http://localhost:${server.port}`);
