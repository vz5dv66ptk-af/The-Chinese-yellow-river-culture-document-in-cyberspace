import { textToSpeech } from '@kit.CoreSpeechKit';

export class QingLuanVoice {
  private engine: textToSpeech.TextToSpeechEngine | null = null;
  private ready: boolean = false;
  private enabled: boolean = true;
  private busy: boolean = false;
  private seq: number = 0;
  private inited: boolean = false;
  private lastError: string = '';

  async init(): Promise<void> {
    if (this.inited && this.ready) {
      return;
    }
    this.inited = true;
    for (let attempt = 0; attempt < 3; attempt++) {
      const ok: boolean = await this.createOnce();
      if (ok) {
        this.ready = true;
        this.lastError = '';
        return;
      }
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 600);
      });
    }
    this.ready = false;
  }

  private async createOnce(): Promise<boolean> {
    try {
      const params: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1,
        extraParams: {
          'style': 'interaction-broadcast',
          'locate': 'CN',
          'name': 'huanghe-qingluan'
        }
      };
      const engine = await textToSpeech.createEngine(params);
      const listener: textToSpeech.SpeakListener = {
        onStart: (requestId: string, response: textToSpeech.StartResponse) => {
        },
        onComplete: (requestId: string, response: textToSpeech.CompleteResponse) => {
          this.busy = false;
        },
        onStop: (requestId: string, response: textToSpeech.StopResponse) => {
          this.busy = false;
        },
        onError: (requestId: string, errorCode: number, errorMessage: string) => {
          this.busy = false;
          this.lastError = 'code=' + errorCode + ' ' + errorMessage;
        }
      };
      engine.setListener(listener);
      this.engine = engine;
      return true;
    } catch (e) {
      this.engine = null;
      this.lastError = (e as Error)?.message ?? 'createEngine failed';
      return false;
    }
  }

  setEnabled(on: boolean): void {
    this.enabled = on;
    if (!on) {
      this.stop();
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  isReady(): boolean {
    return this.ready;
  }

  status(): string {
    if (!this.enabled) {
      return '语音已关闭';
    }
    if (!this.ready) {
      return this.lastError.length > 0 ? ('语音不可用：' + this.lastError) : '语音引擎未就绪';
    }
    return this.busy ? '正在朗读' : '语音就绪';
  }

  say(text: string): void {
    if (!this.enabled || !this.ready || this.engine === null) {
      return;
    }
    const clean: string = QingLuanVoice.clean(text);
    if (clean.length === 0) {
      return;
    }
    try {
      this.engine.stop();
    } catch (e) {
    }
    this.seq = this.seq + 1;
    const req: textToSpeech.SpeakParams = {
      requestId: 'ql-' + this.seq,
      extraParams: {
        'queueMode': 0,
        'speed': 1.0,
        'volume': 1.0,
        'pitch': 1.05,
        'languageContext': 'zh-CN',
        'audioType': 'pcm',
        'playType': 1
      }
    };
    try {
      this.engine.speak(clean, req);
      this.busy = true;
    } catch (e) {
      this.busy = false;
      this.lastError = (e as Error)?.message ?? 'speak failed';
    }
  }

  stop(): void {
    if (this.engine === null) {
      return;
    }
    try {
      this.engine.stop();
    } catch (e) {
    }
    this.busy = false;
  }

  release(): void {
    if (this.engine !== null) {
      try {
        this.engine.shutdown();
      } catch (e) {
      }
    }
    this.engine = null;
    this.ready = false;
    this.busy = false;
    this.inited = false;
  }

  private static clean(text: string): string {
    let t: string = text;
    t = t.replace(/[#>*`]/g, '');
    t = t.replace(/\r/g, '');
    t = t.replace(/\n+/g, '。');
    t = t.replace(/。{2,}/g, '。');
    t = t.replace(/·/g, '，');
    t = t.replace(/^[。，\s]+/, '');
    if (t.length > 260) {
      t = t.substring(0, 260);
    }
    return t;
  }
}
