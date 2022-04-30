/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



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

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    //creates an empty array which we'll use to keep track of the people who funded
    address[] public funders;
    //creates a variable of type 'address' called owner
    address public owner;

    //constructor is a function that automaticall executes as soon as the contract is deployed.
    //You don't have to state 'public' when using constructor. This is already implied
    constructor() {
        //we set the owner to whoever is the msg.sender of this contract. And the msg.sender of contruct
        //will always be the person who deploys the contract
        owner = msg.sender;
    }

    function fund() public payable {     //Payable means the function can pay for things
        uint256 minimumUSD = 50 * (10**18);
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more Eth!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); //whoever funds the contract, add them to the funders array

    }

    function getVersion() public view returns (uint256) {
        //interface of type 'AggregatorV3Interface' named 'priceFeed' is equal to the AggregatorV3Interface function
        //called on the Rinkeby Ethereum to USD address (0x8A753747A1....)
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint(answer*10000000000);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }

    //we can add 'onlyOwner' to any of our functions. Since we have the require statement as the first line,
    //and the second line is the '_', the underscore means run the rest of the code in the function
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {
        //.transfer means we transfer ether to whatever comes before .transfer (in this case msg.sender)
        payable(msg.sender).transfer(address(this).balance);

        //create a for loop that can be used to reset the amounts that each person funded
        //the for loop starts at 'uint256 funderIndex=0' which we defined ourselves
        //the for loop checks if 'funderIndex' is less than the length of our funders array
        //if the for loop is less than the length of the funders array, we add 1 to the funder index and continue
        //the loop stops once fundexIndex is greater than or equal to the length of the funders array
        for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++) {
            address funder = funders[funderIndex]; //create an address for whichever funder we are on in the funders array
            addressToAmountFunded[funder]=0; //set the addressToAmountFunded for this funder to 0
        }
        funders = new address[](0); //now we create a 'new' funders array and initialize it to 0
    }
}