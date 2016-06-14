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

    def initialize(options = {})
      @options = options
      @options.merge!(precision: LFConvert::UsdToEurConverter::DEFAULT_NUMERIC_PRECISION) unless @options.has_key?(:precision)
    end

    def convert!(from_amount, date)
      rate, nearest_date = get_rate_and_nearest_date_for_date(date)
      {rate: format_money(rate), nearest_date: nearest_date, converted_amount: format_money(from_amount / rate)}
    end


    private

    def get_rates
      @rates ||= begin
        unless Dir.exist?(DEFAULT_CONFIG_FOLDER)
          FileUtils::mkdir(DEFAULT_CONFIG_FOLDER)
          download_rates(get_cached_rates_path, CEB_CSV_URL)
        end

        if !File.exist?(get_cached_rates_path) || @options[:force]
          download_rates(get_cached_rates_path, CEB_CSV_URL)
        end

        init_rates_from_file(get_cached_rates_path, SKIP_CSV_LINES)
      end
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

    def init_rates_from_file(rates_file_path, skip_csv_lines)
      rates = {}

      if File.exist?(rates_file_path)
        File.readlines(rates_file_path).drop(skip_csv_lines).each do |line|
          m = /(\d{4}-\d{2}-\d{2}),(\d+\.\d*)/.match(line.chomp)
          if m
            date = m[1]; rate = m[2]
            bd_rate = BigDecimal.new(rate, 2)
            rates[date] = bd_rate if bd_rate != BigDecimal.new('0')
          end
        end
      end

      raise 'CEB file is either missing or contains invalid data' if rates.empty?

      rates
    end

    def get_rate_and_nearest_date_for_date(date)
      nearest_date = find_nearest_date(date)
      [get_rates[nearest_date], nearest_date]
    end

    def find_nearest_date(date)
      nearest_date = get_rates_index.select {|d| d <= date}.last
      raise "No rate available for date #{date}" if nearest_date.nil?
      nearest_date
    end

    def get_rates_index
      @rates_index ||= get_rates.keys.sort
    end

    def get_cached_rates_path
      return RATES_FILE_PATH
    end

    def format_money(amount)
      amount.truncate(@options[:precision]).to_s('F')
    end
  end
end
