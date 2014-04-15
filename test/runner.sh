#!/usr/bin/env sh
source ~/.laptop.secrets

FAILED=false

message() {
  printf "\e[1;34m:: \e[1;37m%s\e[0m\n" "$*"
}

failure_message() {
  printf "\n\e[1;31mFAILURE\e[0m: \e[1;37m%s\e[0m\n\n" "$*" >&2;
}

failure() {
  FAILED=true
  failure_message
  continue
}

vagrant_destroy() {
  if [ -z "$KEEP_VM" ]; then
    vagrant destroy --force
  fi
}

publish_box(){
  LAPTOP_BASENAME=$(echo "$vagrantfile" | cut -d'.' -f2-);
  VIRTUALBOX_NAME="laptop-$LAPTOP_BASENAME";
  BOX_NAME="$LAPTOP_BASENAME-with-laptop.box"

  rm -f $BOX_NAME

  message "Creating $BOX_NAME from $VIRTUALBOX_NAME"
  vagrant package --base $VIRTUALBOX_NAME --output $BOX_NAME
  message "Done creating $BOX_NAME"

  message "Removing existing box: $BOX_NAME"
  aws s3 rm s3://laptop-boxes/$BOX_NAME

  message "Uploading box to s3: $BOX_NAME"
  aws s3 cp $BOX_NAME s3://laptop-boxes/ --grants \
    read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
    full=emailaddress=$S3_BOX_OWNER_EMAIL
}

if ! vagrant -v | grep -qiE 'Vagrant 1.5'; then
  failure_message 'You must use vagrant >= 1.5.0 to run the test suite.'
  exit 1
fi

message "Building latest scripts"
./bin/build.sh

for vagrantfile in test/Vagrantfile.*; do
  FAILED=false

  message "Testing with $vagrantfile"

  ln -sf "$vagrantfile" ./Vagrantfile || failure "Unable to link Vagrantfile $vagrantfile"

  message 'Destroying and recreating virtual machine'
  vagrant_destroy
  vagrant up || failure "$vagrantfile :: Unable to start virtual machine"

  # TODO: Create a Vagrantfile.mac that uses VMWare Fusion to run OSX
  if echo "$vagrantfile" | grep -q '\.mac$'; then
    vagrant ssh -c 'echo vagrant | bash /vagrant/mac' \
      || failure "$vagrantfile :: Installation script failed to run"
  else
    vagrant ssh -c 'echo vagrant | bash /vagrant/linux' \
      || failure "$vagrantfile :: Installation script failed to run"
  fi

  vagrant ssh -c '[ "$SHELL" = "/usr/bin/zsh" ]' \
    || failure "$vagrantfile :: Installation did not set \$SHELL to ZSH"

  ruby_version="$(curl -sSL http://ruby.thoughtbot.com/latest)"

  vagrant ssh -c 'zsh -i -l -c "ruby --version" | grep -Fq "$ruby_version"' \
    || failure "$vagrantfile :: Installation did not install the correct ruby"

  vagrant ssh -c 'zsh -i -l -c "rm -Rf ~/test_app && cd ~ && rails new test_app"' \
    || failure "$vagrantfile :: Could not successfully create a rails app"

  vagrant ssh -c 'zsh -i -l -c "cd ~/test_app && rails g scaffold post title:string"' \
    || failure "$vagrantfile :: Could not successfully generate a scaffolded model"

  vagrant ssh -c 'zsh -i -l -c "cd ~/test_app && rake db:create db:migrate db:test:prepare"' \
    || failure "$vagrantfile :: Could not successfully initialize databases and migrate"

  vagrant ssh -c 'zsh -i -l -c "rm -Rf ~/test_app"'
  vagrant ssh -c 'zsh -i -l -c "sudo aptitude clean"'

  if [ "$FAILED" = true ]; then
    failure_message "$vagrantfile :: The automated tests failed. Please look for error messages above"
  else
    message "$vagrantfile tests succeeded"
    if [ $PUBLISH_BOXES ]; then
      message 'publishing box'
      publish_box
    fi
  fi

  vagrant halt
  sleep 30
  vagrant_destroy
  sleep 30
done
