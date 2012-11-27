require 'celluloid'
module SvmToolkit
  class Svm
    def self.doe_search(args={})
      doe_search = DoeSearch.new args.fetch(:folds) { 3 }
      doe_search.search args
    end
  end
  class DoeSearch
    attr_accessor :number_of_folds
    def initialize number_of_folds
      self.number_of_folds = number_of_folds
    end
    def search(args={})
      # deal with input
      feature_vectors = args[:feature_vectors]
      cost_min = args.fetch(:cost_min) { -5 }
      cost_max = args.fetch(:cost_max) { 15 }
      gamma_min = args.fetch(:gamma_min) { -15 }
      gamma_max = args.fetch(:gamma_max) { 9 }
      evaluator = args.fetch(:evaluator, Evaluator::OverallAccuracy)
      max_iterations = args.fetch(:interations) { 1 }

      # split feature_vectors into folds
      *folds,_ = feature_vectors.each_slice(feature_vectors.size/number_of_folds).map{|set|
                   Problem.from_array(set.map(&:data), set.map(&:label))
                 }

      # initialize iteration parameters
      results = {}
      resolution = [(cost_min.abs + cost_max.abs)/2.0, (gamma_min.abs + gamma_max.abs)/2.0]
      parameter_pairs = build_doe_matrix cost_min, cost_max, gamma_min, gamma_max

      # create Celluloid Threadpool
      worker = SvmWorker.pool(args: [ {evaluator: evaluator}] )
      max_iterations.times do |iteration|
        futures = []
        parameter_pairs.each do |cost,gamma|
          next if results.has_key?(cost: cost, gamma: gamma) # skip already tested models
          folds.each.with_index do |fold,index|
            # train SVM async
            futures << worker.future.train( fold,
                                            Parameter.new(:svm_type => Parameter::C_SVC,
                                                          :kernel_type => Parameter::RBF,
                                                          :cost => cost,
                                                          :gamma => gamma),
                                            folds.select.with_index{|e,ii| index!=ii }
                                          )
          end
        end

        # blocking call to receive all results
        new_results = Hash.new { |h, k| h[k] = [] }
        futures.map { |f|
          result = f.value
          new_results[cost: model.cost, gamma: model.gamma] << result
        }
        # make means of all folds
        new_results = new_results.map{|k,v| {k => v.instance_eval { reduce(:+) / size.to_f }}}
        new_results = Hash[*mean_results.map(&:to_a).flatten]
        results.merge new_results

        best_pair = results.invert[results.values.max] # get the key with the best value
        resolution.map!{|e| e/Math.sqrt(2)}
        parameter_pairs = build_doe_pattern_for_center best_pair[:cost], best_pair[:gamma], resolution
      end

      best_pair = results.invert[results.values.max]
      # retrain the model with the best results
      feature_set = Problem.from_array(feature_vectors.map(&:data), feature_vectors.map(&:label))
      model = Svm.svm_train(train, Parameter.new(:svm_type => Parameter::C_SVC,
                                                :kernel_type => Parameter::RBF,
                                                :cost => best_pair[:cost],
                                                :gamma => best_pair[:gamma]))
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
      #     3^d pattern         #      2^d pattern
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
  end

  private
  class SvmWorker
    include Celluloid
    def initialize args={}
      @evaluator = args[:evaluator]
    end
    def train train, parameter, folds
      evaluate Svm.svm_train(train, parameter), folds
    end
    def evaluate model, folds
      result = folds.map{ |fold|
        model.evaluate_dataset(fold, :evaluator => @evaluator)
      }.reduce(&:+) / folds.count
      return [model, results]
    end
  end
end