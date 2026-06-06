/*
 * SPDX-FileCopyrightText: 2026 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    const char *broker;
    int         port;
    const char *username;
    const char *password;
    const char *subscribe_topic;
    const char *publish_topic;
} cap_mqtt_im_config_t;

esp_err_t cap_mqtt_im_start(const cap_mqtt_im_config_t *config);
esp_err_t cap_mqtt_im_stop(void);
esp_err_t cap_mqtt_im_publish(const char *text);

#ifdef __cplusplus
}
#endif
