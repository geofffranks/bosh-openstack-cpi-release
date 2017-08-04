#!/usr/bin/env bash

set -e
set -x

echo "Check if latest auto-update commit has already been merged to master"
pr_open=$(git branch master --contains $(git rev-parse origin/auto-update))
if [ -z ${pr_open} ]; then
  echo "PR is open. Merge first"
  exit 1
fi

cd bosh-cpi-src-in
pushd src/bosh_openstack_cpi
  echo "Looking for new gem versions"
  rm Gemfile.lock
  ./vendor_gems
  git diff --exit-code Gemfile.lock || exit_code=$?
  if [ -v exit_code ]; then
    echo "Running unit tests"
    bundle install
    bundle exec rspec spec/unit/*

    echo "Creating new pull request"
      git add .
      git config --global user.email cf-bosh-eng@pivotal.io
      git config --global user.name CI
      git commit -m "Bump gems"
      git push origin HEAD:auto-update
      hub pull-request -f -b master -h auto-update-m "Bump gems"
  else
    echo "No new gem versions found"
  fi
popd