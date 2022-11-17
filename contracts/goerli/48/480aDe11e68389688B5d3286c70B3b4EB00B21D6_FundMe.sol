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

// Get funds from users
// Withdraw funds
// Set minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    // set to constant to save gas
    uint256 public constant MINIMUM_USD = 50;

    address[] public funders;

    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;

        // Goerli contract address for chainlink price feed of ETH/USD: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // go to https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol to check out the methods provided in the AggregatorV3Interface.sol code
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // smart contracts can hold funds, just like how wallets can
    // In order to send ETH or any token with a function, we need to declare the function with a 'payable' keyword
    function fund() public payable {
        // to get the value of how much someone is sending in the call to this function. We can only call msg.value when the function declaration has the 'payable' keyword
        require(PriceConverter.getEthAmountInUsd(msg.value, priceFeed) >= MINIMUM_USD * 1e18, "Didn't send enough funds. Minimum is 50 USD in ETH"); // 1e18 = 1 000 000 000 000 000 000 wei = 1 ETH

        // What is reverting?
        // Undo any action before, and send the remaining gas back
        // This means that if the above "require" function fails, it will cancel the transaction, undo any state changes that happens before, and return the remaining gas that would have been needed to execute the operations
        // after the "require" statement

        // msg.sender is the address of the account that calls this function
        funders.push(msg.sender);

        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdrawAll() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];

            // update to 0 first, before making any transactions (prevent re-entrancy)
            addressToAmountFunded[funder] = 0;
        }

        // reset the array with 0 objects in it
        funders = new address[](0);

        // withdraw the funds; there are 3 ways (transfer, send, call)

        // transfer the balance of "this" contract to msg.sender
        // msg.sender is of type address; payable(msg.sender) is of type payable address
        // In solidity, in order to send the native blockchain token, we need to make the receiving address payable
        // payable(msg.sender).transfer(address(this).balance);

        // // send. In transfer, the transaction automatically reverts if fails. However, in send, we need to explicitly define a require statement to revert
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "sending failed");

        // call. Returns two values, the success of the call and a byte array
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");


        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "You must be the owner to execute this function!");

        // saves gas; revert error strings in require is expensive
        if (msg.sender != i_owner) {
            revert NotOwner();
        }

        // the rest of the code in the function that is declared with this modifier
        _;
    }

    // what happens if someone sends this contract ETH withouth calling the fund() function

    // receive
    receive() external payable {
        fund();
    }

    // fallback
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// yarn add --dev @chainlink/contracts
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getEthPriceInUsd(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // ABI (contract)

        (, int256 price, , , ) = priceFeed.latestRoundData();

        // ETH price in USD (8 decimals for Chainlink price feeds). Multiply by 10 to make it consistent with the wei value in fund().
        // msg.value above is also in uint256, so we typecast it accordingly
        return uint256(price * 1e10);
    }

    function getVersion(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        return priceFeed.version();
    }

    function getEthAmountInUsd(uint256 _ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getEthPriceInUsd(priceFeed);

        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;

        return ethAmountInUsd;
    }
}