# @version >=0.3

from vyper.interfaces import ERC20


interface CreateMiniProxy:
    def createMiniProxyContract(target: address) -> address: nonpayable

@external
def createMiniProxyContractTo(target: address) -> address:

    x: uint256 = 123
    response: Bytes[32] = raw_call(
        target,
        _abi_encode(x, method_id=method_id("createMiniProxyContract(address)")),
        max_outsize=32,
        is_delegate_call=True
    )
    a: address = extract32(response, 0, output_type=address)
    return a

@external
def createMiniProxyContractTo2(target: address) -> address:

    x: uint256 = 123
    response: Bytes[32] = raw_call(
        target,
        _abi_encode(x, method_id=method_id("createMiniProxyContract(address)")),
        max_outsize=32,
    )
    a: address = extract32(response, 0, output_type=address)
    return a