require 'spec_helper'

RSpec.describe Meander::Mutable do
  context "single target" do
    include_examples 'common meander'
    include_examples 'mutable meander'
  end

  context 'multiple targets' do
    include_examples 'common meander' do
      let(:second_hash) { { second_target: 1 } }
      let(:original_config) { described_class.new(original_hash, second_hash) }
      include_examples 'mutable meander'

      it "has second target set" do
        expect(original_config).to respond_to(:second_target)
      end

      it "support multiple mutable targets" do
        original_hash[:x] = 2
        second_hash[:second_target] = 3
        expect(original_config.x).to be_eql(2)
        expect(original_config.second_target).to be_eql(3)
      end
    end
  end
end
