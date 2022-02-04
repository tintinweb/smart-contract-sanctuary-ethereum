// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address public sender;
    AggregatorV3Interface public priceFeed;

    constructor(address __priceFeed) public {
        priceFeed = AggregatorV3Interface(__priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // to which address it is funding
        uint256 minimumUSD = 10 * 10**18;
        require(
            getConversion(msg.value) >= minimumUSD,
            "You have to spend minimum of 10 USD"
        );
        addressToAmountFunded[msg.sender] = msg.value;
        sender = msg.sender;
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e //this address is of rinkbey testnets
        // );
        return priceFeed.version();
    }

    function getValue() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // 274648929177
        return uint256(answer * 10**10);
    }

    function getConversion(uint256 ethAmount) public view returns (uint256) {
        uint256 price = getValue();
        //244228000000
        uint256 ethAmontInUSD = (price * ethAmount) / (10**18);
        //249758928896000
        return ethAmontInUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

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