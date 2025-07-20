export class Channel {
    private channelName: string;
    constructor(channelName: string) {
        this.channelName = channelName;
    }

    getName(): string {
        return this.channelName;
    }

    private listeners: { [event: string]: ((...args: any[]) => void)[] } = {};

    addListener(event: string, callback: (...args: any[]) => void): void {
        if (!this.listeners[event]) {
            this.listeners[event] = [];
        }
        this.listeners[event].push(callback);
    }

    removeListener(event: string, callback: (...args: any[]) => void): void {
        if (!this.listeners[event]) return;

        this.listeners[event] = this.listeners[event].filter(listener => listener !== callback);
    }

    emit(event: string, data: string): void {
        if (!this.listeners[event]) return;

        const args = JSON.parse(data);
        this.listeners[event].forEach(listener => listener(...args));
    }

    once(event: string, callback: (...args: any[]) => void): void {
        const onceWrapper = (...args: any[]) => {
            callback(...args);
            this.removeListener(event, onceWrapper);
        };
        this.addListener(event, onceWrapper);
    }
}
