require_relative 'test_helper'
class EvaluationTests < Test::Unit::TestCase
  def test_total_errors
    performance = Evaluator::OverallAccuracy.new
    assert_equal(0.0, performance.value)
    performance.add_result(0, 0)
    assert_equal(100.0, performance.value)
    performance.add_result(1, 0)
    assert_equal(50.0, performance.value)
    performance2 = Evaluator::OverallAccuracy.new
    assert performance.better_than?(performance2)
    performance2.add_result(1, 1)
    performance2.add_result(1, 1)
    assert !performance.better_than?(performance2)
  end

  def test_geometric_mean
    performance = Evaluator::GeometricMean.new
    assert_equal(0.0, performance.value)
    performance.add_result(0, 0)
    assert_equal(1.0, performance.value)
    performance.add_result(0, 1)
    performance.add_result(1, 1)
    assert((0.707 - performance.value).abs < 0.01)
    performance.add_result(1, 1)
    performance.add_result(1, 0)
    assert((0.577 - performance.value).abs < 0.01)
  end

  def test_precision
    performance1 = Evaluator::ClassPrecision(0).new
    performance1.add_result(0, 0)
    performance1.add_result(0, 0)
    performance1.add_result(0, 0)
    performance1.add_result(0, 1)
    performance1.add_result(1, 0)
    performance1.add_result(1, 0)
    performance1.add_result(1, 1)
    # 3 correct out of 4 0s actually output
    assert_equal(0.75, performance1.value)

    performance2 = Evaluator::ClassPrecision(1).new
    performance2.add_result(0, 0)
    performance2.add_result(0, 0)
    performance2.add_result(0, 0)
    performance2.add_result(0, 1)
    performance2.add_result(1, 0)
    performance2.add_result(1, 0)
    performance2.add_result(1, 1)
    # 2 correct out of 3 1s actually output
    assert((0.333333-performance2.value).abs < 0.001)
  end

  def test_recall
    performance1 = Evaluator::ClassRecall(0).new
    performance1.add_result(0, 0)
    performance1.add_result(0, 0)
    performance1.add_result(0, 0)
    performance1.add_result(0, 1)
    performance1.add_result(1, 0)
    performance1.add_result(1, 0)
    performance1.add_result(1, 1)
    # 3 correct out of the 5 predicted 0s
    assert_equal(0.6, performance1.value)

    performance2 = Evaluator::ClassRecall(1).new
    performance2.add_result(0, 0)
    performance2.add_result(0, 0)
    performance2.add_result(0, 0)
    performance2.add_result(0, 1)
    performance2.add_result(1, 0)
    performance2.add_result(1, 0)
    performance2.add_result(1, 1)
    # 1 correct out of the 2 predicted 1s
    assert_equal(0.5, performance2.value)
  end
end