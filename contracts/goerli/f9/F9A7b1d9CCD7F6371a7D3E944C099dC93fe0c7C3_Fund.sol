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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Fund {
    uint256 constant MINIMUM_VAL = 2;
    address public immutable owner;
    address private immutable pF; // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

    modifier ownerMod() {
        require(owner == msg.sender, "Only owner can withdraw");
        _;
    }

    constructor(address priceFeed) {
        owner = msg.sender;
        pF = priceFeed;
    }

    function fund() public payable {
        require(
            convert(int256(msg.value)) >= MINIMUM_VAL * 1e8,
            "Minimum value requirement condition exists"
        );
    }

    function convert(int256 wi) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(pF);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        answer = (wi * answer) / 1e18;
        return uint256(answer);
    }

    function withdraw() public ownerMod {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}