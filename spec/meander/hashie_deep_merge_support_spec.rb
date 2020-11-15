require 'spec_helper'
require 'hashie'

class HashieDeepMergeSupport < Meander::Mutable
  include ::Hashie::Extensions::DeepMerge
end

RSpec.describe HashieDeepMergeSupport do
  it_behaves_like 'common meander' do
    it_behaves_like 'mutable meander' do
      it_behaves_like 'support deep_merge'
    end
  end
end
