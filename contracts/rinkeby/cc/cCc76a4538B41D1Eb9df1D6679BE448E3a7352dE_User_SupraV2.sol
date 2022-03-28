/**
   User can now access both service(s)
        
    1. Price 
            - Current Price
            - Weekly Price
    2. Weather Data 

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleContract {
    function getCurrentPrice(string memory currencyPair) external view returns (string memory, uint256);
    function getWeeklyPrice(string memory currencyPair) external view returns(string memory, uint256);
    function getWeatherInfo(string memory _city) external view returns(string memory, uint256);
}

interface IProxy {
    function getProxyImplementation(address _proxy) external view returns (address);
}

contract User_SupraV2 {

    IOracleContract internal oracleInstance;
    IProxy internal iproxyVariable;
    address proxyAddress;
    
    constructor() {
        proxyAddress = 0x9535fD6a259e1C8dF456FC428Ff8F00D15B3aC6A;
       
    }

    function getCurrentImplementation(address _proxy) public view returns (address){
        return IProxy(0xe43BE78b13c815a4DD8151977aa9831E444c9220).getProxyImplementation(_proxy);  //Admin | Transparent
    }

    /*
    
        Following functions are only available to : 
            1. whitelisted users
            2. Who has purchased access time
    
    **/

    function currentPrice(string memory currencyPair) public view returns(string memory, uint256){
       return IOracleContract(getCurrentImplementation(proxyAddress)).getCurrentPrice(currencyPair); 
    }
    
    function weeklyPrice(string memory currencyPair) public view returns(string memory, uint256){
       return IOracleContract(getCurrentImplementation(proxyAddress)).getWeeklyPrice(currencyPair); 
    }
   
    function weatherInfo(string memory _city) public view returns(string memory, uint256){
       return IOracleContract(getCurrentImplementation(proxyAddress)).getWeatherInfo(_city); 
    }
    

}