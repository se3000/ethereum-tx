describe Eth::Chains do
  describe '.legacy_recover_id?' do
    it 'is true for legacy versions' do
      expect(described_class.legacy_recovery_id?(27)).to be true
      expect(described_class.legacy_recovery_id?(28)).to be true
    end

    it 'is false for non-legacy versions' do
      expect(described_class.legacy_recovery_id?(29)).to be false
    end
  end

  describe '.to_recovery_id' do
    it 'correctly handles legacy versions' do
      expect(described_class.to_recovery_id(27, nil)).to eq(0)
      expect(described_class.to_recovery_id(28, nil)).to eq(1)
    end

    it 'raises an error if invalid legacy version is given without chain_id' do
      expect do
        expect(described_class.to_recovery_id(29, nil))
      end.to raise_error(ArgumentError, 'Invalid legacy v value 29.')
    end

    it 'correctly handles non-legacy versions' do
      expect(described_class.to_recovery_id(37, Eth::Chains::MAINNET)).to eq(0)
      expect(described_class.to_recovery_id(38, Eth::Chains::MAINNET)).to eq(1)
    end

    it 'raises an error if an invalid non-legacy version is given' do
      expect do
        described_class.to_recovery_id(29, Eth::Chains::MAINNET)
      end.to raise_error(ArgumentError, 'Invalid v value for chain 1. Invalid chain_id?')
    end
  end

  describe '.to_v' do
    it 'returns the correct version' do
      expect(described_class.to_v(0, Eth::Chains::MAINNET)).to eq(37)
      expect(described_class.to_v(1, Eth::Chains::MAINNET)).to eq(38)
    end
  end
end
