import { createAction } from 'common/redux';

export const toggleTts = createAction('tts/toggle');
export const setTtsVoice = createAction('tts/setVoice');
export const setTtsVolume = createAction('tts/setVolume');
export const setTtsSpeed = createAction('tts/setSpeed');
export const toggleTtsType = createAction('tts/toggleType');
export const ttsModelLoading = createAction('tts/modelLoading');
export const ttsModelReady = createAction('tts/modelReady');
export const ttsModelError = createAction('tts/modelError');
export const ttsModelProgress = createAction('tts/modelProgress');
export const ttsQueueUpdate = createAction('tts/queueUpdate');
