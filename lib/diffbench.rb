require "yaml"
require "benchmark"
require "git"
require "base64"
require "optparse"
require "diffbench/encoder"
require "diffbench/bm"

class DiffBench

  class Runner
    COLORS = {:red => 31, :green => 32, :yellow => 33}

    def initialize(*args)
      parser = OptionParser.new do |opts|
        opts.banner = <<-DOC
Usage: diffbench [options] file

When working tree is dirty default is run benchmark againts dirty tree and clean tree.
When working tree is clean default is run benchmark against current head and previous commit.
DOC
        
        opts.on("-r", '--revision [REVISIONS]', 'Specify revisions to run benchmark (comma separated). Example: master,f9a845,v3.1.4') do |value|
          if tree_dirty?
            raise Error, "Working tree is dirty."
          end
          @revisions = value.split(",")
        end
        opts.on("-b", '--before [COMMAND]', 'Specify command to run before each benchmark run. e.g. bundle install') do |value|
          @before_command = value
        end

        opts.on_tail('-h', '--help', 'Show this help') do
          output opts
          exit
        end
      end
      parser.parse!(args)
      @file = args.first or raise Error, 'File not specified'
    end

    def run
      if @revisions
        run_revisions
      else
        run_current_head
      end
    end

    def run_revisions
      branch = current_head
      
      results = begin
        @revisions.inject({}) do |result, revision|
          output "Checkout to #{revision}"
          output "Run benchmark with #{revision}"
          git_run("checkout '#{revision}'")
          result[revision] = run_file
          result
        end
      ensure
        output "Checkout to #{branch}"
        git_run("checkout '#{branch}'")
      end
      print_results(results)
    end

    def print_results(results)
      output ""
      #TODO set caption the right way
      caption = "Before patch: ".gsub(/./, " ") +  Benchmark::Tms::CAPTION
      output caption
      tests = results.values.first.keys
      tests.each do |test|
        output(("-" * (caption.size - test.size)) + test)
        results.each do |revision, benchmark|
          output "#{revision}: #{benchmark[test].format}"
        end
        #TODO set improvement
        #improvement = improvement_percentage(before_patch, after_patch)
        #color_string = result_color(improvement)
        #output self.class.color("Improvement: #{improvement}%", color_string).strip
        output ""
      end
    end

    def run_current_head
      output "Running benchmark with current working tree"
      first_run = run_file
      if tree_dirty?
        output "Stashing changes"
        git_run "stash"
        output "Running benchmark with clean working tree"
        begin
          second_run = run_file
        ensure
          output "Applying stashed changes back"
          git_run "stash pop"
        end
      elsif branch = current_head
        output "Checkout HEAD^"
        git_run "checkout 'HEAD^'"
        output "Running benchmark with HEAD^"
        begin
          second_run = run_file
        ensure
          output "Checkout to previous HEAD again"
          git_run "checkout #{branch}"
        end
      else
        raise Error, "No current branch."
      end
      output ""
      caption = "Before patch: ".gsub(/./, " ") +  Benchmark::Tms::CAPTION
      output caption
      first_run.keys.each do |test|
        output(("-" * (caption.size - test.size)) + test)
        before_patch = second_run[test]
        after_patch = first_run[test]
        improvement = improvement_percentage(before_patch, after_patch)
        color_string = result_color(improvement)
        output "After patch:  #{after_patch.format}"
        output "Before patch: #{before_patch.format}"
        output self.class.color("Improvement: #{improvement}%", color_string).strip
        output ""
      end
    end

    def improvement_percentage(before_patch, after_patch)
      (((before_patch.real - after_patch.real).to_f / before_patch.real) * 100).round
    end

    def self.color(text, color_string)
      code = COLORS[color_string]
      self.color_enabled? ? "\e[#{code}m#{text}\e[0m" : text
    end
    
    def self.color_enabled?
      true
    end

    protected

    def result_color(improvement)
      if (-5..5).include?(improvement)
        :yellow
      else
        improvement > 0 ? :green : :red
      end
    end

    def current_head
      branch = git.current_branch.to_s 
      return branch if !(branch == "(no branch)")
      branch = git_run("symbolic-ref HEAD").gsub(/^refs\/head\//, "")
      return branch unless branch.empty?
    rescue Git::GitExecuteError
      branch = git_run("rev-parse HEAD")[0..7]
      return branch
    end

    def run_file
      output `#{@before_command}` if @before_command
      output = `ruby -I#{File.dirname(__FILE__)} #{@file}`
      output.split("\n").select! do |line|
        if line.start_with?("diffbench:")
          true
        else
          output line
        end
      end
      if $?.to_i > 0
        raise Error, "Error exit code: #{$?.to_i}"
      end
      begin
        result = Encoder.decode(output) 
        raise Error, "Can not parse result of ruby script: \n #{output}" unless result.is_a?(Hash)
        result
      rescue Psych::SyntaxError
        raise Error, "Can not run ruby script: \n#{output}"
      end
    end

    def git_run(command)
      git.lib.send(:command, command)
    end

    def git
      @git ||= Git.open(discover_git_dir)
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

    def tree_dirty?
      status = git.status
      status.deleted.any? || status.changed.any?
    end

    def output(string)
      puts string
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


  class Error < StandardError; end
end
