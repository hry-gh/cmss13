import type { TtsState } from './types';
import { DEFAULT_TTS_TYPES } from './constants';

const initialState: TtsState = {
  enabled: false,
  voiceId: 'af_heart',
  volume: 0.5,
  speed: 1.0,
  modelStatus: 'unloaded',
  modelProgress: 0,
  errorMessage: null,
  queueLength: 0,
  ttsTypes: { ...DEFAULT_TTS_TYPES },
};

export const ttsReducer = (state = initialState, action) => {
  const { type, payload } = action;

  if (type === 'tts/toggle') {
    return {
      ...state,
      enabled: !state.enabled,
    };
  }
  if (type === 'tts/setVoice') {
    return {
      ...state,
      voiceId: payload,
    };
  }
  if (type === 'tts/setVolume') {
    return {
      ...state,
      volume: payload,
    };
  }
  if (type === 'tts/setSpeed') {
    return {
      ...state,
      speed: payload,
    };
  }
  if (type === 'tts/toggleType') {
    return {
      ...state,
      ttsTypes: {
        ...state.ttsTypes,
        [payload]: !state.ttsTypes[payload],
      },
    };
  }
  if (type === 'tts/modelLoading') {
    return {
      ...state,
      modelStatus: 'loading' as const,
      modelProgress: 0,
      errorMessage: null,
    };
  }
  if (type === 'tts/modelProgress') {
    return {
      ...state,
      modelProgress: payload,
    };
  }
  if (type === 'tts/modelReady') {
    return {
      ...state,
      modelStatus: 'ready' as const,
      modelProgress: 100,
    };
  }
  if (type === 'tts/modelError') {
    return {
      ...state,
      modelStatus: 'error' as const,
      errorMessage: payload,
    };
  }
  if (type === 'tts/queueUpdate') {
    return {
      ...state,
      queueLength: payload,
    };
  }
  // Restore TTS settings from persisted settings
  if (type === 'settings/load' || type === 'settings/import') {
    const ttsSettings = payload?.tts || payload?.newSettings?.tts;
    if (ttsSettings) {
      return {
        ...state,
        ...ttsSettings,
        // Never restore transient state
        modelStatus: 'unloaded' as const,
        modelProgress: 0,
        errorMessage: null,
        queueLength: 0,
      };
    }
  }

  return state;
};
