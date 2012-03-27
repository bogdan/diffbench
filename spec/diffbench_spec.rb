require 'spec_helper'
require "fileutils"

describe DiffBench do
  let(:repo) do
    "#{File.dirname(__FILE__)}/repo"
  end
  let!(:git) do
    FileUtils.rm_rf(repo)
    FileUtils.mkdir(repo)
    git = Git.init(repo)
    FileUtils.cp("spec/code.rb", repo)
    FileUtils.cp("spec/bench.rb", "#{repo}/bench.rb")
    git.add("code.rb")
    git.commit("Init")
    git
  end


  describe "when git tree is dirty" do
    before do
      content = File.read("#{repo}/code.rb")
      File.open("#{repo}/code.rb", "w") do |f|
        f.write(content.gsub(/TIME = 0\.2/, "TIME = 0.1"))
      end
    end

    it "should run benchmark with dirty tree and clean tree" do
      puts `cd #{repo}; ./../../bin/diffbench bench.rb`
    end

    describe "when changes got commit" do

      before(:each) do
        git.add("code.rb")
        git.commit("Commit")
      end

      it "should run benchmark with HEAD and HEAD^" do
        puts `cd #{repo}; ./../../bin/diffbench bench.rb`
      end
    end
  end

  
end
