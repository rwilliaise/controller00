import { Server } from "../server";
import * as readline from "node:readline/promises"
import { stdin as input, stdout as output } from "node:process"

import turtles from "./turtles";
import exit from "./exit";
import kick from "./kick";

type CommandsList = { [x: string]: ((server: Server, args: string[]) => void) | ((server: Server, args: string[]) => Promise<void>) }

export class Commands {
    commands: CommandsList = {
        turtles,
        exit,
        kick,
    }
    interface = readline.createInterface({
        input,
        output,
        prompt: "> "
    })

    constructor(public server: Server) {
        this.interface.on("line", async i => {
            await this.run(i)
            this.interface.prompt()
        })
        this.interface.prompt()
    }

    async run(input: string) {
        const args = input.trim().split(" ")
        const command = args[0]
        if (command === undefined) return
        if (!(command in this.commands)) {
            console.log(`Command ${command} not found.`)
            return
        }
        await Promise.resolve(this.commands[command](this.server, args.slice(1)))
    }
}
