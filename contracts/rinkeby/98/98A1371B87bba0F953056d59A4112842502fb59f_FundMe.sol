pragma solidity >=0.6.0 <0.9.0;
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToamountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface pricefeed;

    constructor(address ad) public {
        owner = msg.sender;
        pricefeed = AggregatorV3Interface(ad);
    }

    function fund() public payable {
        uint256 minimumusd = 50 * (10**18);
        require(
            getConversionRate(msg.value) >= minimumusd,
            "you need to spend more eth"
        );

        addressToamountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVesion() public view returns (uint256) {
        return pricefeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = pricefeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethprice = getPrice();
        uint256 ethAmountInUSD = (ethprice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToamountFunded[funder] = 0;
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