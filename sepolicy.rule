# debug
magiskpolicy --live "dontaudit system_server system_file file write"
magiskpolicy --live "allow     system_server system_file file write"

# context
magiskpolicy --live "type vendor_overlay_file"
magiskpolicy --live "dontaudit vendor_overlay_file labeledfs filesystem associate"
magiskpolicy --live "allow     vendor_overlay_file labeledfs filesystem associate"
magiskpolicy --live "dontaudit init vendor_overlay_file dir relabelfrom"
magiskpolicy --live "allow     init vendor_overlay_file dir relabelfrom"
magiskpolicy --live "dontaudit init vendor_overlay_file file relabelfrom"
magiskpolicy --live "allow     init vendor_overlay_file file relabelfrom"

# service_manager
magiskpolicy --live "allow { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } { hal_power_service color_display_service } service_manager find"

# binder
magiskpolicy --live "dontaudit { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } hal_power_default binder call"
magiskpolicy --live "allow     { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } hal_power_default binder call"

# unix_stream_socket
magiskpolicy --live "dontaudit { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } zygote unix_stream_socket getopt"
magiskpolicy --live "allow     { flipendo system_app platform_app priv_app untrusted_app_29 untrusted_app_27 untrusted_app } zygote unix_stream_socket getopt"

# additional
magiskpolicy --live "dontaudit hal_power_stats_default sysfs dir { read open }"
magiskpolicy --live "allow     hal_power_stats_default sysfs dir { read open }"


