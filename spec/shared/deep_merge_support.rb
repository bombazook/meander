shared_examples 'support deep_merge support' do
  let(:original_hash) { { x: { y: { z: 1 } } } }

  shared_examples 'common deep_merge' do
    it 'addes new key to subhash' do
      expect(merged_config.x.y.yo).to be_eql(2)
    end

    it 'keeps original key in subhash' do
      expect(merged_config.x.y.z).to be_eql(1)
    end

    it 'makes subhash covered with described class' do
      expect(merged_config.x.y).to be_instance_of(described_class)
    end
  end

  context 'external merge' do
    let(:merged_config) { original_config.deep_merge(x: { y: { yo: 2 } }) }

    it_behaves_like 'common deep_merge'
  end

  context 'empty original config' do
    let(:original_hash) { {} }

    it 'does not alter original_hash' do
      original_config.deep_merge(some: :hash)
      expect(original_config.keys).to be_empty
    end
  end

  context 'internal merge' do
    let(:merged_config) { original_config.deep_merge!(x: { y: { yo: 2 } }) }

    it_behaves_like 'common deep_merge'
  end
end
