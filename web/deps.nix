{
  pkgs,
  lib,
  beamPackages,
  overrides ? (x: y: { }),
  overrideFenixOverlay ? null,
}:

let
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;

  workarounds = {
    portCompiler = _unusedArgs: old: {
      buildPlugins = [ pkgs.beamPackages.pc ];
    };

    rustlerPrecompiled =
      {
        toolchain ? null,
        ...
      }:
      old:
      let
        extendedPkgs = pkgs.extend fenixOverlay;
        fenixOverlay =
          if overrideFenixOverlay == null then
            import "${
              fetchTarball {
                url = "https://github.com/nix-community/fenix/archive/056c9393c821a4df356df6ce7f14c722dc8717ec.tar.gz";
                sha256 = "sha256:1cdfh6nj81gjmn689snigidyq7w98gd8hkl5rvhly6xj7vyppmnd";
              }
            }/overlay.nix"
          else
            overrideFenixOverlay;
        nativeDir = "${old.src}/native/${with builtins; head (attrNames (readDir "${old.src}/native"))}";
        fenix =
          if toolchain == null then
            extendedPkgs.fenix.stable
          else
            extendedPkgs.fenix.fromToolchainName toolchain;
        native =
          (extendedPkgs.makeRustPlatform {
            inherit (fenix) cargo rustc;
          }).buildRustPackage
            {
              pname = "${old.packageName}-native";
              version = old.version;
              src = nativeDir;
              cargoLock = {
                lockFile = "${nativeDir}/Cargo.lock";
              };
              nativeBuildInputs = [
                extendedPkgs.cmake
              ];
              doCheck = false;
            };

      in
      {
        nativeBuildInputs = [ extendedPkgs.cargo ];

        env.RUSTLER_PRECOMPILED_FORCE_BUILD_ALL = "true";
        env.RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH = "unused-but-required";

        preConfigure = ''
          mkdir -p priv/native
          for lib in ${native}/lib/*
          do
            ln -s "$lib" "priv/native/$(basename "$lib")"
          done
        '';

        buildPhase = ''
          suggestion() {
            echo "***********************************************"
            echo "                 deps_nix                      "
            echo
            echo " Rust dependency build failed.                 "
            echo
            echo " If you saw network errors, you might need     "
            echo " to disable compilation on the appropriate     "
            echo " RustlerPrecompiled module in your             "
            echo " application config.                           "
            echo
            echo " We think you need this:                       "
            echo
            echo -n " "
            grep -Rl 'use RustlerPrecompiled' lib \
              | xargs grep 'defmodule' \
              | sed 's/defmodule \(.*\) do/config :${old.packageName}, \1, skip_compilation?: true/'
            echo "***********************************************"
            exit 1
          }
          trap suggestion ERR
          ${old.buildPhase}
        '';
      };
  };

  defaultOverrides = (
    final: prev:

    let
      apps = {
        crc32cer = [
          {
            name = "portCompiler";
          }
        ];
        explorer = [
          {
            name = "rustlerPrecompiled";
            toolchain = {
              name = "nightly-2024-11-01";
              sha256 = "sha256-wq7bZ1/IlmmLkSa3GUJgK17dTWcKyf5A+ndS9yRwB88=";
            };
          }
        ];
        snappyer = [
          {
            name = "portCompiler";
          }
        ];
      };

      applyOverrides =
        appName: drv:
        let
          allOverridesForApp = builtins.foldl' (
            acc: workaround: acc // (workarounds.${workaround.name} workaround) drv
          ) { } apps.${appName};

        in
        if builtins.hasAttr appName apps then drv.override allOverridesForApp else drv;

    in
    builtins.mapAttrs applyOverrides prev
  );

  self = packages // (defaultOverrides self packages) // (overrides self packages);

  packages =
    with beamPackages;
    with self;
    {

      bandit =
        let
          version = "1.7.0";
          drv = buildMix {
            inherit version;
            name = "bandit";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "bandit";
              sha256 = "3e2f7a98c7a11f48d9d8c037f7177cd39778e74d55c7af06fe6227c742a8168a";
            };

            beamDeps = [
              hpax
              plug
              telemetry
              thousand_island
              websock
            ];
          };
        in
        drv;

      bcrypt_elixir =
        let
          version = "3.3.2";
          drv = buildMix {
            inherit version;
            name = "bcrypt_elixir";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "bcrypt_elixir";
              sha256 = "471be5151874ae7931911057d1467d908955f93554f7a6cd1b7d804cac8cef53";
            };

            beamDeps = [
              comeonin
              elixir_make
            ];
          };
        in
        drv;

      certifi =
        let
          version = "2.15.0";
          drv = buildRebar3 {
            inherit version;
            name = "certifi";

            src = fetchHex {
              inherit version;
              pkg = "certifi";
              sha256 = "b147ed22ce71d72eafdad94f055165c1c182f61a2ff49df28bcc71d1d5b94a60";
            };
          };
        in
        drv;

      comeonin =
        let
          version = "5.5.1";
          drv = buildMix {
            inherit version;
            name = "comeonin";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "comeonin";
              sha256 = "65aac8f19938145377cee73973f192c5645873dcf550a8a6b18187d17c13ccdb";
            };
          };
        in
        drv;

      db_connection =
        let
          version = "2.8.0";
          drv = buildMix {
            inherit version;
            name = "db_connection";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "db_connection";
              sha256 = "008399dae5eee1bf5caa6e86d204dcb44242c82b1ed5e22c881f2c34da201b15";
            };

            beamDeps = [
              telemetry
            ];
          };
        in
        drv;

      decimal =
        let
          version = "2.3.0";
          drv = buildMix {
            inherit version;
            name = "decimal";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "decimal";
              sha256 = "a4d66355cb29cb47c3cf30e71329e58361cfcb37c34235ef3bf1d7bf3773aeac";
            };
          };
        in
        drv;

      dns_cluster =
        let
          version = "0.2.0";
          drv = buildMix {
            inherit version;
            name = "dns_cluster";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "dns_cluster";
              sha256 = "ba6f1893411c69c01b9e8e8f772062535a4cf70f3f35bcc964a324078d8c8240";
            };
          };
        in
        drv;

      ecto =
        let
          version = "3.13.2";
          drv = buildMix {
            inherit version;
            name = "ecto";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "ecto";
              sha256 = "669d9291370513ff56e7b7e7081b7af3283d02e046cf3d403053c557894a0b3e";
            };

            beamDeps = [
              decimal
              jason
              telemetry
            ];
          };
        in
        drv;

      ecto_sql =
        let
          version = "3.13.2";
          drv = buildMix {
            inherit version;
            name = "ecto_sql";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "ecto_sql";
              sha256 = "539274ab0ecf1a0078a6a72ef3465629e4d6018a3028095dc90f60a19c371717";
            };

            beamDeps = [
              db_connection
              ecto
              postgrex
              telemetry
            ];
          };
        in
        drv;

      elixir_make =
        let
          version = "0.9.0";
          drv = buildMix {
            inherit version;
            name = "elixir_make";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "elixir_make";
              sha256 = "db23d4fd8b757462ad02f8aa73431a426fe6671c80b200d9710caf3d1dd0ffdb";
            };
          };
        in
        drv;

      esbuild =
        let
          version = "0.10.0";
          drv = buildMix {
            inherit version;
            name = "esbuild";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "esbuild";
              sha256 = "468489cda427b974a7cc9f03ace55368a83e1a7be12fba7e30969af78e5f8c70";
            };

            beamDeps = [
              jason
            ];
          };
        in
        drv;

      ex_aws =
        let
          version = "2.6.0";
          drv = buildMix {
            inherit version;
            name = "ex_aws";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "ex_aws";
              sha256 = "30729ee9cbaacda674a4e4260d74206fa89bcd712267c4eaf42a0fc34592c0b3";
            };

            beamDeps = [
              hackney
              jason
              mime
              req
              sweet_xml
              telemetry
            ];
          };
        in
        drv;

      ex_aws_s3 =
        let
          version = "2.5.8";
          drv = buildMix {
            inherit version;
            name = "ex_aws_s3";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "ex_aws_s3";
              sha256 = "84e512ca2e0ae6a6c497036dff06d4493ffb422cfe476acc811d7c337c16691c";
            };

            beamDeps = [
              ex_aws
              sweet_xml
            ];
          };
        in
        drv;

      expo =
        let
          version = "1.1.0";
          drv = buildMix {
            inherit version;
            name = "expo";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "expo";
              sha256 = "fbadf93f4700fb44c331362177bdca9eeb8097e8b0ef525c9cc501cb9917c960";
            };
          };
        in
        drv;

      finch =
        let
          version = "0.20.0";
          drv = buildMix {
            inherit version;
            name = "finch";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "finch";
              sha256 = "2658131a74d051aabfcba936093c903b8e89da9a1b63e430bee62045fa9b2ee2";
            };

            beamDeps = [
              mime
              mint
              nimble_options
              nimble_pool
              telemetry
            ];
          };
        in
        drv;

      gettext =
        let
          version = "0.26.2";
          drv = buildMix {
            inherit version;
            name = "gettext";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "gettext";
              sha256 = "aa978504bcf76511efdc22d580ba08e2279caab1066b76bb9aa81c4a1e0a32a5";
            };

            beamDeps = [
              expo
            ];
          };
        in
        drv;

      hackney =
        let
          version = "1.25.0";
          drv = buildRebar3 {
            inherit version;
            name = "hackney";

            src = fetchHex {
              inherit version;
              pkg = "hackney";
              sha256 = "7209bfd75fd1f42467211ff8f59ea74d6f2a9e81cbcee95a56711ee79fd6b1d4";
            };

            beamDeps = [
              certifi
              idna
              metrics
              mimerl
              parse_trans
              ssl_verify_fun
              unicode_util_compat
            ];
          };
        in
        drv;

      heroicons = pkgs.fetchFromGitHub {
        owner = "tailwindlabs";
        repo = "heroicons";
        rev = "0435d4ca364a608cc75e2f8683d374e55abbae26";
        hash = "sha256-Jcxr1fSbmXO9bZKeg39Z/zVN0YJp17TX3LH5Us4lsZU=";
      };

      hpax =
        let
          version = "1.0.3";
          drv = buildMix {
            inherit version;
            name = "hpax";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "hpax";
              sha256 = "8eab6e1cfa8d5918c2ce4ba43588e894af35dbd8e91e6e55c817bca5847df34a";
            };
          };
        in
        drv;

      idna =
        let
          version = "6.1.1";
          drv = buildRebar3 {
            inherit version;
            name = "idna";

            src = fetchHex {
              inherit version;
              pkg = "idna";
              sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
            };

            beamDeps = [
              unicode_util_compat
            ];
          };
        in
        drv;

      jason =
        let
          version = "1.4.4";
          drv = buildMix {
            inherit version;
            name = "jason";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "jason";
              sha256 = "c5eb0cab91f094599f94d55bc63409236a8ec69a21a67814529e8d5f6cc90b3b";
            };

            beamDeps = [
              decimal
            ];
          };
        in
        drv;

      metrics =
        let
          version = "1.0.1";
          drv = buildRebar3 {
            inherit version;
            name = "metrics";

            src = fetchHex {
              inherit version;
              pkg = "metrics";
              sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
            };
          };
        in
        drv;

      mime =
        let
          version = "2.0.7";
          drv = buildMix {
            inherit version;
            name = "mime";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "mime";
              sha256 = "6171188e399ee16023ffc5b76ce445eb6d9672e2e241d2df6050f3c771e80ccd";
            };
          };
        in
        drv;

      mimerl =
        let
          version = "1.4.0";
          drv = buildRebar3 {
            inherit version;
            name = "mimerl";

            src = fetchHex {
              inherit version;
              pkg = "mimerl";
              sha256 = "13af15f9f68c65884ecca3a3891d50a7b57d82152792f3e19d88650aa126b144";
            };
          };
        in
        drv;

      mint =
        let
          version = "1.7.1";
          drv = buildMix {
            inherit version;
            name = "mint";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "mint";
              sha256 = "fceba0a4d0f24301ddee3024ae116df1c3f4bb7a563a731f45fdfeb9d39a231b";
            };

            beamDeps = [
              hpax
            ];
          };
        in
        drv;

      nimble_options =
        let
          version = "1.1.1";
          drv = buildMix {
            inherit version;
            name = "nimble_options";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "nimble_options";
              sha256 = "821b2470ca9442c4b6984882fe9bb0389371b8ddec4d45a9504f00a66f650b44";
            };
          };
        in
        drv;

      nimble_pool =
        let
          version = "1.1.0";
          drv = buildMix {
            inherit version;
            name = "nimble_pool";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "nimble_pool";
              sha256 = "af2e4e6b34197db81f7aad230c1118eac993acc0dae6bc83bac0126d4ae0813a";
            };
          };
        in
        drv;

      parse_trans =
        let
          version = "3.4.1";
          drv = buildRebar3 {
            inherit version;
            name = "parse_trans";

            src = fetchHex {
              inherit version;
              pkg = "parse_trans";
              sha256 = "620a406ce75dada827b82e453c19cf06776be266f5a67cff34e1ef2cbb60e49a";
            };
          };
        in
        drv;

      phoenix =
        let
          version = "1.8.0";
          drv = buildMix {
            inherit version;
            name = "phoenix";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "phoenix";
              sha256 = "15f6e9cb76646ad8d9f2947240519666fc2c4f29f8a93ad9c7664916ab4c167b";
            };

            beamDeps = [
              bandit
              jason
              phoenix_pubsub
              phoenix_template
              plug
              plug_crypto
              telemetry
              websock_adapter
            ];
          };
        in
        drv;

      phoenix_ecto =
        let
          version = "4.6.5";
          drv = buildMix {
            inherit version;
            name = "phoenix_ecto";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "phoenix_ecto";
              sha256 = "26ec3208eef407f31b748cadd044045c6fd485fbff168e35963d2f9dfff28d4b";
            };

            beamDeps = [
              ecto
              phoenix_html
              plug
              postgrex
            ];
          };
        in
        drv;

      phoenix_html =
        let
          version = "4.2.1";
          drv = buildMix {
            inherit version;
            name = "phoenix_html";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "phoenix_html";
              sha256 = "cff108100ae2715dd959ae8f2a8cef8e20b593f8dfd031c9cba92702cf23e053";
            };
          };
        in
        drv;

      phoenix_live_dashboard =
        let
          version = "0.8.7";
          drv = buildMix {
            inherit version;
            name = "phoenix_live_dashboard";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "phoenix_live_dashboard";
              sha256 = "3a8625cab39ec261d48a13b7468dc619c0ede099601b084e343968309bd4d7d7";
            };

            beamDeps = [
              ecto
              mime
              phoenix_live_view
              telemetry_metrics
            ];
          };
        in
        drv;

      phoenix_live_view =
        let
          version = "1.1.3";
          drv = buildMix {
            inherit version;
            name = "phoenix_live_view";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "phoenix_live_view";
              sha256 = "942967524e8d256ce6847ca3143d94425fa5125b53563790a609c78740cfb6c9";
            };

            beamDeps = [
              jason
              phoenix
              phoenix_html
              phoenix_template
              plug
              telemetry
            ];
          };
        in
        drv;

      phoenix_pubsub =
        let
          version = "2.1.3";
          drv = buildMix {
            inherit version;
            name = "phoenix_pubsub";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "phoenix_pubsub";
              sha256 = "bba06bc1dcfd8cb086759f0edc94a8ba2bc8896d5331a1e2c2902bf8e36ee502";
            };
          };
        in
        drv;

      phoenix_template =
        let
          version = "1.0.4";
          drv = buildMix {
            inherit version;
            name = "phoenix_template";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "phoenix_template";
              sha256 = "2c0c81f0e5c6753faf5cca2f229c9709919aba34fab866d3bc05060c9c444206";
            };

            beamDeps = [
              phoenix_html
            ];
          };
        in
        drv;

      plug =
        let
          version = "1.18.1";
          drv = buildMix {
            inherit version;
            name = "plug";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "plug";
              sha256 = "57a57db70df2b422b564437d2d33cf8d33cd16339c1edb190cd11b1a3a546cc2";
            };

            beamDeps = [
              mime
              plug_crypto
              telemetry
            ];
          };
        in
        drv;

      plug_crypto =
        let
          version = "2.1.1";
          drv = buildMix {
            inherit version;
            name = "plug_crypto";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "plug_crypto";
              sha256 = "6470bce6ffe41c8bd497612ffde1a7e4af67f36a15eea5f921af71cf3e11247c";
            };
          };
        in
        drv;

      postgrex =
        let
          version = "0.21.1";
          drv = buildMix {
            inherit version;
            name = "postgrex";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "postgrex";
              sha256 = "27d8d21c103c3cc68851b533ff99eef353e6a0ff98dc444ea751de43eb48bdac";
            };

            beamDeps = [
              db_connection
              decimal
              jason
            ];
          };
        in
        drv;

      req =
        let
          version = "0.5.15";
          drv = buildMix {
            inherit version;
            name = "req";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "req";
              sha256 = "a6513a35fad65467893ced9785457e91693352c70b58bbc045b47e5eb2ef0c53";
            };

            beamDeps = [
              finch
              jason
              mime
              plug
            ];
          };
        in
        drv;

      ssl_verify_fun =
        let
          version = "1.1.7";
          drv = buildMix {
            inherit version;
            name = "ssl_verify_fun";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "ssl_verify_fun";
              sha256 = "fe4c190e8f37401d30167c8c405eda19469f34577987c76dde613e838bbc67f8";
            };
          };
        in
        drv;

      sweet_xml =
        let
          version = "0.7.5";
          drv = buildMix {
            inherit version;
            name = "sweet_xml";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "sweet_xml";
              sha256 = "193b28a9b12891cae351d81a0cead165ffe67df1b73fe5866d10629f4faefb12";
            };
          };
        in
        drv;

      swoosh =
        let
          version = "1.19.5";
          drv = buildMix {
            inherit version;
            name = "swoosh";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "swoosh";
              sha256 = "c953f51ee0a8b237e0f4307c9cefd3eb1eb751c35fcdda2a8bccb991766473be";
            };

            beamDeps = [
              bandit
              ex_aws
              finch
              hackney
              jason
              mime
              plug
              req
              telemetry
            ];
          };
        in
        drv;

      tailwind =
        let
          version = "0.3.1";
          drv = buildMix {
            inherit version;
            name = "tailwind";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "tailwind";
              sha256 = "98a45febdf4a87bc26682e1171acdedd6317d0919953c353fcd1b4f9f4b676a2";
            };
          };
        in
        drv;

      telemetry =
        let
          version = "1.3.0";
          drv = buildRebar3 {
            inherit version;
            name = "telemetry";

            src = fetchHex {
              inherit version;
              pkg = "telemetry";
              sha256 = "7015fc8919dbe63764f4b4b87a95b7c0996bd539e0d499be6ec9d7f3875b79e6";
            };
          };
        in
        drv;

      telemetry_metrics =
        let
          version = "1.1.0";
          drv = buildMix {
            inherit version;
            name = "telemetry_metrics";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "telemetry_metrics";
              sha256 = "e7b79e8ddfde70adb6db8a6623d1778ec66401f366e9a8f5dd0955c56bc8ce67";
            };

            beamDeps = [
              telemetry
            ];
          };
        in
        drv;

      telemetry_poller =
        let
          version = "1.3.0";
          drv = buildRebar3 {
            inherit version;
            name = "telemetry_poller";

            src = fetchHex {
              inherit version;
              pkg = "telemetry_poller";
              sha256 = "51f18bed7128544a50f75897db9974436ea9bfba560420b646af27a9a9b35211";
            };

            beamDeps = [
              telemetry
            ];
          };
        in
        drv;

      thousand_island =
        let
          version = "1.3.14";
          drv = buildMix {
            inherit version;
            name = "thousand_island";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "thousand_island";
              sha256 = "d0d24a929d31cdd1d7903a4fe7f2409afeedff092d277be604966cd6aa4307ef";
            };

            beamDeps = [
              telemetry
            ];
          };
        in
        drv;

      tzdata =
        let
          version = "1.1.3";
          drv = buildMix {
            inherit version;
            name = "tzdata";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "tzdata";
              sha256 = "d4ca85575a064d29d4e94253ee95912edfb165938743dbf002acdf0dcecb0c28";
            };

            beamDeps = [
              hackney
            ];
          };
        in
        drv;

      unicode_util_compat =
        let
          version = "0.7.1";
          drv = buildRebar3 {
            inherit version;
            name = "unicode_util_compat";

            src = fetchHex {
              inherit version;
              pkg = "unicode_util_compat";
              sha256 = "b3a917854ce3ae233619744ad1e0102e05673136776fb2fa76234f3e03b23642";
            };
          };
        in
        drv;

      websock =
        let
          version = "0.5.3";
          drv = buildMix {
            inherit version;
            name = "websock";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "websock";
              sha256 = "6105453d7fac22c712ad66fab1d45abdf049868f253cf719b625151460b8b453";
            };
          };
        in
        drv;

      websock_adapter =
        let
          version = "0.5.8";
          drv = buildMix {
            inherit version;
            name = "websock_adapter";
            appConfigPath = ./config;

            src = fetchHex {
              inherit version;
              pkg = "websock_adapter";
              sha256 = "315b9a1865552212b5f35140ad194e67ce31af45bcee443d4ecb96b5fd3f3782";
            };

            beamDeps = [
              bandit
              plug
              websock
            ];
          };
        in
        drv;

    };
in
self
