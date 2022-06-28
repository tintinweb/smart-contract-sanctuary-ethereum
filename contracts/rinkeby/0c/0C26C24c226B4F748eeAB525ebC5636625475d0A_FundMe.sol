// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "./PriceConvertor.sol";

contract FundMe {
    address public immutable owner; // immutable -> constant after first declaration

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    using PriceConvertor for uint256; // gives uint256 type methods described inside library

    uint256 public constant minUSD = 50 * 1e18; // constant -> cant change

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        // 10**18 wei = 1 ETH
        // msg.value contains eth (native) amount send in uint256
        // require(getConversionRate(msg.value) >= minUSD, "Amount is less");
        require(
            msg.value.getConversionRate(priceFeed) >= minUSD,
            "Amount is less"
        );

        // revert if false -> undo any action done so far and send remaing gas fee back
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        // reset array
        funders = new address[](0);
        // 3 ways to withraw fund

        // transfer - results in err if any (revert transaction)
        // payable(msg.sender).transfer(address(this).balance);

        // send - return bool if error or not (allow us to tell if to revert)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,'send failed');

        // call (lower level command, dont need abi)
        // (bool callSucess, bytes memory dataReturned) = payable_address.call{...args}(fxn name);
        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "send failed");
    }

    // modifier with custom Error
    modifier onlyOwner() {
        // require(msg.sender == owner, "Not owner"); // save gas to use error instead of string
        if (msg.sender != owner) revert NotOwner();
        _; // wrapped code here
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

error NotOwner();

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library cant have state variable and also cant send ether

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int price, , , ) = priceFeed.latestRoundData(); // destructuring of solidity
        // price is 10**8 multiple and type int but 10**18 uint is needed
        return uint256(price * 1e10);
    }

    // eth to usd
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // dividing by 1e18 as both are 1e18 which will result in 1e36
        return ethAmountInUsd; // return eth in usd raised to power 18
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