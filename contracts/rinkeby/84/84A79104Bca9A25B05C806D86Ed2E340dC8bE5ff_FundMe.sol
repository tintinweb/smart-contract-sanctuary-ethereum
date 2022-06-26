//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

/** @title Simple Fund Me Contract
 * @author Sanskar Sharma
 * @notice This contract is used for creating a simple funding contract
 * @dev This implements price feed as library
 */
contract FundMe {
    //Type Conversion
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    AggregatorV3Interface private s_priceFeed;
    address private immutable i_owner;
    uint256 constant MINIMUM_USD = 50 * 1e18;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    //Functions

    /** @notice This function is used to fund the contract based on ETH/USD  */

    function fund() public payable {
        require(
            msg.value.getConversion(s_priceFeed) >= MINIMUM_USD,
            "Not sufficient amount"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    /** @notice This function is used by the owner to withdraw the funds given by the users  */

    function withdraw() public payable onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            address currFunder = s_funders[i];
            s_addressToAmountFunded[currFunder] = 0;
        }
        s_funders = new address[](0);
        (bool callSucc, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucc, "Transaction Failed");
    }

    //View or pure functions

    function getaddressToAmountFunded(address funderAddress)
        public
        view
        returns (uint256)
    {
        return (s_addressToAmountFunded[funderAddress]);
    }

    function getFunders(uint256 index) public view returns (address) {
        return (s_funders[index]);
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return (s_priceFeed);
    }

    function getOwner() public view returns (address) {
        return (i_owner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e18);
    }

    function getConversion(uint256 amntFunded, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmntInUSD = (ethPrice * amntFunded) / 1e18;
        return ethAmntInUSD;
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