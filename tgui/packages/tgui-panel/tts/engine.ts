/**
 * TTS Engine - wraps kokoro-js for browser-based text-to-speech.
 *
 * Handles lazy model loading, sequential playback queue,
 * and volume/speed control.
 */

import { KOKORO_DEVICE, KOKORO_DTYPE, KOKORO_MODEL_ID, TTS_MAX_QUEUE } from './constants';

type ProgressCallback = (progress: number) => void;
type StatusCallback = (status: string, error?: string) => void;
type QueueCallback = (length: number) => void;

export class TtsEngine {
  private tts: any = null;
  private queue: Array<{ text: string; voice: string }> = [];
  private processing = false;
  private volume = 0.5;
  private speed = 1.0;
  private currentAudio: HTMLAudioElement | null = null;

  onProgress: ProgressCallback = () => {};
  onStatus: StatusCallback = () => {};
  onQueueUpdate: QueueCallback = () => {};

  async loadModel(voiceId: string): Promise<void> {
    if (this.tts) {
      return;
    }

    this.onStatus('loading');

    try {
      // Dynamic import so the module is only loaded when TTS is enabled
      const { KokoroTTS } = await import(
        /* webpackChunkName: "tts-kokoro" */ 'kokoro-js'
      );

      this.tts = await KokoroTTS.from_pretrained(KOKORO_MODEL_ID, {
        dtype: KOKORO_DTYPE,
        device: KOKORO_DEVICE,
        progress_callback: (progress: any) => {
          if (progress.status === 'progress' && progress.total) {
            const pct = Math.round((progress.loaded / progress.total) * 100);
            this.onProgress(pct);
          }
        },
      });

      this.onStatus('ready');
    } catch (err) {
      this.tts = null;
      const message = err instanceof Error ? err.message : String(err);
      this.onStatus('error', message);
      throw err;
    }
  }

  enqueue(text: string, voice: string): void {
    // Drop messages if the queue is too long to avoid falling behind
    if (this.queue.length >= TTS_MAX_QUEUE) {
      return;
    }

    this.queue.push({ text, voice });
    this.onQueueUpdate(this.queue.length);
    this.processQueue();
  }

  private async processQueue(): Promise<void> {
    if (this.processing || !this.tts || this.queue.length === 0) {
      return;
    }

    this.processing = true;

    while (this.queue.length > 0) {
      const item = this.queue.shift()!;
      this.onQueueUpdate(this.queue.length);

      try {
        const audio = await this.tts.generate(item.text, {
          voice: item.voice,
          speed: this.speed,
        });

        const wavBytes = audio.toWav();
        const blob = new Blob([wavBytes], { type: 'audio/wav' });
        const url = URL.createObjectURL(blob);

        await this.playAudio(url);
        URL.revokeObjectURL(url);
      } catch (err) {
        // Log but don't break the queue
        console.error('[TTS] Generation failed:', err);
      }
    }

    this.processing = false;
    this.onQueueUpdate(0);
  }

  private playAudio(url: string): Promise<void> {
    return new Promise((resolve) => {
      const audio = new Audio(url);
      audio.volume = this.volume;
      this.currentAudio = audio;

      audio.addEventListener('ended', () => {
        this.currentAudio = null;
        resolve();
      });

      audio.addEventListener('error', () => {
        this.currentAudio = null;
        resolve();
      });

      audio.play().catch(() => {
        this.currentAudio = null;
        resolve();
      });
    });
  }

  setVolume(volume: number): void {
    this.volume = volume;
    if (this.currentAudio) {
      this.currentAudio.volume = volume;
    }
  }

  setSpeed(speed: number): void {
    this.speed = speed;
  }

  stop(): void {
    this.queue = [];
    this.onQueueUpdate(0);
    if (this.currentAudio) {
      this.currentAudio.pause();
      this.currentAudio = null;
    }
  }

  isReady(): boolean {
    return this.tts !== null;
  }

  /**
   * Unloads the model to free memory.
   */
  unload(): void {
    this.stop();
    this.tts = null;
    this.onStatus('unloaded');
  }
}
