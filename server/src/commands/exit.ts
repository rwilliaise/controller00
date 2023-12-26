import { Server } from "../server";

export default function exit(server: Server, args: string[]) {
    server.world.save()
        .finally(() => process.exit(parseInt(args[0] ?? "0")))
}
