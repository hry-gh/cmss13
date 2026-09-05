import { toFixed } from 'common/math';
import { Button, LabeledList, ProgressBar, Section, Slider, Stack } from 'tgui/components';

import { MESSAGE_TYPES } from '../chat/constants';
import { TTS_VOICES } from './constants';
import { useTts } from './hooks';

export function TtsSettings() {
  const tts = useTts();

  const voiceLabel =
    TTS_VOICES.find((v) => v.id === tts.voiceId)?.name || tts.voiceId;

  // Filter to only non-admin message types that TTS can handle
  const ttsMessageTypes = MESSAGE_TYPES.filter(
    (mt) => !mt.admin && mt.type !== 'system' && mt.type !== 'unknown',
  );

  return (
    <Section>
      <LabeledList>
        <LabeledList.Item label="Text to Speech">
          <Button
            icon={tts.enabled ? 'volume-up' : 'volume-mute'}
            selected={tts.enabled}
            color={tts.enabled ? 'good' : 'default'}
            onClick={() => tts.toggle()}
          >
            {tts.enabled ? 'Enabled' : 'Disabled'}
          </Button>
        </LabeledList.Item>

        {tts.enabled && (
          <>
            <LabeledList.Item label="Model Status">
              {tts.modelStatus === 'loading' && (
                <ProgressBar
                  value={tts.modelProgress}
                  maxValue={100}
                  color="blue"
                >
                  Downloading model... {tts.modelProgress}%
                </ProgressBar>
              )}
              {tts.modelStatus === 'ready' && (
                <Button icon="check" color="good" disabled>
                  Model loaded
                </Button>
              )}
              {tts.modelStatus === 'error' && (
                <Stack>
                  <Stack.Item>
                    <Button icon="exclamation-triangle" color="bad" disabled>
                      Error: {tts.errorMessage}
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="redo" onClick={() => tts.toggle()}>
                      Retry
                    </Button>
                  </Stack.Item>
                </Stack>
              )}
              {tts.modelStatus === 'unloaded' && (
                <Button icon="download" color="default" disabled>
                  Model will load when enabled
                </Button>
              )}
            </LabeledList.Item>

            <LabeledList.Item label="Voice">
              {TTS_VOICES.map((voice) => (
                <Button
                  key={voice.id}
                  selected={tts.voiceId === voice.id}
                  color="transparent"
                  onClick={() => tts.setVoice(voice.id)}
                >
                  {voice.name}
                </Button>
              ))}
            </LabeledList.Item>

            <LabeledList.Item label="Volume">
              <Slider
                width="100%"
                step={0.01}
                minValue={0}
                maxValue={1}
                value={tts.volume}
                format={(value) => `${Math.round(value * 100)}%`}
                onDrag={(e, value) => tts.setVolume(value)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Speed">
              <Slider
                width="100%"
                step={0.1}
                minValue={0.5}
                maxValue={2.0}
                value={tts.speed}
                format={(value) => `${toFixed(value, 1)}x`}
                onDrag={(e, value) => tts.setSpeed(value)}
              />
            </LabeledList.Item>

            <LabeledList.Item label="Read message types">
              <Stack wrap>
                {ttsMessageTypes.map((mt) => (
                  <Stack.Item key={mt.type}>
                    <Button
                      selected={!!tts.ttsTypes[mt.type]}
                      color="transparent"
                      tooltip={mt.description}
                      onClick={() => tts.toggleType(mt.type)}
                    >
                      {mt.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </LabeledList.Item>

            {tts.queueLength > 0 && (
              <LabeledList.Item label="Queue">
                {tts.queueLength} message(s) pending
              </LabeledList.Item>
            )}
          </>
        )}
      </LabeledList>
    </Section>
  );
}
