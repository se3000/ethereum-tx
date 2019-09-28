describe Eth::Key, type: :model do
  let(:priv) { nil }
  subject(:key) { Eth::Key.new priv: priv }

  describe "#initialize" do
    it "returns a key with a new private key" do
      key1 = Eth::Key.new
      key2 = Eth::Key.new

      expect(key1.private_hex).not_to eq(key2.private_hex)
      expect(key1.public_hex).not_to eq(key2.public_hex)
    end

    it "regenerates an old private key" do
      key1 = Eth::Key.new
      key2 = Eth::Key.new priv: key1.private_hex

      expect(key1.private_hex).to eq(key2.private_hex)
      expect(key1.public_hex).to eq(key2.public_hex)
    end
  end

  describe "#sign" do
    let(:message) { "Hi Mom!" }

    it "signs a message so that the public key is recoverable" do
      10.times do
        signature = key.sign message
        expect(key.verify_signature message, signature).to be_truthy
      end
    end
  end

  describe "#personal_sign" do
    let(:message) { "Hi Mom!" }

    it "signs a message so that the public key can be recovered with personal_recover" do
      10.times do
        signature = key.personal_sign message
        expect(Eth::Key.personal_recover message, signature).to eq(key.public_hex)
      end
    end
  end

  describe ".personal_recover" do
    let(:message) { "test" }
    let(:signature) { "3eb24bd327df8c2b614c3f652ec86efe13aa721daf203820241c44861a26d37f2bffc6e03e68fc4c3d8d967054c9cb230ed34339b12ef89d512b42ae5bf8c2ae1c" }
    let(:public_hex) { "043e5b33f0080491e21f9f5f7566de59a08faabf53edbc3c32aaacc438552b25fdde531f8d1053ced090e9879cbf2b0d1c054e4b25941dab9254d2070f39418afc" }

    it "it can recover a public key from a signature generated with web3/metamask" do
      10.times do
        expect(Eth::Key.personal_recover message, signature).to eq(public_hex)
      end
    end
  end

  describe "#verify_signature" do
    let(:priv) { '5a37533acfa3ff9386aed01e16c0e7a79038ce05cc383e290d360b8ce9cd6fdf' }
    let(:signature) { hex_to_bin "1ce2f13b4123a23a4a280ac4adcba1ffa3f3848f494dc1de440af43f677e0e01260fb4667ed117d555659b249702c8215162b3f0ee09628813a4ef83616f99f180" }
    let(:message) { "Hi Mom!" }

    it "signs a message so that the public key is recoverable" do
      expect(key.verify_signature message, signature).to be_truthy
    end

    context "when the signature matches another public key" do
      let(:other_priv) { 'fd7f87d1f8c6cdfeb36caa491864519e89b405850c9e2e070839e74966d810cf' }
      let(:signature) { hex_to_bin "1b21a66b55af07a2b0981e3a0ba1768382c5bdbed3d16bcc58a8011425b3bbc090f881cc13d16792af55438637fbe9a2a81d85d6bb18b87b6c08aa9c20ce1341f4" }

      it "does not verify the signature" do
        expect(key.verify_signature message, signature).to be_falsy
      end
    end

    context "when the signature is invalid" do
      let(:signature) { hex_to_bin "1b21a66b" }

      it "raises an error" do
        expect do
          key.verify_signature(message, signature)
        end.to raise_error(::Secp256k1::Error)
      end
    end
  end

  describe "#address" do
    subject { key.address }
    let(:priv) { 'c3a4349f6e57cfd2cbba275e3b3d15a2e4cf00c89e067f6e05bfee25208f9cbb' }
    it { is_expected.to eq('0x759b427456623a33030bbC2195439C22A8a51d25') }
    it { is_expected.to eq(key.to_address) }
  end

  describe ".encrypt/.decrypt" do
    # see: https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition

    let(:password) { SecureRandom.base64 }
    let(:key) { Eth::Key.new }

    it "reads and writes keys in the Ethereum Secret Storage definition" do
      encrypted = Eth::Key.encrypt key, password
      decrypted = Eth::Key.decrypt encrypted, password

      expect(key.address).to eq(decrypted.address)
      expect(key.public_hex).to eq(decrypted.public_hex)
      expect(key.private_hex).to eq(decrypted.private_hex)
    end
  end
end
