module SvmToolkit
  #
  # Parameter holds values determining the kernel type 
  # and training process.
  #
  class Parameter

    # :attr_accessor: svm_type
    # The type of SVM problem being solved.
    # * C_SVC, the usual classification task.
    # * NU_SVC
    # * ONE_CLASS
    # * EPSILON_SVR
    # * NU_SVR

    # :attr_accessor: kernel_type
    # The type of kernel to use.
    # * LINEAR
    # * POLY
    # * RBF
    # * SIGMOID
    # * PRECOMPUTED

    # :attr_writer: degree
    # A parameter in polynomial kernels.

    # :attr_accessor: gamma
    # A parameter in poly/rbf/sigmoid kernels.

    # :attr_accessor: coef0
    # A parameter for poly/sigmoid kernels.

    # :attr_accessor: cache_size
    # For training, in MB.

    # :attr_accessor: eps
    # For training, stopping criterion.

    # :attr_accessor: C
    # For training with C_SVC, EPSILON_SVR, NU_SVR: the cost parameter.

    # :attr_accessor: nr_weight
    # For training with C_SVC.

    # :attr_accessor: weight_label
    # For training with C_SVC.

    # :attr_accessor: weight
    # For training with C_SVC.

    # :attr_accessor: nu
    # For training with NU_SVR, ONE_CLASS, NU_SVC.

    # :attr_accessor: p
    # For training with EPSILON_SVR.

    # :attr_accessor: shrinking
    # For training, whether to use shrinking heuristics.

    # :attr_accessor: probability
    # For training, whether to use probability estimates.

    # Constructor sets up values of attributes based on provided map.
    # Valid keys with their default values:
    # * :svm_type = Parameter::C_SVC, for the type of SVM
    # * :kernel_type = Parameter::LINEAR, for the type of kernel
    # * :cost = 1.0, for the cost or C parameter
    # * :gamma = 0.0, for the gamma parameter in kernel
    # * :degree = 1, for polynomial kernel
    # * :coef0 = 0.0, for polynomial/sigmoid kernels
    # * :eps = 0.001, for stopping criterion
    # * :nr_weight = 0, for C_SVC
    # * :nu = 0.5, used for NU_SVC, ONE_CLASS and NU_SVR. Nu must be in (0,1]
    # * :p = 0.1, used for EPSILON_SVR
    # * :shrinking = 1, use the shrinking heuristics
    # * :probability = 0, use the probability estimates
    def initialize args
      super()
      self.svm_type    = args.fetch(:svm_type, Parameter::C_SVC)
      self.kernel_type = args.fetch(:kernel_type, Parameter::LINEAR)
      self.C           = args.fetch(:cost, 1.0)
      self.gamma       = args.fetch(:gamma, 0.0)
      self.degree      = args.fetch(:degree, 1)
      self.coef0       = args.fetch(:coef0, 0.0)
      self.eps         = args.fetch(:eps, 0.001)
      self.nr_weight   = args.fetch(:nr_weight, 0)
      self.nu          = args.fetch(:nu, 0.5)
      self.p           = args.fetch(:p, 0.1)
      self.shrinking   = args.fetch(:shrinking, 1)
      self.probability = args.fetch(:probability, 0)

      unless self.nu > 0.0 and self.nu <= 1.0
        raise ArgumentError "Invalid value of nu #{self.nu}, should be in (0,1]"
      end
    end

    # A more readable accessor for the C parameter
    def cost
      self.C
    end

    # A more readable mutator for the C parameter
    def cost= val
      self.C = val
    end

    # Return a list of the available kernels.
    def self.kernels
      [Parameter::LINEAR, Parameter::POLY, Parameter::RBF, Parameter::SIGMOID]
    end

    # Return a printable name for the given kernel.
    def self.kernel_name kernel
      case kernel
      when Parameter::LINEAR
        "Linear"
      when Parameter::POLY
        "Polynomial"
      when Parameter::RBF
        "Radial basis function"
      when Parameter::SIGMOID
        "Sigmoid"
      else
        "Unknown"
      end
    end
  end
end