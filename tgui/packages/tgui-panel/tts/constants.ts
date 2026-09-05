import {
  MESSAGE_TYPE_ADMINPM,
  MESSAGE_TYPE_DEADCHAT,
  MESSAGE_TYPE_HIVEMIND,
  MESSAGE_TYPE_LOCALCHAT,
  MESSAGE_TYPE_OOC,
  MESSAGE_TYPE_RADIO,
  MESSAGE_TYPE_WARNING,
} from '../chat/constants';

// Message types that TTS will read by default
export const DEFAULT_TTS_TYPES: Record<string, boolean> = {
  [MESSAGE_TYPE_LOCALCHAT]: true,
  [MESSAGE_TYPE_RADIO]: true,
  [MESSAGE_TYPE_HIVEMIND]: true,
  [MESSAGE_TYPE_OOC]: false,
  [MESSAGE_TYPE_DEADCHAT]: false,
  [MESSAGE_TYPE_WARNING]: false,
  [MESSAGE_TYPE_ADMINPM]: true,
};

// Max queued messages before we start dropping
export const TTS_MAX_QUEUE = 5;

// Kokoro model config
export const KOKORO_MODEL_ID = 'onnx-community/Kokoro-82M-v1.0-ONNX';
export const KOKORO_DTYPE = 'q8';
export const KOKORO_DEVICE = 'wasm';

// Available voices (English subset for sanity)
export const TTS_VOICES = [
  { id: 'af_heart', name: 'Heart (Female, US)', lang: 'en-US' },
  { id: 'af_bella', name: 'Bella (Female, US)', lang: 'en-US' },
  { id: 'af_nicole', name: 'Nicole (Female, US)', lang: 'en-US' },
  { id: 'af_sarah', name: 'Sarah (Female, US)', lang: 'en-US' },
  { id: 'af_sky', name: 'Sky (Female, US)', lang: 'en-US' },
  { id: 'af_nova', name: 'Nova (Female, US)', lang: 'en-US' },
  { id: 'am_adam', name: 'Adam (Male, US)', lang: 'en-US' },
  { id: 'am_michael', name: 'Michael (Male, US)', lang: 'en-US' },
  { id: 'am_eric', name: 'Eric (Male, US)', lang: 'en-US' },
  { id: 'am_liam', name: 'Liam (Male, US)', lang: 'en-US' },
  { id: 'bf_emma', name: 'Emma (Female, UK)', lang: 'en-GB' },
  { id: 'bf_isabella', name: 'Isabella (Female, UK)', lang: 'en-GB' },
  { id: 'bm_daniel', name: 'Daniel (Male, UK)', lang: 'en-GB' },
  { id: 'bm_george', name: 'George (Male, UK)', lang: 'en-GB' },
];
