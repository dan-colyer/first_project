require_relative('../db/sql_runner.rb')
require_relative('merchant.rb')
require_relative('tag.rb')

class Transaction
  attr_reader :id
  attr_accessor :description, :merchant_id, :tag_id, :amount, :transaction_date

  def initialize(options)
    @id = options["id"].to_i
    @description = options["description"]
    @merchant_id = options["merchant_id"].to_i
    @tag_id = options["tag_id"].to_i
    @amount = options["amount"].to_f.round(2)
    @transaction_date = options["transaction_date"]
  end

  def save()
    sql = "INSERT INTO transactions
          ( description,
            merchant_id,
            tag_id,
            amount,
            transaction_date)
          VALUES
          ($1, $2, $3, $4, $5)
          RETURNING id"
    values = [@description, @merchant_id, @tag_id, @amount, @transaction_date]
    results = SqlRunner.run(sql, values)
    @id = results.first()["id"].to_i
  end

  def pretty_date()
    date = Date.strptime(@transaction_date, "%F")
    new_format = date.strftime("%d-%m-%y")
    return new_format
  end

  def self.all()
    sql = "SELECT * FROM transactions ORDER BY transaction_date DESC"
    values =[]
    results = SqlRunner.run(sql, values)
    return results.map {|result| Transaction.new(result)}
  end

  def delete()
    sql = "DELETE FROM transactions
          WHERE id = $1"
    values = [@id]
    SqlRunner.run(sql, values)
  end

  def update()
    sql = "UPDATE transactions
          SET (description, merchant_id, tag_id, amount, transaction_date)
          = ($1, $2, $3, $4, $5)
          WHERE id = $6"
    values = [@description, @merchant_id, @tag_id, @amount, @transaction_date, @id]
    SqlRunner.run(sql, values)
  end

  def self.find(id)
    sql = "SELECT * FROM transactions
    WHERE id = $1"
    values = [id]
    results = SqlRunner.run( sql, values )
    return Transaction.new( results.first )
  end

  def merchant()
    sql = "SELECT * FROM merchants
          WHERE id = $1"
    values = [@merchant_id]
    results = SqlRunner.run(sql, values)
    return Merchant.new(results.first)
  end

  def tag()
    sql = "SELECT * FROM tags
          WHERE id = $1"
    values = [@tag_id]
    results = SqlRunner.run(sql, values)
    return Tag.new(results.first)
  end

  def self.transactions_by_merchant(id)
    sql = "SELECT merchants.name, transactions.* FROM merchants
          INNER JOIN transactions
          ON merchants.id = transactions.merchant_id
          WHERE merchants.id = $1"
    values = [id]
    results = SqlRunner.run(sql, values)
    return results.map{|result| Transaction.new(result)}
  end

  def self.transactions_by_tag(id)
    sql = "SELECT tags.type, transactions.* FROM tags
          INNER JOIN transactions
          ON tags.id = transactions.tag_id
          WHERE tags.id = $1"
    values = [id]
    results = SqlRunner.run(sql, values)
    return results.map{|result| Transaction.new(result)}
  end

  def self.total_spend()
    sql = "SELECT SUM(amount) as sum FROM transactions"
    values = []
    results = SqlRunner.run(sql, values)
    return results.first["sum"].to_f.round(2)
  end

  def self.budget_minus_total_spend()
    remaining_budget = 1800.00 - (self.total_spend)
    return remaining_budget.to_f.round(2)
  end

  def self.total_spend_by_tag(type)
    sql = "SELECT tags.type, SUM(transactions.amount) as sum
          FROM tags
          INNER JOIN transactions
          ON tags.id = transactions.tag_id
          WHERE type = $1
          GROUP BY tags.type"
    values = [type]
    results = SqlRunner.run(sql, values)
    return results.first["sum"].to_f.round(2)
  end

  def self.total_spend_by_merchant(name)
    sql = "SELECT merchants.name, SUM(transactions.amount) as sum
          FROM merchants
          INNER JOIN transactions
          ON merchants.id = transactions.merchant_id
          WHERE name = $1
          GROUP BY merchants.name"
    values = [name]
    results = SqlRunner.run(sql, values)
    return results.first["sum"].to_f.round(2)
  end
end
