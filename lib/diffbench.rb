require "yaml"
require "benchmark"
require "git"

class DiffBench

  class Runner
    def initialize(file, *args)
      @file = file
      unless @file
        raise Error, "File not specified"
      end
    end

    def run
      first_run = run_file
      git "stash"
      second_run = run_file
      git "stash pop"
      first_run.keys.each do |test|
        puts "-"* 10 + test + "-" * 10
        puts "New: #{first_run[test].format}"
        puts "Old: #{second_run[test].format}"
      end
    end

    def run_file
      output = `ruby #{@file}`
      begin
        YAML.load(output) 
      rescue Psych::SyntaxError
        raise Error, "Can not run ruby script: \n#{output}"
      end
    end

    def git(command)
      @git ||= Git.open(discover_git_dir).lib
      @git.send(:command, command)
    end

    def discover_git_dir
      tokens = ENV['PWD'].split("/")
      while tokens.any?
        path = tokens.join("/")
        if File.exists?(path + "/.git")
          return path
        end
        tokens.pop
      end
      raise Error, "Git working dir not found"
    end
  end

  class << self

    def run(*args)
      Runner.new(*args).run
    end
    def bm(&block)
      DiffBench::Bm.new(&block)
    end

  end

  class Bm
    def initialize(&block)
      @measures = {}
      instance_eval(&block)
      puts @measures.to_yaml
    end


    def report(label)
      @measures[label] = Benchmark.measure do
        yield
      end
    end
  end
  class Error < StandardError; end
end
