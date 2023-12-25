import { Server } from "../server";

export default function turtles(server: Server, args: string[]) {
    let table: { [x: string]: object } = {}
    for (const turtle of server.turtles) {
        table[`Turtle ${turtle.uid}`] = {
            fuel: turtle.fuel ?? "unknown",
            position: turtle.pos.toString(),
            direction: turtle.direction,
            inventory: `${turtle.inventory.reduce(
                (n, c) => c.name !== undefined ? n + 1 : n,
                0
            )} item(s)`,
        }
    }
    console.table(table)
}
