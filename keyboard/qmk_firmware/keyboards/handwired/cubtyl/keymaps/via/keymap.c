#include QMK_KEYBOARD_H

// Each layer gets a name for readability, which is then used in the keymap matrix below.
// The underscores don't mean anything - you can have a layer called STUFF or any other name.
// Layer names don't all need to be of the same length, obviously, and you can also skip them
// entirely and just use numbers.
#define _QWERTY 0
#define _WORKMAN 1
#define _FNSYM 2
#define _MEDIA 3
#define _NUMPAD 4

enum keycodes {
    KC_CYCLE_LAYERS = QK_USER,
};

#define LAYER_CYCLE_START 0
#define LAYER_CYCLE_END   1

// Add the behaviour of this new keycode
// https://docs.qmk.fm/feature_layers#example-keycode-to-cycle-through-layers
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
    case KC_CYCLE_LAYERS:
      // Our logic will happen on presses, nothing is done on releases
      if (!record->event.pressed) {
        // We've already handled the keycode (doing nothing), let QMK know so no further code is run unnecessarily
        return false;
      }

      uint8_t current_layer = get_highest_layer(layer_state);

      // Check if we are within the range, if not quit
      if (current_layer > LAYER_CYCLE_END || current_layer < LAYER_CYCLE_START) {
        return false;
      }

      uint8_t next_layer = current_layer + 1;
      if (next_layer > LAYER_CYCLE_END) {
          next_layer = LAYER_CYCLE_START;
      }
      set_single_default_layer(next_layer);
      return false;

    // Process other keycodes normally
    default:
      return true;
  }
}


