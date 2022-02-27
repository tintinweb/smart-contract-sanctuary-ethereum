// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "AggregatorV3Interface.sol";

contract Donation {
    mapping(address => uint256) public fundersAmount ;
    address[] public funders ;
    address public admin;
    AggregatorV3Interface chainLink;

    constructor (address _priceFeed) {
        chainLink = AggregatorV3Interface(_priceFeed);
        admin = address(msg.sender);
    }

    modifier atLeast10USD() {
        uint256 valueInUsd = getPriceInUSD(msg.value);
        require(valueInUsd >= 10 * 10 ** 18, "At least 10 USD");
        _;
    }

    function donate() payable atLeast10USD public {
        funders.push(address(msg.sender));
        fundersAmount[address(msg.sender)] = msg.value;
    }

    function getPriceInUSD(uint256 ethAmount) public view returns (uint256) {
        uint256 cRate = getEthUSDConversionRate();
        return ethAmount * cRate / 10 ** 18;
        
    }

    function getEthUSDConversionRate() public view returns(uint256) {
        (,int price,,,) = chainLink.latestRoundData();

        // return price with 18 decimal places
        return uint256(price) * 10**10;
    }

    modifier isAdmin() {
        require(address(msg.sender) == admin, "Only Admin Can Withdraw");
        _;
    }

    function withdraw() payable isAdmin public {
        payable(address(msg.sender)).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            fundersAmount[funders[i]] = 0;
        }
        funders = new address[](0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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