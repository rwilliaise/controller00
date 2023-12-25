import { Server } from "../server";

export default function exit(server: Server, args: string[]) {
    process.exit(parseInt(args[0] ?? "0"))
}
