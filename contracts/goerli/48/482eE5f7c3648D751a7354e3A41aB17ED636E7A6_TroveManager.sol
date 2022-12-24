// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Dependencies/DfrancBase.sol";
import "./Dependencies/CheckContract.sol";

import "./Interfaces/ITroveManager.sol";

/*
 * In this leverage version there is no CollGasCompensation and no DCHFGasCompensation.
 * Besides, there is a protocol fee on the total Collateral liquidated.
 * No redistribution as it happens when the DCHF of the Stability Pool is not enough for the liquidation
 * and the rest of the debt and coll gets redistributed between the users.
 * No interactions with Default Pool.
 * Ownable is inherited from DfrancBase.
 */

contract TroveManager is DfrancBase, CheckContract, ITroveManager {
    using SafeERC20 for IERC20;

    string public constant NAME = "TroveManager";

    // --- Connected contract declarations --- //

    address public borrowerOperationsAddress;
    address public feeContractAddress;

    ICollSurplusPool collSurplusPool;

    IDCHFToken public override dchfToken;

    // A doubly linked list of Troves sorted by their sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    // --- Data structures --- //

    // Store the necessary data for a trove
    struct Trove {
        address asset;
        uint256 debt;
        uint256 coll;
        Status status;
        uint128 arrayIndex;
    }

    bool public isInitialized;

    uint256 public constant SECONDS_IN_ONE_MINUTE = 60;
    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint256 public constant MINUTE_DECAY_FACTOR = 999037758833783000;

    /*
     * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
     * Corresponds to (1 / ALPHA) in the white paper.
     */
    uint256 public constant BETA = 2;

    mapping(address => uint256) public baseRate;

    // The timestamp of the latest fee operation (redemption or new DCHF issuance)
    mapping(address => uint256) public lastFeeOperationTime;

    mapping(address => mapping(address => Trove)) public Troves;

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    mapping(address => address[]) public TroveOwners;

    mapping(address => bool) public redemptionWhitelist;
    bool public isRedemptionWhitelisted;

    mapping(address => bool) public liquidationWhitelist;
    bool public isLiquidationWhitelisted;

    uint256 public protocolFee; // In bps 1% = 100, 10% = 1000, 100% = 10000

    modifier troveIsActive(address _asset, address _borrower) {
        require(isTroveActive(_asset, _borrower), "TroveManager: Trove does not exist or is closed");
        _;
    }

    function _onlyBorrowerOperations() private view {
        require(msg.sender == borrowerOperationsAddress, "TroveManager: Caller is not BorrowerOperations");
    }

    modifier onlyBorrowerOperations() {
        _onlyBorrowerOperations();
        _;
    }

    // --- Dependency setter --- //

    function setAddresses(
        address _collSurplusPoolAddress,
        address _dchfTokenAddress,
        address _sortedTrovesAddress,
        address _feeContractAddress,
        address _dfrancParamsAddress,
        address _borrowerOperationsAddress
    ) external override onlyOwner {
        require(!isInitialized, "Already initialized");
        checkContract(_collSurplusPoolAddress);
        checkContract(_dchfTokenAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_feeContractAddress);
        checkContract(_dfrancParamsAddress);
        checkContract(_borrowerOperationsAddress);

        isInitialized = true;

        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        dchfToken = IDCHFToken(_dchfTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        feeContractAddress = _feeContractAddress;

        setDfrancParameters(_dfrancParamsAddress);
    }

    // --- Setter onlyOwner --- //

    function setFeeContractAddress(address _newFeeAddress) external onlyOwner {
        require(_newFeeAddress != address(0), "BorrowerOps: Not valid address");
        feeContractAddress = _newFeeAddress;
        emit FeeContractAddressChanged(feeContractAddress);
    }

    // --- Trove Getter functions --- //

    function isContractTroveManager() public pure returns (bool) {
        return true;
    }

    // --- Trove Liquidation functions --- //

    // Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
    function liquidate(address _asset, address _borrower) external override troveIsActive(_asset, _borrower) {
        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateTroves(_asset, borrowers);
    }

    // --- Inner single liquidation functions --- //

    // Liquidate one trove, in Normal Mode. Trove debt is DCHF amount + DCHF borrowing fee.
    function _liquidateNormalMode(address _asset, address _borrower)
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        (
            singleLiquidation.entireTroveColl, // coll
            singleLiquidation.entireTroveDebt // debt
        ) = _getCurrentTroveAmounts(_asset, _borrower); // Troves[_borrower][_asset]

        _closeTrove(_asset, _borrower, Status.closedByLiquidation); // Troves[_borrower][_asset] = 0;

        emit TroveLiquidated(
            _asset,
            _borrower,
            singleLiquidation.entireTroveDebt,
            singleLiquidation.entireTroveColl,
            TroveManagerOperation.liquidateInNormalMode
        );
        emit TroveUpdated(_asset, _borrower, 0, 0, TroveManagerOperation.liquidateInNormalMode);
    }

    /*
     * Liquidate a sequence of troves. Closes a maximum number of n under-collateralized Troves,
     * starting from the one with the lowest collateral ratio in the system, and moving upwards.
     */
    function liquidateTroves(address _asset, uint256 _n) external override {
        if (isLiquidationWhitelisted) {
            require(liquidationWhitelist[msg.sender], "TroveManager: Not in whitelist");
        }

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.price = dfrancParams.priceFeed().fetchPrice(_asset);

        totals = _getTotalsFromLiquidateTrovesSequence_NormalMode(_asset, vars.price, _n, msg.sender);

        require(totals.totalDebtInSequence > 0, "TroveManager: Nothing to liquidate");

        // Burn the DCHF debt amount from liquidator and compensate with the trove collateral, minus fees
        uint256 protocolCompensation = _executeLiq(
            _asset,
            totals.totalCollInSequence,
            totals.totalDebtInSequence,
            msg.sender
        );

        emit Liquidation(
            _asset,
            totals.totalDebtInSequence,
            totals.totalCollInSequence,
            protocolCompensation
        );
    }

    function _getTotalsFromLiquidateTrovesSequence_NormalMode(
        address _asset,
        uint256 _price,
        uint256 _n,
        address _liquidator
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        ISortedTroves sortedTrovesCached = sortedTroves;

        vars.remainingDCHFInLiquidator = dchfToken.balanceOf(_liquidator);

        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = sortedTrovesCached.getLast(_asset);
            vars.ICR = getCurrentICR(_asset, vars.user, _price);

            if (vars.ICR < dfrancParams.LIQ_MCR(_asset)) {
                singleLiquidation = _liquidateNormalMode(_asset, vars.user);

                require(
                    singleLiquidation.entireTroveDebt <= vars.remainingDCHFInLiquidator,
                    "Not enough funds to liquidate n Troves"
                );
                vars.remainingDCHFInLiquidator =
                    vars.remainingDCHFInLiquidator -
                    singleLiquidation.entireTroveDebt;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            } else break; // Break if the loop reaches a Trove with ICR >= MCR
        }
    }

    /*
     * Attempt to liquidate a custom list of troves provided by the caller.
     */
    function batchLiquidateTroves(address _asset, address[] memory _troveArray) public override {
        if (isLiquidationWhitelisted) {
            require(liquidationWhitelist[msg.sender], "TroveManager: Not in whitelist");
        }

        require(_troveArray.length != 0, "TroveManager: Calldata address array must not be empty");

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.price = dfrancParams.priceFeed().fetchPrice(_asset);

        totals = _getTotalsFromBatchLiquidate_NormalMode(_asset, vars.price, _troveArray, msg.sender);

        require(totals.totalDebtInSequence > 0, "TroveManager: Nothing to liquidate");

        // Burn the DCHF debt amount from liquidator and compensate with the trove collateral, minus fees
        uint256 protocolCompensation = _executeLiq(
            _asset,
            totals.totalCollInSequence,
            totals.totalDebtInSequence,
            msg.sender
        );

        emit Liquidation(
            _asset,
            totals.totalDebtInSequence,
            totals.totalCollInSequence,
            protocolCompensation
        );
    }

    function _getTotalsFromBatchLiquidate_NormalMode(
        address _asset,
        uint256 _price,
        address[] memory _troveArray,
        address _liquidator
    ) internal returns (LiquidationTotals memory totals) {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingDCHFInLiquidator = dchfToken.balanceOf(_liquidator);

        for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.user = _troveArray[vars.i];
            vars.ICR = getCurrentICR(_asset, vars.user, _price);

            if (vars.ICR < dfrancParams.LIQ_MCR(_asset)) {
                singleLiquidation = _liquidateNormalMode(_asset, vars.user);

                require(
                    singleLiquidation.entireTroveDebt <= vars.remainingDCHFInLiquidator,
                    "Not enough funds to liquidate n Troves"
                );
                vars.remainingDCHFInLiquidator =
                    vars.remainingDCHFInLiquidator -
                    singleLiquidation.entireTroveDebt;

                // Add liquidation values to their respective running totals (totals start in 0)
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

    // --- Liquidation helper functions --- //

    // Tally all the values with their respective running totals
    function _addLiquidationValuesToTotals(
        LiquidationTotals memory oldTotals,
        LiquidationValues memory singleLiquidation
    ) internal pure returns (LiquidationTotals memory newTotals) {
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence + singleLiquidation.entireTroveDebt;
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence + singleLiquidation.entireTroveColl;
    }

    function _executeLiq(
        address _asset,
        uint256 _collToRelease,
        uint256 _debtToOffset,
        address _liquidator
    ) internal returns (uint256) {
        IActivePool activePoolCached = dfrancParams.activePool();

        require(dchfToken.balanceOf(_liquidator) >= _debtToOffset, "TroveManager: Not enough balance");

        activePoolCached.decreaseDCHFDebt(_asset, _debtToOffset); // cancel the liquidated DCHF debt

        dchfToken.burn(_liquidator, _debtToOffset); // burn the DCHF debt amount form the liquidator

        uint256 protocolGain = (_collToRelease * protocolFee) / 10000;
        uint256 collToLiquidator = _collToRelease - protocolGain;

        activePoolCached.sendAsset(_asset, feeContractAddress, protocolGain);
        activePoolCached.sendAsset(_asset, _liquidator, collToLiquidator);

        return protocolGain;
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee >= 0 && _fee < 1000, "TroveManager: Invalid fee value"); // Between 0 and 10% of the total collateral
        uint256 prevFee = protocolFee;
        protocolFee = _fee;
        emit SetFees(protocolFee, prevFee);
    }

    function setLiquidationWhitelistStatus(bool _status) external onlyOwner {
        isLiquidationWhitelisted = _status;
    }

    function addUserToWhitelistLiquidation(address _user) external onlyOwner {
        liquidationWhitelist[_user] = true;
    }

    function removeUserFromWhitelistLiquidation(address _user) external onlyOwner {
        delete liquidationWhitelist[_user];
    }

    // --- Redemption functions --- //

    // Redeem as much collateral as possible from _borrower's Trove in exchange for DCHF up to _maxDCHFamount
    function _redeemCollateralFromTrove(
        address _asset,
        ContractsCache memory _contractsCache,
        address _borrower,
        uint256 _maxDCHFamount,
        uint256 _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR
    ) internal returns (SingleRedemptionValues memory singleRedemption) {
        LocalVariables_AssetBorrowerPrice memory vars = LocalVariables_AssetBorrowerPrice(
            _asset,
            _borrower,
            _price
        );

        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Trove minus the liquidation reserve
        singleRedemption.DCHFLot = DfrancMath._min(_maxDCHFamount, getTroveDebt(vars._asset, vars._borrower));

        // Get the ETHLot of equivalent value in USD (ETH value of the DCHF amount to redeem)
        singleRedemption.ETHLot = (singleRedemption.DCHFLot * DECIMAL_PRECISION) / _price;

        // Decrease the debt and collateral of the current Trove according to the DCHF lot and corresponding ETH to send
        uint256 newDebt = (getTroveDebt(vars._asset, vars._borrower)) - singleRedemption.DCHFLot;
        uint256 newColl = (getTroveColl(vars._asset, vars._borrower)) - singleRedemption.ETHLot; // newColl is the collSurplus that remains for the borrower (TotalColl - ETHLot)

        if (newDebt == 0) {
            // No debt left in the Trove (except for the liquidation reserve), therefore the trove gets closed
            _closeTrove(vars._asset, vars._borrower, Status.closedByRedemption);

            _redeemCloseTrove(vars._asset, _contractsCache, vars._borrower, newColl);

            emit TroveUpdated(vars._asset, vars._borrower, 0, 0, TroveManagerOperation.redeemCollateral);
        } else {
            uint256 newNICR = DfrancMath._computeNominalCR(newColl, newDebt);

            /*
             * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
             * certainly result in running out of gas.
             *
             * If the resultant net debt of the partial is less than the minimum, net debt we bail.
             */
            if (newNICR != _partialRedemptionHintNICR || newDebt < dfrancParams.MIN_NET_DEBT(vars._asset)) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            _contractsCache.sortedTroves.reInsert(
                vars._asset,
                vars._borrower,
                newNICR,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint
            );

            _setTroveDebtAndColl(vars._asset, vars._borrower, newDebt, newColl);

            emit TroveUpdated(
                vars._asset,
                vars._borrower,
                newDebt,
                newColl,
                TroveManagerOperation.redeemCollateral
            );
        }

        return singleRedemption;
    }

    /*
     * Called when a full redemption occurs, and closes the trove.
     * The redeemer swaps (debt) DCHF for (debt) worth of ETH, as here there is no DCHF liquidation reserve.
     * In this case, there is no need to burn the DCHF liquidation reserve, and remove the corresponding debt from the active pool.
     * The debt recorded on the trove's struct is zero'd elsewhere, in _closeTrove.
     * Any surplus ETH left in the trove, is sent to the Coll surplus pool, and can be later claimed by the borrower.
     */
    function _redeemCloseTrove(
        address _asset,
        ContractsCache memory _contractsCache,
        address _borrower,
        uint256 _ETH
    ) internal {
        // Send ETH from Active Pool to the CollSurplusPool -> the borrower can reclaim it later
        _contractsCache.collSurplusPool.accountSurplus(_asset, _borrower, _ETH);
        _contractsCache.activePool.sendAsset(_asset, address(_contractsCache.collSurplusPool), _ETH);
    }

    function _isValidFirstRedemptionHint(
        address _asset,
        ISortedTroves _sortedTroves,
        address _firstRedemptionHint,
        uint256 _price
    ) internal view returns (bool) {
        if (
            _firstRedemptionHint == address(0) ||
            !_sortedTroves.contains(_asset, _firstRedemptionHint) ||
            getCurrentICR(_asset, _firstRedemptionHint, _price) < dfrancParams.LIQ_MCR(_asset)
        ) {
            return false;
        }

        address nextTrove = _sortedTroves.getNext(_asset, _firstRedemptionHint);
        return
            nextTrove == address(0) ||
            getCurrentICR(_asset, nextTrove, _price) < dfrancParams.LIQ_MCR(_asset);
    }

    function setRedemptionWhitelistStatus(bool _status) external onlyOwner {
        isRedemptionWhitelisted = _status;
    }

    function addUserToWhitelistRedemption(address _user) external onlyOwner {
        redemptionWhitelist[_user] = true;
    }

    function removeUserFromWhitelistRedemption(address _user) external onlyOwner {
        delete redemptionWhitelist[_user];
    }

    /* Send _DCHFamount DCHF to the system and redeem the corresponding amount of collateral from as many Troves as are needed to fill the redemption
     * request. Applies pending rewards to a Trove before reducing its debt and coll.
     *
     * Note that if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
     * splitting the total _amount in appropriate chunks and calling the function multiple times.
     *
     * Param `_maxIterations` can also be provided, so the loop through Troves is capped (if it’s zero, it will be ignored).This makes it easier to
     * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
     * of the trove list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
     * costs can vary.
     *
     * All Troves that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
     * If the last Trove does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
     * A frontend should use getRedemptionHints() to calculate what the ICR of this Trove will be after redemption, and pass a hint for its position
     * in the sortedTroves list along with the ICR value that the hint was found for.
     *
     * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
     * is very likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the
     * redemption will stop after the last completely redeemed Trove and the sender will keep the remaining DCHF amount, which they can attempt
     * to redeem later.
     *
     * A redemption sequence of n steps will fully redeem from up to n-1 Troves, and, and partially redeems from up to 1 Trove, which is always the last
     * Trove in the redemption sequence.
     */
    function redeemCollateral(
        address _asset,
        uint256 _DCHFamount,
        address _firstRedemptionHint, // hints at the position of the first Trove that will be redeemed from
        address _upperPartialRedemptionHint, // hints at the prevId neighbor of the last redeemed Trove upon reinsertion, if it's partially redeemed
        address _lowerPartialRedemptionHint, // hints at the nextId neighbor of the last redeemed Trove upon reinsertion, if it's partially redeemed
        uint256 _partialRedemptionHintNICR, // ensures that the transaction won't run out of gas if neither
        uint256 _maxIterations,
        uint256 _maxFeePercentage
    ) external override {
        if (isRedemptionWhitelisted) {
            require(redemptionWhitelist[msg.sender], "TroveManager: Not in whitelist");
        }

        // Redemptions are disabled during the first 14 days of operation to protect the system
        require(
            block.timestamp >= dfrancParams.redemptionBlock(_asset),
            "TroveManager: Redemption is blocked"
        );

        ContractsCache memory contractsCache = ContractsCache(
            dfrancParams.activePool(),
            dchfToken,
            sortedTroves,
            collSurplusPool
        );

        RedemptionTotals memory totals;

        totals.price = dfrancParams.priceFeed().fetchPrice(_asset);

        _requireValidMaxFeePercentage(_asset, _maxFeePercentage);
        _requireTCRoverMCR(_asset, totals.price);
        _requireAmountGreaterThanZero(_DCHFamount);
        _requireDCHFBalanceCoversRedemption(contractsCache.dchfToken, msg.sender, _DCHFamount);

        totals.totalDCHFSupplyAtStart = getEntireSystemDebt(_asset); // activePool
        totals.remainingDCHF = _DCHFamount;
        address currentBorrower;

        if (
            _isValidFirstRedemptionHint(
                _asset,
                contractsCache.sortedTroves,
                _firstRedemptionHint,
                totals.price
            )
        ) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedTroves.getLast(_asset);
            // Find the first trove with ICR >= MCR -> will only redeem from Troves that have an ICR >= MCR
            // Troves are redeemed from in ascending order of their collateralization ratio
            while (
                currentBorrower != address(0) &&
                getCurrentICR(_asset, currentBorrower, totals.price) < dfrancParams.LIQ_MCR(_asset)
            ) {
                currentBorrower = contractsCache.sortedTroves.getPrev(_asset, currentBorrower);
            }
        }

        // Loop through the Troves starting from the one with lowest collateral ratio until _amount of DCHF is exchanged for collateral
        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }
        while (currentBorrower != address(0) && totals.remainingDCHF > 0 && _maxIterations > 0) {
            _maxIterations--;
            // Save the address of the Trove preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedTroves.getPrev(_asset, currentBorrower);

            SingleRedemptionValues memory singleRedemption = _redeemCollateralFromTrove(
                _asset,
                contractsCache,
                currentBorrower,
                totals.remainingDCHF,
                totals.price,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNICR
            );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Trove

            totals.totalDCHFToRedeem = totals.totalDCHFToRedeem + singleRedemption.DCHFLot;
            totals.totalAssetDrawn = totals.totalAssetDrawn + singleRedemption.ETHLot;

            totals.remainingDCHF = totals.remainingDCHF - singleRedemption.DCHFLot;
            currentBorrower = nextUserToCheck;
        }
        require(totals.totalAssetDrawn > 0, "TroveManager: Unable to redeem any amount");

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // The baseRate increases with each redemption, and decays according to time passed since the last fee event.
        // Use the saved total DCHF supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(
            _asset,
            totals.totalAssetDrawn,
            totals.price,
            totals.totalDCHFSupplyAtStart
        );

        // Calculate the ETH fee
        totals.ETHFee = _getRedemptionFee(_asset, totals.totalAssetDrawn);

        _requireUserAcceptsFee(totals.ETHFee, totals.totalAssetDrawn, _maxFeePercentage);

        // Send the ETH fee to the feeContract
        contractsCache.activePool.sendAsset(_asset, feeContractAddress, totals.ETHFee);

        totals.ETHToSendToRedeemer = totals.totalAssetDrawn - totals.ETHFee;

        emit Redemption(_asset, _DCHFamount, totals.totalDCHFToRedeem, totals.totalAssetDrawn, totals.ETHFee);

        // Burn the total DCHF that is cancelled with debt, and send the redeemed Asset (ETH) to msg.sender
        contractsCache.dchfToken.burn(msg.sender, totals.totalDCHFToRedeem);

        // Update Active Pool DCHF, and send ETH to account
        contractsCache.activePool.decreaseDCHFDebt(_asset, totals.totalDCHFToRedeem);
        contractsCache.activePool.sendAsset(_asset, msg.sender, totals.ETHToSendToRedeemer);
    }

    // --- Helper functions --- //

    // Return the nominal collateral ratio (ICR) of a given Trove, without the price. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _asset, address _borrower) public view override returns (uint256) {
        (uint256 currentAsset, uint256 currentDCHFDebt) = _getCurrentTroveAmounts(_asset, _borrower);
        uint256 NICR = DfrancMath._computeNominalCR(currentAsset, currentDCHFDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(
        address _asset,
        address _borrower,
        uint256 _price
    ) public view override returns (uint256) {
        (uint256 currentAsset, uint256 currentDCHFDebt) = _getCurrentTroveAmounts(_asset, _borrower);
        uint256 ICR = DfrancMath._computeCR(currentAsset, currentDCHFDebt, _price);
        return ICR;
    }

    function _getCurrentTroveAmounts(address _asset, address _borrower)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 currentAsset = Troves[_borrower][_asset].coll;
        uint256 currentDCHFDebt = Troves[_borrower][_asset].debt;

        return (currentAsset, currentDCHFDebt);
    }

    function closeTrove(address _asset, address _borrower) external override onlyBorrowerOperations {
        _closeTrove(_asset, _borrower, Status.closedByOwner);
    }

    function _closeTrove(
        address _asset,
        address _borrower,
        Status closedStatus
    ) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint256 TroveOwnersArrayLength = TroveOwners[_asset].length;
        _requireMoreThanOneTroveInSystem(_asset, TroveOwnersArrayLength);

        Troves[_borrower][_asset].status = closedStatus;
        Troves[_borrower][_asset].coll = 0;
        Troves[_borrower][_asset].debt = 0;

        _removeTroveOwner(_asset, _borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_asset, _borrower);
    }

    function addTroveOwnerToArray(address _asset, address _borrower)
        external
        override
        onlyBorrowerOperations
        returns (uint256)
    {
        return _addTroveOwnerToArray(_asset, _borrower);
    }

    function _addTroveOwnerToArray(address _asset, address _borrower) internal returns (uint128 index) {
        TroveOwners[_asset].push(_borrower);

        index = uint128(TroveOwners[_asset].length - 1);
        Troves[_borrower][_asset].arrayIndex = index;
    }

    function _removeTroveOwner(
        address _asset,
        address _borrower,
        uint256 troveOwnersArrayLength
    ) internal {
        Status troveStatus = Troves[_borrower][_asset].status;
        assert(troveStatus != Status.nonExistent && troveStatus != Status.active);

        uint128 index = Troves[_borrower][_asset].arrayIndex;
        uint256 length = troveOwnersArrayLength;
        uint256 idxLast = length - 1;

        assert(index <= idxLast);

        address addressToMove = TroveOwners[_asset][idxLast];

        TroveOwners[_asset][index] = addressToMove;
        Troves[addressToMove][_asset].arrayIndex = index;
        emit TroveIndexUpdated(_asset, addressToMove, index);

        TroveOwners[_asset].pop();
    }

    function getTCR(address _asset, uint256 _price) external view override returns (uint256) {
        return _getTCR(_asset, _price);
    }

    function _updateBaseRateFromRedemption(
        address _asset,
        uint256 _ETHDrawn,
        uint256 _price,
        uint256 _totalDCHFSupply
    ) internal returns (uint256) {
        uint256 decayedBaseRate = _calcDecayedBaseRate(_asset);

        uint256 redeemedDCHFFraction = (_ETHDrawn * _price) / _totalDCHFSupply;

        uint256 newBaseRate = decayedBaseRate + (redeemedDCHFFraction / BETA);
        newBaseRate = DfrancMath._min(newBaseRate, DECIMAL_PRECISION);
        assert(newBaseRate > 0);

        baseRate[_asset] = newBaseRate;
        emit BaseRateUpdated(_asset, newBaseRate);

        _updateLastFeeOpTime(_asset);

        return newBaseRate;
    }

    function getRedemptionRate(address _asset) public view override returns (uint256) {
        return _calcRedemptionRate(_asset, baseRate[_asset]);
    }

    function getRedemptionRateWithDecay(address _asset) public view override returns (uint256) {
        return _calcRedemptionRate(_asset, _calcDecayedBaseRate(_asset));
    }

    function _calcRedemptionRate(address _asset, uint256 _baseRate) internal view returns (uint256) {
        return DfrancMath._min(dfrancParams.REDEMPTION_FEE_FLOOR(_asset) + _baseRate, DECIMAL_PRECISION);
    }

    function _getRedemptionFee(address _asset, uint256 _assetDraw) internal view returns (uint256) {
        return _calcRedemptionFee(getRedemptionRate(_asset), _assetDraw);
    }

    function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw)
        external
        view
        override
        returns (uint256)
    {
        return _calcRedemptionFee(getRedemptionRateWithDecay(_asset), _assetDraw);
    }

    function _calcRedemptionFee(uint256 _redemptionRate, uint256 _assetDraw) internal pure returns (uint256) {
        uint256 redemptionFee = (_redemptionRate * _assetDraw) / DECIMAL_PRECISION;
        require(redemptionFee < _assetDraw, "TroveManager: Fee would eat up all returned collateral");
        return redemptionFee;
    }

    function getBorrowingRate(address _asset) public view override returns (uint256) {
        return _calcBorrowingRate(_asset, baseRate[_asset]);
    }

    function getBorrowingRateWithDecay(address _asset) public view override returns (uint256) {
        return _calcBorrowingRate(_asset, _calcDecayedBaseRate(_asset));
    }

    function _calcBorrowingRate(address _asset, uint256 _baseRate) internal view returns (uint256) {
        return
            DfrancMath._min(
                dfrancParams.BORROWING_FEE_FLOOR(_asset) + _baseRate,
                dfrancParams.MAX_BORROWING_FEE(_asset)
            );
    }

    function getBorrowingFee(address _asset, uint256 _DCHFDebt) external view override returns (uint256) {
        return _calcBorrowingFee(getBorrowingRate(_asset), _DCHFDebt);
    }

    function getBorrowingFeeWithDecay(address _asset, uint256 _DCHFDebt) external view returns (uint256) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(_asset), _DCHFDebt);
    }

    function _calcBorrowingFee(uint256 _borrowingRate, uint256 _DCHFDebt) internal pure returns (uint256) {
        return (_borrowingRate * _DCHFDebt) / DECIMAL_PRECISION;
    }

    function decayBaseRateFromBorrowing(address _asset) external override onlyBorrowerOperations {
        uint256 decayedBaseRate = _calcDecayedBaseRate(_asset);
        assert(decayedBaseRate <= DECIMAL_PRECISION);

        baseRate[_asset] = decayedBaseRate;
        emit BaseRateUpdated(_asset, decayedBaseRate);

        _updateLastFeeOpTime(_asset);
    }

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime(address _asset) internal {
        uint256 timePassed = block.timestamp - lastFeeOperationTime[_asset];

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime[_asset] = block.timestamp;
            emit LastFeeOpTimeUpdated(_asset, block.timestamp);
        }
    }

    function _calcDecayedBaseRate(address _asset) internal view returns (uint256) {
        uint256 minutesPassed = _minutesPassedSinceLastFeeOp(_asset);
        uint256 decayFactor = DfrancMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return (baseRate[_asset] * decayFactor) / DECIMAL_PRECISION;
    }

    function _minutesPassedSinceLastFeeOp(address _asset) internal view returns (uint256) {
        return (block.timestamp - lastFeeOperationTime[_asset]) / SECONDS_IN_ONE_MINUTE;
    }

    function _requireDCHFBalanceCoversRedemption(
        IDCHFToken _dchfToken,
        address _redeemer,
        uint256 _amount
    ) internal view {
        require(
            _dchfToken.balanceOf(_redeemer) >= _amount,
            "TroveManager: Requested redemption amount must be <= user's DCHF token balance"
        );
    }

    function _requireMoreThanOneTroveInSystem(address _asset, uint256 TroveOwnersArrayLength) internal view {
        require(
            TroveOwnersArrayLength > 1 && sortedTroves.getSize(_asset) > 1,
            "TroveManager: Only one trove in the system"
        );
    }

    function _requireAmountGreaterThanZero(uint256 _amount) internal pure {
        require(_amount > 0, "TroveManager: Amount must be greater than zero");
    }

    function _requireTCRoverMCR(address _asset, uint256 _price) internal view {
        require(
            _getTCR(_asset, _price) >= dfrancParams.LIQ_MCR(_asset),
            "TroveManager: Cannot redeem when TCR < MCR"
        );
    }

    function _requireValidMaxFeePercentage(address _asset, uint256 _maxFeePercentage) internal view {
        require(
            _maxFeePercentage >= dfrancParams.REDEMPTION_FEE_FLOOR(_asset) &&
                _maxFeePercentage <= DECIMAL_PRECISION,
            "Max fee percentage must be between 0.5% and 100%"
        );
    }

    function isTroveActive(address _asset, address _borrower) public view override returns (bool) {
        return getTroveStatus(_asset, _borrower) == uint256(Status.active);
    }

    // --- Trove owners getters --- //

    function getTroveOwnersCount(address _asset) external view override returns (uint256) {
        return TroveOwners[_asset].length;
    }

    function getTroveFromTroveOwnersArray(address _asset, uint256 _index)
        external
        view
        override
        returns (address)
    {
        return TroveOwners[_asset][_index];
    }

    // --- Trove property getters --- //

    function getTrove(address _asset, address _borrower)
        external
        view
        override
        returns (
            address,
            uint256,
            uint256,
            Status,
            uint128
        )
    {
        Trove memory _trove = Troves[_borrower][_asset];
        return (_trove.asset, _trove.debt, _trove.coll, _trove.status, _trove.arrayIndex);
    }

    function getTroveStatus(address _asset, address _borrower) public view override returns (uint256) {
        return uint256(Troves[_borrower][_asset].status);
    }

    function getTroveDebt(address _asset, address _borrower) public view override returns (uint256) {
        return Troves[_borrower][_asset].debt;
    }

    function getTroveColl(address _asset, address _borrower) public view override returns (uint256) {
        return Troves[_borrower][_asset].coll;
    }

    function getEntireDebtAndColl(address _asset, address _borrower)
        public
        view
        override
        returns (uint256 debt, uint256 coll)
    {
        debt = Troves[_borrower][_asset].debt;
        coll = Troves[_borrower][_asset].coll;
    }

    // --- Trove property setters, internal --- //

    function _setTroveDebtAndColl(
        address _asset,
        address _borrower,
        uint256 _debt,
        uint256 _coll
    ) internal {
        Troves[_borrower][_asset].debt = _debt;
        Troves[_borrower][_asset].coll = _coll;
    }

    // --- Trove property setters, called by BorrowerOperations --- //

    function setTroveStatus(
        address _asset,
        address _borrower,
        uint256 _num
    ) external override onlyBorrowerOperations {
        Troves[_borrower][_asset].asset = _asset;
        Troves[_borrower][_asset].status = Status(_num);
    }

    function decreaseTroveColl(
        address _asset,
        address _borrower,
        uint256 _collDecrease
    ) external override onlyBorrowerOperations returns (uint256) {
        uint256 newColl = Troves[_borrower][_asset].coll - _collDecrease;
        Troves[_borrower][_asset].coll = newColl;
        return newColl;
    }

    function increaseTroveDebt(
        address _asset,
        address _borrower,
        uint256 _debtIncrease
    ) external override onlyBorrowerOperations returns (uint256) {
        uint256 newDebt = Troves[_borrower][_asset].debt + _debtIncrease;
        Troves[_borrower][_asset].debt = newDebt;
        return newDebt;
    }

    function decreaseTroveDebt(
        address _asset,
        address _borrower,
        uint256 _debtDecrease
    ) external override onlyBorrowerOperations returns (uint256) {
        uint256 newDebt = Troves[_borrower][_asset].debt - _debtDecrease;
        Troves[_borrower][_asset].debt = newDebt;
        return newDebt;
    }

    function increaseTroveColl(
        address _asset,
        address _borrower,
        uint256 _collIncrease
    ) external override onlyBorrowerOperations returns (uint256) {
        uint256 newColl = Troves[_borrower][_asset].coll + _collIncrease;
        Troves[_borrower][_asset].coll = newColl;
        return newColl;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract CheckContract {
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseMath.sol";
import "./DfrancMath.sol";

import "../Interfaces/IActivePool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IDfrancBase.sol";

/*
 * Base contract for TroveManager & BorrowerOperations. Contains global system constants and common functions.
 */
contract DfrancBase is BaseMath, IDfrancBase, Ownable {
    address public constant ETH_REF_ADDRESS = address(0);

    IDfrancParameters public override dfrancParams;

    function setDfrancParameters(address _vaultParams) public onlyOwner {
        dfrancParams = IDfrancParameters(_vaultParams);
        emit VaultParametersBaseChanged(_vaultParams);
    }

    function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
        entireSystemColl = dfrancParams.activePool().getAssetBalance(_asset); // activeColl
    }

    function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
        entireSystemDebt = dfrancParams.activePool().getDCHFDebt(_asset); // activeDebt
    }

    function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
        uint256 entireSystemColl = getEntireSystemColl(_asset);
        uint256 entireSystemDebt = getEntireSystemDebt(_asset);

        TCR = DfrancMath._computeCR(entireSystemColl, entireSystemDebt, _price);
    }

    function _requireUserAcceptsFee(
        uint256 _fee,
        uint256 _amount,
        uint256 _maxFeePercentage
    ) internal view {
        uint256 feePercentage = (_fee * dfrancParams.DECIMAL_PRECISION()) / _amount;
        require(feePercentage <= _maxFeePercentage, "Fee needs to be below max");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IDfrancBase.sol";
import "./IDCHFToken.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IActivePool.sol";

// Common Interface for the Trove Manager
interface ITroveManager is IDfrancBase {
    // --- Variable container structs for liquidations --- //
    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }
    /*
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     **/

    struct LocalVariables_OuterLiquidationFunction {
        uint256 price;
        uint256 DCHFInLiquidator;
        uint256 liquidatedDebt;
        uint256 liquidatedColl;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        uint256 collToLiquidate;
        uint256 pendingDebtReward;
        uint256 pendingCollReward;
    }

    struct LocalVariables_LiquidationSequence {
        uint256 remainingDCHFInLiquidator;
        uint256 i;
        uint256 ICR;
        address user;
        uint256 entireSystemDebt;
        uint256 entireSystemColl;
    }

    struct LocalVariables_AssetBorrowerPrice {
        address _asset;
        address _borrower;
        uint256 _price;
    }

    struct LiquidationValues {
        uint256 entireTroveDebt;
        uint256 entireTroveColl;
    }

    struct LiquidationTotals {
        uint256 totalCollInSequence;
        uint256 totalDebtInSequence;
    }

    struct ContractsCache {
        IActivePool activePool;
        IDCHFToken dchfToken;
        ISortedTroves sortedTroves;
        ICollSurplusPool collSurplusPool;
    }

    // --- Variable container structs for redemptions --- //

    struct RedemptionTotals {
        uint256 remainingDCHF;
        uint256 totalDCHFToRedeem;
        uint256 totalAssetDrawn;
        uint256 ETHFee;
        uint256 ETHToSendToRedeemer;
        uint256 decayedBaseRate;
        uint256 price;
        uint256 totalDCHFSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint256 DCHFLot;
        uint256 ETHLot;
        bool cancelledPartial;
    }

    // --- Events --- //

    event Liquidation(
        address indexed _asset,
        uint256 _liquidatedDebt,
        uint256 _liquidatedColl,
        uint256 _protocolCompensation
    );
    event Redemption(
        address indexed _asset,
        uint256 _attemptedMONmount,
        uint256 _actualMONmount,
        uint256 _AssetSent,
        uint256 _AssetFee
    );
    event TroveUpdated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint8 operation
    );
    event TroveLiquidated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint8 operation
    );
    event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
    event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
    event TroveIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);
    event SetFees(uint256 fee, uint256 prevFee);
    event FeeContractAddressChanged(address _feeContractAddress);

    event TroveUpdated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        TroveManagerOperation _operation
    );
    event TroveLiquidated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        TroveManagerOperation _operation
    );

    enum TroveManagerOperation {
        liquidateInNormalMode,
        redeemCollateral
    }

    // --- Functions --- //

    function setAddresses(
        address _collSurplusPoolAddress,
        address _dchfTokenAddress,
        address _sortedTrovesAddress,
        address _feeContractAddress,
        address _dfrancParamsAddress,
        address _borrowerOperationsAddress
    ) external;

    function dchfToken() external view returns (IDCHFToken);

    function liquidate(address _asset, address borrower) external;

    function liquidateTroves(address _asset, uint256 _n) external;

    function batchLiquidateTroves(address _asset, address[] memory _troveArray) external;

    function redeemCollateral(
        address _asset,
        uint256 _MONmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        uint256 _maxFee
    ) external;

    function getTrove(address _asset, address _borrower)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            Status,
            uint128
        );

    function addTroveOwnerToArray(address _asset, address _borrower) external returns (uint256 index);

    function closeTrove(address _asset, address _borrower) external;

    function decayBaseRateFromBorrowing(address _asset) external;

    function decreaseTroveColl(
        address _asset,
        address _borrower,
        uint256 _collDecrease
    ) external returns (uint256);

    function decreaseTroveDebt(
        address _asset,
        address _borrower,
        uint256 _collDecrease
    ) external returns (uint256);

    function getBorrowingFee(address _asset, uint256 DCHFDebt) external view returns (uint256);

    function getBorrowingRateWithDecay(address _asset) external view returns (uint256);

    function getBorrowingRate(address _asset) external view returns (uint256);

    function getCurrentICR(
        address _asset,
        address _borrower,
        uint256 _price
    ) external view returns (uint256);

    function getNominalICR(address _asset, address _borrower) external view returns (uint256);

    function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw) external view returns (uint256);

    function getRedemptionRate(address _asset) external view returns (uint256);

    function getRedemptionRateWithDecay(address _asset) external view returns (uint256);

    function getTCR(address _asset, uint256 _price) external view returns (uint256);

    function getTroveColl(address _asset, address _borrower) external view returns (uint256);

    function getTroveDebt(address _asset, address _borrower) external view returns (uint256);

    function getTroveStatus(address _asset, address _borrower) external view returns (uint256);

    function getEntireDebtAndColl(address _asset, address _borrower)
        external
        view
        returns (uint256 debt, uint256 coll);

    function increaseTroveColl(
        address _asset,
        address _borrower,
        uint256 _collIncrease
    ) external returns (uint256);

    function increaseTroveDebt(
        address _asset,
        address _borrower,
        uint256 _debtIncrease
    ) external returns (uint256);

    function setTroveStatus(
        address _asset,
        address _borrower,
        uint256 num
    ) external;

    function getBorrowingFeeWithDecay(address _asset, uint256 _DCHFDebt) external view returns (uint256);

    function getTroveOwnersCount(address _asset) external view returns (uint256);

    function getTroveFromTroveOwnersArray(address _asset, uint256 _index) external view returns (address);

    function isTroveActive(address _asset, address _borrower) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
