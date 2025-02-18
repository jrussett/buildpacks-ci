#!/usr/bin/env ruby
# encoding: utf-8
require 'yaml'
require 'fileutils'
stack = ENV.fetch('STACK')

puts "Creating BOSH release capi with #{stack}"
version = "212.0.#{Time.now.strftime('%s')}"

%w[cc_deployment_updater cloud_controller_clock cloud_controller_ng cloud_controller_worker].each do |job|
  puts "handling #{job}"
  specfile = "../capi-release/jobs/#{job}/spec"
  spec = YAML.safe_load(File.read(specfile))
  if spec['properties']['cc.diego.lifecycle_bundles']['default'].keys.grep(/#{stack}/).none?
    spec['properties']['cc.diego.lifecycle_bundles']['default']["buildpack/#{stack}"] = 'buildpack_app_lifecycle/buildpack_app_lifecycle.tgz'
  end
  File.write(specfile, YAML.dump(spec))
end

FileUtils.cp_r '../capi-release/.', '../capi-release-artifacts'

puts "Running 'bosh create release' in capi-release"

Dir.chdir('../capi-release-artifacts') do
  puts `gem install bundler`
  Bundler.with_clean_env do
    puts `bosh2 create-release --force --tarball "dev_releases/capi/capi-#{version}.tgz" --name capi --version "#{version}"`
  end

  File.write('use-dev-release-opsfile.yml', "---
- type: replace
  path: /releases/name=capi
  value:
    name: capi
    version: #{version}
")

  File.write('use-rootfs-as-default-stack.yml', "---
- type: replace
  path: /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/cc/stacks?
  value:
  - name: #{stack}
    description: Cloud Foundry Linux-based filesystem (Ubuntu 18.04)
- type: replace
  path: /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/cc/default_stack?
  value: #{stack}
")
end
