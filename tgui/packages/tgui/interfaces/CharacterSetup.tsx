import { randomInteger } from 'common/random';
import { capitalizeFirst } from 'common/string';
import {
  createContext,
  Dispatch,
  PropsWithChildren,
  ReactNode,
  SetStateAction,
  useContext,
  useState,
} from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  ByondUi,
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
  predator_armor_material: string;
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
  custom_cursors: boolean;
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
  adaptive_zoom: number;
  tooltips: boolean;
  tgui_fancy: boolean;
  tgui_lock: boolean;
  hear_admin_sounds: boolean;
  hear_observer_announcements: boolean;
  hear_faxes: boolean;
  hear_lobby_music: boolean;
  hear_vox: boolean;
  ghost_nightvision: string;

  hurt_self: boolean;
  help_intent_safety: boolean;
  middle_mouse_click: boolean;
  ability_deactivation: boolean;
  directional_assist: boolean;
  magazine_autoeject: boolean;
  magazine_autoeject_to_hand: boolean;
  magazine_eject_to_hand: boolean;
  combat_clickdrag_override: boolean;
  auto_punctuation: boolean;
  middle_mouse_swap_hands: boolean;
  vend_item_to_hand: boolean;
  semi_auto_display_limiter: boolean;

  play_leader: boolean;
  play_medic: boolean;
  play_engineer: boolean;
  play_heavy: boolean;
  play_smartgunner: boolean;
  play_synth: boolean;
  play_misc: boolean;
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
            <ByondUi
              height="30em"
              params={{
                id: 'preview',
                type: 'map',
              }}
            />
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
  readonly buttons?: ReactNode;
}

const SettingsBlock = (props: SettingsProps) => {
  const { title, children, buttons } = props;

  return (
    <Flex.Item className="settingsBlock">
      <Box className="title">
        {title} {buttons}
      </Box>
      <LabeledList>{children}</LabeledList>
    </Flex.Item>
  );
};

const formatText = (fluffText?: string) => {
  if (!fluffText) return 'Empty';
  if (fluffText.length < 50) return fluffText;
  return fluffText.substring(0, 50) + '...';
};

