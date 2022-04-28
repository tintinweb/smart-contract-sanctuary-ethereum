// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Get the latest ETH/USD price from chainlink price feed
import "AggregatorV3Interface.sol";

contract BasicBet {
    //mapping to store which address depositeded how much ETH
    mapping(address => uint256) public addressToAmountFunded;
    // array of addresses who deposited
    address[] public funders;
    // uint256 holding the amount to be bet + gas costs
    uint256 cost;

    constructor(uint256 amount) {
        cost = amount; // convert to eth???
        fund(msg.sender);
    }
    function retrieveCost() public view returns (uint256) { // Thomas Edit
        return cost;
    }
    function retrieveNumFunders() public view returns (uint256) {
        return funders.length;
    }

    function fund(address p) public payable {
        if (addressToAmountFunded[msg.sender] == 0) {
            // 18 digit number to be compared with donated amount
            uint256 minimumUSD = 0 * 10 ** 18;
            uint256 maximumUSD = 20 * 10 ** 18;
            //keep bet size within member-ship parameters ($5-$20)
            require(getConversionRate(msg.value) >= minimumUSD, "You need to bet more ETH!");
            require(getConversionRate(msg.value) <= maximumUSD, "You can't bet that much ETH!");
            //if not, add to mapping and funders array
            addressToAmountFunded[msg.sender] += msg.value;
            funders.push(msg.sender);
        }
    }
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(uint256(answer) * 10000000000);
    }
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
    function withdraw() payable public {

        // If you are using version eight (v0.8) of chainlink aggregator interface,
        // you will need to change the code below to
        payable(msg.sender).transfer(address(this).balance);
        //     msg.sender.transfer(address(this).balance);


        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //funders array will be initialized to 0
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