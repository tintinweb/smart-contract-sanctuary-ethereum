// Get fund from users
// Withdraw fund
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.8;

// 2. Imports
import "./PriceConverter.sol";
// gas optimization:
//      -> constant, immutable
//      -> custom errors

// 3. Error Codes
error FundMe__NotOwner();

// 4. Interfaces
// 5. Libraries
// 6. Contracts
/**
 * @title A contract for crowd funding
 * @author Marco Villa
 * @notice This contract is to demo a sample running contract
 * @dev This implements price feed as our library
 */
contract FundMe {
    // A. Type Declarations
    using PriceConverter for uint256;

    // B. State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    // 21,415 gas - constant
    // 23,515 gas - non-constant

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    // 21,508 gas - immutable
    // 23,644 gas - non-immutable

    AggregatorV3Interface private s_priceFeed;

    // C. Events
    // D. Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner!"); // not gas efficient
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // E. Functions
    // Functions order:
    // _constructor
    // _receive
    // _fallback
    // _external
    // _public
    // _internal
    // _private
    // _view / pure
    constructor(address _priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(_priceFeedAddress);
        i_owner = msg.sender;
    }

    // // receive() -> if someone sends money (with no data) we process the transaction
    // receive() external payable {
    //     fund();
    // }

    // // fallback() -> if someone sends money to the wrong function (signature)
    // fallback() external payable {
    //     fund();
    // }

    /**
     * @notice This function funds this contract
     * @dev This implements price feed as our library
     * @ param "<param>" explain about the params
     * @ return explain about returning
     */
    function fund() public payable {
        // be able to set a minimum amount in USD
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH!"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        // 18 decimals
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        // starting index, ending condition, step amount
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset array
        s_funders = new address[](0);

        // withdraw the funds
        // 1. transfer
        // msg.sender -> address type | payable(msg.sender) -> payable address type
        // payable(msg.sender).transfer(address(this).balance); // if this call uses more then 2300 gas it throws an error

        // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // if this call uses more then 2300 gas it returns false
        // require(sendSuccess, "Send failed"); // we can revert if false

        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // returns a bool "success" and a bytes "data" variables
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mapping cannot be in memory!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 _index) public view returns (address) {
        return s_funders[_index];
    }

    function getAddressToAmountFunded(address _funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[_funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    // What if someone send ETH to this contract without calling the function fund()?
    // in this way if someone sends Ether without calling the fund function is automatically rerouted to that function
}

// To debug:
// 1. Tinker and try to pinpoint exactly what's going on
// 2. Google the exact error
// 3. Ask a question on a forum like Stack Exchange ETH and Stack Overflow

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// libraries can NOT have state variables
// libraries can NOT send Ether
// all the functions are internal
library PriceConverter {
    function getPrice(AggregatorV3Interface _priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address - 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (
            ,
            /*uint80 roundID*/
            int256 price,
            ,
            ,

        ) = /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            _priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000 -> 8 decimals
        return uint256(price * 1e10); // 1e10 == 1**10 == 10000000000
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        // 3000_0000000000000000000 = ETH / UDS price
        // 1_000000000000000000 ETH
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;
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