import {Server} from "../server";

export default async function save(server: Server, args: string[]) {
    await server.world.save()
}
