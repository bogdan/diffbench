$LOAD_PATH.unshift "./lib"
require 'diffbench'
load File.dirname(__FILE__) + "/code.rb"

DiffBench.bm do
  report "Sleeper 1" do
    Sleeper.run
  end
  report "Sleeper 2" do
    Sleeper.run
  end
end
