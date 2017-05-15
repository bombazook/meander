shared_examples 'support deep_merge' do
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

    it 'keeps merged_config mutable' do
      merged_config
      original_hash[:p] = 1
      expect(merged_config.p).to be_eql(1)
    end
  end

  context 'external merge' do
    let(:merged_config) { original_config.deep_merge(x: { y: { yo: 2 } }) }

    it_behaves_like 'common deep_merge'
  end

  context 'internal merge' do
    let(:merged_config) { original_config.deep_merge!(x: { y: { yo: 2 } }) }

    it_behaves_like 'common deep_merge'
  end

  context 'altered keys support' do
    let(:original_hash) { {} }
    let(:merging_config) do
      config = described_class.new(a: 1)
      config.b = 2
      config
    end
    let(:merged_config) { original_config.deep_merge(merging_config) }

    it 'adds both own keys and original keys under deep_merge' do
      expect(merged_config.keys).to include('a', 'b')
    end
  end

  context 'empty original config' do
    let(:original_hash) { {} }

    it 'does not alter original_hash' do
      original_config.deep_merge(some: :hash)
      expect(original_config.keys).to be_empty
    end
  end
end