// Some basic macros
// #define TASK   LCTL(LSFT(KC_ESC))
// #define TAB_R  LCTL(KC_TAB)
// #define TAB_L  LCTL(LSFT(KC_TAB))
// #define TAB_RO LCTL(LSFT(KC_T))

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [_QWERTY] = LAYOUT(
        // left hand
        KC_EQL,    KC_1,     KC_2,     KC_3,     KC_4,     KC_5,     KC_CYCLE_LAYERS,
        KC_TAB,    KC_Q,     KC_W,     KC_E,     KC_R,     KC_T,     TG(_NUMPAD),
        KC_ESC,    KC_A,     KC_S,     KC_D,     KC_F,     KC_G,     OSL(_MEDIA),
        KC_CAPS,   KC_Z,     KC_X,     KC_C,     KC_V,     KC_B,
                             KC_NO,    KC_LEFT,  KC_RIGHT,
                                       KC_LSFT,  KC_LCTL,  KC_LALT,  KC_LGUI,
                                                 KC_SPACE, KC_ENTER, TG(_FNSYM),
        // right hand
        KC_NO,     KC_6,     KC_7,     KC_8,     KC_9,     KC_0,     KC_MINUS,
        KC_NO,     KC_Y,     KC_U,     KC_I,     KC_O,     KC_P,     KC_BSLS,
        KC_NO,     KC_H,     KC_J,     KC_K,     KC_L,     KC_SCLN,  KC_QUOT,
                   KC_N,     KC_M,     KC_COMM,  KC_DOT,   KC_SLSH,  KC_NO,
                             KC_UP,    KC_DOWN,  KC_NO,
        KC_RGUI,   KC_RALT,  KC_RCTL,  KC_RSFT,
        KC_NO,     KC_DEL,   KC_BSPC
    ),
    [_WORKMAN] = LAYOUT(
        // left hand
        KC_EQL,    KC_1,     KC_2,     KC_3,     KC_4,     KC_5,     KC_CYCLE_LAYERS,
        KC_TAB,    KC_Q,     KC_D,     KC_R,     KC_W,     KC_B,     TG(_NUMPAD),
        KC_ESC,    KC_A,     KC_S,     KC_H,     KC_T,     KC_G,     OSL(_MEDIA),
        KC_CAPS,   KC_Z,     KC_X,     KC_M,     KC_C,     KC_V,
                             KC_NO,    KC_LEFT,  KC_RIGHT,
                                       KC_LSFT,  KC_LCTL,  KC_LALT,  KC_LGUI,
                                                 KC_SPACE, KC_ENTER, TG(_FNSYM),
        // right hand
        KC_NO,     KC_6,     KC_7,     KC_8,     KC_9,     KC_0,     KC_MINUS,
        KC_NO,     KC_J,     KC_F,     KC_U,     KC_P,     KC_SCLN,  KC_BSLS,
        KC_NO,     KC_Y,     KC_N,     KC_E,     KC_O,     KC_I,     KC_QUOT,
                   KC_K,     KC_L,     KC_COMM,  KC_DOT,   KC_SLSH,  KC_NO,
                             KC_UP,    KC_DOWN,  KC_NO,
        KC_RGUI,   KC_RALT,  KC_RCTL,  KC_RSFT,
        KC_NO,     KC_DEL,   KC_BSPC
    ),
    [_FNSYM] = LAYOUT( // TODO
        // left hand
        KC_F1,     KC_F2,    KC_F3,    KC_F4,    KC_F5,    KC_F6,    _______,
        _______,   KC_1,     KC_2,     KC_3,     KC_4,     KC_5,     _______,
        _______,   KC_NO,    KC_LCBR,  KC_LBRC,  KC_LPRN,  KC_EQL,   _______,
        _______,   KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,
                             _______,  _______,  _______,
                                       _______,  _______,  _______,  _______,
                                                 _______,  _______,  _______,
        // right hand
        _______,   KC_F7,    KC_F8,    KC_F9,    KC_F10,   KC_F11,   KC_F12,
        _______,   KC_6,     KC_7,     KC_8,     KC_9,     KC_0,     _______,
        _______,   KC_MINS,  KC_RPRN,  KC_RBRC,  KC_RCBR,  KC_SCLN,  _______,
                   KC_NO,    KC_NO,    _______,  _______,   _______, _______,
                             _______,  _______,  _______,
        _______,   _______,  _______,  _______,
        _______,   _______,  _______
    ),
    [_MEDIA] = LAYOUT(
        // left hand
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    _______,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    _______,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    _______,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,
                             KC_NO,    KC_NO,    KC_NO,
                                       KC_NO,    KC_NO,    KC_NO,    KC_NO,
                                                 KC_NO,    KC_NO,    KC_NO,
        // right hand
        _______,   KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,
        _______,   KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,
        _______,   KC_PSCR,  KC_PAUS,  KC_SCRL,  KC_NO,    KC_NO,    KC_NO,
                   KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,
                             KC_VOLU,  KC_VOLD,  KC_MUTE,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,
        KC_NO,     KC_NO,    KC_NO
    ),
    [_NUMPAD] = LAYOUT(
        // left hand
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    _______,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    _______,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,    _______,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,    KC_NO,    KC_NO,
                             KC_NO,    KC_NO,    KC_NO,
                                       KC_NO,    KC_NO,    KC_NO,    KC_NO,
                                                 KC_NO,    KC_NO,    KC_NO,
        // right hand
        _______,   KC_NO,    KC_NUM,   KC_PSLS,  KC_PAST,  KC_PMNS,  KC_CALC,
        _______,   KC_NO,    KC_P7,    KC_P8,    KC_P9,    KC_PPLS,  KC_NO,
        _______,   KC_NO,    KC_P4,    KC_P5,    KC_P6,    KC_NO,    KC_NO,
                   KC_NO,    KC_P1,    KC_P2,    KC_P3,    KC_PENT,  KC_NO,
                             KC_P0,    KC_NO,    KC_PDOT,
        KC_NO,     KC_NO,    KC_NO,    KC_NO,
        KC_NO,     KC_NO,    KC_NO
    )
};

void keyboard_post_init_user(void) {
    debug_enable=true;
    debug_matrix=true;
}

