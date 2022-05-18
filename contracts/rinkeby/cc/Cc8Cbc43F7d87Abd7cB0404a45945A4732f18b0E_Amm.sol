// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;
import "hardhat/console.sol";

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Metadata } from "../interface/IERC20Metadata.sol";
import { IAmm } from "../interface/IAmm.sol";
import { SigmaMath } from "../lib/SigmaMath.sol";
import { AmmLib } from "../lib/AmmLib.sol";
import { BlockContext } from "../base/BlockContext.sol";
import { OwnerPausable } from "../base/OwnerPausable.sol";
import { AmmStorageV1 } from "../storage/AmmStorage.sol";

contract Amm is IAmm, AmmStorageV1, BlockContext, OwnerPausable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using SigmaMath for uint256;
    using SigmaMath for int256;

    /// @notice This struct is used for avoiding stack too deep error
    struct InternalAddLiquidityAstp {
        uint256[2] AGamma;
        uint256[2] xp;
        uint256 oldD;
        uint256[2] xpOld;
    }

    /// @notice This struct is used for avoiding stack too deep error
    struct InternalSwapAstp {
        uint256[2] AGamma;
        uint256[2] xp;
        uint256 p;
        uint256 dy;
        uint256 y;
        uint256 x0;
        uint256 preci;
        uint256 precj;
    }

    function initialize(InitializeParams memory params) external initializer {
        __OwnerPausable_init();
        __ReentrancyGuard_init();

        // Pack A and gamma:
        // shifted A + gamma
        uint256 AGamma = SigmaMath.shift(params.A, 128);
        AGamma = SigmaMath.bitwiseOr(AGamma, params.gamma);
        _globalInitializeParams.initialAGamma = AGamma;
        _globalFutureParams.futureAGamma = AGamma;

        _globalInitializeParams.adjustmentStep = params.adjustmentStep;
        _globalInitializeParams.maHalfTime = params.maHalfTime;

        _priceScale = params.initialPrice;
        _priceOracle = params.initialPrice;
        _priceLast = params.initialPrice;

        _priceLastTimestamp = _blockTimestamp();

        _coinPairs = [params.quoteToken, params.baseToken];

        _coinPrecisions = [
            10**(18 - IERC20Metadata(_coinPairs[0]).decimals()),
            10**(18 - IERC20Metadata(_coinPairs[1]).decimals())
        ];

        _clearingHouse = params.clearingHouse;
        _marketTaker = params.marketTaker;
        _liquidityProvider = params.liquidityProvider;
    }

    function swap(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 dyLimit,
        bool isExactInput
    ) external override whenNotPaused nonReentrant returns (uint256) {
        // AM_OMT: only MarketTaker
        require(_marketTaker == _msgSender(), "AM_OMT");
        return _swap(i, j, dx, dyLimit, isExactInput, false);
    }

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 minLiquidity
    )
        external
        override
        whenNotPaused
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // AM_OLP: only LiquidityProvider
        require(_liquidityProvider == _msgSender(), "AM_OLP");
        // AM_QZ: quote amount is zero
        require(amount0Desired > 0, "AM_QA0");
        // AM_BZ: base amount is zero
        require(amount1Desired > 0, "AM_BA0");
        // AM_MLLZ: min liquidity less than zero
        require(minLiquidity >= 0, "AM_MLL0");

        uint256[N_COINS] memory amounts = [amount0Desired, amount1Desired];
        if (_coinBalances[0] != 0 && _coinBalances[1] != 0) {
            amounts[1] = quote(amount0Desired, _coinBalances[0], _coinBalances[1]);
            if (amounts[1] <= amount1Desired) {
                // require(amounts[1] >= amountBMin, "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
                (amounts[0], amounts[1]) = (amount0Desired, amounts[1]);
            } else {
                amounts[0] = quote(amount1Desired, _coinBalances[1], _coinBalances[0]);
                assert(amounts[0] <= amount0Desired);
                // require(amountAOptimal >= amountAMin, "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
                (amounts[0], amounts[1]) = (amounts[0], amount1Desired);
            }
        } else {
            uint256 priceCurrent = getPriceCurrent();
            // AM_IBIA: imbalance initial amount
            require(amount0Desired == (amount1Desired * priceCurrent) / 1e18, "AM_IBIA");
        }

        InternalAddLiquidityAstp memory al;
        al.AGamma = _getAGamma();
        al.xp = SigmaMath.copy(_coinBalances);
        al.xpOld = SigmaMath.copy(al.xp);

        for (uint8 i = 0; i < N_COINS; i++) {
            uint256 bal = al.xp[i] + amounts[i];
            al.xp[i] = bal;
            _coinBalances[i] = bal;
        }

        uint256 priceScaleTemp = _priceScale * _coinPrecisions[1];
        al.xp = [al.xp[0] * _coinPrecisions[0], (al.xp[1] * priceScaleTemp) / PRECISION];
        al.xpOld = [al.xpOld[0] * _coinPrecisions[0], (al.xpOld[1] * priceScaleTemp) / PRECISION];

        for (uint8 i = 0; i < N_COINS; i++) {
            if (amounts[i] > 0) {
                IERC20Upgradeable(_coinPairs[i]).transferFrom(_clearingHouse, address(this), amounts[i]);
            }
        }

        uint256 t = _globalFutureParams.futureAGammaTime;
        if (t > 0) {
            al.oldD = AmmLib.newtonD(al.AGamma[0], al.AGamma[1], al.xpOld);
            if (_blockTimestamp() >= t) {
                _globalFutureParams.futureAGammaTime = 1;
            }
        } else {
            al.oldD = _globalD;
        }

        uint256 newD = AmmLib.newtonD(al.AGamma[0], al.AGamma[1], al.xp);

        uint256 liquidity;
        if (al.oldD > 0) {
            liquidity = (_totalLiquidity * newD) / al.oldD - _totalLiquidity;
        } else {
            liquidity = _getXcp(newD); // making initial virtual price equal to 1
        }

        // AM_NM: nothing minted
        require(liquidity > 0, "AM_NM");

        _totalLiquidity += liquidity;
        if (al.oldD > 0) {
            _tweakPrice(al.AGamma, al.xp, 0, newD);
        } else {
            _globalD = newD;
        }

        // AM_OSPWAL: over slippage protection when add liquidity
        require(liquidity >= minLiquidity, "AM_OSPWAL");

        emit AddLiquidity(_msgSender(), amounts[0], amounts[1], liquidity, _totalLiquidity);

        return (amounts[0], amounts[1], liquidity);
    }

    function removeLiquidity(
        uint256 liquidity,
        uint256 minAmount0,
        uint256 minAmount1
    ) public override whenNotPaused nonReentrant returns (uint256 amount0, uint256 amount1) {
        // AM_OLP: only LiquidityProvider
        require(_liquidityProvider == _msgSender(), "AM_OLP");
        // AM_LIZ: liquidity is zero
        require(liquidity > 1, "AM_LIZ");
        // AM_LO: liquidity overflow
        require(liquidity <= _totalLiquidity, "AM_LOF");

        // This withdrawal method is very safe, does no complex math
        uint256 totalSupply = _totalLiquidity;
        _totalLiquidity -= liquidity;

        // Make rounding errors favoring other LPs a tiny bit
        uint256 calcLiquidity = liquidity - 1;

        uint256[N_COINS] memory tokenAmounts = SigmaMath.copy(_coinBalances);
        for (uint8 i = 0; i < N_COINS; i++) {
            uint256 tokenAmount = (tokenAmounts[i] * calcLiquidity) / totalSupply;
            // AM_OSPWRL: over slippage protection when remove liquidity
            require(tokenAmount >= (i == 0 ? minAmount0 : minAmount1), "AM_OSPWRL");

            _coinBalances[i] = tokenAmounts[i] - tokenAmount;
            tokenAmounts[i] = tokenAmount; // now it's the amounts going out

            IERC20Upgradeable(_coinPairs[i]).transfer(_clearingHouse, tokenAmount);
        }

        if (_totalLiquidity != 0) {
            _globalD = _globalD - (_globalD * calcLiquidity) / totalSupply;
        } else {
            _globalD = 0;
        }

        emit RemoveLiquidity(_msgSender(), tokenAmounts[0], tokenAmounts[1], liquidity, _totalLiquidity);

        return (tokenAmounts[0], tokenAmounts[1]);
    }

    /**
     * External View Functions
     */

    function getDy(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isExactInput
    ) public view override returns (uint256) {
        // AM_SCI: same coin index
        require(i != j, "AM_SCI");
        // AM_CIOOR: coin index out of range
        require(i < N_COINS, "AM_CIOOR");
        // AM_CIOOR: coin index out of range
        require(j < N_COINS, "AM_CIOOR");

        uint256 priceScaleTemp = _priceScale * _coinPrecisions[1];
        uint256[N_COINS] memory xp = SigmaMath.copy(_coinBalances);
        uint256[2] memory AGamma = _getAGamma();
        uint256 D = _globalD;

        if (_globalFutureParams.futureAGammaTime > 0) {
            D = AmmLib.newtonD(AGamma[0], AGamma[1], _getXp());
        }

        xp[i] = isExactInput ? xp[i] + dx : xp[i] - dx;
        xp = [xp[0] * _coinPrecisions[0], (xp[1] * priceScaleTemp) / PRECISION];

        uint256 y = AmmLib.newtonY(AGamma[0], AGamma[1], xp, D, j);

        uint256 dy = isExactInput ? (xp[j] - y - 1) : (y - xp[j] + 1);

        xp[j] = y;

        if (j > 0) {
            dy = (dy * PRECISION) / priceScaleTemp;
        } else {
            dy /= _coinPrecisions[0];
        }

        return dy;
    }

    function calcTokenAmountsByLiquidity(uint256 liquidity)
        external
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        // AM_LZ: liquidity is zero
        require(liquidity > 1, "AM_LZ");
        // AM_TLZ: total liquidity is zero
        require(_totalLiquidity > 0, "AM_TLZ");
        // AM_LO: liquidity overflow
        require(liquidity <= _totalLiquidity, "AM_LOF");

        // Make rounding errors favoring other LPs a tiny bit
        liquidity = liquidity - 1;

        uint256[N_COINS] memory tokenAmounts;
        for (uint8 i = 0; i < N_COINS; i++) {
            tokenAmounts[i] = (_coinBalances[i] * liquidity) / _totalLiquidity;
        }

        return (tokenAmounts[0], tokenAmounts[1]);
    }

    function calcLiquidityByTokenAmounts(uint256 amount0Desired, uint256 amount1Desired)
        external
        view
        override
        returns (uint256)
    {
        // AM_CQA0: calculate quote amount is zero
        require(amount0Desired > 0, "AM_CQA0");
        // AM_CBA0: calculate base amount is zero
        require(amount1Desired > 0, "AM_CBA0");

        uint256[N_COINS] memory amounts = [amount0Desired, amount1Desired];
        if (_coinBalances[0] != 0 && _coinBalances[1] != 0) {
            amounts[1] = quote(amount0Desired, _coinBalances[0], _coinBalances[1]);
            if (amounts[1] <= amount1Desired) {
                (amounts[0], amounts[1]) = (amount0Desired, amounts[1]);
            } else {
                amounts[0] = quote(amount1Desired, _coinBalances[1], _coinBalances[0]);
                assert(amounts[0] <= amount0Desired);
                (amounts[0], amounts[1]) = (amounts[0], amount1Desired);
            }
        } else {
            // AM_CIBIA: calculate imbalance initial amount
            require(amount0Desired == (amount1Desired * getPriceCurrent()) / 1e18, "AM_CIBIA");
        }

        uint256[2] memory AGamma = _getAGamma();
        uint256[2] memory xp = SigmaMath.copy(_coinBalances);
        uint256[2] memory xpOld = SigmaMath.copy(xp);

        for (uint8 i = 0; i < N_COINS; i++) {
            uint256 bal = xp[i] + amounts[i];
            xp[i] = bal;
        }

        xp = [xp[0] * _coinPrecisions[0], (xp[1] * _priceScale * _coinPrecisions[1]) / PRECISION];
        xpOld = [xpOld[0] * _coinPrecisions[0], (xpOld[1] * _priceScale * _coinPrecisions[1]) / PRECISION];

        uint256 oldD;
        uint256 t = _globalFutureParams.futureAGammaTime;
        if (t > 0) {
            oldD = AmmLib.newtonD(AGamma[0], AGamma[1], xpOld);
        } else {
            oldD = _globalD;
        }

        uint256 newD = AmmLib.newtonD(AGamma[0], AGamma[1], xp);

        uint256 liquidity;
        if (oldD > 0) {
            liquidity = (_totalLiquidity * newD) / oldD - _totalLiquidity;
        } else {
            liquidity = _getXcp(newD);
        }

        // AM_CNM: calculate nothing minted
        require(liquidity > 0, "AM_CNM");

        return liquidity;
    }

    function simulatedSwapInternal(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 dyLimit,
        bool isExactInput
    ) external returns (uint256) {
        // AM_OAM: only Amm
        require(_msgSender() == address(this), "AM_OAM");
        return _swap(i, j, dx, dyLimit, isExactInput, true);
    }

    function simulatedSwap(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isExactInput
    )
        external
        override
        nonReentrant
        returns (
            uint256 priceAfter,
            uint256 amount0,
            uint256 amount1
        )
    {
        // AM_SCI: same coin index
        require(i != j, "AM_SCI");
        // AM_CIOOR: coin index out of range
        require(i < N_COINS, "AM_CIOOR");
        // AM_CIOOR: coin index out of range
        require(j < N_COINS, "AM_CIOOR");

        uint256 dyLimit = getDy(i, j, dx, isExactInput);
        try this.simulatedSwapInternal(i, j, dx, dyLimit, isExactInput) {} catch (bytes memory reason) {
            if (reason.length != 96) {
                if (reason.length < 68) revert("Unexpected error");
                assembly {
                    reason := add(reason, 0x04)
                }
                revert(abi.decode(reason, (string)));
            }

            (uint256 price, uint256 dx1, uint256 dy1) = abi.decode(reason, (uint256, uint256, uint256));

            emit CalcPriceAfterSwap(_msgSender(), dx1, dy1, price, isExactInput);

            return (price, dx1, dy1);
        }
    }

    function getPriceScale() external view override returns (uint256) {
        return _priceScale;
    }

    function getPriceOracle() external view override returns (uint256) {
        return _priceOracle;
    }

    function getPriceLast() external view override returns (uint256) {
        return _priceLast;
    }

    function getPriceCurrent() public view override returns (uint256) {
        if (_totalLiquidity > 0) {
            uint256 bestBid = getDy(1, 0, 1e11, true) * 1e7;
            uint256 bestAsk = getDy(1, 0, 1e11, false) * 1e7;

            if (_priceLast < bestBid) {
                return bestBid;
            } else if (_priceLast > bestAsk) {
                return bestAsk;
            } else {
                return _priceLast;
            }
        }

        return _priceScale;
    }

    function getTwapMarkPrice(uint256 interval) external view override returns (uint256) {
        // 3 different timestamps, `previous`, `current`, `target`
        // `base` = now - _interval
        // `current` = current round timestamp from aggregator
        // `previous` = previous round timestamp form aggregator
        // now >= previous > current > = < base
        //
        //  while loop i = 0
        //  --+------+-----+-----+-----+-----+-----+
        //         base                 current  now(previous)
        //
        //  while loop i = 1
        //  --+------+-----+-----+-----+-----+-----+
        //         base           current previous now

        (uint256 round, uint256 latestPrice, uint256 latestTimestamp) = latestRoundData();
        if (interval == 0 || round == 0) {
            return latestPrice;
        }

        uint256 baseTimestamp = _blockTimestamp() - interval;
        // if latest updated timestamp is earlier than target timestamp, return the latest price.
        if (latestTimestamp < baseTimestamp) {
            return latestPrice;
        }

        // rounds are like snapshots, latestRound means the latest price snapshot. follow chainlink naming
        uint256 previousTimestamp = latestTimestamp;
        uint256 cumulativeTime = _blockTimestamp() - previousTimestamp;
        uint256 weightedPrice = latestPrice * cumulativeTime;
        uint256 timeFraction;
        while (true) {
            if (round == 0) {
                // To prevent from div 0 error, return the latest price if `cumulativeTime == 0`
                if (cumulativeTime == 0) {
                    return latestPrice;
                }
                // if cumulative time is less than requested interval, return current twap price
                return weightedPrice / cumulativeTime;
            }

            round = round - 1;
            (, uint256 currentPrice, uint256 currentTimestamp) = getRoundData(round);

            // check if current round timestamp is earlier than target timestamp
            if (currentTimestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, interval is 100, then target timestamp is 900. If timestamp of current round is 970,
                // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice + currentPrice * (previousTimestamp - baseTimestamp);
                break;
            }

            timeFraction = previousTimestamp - currentTimestamp;
            weightedPrice = weightedPrice + currentPrice * timeFraction;
            cumulativeTime = cumulativeTime + timeFraction;
            previousTimestamp = currentTimestamp;
        }
        if (weightedPrice == 0) {
            return latestPrice;
        }
        return weightedPrice / interval;
    }

    function getCoins(uint256 i) external view override returns (address) {
        return _coinPairs[i];
    }

    function getBalances(uint256 i) external view override returns (uint256) {
        return _coinBalances[i];
    }

    function getA() external view override returns (uint256) {
        return _getAGamma()[0];
    }

    function getGamma() external view override returns (uint256) {
        return _getAGamma()[1];
    }

    function getTotalLiquidity() external view override returns (uint256) {
        return _totalLiquidity;
    }

    /**
     * Internal View Functions
     */
    function _swap(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 dyLimit,
        bool isExactInput,
        bool isQuoteSwap
    ) internal returns (uint256 dy) {
        // AM_SCI: same coin index
        require(i != j, "AM_SCI");
        // AM_CIOOR: coin index out of range
        require(i < N_COINS, "AM_CIOOR");
        // AM_CIOOR: coin index out of range
        require(j < N_COINS, "AM_CIOOR");
        // AM_AIZ: amount in is zero
        require(dx > 0, "AM_AI0");

        InternalSwapAstp memory sp;

        sp.AGamma = _getAGamma();
        sp.xp = SigmaMath.copy(_coinBalances);

        sp.y = sp.xp[j];
        sp.x0 = sp.xp[i];
        sp.xp[i] = isExactInput ? sp.x0 + dx : sp.x0 - dx;

        _coinBalances[i] = sp.xp[i];

        sp.xp = [sp.xp[0] * _coinPrecisions[0], (sp.xp[1] * _priceScale * _coinPrecisions[1]) / PRECISION];

        sp.preci = _coinPrecisions[0];
        sp.precj = _coinPrecisions[1];

        if (i == 1) {
            sp.preci = _coinPrecisions[1];
            sp.precj = _coinPrecisions[0];
        }

        {
            // In case ramp is happening
            uint256 t = _globalFutureParams.futureAGammaTime;
            if (t > 0) {
                sp.x0 *= sp.preci;
                if (i > 0) {
                    sp.x0 = (sp.x0 * _priceScale) / PRECISION;
                }
                uint256 x1 = sp.xp[i]; // Back up old value in sp.xp
                sp.xp[i] = sp.x0;
                _globalD = AmmLib.newtonD(sp.AGamma[0], sp.AGamma[1], sp.xp);
                sp.xp[i] = x1; // And restore
                if (_blockTimestamp() >= t) {
                    _globalFutureParams.futureAGammaTime = 1;
                }
            }
        }

        if (isExactInput) {
            IERC20Upgradeable(_coinPairs[i]).transferFrom(_clearingHouse, address(this), dx);

            dy = sp.xp[j] - AmmLib.newtonY(sp.AGamma[0], sp.AGamma[1], sp.xp, _globalD, j);

            // Not defining new "sp.y" here to have less variables / make subsequent calls cheaper
            sp.xp[j] -= dy;
            dy -= 1;
            if (j > 0) {
                dy = (dy * PRECISION) / _priceScale;
            }
            dy /= sp.precj;

            // AM_OSPWSEI: over slippage protection when swap with exact input
            require(dy >= dyLimit, "AM_OSPWSEI");

            sp.y -= dy;
            _coinBalances[j] = sp.y;

            IERC20Upgradeable(_coinPairs[j]).transfer(_clearingHouse, dy);
        } else {
            IERC20Upgradeable(_coinPairs[i]).transfer(_clearingHouse, dx);

            dy = AmmLib.newtonY(sp.AGamma[0], sp.AGamma[1], sp.xp, _globalD, j) - sp.xp[j];

            // Not defining new "sp.y" here to have less variables / make subsequent calls cheaper
            sp.xp[j] += dy;
            dy += 1;
            if (j > 0) {
                dy = (dy * PRECISION) / _priceScale;
            }
            dy /= sp.precj;

            // AM_OSPWSEO: over slippage protection when swap with exact output
            require(dy <= dyLimit, "AM_OSPWSEO");

            sp.y += dy;

            _coinBalances[j] = sp.y;

            IERC20Upgradeable(_coinPairs[j]).transferFrom(_clearingHouse, address(this), dy);
        }

        sp.y *= sp.precj;
        if (j > 0) {
            sp.y = (sp.y * _priceScale) / PRECISION;
        }

        sp.xp[j] = sp.y;
        // Calculate price
        if (dx > 10**5 && dy > 10**5) {
            uint256 _dx = dx * sp.preci;
            uint256 _dy = dy * sp.precj;
            if (i == 0) {
                sp.p = (_dx * 10**18) / _dy;
            } else {
                // j == 0
                sp.p = (_dy * 10**18) / _dx;
            }
        }

        _tweakPrice(sp.AGamma, sp.xp, sp.p, 0);

        uint256 currentPrice = getPriceCurrent();
        if (isQuoteSwap) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, currentPrice)
                mstore(add(ptr, 0x20), dx)
                mstore(add(ptr, 0x40), dy)
                revert(ptr, 96)
            }
        }

        _priceSnapshorts.push(AmmLib.PriceSnapshort(_priceSnapshorts.length, currentPrice, _blockTimestamp()));

        emit TokenExchange(_msgSender(), i, dx, j, dy, isExactInput);
        // console.log("dy:", dy);
        return dy;
    }

    function _tweakPrice(
        uint256[2] memory AGamma,
        uint256[N_COINS] memory _xp,
        uint256 pi,
        uint256 newD
    ) internal {
        uint256 priceOracleTemp = _priceOracle;
        uint256 priceScaleTemp = _priceScale;
        uint256 priceLastTemp = _priceLast;
        uint256 priceLastTimestampTemp = _priceLastTimestamp;

        if (priceLastTimestampTemp < _blockTimestamp()) {
            // MA update required
            uint256 maHalfTimeTemp = _globalInitializeParams.maHalfTime;
            uint256 alpha = AmmLib.halfpow(((_blockTimestamp() - priceLastTimestampTemp) * 10**18) / maHalfTimeTemp);
            priceOracleTemp = (priceLastTemp * (10**18 - alpha) + priceOracleTemp * alpha) / 10**18;
            _priceOracle = priceOracleTemp;
            _priceLastTimestamp = _blockTimestamp();
        }

        uint256 unadjustedD = newD; // Withdrawal methods know new D already
        if (newD == 0) {
            // We will need this a few times (35k gas)
            unadjustedD = AmmLib.newtonD(AGamma[0], AGamma[1], _xp);
        }

        if (pi > 0) {
            priceLastTemp = pi;
        } else {
            // calculate real prices
            uint256[N_COINS] memory __xp = SigmaMath.copy(_xp);
            uint256 dxPrice = __xp[0] / 10**6;
            __xp[0] += dxPrice;
            priceLastTemp =
                (priceScaleTemp * dxPrice) /
                (_xp[1] - AmmLib.newtonY(AGamma[0], AGamma[1], __xp, unadjustedD, 1));
        }

        _priceLast = priceLastTemp;

        _repegging(AGamma, _xp, unadjustedD);
    }

    function _repegging(
        uint256[2] memory AGamma,
        uint256[N_COINS] memory _xp,
        uint256 unadjustedD
    ) internal {
        uint256 norm = (_priceOracle * 10**18) / _priceScale;
        if (norm > 10**18) {
            norm -= 10**18;
        } else {
            norm = 10**18 - norm;
        }

        // TODO(just for test)
        if (_globalInitializeParams.adjustmentStep == 1e18) {
            uint256 pNew = _priceOracle;

            // Calculate balances*prices
            uint256[N_COINS] memory xp = [_xp[0], (_xp[1] * pNew) / _priceScale];

            // Calculate "extended constant product" invariant xCP and virtual price
            uint256 D = AmmLib.newtonD(AGamma[0], AGamma[1], xp);
            xp = [D / N_COINS, (D * PRECISION) / (N_COINS * pNew)];

            _priceScale = pNew;
            _globalD = D;

            return;
        }

        uint256 adjustmentStepTemp = _globalInitializeParams.adjustmentStep;

        // TODO(just for test)
        if (_globalInitializeParams.adjustmentStep == 0.9e18) {
            adjustmentStepTemp = SigmaMath.max(uint256(0.000146e18), norm / 5);
        }

        if (norm > adjustmentStepTemp) {
            uint256 pNew = (_priceScale * (norm - adjustmentStepTemp) + adjustmentStepTemp * _priceOracle) / norm;

            // Calculate balances*prices
            uint256[N_COINS] memory xp = [_xp[0], (_xp[1] * pNew) / _priceScale];

            // Calculate "extended constant product" invariant xCP and virtual price
            uint256 D = AmmLib.newtonD(AGamma[0], AGamma[1], xp);
            xp = [D / N_COINS, (D * PRECISION) / (N_COINS * pNew)];

            _priceScale = pNew;
            _globalD = D;

            // console.log("amm -> price_scale_new", _priceScale);
            // console.log("amm -> price_oracle_new", _priceOracle);

            return;
        }

        _globalD = unadjustedD;
    }

    function _getXp() internal view returns (uint256[N_COINS] memory) {
        return [
            _coinBalances[0] * _coinPrecisions[0],
            (_coinBalances[1] * _coinPrecisions[1] * _priceScale) / PRECISION
        ];
    }

    function _getAGamma() internal view returns (uint256[2] memory) {
        uint256 t1 = _globalFutureParams.futureAGammaTime;
        uint256 AGamma1 = _globalFutureParams.futureAGamma;
        uint256 gamma1 = SigmaMath.bitwiseAnd(AGamma1, 2**128 - 1);
        uint256 A1 = SigmaMath.shift(AGamma1, -128);

        if (_blockTimestamp() < t1) {
            // handle ramping up and down of A
            uint256 AGamma0 = _globalInitializeParams.initialAGamma;
            uint256 t0 = _globalInitializeParams.initialAGammaTime;

            // Less readable but more compact way of writing and converting to uint256
            // uint256 gamma0 = SigmaMath.bitwiseAnd(AGamma0, 2**128-1)
            // uint256 A0 = SigmaMath.shift(AGamma0, -128)
            // A1 = A0 + (A1 - A0) * (_blockTimestamp() - t0) / (t1 - t0)
            // gamma1 = gamma0 + (gamma1 - gamma0) * (_blockTimestamp() - t0) / (t1 - t0)
            t1 -= t0;
            t0 = _blockTimestamp() - t0;
            uint256 t2 = t1 - t0;
            A1 = (SigmaMath.shift(AGamma0, -128) * t2 + A1 * t0) / t1;
            gamma1 = (SigmaMath.bitwiseAnd(AGamma0, 2**128 - 1) * t2 + gamma1 * t0) / t1;
        }

        return [A1, gamma1];
    }

    function _getXcp(uint256 D) internal view returns (uint256) {
        uint256[N_COINS] memory x = [D / N_COINS, (D * PRECISION) / (_priceScale * N_COINS)];
        return AmmLib.geometricMean(x, true);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amount0,
        uint256 balance0,
        uint256 balance1
    ) internal pure returns (uint256 amount1) {
        // AM_IA: insufficient amount
        require(amount0 > 0, "AM_IA");
        // AM_IL: insufficient liquidity
        require(balance0 > 0 && balance1 > 0, "AM_IL");
        amount1 = (amount0 * balance1) / balance0;
    }

    function getRoundData(uint256 roundId)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        AmmLib.PriceSnapshort memory currentSnapshot = _priceSnapshorts[roundId];
        return (currentSnapshot.roundId, currentSnapshot.price, currentSnapshot.timestamp);
    }

    function latestRoundData()
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_priceSnapshorts.length == 0) {
            return (0, getPriceCurrent(), _blockTimestamp());
        }

        uint256 roundId = _priceSnapshorts.length - 1;
        AmmLib.PriceSnapshort memory latestSnapshot = _priceSnapshorts[roundId];
        return (latestSnapshot.roundId, latestSnapshot.price, latestSnapshot.timestamp);
    }

    /**
     * Only owner
     */
    function setClearingHouse(address clearingHouseArg) external onlyOwner {
        // AM_CHNC: ClearingHouse is not contract
        require(clearingHouseArg.isContract(), "AM_CHNC");

        _clearingHouse = clearingHouseArg;
        emit ClearingHouseChanged(clearingHouseArg);
    }

    function setMarketTaker(address marketTakerArg) external onlyOwner {
        // AM_MTNC: MarketTaker is not contract
        require(marketTakerArg.isContract(), "AM_MTNC");

        _marketTaker = marketTakerArg;
        emit MarketTakerChanged(marketTakerArg);
    }

    function setLiquidityProvider(address liquidityProviderArg) external onlyOwner {
        // AM_LPNC: LiquidityProvider is not contract
        require(liquidityProviderArg.isContract(), "AM_LPNC");

        _liquidityProvider = liquidityProviderArg;
        emit LiquidityProviderChanged(liquidityProviderArg);
    }

    function rampAGamma(
        uint256 futureA,
        uint256 futureGamma,
        uint256 futureTime
    ) external onlyOwner {
        // AM_ATS: A is too small
        require(futureA > AmmLib.MIN_A - 1, "AM_ATS");
        // AM_ATL: A is too large
        require(futureA < AmmLib.MAX_A + 1, "AM_ATL");
        // AM_GTS: gamma is too small
        require(futureGamma > AmmLib.MIN_GAMMA - 1, "AM_GTS");
        // AM_GTS: gamma is too large
        require(futureGamma < AmmLib.MAX_GAMMA + 1, "AM_GTL");
        // AM_CTTS: current time is too small
        require(_blockTimestamp() > _globalInitializeParams.initialAGammaTime + (MIN_RAMP_TIME - 1), "AM_CTTS");
        // AM_FTTS: future time is too small
        require(futureTime > _blockTimestamp() + (MIN_RAMP_TIME - 1), "AM_FTTS");

        uint256[2] memory AGamma = _getAGamma();
        uint256 initialAGammaTemp = SigmaMath.shift(AGamma[0], 128);
        initialAGammaTemp = SigmaMath.bitwiseOr(initialAGammaTemp, AGamma[1]);

        uint256 ratio = (10**18 * futureA) / AGamma[0];
        // AM_ACTL: A change step is too large
        require(ratio < 10**18 * MAX_A_CHANGE + 1, "AM_ACTL");
        // AM_ACTS: A change step is too small
        require(ratio > 10**18 / MAX_A_CHANGE - 1, "AM_ACTS");

        ratio = (10**18 * futureGamma) / AGamma[1];
        // AM_GCTL: gamma change step is too large
        require(ratio < 10**18 * MAX_A_CHANGE + 1, "AM_GCTL");
        // AM_GCTS: gamma change step is too small
        require(ratio > 10**18 / MAX_A_CHANGE - 1, "AM_GCTS");

        _globalInitializeParams.initialAGamma = initialAGammaTemp;
        _globalInitializeParams.initialAGammaTime = _blockTimestamp();

        uint256 futureAGammaTemp = SigmaMath.shift(futureA, 128);
        futureAGammaTemp = SigmaMath.bitwiseOr(futureAGammaTemp, futureGamma);
        _globalFutureParams.futureAGammaTime = futureTime;
        _globalFutureParams.futureAGamma = futureAGammaTemp;

        emit RampAgamma(AGamma[0], futureA, AGamma[1], futureGamma, _blockTimestamp(), futureTime);
    }

    function stopRampAGamma() external onlyOwner {
        uint256[2] memory AGamma = _getAGamma();
        uint256 currentAGamma = SigmaMath.shift(AGamma[0], 128);
        currentAGamma = SigmaMath.bitwiseOr(currentAGamma, AGamma[1]);

        _globalInitializeParams.initialAGamma = currentAGamma;
        _globalFutureParams.futureAGamma = currentAGamma;
        _globalInitializeParams.initialAGammaTime = _blockTimestamp();
        _globalFutureParams.futureAGammaTime = _blockTimestamp();

        // now (_blockTimestamp() < t1) is always false, so we return saved A
        emit StopRampA(AGamma[0], AGamma[1], _blockTimestamp());
    }

    function commitNewParameters(uint256 newAdjustmentStep, uint256 newMAHalfTime) external onlyOwner {
        // AM_ADNZ: action deadline is not zero
        require(_adminActionsDeadline == 0, "AM_ADN0");

        if (newAdjustmentStep > 10**18) {
            newAdjustmentStep = _globalInitializeParams.adjustmentStep;
        }

        // MA
        if (newMAHalfTime < 7 * 86400) {
            // AM_MAHTZ: ma half time is zero
            require(newMAHalfTime > 0, "AM_MAHT0");
        } else {
            newMAHalfTime = _globalInitializeParams.maHalfTime;
        }

        uint256 _deadline = _blockTimestamp() + ADMIN_ACTIONS_DELAY;
        _adminActionsDeadline = _deadline;

        _globalFutureParams.futureAdjustmentStep = newAdjustmentStep;
        _globalFutureParams.futureMAHalfTime = newMAHalfTime;

        emit CommitNewParameters(_deadline, newAdjustmentStep, newMAHalfTime);
    }

    function applyNewParameters() external nonReentrant onlyOwner {
        // AM_IT: insufficient time
        require(_blockTimestamp() >= _adminActionsDeadline, "AM_IT");
        // AM_ADZ: action deadline is zero
        require(_adminActionsDeadline != 0, "AM_ADZ");

        _adminActionsDeadline = 0;

        uint256 adjustmentStepTemp = _globalFutureParams.futureAdjustmentStep;
        _globalInitializeParams.adjustmentStep = adjustmentStepTemp;

        uint256 maHalfTimeTemp = _globalFutureParams.futureMAHalfTime;
        _globalInitializeParams.maHalfTime = maHalfTimeTemp;

        emit NewParameters(adjustmentStepTemp, maHalfTimeTemp);
    }

    function revertNewParameters() external onlyOwner {
        _adminActionsDeadline = 0;
    }

    // TODO(just for test)
    function setAdjustmentStep(uint256 newAdjustmentStep) external onlyOwner {
        _globalInitializeParams.adjustmentStep = newAdjustmentStep;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

interface IAmm {
    /// @param coinPairs 0: quote token address, 1: base token address
    struct InitializeParams {
        uint256 A;
        uint256 gamma;
        uint256 adjustmentStep;
        uint256 maHalfTime;
        uint256 initialPrice;
        address baseToken;
        address quoteToken;
        address clearingHouse;
        address marketTaker;
        address liquidityProvider;
    }

    // Events
    event TokenExchange(address indexed buyer, uint256 i, uint256 dx, uint256 j, uint256 dy, bool isExactInput);

    event AddLiquidity(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 totalLiquidity
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 totalLiquidity
    );

    event CommitNewParameters(uint256 indexed deadline, uint256 adjustmentStep, uint256 maHalfTime);

    event NewParameters(uint256 adjustmentStep, uint256 maHalfTime);

    event RampAgamma(
        uint256 initialA,
        uint256 futureA,
        uint256 initialGamma,
        uint256 futureGamma,
        uint256 initialTime,
        uint256 futureTime
    );

    event StopRampA(uint256 currentA, uint256 currentGamma, uint256 time);

    event CalcPriceAfterSwap(
        address sender,
        uint256 amountIn,
        uint256 amountOut,
        uint256 priceAfter,
        bool isExactInput
    );

    event ClearingHouseChanged(address clearingHouse);

    event MarketTakerChanged(address marketTaker);

    event LiquidityProviderChanged(address liquidityProvider);

    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 minLiquidity
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(
        uint256 liquidity,
        uint256 minAmount0,
        uint256 minAmount1
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 dyLimit,
        bool isExactInput
    ) external returns (uint256);

    function simulatedSwap(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isExactInput
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function getDy(
        uint256 i,
        uint256 j,
        uint256 dx,
        bool isExactInput
    ) external view returns (uint256);

    function getA() external view returns (uint256);

    function getGamma() external view returns (uint256);

    function getCoins(uint256 i) external view returns (address);

    function getBalances(uint256 i) external view returns (uint256);

    function getPriceScale() external view returns (uint256);

    function getPriceOracle() external view returns (uint256);

    function getPriceLast() external view returns (uint256);

    function getPriceCurrent() external view returns (uint256);

    function getTwapMarkPrice(uint256 interval) external view returns (uint256);

    function getTotalLiquidity() external view returns (uint256);

    function calcTokenAmountsByLiquidity(uint256 liquidity) external view returns (uint256 amount0, uint256 amount1);

    function calcLiquidityByTokenAmounts(uint256 amount0Desired, uint256 amount1Desired)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { FullMath } from "./FullMath.sol";
import { Constant } from "./Constant.sol";

library SigmaMath {
    function copy(uint256[2] memory data) internal pure returns (uint256[2] memory) {
        uint256[2] memory result;
        for (uint8 i = 0; i < 2; i++) {
            result[i] = data[i];
        }
        return result;
    }

    function shift(uint256 x, int256 _shift) internal pure returns (uint256) {
        if (_shift > 0) {
            return x << abs(_shift);
        } else if (_shift < 0) {
            return x >> abs(_shift);
        }

        return x;
    }

    function bitwiseOr(uint256 x, uint256 y) internal pure returns (uint256) {
        return x | y;
    }

    function bitwiseAnd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x & y;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? toUint256(value) : toUint256(neg256(value));
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "SigmaMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -toInt256(a);
    }

    function formatX1e18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, Constant.IQ96, 1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : toInt256(unsignedResult);

        return result;
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { SigmaMath } from "./SigmaMath.sol";

library AmmLib {
    struct InternalNewtonYAstp {
        uint256 xj;
        uint256 prevY;
        uint256 y;
        uint256 K0;
        uint256 K0i;
        uint256 g1k0;
        uint256 convergenceLimit;
        uint256 S;
    }

    struct GlobalInitializeParams {
        uint256 initialAGamma;
        uint256 initialAGammaTime;
        uint256 adjustmentStep;
        uint256 maHalfTime;
    }

    struct GlobalFutureParams {
        uint256 futureAGamma;
        uint256 futureAGammaTime;
        uint256 futureAdjustmentStep;
        uint256 futureMAHalfTime;
    }

    struct PriceSnapshort {
        uint256 roundId;
        uint256 price;
        uint256 timestamp;
    }

    uint256 internal constant N_COINS = 2;
    uint256 internal constant EXP_PRECISION = 10**10;
    uint256 internal constant A_MULTIPLIER = 10000;
    uint256 internal constant MIN_GAMMA = 10**10;
    uint256 internal constant MAX_GAMMA = 2 * 10**16;
    uint256 internal constant MIN_A = (N_COINS**N_COINS * A_MULTIPLIER) / 10;
    uint256 internal constant MAX_A = N_COINS**N_COINS * A_MULTIPLIER * 100000;

    /**
     * Math functions
     */
    function geometricMean(uint256[N_COINS] memory unsortedX, bool sort) internal pure returns (uint256) {
        // (x[0] * x[1] * ...) ** (1/N)
        uint256[N_COINS] memory x = SigmaMath.copy(unsortedX);
        if (sort && x[0] < x[1]) {
            x = [unsortedX[1], unsortedX[0]];
        }
        uint256 D = x[0];
        uint256 diff = 0;
        for (uint8 i = 0; i < 255; i++) {
            uint256 prevD = D;

            // uint256 tmp = 10**18
            // for _x in x:
            //     tmp = tmp * _x / D
            // D = D * ((N_COINS - 1) * 10**18 + tmp) / (N_COINS * 10**18)
            // line below makes it for 2 coins
            D = (D + (x[0] * x[1]) / D) / N_COINS;
            if (D > prevD) {
                diff = D - prevD;
            } else {
                diff = prevD - D;
            }
            if (diff <= 1 || diff * 10**18 < D) {
                return D;
            }
        }
        revert("Did not converge");
    }

    function newtonD(
        uint256 ANN,
        uint256 gamma,
        uint256[N_COINS] memory unsortedX
    ) external pure returns (uint256) {
        // Finding the invariant using Newton method.
        // ANN is higher by the factor A_MULTIPLIER
        // ANN is already A * N**N
        // Currently uses 60k gas

        // AW_USVA: unsafe A
        require((ANN > MIN_A - 1) && (ANN < MAX_A + 1), "AW_USA");
        // AW_USG: unsafe gamma
        require((gamma > MIN_GAMMA - 1) && (gamma < MAX_GAMMA + 1), "AW_USG");

        // Initial value of invariant D is that for constant-product invariant
        uint256[N_COINS] memory x = SigmaMath.copy(unsortedX);
        if (x[0] < x[1]) {
            x = [unsortedX[1], unsortedX[0]];
        }

        // AW_USQM: unsafe quote token amount
        require((x[0] > 10**9 - 1) && (x[0] < 10**15 * 10**18 + 1), "AW_USQM");
        // AW_USBM: unsafe base token amount
        require(((x[1] * 10**18) / x[0]) > (10**14 - 1), "AW_USBM");

        uint256 D = N_COINS * geometricMean(x, false);
        uint256 S = x[0] + x[1];

        for (uint8 i = 0; i < 255; i++) {
            uint256 prevD = D;

            // uint256 K0 = 10**18
            // for _x in x:
            //     K0 = K0 * _x * N_COINS / D
            // collapsed for 2 coins
            // uint256 K0 = ((((10**18 * N_COINS**2) * x[0]) / D) * x[1]) / D;
            uint256 K0 = (10**18 * N_COINS**2 * x[0] * x[1]) / (D * D);
            uint256 g1k0 = gamma + 10**18;
            if (g1k0 > K0) {
                g1k0 = g1k0 - K0 + 1;
            } else {
                g1k0 = K0 - g1k0 + 1;
            }

            // D / (A * N**N) * g1k0**2 / gamma**2
            // uint256 mul1 = (10**18 * D * g1k0 * g1k0 * A_MULTIPLIER) / (ANN * gamma * gamma);
            uint256 mul1 = (((((10**18 * D) / gamma) * g1k0) / gamma) * g1k0 * A_MULTIPLIER) / ANN;

            // 2*N*K0 / g1k0
            uint256 mul2 = ((2 * 10**18) * N_COINS * K0) / g1k0;
            uint256 negFprime = (S + (S * mul2) / 10**18) + (mul1 * N_COINS) / K0 - (mul2 * D) / 10**18;

            // D -= f / fprime
            uint256 plusD = (D * (negFprime + S)) / negFprime;
            uint256 minusD = (D * D) / negFprime;

            if (10**18 > K0) {
                minusD += (((D * (mul1 / negFprime)) / 10**18) * (10**18 - K0)) / K0;
            } else {
                minusD -= (((D * (mul1 / negFprime)) / 10**18) * (K0 - 10**18)) / K0;
            }

            if (plusD > minusD) {
                D = plusD - minusD;
            } else {
                D = (minusD - plusD) / 2;
            }

            uint256 diff = 0;
            if (D > prevD) {
                diff = D - prevD;
            } else {
                diff = prevD - D;
            }
            if (diff * 10**14 < SigmaMath.max(10**16, D)) {
                // Could reduce precision for gas efficiency here
                // Test that we are safe with the next newtonY
                for (uint8 k = 0; k < N_COINS; k++) {
                    uint256 _x = x[k];
                    uint256 frac = (_x * 10**18) / D;
                    // AW_USX: unsafe value x[i]
                    require((frac > 10**16 - 1) && (frac < 10**20 + 1), "AW_USX");
                }
                return D;
            }
        }
        revert("Did not converge");
    }

    function newtonY(
        uint256 ANN,
        uint256 gamma,
        uint256[N_COINS] memory x,
        uint256 D,
        uint256 i
    ) external pure returns (uint256) {
        // Calculating x[i] given other balances x[0..N_COINS-1] and invariant D
        // ANN = A * N**N
        // AW_USA: unsafe values A
        require((ANN > MIN_A - 1) && (ANN < MAX_A + 1), "AW_USA");
        // AW_USG: unsafe values gamma
        require((gamma > MIN_GAMMA - 1) && (gamma < MAX_GAMMA + 1), "AW_USG");
        // AW_USD: unsafe values D
        require((D > 10**17 - 1) && (D < 10**15 * 10**18 + 1), "AW_USD");

        InternalNewtonYAstp memory nty;
        nty.xj = x[1 - i];
        nty.y = D**2 / (nty.xj * N_COINS**2);
        nty.K0i = ((10**18 * N_COINS) * nty.xj) / D;

        // S_i = nty.xj
        // frac = nty.xj * 1e18 / D => frac = nty.K0i / N_COINS
        // AW_USX: unsafe values x[i]
        require((nty.K0i > 10**16 * N_COINS - 1) && (nty.K0i < 10**20 * N_COINS + 1), "AW_USX");

        // uint256[N_COINS] memory x_sorted = x
        // x_sorted[i] = 0
        // x_sorted = self.sort(x_sorted)  // From high to low
        // x[not i] instead of x_sorted since x_soted has only 1 element
        nty.convergenceLimit = SigmaMath.max(SigmaMath.max(nty.xj / 10**14, D / 10**14), 100);

        for (uint8 j = 0; j < 255; j++) {
            nty.prevY = nty.y;
            nty.K0 = (nty.K0i * nty.y * N_COINS) / D;
            nty.S = nty.xj + nty.y;
            nty.g1k0 = gamma + 10**18;

            if (nty.g1k0 > nty.K0) {
                nty.g1k0 = nty.g1k0 - nty.K0 + 1;
            } else {
                nty.g1k0 = nty.K0 - nty.g1k0 + 1;
            }

            // D / (A * N**N) * nty.g1k0**2 / gamma**2
            uint256 mul1 = (((((10**18 * D) / gamma) * nty.g1k0) / gamma) * nty.g1k0 * A_MULTIPLIER) / ANN;

            // 2*nty.K0 / nty.g1k0
            uint256 mul2 = 10**18 + ((2 * 10**18) * nty.K0) / nty.g1k0;
            uint256 yfprime = 10**18 * nty.y + nty.S * mul2 + mul1;
            uint256 _dyfprime = D * mul2;

            if (yfprime < _dyfprime) {
                nty.y = nty.prevY / 2;
                continue;
            } else {
                yfprime -= _dyfprime;
            }
            uint256 fprime = yfprime / nty.y;

            // y -= f / f_prime;  y = (y * fprime - f) / fprime
            // y = (yfprime + 10**18 * D - 10**18 * nty.S) // fprime + mul1 // fprime * (10**18 - nty.K0) // nty.K0
            uint256 minusY = mul1 / fprime;
            uint256 plusY = (yfprime + 10**18 * D) / fprime + (minusY * 10**18) / nty.K0;
            minusY += (10**18 * nty.S) / fprime;

            if (plusY < minusY) {
                nty.y = nty.prevY / 2;
            } else {
                nty.y = plusY - minusY;
            }

            uint256 diff = 0;
            if (nty.y > nty.prevY) {
                diff = nty.y - nty.prevY;
            } else {
                diff = nty.prevY - nty.y;
            }
            if (diff < SigmaMath.max(nty.convergenceLimit, nty.y / 10**14)) {
                uint256 frac = (nty.y * 10**18) / D;
                // AW_USY: unsafe value for y
                require((frac > 10**16 - 1) && (frac < 10**20 + 1), "AW_USY");

                return nty.y;
            }
        }
        revert("Did not converge");
    }

    function halfpow(uint256 power) external pure returns (uint256) {
        // 1e18 * 0.5 ** (power/1e18)
        // Inspired by: https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol//L128
        uint256 intpow = power / 10**18;
        uint256 otherpow = power - intpow * 10**18;

        if (intpow > 59) {
            return 0;
        }

        uint256 result = 10**18 / (2**intpow);
        if (otherpow == 0) {
            return result;
        }

        uint256 term = 10**18;
        uint256 x = 5 * 10**17;
        uint256 S = 10**18;
        bool neg = false;

        for (uint256 i = 1; i < 256; i++) {
            uint256 K = i * (10**18);
            uint256 c = K - 10**18;
            if (otherpow > c) {
                c = otherpow - c;
                neg = !neg;
            } else {
                c -= otherpow;
            }

            term = (term * ((c * x) / 10**18)) / K;

            if (neg) {
                S -= term;
            } else {
                S += term;
            }
            if (term < EXP_PRECISION) {
                return (result * S) / 10**18;
            }
        }
        revert("Did not converge");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeOwnable } from "./SafeOwnable.sol";

abstract contract OwnerPausable is SafeOwnable, PausableUpgradeable {
    // __gap is reserved storage
    uint256[50] private __gap;

    // solhint-disable-next-line func-order
    function __OwnerPausable_init() internal initializer {
        __SafeOwnable_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import { AmmLib } from "../lib/AmmLib.sol";

/// @notice For future upgrades, do not change AmmStorageV1. Create a new
/// contract which implements AmmStorageV1 and following the naming convention
/// AmmStorageVX.
abstract contract AmmStorageV1 {
    uint256 internal constant N_COINS = 2;
    uint256 internal constant PRECISION = 10**18; // The precision to convert to
    uint256 internal constant ADMIN_ACTIONS_DELAY = 3 * 86400;
    uint256 internal constant MIN_RAMP_TIME = 86400;
    uint256 internal constant MAX_A_CHANGE = 10;

    uint256 internal _globalD;
    uint256 internal _adminActionsDeadline;

    uint256 internal _totalLiquidity;
    uint256 internal _priceScale; // Internal price scale
    uint256 internal _priceOracle; // Price target given by MA
    uint256 internal _priceLast;
    uint256 internal _priceLastTimestamp;

    address _clearingHouse;
    address _marketTaker;
    address _liquidityProvider;

    uint256[N_COINS] internal _coinBalances;
    uint256[N_COINS] internal _coinPrecisions;
    address[N_COINS] internal _coinPairs;

    AmmLib.GlobalInitializeParams internal _globalInitializeParams;
    AmmLib.GlobalFutureParams internal _globalFutureParams;
    AmmLib.PriceSnapshort[] internal _priceSnapshorts;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        // uint256 twos = -denominator & denominator;
        uint256 twos = denominator & (~denominator + 1);

        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

library Constant {
    address internal constant ADDRESS_ZERO = address(0);
    uint256 internal constant DECIMAL_ONE = 1e18;
    int256 internal constant DECIMAL_ONE_SIGNED = 1e18;
    uint256 internal constant IQ96 = 0x1000000000000000000000000;
    int256 internal constant IQ96_SIGNED = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Constant } from "../lib/Constant.sol";

abstract contract SafeOwnable is ContextUpgradeable {
    address private _owner;
    address private _candidate;

    // __gap is reserved storage
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // SO_CNO: caller not owner
        require(owner() == _msgSender(), "SO_CNO");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __SafeOwnable_init() internal initializer {
        __Context_init();
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(Constant.ADDRESS_ZERO, msgSender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, Constant.ADDRESS_ZERO);
        _owner = Constant.ADDRESS_ZERO;
        _candidate = Constant.ADDRESS_ZERO;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        // SO_NW0: newOwner is 0
        require(newOwner != Constant.ADDRESS_ZERO, "SO_NW0");
        // SO_SAO: same as original
        require(newOwner != _owner, "SO_SAO");
        // SO_SAC: same as candidate
        require(newOwner != _candidate, "SO_SAC");

        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() external {
        // SO_C0: candidate is zero
        require(_candidate != Constant.ADDRESS_ZERO, "SO_C0");
        // SO_CNC: caller is not candidate
        require(_candidate == _msgSender(), "SO_CNC");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = Constant.ADDRESS_ZERO;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the candidate that can become the owner.
     */
    function candidate() external view returns (address) {
        return _candidate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}