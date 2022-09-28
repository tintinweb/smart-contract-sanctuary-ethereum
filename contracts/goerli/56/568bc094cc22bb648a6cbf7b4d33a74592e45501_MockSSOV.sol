//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {ISSOV, EpochStrikeData, EpochData} from "../interfaces/ISSOV.sol";

contract MockSSOV is ISSOV {
    struct EpochTime {
        uint256 start;
        uint256 end;
    }

    address public token;

    mapping(uint256 => mapping(uint256 => address)) internal epochStrikeTokens;

    mapping(uint256 => EpochTime) internal epochTimes;
    mapping(uint256 => uint256[]) internal epochStrikes;

    uint256 internal epoch = 1;
    uint256 internal volatility = 100;
    uint256 internal premium = 200000000000000000; // 0.2 token
    uint256 internal price = 3500000000; // $35
    mapping(uint256 => address) internal strikeToAddr;
    uint256[] internal strikes;

    constructor(address _token) {
        token = _token;
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

    function getEpochData(uint256 _epoch)
        external
        view
        returns (EpochData memory)
    {
        return
            EpochData(
                false,
                0,
                0,
                0,
                0,
                0,
                0,
                epochStrikes[_epoch],
                new uint256[](0),
                new uint256[](0),
                new address[](0)
            );
    }

    function currentEpoch() public view returns (uint256) {
        return epoch;
    }

    function getCollateralPrice() public view returns (uint256) {
        return price;
    }

    function setVolatility(uint256 _volatility) public {
        volatility = _volatility;
    }

    function getVolatility(uint256) external view returns (uint256) {
        return volatility;
    }

    function collateralPrecision() public pure returns (uint256) {
        return 1e18;
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
        strikeToAddr[_strike] = _token;
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

    function collateralPrecision() external view returns (uint256);

    function getVolatility(uint256) external view returns (uint256);

    function getCollateralPrice() external view returns (uint256);

    function getEpochTimes(uint256 _epoch)
        external
        view
        returns (uint256, uint256);
}