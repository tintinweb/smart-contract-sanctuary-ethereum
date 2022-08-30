// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract Wallet {
    // Type Declarations
    using PriceConverter for uint256;

    AggregatorV3Interface private priceFeed;
    address private immutable owner;
    uint256 private balance = 0;
    uint256 private constant minUSD = 50 * 10**9;
    mapping(address => uint256) private sendersAddress;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    function fund() public payable {
        require(
            msg.value.getPriceInUSD(priceFeed) >= minUSD,
            "You need to spend more ETH!"
        );
        sendersAddress[msg.sender] += msg.value;
        balance += msg.value;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        if (_amount > balance) {
            revert("Balance is low !!");
        } else {
            (bool sent, ) = owner.call{value: _amount}("");
            require(sent, "Transaction Failed!!");
            balance -= _amount;
        }
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

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer / 100000000);
    }

    function getPriceInUSD(uint256 ethAmt, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethInUSD = (ethPrice * ethAmt) / 1000000000;

        return ethInUSD;
    }
}