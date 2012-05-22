class DiffBench
  class Encoder
    class << self
      def encode(object)
        "diffbench:#{Base64.encode64(object.to_yaml).gsub!("\n", "")}"
      end

      def decode(string)
        YAML.load(Base64.decode64(string.split(":").last))
      end
    end
  end
end
