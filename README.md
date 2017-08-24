- Ansible playbook to deploy the REST TNG stack on OpenStack

## What this does

This playbook will build an Ensembl REST TNG cluster. It will install an haproxy router instance, a mysql server, and one or more catalyst, TaRK, and mod_faidx workers depending on your configuration. The machines will be auto-configured for their role and /etc/hosts will be updated so all machines know about each other.

## Requirement

- Ansible 2.3.x or above and the python shade module
- Access to an OpenStack instance
- [clouds.yaml](https://developer.openstack.org/sdks/python/openstacksdk/users/guides/connect_from_config.html) file configured to access the stack
- A Debian Stretch or Ubuntu Xenial image loaded on to OpenStack
- A volume containing mysql databases for one or more Ensembl releases and the TaRK database
- A key pair to use

## Installation

Edit the file `group_vars/all/vars.yml` for your local OpenStack configuration

Edit the file `group_vars/faidx_workers/vars.yml` if desired to change the fasta files that will be available from mod_faidx

Add entries to your ~/.ssh/config for accessing the cluster via the haproxy jump host that will be created:

```
Host 1.2.3.4                    # <-- your floating ip
  User debian                   # <-- default username for your image
  IdentityFile ~/.ssh/rest.pem  # <-- private key specified in group_vars/all/vars.yml
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host 192.168.0.*                # <-- private subnet in your OpenStack network
  HostName %h
  User debian                   # <-- name username from above
  ProxyCommand ssh -W %h:%p 1.2.3.4 # <-- floating ip
  IdentityFile ~/.ssh/rest.pem  # <-- private key
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```

Once configured you should now be able to build the cluster with:

```
ansible-playbook provision_stack.yml
```

## Using

Once built you should have urls available such as

- http://1.2.3.4/lookup/gene/?id=ENSG00000198001&expand=1
- http://1.2.3.4/sequence/region/GRCh38
- http://1.2.3.4/sequence/sets/
- http://1.2.3.4/sequence/region/GRCh38?location=19%3A10000-15000&location=X%3A10000-11000#

## Deleting the stack

With all the above configurations still in place, run the playbook:

```
ansible-playbook delete_stack.yml
```
