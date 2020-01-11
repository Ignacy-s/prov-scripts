# prov-scripts
   Based on the Linux in the Real World course, these scripts help with
   going through the exercises.
   Provisioning scripts can idempotently set up Vagrant Virtual
   Machines with apps from different projects.
   Helper scripts (not marked as provisioning) provide automation and
   empowerment to Vagrant commands, like:
   - wagrant $vagrant-sub-command $vm-name*
   running commands on any VM from any location (not just Vagrant's
   project directory)
   - bootme.sh $vm-name* [$vm-name*]
   booting up all the VMs that are being worked on
   - update_ssh_config.sh
   updating information in ~/.ssh/config to facilitate usage of `ssh` or
   `emacs-tramp` with the machine names instead of IPs and Ports.

## restoring-VMs.org
This is an emacs org file that contains journal style documentation of my efforts to redeploy (and automate this redeployment of) Osticket, Kanboard and Icinga. 
## TODO:
- check kanboard and osticket for run errors.
- prepare scripts to run on agent clients of icinga system.

