//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

import {ISSOV, EpochStrikeData, EpochData} from "../interfaces/ISSOV.sol";

contract MockSSOV is ISSOV {
    struct EpochTime {
        uint256 start;
        uint256 end;
    }

    address public token;

    mapping(uint256 => mapping(uint256 => address)) public epochStrikeTokens;

    mapping(uint256 => EpochTime) public epochTimes;
    mapping(uint256 => uint256[]) public epochStrikes;

    uint256 public epoch = 1;
    uint256 public premium = 200000000000000000; // 0.2 token
    uint256 public price = 3500000000; // $35
    mapping(uint256 => address) public strikeToAddr;
    uint256[] public strikes;

    constructor(address _token) {
        token = _token;
    }

    function setStrikeToken(uint256 _strike, address _strikeAddr) public {
        strikeToAddr[_strike] = _strikeAddr;
        strikes.push(_strike);
    }

    function getEpochStrikeData(uint256, uint256 _strike)
        external
        view
        returns (EpochStrikeData memory)
    {
        return
            EpochStrikeData(
                strikeToAddr[_strike],
                0,
                0,
                0,
                0,
                new uint256[](0),
                new uint256[](0)
            );
    }

    function getEpochData(uint256) external view returns (EpochData memory) {
        return
            EpochData(
                false,
                0,
                0,
                0,
                0,
                0,
                0,
                strikes,
                new uint256[](0),
                new uint256[](0),
                new address[](0)
            );
    }

    function currentEpoch() public view returns (uint256) {
        return epoch;
    }

    function calculatePremium(
        uint256,
        uint256 amount,
        uint256
    ) public view returns (uint256) {
        return (premium * amount) / 1 ether;
    }

    function getCollateralPrice() public view returns (uint256) {
        return price;
    }

    function setCurrentEpoch(uint256 _epoch) public {
        epoch = _epoch;
    }

    function setPrice(uint256 _price) public {
        price = _price;
    }

    function setEpochStrikeTokens(
        uint256 _epoch,
        uint256 _strike,
        address _token
    ) public returns (bool) {
        epochStrikeTokens[_epoch][_strike] = _token;
        epochStrikes[_epoch].push(_strike);
        return true;
    }

    function setEpochTimes(
        uint256 _epoch,
        uint256 start,
        uint256 end
    ) public returns (bool) {
        epochTimes[_epoch] = EpochTime(start, end);
        return true;
    }

    function getEpochTimes(uint256 _epoch)
        public
        view
        returns (uint256, uint256)
    {
        return (epochTimes[_epoch].start, epochTimes[_epoch].end);
    }

    function setPremium(uint256 _premium) external {
        premium = _premium;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

struct EpochStrikeData {
    address strikeToken;
    uint256 totalCollateral;
    uint256 activeCollateral;
    uint256 totalPremiums;
    uint256 checkpointPointer;
    uint256[] rewardStoredForPremiums;
    uint256[] rewardDistributionRatiosForPremiums;
}

struct EpochData {
    bool expired;
    uint256 startTime;
    uint256 expiry;
    uint256 settlementPrice;
    uint256 totalCollateralBalance; // Premium + Deposits from all strikes
    uint256 collateralExchangeRate; // Exchange rate for collateral to underlying (Only applicable to CALL options)
    uint256 settlementCollateralExchangeRate; // Exchange rate for collateral to underlying on settlement (Only applicable to CALL options)
    uint256[] strikes;
    uint256[] totalRewardsCollected;
    uint256[] rewardDistributionRatios;
    address[] rewardTokensToDistribute;
}

interface ISSOV {
    function getEpochStrikeData(uint256 epoch, uint256 strike)
        external
        view
        returns (EpochStrikeData memory);

    function getEpochData(uint256 epoch)
        external
        view
        returns (EpochData memory);

    function currentEpoch() external view returns (uint256);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount,
        uint256 _expiry
    ) external view returns (uint256 premium);

    function getCollateralPrice() external view returns (uint256);

    function getEpochTimes(uint256 _epoch)
        external
        view
        returns (uint256, uint256);
}