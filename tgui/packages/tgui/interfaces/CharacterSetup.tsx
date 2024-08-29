import { randomInteger } from 'common/random';
import { capitalizeFirst } from 'common/string';
import {
  createContext,
  Dispatch,
  PropsWithChildren,
  SetStateAction,
  useContext,
  useState,
} from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  ColorBox,
  Flex,
  LabeledList,
  Modal,
  Section,
} from '../components';
import { Window } from '../layouts';

interface CharacterSetupProps {
  real_name: string;
  be_random_name: boolean;
  be_random_body: boolean;
  age: string;
  gender: string;
  skin_color: string;
  body_size: string;
  body_type: string;
  hair_style: string;
  hair_color: string;
  gradient_style: string;
  gradient_color: string;
  facial_hair_style: string;
  facial_hair_color: string;
  eye_color: string;
  underwear: string;
  undershirt: string;
  bag: string;
  preferred_armor: string;
  show_job_gear: boolean;
  origin: string;
  religion: string;
  corporate_relation: string;
  preferred_squad: string;
  flavor_text?: string;
  medical_record?: string;
  security_record?: string;
  employment_record?: string;

  xeno_prefix: string;
  xeno_postfix: string;
  playtime_perks: boolean;
  xeno_night_vision_level: string;

  be_xeno_after_unrevivably_dead: boolean;
  be_agent: boolean;

  commander_status: string;
  commander_sidearm: string;
  commander_affiliation: string;

  synthetic_name: string;
  synthetic_type: string;
  synthetic_status: string;

  predator_name: string;
  predator_gender: string;
  predator_age: string;
  predator_hair_style: string;
  predator_skin_color: string;
  predator_flavor_text: string;
  predator_status: string;

  predator_use_legacy: string;
  predator_translator_type: string;
  predator_mask_type: string;
  predator_armor_type: string;
  predator_boot_type: string;
  predator_mask_material: string;
  predator_greave_material: string;
  predator_caster_material: string;
  predator_cape_type: string;
  predator_cape_color: string;

  hotkeys_mode: boolean;
  tgui_say: boolean;
  tgui_say_light_mode: boolean;
  ui_style: string;
  ui_style_color: string;
  ui_style_alpha: number;
  stylesheet: string;
  hide_statusbar: boolean;
  no_radials: boolean;
  no_radial_labels: boolean;
  ooc_flag: boolean;
  view_mc: boolean;
  membership_publicity: boolean;
  ghost_ears: boolean;
  ghost_sight: boolean;
  ghost_radio: boolean;
  ghost_spy_radio: boolean;
  ghost_hivemind: boolean;
  langchat: boolean;
  langchat_emotes: boolean;

  ambient_occlusion: boolean;
  auto_fit_viewport: boolean;
  adaptive_zoom: boolean;
  tooltips: boolean;
  tgui_fancy: boolean;
  tgui_lock: boolean;
  hear_admin_sounds: boolean;
  hear_observer_announcements: boolean;
  hear_faxes: boolean;
  hear_lobby_music: boolean;
  hear_vox: boolean;

  hurt_self: boolean;
  help_intent_safety: boolean;
  middle_mouse_click: boolean;
  ability_deactivation: boolean;
  directional_assist: boolean;
  magazine_autoeject: boolean;
  magazine_autoeject_to_hand: boolean;
  combat_clickdrag_override: boolean;
  middle_mouse_swap_hands: boolean;
  vend_item_to_hand: boolean;
  semi_auto_display_limiter: boolean;
}

enum MenuOptions {
  Human = 'Human',
  Xenomorph = 'Xenomorph',
  CommandingOfficer = 'Commanding Officer',
  Synthetic = 'Synthetic',
  Yautja = 'Yautja',
  Settings = 'Settings',
  SpecialRoles = 'Special Roles',
}

enum PopupOptions {
  CharacterRecords = 'characterrecords',
}

interface ContextInterface {
  setActiveModal: Dispatch<SetStateAction<PopupOptions> | undefined>;
}

const CharacterSetupContext = createContext<ContextInterface>({
  setActiveModal: () => {},
});

interface MenuInterface {
  active: string;
  setActive: (_) => void;
}

const CharacterMenu = createContext<MenuInterface>({
  active: '',
  setActive: () => {},
});

const CharacterSetupButton = (props: { readonly title: MenuOptions }) => {
  const { title } = props;
  const { active, setActive } = useContext(CharacterMenu);
  return (
    <Button disabled={active === title} onClick={() => setActive(title)}>
      {title}
    </Button>
  );
};

