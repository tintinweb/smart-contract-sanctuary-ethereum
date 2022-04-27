//SPDX-License-Identifier: MIT

//This smart contract allows for users to add funds to the smart contract, and for the admin to withdraw those funds
//Q: Is the 'owner' the owner of the contract forever? Can multiple users call the same smart contract and create seperate instances
//   of it, so that there are different 'owners' for the same smart contracts? 

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    //This constructor makes it so that the address calling the contract is the 'owner'
    constructor() public {
        owner = msg.sender;
    }


    function fund() public payable {
        //Ensure minimum of $50 USD 
        uint256 minimumUSD = 50 * (10**18);
        require(getConversionRate(msg.value) >= minimumUSD, "Minimum Amount is $50.00 USD");

        //Adding funds to account
        addressToAmountFunded[msg.sender] += msg.value;

        //Adding account to funders array
        funders.push(msg.sender);
    }


    /* Creates the AggregatorV3Interface object for the ETH/USD data feed address and names the object/interface 'priceFeed' 
       Calls the AggregatorV3Interface object's .version function */
    function getVersion() public view returns(uint256) { 
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }


    /* Creates the AggregatorV3Interface object for the ETH/USD data feed address and names the object/interface 'priceFeed' 
       Calls the AggregatorV3Interface object's .latestRoundData and selects 'int256 answer' from the 5 options to get the latest ETH/USD 
       Multiplies answer by 10000000000 */
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }


    /* Calls the getPrice() function to get the current Eth price and multiplies it by an input amount
       Multiplies by 10^18*/
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; 
        return ethAmountInUsd;
    }


    //This function modifier will check to ensure that the address calling a function is the 'owner' of the contract
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    //Withdraw function 
    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 fundersIndex=0; fundersIndex < funders.length; fundersIndex++){
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }

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