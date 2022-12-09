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

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__notSentEnough();
error FundMe__unexpectedlyWithdrawalFailed();
error FundMe__notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 private constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_funderToAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface private immutable i_priceFeed;

    modifier onlyOwner() {
        if (i_owner != msg.sender) {
            revert FundMe__notOwner();
        }

        _;
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(i_priceFeed) < MINIMUM_USD) {
            revert FundMe__notSentEnough();
        }

        s_funders.push(msg.sender);
        s_funderToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        address[] memory funders = s_funders;

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            s_funderToAmountFunded[funders[funderIndex]] = 0;
        }

        s_funders = new address[](0);

        (bool isSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");

        if (!isSuccess) {
            revert FundMe__unexpectedlyWithdrawalFailed();
        }
    }

    function getMinimumPayment() public pure returns (uint256) {
        return MINIMUM_USD;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 _funderIdx) public view returns (address) {
        return s_funders[_funderIdx];
    }

    function getFundersLen() public view returns (uint256) {
        return s_funders.length;
    }

    function getFunderAmount(address funder) public view returns (uint256) {
        return s_funderToAmountFunded[funder];
    }

    function getPriceFeedAddress() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();

        return uint256(latestPrice * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 latestETHPrice = getPrice(priceFeed);

        uint256 convertedPrice = (latestETHPrice * ethAmount) / 1e18;

        return convertedPrice;
    }
}