/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {

    mapping(address => uint256) public fundMeArray;

    address[] public fundAddresses;

    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function send() public payable {

        // uint256 minimumAmount = 50 * 10 ** 18;
        // require(getCorversion(msg.value) >= minimumAmount, "You need to spent more eth!");

        fundMeArray[msg.sender] += msg.value;

        fundAddresses.push(msg.sender);

    }

    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getCorversion(uint256 ethAmount) public view returns(uint256) {
        uint256 priceFeed = getPrice();
        uint256 ethPrice = (ethAmount * priceFeed) / 1000000000000000000;
        return ethPrice;
    }

    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public ownerOnly payable {

        address payable value = payable(msg.sender);

        require(value == owner);
        
        value.transfer(address(this).balance);

        for (uint256 index; index < fundAddresses.length; index++) {
            address fundAdd = fundAddresses[index];
            fundMeArray[fundAdd] = 0;
        }

        fundAddresses = new address[](0);
    }

}