const SettingsItem = (props: {
  readonly label: string;
  readonly value?: string;
  readonly to_act?: string;
  readonly children?: React.JSX.Element;
}) => {
  const { act } = useBackend();

  const { label, value, to_act, children } = props;

  return (
    <LabeledList.Item label={label}>
      {value && (
        <Button onClick={() => (to_act ? act(to_act) : {})}>{value}</Button>
      )}
      {children}
    </LabeledList.Item>
  );
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
            <SettingsBlock
              title="Biographical Information"
              buttons={<Button>®</Button>}
            >
              <SettingsItem label="Name" value={data.real_name} />
              <SettingsItem
                label="Always Pick Random Name"
                value={formatBoolean(data.be_random_name)}
              />
              <SettingsItem
                label="Always Pick Random Appearance"
                value={formatBoolean(data.be_random_body)}
              />
            </SettingsBlock>
            <SettingsBlock
              title="Physical Information"
              buttons={<Button>®</Button>}
            >
              <SettingsItem label="Age" value={data.age} />
              <SettingsItem
                label="Gender"
                value={capitalizeFirst(data.gender)}
              />
              <SettingsItem label="Skin Color" value={data.skin_color} />
              <SettingsItem label="Body Size" value={data.body_size} />
              <SettingsItem label="Body Muscularity" value={data.body_type} />
            </SettingsBlock>
          </Flex>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <Flex direction="column">
            <SettingsBlock title="Hair and Eyes">
              <SettingsItem label="Hair" value={data.hair_style}>
                <Button>
                  <ColorBox color={`#${data.hair_color}`} />
                </Button>
              </SettingsItem>
              <SettingsItem label="Facial Hair" value={data.facial_hair_style}>
                <Button>
                  <ColorBox color={`#${data.facial_hair_color}`} />
                </Button>
              </SettingsItem>
              <SettingsItem label="Eye">
                <Button>
                  <ColorBox color={`#${data.eye_color}`} />
                </Button>
              </SettingsItem>
            </SettingsBlock>
            <SettingsBlock title="Marine Gear">
              <SettingsItem label="Underwear" value={data.underwear} />
              <SettingsItem label="Undershirt" value={data.undershirt} />
              <SettingsItem label="Backpack Type" value={data.bag} />
              <SettingsItem
                label="Preferred Armor"
                value={data.preferred_armor}
              />
              <SettingsItem
                label="Show Job Gear"
                value={formatBoolean(data.show_job_gear)}
              />
              <SettingsItem label="Background" value="Cycle Background" />
            </SettingsBlock>
          </Flex>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <Flex direction="column">
            <SettingsBlock title="Background Information">
              <SettingsItem label="Origin" value={data.origin} />
              <SettingsItem label="Religion" value={data.religion} />
              <SettingsItem
                label="Corporate Relation"
                value={data.corporate_relation}
              />
              <SettingsItem
                label="Preferred Squad"
                value={data.preferred_squad}
              />
            </SettingsBlock>
            <SettingsBlock title="Fluff Information">
              <SettingsItem label="Records">
                <Button onClick={() => setModal(PopupOptions.CharacterRecords)}>
                  Character Records
                </Button>
              </SettingsItem>
              <SettingsItem
                label="Flavor Text"
                value={formatText(data.flavor_text)}
              />
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
            <SettingsItem label="Xeno prefix" value={data.xeno_prefix} />
            <SettingsItem
              label="Xeno postfix"
              value={data.xeno_postfix ?? 'Empty'}
            />
            <SettingsItem
              label="Enable Playtime Perks"
              value={formatBoolean(data.playtime_perks)}
            />
            <SettingsItem
              label="Default Xeno Night Vision Level"
              value={data.xeno_night_vision_level}
            />
            <SettingsItem
              label="Xeno Name"
              value={`${data.xeno_prefix}-${randomInteger(0, 999)}${data.xeno_postfix ?? ''}`}
            />
          </SettingsBlock>
        </Flex.Item>
        <Flex.Item style={{ width: '50%' }}>
          <SettingsBlock title="Occupation Choices">
            <SettingsItem
              label="Be Xenomorph after unrevivably dead"
              value={formatBoolean(data.be_xeno_after_unrevivably_dead)}
            />
            <SettingsItem
              label="Be Agent"
              value={formatBoolean(data.be_agent)}
            />
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
        <SettingsItem
          label="Commander Whitelist Status"
          value={data.commander_status}
        />
        <SettingsItem
          label="Commander Sidearm"
          value={data.commander_sidearm}
        />
        <SettingsItem
          label="Commander Affiliation"
          value={data.commander_affiliation ?? 'Unaligned'}
        />
      </SettingsBlock>
    </Section>
  );
};

const SyntheticMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Synthetic">
      <SettingsBlock title="Synthetic Settings">
        <SettingsItem label="Synthetic Name" value={data.synthetic_name} />
        <SettingsItem label="Synthetic Type" value={data.synthetic_type} />
        <SettingsItem
          label="Synthetic Whitelist Status"
          value={data.synthetic_status}
        />
      </SettingsBlock>
    </Section>
  );
};

const YautjaMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Yautja">
      <Flex>
        <Flex.Item style={{ width: '33%' }}>
          <SettingsBlock title="Yautja Information">
            <SettingsItem label="Yautja Name" value={data.predator_name} />
            <SettingsItem
              label="Yautja Gender"
              value={capitalizeFirst(data.predator_gender)}
            />
            <SettingsItem label="Yautja Age" value={data.predator_age} />
            <SettingsItem
              label="Yautja Quill Style"
              value={data.predator_hair_style}
            />
            <SettingsItem
              label="Yautja Skin Color"
              value={data.predator_skin_color}
            />
            <SettingsItem
              label="Yautja Flavor Text"
              value={formatText(data.predator_flavor_text)}
            />
            <SettingsItem
              label="Yautja Whitelist Status"
              value={data.predator_status}
            />
          </SettingsBlock>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <SettingsBlock title="Equipment Setup">
            <SettingsItem
              label="Legacy Gear"
              value={data.predator_use_legacy}
            />
            <SettingsItem
              label="Translator Type"
              value={data.predator_translator_type}
            />
            <SettingsItem label="Mask Style" value={data.predator_mask_type} />
            <SettingsItem
              label="Armor Style"
              value={data.predator_armor_type}
            />
            <SettingsItem
              label="Greave Style"
              value={data.predator_boot_type}
            />
            <SettingsItem
              label="Mask Material"
              value={data.predator_mask_material}
            />
            <SettingsItem
              label="Armor Material"
              value={data.predator_armor_material}
            />
            <SettingsItem
              label="Greave Material"
              value={data.predator_greave_material}
            />
            <SettingsItem
              label="Caster Material"
              value={data.predator_caster_material}
            />
          </SettingsBlock>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <SettingsBlock title="Clothing Setup">
            <SettingsItem label="Cape Type" value={data.predator_cape_type} />
            <SettingsItem label="Cape Color">
              <Button>
                <ColorBox color={data.predator_cape_color} />
              </Button>
            </SettingsItem>
            <SettingsItem label="Background" value="Cycle Background" />
          </SettingsBlock>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const formatBoolean = (bool: boolean) => {
  return bool ? 'Yes' : 'No';
};

const SettingsMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Settings">
      <Flex>
        <Flex.Item style={{ width: '33%' }}>
          <SettingsBlock title="Input Settings">
            <SettingsItem
              label="Mode"
              value={data.hotkeys_mode ? 'Hotkeys Mode' : 'Send to Chat'}
            />
            <SettingsItem label="Keybinds" value="View Keybinds" />
            <SettingsItem
              label="Say Input Style"
              value={data.tgui_say ? 'Modern (default)' : 'Legacy'}
            />
            <SettingsItem
              label="Say Input Color"
              value={
                data.tgui_say_light_mode ? 'Darkmode (default)' : 'Lightmode'
              }
            />
          </SettingsBlock>
          <SettingsBlock title="UI Customization">
            <SettingsItem label="Style" value={data.ui_style} />
            <SettingsItem label="Color" value={data.ui_style_color}>
              <ColorBox color={data.ui_style_color} />
            </SettingsItem>
            <SettingsItem label="Alpha" value={`${data.ui_style_alpha}`} />
            <SettingsItem label="Stylesheet" value={data.stylesheet} />
            <SettingsItem
              label="Hide Statusbar"
              value={formatBoolean(data.hide_statusbar)}
            />
            <SettingsItem
              label="No radial menus"
              value={formatBoolean(data.no_radials)}
            />
            <SettingsItem
              label="No radial labels"
              value={formatBoolean(data.no_radial_labels)}
            />
            <SettingsItem
              label="Custom cursors"
              value={formatBoolean(data.custom_cursors)}
            />
          </SettingsBlock>
          <SettingsBlock title="Chat Settings">
            <SettingsItem
              label="View MC Tab"
              value={formatBoolean(data.view_mc)}
            />
            <SettingsItem
              label="BYOND Membership Shown"
              value={formatBoolean(data.membership_publicity)}
            />
            <SettingsItem
              label="Ghost Ears"
              value={formatBoolean(data.ghost_ears)}
            />
            <SettingsItem
              label="Ghost Sight"
              value={formatBoolean(data.ghost_sight)}
            />
            <SettingsItem
              label="Ghost Radio"
              value={formatBoolean(data.ghost_radio)}
            />
            <SettingsItem
              label="Ghost Spy Radio"
              value={formatBoolean(data.ghost_spy_radio)}
            />
            <SettingsItem
              label="Ghost Hivemind"
              value={formatBoolean(data.ghost_hivemind)}
            />
            <SettingsItem
              label="Abovehead Chat"
              value={formatBoolean(!data.langchat)}
            />
            <SettingsItem
              label="Abovehead Emotes"
              value={formatBoolean(data.langchat_emotes)}
            />
          </SettingsBlock>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <SettingsBlock title="Game Settings">
            <SettingsItem
              label="Ambient Occlusion"
              value={formatBoolean(data.ambient_occlusion)}
            />
            <SettingsItem
              label="Auto Fit Viewport"
              value={formatBoolean(data.auto_fit_viewport)}
            />
            <SettingsItem
              label="Adaptive Zoom"
              value={
                data.adaptive_zoom ? `${data.adaptive_zoom * 2}x` : 'Disabled'
              }
            />
            <SettingsItem
              label="Tooltips"
              value={formatBoolean(data.tooltips)}
            />
            <SettingsItem
              label="tgui Window Mode"
              value={
                data.tgui_fancy ? 'Fancy (default)' : 'Compatible (slower)'
              }
            />
            <SettingsItem
              label="tgui Window Placement"
              value={data.tgui_lock ? 'Primary monitor' : 'Free (default)'}
            />
            <SettingsItem
              label="Play Admin Sounds"
              value={formatBoolean(data.hear_admin_sounds)}
            />
            <SettingsItem
              label="Announcement Sounds as Ghost"
              value={formatBoolean(data.hear_observer_announcements)}
            />
            <SettingsItem
              label="Fax Sounds as Ghost"
              value={formatBoolean(data.hear_faxes)}
            />
            <SettingsItem label="Meme/Atmospheric Sounds" value="Toggle" />
            <SettingsItem label="Set Eye Blur Type" value="Set" />
            <SettingsItem label="Set Flash Type" value="Set" />
            <SettingsItem label="Set Crit Type" value="Set" />
            <SettingsItem
              label="Play Lobby Music"
              value={formatBoolean(data.hear_lobby_music)}
            />
            <SettingsItem
              label="Play VOX Announcements"
              value={formatBoolean(data.hear_vox)}
            />
            <SettingsItem
              label="Ghost Nightvision"
              value={data.ghost_nightvision}
            />
          </SettingsBlock>
        </Flex.Item>
        <Flex.Item style={{ width: '33%' }}>
          <SettingsBlock title="Gameplay Toggles">
            <SettingsItem
              label="Being Able to Hurt Yourself"
              value={formatBoolean(!data.hurt_self)}
            />
            <SettingsItem
              label="Help Intent Safety"
              value={formatBoolean(data.help_intent_safety)}
            />
            <SettingsItem
              label="Middle Mouse Abilities"
              value={formatBoolean(data.middle_mouse_click)}
            />
            <SettingsItem
              label="Ability Deactivation"
              value={formatBoolean(!data.ability_deactivation)}
            />
            <SettingsItem
              label="Directional Assist"
              value={formatBoolean(data.directional_assist)}
            />
            <SettingsItem
              label="Magazine Auto-Ejection"
              value={formatBoolean(!data.magazine_autoeject)}
            />
            <SettingsItem
              label="Magazine Auto-Ejection to Offhand"
              value={formatBoolean(data.magazine_autoeject_to_hand)}
            />
            <SettingsItem
              label="Magazine Manual Ejection to Offhand"
              value={formatBoolean(data.magazine_eject_to_hand)}
            />
            <SettingsItem
              label="Automatic Punctuation"
              value={formatBoolean(data.auto_punctuation)}
            />
            <SettingsItem
              label="Combat Click-Drag Override"
              value={formatBoolean(data.combat_clickdrag_override)}
            />
            <SettingsItem
              label="Middle-Click Swap Hands"
              value={formatBoolean(data.middle_mouse_swap_hands)}
            />
            <SettingsItem
              label="Vendors Vending to Hands"
              value={formatBoolean(data.vend_item_to_hand)}
            />
            <SettingsItem
              label="Semi-Auto Ammo Display Limiter"
              value={formatBoolean(data.semi_auto_display_limiter)}
            />
          </SettingsBlock>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const SpecialRolesMenu = () => {
  const { act, data } = useBackend<CharacterSetupProps>();

  return (
    <Section title="Special Roles">
      <SettingsBlock title="ERT Settings">
        <SettingsItem
          label="Spawn as Leader"
          value={formatBoolean(data.play_leader)}
        />
        <SettingsItem
          label="Spawn as Medic"
          value={formatBoolean(data.play_medic)}
        />
        <SettingsItem
          label="Spawn as Engineer"
          value={formatBoolean(data.play_engineer)}
        />
        <SettingsItem
          label="Spawn as Heavy"
          value={formatBoolean(data.play_heavy)}
        />
        <SettingsItem
          label="Spawn as Smartgunner"
          value={formatBoolean(data.play_smartgunner)}
        />
        <SettingsItem
          label="Spawn as Synth"
          value={formatBoolean(data.play_synth)}
        />
        <SettingsItem
          label="Spawn as Miscellaneous"
          value={formatBoolean(data.play_leader)}
        />
      </SettingsBlock>
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
