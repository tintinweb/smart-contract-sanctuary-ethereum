// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceImplementation {
    function getCurrentPrice(string memory currencyPair) external view returns (string memory, uint256);
}

interface IProxy {
    function getProxyImplementation(address _transparentProxy) external view returns (address);     
}

contract User {

    address public proxyAdmin;     // remove public
    address public transparentProxy;

    IProxy internal iproxyVariable;
    address proxyAddress;
    

    function setProxy(address _proxyAdmin, address _transparentProxy) public {
       proxyAdmin = _proxyAdmin;
       transparentProxy = _transparentProxy;
    }

    function getProxyImplementation(address _proxy) public view returns (address){
        return IProxy(proxyAdmin).getProxyImplementation(_proxy);  // Proxy Admin 
    }

    /*
        Following function is only available to : 
            1. whitelisted users
            2. Who has purchased access time
    **/
     
    //####| Group Users |#####| Time Buyer |#####| ===========> | V1 Contract |
    function currentPrice(string memory currencyPair) public view returns(string memory, uint256){
       return IPriceImplementation(getProxyImplementation(transparentProxy)).getCurrentPrice(currencyPair); 
    } 

}