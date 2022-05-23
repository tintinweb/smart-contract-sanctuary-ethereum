// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    AggregatorV3Interface internal AggInt;
    mapping(address => uint256) public donorsMap;
    address[] public donorsList;
    address private owner;
    uint256 public minFeeUSD = 50;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        AggInt = AggregatorV3Interface(priceFeedAddress);
    }


    function fund() public payable {

        require(msg.value >= getMinimumFee(), "Ya'll dutch or something?");

        donorsMap[msg.sender] += msg.value;
        donorsList.push(msg.sender);
        
    }

    function withdrawAll() public payable onlyOwner {

        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i = 0; i<donorsList.length; i++) { donorsMap[donorsList[i]] = 0; }
        donorsList = new address[](0);
    }


    function getMinimumFee() public view returns(uint256) { //returns in wei
        uint256 ETHUSD = ETHUSD_get();
        uint256 precision = 10 ** 18; //converting from $wei to wei, so must apply twice
        return (minFeeUSD * precision * precision) / ETHUSD;
    }


    function ETHUSD_get() public view returns(uint256) {
        (,int price,,,) = AggInt.latestRoundData();
        return uint256(price) * 10 ** 10; //1 ETH -> 10^-18 USD
    }

    function weiToUSD(uint256 value) public view returns(uint256) { //no longer useful
        return (value * ETHUSD_get()) / (10 ** 36); //get function has 10^18 attached
    }


    modifier onlyOwner {
        require(msg.sender == owner, "stop tryna steal me money u dirty bich");
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