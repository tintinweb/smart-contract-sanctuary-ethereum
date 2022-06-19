// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // Immutables and constant are not stored insied a storage slot instead they are stored in bytecode itself
    uint256 public constant MIN_USD = 50 * 1e18;
    address public immutable i_owner;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        // msg.value.getConversionRate(); msg.value becomes first parameter of the function
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Price is lower, send more"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        /* Reset mapping */
        for (uint256 i = 0; i < funders.length; i++) {
            address currAddress = funders[i];
            addressToAmountFunded[currAddress] = 0;
        }

        /* Reseting the array to point to new location and intial element 0 */
        funders = new address[](0);

        // msg.sender = address
        // paybale(msg.sender) = paybale address;

        (bool callSuccess, ) = payable(address(this)).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call falied ");
    }

    modifier onlyOwner() {
        // The string is stored in string array
        // require(msg.sender == i_owner, "Not owner of the contract");

        // Hence we dont store array of string
        if (msg.sender == i_owner) {
            revert NotOwner();
        }
        _;
    }

    /* 
        A contract receiving Ether must have at least one of the functions below
        receive() external payable
        fallback() external payable
        receive() is called if msg.data is empty, otherwise fallback() is called.
    */

    /*                
            send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback() 
    */

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // They can't have state variables and also all func will be internal
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        //because returned value has 8 decimal place and our msg.value is of 18
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 currEthPrice = getPrice(priceFeed);
        uint256 ethAmountToUSD = (currEthPrice * _ethAmount) / 1e18;
        return ethAmountToUSD;
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