export const CharacterSetup = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  const [menu, setMenu] = useState<MenuOptions>(MenuOptions.Human);

  const [modal, setModal] = useState<PopupOptions>();

  console.log(setModal);

  return (
    <Window height={1032} width={1000}>
      <Window.Content className="CharacterSetup">
        <CharacterSetupContext.Provider value={{ setActiveModal: setModal }}>
          <CharacterMenu.Provider value={{ active: menu, setActive: setMenu }}>
            {modal && (
              <Modal>
                <Button onClick={() => setModal(undefined)}>X</Button>
                {PopupToComponent[modal]()}
              </Modal>
            )}
            <Section>
              <Flex direction="row" justify="center">
                <Button>Load Slot</Button>
                <Button>Save Slot</Button>
                <Button>Reload Slot</Button>
              </Flex>
            </Section>
            <Section>
              <Flex direction="row" justify="center">
                <CharacterSetupButton title={MenuOptions.Human} />
                <CharacterSetupButton title={MenuOptions.Xenomorph} />
                <CharacterSetupButton title={MenuOptions.CommandingOfficer} />
                <CharacterSetupButton title={MenuOptions.Synthetic} />
                <CharacterSetupButton title={MenuOptions.Yautja} />
                <CharacterSetupButton title={MenuOptions.Settings} />
                <CharacterSetupButton title={MenuOptions.SpecialRoles} />
              </Flex>
            </Section>
            {MenuToComponent[menu](setModal)}
          </CharacterMenu.Provider>
        </CharacterSetupContext.Provider>
      </Window.Content>
    </Window>
  );
};

interface SettingsProps extends PropsWithChildren {
  readonly title: string;
}

const SettingsBlock = (props: SettingsProps) => {
  const { title, children } = props;

  return (
    <Flex.Item className="settingsBlock">
      <Box className="title">{title}</Box>
      {children}
    </Flex.Item>
  );
};

const formatText = (fluffText?: string) => {
  if (!fluffText) return 'Empty';
  if (fluffText.length < 50) return fluffText;
  return fluffText.substring(0, 50) + '...';
};

const CharacterRecords = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Box>
      <LabeledList>
        <LabeledList.Item
          labelWrap
          label="Medical Records"
          buttons={<Button>Edit</Button>}
        >
          {formatText(data.medical_record)}
        </LabeledList.Item>
        <LabeledList.Item
          labelWrap
          label="Employment Records"
          buttons={<Button>Edit</Button>}
        >
          {formatText(data.employment_record)}
        </LabeledList.Item>
        <LabeledList.Item
          labelWrap
          label="Security Records"
          buttons={<Button>Edit</Button>}
        >
          {formatText(data.security_record)}
        </LabeledList.Item>
      </LabeledList>
    </Box>
  );
};

