// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__FewMoney();
error FundMe__NotOwner();

/**
 * @title this contract feeds data prices
 * @dev dsckjdwckwcwc
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMAL_USD = 1 * 1e18;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToFundersIndex;

    address payable private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address s_priceFeedAddress) {
        i_owner = payable(msg.sender);
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if (msg.value.convertValueToUsd(s_priceFeed) < MINIMAL_USD) {
            revert FundMe__FewMoney();
        }
        if (s_addressToFundersIndex[msg.sender] == 0) {
            s_funders.push(msg.sender);
            s_addressToFundersIndex[msg.sender] = s_funders.length;
        }
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            s_addressToAmountFunded[funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool successCall, ) = i_owner.call{value: address(this).balance}("");
        require(successCall, "not successful");
    }

    function getAddressToAmountFunded(address addr)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[addr];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToFundersIndex(address addr)
        public
        view
        returns (uint256)
    {
        return s_addressToFundersIndex[addr];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function convertValueToUsd(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256 usdAmount) {
        uint256 ethPrice = getPrice(priceFeed);
        usdAmount = (ethPrice * ethAmount) / 1e18;
    }

    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // int256 price = 110000000000;
        return uint256(price * 1e10);
    }
}