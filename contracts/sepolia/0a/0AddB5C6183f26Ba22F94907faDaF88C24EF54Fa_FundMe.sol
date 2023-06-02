// SPDX-License-Identifier: MIT
// pragma
pragma solidity ^0.8.18;

// imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "contracts/PriceConverter.sol";

// error codes
error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author Ayush Patel
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our libaray
 */

contract FundMe{
    // Type declaration
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 *1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        // require(getConversionRate(msg.value) >= minimumUsd,"Didn't send enough.");

        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,"Didn't send enough");

        funders.push(msg.sender);
        // if condition isn't satisfied require function will revert
        // Revert - Send the gas back(undo the process)
        
    }

    function withdraw() public onlyOwner{

        

        for (uint256 funderIndex = 0; funderIndex <funders.length; funderIndex ++) 
        {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;

        }
        // reset the array
        funders = new address[](0);// (0) means making new funders array with 0 array elements from the start

        // 3 ways to withdraw the funds
        // using transfer - costs = 2300 gas, throw error

        // payable(msg.sender).transfer(address(this).balance);

        // using send - costs = 2300 gas, bool
        // bool sendSucess =  payable(msg.sender).send(address(this).balance);
        // require(sendSucess,"Send Failed");

        // Using call - reverts the gas , bool
        (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}(""); //bytes objects are array . Therefore we're using memory
        require(callSuccess,"Call Failed");

    }

    modifier onlyOwner{
        // _; if it has written above require means it will run all the code and then check the condition
        // require(msg.sender == i_owner,"You're not Owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // ABI
        
        (,int price,,,) = priceFeed.latestRoundData();

        // ETH in terms of USD
        return uint256(price * 1e18);

    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return pricefeed.version();
    }

    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal  view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice*ethAmount)/1e18;
        return ethAmountInUSD;
    }
}