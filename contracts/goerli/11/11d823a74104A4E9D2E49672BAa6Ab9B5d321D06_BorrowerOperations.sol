// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ICdpManager.sol";
import "./Interfaces/IEBTCToken.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ISortedCdps.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/ReentrancyGuard.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/AuthNoOwner.sol";
import "./Dependencies/ERC3156FlashLender.sol";

contract BorrowerOperations is
    LiquityBase,
    ReentrancyGuard,
    IBorrowerOperations,
    ERC3156FlashLender
{
    string public constant NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ICdpManager public immutable cdpManager;

    ICollSurplusPool public immutable collSurplusPool;

    address public feeRecipientAddress;

    IEBTCToken public immutable ebtcToken;

    // A doubly linked list of Cdps, sorted by their collateral ratios
    ISortedCdps public immutable sortedCdps;

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

    struct LocalVariables_adjustCdp {
        uint price;
        uint collChange;
        uint netDebtChange;
        bool isCollIncrease;
        uint debt;
        uint coll;
        uint oldICR;
        uint newICR;
        uint newTCR;
        uint newDebt;
        uint newColl;
        uint stake;
    }

    struct LocalVariables_openCdp {
        uint price;
        uint debt;
        uint totalColl;
        uint netColl;
        uint ICR;
        uint NICR;
        uint stake;
        uint arrayIndex;
    }

    struct LocalVariables_moveTokens {
        address user;
        uint collChange;
        uint collAddUnderlying; // ONLY for isCollIncrease=true
        bool isCollIncrease;
        uint EBTCChange;
        bool isDebtIncrease;
        uint netDebtChange;
    }

    // --- Dependency setters ---
    constructor(
        address _cdpManagerAddress,
        address _activePoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedCdpsAddress,
        address _ebtcTokenAddress,
        address _feeRecipientAddress,
        address _collTokenAddress
    ) LiquityBase(_activePoolAddress, _priceFeedAddress, _collTokenAddress) {
        // We no longer checkContract() here, because the contracts we depend on may not yet be deployed.

        // This makes impossible to open a cdp with zero withdrawn EBTC
        // assert(MIN_NET_DEBT > 0);
        // TODO: Re-evaluate this

        cdpManager = ICdpManager(_cdpManagerAddress);
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        sortedCdps = ISortedCdps(_sortedCdpsAddress);
        ebtcToken = IEBTCToken(_ebtcTokenAddress);
        feeRecipientAddress = _feeRecipientAddress;

        address _authorityAddress = address(AuthNoOwner(_cdpManagerAddress).authority());
        if (_authorityAddress != address(0)) {
            _initializeAuthority(_authorityAddress);
        }

        emit CdpManagerAddressChanged(_cdpManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit SortedCdpsAddressChanged(_sortedCdpsAddress);
        emit EBTCTokenAddressChanged(_ebtcTokenAddress);
        emit FeeRecipientAddressChanged(_feeRecipientAddress);
        emit CollateralAddressChanged(_collTokenAddress);

        // No longer need a concept of ownership if there is no initializer
    }

    /**
        @notice BorrowerOperations and CdpManager share reentrancy status by confirming the other's locked flag before beginning operation
        @dev This is an alternative to the more heavyweight solution of both being able to set the reentrancy flag on a 3rd contract.
     */
    modifier nonReentrantSelfAndCdpM() {
        require(locked == OPEN, "BorrowerOperations: REENTRANCY");
        require(ReentrancyGuard(address(cdpManager)).locked() == OPEN, "CdpManager: REENTRANCY");

        locked = LOCKED;

        _;

        locked = OPEN;
    }

    // --- Borrower Cdp Operations ---

    /**
    @notice Function that creates a Cdp for the caller with the requested debt, and the stETH received as collateral.
    @notice Successful execution is conditional mainly on the resulting collateralization ratio which must exceed the minimum (110% in Normal Mode, 150% in Recovery Mode).
    @notice In addition to the requested debt, extra debt is issued to cover the gas compensation.
    */
    function openCdp(
        uint _EBTCAmount,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAmount
    ) external override nonReentrantSelfAndCdpM returns (bytes32) {
        return _openCdp(_EBTCAmount, _upperHint, _lowerHint, _collAmount, msg.sender);
    }

    // Function that adds the received stETH to the caller's specified Cdp.
    function addColl(
        bytes32 _cdpId,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAmount
    ) external override nonReentrantSelfAndCdpM {
        _adjustCdp(_cdpId, 0, 0, false, _upperHint, _lowerHint, _collAmount);
    }

    /**
    Withdraws `_collWithdrawal` amount of collateral from the caller’s Cdp. Executes only if the user has an active Cdp, the withdrawal would not pull the user’s Cdp below the minimum collateralization ratio, and the resulting total collateralization ratio of the system is above 150%.
    */
    function withdrawColl(
        bytes32 _cdpId,
        uint _collWithdrawal,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external override nonReentrantSelfAndCdpM {
        _adjustCdp(_cdpId, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw EBTC tokens from a cdp: mint new EBTC tokens to the owner, and increase the cdp's debt accordingly
    /**
    Issues `_amount` of eBTC from the caller’s Cdp to the caller. Executes only if the Cdp's collateralization ratio would remain above the minimum, and the resulting total collateralization ratio is above 150%.
     */
    function withdrawEBTC(
        bytes32 _cdpId,
        uint _EBTCAmount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external override nonReentrantSelfAndCdpM {
        _adjustCdp(_cdpId, 0, _EBTCAmount, true, _upperHint, _lowerHint, 0);
    }

    // Repay EBTC tokens to a Cdp: Burn the repaid EBTC tokens, and reduce the cdp's debt accordingly
    /**
    repay `_amount` of eBTC to the caller’s Cdp, subject to leaving 50 debt in the Cdp (which corresponds to the 50 eBTC gas compensation).
    */
    function repayEBTC(
        bytes32 _cdpId,
        uint _EBTCAmount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external override nonReentrantSelfAndCdpM {
        _adjustCdp(_cdpId, 0, _EBTCAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustCdp(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _EBTCChange,
        bool _isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external override nonReentrantSelfAndCdpM {
        _adjustCdp(_cdpId, _collWithdrawal, _EBTCChange, _isDebtIncrease, _upperHint, _lowerHint, 0);
    }

    /**
    enables a borrower to simultaneously change both their collateral and debt, subject to all the restrictions that apply to individual increases/decreases of each quantity with the following particularity: if the adjustment reduces the collateralization ratio of the Cdp, the function only executes if the resulting total collateralization ratio is above 150%. The borrower has to provide a `_maxFeePercentage` that he/she is willing to accept in case of a fee slippage, i.e. when a redemption transaction is processed first, driving up the issuance fee. The parameter is ignored if the debt is not increased with the transaction.
    */
    // TODO optimization candidate
    function adjustCdpWithColl(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _EBTCChange,
        bool _isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAddAmount
    ) external override nonReentrantSelfAndCdpM {
        _adjustCdp(
            _cdpId,
            _collWithdrawal,
            _EBTCChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint,
            _collAddAmount
        );
    }

    function _adjustCdp(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _EBTCChange,
        bool _isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAddAmount
    ) internal {
        _requireCdpOwner(_cdpId);
        _adjustCdpInternal(
            _cdpId,
            _collWithdrawal,
            _EBTCChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint,
            _collAddAmount
        );
    }

    /*
     * _adjustCdpInternal(): Alongside a debt change, this function can perform either
     * a collateral top-up or a collateral withdrawal.
     *
     * It therefore expects either a positive _collAddAmount, or a positive _collWithdrawal argument.
     *
     * If both are positive, it will revert.
     */
    function _adjustCdpInternal(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _EBTCChange,
        bool _isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAddAmount
    ) internal {
        LocalVariables_adjustCdp memory vars;

        _requireCdpisActive(cdpManager, _cdpId);

        vars.price = priceFeed.fetchPrice();

        // Reversed BTC/ETH price
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireNonZeroDebtChange(_EBTCChange);
        }
        _requireSingularCollChange(_collAddAmount, _collWithdrawal);
        _requireNonZeroAdjustment(_collAddAmount, _collWithdrawal, _EBTCChange);

        // Confirm the operation is either a borrower adjusting their own cdp
        address _borrower = sortedCdps.getOwnerAddress(_cdpId);
        assert(msg.sender == _borrower);

        cdpManager.applyPendingRewards(_cdpId);

        // Get the collChange based on the collateral value transferred in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(_collAddAmount, _collWithdrawal);

        vars.netDebtChange = _EBTCChange;

        vars.debt = cdpManager.getCdpDebt(_cdpId);
        vars.coll = cdpManager.getCdpColl(_cdpId);

        // Get the cdp's old ICR before the adjustment, and what its new ICR will be after the adjustment
        uint _cdpCollAmt = collateral.getPooledEthByShares(vars.coll);
        vars.oldICR = LiquityMath._computeCR(_cdpCollAmt, vars.debt, vars.price);
        vars.newICR = _getNewICRFromCdpChange(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease,
            vars.price
        );
        assert(_collWithdrawal <= _cdpCollAmt);

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars);

        // When the adjustment is a debt repayment, check it's a valid amount, that the caller has enough EBTC, and that the resulting debt is >0
        if (!_isDebtIncrease && _EBTCChange > 0) {
            _requireValidEBTCRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientEBTCBalance(ebtcToken, _borrower, vars.netDebtChange);
            _requireNonZeroDebt(vars.debt - vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateCdpFromAdjustment(
            cdpManager,
            _cdpId,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );

        // Only check when the collateral exchange rate from share is above 1e18
        // If there is big decrease due to slashing, some CDP might already fall below minimum collateral requirements
        if (collateral.getPooledEthByShares(1e18) >= 1e18) {
            _requireAtLeastMinNetColl(collateral.getPooledEthByShares(vars.newColl));
        }

        vars.stake = cdpManager.updateStakeAndTotalStakes(_cdpId);

        // Re-insert cdp in to the sorted list
        {
            uint newNICR = _getNewNominalICRFromCdpChange(vars, _isDebtIncrease);
            sortedCdps.reInsert(_cdpId, newNICR, _upperHint, _lowerHint);
        }

        emit CdpUpdated(
            _cdpId,
            _borrower,
            vars.debt,
            vars.coll,
            vars.newDebt,
            vars.newColl,
            vars.stake,
            BorrowerOperation.adjustCdp
        );

        // Use the unmodified _EBTCChange here, as we don't send the fee to the user
        {
            LocalVariables_moveTokens memory _varMvTokens = LocalVariables_moveTokens(
                msg.sender,
                vars.collChange,
                (vars.isCollIncrease ? _collAddAmount : 0),
                vars.isCollIncrease,
                _EBTCChange,
                _isDebtIncrease,
                vars.netDebtChange
            );
            _processTokenMovesFromAdjustment(_varMvTokens);
        }
    }

    function _openCdp(
        uint _EBTCAmount,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAmount,
        address _borrower
    ) internal returns (bytes32) {
        require(_collAmount > 0, "BorrowerOps: collateral for CDP is zero");
        _requireNonZeroDebt(_EBTCAmount);

        LocalVariables_openCdp memory vars;

        // ICR is based on the net coll, i.e. the requested coll amount - fixed liquidator incentive gas comp.
        vars.netColl = _getNetColl(_collAmount);

        _requireAtLeastMinNetColl(vars.netColl);

        vars.price = priceFeed.fetchPrice();

        // Reverse ETH/BTC price to BTC/ETH
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        vars.debt = _EBTCAmount;

        // Sanity check
        assert(vars.netColl > 0);

        uint _netCollAsShares = collateral.getSharesByPooledEth(vars.netColl);
        uint _liquidatorRewardShares = collateral.getSharesByPooledEth(LIQUIDATOR_REWARD);

        // ICR is based on the net coll, i.e. the requested coll amount - fixed liquidator incentive gas comp.
        vars.ICR = LiquityMath._computeCR(vars.netColl, vars.debt, vars.price);

        // NICR uses shares to normalize NICR across CDPs opened at different pooled ETH / shares ratios
        vars.NICR = LiquityMath._computeNominalCR(_netCollAsShares, vars.debt);

        /**
            In recovery move, ICR must be greater than CCR
            CCR > MCR (125% vs 110%)

            In normal mode, ICR must be greater thatn MCR
            Additionally, the new system TCR after the CDPs addition must be >CCR
        */
        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint newTCR = _getNewTCRFromCdpChange(vars.netColl, true, vars.debt, true, vars.price); // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR);
        }

        // Set the cdp struct's properties
        bytes32 _cdpId = sortedCdps.insert(_borrower, vars.NICR, _upperHint, _lowerHint);

        cdpManager.setCdpStatus(_cdpId, 1);
        cdpManager.increaseCdpColl(_cdpId, _netCollAsShares); // Collateral is stored in shares form for normalization
        cdpManager.increaseCdpDebt(_cdpId, vars.debt);
        cdpManager.setCdpLiquidatorRewardShares(_cdpId, _liquidatorRewardShares);

        cdpManager.updateCdpRewardSnapshots(_cdpId);
        vars.stake = cdpManager.updateStakeAndTotalStakes(_cdpId);

        vars.arrayIndex = cdpManager.addCdpIdToArray(_cdpId);
        emit CdpCreated(_cdpId, _borrower, msg.sender, vars.arrayIndex);

        // Mint the full EBTCAmount to the borrower
        _withdrawEBTC(_borrower, _EBTCAmount, _EBTCAmount);

        /**
            Note that only NET coll (as shares) is considered part of the CDP.
            The static liqudiation incentive is stored in the gas pool and can be considered a deposit / voucher to be returned upon CDP close, to the closer.
            The close can happen from the borrower closing their own CDP, a full liquidation, or a redemption.
        */
        emit CdpUpdated(
            _cdpId,
            _borrower,
            0,
            0,
            vars.debt,
            _netCollAsShares,
            vars.stake,
            BorrowerOperation.openCdp
        );

        // CEI: Move the net collateral and liquidator gas compensation to the Active Pool. Track only net collateral shares for TCR purposes.
        _activePoolAddColl(_collAmount, _netCollAsShares, _liquidatorRewardShares);

        assert(vars.netColl + LIQUIDATOR_REWARD == _collAmount); // Invariant Assertion

        return _cdpId;
    }

    /**
    allows a borrower to repay all debt, withdraw all their collateral, and close their Cdp. Requires the borrower have a eBTC balance sufficient to repay their cdp's debt, excluding gas compensation - i.e. `(debt - 50)` eBTC.
    */
    function closeCdp(bytes32 _cdpId) external override {
        _requireCdpOwner(_cdpId);

        _requireCdpisActive(cdpManager, _cdpId);
        uint price = priceFeed.fetchPrice();
        _requireNotInRecoveryMode(price);

        cdpManager.applyPendingRewards(_cdpId);

        uint coll = cdpManager.getCdpColl(_cdpId);
        uint debt = cdpManager.getCdpDebt(_cdpId);
        uint liquidatorRewardShares = cdpManager.getCdpLiquidatorRewardShares(_cdpId);

        _requireSufficientEBTCBalance(ebtcToken, msg.sender, debt);

        uint newTCR = _getNewTCRFromCdpChange(
            collateral.getPooledEthByShares(coll),
            false,
            debt,
            false,
            price
        );
        _requireNewTCRisAboveCCR(newTCR);

        cdpManager.removeStake(_cdpId);
        cdpManager.closeCdp(_cdpId);

        // We already verified msg.sender is the borrower
        emit CdpUpdated(_cdpId, msg.sender, debt, coll, 0, 0, 0, BorrowerOperation.closeCdp);

        // Burn the repaid EBTC from the user's balance
        _repayEBTC(msg.sender, debt);

        // CEI: Send the collateral and liquidator reward shares back to the user
        activePool.sendStEthCollAndLiquidatorReward(msg.sender, coll, liquidatorRewardShares);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode

      when a borrower’s Cdp has been fully redeemed from and closed, or liquidated in Recovery Mode with a collateralization ratio above 110%, this function allows the borrower to claim their stETH collateral surplus that remains in the system (collateral - debt upon redemption; collateral - 110% of the debt upon liquidation).
     */
    function claimCollateral() external override {
        // send ETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _getUSDValue(uint _coll, uint _price) internal pure returns (uint) {
        uint usdValue = (_price * _coll) / DECIMAL_PRECISION;

        return usdValue;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    ) internal view returns (uint collChange, bool isCollIncrease) {
        if (_collReceived != 0) {
            collChange = collateral.getSharesByPooledEth(_collReceived);
            isCollIncrease = true;
        } else {
            collChange = collateral.getSharesByPooledEth(_requestedCollWithdrawal);
        }
    }

    // Update cdp's coll and debt based on whether they increase or decrease
    function _updateCdpFromAdjustment(
        ICdpManager _cdpManager,
        bytes32 _cdpId,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    ) internal returns (uint, uint) {
        uint newColl = (_isCollIncrease)
            ? _cdpManager.increaseCdpColl(_cdpId, _collChange)
            : _cdpManager.decreaseCdpColl(_cdpId, _collChange);
        uint newDebt = (_isDebtIncrease)
            ? _cdpManager.increaseCdpDebt(_cdpId, _debtChange)
            : _cdpManager.decreaseCdpDebt(_cdpId, _debtChange);

        return (newColl, newDebt);
    }

    /**
        @notice Process the token movements required by a CDP adjustment.
        @notice Handles the cases of a debt increase / decrease, and/or a collateral increase / decrease.
     */
    function _processTokenMovesFromAdjustment(
        LocalVariables_moveTokens memory _varMvTokens
    ) internal {
        // Debt increase: mint change value of new eBTC to user, increment ActivePool eBTC internal accounting
        if (_varMvTokens.isDebtIncrease) {
            _withdrawEBTC(_varMvTokens.user, _varMvTokens.EBTCChange, _varMvTokens.netDebtChange);
        } else {
            // Debt decrease: burn change value of eBTC from user, decrement ActivePool eBTC internal accounting
            _repayEBTC(_varMvTokens.user, _varMvTokens.EBTCChange);
        }

        if (_varMvTokens.isCollIncrease) {
            // Coll increase: send change value of stETH to Active Pool, increment ActivePool stETH internal accounting
            _activePoolAddColl(_varMvTokens.collAddUnderlying, _varMvTokens.collChange, 0);
        } else {
            // Coll decrease: send change value of stETH to user, decrement ActivePool stETH internal accounting
            activePool.sendStEthColl(_varMvTokens.user, _varMvTokens.collChange);
        }
    }

    /// @notice Send stETH to Active Pool and increase its recorded ETH balance
    /// @dev Liquidator reward shares are not considered as part of the system for CR purposes.
    /// @dev These number of liquidator shares associated with each CDP are stored in the CDP, while the actual tokens float in the active pool
    function _activePoolAddColl(
        uint _amount,
        uint _sharesToTrack,
        uint _liquidatorRewardShares
    ) internal {
        // NOTE: No need for safe transfer if the collateral asset is standard. Make sure this is the case!
        collateral.transferFrom(msg.sender, address(activePool), _amount);
        activePool.receiveColl(_sharesToTrack);
    }

    // Issue the specified amount of EBTC to _account and increases
    // the total active debt
    function _withdrawEBTC(address _account, uint _EBTCAmount, uint _netDebtIncrease) internal {
        activePool.increaseEBTCDebt(_netDebtIncrease);
        ebtcToken.mint(_account, _EBTCAmount);
    }

    // Burn the specified amount of EBTC from _account and decreases the total active debt
    function _repayEBTC(address _account, uint _EBTC) internal {
        activePool.decreaseEBTCDebt(_EBTC);
        ebtcToken.burn(_account, _EBTC);
    }

    // --- 'Require' wrapper functions ---

    function _requireCdpOwner(bytes32 _cdpId) internal view {
        address _owner = sortedCdps.existCdpOwners(_cdpId);
        require(msg.sender == _owner, "BorrowerOps: Caller must be cdp owner");
    }

    function _requireSingularCollChange(uint _collAdd, uint _collWithdrawal) internal pure {
        require(
            _collAdd == 0 || _collWithdrawal == 0,
            "BorrowerOperations: Cannot withdraw and add coll"
        );
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(
            msg.sender == _borrower,
            "BorrowerOps: Caller must be the borrower for a withdrawal"
        );
    }

    function _requireNonZeroAdjustment(
        uint _collAddAmount,
        uint _EBTCChange,
        uint _collWithdrawal
    ) internal pure {
        require(
            _collAddAmount != 0 || _collWithdrawal != 0 || _EBTCChange != 0,
            "BorrowerOps: There must be either a collateral change or a debt change"
        );
    }

    function _requireCdpisActive(ICdpManager _cdpManager, bytes32 _cdpId) internal view {
        uint status = _cdpManager.getCdpStatus(_cdpId);
        require(status == 1, "BorrowerOps: Cdp does not exist or is closed");
    }

    //    function _requireCdpisNotActive(ICdpManager _cdpManager, address _borrower) internal view {
    //        uint status = _cdpManager.getCdpStatus(_borrower);
    //        require(status != 1, "BorrowerOps: Cdp is active");
    //    }

    function _requireNonZeroDebtChange(uint _EBTCChange) internal pure {
        require(_EBTCChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }

    function _requireNotInRecoveryMode(uint _price) internal view {
        require(
            !_checkRecoveryMode(_price),
            "BorrowerOps: Operation not permitted during Recovery Mode"
        );
    }

    function _requireNoCollWithdrawal(uint _collWithdrawal) internal pure {
        require(
            _collWithdrawal == 0,
            "BorrowerOps: Collateral withdrawal not permitted Recovery Mode"
        );
    }

    function _requireValidAdjustmentInCurrentMode(
        bool _isRecoveryMode,
        uint _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustCdp memory _vars
    ) internal view {
        /*
         *In Recovery Mode, only allow:
         *
         * - Pure collateral top-up
         * - Pure debt repayment
         * - Collateral top-up with debt repayment
         * - A debt increase combined with a collateral top-up which makes the
         * ICR >= 150% and improves the ICR (and by extension improves the TCR).
         *
         * In Normal Mode, ensure:
         *
         * - The new ICR is above MCR
         * - The adjustment won't pull the TCR below CCR
         */
        if (_isRecoveryMode) {
            _requireNoCollWithdrawal(_collWithdrawal);
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_vars.newICR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }
        } else {
            // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromCdpChange(
                collateral.getPooledEthByShares(_vars.collChange),
                _vars.isCollIncrease,
                _vars.netDebtChange,
                _isDebtIncrease,
                _vars.price
            );
            _requireNewTCRisAboveCCR(_vars.newTCR);
        }
    }

    function _requireICRisAboveMCR(uint _newICR) internal pure {
        require(
            _newICR >= MCR,
            "BorrowerOps: An operation that would result in ICR < MCR is not permitted"
        );
    }

    function _requireICRisAboveCCR(uint _newICR) internal pure {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave cdp with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint _newICR, uint _oldICR) internal pure {
        require(_newICR >= _oldICR, "BorrowerOps: Cannot decrease your Cdp's ICR in Recovery Mode");
    }

    function _requireNewTCRisAboveCCR(uint _newTCR) internal pure {
        require(
            _newTCR >= CCR,
            "BorrowerOps: An operation that would result in TCR < CCR is not permitted"
        );
    }

    function _requireNonZeroDebt(uint _debt) internal pure {
        require(_debt > 0, "BorrowerOps: Debt must be non-zero");
    }

    function _requireAtLeastMinNetColl(uint _coll) internal pure {
        require(_coll >= MIN_NET_COLL, "BorrowerOps: Cdp's net coll must be greater than minimum");
    }

    function _requireValidEBTCRepayment(uint _currentDebt, uint _debtRepayment) internal pure {
        require(
            _debtRepayment <= _currentDebt,
            "BorrowerOps: Amount repaid must not be larger than the Cdp's debt"
        );
    }

    function _requireSufficientEBTCBalance(
        IEBTCToken _ebtcToken,
        address _borrower,
        uint _debtRepayment
    ) internal view {
        require(
            _ebtcToken.balanceOf(_borrower) >= _debtRepayment,
            "BorrowerOps: Caller doesnt have enough EBTC to make repayment"
        );
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromCdpChange(
        LocalVariables_adjustCdp memory vars,
        bool _isDebtIncrease
    ) internal pure returns (uint) {
        (uint newColl, uint newDebt) = _getNewCdpAmounts(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );

        uint newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromCdpChange(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    ) internal view returns (uint) {
        (uint newColl, uint newDebt) = _getNewCdpAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

        uint newICR = LiquityMath._computeCR(
            collateral.getPooledEthByShares(newColl),
            newDebt,
            _price
        );
        return newICR;
    }

    function _getNewCdpAmounts(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint, uint) {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll + _collChange : _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }

    function _getNewTCRFromCdpChange(
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    ) internal view returns (uint) {
        uint _shareColl = getEntireSystemColl();
        uint totalColl = collateral.getPooledEthByShares(_shareColl);
        uint totalDebt = _getEntireSystemDebt();

        totalColl = _isCollIncrease ? totalColl + _collChange : totalColl - _collChange;
        totalDebt = _isDebtIncrease ? totalDebt + _debtChange : totalDebt - _debtChange;

        uint newTCR = LiquityMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    // === Governed Functions ==

    function setFeeRecipientAddress(address _feeRecipientAddress) external requiresAuth {
        require(
            _feeRecipientAddress != address(0),
            "BorrowerOperations: cannot set fee recipient to zero address"
        );
        feeRecipientAddress = _feeRecipientAddress;
        emit FeeRecipientAddressChanged(_feeRecipientAddress);
    }

    // === Flash Loans === //
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(amount > 0, "BorrowerOperations: 0 Amount");
        require(token == address(ebtcToken), "BorrowerOperations: EBTC Only");
        require(amount <= maxFlashLoan(token), "BorrowerOperations: Too much");
        // NOTE: Check for `eBTCToken` is implicit in the two requires above

        uint256 fee = (amount * feeBps) / MAX_BPS;

        // Issue EBTC
        ebtcToken.mint(address(receiver), amount);

        // Callback
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == FLASH_SUCCESS_VALUE,
            "BorrowerOperations: IERC3156: Callback failed"
        );

        // Gas: Repay from user balance, so we don't trigger a new SSTORE
        // Safe to use transferFrom and unchecked as it's a standard token
        // Also saves gas
        // Send both fee and amount to FEE_RECIPIENT, to burn allowance per EIP-3156
        ebtcToken.transferFrom(address(receiver), feeRecipientAddress, fee + amount);

        // Burn amount, from FEE_RECIPIENT
        ebtcToken.burn(feeRecipientAddress, amount);

        emit FlashLoanSuccess(address(receiver), token, amount, fee);

        return true;
    }

    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        require(token == address(ebtcToken), "BorrowerOperations: EBTC Only");

        return (amount * feeBps) / MAX_BPS;
    }

    /// @dev Max flashloan, exclusively in ETH equals to the current balance
    function maxFlashLoan(address token) public view override returns (uint256) {
        if (token != address(ebtcToken)) {
            return 0;
        }
        return type(uint112).max;
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

/**
 * Check that the account is an already deployed non-destroyed contract.
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
 */

contract CheckContract {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
    function checkContract(address account) internal view {
        require(account != address(0), "Account cannot be zero address");
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        require(account.code.length > 0, "Account code size cannot be zero");
    }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../Interfaces/IERC3156FlashLender.sol";
import "../Interfaces/IWETH.sol";
import "./AuthNoOwner.sol";

abstract contract ERC3156FlashLender is IERC3156FlashLender, AuthNoOwner {
    // TODO: Fix / Finalize
    uint256 public constant MAX_BPS = 10_000;

    uint256 public feeBps = 50; // 50 BPS
    uint256 public maxFeeBps = 1_000; // 10%

    bytes32 public constant FLASH_SUCCESS_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    function setFeeBps(uint _newFee) external requiresAuth {
        require(_newFee <= maxFeeBps, "ERC3156FlashLender: _newFee should <= maxFeeBps");

        // set new flash fee
        uint _oldFee = feeBps;
        feeBps = _newFee;
        emit FlashFeeSet(msg.sender, _oldFee, _newFee);
    }

    function setMaxFeeBps(uint _newMaxFlashFee) external requiresAuth {
        require(_newMaxFlashFee <= MAX_BPS, "ERC3156FlashLender: _newMaxFlashFee should <= 10000");

        // set new max flash fee
        uint _oldMaxFlashFee = maxFeeBps;
        maxFeeBps = _newMaxFlashFee;
        emit MaxFlashFeeSet(msg.sender, _oldMaxFlashFee, _newMaxFlashFee);
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

// Common interface for the Cdp Manager.
interface IBorrowerOperations {
    // --- Events ---

    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event SortedCdpsAddressChanged(address _sortedCdpsAddress);
    event EBTCTokenAddressChanged(address _ebtcTokenAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollateralAddressChanged(address _collTokenAddress);
    event FlashLoanSuccess(address _receiver, address _token, uint _amount, uint _fee);

    event CdpCreated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        address indexed _creator,
        uint arrayIndex
    );
    event CdpUpdated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _oldDebt,
        uint _oldColl,
        uint _debt,
        uint _coll,
        uint _stake,
        BorrowerOperation _operation
    );

    enum BorrowerOperation {
        openCdp,
        closeCdp,
        adjustCdp
    }

    // --- Functions ---

    function openCdp(
        uint _EBTCAmount,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAmount
    ) external returns (bytes32);

    function addColl(
        bytes32 _cdpId,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAmount
    ) external;

    function withdrawColl(
        bytes32 _cdpId,
        uint _amount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function withdrawEBTC(
        bytes32 _cdpId,
        uint _amount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function repayEBTC(
        bytes32 _cdpId,
        uint _amount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function closeCdp(bytes32 _cdpId) external;

    function adjustCdp(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _debtChange,
        bool isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function adjustCdpWithColl(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _debtChange,
        bool isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAddAmount
    ) external;

    function claimCollateral() external;

    function feeRecipientAddress() external view returns (address);
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

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    event FlashFeeSet(address _setter, uint _oldFee, uint _newFee);
    event MaxFlashFeeSet(address _setter, uint _oldMaxFee, uint _newMaxFee);

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}