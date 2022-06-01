// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './EtherToUSD.sol';

error FundMe__NotOwner();

/// @title A contract for crowdfunding
/// @author A. Brel
/// @notice This contract is a demo funding contact
/// @dev This implements price feed as our library
contract FundMe {
    using EtherToUSD for uint256;

    address public immutable owner;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    uint256 private constant MIN_USD = 50;
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /// @notice This function funds our contract
    /// @dev This implements price feed as our library
    function fund() public payable {
        require(msg.value.toUSD(priceFeed) > MIN_USD, 'Send at least 50$');

        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, 'Revert as send was not successful');

        // call - recommended way
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }('');
        require(callSuccess, 'Revert call');

        for (uint256 i; i < funders.length; i++) {
            addressToAmountFunded[funders[i]] = 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library EtherToUSD {
    function getLatestETHPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function toUSD(uint256 eth, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        return (eth * getLatestETHPrice(priceFeed)) / 1e36;
    }
}