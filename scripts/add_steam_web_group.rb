#!/usr/bin/env ruby
"""Add a dedicated Steam website proxy group and reusable routing rules."""

require "yaml"

if ARGV.length < 3
  warn "usage: add_steam_web_group.rb CONFIG.yaml GROUP_NAME NODE_REGEX [PREFERRED_NODE ...]"
  exit 2
end

config_path, group_name, node_pattern = ARGV.shift(3)
preferred_nodes = ARGV

data = YAML.load_file(config_path)
abort "config is not a YAML mapping" unless data.is_a?(Hash)

available_nodes = (data["proxies"] || []).filter_map do |proxy|
  proxy["name"] if proxy.is_a?(Hash)
end

begin
  node_regex = Regexp.new(node_pattern)
rescue RegexpError => error
  abort "invalid NODE_REGEX: #{error.message}"
end

matching_nodes = available_nodes.select { |name| name.to_s.match?(node_regex) }
ordered_nodes = preferred_nodes.select { |name| available_nodes.include?(name) }
ordered_nodes.concat(matching_nodes)
ordered_nodes.uniq!

abort "no proxy nodes matched NODE_REGEX or PREFERRED_NODE" if ordered_nodes.empty?

groups = (data["proxy-groups"] ||= [])
groups.reject! { |group| group.is_a?(Hash) && group["name"] == group_name }
groups.unshift(
  "name" => group_name,
  "type" => "select",
  "proxies" => ordered_nodes
)

steam_rules = [
  "DOMAIN-SUFFIX,steamcommunity.com,#{group_name}",
  "DOMAIN,api.steampowered.com,#{group_name}",
  "DOMAIN,login.steampowered.com,#{group_name}",
  "DOMAIN,store.steampowered.com,#{group_name}",
  "DOMAIN,help.steampowered.com,#{group_name}",
  "DOMAIN-SUFFIX,steamstatic.com,#{group_name}",
  "DOMAIN-SUFFIX,steamusercontent.com,#{group_name}",
  "DOMAIN-SUFFIX,steamcommunity-a.akamaihd.net,#{group_name}",
  "DOMAIN-SUFFIX,steamcdn-a.akamaihd.net,#{group_name}",
  "DOMAIN-SUFFIX,steam-chat.com,#{group_name}"
]

rules = (data["rules"] ||= [])
rules.reject! do |rule|
  rule.is_a?(String) && rule.end_with?(",#{group_name}")
end
data["rules"] = (steam_rules + rules).uniq

File.open(config_path, "w") { |file| YAML.dump(data, file) }
puts "group=#{group_name}"
puts "nodes=#{ordered_nodes.length}"
puts "rules=#{steam_rules.length}"
