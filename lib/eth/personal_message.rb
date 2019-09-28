module Eth
  # Represents a personal message that can be signed with a private key.
  class PersonalMessage
    # Default constructor.
    #
    # @param message [String] personal message to be signed or verified.
    def initialize(message)
      @message = message
    end

    def prefixed_message
      # Prepend the expected web3.eth.sign message prefix
      "\x19Ethereum Signed Message:\n#{@message.length}#{@message}"
    end

    # Signs a personal message with the given private key.
    #
    # @param private_key [Secp256k1::PrivateKey] key to use for signing.
    # @param chain_id [Integer] unique identifier for chain.
    # @return [String] binary signature data including recovery id v at end.
    def sign(private_key, chain_id)
      ctx = Secp256k1::Context.new
      signature, recovery_id = ctx.sign_recoverable(private_key, hash).compact
      result = signature.bytes
      result = result << Chains.to_v(recovery_id, chain_id)
      result.pack('c*')
    end

    # Produce a signature with legacy v values.
    #
    # @param private_key [Secp256k1::PrivateKey] key to use for signing.
    # @return [String] binary signature data including legacy recovery id v at
    #   end.
    def sign_legacy(private_key)
      ctx = Secp256k1::Context.new
      signature, recovery_id = ctx.sign_recoverable(private_key, hash).compact
      result = signature.bytes
      result = result << (27 + recovery_id)
      result.pack('c*')
    end

    # Returns the keccak256 hash of the message.
    #
    # Applies the expected prefix for personal messages signed with Ethereum
    # keys.
    #
    # @return [String] binary string hash of the given data.
    def hash
      Utils.keccak256(prefixed_message)
    end
  end
end
