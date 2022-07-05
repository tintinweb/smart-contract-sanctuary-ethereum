// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 *18
    // make it to the same value i.e decimal points
    // constant makes it more gas efficient, it is also used for those values that appear once or a few times in your code without much changes,

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    // immutable is similar to constant. They save gas.

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; //whoever depolyed this contract
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // payable is the function to send native token/Eth to the contract
        // Want to be able to set a minimum fund amount in usd
        // 1. How do we send ETH to this contract
        // msg.value.getConversionRate(); -->easier way (using the library)
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 = 1 ETH
        // If value is < 1e18, it will revert with the message.
        // msg.value is for the value for ETH/blockchain native currency

        // What is reverting?
        // undo any action before and send the remaining gas back.

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // for loop -"for" word to start using it
        // [a, b, c, d]
        /*starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            // + 1 = ++ (for funderIndex)
            address funder = funders[funderIndex]; // address to the first account which contributed
            addressToAmountFunded[funder] = 0; //reset the account back to 0 since the amount is withdrawn
        }
        // reset the array
        funders = new address[](0);
        // actually withdraw the funds
        // 3 ways:

        // transfer (if fails, it will error and revert the transaction) - 2300 gas
        // msg.sender = address
        // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);

        // send (if fails, will send back a boolean whether it is successful). - 2300 gas
        // will only revert the transaction with the require function.
        // bool sendSuccess = (msg.sender).send(address(this).balnce);
        // require(sendSucess, "Send failed");

        // call (no cap gas) - recommended way to send/receive native tokens
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        // bytes memory dataReturned (beside the bool function) - is not required thus the code in such way
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not owner!");
        //if(msg.sender != i_owner) { revert NotOwner(); } --> Another way to write the require function
        // = set parameter, == check these 2 variables are equivalent
        _;
        // Do this code first before other codes.
        // if _; is before the require funtion, the code will the the rest of the codes first before seeing the require function
    }

    // What happens if someone sends this contract ETH without calling the the fund function.
    receive() external payable {
        fund;
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address - 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Price of ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); //1**10== 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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