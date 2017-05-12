shared_examples 'mutable meander' do
  describe '#[]= and #[]' do
    it 'changes higher level hash response if original one changed' do
      original_config
      original_hash[:x] = 2
      expect(original_config[:x]).to be_eql 2
    end

    context 'nested hash object' do
      let(:original_hash) { { x: {} } }

      it 'makes new object cover after underlying key assignment' do
        subhash = { y: 2 }
        original_config[:x][:y] = subhash
        subhash[:z] = 3
        expect(original_config[:x][:y][:z]).to be_eql(3)
      end

      it 'covers new object after second level underlying key assignment' do
        subhash = { y: 2 }
        subhash2 = { f: 4 }
        original_config[:x][:y] = subhash
        subhash[:z] = 3
        original_config[:x][:y][:z] = subhash2
        expect(original_config[:x][:y][:z][:f]).to be_eql(4)
      end
    end
  end

  describe '#method_missing' do
    context 'nested hash object' do
      let(:original_hash) { { x: {} } }

      it 'makes new object cover after underlying key assignment' do
        subhash = { y: 2 }
        original_config.x.y = subhash
        subhash[:z] = 3
        expect(original_config.x.y.z).to be_eql(3)
      end

      it 'covers new object after second level underlying key assignment' do
        subhash = { y: 2 }
        subhash2 = { f: 4 }
        original_config.x.y = subhash
        subhash[:z] = 3
        original_config.x.y.z = subhash2
        expect(original_config.x.y.z.f).to be_eql(4)
      end
    end
  end

  context 'nested hash' do
    let(:original_hash) { { x: { y: 1 } } }

    it 'creates higher level hash if accessing key not declared' do
      config_copy[:x][:y] = 2
      expect(original_config[:x][:y]).to be_eql(1)
    end
  end

  describe '.some_key=' do
    it 'does not break [] with false value' do
      original_config.y = false
      config_copy[:y] = true
      expect(config_copy[:y]).to be_eql(true)
    end

    it 'does not break method_missing with false value' do
      original_config.y = false
      config_copy[:y] = true
      expect(config_copy.y).to be_eql(true)
    end
  end
end
