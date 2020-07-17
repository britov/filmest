#!/bin/bash

GEM_HOME="./vendor/bundle/ruby/2.6.0"
gem install --install-dir $GEM_HOME bundler
bundle install
