//SPDX-License-Identifier: MIT

//pragma solidity ^0.8.15;
pragma solidity ^0.8.15;

// Let's keep tracking of who sends us some funding.

// Interfaces compile down to an ABI
// ABI = Application Binary Interface
// The ABI tells solidity and other programming languages
// how it can interact with another contract.

// Remix understand @chainlink/contracts is npm package and
// can download it but brownie cannot do that
// brownie can download it from Github
// check brownie-config.yaml dependencies and complier-solc

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    // here it is an address array;
    address[] public funders;

    // here it is only an address variable, not an array;
    address public owner;

    // AggregatorV3Interface create a global variable
    AggregatorV3Interface public priceFeed;

    // constructor is execute right after contract creation

    // Here we add _priceFeed address parameter
    // then we can input correct address to get eth-to-usd price
    // when we deploy contract to
    // the price can be used in multiple places.
    constructor(address _priceFeed) public {
        // using correct address to get eth-to-usd price
        priceFeed = AggregatorV3Interface(_priceFeed);
        // msg.sender is us who deploys the contract.
        owner = msg.sender;
    }

    function fund() public payable {
        // $50
        // the reason that why $50 need to multiple with 18 zero
        // because the getprice() return 1,218,663,863,030,000,000,000
        // we need to match the 50 dollar with corresponding amount of zero to do comparison
        // the function cannot return dollar value with one WEI is because AggregatorV3Interface returns int number.
        uint256 mimimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= mimimumUSD,
            "Give Me More Money! You Poor SOB!"
        );

        // msg.sender is the person who call the function
        // meaning the person who call the function is the person
        // who makes the donation.
        // The contract is the owner of donation
        addressToAmountFunded[msg.sender] += msg.value;

        // append msg.sender to funders array.
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // contract "AggregatorV3Interface" defined in an interface
        // (link: https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol)
        // this contract locates in this address "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e"
        // make sure the contract address is for Rinkeby

        // this part is replaced by code in constructor
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);

        // priceFeed is constructed in constructor
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // this part is replaced by code in constructor

        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        (
            ,
            // Unlike version function, latestRoundData return five values(Tuple)
            // A list of objects of potentially different types whose number is a constant at compile-time.

            // uint80 roundId,
            // int256 answer,
            // uint256 startedAt,
            // uint256 updatedAt,
            // uint80 answeredInRound

            // No need to list all five values inside the parenthesis
            int256 answer,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    // Modifier change the behavior of a function in a declarative way.
    // "_;" at the end meaning the function with "onlyOwner" will run the code
    // in modifier first then run the code in modified function.
    // using modifier we can modify fucntions easily by adding "onlyOwner".
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not the rightful owner, don't steal my money you stupid thief!"
        );
        _;
    }

    function withdraw() public payable onlyOwner {
        // only want the contract owner/admin to withdraw money
        // we need to set up owner of this contract immediately
        // right after the contract's creation.
        // so we need to use constructor with will be executed after contact is deployed.

        // code: require(msg.sender == owner);

        // msg.sender is the account that call the "withdraw" function
        // A.transfer(B) means transfer money from B to A
        // "this" is keyword in solidty mean the contract we are in
        // so here it means transfer this contract's balance to account call this function.

        // msg.sender is no longer a payable address anymore starting from Solidity 0.8.x.
        // we need to explicitly convert it to payable by using payable(msg.sender).
        payable(msg.sender).transfer(address(this).balance);

        // loop through each address has sent money and reset its balance as 0;
        // funderIndex < funders.length no equal because index start from 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset funders array as zero as well after withdraw balance.
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