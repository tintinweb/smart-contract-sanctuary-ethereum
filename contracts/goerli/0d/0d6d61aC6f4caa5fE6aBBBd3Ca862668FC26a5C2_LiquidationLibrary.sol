// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/ICdpManagerData.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/IEBTCToken.sol";
import "./Interfaces/ISortedCdps.sol";
import "./Dependencies/ICollateralTokenOracle.sol";
import "./CdpManagerStorage.sol";

contract LiquidationLibrary is CdpManagerStorage {
    constructor(
        address _borrowerOperationsAddress,
        address _collSurplusPool,
        address _ebtcToken,
        address _sortedCdps,
        address _activePool,
        address _priceFeed,
        address _collateral
    )
        CdpManagerStorage(
            address(0),
            address(0),
            _borrowerOperationsAddress,
            _collSurplusPool,
            _ebtcToken,
            _sortedCdps,
            _activePool,
            _priceFeed,
            _collateral
        )
    {}

    /// @notice Single CDP liquidation function (fully).
    /// @notice callable by anyone, attempts to liquidate the CdpId. Executes successfully if Cdp meets the conditions for liquidation (e.g. in Normal Mode, it liquidates if the Cdp's ICR < the system MCR).
    function liquidate(bytes32 _cdpId) external nonReentrantSelfAndBOps {
        _liquidateSingle(_cdpId, 0, _cdpId, _cdpId);
    }

    // Single CDP liquidation function (partially).
    function partiallyLiquidate(
        bytes32 _cdpId,
        uint256 _partialAmount,
        bytes32 _upperPartialHint,
        bytes32 _lowerPartialHint
    ) external nonReentrantSelfAndBOps {
        _liquidateSingle(_cdpId, _partialAmount, _upperPartialHint, _lowerPartialHint);
    }

    // Single CDP liquidation function.
    function _liquidateSingle(
        bytes32 _cdpId,
        uint _partialAmount,
        bytes32 _upperPartialHint,
        bytes32 _lowerPartialHint
    ) internal {
        _requireCdpIsActive(_cdpId);

        _applyAccumulatedFeeSplit(_cdpId);

        uint256 _price = priceFeed.fetchPrice();

        // prepare local variables
        uint256 _ICR = getCurrentICR(_cdpId, _price);
        (uint _TCR, uint systemColl, uint systemDebt) = _getTCRWithTotalCollAndDebt(_price);

        require(_ICR < MCR || (_TCR < CCR && _ICR < _TCR), "!_ICR");

        bool _recoveryModeAtStart = _TCR < CCR ? true : false;
        LocalVar_InternalLiquidate memory _liqState = LocalVar_InternalLiquidate(
            _cdpId,
            _partialAmount,
            _price,
            _ICR,
            _upperPartialHint,
            _lowerPartialHint,
            (_recoveryModeAtStart),
            _TCR,
            0,
            0,
            0,
            0,
            0,
            false
        );

        LocalVar_RecoveryLiquidate memory _rs = LocalVar_RecoveryLiquidate(
            systemDebt,
            systemColl,
            0,
            0,
            0,
            _cdpId,
            _price,
            _ICR,
            0,
            0,
            false
        );

        _liquidateSingleCDP(_liqState, _rs);
    }

    // liquidate given CDP by repaying debt in full or partially if its ICR is below MCR or TCR in recovery mode.
    // For partial liquidation, caller should use HintHelper smart contract to get correct hints for reinsertion into sorted CDP list
    function _liquidateSingleCDP(
        LocalVar_InternalLiquidate memory _liqState,
        LocalVar_RecoveryLiquidate memory _recoveryState
    ) internal {
        uint256 totalDebtToBurn;
        uint256 totalColToSend;
        uint256 totalDebtToRedistribute;
        uint256 totalColReward;

        if (_liqState._partialAmount == 0) {
            (
                totalDebtToBurn,
                totalColToSend,
                totalDebtToRedistribute,
                totalColReward
            ) = _liquidateCDPByExternalLiquidator(_liqState, _recoveryState);
        } else {
            (totalDebtToBurn, totalColToSend) = _liquidateCDPPartially(_liqState);
            if (totalColToSend == 0 && totalDebtToBurn == 0) {
                // retry with fully liquidation
                (
                    totalDebtToBurn,
                    totalColToSend,
                    totalDebtToRedistribute,
                    totalColReward
                ) = _liquidateCDPByExternalLiquidator(_liqState, _recoveryState);
            }
        }

        _finalizeExternalLiquidation(
            totalDebtToBurn,
            totalColToSend,
            totalDebtToRedistribute,
            totalColReward
        );
    }

    // liquidate (and close) the CDP from an external liquidator
    // this function would return the liquidated debt and collateral of the given CDP
    function _liquidateCDPByExternalLiquidator(
        LocalVar_InternalLiquidate memory _liqState,
        LocalVar_RecoveryLiquidate memory _recoveryState
    ) private returns (uint256, uint256, uint256, uint256) {
        if (_liqState._recoveryModeAtStart) {
            LocalVar_RecoveryLiquidate memory _outputState = _liquidateSingleCDPInRecoveryMode(
                _recoveryState
            );

            // housekeeping leftover collateral for liquidated CDP
            if (_outputState.totalColSurplus > 0) {
                activePool.sendStEthColl(address(collSurplusPool), _outputState.totalColSurplus);
            }

            return (
                _outputState.totalDebtToBurn,
                _outputState.totalColToSend,
                _outputState.totalDebtToRedistribute,
                _outputState.totalColReward
            );
        } else {
            LocalVar_InternalLiquidate memory _outputState = _liquidateSingleCDPInNormalMode(
                _liqState
            );
            return (
                _outputState.totalDebtToBurn,
                _outputState.totalColToSend,
                _outputState.totalDebtToRedistribute,
                _outputState.totalColReward
            );
        }
    }

    function _liquidateSingleCDPInNormalMode(
        LocalVar_InternalLiquidate memory _liqState
    ) private returns (LocalVar_InternalLiquidate memory) {
        // liquidate entire debt
        (
            uint256 _totalDebtToBurn,
            uint256 _totalColToSend,
            uint256 _liquidatorReward
        ) = _liquidateCDPByExternalLiquidatorWithoutEvent(_liqState._cdpId, _liqState.sequenceLiq);
        uint256 _cappedColPortion;
        uint256 _collSurplus;
        uint256 _debtToRedistribute;
        address _borrower = sortedCdps.getOwnerAddress(_liqState._cdpId);

        // I don't see an issue emitting the CdpUpdated() event up here and avoiding this extra cache, any objections?
        emit CdpUpdated(
            _liqState._cdpId,
            _borrower,
            _totalDebtToBurn,
            _totalColToSend,
            0,
            0,
            0,
            CdpManagerOperation.liquidateInNormalMode
        );

        {
            (_cappedColPortion, _collSurplus, _debtToRedistribute) = _calculateSurplusAndCap(
                _liqState._ICR,
                _liqState._price,
                _totalDebtToBurn,
                _totalColToSend,
                true,
                _liquidatorReward
            );
            if (_collSurplus > 0) {
                // due to division precision loss, should be zero surplus in normal mode
                _cappedColPortion = _cappedColPortion + _collSurplus;
                _collSurplus = 0;
            }
            if (_debtToRedistribute > 0) {
                _totalDebtToBurn = _totalDebtToBurn - _debtToRedistribute;
            }
        }
        _liqState.totalDebtToBurn = _liqState.totalDebtToBurn + _totalDebtToBurn;
        _liqState.totalColToSend = _liqState.totalColToSend + _cappedColPortion;
        _liqState.totalDebtToRedistribute = _liqState.totalDebtToRedistribute + _debtToRedistribute;
        _liqState.totalColReward = _liqState.totalColReward + _liquidatorReward;

        // Emit events
        emit CdpLiquidated(
            _liqState._cdpId,
            _borrower,
            _totalDebtToBurn,
            _cappedColPortion,
            CdpManagerOperation.liquidateInNormalMode
        );

        return _liqState;
    }

    function _liquidateSingleCDPInRecoveryMode(
        LocalVar_RecoveryLiquidate memory _recoveryState
    ) private returns (LocalVar_RecoveryLiquidate memory) {
        // liquidate entire debt
        (
            uint256 _totalDebtToBurn,
            uint256 _totalColToSend,
            uint256 _liquidatorReward
        ) = _liquidateCDPByExternalLiquidatorWithoutEvent(
                _recoveryState._cdpId,
                _recoveryState.sequenceLiq
            );

        // cap the liquidated collateral if required
        uint256 _cappedColPortion;
        uint256 _collSurplus;
        uint256 _debtToRedistribute;
        address _borrower = sortedCdps.getOwnerAddress(_recoveryState._cdpId);

        // I don't see an issue emitting the CdpUpdated() event up here and avoiding an extra cache of the values, any objections?
        emit CdpUpdated(
            _recoveryState._cdpId,
            _borrower,
            _totalDebtToBurn,
            _totalColToSend,
            0,
            0,
            0,
            CdpManagerOperation.liquidateInRecoveryMode
        );

        // avoid stack too deep
        {
            (_cappedColPortion, _collSurplus, _debtToRedistribute) = _calculateSurplusAndCap(
                _recoveryState._ICR,
                _recoveryState._price,
                _totalDebtToBurn,
                _totalColToSend,
                true,
                _liquidatorReward
            );
            if (_collSurplus > 0) {
                collSurplusPool.accountSurplus(_borrower, _collSurplus);
                _recoveryState.totalColSurplus = _recoveryState.totalColSurplus + _collSurplus;
            }
            if (_debtToRedistribute > 0) {
                _totalDebtToBurn = _totalDebtToBurn - _debtToRedistribute;
            }
        }
        _recoveryState.totalDebtToBurn = _recoveryState.totalDebtToBurn + _totalDebtToBurn;
        _recoveryState.totalColToSend = _recoveryState.totalColToSend + _cappedColPortion;
        _recoveryState.totalDebtToRedistribute =
            _recoveryState.totalDebtToRedistribute +
            _debtToRedistribute;
        _recoveryState.totalColReward = _recoveryState.totalColReward + _liquidatorReward;

        // check if system back to normal mode
        _recoveryState.entireSystemDebt = _recoveryState.entireSystemDebt > _totalDebtToBurn
            ? _recoveryState.entireSystemDebt - _totalDebtToBurn
            : 0;
        _recoveryState.entireSystemColl = _recoveryState.entireSystemColl > _totalColToSend
            ? _recoveryState.entireSystemColl - _totalColToSend
            : 0;

        emit CdpLiquidated(
            _recoveryState._cdpId,
            _borrower,
            _totalDebtToBurn,
            _cappedColPortion,
            CdpManagerOperation.liquidateInRecoveryMode
        );

        return _recoveryState;
    }

    // liquidate (and close) the CDP from an external liquidator
    // this function would return the liquidated debt and collateral of the given CDP
    // without emmiting events
    function _liquidateCDPByExternalLiquidatorWithoutEvent(
        bytes32 _cdpId,
        bool _sequenceLiq
    ) private returns (uint256, uint256, uint256) {
        // calculate entire debt to repay
        (uint256 entireDebt, uint256 entireColl, uint256 pendingDebtReward) = getEntireDebtAndColl(
            _cdpId
        );

        // housekeeping after liquidation by closing the CDP
        _removeStake(_cdpId);
        uint _liquidatorReward = Cdps[_cdpId].liquidatorRewardShares;
        if (_sequenceLiq) {
            _closeCdpWithoutRemovingSortedCdps(_cdpId, Status.closedByLiquidation);
        } else {
            _closeCdp(_cdpId, Status.closedByLiquidation);
        }

        return (entireDebt, entireColl, _liquidatorReward);
    }

    // Liquidate partially the CDP by an external liquidator
    // This function would return the liquidated debt and collateral of the given CDP
    function _liquidateCDPPartially(
        LocalVar_InternalLiquidate memory _partialState
    ) private returns (uint256, uint256) {
        bytes32 _cdpId = _partialState._cdpId;
        uint _partialDebt = _partialState._partialAmount;

        // calculate entire debt to repay
        LocalVar_CdpDebtColl memory _debtAndColl = _getEntireDebtAndColl(_cdpId);
        _requirePartialLiqDebtSize(_partialDebt, _debtAndColl.entireDebt, _partialState._price);
        uint newDebt = _debtAndColl.entireDebt - _partialDebt;

        // credit to https://arxiv.org/pdf/2212.07306.pdf for details
        (uint _partialColl, uint newColl, ) = _calculateSurplusAndCap(
            _partialState._ICR,
            _partialState._price,
            _partialDebt,
            _debtAndColl.entireColl,
            false,
            0
        );

        // early return: if new collateral is zero, we have a full liqudiation
        if (newColl == 0) {
            return (0, 0);
        }

        // If we have coll remaining, it must meet minimum CDP size requirements:
        // Only check when the collateral exchange rate from share is above 1e18
        // If there is big decrease due to slashing, some CDP might already fall below minimum collateral requirements
        if (collateral.getPooledEthByShares(1e18) >= 1e18) {
            _requirePartialLiqCollSize(collateral.getPooledEthByShares(newColl));
        }

        // apply pending debt if any
        // and update CDP internal accounting for debt
        // if there is liquidation redistribution
        {
            if (_debtAndColl.pendingDebtReward > 0) {
                Cdps[_cdpId].debt = Cdps[_cdpId].debt + _debtAndColl.pendingDebtReward;
            }
        }

        // updating the CDP accounting for partial liquidation
        _partiallyReduceCdpDebt(_cdpId, _partialDebt, _partialColl);

        // reInsert into sorted CDP list after partial liquidation
        {
            _reInsertPartialLiquidation(
                _partialState,
                LiquityMath._computeNominalCR(newColl, newDebt),
                _debtAndColl.entireDebt,
                _debtAndColl.entireColl
            );
            emit CdpPartiallyLiquidated(
                _cdpId,
                sortedCdps.getOwnerAddress(_cdpId),
                _partialDebt,
                _partialColl,
                CdpManagerOperation.partiallyLiquidate
            );
        }
        return (_partialDebt, _partialColl);
    }

    // return CdpId array (in NICR-decreasing order same as SortedCdps)
    // including the last N CDPs in sortedCdps for batch liquidation
    function _sequenceLiqToBatchLiq(
        uint _n,
        bool _recovery,
        uint _price
    ) internal view returns (bytes32[] memory _array) {
        if (_n > 0) {
            bytes32 _last = sortedCdps.getLast();
            bytes32 _first = sortedCdps.getFirst();
            bytes32 _cdpId = _last;

            uint _TCR = _getTCR(_price);

            // get count of liquidatable CDPs
            uint _cnt;
            for (uint i = 0; i < _n && _cdpId != _first; ++i) {
                uint _icr = getCurrentICR(_cdpId, _price);
                bool _liquidatable = _recovery ? (_icr < MCR || _icr < _TCR) : _icr < MCR;
                if (_liquidatable && Cdps[_cdpId].status == Status.active) {
                    _cnt += 1;
                }
                _cdpId = sortedCdps.getPrev(_cdpId);
            }

            // retrieve liquidatable CDPs
            _array = new bytes32[](_cnt);
            _cdpId = _last;
            uint _j;
            for (uint i = 0; i < _n && _cdpId != _first; ++i) {
                uint _icr = getCurrentICR(_cdpId, _price);
                bool _liquidatable = _recovery ? (_icr < MCR || _icr < _TCR) : _icr < MCR;
                if (_liquidatable && Cdps[_cdpId].status == Status.active) {
                    _array[_cnt - _j - 1] = _cdpId;
                    _j += 1;
                }
                _cdpId = sortedCdps.getPrev(_cdpId);
            }
            require(_j == _cnt, "LiquidationLibrary: wrong sequence conversion!");
        }
    }

    function _partiallyReduceCdpDebt(bytes32 _cdpId, uint _partialDebt, uint _partialColl) internal {
        Cdp storage _cdp = Cdps[_cdpId];
        uint _coll = _cdp.coll;
        uint _debt = _cdp.debt;

        _cdp.coll = _coll - _partialColl;
        _cdp.debt = _debt - _partialDebt;
        _updateStakeAndTotalStakes(_cdpId);

        _updateCdpRewardSnapshots(_cdpId);
    }

    // Re-Insertion into SortedCdp list after partial liquidation
    function _reInsertPartialLiquidation(
        LocalVar_InternalLiquidate memory _partialState,
        uint _newNICR,
        uint _oldDebt,
        uint _oldColl
    ) internal {
        bytes32 _cdpId = _partialState._cdpId;

        // ensure new ICR does NOT decrease due to partial liquidation
        // if original ICR is above LICR
        if (_partialState._ICR > LICR) {
            require(
                getCurrentICR(_cdpId, _partialState._price) >= _partialState._ICR,
                "!_newICR>=_ICR"
            );
        }

        // reInsert into sorted CDP list
        sortedCdps.reInsert(
            _cdpId,
            _newNICR,
            _partialState._upperPartialHint,
            _partialState._lowerPartialHint
        );
        emit CdpUpdated(
            _cdpId,
            sortedCdps.getOwnerAddress(_cdpId),
            _oldDebt,
            _oldColl,
            Cdps[_cdpId].debt,
            Cdps[_cdpId].coll,
            Cdps[_cdpId].stake,
            CdpManagerOperation.partiallyLiquidate
        );
    }

    function _finalizeExternalLiquidation(
        uint256 totalDebtToBurn,
        uint256 totalColToSend,
        uint256 totalDebtToRedistribute,
        uint256 totalColReward
    ) internal {
        // update the staking and collateral snapshots
        _updateSystemSnapshots_excludeCollRemainder(totalColToSend);

        emit Liquidation(totalDebtToBurn, totalColToSend, totalColReward);

        // redistribute debt if any
        if (totalDebtToRedistribute > 0) {
            _redistributeDebt(totalDebtToRedistribute);
        }

        // burn the debt from liquidator
        ebtcToken.burn(msg.sender, totalDebtToBurn);

        // offset debt from Active Pool
        activePool.decreaseEBTCDebt(totalDebtToBurn);

        // CEI: ensure sending back collateral to liquidator is last thing to do
        activePool.sendStEthCollAndLiquidatorReward(msg.sender, totalColToSend, totalColReward);
    }

    // Function that calculates the amount of collateral to send to liquidator (plus incentive) and the amount of collateral surplus
    function _calculateSurplusAndCap(
        uint _ICR,
        uint _price,
        uint _totalDebtToBurn,
        uint _totalColToSend,
        bool _fullLiquidation,
        uint _liquidatorReward
    ) private view returns (uint cappedColPortion, uint collSurplus, uint debtToRedistribute) {
        // Calculate liquidation incentive for liquidator:
        // If ICR is less than 103%: give away 103% worth of collateral to liquidator, i.e., repaidDebt * 103% / price
        // If ICR is more than 103%: give away min(ICR, 110%) worth of collateral to liquidator, i.e., repaidDebt * min(ICR, 110%) / price
        uint _incentiveColl;
        if (_ICR > LICR) {
            _incentiveColl = (_totalDebtToBurn * (_ICR > MCR ? MCR : _ICR)) / _price;
        } else {
            if (_fullLiquidation) {
                // for full liquidation, there would be some bad debt to redistribute
                _incentiveColl = collateral.getPooledEthByShares(_totalColToSend);
                uint _debtToRepay = (_incentiveColl * _price) / LICR;
                debtToRedistribute = _debtToRepay < _totalDebtToBurn
                    ? _totalDebtToBurn - _debtToRepay
                    : 0;
            } else {
                // for partial liquidation, new ICR would deteriorate
                // since we give more incentive (103%) than current _ICR allowed
                _incentiveColl = (_totalDebtToBurn * LICR) / _price;
            }
        }
        cappedColPortion = collateral.getSharesByPooledEth(_incentiveColl);
        cappedColPortion = cappedColPortion < _totalColToSend ? cappedColPortion : _totalColToSend;
        collSurplus = (cappedColPortion == _totalColToSend) ? 0 : _totalColToSend - cappedColPortion;
    }

    // --- Batch/Sequence liquidation functions ---

    /*
     * Liquidate a sequence of cdps. Closes a maximum number of n cdps with their CR < MCR or CR < TCR in reocvery mode,
     * starting from the one with the lowest collateral ratio in the system, and moving upwards

     callable by anyone, checks for under-collateralized Cdps below MCR and liquidates up to `n`, starting from the Cdp with the lowest collateralization ratio; subject to gas constraints and the actual number of under-collateralized Cdps. The gas costs of `liquidateCdps(uint n)` mainly depend on the number of Cdps that are liquidated, and whether the Cdps are offset against the Stability Pool or redistributed. For n=1, the gas costs per liquidated Cdp are roughly between 215K-400K, for n=5 between 80K-115K, for n=10 between 70K-82K, and for n=50 between 60K-65K.
     */
    function liquidateCdps(uint _n) external nonReentrantSelfAndBOps {
        require(_n > 0, "LiquidationLibrary: can't liquidate zero CDP in sequence");

        LocalVariables_OuterLiquidationFunction memory vars;

        LiquidationTotals memory totals;

        // taking fee to avoid accounted for the calculation of the TCR
        claimStakingSplitFee();

        vars.price = priceFeed.fetchPrice();
        (uint _TCR, uint systemColl, uint systemDebt) = _getTCRWithTotalCollAndDebt(vars.price);
        vars.recoveryModeAtStart = _TCR < CCR ? true : false;

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        bytes32[] memory _batchedCdps;
        if (vars.recoveryModeAtStart) {
            _batchedCdps = _sequenceLiqToBatchLiq(_n, true, vars.price);
            totals = _getTotalFromBatchLiquidate_RecoveryMode(
                vars.price,
                systemColl,
                systemDebt,
                _batchedCdps,
                true
            );
        } else {
            // if !vars.recoveryModeAtStart
            _batchedCdps = _sequenceLiqToBatchLiq(_n, false, vars.price);
            totals = _getTotalsFromBatchLiquidate_NormalMode(vars.price, _TCR, _batchedCdps, true);
        }

        require(totals.totalDebtInSequence > 0, "LiquidationLibrary: nothing to liquidate");

        // housekeeping leftover collateral for liquidated CDPs
        if (totals.totalCollSurplus > 0) {
            activePool.sendStEthColl(address(collSurplusPool), totals.totalCollSurplus);
        }

        _finalizeExternalLiquidation(
            totals.totalDebtToOffset,
            totals.totalCollToSendToLiquidator,
            totals.totalDebtToRedistribute,
            totals.totalCollReward
        );
    }

    function _getLiquidationValuesNormalMode(
        uint _price,
        uint _TCR,
        LocalVariables_LiquidationSequence memory vars,
        LiquidationValues memory singleLiquidation,
        bool sequenceLiq
    ) internal {
        LocalVar_InternalLiquidate memory _liqState = LocalVar_InternalLiquidate(
            vars.cdpId,
            0,
            _price,
            vars.ICR,
            vars.cdpId,
            vars.cdpId,
            (false),
            _TCR,
            0,
            0,
            0,
            0,
            0,
            sequenceLiq
        );

        LocalVar_InternalLiquidate memory _outputState = _liquidateSingleCDPInNormalMode(_liqState);

        singleLiquidation.entireCdpDebt = _outputState.totalDebtToBurn;
        singleLiquidation.debtToOffset = _outputState.totalDebtToBurn;
        singleLiquidation.totalCollToSendToLiquidator = _outputState.totalColToSend;
        singleLiquidation.collSurplus = _outputState.totalColSurplus;
        singleLiquidation.debtToRedistribute = _outputState.totalDebtToRedistribute;
        singleLiquidation.collReward = _outputState.totalColReward;
    }

    function _getLiquidationValuesRecoveryMode(
        uint _price,
        uint _systemDebt,
        uint _systemColl,
        LocalVariables_LiquidationSequence memory vars,
        LiquidationValues memory singleLiquidation,
        bool sequenceLiq
    ) internal {
        LocalVar_RecoveryLiquidate memory _recState = LocalVar_RecoveryLiquidate(
            _systemDebt,
            _systemColl,
            0,
            0,
            0,
            vars.cdpId,
            _price,
            vars.ICR,
            0,
            0,
            sequenceLiq
        );

        LocalVar_RecoveryLiquidate memory _outputState = _liquidateSingleCDPInRecoveryMode(
            _recState
        );

        singleLiquidation.entireCdpDebt = _outputState.totalDebtToBurn;
        singleLiquidation.debtToOffset = _outputState.totalDebtToBurn;
        singleLiquidation.totalCollToSendToLiquidator = _outputState.totalColToSend;
        singleLiquidation.collSurplus = _outputState.totalColSurplus;
        singleLiquidation.debtToRedistribute = _outputState.totalDebtToRedistribute;
        singleLiquidation.collReward = _outputState.totalColReward;
    }

    /*
     * Attempt to liquidate a custom list of cdps provided by the caller.

     callable by anyone, accepts a custom list of Cdps addresses as an argument. Steps through the provided list and attempts to liquidate every Cdp, until it reaches the end or it runs out of gas. A Cdp is liquidated only if it meets the conditions for liquidation. For a batch of 10 Cdps, the gas costs per liquidated Cdp are roughly between 75K-83K, for a batch of 50 Cdps between 54K-69K.
     */
    function batchLiquidateCdps(bytes32[] memory _cdpArray) external nonReentrantSelfAndBOps {
        require(
            _cdpArray.length != 0,
            "LiquidationLibrary: Calldata address array must not be empty"
        );

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        // taking fee to avoid accounted for the calculation of the TCR
        claimStakingSplitFee();

        vars.price = priceFeed.fetchPrice();
        (uint _TCR, uint systemColl, uint systemDebt) = _getTCRWithTotalCollAndDebt(vars.price);
        vars.recoveryModeAtStart = _TCR < CCR ? true : false;

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        if (vars.recoveryModeAtStart) {
            totals = _getTotalFromBatchLiquidate_RecoveryMode(
                vars.price,
                systemColl,
                systemDebt,
                _cdpArray,
                false
            );
        } else {
            //  if !vars.recoveryModeAtStart
            totals = _getTotalsFromBatchLiquidate_NormalMode(vars.price, _TCR, _cdpArray, false);
        }

        require(totals.totalDebtInSequence > 0, "LiquidationLibrary: nothing to liquidate");

        // housekeeping leftover collateral for liquidated CDPs
        if (totals.totalCollSurplus > 0) {
            activePool.sendStEthColl(address(collSurplusPool), totals.totalCollSurplus);
        }

        _finalizeExternalLiquidation(
            totals.totalDebtToOffset,
            totals.totalCollToSendToLiquidator,
            totals.totalDebtToRedistribute,
            totals.totalCollReward
        );
    }

    /*
     * This function is used when the batch liquidation sequence starts during Recovery Mode. However, it
     * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
     */
    function _getTotalFromBatchLiquidate_RecoveryMode(
        uint _price,
        uint _systemColl,
        uint _systemDebt,
        bytes32[] memory _cdpArray,
        bool sequenceLiq
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.backToNormalMode = false;
        vars.entireSystemDebt = _systemDebt;
        vars.entireSystemColl = _systemColl;
        uint _TCR = _computeTCRWithGivenSystemValues(
            vars.entireSystemColl,
            vars.entireSystemDebt,
            _price
        );
        uint _cnt = _cdpArray.length;
        bool[] memory _liqFlags = new bool[](_cnt);
        uint _liqCnt;
        uint _start = sequenceLiq ? _cnt - 1 : 0;
        for (vars.i = _start; ; ) {
            vars.cdpId = _cdpArray[vars.i];
            // only for active cdps
            if (vars.cdpId != bytes32(0) && Cdps[vars.cdpId].status == Status.active) {
                vars.ICR = getCurrentICR(vars.cdpId, _price);

                if (!vars.backToNormalMode && (vars.ICR < MCR || vars.ICR < _TCR)) {
                    vars.price = _price;
                    _applyAccumulatedFeeSplit(vars.cdpId);
                    _getLiquidationValuesRecoveryMode(
                        _price,
                        vars.entireSystemDebt,
                        vars.entireSystemColl,
                        vars,
                        singleLiquidation,
                        sequenceLiq
                    );

                    // Update aggregate trackers
                    vars.entireSystemDebt = vars.entireSystemDebt - singleLiquidation.debtToOffset;
                    vars.entireSystemColl =
                        vars.entireSystemColl -
                        singleLiquidation.totalCollToSendToLiquidator -
                        singleLiquidation.collSurplus;

                    // Add liquidation values to their respective running totals
                    totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                    _TCR = _computeTCRWithGivenSystemValues(
                        vars.entireSystemColl,
                        vars.entireSystemDebt,
                        _price
                    );
                    vars.backToNormalMode = _TCR < CCR ? false : true;
                    _liqFlags[vars.i] = true;
                    _liqCnt += 1;
                } else if (vars.backToNormalMode && vars.ICR < MCR) {
                    _applyAccumulatedFeeSplit(vars.cdpId);
                    _getLiquidationValuesNormalMode(
                        _price,
                        _TCR,
                        vars,
                        singleLiquidation,
                        sequenceLiq
                    );

                    // Add liquidation values to their respective running totals
                    totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
                    _liqFlags[vars.i] = true;
                    _liqCnt += 1;
                }
                // In Normal Mode skip cdps with ICR >= MCR
            }
            if (sequenceLiq) {
                if (vars.i == 0) {
                    break;
                }
                --vars.i;
            } else {
                ++vars.i;
                if (vars.i == _cnt) {
                    break;
                }
            }
        }

        // remove from sortedCdps for sequence liquidation
        if (sequenceLiq) {
            bytes32[] memory _toRemoveIds = _cdpArray;
            if (_liqCnt > 0 && _liqCnt != _cnt) {
                _toRemoveIds = new bytes32[](_liqCnt);
                uint _j;
                for (uint i = 0; i < _cnt; ++i) {
                    if (_liqFlags[i]) {
                        _toRemoveIds[_j] = _cdpArray[i];
                        _j += 1;
                    }
                }
                require(
                    _j == _liqCnt,
                    "LiquidationLibrary: sequence liquidation (recovery mode) count error!"
                );
            }
            if (_liqCnt > 1) {
                sortedCdps.batchRemove(_toRemoveIds);
            } else if (_liqCnt == 1) {
                sortedCdps.remove(_toRemoveIds[0]);
            }
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode(
        uint _price,
        uint _TCR,
        bytes32[] memory _cdpArray,
        bool sequenceLiq
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        uint _cnt = _cdpArray.length;
        uint _liqCnt;
        uint _start = sequenceLiq ? _cnt - 1 : 0;
        for (vars.i = _start; ; ) {
            vars.cdpId = _cdpArray[vars.i];
            // only for active cdps
            if (vars.cdpId != bytes32(0) && Cdps[vars.cdpId].status == Status.active) {
                vars.ICR = getCurrentICR(vars.cdpId, _price);

                if (vars.ICR < MCR) {
                    _applyAccumulatedFeeSplit(vars.cdpId);
                    _getLiquidationValuesNormalMode(
                        _price,
                        _TCR,
                        vars,
                        singleLiquidation,
                        sequenceLiq
                    );

                    // Add liquidation values to their respective running totals
                    totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
                    _liqCnt += 1;
                }
            }
            if (sequenceLiq) {
                if (vars.i == 0) {
                    break;
                }
                --vars.i;
            } else {
                ++vars.i;
                if (vars.i == _cnt) {
                    break;
                }
            }
        }

        // remove from sortedCdps for sequence liquidation
        if (sequenceLiq) {
            require(
                _liqCnt == _cnt,
                "LiquidationLibrary: sequence liquidation (normal mode) count error!"
            );
            if (_cnt > 1) {
                sortedCdps.batchRemove(_cdpArray);
            } else if (_cnt == 1) {
                sortedCdps.remove(_cdpArray[0]);
            }
        }
    }

    // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(
        LiquidationTotals memory oldTotals,
        LiquidationValues memory singleLiquidation
    ) internal pure returns (LiquidationTotals memory newTotals) {
        // Tally all the values with their respective running totals
        newTotals.totalDebtInSequence =
            oldTotals.totalDebtInSequence +
            singleLiquidation.entireCdpDebt;
        newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset + singleLiquidation.debtToOffset;
        newTotals.totalCollToSendToLiquidator =
            oldTotals.totalCollToSendToLiquidator +
            singleLiquidation.totalCollToSendToLiquidator;
        newTotals.totalDebtToRedistribute =
            oldTotals.totalDebtToRedistribute +
            singleLiquidation.debtToRedistribute;
        newTotals.totalCollToRedistribute =
            oldTotals.totalCollToRedistribute +
            singleLiquidation.collToRedistribute;
        newTotals.totalCollSurplus = oldTotals.totalCollSurplus + singleLiquidation.collSurplus;
        newTotals.totalCollReward = oldTotals.totalCollReward + singleLiquidation.collReward;

        return newTotals;
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Cdp, without the price.
    // Takes a cdp's pending coll and debt rewards from redistributions into account.
    function getNominalICR(bytes32 _cdpId) external view returns (uint) {
        (uint currentEBTCDebt, uint currentETH, ) = getEntireDebtAndColl(_cdpId);

        uint NICR = LiquityMath._computeNominalCR(currentETH, currentEBTCDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Cdp.
    //Takes a cdp's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(bytes32 _cdpId, uint _price) public view returns (uint) {
        (uint currentEBTCDebt, uint currentETH, ) = getEntireDebtAndColl(_cdpId);

        uint _underlyingCollateral = collateral.getPooledEthByShares(currentETH);
        uint ICR = LiquityMath._computeCR(_underlyingCollateral, currentEBTCDebt, _price);
        return ICR;
    }

    /**
    get the pending Cdp debt "reward" (i.e. the amount of extra debt assigned to the Cdp) from liquidation redistribution events, earned by their stake
    */
    function getPendingEBTCDebtReward(
        bytes32 _cdpId
    ) public view returns (uint pendingEBTCDebtReward) {
        return _getRedistributedEBTCDebt(_cdpId);
    }

    function hasPendingRewards(bytes32 _cdpId) public view returns (bool) {
        return _hasRedistributedDebt(_cdpId);
    }

    // Return the Cdps entire debt and coll struct
    function _getEntireDebtAndColl(
        bytes32 _cdpId
    ) internal view returns (LocalVar_CdpDebtColl memory) {
        (uint256 entireDebt, uint256 entireColl, uint pendingDebtReward) = getEntireDebtAndColl(
            _cdpId
        );
        return LocalVar_CdpDebtColl(entireDebt, entireColl, pendingDebtReward);
    }

    // Return the Cdps entire debt and coll, including pending rewards from redistributions and collateral reduction from split fee.
    /// @notice pending rewards are included in the debt and coll totals returned.
    function getEntireDebtAndColl(
        bytes32 _cdpId
    ) public view returns (uint debt, uint coll, uint pendingEBTCDebtReward) {
        debt = Cdps[_cdpId].debt;
        (uint _feeSplitDistributed, uint _newColl) = getAccumulatedFeeSplitApplied(
            _cdpId,
            stFeePerUnitg,
            stFeePerUnitgError,
            totalStakes
        );
        coll = _newColl;

        pendingEBTCDebtReward = getPendingEBTCDebtReward(_cdpId);

        debt = debt + pendingEBTCDebtReward;
    }

    function _redistributeDebt(uint _debt) internal {
        if (_debt == 0) {
            return;
        }

        /*
         * Add distributed debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
         * error correction, to keep the cumulative error low in the running totals L_EBTCDebt:
         *
         * 1) Form numerators which compensate for the floor division errors that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratios.
         * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
         * 4) Store these errors for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint EBTCDebtNumerator = (_debt * DECIMAL_PRECISION) + lastEBTCDebtError_Redistribution;

        // Get the per-unit-staked terms
        uint _totalStakes = totalStakes;
        uint EBTCDebtRewardPerUnitStaked = EBTCDebtNumerator / _totalStakes;

        lastEBTCDebtError_Redistribution =
            EBTCDebtNumerator -
            (EBTCDebtRewardPerUnitStaked * _totalStakes);

        // Add per-unit-staked terms to the running totals
        L_EBTCDebt = L_EBTCDebt + EBTCDebtRewardPerUnitStaked;

        emit LTermsUpdated(L_EBTCDebt);
    }

    // --- 'require' wrapper functions ---

    function _requirePartialLiqDebtSize(
        uint _partialDebt,
        uint _entireDebt,
        uint _price
    ) internal view {
        require(
            (_partialDebt + _convertDebtDenominationToBtc(MIN_NET_COLL, _price)) <= _entireDebt,
            "LiquidationLibrary: Partial debt liquidated must be less than total debt"
        );
    }

    function _requirePartialLiqCollSize(uint _entireColl) internal pure {
        require(
            _entireColl >= MIN_NET_COLL,
            "LiquidationLibrary: Coll remaining in partially liquidated CDP must be >= minimum"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/ICdpManager.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/IEBTCToken.sol";
import "./Interfaces/ISortedCdps.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/ReentrancyGuard.sol";
import "./Dependencies/ICollateralTokenOracle.sol";
import "./Dependencies/AuthNoOwner.sol";

/**
    @notice CDP Manager storage and shared functions
    @dev CDP Manager was split to get around contract size limitations, liquidation related functions are delegated to LiquidationLibrary contract code.
    @dev Both must maintain the same storage layout, so shared storage components where placed here
    @dev Shared functions were also added here to de-dup code
 */
contract CdpManagerStorage is LiquityBase, ReentrancyGuard, ICdpManagerData, AuthNoOwner {
    string public constant NAME = "CdpManager";

    // --- Connected contract declarations ---

    address public immutable borrowerOperationsAddress;

    ICollSurplusPool immutable collSurplusPool;

    IEBTCToken public immutable override ebtcToken;

    address public immutable liquidationLibrary;

    // A doubly linked list of Cdps, sorted by their sorted by their collateral ratios
    ISortedCdps public immutable sortedCdps;

    // --- Data structures ---

    uint public constant SECONDS_IN_ONE_MINUTE = 60;

    uint public constant MIN_REDEMPTION_FEE_FLOOR = (DECIMAL_PRECISION * 5) / 1000; // 0.5%
    uint public redemptionFeeFloor = MIN_REDEMPTION_FEE_FLOOR;

    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint public minuteDecayFactor = 999037758833783000;
    uint public constant MIN_MINUTE_DECAY_FACTOR = 1; // Non-zero
    uint public constant MAX_MINUTE_DECAY_FACTOR = 999999999999999999; // Corresponds to a very fast decay rate, but not too extreme

    // During bootsrap period redemptions are not allowed
    uint public constant BOOTSTRAP_PERIOD = 14 days;

    uint internal immutable deploymentStartTime;

    /*
     * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction,
     * in order to calc the new base rate from a redemption.
     * Corresponds to (1 / ALPHA) in the white paper.
     */
    uint public beta = 2;

    uint public baseRate;

    uint public stakingRewardSplit;

    // The timestamp of the latest fee operation (redemption or new EBTC issuance)
    uint public lastFeeOperationTime;

    mapping(bytes32 => Cdp) public Cdps;

    uint public override totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation and split fee claim
    uint public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool, immediately after the latest liquidation and split fee claim
    uint public totalCollateralSnapshot;

    /*
     * L_EBTCDebt track the sums of accumulated liquidation rewards per unit staked.
     * During its lifetime, each stake earns:
     *
     * A EBTCDebt increase  of ( stake * [L_EBTCDebt - L_EBTCDebt(0)] )
     *
     * Where L_EBTCDebt(0) are snapshots of L_EBTCDebt
     * for the active Cdp taken at the instant the stake was made
     */
    uint public L_EBTCDebt;

    /* Global Index for (Full Price Per Share) of underlying collateral token */
    uint256 public override stFPPSg;
    /* Global Fee accumulator (never decreasing) per stake unit in CDPManager, similar to L_EBTCDebt */
    uint256 public override stFeePerUnitg;
    /* Global Fee accumulator calculation error due to integer division, similar to redistribution calculation */
    uint256 public override stFeePerUnitgError;
    /* Individual CDP Fee accumulator tracker, used to calculate fee split distribution */
    mapping(bytes32 => uint256) public stFeePerUnitcdp;
    /* Update timestamp for global index */
    uint256 lastIndexTimestamp;
    /* Global Index update minimal interval, typically it is updated once per day  */
    uint256 public INDEX_UPD_INTERVAL;
    // Map active cdps to their RewardSnapshot (eBTC debt redistributed)
    mapping(bytes32 => uint) public rewardSnapshots;

    // Array of all active cdp Ids - used to to compute an approximate hint off-chain, for the sorted list insertion
    bytes32[] public CdpIds;

    // Error trackers for the cdp redistribution calculation
    uint public lastETHError_Redistribution;
    uint public lastEBTCDebtError_Redistribution;

    constructor(
        address _liquidationLibraryAddress,
        address _authorityAddress,
        address _borrowerOperationsAddress,
        address _collSurplusPool,
        address _ebtcToken,
        address _sortedCdps,
        address _activePool,
        address _priceFeed,
        address _collateral
    ) LiquityBase(_activePool, _priceFeed, _collateral) {
        // TODO: Move to setAddresses or _tickInterest?
        deploymentStartTime = block.timestamp;
        liquidationLibrary = _liquidationLibraryAddress;

        _initializeAuthority(_authorityAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPool);
        ebtcToken = IEBTCToken(_ebtcToken);
        sortedCdps = ISortedCdps(_sortedCdps);

        emit LiquidationLibraryAddressChanged(_liquidationLibraryAddress);
    }

    /**
        @notice BorrowerOperations and CdpManager share reentrancy status by confirming the other's locked flag before beginning operation
        @dev This is an alternative to the more heavyweight solution of both being able to set the reentrancy flag on a 3rd contract.
     */
    modifier nonReentrantSelfAndBOps() {
        require(locked == OPEN, "CdpManager: REENTRANCY");
        require(
            ReentrancyGuard(borrowerOperationsAddress).locked() == OPEN,
            "BorrowerOperations: REENTRANCY"
        );

        locked = LOCKED;

        _;

        locked = OPEN;
    }

    function _closeCdp(bytes32 _cdpId, Status closedStatus) internal {
        _closeCdpWithoutRemovingSortedCdps(_cdpId, closedStatus);
        sortedCdps.remove(_cdpId);
    }

    function _closeCdpWithoutRemovingSortedCdps(bytes32 _cdpId, Status closedStatus) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint CdpIdsArrayLength = CdpIds.length;
        _requireMoreThanOneCdpInSystem(CdpIdsArrayLength);

        Cdps[_cdpId].status = closedStatus;
        Cdps[_cdpId].coll = 0;
        Cdps[_cdpId].debt = 0;
        Cdps[_cdpId].liquidatorRewardShares = 0;

        rewardSnapshots[_cdpId] = 0;

        _removeCdp(_cdpId, CdpIdsArrayLength);
    }

    /*
     * Updates snapshots of system total stakes and total collateral,
     * excluding a given collateral remainder from the calculation.
     * Used in a liquidation sequence.
     *
     * The calculation excludes a portion of collateral that is in the ActivePool:
     *
     * the total ETH gas compensation from the liquidation sequence
     *
     * The ETH as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
     */
    function _updateSystemSnapshots_excludeCollRemainder(uint _collRemainder) internal {
        totalStakesSnapshot = totalStakes;

        uint activeColl = activePool.getStEthColl();
        totalCollateralSnapshot = (activeColl - _collRemainder);

        emit SystemSnapshotsUpdated(totalStakesSnapshot, totalCollateralSnapshot);
    }

    /**
    get the pending Cdp debt "reward" (i.e. the amount of extra debt assigned to the Cdp) from liquidation redistribution events, earned by their stake
    */
    function _getRedistributedEBTCDebt(
        bytes32 _cdpId
    ) internal view returns (uint pendingEBTCDebtReward) {
        uint snapshotEBTCDebt = rewardSnapshots[_cdpId];
        Cdp storage cdp = Cdps[_cdpId];

        if (cdp.status != Status.active) {
            return 0;
        }

        uint stake = cdp.stake;

        uint rewardPerUnitStaked = L_EBTCDebt - snapshotEBTCDebt;

        if (rewardPerUnitStaked > 0) {
            pendingEBTCDebtReward = (stake * rewardPerUnitStaked) / DECIMAL_PRECISION;
        }
    }

    function _hasRedistributedDebt(bytes32 _cdpId) internal view returns (bool) {
        /*
         * A Cdp has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
         * this indicates that rewards have occured since the snapshot was made, and the user therefore has
         * pending rewards
         */
        if (Cdps[_cdpId].status != Status.active) {
            return false;
        }

        // Returns true if there have been any redemptions
        return (rewardSnapshots[_cdpId] < L_EBTCDebt);
    }

    function _updateCdpRewardSnapshots(bytes32 _cdpId) internal {
        rewardSnapshots[_cdpId] = L_EBTCDebt;
        emit CdpSnapshotsUpdated(_cdpId, L_EBTCDebt);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Cdp
    function _applyPendingRewards(bytes32 _cdpId) internal {
        _applyAccumulatedFeeSplit(_cdpId);

        if (_hasRedistributedDebt(_cdpId)) {
            _requireCdpIsActive(_cdpId);

            // Compute pending rewards
            uint pendingEBTCDebtReward = _getRedistributedEBTCDebt(_cdpId);

            Cdp storage _cdp = Cdps[_cdpId];
            uint prevDebt = _cdp.debt;
            uint prevColl = _cdp.coll;

            // Apply pending rewards to cdp's state
            _cdp.debt = prevDebt + pendingEBTCDebtReward;

            _updateCdpRewardSnapshots(_cdpId);

            address _borrower = ISortedCdps(sortedCdps).getOwnerAddress(_cdpId);
            emit CdpUpdated(
                _cdpId,
                _borrower,
                prevDebt,
                prevColl,
                Cdps[_cdpId].debt,
                prevColl,
                Cdps[_cdpId].stake,
                CdpManagerOperation.applyPendingRewards
            );
        }
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(bytes32 _cdpId) internal {
        uint stake = Cdps[_cdpId].stake;
        totalStakes = totalStakes - stake;
        Cdps[_cdpId].stake = 0;
        emit TotalStakesUpdated(totalStakes);
    }

    // Update borrower's stake based on their latest collateral value
    // and update otalStakes accordingly as well
    function _updateStakeAndTotalStakes(bytes32 _cdpId) internal returns (uint) {
        (uint newStake, uint oldStake) = _updateStakeForCdp(_cdpId);

        totalStakes = totalStakes + newStake - oldStake;
        emit TotalStakesUpdated(totalStakes);

        return newStake;
    }

    // Update borrower's stake based on their latest collateral value
    function _updateStakeForCdp(bytes32 _cdpId) internal returns (uint, uint) {
        Cdp storage _cdp = Cdps[_cdpId];
        uint newStake = _computeNewStake(_cdp.coll);
        uint oldStake = _cdp.stake;
        _cdp.stake = newStake;

        return (newStake, oldStake);
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(uint _coll) internal view returns (uint) {
        uint stake;
        if (totalCollateralSnapshot == 0) {
            stake = _coll;
        } else {
            /*
             * The following assert() holds true because:
             * - The system always contains >= 1 cdp
             * - When we close or liquidate a cdp, we redistribute the pending rewards,
             * so if all cdps were closed/liquidated,
             * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
             */
            assert(totalStakesSnapshot > 0);
            stake = (_coll * totalStakesSnapshot) / totalCollateralSnapshot;
        }
        return stake;
    }

    /*
     * Remove a Cdp owner from the CdpOwners array, not preserving array order. Removing owner 'B' does the following:
     * [A B C D E] => [A E C D], and updates E's Cdp struct to point to its new array index.
     */
    function _removeCdp(bytes32 _cdpId, uint CdpIdsArrayLength) internal {
        Status cdpStatus = Cdps[_cdpId].status;
        // It’s set in caller function `_closeCdp`
        assert(cdpStatus != Status.nonExistent && cdpStatus != Status.active);

        uint128 index = Cdps[_cdpId].arrayIndex;
        uint length = CdpIdsArrayLength;
        uint idxLast = length - 1;

        assert(index <= idxLast);

        bytes32 idToMove = CdpIds[idxLast];

        CdpIds[index] = idToMove;
        Cdps[idToMove].arrayIndex = index;
        emit CdpIndexUpdated(idToMove, index);

        CdpIds.pop();
    }

    // --- Recovery Mode and TCR functions ---

    // Calculate TCR given an price, and the entire system coll and debt.
    function _computeTCRWithGivenSystemValues(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price
    ) internal view returns (uint) {
        uint _totalColl = collateral.getPooledEthByShares(_entireSystemColl);
        return LiquityMath._computeCR(_totalColl, _entireSystemDebt, _price);
    }

    // --- Staking-Reward Fee split functions ---

    // Claim split fee if there is staking-reward coming
    // and update global index & fee-per-unit variables
    function claimStakingSplitFee() public {
        (uint _oldIndex, uint _newIndex) = _syncIndex();
        if (_newIndex > _oldIndex && totalStakes > 0) {
            (uint _feeTaken, uint _deltaFeePerUnit, uint _perUnitError) = calcFeeUponStakingReward(
                _newIndex,
                _oldIndex
            );
            _takeSplitAndUpdateFeePerUnit(_feeTaken, _deltaFeePerUnit, _perUnitError);
            _updateSystemSnapshots_excludeCollRemainder(0);
        }
    }

    // Update the global index via collateral token
    function _syncIndex() internal returns (uint, uint) {
        uint _oldIndex = stFPPSg;
        uint _newIndex = collateral.getPooledEthByShares(DECIMAL_PRECISION);
        if (_newIndex != _oldIndex) {
            stFPPSg = _newIndex;
            lastIndexTimestamp = block.timestamp;
            emit CollateralGlobalIndexUpdated(_oldIndex, _newIndex, block.timestamp);
        }
        return (_oldIndex, _newIndex);
    }

    // Calculate fee for given pair of collateral indexes, following are returned values:
    // - fee split in collateral token which will be deduced from current total system collateral
    // - fee split increase per unit, used to update stFeePerUnitg
    // - fee split calculation error, used to update stFeePerUnitgError
    function calcFeeUponStakingReward(
        uint256 _newIndex,
        uint256 _prevIndex
    ) public view returns (uint256, uint256, uint256) {
        require(_newIndex > _prevIndex, "LiquidationLibrary: only take fee with bigger new index");
        uint256 deltaIndex = _newIndex - _prevIndex;
        uint256 deltaIndexFees = (deltaIndex * stakingRewardSplit) / MAX_REWARD_SPLIT;

        // we take the fee for all CDPs immediately which is scaled by index precision
        uint256 _deltaFeeSplit = deltaIndexFees * getEntireSystemColl();
        uint256 _cachedAllStakes = totalStakes;
        // return the values to update the global fee accumulator
        uint256 _feeTaken = collateral.getSharesByPooledEth(_deltaFeeSplit) / DECIMAL_PRECISION;
        uint256 _deltaFeeSplitShare = (_feeTaken * DECIMAL_PRECISION) + stFeePerUnitgError;
        uint256 _deltaFeePerUnit = _deltaFeeSplitShare / _cachedAllStakes;
        uint256 _perUnitError = _deltaFeeSplitShare - (_deltaFeePerUnit * _cachedAllStakes);
        return (_feeTaken, _deltaFeePerUnit, _perUnitError);
    }

    // Take the cut from staking reward
    // and update global fee-per-unit accumulator
    function _takeSplitAndUpdateFeePerUnit(
        uint256 _feeTaken,
        uint256 _deltaPerUnit,
        uint256 _newErrorPerUnit
    ) internal {
        uint _oldPerUnit = stFeePerUnitg;
        stFeePerUnitg = stFeePerUnitg + _deltaPerUnit;
        stFeePerUnitgError = _newErrorPerUnit;

        require(activePool.getStEthColl() > _feeTaken, "CDPManager: fee split is too big");
        activePool.allocateFeeRecipientColl(_feeTaken);

        emit CollateralFeePerUnitUpdated(_oldPerUnit, stFeePerUnitg, _feeTaken);
    }

    // Apply accumulated fee split distributed to the CDP
    // and update its accumulator tracker accordingly
    function _applyAccumulatedFeeSplit(bytes32 _cdpId) internal {
        // TODO Ensure global states like stFeePerUnitg get timely updated
        // whenever there is a CDP modification operation,
        // such as opening, closing, adding collateral, repaying debt, or liquidating
        // OR Should we utilize some bot-keeper to work the routine job at fixed interval?
        claimStakingSplitFee();

        uint _oldPerUnitCdp = stFeePerUnitcdp[_cdpId];
        if (_oldPerUnitCdp == 0) {
            stFeePerUnitcdp[_cdpId] = stFeePerUnitg;
            return;
        } else if (_oldPerUnitCdp == stFeePerUnitg) {
            return;
        }

        (uint _feeSplitDistributed, uint _newColl) = getAccumulatedFeeSplitApplied(
            _cdpId,
            stFeePerUnitg,
            stFeePerUnitgError,
            totalStakes
        );
        Cdps[_cdpId].coll = _newColl;
        stFeePerUnitcdp[_cdpId] = stFeePerUnitg;

        emit CdpFeeSplitApplied(
            _cdpId,
            _oldPerUnitCdp,
            stFeePerUnitcdp[_cdpId],
            _feeSplitDistributed,
            Cdps[_cdpId].coll
        );
    }

    // return the applied split fee(scaled by 1e18) and the resulting CDP collateral amount after applied
    function getAccumulatedFeeSplitApplied(
        bytes32 _cdpId,
        uint _stFeePerUnitg,
        uint _stFeePerUnitgError,
        uint _totalStakes
    ) public view returns (uint, uint) {
        if (
            stFeePerUnitcdp[_cdpId] == 0 ||
            Cdps[_cdpId].coll == 0 ||
            stFeePerUnitcdp[_cdpId] == _stFeePerUnitg
        ) {
            return (0, Cdps[_cdpId].coll);
        }

        uint _oldStake = Cdps[_cdpId].stake;

        uint _diffPerUnit = _stFeePerUnitg - stFeePerUnitcdp[_cdpId];
        uint _feeSplitDistributed = _diffPerUnit > 0 ? _oldStake * _diffPerUnit : 0;

        uint _scaledCdpColl = Cdps[_cdpId].coll * DECIMAL_PRECISION;
        require(
            _scaledCdpColl > _feeSplitDistributed,
            "LiquidationLibrary: fee split is too big for CDP"
        );

        return (_feeSplitDistributed, (_scaledCdpColl - _feeSplitDistributed) / DECIMAL_PRECISION);
    }

    // -- Modifier functions --
    function _requireCdpIsActive(bytes32 _cdpId) internal view {
        require(Cdps[_cdpId].status == Status.active, "CdpManager: Cdp does not exist or is closed");
    }

    function _requireMoreThanOneCdpInSystem(uint CdpOwnersArrayLength) internal view {
        require(
            CdpOwnersArrayLength > 1 && sortedCdps.getSize() > 1,
            "CdpManager: Only one cdp in the system"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {Authority} from "./Authority.sol";

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified by BadgerDAO to remove owner
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
contract AuthNoOwner {
    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    Authority public authority;
    bool public authorityInitialized;

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "Auth: UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig));
    }

    function setAuthority(address newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(authority.canCall(msg.sender, address(this), msg.sig));

        authority = Authority(newAuthority);

        // Once authority is set once via any means, ensure it is initialized
        if (!authorityInitialized) {
            authorityInitialized = true;
        }

        emit AuthorityUpdated(msg.sender, Authority(newAuthority));
    }

    /// @notice Changed constructor to initialize to allow flexiblity of constructor vs initializer use
    /// @notice sets authorityInitiailzed flag to ensure only one use of
    function _initializeAuthority(address newAuthority) internal {
        require(address(authority) == address(0), "Auth: authority is non-zero");
        require(!authorityInitialized, "Auth: authority already initialized");

        authority = Authority(newAuthority);
        authorityInitialized = true;

        emit AuthorityUpdated(address(this), Authority(newAuthority));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(address user, address target, bytes4 functionSig) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BaseMath {
    uint public constant DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralToken is IERC20 {
    // Returns the amount of shares that corresponds to _ethAmount protocol-controlled Ether
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);

    // Returns the amount of Ether that corresponds to _sharesAmount token shares
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    // Moves `_sharesAmount` token shares from the caller's account to the `_recipient` account.
    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);

    // Returns the amount of shares owned by _account
    function sharesOf(address _account) external view returns (uint256);

    // Returns authorized oracle address
    function getOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralTokenOracle {
    // Return beacon specification data.
    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 *
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to
     * a value in the near future. The deadline argument can be set to uint(-1) to
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);

    function version() external view returns (string memory);

    function permitTypeHash() external view returns (bytes32);

    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./BaseMath.sol";
import "./LiquityMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/ILiquityBase.sol";
import "../Dependencies/ICollateralToken.sol";

/*
 * Base contract for CdpManager, BorrowerOperations. Contains global system constants and
 * common functions.
 */
contract LiquityBase is BaseMath, ILiquityBase {
    uint public constant _100pct = 1000000000000000000; // 1e18 == 100%
    uint public constant _105pct = 1050000000000000000; // 1.05e18 == 105%
    uint public constant _5pct = 50000000000000000; // 5e16 == 5%

    // Collateral Ratio applied for Liquidation Incentive
    // i.e., liquidator repay $1 worth of debt to get back $1.03 worth of collateral
    uint public constant LICR = 1030000000000000000; // 103%

    // Minimum collateral ratio for individual cdps
    uint public constant MCR = 1100000000000000000; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint public constant CCR = 1250000000000000000; // 125%

    // Amount of stETH collateral to be locked in active pool on opening cdps
    uint public constant LIQUIDATOR_REWARD = 2e17;

    // Minimum amount of stETH collateral a CDP must have
    uint public constant MIN_NET_COLL = 2e18;

    uint public constant PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint public constant BORROWING_FEE_FLOOR = 0; // 0.5%

    uint public constant STAKING_REWARD_SPLIT = 2_500; // taking 25% cut from staking reward

    uint public constant MAX_REWARD_SPLIT = 10_000;

    IActivePool public immutable activePool;

    IPriceFeed public immutable override priceFeed;

    // the only collateral token allowed in CDP
    ICollateralToken public immutable collateral;

    constructor(address _activePoolAddress, address _priceFeedAddress, address _collateralAddress) {
        activePool = IActivePool(_activePoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        collateral = ICollateralToken(_collateralAddress);
    }

    // --- Gas compensation functions ---

    function _getNetColl(uint _coll) internal pure returns (uint) {
        return _coll - LIQUIDATOR_REWARD;
    }

    // Return the amount of ETH to be drawn from a cdp's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal pure returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }

    /**
        @notice Get the entire system collateral
        @notice Entire system collateral = collateral stored in ActivePool, using their internal accounting
        @dev Coll stored for liquidator rewards or coll in CollSurplusPool are not included
     */
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        return (activePool.getStEthColl());
    }

    /**
        @notice Get the entire system debt
        @notice Entire system collateral = collateral stored in ActivePool, using their internal accounting
     */
    function _getEntireSystemDebt() internal view returns (uint entireSystemDebt) {
        return (activePool.getEBTCDebt());
    }

    function _getTCR(uint256 _price) internal view returns (uint TCR) {
        (TCR, , ) = _getTCRWithTotalCollAndDebt(_price);
    }

    function _getTCRWithTotalCollAndDebt(
        uint256 _price
    ) internal view returns (uint TCR, uint _coll, uint _debt) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = _getEntireSystemDebt();

        uint _underlyingCollateral = collateral.getPooledEthByShares(entireSystemColl);
        TCR = LiquityMath._computeCR(_underlyingCollateral, entireSystemDebt, _price);

        return (TCR, entireSystemColl, entireSystemDebt);
    }

    function _checkRecoveryMode(uint256 _price) internal view returns (bool) {
        return _getTCR(_price) < CCR;
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = (_fee * DECIMAL_PRECISION) / _amount;
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }

    // Convert ETH/BTC price to BTC/ETH price
    function _getPriceReciprocal(uint _price) internal pure returns (uint) {
        return (DECIMAL_PRECISION * DECIMAL_PRECISION) / _price;
    }

    // Convert debt denominated in BTC to debt denominated in ETH given that _price is ETH/BTC
    // _debt is denominated in BTC
    // _price is ETH/BTC
    function _convertDebtDenominationToEth(uint _debt, uint _price) internal pure returns (uint) {
        uint priceReciprocal = _getPriceReciprocal(_price);
        return (_debt * priceReciprocal) / DECIMAL_PRECISION;
    }

    // Convert debt denominated in ETH to debt denominated in BTC given that _price is ETH/BTC
    // _debt is denominated in ETH
    // _price is ETH/BTC
    function _convertDebtDenominationToBtc(uint _debt, uint _price) internal pure returns (uint) {
        return (_debt * _price) / DECIMAL_PRECISION;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library LiquityMath {
    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x * y;

        decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) CdpManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
        if (_minutes > 525600000) {
            _minutes = 525600000;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n / 2;
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n - 1) / 2;
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? (_a - _b) : (_b - _a);
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return (_coll * NICR_PRECISION) / _debt;
        }
        // Return the maximal value for uint256 if the Cdp has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2 ** 256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = (_coll * _price) / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Cdp has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2 ** 256 - 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 internal constant OPEN = 1;
    uint256 internal constant LOCKED = 2;

    uint256 public locked = OPEN;

    modifier nonReentrant() virtual {
        require(locked == OPEN, "ReentrancyGuard: REENTRANCY");

        locked = LOCKED;

        _;

        locked = OPEN;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolEBTCDebtUpdated(uint _EBTCDebt);
    event ActivePoolCollBalanceUpdated(uint _coll);
    event CollateralAddressChanged(address _collTokenAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusAddress);
    event ActivePoolFeeRecipientClaimableCollIncreased(uint _coll, uint _fee);
    event ActivePoolFeeRecipientClaimableCollDecreased(uint _coll, uint _fee);
    event FlashLoanSuccess(address _receiver, address _token, uint _amount, uint _fee);
    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Functions ---
    function sendStEthColl(address _account, uint _amount) external;

    function receiveColl(uint _value) external;

    function sendStEthCollAndLiquidatorReward(
        address _account,
        uint _shares,
        uint _liquidatorRewardShares
    ) external;

    function allocateFeeRecipientColl(uint _shares) external;

    function claimFeeRecipientColl(uint _shares) external;

    function feeRecipientAddress() external view returns (address);

    function getFeeRecipientClaimableColl() external view returns (uint);

    function setFeeRecipientAddress(address _feeRecipientAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ILiquityBase.sol";
import "./IEBTCToken.sol";
import "./IFeeRecipient.sol";
import "./ICollSurplusPool.sol";
import "./ICdpManagerData.sol";

// Common interface for the Cdp Manager.
interface ICdpManager is ILiquityBase, ICdpManagerData {
    // --- Functions ---
    function getCdpIdsCount() external view returns (uint);

    function getIdFromCdpIdsArray(uint _index) external view returns (bytes32);

    function getNominalICR(bytes32 _cdpId) external view returns (uint);

    function getCurrentICR(bytes32 _cdpId, uint _price) external view returns (uint);

    function liquidate(bytes32 _cdpId) external;

    function partiallyLiquidate(
        bytes32 _cdpId,
        uint256 _partialAmount,
        bytes32 _upperPartialHint,
        bytes32 _lowerPartialHint
    ) external;

    function liquidateCdps(uint _n) external;

    function batchLiquidateCdps(bytes32[] calldata _cdpArray) external;

    function redeemCollateral(
        uint _EBTCAmount,
        bytes32 _firstRedemptionHint,
        bytes32 _upperPartialRedemptionHint,
        bytes32 _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external;

    function updateStakeAndTotalStakes(bytes32 _cdpId) external returns (uint);

    function updateCdpRewardSnapshots(bytes32 _cdpId) external;

    function addCdpIdToArray(bytes32 _cdpId) external returns (uint index);

    function applyPendingRewards(bytes32 _cdpId) external;

    function getTotalStakeForFeeTaken(uint _feeTaken) external view returns (uint, uint);

    function syncUpdateIndexInterval() external returns (uint);

    function getPendingEBTCDebtReward(bytes32 _cdpId) external view returns (uint);

    function hasPendingRewards(bytes32 _cdpId) external view returns (bool);

    function getEntireDebtAndColl(
        bytes32 _cdpId
    ) external view returns (uint debt, uint coll, uint pendingEBTCDebtReward);

    function closeCdp(bytes32 _cdpId) external;

    function removeStake(bytes32 _cdpId) external;

    function getRedemptionRate() external view returns (uint);

    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint EBTCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _EBTCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getCdpStatus(bytes32 _cdpId) external view returns (uint);

    function getCdpStake(bytes32 _cdpId) external view returns (uint);

    function getCdpDebt(bytes32 _cdpId) external view returns (uint);

    function getCdpColl(bytes32 _cdpId) external view returns (uint);

    function getCdpLiquidatorRewardShares(bytes32 _cdpId) external view returns (uint);

    function setCdpStatus(bytes32 _cdpId, uint num) external;

    function increaseCdpColl(bytes32 _cdpId, uint _collIncrease) external returns (uint);

    function decreaseCdpColl(bytes32 _cdpId, uint _collDecrease) external returns (uint);

    function increaseCdpDebt(bytes32 _cdpId, uint _debtIncrease) external returns (uint);

    function decreaseCdpDebt(bytes32 _cdpId, uint _collDecrease) external returns (uint);

    function setCdpLiquidatorRewardShares(bytes32 _cdpId, uint _liquidatorRewardShares) external;

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICollSurplusPool.sol";
import "./IEBTCToken.sol";
import "./ISortedCdps.sol";
import "./IActivePool.sol";
import "../Dependencies/ICollateralTokenOracle.sol";

// Common interface for the Cdp Manager.
interface ICdpManagerData {
    // --- Events ---

    event LiquidationLibraryAddressChanged(address _liquidationLibraryAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event EBTCTokenAddressChanged(address _newEBTCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedCdpsAddressChanged(address _sortedCdpsAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollateralAddressChanged(address _collTokenAddress);
    event StakingRewardSplitSet(uint256 _stakingRewardSplit);
    event RedemptionFeeFloorSet(uint256 _redemptionFeeFloor);
    event MinuteDecayFactorSet(uint256 _minuteDecayFactor);
    event BetaSet(uint256 _beta);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _liqReward);
    event Redemption(uint _attemptedEBTCAmount, uint _actualEBTCAmount, uint _ETHSent, uint _ETHFee);
    event CdpUpdated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _oldDebt,
        uint _oldColl,
        uint _debt,
        uint _coll,
        uint _stake,
        CdpManagerOperation _operation
    );
    event CdpLiquidated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _debt,
        uint _coll,
        CdpManagerOperation _operation
    );
    event CdpPartiallyLiquidated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _debt,
        uint _coll,
        CdpManagerOperation operation
    );
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_EBTCDebt);
    event CdpSnapshotsUpdated(bytes32 _cdpId, uint _L_EBTCDebt);
    event CdpIndexUpdated(bytes32 _cdpId, uint _newIndex);
    event CollateralGlobalIndexUpdated(uint _oldIndex, uint _newIndex, uint _updTimestamp);
    event CollateralIndexUpdateIntervalUpdated(uint _oldInterval, uint _newInterval);
    event CollateralFeePerUnitUpdated(uint _oldPerUnit, uint _newPerUnit, uint _feeTaken);
    event CdpFeeSplitApplied(
        bytes32 _cdpId,
        uint _oldPerUnitCdp,
        uint _newPerUnitCdp,
        uint _collReduced,
        uint collLeft
    );

    enum CdpManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral,
        partiallyLiquidate
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a cdp
    struct Cdp {
        uint debt;
        uint coll;
        uint stake;
        uint liquidatorRewardShares;
        Status status;
        uint128 arrayIndex;
    }

    /*
     * --- Variable container structs for liquidations ---
     *
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     **/

    struct LocalVar_CdpDebtColl {
        uint256 entireDebt;
        uint256 entireColl;
        uint256 pendingDebtReward;
    }

    struct LocalVar_InternalLiquidate {
        bytes32 _cdpId;
        uint256 _partialAmount; // used only for partial liquidation, default 0 means full liquidation
        uint256 _price;
        uint256 _ICR;
        bytes32 _upperPartialHint;
        bytes32 _lowerPartialHint;
        bool _recoveryModeAtStart;
        uint256 _TCR;
        uint256 totalColSurplus;
        uint256 totalColToSend;
        uint256 totalDebtToBurn;
        uint256 totalDebtToRedistribute;
        uint256 totalColReward;
        bool sequenceLiq;
    }

    struct LocalVar_RecoveryLiquidate {
        uint256 entireSystemDebt;
        uint256 entireSystemColl;
        uint256 totalDebtToBurn;
        uint256 totalColToSend;
        uint256 totalColSurplus;
        bytes32 _cdpId;
        uint256 _price;
        uint256 _ICR;
        uint256 totalDebtToRedistribute;
        uint256 totalColReward;
        bool sequenceLiq;
    }

    struct LocalVariables_OuterLiquidationFunction {
        uint price;
        bool recoveryModeAtStart;
        uint liquidatedDebt;
        uint liquidatedColl;
    }

    struct LocalVariables_LiquidationSequence {
        uint i;
        uint ICR;
        bytes32 cdpId;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
        uint price;
        uint TCR;
    }

    struct LocalVariables_RedeemCollateralFromCdp {
        bytes32 _cdpId;
        uint _maxEBTCamount;
        uint _price;
        bytes32 _upperPartialRedemptionHint;
        bytes32 _lowerPartialRedemptionHint;
        uint _partialRedemptionHintNICR;
    }

    struct LiquidationValues {
        uint entireCdpDebt;
        uint debtToOffset;
        uint totalCollToSendToLiquidator;
        uint debtToRedistribute;
        uint collToRedistribute;
        uint collSurplus;
        uint collReward;
    }

    struct LiquidationTotals {
        uint totalDebtInSequence;
        uint totalDebtToOffset;
        uint totalCollToSendToLiquidator;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        uint totalCollSurplus;
        uint totalCollReward;
    }

    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint remainingEBTC;
        uint totalEBTCToRedeem;
        uint totalETHDrawn;
        uint ETHFee;
        uint ETHToSendToRedeemer;
        uint decayedBaseRate;
        uint price;
        uint totalEBTCSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint eBtcToRedeem;
        uint stEthToRecieve;
        bool cancelledPartial;
        bool fullRedemption;
    }

    function totalStakes() external view returns (uint);

    function ebtcToken() external view returns (IEBTCToken);

    function stFeePerUnitg() external view returns (uint);

    function stFeePerUnitgError() external view returns (uint);

    function stFPPSg() external view returns (uint);

    function calcFeeUponStakingReward(
        uint256 _newIndex,
        uint256 _prevIndex
    ) external view returns (uint256, uint256, uint256);

    function claimStakingSplitFee() external;

    function getAccumulatedFeeSplitApplied(
        bytes32 _cdpId,
        uint _stFeePerUnitg,
        uint _stFeePerUnitgError,
        uint _totalStakes
    ) external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollSurplusPool {
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralAddressChanged(address _collTokenAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event CollateralSent(address _to, uint _amount);

    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Contract setters ---

    function getStEthColl() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;

    function receiveColl(uint _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../Dependencies/IERC20.sol";
import "../Dependencies/IERC2612.sol";

interface IEBTCToken is IERC20, IERC2612 {
    // --- Events ---

    event CdpManagerAddressChanged(address _cdpManagerAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event EBTCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IFeeRecipient {
    // --- Events --

    event EBTCTokenAddressSet(address _ebtcTokenAddress);
    event CdpManagerAddressSet(address _cdpManager);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event ActivePoolAddressSet(address _activePoolAddress);
    event CollateralAddressSet(address _collTokenAddress);

    event ReceiveFee(address indexed _sender, address indexed _token, uint _amount);
    event CollateralSent(address _account, uint _amount);

    // --- Functions ---

    function receiveStEthFee(uint _ETHFee) external;

    function receiveEbtcFee(uint _EBTCFee) external;

    function claimStakingSplitFee() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPriceFeed.sol";

interface ILiquityBase {
    function priceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the Pools.
interface IPool {
    // --- Events ---

    event ETHBalanceUpdated(uint _newBalance);
    event EBTCBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralSent(address _to, uint _amount);

    // --- Functions ---

    function getStEthColl() external view returns (uint);

    function getEBTCDebt() external view returns (uint);

    function increaseEBTCDebt(uint _amount) external;

    function decreaseEBTCDebt(uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
    event PriceFeedStatusChanged(Status newStatus);
    event FallbackCallerChanged(address _oldFallbackCaller, address _newFallbackCaller);
    event UnhealthyFallbackCaller(address _fallbackCaller, uint256 timestamp);

    // --- Structs ---

    struct ChainlinkResponse {
        uint80 roundEthBtcId;
        uint80 roundStEthEthId;
        uint256 answer;
        uint256 timestampEthBtc;
        uint256 timestampStEthEth;
        bool success;
    }

    struct FallbackResponse {
        uint256 answer;
        uint256 timestamp;
        bool success;
    }

    // --- Enum ---

    enum Status {
        chainlinkWorking,
        usingFallbackChainlinkUntrusted,
        bothOraclesUntrusted,
        usingFallbackChainlinkFrozen,
        usingChainlinkFallbackUntrusted
    }

    // --- Function ---
    function fetchPrice() external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the SortedCdps Doubly Linked List.
interface ISortedCdps {
    // --- Events ---

    event CdpManagerAddressChanged(address _cdpManagerAddress);
    event SortedCdpsAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(bytes32 _id, uint _NICR);
    event NodeRemoved(bytes32 _id);

    // --- Functions ---

    function remove(bytes32 _id) external;

    function batchRemove(bytes32[] memory _ids) external;

    function reInsert(bytes32 _id, uint256 _newICR, bytes32 _prevId, bytes32 _nextId) external;

    function contains(bytes32 _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (bytes32);

    function getLast() external view returns (bytes32);

    function getNext(bytes32 _id) external view returns (bytes32);

    function getPrev(bytes32 _id) external view returns (bytes32);

    function validInsertPosition(
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view returns (bool);

    function findInsertPosition(
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view returns (bytes32, bytes32);

    function insert(
        address owner,
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external returns (bytes32);

    function getOwnerAddress(bytes32 _id) external pure returns (address);

    function existCdpOwners(bytes32 _id) external view returns (address);

    function nonExistId() external view returns (bytes32);

    function cdpCountOf(address owner) external view returns (uint256);

    function getCdpsOf(address owner) external view returns (bytes32[] memory);

    function cdpOfOwnerByIndex(address owner, uint256 index) external view returns (bytes32);

    // Mapping from cdp owner to list of owned cdp IDs
    // mapping(address => mapping(uint256 => bytes32)) public _ownedCdps;
    function _ownedCdps(address, uint256) external view returns (bytes32);

    // Mapping from cdp ID to index within owner cdp list
    // mapping(bytes32 => uint256) public _ownedCdpIndex;
    function _ownedCdpIndex(bytes32) external view returns (uint256);

    // Mapping from cdp owner to its owned cdps count
    // mapping(address => uint256) public _ownedCount;
    function _ownedCount(address) external view returns (uint256);
}