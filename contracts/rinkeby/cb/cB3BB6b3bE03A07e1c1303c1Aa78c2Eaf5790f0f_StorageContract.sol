/*  
    ------------------------------------DEVELOPER INSTRUCTONS-----------------------------------------------
    ----------------------------------------------------------------------------------------------
    1. Need to Separate Storage contrcat.
    2. This contract will be deployed separately and its address need to be set in implementation contract.
    3. Need to define structs and mapping for all services in advance.
    4. Getter functions will be allowed as per whitelisting.
    5. Setter functions can only be done from current implementation contract.
    6. Not allowed to set values directly via StorageContract methods.  


    TODO : Access Control(Whitelisting for getter functions, disable direct access to setter functions)
    -----------------------------------------------------------------------------------------------
*/ 

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageContract{

    struct priceFeedData {
        string currentPrice;
        string weeklyPrice;
        uint256 currentPriceTimeStamp; 
        uint256 weeklyPriceTimeStamp; 
    }

    struct weatherData {
        string humidity;
        string wind_speed;
        string temperature;
        uint256 timestamp; 

    }

    mapping(string => priceFeedData) internal priceDB; 
    mapping(string => weatherData) internal weatherDB; 


    function getCurrentPrice(string memory currencyPair) public view returns(string memory, uint256){
      return (priceDB[currencyPair].currentPrice, priceDB[currencyPair].currentPriceTimeStamp);
    }

    function getWeeklyPrice(string memory currencyPair) public view returns(string memory, uint256){
      return (priceDB[currencyPair].weeklyPrice, priceDB[currencyPair].weeklyPriceTimeStamp);
    }


    function getWeatherInfo(string memory city) public view returns(string memory, string memory, string memory, uint256){
      return (weatherDB[city].humidity, weatherDB[city].wind_speed, weatherDB[city].temperature, weatherDB[city].timestamp);
    }

    function setCurrentPrice(string memory currencyPair, string memory price) public virtual{
        priceDB[currencyPair].currentPrice = price;
        priceDB[currencyPair].currentPriceTimeStamp = block.timestamp;
    }

    function setWeeklyPrice(string memory currencyPair, string memory price) public virtual{
        priceDB[currencyPair].weeklyPrice = price;
        priceDB[currencyPair].weeklyPriceTimeStamp = block.timestamp;
    }

    function setWeatherInfo(string memory city, string memory val_1, string memory val_2, string memory val_3) public virtual {
        weatherDB[city].humidity = val_1;
        weatherDB[city].wind_speed = val_2;
        weatherDB[city].temperature = val_3;
        weatherDB[city].timestamp = block.timestamp;
    }

}