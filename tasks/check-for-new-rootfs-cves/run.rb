#!/usr/bin/env ruby
# encoding: utf-8

stack = ENV['STACK']

buildpacks_ci_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
stacks_dir = File.expand_path(File.join(buildpacks_ci_dir, '..', stack.gsub(/m$/, '')))
cves_dir = File.expand_path(File.join(buildpacks_ci_dir, '..', 'output-new-cves', 'new-cve-notifications'))

require "#{buildpacks_ci_dir}/lib/rootfs-cve-notifier"

cve_notifier = RootFSCVENotifier.new(cves_dir, stacks_dir)

case stack
when 'cflinuxfs3'
  cve_notifier.run!(stack, 'Ubuntu 18.04', 'ubuntu18.04', [])
else
  raise "Unsupported stack: #{stack}"
end
