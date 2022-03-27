/**
    1. SupraBridge will interact with Anchor contract.
    2. This contract knows current implementation contract through ProxyAdmin contract.
    3. ISupra :::: current implementation contract.
    4. IProxy :::: ProxyAdmin contract.

    Note :: Curently implementation contract(Supra, SupraV2) function => storeFeed is 
            callable by any address because in future only afer signature verification 
            the data can be updated in the smart contract.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupra {
    function storeFeed(string memory _feeds, bool flag, uint targetDB) external returns (string memory);
}

interface IProxy {
    function getProxyImplementation(address _proxy) external view returns (address);
}

contract Anchor {

    ISupra internal supraInstance;
  
    constructor() {
        supraInstance = ISupra(0x121E4136cC3e83de6b591040fEBD3fC5Bd818247);     // Oracle Contract
    }

   // ProxyAdmin takes Proxy address to give current implementation contract
   function getCurrentImplementation(address _proxy) public view returns (address){
        return IProxy(0xCe51A93F11Bf87629E637a9aB6a209E090d99103).getProxyImplementation(_proxy);
   }

   // targets function of current implementation contract
   function storeOracleData(address _proxy, string memory _feeds, bool flag, uint targetDB) public returns(string memory){
       return ISupra(getCurrentImplementation(_proxy)).storeFeed(_feeds, flag, targetDB); 
   }
    

}