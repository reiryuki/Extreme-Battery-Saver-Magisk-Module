# type
magiskpolicy --live "type vendor_overlay_file"

# service_manager
magiskpolicy --live "allow { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } { hal_power_service color_display_service } service_manager find"

# binder
magiskpolicy --live "dontaudit { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } hal_power_default binder call"
magiskpolicy --live "allow     { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } hal_power_default binder call"

# additional
magiskpolicy --live "dontaudit hal_power_stats_default sysfs dir { read open }"
magiskpolicy --live "allow     hal_power_stats_default sysfs dir { read open }"


