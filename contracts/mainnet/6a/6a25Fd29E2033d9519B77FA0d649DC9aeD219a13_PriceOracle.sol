// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {AggregatorV3Interface} from "AggregatorV3Interface.sol";
import {Errors} from "Errors.sol";

interface I3Pool {
    function get_virtual_price() external view returns (uint256);
    function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

interface ITrancheToken {
    function getShareAssets(uint256 _amount) external view returns (uint256);
    function getPricePerShare() external view returns (uint256);
}

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|
// gro protocol: https://github.com/groLabs/GSquared
contract FixedValues {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    ITrancheToken constant PWRD = ITrancheToken(0xF0a93d4994B3d98Fb5e3A2F90dBc2d69073Cb86b);
    ITrancheToken constant GVT = ITrancheToken(0x3ADb04E127b9C0a5D36094125669d4603AC52a0c);

    I3Pool public constant curvePool =
        I3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    uint256 constant DAI_DECIMALS = 1_000_000_000_000_000_000;
    uint256 constant USDC_DECIMALS = 1_000_000;
    uint256 constant USDT_DECIMALS = 1_000_000;
    uint256 constant THREE_CRV_DECIMALS = 1_000_000_000_000_000_000;
    uint256 constant BASE_DECIMALS = 1_000_000_000_000_000_000;
    uint256 constant BASIS_POINTS = 10_000;

    constructor() {}

    function getToken(uint256 _index) public pure returns (address) {
        if (_index == 0) {
            return DAI;
        } else if (_index == 1) {
            return USDC;
        } else if (_index == 2) {
            return USDT;
        } else {
            return THREE_CRV;
        }
    }

    function getDecimal(uint256 _index) public pure returns (uint256) {
        if (_index == 0) {
            return DAI_DECIMALS;
        } else if (_index == 1) {
            return USDC_DECIMALS;
        } else if (_index == 2) {
            return USDT_DECIMALS;
        } else {
            return THREE_CRV_DECIMALS;
        }
    }
}

contract PriceOracle is FixedValues {
    uint256 constant CHAINLINK_FACTOR = 1_00_000_000;
    uint256 constant NO_OF_AGGREGATORS = 3;
    uint256 constant STALE_CHECK = 86_400; // 24 Hours

    address public immutable daiUsdFeed;
    address public immutable usdcUsdFeed;
    address public immutable usdtUsdFeed;

    constructor(address[NO_OF_AGGREGATORS] memory aggregators) {
        daiUsdFeed = aggregators[0];
        usdcUsdFeed = aggregators[1];
        usdtUsdFeed = aggregators[2];
    }

    function deposit(uint256 _amount, uint256 _slippage, uint256 _index, bool _tranche) external view returns (uint256, uint256, uint256) {
        uint256 dollarValue;
        uint256 minAmount;
        if (_index == 3) {
            dollarValue = _amount * curvePool.get_virtual_price() / THREE_CRV_DECIMALS;
            minAmount = dollarValue * (BASIS_POINTS - _slippage) / BASIS_POINTS;
        } else {
            uint256[3] memory amounts;
            amounts[_index] = _amount;
            dollarValue = curvePool.calc_token_amount(amounts, true) * curvePool.get_virtual_price() / BASE_DECIMALS;
            minAmount = stableToUsd(_amount, _index) * (BASIS_POINTS - _slippage) / BASIS_POINTS;
        }
        uint256 tokenAmounts = _tranche ? dollarValue * BASE_DECIMALS / PWRD.getPricePerShare() : dollarValue * BASE_DECIMALS / GVT.getPricePerShare();
        minAmount = _tranche ? minAmount * BASE_DECIMALS / PWRD.getPricePerShare() : minAmount * BASE_DECIMALS / GVT.getPricePerShare();
        return (tokenAmounts, minAmount, dollarValue);
    }

    function withdraw(uint256 _amount, uint256 _slippage, uint256 _index, bool _tranche) external view returns (uint256, uint256, uint256) {
        uint256 dollarValue = _tranche ? PWRD.getShareAssets(_amount) : GVT.getShareAssets(_amount);
        uint256 tokenValue = dollarValue * BASE_DECIMALS / curvePool.get_virtual_price();
        uint256 minAmount;
        if (_index == 3) {
            minAmount = tokenValue * (BASIS_POINTS - _slippage) / BASIS_POINTS;
        } else {
            tokenValue = curvePool.calc_withdraw_one_coin(tokenValue, int128(int256(_index)));
            minAmount = usdToStable(dollarValue, _index) * (BASIS_POINTS - _slippage) / BASIS_POINTS;
            dollarValue = stableToUsd(tokenValue, _index);
        }
        return (tokenValue, minAmount, dollarValue);
    }

    /// @notice Get estimate USD price of a stablecoin amount
    /// @param _amount Token amount
    /// @param _index Index of token
    function stableToUsd(uint256 _amount, uint256 _index)
        internal
        view
        returns (uint256)
    {
        if (_index == 3)
            return (curvePool.get_virtual_price() * _amount) / THREE_CRV_DECIMALS;
        (uint256 price, ) = getPriceFeed(_index);
        return (_amount * price) / CHAINLINK_FACTOR * (BASE_DECIMALS / getDecimal(_index));
    }

    /// @notice Get LP token value of input amount of single token
    function usdToStable(uint256 _amount, uint256 _index)
        internal
        view
        returns (uint256)
    {
        if (_index == 3)
            return (THREE_CRV_DECIMALS * _amount) / curvePool.get_virtual_price();
        (uint256 price, ) = getPriceFeed(_index);
        return (_amount * CHAINLINK_FACTOR) / price / (BASE_DECIMALS / getDecimal(_index));
    }

    /// @notice Get price from aggregator
    /// @param _index Stablecoin to get USD price for
    function getPriceFeed(uint256 _index)
        internal
        view
        returns (uint256, bool)
    {
        (, int256 answer, , uint256 updatedAt, ) = AggregatorV3Interface(
            getAggregator(_index)
        ).latestRoundData();
        return (uint256(answer), staleCheck(updatedAt));
    }

    function staleCheck(uint256 _updatedAt) internal view returns (bool) {
        return (block.timestamp - _updatedAt >= STALE_CHECK);
    }

    /// @notice Get USD/Stable coin chainlink feed
    /// @param _index index of feed based of stablecoin index (dai/usdc/usdt)
    function getAggregator(uint256 _index) internal view returns (address) {
        if (_index >= NO_OF_AGGREGATORS) revert Errors.IndexTooHigh();
        if (_index == 0) {
            return daiUsdFeed;
        } else if (_index == 1) {
            return usdcUsdFeed;
        } else {
            return usdtUsdFeed;
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

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

library Errors {
    // Common
    error AlreadyMigrated(); // 0xca1c3cbc
    error AmountIsZero(); // 0x43ad20fc
    error ChainLinkFeedStale(); //0x3bc80ea6
    error IndexTooHigh(); // 0xfbf22ac0
    error IncorrectSweepToken(); // 0x25371b04
    error LTMinAmountExpected(); //less than 0x3d93e699
    error NotEnoughBalance(); // 0xad3a8b9e
    error ZeroAddress(); //0xd92e233d
    error MinDeposit(); //0x11bcd830

    // GMigration
    error TrancheAlreadySet(); //0xe8ce7222
    error TrancheNotSet(); //0xc7896cf2

    // GTranche
    error UtilisationTooHigh(); // 0x01dbe4de
    error MsgSenderNotTranche(); // 0x7cda3092
    error NoAssets(); // 0x5373815f

    // GVault
    error InsufficientShares(); // 0x39996567
    error InsufficientAssets(); // 0x96d80433
    error IncorrectStrategyAccounting(); //0x7b6d99a5
    error IncorrectVaultOnStrategy(); //0x7408aa63
    error OverDepositLimit(); //0xbf41e3d0
    error StrategyActive(); // 0xebb33d91
    error StrategyNotActive(); // 0xdc974a98
    error StrategyDebtNotZero(); // 0x332c333c
    error StrategyLossTooHigh(); // 0xa9aba8bd
    error VaultDebtRatioTooHigh(); //0xf6f34eca
    error VaultFeeTooHigh(); //0xb6659cb6
    error ZeroAssets(); //0x32d971dc
    error ZeroShares(); //0x9811e0c7

    //Whitelist
    error NotInWhitelist(); // 0x5b0aa2ba
}