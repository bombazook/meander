shared_examples 'support deep_merge support' do
  let(:original_hash) { { x: { y: { z: 1 } } } }

  context 'external merge' do
    let(:merged_config) { original_config.deep_merge(x: { y: { yo: 2 } }) }

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

  context 'internal merge' do
    let(:merged_config) { original_config.deep_merge!(x: { y: { yo: 2 } }) }

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
end
