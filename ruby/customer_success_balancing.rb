require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success # Id and CS experience level
    @customers = customers # Id ans Customers experience level
    @away_customer_success = away_customer_success # CustomerSuccess id`s unavailable
  end

  def execute
    cs_attending = @away_customer_success.any? ? search_cs : @customer_success

    # Orders customers and customer success by score
    ordered_cs = order_by_score(cs_attending)
    ordered_customers = @customers.empty? ? [] : order_by_score(@customers)

    # Distributes customers to customer success
    customers_per_cs(ordered_cs, ordered_customers)
    cs_with_most_customers = most_attendings_groups(ordered_cs)

    # Return the ID from customer success with most customers
    return 0 unless cs_with_most_customers[1].count == 1

    cs_with_most_customers[1].first[:id]
  end

  private

  # Return a new array with only the elements that match the condition
  def search_cs
    @customer_success = @customer_success.select { |cs| !@away_customer_success.include?(cs[:id]) }
  end

  # Sorts the list of objects by the score
  def order_by_score(objects)
    objects.sort_by { |object| object[:score] }
  end

  # The use of Float::INFINITY to represent a large positive number in the lower bound makes the code more flexible
  def find_customers(ordered_customers, customer_success, index, ordered_cs)
    score_limit = customer_success[:score]
    lower_bound = index.zero? ? -Float::INFINITY : ordered_cs[index - 1][:score]
    ordered_customers.select { |customer| customer[:score] > lower_bound && customer[:score] <= score_limit }
  end

  # Loop through the CS list, find the customers in the customers list that match that CS, and assigning them to that CS
  def customers_per_cs(ordered_cs, ordered_customers)
    ordered_cs.each_with_index do |customer_success, index|
      customer_success[:customers_attending] = find_customers(ordered_customers, customer_success, index, ordered_cs)
    end
  end

  # This function takes in an array of CS data as an argument and sorts it by the number of customers attending.
  # It then reverses the sort order, and returns the group with the most attendings.
  def most_attendings_groups(customer_success)
    return [] if customer_success.empty?

    customer_success.group_by { |index| index[:customers_attending].count }.sort.reverse.first
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  # This is a test case checks the scenario when there are customer scores [2, 5, 6, 7] and CS scores [6].
  # The test is to see if the CS with the ID of 3 is returned, which has the score of 6.
  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([2,5,6,7]),
      build_scores([6]),
      []
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
