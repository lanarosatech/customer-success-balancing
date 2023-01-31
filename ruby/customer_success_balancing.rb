require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success # id and CS experience level
    @customers = customers # id ans Customers experience level
    @away_customer_success = away_customer_success # CustomerSuccess id`s unavailable
  end

  def execute
    customer_success_attending = @away_customer_success.any? ? search_customer_success : @customer_success

    # that orders customers and customer success by score
    ordered_customer_success = order_by_score(customer_success_attending)
    ordered_customers = @customers.empty? ? [] : order_by_score(@customers)

    # distributes customers to customer success
    distribute_customers_per_customer_success(ordered_customer_success, ordered_customers)
    customer_success_with_most_customers = group_by_most_attendings(ordered_customer_success)

    # return the ID from customer success with most customers
    return 0 unless customer_success_with_most_customers[1].count == 1

    customer_success_with_most_customers[1].first[:id]
  end

  private

  def search_customer_success
    @customer_success = @customer_success.select { |cs| !@away_customer_success.include?(cs[:id]) }
  end
  # In this version, instead of using reject! to modify the original array,
  # select is used to return a new array with only the elements that match the condition.

  def order_by_score(objects)
    objects.sort_by { |object| object[:score] }
  end
  # This is a Ruby code snippet that can be used to order a list of data objects by their score.
  # The list of data objects is passed in as an argument and then the code sorts the list by the score attribute of each object.

  def find_customers(ordered_customers, customer_success, index, ordered_customer_success)
    score_limit = customer_success[:score]
    lower_bound = index.zero? ? -Float::INFINITY : ordered_customer_success[index - 1][:score]
    ordered_customers.select { |customer| customer[:score] > lower_bound && customer[:score] <= score_limit }
  end
  # In this version, the score limit and the score lower bound are defined as variables before
  # the select method is called, making the code more readable and easier to understand.
  # The use of Float::INFINITY to represent a large positive number in the lower bound makes
  # the code more flexible, as it can handle cases where the index is zero without the need for
  # a separate if statement.

  def distribute_customers_per_customer_success(ordered_customer_success, ordered_customers)
    ordered_customer_success.each_with_index do |customer_success, index|
      # customers = find_customers(ordered_customers, customer_success, index, ordered_customer_success)
      customer_success[:customers_attending] = find_customers(ordered_customers, customer_success, index, ordered_customer_success)
    end
  end
  # This function takes two ordered lists of customer success and customers, and assigns each customer success
  # with a list of customers attending. It does this by looping through the customer success list, finding the customers
  # in the customers list that match that customer success, and assigning them to that customer success.

  def group_by_most_attendings(customer_success)
    return [] if customer_success.empty?

    customer_success.group_by { |index| index[:customers_attending].count }.sort.reverse.first
  end
  # This function takes in an array of customer success data as an argument and sorts it by the number of customers attending.
  # It then reverses the sort order, and returns the group with the most attendings.
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
