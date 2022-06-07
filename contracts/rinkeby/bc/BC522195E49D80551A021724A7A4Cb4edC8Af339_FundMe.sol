// SPDX-License-Identifier: MIT

// Get funds form users
// Withdraw funds
// Set a minimum funding value in USD

// pragma solidity >=0.6.0 <0.9.0;
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

import "./PriceConverter.sol";

// advance
//1 Constant , immutable
//2 custom error
//3 fallback and receive functions

error FundMe_NotOwner();

// NatSpec Format
/** @title A contract for crowd funding
  * @author Himanshu goyal
  * @notice This contract is to demo a sample funding contract 
  * @dev This implements price feeds as our library
*/


contract FundMe{
    // using SafeMathChainlink for uint256; // no overflow
    using PriceConverter for uint256 ;
    address[] public s_funders;
    mapping(address => uint256) private s_addressToAmount;

    uint256 constant MINIMUM_USD = 50*1e18;
        // 21,415 gas - constant
        // 23,515 gas - non-constant

    address private immutable owner;
        // 21,508 gas - immutable
        // 23,644 gas - non - immutable

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner{
        // require(msg.sender == owner,"Owner hi le skta hai");
        if(msg.sender != owner){ revert FundMe_NotOwner();}
        _; //first do reqire statment then do the rest of the function code
    }

    // when we deploy the contract then this below function is called right away
    constructor(address priceFeedAddress){
        owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }


    uint256 public number;
    // when we send our funds to a contract then the person who deploy it will recive
    function fund() public payable{
        // $50
        

        // 1gwei < $50
        number = 5; // number will become 0 when reverting // gas spend in making number 5 is also given back to the user
        // require(getConversionRate(msg.value) >= minUDS , "You need to spend more ETH!");
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD , "You need to spend more ETH!");
        // msg.value.getConversionRate();
        // if require condition not met then it revert back the transaction by saying the message : "you need to spend more ETH"
        s_addressToAmount[msg.sender] += msg.value;
        s_funders.push(msg.sender);
        // What the ETH -> USD conversion rate
    }

    // in PriceConverter.sol Library
    /*
    function getVersion() public view returns(uint256){
        AggregatorV3Interface s_priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return s_priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface s_priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        // (,int256 answer,,,) = s_priceFeed.latestRoundData(); // similar as below
        (   ,
            int256 answer,
            ,
            ,
            uint80 answeredInRound
        )=s_priceFeed.latestRoundData();
        // return uint256(answer); // Type casting
        return uint256(answer * 1000000000);  // in wei
        // 1965.84000000 UDS = 196584000000 gwei// 21 may 2022
    }
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethMountInUsd = (ethPrice * ethAmount)/1000000000000000000;
        return ethMountInUsd;
    } */


    function withdraw() payable onlyOwner public {
        // only want the contract admin/owner
        // require(msg.sender == owner , "Sender is not owner");

        //https://solidity-by-example.org/sending-ether/
        // transfer (Method 1) 
        // msg.sender.transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance); // if payable not above

        // send (Method 2)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess , "Send failed");

        // call (Method 3)
        // (bool callSuccess , /*bytes memory dataReturned*/)=payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess , "Call failed");

        // making all funds to zero
        for(uint256 i=0; i<s_funders.length ;i++){
            address funder = s_funders[i];
            s_addressToAmount[funder] = 0;
        }
        s_funders = new address[](0); // reseting array
    }

    /*******************************************************************/
    function cheaperWithdraw() payable public onlyOwner {
        address[] memory funders = s_funders;
        // mapping can't be in memory, sorry!
        for(uint256 i=0;i<funders.length;i++){
            address funder = funders[i];
            s_addressToAmount[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success , ) = owner.call{value:address(this).balance}("");
        require(success);
    }
    /*******************************************************************/
    
    // What happens if someone sends this contract ETH without calling the fund function
    // receive()
    receive() external payable{
        fund();
    }
    // fallback()
    fallback() external payable{
        fund();
    }

    /* view and pure functions */
    function getOwner() public view returns(address){
        return owner;
    }
    function getFunder(uint256 index) public view returns(address){
        return s_funders[index];
    }
    function getAddressToAmountFunded(address funder) public view returns(uint256){
        return s_addressToAmount[funder];
    }
    function getpriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    
    /* function getVersion() internal view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    } */

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){

        // (,int256 answer,,,) = priceFeed.latestRoundData(); // similar as below
        (   ,
            int256 answer,
            ,
            ,
            //uint80 answeredInRound
        )=priceFeed.latestRoundData();
        // return uint256(answer); // Type casting
        return uint256(answer * 1000000000);  // in wei
        // 1965.84000000 UDS = 196584000000 gwei// 21 may 2022
    }
    function getConversionRate(uint256 ethAmount , AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethMountInUsd = (ethPrice * ethAmount)/1000000000000000000;
        return ethMountInUsd;
    }
}