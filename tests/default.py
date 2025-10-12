moonraker_port = 7125
nginx_port = 80
printer.wait_for_open_port(port = moonraker_port, timeout = 20)
printer.wait_for_open_port(port = nginx_port, timeout = 20)
printer.wait_for_unit("klipper.service")
printer.wait_for_unit("cage-tty1.service")
printer.wait_for_unit("moonraker.service")
printer.fail("journalctl -u moonraker.service --grep 'not a valid config section'")
printer.wait_for_unit("plymouth-quit.service")
printer.succeed("klix-url some-id versions")
