//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner(); // throw a error, used like require, the difference is that save gas

/**
 * @author Rodrigo
 * @title  A contract to crowd funding
 * @notice This contract is to demo a sample funding contract
 * @dev this implements price feeds as our library
 */

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // Minimum USD value that we will afford tu use the fund function

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // those function does not have the function keyword and needs to be external and payable
    receive() external payable {
        // special function needed so we can send eth without calling the normal functions
        // only used if we doesn't send any data
        fund();
    }

    fallback() external payable {
        // used only if not exist a receive function and if we send any data besides the ether
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev this implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need at least 50 dol in ethers"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        // We need to empty all addresses, so we use a for to iterate in all indexes
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funderAdress = funders[funderIndex]; // we create a variable address to access the address of the array
            addressToAmountFunded[funderAdress] = 0; // we set to zero the value
        }
        funders = new address[](0); // a brand new address array with zero objects in it to ( a completely blank new array )
        // to withdraw the funds we have 3 options: transfer, call, send
        /*
        // the transfer function with fail throws a error
        payable(msg.sender).transfer(address(this).balance); // to receive ether the address variable needs to be payable

        // the send function returns a bool, so we need to check if a require statement
        boll sendSucess = payable(msg.sender).send(address(this).balance);
        require(sendSucess, "Send failed!");*/

        // the call function returns two paramers, a bool and a bytes data (if call a function that returns data)
        (
            bool callSucess, /* bytes memory dataReturned */

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSucess, "Call failed!");
        // For some reason that I don't know yet, the call function is the best way to send ether
    }
}

//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// MAXIMUM
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // To access the ChainLink contract ETH/USD Updated price, we need the ABI and the address of the contract
        // the address for the goerli teste net can be founded at: https://docs.chain.link/docs/ethereum-addresses/
        // THe address is: 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10); // the value come with 8 decimals besides the original value, so we need to multiply by e10 to have the 18 decimals.
        // also is needed to typecasting to uint256 because the msg.sender has the uint256 type
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