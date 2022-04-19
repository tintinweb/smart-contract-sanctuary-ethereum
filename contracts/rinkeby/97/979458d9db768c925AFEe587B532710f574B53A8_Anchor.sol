/**

   V1 Contract ==> Call StoreFeed
   
   IPROXY      ==> Get Implementation
   
 

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceV1{
     function storeFeed(string memory _feeds, bool flag, uint targetDB) external returns (string memory);
}

interface IProxy {
    function getProxyImplementation(address _proxy) external view returns (address);
}

contract Anchor {
    IPriceV1 internal priceInstance;

    address public proxyAdmin;     // remove public
    address public transparentProxy;
  
    function setProxy(address _proxyAdmin, address _transparentProxy) public {
       proxyAdmin = _proxyAdmin;
       transparentProxy = _transparentProxy;
    }

    function getProxyImplementation(address _proxy) public view returns (address){               
        return IProxy(proxyAdmin).getProxyImplementation(_proxy); // Proxy Admin
    }

    // targets function of current implementation contract
    function storeFeed(string memory _feeds, bool flag, uint targetDB) public returns(string memory){
       return IPriceV1(getProxyImplementation(transparentProxy)).storeFeed(_feeds, flag, targetDB); 
    }
    

}