module SvmToolkit
  #
  # Node is used to store the index/value pair for an individual 
  # feature of an instance.
  #
  class Node
    # :attr_accessor: index
    # Index of this node in feature set.

    # :attr_accessor: value
    # Value of this node in feature set.

    #
    def initialize(index, value)
      super()
      self.index = index
      self.value = value
    end
  end
end