#!/usr/bin/env ruby
"""Remove subscription information proxies and all references to them."""

require "yaml"

path = ARGV.fetch(0) do
  warn "usage: filter_pseudo_nodes.rb CONFIG.yaml"
  exit 2
end

data = YAML.load_file(path)
pattern = /套餐|到期|官网|客户端|说明|如您只有|订阅|网址|群组|过期|剩余|重置|流量|协议|升级|Traffic|Expire|Plan|Official/i
removed_proxies = 0
removed_refs = 0

(data["proxies"] || []).reject! do |proxy|
  remove = proxy.is_a?(Hash) && proxy["name"].to_s.match?(pattern)
  removed_proxies += 1 if remove
  remove
end

empty_groups = []
(data["proxy-groups"] || []).each do |group|
  next unless group["proxies"].is_a?(Array)

  before = group["proxies"].length
  group["proxies"].reject! { |name| name.to_s.match?(pattern) }
  removed_refs += before - group["proxies"].length
  empty_groups << group["name"] if group["proxies"].empty?
end

unless empty_groups.empty?
  abort "refusing to create empty groups: #{empty_groups.join(', ')}"
end

File.open(path, "w") { |file| YAML.dump(data, file) }
puts "removed_proxy_nodes=#{removed_proxies}"
puts "removed_group_references=#{removed_refs}"
