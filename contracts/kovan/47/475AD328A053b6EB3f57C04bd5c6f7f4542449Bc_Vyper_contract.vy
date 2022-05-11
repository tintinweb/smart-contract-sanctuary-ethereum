# @version ^0.3.1
# license: MIT


event tokenDeployed:
    deployer: address
    tokenAddress: address
    name: String[64]
    symbol: String[16]
    initialSupply: uint256


interface pERC20:
    def transferOwnership(newAddress : address): nonpayable
    def transferMinter(newMinter : address): nonpayable
    def claimContract(name: String[64], symbol: String[16]): nonpayable
    def mint(_to : address, _amount : uint256): nonpayable

tokenTemplate: constant(address) = 0x14a749B5D7747db416bE0116778DFBDa8653aeED


@external
def deploy_erc20(name: String[64], symbol: String[16], initialSupply : uint256) -> address:
    result: address = create_forwarder_to(tokenTemplate)
    pERC20(result).claimContract(name, symbol)

    pERC20(result).mint(msg.sender, initialSupply)

    pERC20(result).transferMinter(msg.sender)
    pERC20(result).transferOwnership(msg.sender)
    
    log tokenDeployed(msg.sender, result, name, symbol, initialSupply)

    return result