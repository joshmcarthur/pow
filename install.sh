#!/bin/bash
#                       W
#                      R RW        W.
#                    RW::::RW    DR::R
#         :RRRRRWWWWRt:::::::RRR::::::E        jR
#          R.::::::::::::::::::::::::::Ri  jiR:::R
#           R:::::::.RERRRRWWRERR,::::::Efi:::::::R             GjRRR Rj
#            R::::::.R             R:::::::::::::;G    RRj    WWR    RjRRRRj
#            Rt::::WR      RRWR     R::::::::::::::::fWR::R;  WRW    RW    R
#        WWWWRR:::EWR     E::W     WRRW:::EWRRR::::::::: RRED WR    RRW   RR
#        'R:::::::RRR            RR     DWW   R::::::::RW   LRRR    WR    R
#          RL:::::WRR       GRWRR        RR   R::WRiGRWW    RRR    RRR   R
#            Ri:::WWD    RWRRRWW   WWR   LR   R W    RR    RRRR    RR    R
#   RRRWWWWRE;,:::WW     R:::RW   RR:W   RR   ERE    RR    RRR    RRR    R
#    RR:::::::::::RR    tR:::WR   Wf:R   RW    R     R     RRR    RR    R
#      WR::::::::tRR    WR::RW   ER.R   RRR       R       RRRR    RR    R
#         WE:::::RR     R:::RR   :RW   E RR      RW;     GRRR    RR    R
#         R.::::,WR     R:::GRW       E::RR     WiWW     RRWR   LRRWWRR
#       WR::::::RRRRWRG::::::RREWDWRj::::RW  ,WR::WR    iRWWWWWRWW    R
#     LR:::::::::::::::::::::::::::::::::EWRR::::::RRRDi:::W    RR   R
#    R:::::::::::::::::::::::::::::::::::::::::::::::::::tRW   RRRWWWW
#  RRRRRRRRRRR::::::::::::::::::::::::::::::::::::,:::DE RRWRWW,
#            R::::::::::::: RW::::::::R::::::::::RRWRRR
#            R::::::::::WR.  ;R::::;R  RWi:::::ER
#            R::::::.RR       Ri:iR       RR:,R
#            E::: RE           RW           Y
#            ERRR
#            G       Zero-configuration Rack server for Mac OS X
#                    http://pow.cx/
#
#     This is the installation script for Pow.
#     See the full annotated source: http://pow.cx/docs/
#
#     Install Pow by running this command:
#     curl get.pow.cx | sh
#
#     Uninstall Pow: :'(
#     curl get.pow.cx/uninstall.sh | sh


# Set up the environment. Respect $VERSION if it's set.

      set -e
      POW_ROOT="$HOME/.pow_application"
      POW_BIN="$POW_ROOT/Current/bin/pow"
      [[ -z "$VERSION" ]] && VERSION=0.3.2


# Fail fast if we're not on Ubuntu
      if [ "$(cat /etc/lsb_release)" !~ "Ubuntu" ]; then
        echo "Sorry, but the Ubuntu branch of https://github.com/joshmcarthur/pow.git requires Ubuntu to run." >&2
        echo "If you are running Mac OS X > 10.6, use the main Pow repository (See http://pow.cx)." > &2
        exit 1
      fi
      
      if [ "$(which resolvconf)" != "/sbin/resolvconf" ]; then
        echo "The resolvconf package is required to run Pow on Ubuntu (sudo apt-get install resolvconf and try again)." >&2
        exit 1
      fi

      echo "*** Installing Pow $VERSION..."


# Create the Pow directory structure if it doesn't already exist.

      mkdir -p "$POW_ROOT/Hosts" "$POW_ROOT/Versions"


# If the requested version of Pow is already installed, remove it first.

      cd "$POW_ROOT/Versions"
      rm -rf "$POW_ROOT/Versions/$VERSION"


# Download the requested version of Pow and unpack it.

      curl -s https://github.com/joshmcarthur/pow/tarball/ubuntu | tar xzf -


# Update the Current symlink to point to the new version.

      cd "$POW_ROOT"
      rm -f Current
      ln -s Versions/$VERSION Current


# Create the ~/.pow symlink if it doesn't exist.

      cd "$HOME"
      [[ -a .pow ]] || ln -s "$POW_ROOT/Hosts" .pow


# Install local configuration files.

      echo "*** Installing local configuration files..."
      "$POW_BIN" --install-local


# Check to see whether we need root privileges.

      "$POW_BIN" --install-system --dry-run >/dev/null && NEEDS_ROOT=0 || NEEDS_ROOT=1


# Install system configuration files, if necessary. (Avoid sudo otherwise.)

      if [ $NEEDS_ROOT -eq 1 ]; then
        echo "*** Installing system configuration files as root..."
        sudo "$POW_BIN" --install-system
      fi


# Start (or restart) Pow.

      echo "*** Starting the Pow server..."
      /etc/init.d/pow start 2>/dev/null



# Check to see if the server is running properly.

      # If this version of Pow supports the --print-config option,
      # source the configuration and use it to run a self-test.
      CONFIG=$("$POW_BIN" --print-config 2>/dev/null || true)

      if [[ -n "$CONFIG" ]]; then
        eval "$CONFIG"
        echo "*** Performing self-test..."

        # Check to see if the server is running at all.
        function check_status() {
          sleep 1
          curl -sH host:pow "localhost:$POW_HTTP_PORT/status.json" | grep -c "$VERSION" >/dev/null
        }

        # Attempt to connect to Pow via each configured domain. If a
        # domain is inaccessible, try to force a reload of OS X's
        # network configuration.
        function check_domains() {
          for domain in ${POW_DOMAINS//,/$IFS}; do
            echo | nc "${domain}." "$POW_DST_PORT" 2>/dev/null || return 1
          done
        }

        # Use networksetup(8) to create a temporary network location,
        # switch to it, switch back to the original location, then
        # delete the temporary location. This forces reloading of the
        # system network configuration.
        function reload_network_configuration() {
          echo "*** Reloading system network configuration..."
          /etc/init.d/networking restart
        }

        # Try twice to connect to Pow. Bail if it doesn't work.
        check_status || check_status || {
          echo "!!! Couldn't find a running Pow server on port $POW_HTTP_PORT"
          exit 1
        }

        # Try resolving and connecting to each configured domain. If
        # it doesn't work, reload the network configuration and try
        # again. Bail if it fails the second time.
        check_domains || {
          { reload_network_configuration && check_domains; } || {
            echo "!!! Couldn't resolve configured domains ($POW_DOMAINS)"
            exit 1
          }
        }
      fi


# All done!

      echo "*** Installed"
