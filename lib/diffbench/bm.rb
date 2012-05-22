class DiffBench
  class Bm
    def initialize(&block)
      @measures = {}
      if block.arity == -1 || block.arity > 0
        block.call(self)
      else
        instance_eval(&block)
      end

      print Encoder.encode(@measures)
    end

    def report(label)
      @measures[label] = Benchmark.measure do
        yield
      end
    end
  end
end
