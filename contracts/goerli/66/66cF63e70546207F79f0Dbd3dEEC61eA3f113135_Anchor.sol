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
        supraInstance = ISupra(0x51BB686176427019F4445320dA568B00867B8B58);     // Oracle Contract
    }

   function getCurrentImplementation(address _transparentUpgradableproxy) public view returns (address){               
        return IProxy(0x2fDeF7b501250C2187c9f86c5fC633eD372b81F9).getProxyImplementation(_transparentUpgradableproxy); // Proxy Admin
   }

   // targets function of current implementation contract
   function storeOracleData(string memory _feeds, bool flag, uint targetDB) public returns(string memory){
       return ISupra(0x18520EDA1D2F38A2DCA148a6A9e743c33f11aC8b).storeFeed(_feeds, flag, targetDB); // Supra V1
   }
    

}