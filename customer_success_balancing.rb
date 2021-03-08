require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, customer_success_away)
    @customer_success = customer_success
    @customers = customers
    @customer_success_away = customer_success_away
  end

  def execute
    available_employees = get_available_employees(@customer_success, @customer_success_away)
    sorted_available_employees = sort_employees_by_score(available_employees)

    customers_by_employee = sorted_available_employees.map do |employee|
      received_customers =  @customers.extract! do |customer|
        customer[:score] <= employee[:score]
      end

      { employee_id: employee[:id], received_customers: received_customers }
    end

    get_employee_id_with_max_customers(customers_by_employee)
  end

  def get_available_employees(employees, unavailable_employees_ids)
    employees.reject { |employee| unavailable_employees_ids.include? employee[:id] }
  end

  def sort_employees_by_score(employees)
    employees.sort_by { |employee| employee[:score] }
  end

  def get_employee_id_with_max_customers(customers_by_employee)
    max_received_customers = customers_by_employee.map { |employee| employee[:received_customers].length }.max
    employees_with_max_customers = customers_by_employee.select do |employee|
      employee[:received_customers].length == max_received_customers
    end

    return 0 if employees_with_max_customers.empty? ||
                employees_with_max_customers.length > 1

    employees_with_max_customers.first[:employee_id]
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    css = [{ id: 1, score: 60 }, { id: 2, score: 20 }, { id: 3, score: 95 }, { id: 4, score: 75 }]
    customers = [{ id: 1, score: 90 }, { id: 2, score: 20 }, { id: 3, score: 70 }, { id: 4, score: 40 }, { id: 5, score: 60 }, { id: 6, score: 10}]

    balancer = CustomerSuccessBalancing.new(css, customers, [2, 4])
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    css = array_to_map([11, 21, 31, 3, 4, 5])
    customers = array_to_map( [10, 10, 10, 20, 20, 30, 30, 30, 20, 60])
    balancer = CustomerSuccessBalancing.new(css, customers, [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    customer_success = Array.new(1000, 0)
    customer_success[998] = 100

    customers = Array.new(10000, 10)
    
    balancer = CustomerSuccessBalancing.new(array_to_map(customer_success), array_to_map(customers), [1000])

    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 999, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(array_to_map([1, 2, 3, 4, 5, 6]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 2, 3, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [])
    assert_equal balancer.execute, 1
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [1, 3, 2])
    assert_equal balancer.execute, 0
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(array_to_map([100, 99, 88, 3, 4, 5]), array_to_map([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]), [4, 5, 6])
    assert_equal balancer.execute, 3
  end

  def array_to_map(arr)
    out = []
    arr.each_with_index { |score, index| out.push({ id: index + 1, score: score }) }
    out
  end
end

class Array
  # Removes and returns the elements for which the block returns a true value.
  # If no block is given, an Enumerator is returned instead.
  #
  #   numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  #   odd_numbers = numbers.extract! { |number| number.odd? } # => [1, 3, 5, 7, 9]
  #   numbers # => [0, 2, 4, 6, 8]
  def extract!
    return to_enum(:extract!) { size } unless block_given?

    extracted_elements = []

    reject! do |element|
      extracted_elements << element if yield(element)
    end

    extracted_elements
  end
end
