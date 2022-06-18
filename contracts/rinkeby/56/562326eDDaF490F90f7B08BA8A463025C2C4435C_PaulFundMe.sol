//SPDX-License-Identifier: MIT

//Pragma
pragma solidity ^0.8.0;
//Imports
import "./PaulPriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error PaulFundMe__NotOwner();
error PaulFundMe__CallFailed();

contract PaulFundMe {
    //Type Declarations
    using PaulPriceConverter for uint256;
    // State Variables
    uint256 public MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public mapAddressToAmountFunded;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    //Modifiers
    modifier onlyi_Owner() {
        if (msg.sender != i_owner) {
            revert PaulFundMe__NotOwner();
        }
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConversion(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );
        funders.push(msg.sender);
        mapAddressToAmountFunded[msg.sender] += msg.value;
    }

    function Withdraw() public onlyi_Owner {
        for (uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            mapAddressToAmountFunded[funder] = 0;
        }
        //-------------Reseting the array----------------
        funders = new address[](0);

        //----------------Withdrawing funds------------------
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) {
            revert PaulFundMe__CallFailed();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PaulPriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversion(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        return (ethPrice * ethAmount) / 1e18;
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