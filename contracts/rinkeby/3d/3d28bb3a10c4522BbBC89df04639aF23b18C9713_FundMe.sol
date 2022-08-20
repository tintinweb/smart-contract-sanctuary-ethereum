//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        // The owner is the person who deploys this contract, thus me.
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18; //debe ser a la 18 no a la 8

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        answer = answer * 10**10;
        return uint256(answer);
    }

    // 1000000000
    function getConversionRate(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * weiAmount) / (10**18);
        return ethAmountInUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

// https://eth-converter.com/
// https://github.com/smartcontractkit/full-blockchain-solidity-course-py#lesson-3-fund-me
// https://www.epochconverter.com/
// https://github.com/smartcontractkit/full-blockchain-solidity-course-js#lesson-4-remix-fund-me

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