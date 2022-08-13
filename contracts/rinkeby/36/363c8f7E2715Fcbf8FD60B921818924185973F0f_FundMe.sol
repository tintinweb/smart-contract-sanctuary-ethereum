// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

//Import Chainlink Aggregator
import "AggregatorV3Interface.sol";

//FundMe to send fund to the contract and withdraw it
contract FundMe {
    //Price feed to retrive ETH -> USD conversion
    AggregatorV3Interface priceFeed =
        AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

    //Mapping of addres which send funds
    mapping(address => uint256) public addressToAmountFunded;

    //Address of contract owner
    address public owner;

    //Array address of funders
    address[] public funders;

    //Modifier (keyword for function that will be executed before or after the inside code of the function
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!!");
        _;
    }

    //Constructor (call when contract is deployed
    constructor() public {
        owner = msg.sender;
    }

    //Function fund, payable function to send fund to the contract with minimum amount required 50$
    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    //Function getVersion, return version of aggregator
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    //Function getLastPrice, return price of ETH in USD
    function getLastPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    //Function getConversionRate, return the amount in USD from ETH amount
    function getConversionRate(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getLastPrice();
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    //Function withdraw, payable function wich withdraw the funds from the contract to give to the owner of the contract
    //User the modifier onlyOwner
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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