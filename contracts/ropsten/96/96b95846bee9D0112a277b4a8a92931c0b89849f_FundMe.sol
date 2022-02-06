/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



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

/*
---Here, the above import statement imports the following sol interface---
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
*/

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    //Here, a constructor is called for withdraw function.
    //Constructor is executed whenever the contract is run. So, through this constructor, we can find who is deploying the contract i.e., admin.
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    //payable is used in a function if that function is responsible for the transfer of ethereum
    function fund() public payable {
        //Let's say a user can only send us ethereum worth more than $50. So, we do that by following:
        //Here, 50 dollars is converted to unit value worth of wei as transaction in system is calculated especially through wei.
        uint256 minimumUSD = 50 * 10**18;
        /*Now, we need to check if the deposited amount is more than $50 or not. So, require function is used.
        Require is like a if statement. First, the eht is converted into dollars through getConversionRate() function
        So, condition is checked and if the condition is true, the contract exectues else the contract stops in the middle and displays the error message.
        */
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        //msg.sender is the sender and msg.value is the value they fund
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); //This is done to update the mapping after withdrawl of money
    }

    //This function returns the version of AggregatorV3Interface
    function getVersion() public view returns (uint256) {
        /*Creating an oject of the AggregatorV3Interface with an address on it.
        Here, this address is the adress that gives the current value of ropsten eth in usd.
        This address can be known from searching "Ethereum price feeds" in google
        */
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //Calling version()function from AggregatorV3Interface
        return priceFeed.version();
    }

    //This function returns the price of 1 ethereum
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        /*The latestRoundData() function is used from AggregatorV3Interface
        But, this function returns five different values <look at line 33>
        So, a touple is created to store those returned values.
        Simply, we just want answer of the latestRoundData() function. So, we are only defining answer in our tuple and ignoring all the other returns
        */
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        //Once the tuple is created, now we can get whatever we need from that tuple as below
        //The below code is doing a type casting from int256<look in line35>
        //to the returned type of this function i.e., uint256<look at line 63>
        return uint256(answer);
    }

    //This returns the usd value of what ethereum the person has funded.
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        //Here, the value is divided by 10^18 because system calculates in terms of wei.
        /*
        --------------note_--------------
            1 Eth = 10^9 Gwei
            1 Gwei = 10^18 Wei
        */
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    //Till now, the money can be send through fund(). Now lets know how the sender can retake their sent money back.
    /*
      address(this) is gives the address of this contract where we are currently working at.
      Now, code says that whoever calls this function "i.e., msg.sender", entire balance is transfered to them.
      Here, balance is the amount of Eth that the person has sent through this contract.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; //<_;> indicates where the rest of the code should go. In this case, to withdraw function.
    }

    //Here, onlyOwner is a modifier that restricts the function to be executed. withdraw function is only exectued after the onlyOwner is executed.
    function withdraw() public payable onlyOwner {
        //Note_ that withdraw function is not a great option. We want only the admin i.e., money sender to use this withdraw function.
        //So, for this a constructor is used that gives the of the owner who has run this contract.
        //Here, the money sender has to be the admin i.e., the person who deploys the contract.
        msg.sender.transfer(address(this).balance);
        /*We know that once the money is sent, the sender address is mapped with the money they sent using mapping - addressToAmountFunded 
          But, after withdrawl, the money is resent to the sender. So, we need to update that mapping and this is done using for loop.
          First, an empty list is initialized <in last line> so that the values can be iterated.
        */
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        //Just understand that the list is a dummy list that aids in setting the mapping of the sender address to 0.
        //Once the use of this dummy list is complete, reset the list to an empty list as follow.
        funders = new address[](0);
    }

    //Here, address is used as the  list contains data of addresses.
    address[] public funders;
}