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
        proxyAddress = 0x9535fD6a259e1C8dF456FC428Ff8F00D15B3aC6A; // transparent
       
    }
    
    // ProxyAdmin [TransparentUpgradableProxy] ==> Implementation address 
    function getCurrentImplementation(address _proxy) public view returns (address){
        return IProxy(0xe43BE78b13c815a4DD8151977aa9831E444c9220).getProxyImplementation(_proxy);  //| ADMIN | TXPAdd
    }

    /*
        Following function is only available to : 
            1. whitelisted users
            2. Who has purchased access time
    **/

    function currentPrice(string memory currencyPair) public view returns(string memory, uint256){
       return IOracleContract(getCurrentImplementation(proxyAddress)).getCurrentPrice(currencyPair); 
    } 

}