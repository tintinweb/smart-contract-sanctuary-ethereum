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

// get funds from users
// withdraw funds
// set a minimum value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

// 859741 gas
// 839789 gas

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 10 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // owner is whomever deployed this contract
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Want to be albe to set a minimal fund amount in SUD
        // 1. How do we send ETH to this contract?
        // Now tha we having 'payable' in our function, we can access 'Value' in our function
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); // 1e18 = 1 * 10 ** 18 (value in Wei for 1 ETH)

        // msg.value is considered the first parameter for any of the library functions. that is why we did not write the parameter in getConversionRate

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
        // everything after require (if it's not met the requirement) reverts back, and everything before require undoes (but the Gas is still paid)

        // When we send less than what is needed to be sent, we get revert with the message above
        // Reverting = undo any action before, and send remaining gas back
    }

    function withdraw() public onlyOwner {
        // looping /* starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++ /* funderIndex++ is the same as  fI = fI +1 */
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);

        // actually withdraw funds

        // transfer
        // send
        // call

        // msg.sender = address type
        // payable(msg.sender) = payable address type (in Solidity the only wat to transfer native token is to do that with a payable address)
        // payable(msg.sender).transfer(address(this).balance);

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failde");

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failde");
    }

    modifier onlyOwner() {
        //  require(msg.sender == i_owner, "Sender is not owner!"); // == means 'check if this right' whereas = means setting
        if (msg.sender != i_owner) revert NotOwner();
        _;
        // first do the require, then do the underscore (everything else in the code)
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price of ETH in terms of USD
        // 3000.00000000 (it has eight decimals, and we need 18 decimals)
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }
}