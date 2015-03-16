#!/usr/bin/env sh
# a NixOS friendly prompt

#////////////////////////////////////////////////////////
# install everything you need to turn your voice into a synth
#////////////////////////////////////////////////////////

# check if we are on linux

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
echo "If you want to install those automatically, type yes. It will be a big download! (+/- 800Mb unpacked)"
echo -e "\n"
while true; do
  read -p "Do you want to install everything automatically?" yn
    case $yn in
        [Yy]* ) 
          echo "installing the nix package manager, see here for more info:"
          echo "http://nixos.org/nix/manual/#chap-quick-start"
          curl https://nixos.org/nix/install | sh                          && \
          echo 'source ~/.nix-profile/etc/profile.d/nix.sh' >> ~/.profile  && \
          . ~/.nix-profile/etc/profile.d/nix.sh                            && \
          nix-env -i git                                                   && \
          cd /tmp/                                                         && \
          git clone https://github.com/magnetophon/SynthSinger.git         && \
          nix-env -f faust/SynthSinger/SynthSinger.nix -i SynthSinger      && \
          break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
if [ $(which classicVocoder) ]; then
  echo "All synths built."                                                   && \
  echo "Now run \"sudo install_synths.sh\""
  echo "or, if you want to specify an instalation dir:"
  echo "\"sudo install_synths.sh\ /path/to/install/to/""
fi
