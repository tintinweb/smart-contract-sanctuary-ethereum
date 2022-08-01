// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error Funding__NotOwner();

contract Funding {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 10**18;
    address private immutable _owner;
    address[] private _funders;
    mapping(address => uint256) private _addressToAmountFunded;
    AggregatorV3Interface private _priceFeed;

    modifier onlyOwner() {
        if (msg.sender != _owner) revert Funding__NotOwner();
        _;
    }

    constructor(address priceFeed) {
        _priceFeed = AggregatorV3Interface(priceFeed);
        _owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate(_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");

        _addressToAmountFunded[msg.sender] += msg.value;
        _funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < _funders.length; funderIndex++) {
            address funder = _funders[funderIndex];
            _addressToAmountFunded[funder] = 0;
        }
        _funders = new address[](0);

        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = _funders;

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            _addressToAmountFunded[funder] = 0;
        }
        _funders = new address[](0);

        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success);
    }

    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return _addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return _priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return _funders[index];
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return _priceFeed;
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
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;

        return ethAmountInUsd;
    }
}