import WebSocket, { RawData } from "ws";
import { World } from ".";
import {Vector2, Vector3} from "../math";
import { Item } from "./item";
import {BlockState} from "./block";

type PacketCallback = (this: Turtle, obj: any) => void

const DIRECTIONS = {
    u: new Vector3(0, 1, 0),
    d: new Vector3(0, -1, 0),
    n: new Vector3(0, 0, -1),
    s: new Vector3(0, 0, 1),
    w: new Vector3(-1, 0, 0),
    e: new Vector3(1, 0, 0),
}

const SCAN_BLACKLIST = [
    "computercraft:turtle_expanded",
    "computercraft:turtle_advanced",
    "minecraft:air",
]

interface TurtleState {
    fuel: number
    inventory: Item[]
    equip: {
        left: Item
        right: Item
    }
    position: { x: number, y: number, z: number }
    direction: string
    state: string
}

type UpdateWorldData = {
    pos: { x: number, y: number, z: number }
    data: {
        name: string
        metadata: number
    }
}

export class Turtle {
    id = -1
    uid = -1
    net: { [x: string]: PacketCallback }  = {
        introduce: this.introduce,
        update_state: this.updateState,
        update_world: this.updateWorld,
        request_path: this.requestPath,
        log: this.log,
    }
    pos = new Vector3()
    inventory: Item[] = []
    fuel?: number
    direction = "unknown"
    state = "idle"

    received = 0
    sent = 0
    netstat = {
        received: {} as Record<string, number>,
        sent: {} as Record<string, number>
    }

    constructor(public world: World, public ws: WebSocket) {
        this.ws.on("message", (data, bin) => this.receive(data, bin))
        this.ws.on("close", (code, reason) => this.close(code, reason))

        this.send({ id: "introduce" })
    }

    close(code: number, reason: Buffer) {
        console.log(`Turtle ${this.uid} (sid: ${this.id}) closing: ${code} ${reason.toString()}`)
        this.world.remove(this)
    }

    receive(data: RawData, bin: boolean) {
        if (bin) return
        const str = data.toString()
        const obj = JSON.parse(str)
        
        if (obj == undefined) return
        if (!("id" in obj)) return
        const method = (this.net as any)[obj.id]

        if (method === undefined) return
        if (typeof method !== "function") return
        
        this.received++
        this.netstat.received[obj.id] = (this.netstat.received[obj.id] ?? 0) + 1
        method.call(this, obj)
    }

    send(obj: any) {
        this.sent++
        this.netstat.sent[obj.id] = (this.netstat.sent[obj.id] ?? 0) + 1
        this.ws.send(JSON.stringify(obj))
    }

    sendData(id: string, data: any) {
        this.send({ id, data })
    }

    introduce(obj: any) {
        if (typeof obj.data !== "number") return
        this.id = obj.data
        this.uid = this.world.server.currentUid++
        console.log(`Turtle ${this.uid} (sid: ${this.id}) joined.`)
    }

    updateState(obj: any) {
        if (typeof obj.data !== "object") return
        const state = obj.data as TurtleState
        try {
            const pos = state.position
            this.pos.x = pos.x
            this.pos.y = pos.y
            this.pos.z = pos.z

            this.inventory = state.inventory
            this.fuel = state.fuel
            this.direction = state.direction
            this.state = state.state
        } catch {}
    }

    updateWorld(obj: any) {
        if (obj.data === undefined) return
        // oh my god
        (async () => {
            for (const data of (obj.data as UpdateWorldData[])) {
                await this.world.setBlock(
                    new Vector3(
                        data.pos.x,
                        data.pos.y,
                        data.pos.z,
                    ),
                    (data.data !== undefined && !SCAN_BLACKLIST.includes(data.data.name)) ? new BlockState(data.data.name, data.data.metadata ?? 0) : undefined
                )

            }
        })().catch(e => console.log(`Failed to update world: ${e}`))
    }

    requestPath(obj: any) {
        if (typeof obj.data !== "object") return
        this.findPath(new Vector3(obj.data.x, obj.data.y, obj.data.z))
    }
    
    log(obj: any) {
        console.log(`Turtle ${this.uid}: ${obj.data}`)
    }

    async findPath(moveTo: Vector3) {
        const block = await this.world.getBlock(moveTo)
        if (moveTo.equals(this.pos) || block !== undefined) {
            if (block !== undefined) {
                console.log(`Turtle ${this.uid}: Block is full: ${moveTo.toString()}`)
            }
            this.send({ id: "path_calculated", error: "Goal is invalid" })
            return
        }

        let pathTo = new Vector3(
            moveTo.x,
            moveTo.y,
            moveTo.z
        ) 
        if (moveTo.y < 0) {
            const height = await this.world.getHeight(new Vector2(
                moveTo.x,
                moveTo.z
            ))
            let targetY = 0
            if (height !== undefined)
                targetY = height + 1
            else if (moveTo.y === -1)
                targetY = this.pos.y
            pathTo.y = targetY
        }
        const path = await this.world.searchPath(this.pos, pathTo)
        
        if (path === undefined) {
            console.log(`Turtle ${this.uid}: failed to find viable path.`)
            this.send({ id: "path_calculated", error: "Failed to find viable path" })
            return
        }
        let data = ""

        let lastPoint = path[0]
        for (let i = 1; i < path.length; i++) {
            const point = path[i]
            const delta = point.subv(lastPoint)
            lastPoint = point

            let direction
            for (const [dir, v] of Object.entries(DIRECTIONS)) {
                if (v.equals(delta)) {
                    direction = dir
                }
            }
            data += direction ?? ""
        }

        // console.log(`Using ${data.length} fuel.`)

        if (data.length > (this.fuel ?? 0)) {
            console.log(`Turtle ${this.uid} does not have enough fuel. Aborting path.`)
            return
        }
        this.sendData("path_calculated", data)
    }
}
