                          UnitWarden

Description:
UnitWarden is a comprehensive Bash utility for auditing, visualizing,
and detecting all systemd unit files on a Linux host. It identifies
every active, inactive, static, and masked unit known to systemd, as
well as any hidden or rogue unit files located outside standard
directories.

UnitWarden was built for incident response, red-team validation,
and blue-team hardening to ensure no unauthorized or stealth
systemd units persist within a system.

FEATURES
1. Lists all systemd unit files and active units, including:
   - Services, sockets, timers, mounts, targets, slices, and more.
   - Both static (installed) and dynamic (runtime) units.

2. Displays full metadata for each unit:
   - LoadState, ActiveState, FragmentPath, and DropInPaths.

3. Detects hidden or rogue unit files outside standard paths:
   - Searches in configurable directories (default: /tmp:/opt:/home:/usr/local:/srv).
   - Highlights suspicious or non-standard units in red.

4. Color-coded output for rapid triage:
   - Green   = Enabled or Active
   - Yellow  = Disabled or Inactive
   - Magenta = Masked or Failed
   - Cyan    = Static, Indirect, or Other
   - Red     = Hidden or Suspicious

5. Lightweight and portable:
   - Requires only standard Bash utilities and systemctl.
   - No external dependencies.

USAGE
1. Make the script executable: chmod +x unitwarden.sh

2. Run with default paths: ./unitwarden.sh

3. Run with custom search paths:
./unitwarden.sh "/opt:/tmp:/srv"

4. Disable color output (for log or CI usage):
      NO_COLOR=1 ./unitwarden.sh

5. Example: ./unitwarden.sh "/opt:/tmp"

   Output will display:
      - All known systemd units (loaded and on-disk)
      - All active/inactive service instances
      - Any hidden unit files in specified paths

OUTPUT LEGEND
Each listed unit includes its current load and active state,
and the file where it resides.

Example:
   NetworkManager.service                      (loaded/active)
       Fragment: /usr/lib/systemd/system/NetworkManager.service

Hidden unit example:
   Hidden: /opt/hidden-test.service
       [Unit]
       Description=Hidden Test Service (for detection only)

CUSTOMIZATION
• To search additional directories for hidden units:
      ./unitwarden.sh "/mnt:/srv:/var/tmp"

• To extend color support or integrate with log parsers,
  redirect output:
      ./unitwarden.sh --no-color > audit-report.txt

TROUBLESHOOTING
• If new units are not visible to systemd, reload the daemon:
      sudo systemctl daemon-reload

• Some unit files require root privileges to read. Run as root
  for complete coverage: sudo ./unitwarden.sh

RECOMMENDED USAGE
- Run periodically on servers and workstations to detect new or
  unauthorized units.
- Integrate into incident response or configuration integrity
  monitoring systems.
- Use as part of compliance audits for systemd-based systems.

LEGAL DISCLAIMER
UnitWarden is provided "AS IS" without any warranty of any kind,
express or implied, including but not limited to warranties of
merchantability, fitness for a particular purpose, or non-infringement.

The author and contributors shall not be held liable for any direct,
indirect, incidental, special, exemplary, or consequential damages
(including, but not limited to, loss of data, service interruption,
or system damage) arising in any way from the use, misuse, or
inability to use this program.

Use of UnitWarden is at your own risk. The program is intended for
security auditing, research, and educational purposes only.
Do not deploy or use UnitWarden on systems you do not own or have
explicit authorization to test.