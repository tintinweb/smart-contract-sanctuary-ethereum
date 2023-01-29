# @version ^0.3.7

_COLLISION_OFFSET: constant(bytes1) = 0xFF

# @dev A Vyper contract cannot call directly between two `external` functions.
# To bypass this, we can use an interface.
interface ComputeCreate2Address:
    def compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address: pure

aa: public(address)

@external
@payable
def __init__():
    pass

@external
@view
def compute_address_self(salt: bytes32, bytecode_hash: bytes32) -> address:
    return ComputeCreate2Address(self).compute_address(salt, bytecode_hash, self)


@external
@view
def compute_address_self1(salt: bytes32, bytecode_hash: bytes32, sender: address) -> address:
    return ComputeCreate2Address(self).compute_address(salt, bytecode_hash, sender)


@external
@pure
def compute_address(salt: bytes32, bytecode_hash: bytes32, deployer: address) -> address:
    
    data: bytes32 = keccak256(concat(_COLLISION_OFFSET, convert(deployer, bytes20), salt, bytecode_hash))
    return self._convert_keccak256_2_address(data)


@internal
@pure
def _convert_keccak256_2_address(digest: bytes32) -> address:
    return convert(convert(digest, uint256) & max_value(uint160), address)


@external
def foo(_salt: bytes32, addr: address) -> bool:

    self.aa = create_minimal_proxy_to(addr, salt=_salt)
    return True