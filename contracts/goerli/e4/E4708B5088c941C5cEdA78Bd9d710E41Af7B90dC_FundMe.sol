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

// SPDX-License-Identifier: MIT
// Style Guide
// Pragma
pragma solidity ^0.8.0;
// Imports
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/**
 * @title A contract for crowd funding
 * @author Abdulbasit Akingbade
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    // Events
    event Funded(address indexed funder, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        // require(i_owner == msg.sender, "Sender is not the owner");
        if (i_owner != msg.sender) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    // 1. constructor
    // 2. external functions
    // 3. public functions
    // 4. internal functions
    // 5. private functions
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // solidity magic function that gets called when a user sends ether to
    //      the contract adderss without calling the fund function
    // receive function is called when the data parameter is empty
    receive() external payable {
        fund();
    }

    // solidity magic function that gets called when a user sends ether to
    //      the contract adderss without calling the fund function
    // fallback function is called when the data parameter is not empty
    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to send more ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        emit Funded(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        // Send the coin from the contract address wallet to the person's calling this function
        // Can use transfer, send or call
        (bool onSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(onSuccess, "Call failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    /*function getVersion() internal view returns (uint256) {
        // ABI interface and address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );

        return priceFeed.version();
    }*/

    function getConversionRate(
        uint ethAmt,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);

        uint256 ethAmountInUsd = (ethPrice * ethAmt) / 1e18;
        return ethAmountInUsd;
    }
}