const HumanMenu = (setModal: (_) => void) => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Human">
      <Flex>
        <Flex.Item style={{ width: '33%' }}>
          <Flex direction="column">
            <SettingsBlock title="Biographical Information">
              <LabeledList>
                <LabeledList.Item label="Name">
                  <Button>{data.real_name}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Always Pick Random Name">
                  <Button>{data.be_random_name ? 'Yes' : 'No'}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Always Pick Random Appearance">
                  <Button>{data.be_random_body ? 'Yes' : 'No'}</Button>
                </LabeledList.Item>
              </LabeledList>
            </SettingsBlock>
            <SettingsBlock title="Physical Information">
              <LabeledList>
                <LabeledList.Item label="Age">
                  <Button>{data.age}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Gender">
                  <Button>{capitalizeFirst(data.gender)}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Skin Color">
                  <Button>{data.skin_color}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Body Size">
                  <Button>{data.body_size}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Body Muscularity">
                  <Button>{data.body_type}</Button>
                </LabeledList.Item>
              </LabeledList>
            </SettingsBlock>
          </Flex>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <Flex direction="column">
            <SettingsBlock title="Hair and Eyes">
              <LabeledList>
                <LabeledList.Item label="Hair">
                  <Button>{data.hair_style}</Button>
                  <Button>
                    <ColorBox color={`#${data.hair_color}`} />
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="Facial Hair">
                  <Button>{data.facial_hair_style}</Button>
                  <Button>
                    <ColorBox color={`#${data.facial_hair_color}`} />
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="Eye">
                  <Button>
                    <ColorBox color={`#${data.eye_color}`} />
                  </Button>
                </LabeledList.Item>
              </LabeledList>
            </SettingsBlock>
            <SettingsBlock title="Marine Gear">
              <LabeledList>
                <LabeledList.Item label="Underwear">
                  <Button>{data.underwear}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Undershirt">
                  <Button>{data.undershirt}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Backpack Type">
                  <Button>{data.bag}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Preferred Armor">
                  <Button>{data.preferred_armor}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Show Job Gear">
                  <Button>{data.show_job_gear ? 'Yes' : 'No'}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Background">
                  <Button>Cycle Background</Button>
                </LabeledList.Item>
              </LabeledList>
            </SettingsBlock>
          </Flex>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <Flex direction="column">
            <SettingsBlock title="Background Information">
              <LabeledList>
                <LabeledList.Item label="Origin">
                  <Button>{data.origin}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Religion">
                  <Button>{data.religion}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Corporate Relation">
                  <Button>{data.corporate_relation}</Button>
                </LabeledList.Item>
                <LabeledList.Item label="Preferred Squad">
                  <Button>{data.preferred_squad}</Button>
                </LabeledList.Item>
              </LabeledList>
            </SettingsBlock>
            <SettingsBlock title="Fluff Information">
              <LabeledList>
                <LabeledList.Item label="Records">
                  <Button
                    onClick={() => setModal(PopupOptions.CharacterRecords)}
                  >
                    Character Records
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="Flavor Text">
                  <Button>{formatText(data.flavor_text)}</Button>
                </LabeledList.Item>
              </LabeledList>
            </SettingsBlock>
          </Flex>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const XenoMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Xenomorph">
      <Flex>
        <Flex.Item style={{ width: '50%' }}>
          <SettingsBlock title="Xenomorph Information">
            <LabeledList>
              <LabeledList.Item label="Xeno prefix">
                <Button>{data.xeno_prefix}</Button>
              </LabeledList.Item>
              <LabeledList.Item label="Xeno postfix">
                <Button>{data.xeno_postfix ?? 'Empty'}</Button>
              </LabeledList.Item>
              <LabeledList.Item label="Enable Playtime Perks">
                <Button>{data.playtime_perks ? 'Yes' : 'No'}</Button>
              </LabeledList.Item>
              <LabeledList.Item label="Default Xeno Night Vision Level">
                <Button>{data.xeno_night_vision_level}</Button>
              </LabeledList.Item>
              <LabeledList.Item label="Xeno Name">
                {`${data.xeno_prefix}-${randomInteger(0, 999)}${data.xeno_postfix ?? ''}`}
              </LabeledList.Item>
            </LabeledList>
          </SettingsBlock>
        </Flex.Item>
        <Flex.Item style={{ width: '50%' }}>
          <SettingsBlock title="Occupation Choices">
            <LabeledList>
              <LabeledList.Item label="Be Xenomorph after unrevivably dead">
                <Button>
                  {data.be_xeno_after_unrevivably_dead ? 'Yes' : 'No'}
                </Button>
              </LabeledList.Item>
              <LabeledList.Item label="Be Agent">
                <Button>{data.be_agent ? 'Yes' : 'No'}</Button>
              </LabeledList.Item>
            </LabeledList>
          </SettingsBlock>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const CommandingOfficerMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Commanding Officer">
      <SettingsBlock title="Commander Settings">
        <LabeledList>
          <LabeledList.Item label="Commander Whitelist Status">
            <Button>{data.commander_status}</Button>
          </LabeledList.Item>
          <LabeledList.Item label="Commander Sidearm">
            <Button>{data.commander_sidearm}</Button>
          </LabeledList.Item>
          <LabeledList.Item label="Commander Affiliation">
            <Button>{data.commander_affiliation ?? 'Unaligned'}</Button>
          </LabeledList.Item>
        </LabeledList>
      </SettingsBlock>
    </Section>
  );
};

const SyntheticMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Synthetic">
      <Box>foo bar</Box>
    </Section>
  );
};

const YautjaMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Yautja">
      <Box>foo bar</Box>
    </Section>
  );
};

const SettingsMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Settings">
      <Box>foo bar</Box>
    </Section>
  );
};

const SpecialRolesMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Special Roles">
      <Box>foo bar</Box>
    </Section>
  );
};

const MenuToComponent: { [key in MenuOptions] } = {
  [MenuOptions.Human]: HumanMenu,
  [MenuOptions.Xenomorph]: XenoMenu,
  [MenuOptions.CommandingOfficer]: CommandingOfficerMenu,
  [MenuOptions.Synthetic]: SyntheticMenu,
  [MenuOptions.Yautja]: YautjaMenu,
  [MenuOptions.Settings]: SettingsMenu,
  [MenuOptions.SpecialRoles]: SpecialRolesMenu,
};

const PopupToComponent: { [key in PopupOptions]: () => React.JSX.Element } = {
  [PopupOptions.CharacterRecords]: CharacterRecords,
};
