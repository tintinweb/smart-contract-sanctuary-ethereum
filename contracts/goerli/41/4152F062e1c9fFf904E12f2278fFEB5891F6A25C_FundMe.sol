// SPDX-License-Identifier: MIT

////////////////////////////////
/// Lesson 7: hardhat Fund Me //
////////////////////////////////

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

    error FundMe__NotOwner();
    error FundMe__TransferFailed();
    error FundMe__NotEnoughFund();

// @title A contract for crowdfunding
// @author Maciej Czekaj
// @notice This contact is to demo a sample funding contract
// @dev This implements price feeds as our library
contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(AggregatorV3Interface _priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = _priceFeedAddress;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function withdraw() external onlyOwner {
        address[] memory funders = s_funders;

        for (uint256 index = 0; index < funders.length; index++) {
            s_addressToAmountFunded[funders[index]] = 0;
        }

        s_funders = new address[](0);

        // There are 3 ways to transfer eth: transfer/send/call

        // transfer: uses max 2300 gas, throws error on failure
        // payable(msg.sender).transfer(address(this).balance);

        // send: uses max 2300 gas, returns bool if succesful;
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call: forward all gas or set gas, returns bool and data. It's cheaper (2100 gas?) but doesn't protect against reentrancy attacks. It's recommended when transfering ether and should be avoided when calling other functions.
        // solhint-disable-next-line avoid-low-level-calls
        (bool callSuccess,) = payable(msg.sender).call{value : address(this).balance}("");
        if (!callSuccess) {
            revert FundMe__TransferFailed();
        }
    }

    // @notice This function funds this contract
    // @dev This implements price feeds as our library
    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughFund();
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (address) {
        return address(s_priceFeed);
    }
}

// SPDX-License-Identifier: MIT

////////////////////////////////
/// Lesson 7: Hardhat Fund Me //
////////////////////////////////

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Address for Rinkeby
library PriceConverter {
    function getPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (,int256 price,,,) = _priceFeed.latestRoundData();
        return uint256(price * 1e10);
        // ETH in terms of USD
    }

    // How much worth in USD is passed eth
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        return (ethPrice * ethAmount) / 1e18;
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