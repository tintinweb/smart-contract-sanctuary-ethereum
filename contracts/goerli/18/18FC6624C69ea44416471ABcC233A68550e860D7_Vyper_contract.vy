# @version >=0.3

from vyper.interfaces import ERC20

@view
@external
def uintToBytes(input: uint256) -> bytes32:
    return convert(input, bytes32)


@external
def createMiniProxyContract(target: address) -> address:
    return create_minimal_proxy_to(target)