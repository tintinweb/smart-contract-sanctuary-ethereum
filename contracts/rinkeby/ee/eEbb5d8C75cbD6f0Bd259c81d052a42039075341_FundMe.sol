/**
 *Submitted for verification at Etherscan.io on 2022-02-16
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

// File: FundMe.sol

// The ABI tells solidity and other programming languages how it can interact with another contract

contract FundMe {
    // using SafeMathChainlink for uint256;
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // When the contract is run, we are set as the owner
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // payable means this function can be used to pay for things. 
    function fund() public payable {
        // $50, we can allow anybody to fund this contract with the minimum amount and above
        uint256 minimumUSD = 50 * 10**18; // usdamount per wei
        // 1gwei < $50
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        // Keep track of how much they funding and who is funding us
        // addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }


    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        // (uint80 roundId, 
        // int256 answer, 
        // uint256 startedAt, 
        // uint256 updatedAt, 
        // uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // the multiplication returns the in 18 decimals(wei)
    }

    // 1000000000(ethAmount) in gwei
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();                    
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000 ;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns(uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // this function makes it so we are the only one that can withdraw from the contract and resets the funders
    function withdraw() payable onlyOwner public {
    // whoever calls this function is going to be the sender, transfer them all of our money.
    // "this" means the current contract
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}