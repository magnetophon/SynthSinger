#!/usr/bin/env sh
# a NixOS friendly prompt

#////////////////////////////////////////////////////////
# install the synths if we already have pd-extended and faust
#////////////////////////////////////////////////////////

faust_version=$(faust -v | grep Version | tr -dc '[:digit:]')
if [ $faust_version  -gt 967 ]; then
  echo "faust version OK"
  echo -e "\n"
else
  echo -e "\n"
  echo "Unfortunately, your faust version has a bug in the Open Sound Control implementation."
  echo "Please build faust from git, or wait until the release of version 0.9.68"
  echo "Alternatively, you can install the whole of VoiceOfFaust automatically,"
  echo "by running the install.sh script in the top directory."
  echo -e "\n"
    read -p "If you are sure you built the synths with working OSC, type yes to override this check" yn
      case $yn in
          [Yy]* ) 
            echo "OK, but on your own risk!";;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
      esac
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

if [ $1 ]; then
  out="$1"
else
  out="/usr/local"
fi

# get the dir where this script is stored
work_dir="$(dirname $0:A)/src/VoiceOfFaust/"
if [ -x $work_dir/classicVocoder ]; then
  echo "Synths found."
  echo -e "\n"
else
  echo -e "\n"
  echo "Synths NOT found."
  echo -e "\n"
  echo "Please run build_sunths.sh to manually build the synths."
  echo "Alternatively, you can install the whole of VoiceOfFaust automatically,"
  echo "by running the install.sh script in the top directory."
  exit
fi

echo "Installing synths from $work_dir to $out" && \
  echo -e "\n"
sed -i "s@pd -nodac@pd-extended@g" $work_dir/launchers/synthWrapper                                                   && \
sed -i "s@../PureData/OscSendVoc.pd@  $out/include/VoiceOfFaust/PureData/OscSendVoc.pd@g" $work_dir/launchers/synthWrapper  && \
mkdir -p                              $out/bin                                                                              && \
cp $work_dir/launchers/*              $out/bin/                                                                             && \
cp $work_dir/classicVocoder           $out/bin/                                                                             && \
cp $work_dir/CZringmod                $out/bin/                                                                             && \
cp $work_dir/FMsinger                 $out/bin/                                                                             && \
cp $work_dir/FOFvocoder               $out/bin/                                                                             && \
cp $work_dir/Karplus-StrongSinger     $out/bin/                                                                             && \
cp $work_dir/Karplus-StrongSingerMaxi $out/bin/                                                                             && \
cp $work_dir/PAFvocoder               $out/bin/                                                                             && \
cp $work_dir/stringSinger             $out/bin/                                                                             && \
cp $work_dir/subSinger                $out/bin/                                                                             && \
#cp $work_dir/VocSynthFull            $out/bin/                                                                             && \
mkdir -p                              $out/include/VoiceOfFaust/PureData/                                                   && \
cp $work_dir/PureData/*               $out/include/VoiceOfFaust/PureData/                                                   && \
echo "done installing."                                                                                                      && \
echo "now run jack at low latency, run classicVocoder_PT, and sing into your microphone."                                    && \
echo "Executables with \"_PT\" in their name automatically run the pd pitchtracker and connect the input"                    && \
echo "If you want more flexibility, run the ones without \"_PT\""
