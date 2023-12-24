
export class Vector2 {
    constructor(public x = 0, public y = 0) {}

    toString() {
        return `${this.x} ${this.y}`
    }

    equals(that: Vector3) {
        return this.x === that.x &&
            this.y == that.y
    }
}

export class Vector3 {
    constructor(public x = 0, public y = 0, public z = 0) {}

    static fromString(str: string): Vector3 {
        const split = str.split(" ")
        return new Vector3(
            parseInt(split[0]),
            parseInt(split[1]),
            parseInt(split[2]),
        )
    }

    toString() {
        return `${this.x} ${this.y} ${this.z}`
    }

    equals(that: Vector3) {
        return this.x === that.x &&
            this.y == that.y &&
            this.z == that.z
    }

    add(x = 0, y = 0, z = 0) {
        return new Vector3(this.x + x, this.y + y, this.z + z)
    }
}

