#!/usr/bin/env sh
source ./test/common
source ~/.laptop.secrets

set_box_names() {
  LAPTOP_BASENAME="$(echo "$successful_laptop_build" | cut -d'.' -f2-)";
  VIRTUALBOX_NAME="laptop-$LAPTOP_BASENAME";
  BOX_NAME="$LAPTOP_BASENAME-with-laptop.box"
}

publish_box(){
  set_box_names

  rm -f "$BOX_NAME"

  message "Creating $BOX_NAME from $VIRTUALBOX_NAME"
  vagrant package --base "$VIRTUALBOX_NAME" --output "$BOX_NAME"
  message "Done creating $BOX_NAME"

  message "Removing existing box: $BOX_NAME"
  aws s3 rm "s3://laptop-boxes/$BOX_NAME"

  message "Uploading box to s3: $BOX_NAME"
  aws s3 cp "$BOX_NAME" s3://laptop-boxes/ --grants \
    read=uri=http://acs.amazonaws.com/groups/global/AllUsers \
    full=emailaddress=$S3_BOX_OWNER_EMAIL && \
    rm "./test/succeeded.$successful_laptop_build"
}

if ! command -v aws &>/dev/null; then
  failure_message 'You must install aws-cli to publish boxes'
  exit 1
fi

for successful_laptop_build in test/succeeded.*; do
  if [ -e "$vagrantfile" ]; then
    publish_box
  fi
done
