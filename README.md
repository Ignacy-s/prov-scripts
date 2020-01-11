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
   updating information in ~/.ssh/config with credentials of active VMs
   to facilitate usage of `ssh` or `emacs-tramp` with the machine names
   instead of IPs and Ports.
   
   \**vm-name is the name of the vagrant project directory*

## restoring-VMs.org
This is an emacs org file that contains journal style documentation of my efforts to redeploy (and automate this redeployment of) Osticket, Kanboard and Icinga. 
## TODO:
- check kanboard and osticket for run errors.
- prepare scripts to run on agent clients of icinga system.

