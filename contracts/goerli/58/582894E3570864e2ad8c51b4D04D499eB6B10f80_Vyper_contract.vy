# @version 0.3.7

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

# Events
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256

event MinterUpdated:
    minter: indexed(address)
    canMint: bool

# ERC20 Token Metadata
name: public(String[20])
symbol: public(String[5])
decimals: public(uint8)

# ERC20 State Variables
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

# governance 
isMinter: public(HashMap[address, bool])
governance: public(address)
pendingGovernance: public(address)

# EIP-712
nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')


@external
def __init__( _name: String[20], _symbol: String[5], _decimals: uint8, _governance: address):
    self.governance = _governance
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals


    # EIP-712
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(_name),
            keccak256("1.0"),
            _abi_encode(chain.id, self)
        )
    )

############
# Transfer #
############


@external
def transfer(_recipient: address, _amount: uint256) -> bool:
    self.balanceOf[msg.sender] -= _amount
    self.balanceOf[_recipient] += _amount
    log Transfer(msg.sender, _recipient, _amount)
    return True


@external
def transferFrom(_sender: address, _recipient: address, _amount: uint256) -> bool:
    self.allowance[_sender][msg.sender] -= _amount
    self.balanceOf[_sender] -= _amount
    self.balanceOf[_recipient] += _amount
    log Transfer(_sender, _recipient, _amount)
    return True


###############
# Mint + Burn #
###############


@external
def mint(_recipient: address, _amount: uint256) -> bool:
    assert msg.sender == self.governance or self.isMinter[msg.sender] , "# dev: access denied <CustomERC20.mint>"
    assert _recipient != empty(address)
    self.totalSupply += _amount
    self.balanceOf[_recipient] += _amount
    log Transfer(empty(address), _recipient, _amount)
    return True


@external
def burn(_amount: uint256) -> bool:
    self.balanceOf[msg.sender] -= _amount
    self.totalSupply -= _amount
    log Transfer(msg.sender, empty(address), _amount)
    return True


#############
# Allowance #
#############


@external
def approve(_spender: address, _amount: uint256) -> bool:
    self.allowance[msg.sender][_spender] = _amount
    log Approval(msg.sender, _spender, _amount)
    return True


@external
def permit(_owner: address, _spender: address, _amount: uint256, _expiry: uint256, _signature: Bytes[65]) -> bool:
    # See https://eips.ethereum.org/EIPS/eip-2612
    assert _owner != empty(address), "# dev: invalid owner"
    assert _expiry == 0 or _expiry >= block.timestamp, "# dev: permit expired"
    nonce: uint256 = self.nonces[_owner]
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(
                _abi_encode(
                    PERMIT_TYPE_HASH,
                    _owner,
                    _spender,
                    _amount,
                    nonce,
                    _expiry,
                )
            )
        )
    )
    # NOTE: signature is packed as r, s, v
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == _owner, "# dev: invalid signature"
    self.allowance[_owner][_spender] = _amount
    self.nonces[_owner] = nonce + 1
    log Approval(_owner, _spender, _amount)
    return True


##############
# Governance #
##############


@external
def setMinter(_minter: address, _canMint: bool) -> bool:
    assert msg.sender == self.governance, "# dev: access denied <CustomERC20.setMinter>"
    assert _minter != empty(address) , "# dev: cannot add 0x0 as minter"
    self.isMinter[_minter] = _canMint
    log MinterUpdated(_minter, _canMint)
    return True


@external
def updateGovernance(_pendingGovernance: address):
    assert msg.sender == self.governance, "# dev: access denied <CustomERC20.updateGovernance>"
    assert _pendingGovernance != empty(address), "# dev: cannot be 0x0"
    self.pendingGovernance = _pendingGovernance


@external
def acceptGovernance():
    newGovernance: address = msg.sender 
    assert newGovernance == self.pendingGovernance, "# dev: only pendingGovernance can accept"
    self.governance = newGovernance
    self.pendingGovernance = empty(address)