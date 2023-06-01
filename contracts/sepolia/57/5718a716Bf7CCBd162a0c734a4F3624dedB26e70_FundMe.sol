// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PriceConvertor.sol";

error NotEnough();
error CallFailed();
error NotOwner();

contract FundMe {
    using PriceConvertor for uint256;

    uint256 private constant MINIMUM_USD = 50 * 1e18;
    address public immutable i_owner;
    address[] public funders;
    mapping(address => uint256) public addressToAmountUsd; 
    event FundIn(address funder, uint256 amountUsd);
    event Withdraw(address _to, uint256 amount);

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function fund() public payable {
        if (msg.value.priceConvertionRate(priceFeed) <= MINIMUM_USD)
            revert NotEnough();
        funders.push(msg.sender);
        addressToAmountUsd[msg.sender] = msg.value;
        emit FundIn(msg.sender, msg.value);
    }

    function withdraw() public {
        for (uint256 i; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountUsd[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = payable(i_owner).call{value: address(this).balance}(
            ""
        );
        if (!success) revert CallFailed();
        emit Withdraw(msg.sender, address(this).balance);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = _priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function priceConvertionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256 ethAmountToUsd) {
        uint256 ethPrice = getPrice(_priceFeed);
        ethAmountToUsd = (ethPrice * _ethAmount) / 1e18;
    }
}