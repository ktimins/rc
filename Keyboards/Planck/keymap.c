
/* Copyright 2015-2017 Jack Humbert
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*#include "planck.h"*/
/*#include "action_layer.h"*/
#include QMK_KEYBOARD_H
#include "rzitex.h"

// Custom keys
#define RZ_CAD    LALT(LCTL(KC_DEL))
#define RZ_LOCK   LGUI(LSFT(KC_Q))
#define RZ_CTLC   LCTL(KC_C)
#define RZ_EMU    LCTL(KC_GRV)
#define RZ_TASK   LCTL(LSFT(KC_ESC))
#define RZ_FLUX   LALT(KC_END)
#define RZ_MUTE   LCTL(LSFT(KC_F13))  // Toggle global mute

extern keymap_config_t keymap_config;

enum planck_layers {
   _QWERTY,
   _COLEMAK,
   _NUMPAD,
   _LOWER,
   _RAISE,
   _POK3R,
   _ADJUST
};

enum planck_keycodes {
   QWERTY = SAFE_RANGE,
   COLEMAK,
   NUMPAD,
   LOWER,
   RAISE,
   POK3R
};

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

   /* Qwerty
    * ,-----------------------------------------------------------------------------------.
    * | Tab  |   Q  |   W  |   E  |   R  |   T  |   Y  |   U  |   I  |   O  |   P  | Bksp |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | Bksp |   A  |   S  |   D  |   F  |   G  |   H  |   J  |   K  |   L  |   ;  |  "   |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | Shift|   Z  |   X  |   C  |   V  |   B  |   N  |   M  |   ,  |   .  |   /  |Enter |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |  F24 | Ctrl | GUI  | Alt  |Lower |    Space    |Raise | Left | RCTL |Pok3r |Right |
    * `-----------------------------------------------------------------------------------'
    */
   [_QWERTY] = LAYOUT_planck_grid(
         KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,    KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_BSPC,
         KC_BSPC, KC_A,    KC_S,    KC_D,    KC_F,    KC_G,    KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT,
         KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,    KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, SC_SENT,
         KC_F24,  KC_LCTL, KC_LGUI, KC_LALT, LOWER,   KC_SPC,  KC_SPC,  RAISE,   KC_LEFT, KC_RCTL, POK3R,   KC_RGHT
         ),

   /* Colemak
    * ,-----------------------------------------------------------------------------------.
    * | Tab  |   Q  |   W  |   F  |   P  |   G  |   J  |   L  |   U  |   Y  |   ;  | Bksp |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | Bksp |   A  |   R  |   S  |   T  |   D  |   H  |   N  |   E  |   I  |   O  |  "   |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | Shift|   Z  |   X  |   C  |   V  |   B  |   K  |   M  |   ,  |   .  |   /  |Enter |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      | Ctrl | GUI  | Alt  |Lower |    Space    |Raise | Left | RCTL |Pok3r |Right |
    * `-----------------------------------------------------------------------------------'
    */
   [_COLEMAK] = LAYOUT_planck_grid(
         KC_TAB , KC_Q,    KC_W,    KC_F,    KC_P,    KC_G,   KC_J,    KC_L,    KC_U,    KC_Y,    KC_SCLN, KC_BSPC,
         KC_BSPC, KC_A,    KC_R,    KC_S,    KC_T,    KC_D,   KC_H,    KC_N,    KC_E,    KC_I,    KC_O,    KC_QUOT,
         KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,   KC_K,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, SC_SENT,
         _______, KC_LCTL, KC_LGUI, KC_LALT, LOWER,   KC_SPC, KC_SPC,  RAISE,   KC_LEFT, KC_RCTL, POK3R,   KC_RGHT
         ),

   /* NumPad
    * ,-----------------------------------------------------------------------------------.
    * |      |      |      |      |      |      |NUMLCK|  7   |  8   |  9   |  /   |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |      |      |      |      |      |      |  4   |  5   |  6   |  *   |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |      |      |      |      |      |  0   |  1   |  2   |  3   |  -   |ENTER |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |      |      |      |Lower |      +      |Raise |  0   |  .   |POK3R |      |
    * `-----------------------------------------------------------------------------------'
    */
   [_NUMPAD] = LAYOUT_planck_grid(
         _______, _______, _______, _______, _______, _______, KC_NUM,  KC_KP_7, KC_KP_8, KC_KP_9, KC_PSLS, _______,
         _______, _______, _______, _______, _______, _______, _______, KC_KP_4, KC_KP_5, KC_KP_6, KC_PAST, _______,
         _______, _______, _______, _______, _______, _______, KC_KP_0, KC_KP_1, KC_KP_2, KC_KP_3, KC_PMNS, KC_PENT,
         _______, _______, _______, _______, LOWER,   KC_PPLS, KC_PPLS, RAISE,   KC_KP_0, KC_PDOT, POK3R,   _______
         ),

   /* Lower
    * ,-----------------------------------------------------------------------------------.
    * |   ~  |   !  |   @  |   #  |   $  |   %  |   ^  |   &  |   *  |   (  |   )  | Del  |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | ESC  |  F1  |  F2  |  F3  |  F4  |  F5  |  F6  |   _  |   +  |   {  |   }  |  |   |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |  F7  |  F8  |  F9  |  F10 |  F11 |  F12 |      |      | Home | End  |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |      |      |      |      |             |      |      | CAD  |      |      |
    * `-----------------------------------------------------------------------------------'
    */
   [_LOWER] = LAYOUT_planck_grid(
         KC_TILD, KC_EXLM, KC_AT,   KC_HASH, KC_DLR,  KC_PERC, KC_CIRC, KC_AMPR, KC_ASTR, KC_LPRN, KC_RPRN, KC_DEL,
         KC_ESC,  KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   KC_F6,   KC_UNDS, KC_PLUS, KC_LCBR, KC_RCBR, KC_PIPE,
         _______, KC_F7,   KC_F8,   KC_F9,   KC_F10,  KC_F11,  KC_F12,  _______, _______, KC_HOME, KC_END,  _______,
         _______, _______, _______, _______, _______, _______, _______, _______, _______, RZ_CAD , _______, _______
         ),

   /* Raise
    * ,-----------------------------------------------------------------------------------.
    * |   `  |   1  |   2  |   3  |   4  |   5  |   6  |   7  |   8  |   9  |   0  | Del  |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | Del  |  F1  |  F2  |  F3  |  F4  |  F5  |  F6  |   -  |   =  |   [  |   ]  |  \   |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |  F7  |  F8  |  F9  |  F10 |  F11 |  F12 |      |      |Pg Up |Pg Dn |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |      |      |      |      |             |      |      | LOCK |      | FLUX |
    * `-----------------------------------------------------------------------------------'
    */
   [_RAISE] = LAYOUT_planck_grid(
         KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5,    KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_DEL,
         KC_DEL,  KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   KC_F6,   KC_MINS, KC_EQL,  KC_LBRC, KC_RBRC, KC_BSLS,
         _______, KC_F7,   KC_F8,   KC_F9,   KC_F10,  KC_F11,  KC_F12,  _______, _______, KC_PGUP, KC_PGDN, _______,
         _______, _______, _______, _______, _______, _______, _______, _______, _______, RZ_LOCK, _______, RZ_FLUX
         ),

   /* POK3R
    * ,-----------------------------------------------------------------------------------.
    * | TASK | Stop | Play | Prev | Next |      | Calc | PGDN | Home | PGUP |      |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | APP  |      | MUTE | VOLD | VOLU |      | Left | Down |  Up  | Right|      |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | SHFT |      | CUT  | COPY | PASTE|      | End  | End  |      |      |      |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      | Ctrl | GUI  | Alt  |      |   CONEMU    |      |      |      |      |      |
    * `-----------------------------------------------------------------------------------'
    */
   [_POK3R] = LAYOUT_planck_grid(
         RZ_TASK, KC_MSTP, KC_MPLY, KC_MPRV, KC_MNXT,  _______, KC_CALC, KC_PGDN, KC_HOME, KC_PGUP, XXXXXXX, XXXXXXX,
         KC_APP , _______, KC_MUTE, KC_VOLD, KC_VOLU,  _______, KC_LEFT, KC_DOWN, KC_UP  , KC_RGHT, _______, _______,
         KC_LSFT, _______, KC_CUT , KC_COPY, KC_PASTE, _______, KC_END , KC_END , _______, _______, _______, _______,
         _______, KC_LCTL, KC_LGUI, KC_LALT, _______,  RZ_EMU,  RZ_EMU,  _______, _______, _______, _______, _______
         ),

   /* Adjust (Lower + Raise)
    * ,-----------------------------------------------------------------------------------.
    * |      | Reset|      |      |      |      |      |      | Pause|RZMUTE| Print|  Del |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * | CAPS |CK ON |CK OFF|Aud on|Audoff|      |      |Qwerty|Colemk|NUMPAD|Insert|      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |CLKTGL|CLK UP|CLKDWN|CLKRST|      |      |AGNORM|AGSWAP|      |      |      |
    * |------+------+------+------+------+------+------+------+------+------+------+------|
    * |      |      |      |      |      |    CONEMU   |      |      |      |      |      |
    * `-----------------------------------------------------------------------------------'
    */
   [_ADJUST] = LAYOUT_planck_grid(
         _______, QK_BOOT, _______, _______, _______, _______, _______, _______, KC_PAUS, RZ_MUTE, KC_PSCR, KC_DEL ,
         KC_CAPS, CK_ON,   CK_OFF,  AU_ON,   AU_OFF,  _______, _______, QWERTY,  COLEMAK, NUMPAD,  KC_INS,  _______,
         _______, CK_TOGG, CK_UP,   CK_DOWN, CK_RST,  _______, _______, AG_NORM, AG_SWAP, _______, _______, _______,
         _______, _______, _______, _______, _______, RZ_EMU , RZ_EMU , _______, _______, _______, _______, _______
         )

};

