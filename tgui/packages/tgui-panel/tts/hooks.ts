import { useDispatch, useSelector } from 'tgui/backend';

import {
  setTtsSpeed,
  setTtsVoice,
  setTtsVolume,
  toggleTts,
  toggleTtsType,
} from './actions';
import { selectTts } from './selectors';

export const useTts = () => {
  const state = useSelector(selectTts);
  const dispatch = useDispatch();
  return {
    ...state,
    toggle: () => dispatch(toggleTts()),
    setVoice: (voiceId: string) => dispatch(setTtsVoice(voiceId)),
    setVolume: (volume: number) => dispatch(setTtsVolume(volume)),
    setSpeed: (speed: number) => dispatch(setTtsSpeed(speed)),
    toggleType: (messageType: string) => dispatch(toggleTtsType(messageType)),
  };
};
