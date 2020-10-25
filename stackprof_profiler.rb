require_relative 'task-2-ref'
require 'stackprof'

StackProf.run(mode: :object, out: 'stackprof_reports/stackprof.dump', raw: true) do
  ReportGenerator.new.work(gc_disable: false)
end
