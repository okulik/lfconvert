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
        rates = subject.get_rates(FIXTURES_FILE_PATH, 5)
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
    let(:date_index) { subject.get_rates(FIXTURES_FILE_PATH, 5).keys.sort }

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

    context "there's no rate for the given date in the future" do
      let(:_ret) { subject.get_rate_and_nearest_date_for_date(rates, '2026-05-30') }
      let(:rate) { _ret[:rate] }
      let(:nearest_date) { _ret[:nearest_date] }

      it "should return last known date" do
        expect(nearest_date).to eq('2016-05-30')
      end

      it "should return last known rate" do
        expect(rate).to eq(subject.get_rate_and_nearest_date_for_date(rates, '2016-05-30')[:rate])
      end

      it "should return correct rate" do
        expect(rate).to eq(BigDecimal.new('1.1139'))
      end
    end

    context "there's a rate for the given date" do
      let(:_ret) { subject.get_rate_and_nearest_date_for_date(rates, '2016-05-30') }
      let(:rate) { _ret[:rate] }
      let(:nearest_date) { _ret[:nearest_date] }

      it "should return given day's date" do
        expect(nearest_date).to eq('2016-05-30')
      end

      it "should return correct rate" do
        expect(rate).to eq(BigDecimal.new('1.1139'))
      end
    end

    context "given date is on the weekend" do
      let(:_ret) { subject.get_rate_and_nearest_date_for_date(rates, '2016-05-28') }
      let(:rate) { _ret[:rate] }
      let(:nearest_date) { _ret[:nearest_date] }

      it "should return previous day's date" do
        expect(nearest_date).to eq('2016-05-27')
      end

      it "should return last known rate" do
        expect(rate).to eq(subject.get_rate_and_nearest_date_for_date(rates, '2016-05-27')[:rate])
      end

      it "should return correct rate" do
        expect(rate).to eq(BigDecimal.new('1.1168'))
      end
    end

    context "given date is before beginning of time" do
      let(:ret) { subject.get_rate_and_nearest_date_for_date(rates, '1992-01-04') }

      it "should return nil" do
        expect(ret).to be_nil
      end
    end
  end

  describe ".convert" do
    let(:rates) { subject.get_rates(FIXTURES_FILE_PATH, 5) }

    context "there's no rate for the given date in the future" do
      let(:converted_amount) { subject.convert_from_rates(rates, BigDecimal.new('100.0'), '2026-05-30')[:converted_amount] }

      it "should return last known date's converted amount" do
        expect(converted_amount).to eq('89.774665')
      end
    end

    context "there's a rate for the given date" do
      let(:converted_amount) { subject.convert_from_rates(rates, BigDecimal.new('100.0'), '2016-05-30')[:converted_amount] }

      it "should return given date's converted amount" do
        expect(converted_amount).to eq('89.774665')
      end
    end

    context "given date is on the weekend" do
      let(:converted_amount) { subject.convert_from_rates(rates, BigDecimal.new('100.0'), '2016-05-28')[:converted_amount] }

      it "should return previous day's converted amount" do
        expect(converted_amount).to eq('89.541547')
      end
    end

    context "given date is before beginning of time" do
      let(:ret) { subject.convert_from_rates(rates, BigDecimal.new('100.0'), '1992-01-04') }

      it "should return error" do
        expect(ret).to include(:error)
      end
    end
  end
end
