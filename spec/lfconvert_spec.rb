require 'spec_helper'

FIXTURES_FILE_PATH = File.join(File.dirname(__FILE__), 'fixtures', 'data.csv')

describe LFConvert::UsdToEurConverter do
  it "has a version number" do
    expect(LFConvert::VERSION).not_to be nil
  end

  subject { LFConvert::UsdToEurConverter.new }

  describe ".get_rates" do
    context "we use correct number of lines to skip in CSV file" do
      it "should return a proper rates dictionary" do
        rates = subject.get_rates(File.join(File.dirname(__FILE__), 'fixtures', 'data.csv'), 5)
        expect(rates).to include({
          '2016-05-30' => BigDecimal.new('1.1139'),
          '2016-05-27' => BigDecimal.new('1.1168'),
          '2016-05-26' => BigDecimal.new('1.1168'),
          '2016-05-25' => BigDecimal.new('1.1146'),
          '2016-05-20' => BigDecimal.new('1.1219'),
          '1999-01-04' => BigDecimal.new('1.1789')
        })
      end
    end

    context "we skipped too many lines in CSV file" do
      it "should return smaller number of rates than available" do
        rates = subject.get_rates(FIXTURES_FILE_PATH, 7)
        expect(rates.count).to be < 6
      end
    end

    context "we didn't skip any lines in CSV file" do
      it "should return empty dictionary" do
        rates = subject.get_rates(FIXTURES_FILE_PATH, 0)
        expect(rates).to be_empty
      end
    end
  end

  describe ".get_nearest_date" do
    let(:rates) { subject.get_rates(FIXTURES_FILE_PATH, 5) }
    let(:date_index) { rates.keys.sort }

    it "should return specified date when using existing date" do
      expect(subject.get_nearest_date(date_index, '2016-05-30')).to eq('2016-05-30')
    end

    it "should return last date when using future, non-exising date" do
      expect(subject.get_nearest_date(date_index, '2026-05-30')).to eq('2016-05-30')
    end

    it "should return last working day's date when using weekend date" do
      expect(subject.get_nearest_date(date_index, '2016-05-29')).to eq('2016-05-27')
    end

    it "should return nil when using before-history date" do
      expect(subject.get_nearest_date(date_index, '1984-01-01')).to be_nil
    end
  end

  describe ".get_rate_and_nearest_date_for_date" do
    let(:rates) { subject.get_rates(FIXTURES_FILE_PATH, 5) }

    it "should return correct rates" do
      expect(subject.get_rate_and_nearest_date_for_date(rates, '2016-05-30')[:rate]).to eq(BigDecimal.new('1.1139'))
      expect(subject.get_rate_and_nearest_date_for_date(rates, '2016-05-27')[:rate]).to eq(BigDecimal.new('1.1168'))
      expect(subject.get_rate_and_nearest_date_for_date(rates, '2016-05-26')[:rate]).to eq(BigDecimal.new('1.1168'))
      expect(subject.get_rate_and_nearest_date_for_date(rates, '2016-05-25')[:rate]).to eq(BigDecimal.new('1.1146'))
      expect(subject.get_rate_and_nearest_date_for_date(rates, '2016-05-20')[:rate]).to eq(BigDecimal.new('1.1219'))
      expect(subject.get_rate_and_nearest_date_for_date(rates, '1999-01-04')[:rate]).to eq(BigDecimal.new('1.1789'))
    end
  end

  describe ".convert" do
    it "should return correct converted amounts" do
      expect(subject.convert(BigDecimal.new('100.0'), '2016-05-30')[:converted_amount]).to eq('89.774665')
      expect(subject.convert(BigDecimal.new('100.0'), '2016-05-27')[:converted_amount]).to eq('89.541547')
      expect(subject.convert(BigDecimal.new('100.0'), '2016-05-26')[:converted_amount]).to eq('89.541547')
      expect(subject.convert(BigDecimal.new('100.0'), '2016-05-25')[:converted_amount]).to eq('89.718284')
      expect(subject.convert(BigDecimal.new('100.0'), '2016-05-20')[:converted_amount]).to eq('89.134503')
      expect(subject.convert(BigDecimal.new('100.0'), '1999-01-04')[:converted_amount]).to eq('84.824836')
    end
  end
end
