// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.7;

// 576.825 gas cost

import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__NotEnoughMoney();
error FundMe__WithdrawalFailed();

/// @title A contract for public funding
/// @author Kyrylo Troiak
/// @notice Basic contract for crowd funding
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract FundMe {
    using StateConverter for uint256;
    uint256 constant MIN_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;
    address private immutable i_OWNER;

    AggregatorV3Interface public s_priceFeed;

    modifier OnlyOwner() {
        if (msg.sender != i_OWNER) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address s_priceFeedAddress) {
        i_OWNER = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if (!(msg.value.getConversionRate(s_priceFeed) >= MIN_USD)) {
            revert FundMe__NotEnoughMoney();
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
        // Get ETH => USD conversion rate
    }

    function withdraw() public OnlyOwner {
        // Resetting mapping
        for (
            uint256 funderIndex = 1;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            s_addressToAmountFunded[s_funders[funderIndex]] = 0;
        }
        // Resetting Array
        s_funders = new address[](0);
        // Withdrawing funds

        // call
        (bool SendSuccess, bytes memory DataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        if (!SendSuccess) {
            revert FundMe__WithdrawalFailed();
        }
    }

    function cheaperWithdraw() public OnlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 1;
            funderIndex < funders.length;
            funderIndex++
        ) {
            s_addressToAmountFunded[funders[funderIndex]] = 0;
        }
        // Resetting Array
        funders = new address[](0);
        s_funders = funders;
        // Withdrawing funds

        // call
        (bool SendSuccess, ) = i_OWNER.call{value: address(this).balance}("");
        if (!SendSuccess) {
            revert FundMe__WithdrawalFailed();
        }
    }

    function getOwner() public view returns (address) {
        return i_OWNER;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library StateConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 Ethprice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (Ethprice * ethAmount) / 1e18;
        return ethAmountInUsd;
        // Adrress 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // ABI
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