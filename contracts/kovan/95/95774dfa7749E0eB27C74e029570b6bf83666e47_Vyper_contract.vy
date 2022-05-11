# @version ^0.3.1


event PoolDeployed:
    deployer : indexed(address)  # msg.sender
    pool_address : indexed(address)  # The forwarder for the pool template
    _chaininterface : indexed(address)  # Which cross chain messaging service is used? TODO CHECK SECURITY
    _k : uint256  # amplification
    _assets : address[NUMASSETS]  # List of the 3 assets


NUMASSETS: constant(uint256) = 3
pooltemplate: public(address)
pooltokentemplate: public(address)
IsCreatedByFactory: public(HashMap[address, bool])


interface ISwapPool:
    def setup(_chaininterface : address, init_assets : address[NUMASSETS], k : uint256, ptt : address, name : String[16], symbol: String[8], _setupMaster : address): nonpayable


@external
def __init__( _pooltemplate : address, _pooltokentemplate : address):
    self.pooltemplate = _pooltemplate
    self.pooltokentemplate = _pooltokentemplate


@external
def deploy_swappool(_chaininterface : address, init_assets : address[NUMASSETS], k : uint256, name: String[16], symbol: String[8]) -> address:
    result: address = create_forwarder_to(self.pooltemplate)
    self.IsCreatedByFactory[result] = True
    
    ISwapPool(result).setup(_chaininterface, init_assets, k, self.pooltokentemplate, name, symbol, msg.sender)
    
    log PoolDeployed(msg.sender, result, _chaininterface, k, init_assets)
    return result