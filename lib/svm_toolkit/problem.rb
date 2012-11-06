module SvmToolkit
  class Problem

    #
    # Support constructing a problem from arrays of double values.
    # * Input
    #   [+instances+] an array of instances, each instance being an array of doubles.
    #   [+labels+] an array of doubles, forming the labels for each instance.
    #
    # An ArgumentError exception is raised if all the following conditions are not met:
    # * the number of instances should equal the number of labels,
    # * there must be at least one instance, and
    # * every instance must have the same number of features.
    #
    def self.from_array(instances, labels)
      unless instances.size == labels.size
        raise ArgumentError.new "Number of instances must equal number of labels"
      end
      unless instances.size > 0
        raise ArgumentError.new "There must be at least one instance."
      end
      unless instances.collect {|i| i.size}.min == instances.collect {|i| i.size}.max
        raise ArgumentError.new "All instances must have the same size"
      end

      problem = Problem.new
      problem.l = labels.size
      # -- add in the training data
      problem.x = Node[instances.size, instances[0].size].new
      instances.each_with_index do |instance, i|
        instance.each_with_index do |v, j|
          problem.x[i][j] = Node.new(j, v)
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    # To select SvmLight input file format
    SvmLight = 0

    # To select Csv input file format
    Csv = 1

    # To select ARFF input file format
    Arff = 2

    #
    # Read in a problem definition from a file. 
    # Input:
    # * +filename+, the name of the file
    # * +format+, either Svm::SvmLight (default), Svm::Csv or Svm::Arff
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file(filename, format = SvmLight)
      case format 
      when SvmLight
        return self.from_file_svmlight filename
      when Csv
        return self.from_file_csv filename
      when Arff
        return self.from_file_arff filename
      end
    end

    #
    # Read in a problem definition in svmlight format from given 
    # filename.
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file_svmlight filename
      instances = []
      labels = []
      max_index = 0
      IO.foreach(filename) do |line|
        tokens = line.split(" ")
        labels << tokens[0].to_f
        instance = []
        tokens[1..-1].each do |feature|
          index, value = feature.split(":")
          instance << Node.new(index.to_i, value.to_f)
          max_index = [index.to_i, max_index].max 
        end
        instances << instance
      end
      max_index += 1 # to allow for 0 position
      unless instances.size == labels.size
        raise ArgumentError.new "Number of labels read differs from number of instances"
      end
      # now create a Problem definition
      problem = Problem.new
      problem.l = instances.size
      # -- add in the training data
      problem.x = Node[instances.size, max_index].new
      # -- fill with blank nodes
      instances.size.times do |i|
        max_index.times do |j|
          problem.x[i][j] = Node.new(i, 0)
        end
      end
      # -- add known values
      instances.each_with_index do |instance, i|
        instance.each do |node|
          problem.x[i][node.index] = node
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    #
    # Read in a problem definition in csv format from given 
    # filename.
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file_csv filename
      instances = []
      labels = []
      max_index = 0
      IO.foreach(filename) do |line|
        tokens = line.split(",")
        labels << tokens[0].to_f
        instance = []
        tokens[1..-1].each_with_index do |value, index|
          instance << Node.new(index, value.to_f)
        end
        max_index = [tokens.size, max_index].max 
        instances << instance
      end
      max_index += 1 # to allow for 0 position
      unless instances.size == labels.size
        raise ArgumentError.new "Number of labels read differs from number of instances"
      end
      # now create a Problem definition
      problem = Problem.new
      problem.l = instances.size
      # -- add in the training data
      problem.x = Node[instances.size, max_index].new
      # -- fill with blank nodes
      instances.size.times do |i|
        max_index.times do |j|
          problem.x[i][j] = Node.new(i, 0)
        end
      end
      # -- add known values
      instances.each_with_index do |instance, i|
        instance.each do |node|
          problem.x[i][node.index] = node
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    #
    # Read in a problem definition in arff format from given 
    # filename.
    # Assumes all values are numbers (non-numbers converted to 0.0), 
    # and that the class is the last field.
    # Raises ArgumentError if there is any error in format.
    #
    def self.from_file_arff filename
      instances = []
      labels = []
      max_index = 0
      found_data = false
      IO.foreach(filename) do |line|
        unless found_data
          puts "Ignoring", line
          found_data = line.downcase.strip == "@data"
          next # repeat the loop
        end
        tokens = line.split(",")
        labels << tokens.last.to_f
        instance = []
        tokens[1...-1].each_with_index do |value, index|
          instance << Node.new(index, value.to_f)
        end
        max_index = [tokens.size, max_index].max 
        instances << instance
      end
      max_index += 1 # to allow for 0 position
      unless instances.size == labels.size
        raise ArgumentError.new "Number of labels read differs from number of instances"
      end
      # now create a Problem definition
      problem = Problem.new
      problem.l = instances.size
      # -- add in the training data
      problem.x = Node[instances.size, max_index].new
      # -- fill with blank nodes
      instances.size.times do |i|
        max_index.times do |j|
          problem.x[i][j] = Node.new(i, 0)
        end
      end
      # -- add known values
      instances.each_with_index do |instance, i|
        instance.each do |node|
          problem.x[i][node.index] = node
        end
      end
      # -- add in the labels
      problem.y = Java::double[labels.size].new
      labels.each_with_index do |v, i| 
        problem.y[i] = v
      end

      return problem
    end

    # Return the number of instances
    def size
      self.l
    end

    # Rescale values within problem to be in range min_value to max_value
    #
    # For SVM models, it is recommended all features be in range [0,1] or [-1,1]
    def rescale(min_value = 0.0, max_value = 1.0)
      return if self.l.zero?
      x[0].size.times do |i|
        rescale_column(i, min_value, max_value)
      end
    end

    # Create a new problem by combining the instances in this problem with 
    # those in the given problem.
    def merge problem
      unless self.x[0].size == problem.x[0].size
        raise ArgumentError.new "Cannot merge two problems with different numbers of features"
      end
      num_features = self.x[0].size
      num_instances = size + problem.size

      new_problem = Problem.new
      new_problem.l = num_instances
      new_problem.x = Node[num_instances, num_features].new
      new_problem.y = Java::double[num_instances].new
      # fill out the features
      num_instances.times do |i|
        num_features.times do |j|
          if i < size
            new_problem.x[i][j] = self.x[i][j]
          else
            new_problem.x[i][j] = problem.x[i-size][j]
          end
        end
      end
      # fill out the labels
      num_instances.times do |i|
        if i < size
          new_problem.y[i] = self.y[i]
        else
          new_problem.y[i] = problem.y[i-size]
        end
      end

      return new_problem
    end

    # Rescale values within problem for given column index, 
    # to be in range min_value to max_value
    private
    def rescale_column(col, min_value, max_value)
      # -- first locate the column's range
      current_min = x[0][col].value
      current_max = x[0][col].value
      self.l.times do |index|
        if x[index][col].value < current_min
          current_min = x[index][col].value
        end
        if x[index][col].value > current_max
          current_max = x[index][col].value
        end
      end
      # -- then update each value
      self.l.times do |index|
        x[index][col].value = ((max_value - min_value) * (x[index][col].value - current_min) / (current_max - current_min)) + min_value
      end
    end
  end
end