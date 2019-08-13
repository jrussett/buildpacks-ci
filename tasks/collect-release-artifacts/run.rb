#!/usr/bin/env ruby

require 'octokit'
require 'yaml'
require 'rubygems'
require 'zip'
require 'digest'
require 'fileutils'
require_relative './release-artifacts'

repo = ENV.fetch('REPO', '')
stack = ENV.fetch('STACK', "cflinuxfs3")
GITHUB_ACCESS_TOKEN = ENV.fetch('GITHUB_ACCESS_TOKEN', '')

Octokit.configure do |c|
  c.access_token = GITHUB_ACCESS_TOKEN
end

old_manifest_deps = {}
latest_release_path = ReleaseArtifacts.download_latest_release(repo)
if File.exist? latest_release_path
  old_manifest = ReleaseArtifacts.open_manifest_from_zip(latest_release_path)
  old_manifest_deps = ReleaseArtifacts.reduce_manifest(old_manifest)
end

rc_path = Dir.glob(File.join("release-candidate", "*-v*.zip")).first
absolute_rc_path = File.absolute_path(rc_path)
current_manifest = ReleaseArtifacts.open_manifest_from_zip(absolute_rc_path)
current_manifest_deps = ReleaseArtifacts.reduce_manifest(current_manifest)

cnb_version_diff = ReleaseArtifacts.find_version_diff(old_manifest_deps, current_manifest_deps)

version = File.read(File.join("version", "version")).strip()
tag = "v#{version}"
release_notes = ReleaseArtifacts.compile_release_notes(repo, tag, cnb_version_diff)
puts release_notes

rc_shasum = Digest::SHA256.file(absolute_rc_path).hexdigest

output_dir = File.absolute_path("buildpack-artifacts")
bp_name = "#{repo}-compat-#{stack}-#{tag}.zip"
sha_file_name = "#{bp_name}.SHA256SUM.txt"
File.write(File.join(output_dir, "tag"), tag)
File.write(File.join(output_dir, "release_notes"), release_notes)
FileUtils.mv(absolute_rc_path, File.join(output_dir, bp_name))
File.write(File.join(output_dir, sha_file_name), rc_shasum)