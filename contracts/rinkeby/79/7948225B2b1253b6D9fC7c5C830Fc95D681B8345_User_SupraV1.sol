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
        proxyAddress = 0xd15Ab7c0566a652C6d9A7e7055E4249bc5Ca8Be5;
       
    }
    
    // ProxyAdmin [TransparentUpgradableProxy] ==> Implementation address 
    function getCurrentImplementation(address _proxy) public view returns (address){
        return IProxy(0x6eb57122d6FE5F168Cebc2e53906127814D94ad9).getProxyImplementation(_proxy);
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