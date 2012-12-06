# This file is part of svm_toolkit.
#
# Author::    Peter Lane
# Copyright:: Copyright 2011, Peter Lane.
# License::   GPLv3
#
# svm_toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# svm_toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with svm_toolkit.  If not, see <http://www.gnu.org/licenses/>.

module SvmToolkit
class Svm
    #
    # :singleton-method: svm_train
    # 
    # * Input
    #   [+problem+] instance of Problem
    #   [+param+]   instance of Parameter
    # 
    # * Output
    #   [+model+] instance of Model

    #
    # :singleton-method: svm_cross_validation
    #
    # * Input
    #   [+problem+] instance of Problem
    #   [+param+]   instance of Parameter
    #   [+nr_fold+] number of folds
    #   [+target+]
    #

    #
    # Perform cross validation search on given gamma/cost values, 
    # using an RBF kernel, 
    # returning the best performing model and optionally displaying 
    # a contour map of performance.
    #
    # * Input
    #   [+training_set+]   instance of Problem, used for training
    #   [+cross_valn_set+] instance of Problem, used for evaluating models
    #   [+costs+]          array of cost values to search across
    #   [+gammas+]         array of gamma values to search across
    #   [+params+]         Optional parameters include:
    #     * :evaluator => Evaluator::OverallAccuracy, the name of the class 
    #     to use for computing performance
    #     * :show_plot => false, whether to display contour plot
    #     * :train_whole => false, whether to train the final model on both 
    #     the training and cross-validation datasets
    #
    # * Output
    #   [+model+]          instance of Model, the best performing model
    #
    def self.cross_validation_search(training_set, cross_valn_set, 
                                     costs = [-2,-1,0,1,2,3].collect {|i| 2**i}, 
                                     gammas = [-2,-1,0,1,2,3].collect {|i| 2**i}, 
                                     params = {})
      evaluator = params.fetch(:evaluator, Evaluator::OverallAccuracy)
      train_whole = params.fetch(:train_whole, false)
      results = []
      best_model = nil
      lowest_error = nil

      gammas.each do |gamma|
        results_row = []
        costs.each do |cost|
          model = Svm.svm_train(training_set, Parameter.new(
            :svm_type => Parameter::C_SVC,
            :kernel_type => Parameter::RBF,
            :cost => cost,
            :gamma => gamma
          ))
          result = model.evaluate_dataset(cross_valn_set, :evaluator => evaluator)
          if result.better_than? lowest_error
            best_model = model
            lowest_error = result
          end
          puts "Result for cost = #{cost}  gamma = #{gamma} is #{result.value}"
          results_row << result.value
        end
        results << results_row
      end

      return best_model
    end
  end
end