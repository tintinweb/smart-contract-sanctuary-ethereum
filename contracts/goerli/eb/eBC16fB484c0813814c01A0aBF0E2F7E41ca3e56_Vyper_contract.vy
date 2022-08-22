# @version >=0.3

from vyper.interfaces import ERC20

@external
def createMiniProxyContract(target: address) -> address:
    return create_minimal_proxy_to(target)