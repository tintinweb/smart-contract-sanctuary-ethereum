// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe{

    mapping(address => uint256) public addressToAmount;

    address owner;

    AggregatorV3Interface internal priceFeed;

    constructor(address _feedAddress){
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function fund() public payable {
        require(msg.value >= 386650000000000,"Add more amount" );
        addressToAmount[msg.sender] += msg.value;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"you are not the owner");
        _;
    }


    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price/100000000;
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