import WebSocket, { RawData } from "ws";
import { World } from ".";
import {Vector3} from "../math";
import { Item } from "./item";

type PacketCallback = (this: Turtle, obj: any) => void
interface TurtleSafetyNet {
    introduce: PacketCallback
    update_state: PacketCallback
}

interface TurtleState {
    fuel: number
    inventory: Item[]
    equip: {
        left: Item
        right: Item
    }
    position: { x: number, y: number, z: number }
}

export class Turtle {
    id = -1
    uid = -1
    net: TurtleSafetyNet = {
        introduce: this.introduce,
        update_state: this.updateState,
    }
    moveTo?: Vector3
    pos = new Vector3()
    inventory: Item[] = []
    fuel?: number

    constructor(public world: World, public ws: WebSocket) {
        this.ws.on("message", (data, bin) => this.receive(data, bin))
        this.ws.on("close", (code, reason) => this.close(code, reason))
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
        method.call(this, obj)
    }

    send(obj: any) {
        this.ws.send(JSON.stringify(obj))
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
        } catch {}
    }

    newPath(to: Vector3) {
        
    }
}
