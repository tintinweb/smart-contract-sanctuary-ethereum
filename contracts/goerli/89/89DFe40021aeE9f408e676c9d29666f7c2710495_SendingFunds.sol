// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract SendingFunds{
    using PriceConverter for uint256;
    uint256  MINIMUM_TRANSFER = 5*1e18;
    AggregatorV3Interface public s_priceFeed;
   
    constructor(address priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function GetETHToUSDPrice(uint256 x) public view returns(uint256){
        return x.ETHToUSDConversion(s_priceFeed);
    }

    function GetUSDToETHPrice(uint256 y) public  view returns(uint256){
        return y.USDToETHConversion(s_priceFeed);
    }
    
    function Sending(address payable receiverAddress)public payable {
        require(msg.value >= MINIMUM_TRANSFER, "Minimum transaction of 5 USD");
        (bool successful, ) = receiverAddress.call{value: msg.value}("");
        require(successful, "sending fail");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter {

    function GetEthLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function ETHToUSDConversion(uint256 _ETHammount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        // _ETHammount in wei conversion i.e 1000000000000000000 = 1eth
        uint256 USDPrice = GetEthLatestPrice(priceFeed);
        return (_ETHammount * USDPrice)/1e18; 

        // the reason for this is to be able to calculate even the value of a wei
        // Note: all answers divided by 1e18 to remove the extra zeros
    }

    function USDToETHConversion(uint256 _USDAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){ 
        // _USDAmount in with 18 zeros too.
        uint256 USDPrice = GetEthLatestPrice(priceFeed);
        // return ((_ETHAmount * 1e18) /USDPrice) * 1e18;
        return ((_USDAmount * 1e36) /USDPrice);

        // answer will be in wei
        // Note: all answers divided by 1e18 to remove the extra zeros
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}