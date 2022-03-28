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
    address public transparentProxy;
  
    constructor() {
        supraInstance = ISupra(0xCfE5B0cDBEe77653c0045795DaB291691c0D84A8);     // Oracle Contract
        transparentProxy = 0xd23d0a69CF2c590129352ffD9753CeE26a248d85 ;          // Transaprent proxy
    }

 
   function getCurrentImplementation(address _transparentUpgradableproxy) public view returns (address){               
        return IProxy(0x7aBdA83855897D4Beec6dFEAC74a043E3bCdE5bC).getProxyImplementation(_transparentUpgradableproxy); // Proxy Admin
   }

   // targets function of current implementation contract
   function storeOracleData(string memory _feeds, bool flag, uint targetDB) public returns(string memory){
       return ISupra(getCurrentImplementation(transparentProxy)).storeFeed(_feeds, flag, targetDB); 
   }
    

}