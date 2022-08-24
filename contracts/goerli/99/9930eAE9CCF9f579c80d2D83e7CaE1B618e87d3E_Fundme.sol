// SPDX-License-Identifier: MIT


// Get funds from users
// Withdraw Funds
// Set a minimum funding value in USD


pragma solidity ^0.8.8;

//Refer PriceConvertor.sol for other functions
import "./PriceConvertor.sol";



error NotOwner();

contract Fundme{
    using PriceConvertor for uint256;

    uint256 public constant MINIMUM_USD=50 * 1e18;  // To make it GAS efficient we can make constant( variables whose values dont change after complile time like owner, minimumUSD
    // constant variables have different naming conventions .. ALL CAPS
    address[] public funders;
    mapping(address=> uint256) public addressToAmountFunded;

    address public immutable i_owner;  //Value changes once .. hence immutable .. add i_ to identify

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner=msg.sender;
        priceFeed=AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        //Want to set a minimum fund amount in USD
        // msg.value; used to get value (amount of ether sent)

        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't Send enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]+=msg.value;
    }

    

    function Withdraw() public onlyOwner{        //Added modifier
        // require(msg.sender==i_owner,"Sender is not owner");        // Makes sure only the owner can use the withdraw function
        // Reset the mapping of all the funders to 0
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder=funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }

        // reset the funders array
        funders=new address[](0);

        // withdraw funds from contract to the owner  check https://solidity-by-example.org/sending-ether/ for disadvantage
        //3 ways-> trasnfer, send, call

        // transnfer
        //payable(msg.sender).transnfer(address(this).balance);

        //send
        /* bool sendSuccess=payable(msg.sender).send(address(this).balance);
            require(sendSuccess,"Send failed");  */

        //call
        /* (bool callSuccess, bytes memory dataReturned)=payable(msg.sender).call{value: address(this).balance}("");
            require(callSuccess,"Send failed");  */

        // call is recommended
        (bool callSuccess,)=payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"Send failed");

    }

    modifier onlyOwner{          // if multiple functions needs only owner access use mmodifier
        //require(msg.sender==i_owner,"Sender is not owner"); 
        if(msg.sender!=i_owner){ revert NotOwner(); }
        _;  // _ represents doing rest of the code
    }


    // What happens if someone sends this contract ETH without calling the fund function.
    // As of now the contract will get the ETH but the sender's information is not stored

    // receive() and fallback() are special function

    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }
}


// require can be replaced with custom error to save gas

// SPDX-License-Identifier: MIT


//Library 
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";  // Uses npm to install @chainlink/contract from github


// Changes made... sending priceFeed as parameter so easier when switching networks
library PriceConvertor{
    function getPrice(AggregatorV3Interface priceFeed) public view returns(uint256){
        // NEED

        // ABI import the required ABI number .. Use interface( function declaration)
        // Address -> from  https://docs.chain.link/docs/ethereum-addresses/  (ETH/USD) 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

        //AggregatorV3Interface priceFeed=AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); //Changed to Kovan network.. so using contract address .. use link above
        // (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound)=priceFeed.latestRoundData(); To get all the values
        (, int256 price, , ,)=priceFeed.latestRoundData(); //Only price
        
        return uint256(price*1e10);
        
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice=getPrice(priceFeed);
        uint256 ethAmountInUSD=(ethPrice*ethAmount) / 1e18;
        return ethAmountInUSD;
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