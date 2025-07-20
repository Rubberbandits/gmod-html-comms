export interface Gmod {
    call: (uid: string, key: string, ...args: any[]) => void;
}

export class LuaCall {
    private uid: string;

    constructor() {
        this.uid = this.randomUid();
    }

    private randomUid(): string {
        let randomString = "";
        crypto.getRandomValues(new Uint8Array(8)).forEach((byte) => {
            randomString += byte.toString(16);
        });
      
        return `lua_call_${randomString}`;
    }

    call(key: string, ...args: any[]): Promise<any> {
        return new Promise((resolve, reject) => {
            if (gmod == undefined) {
                reject(new Error("Gmod object is not available"));
                return;
            }

            gmod.call(this.uid, key, ...args, (data: any | any[]) => {
                // Complex type
                if (typeof data === 'object') {
                    if (data.error) {
                        reject(new Error(data.error));
                        this.uid = this.randomUid(); // Reset uid for next call
                    } else if (data.callback) {
                        if (!window.callbacks) {
                            window.callbacks = {};
                        }

                        window.callbacks[this.uid] = (jsonData: string) => {
                            let data = JSON.parse(jsonData) as any[];
                            if (data.length === 0) {
                                resolve([]);
                                return;
                            }

                            let error = data[0].error;
                            if (error) {
                                reject(new Error(error));
                            } else {
                                resolve(data);
                            }

                            delete window.callbacks[this.uid];
                            this.uid = this.randomUid(); // Reset uid for next call
                        };
                    } else {
                        resolve(data);
                        this.uid = this.randomUid(); // Reset uid for next call
                    }
                } else { // Simple type, e.g. string, number, boolean
                    resolve(data);
                    this.uid = this.randomUid(); // Reset uid for next call
                }
            });
        });
    }
}

export type PlayerType = {
    type: "player";
    value: number;
};

export class Player {
    player: PlayerType;

    constructor(p: PlayerType) {
        this.player = p;
    }

    async getName(): Promise<string> {
        const lua = new LuaCall();
        return await lua.call("Player.GetName", this.player) as string;
    }
}

export async function LocalPlayer(): Promise<Player> {
    const lua = new LuaCall();
    const data = await lua.call("Player.GetLocalPlayer") as PlayerType;
    return new Player(data);
}

export interface Entity {
    type: "entity";
    value: number;
}

export interface Vector {
    type: "vector";
    value: { x: number; y: number; z: number };
}

export interface Angle {
    type: "angle";
    value: { p: number; y: number; r: number };
}

export interface Color {
    type: "color";
    value: { r: number; g: number; b: number; a: number };
}
