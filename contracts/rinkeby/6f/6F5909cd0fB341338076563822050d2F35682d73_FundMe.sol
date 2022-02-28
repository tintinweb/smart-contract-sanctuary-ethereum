// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Gib uns mehr Geld");
        _;
    }

    mapping(address => uint256) public addressNachAmountFunded;

    function fund() public payable {
        uint256 minimumUSD = 50;
        require(getConversionRate(msg.value) >= minimumUSD, "Gib mehr Geld");

        addressNachAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }

    function getDecimal() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.decimals();
    }

    function withdrawGeld() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressNachAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = uint256(getPrice());
        uint256 ethAmountUSD = ethAmount * ethPrice;
        return ethAmountUSD;
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