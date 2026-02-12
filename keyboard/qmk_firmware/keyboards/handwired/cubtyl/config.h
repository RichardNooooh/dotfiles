#pragma once

#define EE_HANDS // Store which side I am in EEPROM

/* Keyboard matrix assignments */
#define MATRIX_ROW_PINS { GP23, GP29, GP28, GP27, GP26, GP22, GP21 }
#define MATRIX_COL_PINS { GP8, GP7, GP6, GP5, GP4, GP3, GP2 }

/* Reset */
#define RP2040_BOOTLOADER_DOUBLE_TAP_RESET

#define DYNAMIC_KEYMAP_LAYER_COUNT 16
