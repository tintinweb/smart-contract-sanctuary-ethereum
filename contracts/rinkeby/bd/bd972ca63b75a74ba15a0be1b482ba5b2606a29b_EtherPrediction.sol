// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EtherPredictionFactory{
    event NewPrediction(address prediction);
    address[] public contracts;

    function newEtherPrediction(address aggregator, int targetPrice, uint targetTime, uint deadline) public returns (address){
        EtherPrediction e = new EtherPrediction(aggregator, targetPrice, targetTime, deadline);
        contracts.push(address(e));
        emit NewPrediction(address(e));
        return address(e);
    }    
}

contract EtherPrediction {

    AggregatorV3Interface internal priceFeed;
    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    constructor(address aggregator, int _targetPrice, uint _targetTime, uint _deadline) {
        require(_deadline < _targetTime, "The deadline has to be before the targetTime.");
        priceFeed = AggregatorV3Interface(aggregator);
        targetPrice = _targetPrice;
        targetTime = _targetTime;
        deadline = _deadline;
    }

    /**
     This struct will keep the total amount of ETH bet on the price being higher or lower than targetPrice at targetTime
     on the variable total.
     There's also a mapping between address and Bet, which tracks how much each user is betting on both higher and lower.
     */
    
    struct Bet{
        uint higher;
        uint lower;
    }

    Bet total;

    // Whether or not the price has been obtained already.
    bool obtainedPrice;

    // The price fetched by ChainLINK.
    int fetchedPrice;

    // The price users are betting for or against.
    int targetPrice;

    // UNIX time (seconds) for the prediction to be made.
    uint targetTime;

    // deadline UNIX time (seconds) for placing bets. Should be less than targetTime.
    uint deadline;

    uint constant decimals = 10 ** 12;

    mapping(address => Bet) addressToBet;

    function getDetails() public view returns (AggregatorV3Interface, Bet memory, int, int, uint, uint){
        return(priceFeed, total, fetchedPrice, targetPrice, targetTime, deadline);
    }

    function getUserBet(address a) public view returns (Bet memory){
        return addressToBet[a];
    }


    function placeBet(bool higher) public payable{
        require(msg.value > 0, "msg.value has to be more than 0");
        require(block.timestamp < deadline, "You can't place bets anymore, deadline was reached.");
        if (higher){
            addressToBet[msg.sender].higher += msg.value;
            total.higher += msg.value;
        }
        else{
            addressToBet[msg.sender].lower += msg.value;
            total.lower += msg.value;
        }
    }

    function claimPrize() public{
        require(block.timestamp > targetTime, "targetTime has not been reached yet");
        require(obtainedPrice, "Price has not been obtained yet.");
        uint prizeShare;
        
        if (targetPrice > fetchedPrice){
            prizeShare = (addressToBet[msg.sender].higher * decimals) / total.higher;
        }
        else{
            prizeShare = (addressToBet[msg.sender].lower * decimals) / total.lower;
        }

        uint prize = (prizeShare * (total.higher + total.lower)) / decimals;
        require(prize > 0, "You did not win any prize");

        (bool sent,) = payable(msg.sender).call{value: prize}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
                (
            /*uint80 roundID*/, 
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function obtainPrice() public{
        require(block.timestamp > targetTime, "targetTime has not been reached yet");
        require(obtainedPrice == false, "Price has already been obtained.");
        fetchedPrice = getLatestPrice();
        obtainedPrice = true;
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