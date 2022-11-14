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

//SPDX-License-Identifier:MIT

//Get funds from users
//WithDraw funds
//Set a minimum funding value in USD

//Pragma
pragma solidity ^0.8.8;
//import
import "./PriceConverter.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Error Codes

//InterFace Libraries Contracts

/** @title A contract for  crowd Funding 
 ** @auther Patrick Collins 
 ** @notice This contract is to demo  a sample funding contract 
 **@dev This implements price feeds as our library 
 */

contract FundMe {
    //Type Declarations 
    using PriceConverter for uint256;
    //State Variable 
    uint256 public minimumUsd = 5000 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable  owner;
    AggregatorV3Interface public priceFeed;
    //Modifier
     modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner ");
        _;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // What happen if someone send this contracts  ETH without calling the fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    //	932012 gas -non imutable
    //908553 gas -immutable
    function fund() public payable {
        //want to be able to set a minimum fund amount in USD
        //1.How do we send ETH to this contracts ?
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "Didn't send enough!"
        );

        //1e18 ==1*10**18==1000000000000000000
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //rest the array
        funders = new address[](0);
        //actually withdraw the funds

        //transfer
        payable(msg.sender).transfer(address(this).balance);

        //send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(" ");
        require(callSuccess, "Call failed ");
    }

   

}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library  PriceConverter{
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //ETH in terms of USD
        //3000.00000000
        return uint(price * 1e10);
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        return priceFeed.version();
    }

    function getConversionRate(uint ethAmount, AggregatorV3Interface priceFeed)
       internal
        view
        returns (uint256)
    {
        uint ethPrice = getPrice(priceFeed);
        //3000_00000000000000000=ETH/USD price

        //1_00000000000000000
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}