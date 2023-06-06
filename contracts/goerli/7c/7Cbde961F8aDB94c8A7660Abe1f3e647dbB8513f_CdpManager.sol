// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/ICdpManager.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/IEBTCToken.sol";
import "./Interfaces/ISortedCdps.sol";
import "./Dependencies/ICollateralTokenOracle.sol";
import "./CdpManagerStorage.sol";
import "./EBTCDeployer.sol";
import "./Dependencies/Proxy.sol";

contract CdpManager is CdpManagerStorage, ICdpManager, Proxy {
    // --- Dependency setter ---

    /**
     * @notice Constructor for CdpManager contract.
     * @dev Sets up dependencies and initial staking reward split.
     * @param _liquidationLibraryAddress Address of the liquidation library.
     * @param _authorityAddress Address of the authority.
     * @param _borrowerOperationsAddress Address of BorrowerOperations.
     * @param _collSurplusPoolAddress Address of CollSurplusPool.
     * @param _ebtcTokenAddress Address of the eBTC token.
     * @param _sortedCdpsAddress Address of the SortedCDPs.
     * @param _activePoolAddress Address of the ActivePool.
     * @param _priceFeedAddress Address of the price feed.
     * @param _collTokenAddress Address of the collateral token.
     */
    constructor(
        address _liquidationLibraryAddress,
        address _authorityAddress,
        address _borrowerOperationsAddress,
        address _collSurplusPoolAddress,
        address _ebtcTokenAddress,
        address _sortedCdpsAddress,
        address _activePoolAddress,
        address _priceFeedAddress,
        address _collTokenAddress
    )
        CdpManagerStorage(
            _liquidationLibraryAddress,
            _authorityAddress,
            _borrowerOperationsAddress,
            _collSurplusPoolAddress,
            _ebtcTokenAddress,
            _sortedCdpsAddress,
            _activePoolAddress,
            _priceFeedAddress,
            _collTokenAddress
        )
    {
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit EBTCTokenAddressChanged(_ebtcTokenAddress);
        emit SortedCdpsAddressChanged(_sortedCdpsAddress);
        emit CollateralAddressChanged(_collTokenAddress);

        stakingRewardSplit = 2500;
        // Emit initial value for analytics
        emit StakingRewardSplitSet(stakingRewardSplit);

        _syncIndex();
        syncUpdateIndexInterval();
        stFeePerUnitg = 1e18;
    }

    // --- Getters ---

    /**
     * @notice Get the count of CDPs in the system
     * @return The number of CDPs.
     */

    function getCdpIdsCount() external view override returns (uint) {
        return CdpIds.length;
    }

    /**
     * @notice Get the CdpId at a given index in the CdpIds array.
     * @param _index Index of the CdpIds array.
     * @return CDP ID.
     */
    function getIdFromCdpIdsArray(uint _index) external view override returns (bytes32) {
        return CdpIds[_index];
    }

    // --- Cdp Liquidation functions ---
    // -----------------------------------------------------------------
    //    CDP ICR     |       Liquidation Behavior (TODO gas compensation?)
    //
    //  < MCR         |  debt could be fully repaid by liquidator
    //                |  and ALL collateral transferred to liquidator
    //                |  OR debt could be partially repaid by liquidator and
    //                |  liquidator could get collateral of (repaidDebt * max(LICR, min(ICR, MCR)) / price)
    //
    //  > MCR & < TCR |  only liquidatable in Recovery Mode (TCR < CCR)
    //                |  debt could be fully repaid by liquidator
    //                |  and up to (repaid debt * MCR) worth of collateral
    //                |  transferred to liquidator while the residue of collateral
    //                |  will be available in CollSurplusPool for owner to claim
    //                |  OR debt could be partially repaid by liquidator and
    //                |  liquidator could get collateral of (repaidDebt * max(LICR, min(ICR, MCR)) / price)
    // -----------------------------------------------------------------

    /// @notice Fully liquidate a single CDP by ID. CDP must meet the criteria for liquidation at the time of execution.
    /// @notice callable by anyone, attempts to liquidate the CdpId. Executes successfully if Cdp meets the conditions for liquidation (e.g. in Normal Mode, it liquidates if the Cdp's ICR < the system MCR).
    /// @dev forwards msg.data directly to the liquidation library using OZ proxy core delegation function
    /// @param _cdpId ID of the CDP to liquidate.

    function liquidate(bytes32 _cdpId) external override {
        _delegate(liquidationLibrary);
    }

    /// @notice Partially liquidate a single CDP.
    /// @dev forwards msg.data directly to the liquidation library using OZ proxy core delegation function
    /// @param _cdpId ID of the CDP to partially liquidate.
    /// @param _partialAmount Amount to partially liquidate.
    /// @param _upperPartialHint Upper hint for reinsertion of the CDP into the linked list.
    /// @param _lowerPartialHint Lower hint for reinsertion of the CDP into the linked list.
    function partiallyLiquidate(
        bytes32 _cdpId,
        uint256 _partialAmount,
        bytes32 _upperPartialHint,
        bytes32 _lowerPartialHint
    ) external override {
        _delegate(liquidationLibrary);
    }

    // --- Batch/Sequence liquidation functions ---

    /// @notice Liquidate a sequence of cdps.
    /// @notice Closes a maximum number of n cdps with their CR < MCR in normla mode, or CR < TCR in recovery mode, starting from the one with the lowest collateral ratio in the system, and moving upwards.
    /// @notice Callable by anyone, checks for under-collateralized Cdps below MCR and liquidates up to `n`, starting from the Cdp with the lowest collateralization ratio; subject to gas constraints and the actual number of under-collateralized Cdps. The gas costs of `liquidateCdps(uint n)` mainly depend on the number of Cdps that are liquidated, and whether the Cdps are offset against the Stability Pool or redistributed. For n=1, the gas costs per liquidated Cdp are roughly between 215K-400K, for n=5 between 80K-115K, for n=10 between 70K-82K, and for n=50 between 60K-65K.
    /// @dev forwards msg.data directly to the liquidation library using OZ proxy core delegation function
    /// @param _n Maximum number of CDPs to liquidate.
    function liquidateCdps(uint _n) external override {
        _delegate(liquidationLibrary);
    }

    /// @notice Attempt to liquidate a custom list of CDPs provided by the caller
    /// @notice Callable by anyone, accepts a custom list of Cdps addresses as an argument. Steps through the provided list and attempts to liquidate every Cdp, until it reaches the end or it runs out of gas. A Cdp is liquidated only if it meets the conditions for liquidation. For a batch of 10 Cdps, the gas costs per liquidated Cdp are roughly between 75K-83K, for a batch of 50 Cdps between 54K-69K.
    /// @dev forwards msg.data directly to the liquidation library using OZ proxy core delegation function
    /// @param _cdpArray Array of CDPs to liquidate.
    function batchLiquidateCdps(bytes32[] memory _cdpArray) external override {
        _delegate(liquidationLibrary);
    }

    // --- Redemption functions ---

    /// @notice // Redeem as much collateral as possible from given Cdp in exchange for EBTC up to specified maximum
    /// @param _redeemColFromCdp Struct containing variables for redeeming collateral.
    /// @return singleRedemption Struct containing redemption values.
    function _redeemCollateralFromCdp(
        LocalVariables_RedeemCollateralFromCdp memory _redeemColFromCdp
    ) internal returns (SingleRedemptionValues memory singleRedemption) {
        // Determine the remaining amount (lot) to be redeemed,
        // capped by the entire debt of the Cdp minus the liquidation reserve
        singleRedemption.eBtcToRedeem = LiquityMath._min(
            _redeemColFromCdp._maxEBTCamount,
            Cdps[_redeemColFromCdp._cdpId].debt
        );

        // Get the stEthToRecieve of equivalent value in USD
        singleRedemption.stEthToRecieve = collateral.getSharesByPooledEth(
            (singleRedemption.eBtcToRedeem * DECIMAL_PRECISION) / _redeemColFromCdp._price
        );

        // Repurposing this struct here to avoid stack too deep.
        LocalVar_CdpDebtColl memory _oldDebtAndColl = LocalVar_CdpDebtColl(
            Cdps[_redeemColFromCdp._cdpId].debt,
            Cdps[_redeemColFromCdp._cdpId].coll,
            0
        );

        // Decrease the debt and collateral of the current Cdp according to the EBTC lot and corresponding ETH to send
        uint newDebt = _oldDebtAndColl.entireDebt - singleRedemption.eBtcToRedeem;
        uint newColl = _oldDebtAndColl.entireColl - singleRedemption.stEthToRecieve;

        if (newDebt == 0) {
            // No debt remains, close CDP
            // No debt left in the Cdp, therefore the cdp gets closed

            address _borrower = sortedCdps.getOwnerAddress(_redeemColFromCdp._cdpId);
            _redeemCloseCdp(_redeemColFromCdp._cdpId, 0, newColl, _borrower);
            singleRedemption.fullRedemption = true;

            emit CdpUpdated(
                _redeemColFromCdp._cdpId,
                _borrower,
                _oldDebtAndColl.entireDebt,
                _oldDebtAndColl.entireColl,
                0,
                0,
                0,
                CdpManagerOperation.redeemCollateral
            );
        } else {
            // Debt remains, reinsert CDP
            uint newNICR = LiquityMath._computeNominalCR(newColl, newDebt);

            /*
             * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
             * certainly result in running out of gas.
             *
             * If the resultant net coll of the partial is less than the minimum, we bail.
             */
            if (newNICR != _redeemColFromCdp._partialRedemptionHintNICR || newColl < MIN_NET_COLL) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            sortedCdps.reInsert(
                _redeemColFromCdp._cdpId,
                newNICR,
                _redeemColFromCdp._upperPartialRedemptionHint,
                _redeemColFromCdp._lowerPartialRedemptionHint
            );

            Cdps[_redeemColFromCdp._cdpId].debt = newDebt;
            Cdps[_redeemColFromCdp._cdpId].coll = newColl;
            _updateStakeAndTotalStakes(_redeemColFromCdp._cdpId);

            address _borrower = ISortedCdps(sortedCdps).getOwnerAddress(_redeemColFromCdp._cdpId);
            emit CdpUpdated(
                _redeemColFromCdp._cdpId,
                _borrower,
                _oldDebtAndColl.entireDebt,
                _oldDebtAndColl.entireColl,
                newDebt,
                newColl,
                Cdps[_redeemColFromCdp._cdpId].stake,
                CdpManagerOperation.redeemCollateral
            );
        }

        return singleRedemption;
    }

    /*
     * Called when a full redemption occurs, and closes the cdp.
     * The redeemer swaps (debt) EBTC for (debt)
     * worth of stETH, so the stETH liquidation reserve is all that remains.
     * In order to close the cdp, the stETH liquidation reserve is returned to the CDP owner,
     * The debt recorded on the cdp's struct is zero'd elswhere, in _closeCdp.
     * Any surplus stETH left in the cdp, is sent to the Coll surplus pool, and can be later claimed by the borrower.
     */
    function _redeemCloseCdp(
        bytes32 _cdpId, // TODO: Remove?
        uint _EBTC,
        uint _stEth,
        address _borrower
    ) internal {
        uint _liquidatorRewardShares = Cdps[_cdpId].liquidatorRewardShares;

        _removeStake(_cdpId);
        _closeCdpWithoutRemovingSortedCdps(_cdpId, Status.closedByRedemption);

        // Update Active Pool EBTC, and send ETH to account
        activePool.decreaseEBTCDebt(_EBTC);

        // Register stETH surplus from upcoming transfers of stETH from Active Pool and Gas Pool
        collSurplusPool.accountSurplus(_borrower, _stEth + _liquidatorRewardShares);

        // CEI: send stETH coll and liquidator reward shares from Active Pool to CollSurplus Pool
        activePool.sendStEthCollAndLiquidatorReward(
            address(collSurplusPool),
            _stEth,
            _liquidatorRewardShares
        );
    }

    function _isValidFirstRedemptionHint(
        ISortedCdps _sortedCdps,
        bytes32 _firstRedemptionHint,
        uint _price
    ) internal view returns (bool) {
        if (
            _firstRedemptionHint == _sortedCdps.nonExistId() ||
            !_sortedCdps.contains(_firstRedemptionHint) ||
            getCurrentICR(_firstRedemptionHint, _price) < MCR
        ) {
            return false;
        }

        bytes32 nextCdp = _sortedCdps.getNext(_firstRedemptionHint);
        return nextCdp == _sortedCdps.nonExistId() || getCurrentICR(nextCdp, _price) < MCR;
    }

    /** 
    redeems `_EBTCamount` of eBTC for stETH from the system. Decreases the caller’s eBTC balance, and sends them the corresponding amount of stETH. Executes successfully if the caller has sufficient eBTC to redeem. The number of Cdps redeemed from is capped by `_maxIterations`. The borrower has to provide a `_maxFeePercentage` that he/she is willing to accept in case of a fee slippage, i.e. when another redemption transaction is processed first, driving up the redemption fee.
    */

    /* Send _EBTCamount EBTC to the system and redeem the corresponding amount of collateral
     * from as many Cdps as are needed to fill the redemption
     * request.  Applies pending rewards to a Cdp before reducing its debt and coll.
     *
     * Note that if _amount is very large, this function can run out of gas, specially if traversed cdps are small.
     * This can be easily avoided by
     * splitting the total _amount in appropriate chunks and calling the function multiple times.
     *
     * Param `_maxIterations` can also be provided, so the loop through Cdps is capped
     * (if it’s zero, it will be ignored).This makes it easier to
     * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough,
     * without needing to know the “topology”
     * of the cdp list. It also avoids the need to set the cap in stone in the contract,
     * nor doing gas calculations, as both gas price and opcode costs can vary.
     *
     * All Cdps that are redeemed from -- with the likely exception of the last one -- will end up with no debt left,
     * therefore they will be closed.
     * If the last Cdp does have some remaining debt, it has a finite ICR, and the reinsertion
     * could be anywhere in the list, therefore it requires a hint.
     * A frontend should use getRedemptionHints() to calculate what the ICR of this Cdp will be after redemption,
     * and pass a hint for its position
     * in the sortedCdps list along with the ICR value that the hint was found for.
     *
     * If another transaction modifies the list between calling getRedemptionHints()
     * and passing the hints to redeemCollateral(), it is very likely that the last (partially)
     * redeemed Cdp would end up with a different ICR than what the hint is for. In this case the
     * redemption will stop after the last completely redeemed Cdp and the sender will keep the
     * remaining EBTC amount, which they can attempt to redeem later.
     */
    function redeemCollateral(
        uint _EBTCamount,
        bytes32 _firstRedemptionHint,
        bytes32 _upperPartialRedemptionHint,
        bytes32 _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    ) external override nonReentrantSelfAndBOps {
        RedemptionTotals memory totals;

        _requireValidMaxFeePercentage(_maxFeePercentage);
        _requireAfterBootstrapPeriod();
        totals.price = priceFeed.fetchPrice();
        _requireTCRoverMCR(totals.price);
        _requireAmountGreaterThanZero(_EBTCamount);
        _requireEBTCBalanceCoversRedemption(ebtcToken, msg.sender, _EBTCamount);

        totals.totalEBTCSupplyAtStart = _getEntireSystemDebt();
        // Confirm redeemer's balance is less than total EBTC supply
        assert(ebtcToken.balanceOf(msg.sender) <= totals.totalEBTCSupplyAtStart);

        totals.remainingEBTC = _EBTCamount;
        address currentBorrower;
        bytes32 _cId = _firstRedemptionHint;

        if (_isValidFirstRedemptionHint(sortedCdps, _firstRedemptionHint, totals.price)) {
            currentBorrower = sortedCdps.existCdpOwners(_firstRedemptionHint);
        } else {
            _cId = sortedCdps.getLast();
            currentBorrower = sortedCdps.getOwnerAddress(_cId);
            // Find the first cdp with ICR >= MCR
            while (currentBorrower != address(0) && getCurrentICR(_cId, totals.price) < MCR) {
                _cId = sortedCdps.getPrev(_cId);
                currentBorrower = sortedCdps.getOwnerAddress(_cId);
            }
        }

        // Loop through the Cdps starting from the one with lowest collateral
        // ratio until _amount of EBTC is exchanged for collateral
        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }
        bytes32 _firstRedeemed = _cId;
        bytes32 _lastRedeemed = _cId;
        uint _fullRedeemed;
        while (currentBorrower != address(0) && totals.remainingEBTC > 0 && _maxIterations > 0) {
            _maxIterations--;
            // Save the address of the Cdp preceding the current one, before potentially modifying the list
            {
                bytes32 _nextId = sortedCdps.getPrev(_cId);
                address nextUserToCheck = sortedCdps.getOwnerAddress(_nextId);

                _applyPendingRewards(_cId);

                LocalVariables_RedeemCollateralFromCdp
                    memory _redeemColFromCdp = LocalVariables_RedeemCollateralFromCdp(
                        _cId,
                        totals.remainingEBTC,
                        totals.price,
                        _upperPartialRedemptionHint,
                        _lowerPartialRedemptionHint,
                        _partialRedemptionHintNICR
                    );
                SingleRedemptionValues memory singleRedemption = _redeemCollateralFromCdp(
                    _redeemColFromCdp
                );
                // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum),
                // therefore we could not redeem from the last Cdp
                if (singleRedemption.cancelledPartial) break;

                totals.totalEBTCToRedeem = totals.totalEBTCToRedeem + singleRedemption.eBtcToRedeem;
                totals.totalETHDrawn = totals.totalETHDrawn + singleRedemption.stEthToRecieve;

                totals.remainingEBTC = totals.remainingEBTC - singleRedemption.eBtcToRedeem;
                currentBorrower = nextUserToCheck;
                if (singleRedemption.fullRedemption) {
                    _lastRedeemed = _cId;
                    _fullRedeemed = _fullRedeemed + 1;
                }
                _cId = _nextId;
            }
        }
        require(totals.totalETHDrawn > 0, "CdpManager: Unable to redeem any amount");

        // remove from sortedCdps
        if (_fullRedeemed == 1) {
            sortedCdps.remove(_firstRedeemed);
        } else if (_fullRedeemed > 1) {
            bytes32[] memory _toRemoveIds = _getCdpIdsToRemove(
                _lastRedeemed,
                _fullRedeemed,
                _firstRedeemed
            );
            sortedCdps.batchRemove(_toRemoveIds);
        }

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total EBTC supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(
            totals.totalETHDrawn,
            totals.price,
            totals.totalEBTCSupplyAtStart
        );

        // Calculate the ETH fee
        totals.ETHFee = _getRedemptionFee(totals.totalETHDrawn);

        _requireUserAcceptsFee(totals.ETHFee, totals.totalETHDrawn, _maxFeePercentage);

        totals.ETHToSendToRedeemer = totals.totalETHDrawn - totals.ETHFee;

        emit Redemption(_EBTCamount, totals.totalEBTCToRedeem, totals.totalETHDrawn, totals.ETHFee);

        // Burn the total eBTC that is redeemed
        ebtcToken.burn(msg.sender, totals.totalEBTCToRedeem);

        // Update Active Pool eBTC debt internal accounting
        activePool.decreaseEBTCDebt(totals.totalEBTCToRedeem);

        // Allocate the stETH fee to the FeeRecipient
        activePool.allocateFeeRecipientColl(totals.ETHFee);

        // CEI: Send the stETH drawn to the redeemer
        activePool.sendStEthColl(msg.sender, totals.ETHToSendToRedeemer);

        // TODO: an alternative is we could track a variable on the activePool and avoid the transfer, for claim at-will be feeRecipient
        // Then we can avoid the whole feeRecipient contract in every other contract. It can then be governable and switched out. ActivePool can handle sending any extra metadata to the recipient
    }

    // --- Helper functions ---

    function _getCdpIdsToRemove(
        bytes32 _start,
        uint _total,
        bytes32 _end
    ) internal view returns (bytes32[] memory) {
        uint _cnt = _total;
        bytes32 _id = _start;
        bytes32[] memory _toRemoveIds = new bytes32[](_total);
        while (_cnt > 0 && _id != bytes32(0)) {
            _toRemoveIds[_total - _cnt] = _id;
            _cnt = _cnt - 1;
            _id = sortedCdps.getNext(_id);
        }
        require(
            _toRemoveIds[0] == _start,
            "LiquidationLibrary: batchRemoveSortedCdpIds check start error!"
        );
        require(
            _toRemoveIds[_total - 1] == _end,
            "LiquidationLibrary: batchRemoveSortedCdpIds check end error!"
        );
        return _toRemoveIds;
    }

    // Return the nominal collateral ratio (ICR) of a given Cdp, without the price.
    // Takes a cdp's pending coll and debt rewards from redistributions into account.
    function getNominalICR(bytes32 _cdpId) external view override returns (uint) {
        (uint currentEBTCDebt, uint currentETH, ) = getEntireDebtAndColl(_cdpId);

        uint NICR = LiquityMath._computeNominalCR(currentETH, currentEBTCDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Cdp.
    //Takes a cdp's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(bytes32 _cdpId, uint _price) public view override returns (uint) {
        (uint currentEBTCDebt, uint currentETH, ) = getEntireDebtAndColl(_cdpId);

        uint _underlyingCollateral = collateral.getPooledEthByShares(currentETH);
        uint ICR = LiquityMath._computeCR(_underlyingCollateral, currentEBTCDebt, _price);
        return ICR;
    }

    function applyPendingRewards(bytes32 _cdpId) external override {
        // TODO: Open this up for anyone?
        _requireCallerIsBorrowerOperations();
        return _applyPendingRewards(_cdpId);
    }

    // Update borrower's snapshots of L_EBTCDebt to reflect the current values
    function updateCdpRewardSnapshots(bytes32 _cdpId) external override {
        _requireCallerIsBorrowerOperations();
        _applyAccumulatedFeeSplit(_cdpId);
        return _updateCdpRewardSnapshots(_cdpId);
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
    ) public view override returns (uint debt, uint coll, uint pendingEBTCDebtReward) {
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

    function removeStake(bytes32 _cdpId) external override {
        _requireCallerIsBorrowerOperations();
        return _removeStake(_cdpId);
    }

    // get totalStakes after split fee taken removed
    function getTotalStakeForFeeTaken(uint _feeTaken) public view override returns (uint, uint) {
        uint stake = _computeNewStake(_feeTaken);
        uint _newTotalStakes = totalStakes - stake;
        return (_newTotalStakes, stake);
    }

    function updateStakeAndTotalStakes(bytes32 _cdpId) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        return _updateStakeAndTotalStakes(_cdpId);
    }

    function closeCdp(bytes32 _cdpId) external override {
        _requireCallerIsBorrowerOperations();
        return _closeCdp(_cdpId, Status.closedByOwner);
    }

    // Push the owner's address to the Cdp owners list, and record the corresponding array index on the Cdp struct
    function addCdpIdToArray(bytes32 _cdpId) external override returns (uint index) {
        _requireCallerIsBorrowerOperations();
        return _addCdpIdToArray(_cdpId);
    }

    function _addCdpIdToArray(bytes32 _cdpId) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 cdps. No risk of overflow, since cdps have minimum EBTC
        debt of liquidation reserve plus MIN_NET_DEBT.
        3e30 EBTC dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the Cdpowner to the array
        CdpIds.push(_cdpId);

        // Record the index of the new Cdpowner on their Cdp struct
        index = uint128(CdpIds.length - 1);
        Cdps[_cdpId].arrayIndex = index;

        return index;
    }

    // --- Recovery Mode and TCR functions ---

    /**
    Returns the systemic entire debt assigned to Cdps, i.e. the sum of the EBTCDebt in the Active Pool and the Default Pool.
     */
    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        return _getEntireSystemDebt();
    }

    /**
    returns the total collateralization ratio (TCR) of the system.  The TCR is based on the the entire system debt and collateral (including pending rewards). */
    function getTCR(uint _price) external view override returns (uint) {
        return _getTCR(_price);
    }

    /**
    reveals whether or not the system is in Recovery Mode (i.e. whether the Total Collateralization Ratio (TCR) is below the Critical Collateralization Ratio (CCR)).
    */
    function checkRecoveryMode(uint _price) external view override returns (bool) {
        return _checkRecoveryMode(_price);
    }

    // Check whether or not the system *would be* in Recovery Mode,
    // given an ETH:USD price, and the entire system coll and debt.
    function _checkPotentialRecoveryMode(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price
    ) internal view returns (bool) {
        uint TCR = _computeTCRWithGivenSystemValues(_entireSystemColl, _entireSystemDebt, _price);
        return TCR < CCR;
    }

    function syncUpdateIndexInterval() public override returns (uint) {
        ICollateralTokenOracle _oracle = ICollateralTokenOracle(collateral.getOracle());
        (uint256 epochsPerFrame, uint256 slotsPerEpoch, uint256 secondsPerSlot, ) = _oracle
            .getBeaconSpec();
        uint256 _newInterval = (epochsPerFrame * slotsPerEpoch * secondsPerSlot) / 2;
        if (_newInterval != INDEX_UPD_INTERVAL) {
            emit CollateralIndexUpdateIntervalUpdated(INDEX_UPD_INTERVAL, _newInterval);
            INDEX_UPD_INTERVAL = _newInterval;
            // Ensure growth of index from last update to the time this function gets called will be charged
            claimStakingSplitFee();
        }
        return INDEX_UPD_INTERVAL;
    }

    // --- Redemption fee functions ---

    /*
     * This function has two impacts on the baseRate state variable:
     * 1) decays the baseRate based on time passed since last redemption or EBTC borrowing operation.
     * then,
     * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
     */
    function _updateBaseRateFromRedemption(
        uint _ETHDrawn,
        uint _price,
        uint _totalEBTCSupply
    ) internal returns (uint) {
        uint decayedBaseRate = _calcDecayedBaseRate();

        /* Convert the drawn ETH back to EBTC at face value rate (1 EBTC:1 USD), in order to get
         * the fraction of total supply that was redeemed at face value. */
        uint redeemedEBTCFraction = (collateral.getPooledEthByShares(_ETHDrawn) * _price) /
            _totalEBTCSupply;

        uint newBaseRate = decayedBaseRate + (redeemedEBTCFraction / beta);
        newBaseRate = LiquityMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%
        assert(newBaseRate > 0); // Base rate is always non-zero after redemption

        // Update the baseRate state variable
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);

        _updateLastFeeOpTime();

        return newBaseRate;
    }

    function getRedemptionRate() public view override returns (uint) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view override returns (uint) {
        return _calcRedemptionRate(_calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint _baseRate) internal view returns (uint) {
        return
            LiquityMath._min(
                redemptionFeeFloor + _baseRate,
                DECIMAL_PRECISION // cap at a maximum of 100%
            );
    }

    function _getRedemptionFee(uint _ETHDrawn) internal view returns (uint) {
        return _calcRedemptionFee(getRedemptionRate(), _ETHDrawn);
    }

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view override returns (uint) {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _ETHDrawn);
    }

    function _calcRedemptionFee(uint _redemptionRate, uint _ETHDrawn) internal pure returns (uint) {
        uint redemptionFee = (_redemptionRate * _ETHDrawn) / DECIMAL_PRECISION;
        require(redemptionFee < _ETHDrawn, "CdpManager: Fee would eat up all returned collateral");
        return redemptionFee;
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view override returns (uint) {
        return _calcBorrowingRate(_calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint _baseRate) internal pure returns (uint) {
        return BORROWING_FEE_FLOOR;
    }

    function getBorrowingFee(uint _EBTCDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRate(), _EBTCDebt);
    }

    function getBorrowingFeeWithDecay(uint _EBTCDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _EBTCDebt);
    }

    function _calcBorrowingFee(uint _borrowingRate, uint _EBTCDebt) internal pure returns (uint) {
        return BORROWING_FEE_FLOOR;
    }

    // Updates the baseRate state variable based on time elapsed since the last redemption or EBTC borrowing operation.
    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOperations();

        _decayBaseRate();
    }

    function _decayBaseRate() internal {
        uint decayedBaseRate = _calcDecayedBaseRate();
        assert(decayedBaseRate <= DECIMAL_PRECISION); // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
    }

    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint timePassed = block.timestamp > lastFeeOperationTime
            ? block.timestamp - lastFeeOperationTime
            : 0;

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            // Using the effective elapsed time that is consumed so far to update lastFeeOperationTime
            // instead block.timestamp for consistency with _calcDecayedBaseRate()
            lastFeeOperationTime += _minutesPassedSinceLastFeeOp() * SECONDS_IN_ONE_MINUTE;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function _calcDecayedBaseRate() internal view returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = LiquityMath._decPow(minuteDecayFactor, minutesPassed);

        return (baseRate * decayFactor) / DECIMAL_PRECISION;
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint) {
        return
            block.timestamp > lastFeeOperationTime
                ? ((block.timestamp - lastFeeOperationTime) / SECONDS_IN_ONE_MINUTE)
                : 0;
    }

    function getDeploymentStartTime() public view returns (uint256) {
        return deploymentStartTime;
    }

    // Check whether or not the system *would be* in Recovery Mode,
    // given an ETH:USD price, and the entire system coll and debt.
    function checkPotentialRecoveryMode(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price
    ) external view returns (bool) {
        return _checkPotentialRecoveryMode(_entireSystemColl, _entireSystemDebt, _price);
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "CdpManager: Caller is not the BorrowerOperations contract"
        );
    }

    function _requireEBTCBalanceCoversRedemption(
        IEBTCToken _ebtcToken,
        address _redeemer,
        uint _amount
    ) internal view {
        require(
            _ebtcToken.balanceOf(_redeemer) >= _amount,
            "CdpManager: Requested redemption amount must be <= user's EBTC token balance"
        );
    }

    function _requireAmountGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "CdpManager: Amount must be greater than zero");
    }

    function _requireTCRoverMCR(uint _price) internal view {
        require(_getTCR(_price) >= MCR, "CdpManager: Cannot redeem when TCR < MCR");
    }

    function _requireAfterBootstrapPeriod() internal view {
        uint systemDeploymentTime = getDeploymentStartTime();
        require(
            block.timestamp >= systemDeploymentTime + BOOTSTRAP_PERIOD,
            "CdpManager: Redemptions are not allowed during bootstrap phase"
        );
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage) internal view {
        require(
            _maxFeePercentage >= redemptionFeeFloor && _maxFeePercentage <= DECIMAL_PRECISION,
            "Max fee percentage must be between redemption fee floor and 100%"
        );
    }

    // --- Governance Parameters ---

    function setStakingRewardSplit(uint _stakingRewardSplit) external requiresAuth {
        require(
            _stakingRewardSplit <= MAX_REWARD_SPLIT,
            "CDPManager: new staking reward split exceeds max"
        );

        stakingRewardSplit = _stakingRewardSplit;
        emit StakingRewardSplitSet(_stakingRewardSplit);
    }

    function setRedemptionFeeFloor(uint _redemptionFeeFloor) external requiresAuth {
        require(
            _redemptionFeeFloor >= MIN_REDEMPTION_FEE_FLOOR,
            "CDPManager: new redemption fee floor is lower than minimum"
        );
        require(
            _redemptionFeeFloor <= DECIMAL_PRECISION,
            "CDPManager: new redemption fee floor is higher than maximum"
        );

        redemptionFeeFloor = _redemptionFeeFloor;
        emit RedemptionFeeFloorSet(_redemptionFeeFloor);
    }

    function setMinuteDecayFactor(uint _minuteDecayFactor) external requiresAuth {
        require(
            _minuteDecayFactor >= MIN_MINUTE_DECAY_FACTOR,
            "CDPManager: new minute decay factor out of range"
        );
        require(
            _minuteDecayFactor <= MAX_MINUTE_DECAY_FACTOR,
            "CDPManager: new minute decay factor out of range"
        );

        // decay first according to previous factor
        _decayBaseRate();

        // set new factor after decaying
        minuteDecayFactor = _minuteDecayFactor;
        emit MinuteDecayFactorSet(_minuteDecayFactor);
    }

    function setBeta(uint _beta) external requiresAuth {
        _decayBaseRate();

        beta = _beta;
        emit BetaSet(_beta);
    }

    // --- Cdp property getters ---

    /// @notice Get status of a CDP. Named values can be found in ICdpManagerData.Status.
    function getCdpStatus(bytes32 _cdpId) external view override returns (uint) {
        return uint(Cdps[_cdpId].status);
    }

    /// @notice Get stake value of a CDP.
    function getCdpStake(bytes32 _cdpId) external view override returns (uint) {
        return Cdps[_cdpId].stake;
    }

    /// @notice Get stored debt value of a CDP, in eBTC units. Does not include pending changes from redistributions
    function getCdpDebt(bytes32 _cdpId) external view override returns (uint) {
        return Cdps[_cdpId].debt;
    }

    /// @notice Get stored collateral value of a CDP, in stETH shares. Does not include pending changes from redistributions or unprocessed staking yield.
    function getCdpColl(bytes32 _cdpId) external view override returns (uint) {
        return Cdps[_cdpId].coll;
    }

    /**
        @notice Get shares value of the liquidator gas incentive reward stored for a CDP. 
        @notice This value is processed when a CDP closes. 
        @dev This value is returned to the borrower when they close their own CDP
        @dev This value is given to liquidators upon fully liquidating a CDP
        @dev This value is sent to the CollSurplusPool for reclaiming by the borrower when their CDP is redeemed
    */
    function getCdpLiquidatorRewardShares(bytes32 _cdpId) external view override returns (uint) {
        return Cdps[_cdpId].liquidatorRewardShares;
    }

    // --- Cdp property setters, called by BorrowerOperations ---

    /**
     * @notice Set the status of a CDP
     * @param _cdpId The ID of the CDP
     * @param _num The new ICdpManagerData.Satus, as an integer
     */
    function setCdpStatus(bytes32 _cdpId, uint _num) external override {
        _requireCallerIsBorrowerOperations();
        Cdps[_cdpId].status = Status(_num);
    }

    /**
     * @notice Increase the collateral of a CDP
     * @param _cdpId The ID of the CDP
     * @param _collIncrease The amount to collateral to increase, in stETH shares
     * @return The new collateral amount in stETH shares
     */
    function increaseCdpColl(bytes32 _cdpId, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Cdps[_cdpId].coll + _collIncrease;
        Cdps[_cdpId].coll = newColl;
        return newColl;
    }

    /**
     * @notice Decrease the collateral of a CDP
     * @param _cdpId The ID of the CDP
     * @param _collDecrease The amount of collateral to decrease, in stETH sharse
     * @return The new collateral amount in stETH shares
     */
    function decreaseCdpColl(bytes32 _cdpId, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Cdps[_cdpId].coll - _collDecrease;
        Cdps[_cdpId].coll = newColl;
        return newColl;
    }

    /**
     * @notice Increase the debt of a CDP
     * @param _cdpId The ID of the CDP
     * @param _debtIncrease The amount of debt to increase
     * @return The new debt amount
     */
    function increaseCdpDebt(bytes32 _cdpId, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Cdps[_cdpId].debt + _debtIncrease;
        Cdps[_cdpId].debt = newDebt;
        return newDebt;
    }

    /**
     * @notice Decrease the debt of a CDP
     * @param _cdpId The ID of the CDP
     * @param _debtDecrease The amount of debt to decrease
     * @return The new debt amount
     */
    function decreaseCdpDebt(bytes32 _cdpId, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Cdps[_cdpId].debt - _debtDecrease;
        Cdps[_cdpId].debt = newDebt;
        return newDebt;
    }

    /**
     * @notice Set the liquidator reward shares of a CDP
     * @param _cdpId The ID of the CDP
     * @param _liquidatorRewardShares The new liquidator reward shares
     */
    function setCdpLiquidatorRewardShares(
        bytes32 _cdpId,
        uint _liquidatorRewardShares
    ) external override {
        _requireCallerIsBorrowerOperations();
        Cdps[_cdpId].liquidatorRewardShares = _liquidatorRewardShares;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.17;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
    error ErrorCreatingProxy();
    error ErrorCreatingContract();
    error TargetAlreadyExists();

    /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

  0x67363d3d37363d34f03d5260086018f3:
      0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
      0x02  0x52  0x52                  MSTORE
      0x03  0x60  0x6008                PUSH1 08        8
      0x04  0x60  0x6018                PUSH1 18        24 8
      0x05  0xf3  0xf3                  RETURN

  0x363d3d37363d34f0:
      0x00  0x36  0x36                  CALLDATASIZE    cds
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                  CALLDATACOPY
      0x04  0x36  0x36                  CALLDATASIZE    cds
      0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x06  0x34  0x34                  CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                  CREATE          addr
  */

    bytes internal constant PROXY_CHILD_BYTECODE =
        hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
    bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE =
        0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
    function create3(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
        return create3(_salt, _creationCode, 0);
    }

    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @param _value In WEI of ETH to be forwarded to child contract
    @return addr of the deployed contract, reverts on error
  */
    function create3(
        bytes32 _salt,
        bytes memory _creationCode,
        uint256 _value
    ) internal returns (address addr) {
        // Creation code
        bytes memory creationCode = PROXY_CHILD_BYTECODE;

        // Get target final address
        addr = addressOf(_salt);
        if (codeSize(addr) != 0) revert TargetAlreadyExists();

        // Create CREATE2 proxy
        address proxy;
        assembly {
            proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)
        }
        if (proxy == address(0)) revert ErrorCreatingProxy();

        // Call proxy with final init code
        (bool success, ) = proxy.call{value: _value}(_creationCode);
        if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
    }

    /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error

    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
    function addressOf(bytes32 _salt) internal view returns (address) {
        address proxy = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            _salt,
                            KECCAK256_PROXY_CHILD_BYTECODE
                        )
                    )
                )
            )
        );

        return address(uint160(uint256(keccak256(abi.encodePacked(hex"d6_94", proxy, hex"01")))));
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.17;

