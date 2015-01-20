class Item
	include Mongoid::Document

  require 'open-uri'

	field :name, type: String
	field :value_date, type: Date
	field :description, type: String
	belongs_to :event
  field :base_amount, type: BigDecimal
  field :base_currency, type: String
  field :exchange_rate, type: BigDecimal
  field :foreign_amount, type: BigDecimal
  field :foreign_currency, type: String
  field :payer_id, type: BSON::ObjectId
  has_and_belongs_to_many :beneficiaries, class_name: "User", inverse_of: nil

  validates :name, :description, :value_date, :base_currency, :foreign_amount, :foreign_currency, :beneficiaries, presence: true
  validates :foreign_amount, :exchange_rate, numericality: {greater_than_or_equal_to: 0}

  # returns a big decimal for better accuracy
  def cost_per_beneficiary
    self.base_amount / self.beneficiaries.count
  end

  def apply_exchange_rate
    begin
      rate = JSON.parse(open("http://devel.farebookings.com/api/curconversor/" + self.foreign_currency + "/" + self.base_currency + "/1/json").read)[self.base_currency]
      self.exchange_rate = rate
      self.base_amount = self.foreign_amount * self.exchange_rate
    rescue OpenURI::HTTPError => ex
      self.errors[:foreign_currency] = " cannot get exchange rate. Choose a currency or try to type a rate manually."
    end
  end

end