/*layer_state_t layer_state_set_user(layer_state_t state) {*/
/*return update_tri_layer_state(state, _LOWER, _RAISE, _ADJUST);*/
/*}*/

/*default_layer_set(_COLEMAK);*/


bool process_record_user(uint16_t keycode, keyrecord_t *record) {
   switch (keycode) {
      case QWERTY:
         if (record->event.pressed) {
            set_single_persistent_default_layer(_QWERTY);
         }
         return false;
         break;
      case COLEMAK:
         if (record->event.pressed) {
            set_single_persistent_default_layer(_COLEMAK);
         }
         return false;
         break;
      case NUMPAD:
         if (record->event.pressed) {
            set_single_persistent_default_layer(_NUMPAD);
         }
         return false;
         break;
      case LOWER:
         if (record->event.pressed) {
            layer_on(_LOWER);
            update_quad_layer(_LOWER, _RAISE, _ADJUST, _POK3R);
         } else {
            layer_off(_LOWER);
            update_quad_layer(_LOWER, _RAISE, _ADJUST, _POK3R);
         }
         return false;
         break;
      case RAISE:
         if (record->event.pressed) {
            layer_on(_RAISE);
            update_quad_layer(_LOWER, _RAISE, _ADJUST, _POK3R);
         } else {
            layer_off(_RAISE);
            update_quad_layer(_LOWER, _RAISE, _ADJUST, _POK3R);
         }
         return false;
         break;
      case POK3R:
         if (record->event.pressed) {
            layer_on(_POK3R);
            update_quad_layer(_LOWER, _RAISE, _ADJUST, _POK3R);
         } else {
            layer_off(_POK3R);
            update_quad_layer(_LOWER, _RAISE, _ADJUST, _POK3R);
         }
         return false;
         break;
   }
   return true;
}
