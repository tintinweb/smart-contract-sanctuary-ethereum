// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract Fundme {
    mapping(address => uint256) public addresstoAmountFunded;

    address public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        owner = msg.sender;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        uint256 minUSD = 5000000000;
        uint256 amountFundedinUSD = getConversionRates(msg.value);
        require(amountFundedinUSD >= minUSD, "You need to spend more eth.");
        addresstoAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        //what is the ETH -> USD rate
    }

    function getEnteranceFee() public view returns (uint256) {
        uint256 minimumUSD = 5000000000;
        uint256 ETHtoUSD = getETHtoUSD();
        uint256 precision = 1 * 10**8;
        return (minimumUSD * ETHtoUSD) / precision;
    }

    function getETHtoUSD() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRates(uint256 amount) public view returns (uint256) {
        uint256 ethPrice = getETHtoUSD();
        uint256 amountUSD = (amount * ethPrice) / 1000000000000000000;
        return amountUSD;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You dont have the rights to withdraw funds."
        );
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addresstoAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

//0.00000325

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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