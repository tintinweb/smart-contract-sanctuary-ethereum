// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

// Kovan chainlink eth -> usd addy 0x9326BFA02ADD2366b30bacB125260Af641031331
// Rinkby chainlink eth -> usd addy 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner = msg.sender;

    function fund() public payable {
        uint256 minUSD = 1 * 10**18; // 1 dollar
        require(msg.value >= minUSD, "You need to spend more Eth!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getAddressToAmountFunded(address key)
        public
        view
        returns (address, uint256)
    {
        return (key, addressToAmountFunded[key]);
    }

    // need to be on kovan bc for this to work
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        return ethPrice * ethAmount;
    }

    function withdraw() public payable onlyOwner {
        payable(owner).transfer(address(this).balance);

        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            addressToAmountFunded[funders[funderIdx]] = 0;
        }

        funders = new address[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
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