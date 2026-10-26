#!/usr/bin/env ruby
"""Add real-IP exceptions to a Mihomo blacklist-mode fake-ip-filter."""

require "yaml"

if ARGV.length < 2
  warn "usage: add_fakeip_filter_entries.rb CONFIG.yaml DOMAIN_OR_PATTERN ..."
  exit 2
end

config_path = ARGV.shift
entries = ARGV.reject(&:empty?).uniq
abort "no fake-ip-filter entries provided" if entries.empty?

data = YAML.load_file(config_path)
abort "config is not a YAML mapping" unless data.is_a?(Hash)

dns = data["dns"]
abort "config has no dns mapping" unless dns.is_a?(Hash)

mode = dns["fake-ip-filter-mode"].to_s
unless mode.empty? || mode == "blacklist"
  abort "this helper requires blacklist mode, current mode=#{mode}"
end

filters = (dns["fake-ip-filter"] ||= [])
abort "fake-ip-filter is not a list" unless filters.is_a?(Array)

added = entries.reject { |entry| filters.include?(entry) }
filters.concat(added)

File.open(config_path, "w") { |file| YAML.dump(data, file) }
puts "added=#{added.length}"
puts "total=#{filters.length}"
