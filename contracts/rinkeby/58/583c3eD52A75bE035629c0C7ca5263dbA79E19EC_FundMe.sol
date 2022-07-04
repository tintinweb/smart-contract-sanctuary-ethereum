// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./PriceConverterLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error InvalidAmount(uint256);
error NotOwner(address);

contract FundMe {
    

    using PriceConverterLib for uint256;

    uint256 public constant  minimumUsd = 50; // 50usd
    address[]public funders;
    mapping(address => uint256) public addressToAmoundedFunded;
    address public immutable owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }

    function fundEth() public payable {
        require(msg.value.getConversionRate(priceFeed) >= 1e18, "amount less than 1 eth"); // 1e18 = 1* 10 ** 18 == 1000000000000000000 
    }

    function fund() public payable {
        
        // more gas efficient way to handle errors than revert()
        // less expensive to deploy
        if(msg.value >= minimumUsd) {
            revert InvalidAmount(msg.value);
        }
        //require(msg.value >= minimumUsd, "amount less than 1 eth"); // 1e18 = 1* 10 ** 18 == 1000000000000000000 
        funders.push(msg.sender);
        addressToAmoundedFunded[msg.sender] = msg.value;
    }

    function withdraw() external onlyOwner {
       for(uint8 i = 0; i < funders.length; i ++) {
           address funder = funders[i];
           addressToAmoundedFunded[funder] = 0;
       }

       // resets the array, to a brand new array with 0 items
       funders = new address[](0);

       // 3 ways to send ether
       // transfer - capped at 2300 gas, if more gas is used, automatically reverts - it throws an error
             payable(msg.sender).transfer(address(this).balance);
       // send - capped at 2300 gas , if more gas is used, it returns a bool 
             require(payable(msg.sender).send(address(this).balance), "Send failed");
       // call - forwards all gas, i.e no capped gas, returns boolean and bytes data
        // call is the recommended as of the time oif this writing
        (bool success, bytes memory returnedData) = payable(msg.sender).call{value: address(this).balance}("");
            require(success, "Call failed");
        }

        modifier onlyOwner {
            //require(msg.sender == owner,"only_owner");
            if(msg.sender != owner) {revert NotOwner(msg.sender);}
            _;
        }

        // called if calldata is not defined 
        receive() external payable {
            fund();
        }
        
        // called if calleddata is not emoty and receive is not defined
        fallback() external payable{
            fund();
        }



   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverterLib {

    // LIBRARIES CANT HAVE STATE VARIABLES 
    // CANT SEND ETHER

     function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
       (, int price,,,) = priceFeed.latestRoundData();
       // price has 8 decimals 
       // msg.value has 18 decimals 
       // to make price value 18 decimals we multiply by 10
       return uint256(price * 1e10);
    }
     // converts eth amount to usd price
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/1e18; // removes the 18 decimals 
        return ethAmountInUsd;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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