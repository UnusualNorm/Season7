const debug = Deno.env.get("DEBUG") === "true";
const script = await Deno.readTextFile("installer.ps1");
Deno.serve(
  { port: 1993 },
  async () =>
    new Response(debug ? await Deno.readTextFile("installer.ps1") : script),
);
