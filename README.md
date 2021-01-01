# Eth [![Travis-CI](https://travis-ci.org/se3000/ruby-eth.svg?branch=master)](https://travis-ci.org/se3000/ruby-eth) [![Code Climate](https://codeclimate.com/github/se3000/ruby-eth/badges/gpa.svg)](https://codeclimate.com/github/se3000/ruby-eth) [![Gitter](https://badges.gitter.im/ruby-eth/Lobby.svg)](https://gitter.im/ruby-eth/Lobby)

A simple library to build and sign Ethereum transactions. Allows separation of key and node management. Sign transactions and handle keys anywhere you can run ruby, broadcast transactions through any node.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install eth

## Usage

First of all, require this gem:

```ruby
require 'eth'
```

### Keys

Create a new public/private key and get its address:

```ruby
key = Eth::Key.new
key.private_hex
key.public_hex
key.address # EIP55 checksummed address
```

Import an existing key:

```ruby
old_key = Eth::Key.new priv: private_key
```

Or decrypt an [encrypted key](https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition):

```ruby
decrypted_key = Eth::Key.decrypt File.read('./some/path.json'), 'p455w0rD'
```

You can also encrypt your keys for use with other ethereum libraries:

```ruby
encrypted_key_info = Eth::Key.encrypt key, 'p455w0rD'
```

### How to make a trasaction?

Let's take an example of sending ETH to another address:

Step1. Build a transaction from scratch:

```ruby
tx = Eth::Tx.new({

  # 0x00 or something else
  data: "0x00",

  # 21000 for sending eth, and 50_000 or more for sending erc-20 tokens.
  gas_limit: 21_000,

  # assume current fast price is 50 gwei
  gas_price: (50 * 1e9).to_i,

  # you must get the correct nonce for the "from address", otherwise
  # the signed-tx will NOT be broadcasted
  # you can query the nonce from interface such as infura's `eth_getTransactionCount`
  nonce: 0,

  # this is where the crypto will be sent to
  to: "0x3Ae7a18407B17037B2ECC4901c1b77Db9836888",

  # let us send 0.12 ETH
  value: (BigDecimal("0.12") * 1e18).to_i
})
```

Or decode an encoded raw transaction:

```ruby
tx = Eth::Tx.decode hex
```

Step2. Then sign the transaction with your private key:

```ruby

# step 2.1 get the private key of the "from address"
from_address_json_file = './from_address_json'
from_address_password = 'p455w0rD'
the_private_key = Eth::Key.decrypt File.read(from_address_json_file), from_address_password

# step 2.2 sign the tx with private key

tx.sign the_private_key
```

Step3. Get the raw transaction( signed transaction) with:

```ruby

# will return a hex value with length 200+, depends on `data` parameter
tx.hex

# e.g.  =>  0xf86c82039585174876e800825208943ae7a18407b17037b2ecc4901c1b77db98367cda866d23ad5f80008026a085b81f23b7e80c65f6e8d97f2c6482c0cc7d660fc538f566c47c22e57c841726a07351fe455188b160c726d3032d03ddcdf1929716bb1c5aa06274fdf2830b73ba
```

Step4. broadcast it through any Ethereum node, or third-party services ( like infura )

```json
curl https://mainnet.infura.io/v3/<YOUR-PROJECT-ID>
  -X POST
  -H "Content-Type: application/json"
  -d '{
        "jsonrpc":"2.0",
        "method":"eth_sendRawTransaction",
        "params":[
          "0xf86c82039585174876e800825208943ae7a18407b17037b2ecc4901c1b77db98367cda866d23ad5f80008026a085b81f23b7e80c65f6e8d97f2c6482c0cc7d660fc538f566c47c22e57c841726a07351fe455188b160c726d3032d03ddcdf1929716bb1c5aa06274fdf2830b73ba"
        ],
        "id":1
      }'
```

you will get result like:

```json
{
  "jsonrpc":"2.0",
  "id":1,
  "result":"0x371c92a5815a734c6cd4c6e890e4b9216aa9eeee482b6a8279bea1bdeebc0d2d"
}
```

Or, just get the TXID with `tx.hash`.

### Utils

Validate an [EIP55](https://github.com/ethereum/EIPs/issues/55) checksummed address:

```ruby
Eth::Utils.valid_address? address
```

Or add a checksum to an existing address:

```ruby
Eth::Utils.format_address "0x4bc787699093f11316e819b5692be04a712c4e69" # => "0x4bc787699093f11316e819B5692be04A712C4E69"
```

### Personal Signatures

You can recover public keys and generate web3/metamask-compatible signatures:

```ruby
# Generate signature
key.personal_sign('hello world')

# Recover signature
message = 'test'
signature = '0x3eb24bd327df8c2b614c3f652ec86efe13aa721daf203820241c44861a26d37f2bffc6e03e68fc4c3d8d967054c9cb230ed34339b12ef89d512b42ae5bf8c2ae1c'
Eth::Key.personal_recover(message, signature) # => 043e5b33f0080491e21f9f5f7566de59a08faabf53edbc3c32aaacc438552b25fdde531f8d1053ced090e9879cbf2b0d1c054e4b25941dab9254d2070f39418afc
```

### Configure

In order to prevent replay attacks, you must specify which Ethereum chain your transactions are created for. See [EIP 155](https://github.com/ethereum/EIPs/issues/155) for more detail.

```ruby
Eth.configure do |config|
  config.chain_id = 1 # nil by default, meaning valid on any chain
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/se3000/ethereum-tx. Tests are encouraged.

### Tests

First install the [Ethereum common tests](https://github.com/ethereum/tests):

```shell
git submodule update --init
```

Then run the associated tests:

```shell
rspec
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## TODO

* Better test suite.
* Expose API for HD keys.
* Support signing with [libsecp256k1](https://github.com/bitcoin-core/secp256k1).
