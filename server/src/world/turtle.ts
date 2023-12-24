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
}

export class Turtle {
    id = -1
    uid = -1
    net: TurtleSafetyNet = {
        introduce: this.introduce,
        update_state: this.updateState,
    }
    pos = new Vector3()

    constructor(private world: World, private ws: WebSocket) {
        this.ws.on("message", (data, bin) => this.receive(data, bin))
    }

    receive(data: RawData, bin: boolean) {
        if (bin) return
        const str = data.toString()
        const obj = JSON.parse(str)

        console.log(obj)
        
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
    }

    updateState(obj: any) {
        if (typeof obj.data !== "object") return
        if (typeof obj.data.position !== "object") return
        const pos = obj.data.position
        this.pos.x = pos.x
        this.pos.y = pos.y
        this.pos.z = pos.z

        this.send({ id: "follow_path", path: this.world.searchPath(this.pos, this.pos.add(25, 10, 15)) })
    }

    newPath() {

    }
}
