import express, { Request, Response } from "express";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";

// A fresh server + transport pair is created per request: in stateless mode the
// Streamable HTTP transport is single-use, so sharing one instance makes every
// request after the first fail.
const createMcpServer = (): McpServer => {
  const server = new McpServer({
    name: "mcp-streamable-http",
    version: "1.0.0",
  });

  // Get Chuck Norris joke tool
  server.tool("get-chuck-joke", "Get a random Chuck Norris joke", async () => {
    const response = await fetch("https://api.chucknorris.io/jokes/random");
    const data = await response.json();
    return {
      content: [
        {
          type: "text",
          text: data.value,
        },
      ],
    };
  });

  // Get Chuck Norris joke by category tool
  server.tool(
    "get-chuck-joke-by-category",
    "Get a random Chuck Norris joke by category",
    async () => {
      const response = await fetch(
        "https://api.chucknorris.io/jokes/random?category=dev"
      );
      const data = await response.json();
      return {
        content: [
          {
            type: "text",
            text: data.value,
          },
        ],
      };
    }
  );

  // Get Chuck Norris joke categories tool
  server.tool(
    "get-chuck-categories",
    "Get all available categories for Chuck Norris jokes",
    async () => {
      const response = await fetch(
        "https://api.chucknorris.io/jokes/categories"
      );
      const data = await response.json();
      return {
        content: [
          {
            type: "text",
            text: data.join(", "),
          },
        ],
      };
    }
  );

  // Get Dad joke tool
  server.tool("get-dad-joke", "Get a random dad joke", async () => {
    const response = await fetch("https://icanhazdadjoke.com/", {
      headers: {
        Accept: "application/json",
      },
    });
    const data = await response.json();
    return {
      content: [
        {
          type: "text",
          text: data.joke,
        },
      ],
    };
  });

  return server;
};

const app = express();
app.use(express.json());

app.post("/mcp", async (req: Request, res: Response) => {
  console.log("Received MCP request:", req.body);
  const server = createMcpServer();
  const transport: StreamableHTTPServerTransport =
    new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined, // set to undefined for stateless servers
    });

  res.on("close", () => {
    void transport.close();
    void server.close();
  });

  try {
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  } catch (error) {
    console.error("Error handling MCP request:", error);
    if (!res.headersSent) {
      res.status(500).json({
        jsonrpc: "2.0",
        error: {
          code: -32603,
          message: "Internal server error",
        },
        id: null,
      });
    }
  }
});

app.get("/mcp", async (req: Request, res: Response) => {
  console.log("Received GET MCP request");
  res.writeHead(405).end(
    JSON.stringify({
      jsonrpc: "2.0",
      error: {
        code: -32000,
        message: "Method not allowed.",
      },
      id: null,
    })
  );
});

app.delete("/mcp", async (req: Request, res: Response) => {
  console.log("Received DELETE MCP request");
  res.writeHead(405).end(
    JSON.stringify({
      jsonrpc: "2.0",
      error: {
        code: -32000,
        message: "Method not allowed.",
      },
      id: null,
    })
  );
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`MCP Streamable HTTP Server listening on port ${PORT}`);
});
