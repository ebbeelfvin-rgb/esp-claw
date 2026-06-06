idf_component_register(
    SRCS "src/cap_mqtt_im.c"
    INCLUDE_DIRS "include"
    REQUIRES
        mqtt
        claw_cap
        claw_event_router
        freertos
)
