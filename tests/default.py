moonraker_port = 7125
nginx_port = 80
printer.wait_for_open_port(port = moonraker_port, timeout = 10)
printer.wait_for_open_port(port = nginx_port, timeout = 10)
printer.wait_for_unit("cage-tty1.service")
printer.wait_for_unit("moonraker.service")
printer.fail("journalctl -u moonraker.service --grep 'not a valid config section'")
