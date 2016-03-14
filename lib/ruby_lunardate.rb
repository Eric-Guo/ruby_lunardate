require 'date'

class Date
  def from_solar
    LunarDate.from_solar(year, month, day)
  end

  def to_solar(is_leap_month = false, calendar_symbol = :ko)
    LunarDate.to_solar(year, month, day, is_leap_month)
  end
end

class LunarDate
  attr_accessor :year, :month, :day, :is_leap_month

  def self.from_solar(year, month, day, calendar_symbol = :ko)
    solar_date = Date.new(year, month, day)
    days = get_days(solar_date)
    lunar_from_days(days, calendar_symbol)
  end

  def self.to_solar(year, month, day, is_leap_month = false, calendar_symbol = :ko)
    days = 0
    year_diff = year - 1900
    year_info = CALENDAR_YEAR_INFO_MAP[calendar_symbol]

    year_diff.times do |year_idx|
      days += year_info[year_idx][0]
    end

    (month - 1).times do |month_idx|
      total, _normal, _leap = lunardays_for_type(year_info[year_diff][month_idx + 1])
      days += total
    end

    days += (day - 1)

    if is_leap_month && year_info[year_diff][month] > 2
      days += lunardays_for_type(year_info[year_diff][month])[1]
    end

    solar_date = SOLAR_START_DATE + days
  end

  def to_s
    format('%4d%02d%02d', year, month, day)
  end

  def inspect
    to_s
  end

  private

  KOREAN_LUNAR_YEAR_INFO = [
    [384, 1, 2, 1, 1, 2, 1, 2, 4, 2, 2, 1, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze,
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze,
    [383, 1, 2, 1, 2, 3, 2, 1, 1, 2, 2, 1, 2].freeze,
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1].freeze,
    [355, 2, 2, 1, 2, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [384, 1, 2, 2, 5, 1, 2, 1, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2].freeze,
    [384, 1, 4, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze,
    [384, 2, 1, 2, 1, 1, 4, 1, 2, 2, 1, 2, 2].freeze,
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2].freeze,
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze,
    [384, 2, 2, 1, 2, 4, 1, 2, 1, 2, 1, 1, 2].freeze,
    [355, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze,
    [384, 2, 3, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1].freeze,
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2].freeze,
    [384, 1, 2, 1, 1, 2, 1, 4, 2, 2, 1, 2, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2].freeze,
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze,
    [384, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 2, 2].freeze,
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2].freeze,
    [354, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 1].freeze,
    [385, 2, 1, 2, 4, 2, 1, 2, 2, 1, 2, 1, 2].freeze,
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze,
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2].freeze,
    [384, 1, 4, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2].freeze,
    [383, 1, 2, 2, 1, 1, 4, 1, 2, 1, 2, 2, 1].freeze,
    [354, 2, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 1].freeze,
    [355, 2, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2].freeze,
    [384, 1, 2, 2, 1, 6, 1, 2, 1, 2, 1, 1, 2].freeze,
    [355, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2].freeze,
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze,
    [384, 2, 1, 5, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze,
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1].freeze,
    [384, 2, 2, 1, 1, 2, 1, 5, 1, 2, 2, 1, 2].freeze,
    [354, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [354, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze,
    [384, 2, 2, 1, 2, 2, 5, 1, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1, 1, 2].freeze,
    [355, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2].freeze,
    [384, 1, 1, 2, 5, 1, 2, 1, 2, 2, 1, 2, 2].freeze,
    [354, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2].freeze,
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2].freeze,
    [384, 2, 4, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2].freeze,
    [354, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [384, 2, 2, 1, 2, 1, 2, 3, 2, 1, 2, 1, 2].freeze,
    [354, 2, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze,
    [384, 1, 2, 1, 2, 5, 2, 1, 2, 1, 2, 1, 2].freeze,
    [355, 1, 2, 1, 1, 2, 2, 1, 2, 2, 1, 2, 2].freeze,
    [354, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2].freeze,
    [384, 2, 1, 5, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze,
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2].freeze,
    [384, 2, 1, 2, 1, 2, 1, 1, 4, 2, 1, 2, 2].freeze,
    [354, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1].freeze,
    [384, 2, 1, 2, 1, 2, 4, 2, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze,
    [384, 2, 1, 2, 3, 2, 1, 2, 1, 2, 2, 2, 1].freeze,
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze,
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2].freeze,
    [383, 1, 2, 4, 2, 1, 1, 2, 1, 1, 2, 2, 1].freeze,
    [355, 2, 2, 1, 2, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [384, 1, 2, 2, 1, 2, 1, 4, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2].freeze,
    [384, 1, 2, 1, 1, 4, 2, 1, 2, 2, 2, 1, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze,
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2, 1].freeze,
    [384, 2, 2, 1, 4, 1, 2, 1, 1, 2, 2, 1, 2].freeze,
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze,
    [384, 2, 2, 1, 2, 1, 2, 1, 4, 2, 1, 1, 2].freeze,
    [354, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 1].freeze,
    [355, 2, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze,
    [384, 2, 1, 1, 2, 1, 6, 1, 2, 2, 1, 2, 1].freeze,
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2].freeze,
    [384, 2, 1, 2, 3, 2, 1, 1, 2, 2, 1, 2, 2].freeze,
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze,
    [384, 2, 1, 2, 2, 1, 1, 2, 1, 1, 4, 2, 2].freeze,
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2].freeze,
    [354, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2, 1, 1].freeze,
    [385, 2, 1, 2, 2, 1, 4, 2, 2, 1, 2, 1, 2].freeze,
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze,
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2].freeze,
    [384, 1, 2, 1, 1, 4, 1, 2, 2, 1, 2, 2, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2].freeze,
    [354, 1, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze,
    [383, 1, 2, 4, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze,
    [355, 2, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2].freeze,
    [384, 1, 2, 2, 1, 2, 2, 1, 4, 2, 1, 1, 2].freeze,
    [355, 1, 2, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2].freeze,
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze,
    [384, 2, 1, 1, 2, 3, 2, 2, 1, 2, 2, 2, 1].freeze,
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1].freeze,
    [354, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1].freeze,
    [384, 2, 2, 2, 3, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [354, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze,
    [355, 2, 2, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2].freeze,
    [384, 1, 4, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1, 1].freeze,
    [385, 2, 1, 2, 1, 2, 1, 4, 2, 2, 1, 2, 2].freeze,
    [354, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2].freeze,
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2].freeze,
    [384, 2, 2, 1, 1, 4, 1, 2, 1, 2, 1, 2, 2].freeze,
    [354, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [354, 2, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze,
    [384, 2, 1, 6, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze,
    [384, 1, 2, 1, 2, 1, 2, 1, 2, 4, 2, 1, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2, 1].freeze,
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2].freeze,
    [384, 1, 2, 1, 2, 3, 2, 1, 2, 1, 2, 2, 2].freeze,
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2].freeze,
    [354, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [384, 2, 1, 2, 4, 2, 1, 1, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2].freeze,
    [384, 1, 4, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze,
    [384, 2, 1, 2, 1, 1, 4, 2, 1, 2, 2, 2, 1].freeze,
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze,
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2].freeze,
    [383, 1, 2, 2, 1, 4, 1, 2, 1, 1, 2, 2, 1].freeze,
    [355, 2, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 2].freeze,
    [354, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1].freeze,
    [384, 2, 1, 4, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2].freeze,
    [384, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 4, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze,
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2].freeze,
    [384, 2, 2, 1, 2, 1, 5, 1, 1, 2, 2, 1, 2].freeze,
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze,
    [354, 2, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1].freeze,
    [384, 2, 2, 1, 2, 4, 2, 1, 2, 1, 2, 1, 1].freeze,
    [355, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze,
    [355, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2].freeze,
    [384, 1, 4, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2].freeze,
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2].freeze,
    [384, 2, 1, 2, 1, 1, 2, 3, 2, 1, 2, 2, 2].freeze,
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze,
    [354, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze,
    [384, 2, 1, 2, 2, 5, 1, 2, 1, 1, 2, 1, 2].freeze,
    [354, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2, 1, 1].freeze,
    [355, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1].freeze
  ].freeze

  CHINESE_LUNAR_YEAR_INFO = [
    [384, 1, 2, 1, 1, 2, 1, 2, 4, 2, 2, 1, 2].freeze, # 1901
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze, # 1902
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze, # 1903
    [383, 1, 2, 1, 2, 3, 2, 1, 1, 2, 2, 1, 2].freeze, # 1904
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1].freeze, # 1905
    [355, 2, 2, 1, 2, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 1906
    [384, 1, 2, 2, 5, 1, 2, 1, 2, 1, 2, 1, 2].freeze, # 1907
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze, # 1908
    [355, 2, 1, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2].freeze, # 1909
    [384, 1, 4, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2].freeze, # 1910
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze, # 1911
    [384, 2, 1, 2, 1, 1, 4, 1, 2, 2, 1, 2, 2].freeze, # 1912
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2].freeze, # 1913
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze, # 1914
    [384, 2, 2, 1, 2, 4, 1, 2, 1, 2, 1, 1, 2].freeze, # 1915
    [355, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze, # 1916
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze, # 1917
    [384, 2, 3, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1].freeze, # 1918
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2].freeze, # 1919
    [384, 1, 2, 1, 1, 2, 1, 4, 2, 2, 1, 2, 2].freeze, # 1920
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2].freeze, # 1921
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze, # 1922
    [384, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 2, 2].freeze, # 1923
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2].freeze, # 1924
    [354, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 1].freeze, # 1925
    [385, 2, 1, 2, 4, 2, 1, 2, 2, 1, 2, 1, 2].freeze, # 1926
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze, # 1927
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2].freeze, # 1928
    [384, 1, 4, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2].freeze, # 1929
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2].freeze, # 1930
    [383, 1, 2, 2, 1, 1, 4, 1, 2, 1, 2, 2, 1].freeze, # 1931
    [354, 2, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 1].freeze, # 1932
    [355, 2, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2].freeze, # 1933
    [384, 1, 2, 2, 1, 6, 1, 2, 1, 2, 1, 1, 2].freeze, # 1934
    [355, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2].freeze, # 1935
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze, # 1936
    [384, 2, 1, 5, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze, # 1937
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1].freeze, # 1938
    [384, 2, 2, 1, 1, 2, 1, 5, 1, 2, 2, 1, 2].freeze, # 1939
    [354, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 1940
    [354, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze, # 1941
    [384, 2, 2, 1, 2, 2, 5, 1, 1, 2, 1, 2, 1].freeze, # 1942
    [355, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1, 1, 2].freeze, # 1943
    [355, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2].freeze, # 1944
    [384, 1, 1, 2, 5, 1, 2, 1, 2, 2, 1, 2, 2].freeze, # 1945
    [354, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2].freeze, # 1946
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2].freeze, # 1947
    [384, 2, 4, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2].freeze, # 1948
    [354, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 1949
    [384, 2, 2, 1, 2, 1, 2, 3, 2, 1, 2, 1, 2].freeze, # 1950
    [354, 2, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze, # 1951
    [355, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze, # 1952
    [384, 1, 2, 1, 2, 5, 2, 1, 2, 1, 2, 1, 2].freeze, # 1953
    [355, 1, 2, 1, 1, 2, 2, 1, 2, 2, 1, 2, 2].freeze, # 1954
    [354, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2].freeze, # 1955
    [384, 2, 1, 5, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze, # 1956
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2].freeze, # 1957
    [384, 2, 1, 2, 1, 2, 1, 1, 4, 2, 1, 2, 2].freeze, # 1958
    [354, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 1959
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1].freeze, # 1960
    [384, 2, 1, 2, 1, 2, 4, 2, 1, 2, 1, 2, 1].freeze, # 1961
    [355, 2, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2].freeze, # 1962
    [354, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze, # 1963
    [384, 2, 1, 2, 3, 2, 1, 2, 1, 2, 2, 2, 1].freeze, # 1964
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze, # 1965
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2].freeze, # 1966
    [383, 1, 2, 4, 2, 1, 1, 2, 1, 1, 2, 2, 1].freeze, # 1967
    [355, 2, 2, 1, 2, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 1968
    [384, 1, 2, 2, 1, 2, 1, 4, 2, 1, 2, 1, 2].freeze, # 1969
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze, # 1970
    [355, 2, 1, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2].freeze, # 1971
    [384, 1, 2, 1, 1, 4, 2, 1, 2, 2, 2, 1, 2].freeze, # 1972
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze, # 1973
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2, 1].freeze, # 1974
    [384, 2, 2, 1, 4, 1, 2, 1, 1, 2, 2, 1, 2].freeze, # 1975
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze, # 1976
    [384, 2, 2, 1, 2, 1, 2, 1, 4, 2, 1, 1, 2].freeze, # 1977
    [354, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 1].freeze, # 1978
    [355, 2, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze, # 1979
    [384, 2, 1, 1, 2, 1, 6, 1, 2, 2, 1, 2, 1].freeze, # 1980
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2].freeze, # 1981
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2].freeze, # 1982
    [384, 2, 1, 2, 3, 2, 1, 1, 2, 2, 1, 2, 2].freeze, # 1983
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze, # 1984
    [384, 2, 1, 2, 2, 1, 1, 2, 1, 1, 4, 2, 2].freeze, # 1985
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2].freeze, # 1986
    [354, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2, 1, 1].freeze, # 1987
    [385, 2, 1, 2, 2, 1, 4, 2, 2, 1, 2, 1, 2].freeze, # 1988
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze, # 1989
    [355, 2, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2].freeze, # 1990
    [384, 1, 2, 1, 1, 4, 1, 2, 2, 1, 2, 2, 2].freeze, # 1991
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2].freeze, # 1992
    [354, 1, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze, # 1993
    [383, 1, 2, 4, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze, # 1994
    [355, 2, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2].freeze, # 1995
    [384, 1, 2, 2, 1, 2, 2, 1, 4, 2, 1, 1, 2].freeze, # 1996
    [355, 1, 2, 1, 2, 2, 1, 2, 1, 2, 2, 1, 2].freeze, # 1997
    [354, 1, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze, # 1998
    [384, 2, 1, 1, 2, 3, 2, 2, 1, 2, 2, 2, 1].freeze, # 1999
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1].freeze, # 2000
    [354, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1].freeze, # 2001
    [384, 2, 2, 2, 3, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 2002
    [354, 2, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze, # 2003
    [355, 2, 2, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2].freeze, # 2004
    [384, 1, 4, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze, # 2005
    [354, 1, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1, 1].freeze, # 2006
    [385, 2, 1, 2, 1, 2, 1, 4, 2, 2, 1, 2, 2].freeze, # 2007
    [354, 1, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2].freeze, # 2008
    [354, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2].freeze, # 2009
    [384, 2, 2, 1, 1, 4, 1, 2, 1, 2, 1, 2, 2].freeze, # 2010
    [354, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 2011
    [354, 2, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze, # 2012
    [384, 2, 1, 6, 2, 1, 2, 1, 1, 2, 1, 2, 1].freeze, # 2013
    [355, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2].freeze, # 2014
    [384, 1, 2, 1, 2, 1, 2, 1, 2, 4, 2, 1, 2].freeze, # 2015
    [354, 1, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2, 1].freeze, # 2016
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2].freeze, # 2017
    [384, 1, 2, 1, 2, 3, 2, 1, 2, 1, 2, 2, 2].freeze, # 2018
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2].freeze, # 2019
    [354, 2, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 2020
    [384, 2, 1, 2, 4, 2, 1, 1, 2, 1, 2, 1, 2].freeze, # 2021
    [354, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1].freeze, # 2022
    [355, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2].freeze, # 2023
    [384, 1, 4, 2, 1, 2, 1, 2, 2, 1, 2, 1, 2].freeze, # 2024
    [354, 1, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1].freeze, # 2025
    [384, 2, 1, 2, 1, 1, 4, 2, 1, 2, 2, 2, 1].freeze, # 2026
    [355, 2, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2].freeze, # 2027
    [354, 1, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 2].freeze, # 2028
    [383, 1, 2, 2, 1, 4, 1, 2, 1, 1, 2, 2, 1].freeze, # 2029
    [355, 2, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 2].freeze, # 2030
    [354, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2, 1].freeze, # 2031
    [384, 2, 1, 4, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze, # 2032
    [355, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2].freeze, # 2033
    [384, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 4, 2].freeze, # 2034
    [354, 1, 2, 1, 1, 2, 1, 2, 1, 2, 2, 2, 1].freeze, # 2035
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2].freeze, # 2036
    [384, 2, 2, 1, 2, 1, 5, 1, 1, 2, 2, 1, 2].freeze, # 2037
    [354, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze, # 2038
    [354, 2, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1].freeze, # 2039
    [384, 2, 2, 1, 2, 4, 2, 1, 2, 1, 2, 1, 1].freeze, # 2040
    [355, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2, 1].freeze, # 2041
    [355, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2].freeze, # 2042
    [384, 1, 4, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2].freeze, # 2043
    [354, 1, 2, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2].freeze, # 2044
    [384, 2, 1, 2, 1, 1, 2, 3, 2, 1, 2, 2, 2].freeze, # 2045
    [354, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 2].freeze, # 2046
    [354, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 1, 2].freeze, # 2047
    [384, 2, 1, 2, 2, 5, 1, 2, 1, 1, 2, 1, 2].freeze, # 2048
    [354, 1, 2, 2, 1, 2, 2, 1, 2, 1, 2, 1, 1].freeze, # 2049
    [355, 2, 1, 2, 1, 2, 2, 1, 2, 2, 1, 2, 1].freeze  # 2050
  ].freeze

  MAX_YEAR_NUMBER = 150
  CALENDAR_YEAR_INFO_MAP = {
    ko: KOREAN_LUNAR_YEAR_INFO,
    cn: CHINESE_LUNAR_YEAR_INFO
  }.freeze

  LUNARDAYS_FOR_MONTHTYPE = {
    1 => [29, 29, 0],
    2 => [30, 30, 0],
    3 => [58, 29, 29],
    4 => [59, 30, 29],
    5 => [59, 29, 30],
    6 => [60, 30, 30]
  }.freeze

  SOLAR_START_DATE = Date.new(1900, 1, 31).freeze

  def initialize(year, month, day, is_leap_month = false)
    self.year = year
    self.month = month
    self.day = day
    self.is_leap_month = is_leap_month
  end

  class << self
    private

    def lunardays_for_type(month_type)
      LUNARDAYS_FOR_MONTHTYPE[month_type]
    end

    def get_days(solar_date)
      (solar_date - SOLAR_START_DATE).to_i
    end

    def in_this_days?(days, left_days)
      (days - left_days) < 0
    end

    def lunar_from_days(days, calendar_symbol)
      start_year = 1900
      target_month = 0
      is_leap_month = false
      matched = false
      year_info = CALENDAR_YEAR_INFO_MAP[calendar_symbol]

      MAX_YEAR_NUMBER.times do |year_idx|
        year_days = year_info[year_idx][0]
        if in_this_days?(days, year_days)
          12.times do |month_idx|
            total, normal, _leap = lunardays_for_type(year_info[year_idx][month_idx + 1])
            if in_this_days?(days, total)
              unless in_this_days?(days, normal)
                days -= normal
                is_leap_month = true
              end

              matched = true
              break
            end

            days -= total
            target_month += 1
          end
        end

        break if matched

        days -= year_days
        start_year += 1
      end

      lunar_date = new(start_year, target_month + 1, days + 1, is_leap_month)

      lunar_date
    end
  end
end
