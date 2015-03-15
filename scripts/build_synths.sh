#!/usr/bin/env sh
# a NixOS friendly prompt

#////////////////////////////////////////////////////////
# build the synths if we already have pd-extended and faust
#////////////////////////////////////////////////////////

faust_version=$(faust -v | grep Version | tr -dc '[:digit:]')
if [ $faust_version  -gt 967 ]; then
  echo "faust version OK"
  echo -e "\n"
else
  echo "Unfortunately, your faust version has a bug in the Open Sound Control implementation."
  echo "Please build faust from git, or wait until the release of version 0.9.68"
  echo "Alternatively, you can install the whole of VoiceOfFaust automatically,"
  echo "by running the install.sh script in the top directory."
  exit
fi
if [ $(which pd-extended) ]; then
  echo "pd-extended found"
  echo -e "\n"
else
  echo -e "\n"
  echo "pd-extended NOT found"
  echo -e "\n"
  echo "pd-extended is needed to send OSC messages, so VoiceOfFaust knows the pitch."
  echo "Please install either pd-extended, or puredata with the mrpeach externals."
  echo "Alternatively, you can install the whole of VoiceOfFaust automatically,"
  echo "by running the install.sh script in the top directory."
  exit
fi

if [ $(which git) ]; then
  echo "git found"
  echo -e "\n"
else
  echo -e "\n"
  echo "git NOT found"
  echo -e "\n"
  echo "git is needed download the source, please install it."
  echo "Alternatively, you can install the whole of VoiceOfFaust automatically,"
  echo "by running the install.sh script in the top directory."
  exit
fi

# get the dir where this script is stored
work_dir="$(dirname $0:A)"
echo "$work_dir"
ls
cd $work_dir/
if [ ! -d  src/ ]; then
  ls
  mkdir -p src/                                                    && \
  cd src/                                                          && \
  git clone https://github.com/magnetophon/VoiceOfFaust.git
  cd ..
fi

# todo: check for 64 bit, and if so, build from source                     && \
# for now, the pd built in pitchtracker will have to do.                   && \
#curl -sS http://www.katjaas.nl/helmholtz/helmholtz%7E.zip > helmholtz.zip && \
#unzip helmholtz.zip                                                       && \
#rm helmholtz.zip                                                          && \
#mkdir -p $work_dir/PureData/                                              && \
#cp -r helmholtz~/helmholtz~/* $work_dir/PureData/                         && \
cd src/VoiceOfFaust                                                        && \
echo "Building synths, done with:"                                         && \
faust2jack -osc classicVocoder.dsp                                         && \
faust2jack -osc CZringmod.dsp                                              && \
faust2jack -osc FMsinger.dsp                                               && \
faust2jack -osc FOFvocoder.dsp                                             && \
faust2jack -osc Karplus-StrongSinger.dsp                                   && \
faust2jack -osc -sch -t 99999 Karplus-StrongSingerMaxi.dsp                 && \
faust2jack -osc PAFvocoder.dsp                                             && \
faust2jack -osc -sch -t 99999 stringSinger.dsp                             && \
faust2jack -osc subSinger.dsp                                              && \
# doesn't compile on most systems, too big:                                && \
#faust2jack -osc -sch -t 99999 VocSynthFull.dsp                            && \
echo "All synths built."                                                   && \
echo "Now run \"sudo ./scripts/install_synths.sh\""
echo "or, if you want to specify an instalation dir:"
echo "\"sudo ./scripts/install_synths.sh /path/to/install/to/\""
echo "The default instalation dir is \"/usr/local/VoiceOfFaust\"."
