/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function getProxyImplementation(address _proxy) external view returns (address);
}

contract PriceOracle{
      IProxy proxyInstance;

    address public proxyAdmin;     // remove public
    address public transparentProxy;
    
    struct priceFeedData {
        string currentPrice;
        string weeklyPrice;
        uint256 currentPriceTimeStamp; 
        uint256 weeklyPriceTimeStamp; 
    }

   
    mapping(string => priceFeedData) internal priceDB; 
    
    // set anchor contract for access restriction

    // only current implementation contract can call getter nethods
    // Make ownable

    function setProxy(address _proxyAdmin, address _transparentProxy) public {
       proxyAdmin = _proxyAdmin;
       transparentProxy = _transparentProxy;
    }

    function getImplementation() public view returns (address){               
        return IProxy(proxyAdmin).getProxyImplementation(transparentProxy); // Proxy Admin
    }

    function setCurrentPrice(string memory currencyPair, string memory price) external virtual{   
        require( msg.sender == getImplementation(), "You are not implementation contract");
        priceDB[currencyPair].currentPrice = price;
        priceDB[currencyPair].currentPriceTimeStamp = block.timestamp;
    }

    function setWeeklyPrice(string memory currencyPair, string memory price) external virtual{
        require( msg.sender == getImplementation(), "You are not implementation contract");
        priceDB[currencyPair].weeklyPrice = price;
        priceDB[currencyPair].weeklyPriceTimeStamp = block.timestamp;
    }

    function getCurrentPrice(string memory currencyPair) external view returns(string memory, uint256){
       require( msg.sender == getImplementation(), "Only current implementation contract can access current price");
       return (priceDB[currencyPair].currentPrice, priceDB[currencyPair].currentPriceTimeStamp);
    }

    function getWeeklyPrice(string memory currencyPair) external view returns(string memory, uint256){
      require( msg.sender == getImplementation(), "Only current implementation contract can access weekly price");
      return (priceDB[currencyPair].weeklyPrice, priceDB[currencyPair].weeklyPriceTimeStamp);
    }

}