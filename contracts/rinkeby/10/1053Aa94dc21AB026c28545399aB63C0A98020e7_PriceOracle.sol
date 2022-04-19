/**

   Anchor Contract ====> Get Implementation




*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAnchor {
    function getProxyImplementation(address _proxy) external view returns (address);
}

contract PriceOracle{
    IAnchor anchorInstance;
    address public transparentProxy;  // REMOVE PUBLIC
    
    struct priceFeedData {
        string currentPrice;
        string weeklyPrice;
        uint256 currentPriceTimeStamp; 
        uint256 weeklyPriceTimeStamp; 
    }

    mapping(string => priceFeedData) internal priceDB; 
    
    function setAddress(address _transparentProxy, address _anchor) public {
       transparentProxy = _transparentProxy;
       anchorInstance = IAnchor(_anchor); 
    }

    function getProxyImplementation(address _proxy) public view returns (address){               
        return anchorInstance.getProxyImplementation(_proxy); 
    }
    
    // ###################################################################################
    function setCurrentPrice(string memory currencyPair, string memory price) external virtual{   
        require( msg.sender == getProxyImplementation(transparentProxy), "You are not implementation contract");
        priceDB[currencyPair].currentPrice = price;
        priceDB[currencyPair].currentPriceTimeStamp = block.timestamp;
    }
    
    // ###################################################################################
    function setWeeklyPrice(string memory currencyPair, string memory price) external virtual{
       require( msg.sender == getProxyImplementation(transparentProxy), "You are not implementation contract");
        priceDB[currencyPair].weeklyPrice = price;
        priceDB[currencyPair].weeklyPriceTimeStamp = block.timestamp;
    }

     // DIRECT ACCESS FROM V1 CONTRACT
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function getCurrentPrice(string memory currencyPair) public view returns(string memory, uint256){
       require( msg.sender == getProxyImplementation(transparentProxy), "Only current implementation contract can access current price");
       return (priceDB[currencyPair].currentPrice, priceDB[currencyPair].currentPriceTimeStamp);
    }
    
    // DIRECT ACCESS FROM V1 CONTRACT
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function getWeeklyPrice(string memory currencyPair) public view returns(string memory, uint256){
      require( msg.sender == getProxyImplementation(transparentProxy), "Only current implementation contract can access weekly price");
      return (priceDB[currencyPair].weeklyPrice, priceDB[currencyPair].weeklyPriceTimeStamp);
    }

}