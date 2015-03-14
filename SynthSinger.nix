with import <nixpkgs> {};

# the block from 'let' untill 'in' is only needed untill these pkgs are
# merged into the main distro
let
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
    sha256 = "0s02jv2xagbqy79wf9m0n180p58b2mcfqfb948y05avzcamdg0a2";
  };

  runtimeInputs = [ puredata-with-plugins ];

  buildInputs = [ faust faust2jack ];

  patchPhase = ''
    sed -i "s@pd -nodac@${puredata-with-plugins}/bin/pd -nodac@g" launchers/synthWrapper
    sed -i "s@../PureData/OscSendVoc.pd@$out/PureData/OscSendVoc.pd@g" launchers/synthWrapper
  '';

  buildPhase = ''
    faust2jack -osc classicVocoder.dsp
    faust2jack -osc CZringmod.dsp
    faust2jack -osc FMsinger.dsp
    faust2jack -osc FOFvocoder.dsp
    faust2jack -osc Karplus-StrongSinger.dsp
    faust2jack -osc -sch -t 99999 Karplus-StrongSingerMaxi.dsp
    faust2jack -osc PAFvocoder.dsp
    faust2jack -osc -sch -t 99999 stringSinger.dsp
    faust2jack -osc subSinger.dsp
    faust2jack -osc -sch -t 99999 VocSynthFull.dsp
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp launchers/* $out/bin/
    cp classicVocoder $out/bin/
    cp classicVocoder $out/bin/
    cp CZringmod $out/bin/
    cp FMsinger $out/bin/
    cp FOFvocoder $out/bin/
    cp Karplus-StrongSinger $out/bin/
    cp Karplus-StrongSingerMaxi $out/bin/
    cp PAFvocoder $out/bin/
    cp stringSinger $out/bin/
    cp subSinger $out/bin/
    cp VocSynthFull $out/bin/
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
