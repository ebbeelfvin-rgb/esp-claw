/*
 * SPDX-FileCopyrightText: 2026 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */
#include "cap_mqtt_im.h"

#include <string.h>
#include <stdlib.h>

#include "cJSON.h"
#include "claw_cap.h"
#include "claw_event_publisher.h"
#include "claw_event_router.h"
#include "esp_err.h"
#include "esp_log.h"
#include "mqtt_client.h"

#define MQTT_IM_SOURCE_CAP  "mqtt_gateway"
#define MQTT_IM_CHANNEL     "mqtt"
#define MQTT_IM_CHAT_ID     "mqtt"
#define MQTT_IM_SENDER_ID   "mqtt_user"

static const char *TAG = "cap_mqtt_im";

typedef struct {
    esp_mqtt_client_handle_t client;
    char subscribe_topic[320];
    char publish_topic[320];
    bool started;
} cap_mqtt_im_state_t;

static cap_mqtt_im_state_t s_state;

/* ── Send capability (called by the router to deliver agent responses) ── */

static esp_err_t mqtt_send_message_execute(const char *input_json,
                                           const claw_cap_call_context_t *ctx,
                                           char *output,
                                           size_t output_size)
{
    cJSON *root = cJSON_Parse(input_json ? input_json : "{}");
    if (!root) {
        snprintf(output, output_size, "Error: invalid JSON");
        return ESP_ERR_INVALID_ARG;
    }

    cJSON *msg_item = cJSON_GetObjectItem(root, "message");
    const char *message = cJSON_IsString(msg_item) ? msg_item->valuestring : NULL;

    if (!message || !message[0]) {
        cJSON_Delete(root);
        snprintf(output, output_size, "Error: message required");
        return ESP_ERR_INVALID_ARG;
    }

    esp_err_t err = cap_mqtt_im_publish(message);
    cJSON_Delete(root);

    if (err != ESP_OK) {
        snprintf(output, output_size, "Error: %s", esp_err_to_name(err));
        return err;
    }

    snprintf(output, output_size, "reply sent via MQTT");
    return ESP_OK;
}

static const claw_cap_descriptor_t s_mqtt_descriptors[] = {
    {
        .id = "mqtt_send_message",
        .name = "mqtt_send_message",
        .family = "im",
        .description = "Send a text message back to the MQTT broker.",
        .kind = CLAW_CAP_KIND_CALLABLE,
        .cap_flags = 0,
        .input_schema_json =
            "{\"type\":\"object\",\"properties\":"
            "{\"channel\":{\"type\":\"string\"},"
            "\"chat_id\":{\"type\":\"string\"},"
            "\"message\":{\"type\":\"string\"}},"
            "\"required\":[\"message\"]}",
        .execute = mqtt_send_message_execute,
    },
};

static const claw_cap_group_t s_mqtt_group = {
    .group_id = "cap_mqtt_im",
    .descriptors = s_mqtt_descriptors,
    .descriptor_count = sizeof(s_mqtt_descriptors) / sizeof(s_mqtt_descriptors[0]),
};

/* ── MQTT event handler ─────────────────────────────────────────────── */

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;

    switch ((esp_mqtt_event_id_t)event_id) {
    case MQTT_EVENT_CONNECTED:
        ESP_LOGI(TAG, "Connected to broker, subscribing to %s", s_state.subscribe_topic);
        esp_mqtt_client_subscribe(s_state.client, s_state.subscribe_topic, 0);
        break;

    case MQTT_EVENT_DISCONNECTED:
        ESP_LOGW(TAG, "Disconnected from broker");
        break;

    case MQTT_EVENT_SUBSCRIBED:
        ESP_LOGI(TAG, "Subscribed msg_id=%d", event->msg_id);
        break;

    case MQTT_EVENT_DATA:
        if (event->data && event->data_len > 0) {
            char *text = strndup(event->data, event->data_len);
            if (!text) {
                ESP_LOGE(TAG, "OOM on inbound MQTT message");
                break;
            }
            ESP_LOGI(TAG, "Inbound topic=%.*s text=%.80s",
                     event->topic_len, event->topic ? event->topic : "",
                     text);
            claw_event_router_publish_message(MQTT_IM_SOURCE_CAP,
                                             MQTT_IM_CHANNEL,
                                             MQTT_IM_CHAT_ID,
                                             text,
                                             MQTT_IM_SENDER_ID,
                                             NULL);
            free(text);
        }
        break;

    case MQTT_EVENT_ERROR:
        ESP_LOGE(TAG, "MQTT client error");
        break;

    default:
        break;
    }
}

