# Testing

Laptop is tested by using it to provision a fresh VM. The process is lengthy
but scripted, and relies on Vagrant.

Currently, only the linux script is tested. See the dedicated section for
information about OSX testing.

## Prerequisites

1. [VirtualBox][]
2. [Vagrant][] - version >= 1.5.0
3. [aws-cli][] - optional, for publishers only.

[VirtualBox]: https://www.virtualbox.org/
[Vagrant]: http://www.vagrantup.com/
[aws-cli]: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html

`aws-cli` is only necessary if you're one of the maintainers and want to
publish new "laptopped" boxes after running tests.

## Running the tests

1. From the repository root, execute `./test/runner.sh`

## Details

For each file found at `./test/Vagrantfile.*`:

1. Vagrant creates and starts a VM as described by the Vagrantfile
2. The appropriate laptop script is run inside the VM
3. Some assertions are made against the VMs state
4. Vagrant stops and destroys the VM

The following are the assertions:

1. The VM was brought up successfully
2. The laptop script(s) ran successfully
3. The VM reports the correct `$SHELL`
4. The VM reports the correct ruby
5. A rails app can be created successfully
6. A scaffolded model can be created within that rails app
7. A default sqlite development and test database can be created and migrations can be run

You can test idempotency (allowing you to run the script multiple times in the
same environment) by exporting `KEEP_VM` before running `./test/runner.sh`
thusly:

    KEEP_VM=1 ./test/runner.sh

## OSX Testing

Adding additional linux tests via this framework should be easy: simply
add a new Vagrantfile under the test directory which uses a base box
with the desired distribution.

OSX will need to be handled specially:

1. The [VMware][] provider will have to be used
2. Building an OSX base box may or may not be easy
3. The resulting test can only be run on an OSX host

[VMware]: http://www.vmware.com/

## Publishing

First, you'll need to install and configure `aws-cli`. Create a
`~/.laptop-secrets` file that contains the email address that matches your
aws-cli config.

    S3_BOX_OWNER_EMAIL=your.s3.account.owner@example.com

When you're ready to publish a new set of boxes, run thusly:

    PUBLISH_BOXES=1 ./test/runner.sh

This will package all successful boxes and publish them to s3.  You do not
need to re-create or update the box config in vagrantcloud for an updated box,
as long as the URL stays the same.

## Removing a deprecated release

- Remove the vagrantfile under `test/`
- Remove the files published to s3
- Remove the box config in vagrantcloud
- Update README.md

## Creating new base boxes to test a new release

- Download a 64 bit minimal server ISO
- Set up a new virtualbox machine
    - Name it logically: `ubuntu-14-04-server` or similar
    - 512 meg of RAM
    - 2 CPUs
    - 8 gig dynamically allocated disk, choosing the default VDI storage

- Install. During installation:
    - Create a `vagrant` user with the password "vagrant"
    - Don't encrypt your home drive
    - Choose the minimal packages necessary to get a working SSH server

- Reboot. And then follow the [general base box instructions][], specifically:
    - Log in as the `vagrant` user, `sudo -i` and then set root's password to 'vagrant'
    - Modify `/etc/sudoers` to allow vagrant password-less `sudo` for all commands
    - Install the vagrant insecure SSH keypair into the `vagrant` account
    - Set up guest additions according to the [virtualbox provider docs][]. See [this bug in 4.3.10][].
    - Update and clean up: `aptitude update && aptitude dist-upgrade -y && aptitude clean`

- Package the new minimal base box.

    vagrant package --base ubuntu-14-04-server --output ubuntu-14-04-server.box

- Test the new base box.
    - Add the box to your local vagrant: `vagrant box add ubuntu-14-04-server.box --name ubuntu-14-04-server`
    - Create a minimal `Vagrantfile` that uses your new box by name
    - `vagrant up`
    - Connect to your box via `vagrant ssh`
    - Make sure you can see shared files under the `/vagrant` directory.
    - If it works, clean up after yourself:

    vagrant destroy
    vagrant box remove ubuntu-14-04-server

    - Remove the virtualbox you created from the release ISO if you're sure everything works.

- Upload the new base box to s3. Assuming you have aws-cli installed:

    aws s3 cp ubuntu-14-04-server.box s3://laptop-boxes/ \
      --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers full=emailaddress=S3_BOX_OWNER_EMAIL

where `S3_BOX_OWNER_EMAIL` is the email address of the account that should own these boxes.

- Add a new box config to vagrantcloud, named and described logically.
    - Create a version (0.1.0) and a provider with the s3 URL you created above.
    - Release the config. It's OK if the box hasn't been uploaded to s3 yet, vagrantcloud issues a 302 when a box is requested.

- Create a Vagrantfile under `test/` that uses the vagrantcloud remote name.
- Run `test/runner.sh` and see if laptop applied successfully.

Assuming laptop applies cleanly, re-run with `PUBLISH_BOXES` set or just always
run with this ENV variable and you can figure out errors later.

[general base box instructions]:http://docs.vagrantup.com/v2/boxes/base.html
[virtualbox provider docs]:http://docs.vagrantup.com/v2/virtualbox/boxes.html
[this bug in 4.3.10]:https://github.com/dotless-de/vagrant-vbguest/issues/117

## chsh errors

The test script may fail when changing the vagrant user's shell to `zsh`. If
this happens, you need to configure PAM to allow a user to change their shell
without a password. Open '/etc/pam.d/chsh' and change the line:

    auth		sufficient	pam_rootok.so

to

    auth		sufficient	pam_permit.so

which will allow the vagrant user to change their shell without a password.
You'll need to repackage and re-upload the base box with this change.
