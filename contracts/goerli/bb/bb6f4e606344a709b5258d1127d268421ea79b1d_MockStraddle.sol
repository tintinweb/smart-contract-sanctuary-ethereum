//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {IStraddle, EpochData} from "../interfaces/IStraddle.sol";

contract MockStraddle is IStraddle {
    uint256 public epoch = 1;
    uint256 public expiry = 1663317000;

    uint256 public premium = 6e5 * 1 ether; // $0.6
    uint256 public underlyingPrice = 4500000000; // $45
    uint256 public settledPrice = 3500000000; // $35

    function setSettledPrice(uint256 _price) public {
        settledPrice = _price;
    }

    function setExpiry(uint256 _expiry) public {
        expiry = _expiry;
    }

    function epochData(uint256) external view returns (EpochData memory) {
        return EpochData(0, expiry, 0, 0, settledPrice, 0, 0);
    }

    function setCurrentEpoch(uint256 _epoch) public {
        epoch = _epoch;
    }

    function currentEpoch() public view returns (uint256) {
        return epoch;
    }

    function setPremium(uint256 _premium) external {
        premium = _premium;
    }

    function calculatePremium(
        bool,
        uint256,
        uint256 amount,
        uint256
    ) public view returns (uint256) {
        return (premium * amount) / 1 ether;
    }

    function setPrice(uint256 _price) public {
        underlyingPrice = _price;
    }

    function getUnderlyingPrice() public view returns (uint256) {
        return underlyingPrice;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

struct EpochData {
    // Start time
    uint256 startTime;
    // Expiry time
    uint256 expiry;
    // Total USD deposits
    uint256 usdDeposits;
    // Active USD deposits (used for writing)
    uint256 activeUsdDeposits;
    // Settlement Price
    uint256 settlementPrice;
    // Percentage of total settlement executed
    uint256 settlementPercentage;
    // Amount of underlying assets purchased
    uint256 underlyingPurchased;
}

interface IStraddle {
    function epochData(uint256 epoch) external view returns (EpochData memory);

    function currentEpoch() external view returns (uint256 epoch);

    function calculatePremium(
        bool _isPut,
        uint256 _strike,
        uint256 _amount,
        uint256 _expiry
    ) external view returns (uint256 premium);

    function getUnderlyingPrice() external view returns (uint256 price);
}