/* ── Public API ─────────────────────────────────────────────────────── */

esp_err_t cap_mqtt_im_start(const cap_mqtt_im_config_t *config)
{
    if (!config || !config->broker || !config->broker[0]) {
        ESP_LOGW(TAG, "No broker configured, MQTT IM disabled");
        return ESP_OK;
    }

    if (s_state.started) {
        ESP_LOGW(TAG, "Already started");
        return ESP_OK;
    }

    /* Register capability group so the router can call mqtt_send_message */
    if (!claw_cap_group_exists(s_mqtt_group.group_id)) {
        esp_err_t err = claw_cap_register_group(&s_mqtt_group);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "Failed to register cap group: %s", esp_err_to_name(err));
            return err;
        }
    }

    /* Bind "mqtt" channel → "mqtt_send_message" capability */
    esp_err_t err = claw_event_router_register_outbound_binding(MQTT_IM_CHANNEL, "mqtt_send_message");
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to register outbound binding: %s", esp_err_to_name(err));
        return err;
    }

    char uri[340];
    snprintf(uri, sizeof(uri), "mqtt://%s:%d", config->broker, config->port > 0 ? config->port : 1883);

    esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = uri,
    };

    if (config->username && config->username[0]) {
        mqtt_cfg.credentials.username = config->username;
    }
    if (config->password && config->password[0]) {
        mqtt_cfg.credentials.authentication.password = config->password;
    }

    strlcpy(s_state.subscribe_topic,
            (config->subscribe_topic && config->subscribe_topic[0]) ? config->subscribe_topic : "sigge/hjarna/in",
            sizeof(s_state.subscribe_topic));

    strlcpy(s_state.publish_topic,
            (config->publish_topic && config->publish_topic[0]) ? config->publish_topic : "sigge/hjarna/out",
            sizeof(s_state.publish_topic));

    s_state.client = esp_mqtt_client_init(&mqtt_cfg);
    if (!s_state.client) {
        ESP_LOGE(TAG, "Failed to create MQTT client");
        return ESP_FAIL;
    }

    err = esp_mqtt_client_register_event(s_state.client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Register event failed: %s", esp_err_to_name(err));
        esp_mqtt_client_destroy(s_state.client);
        s_state.client = NULL;
        return err;
    }

    err = esp_mqtt_client_start(s_state.client);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Client start failed: %s", esp_err_to_name(err));
        esp_mqtt_client_destroy(s_state.client);
        s_state.client = NULL;
        return err;
    }

    s_state.started = true;
    ESP_LOGI(TAG, "MQTT IM started broker=%s sub=%s pub=%s", uri, s_state.subscribe_topic, s_state.publish_topic);
    return ESP_OK;
}

esp_err_t cap_mqtt_im_stop(void)
{
    if (s_state.client) {
        esp_mqtt_client_stop(s_state.client);
        esp_mqtt_client_destroy(s_state.client);
        s_state.client = NULL;
    }
    s_state.started = false;
    return ESP_OK;
}

esp_err_t cap_mqtt_im_publish(const char *text)
{
    if (!s_state.client || !text || !text[0] || !s_state.publish_topic[0]) {
        return ESP_ERR_INVALID_STATE;
    }
    int msg_id = esp_mqtt_client_publish(s_state.client, s_state.publish_topic, text, 0, 0, 0);
    return msg_id >= 0 ? ESP_OK : ESP_FAIL;
}
