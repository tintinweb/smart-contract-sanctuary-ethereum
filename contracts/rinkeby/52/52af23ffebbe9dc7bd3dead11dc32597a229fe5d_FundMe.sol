//SPDX-License-Identifier: MIT


//Errors remaining 
// Setting a particular threshold 



pragma solidity >=0.6.6 <0.9.0;

// import "@chainlink/contracts/src/v0.3/interfaces/AggregatorV3Interface.sol";
// import "chainlink.......safemath from openzapp"
// we need ABI to interact with already deployed contract

interface AggregatorV3Interface{
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);


    function getRoundData(uint80 _roundId) external view returns(
        uint80 roundID,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answerInRound
    );

    function latestRoundData() external view returns(
        uint80 roundID,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answerInRound
    );

}


contract FundMe{ //accept some type of payment

    // using safemath for int256;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() public{ //constructor called immediately as conytact is deployed
         owner=msg.sender;
    }

    function fund() public payable{

        //setting $50
        // uint256 minimumUSD=1*10**12;
        // require(msg.value >= minimumUSD, "Yo neeed to spend more ETH"); //transaction reverted if not met this condition
        
        addressToAmountFunded[msg.sender]+=msg.value; //keywords in every contract
        //what is conversion rate of token

        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // interface type  name as it will give pricefeed    address of pricefeed rinkeby 
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,
        int256 answer,
        ,
        ,
        )= priceFeed.latestRoundData();
        //  returns price of 1 etherium in USD, divide by 10000000000 to get actual price of 10eth in USD
        return uint256(answer/100000000); 
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice=getPrice();
        uint256 ethAmountInUsd=(ethPrice*ethAmount);
        return ethAmountInUsd;
    }
    //13639598601 this has 18 decimals as well so 0.000000013639598601 for 1Gwei

    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }

    function withdraw() payable onlyOwner public{
        // function withdraw() payable public{
        // require(msg.sender==owner);
        // payable(msg.sender).transfer(address(this).balance);
        // ORRRR
        payable(msg.sender).transfer(address(this).balance);
         //setting all senders to 0
        for(uint256 funderIndex=0; funderIndex< funders.length; funderIndex++){
            address funder=funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }
        funders = new address[](0); //reset the funder array

        // Firstly modifier onlyOwner will run and then after that this function wll learn
        

    }

}