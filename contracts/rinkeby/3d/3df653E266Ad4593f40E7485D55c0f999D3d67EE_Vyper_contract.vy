# @version 0.3.3
from vyper.interfaces import ERC20

implements: ERC20

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

EIP712_TYPEHASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
PERMIT_TYPEHASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")

VERSION: constant(String[8]) = "v1.0.0"


NAME: immutable(String[32])
SYMBOL: immutable(String[32])
DECIMALS: immutable(uint8)
TOTAL_SUPPLY: immutable(uint256)
DOMAIN_SEPARATOR: immutable(bytes32)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

nonces: public(HashMap[address, uint256])


@external
def __init__(_name: String[32], _symbol: String[32], _decimals: uint8, _supply: uint256):
    NAME = _name
    SYMBOL = _symbol
    DECIMALS = _decimals
    TOTAL_SUPPLY = _supply
    self.balanceOf[msg.sender] = _supply

    DOMAIN_SEPARATOR = keccak256(
        _abi_encode(EIP712_TYPEHASH, keccak256(NAME), keccak256(VERSION), chain.id, self)
    )

    log Transfer(ZERO_ADDRESS, msg.sender, 0)

@internal
def _transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    self.allowance[sender][msg.sender] -= amount

    self.balanceOf[sender] -= amount

    # Cannot overflow because the sum of all user
    # balances can't exceed MAX_UINT256
    self.balanceOf[receiver] = unsafe_add(amount, self.balanceOf[receiver])

    log Transfer(sender, receiver, amount)

    return True


@external
def transfer(receiver: address, amount: uint256) -> bool:
    return self._transferFrom(msg.sender, receiver, amount)


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    return self._transferFrom(sender, receiver, amount)


@external
def approve(_spender: address, _value: uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value

    log Approval(msg.sender, _spender, _value)
    return True


@external
def permit(
    _owner: address,
    _spender: address,
    _value: uint256,
    _deadline: uint256,
    _v: uint8,
    _r: bytes32,
    _s: bytes32
) -> bool:
    assert _owner != ZERO_ADDRESS
    assert block.timestamp <= _deadline

    nonce: uint256 = self.nonces[_owner]
    digest: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(_abi_encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonce, _deadline))
        )
    )

    assert ecrecover(digest, convert(_v, uint256), convert(_r, uint256), convert(_s, uint256)) == _owner

    self.allowance[_owner][_spender] = _value
    self.nonces[_owner] = nonce + 1

    log Approval(_owner, _spender, _value)
    return True

@view
@external
def name() -> String[32]:
    return NAME


@view
@external
def symbol() -> String[32]:
    return SYMBOL


@view
@external
def decimals() -> uint8:
    return DECIMALS

@view
@external
def totalSupply() -> uint256:
    return TOTAL_SUPPLY


@view
@external
def version() -> String[8]:
    return VERSION