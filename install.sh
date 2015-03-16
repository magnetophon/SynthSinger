#!/usr/bin/env sh
# a NixOS friendly prompt

#////////////////////////////////////////////////////////
# install everything you need to turn your voice into a synth
#////////////////////////////////////////////////////////

# check if we are on linux

work_dir="$(dirname $0:A)"
faust_version=$(faust -v | grep Version | tr -dc '[:digit:]')
#if [[$faust_version  -gt 967]]  && [[$(which pd)]]; then
if [ $faust_version  -gt 967 ]; then
  if [ $(which pd-extended) ]; then
    if [ $(which git) ]; then
      ./scripts/build_synths.sh && exit
    fi
  fi
fi

echo -e "\n"
echo "For a properly working VoiceOfFaust, you need the git version of Faust."
echo "You also need either puredata with mrpeach, or pd-extended"
echo "If you want to install those manually, type no to exit this script, and try again later."
echo "If you want to install those automatically, type yes. It will be a big download! (1.1Gb unpacked)"
echo -e "\n"
while true; do
  read -p "Do you want to install everything automatically?" yn
    case $yn in
        [Yy]* ) 
          echo -e "\n"
          echo "installing the nix package manager, see here for more info:"
          echo "http://nixos.org/nix/manual/#chap-quick-start"
          echo -e "\n"
          curl https://nixos.org/nix/install | sh              && \
          . ~/.nix-profile/etc/profile.d/nix.sh                && \
          nix-env -f $work_dir/SynthSinger.nix -i SynthSinger  && \
          break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
if [ $(which classicVocoder) ]; then
  echo -e "\n"
  echo "Everything installed successfully."
  echo -e "\n"
  echo "You now have:"
  echo "\". ~/.nix-profile/etc/profile.d/nix.sh\""
  echo "in your ~/.profile,"
  echo "Unfortunately, not every linux sources the profile properly."
  echo -e "\n"
  echo "Now run jack at low latency, run classicVocoder_PT, and sing into your microphone."                          && \
  echo "Executables with \"_PT\" in their name automatically run the needed pd pitchtracker and connect the input."  && \
  echo "If you want more flexibility, run the ones without \"_PT\""
fi
