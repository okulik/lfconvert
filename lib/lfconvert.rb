require 'lfconvert/version'
require 'open-uri'
require 'bigdecimal'

module LFConvert
  class UsdToEurConverter
    CEB_CSV_URL = "http://sdw.ecb.europa.eu/export.do?type=&trans=N&node=2018794&CURRENCY=USD&FREQ=D&start=01-01-2012&q=&submitOptions.y=6&submitOptions.x=51&sfl1=4&end=&SERIES_KEY=120.EXR.D.USD.EUR.SP00.A&sfl3=4&DATASET=0&exportType=csv"
    DEFAULT_CONFIG_FOLDER = File.expand_path('~/.lfconvert')
    RATES_FILE_PATH = File.join(DEFAULT_CONFIG_FOLDER, 'rates.csv')
    SKIP_CSV_LINES = 5
    DEFAULT_NUMERIC_PRECISION = 6

    attr_reader :options

    def initialize(options = {})
      @options = options
      @options.merge!(precision: LFConvert::UsdToEurConverter::DEFAULT_NUMERIC_PRECISION) unless @options.has_key?(:precision)
    end

    def convert(from_amount, date)
      rates = get_rates_from_ecb
      if rates.empty?
        return {code: -1, error: "CEB file is either missing or contains invalid data"}
      end

      convert_from_rates(rates, from_amount, date)
    end

    def convert_from_rates(rates, from_amount, date)
      rate_dict = get_rate_and_nearest_date_for_date(rates, date)
      if rate_dict.nil?
        return {code: -1, error: "No rate available for date #{date}"}
      end

      rate = rate_dict[:rate]
      nearest_date = rate_dict[:nearest_date]
      converted_amount = from_amount / rate

      return {code: 0, rate: format_money(rate), nearest_date: nearest_date, converted_amount: format_money(converted_amount)}
    end

    def get_rates_from_ecb
      unless Dir.exist?(DEFAULT_CONFIG_FOLDER)
        FileUtils::mkdir(DEFAULT_CONFIG_FOLDER)
        download_rates(RATES_FILE_PATH, CEB_CSV_URL)
      end

      if !File.exist?(RATES_FILE_PATH) || options[:force]
        download_rates(RATES_FILE_PATH, CEB_CSV_URL)
      end

      get_rates(RATES_FILE_PATH, SKIP_CSV_LINES)
    end

    def get_rate_and_nearest_date_for_date(rates, date)
      date_index = rates.keys.sort

      nearest_date = get_nearest_date(date_index, date)
      return nil if nearest_date.nil?

      {rate: rates[nearest_date], nearest_date: nearest_date}
    end

    def download_rates(rates_file_path, ceb_csv_url)
      begin
        open(rates_file_path, 'wb') do |file|
          file << open(ceb_csv_url).read
        end
      rescue
        FileUtils.rm rates_file_path, force: true
      end
    end

    def get_rates(rates_file_path, skip_csv_lines)
      rates = {}

      if File.exist?(rates_file_path)
        File.readlines(rates_file_path).drop(skip_csv_lines).each do |line|
          m = /(\d{4}-\d{2}-\d{2}),(.*)/.match(line.chomp)
          break if m.nil?

          date = m[1]; rate = m[2]
          rates[date] = BigDecimal.new(rate, 2)
        end
      end

      rates
    end

    def get_nearest_date(date_index, date)
      date_index.select {|d| d <= date}.last
    end

    def format_money(amount)
      amount.truncate(options[:precision]).to_s('F')
    end
  end
end
