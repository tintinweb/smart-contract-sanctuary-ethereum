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

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();
// constant, immutable
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    address public immutable i_owner;
    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        // Want to be able to set a minimum fund about in USD
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "didn't send enough");  // 
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }


    function withdraw() public onlyOwner {
        for(uint256 funderIndex =0; funderIndex < funders.length; funderIndex +=1){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        // // transfer : transfer (2300 gas, throws error)
        // // msg.sender = address
        // // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        // // send : send (2300 gas, returns bool)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");


        // call : call (forward all gas or set gas, returns bool)
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if(msg.sender != i_owner) { revert NotOwner(); }
        _; // this tells to run the code in the function after the require, if you put before it'll run function code before the require
    }

    // What happens if someone sends this contract ETH without calling fund function 

    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
     (,int256 price,,,) = priceFeed.latestRoundData();
     // ETH in terms of USD
     // has 8 decimal places
     // we want this to have same number of decimal places as eth 1e18 so add 10 zeros
     return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount)/1e18;
        return ethAmountInUSD;
    }
}