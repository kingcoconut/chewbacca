class Status < ActiveRecord::Base
  def self.average_value
    status_values = where("created_at > ?", Time.now - 2.hours).order("created_at DESC").group(:ip).pluck(:value)
    if !status_values.empty?
      @average = status_values.inject(:+) / status_values.length
    else
      50
    end
  end
end
