require 'memory_profiler'
require_relative 'task-2-ref.rb'
# require_relative 'task-2.rb'

report = MemoryProfiler.report do
  ReportGenerator.new.work(gc_disable: true)
end

report.pretty_print(scale_bytes: true)

# report = MemoryProfiler.report do
#   work(gc_disable: false)
# end
# report.pretty_print(scale_bytes: true)