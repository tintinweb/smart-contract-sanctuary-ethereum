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
        supraInstance = ISupra(0xD7b8101b5dB7f3A83762Cdc15F39ac9339b1Cf1b);     // Oracle Contract
    }

 
   function getCurrentImplementation(address _transparentUpgradableproxy) public view returns (address){               
        return IProxy(0xe43BE78b13c815a4DD8151977aa9831E444c9220).getProxyImplementation(_transparentUpgradableproxy); // Proxy Admin
   }

   // targets function of current implementation contract
   function storeOracleData(address _proxy, string memory _feeds, bool flag, uint targetDB) public returns(string memory){
       return ISupra(getCurrentImplementation(_proxy)).storeFeed(_feeds, flag, targetDB); 
   }
    

}