pragma solidity ^0.8.14;

abstract contract BaseMath {
    uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library DfrancMath {
    using SafeMath for uint256;

    uint256 internal constant DECIMAL_PRECISION = 1 ether;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint256 internal constant NICR_PRECISION = 1e20;

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) TroveManager._calcDecayedBaseRate
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
    function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
        if (_minutes > 525600000) {
            _minutes = 525600000;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            return _coll.mul(_price).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events --- //
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolDCHFDebtUpdated(address _asset, uint256 _DCHFDebt);
    event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

    // --- Functions --- //
    function sendAsset(
        address _asset,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IDfrancParameters.sol";

interface IDfrancBase {
    event VaultParametersBaseChanged(address indexed newAddress);

    function dfrancParams() external view returns (IDfrancParameters);
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IOracle.sol";

pragma solidity ^0.8.14;

interface IPriceFeed {
    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    struct OracleResponse {
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    struct RegisterOracle {
        IOracle oracle;
        AggregatorV3Interface chainLinkForex;
        bool isRegistered;
    }

    enum Status {
        chainlinkWorking,
        chainlinkUntrusted
    }

    // --- Events ---
    event PriceFeedStatusChanged(Status newStatus);
    event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
    event LastGoodForexUpdated(address indexed token, uint256 _lastGoodIndex);
    event RegisteredNewOracle(address token, address oracle, address chianLinkIndex);

    // --- Function ---
    function addOracle(
        address _token,
        address _oracle,
        address _chainlinkForexOracle
    ) external;

    function fetchPrice(address _token) external returns (uint256);

    function getDirectPrice(address _asset) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IDeposit.sol";

// Common interface for the Pools.
interface IPool is IDeposit {
    // --- Events --- //

    event AssetBalanceUpdated(uint256 _newBalance);
    event DCHFBalanceUpdated(uint256 _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event AssetAddressChanged(address _assetAddress);
    event AssetSent(address _to, address indexed _asset, uint256 _amount);

    // --- Functions --- //

    function getAssetBalance(address _asset) external view returns (uint256);

    function getDCHFDebt(address _asset) external view returns (uint256);

    function increaseDCHFDebt(address _asset, uint256 _amount) external;

    function decreaseDCHFDebt(address _asset, uint256 _amount) external;
}

pragma solidity 0.8.14;

interface IDeposit {
    function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IActivePool.sol";
import "./IPriceFeed.sol";
import "./IDfrancBase.sol";

interface IDfrancParameters {
    error SafeCheckError(string parameter, uint256 valueEntered, uint256 minValue, uint256 maxValue);

    event BORROW_MCRChanged(uint256 oldBorrowMCR, uint256 newBorrowMCR);
    event LIQ_MCRChanged(uint256 oldLiqMCR, uint256 newLiqMCR);
    event LIMIT_CRChanged(uint256 oldLIMIT_CR, uint256 newLIMIT_CR);
    event TVL_CAPChanged(uint256 oldTVL_CAP, uint256 newTVL_CAP);
    event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
    event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
    event BorrowingFeeFloorChanged(uint256 oldBorrowingFloorFee, uint256 newBorrowingFloorFee);
    event MaxBorrowingFeeChanged(uint256 oldMaxBorrowingFee, uint256 newMaxBorrowingFee);
    event RedemptionFeeFloorChanged(uint256 oldRedemptionFeeFloor, uint256 newRedemptionFeeFloor);
    event RedemptionBlockRemoved(address _asset);
    event PriceFeedChanged(address indexed addr);

    function DECIMAL_PRECISION() external view returns (uint256);

    function _100pct() external view returns (uint256);

    function BORROW_MCR(address _collateral) external view returns (uint256);

    function LIQ_MCR(address _collateral) external view returns (uint256);

    function LIMIT_CR(address _collateral) external view returns (uint256);

    function TVL_CAP(address _collateral) external view returns (uint256);

    function MIN_NET_DEBT(address _collateral) external view returns (uint256);

    function PERCENT_DIVISOR(address _collateral) external view returns (uint256);

    function BORROWING_FEE_FLOOR(address _collateral) external view returns (uint256);

    function REDEMPTION_FEE_FLOOR(address _collateral) external view returns (uint256);

    function MAX_BORROWING_FEE(address _collateral) external view returns (uint256);

    function redemptionBlock(address _collateral) external view returns (uint256);

    function activePool() external view returns (IActivePool);

    function priceFeed() external view returns (IPriceFeed);

    function setAddresses(
        address _activePool,
        address _priceFeed,
        address _adminContract
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function setBORROW_MCR(address _asset, uint256 newBorrowMCR) external;

    function setLIQ_MCR(address _asset, uint256 newLiqMCR) external;

    function setLIMIT_CR(address _asset, uint256 newLIMIT_CR) external;

    function setTVL_CAP(address _asset, uint256 newTVL_CAP) external;

    function sanitizeParameters(address _asset) external returns (bool);

    function setAsDefault(address _asset) external;

    function setAsDefaultWithRedemptionBlock(address _asset, uint256 blockInDays) external;

    function setMinNetDebt(address _asset, uint256 minNetDebt) external;

    function setPercentDivisor(address _asset, uint256 percentDivisor) external;

    function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor) external;

    function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee) external;

    function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor) external;

    function removeRedemptionBlock(address _asset) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IOracle {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestAnswer() external view returns (int256 answer, uint256 updatedAt);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {
    // --- Events --- //

    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
    event NodeRemoved(address indexed _asset, address _id);

    // --- Functions --- //

    function setParams(address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(
        address _asset,
        address _id,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external;

    function remove(address _asset, address _id) external;

    function reInsert(
        address _asset,
        address _id,
        uint256 _newICR,
        address _prevId,
        address _nextId
    ) external;

    function contains(address _asset, address _id) external view returns (bool);

    function isFull(address _asset) external view returns (bool);

    function isEmpty(address _asset) external view returns (bool);

    function getSize(address _asset) external view returns (uint256);

    function getMaxSize(address _asset) external view returns (uint256);

    function getFirst(address _asset) external view returns (address);

    function getLast(address _asset) external view returns (address);

    function getNext(address _asset, address _id) external view returns (address);

    function getPrev(address _asset, address _id) external view returns (address);

    function validInsertPosition(
        address _asset,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (bool);

    function findInsertPosition(
        address _asset,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {
    // --- Events --- //

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
    event AssetSent(address _to, uint256 _amount);

    // --- Contract setters --- //

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getAssetBalance(address _asset) external view returns (uint256);

    function getCollateral(address _asset, address _account) external view returns (uint256);

    function accountSurplus(
        address _asset,
        address _account,
        uint256 _amount
    ) external;

    function claimColl(address _asset, address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../Dependencies/ERC20Permit.sol";

import "../Interfaces/IStabilityPoolManager.sol";

abstract contract IDCHFToken is ERC20Permit {
    // --- Events --- //

    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);

    event DCHFTokenBalanceUpdated(address _user, uint256 _amount);

    function emergencyStopMinting(address _asset, bool status) external virtual;

    function addTroveManager(address _troveManager) external virtual;

    function removeTroveManager(address _troveManager) external virtual;

    function addBorrowerOps(address _borrowerOps) external virtual;

    function removeBorrowerOps(address _borrowerOps) external virtual;

    function mint(
        address _asset,
        address _account,
        uint256 _amount
    ) external virtual;

    function burn(address _account, uint256 _amount) external virtual;

    function sendToPool(
        address _sender,
        address poolAddress,
        uint256 _amount
    ) external virtual;

    function returnFromPool(
        address poolAddress,
        address user,
        uint256 _amount
    ) external virtual;
}

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC2612Permit {
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
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    /**
     * @dev See {IERC2612Permit-permit}.
     *
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline)
        );

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "ERC20Permit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    /**
     * @dev See {IERC2612Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    function chainId() public view returns (uint256 chainID) {
        assembly {
            chainID := chainid()
        }
    }
}

pragma solidity 0.8.14;

import "./IStabilityPool.sol";

interface IStabilityPoolManager {
    event StabilityPoolAdded(address asset, address stabilityPool);
    event StabilityPoolRemoved(address asset, address stabilityPool);

    function isStabilityPool(address stabilityPool) external view returns (bool);

    function addStabilityPool(address asset, address stabilityPool) external;

    function getAssetStabilityPool(address asset) external view returns (IStabilityPool);

    function unsafeGetAssetStabilityPool(address asset) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
    // --- Events --- //
    event StabilityPoolAssetBalanceUpdated(uint256 _newBalance);
    event StabilityPoolDCHFBalanceUpdated(uint256 _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event DCHFTokenAddressChanged(address _newDCHFTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint256 _P);
    event S_Updated(uint256 _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _S, uint256 _G);
    event SystemSnapshotUpdated(uint256 _P, uint256 _G);
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
    event StakeChanged(uint256 _newSystemStake, address _depositor);

    event AssetGainWithdrawn(address indexed _depositor, uint256 _Asset, uint256 _DCHFLoss);
    event MONPaidToDepositor(address indexed _depositor, uint256 _MON);
    event AssetSent(address _to, uint256 _amount);

    // --- Functions --- //

    function NAME() external view returns (string memory name);

    /*
     * Called only once on init, to set addresses of other Dfranc contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _assetAddress,
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _troveManagerHelperAddress,
        address _dchfTokenAddress,
        address _sortedTrovesAddress,
        address _communityIssuanceAddress,
        address _dfrancParamsAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a MON issuance, based on time passed since the last issuance. The MON issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (MON, ETH) to depositor
     * - Sends the tagged front end's accumulated MON gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a MON issuance, based on time passed since the last issuance. The MON issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (MON, ETH) to depositor
     * - Sends the tagged front end's accumulated MON gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a MON issuance, based on time passed since the last issuance. The MON issuance is shared between *all* depositors and front ends
     * - Sends all depositor's MON gain to  depositor
     * - Sends all tagged front end's MON gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawAssetGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the DCHF contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debt, uint256 _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getAssetBalance() external view returns (uint256);

    /*
     * Returns DCHF held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalDCHFDeposits() external view returns (uint256);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorAssetGain(address _depositor) external view returns (uint256);

    /*
     * Calculate the MON gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorMONGain(address _depositor) external view returns (uint256);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedDCHFDeposit(address _depositor) external view returns (uint256);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedTotalStake() external view returns (uint256);

    function getNameBytes() external view returns (bytes32);

    function getAssetType() external view returns (address);

    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ETH received
     * receive() external payable;
     */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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