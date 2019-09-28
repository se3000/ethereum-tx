module Eth
  class Key
    autoload :Decrypter, 'eth/key/decrypter'
    autoload :Encrypter, 'eth/key/encrypter'

    attr_reader :private_key, :public_key

    def self.encrypt(key, password)
      key = new(priv: key) unless key.is_a?(Key)

      Encrypter.perform key.private_hex, password
    end

    def self.decrypt(data, password)
      priv = Decrypter.perform data, password
      new priv: priv
    end

    def self.recover_public_key(hash, signature, chain_id = nil)
      context = Secp256k1::Context.new
      v = signature.unpack('C').first
      recovery_id = Eth::Chains.to_recovery_id(v, chain_id)
      recoverable_signature = context.recoverable_signature_from_compact(
        signature[1..-1], recovery_id
      )
      public_key_bin = recoverable_signature.recover_public_key(hash).uncompressed
      Utils.bin_to_hex(public_key_bin)
    rescue Secp256k1::DeserializationError
      false
    end

    def self.personal_recover(message, signature, chain_id = nil)
      hash = PersonalMessage.new(message).hash
      bin_sig = Utils.hex_to_bin(signature).bytes.rotate(-1).pack('c*')
      recover_public_key(hash, bin_sig, chain_id: chain_id)
    end

    def initialize(priv: nil)
      @context = Secp256k1::Context.new
      key_pair =
        if priv.nil?
          @context.generate_key_pair
        else
          @context.key_pair_from_private_key(Utils.hex_to_bin(priv))
        end
      @private_key = key_pair.private_key
      @public_key = key_pair.public_key
    end

    def private_hex
      Utils.bin_to_hex(private_key.data)
    end

    def public_bytes
      public_key.data
    end

    def public_hex
      Utils.bin_to_hex(public_key.uncompressed)
    end

    def address
      Utils.public_key_to_address public_hex
    end
    alias_method :to_address, :address

    def sign(message)
      sign_hash message_hash(message)
    end

    # Sign a data hash returning signature.
    #
    # @param hash [String] Keccak256 hash as byte string.
    # @param chain_id [Integer] (Optional) ID of the chain message or
    #   transaction belongs to.
    # @return [String] Recoverable signature as byte string
    def sign_hash(hash, chain_id = nil)
      if chain_id.nil?
        sign_legacy(private_key, hash)
      else
        signature, recovery_id =
          @context.sign_recoverable(private_key, hash).compact
        result = signature.bytes
        result.unshift(Eth::Chains.to_v(recovery_id, chain_id))
        result.pack('c*')
      end
    end

    # Produces signature with legacy v values.
    #
    # @param private_key [Secp256k1::PrivateKey] signing key.
    # @param hash [String] hash to be signed.
    # @return [String] binary signature data.
    def sign_legacy(private_key, hash)
      signature, recovery_id =
        @context.sign_recoverable(private_key, hash).compact
      result = signature.bytes
      result.unshift(Eth.v_base + recovery_id)
      result.pack('c*')
    end

    def verify_signature(message, signature, chain_id = nil)
      hash = message_hash(message)
      v = signature.unpack('C')[0]
      recovery_id = Eth::Chains.to_recovery_id(v, chain_id)
      recoverable_signature = @context.recoverable_signature_from_compact(
        signature[1..-1], recovery_id
      )
      public_key_bin =
        recoverable_signature.recover_public_key(hash).uncompressed
      public_hex == Utils.bin_to_hex(public_key_bin)
    end

    def personal_sign(message, chain_id = nil)
      signature =
        if chain_id
          PersonalMessage.new(message).sign(private_key, nil)
        else
          PersonalMessage.new(message).sign_legacy(private_key)
        end
      Secp256k1::Util.bin_to_hex(signature)
    end

    private

    def message_hash(message)
      Utils.keccak256 message
    end
  end
end
