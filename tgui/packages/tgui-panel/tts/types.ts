export type TtsState = {
  enabled: boolean;
  voiceId: string;
  volume: number;
  speed: number;
  modelStatus: 'unloaded' | 'loading' | 'ready' | 'error';
  modelProgress: number;
  errorMessage: string | null;
  queueLength: number;
  ttsTypes: Record<string, boolean>;
};
