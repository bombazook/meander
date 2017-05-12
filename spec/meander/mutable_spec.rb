require 'spec_helper'

RSpec.describe Meander::Mutable do
  it_behaves_like 'common meander' do
    it_behaves_like 'mutable meander'
  end
end
