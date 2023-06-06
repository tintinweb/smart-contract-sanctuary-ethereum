# @version >=0.3


struct Person:
    name: String[32]
    wallet: address

struct Mail:
    from_info: Person
    to_info: Person



PERMIT_TYPEHASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
EIP712_TYPEHASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
VERSION: constant(String[8]) = "v1.0.0"

_CACHED_CHAIN_ID: immutable(uint256)
_CACHED_SELF: immutable(address)
DOMAIN_SEPARATOR: immutable(bytes32)
NAME: immutable(String[64])

owner: public(address)


@external
def __init__():

    self.owner = msg.sender

    name: String[64] = "Example"
    NAME = name
    
    _CACHED_CHAIN_ID = chain.id
    _CACHED_SELF = self
    DOMAIN_SEPARATOR = keccak256(
        _abi_encode(EIP712_TYPEHASH, keccak256(name), keccak256(VERSION), chain.id, self)
    )


@view
@external
def verify(_data: Mail, _signature: Bytes[65]) -> address:

    struct_hash: bytes32 = keccak256(
        _abi_encode(
            keccak256('Mail(Person from_info,Person to_info,string contents)'),
           _abi_encode( _data.from_info),
            _abi_encode(_data.to_info)
        )
    )

    digest: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            DOMAIN_SEPARATOR,
            struct_hash
        )
    )

    r: uint256 = extract32(_signature, 0, output_type=uint256)
    s: uint256 = extract32(_signature, 32, output_type=uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    return ecrecover(digest, v, r, s)


@view
@external
def verify1(_data: Mail, _signature: Bytes[65]) -> bytes32:

    struct_hash: bytes32 = keccak256(
        _abi_encode(
            keccak256('Mail(Person from_info,Person to_info,string contents)'),
            _abi_encode( _data.from_info),
            _abi_encode(_data.to_info)
        )
    )

    digest: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            DOMAIN_SEPARATOR,
            struct_hash
        )
    )


    return digest


@view
@external
def verify2(_data: Mail, v: uint256, r: bytes32, s: bytes32) -> address:

    struct_hash: bytes32 = keccak256(
        _abi_encode(
            keccak256('Mail(Person from_info,Person to_info,string contents)'),
            _abi_encode( _data.from_info),
            _abi_encode(_data.to_info)
        )
    )

    digest: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            DOMAIN_SEPARATOR,
            struct_hash
        )
    )

    return ecrecover(digest, v, r, s)