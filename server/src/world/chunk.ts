import { Vector3 } from "../math";
import { BlockState } from "./block";

export const CHUNK_HEIGHT = 256
export const CHUNK_WIDTH = 16

export class Chunk {
    palette = new Map<number, BlockState>()
    blocks: number[] = []

    getBlock(pos: Vector3): BlockState | undefined {
        const pid = this.blocks[pos.z * CHUNK_WIDTH * CHUNK_HEIGHT + pos.y * CHUNK_WIDTH + pos.x]
        if (pid === undefined) return undefined
        return this.palette.get(pid)
    }

    setBlock(pos: Vector3, state: BlockState) {
        
    }

    
}

