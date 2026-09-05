import { storage } from 'common/storage';

import { selectSettings } from '../settings/selectors';
import {
  ttsModelError,
  ttsModelLoading,
  ttsModelProgress,
  ttsModelReady,
  ttsQueueUpdate,
} from './actions';
import { TtsEngine } from './engine';
import { selectTts } from './selectors';

/**
 * Extracts readable text from a chat message payload.
 * Strips HTML tags and cleans up whitespace.
 */
function extractText(content: any): string {
  if (!content) {
    return '';
  }

  // content can be a string (text) or have an html property
  let raw = '';
  if (typeof content === 'string') {
    raw = content;
  } else if (content.html) {
    raw = content.html;
  } else if (content.text) {
    raw = content.text;
  } else {
    return '';
  }

  // Strip HTML tags
  const div = document.createElement('div');
  div.innerHTML = raw;
  const text = div.textContent || div.innerText || '';

  // Clean up whitespace
  return text.replace(/\s+/g, ' ').trim();
}

/**
 * Determines the message type from a chat message payload.
 * Reuses the same CSS-selector classification logic as the chat renderer.
 */
function getMessageType(content: any): string | null {
  if (!content || !content.html) {
    return null;
  }

  // The chat renderer classifies by checking CSS selectors against the
  // message HTML. We do a simplified version here by checking class names.
  const div = document.createElement('div');
  div.innerHTML = content.html;
  const firstChild = div.firstElementChild;
  if (!firstChild) {
    return null;
  }

  // Import these at the top would create a circular dep, so we inline
  // the class-to-type mapping that mirrors chat/constants.ts MESSAGE_TYPES
  const classMap: Record<string, string> = {
    say: 'localchat',
    emote: 'localchat',
    say_quote: 'localchat',
    radio: 'radio',
    alert: 'radio',
    xeno: 'hivemind',
    xenoqueen: 'hivemind',
    xenoleader: 'hivemind',
    ooc: 'ooc',
    adminooc: 'ooc',
    deadsay: 'deadchat',
    warning: 'warning',
    critical: 'warning',
    userdanger: 'warning',
    pm: 'adminpm',
    adminhelp: 'adminpm',
    danger: 'combat',
    attack: 'combat',
  };

  for (const cls of firstChild.classList) {
    if (classMap[cls]) {
      return classMap[cls];
    }
  }

  return 'unknown';
}

/**
 * Persists TTS-specific settings alongside the main panel settings.
 */
function saveTtsSettings(store) {
  const tts = selectTts(store.getState());
  const settings = selectSettings(store.getState());
  // Save TTS settings as part of the panel settings
  storage.set('panel-settings', {
    ...settings,
    tts: {
      enabled: tts.enabled,
      voiceId: tts.voiceId,
      volume: tts.volume,
      speed: tts.speed,
      ttsTypes: tts.ttsTypes,
    },
  });
}

export const ttsMiddleware = (store) => {
  const engine = new TtsEngine();

  engine.onProgress = (progress) => {
    store.dispatch(ttsModelProgress(progress));
  };

  engine.onStatus = (status, error?) => {
    if (status === 'loading') {
      store.dispatch(ttsModelLoading());
    } else if (status === 'ready') {
      store.dispatch(ttsModelReady());
    } else if (status === 'error') {
      store.dispatch(ttsModelError(error || 'Unknown error'));
    }
  };

  engine.onQueueUpdate = (length) => {
    store.dispatch(ttsQueueUpdate(length));
  };

  return (next) => (action) => {
    const { type, payload } = action;

    // When TTS is toggled on, load the model
    if (type === 'tts/toggle') {
      next(action);
      const tts = selectTts(store.getState());
      if (tts.enabled && !engine.isReady()) {
        engine.loadModel(tts.voiceId).catch(() => {
          // Error already dispatched by engine
        });
      } else if (!tts.enabled) {
        engine.stop();
      }
      saveTtsSettings(store);
      return;
    }

    // Update engine settings
    if (type === 'tts/setVolume') {
      next(action);
      engine.setVolume(payload);
      saveTtsSettings(store);
      return;
    }
    if (type === 'tts/setSpeed') {
      next(action);
      engine.setSpeed(payload);
      saveTtsSettings(store);
      return;
    }
    if (type === 'tts/setVoice') {
      next(action);
      // If the model is loaded and the voice language prefix changed,
      // we might need to reload — but Kokoro handles multi-voice
      // within the same model, so no reload needed.
      saveTtsSettings(store);
      return;
    }
    if (type === 'tts/toggleType') {
      next(action);
      saveTtsSettings(store);
      return;
    }

    // Intercept chat messages for TTS
    if (type === 'chat/message') {
      // Let the chat middleware handle the message first
      next(action);

      const tts = selectTts(store.getState());
      if (!tts.enabled || !engine.isReady()) {
        return;
      }

      // Parse the message payload
      let payloadObj;
      try {
        payloadObj = JSON.parse(payload);
      } catch {
        return;
      }

      const content = payloadObj.content;
      const messageType = getMessageType(content);

      // Check if this message type should be read
      if (!messageType || !tts.ttsTypes[messageType]) {
        return;
      }

      const text = extractText(content);
      if (!text || text.length < 2) {
        return;
      }

      engine.enqueue(text, tts.voiceId);
      return;
    }

    return next(action);
  };
};
