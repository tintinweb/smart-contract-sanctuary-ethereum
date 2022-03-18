/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: lottery.sol

/*contract Lottery, vrfConsumerBase, Ownable{
    address payable[] public players;
    address payable public winner;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE{
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;

    constructor(address _aggregator, address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyhash ) VRFConsumerBase(_vrfCoordinator, _link) public {
        ethUsdPriceFeed = AggregatorV3Interface(_aggregator);
        usdEntryFee = 50 * (10**18);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;

    }
    
    function enter() public payable {

        players.push(msg.sender);  
    }

    function getEntranceFee() public view returns(uint256){
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData;
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 costEnter = (usdEntryFee * 10 ** 18)/price;
        return costEnter;
    }
    function startLottery() public onlyOwner{
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);

    }
    function fullfillRandomness(bytes32 _requestId, uint256 _randomness)internal override{
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "NOT NOW CALCULATING WINNER");
        require(_randomness > 0, "randomness not foun");
        uint256 indexOfWinner = _randomness % players.length;
        winner = players[indexOfWinner];
        winner.transfer(address(this).balance);
    }
}*/

contract Lottery{
    address payable[] public players;
    uint256 public priceFee;
    AggregatorV3Interface public ethPriceUsd;

    constructor(address _aggregator) public{
        priceFee = 50 * (10**18);
        ethPriceUsd = AggregatorV3Interface(_aggregator);

    } 

    function getEntranceFee() public view returns(uint256){
        (,int256 price,,,) = ethPriceUsd.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        uint256 costToEnter = (priceFee * 10 ** 18)/adjustedPrice;
        return costToEnter;
    }

}