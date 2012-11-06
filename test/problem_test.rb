require_relative 'test_helper'
class ProblemTests < Test::Unit::TestCase
  def test_from_array
    assert_raise(ArgumentError) do
      Problem.from_array([], [])
    end
    assert_raise(ArgumentError) do
      Problem.from_array([], [1,2,3])
    end
    assert_raise(ArgumentError) do
      Problem.from_array([[1],[2],[3]], [1,2])
    end
    assert_raise(ArgumentError) do
      Problem.from_array([[1],[2,3],[4]], [1,2,3])
    end
    problem = nil
    assert_nothing_raised(ArgumentError) do
      problem = Problem.from_array([[1,2],[2,3],[3,4]], [1,2,3])
    end
    assert_equal(3, problem.size)
    assert_equal(2, problem.x[1][0].value)
    assert_equal(1, problem.y[0])
  end

  def test_construct_problem
    problem = Problem.from_array(
      [[1,2,3], [1.5, 4, 3.1], [2.0, 6, 3.2]],
      [1, 0, 1]
    )
    assert_equal(3, problem.size)
    assert_equal(1, problem.x[0][0].value)
    assert_equal(2.0, problem.x[2][0].value)

    problem.rescale(-1.0, 1.0)
    assert_equal(3, problem.size)
    assert_equal(-1, problem.x[0][0].value)
    assert_equal(0, problem.x[1][0].value)
    assert_equal(1, problem.x[2][0].value)
    assert_equal(-1, problem.x[0][1].value)
    assert_equal(0, problem.x[1][1].value)
    assert_equal(1, problem.x[2][1].value)
    assert_equal(-1, problem.x[0][1].value)
    assert_equal(0, problem.x[1][1].value)
    assert_equal(1, problem.x[2][1].value)

    problem.rescale(0.0, 1.0)
    assert_equal(3, problem.size)
    assert_equal(0, problem.x[0][0].value)
    assert_equal(0.5, problem.x[1][0].value)
    assert_equal(1.0, problem.x[2][0].value)
    assert_equal(0, problem.x[0][1].value)
    assert_equal(0.5, problem.x[1][1].value)
    assert_equal(1.0, problem.x[2][1].value)
    assert_equal(0, problem.x[0][1].value)
    assert_equal(0.5, problem.x[1][1].value)
    assert_equal(1.0, problem.x[2][1].value)
  end

  def test_merge
    problem1 = Problem.from_array(
      [[1,2,3], [1.5, 4, 3.1], [2.0, 6, 3.2]],
      [1, 0, 1]
    )
    problem2 = Problem.from_array(
      [[1,2,3,4]], [1]
    )
    # problems with differing numbers of features cannot be merged
    assert_raise(ArgumentError) { problem1.merge(problem2) }
    problem3 = Problem.from_array(
      [[1,2,3], [1.5, 4, 3.1], [2.0, 6, 3.2]],
      [1, 0, 1]
    )
    # confirm merging of two problems
    assert_nothing_raised(ArgumentError) { problem1.merge(problem3) }
    problem4 = problem1.merge(problem3)
    assert_equal(6, problem4.size)
    [[1,2,3], [1.5, 4, 3.1], [2.0, 6, 3.2], [1,2,3], [1.5, 4, 3.1], [2.0, 6, 3.2]].each_with_index do |instance, i|
      instance.each_with_index do |v, j|
        assert_equal(v, problem4.x[i][j].value)
      end
    end
    [1,0,1,1,0,1].each_with_index do |v, i|
      assert_equal(v, problem4.y[i])
    end
  end
end
