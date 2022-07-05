// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;
import "AggregatorV3Interface.sol";

contract Lottery{
    
    address payable[] public players;
    uint256 public usd_entry_fee ;
    address owner;
    AggregatorV3Interface internal priceFeed ;

    constructor(address _priceFeed) {
        usd_entry_fee = 50 * 10**18 ;
        owner = msg.sender ;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function enter() public payable{
        // 50$ minimum
        uint256 entrance_fee = getEntranceFee();
        require(msg.value >= entrance_fee) ;
        players.push(payable(msg.sender)) ;
    }

    function getLatestPrice() public view returns(uint256){
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price * 10**10);
    }

    function getEntranceFee() public view returns(uint256){ // entrance fee is in wei
        uint256 price_ETH = getLatestPrice();
        return ((usd_entry_fee * 10**18) / price_ETH) + 1000 ;
    }

    modifier OnlyOwner(){
        require(msg.sender == owner) ;
        _;
    }

    function startLottery() OnlyOwner public{}
    function stopLottery() OnlyOwner public{}
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