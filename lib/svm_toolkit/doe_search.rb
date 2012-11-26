require 'celluloid'
module SvmToolkit
  class Svm
    def self.doe_search(args={})
      Celluloid::Actor[:search] = Search.new args.fetch(:folds) { 3 }
      Celluloid::Actor[:search].search *args
    end
  end
  class Search
    include Celluloid
    attr_accessor :number_of_folds
    def initialize number_of_folds
      self.number_of_folds = number_of_folds
    end
    def search(args={})
      feature_vectors = args[:feature_vectors]
      cost_min = args.fetch(:cost_min) { -5 }
      cost_max = args.fetch(:cost_max) { 15 }
      gamma_min = args.fetch(:gamma_min) { -15 }
      gamma_max = args.fetch(:gamma_max) { 9 }
      evaluator = params.fetch(:evaluator, Evaluator::OverallAccuracy)
      max_iterations = params.fetch(:interations) { 1 }

      *folds,_ = feature_vectors.each_slice(feature_vectors.size/number_of_folds).map{|set|
                   Problem.from_array(set.map(&:data), set.map(&:label))
                 }

      worker = SvmWorker.pool(args: [ {evaluator: evaluator}] )

      results = {}
      parameter_pairs = build_doe_matrix cost_min, cost_max, gamma_min, gamma_max
      resolution = [(cost_min.abs + cost_max.abs)/2.0, (gamma_min.abs + gamma_max.abs)/2.0]

      last_best = 0
      max_iterations.times do |iteration|
        Celluloid::Actor[:collector] = SvmCollector.new

        parameter_pairs.each do |cost,gamma|
          next if results.has_key?(cost: cost, gamma: gamma) # skip already tested models
          folds.each.with_index do |fold,index|
            worker.train!(fold, Parameter.new(
              :svm_type => Parameter::C_SVC,
              :kernel_type => Parameter::RBF,
              :cost => cost,
              :gamma => gamma
            ), folds.select.with_index{|e,ii| index!=ii } })
          end
        end

        new_results = wait :collecting
        results.merge new_results

        best_pair = results.invert[results.values.max] # get the key with the best value
        resolution.map!{|e| e/Math.sqrt(2)}
        parameter_pairs = build_doe_pattern_for_center best_pair[:cost], best_pair[:gamma], resolution
      end
      return model, results
    end

    def build_doe_pattern_for_center cost, gamma, resolution
      cost_min = cost - resolution[0]
      cost_max = cost + resolution[0]
      gamma_min = gamma - resolution[1]
      gamma_max = gamma + resolution[1]

      build_doe_pattern(cost_min, cost_max, gamma_min, gamma_max, cost, gamma)
    end

    def build_doe_pattern cost_min,
                          cost_max,
                          gamma_min,
                          gamma_max,
                          cost_center = (cost_max+cost_min)/2.0,
                          gamma_center = (gamma_max+gamma_min)/2.0
      # 1=max, -1=min, 0=center
      #     3^d points          #      2^d points
      #   |                     #   |
      #  1| O   O   O           #  1|
      #   |                     #   |   O   O
      #  0| O   O   O           #  0|
      #   |                     #   |   O   O
      # -1| O   O   O           # -1|
      #   +------------         #   +------------
      #    -1   0   1           #    -1   0   1

      costs3d = [ cost_min.to_f,# -1
                  cost_center, # 0
                  cost_max.to_f ] # 1
      gammas3d= [ gamma_min.to_f,# -1
                  gamma_center, # 0
                  gamma_max.to_f ] # 1

      costs2d = [ (cost_center+cost_min)/2, # -0.5
                  (cost_max+cost_center)/2 ] # 0.5

      gammas2d= [ (gamma_center+gamma_min)/2, # -0.5
                  (gamma_max+gamma_center)/2 ] # 0.5

      costs3d.product(gammas3d).concat(costs2d.product(gammas2d))
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
    end
    def train train, parameter, folds
      Celluloid::Actor[:collector].one_more
      evaluate Svm.svm_train(train, parameter),folds
    end
    def evaluate model, folds
      result = folds.map{ |fold|
        model.evaluate_dataset(fold, :evaluator => @evaluator)
      }.reduce(&:+) / folds.count
      Celluloid::Actor[:collector].collect(model, result)
    end
  end
  class SvmCollector
    include Celluloid
    attr_accessor :count
    attr_accessor :results
    attr_accessor :model
    attr_accessor :lowest_error
    attr_reader :recieved

    def initialize args
      @count = 0
      @results = Hash.new { |h, k| h[k] = [] } #autoexpand hash
      @recieved = 0
    end
    def one_more
      count += 1
    end
    def collect model, result
      @recieved+=1
      results[cost: model.cost, gamma: model.gamma] << result: result
      if recieved == count && count > 0
        mean_results = results.map{|k,v| {k => v.instance_eval { reduce(:+) / size.to_f }}}
        mean_results = Hash[*mean_results.map(&:to_a).flatten]
        Celluloid::Actor[:search].finished_collecting mean_results
      end
    end
  end
end