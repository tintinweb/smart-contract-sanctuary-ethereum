// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";


// links
// 1. Faucets: https://faucets.chain.link/kovan?_ga=2.177560230.2034364311.1650734525-632805076.1650734525
// 2. Interfaces: https://github.com/smartcontractkit/chainlink/tree/develop/contracts/src/v0.8/interfaces

contract FundMe{

    // stores the address and how much was funded by that address
    mapping(address => uint256) public addressToFundAmount;
    address public owner;


    constructor() public {
        owner = msg.sender;
    }


    function fund() public payable{

        // Minimum required amount
        uint256 minimumUSD = 50 * 10**18;

        require(getConvertionRate(msg.value) >= minimumUSD, "More ETH is required to complete this transaction");
        
        addressToFundAmount[msg.sender] += msg.value;

        // what is the ETH -> USD convertion rate

        // To get the convertion rates we are going to use an off-chain service
        // these are called Oracles

        // ABI tells solidity and other programming languages what functions can 
        // be called on a given contract

        // Interfaces compile down to an ABI.

        // You always need an ABI to interact with a contract
    }


    function withdraw() public payable onlyOwner {
        // The transfer method is used to transfer ETH from one account
        // to another. Basically it transfers funds to the instance on
        // which its being called. In this case the person making this 
        // function call(msg.sender)

        // require(msg.sender == owner, "You are not the owner of this contract");
        payable(msg.sender).transfer(address(this).balance);
    }


    function getVersion() public view returns (uint256){
        // To initialize the contract, we need to pass in the contract address
        // these addressed can be found here: https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }


    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();


        // by default, the return is in 8 decimal places, we want to return 18(WEI)
        // we we need to add 10 more decimal places
        return uint256(answer * 10_000_000_000);
    }


    function getConvertionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1_000_000_000_000_000_000;
        return ethAmountInUSD;
    }


    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }


    function getEntranceFee() public view returns(uint256){
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice(); 
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
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