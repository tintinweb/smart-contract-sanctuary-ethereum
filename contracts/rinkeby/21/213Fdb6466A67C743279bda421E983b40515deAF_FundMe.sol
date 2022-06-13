// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

// contract can hold eth as it is also located at an address just like wallet
contract FundMe {
    using PriceConverter for uint256;

    // both ethPrice and ethAmount are in terms of wei, /1e18 normalize the return from getConversionRate already, further normalize will lead to decimals
    // therefore, *1e18 to minimumUsd instead
    uint256 public constant MINIMUM_USD = 50 * 1e18; // constant can optimize gas usage

    // price as at 0610: $1,792.51
    // at least need 50/1,792.51 eth ~> 28000000000000000 wei   30000000000000000

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner; // immutable can optimize gas usage

    AggregatorV3Interface public priceFeed;

    // immediately called at deployment
    constructor(address priceFeedAddress) {
        // the msg send at deployment must be the owner
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    function fund() public payable {
        // able to set a minimum fund amount in USD
        // require (msg.value >= 1e18, "Didn't send enough!"); // 1e18 == 1 * 10 ** 18 wei = 1 eth
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;

        // revert: error in blockchain
        // undo action before and send remaining gas back
        // what happened before revert prompted still spent gas (already execute once but just undo)
    }

    function withdraw() public onlyOwner {
        // Copy an paste in each function is clumsy, refer to modifier below
        // require(msg.sender == owner, "Sender is not the owner");

        // reset funders' funds record to 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); // 0 object to start

        // 3 ways to withdraw

        // // transfer  -> if error revert automatically
        // payable(msg.sender).transfer(address(this).balance);

        // // send -> need manully require for error case
        // bool sendSuccess =  payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not the owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // _ means doing rest of the code in the function using this modifier
    }

    // trigger when receive payment apart from using the contract itself
    receive() external payable {
        fund();
    }

    // if cannot recognize any function to call then will call this fallback function
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

library PriceConverter {
    // interact with external contract
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // refer to the interface return in github, only need the price in this case
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // xxxx.00000000    return from price is default 8 d.p. for now
        return uint256(price * 1e10); // 18 0s for wei so converting to wei still need add 10 0s
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // always prefer multiply first the divide in solidity
        // solidity is not good at decimals because there will be lose of precision when doing decimals calculation, lose precision during round up/down
        // therefore, usually use whole number to calculate instead and index the place of decimal in another variable
        uint256 ethAmountInUsed = (ethPrice * ethAmount) / 1e18; // wei to eth
        return ethAmountInUsed;
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