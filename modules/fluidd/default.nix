{
  services.fluidd = {
    enable = true;
  };

  services.nginx.clientMaxBodySize = "100m";
}
