/// <reference types="vite/client" />

import { Gmod } from './gmod';

declare global {
  const gmod: Gmod;

  interface Window {
    callbacks: { [key: string]: (jsonData: string) => void };
  }
}
