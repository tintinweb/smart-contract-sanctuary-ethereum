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
        proxyAddress = 0x887E3Cb462BbdED7D3030A99A21626B36Bad2B65; // transparent
       
    }
    
    // ProxyAdmin [TransparentUpgradableProxy] ==> Implementation address 
    function getCurrentImplementation(address _proxy) public view returns (address){
        return IProxy(0x2fDeF7b501250C2187c9f86c5fC633eD372b81F9).getProxyImplementation(_proxy);  // Proxy Admin 
    }

    /*
        Following function is only available to : 
            1. whitelisted users
            2. Who has purchased access time
    **/

    function currentPrice(string memory currencyPair) public view returns(string memory, uint256){
       return IOracleContract(0x51BB686176427019F4445320dA568B00867B8B58).getCurrentPrice(currencyPair); // Oracle Contract
    } 

}