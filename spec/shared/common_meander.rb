# frozen_string_literal: true

RSpec.shared_examples 'common meander' do
  let(:original_hash) { { x: 1 } }
  let(:original_config) { described_class.new(original_hash) }
  let(:config_copy) { described_class.new(original_config) }

  describe '#merge!' do
    it 'doesn\'t change original hash values' do
      config_copy.merge! :x => 2, 'toast' => 3
      expect(original_config[:x]).to be_eql(1)
    end

    it 'doesn\'t set new values to original hash' do
      config_copy.merge! :x => 2, 'toast' => 3
      expect(original_config['toast']).to be_nil
    end
  end

  describe '#[]= and #[]' do
    it 'doesn\'t change original hash values' do
      config_copy['toast'] = 2
      config_copy[:x] = 3
      expect(original_config[:x]).to be_eql(1)
    end

    it 'doesn\'t set new values to original hash' do
      config_copy['toast'] = 2
      config_copy[:x] = 3
      expect(original_config['toast']).to be_nil
    end

    it 'covers child hash by cover_class' do
      config_copy[:x] = { z: 1 }
      expect(config_copy[:x]).to be_kind_of(config_copy.class.cover_class)
    end

    it 'behaves like hash_with_indifferent_access' do
      expect(original_config['x']).to be(1)
    end

    it 'allows not string nor symbol keys' do
      original_hash[1] = 1
      expect { original_config[1] }.not_to raise_exception
    end

    context 'true-false values' do
      let(:original_hash) { { x: true } }

      it 'changes value even if it doesn\'t true in boolean expression' do
        config_copy[:x] = false
        expect(config_copy.x).to be_eql(false)
      end
    end
  end

  describe '#initialize' do
    context 'without arguments' do
      let(:original_config) { described_class.new }

      it 'creates object with empty keys list' do
        expect(original_config.keys).to be_empty
      end
    end

    context 'with nil argument' do
      let(:original_hash) { nil }
      let(:original_config) { described_class.new(original_hash) }

      it 'creates object with empty keys list' do
        expect(original_config.keys).to be_empty
      end
    end
  end

  describe '#method_missing' do
    it 'doesn\'t change original hash values' do
      config_copy.x = 2
      config_copy.y = 1
      expect(original_config[:x]).to be_eql(1)
    end

    it 'doesn\'t set new values to original hash' do
      config_copy.x = 2
      config_copy.y = 1
      expect(original_config[:y]).to be_nil
    end

    it 'allows to access key value by method' do
      expect(original_config.x).to be_eql 1
    end

    it 'doesn\'t create method with _some_name_= key' do
      begin
        original_config[:z=] = 3
      rescue NameError
      end
      original_config.z = 4
      expect(original_config.keys).not_to include('z=')
    end

    it 'raise NameError on []= method with _some_name_= key' do
      expect do
        original_config[:z=] = 3
      end.to raise_error(NameError)
    end

    it 'creates new value if block given' do
      original_config.z { |z| z.x = 1 }
      expect(original_config.z.x).to be_eql 1
    end

    it 'raises NoMethodError if no values set' do
      expect { original_config.non_exist }.to raise_error(NoMethodError)
    end

    context 'with original key already has some value' do
      it 'overrides this value' do
        original_config.x { |x| x.x = 1 }
        expect(original_config.x.x).to be_eql 1
      end
    end
  end

  describe '#key?' do
    it 'true if value was changed' do
      config_copy.y = 2
      expect(config_copy.key?(:y)).to be_eql true
    end

    it 'true if original hash has this value' do
      config_copy.y = 2
      expect(config_copy.key?(:x)).to be_eql true
    end

    it 'false if no such key in exact hash or original one' do
      config_copy.y = 2
      expect(config_copy.key?(:z)).to be_eql false
    end

    context 'with different type keys' do
      let(:original_hash) { { :x => 1, 'y' => 2 } }

      it 'true if original one had symbol key but argument is string' do
        expect(original_config.key?('x')).to be_eql true
      end

      it 'true if original one had string key but argument is symbol' do
        expect(original_config.key?(:y)).to be_eql true
      end
    end
  end

  describe '#keys' do
    it 'converts to_s keys of both current and super hash' do
      original_config[:y] = 2
      expect(original_config.keys).to include('x', 'y')
    end
  end
end