import "./Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity 0.8.17;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 * @dev BadgerDAO: Simplified to the core delegation functionality, without any additional features.
 */
contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
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

import "./Dependencies/Create3.sol";
import "./Dependencies/Ownable.sol";

contract EBTCDeployer is Ownable {
    string public constant name = "eBTC Deployer";

    string public constant AUTHORITY = "ebtc.v1.authority";
    string public constant LIQUIDATION_LIBRARY = "ebtc.v1.liquidationLibrary";
    string public constant CDP_MANAGER = "ebtc.v1.cdpManager";
    string public constant BORROWER_OPERATIONS = "ebtc.v1.borrowerOperations";

    string public constant PRICE_FEED = "ebtc.v1.priceFeed";
    string public constant SORTED_CDPS = "ebtc.v1.sortedCdps";

    string public constant ACTIVE_POOL = "ebtc.v1.activePool";
    string public constant COLL_SURPLUS_POOL = "ebtc.v1.collSurplusPool";

    string public constant HINT_HELPERS = "ebtc.v1.hintHelpers";
    string public constant EBTC_TOKEN = "ebtc.v1.eBTCToken";
    string public constant FEE_RECIPIENT = "ebtc.v1.feeRecipient";
    string public constant MULTI_CDP_GETTER = "ebtc.v1.multiCdpGetter";

    event ContractDeployed(address indexed contractAddress, string contractName, bytes32 salt);

    struct EbtcAddresses {
        address authorityAddress;
        address liquidationLibraryAddress;
        address cdpManagerAddress;
        address borrowerOperationsAddress;
        address priceFeedAddress;
        address sortedCdpsAddress;
        address activePoolAddress;
        address collSurplusPoolAddress;
        address hintHelpersAddress;
        address ebtcTokenAddress;
        address feeRecipientAddress;
        address multiCdpGetterAddress;
    }

    /**
    @notice Helper method to return a set of future addresses for eBTC. Intended to be used in the order specified.
    
    @dev The order is as follows:
    0: authority
    1: liquidationLibrary
    2: cdpManager
    3: borrowerOperations
    4: priceFeed
    5; sortedCdps
    6: activePool
    7: collSurplusPool
    8: hintHelpers
    9: eBTCToken
    10: feeRecipient
    11: multiCdpGetter


     */
    function getFutureEbtcAddresses() public view returns (EbtcAddresses memory) {
        EbtcAddresses memory addresses = EbtcAddresses(
            Create3.addressOf(keccak256(abi.encodePacked(AUTHORITY))),
            Create3.addressOf(keccak256(abi.encodePacked(LIQUIDATION_LIBRARY))),
            Create3.addressOf(keccak256(abi.encodePacked(CDP_MANAGER))),
            Create3.addressOf(keccak256(abi.encodePacked(BORROWER_OPERATIONS))),
            Create3.addressOf(keccak256(abi.encodePacked(PRICE_FEED))),
            Create3.addressOf(keccak256(abi.encodePacked(SORTED_CDPS))),
            Create3.addressOf(keccak256(abi.encodePacked(ACTIVE_POOL))),
            Create3.addressOf(keccak256(abi.encodePacked(COLL_SURPLUS_POOL))),
            Create3.addressOf(keccak256(abi.encodePacked(HINT_HELPERS))),
            Create3.addressOf(keccak256(abi.encodePacked(EBTC_TOKEN))),
            Create3.addressOf(keccak256(abi.encodePacked(FEE_RECIPIENT))),
            Create3.addressOf(keccak256(abi.encodePacked(MULTI_CDP_GETTER)))
        );

        return addresses;
    }

    /**
        @notice Deploy a contract using salt in string format and arbitrary runtime code.
        @dev Intended use is: get the future eBTC addresses, then deploy the appropriate contract to each address via this method, building the constructor using the mapped addresses
        @dev no enforcment of bytecode at address as we can't know the runtime code in this contract due to space constraints
        @dev gated to given deployer EOA to ensure no interference with process, given proper actions by deployer
     */
    function deploy(
        string memory _saltString,
        bytes memory _creationCode
    ) public returns (address deployedAddress) {
        bytes32 _salt = keccak256(abi.encodePacked(_saltString));
        deployedAddress = Create3.create3(_salt, _creationCode);
        emit ContractDeployed(deployedAddress, _saltString, _salt);
    }

    function addressOf(string memory _saltString) external view returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_saltString));
        return Create3.addressOf(_salt);
    }

    function addressOfSalt(bytes32 _salt) external view returns (address) {
        return Create3.addressOf(_salt);
    }

    /**
        @notice Create the creation code for a contract with the given runtime code.
        @dev credit: https://github.com/0xsequence/create3/blob/master/contracts/test_utils/Create3Imp.sol
     */
    function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(hex"63", uint32(_code.length), hex"80_60_0E_60_00_39_60_00_F3", _code);
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