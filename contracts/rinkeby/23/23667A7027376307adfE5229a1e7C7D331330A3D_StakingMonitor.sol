//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

import "AggregatorV3Interface.sol";

error StakeMonitor__UpkeepNotNeeded();
error StakeMonitor__TransferFailed();
error StakingMonitor__UpperBond_SmallerThan_LowerBound();

struct userInfo {
    uint256 balance;
    uint256 DAIBalance;
    uint256 priceUpperBound;
    uint256 priceLowerBound;
}

contract StakingMonitor {
    mapping(address => userInfo) public s_userInfos;
    address[] s_addresses;
    event Deposited(address indexed user);
    AggregatorV3Interface public priceFeed;

    uint256 public s_lowestUpperBound;
    uint256 public s_highestLowerBound;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function deposit() external payable {
        s_userInfos[msg.sender].balance =
            s_userInfos[msg.sender].balance +
            msg.value;
        s_addresses.push(msg.sender);
        emit Deposited(msg.sender);
    }

    function setPriceBounds(uint256 _priceUpperBound, uint256 _priceLowerBound)
        external
    {
        if (_priceUpperBound < _priceLowerBound) {
            revert StakingMonitor__UpperBond_SmallerThan_LowerBound();
        }

        _priceLowerBound = _priceLowerBound * 100000000;
        _priceUpperBound = _priceUpperBound * 100000000;

        s_userInfos[msg.sender].priceUpperBound = _priceUpperBound;
        s_userInfos[msg.sender].priceLowerBound = _priceLowerBound;

        // set lowest upper bound
        if (
            (s_lowestUpperBound == 0) || (s_lowestUpperBound > _priceUpperBound)
        ) {
            s_lowestUpperBound = _priceUpperBound;
        }

        // set highest lower bound
        if (
            (s_highestLowerBound == 0) ||
            (s_highestLowerBound < _priceLowerBound)
        ) {
            s_highestLowerBound = _priceLowerBound;
        }
    }

    function calculatePriceRange() public view returns (bool) {
        uint price = getPrice();
        bool upkeepNeeded = (price < s_lowestUpperBound &&
            price > s_highestLowerBound);
        return upkeepNeeded;
    }

    function checkUpkeep(
        bytes memory /*checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // upkeepNeeded: if price between one of the brackets
        uint price = getPrice();
        upkeepNeeded = (price < s_lowestUpperBound &&
            price > s_highestLowerBound);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert StakeMonitor__UpkeepNotNeeded();
        }
        // perform upkeep
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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