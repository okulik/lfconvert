require 'spec_helper'

FIXTURES_FILE_PATH = File.join(File.dirname(__FILE__), 'fixtures', 'data.csv')

describe LFConvert::UsdToEurConverter do
  it "has a version number" do
    expect(LFConvert::VERSION).not_to be nil
  end

  describe ".convert" do
    before(:each) do
      allow(subject).to receive(:download_rates)
      allow(subject).to receive(:get_cached_rates_path).and_return FIXTURES_FILE_PATH
    end

    context "there's no rate for the given date in the future" do
      it "should return last known date's converted amount" do
        result = subject.convert!(BigDecimal.new('100.0'), '2026-05-30')

        expect(result[:rate]).to eq('1.1139')
        expect(result[:nearest_date]).to eq('2016-05-30')
        expect(result[:converted_amount]).to eq('89.774665')
      end
    end

    context "there's a rate for the given date" do
      it "should return given date's converted amount" do
        result = subject.convert!(BigDecimal.new('100.0'), '2016-05-30')

        expect(result[:rate]).to eq('1.1139')
        expect(result[:nearest_date]).to eq('2016-05-30')
        expect(result[:converted_amount]).to eq('89.774665')
      end
    end

    context "given date is on the weekend" do
      it "should return previous day's converted amount" do
        result = subject.convert!(BigDecimal.new('100.0'), '2016-05-28')

        expect(result[:rate]).to eq('1.1168')
        expect(result[:nearest_date]).to eq('2016-05-27')
        expect(result[:converted_amount]).to eq('89.541547')
      end
    end

    context "rate for a given date is invalid" do
      it "should return previous day's converted amount" do
        result = subject.convert!(BigDecimal.new('100.0'), '2016-05-21')

        expect(result[:rate]).to eq('1.1219')
        expect(result[:nearest_date]).to eq('2016-05-20')
        expect(result[:converted_amount]).to eq('89.134503')
      end
    end

    context "given date is before beginning of time" do
      it "should raise exception" do
        expect{subject.convert!(BigDecimal.new('100.0'), '1992-01-04')}.to raise_error(/No rate available for date/)
      end
    end
  end
end
