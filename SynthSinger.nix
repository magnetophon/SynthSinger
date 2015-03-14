{ system ? builtins.currentSystem, stdenv, fetchgit }:
# the block from 'let' untill 'in' is only needed untill these pkgs are
# merged into the main distro
let
  pkgs = import <nixpkgs> { inherit system; };
  faust = import  pkgs/faust.nix
    {
        inherit (pkgs) stdenv coreutils fetchgit makeWrapper pkgconfig;
    };
  faust2firefox = import pkgs/faust2firefox.nix
    {
    inherit faust;
    inherit (pkgs) xdg_utils;
    };
  faust2jack = import pkgs/faust2jack.nix
    {
    inherit faust;
    inherit (pkgs) gtk jack2 opencv;
    };
  helmholtz = import pkgs/helmholtz.nix
    {
    inherit (pkgs) stdenv fetchurl unzip puredata;
    };
  mrpeach = import pkgs/mrpeach.nix
    {
    inherit (pkgs) stdenv fetchurl puredata;
    };
  plugins = [ helmholtz mrpeach ];
  puredata-with-plugins = import pkgs/pd-wrapper.nix
    {
    inherit plugins;
    inherit (pkgs) stdenv buildEnv makeWrapper puredata;
    };
in
stdenv.mkDerivation rec {
  name = "SynthSinger";

  src = fetchgit {
    url = "https://github.com/magnetophon/VoiceOfFaust";
    rev = "f3cb04f2320b97f68d08de83140708331b624faf";
    sha256 = "0050872ec03f8e0d003cf0d27c90d0c17a114cad9c50fb1edd3a0dce0982f149";
  };

  runtimeInputs = [ puredata-with-plugins ];

  buildInputs = [ faust faust2jack ];

  patchPhase = ''
    sed -i "s@pd -nodac@${puredata-with-plugins}/bin/pd -nodac@g" launchers/synthWrapper
    sed -i "s@../PureData/OscSendVoc.pd@$out/PureData/OscSendVoc.pd@g" launchers/synthWrapper
  '';

  buildPhase = ''
    faust2jack -osc classicVocoder.dsp
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r launchers/* $out/bin/
    cp -r classicVocoder $out/bin/
    mkdir $out/PureData/
    cp PureData/OscSendVoc.pd $out/PureData/OscSendVoc.pd
  '';

  meta = {
    description = "turn your voice into a synthesizer";
    homepage = https://github.com/magnetophon/VoiceOfFaust;
    license = stdenv.lib.licenses.gpl3;
    maintainers = [ stdenv.lib.maintainers.magnetophon ];
    #platforms = [ stdenv.lib.platforms.linux];
  };
}
