// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./Storage.sol";
import "./Liquidity.sol";
import "./Getter.sol";
import "./Admin.sol";

contract LiquidityPoolHop2 is Storage, Liquidity, Admin {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../components/SafeOwnableUpgradeable.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibAsset.sol";
import "./Types.sol";
import "./Events.sol";

contract Storage is Initializable, SafeOwnableUpgradeable, Events {
    using LibAsset for Asset;

    LiquidityPoolStorage internal _storage;

    modifier onlyOrderBook() {
        require(_msgSender() == _storage.orderBook, "BOK"); // can only be called by order BOoK
        _;
    }

    modifier onlyLiquidityManager() {
        require(_msgSender() == _storage.liquidityManager, "LQM"); // can only be called by LiQuidity Manager
        _;
    }

    modifier onlyMaintainer() {
        require(_msgSender() == _storage.maintainer || _msgSender() == owner(), "S!M"); // Sender is Not MaiNTainer
        _;
    }

    function _updateSequence() internal {
        unchecked {
            _storage.sequence += 1;
        }
        emit UpdateSequence(_storage.sequence);
    }

    function _updateBrokerTransactions() internal {
        unchecked {
            _storage.brokerTransactions += 1;
        }
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function _hasAsset(uint8 assetId) internal view returns (bool) {
        return assetId < _storage.assets.length;
    }

    function _isStable(uint8 tokenId) internal view returns (bool) {
        return _storage.assets[tokenId].isStable();
    }

    bytes32[50] internal _gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../libraries/LibAsset.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../interfaces/IMuxRebalancerCallback.sol";
import "./Account.sol";
import "./Storage.sol";

contract Liquidity is Storage, Account {
    using LibAsset for Asset;
    using LibMath for uint256;
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev   Add liquidity
     *
     * @param trader            liquidity provider address
     * @param tokenId           asset.id that added
     * @param rawAmount         asset token amount. decimals = erc20.decimals
     * @param tokenPrice        token price
     * @param mlpPrice          mlp price
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset)
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains
     */
    function addLiquidity(
        address trader,
        uint8 tokenId,
        uint256 rawAmount, // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external onlyOrderBook {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(tokenId), "LST"); // the asset is not LiSTed
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        require(mlpPrice != 0, "P=0"); // Price Is Zero
        require(mlpPrice <= _storage.mlpPriceUpperBound, "MPO"); // Mlp Price is Out of range
        require(mlpPrice >= _storage.mlpPriceLowerBound, "MPO"); // Mlp Price is Out of range
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token.canAddRemoveLiquidity(), "TUL"); // the Token cannot be Used to add Liquidity
        tokenPrice = LibReferenceOracle.checkPriceWithSpread(_storage, token, tokenPrice, SpreadType.Bid);

        // token amount
        uint96 wadAmount = token.toWad(rawAmount);
        token.spotLiquidity += wadAmount; // already reserved fee
        // fee
        uint32 mlpFeeRate = _getLiquidityFeeRate(
            currentAssetValue,
            targetAssetValue,
            true,
            uint256(wadAmount).wmul(tokenPrice).safeUint96(),
            _storage.liquidityBaseFeeRate,
            _storage.liquidityDynamicFeeRate
        );
        uint96 feeCollateral = uint256(wadAmount).rmul(mlpFeeRate).safeUint96();
        token.collectedFee += feeCollateral; // spotLiquidity was modified above
        emit CollectedFee(tokenId, feeCollateral);
        wadAmount -= feeCollateral;
        // mlp
        uint96 mlpAmount = ((uint256(wadAmount) * uint256(tokenPrice)) / uint256(mlpPrice)).safeUint96();
        IERC20Upgradeable(_storage.mlp).transfer(trader, mlpAmount);
        emit AddLiquidity(trader, tokenId, tokenPrice, mlpPrice, mlpAmount, feeCollateral);
        _updateSequence();
        _updateBrokerTransactions();
    }

    /**
     * @dev   Remove liquidity
     *
     * @param trader            liquidity provider address
     * @param mlpAmount         mlp amount
     * @param tokenId           asset.id that removed to
     * @param tokenPrice        token price
     * @param mlpPrice          mlp price
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset)
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains
     */
    function removeLiquidity(
        address trader,
        uint96 mlpAmount, // NOTE: OrderBook SHOULD transfer mlpAmount mlp to LiquidityPool
        uint8 tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external onlyOrderBook {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(tokenId), "LST"); // the asset is not LiSTed
        require(mlpPrice != 0, "P=0"); // Price Is Zero
        require(mlpPrice <= _storage.mlpPriceUpperBound, "MPO"); // Mlp Price is Out of range
        require(mlpPrice >= _storage.mlpPriceLowerBound, "MPO"); // Mlp Price is Out of range
        require(mlpAmount != 0, "A=0"); // Amount Is Zero
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token.canAddRemoveLiquidity(), "TUL"); // the Token cannot be Used to remove Liquidity
        tokenPrice = LibReferenceOracle.checkPriceWithSpread(_storage, token, tokenPrice, SpreadType.Ask);

        // amount
        uint96 wadAmount = ((uint256(mlpAmount) * uint256(mlpPrice)) / uint256(tokenPrice)).safeUint96();
        // fee
        uint96 feeCollateral;
        {
            uint32 mlpFeeRate = _getLiquidityFeeRate(
                currentAssetValue,
                targetAssetValue,
                false,
                uint256(wadAmount).wmul(tokenPrice).safeUint96(),
                _storage.liquidityBaseFeeRate,
                _storage.liquidityDynamicFeeRate
            );
            feeCollateral = uint256(wadAmount).rmul(mlpFeeRate).safeUint96();
        }
        token.collectedFee += feeCollateral; // spotLiquidity will be modified below
        emit CollectedFee(tokenId, feeCollateral);
        wadAmount -= feeCollateral;
        // send token
        require(wadAmount <= token.spotLiquidity, "LIQ"); // insufficient LIQuidity
        token.spotLiquidity -= wadAmount; // already deduct fee
        uint256 rawAmount = token.toRaw(wadAmount);
        token.transferOut(trader, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        emit RemoveLiquidity(trader, tokenId, tokenPrice, mlpPrice, mlpAmount, feeCollateral);
        _updateSequence();
        _updateBrokerTransactions();
    }

    /**
     * @notice Redeem mux token into original tokens
     *
     *         Only strict stable coins and un-stable coins are supported.
     */
    function redeemMuxToken(
        address trader,
        uint8 tokenId,
        uint96 muxTokenAmount // NOTE: OrderBook SHOULD transfer muxTokenAmount to LiquidityPool
    ) external onlyOrderBook {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(tokenId), "LST"); // the asset is not LiSTed
        require(muxTokenAmount != 0, "A=0"); // Amount Is Zero
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        if (token.isStable()) {
            require(token.isStrictStable(), "STR"); // only STRict stable coins and un-stable coins are supported
        }
        require(token.spotLiquidity >= muxTokenAmount, "LIQ"); // insufficient LIQuidity
        uint256 rawAmount = token.toRaw(muxTokenAmount);
        token.spotLiquidity -= muxTokenAmount;
        token.transferOut(trader, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        emit RedeemMuxToken(trader, tokenId, muxTokenAmount);
        _updateSequence();
    }

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _getFundingRate in Liquidity.sol on how to calculate funding rate.
     * @param  stableUtilization    Stable coin utilization in all chains
     * @param  unstableTokenIds     All unstable Asset id(s) MUST be passed in order. ex: 1, 2, 5, 6, ...
     * @param  unstableUtilizations Unstable Asset utilizations in all chains
     * @param  unstablePrices       Unstable Asset prices
     */
    function updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices
    ) external onlyOrderBook {
        uint32 nextFundingTime = (_blockTimestamp() / _storage.fundingInterval) * _storage.fundingInterval;
        if (_storage.lastFundingTime == 0) {
            // init state. just update lastFundingTime
            _storage.lastFundingTime = nextFundingTime;
        } else if (_storage.lastFundingTime + _storage.fundingInterval >= _blockTimestamp()) {
            // do nothing
        } else {
            uint32 timeSpan = nextFundingTime - _storage.lastFundingTime;
            _updateFundingState(stableUtilization, unstableTokenIds, unstableUtilizations, unstablePrices, timeSpan);
            _storage.lastFundingTime = nextFundingTime;
        }
        _updateSequence();
    }

    /**
     * @dev  Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *       rebalancer must implement IMuxRebalancerCallback.
     */
    function rebalance(
        address rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes32 userData,
        uint96 price0,
        uint96 price1
    ) external onlyOrderBook {
        require(rebalancer != address(0), "R=0"); // Rebalancer address is zero
        require(_hasAsset(tokenId0), "LST"); // the asset is not LiSTed
        require(_hasAsset(tokenId1), "LST"); // the asset is not LiSTed
        require(rawAmount0 != 0, "A=0"); // Amount Is Zero
        Asset storage token0 = _storage.assets[tokenId0];
        Asset storage token1 = _storage.assets[tokenId1];
        price0 = LibReferenceOracle.checkPrice(_storage, token0, price0);
        price1 = LibReferenceOracle.checkPrice(_storage, token1, price1);
        require(token0.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token1.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        // send token 0. get amount 1
        uint256 expectedRawAmount1;
        {
            uint96 amount0 = token0.toWad(rawAmount0);
            require(token0.spotLiquidity >= amount0, "LIQ"); // insufficient LIQuidity
            token0.spotLiquidity -= amount0;

            uint96 expectedAmount1 = ((uint256(amount0) * uint256(price0)) / uint256(price1)).safeUint96();
            expectedRawAmount1 = token1.toRaw(expectedAmount1);
        }
        require(expectedRawAmount1 <= maxRawAmount1, "LMT"); // LiMiTed by limitPrice
        // swap. check amount 1
        uint96 rawAmount1;
        {
            IERC20Upgradeable(token0.tokenAddress).safeTransfer(rebalancer, rawAmount0);
            uint256 rawAmount1Old = IERC20Upgradeable(token1.tokenAddress).balanceOf(address(this));
            IMuxRebalancerCallback(rebalancer).muxRebalanceCallback(
                token0.tokenAddress,
                token1.tokenAddress,
                rawAmount0,
                expectedRawAmount1,
                userData
            );
            uint256 rawAmount1New = IERC20Upgradeable(token1.tokenAddress).balanceOf(address(this));
            require(rawAmount1Old <= rawAmount1New, "T1A"); // Token 1 Amount mismatched
            rawAmount1 = (rawAmount1New - rawAmount1Old).safeUint96();
        }
        require(rawAmount1 >= expectedRawAmount1, "T1A"); // Token 1 Amount mismatched
        token1.spotLiquidity += token1.toWad(rawAmount1);

        emit Rebalance(rebalancer, tokenId0, tokenId1, price0, price1, rawAmount0, rawAmount1);
        _updateSequence();
    }

    /**
     * @dev Anyone can withdraw collectedFee into Vault
     */
    function withdrawCollectedFee(uint8[] memory assetIds) external {
        require(_storage.vault != address(0), "VLT"); // bad VauLT
        for (uint256 i = 0; i < assetIds.length; i++) {
            uint8 assetId = assetIds[i];
            Asset storage asset = _storage.assets[assetId];
            uint96 collectedFee = asset.collectedFee;
            require(collectedFee <= asset.spotLiquidity, "LIQ"); // insufficient LIQuidity
            asset.collectedFee = 0;
            asset.spotLiquidity -= collectedFee;
            uint256 rawAmount = asset.toRaw(collectedFee);
            IERC20Upgradeable(asset.tokenAddress).safeTransfer(_storage.vault, rawAmount);
            emit WithdrawCollectedFee(assetId, collectedFee);
        }
        _updateSequence();
    }

    /**
     * @dev Broker can withdraw brokerGasRebate
     */
    function claimBrokerGasRebate(address receiver) external onlyOrderBook returns (uint256 rawAmount) {
        require(receiver != address(0), "RCV"); // bad ReCeiVer
        uint256 assetCount = _storage.assets.length;
        for (uint256 assetId = 0; assetId < assetCount; assetId++) {
            Asset storage asset = _storage.assets[assetId];
            if (asset.tokenAddress == _storage.weth) {
                uint96 rebate = (uint256(_storage.brokerGasRebate) * uint256(_storage.brokerTransactions)).safeUint96();
                require(asset.spotLiquidity >= rebate, "LIQ"); // insufficient LIQuidity
                asset.spotLiquidity -= rebate;
                rawAmount = asset.toRaw(rebate);
                emit ClaimBrokerGasRebate(receiver, _storage.brokerTransactions, rawAmount);
                _storage.brokerTransactions = 0;
                asset.transferOut(receiver, rawAmount, _storage.weth, _storage.nativeUnwrapper);
                _updateSequence();
                return rawAmount;
            }
        }
    }

    function _updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices,
        uint32 timeSpan
    ) internal {
        require(unstableTokenIds.length == unstableUtilizations.length, "LEN"); // LENgth of 2 arguments does not match
        require(unstableTokenIds.length == unstablePrices.length, "LEN"); // LENgth of 2 arguments does not match
        // stable
        uint32 shortFundingRate;
        uint128 shortCumulativeFundingRate;
        (shortFundingRate, shortCumulativeFundingRate) = _getFundingRate(
            _storage.shortFundingBaseRate8H,
            _storage.shortFundingLimitRate8H,
            stableUtilization,
            timeSpan
        );
        // unstable
        uint8 tokenLen = uint8(_storage.assets.length);
        uint8 i = 0;
        for (uint8 tokenId = 0; tokenId < tokenLen; tokenId++) {
            Asset storage asset = _storage.assets[tokenId];
            if (asset.isStable()) {
                continue;
            }
            require(i < unstableTokenIds.length, "LEN"); // invalid LENgth of unstableTokenIds
            require(unstableTokenIds[i] == tokenId, "AID"); // AssetID mismatched
            (uint32 longFundingRate, uint128 longCumulativeFundingRate) = _getFundingRate(
                asset.longFundingBaseRate8H,
                asset.longFundingLimitRate8H,
                unstableUtilizations[i],
                timeSpan
            );
            asset.longCumulativeFundingRate += longCumulativeFundingRate;
            {
                uint96 price = LibReferenceOracle.checkPrice(_storage, asset, unstablePrices[i]);
                asset.shortCumulativeFunding += uint256(shortCumulativeFundingRate).wmul(price).safeUint128();
            }
            emit UpdateFundingRate(
                tokenId,
                longFundingRate,
                asset.longCumulativeFundingRate,
                shortFundingRate,
                asset.shortCumulativeFunding
            );
            i += 1;
        }
    }

    /**
     * @dev   Liquidity fee rate
     *
     *        Lower rates indicate liquidity is closer to target.
     *
     *                                                  targetLiquidity
     *                     <------------------------------------+--------------------------------------> liquidity
     *
     * case 1: high rebate   * currentLiq * newLiq
     *                       * currentLiq                                                    * newLiq
     *
     * case 2: low rebate                 * currentLiq * newLiq
     *                                    * currentLiq                          * newLiq
     *
     * case 3: higher fee                                          * currentLiq * newLiq
     *
     * case 4: max fee                                             * currentLiq              * newLiq
     *                                                                          * currentLiq * newLiq
     *
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset)
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains
     * @param isAdd             true if add liquidity, false if remove liquidity
     * @param deltaValue        add/remove liquidity USD value
     * @param baseFeeRate       base fee
     * @param dynamicFeeRate    dynamic fee
     */
    function _getLiquidityFeeRate(
        uint96 currentAssetValue,
        uint96 targetAssetValue,
        bool isAdd,
        uint96 deltaValue,
        uint32 baseFeeRate, // 1e5
        uint32 dynamicFeeRate // 1e5
    ) internal pure returns (uint32) {
        uint96 newAssetValue;
        if (isAdd) {
            newAssetValue = currentAssetValue + deltaValue;
        } else {
            require(currentAssetValue >= deltaValue, "LIQ"); // insufficient LIQuidity
            newAssetValue = currentAssetValue - deltaValue;
        }
        // | x - target |
        uint96 oldDiff = currentAssetValue > targetAssetValue
            ? currentAssetValue - targetAssetValue
            : targetAssetValue - currentAssetValue;
        uint96 newDiff = newAssetValue > targetAssetValue
            ? newAssetValue - targetAssetValue
            : targetAssetValue - newAssetValue;
        if (targetAssetValue == 0) {
            // avoid division by 0
            return baseFeeRate;
        } else if (newDiff < oldDiff) {
            // improves
            uint32 rebate = ((uint256(dynamicFeeRate) * uint256(oldDiff)) / uint256(targetAssetValue)).safeUint32();
            return baseFeeRate > rebate ? baseFeeRate - rebate : 0;
        } else {
            // worsen
            uint96 avgDiff = (oldDiff + newDiff) / 2;
            avgDiff = LibMath.min(avgDiff, targetAssetValue);
            uint32 dynamic = ((uint256(dynamicFeeRate) * uint256(avgDiff)) / uint256(targetAssetValue)).safeUint32();
            return baseFeeRate + dynamic;
        }
    }

    /**
     * @dev Funding rate formula
     *
     * ^ fr           / limit
     * |            /
     * |          /
     * |        /
     * |______/ base
     * |    .
     * |  .
     * |.
     * +-------------------> %util
     */
    function _getFundingRate(
        uint32 baseRate8H, // 1e5
        uint32 limitRate8H, // 1e5
        uint32 utilization, // 1e5
        uint32 timeSpan // 1e0
    ) internal pure returns (uint32 newFundingRate, uint128 cumulativeFundingRate) {
        require(utilization <= 1e5, "U>1"); // %utilization > 100%
        newFundingRate = uint256(utilization).rmul(limitRate8H).safeUint32();
        newFundingRate = LibMath.max32(newFundingRate, baseRate8H);
        cumulativeFundingRate = ((uint256(newFundingRate) * uint256(timeSpan) * 1e13) / FUNDING_PERIOD).safeUint128();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../libraries/LibSubAccount.sol";
import "./Storage.sol";

contract Getter is Storage {
    using LibSubAccount for bytes32;

    function getAssetInfo(uint8 assetId) external view returns (Asset memory) {
        require(assetId < _storage.assets.length, "LST"); // the asset is not LiSTed
        return _storage.assets[assetId];
    }

    function getAllAssetInfo() external view returns (Asset[] memory) {
        return _storage.assets;
    }

    function getAssetAddress(uint8 assetId) external view returns (address) {
        require(assetId < _storage.assets.length, "LST"); // the asset is not LiSTed
        return _storage.assets[assetId].tokenAddress;
    }

    function getLiquidityPoolStorage()
        external
        view
        returns (
            // [0] shortFundingBaseRate8H
            // [1] shortFundingLimitRate8H
            // [2] lastFundingTime
            // [3] fundingInterval
            // [4] liquidityBaseFeeRate
            // [5] liquidityDynamicFeeRate
            // [6] sequence. note: will be 0 after 0xffffffff
            // [7] strictStableDeviation
            uint32[8] memory u32s,
            // [0] mlpPriceLowerBound
            // [1] mlpPriceUpperBound
            uint96[2] memory u96s
        )
    {
        u32s[0] = _storage.shortFundingBaseRate8H;
        u32s[1] = _storage.shortFundingLimitRate8H;
        u32s[2] = _storage.lastFundingTime;
        u32s[3] = _storage.fundingInterval;
        u32s[4] = _storage.liquidityBaseFeeRate;
        u32s[5] = _storage.liquidityDynamicFeeRate;
        u32s[6] = _storage.sequence;
        u32s[7] = _storage.strictStableDeviation;
        u96s[0] = _storage.mlpPriceLowerBound;
        u96s[1] = _storage.mlpPriceUpperBound;
    }

    function getSubAccount(bytes32 subAccountId)
        external
        view
        returns (
            uint96 collateral,
            uint96 size,
            uint32 lastIncreasedTime,
            uint96 entryPrice,
            uint128 entryFunding
        )
    {
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        collateral = subAccount.collateral;
        size = subAccount.size;
        lastIncreasedTime = subAccount.lastIncreasedTime;
        entryPrice = subAccount.entryPrice;
        entryFunding = subAccount.entryFunding;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./Storage.sol";
import "../libraries/LibAsset.sol";
import "../libraries/LibMath.sol";
import "../libraries/LibReferenceOracle.sol";
import "../core/Types.sol";

contract Admin is Storage {
    using LibAsset for Asset;
    using LibMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function setMaintainer(address newMaintainer) external onlyOwner {
        require(_storage.maintainer != newMaintainer, "CHG"); // not CHanGed
        _storage.maintainer = newMaintainer;
        emit SetMaintainer(newMaintainer);
    }

    function addAsset(
        uint8 assetId,
        bytes32 symbol,
        uint8 decimals,
        bool isStable,
        address tokenAddress,
        address muxTokenAddress
    ) external onlyOwner {
        require(decimals <= 18, "DCM"); // invalid DeCiMals
        require(assetId == _storage.assets.length, "AID"); // invalid AssetID
        require(assetId < 0xFF, "FLL"); // assets list is FuLL
        require(symbol != "", "SYM"); // invalid SYMbol

        _storage.assets.push();
        Asset storage asset = _storage.assets[assetId];
        asset.symbol = symbol;
        asset.id = assetId;
        asset.decimals = decimals;
        asset.flags = (asset.flags & (~ASSET_IS_STABLE)) | (isStable ? ASSET_IS_STABLE : 0);
        asset.tokenAddress = tokenAddress;
        asset.muxTokenAddress = muxTokenAddress;
        emit AddAsset(assetId, symbol, decimals, isStable, tokenAddress, muxTokenAddress);
        _updateSequence();
    }

    function setAssetParams(
        uint8 assetId,
        bytes32 symbol,
        uint32 newInitialMarginRate, // 1e5
        uint32 newMaintenanceMarginRate, // 1e5
        uint32 newPositionFeeRate, // 1e5
        uint32 newMinProfitRate, // 1e5
        uint32 newMinProfitTime, // 1e0
        uint96 newMaxLongPositionSize,
        uint96 newMaxShortPositionSize,
        uint32 newSpotWeight,
        uint32 newHalfSpread
    ) external onlyOwner {
        require(_hasAsset(assetId), "LST"); // the asset is not LiSTed
        require(symbol != "", "SYM"); // invalid SYMbol
        Asset storage asset = _storage.assets[assetId];
        require(asset.initialMarginRate == 0 || newInitialMarginRate <= asset.initialMarginRate, "IMR"); // Initial Margin Raised
        require(asset.maintenanceMarginRate == 0 || newMaintenanceMarginRate <= asset.maintenanceMarginRate, "MMR"); // Maintenance Margin Raised
        asset.symbol = symbol;
        asset.initialMarginRate = newInitialMarginRate;
        asset.maintenanceMarginRate = newMaintenanceMarginRate;
        asset.positionFeeRate = newPositionFeeRate;
        asset.minProfitRate = newMinProfitRate;
        asset.minProfitTime = newMinProfitTime;
        asset.maxLongPositionSize = newMaxLongPositionSize;
        asset.maxShortPositionSize = newMaxShortPositionSize;
        asset.spotWeight = newSpotWeight;
        asset.halfSpread = newHalfSpread;
        emit SetAssetParams(
            assetId,
            symbol,
            newInitialMarginRate,
            newMaintenanceMarginRate,
            newPositionFeeRate,
            newMinProfitRate,
            newMinProfitTime,
            newMaxLongPositionSize,
            newMaxShortPositionSize,
            newSpotWeight,
            newHalfSpread
        );
        _updateSequence();
    }

    function setAssetFlags(
        uint8 assetId,
        bool isTradable,
        bool isOpenable,
        bool isShortable,
        bool useStableTokenForProfit,
        bool isEnabled,
        bool isStrictStable,
        bool canAddRemoveLiquidity
    ) external onlyMaintainer {
        require(_hasAsset(assetId), "LST"); // the asset is not LiSTed
        Asset storage asset = _storage.assets[assetId];
        if (!asset.isStable()) {
            require(!isStrictStable, "STB"); // the asset is impossible to be a strict STaBle coin
        }
        uint56 newFlags = asset.flags;
        newFlags = (newFlags & (~ASSET_IS_TRADABLE)) | (isTradable ? ASSET_IS_TRADABLE : 0);
        newFlags = (newFlags & (~ASSET_IS_OPENABLE)) | (isOpenable ? ASSET_IS_OPENABLE : 0);
        newFlags = (newFlags & (~ASSET_IS_SHORTABLE)) | (isShortable ? ASSET_IS_SHORTABLE : 0);
        newFlags =
            (newFlags & (~ASSET_USE_STABLE_TOKEN_FOR_PROFIT)) |
            (useStableTokenForProfit ? ASSET_USE_STABLE_TOKEN_FOR_PROFIT : 0);
        newFlags = (newFlags & (~ASSET_IS_ENABLED)) | (isEnabled ? ASSET_IS_ENABLED : 0);
        newFlags = (newFlags & (~ASSET_IS_STRICT_STABLE)) | (isStrictStable ? ASSET_IS_STRICT_STABLE : 0);
        newFlags =
            (newFlags & (~ASSET_CAN_ADD_REMOVE_LIQUIDITY)) |
            (canAddRemoveLiquidity ? ASSET_CAN_ADD_REMOVE_LIQUIDITY : 0);
        emit SetAssetFlags(assetId, asset.flags, newFlags);
        asset.flags = newFlags;
        _updateSequence();
    }

    function setFundingParams(
        uint8 assetId,
        uint32 newBaseRate8H,
        uint32 newLimitRate8H
    ) external onlyOwner {
        require(_hasAsset(assetId), "LST"); // the asset is not LiSTed
        if (_storage.assets[assetId].isStable()) {
            _storage.shortFundingBaseRate8H = newBaseRate8H;
            _storage.shortFundingLimitRate8H = newLimitRate8H;
        } else {
            Asset storage asset = _storage.assets[assetId];
            asset.longFundingBaseRate8H = newBaseRate8H;
            asset.longFundingLimitRate8H = newLimitRate8H;
        }
        emit SetFundingParams(assetId, newBaseRate8H, newLimitRate8H);
        _updateSequence();
    }

    function setReferenceOracle(
        uint8 assetId,
        ReferenceOracleType referenceOracleType,
        address referenceOracle,
        uint32 referenceDeviation // 1e5
    ) external onlyOwner {
        LibReferenceOracle.checkParameters(referenceOracleType, referenceOracle, referenceDeviation);
        require(_hasAsset(assetId), "LST"); // the asset is not LiSTed
        Asset storage asset = _storage.assets[assetId];
        asset.referenceOracleType = uint8(referenceOracleType);
        asset.referenceOracle = referenceOracle;
        asset.referenceDeviation = referenceDeviation;
        emit SetReferenceOracle(assetId, uint8(referenceOracleType), referenceOracle, referenceDeviation);
        _updateSequence();
    }

    function setEmergencyNumbers(uint96 newMlpPriceLowerBound, uint96 newMlpPriceUpperBound) external onlyMaintainer {
        if (
            _storage.mlpPriceLowerBound != newMlpPriceLowerBound || _storage.mlpPriceUpperBound != newMlpPriceUpperBound
        ) {
            _storage.mlpPriceLowerBound = newMlpPriceLowerBound;
            _storage.mlpPriceUpperBound = newMlpPriceUpperBound;
            emit SetMlpPriceRange(newMlpPriceLowerBound, newMlpPriceUpperBound);
        }
        _updateSequence();
    }

    function setNumbers(
        uint32 newFundingInterval,
        uint32 newLiquidityBaseFeeRate, // 1e5
        uint32 newLiquidityDynamicFeeRate, // 1e5
        uint32 newStrictStableDeviation, // 1e5
        uint96 newBrokerGasRebate
    ) external onlyOwner {
        require(newLiquidityBaseFeeRate < 1e5, "F>1"); // %fee > 100%
        require(newLiquidityDynamicFeeRate < 1e5, "F>1"); // %fee > 100%
        require(newStrictStableDeviation < 1e5, "D>1"); // %deviation > 100%
        if (_storage.fundingInterval != newFundingInterval) {
            emit SetFundingInterval(_storage.fundingInterval, newFundingInterval);
            _storage.fundingInterval = newFundingInterval;
        }
        if (
            _storage.liquidityBaseFeeRate != newLiquidityBaseFeeRate ||
            _storage.liquidityDynamicFeeRate != newLiquidityDynamicFeeRate
        ) {
            _storage.liquidityBaseFeeRate = newLiquidityBaseFeeRate;
            _storage.liquidityDynamicFeeRate = newLiquidityDynamicFeeRate;
            emit SetLiquidityFee(newLiquidityBaseFeeRate, newLiquidityDynamicFeeRate);
        }
        if (_storage.strictStableDeviation != newStrictStableDeviation) {
            _storage.strictStableDeviation = newStrictStableDeviation;
            emit SetStrictStableDeviation(newStrictStableDeviation);
        }
        if (_storage.brokerGasRebate != newBrokerGasRebate) {
            _storage.brokerGasRebate = newBrokerGasRebate;
            emit SetBrokerGasRebate(newBrokerGasRebate);
        }
        _updateSequence();
    }

    function transferLiquidityOut(uint8[] memory assetIds, uint256[] memory rawAmounts) external onlyLiquidityManager {
        uint256 length = assetIds.length;
        require(length > 0, "MTY"); // argument array is eMpTY
        require(assetIds.length == rawAmounts.length, "LEN"); // LENgth of 2 arguments does not match
        for (uint256 i = 0; i < length; i++) {
            Asset storage asset = _storage.assets[assetIds[i]];
            IERC20Upgradeable(asset.tokenAddress).transfer(msg.sender, rawAmounts[i]);
            uint96 wadAmount = asset.toWad(rawAmounts[i]);
            require(asset.spotLiquidity >= wadAmount, "NLT"); // not enough liquidity
            asset.spotLiquidity -= wadAmount;
            emit TransferLiquidity(address(this), msg.sender, assetIds[i], rawAmounts[i]);
        }
        _updateSequence();
    }

    function transferLiquidityIn(uint8[] memory assetIds, uint256[] memory rawAmounts) external onlyLiquidityManager {
        uint256 length = assetIds.length;
        require(length > 0, "MTY"); // argument array is eMpTY
        require(assetIds.length == rawAmounts.length, "LEN"); // LENgth of 2 arguments does not match
        for (uint256 i = 0; i < length; i++) {
            Asset storage asset = _storage.assets[assetIds[i]];
            asset.spotLiquidity += asset.toWad(rawAmounts[i]);
            emit TransferLiquidity(msg.sender, address(this), assetIds[i], rawAmounts[i]);
        }
        _updateSequence();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SafeOwnableUpgradeable is OwnableUpgradeable {
    address internal _pendingOwner;

    event PrepareToTransferOwnership(address indexed pendingOwner);

    function __SafeOwnable_init() internal onlyInitializing {
        __Ownable_init();
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "O=0"); // Owner Is Zero
        require(newOwner != owner(), "O=O"); // Owner is the same as the old Owner
        _pendingOwner = newOwner;
        emit PrepareToTransferOwnership(_pendingOwner);
    }

    function takeOwnership() public virtual {
        require(_msgSender() == _pendingOwner, "SND"); // SeNDer is not authorized
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    function renounceOwnership() public virtual override onlyOwner {
        _pendingOwner = address(0);
        _transferOwnership(address(0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../core/Types.sol";

/**
 * SubAccountId
 *         96             88        80       72        0
 * +---------+--------------+---------+--------+--------+
 * | Account | collateralId | assetId | isLong | unused |
 * +---------+--------------+---------+--------+--------+
 */
library LibSubAccount {
    bytes32 constant SUB_ACCOUNT_ID_FORBIDDEN_BITS = bytes32(uint256(0xffffffffffffffffff));

    function getSubAccountOwner(bytes32 subAccountId) internal pure returns (address account) {
        account = address(uint160(uint256(subAccountId) >> 96));
    }

    function getSubAccountCollateralId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 88);
    }

    function isLong(bytes32 subAccountId) internal pure returns (bool) {
        return uint8((uint256(subAccountId) >> 72)) > 0;
    }

    struct DecodedSubAccountId {
        address account;
        uint8 collateralId;
        uint8 assetId;
        bool isLong;
    }

    function decodeSubAccountId(bytes32 subAccountId) internal pure returns (DecodedSubAccountId memory decoded) {
        require((subAccountId & SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        decoded.account = address(uint160(uint256(subAccountId) >> 96));
        decoded.collateralId = uint8(uint256(subAccountId) >> 88);
        decoded.assetId = uint8(uint256(subAccountId) >> 80);
        decoded.isLong = uint8((uint256(subAccountId) >> 72)) > 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../interfaces/IWETH9.sol";
import "../interfaces/INativeUnwrapper.sol";
import "../libraries/LibMath.sol";
import "../core/Types.sol";

library LibAsset {
    using LibMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    function transferOut(
        Asset storage token,
        address recipient,
        uint256 rawAmount,
        address weth,
        address nativeUnwrapper
    ) internal {
        if (token.tokenAddress == weth) {
            IWETH(weth).transfer(nativeUnwrapper, rawAmount);
            INativeUnwrapper(nativeUnwrapper).unwrap(payable(recipient), rawAmount);
        } else {
            IERC20Upgradeable(token.tokenAddress).safeTransfer(recipient, rawAmount);
        }
    }

    function issueMuxToken(
        Asset storage token,
        address recipient,
        uint256 muxTokenAmount
    ) internal {
        IERC20Upgradeable(token.muxTokenAddress).safeTransfer(recipient, muxTokenAmount);
    }

    function toWad(Asset storage token, uint256 rawAmount) internal view returns (uint96) {
        return (rawAmount * (10**(18 - token.decimals))).safeUint96();
    }

    function toRaw(Asset storage token, uint96 wadAmount) internal view returns (uint256) {
        return uint256(wadAmount) / 10**(18 - token.decimals);
    }

    // is a usdt, usdc, ...
    function isStable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_STABLE) != 0;
    }

    // can call addLiquidity and removeLiquidity with this token
    function canAddRemoveLiquidity(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_CAN_ADD_REMOVE_LIQUIDITY) != 0;
    }

    // allowed to be assetId
    function isTradable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_TRADABLE) != 0;
    }

    // can open position
    function isOpenable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_OPENABLE) != 0;
    }

    // allow shorting this asset
    function isShortable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_SHORTABLE) != 0;
    }

    // take profit will get stable coin
    function useStableTokenForProfit(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_USE_STABLE_TOKEN_FOR_PROFIT) != 0;
    }

    // allowed to be assetId and collateralId
    function isEnabled(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_ENABLED) != 0;
    }

    // assetPrice is always 1 unless volatility exceeds strictStableDeviation
    function isStrictStable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_STRICT_STABLE) != 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

struct LiquidityPoolStorage {
    // slot
    address orderBook;
    // slot
    address mlp;
    // slot
    address liquidityManager;
    // slot
    address weth;
    // slot
    uint128 _reserved1;
    uint32 shortFundingBaseRate8H; // 1e5
    uint32 shortFundingLimitRate8H; // 1e5
    uint32 fundingInterval; // 1e0
    uint32 lastFundingTime; // 1e0
    // slot
    uint32 _reserved2;
    // slot
    Asset[] assets;
    // slot
    mapping(bytes32 => SubAccount) accounts;
    // slot
    mapping(address => bytes32) _reserved3;
    // slot
    address _reserved4;
    uint96 _reserved5;
    // slot
    uint96 mlpPriceLowerBound; // safeguard against mlp price attacks
    uint96 mlpPriceUpperBound; // safeguard against mlp price attacks
    uint32 liquidityBaseFeeRate; // 1e5
    uint32 liquidityDynamicFeeRate; // 1e5
    // slot
    address nativeUnwrapper;
    // a sequence number that changes when LiquidityPoolStorage updated. this helps to keep track the state of LiquidityPool.
    uint32 sequence; // 1e0. note: will be 0 after 0xffffffff
    uint32 strictStableDeviation; // 1e5. strictStable price is 1.0 if in this damping range
    uint32 brokerTransactions; // transaction count for broker gas rebates
    // slot
    address vault;
    uint96 brokerGasRebate; // the number of native tokens for broker gas rebates per transaction
    // slot
    address maintainer;
    bytes32[50] _gap;
}

struct Asset {
    // slot
    // assets with the same symbol in different chains are the same asset. they shares the same muxToken. so debts of the same symbol
    // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
    // different chains are the same.
    // since muxToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
    // symbol can be different (ex: "USDT", "USDT.e" and "fUSDT").
    bytes32 symbol;
    // slot
    address tokenAddress; // erc20.address
    uint8 id;
    uint8 decimals; // erc20.decimals
    uint56 flags; // a bitset of ASSET_*
    uint24 _flagsPadding;
    // slot
    uint32 initialMarginRate; // 1e5
    uint32 maintenanceMarginRate; // 1e5
    uint32 minProfitRate; // 1e5
    uint32 minProfitTime; // 1e0
    uint32 positionFeeRate; // 1e5
    // note: 96 bits remaining
    // slot
    address referenceOracle;
    uint32 referenceDeviation; // 1e5
    uint8 referenceOracleType;
    uint32 halfSpread; // 1e5
    // note: 24 bits remaining
    // slot
    uint128 _reserved1;
    uint128 _reserved2;
    // slot
    uint96 collectedFee;
    uint32 _reserved3;
    uint96 spotLiquidity;
    // note: 32 bits remaining
    // slot
    uint96 maxLongPositionSize;
    uint96 totalLongPosition;
    // note: 64 bits remaining
    // slot
    uint96 averageLongPrice;
    uint96 maxShortPositionSize;
    // note: 64 bits remaining
    // slot
    uint96 totalShortPosition;
    uint96 averageShortPrice;
    // note: 64 bits remaining
    // slot, less used
    address muxTokenAddress; // muxToken.address. all stable coins share the same muxTokenAddress
    uint32 spotWeight; // 1e0
    uint32 longFundingBaseRate8H; // 1e5
    uint32 longFundingLimitRate8H; // 1e5
    // slot
    uint128 longCumulativeFundingRate; // Σ_t fundingRate_t
    uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t
}

uint32 constant FUNDING_PERIOD = 3600 * 8;

uint56 constant ASSET_IS_STABLE = 0x00000000000001; // is a usdt, usdc, ...
uint56 constant ASSET_CAN_ADD_REMOVE_LIQUIDITY = 0x00000000000002; // can call addLiquidity and removeLiquidity with this token
uint56 constant ASSET_IS_TRADABLE = 0x00000000000100; // allowed to be assetId
uint56 constant ASSET_IS_OPENABLE = 0x00000000010000; // can open position
uint56 constant ASSET_IS_SHORTABLE = 0x00000001000000; // allow shorting this asset
uint56 constant ASSET_USE_STABLE_TOKEN_FOR_PROFIT = 0x00000100000000; // take profit will get stable coin
uint56 constant ASSET_IS_ENABLED = 0x00010000000000; // allowed to be assetId and collateralId
uint56 constant ASSET_IS_STRICT_STABLE = 0x01000000000000; // assetPrice is always 1 unless volatility exceeds strictStableDeviation

struct SubAccount {
    // slot
    uint96 collateral;
    uint96 size;
    uint32 lastIncreasedTime;
    // slot
    uint96 entryPrice;
    uint128 entryFunding; // entry longCumulativeFundingRate for long position. entry shortCumulativeFunding for short position
}

enum ReferenceOracleType {
    None,
    Chainlink
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

contract Events {
    event UpdateSequence(uint32 sequence);

    //////////////////////////////////////////////////////////////////////////////////////
    //                                   trade
    struct OpenPositionArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        bool isLong;
        uint96 amount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 newEntryPrice;
        uint96 feeUsd;
        uint96 remainPosition;
        uint96 remainCollateral;
    }
    event OpenPosition(address indexed trader, uint8 indexed assetId, OpenPositionArgs args);
    struct ClosePositionArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint96 amount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 feeUsd;
        bool hasProfit;
        uint96 pnlUsd;
        uint96 remainPosition;
        uint96 remainCollateral;
    }
    event ClosePosition(address indexed trader, uint8 indexed assetId, ClosePositionArgs args);
    struct LiquidateArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint96 amount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 feeUsd;
        bool hasProfit;
        uint96 pnlUsd;
        uint96 remainCollateral;
    }
    event Liquidate(address indexed trader, uint8 indexed assetId, LiquidateArgs args);
    struct WithdrawProfitArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint256 withdrawRawAmount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 entryPrice;
        uint96 feeUsd;
    }
    event WithdrawProfit(address indexed trader, uint8 indexed assetId, WithdrawProfitArgs args);
    event CollectedFee(uint8 tokenId, uint96 fee);
    event ClaimBrokerGasRebate(address indexed receiver, uint32 transactions, uint256 rawAmount);

    //////////////////////////////////////////////////////////////////////////////////////
    //                                   liquidity
    event AddLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );
    event RemoveLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );
    event UpdateFundingRate(
        uint8 indexed tokenId,
        uint32 longFundingRate, // 1e5
        uint128 longCumulativeFundingRate, // Σ_t fundingRate_t
        uint32 shortFundingRate, // 1e5
        uint128 shortCumulativeFunding // Σ_t fundingRate_t * indexPrice_t
    );
    event IssueMuxToken(
        uint8 indexed tokenId, // if isStable, tokenId will always be 0
        bool isStable,
        uint96 muxTokenAmount
    );
    event RedeemMuxToken(address trader, uint8 tokenId, uint96 muxTokenAmount);
    event Rebalance(
        address indexed rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 price0,
        uint96 price1,
        uint96 rawAmount0,
        uint96 rawAmount1
    );

    //////////////////////////////////////////////////////////////////////////////////////
    //                                   admin
    event AddAsset(
        uint8 indexed id,
        bytes32 symbol,
        uint8 decimals,
        bool isStable,
        address tokenAddress,
        address muxTokenAddress
    );
    event SetAssetParams(
        uint8 indexed assetId,
        bytes32 symbol,
        uint32 newInitialMarginRate,
        uint32 newMaintenanceMarginRate,
        uint32 newPositionFeeRate,
        uint32 newMinProfitRate,
        uint32 newMinProfitTime,
        uint96 newMaxLongPositionSize,
        uint96 newMaxShortPositionSize,
        uint32 newSpotWeight,
        uint32 newHalfSpread
    );
    event SetAssetFlags(uint8 indexed assetId, uint56 oldFlags, uint56 newFlags);
    event SetReferenceOracle(
        uint8 indexed assetId,
        uint8 referenceOracleType,
        address referenceOracle,
        uint32 referenceDeviation
    );
    event SetFundingParams(uint8 indexed assetId, uint32 newBaseRate8H, uint32 newLimitRate8H);
    event SetFundingInterval(uint32 oldFundingInterval, uint32 newFundingInterval);
    event SetMlpPriceRange(uint96 newLowerBound, uint96 newUpperBound);
    event SetLiquidityFee(uint32 newLiquidityBaseFeeRate, uint32 newLiquidityDynamicFeeRate);
    event SetStrictStableDeviation(uint32 newStrictStableDeviation);
    event SetBrokerGasRebate(uint96 newBrokerGasRebate);
    event SetMaintainer(address indexed newMaintainer);
    event WithdrawCollectedFee(uint8 indexed assetId, uint96 collectedFee);
    event TransferLiquidity(address indexed sender, address indexed recipient, uint8 assetId, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface INativeUnwrapper {
    function unwrap(address payable to, uint256 rawAmount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

library LibMath {
    function min(uint96 a, uint96 b) internal pure returns (uint96) {
        return a <= b ? a : b;
    }

    function min32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a <= b ? a : b;
    }

    function max32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a >= b ? a : b;
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e18;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e5;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * 1e18) / b;
    }

    function safeUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "O32"); // uint32 Overflow
        return uint32(n);
    }

    function safeUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "O96"); // uint96 Overflow
        return uint96(n);
    }

    function safeUint128(uint256 n) internal pure returns (uint128) {
        require(n <= type(uint128).max, "O12"); // uint128 Overflow
        return uint128(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/**
 * @notice Any contract that calls IOrderBook#placeRebalanceOrder must implement this interface
 */
interface IMuxRebalancerCallback {
    /**
     * @notice Rebalancer.muxRebalanceCallback is called when Brokers calls IOrderBook#fillRebalanceOrder, where
     *         Rebalancer is `msg.sender` of IOrderBook#placeRebalanceOrder.
     *
     *         Rebalancer will get token0 and send token1 back to `msg.sender`.
     */
    function muxRebalanceCallback(
        address token0,
        address token1,
        uint256 rawAmount0,
        uint256 minRawAmount1,
        bytes32 data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../libraries/LibAsset.sol";
import "../libraries/LibReferenceOracle.sol";
import "./Storage.sol";

contract Account is Storage {
    using LibMath for uint256;
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using LibAsset for Asset;

    event DepositCollateral(
        bytes32 indexed subAccountId,
        address indexed trader,
        uint8 collateralId,
        uint256 rawAmount,
        uint96 wadAmount
    );
    event WithdrawCollateral(
        bytes32 indexed subAccountId,
        address indexed trader,
        uint8 collateralId,
        uint256 rawAmount,
        uint96 wadAmount
    );

    function depositCollateral(
        bytes32 subAccountId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external onlyOrderBook {
        LibSubAccount.DecodedSubAccountId memory decoded = subAccountId.decodeSubAccountId();
        require(decoded.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(decoded.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(decoded.assetId), "LST"); // the asset is not LiSTed
        require(rawAmount != 0, "A=0"); // Amount Is Zero

        SubAccount storage subAccount = _storage.accounts[subAccountId];
        Asset storage asset = _storage.assets[decoded.assetId];
        Asset storage collateral = _storage.assets[decoded.collateralId];
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        uint96 wadAmount = collateral.toWad(rawAmount);
        subAccount.collateral += wadAmount;

        emit DepositCollateral(subAccountId, decoded.account, decoded.collateralId, rawAmount, wadAmount);
        _updateSequence();
    }

    function withdrawCollateral(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external onlyOrderBook {
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        LibSubAccount.DecodedSubAccountId memory decoded = subAccountId.decodeSubAccountId();
        require(decoded.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(decoded.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(decoded.assetId), "LST"); // the asset is not LiSTed

        Asset storage asset = _storage.assets[decoded.assetId];
        Asset storage collateral = _storage.assets[decoded.collateralId];
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        assetPrice = LibReferenceOracle.checkPrice(_storage, asset, assetPrice);
        collateralPrice = LibReferenceOracle.checkPrice(_storage, collateral, collateralPrice);

        // fee & funding
        uint96 feeUsd = _getFundingFeeUsd(subAccount, asset, decoded.isLong, assetPrice);
        if (subAccount.size > 0) {
            _updateEntryFunding(subAccount, asset, decoded.isLong);
        }
        {
            uint96 feeCollateral = uint256(feeUsd).wdiv(collateralPrice).safeUint96();
            require(subAccount.collateral >= feeCollateral, "FEE"); // remaining collateral can not pay FEE
            subAccount.collateral -= feeCollateral;
            collateral.collectedFee += feeCollateral;
            collateral.spotLiquidity += feeCollateral;
            emit CollectedFee(decoded.collateralId, feeCollateral);
        }
        // withdraw
        uint96 wadAmount = collateral.toWad(rawAmount);
        require(subAccount.collateral >= wadAmount, "C<W"); // Collateral can not pay fee or is less than the amount requested for Withdrawal
        subAccount.collateral = subAccount.collateral - wadAmount;
        collateral.transferOut(decoded.account, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        require(_isAccountImSafe(subAccount, decoded.assetId, decoded.isLong, collateralPrice, assetPrice), "!IM");

        emit WithdrawCollateral(subAccountId, decoded.account, decoded.collateralId, rawAmount, wadAmount);
        _updateSequence();
    }

    function withdrawAllCollateral(bytes32 subAccountId) external onlyOrderBook {
        LibSubAccount.DecodedSubAccountId memory decoded = subAccountId.decodeSubAccountId();
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        require(subAccount.size == 0, "S>0"); // position Size should be Zero
        require(subAccount.collateral > 0, "C=0"); // Collateral Is Zero

        Asset storage asset = _storage.assets[decoded.assetId];
        Asset storage collateral = _storage.assets[decoded.collateralId];
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        uint96 wadAmount = subAccount.collateral;
        uint256 rawAmount = collateral.toRaw(wadAmount);
        subAccount.collateral = 0;
        collateral.transferOut(decoded.account, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        emit WithdrawCollateral(subAccountId, decoded.account, decoded.collateralId, rawAmount, wadAmount);
        _updateSequence();
    }

    function _positionPnlUsd(
        Asset storage asset,
        SubAccount storage subAccount,
        bool isLong,
        uint96 amount,
        uint96 assetPrice
    ) internal view returns (bool hasProfit, uint96 pnlUsd) {
        if (amount == 0) {
            return (false, 0);
        }
        require(assetPrice > 0, "P=0"); // Price Is Zero
        hasProfit = isLong ? assetPrice > subAccount.entryPrice : assetPrice < subAccount.entryPrice;
        uint96 priceDelta = assetPrice >= subAccount.entryPrice
            ? assetPrice - subAccount.entryPrice
            : subAccount.entryPrice - assetPrice;
        if (
            hasProfit &&
            _blockTimestamp() < subAccount.lastIncreasedTime + asset.minProfitTime &&
            priceDelta < uint256(subAccount.entryPrice).rmul(asset.minProfitRate).safeUint96()
        ) {
            hasProfit = false;
            return (false, 0);
        }
        pnlUsd = uint256(priceDelta).wmul(amount).safeUint96();
    }

    // NOTE: settle funding by modify subAccount.collateral before this function
    function _isAccountImSafe(
        SubAccount storage subAccount,
        uint32 assetId,
        bool isLong,
        uint96 collateralPrice,
        uint96 assetPrice
    ) internal view returns (bool) {
        Asset storage asset = _storage.assets[assetId];
        (bool hasProfit, uint96 pnlUsd) = _positionPnlUsd(asset, subAccount, isLong, subAccount.size, assetPrice);
        return _isAccountSafe(subAccount, collateralPrice, assetPrice, asset.initialMarginRate, hasProfit, pnlUsd, 0);
    }

    // NOTE: settle funding by modify subAccount.collateral before this function
    function _isAccountMmSafe(
        SubAccount storage subAccount,
        uint32 assetId,
        bool isLong,
        uint96 collateralPrice,
        uint96 assetPrice
    ) internal view returns (bool) {
        Asset storage asset = _storage.assets[assetId];
        (bool hasProfit, uint96 pnlUsd) = _positionPnlUsd(asset, subAccount, isLong, subAccount.size, assetPrice);
        return
            _isAccountSafe(subAccount, collateralPrice, assetPrice, asset.maintenanceMarginRate, hasProfit, pnlUsd, 0);
    }

    function _isAccountSafe(
        SubAccount storage subAccount,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint32 marginRate,
        bool hasProfit,
        uint96 pnlUsd,
        uint96 fundingFee // fundingFee = 0 if subAccount.collateral was modified
    ) internal view returns (bool) {
        uint256 thresholdUsd = (uint256(subAccount.size) * uint256(assetPrice) * uint256(marginRate)) / 1e18 / 1e5;
        thresholdUsd += fundingFee;
        uint256 collateralUsd = uint256(subAccount.collateral).wmul(collateralPrice);
        // break down "collateralUsd +/- pnlUsd >= thresholdUsd >= 0"
        if (hasProfit) {
            return collateralUsd + pnlUsd >= thresholdUsd;
        } else {
            return collateralUsd >= thresholdUsd + pnlUsd;
        }
    }

    function _getFeeUsd(
        SubAccount storage subAccount,
        Asset storage asset,
        bool isLong,
        uint96 amount,
        uint96 assetPrice
    ) internal view returns (uint96) {
        return _getFundingFeeUsd(subAccount, asset, isLong, assetPrice) + _getPositionFeeUsd(asset, amount, assetPrice);
    }

    function _getFundingFeeUsd(
        SubAccount storage subAccount,
        Asset storage asset,
        bool isLong,
        uint96 assetPrice
    ) internal view returns (uint96) {
        if (subAccount.size == 0) {
            return 0;
        }
        uint256 cumulativeFunding;
        if (isLong) {
            cumulativeFunding = asset.longCumulativeFundingRate - subAccount.entryFunding;
            cumulativeFunding = cumulativeFunding.wmul(assetPrice);
        } else {
            cumulativeFunding = asset.shortCumulativeFunding - subAccount.entryFunding;
        }
        return cumulativeFunding.wmul(subAccount.size).safeUint96();
    }

    function _getPositionFeeUsd(
        Asset storage asset,
        uint96 amount,
        uint96 assetPrice
    ) internal view returns (uint96) {
        uint256 feeUsd = ((uint256(assetPrice) * uint256(asset.positionFeeRate)) * uint256(amount)) / 1e5 / 1e18;
        return feeUsd.safeUint96();
    }

    // note: you can skip this function if newPositionSize > 0
    function _updateEntryFunding(
        SubAccount storage subAccount,
        Asset storage asset,
        bool isLong
    ) internal {
        if (isLong) {
            subAccount.entryFunding = asset.longCumulativeFundingRate;
        } else {
            subAccount.entryFunding = asset.shortCumulativeFunding;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../core/Types.sol";
import "./LibMath.sol";
import "./LibAsset.sol";

interface IChainlink {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface IChainlinkV3 {
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

interface IChainlinkV2V3 is IChainlink, IChainlinkV3 {}

enum SpreadType {
    Ask,
    Bid
}

library LibReferenceOracle {
    using LibMath for uint256;
    using LibMath for uint96;
    using LibAsset for Asset;

    // indicate that the asset price is too far away from reference oracle
    event AssetPriceOutOfRange(uint8 assetId, uint96 price, uint96 referencePrice, uint32 deviation);

    /**
     * @dev Check oracle parameters before set
     */
    function checkParameters(
        ReferenceOracleType referenceOracleType,
        address referenceOracle,
        uint32 referenceDeviation
    ) internal view {
        require(referenceDeviation <= 1e5, "D>1"); // %deviation > 100%
        if (referenceOracleType == ReferenceOracleType.Chainlink) {
            IChainlinkV2V3 o = IChainlinkV2V3(referenceOracle);
            require(o.decimals() == 8, "!D8"); // we only support decimals = 8
            require(o.latestAnswer() > 0, "P=0"); // oracle Price <= 0
        }
    }

    /**
     * @dev Truncate price if the error is too large
     */
    function checkPrice(
        LiquidityPoolStorage storage pool,
        Asset storage asset,
        uint96 price
    ) internal returns (uint96) {
        require(price != 0, "P=0"); // broker price = 0

        // truncate price if the error is too large
        if (ReferenceOracleType(asset.referenceOracleType) == ReferenceOracleType.Chainlink) {
            uint96 ref = _readChainlink(asset.referenceOracle);
            price = _truncatePrice(asset, price, ref);
        }

        // strict stable dampener
        if (asset.isStrictStable()) {
            uint256 delta = price > 1e18 ? price - 1e18 : 1e18 - price;
            uint256 dampener = uint256(pool.strictStableDeviation) * 1e13; // 1e5 => 1e18
            if (delta <= dampener) {
                price = 1e18;
            }
        }

        return price;
    }

    /**
     * @dev check price and add spread, where spreadType should be:
     *
     *      subAccount.isLong   openPosition   closePosition   addLiquidity   removeLiquidity
     *      long                ask            bid
     *      short               bid            ask
     *      N/A                                                bid            ask
     */
    function checkPriceWithSpread(
        LiquidityPoolStorage storage pool,
        Asset storage asset,
        uint96 price,
        SpreadType spreadType
    ) internal returns (uint96) {
        price = checkPrice(pool, asset, price);
        price = _addSpread(asset, price, spreadType);
        return price;
    }

    function _readChainlink(address referenceOracle) internal view returns (uint96) {
        int256 ref = IChainlinkV2V3(referenceOracle).latestAnswer();
        require(ref > 0, "P=0"); // oracle Price <= 0
        ref *= 1e10; // decimals 8 => 18
        return uint256(ref).safeUint96();
    }

    function _truncatePrice(
        Asset storage asset,
        uint96 price,
        uint96 ref
    ) private returns (uint96) {
        if (asset.referenceDeviation == 0) {
            return ref;
        }
        uint256 deviation = uint256(ref).rmul(asset.referenceDeviation);
        uint96 bound = (uint256(ref) - deviation).safeUint96();
        if (price < bound) {
            emit AssetPriceOutOfRange(asset.id, price, ref, asset.referenceDeviation);
            price = bound;
        }
        bound = (uint256(ref) + deviation).safeUint96();
        if (price > bound) {
            emit AssetPriceOutOfRange(asset.id, price, ref, asset.referenceDeviation);
            price = bound;
        }
        return price;
    }

    function _addSpread(
        Asset storage asset,
        uint96 price,
        SpreadType spreadType
    ) private view returns (uint96) {
        if (asset.halfSpread == 0) {
            return price;
        }
        uint96 halfSpread = uint256(price).rmul(asset.halfSpread).safeUint96();
        if (spreadType == SpreadType.Bid) {
            require(price > halfSpread, "P=0"); // Price - halfSpread = 0. impossible
            return price - halfSpread;
        } else {
            return price + halfSpread;
        }
    }
}