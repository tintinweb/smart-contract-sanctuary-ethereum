// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    uint256 public minimumUsd = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;

    constructor(){
      owner = msg.sender;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate() > minimumUsd,
            "Didn't send enough"
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
            funders = new address[](0);
            (bool callSuccess, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");
            require(callSuccess, "Call failed");
        }
    }

    modifier onlyOwner{
      require(msg.sender == owner, "Sender is not owner");
      _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{

    function getPrice() internal view returns (uint256) {
        // ABI
        // 0xA39434A63A52E749F02807ae27335515BA4b07F7
        // AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7)
        //     .version();
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xA39434A63A52E749F02807ae27335515BA4b07F7
        );
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xA39434A63A52E749F02807ae27335515BA4b07F7
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
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