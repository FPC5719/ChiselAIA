let
  name = "ChiselAIA";
  # main pkgs: nixos-26.05  -> cocotb 2.0.1, verilator 5.048, circt 1.140.0
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/8eeec934ae0dbeca3d7868c059568a65c08b2fc3.tar.gz";
    sha256 = "1kfvsqfd4yss5a4c1vwri9x0d87vhg9vrw0j40xxwxfqvb59ndwl";
  }) {};
  # old nixpkgs ONLY for mill (26.05's mill is too new for old build.sc's millbuild. prefix)
  pkgs_old = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ecbc1ca8ffd6aea8372ad16be9ebbb39889e55b6.tar.gz";
    sha256 = "0yfaybsa30zx4bm900hgn3hz92javlf4d47ahdaxj9fai00ddc1x";
  }) {};
  my-python3 = pkgs.python3.withPackages (python-pkgs: [
    python-pkgs.cocotb
    # for docs
    python-pkgs.pydot
  ]);
  h_content = builtins.toFile "h_content" ''
    # ${pkgs.lib.toUpper "${name} usage tips"}

    * Show this help: `h`
    * Enter nix-shell: `nix-shell` (`direnv` recommanded!)
    * Before running, make sure git submodules have been updated.
      * `git submodule update --init --recursive`
    * Run Unit Tests: `make -j`
      * The tilelink verilog is generated into `gen/` folder.
      * The axi4 verilog is generated into `gen_axi/` folder.
      * Run a single unit test: `make run-aplic`, `make run-imsic`, ...
        * The available unit tests are located in test/*/main.py
  '';
  _h_ = pkgs.writeShellScriptBin "h" ''
    ${pkgs.glow}/bin/glow ${h_content}
  '';
  markcode = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "xieby1";
    repo = "markcode";
    rev = "bec9fa8279a23e387825b2a79b66ec77ed52220c";
    hash = "sha256-VzqERMEs/8dOz3n4YfNADLrdA2keqxUek62tqID9TnM=";
  }){};
in pkgs.mkShell {
  inherit name;

  buildInputs = [
    _h_
    pkgs_old.mill
    pkgs.jdk
    pkgs.circt
    pkgs.verilator
    pkgs.gtkwave
    my-python3
    # for generating gtkwave's fst waveform
    pkgs.zlib
    # for docs
    pkgs.graphviz
    pkgs.mdbook
    pkgs.drawio-headless
    markcode
  ];

  shellHook = ''
    export CHISEL_FIRTOOL_PATH=${pkgs.circt}/bin/
    export PYTHONPATH+=:${my-python3}/lib/${my-python3.libPrefix}/site-packages
    export PYTHONPATH+=:$(realpath ./test)
    export LIBGL_ALWAYS_SOFTWARE=1
    # To enable pdb when cocotb test failed
    export COCOTB_PDB_ON_EXCEPTION=1
    h
  '';
}
