# @version ^0.3.0

@internal
@view
def add_prefix(_hashedMessage: bytes32) -> bytes32:

    # Arguments:
    # _hashedMessage is the hashed message signed by the user

    # The required prefix for ethereum signed messages.
    # The `32` is the number of bytes in the hashed message.
    prefix: Bytes[28] = b'\x19Ethereum Signed Message:\n32'

    # Concatenate them together since the prefix is required.
    return keccak256(concat(prefix, _hashedMessage))


@internal
@view
def verify_message(_prefixedHashedMessage: bytes32,
                   _signature: Bytes[65]) -> address:

    # Arguments:
    # _prefixedHashedMessage: the hashed message signed by the user, which includes the prefix
    # _signature: the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    # return ecrecover(prefixedHashedMessage, v, r, s) == msg.sender
    return ecrecover(_prefixedHashedMessage, v, r, s)


@external
@view
def verify_js_message(_hashedMessage: bytes32,
                      _signature: Bytes[65]) -> address:

    # Arguments:
    # _hashedMessage: the hashed message signed by the user
    # _signature: the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # Concatenate them together since the prefix is required.
    prefixedHashedMessage: bytes32 = self.add_prefix(_hashedMessage)

    return self.verify_message(prefixedHashedMessage, _signature)


@external
@view
def verify_py_message(_prefixedHashedMessage: bytes32,
                      _signature: Bytes[65]) -> address:

    # Arguments:
    # _prefixedHashedMessage: the hashed message signed by the user, which includes the prefix
    # _signature: the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    return self.verify_message(_prefixedHashedMessage, _signature)


# =================================


# Reference:
# https://github.com/weijiekoh/eip712-signing-demo/blob/master/solidityCode.js

###################################
# Values from contract deployment #
###################################

# The version of the calling script script must match the contract version
scriptVersion: public(uint256)

# The initialization script. The arguments are set during contract deployment
@external
def __init__(_scriptVersion: uint256):
    self.scriptVersion = _scriptVersion

# VALIDATOR_TYPE: constant(Bytes[60]) = b'Validator(address validatorKey,Bytes[65] validatorSignature)'
# VALIDATOR_TYPEHASH: constant(bytes32) = keccak256(_abi_encode(VALIDATOR_TYPE))

struct Validator:
    key: address
    signature: Bytes[65]


#     string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
#     string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
#     string private constant BID_TYPE = "Bid(uint256 amount,Identity bidder)Identity(uint256 userId,address wallet)";
    
#     bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
#     bytes32 private constant IDENTITY_TYPEHASH = keccak256(abi.encodePacked(IDENTITY_TYPE));
#     bytes32 private constant BID_TYPEHASH = keccak256(abi.encodePacked(BID_TYPE));
#     bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
#         EIP712_DOMAIN_TYPEHASH,
#         keccak256("My amazing dApp"),
#         keccak256("2"),
#         chainId,
#         verifyingContract,
#         salt
#     ));





# @internal
# @pure
# def eip_712_domain_hash() -> bytes32:
#     # Remember, no spaces after commas!
#     return keccak256(_abi_encode(keccak256(EIP712_DOMAIN),
#                                  keccak256(b'1'),
#                                  keccak256(b'5'),
#                                  self))


    # function hashBid(Bid memory bid) private pure returns (bytes32){
    #     return keccak256(abi.encodePacked(
    #         "\\x19\\x01",
    #         DOMAIN_SEPARATOR,
    #         keccak256(abi.encode(
    #             BID_TYPEHASH,
    #             bid.amount,
    #             hashIdentity(bid.bidder)
    #         ))
    #     ));
    # }


@internal
@view
def hash_validator(validator: Validator) -> bytes32:
    # Remember, no spaces after commas!
    eip712DomainType: Bytes[83] = b'EIP712Domain(string name,uint256 version,uint256 chainId,address verifyingContract)'
    eip712DomainTypehash: bytes32 = keccak256(_abi_encode(eip712DomainType))
    domainSeparator: bytes32 = keccak256(_abi_encode(
        eip712DomainTypehash,
        keccak256(b'VeriHash'),
        self.scriptVersion,
        chain.id,
        self,
    ))
    # VALIDATOR_TYPE: constant(Bytes[60]) = b'Validator(address key,Bytes[65] signature)'
    # VALIDATOR_TYPEHASH: constant(bytes32) = keccak256(_abi_encode(VALIDATOR_TYPE))
    validatorType: Bytes[60] = b'Validator(address key,Bytes[65] signature)'
    validatorTypeHash: bytes32 = keccak256(_abi_encode(validatorType))
    #     return keccak256(abi.encodePacked(
    #         "\\x19\\x01",
    #         DOMAIN_SEPARATOR,
    #         keccak256(abi.encode(
    #             BID_TYPEHASH,
    #             bid.amount,
    #             hashIdentity(bid.bidder)
    #         ))
    #     ));
    validatorValues: bytes32 = keccak256(_abi_encode(
        validatorTypeHash,
        validator.key,
        keccak256(validator.signature),
    ))
    return keccak256(_abi_encode(
        b'\x19\x01',
        domainSeparator,
        validatorValues,
    ))
    # return keccak256(_abi_encode(keccak256(VALIDATOR_TYPE),
    #                              validatorKey,
    #                              validatorSignature))


@external
@view
def verify(_signature: Bytes[65],
           _validatorKey: address,
           _validatorSignature: Bytes[65],) -> address:

    # hash: bytes32 = keccak256(_abi_encode(b'\x19\x01'))

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    # return ecrecover(prefixedHashedMessage, v, r, s) == msg.sender
    # exampleStruct: MyStruct = MyStruct({value1: 1, value2: 2.0})
    validator: Validator = Validator({
        key: _validatorKey,
        signature: _validatorSignature,
    })
    return ecrecover(self.hash_validator(validator), v, r, s)



            # bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        #  return ecrecover(hash, v, r, s) == _user;
        # }