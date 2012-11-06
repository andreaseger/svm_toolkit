module SvmToolkit
  class Model
    # Evaluate model on given data set (an instance of Problem), 
    # returning the number of errors made.
    # Optional parameters include:
    # * :evaluator => Evaluator::OverallAccuracy, the name of the class to use for computing performance
    # * :print_results => false, whether to print the result for each instance
    def evaluate_dataset(data, params = {})
      evaluator = params.fetch(:evaluator, Evaluator::OverallAccuracy)
      print_results = params.fetch(:print_results, false)
      performance = evaluator.new
      data.l.times do |i|
        pred = Svm.svm_predict(self, data.x[i])
        performance.add_result(data.y[i], pred)
        if print_results
          puts "Instance #{i}, Prediction: #{pred}, True label: #{data.y[i]}"
        end
      end
      return performance
    end

    # Return the value of w squared for the hyperplane.
    # -- returned as an array if there is not just one value.
    def w_squared
      if self.w_2.size == 1
        self.w_2[0]
      else
        self.w_2.to_a
      end
    end

    # Return an array of indices of the training instances used as 
    # support vectors.
    def support_vector_indices
      result = []
      unless sv_indices.nil?
        sv_indices.size.times do |i|
          result << sv_indices[i]
        end
      end

      return result
    end

    # Return the SVM problem type for this model
    def svm_type
      self.param.svm_type
    end

    # Return the kernel type for this model
    def kernel_type
      self.param.kernel_type
    end

    # Return the value of the degree parameter
    def degree
      self.param.degree
    end

    # Return the value of the gamma parameter
    def gamma
      self.param.gamma
    end

    # Return the value of the cost parameter
    def cost
      self.param.cost
    end

    # Return the number of classes handled by this model.
    def number_classes
      self.nr_class
    end

    # Save model to given filename.
    # Raises IOError on any error.
    def save filename
      begin
        Svm.svm_save_model(filename, self)
      rescue java.io.IOException
        raise IOError.new "Error in saving SVM model to file"
      end
    end

    # Load model from given filename.
    # Raises IOError on any error.
    def self.load filename
      begin
        Svm.svm_load_model(filename)
      rescue java.io.IOException
        raise IOError.new "Error in loading SVM model from file"
      end
    end

    #
    # Predict the class of given instance number in given problem.
    #
    def predict(problem, instance_number)
      Svm.svm_predict(self, problem.x[instance_number])
    end

    #
    # Return the values of given instance number of given problem against 
    # each decision boundary.
    # (This is the distance of the instance from each boundary.)
    #
    # Return value is an array if more than one decision boundary.
    #
    def predict_values(problem, instance_number)
      dist = Array.new(number_classes*(number_classes-1)/2, 0).to_java(:double)
      Svm.svm_predict_values(self, problem.x[instance_number], dist)
      if dist.size == 1
        return dist[0]
      else
        return dist.to_a
      end
    end
  end
end