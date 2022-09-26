// Get funcds from users
// Withdraaw funds
// Set a minimum funding valuee in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";
// 833,823
    error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 20 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {


        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
        // ETH. value in with 18 decimals (value in wei)
    }


    function withdraw() public onlyOwner {


        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // withdraw - 3 ways:

        // transfer
        // msg.sender - has type address
        // payable(msg.sender) = has type payable address
        //payable(msg.sender).transfer(address(this).balance); //return error if not enough gas and reverts

        // send
        //bool sendSuccss = payable(msg.sender).send(address(this).balance); // return bool and no revert
        //require (sendSuccess, "Send failed");

        // call - recommended way for this case
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value : address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
            //new way, more gas efficient
        }
        _;
        //doing the rest of the code like next() in middleware
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //npm and github

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // ABI
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // ETH / USDT, 8 decimals
        return uint256(price * 1e10);
        // to have 18 decimals same as ETH amount
    }

    //function getConversionRate(uint256 ethAmount, uint256 somethingElse) internal view returns (uint256) { // use as ethAmount.getConversionRate(somethingElse)
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {//wei to usd
        uint256 ethPrice = getPrice(priceFeed);
        uint256 usd = (ethPrice * ethAmount) / 1e18;
        // to get 18 decimals
        return usd;
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