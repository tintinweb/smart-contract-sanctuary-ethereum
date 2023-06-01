// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

//SPDX-License-Identifier:MIT
//pragmas stmts
pragma solidity ^0.8.8;

//import stmts
import "./PriceConverter.sol";

//818210 gas
//constant
//immutable
//errors syntax
error FundMe__NotOwner();

//interfaces and libraries

contract FundMe {
    //type declarations
    using PriceConverter for uint256;

    //state variables
    mapping(address => uint256) private s_addressToAmountFunded;

    uint256 public constant MINIMUM_USD = 50 * 1e18; //351-constant 2451 without constant
    address[] private s_funders;
    address private immutable i_owner;

    AggregatorV3Interface public s_priceFeed;
    //modifiers
    modifier onlyOwner() {
        // require(msg.sender==i_owner,"sender's address is not bearer of the wallet(contract)!");
        // _;
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    //Functions Order
    //constructor
    //receive
    //fallback
    //external
    //public
    //internal
    //private
    //view/pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //what happens when sb sends this contract ETH without hitting the fund()
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    //AggregatorV3Interface internal priceEth; //AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    /**
     * @notice This function funds the deployed contract on sepolia
     * @dev This implements price feed as our param in getConversionRate function of PriceConverter.sol
     *
     */

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Funds below required limit!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public payable onlyOwner {
        /*starting index,ending index,step amount*/
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array
        s_funders = new address[](0);
        //actually withdraw the funds
    }

    //function cheaper withdraw through storage optimization in for loops using initial memory allocation to conduct cheaper loops
    function cheaperWithdraws() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //transfer

    // payable(msg.sender).transfer(address(this).balance);// automatically reverts if transaction failed

    //send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);// only reverts if require is added
    //require( sendSuccess , "send Failure!");

    //call
    // (bool callSuccess,)=payable(msg.sender).call{value:address(this).balance}("");
    // require(callSuccess , "call failed");
    function getOwner()public view returns(address){
        return i_owner;
    }
    function getFunder(uint256 index)public view returns(address){
        return s_funders[index];
    }
    function getaddressToAmountFunded(address funder)public view returns(uint256){
        return s_addressToAmountFunded[funder];
    }
    function getPriceFeed()public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }

}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{

    function getPrice(AggregatorV3Interface priceFeed)internal view returns(uint256){
    /*AggregatorV3Interface priceEth = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);*//*Removes need 
    for hardcoding this bit of code here*/    
    (,int price,,,)=priceFeed.latestRoundData();
    return uint256(price*1e10);

    }

    function getConversionRate(uint256 etherValue,AggregatorV3Interface priceFeed)internal view returns(uint256){
        //converts msg.value from eth to in terms of dollars 
        uint256 etherPrice = getPrice(priceFeed);
        uint256 priceEthinUsd = (etherPrice*etherValue)/1e18;
        return priceEthinUsd;

    }

}