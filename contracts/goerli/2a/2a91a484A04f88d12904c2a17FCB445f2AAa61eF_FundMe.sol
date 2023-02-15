// Get funds from users
// withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    //uint256 public number;
    uint256 public constant MINIMUM_USD = 50 * 1e18; //constant because it is assigned once at compile time and never changes.
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner; //immutable = variables that we set one time but outside of where they have been declared (see constructor)
    AggregatorV3Interface public priceFeed;

    // constant and immutable variables are directly stored in the bytecode instead of a storage slot => cheaper
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    address[] public funders;

    function fund() public payable {
        //want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract? (value parameter in Remix!)
        //number = 5;
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        // require(getConversionRate(msg.value) >= MINIMUM_USD, "Didn't send enough!"); //1e18== 1* 10**18
        //if require is not met any prior work will be undone => however we have to pay the gas for computations afterwards.
        // 18 decimals
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        /*starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            // or funderIndex++
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0); //brand new funders array with 0 objects in it
        // actually withdraw the funds

        //transfer, send, call. --> transfer to whoever is calling the function withdraw

        //msg.sender = type of address
        //payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);
        //transfer is capped at 2300 gas => throws an error if it goes above. => transfer automatically reverts if the transfer fails.
        //send is also capped at 2300 gas => if it fails it returns a boolean. => with send it won't throw an error. it returns a bool whether it was successfull or not
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed"); // send only reverts the transaction if we add a require statement.
        // call
        // with call we can call functions without even having the ABI.
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}(""); //blank "" if we do not want to call any function
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    //receive and fallback are useful when someone sends funds to our contract accidentaly without calling directly the fund function
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

// libriaries cant have any state variables and cant send any ether. All fcts are internal
library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI and Address needed to interact with contract from outside
        // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e Goerli Testnet ETH USD
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //   0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //); // if you match the ABI with an address you get a contract!
        (, int price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD above
        // 3000.00000000
        return uint256(price * 1e10); // 1**10
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
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