/**
   User can access service
        
    1. Price 
            - Current Price

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleContract {
    function getCurrentPrice(string memory currencyPair) external view returns (string memory, uint256);
   
}

interface IProxy {
    function getProxyImplementation(address _proxy) external view returns (address);                      // TransparentUpgradableProxy
}

contract User_SupraV1 {

    IOracleContract internal oracleInstance;
    IProxy internal iproxyVariable;
    address proxyAddress;
    
    constructor() {
        proxyAddress = 0xd23d0a69CF2c590129352ffD9753CeE26a248d85; // transparent
       
    }
    
    // ProxyAdmin [TransparentUpgradableProxy] ==> Implementation address 
    function getCurrentImplementation(address _proxy) public view returns (address){
        return IProxy(0x7aBdA83855897D4Beec6dFEAC74a043E3bCdE5bC).getProxyImplementation(_proxy);  // Proxy Admin 
    }

    /*
        Following function is only available to : 
            1. whitelisted users
            2. Who has purchased access time
    **/

    function currentPrice(string memory currencyPair) public view returns(string memory, uint256){
       return IOracleContract(0xCfE5B0cDBEe77653c0045795DaB291691c0D84A8).getCurrentPrice(currencyPair); // Oracle Contract
    } 

}