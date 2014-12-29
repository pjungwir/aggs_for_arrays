#!/usr/bin/env ruby

current_title = nil
current_chunk = nil
benches = {}
ms_paddings = []

STDIN.each_line do |line|
  line.chomp!
  blank = line.length == 0
  if blank
    current_title = nil
    current_chunk = []
  else
    if current_chunk
      if current_title
        if line =~ /(\d+(\.\d+)?) ms/
          current_chunk << $1
        end
      else
        current_title = line
        benches[current_title] = current_chunk
      end
    end
  end
end

0.upto(3) do |i|
  ms_paddings << benches.values.map do |v|
    if v[i] =~ /^(\d+)\.(\d+)$/
      $2.length
    else
      0
    end
  end.max
end

padding = benches.keys.map{|k| k.size}.max + 2
benches.each do |name, results|
  puts %Q{| %-#{padding}s | %10.#{ms_paddings[0]}f ms | %12.#{ms_paddings[1]}f ms | %16.#{ms_paddings[2]}f ms | %14.#{ms_paddings[3]}f ms |} % ["`#{name}`", *results]
end
