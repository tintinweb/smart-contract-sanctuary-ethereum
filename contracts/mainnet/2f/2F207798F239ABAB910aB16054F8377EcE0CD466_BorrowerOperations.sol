// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IARTHValuecoin.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";

contract BorrowerOperations is LiquityBase, Ownable, CheckContract, IBorrowerOperations {
    using SafeMath for uint256;
    string public constant NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ITroveManager public troveManager;

    address stabilityPoolAddress;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    IARTHValuecoin public arthToken;

    // A doubly linked list of Troves, sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

    struct LocalVariables_adjustTrove {
        uint256 price;
        uint256 collChange;
        uint256 netDebtChange;
        bool isCollIncrease;
        uint256 debt;
        uint256 coll;
        uint256 oldICR;
        uint256 newICR;
        uint256 newTCR;
        uint256 ARTHFee;
        uint256 newDebt;
        uint256 newColl;
        uint256 stake;
    }

    struct LocalVariables_openTrove {
        uint256 price;
        uint256 ARTHFee;
        uint256 netDebt;
        uint256 compositeDebt;
        uint256 ICR;
        uint256 NICR;
        uint256 stake;
        uint256 arrayIndex;
    }

    struct ContractsCache {
        ITroveManager troveManager;
        IActivePool activePool;
        IARTHValuecoin arthToken;
    }

    mapping(address => bool) public frontEnds;

    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _governanceAddress,
        address _sortedTrovesAddress,
        address _arthTokenAddress
    ) external override onlyOwner {
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_governanceAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_arthTokenAddress);

        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        governance = IGovernance(_governanceAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        arthToken = IARTHValuecoin(_arthTokenAddress);

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit GovernanceAddressChanged(_governanceAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit ARTHTokenAddressChanged(_arthTokenAddress);

        // This makes impossible to open a trove with zero withdrawn ARTH
        assert(MIN_NET_DEBT() > 0);

        _renounceOwnership(); // renounce ownership after migration is done (openTroveFor)
    }

    // --- Borrower Trove Operations ---

    function registerFrontEnd() external override {
        _requireFrontEndNotRegistered(msg.sender);
        _requireTroveisNotActive(troveManager, msg.sender);
        frontEnds[msg.sender] = true;
        emit FrontEndRegistered(msg.sender, block.timestamp);
    }

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint
    ) external payable override {
        _openTrove(
            msg.sender,
            msg.sender,
            _maxFeePercentage,
            _ARTHAmount,
            _upperHint,
            _lowerHint,
            address(0)
        );
    }

    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint,
        address _frontEndTag
    ) external payable override {
        _openTrove(
            msg.sender,
            msg.sender,
            _maxFeePercentage,
            _ARTHAmount,
            _upperHint,
            _lowerHint,
            _frontEndTag
        );
    }

    function openTroveFor(
        address _who,
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint,
        address _frontEndTag
    ) external payable onlyOwner {
        _openTrove(
            _who,
            msg.sender,
            _maxFeePercentage,
            _ARTHAmount,
            _upperHint,
            _lowerHint,
            _frontEndTag
        );
    }

    function _openTrove(
        address _who,
        address _arthRecipeint,
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint,
        address _frontEndTag
    ) internal {
        _requireFrontEndIsRegisteredOrZero(_frontEndTag);
        _requireFrontEndNotRegistered(_who);

        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, arthToken);
        LocalVariables_openTrove memory vars;

        vars.price = getPriceFeed().fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireTroveisNotActive(contractsCache.troveManager, _who);

        vars.ARTHFee;
        vars.netDebt = _ARTHAmount;

        if (!isRecoveryMode) {
            vars.ARTHFee = _triggerBorrowingFee(
                contractsCache.troveManager,
                contractsCache.arthToken,
                _ARTHAmount,
                _maxFeePercentage,
                _frontEndTag
            );
            vars.netDebt = vars.netDebt.add(vars.ARTHFee);
        }
        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested ARTH amount + ARTH borrowing fee + ARTH gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);

        vars.ICR = LiquityMath._computeCR(msg.value, vars.compositeDebt, vars.price);
        vars.NICR = LiquityMath._computeNominalCR(msg.value, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint256 newTCR = _getNewTCRFromTroveChange(
                msg.value,
                true,
                vars.compositeDebt,
                true,
                vars.price
            ); // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR);
        }

        // Set the trove struct's properties
        contractsCache.troveManager.setTroveFrontEndTag(_who, _frontEndTag);
        contractsCache.troveManager.setTroveStatus(_who, 1);
        contractsCache.troveManager.increaseTroveColl(_who, msg.value);
        contractsCache.troveManager.increaseTroveDebt(_who, vars.compositeDebt);

        contractsCache.troveManager.updateTroveRewardSnapshots(_who);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_who);

        sortedTroves.insert(_who, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager.addTroveOwnerToArray(_who);
        emit TroveCreated(_who, vars.arrayIndex);

        // Move the ether to the Active Pool, and mint the ARTHAmount to the borrower
        _activePoolAddColl(contractsCache.activePool, msg.value);
        _withdrawARTH(
            contractsCache.activePool,
            contractsCache.arthToken,
            _arthRecipeint,
            _ARTHAmount,
            vars.netDebt
        );
        // Move the ARTH gas compensation to the Gas Pool
        _withdrawARTH(
            contractsCache.activePool,
            contractsCache.arthToken,
            gasPoolAddress,
            ARTH_GAS_COMPENSATION(),
            ARTH_GAS_COMPENSATION()
        );

        emit TroveUpdated(
            _who,
            vars.compositeDebt,
            msg.value,
            vars.stake,
            BorrowerOperation.openTrove
        );
        emit ARTHBorrowingFeePaid(_who, vars.ARTHFee);
    }

    // Send ETH as collateral to a trove
    function addColl(address _upperHint, address _lowerHint) external payable override {
        _adjustTrove(msg.sender, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Send ETH as collateral to a trove. Called by only the Stability Pool.
    function moveETHGainToTrove(
        address _borrower,
        address _upperHint,
        address _lowerHint
    ) external payable override {
        _requireCallerIsStabilityPool();
        _adjustTrove(_borrower, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ETH collateral from a trove
    function withdrawColl(
        uint256 _collWithdrawal,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustTrove(msg.sender, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ARTH tokens from a trove: mint new ARTH tokens to the owner, and increase the trove's debt accordingly
    function withdrawARTH(
        uint256 _maxFeePercentage,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustTrove(msg.sender, 0, _ARTHAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay ARTH tokens to a Trove: Burn the repaid ARTH tokens, and reduce the trove's debt accordingly
    function repayARTH(
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustTrove(msg.sender, 0, _ARTHAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustTrove(
        uint256 _maxFeePercentage,
        uint256 _collWithdrawal,
        uint256 _ARTHChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable override {
        _adjustTrove(
            msg.sender,
            _collWithdrawal,
            _ARTHChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint,
            _maxFeePercentage
        );
    }

    /*
     * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal.
     *
     * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
     *
     * If both are positive, it will revert.
     */
    function _adjustTrove(
        address _borrower,
        uint256 _collWithdrawal,
        uint256 _ARTHChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) internal {
        ContractsCache memory contractsCache = ContractsCache(troveManager, activePool, arthToken);
        LocalVariables_adjustTrove memory vars;

        vars.price = getPriceFeed().fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_ARTHChange);
        }
        _requireSingularCollChange(_collWithdrawal);
        _requireNonZeroAdjustment(_collWithdrawal, _ARTHChange);
        _requireTroveisActive(contractsCache.troveManager, _borrower);

        // Confirm the operation is either a borrower adjusting their own trove, or a pure ETH transfer from the Stability Pool to a trove
        assert(
            msg.sender == _borrower ||
                (msg.sender == stabilityPoolAddress && msg.value > 0 && _ARTHChange == 0)
        );

        contractsCache.troveManager.applyPendingRewards(_borrower);

        // Get the collChange based on whether or not ETH was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(msg.value, _collWithdrawal);

        vars.netDebtChange = _ARTHChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) {
            address frontEndTag = contractsCache.troveManager.getTroveFrontEnd(_borrower);
            vars.ARTHFee = _triggerBorrowingFee(
                contractsCache.troveManager,
                contractsCache.arthToken,
                _ARTHChange,
                _maxFeePercentage,
                frontEndTag
            );
            vars.netDebtChange = vars.netDebtChange.add(vars.ARTHFee); // The raw debt change includes the fee
        }

        vars.debt = contractsCache.troveManager.getTroveDebt(_borrower);
        vars.coll = contractsCache.troveManager.getTroveColl(_borrower);

        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromTroveChange(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease,
            vars.price
        );
        assert(_collWithdrawal <= vars.coll);

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars);

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough ARTH
        if (!_isDebtIncrease && _ARTHChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt).sub(vars.netDebtChange));
            _requireValidARTHRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientARTHBalance(contractsCache.arthToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateTroveFromAdjustment(
            contractsCache.troveManager,
            _borrower,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_borrower);

        // Re-insert trove in to the sorted list
        uint256 newNICR = _getNewNominalICRFromTroveChange(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );
        sortedTroves.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        emit TroveUpdated(
            _borrower,
            vars.newDebt,
            vars.newColl,
            vars.stake,
            BorrowerOperation.adjustTrove
        );
        emit ARTHBorrowingFeePaid(msg.sender, vars.ARTHFee);

        // Use the unmodified _ARTHChange here, as we don't send the fee to the user
        _moveTokensAndETHfromAdjustment(
            contractsCache.activePool,
            contractsCache.arthToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _ARTHChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeTrove() external override {
        ITroveManager troveManagerCached = troveManager;
        IActivePool activePoolCached = activePool;
        IARTHValuecoin arthTokenCached = arthToken;

        _requireTroveisActive(troveManagerCached, msg.sender);
        uint256 price = getPriceFeed().fetchPrice();
        _requireNotInRecoveryMode(price);

        troveManagerCached.applyPendingRewards(msg.sender);

        uint256 coll = troveManagerCached.getTroveColl(msg.sender);
        uint256 debt = troveManagerCached.getTroveDebt(msg.sender);

        _requireSufficientARTHBalance(
            arthTokenCached,
            msg.sender,
            debt.sub(ARTH_GAS_COMPENSATION())
        );

        uint256 newTCR = _getNewTCRFromTroveChange(coll, false, debt, false, price);
        _requireNewTCRisAboveCCR(newTCR);

        troveManagerCached.removeStake(msg.sender);
        troveManagerCached.closeTrove(msg.sender);

        emit TroveUpdated(msg.sender, 0, 0, 0, BorrowerOperation.closeTrove);

        // Burn the repaid ARTH from the user's balance and the gas compensation from the Gas Pool
        _repayARTH(activePoolCached, arthTokenCached, msg.sender, debt.sub(ARTH_GAS_COMPENSATION()));
        _repayARTH(activePoolCached, arthTokenCached, gasPoolAddress, ARTH_GAS_COMPENSATION());

        // Send the collateral back to the user
        activePoolCached.sendETH(msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral() external override {
        // send ETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(
        ITroveManager _troveManager,
        IARTHValuecoin _arthToken,
        uint256 _ARTHAmount,
        uint256 _maxFeePercentage,
        address _frontEndTag
    ) internal returns (uint256) {
        _troveManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint256 ARTHFee = _troveManager.getBorrowingFee(_ARTHAmount);

        _requireUserAcceptsFee(ARTHFee, _ARTHAmount, _maxFeePercentage);

        if (ARTHFee > 0) {
            uint256 feeForEcosystemFund = ARTHFee;

            // give 50% to ecosystem and frontend
            if (_frontEndTag != address(0)) {
                feeForEcosystemFund = ARTHFee.mul(50).div(100);
                uint256 _fee = ARTHFee.sub(feeForEcosystemFund);
                emit PaidARTHBorrowingFeeToFrontEnd(_frontEndTag, _fee);
                _arthToken.mint(_frontEndTag, _fee);
            }

            _sendFeeToEcosystemFund(_arthToken, feeForEcosystemFund);
        }

        return ARTHFee;
    }

    function _sendFeeToEcosystemFund(IARTHValuecoin _arthToken, uint256 _ARTHFee) internal {
        address ecosystemFund = governance.getFund();
        _arthToken.mint(ecosystemFund, _ARTHFee);
        emit PaidARTHBorrowingFeeToEcosystemFund(ecosystemFund, _ARTHFee);
    }

    function _getUSDValue(uint256 _coll, uint256 _price) internal pure returns (uint256) {
        uint256 usdValue = _price.mul(_coll).div(DECIMAL_PRECISION);

        return usdValue;
    }

    function _getCollChange(uint256 _collReceived, uint256 _requestedCollWithdrawal)
        internal
        pure
        returns (uint256 collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment(
        ITroveManager _troveManager,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal returns (uint256, uint256) {
        uint256 newColl = (_isCollIncrease)
            ? _troveManager.increaseTroveColl(_borrower, _collChange)
            : _troveManager.decreaseTroveColl(_borrower, _collChange);
        uint256 newDebt = (_isDebtIncrease)
            ? _troveManager.increaseTroveDebt(_borrower, _debtChange)
            : _troveManager.decreaseTroveDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndETHfromAdjustment(
        IActivePool _activePool,
        IARTHValuecoin _arthToken,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _ARTHChange,
        bool _isDebtIncrease,
        uint256 _netDebtChange
    ) internal {
        if (_isDebtIncrease) {
            _withdrawARTH(_activePool, _arthToken, _borrower, _ARTHChange, _netDebtChange);
        } else {
            _repayARTH(_activePool, _arthToken, _borrower, _ARTHChange);
        }

        if (_isCollIncrease) {
            _activePoolAddColl(_activePool, _collChange);
        } else {
            _activePool.sendETH(_borrower, _collChange);
        }
    }

    // Send ETH to Active Pool and increase its recorded ETH balance
    function _activePoolAddColl(IActivePool _activePool, uint256 _amount) internal {
        (bool success, ) = address(_activePool).call{value: _amount}("");
        require(success, "BorrowerOps: Sending ETH to ActivePool failed");
    }

    // Issue the specified amount of ARTH to _account and increases the total active debt (_netDebtIncrease potentially includes a ARTHFee)
    function _withdrawARTH(
        IActivePool _activePool,
        IARTHValuecoin _arthToken,
        address _account,
        uint256 _ARTHAmount,
        uint256 _netDebtIncrease
    ) internal {
        require(
            _activePool.getARTHDebt() + _ARTHAmount <= governance.getMaxDebtCeiling(),
            "mint > max debt"
        );
        require(governance.getAllowMinting(), "!minting");
        _activePool.increaseARTHDebt(_netDebtIncrease);
        _arthToken.mint(_account, _ARTHAmount);
    }

    // Burn the specified amount of ARTH from _account and decreases the total active debt
    function _repayARTH(
        IActivePool _activePool,
        IARTHValuecoin _arthToken,
        address _account,
        uint256 _ARTH
    ) internal {
        _activePool.decreaseARTHDebt(_ARTH);
        _arthToken.burn(_account, _ARTH);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint256 _collWithdrawal) internal view {
        require(
            msg.value == 0 || _collWithdrawal == 0,
            "BorrowerOperations: Cannot withdraw and add coll"
        );
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(
            msg.sender == _borrower,
            "BorrowerOps: Caller must be the borrower for a withdrawal"
        );
    }

    function _requireNonZeroAdjustment(uint256 _collWithdrawal, uint256 _ARTHChange) internal view {
        require(
            msg.value != 0 || _collWithdrawal != 0 || _ARTHChange != 0,
            "BorrowerOps: There must be either a collateral change or a debt change"
        );
    }

    function _requireTroveisActive(ITroveManager _troveManager, address _borrower) internal view {
        uint256 status = _troveManager.getTroveStatus(_borrower);
        require(status == 1, "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(ITroveManager _troveManager, address _borrower) internal view {
        uint256 status = _troveManager.getTroveStatus(_borrower);
        require(status != 1, "BorrowerOps: Trove is active");
    }

    function _requireNonZeroDebtChange(uint256 _ARTHChange) internal pure {
        require(_ARTHChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }

    function _requireNotInRecoveryMode(uint256 _price) internal view {
        require(
            !_checkRecoveryMode(_price),
            "BorrowerOps: Operation not permitted during Recovery Mode"
        );
    }

    function _requireNoCollWithdrawal(uint256 _collWithdrawal) internal pure {
        require(
            _collWithdrawal == 0,
            "BorrowerOps: Collateral withdrawal not permitted Recovery Mode"
        );
    }

    function _requireValidAdjustmentInCurrentMode(
        bool _isRecoveryMode,
        uint256 _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustTrove memory _vars
    ) internal view {
        /*
         *In Recovery Mode, only allow:
         *
         * - Pure collateral top-up
         * - Pure debt repayment
         * - Collateral top-up with debt repayment
         * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
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
            _vars.newTCR = _getNewTCRFromTroveChange(
                _vars.collChange,
                _vars.isCollIncrease,
                _vars.netDebtChange,
                _isDebtIncrease,
                _vars.price
            );
            _requireNewTCRisAboveCCR(_vars.newTCR);
        }
    }

    function _requireFrontEndNotRegistered(address _address) internal view {
        require(
            !frontEnds[_address],
            "BorrowerOperations: Must not already be a registered front end"
        );
    }

    function _requireFrontEndIsRegisteredOrZero(address _address) internal view {
        require(
            frontEnds[_address] || _address == address(0),
            "BorrowerOperations: Tag must be a registered front end, or the 0x0"
        );
    }

    function _requireICRisAboveMCR(uint256 _newICR) internal pure {
        require(
            _newICR >= MCR,
            "BorrowerOps: An operation that would result in ICR < MCR is not permitted"
        );
    }

    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave trove with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint256 _newICR, uint256 _oldICR) internal pure {
        require(
            _newICR >= _oldICR,
            "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode"
        );
    }

    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(
            _newTCR >= CCR,
            "BorrowerOps: An operation that would result in TCR < CCR is not permitted"
        );
    }

    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal view {
        require(
            _netDebt >= MIN_NET_DEBT(),
            "BorrowerOps: Trove's net debt must be greater than minimum"
        );
    }

    function _requireValidARTHRepayment(uint256 _currentDebt, uint256 _debtRepayment) internal view {
        require(
            _debtRepayment <= _currentDebt.sub(ARTH_GAS_COMPENSATION()),
            "BorrowerOps: Amount repaid must not be larger than the Trove's debt"
        );
    }

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }

    function _requireSufficientARTHBalance(
        IARTHValuecoin _arthToken,
        address _borrower,
        uint256 _debtRepayment
    ) internal view {
        require(
            _arthToken.balanceOf(_borrower) >= _debtRepayment,
            "BorrowerOps: Caller doesnt have enough ARTH to make repayment"
        );
    }

    function _requireValidMaxFeePercentage(uint256 _maxFeePercentage, bool _isRecoveryMode)
        internal
        view
    {
        if (_isRecoveryMode) {
            require(
                _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%"
            );
        } else {
            require(
                _maxFeePercentage >= getBorrowingFeeFloor() &&
                    _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%"
            );
        }
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromTroveChange(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256) {
        (uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

        uint256 newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    ) internal pure returns (uint256) {
        (uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

        uint256 newICR = LiquityMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewTroveAmounts(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256, uint256) {
        uint256 newColl = _coll;
        uint256 newDebt = _debt;

        newColl = _isCollIncrease ? _coll.add(_collChange) : _coll.sub(_collChange);
        newDebt = _isDebtIncrease ? _debt.add(_debtChange) : _debt.sub(_debtChange);

        return (newColl, newDebt);
    }

    function _getNewTCRFromTroveChange(
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    ) internal view returns (uint256) {
        uint256 totalColl = getEntireSystemColl();
        uint256 totalDebt = getEntireSystemDebt();

        totalColl = _isCollIncrease ? totalColl.add(_collChange) : totalColl.sub(_collChange);
        totalDebt = _isDebtIncrease ? totalDebt.add(_debtChange) : totalDebt.sub(_debtChange);

        uint256 newTCR = LiquityMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    function getCompositeDebt(uint256 _debt) external view override returns (uint256) {
        return _getCompositeDebt(_debt);
    }

    function BORROWING_FEE_FLOOR() external view returns (uint256) {
        return getBorrowingFeeFloor();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// Common interface for the Trove Manager.
interface IBorrowerOperations {
    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event GovernanceAddressChanged(address _newGovernanceAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event ARTHTokenAddressChanged(address _arthTokenAddress);

    event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 stake,
        BorrowerOperation operation
    );
    event ARTHBorrowingFeePaid(address indexed _borrower, uint256 _ARTHFee);
    event FrontEndRegistered(address indexed _frontend, uint256 timestamp);
    event PaidARTHBorrowingFeeToEcosystemFund(address indexed _ecosystemFund, uint256 _ARTHFee);
    event PaidARTHBorrowingFeeToFrontEnd(address indexed _frontEndTag, uint256 _ARTHFee);

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    // --- Functions ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _governanceAddress,
        address _sortedTrovesAddress,
        address _arthTokenAddress
    ) external;

    function registerFrontEnd() external;

    function openTrove(
        uint256 _maxFee,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint,
        address _frontEndTag
    ) external payable;

    function openTrove(
        uint256 _maxFee,
        uint256 _ARTHAmount,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(
        address _user,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function withdrawColl(
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawARTH(
        uint256 _maxFee,
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function repayARTH(
        uint256 _amount,
        address _upperHint,
        address _lowerHint
    ) external;

    function closeTrove() external;

    function adjustTrove(
        uint256 _maxFee,
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint256 _debt) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./IARTHValuecoin.sol";

// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event ARTHTokenAddressChanged(address _newARTHTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event GovernanceAddressChanged(address _governanceAddress);
    event WETHAddressChanged(address _wethAddress);

    event RewardSnapshotDetailsUpdated(address owner, address newOwner, uint256 timestamp);
    event TroveOwnersUpdated(address owner, address newOwner, uint256 idx, uint256 timestamp);
    event Liquidation(
        uint256 _liquidatedDebt,
        uint256 _liquidatedColl,
        uint256 _collGasCompensation,
        uint256 _ARTHGasCompensation
    );
    event Redemption(
        uint256 _attemptedARTHAmount,
        uint256 _actualARTHAmount,
        uint256 _ETHSent,
        uint256 _ETHFee
    );
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 _stake,
        TroveManagerOperation _operation
    );
    event TroveLiquidated(
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        TroveManagerOperation _operation
    );
    event BaseRateUpdated(uint256 _baseRate);
    event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    event TotalStakesUpdated(uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(uint256 _totalStakesSnapshot, uint256 _totalCollateralSnapshot);
    event LTermsUpdated(uint256 _L_ETH, uint256 _L_ARTHDebt);
    event TroveSnapshotsUpdated(uint256 _L_ETH, uint256 _L_ARTHDebt);
    event TroveIndexUpdated(address _borrower, uint256 _newIndex);

    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    // --- Functions ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _governanceAddress,
        address _arthTokenAddress,
        address _sortedTrovesAddress
    ) external;

    function stabilityPool() external view returns (IStabilityPool);

    function arthToken() external view returns (IARTHValuecoin);

    function getTroveOwnersCount() external view returns (uint256);

    function getTroveFromTroveOwnersArray(uint256 _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint256);

    function getCurrentICR(address _borrower, uint256 _price) external view returns (uint256);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint256 _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint256 _ARTHAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        uint256 _maxFee
    ) external;

    function updateStakeAndTotalStakes(address _borrower) external returns (uint256);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint256 index);

    function applyPendingRewards(address _borrower) external;

    function getPendingETHReward(address _borrower) external view returns (uint256);

    function getPendingARTHDebtReward(address _borrower) external view returns (uint256);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower)
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 pendingARTHDebtReward,
            uint256 pendingETHReward
        );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint256);

    function getRedemptionRateWithDecay() external view returns (uint256);

    function getRedemptionFeeWithDecay(uint256 _ETHDrawn) external view returns (uint256);

    function getBorrowingRate() external view returns (uint256);

    function getBorrowingRateWithDecay() external view returns (uint256);

    function getBorrowingFee(uint256 ARTHDebt) external view returns (uint256);

    function getBorrowingFeeWithDecay(uint256 _ARTHDebt) external view returns (uint256);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint256);

    function getTroveStake(address _borrower) external view returns (uint256);

    function getTroveDebt(address _borrower) external view returns (uint256);

    function getTroveColl(address _borrower) external view returns (uint256);

    function setTroveStatus(address _borrower, uint256 num) external;

    function increaseTroveColl(address _borrower, uint256 _collIncrease) external returns (uint256);

    function decreaseTroveColl(address _borrower, uint256 _collDecrease) external returns (uint256);

    function increaseTroveDebt(address _borrower, uint256 _debtIncrease) external returns (uint256);

    function decreaseTroveDebt(address _borrower, uint256 _collDecrease) external returns (uint256);

    function getTCR(uint256 _price) external view returns (uint256);

    function checkRecoveryMode(uint256 _price) external view returns (bool);

    function getTroveFrontEnd(address _borrower) external view returns (address);

    function setTroveFrontEndTag(address _borrower, address _frontEndTag) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC2612.sol";

interface IARTHValuecoin is IERC20, IERC2612 {
    // --- Events ---
    event BorrowerOperationsAddressToggled(
        address borrowerOperations,
        bool oldFlag,
        bool newFlag,
        uint256 timestamp
    );
    event TroveManagerToggled(address troveManager, bool oldFlag, bool newFlag, uint256 timestamp);
    event StabilityPoolToggled(address stabilityPool, bool oldFlag, bool newFlag, uint256 timestamp);
    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event ARTHTokenBalanceUpdated(address _user, uint256 _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function toggleBorrowerOperations(address borrowerOperations) external;

    function toggleTroveManager(address troveManager) external;

    function toggleStabilityPool(address stabilityPool) external;

    function sendToPool(
        address _sender,
        address poolAddress,
        uint256 _amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address user,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ICollSurplusPool {
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
    event EtherSent(address _to, uint256 _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getETH() external view returns (uint256);

    function getCollateral(address _account) external view returns (uint256);

    function accountSurplus(address _account, uint256 _amount) external;

    function claimColl(address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint256 _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---

    function setParams(
        uint256 _size,
        address _TroveManagerAddress,
        address _borrowerOperationsAddress
    ) external;

    function insert(
        address _id,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external;

    function remove(address _id) external;

    function reInsert(
        address _id,
        uint256 _newICR,
        address _prevId,
        address _nextId
    ) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (bool);

    function findInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./BaseMath.sol";
import "./LiquityMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/ILiquityBase.sol";
import "../Interfaces/IGovernance.sol";

/*
 * Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
contract LiquityBase is BaseMath, ILiquityBase {
    using SafeMath for uint256;

    uint256 public constant _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual troves
    uint256 public constant MCR = 1100000000000000000; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint256 public constant CCR = 1500000000000000000; // 150%

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    IActivePool public activePool;
    IDefaultPool public defaultPool;
    IGovernance public governance;

    // --- Gas compensation functions ---

    function getBorrowingFeeFloor() public view returns (uint256) {
        return governance.getBorrowingFeeFloor();
    }

    function getRedemptionFeeFloor() public view returns (uint256) {
        return governance.getRedemptionFeeFloor();
    }

    function getMaxBorrowingFee() public view returns (uint256) {
        return governance.getMaxBorrowingFee();
    }

    function getPriceFeed() public view override returns (IPriceFeed) {
        return governance.getPriceFeed();
    }

    function fetchPriceFeedPrice() public returns (uint256) {
        return governance.getPriceFeed().fetchPrice();
    }

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint256 _debt) internal view returns (uint256) {
        return _debt.add(ARTH_GAS_COMPENSATION());
    }

    function _getNetDebt(uint256 _debt) internal view returns (uint256) {
        return _debt.sub(ARTH_GAS_COMPENSATION());
    }

    // Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint256 _entireColl) internal view returns (uint256) {
        return _entireColl / PERCENT_DIVISOR;
    }

    function getEntireSystemColl() public view returns (uint256 entireSystemColl) {
        uint256 activeColl = activePool.getETH();
        uint256 liquidatedColl = defaultPool.getETH();
        return activeColl.add(liquidatedColl);
    }

    function getEntireSystemDebt() public view returns (uint256 entireSystemDebt) {
        uint256 activeDebt = activePool.getARTHDebt();
        uint256 closedDebt = defaultPool.getARTHDebt();
        return activeDebt.add(closedDebt);
    }

    function ARTH_GAS_COMPENSATION() public view returns (uint256) {
        return governance.getGasCompensation();
    }

    function MIN_NET_DEBT() public view returns (uint256) {
        return governance.getMinNetDebt();
    }

    function _getTCR(uint256 _price) internal view returns (uint256 TCR) {
        uint256 entireSystemColl = getEntireSystemColl();
        uint256 entireSystemDebt = getEntireSystemDebt();
        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt, _price);
        return TCR;
    }

    function _checkRecoveryMode(uint256 _price) internal view returns (bool) {
        uint256 TCR = _getTCR(_price);
        return TCR < CCR;
    }

    function _requireUserAcceptsFee(
        uint256 _fee,
        uint256 _amount,
        uint256 _maxFeePercentage
    ) internal pure {
        uint256 feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

pragma solidity 0.8.0;

contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_account)
        }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IPriceFeed.sol";
import "./IGovernance.sol";

interface ILiquityBase {
    // function governance() external view returns (IGovernance);

    function getPriceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
 * The Stability Pool holds ARTH tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its ARTH debt gets offset with
 * ARTH in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of ARTH tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a ARTH loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total ARTH in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- MAHA ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An MAHA issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued MAHA in proportion to the deposit as a share of total deposits. The MAHA earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#maha-issuance-to-stability-providers
 */
interface IStabilityPool {
    // --- Events ---

    event StabilityPoolETHBalanceUpdated(uint256 _newBalance);
    event StabilityPoolARTHBalanceUpdated(uint256 _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event ARTHTokenAddressChanged(address _newARTHTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event GovernanceAddressChanged(address _newGovernanceAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint256 _P);
    event S_Updated(uint256 _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint256 _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _S, uint256 _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint256 _P, uint256 _G);
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
    event FrontEndStakeChanged(
        address indexed _frontEnd,
        uint256 _newFrontEndStake,
        address _depositor
    );

    event ETHGainWithdrawn(address indexed _depositor, uint256 _ETH, uint256 _ARTHLoss);
    event MAHAPaidToDepositor(address indexed _depositor, uint256 _MAHA);
    event MAHAPaidToFrontEnd(address indexed _frontEnd, uint256 _MAHA);
    event EtherSent(address _to, uint256 _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _arthTokenAddress,
        address _sortedTrovesAddress,
        address _governanceAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (MAHA, ETH) to depositor
     * - Sends the tagged front end's accumulated MAHA gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (MAHA, ETH) to depositor
     * - Sends the tagged front end's accumulated MAHA gains to the tagged front end
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
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Sends all depositor's MAHA gain to  depositor
     * - Sends all tagged front end's MAHA gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint256 _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the ARTH contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debt, uint256 _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint256);

    /*
     * Returns ARTH held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalARTHDeposits() external view returns (uint256);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint256);

    /*
     * Calculate the MAHA gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorMAHAGain(address _depositor) external view returns (uint256);

    /*
     * Return the MAHA gain earned by the front end.
     */
    function getFrontEndMAHAGain(address _frontEnd) external view returns (uint256);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedARTHDeposit(address _depositor) external view returns (uint256);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint256);

    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ETH received
     * receive() external payable;
     */
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    // --- Function ---
    function fetchPrice() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IPriceFeed.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IOracle.sol";

interface IGovernance {
    event AllowMintingChanged(bool oldFlag, bool newFlag, uint256 timestamp);
    event BorrowingFeeFloorChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event FundAddressChanged(address oldAddress, address newAddress, uint256 timestamp);
    event MaxBorrowingFeeChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event MAHAChanged(address oldAddress, address newAddress, uint256 timestamp);
    event MaxDebtCeilingChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event PriceFeedChanged(address oldAddress, address newAddress, uint256 timestamp);
    event RedemptionFeeFloorChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event SentToFund(address token, uint256 amount, uint256 timestamp, string reason);

    function getAllowMinting() external view returns (bool);

    function getBorrowingFeeFloor() external view returns (uint256);

    function getDeploymentStartTime() external view returns (uint256);

    function getFund() external view returns (address);

    function getMAHA() external view returns (IERC20);

    function getGasCompensation() external view returns (uint256);

    function getMaxBorrowingFee() external view returns (uint256);

    function getMaxDebtCeiling() external view returns (uint256);

    function getMinNetDebt() external view returns (uint256);

    function getPriceFeed() external view returns (IPriceFeed);

    function getRedemptionFeeFloor() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity 0.8.0;

interface IOracle {
    function getPrice() external view returns (uint256);

    function getDecimalPercision() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
pragma solidity 0.8.0;

contract BaseMath {
    uint256 public constant DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./SafeMath.sol";

library LiquityMath {
    using SafeMath for uint256;

    uint256 internal constant DECIMAL_PRECISION = 1e18;

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
            uint256 newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return 2**256 - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolARTHDebtUpdated(uint256 _ARTHDebt);
    event ActivePoolETHBalanceUpdated(uint256 _ETH);

    // --- Functions ---
    function sendETH(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolARTHDebtUpdated(uint256 _ARTHDebt);
    event DefaultPoolETHBalanceUpdated(uint256 _ETH);

    // --- Functions ---
    function sendETHToActivePool(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// Common interface for the Pools.
interface IPool {
    // --- Events ---

    event ETHBalanceUpdated(uint256 _newBalance);
    event ARTHBalanceUpdated(uint256 _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event EtherSent(address _to, uint256 _amount);

    // --- Functions ---

    function getETH() external view returns (uint256);

    function getARTHDebt() external view returns (uint256);

    function increaseARTHDebt(uint256 _amount) external;

    function decreaseARTHDebt(uint256 _amount) external;
}