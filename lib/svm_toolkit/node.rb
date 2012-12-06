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