{ stdenv
, coreutils
, fetchgit
, makeWrapper
, pkgconfig
}:

with stdenv.lib.strings;

let

  version = "8-1-2015";

  src = fetchgit {
    url = git://git.code.sf.net/p/faudiostream/code;
    rev = "4db76fdc02b6aec8d15a5af77fcd5283abe963ce";
    sha256 = "f1ac92092ee173e4bcf6b2cb1ac385a7c390fb362a578a403b2b6edd5dc7d5d0";
  };

  meta = with stdenv.lib; {
    homepage = http://faust.grame.fr/;
    downloadPage = http://sourceforge.net/projects/faudiostream/files/;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.magnetophon ];
  };

  faust = stdenv.mkDerivation {

    name = "faust-${version}";

    inherit src;

    buildInputs = [ makeWrapper ];

    passthru = {
      inherit wrap wrapWithBuildEnv;
    };

    preConfigure = ''
      makeFlags="$makeFlags prefix=$out"

      # The faust makefiles use 'system ?= $(shell uname -s)' but nix
      # defines 'system' env var, so undefine that so faust detects the
      # correct system.
      unset system
    '';

    # Remove some faust2appl scripts since they won't run properly
    # without additional paths setup. See mkFaust2Appl.
    postInstall = ''
      # syntax error when eval'd directly
      pattern="faust2!(svg)"
      (shopt -s extglob; rm "$out"/bin/$pattern)
    '';

    postFixup = ''
      # Set faustpath explicitly.
      substituteInPlace "$out"/bin/faustpath \
        --replace "/usr/local /usr /opt /opt/local" "$out"

      # Normally, I'd use makeWrapper to prefix the PATH variable with
      # ${coreutils}/bin, however 'faustoptflags' is 'source'd into
      # other faust scripts and not used as an executable, so patch
      # 'uname' usage directly.
      substituteInPlace "$out"/bin/faustoptflags \
        --replace uname "${coreutils}/bin/uname"

      # wrapper for scripts that don't need mkFaust2Appl
      for script in "$out"/bin/faust2*; do
        wrapProgram "$script" \
          --prefix PATH : "$out"/bin
      done
    '';

    meta = meta // {
      description = "A functional programming language for realtime audio signal processing";
      longDescription = ''
        FAUST (Functional Audio Stream) is a functional programming
        language specifically designed for real-time signal processing
        and synthesis. FAUST targets high-performance signal processing
        applications and audio plug-ins for a variety of platforms and
        standards.
        The Faust compiler translates DSP specifications into very
        efficient C++ code. Thanks to the notion of architecture,
        FAUST programs can be easily deployed on a large variety of
        audio platforms and plugin formats (jack, alsa, ladspa, maxmsp,
        puredata, csound, supercollider, pure, vst, coreaudio) without
        any change to the FAUST code.

        This package has just the compiler, libraries, and headers.
        Install faust for the full set of faust2somethingElse tools.
      '';
    };

  };

  # Default values for faust2appl.
  faust2ApplBase =
    { baseName
    , dir ? "tools/faust2appls"
    , scripts ? [ baseName ]
    , ...
    }:

    {
      name = "${baseName}-${version}";

      inherit src;

      configurePhase = ":";

      buildPhase = ":";

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/bin"
        for script in ${concatStringsSep " " scripts}; do
          cp "${dir}/$script" "$out/bin/"
        done

        runHook postInstall
      '';

      postInstall = ''
        # For the faust2appl script, change 'faustpath' and
        # 'faustoptflags' to absolute paths.
        #
        # TODO: I noticed only some faust2appl scripts use these. The others
        # may need different modifications.
        for script in "$out"/bin/*; do
          substituteInPlace "$script" \
            --replace ". faustpath" ". '${faust}/bin/faustpath'" \
            --replace ". faustoptflags" ". '${faust}/bin/faustoptflags'"
        done
      '';

      meta = meta // {
        description = "The ${baseName} script, part of faust functional programming language for realtime audio signal processing";
      };
    };

  # Builder for 'faust2appl' scripts, such as faust2alsa, that run
  # faust to generate cpp code, then invoke the c++ compiler to build
  # the code. This builder wraps these scripts in parts of the stdenv
  # such that when the scripts are called outside any nix build, they
  # behave as if they were running inside a nix build in terms of
  # compilers and paths being configured.
  #
  # The function takes two main args: the appl name (e.g.
  # 'faust2alsa') and an optional list of propagatedBuildInputs. It
  # returns a derivation that contains only the bin/${appl} script,
  # wrapped up so that it will run as if it was inside a nix build
  # with those build inputs.
  #
  # The build input 'faust' is automatically added to the
  # propagatedBuildInputs.
  wrapWithBuildEnv =
    { baseName
    , propagatedBuildInputs ? [ ]
    , ...
    }@args:

    stdenv.mkDerivation ((faust2ApplBase args) // {

      buildInputs = [ makeWrapper pkgconfig ];

      propagatedBuildInputs = [ faust ] ++ propagatedBuildInputs;

      postFixup = ''
        # This exports parts of the stdenv, including gcc-wrapper, so
        # that the faust2appl scripts will build things correctly. For
        # example, rpath is set so that compiled binaries link to the
        # libs inside the nix store (run 'ldd' on the compilation
        # result)
        for script in "$out"/bin/*; do
          wrapProgram "$script" \
            --set FAUST_LIB_PATH "${faust}/lib/faust" \
            --prefix PATH : "$PATH" \
            --prefix PKG_CONFIG_PATH : "$PKG_CONFIG_PATH" \
            --set NIX_CFLAGS_COMPILE "\"$NIX_CFLAGS_COMPILE\"" \
            --set NIX_LDFLAGS "\"$NIX_LDFLAGS\""
        done
      '';
    });

  # Builder for 'faust2appl' scripts, such as faust2firefox that
  # simply need to be wrapped with some dependencies on PATH.
  #
  # The build input 'faust' is automatically added to the PATH.
  wrap =
    { baseName
    , runtimeInputs ? [ ]
    , ...
    }@args:

    let

      runtimePath = concatStringsSep ":" (map (p: "${p}/bin") ([ faust ] ++ runtimeInputs));

    in stdenv.mkDerivation ((faust2ApplBase args) // {

      buildInputs = [ makeWrapper ];

      postFixup = ''
        for script in "$out"/bin/*; do
          wrapProgram "$script" --prefix PATH : "${runtimePath}"
        done
      '';

    });

in faust
