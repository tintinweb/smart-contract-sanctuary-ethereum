# @version >=0.3

from vyper.interfaces import ERC20


interface CreateMiniProxy:
    def createMiniProxyContract(target: address) -> address: nonpayable

@external
def createMiniProxyContractTo(target: address) -> address:
    return CreateMiniProxy(target).createMiniProxyContract(target)