require 'celluloid'
module SvmToolkit
  class Svm
    def self.cross_validation_search(*args)
      Celluloid::Actor[:grid_search] = GridSearch.new
      Celluloid::Actor[:grid_search].search *args
    end
  end
  class GridSearch
    include Celluloid
    def search(training_set, cross_valn_set, 
               costs = [-2,-1,0,1,2,3].collect {|i| 2**i}, 
               gammas = [-2,-1,0,1,2,3].collect {|i| 2**i}, 
               params = {})
      evaluator = params.fetch(:evaluator, Evaluator::OverallAccuracy)
      train_whole = params.fetch(:train_whole, false)

      Celluloid::Actor[:collector] = SvmCollector.new(size:gammas.size*costs.size)
      worker = SvmWorker.pool(args: [ {evaluator: evaluator, cross_valn_set: cross_valn_set}] )
      gammas.each do |gamma|
        results_row = []
        costs.each do |cost|
          worker.train!(training_set, Parameter.new(
            :svm_type => Parameter::C_SVC,
            :kernel_type => Parameter::RBF,
            :cost => cost,
            :gamma => gamma
          ))
        end
      end

      model, results = wait :collecting
      return model, results
    end
    def finished_collecting *args
      signal :collecting, *args
    end

  end
  private
  class SvmWorker
    include Celluloid
    def initialize args
      @evaluator = args[:evaluator]
      @cross_valn_set = args[:cross_valn_set]
    end
    def train *args
      evaluate Svm.svm_train(*args)
    end
    def evaluate model
      result = model.evaluate_dataset(@cross_valn_set, :evaluator => @evaluator)
      puts "Result for cost = #{model.cost}  gamma = #{model.gamma} is #{result.value}"
      Celluloid::Actor[:collector].collect(model, result)
    end
  end
  class SvmCollector
    include Celluloid
    attr_accessor :count
    attr_accessor :results
    attr_accessor :model
    attr_accessor :lowest_error

    def initialize args
      @count = args[:size]
      @results = []
    end
    def collecting
      @results.size < @count
    end
    def collect model, result
      if result.better_than? lowest_error
        self.model = model
        self.lowest_error = result
      end
      results << { cost: model.cost, gamma: model.gamma, result: result }
      if results.size == count
        Celluloid::Actor[:grid_search].finished_collecting [self.model, self.results]
      end
    end
  end
end