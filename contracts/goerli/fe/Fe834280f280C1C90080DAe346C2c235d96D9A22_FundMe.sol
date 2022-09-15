//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256; // library for uint256

    uint256 public number;
    uint256 public constant MINIMUM_USD = 50 * 10**18; // keyword "constant" cuz it's not changing its value

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
    // constant and immutable keywords are used for saving gas

    AggregatorV3Interface public priceFeed; //an interface that compiled down gives an ABI

    //'constructor' a function that it's runned as soon as someone deploy the contract
    constructor(address priceFeedAddress) {
        // now, in this priceFeedAddress, we store the address of the chain that we're on
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress); // ABI(address) = contract
    }

    function fund() public payable {
        number = 5;
        //if the condition ins't true, this message will be printed
        //AND all the actions that happend in the function will be reverted

        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); // <-how to reset an array to blank

        /*
        // How to actually withdraw the funds:
        
        //transfer -> automatically revertes if it exceedes 2300 gas
        payable(msg.sender).transfer(address(this).balance); 

        // send -> send a boolean whether txn exceeds 2300 or not, but it's not revertable
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed!");
        */

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
    }

    modifier onlyOwner() {
        //creates a keyword that can be added to any function in order to do smth that we want
        //require(msg.sender == i_owner, "Sender is not owner!");
        // OR (a more efficient way to save gas)
        if (msg.sender != i_owner) revert NotOwner();
        _; // <- that symbolise the rest of the code
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract and no function was specified:
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed // this is AggregatorV3Interface(priceFeedAddress)
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
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