module Eth
  # Represents an Ethereum signature where the public key of signer is
  # recoverable.
  class RecoverableSignature
    # Initialize recoverable signature.
    #
    # @param signature [String] Hex formatted signature
    # @param chain_id [Integer] (Optional) chain ID used for deriving recovery
    #   id.
    # @raise [ArgumentError] if signature is the wrong length.
    # @raise [RuntimeError] if v value derived from signature is invalid.
    def initialize(signature, chain_id = nil)
      # Move the last byte containing the v value to the front.
      rotated_signature = Utils.hex_to_bin(signature).bytes.rotate(-1)

      if rotated_signature.length != 65
        raise ArgumentError, 'invalid signature, must be 65 bytes in length'
      end

      @v = rotated_signature[0]

      if chain_id && @v < chain_id
        raise "invalid signature v '#{@v}' is not less than #{@chain_id}."
      end

      @signature = rotated_signature[1..-1].pack('c*')
      @chain_id = chain_id
    end

    # Recover public key for this recoverable signature.
    #
    # @param message [PersonalMessage] The message to verify the signature
    #   against.
    # @return [String] public key address corresponding to the public key
    #   recovered.
    def recover_public_key(message)
      ctx = Secp256k1::Context.new
      recovery_id = Chains.to_recovery_id(@v, @chain_id)

      recoverable_signature = ctx.recoverable_signature_from_compact(
        @signature, recovery_id
      )
      public_key_bin =
        recoverable_signature.recover_public_key(message.hash).uncompressed
      public_key_to_address(public_key_bin)
    end
  end
end
