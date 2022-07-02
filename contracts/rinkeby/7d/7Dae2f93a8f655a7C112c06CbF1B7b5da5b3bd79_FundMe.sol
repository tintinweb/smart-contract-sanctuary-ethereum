// SPDX-License-Identifier:MIT
pragma solidity 0.8.15;
import "AggregatorV3Interface.sol";

contract FundMe {
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToFundValue;

    function fund() public payable {
        //10USD
        uint256 minUSD = 1 * 10**18;
        require(
            getCoversionRate(msg.value) >= minUSD,
            "you need send 1USD at least"
        );
        addressToFundValue[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // need to fund specific value of usd
    // 1.) need find ETH to usd value > from chainlink oracle
    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getCoversionRate(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ETHprice = getLatestPrice();
        uint256 inUSD = (_ethAmount * ETHprice) / 1000000000000000000;
        return inUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdrawal() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        // get this contract balance and transfer to msg.sender
        //clean the funding record when withdraw
        for (uint256 i = 0; i < funders.length; i++) {
            addressToFundValue[funders[i]] = 0;
        }
        funders = new address[](0);
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