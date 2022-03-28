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
        proxyAddress = 0xE7A323aEcc9437fBEe333Abf08f5a594b42DC666; // transparent
       
    }
    
    // ProxyAdmin [TransparentUpgradableProxy] ==> Implementation address 
    function getCurrentImplementation(address _proxy) public view returns (address){
        return IProxy(0xe9e2729567052C8397794b0E9A10b33265718cd6).getProxyImplementation(_proxy);  //| ADMIN | TXPAdd
    }

    /*
        Following function is only available to : 
            1. whitelisted users
            2. Who has purchased access time
    **/

    // function currentPrice(address _proxyAddress, string memory currencyPair) public view returns(string memory, uint256){
    //    return IOracleContract(getCurrentImplementation(_proxyAddress)).getCurrentPrice(currencyPair); 
    // }
    
    
    // +  ++++++++++++++++
    function currentPrice(string memory currencyPair) public view returns(string memory, uint256){
       return IOracleContract(0x4A64C7dF601447137bfE113806aD80Da702ed0eb).getCurrentPrice(currencyPair); 
    } 

}