// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";

import "IBorrowerOps.sol";
import "IVaultManager.sol";
import "IUSDCToken.sol";
import "ICollSurplusPool.sol";
import "ISortedVaults.sol";
import "OrumBase.sol";
import "CheckContract.sol";
import "IoETHToken.sol";
import "ILendingPool.sol";
import "ICollateralPool.sol";
import "IGasPool.sol";
import "IBorrowersRewardsPool.sol";



contract BorrowerOps is  OrumBase, Ownable, CheckContract, IBorrowerOps {
    string constant public NAME = "BorrowerOps";
    
    // --- Connected contract declarations ---
    address lendingPoolAddress;
    address gasPoolAddress;
    address orumFeeDistributionAddress;
    address bufferPoolAddress;

    IoETHToken public oethToken;
    IVaultManager public vaultManager;
    ICollateralPool public collateral_pool;
    ILendingPool lendingPool;
    IGasPool gas_pool;
    ICollSurplusPool collSurplusPool;
    IUSDCToken public usdcToken;
    ISortedVaults public sortedVaults;

    uint public lockupTime;

    // --- Dependency setters ---

    struct LocalVariables_adjustVault {
        uint price;
        uint collChange;
        uint netDebtChange;
        bool isCollIncrease;
        uint debt;
        uint coll;
        uint oldICR;
        uint newICR;
        uint newTCR;
        uint oETHFee;
        uint newDebt;
        uint newColl;
        uint stake;
    }

    struct ContractsCache {
        IVaultManager vaultManager;
        IActivePool activePool;
        IUSDCToken usdcToken;
        IoETHToken oethToken;
    }

    struct LocalVariables_openVault {
        uint price;
        uint oETHFee;
        uint netColl;
        uint netDebt;
        uint compositeDebt;
        uint ICR;
        uint NICR;
        uint stake;
        uint arrayIndex;
    }

    enum BorrowerOperation {
        openVault,
        closeVault,
        adjustVault
    }

    // --- Dependency setters ---
    function setAddresses(
        address _vaultManagerAddress,
        address _activePoolAddress,
        address _borrowersRewardsPoolAddress,
        address _lendingPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedVaultsAddress,
        address _usdcTokenAddress,
        address _orumFeeDistributionAddress,
        address _oETHTokenAddress,
        address _collateralPool
    )
        external
        onlyOwner
    {
        // This makes impossible to open a vault with zero withdrawn USDC
        assert(MIN_NET_DEBT > 0);

        checkContract(_vaultManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_lendingPoolAddress);
        checkContract(_borrowersRewardsPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_sortedVaultsAddress);
        checkContract(_usdcTokenAddress);
        checkContract(_orumFeeDistributionAddress);
        CheckContract(_oETHTokenAddress);

        vaultManager = IVaultManager(_vaultManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        borrowersRewardsPool = IBorrowersRewardsPool(_borrowersRewardsPoolAddress);
        lendingPoolAddress = _lendingPoolAddress;
        lendingPool = ILendingPool(_lendingPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        gas_pool = IGasPool(_gasPoolAddress);
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        sortedVaults = ISortedVaults(_sortedVaultsAddress);
        usdcToken = IUSDCToken(_usdcTokenAddress);
        orumFeeDistributionAddress = _orumFeeDistributionAddress;
        oethToken = IoETHToken(_oETHTokenAddress);
        collateral_pool = ICollateralPool(_collateralPool);

        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit BorrowersRewardsPoolAddressChanged(_borrowersRewardsPoolAddress);
        emit LendingPoolAddressChanged(_lendingPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit SortedVaultsAddressChanged(_sortedVaultsAddress);
        emit USDCTokenAddressChanged(_usdcTokenAddress);
        emit OrumRevenueAddressChanged(_orumFeeDistributionAddress);
        emit oETHTokenAddressChanged(_oETHTokenAddress);
    }

    function setBufferPoolAddress(address _address) external onlyOwner {
        bufferPoolAddress = _address;
    }

    function openVault(uint _maxFeePercentage, uint _USDCAmount, uint _colloETHamount , address _upperHint, address _lowerHint) external payable override {
        require(lendingPool.allowBorrow(), "BorrowerOps: utilisationRatio >= 90");
        require(_colloETHamount <= oethToken.balanceOf(msg.sender) , "BorrowerOps: insufficient oETH balance");
        require(lendingPool.getUSDCDeposits() >= _USDCAmount + (USDC_GAS_COMPENSATION), "BorrowerOps: SP balance is lower than requested borrow amount");
        ContractsCache memory contractsCache = ContractsCache(vaultManager, activePool, usdcToken, oethToken);
        LocalVariables_openVault memory vars;

        vars.price = priceFeed.fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireVaultisNotActive(contractsCache.vaultManager, msg.sender);

        vars.netDebt = _USDCAmount; //10e6
        vars.netColl = _colloETHamount;

        if (!isRecoveryMode) {
            vars.oETHFee = _triggerBorrowingFee(contractsCache.vaultManager, _USDCAmount, _maxFeePercentage, vars.price);
            // send the oeth fee to the staking contract
            vars.netColl -= vars.oETHFee;
        }
        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested USDC amount + USDC gas comp (10)
        vars.compositeDebt = _getCompositeDebt(vars.netDebt); // 10e6 Decimal Precision
        assert(vars.compositeDebt > 0);
        
        vars.ICR = OrumMath._computeCR(vars.netColl, vars.compositeDebt, vars.price);
        vars.NICR = OrumMath._computeNominalCR(vars.netColl, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint newTCR = _getNewTCRFromVaultChange(vars.netColl, true, vars.compositeDebt, true, vars.oETHFee, vars.price);  // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR); 
        }

        // Set the vault struct's properties
        contractsCache.vaultManager.setVaultStatus(msg.sender, 1);
        contractsCache.vaultManager.increaseVaultColl(msg.sender, vars.netColl);
        contractsCache.vaultManager.increaseVaultDebt(msg.sender, vars.compositeDebt);

        contractsCache.vaultManager.updateVaultRewardSnapshots(msg.sender);
        vars.stake = contractsCache.vaultManager.updateStakeAndTotalStakes(msg.sender);

        sortedVaults.insert(msg.sender, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.vaultManager.addVaultOwnerToArray(msg.sender);
        emit VaultCreated(msg.sender, vars.arrayIndex);

        // sends oETH to active pool
        oethToken.sendToPool(msg.sender, address(activePool), _colloETHamount);
        activePool.receiveoETH(_colloETHamount);

        _withdrawUSDC(contractsCache.activePool, contractsCache.usdcToken, msg.sender, _USDCAmount, vars.netDebt);
        // Move the USDC gas compensation to the Gas Pool
        _withdrawUSDC(contractsCache.activePool, contractsCache.usdcToken, gasPoolAddress, USDC_GAS_COMPENSATION, USDC_GAS_COMPENSATION);

        emit VaultUpdated(msg.sender, vars.compositeDebt, vars.netColl, vars.stake, uint8(BorrowerOperation.openVault));
        emit BorrowFeeInoETH(msg.sender, vars.oETHFee);

        if (!isRecoveryMode) {
            if (vars.oETHFee > 0) {
                activePool.sendoETH(orumFeeDistributionAddress, vars.oETHFee);
            }
        }
    }

    // Send oETH as collateral to a vault
    function addColl(uint _collAddition, address _upperHint, address _lowerHint) external payable override  { 
        _adjustVault(msg.sender, _collAddition, true, 0, false, _upperHint, _lowerHint, 0);
    }

    // sends oETH to active pool
    function _transferoETHFromSender(IoETHToken _oETHToken, address _from, address _to, uint _amount) internal {
        bool success = _oETHToken.transferFrom(_from, _to, _amount);
        require(success, "BorrowerOps: error in transfering oETH to active pool or orum_revenue");
    }

    // Send oETH as collateral to a vault. Called by borrowers.
    function moveoETHGainToVault(address _upperHint, address _lowerHint) external payable override {
        _adjustVault(msg.sender, 0, false, 0, false, _upperHint, _lowerHint, 0);
    }

     // Send oETH as collateral to a vault. Called by only the Stability Pool.
    function moveoETHGainToVaultFromLendingPool(address _borrower, uint depositorROSEGain, address _upperHint, address _lowerHint) external payable override {
        _requireCallerIsLendingPool();
        _adjustVault(_borrower, depositorROSEGain, true, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw oETH collateral from a vault
    function withdrawColl(uint _collWithdrawal, address _upperHint, address _lowerHint) external override {
        _adjustVault(msg.sender, _collWithdrawal, false, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw USDC tokens from a vault: mint new USDC tokens to the owner, and increase the vault's debt accordingly
    function withdrawUSDC(uint _maxFeePercentage, uint _USDCAmount, address _upperHint, address _lowerHint) external override {
        require(lendingPool.allowBorrow(), "BorrowerOps: utilisationRatio >= 90");
        require(lendingPool.getUSDCDeposits() >= _USDCAmount + (USDC_GAS_COMPENSATION), "BorrowerOps: SP balance is lower than requested borrow amount");
        _adjustVault(msg.sender, 0, false, _USDCAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay USDC tokens to a Vault: Burn the repaid USDC tokens, and reduce the vault's debt accordingly
    function repayUSDC(uint _USDCAmount, address _upperHint, address _lowerHint) external override {
        _adjustVault(msg.sender, 0, false, _USDCAmount, false, _upperHint, _lowerHint, 0);
    }

    /*
    * _adjustVault(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal. 
    * It therefore expects either a positive _collChange, or a positive _collWithdrawal argument.
    * If both are positive, it will revert.
    */
    function _adjustVault(address _borrower, uint _collChange, bool _isCollIncrease, uint _USDCChange, bool _isDebtIncrease, address _upperHint, address _lowerHint, uint _maxFeePercentage) internal {
        ContractsCache memory contractsCache = ContractsCache(vaultManager, activePool, usdcToken, oethToken);
        LocalVariables_adjustVault memory vars;

        vars.price = priceFeed.fetchPrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_USDCChange);
        }
        
        _requireNonZeroAdjustment(_isCollIncrease, _collChange, _USDCChange);
        _requireVaultisActive(contractsCache.vaultManager, _borrower);

        // Confirm the operation is either a borrower adjusting their own vault, or a pure oETH transfer from the Stability Pool to a vault
        assert(msg.sender == _borrower || (_collChange > 0 && _USDCChange == 0));

        contractsCache.vaultManager.applyStakingRewards(_borrower);

        // Get the collChange based on whether or not oETH was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = (_collChange, _isCollIncrease) ; // _getCollChange(_collChange, _USDCChange); 

        vars.netDebtChange = _USDCChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) { 
            vars.oETHFee = _triggerBorrowingFee(contractsCache.vaultManager, _USDCChange, _maxFeePercentage, vars.price);
        }

        vars.debt = contractsCache.vaultManager.getVaultDebt(_borrower);
        vars.coll = contractsCache.vaultManager.getVaultColl(_borrower);
        
        // Get the vault's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = OrumMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromVaultChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.oETHFee, vars.price);
        require((!_isCollIncrease && _collChange <= vars.coll) || _isCollIncrease , "Bops, cannot withdraw more than existing collateral"); 

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _USDCChange, _isDebtIncrease, vars);
            
        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough USDC
        if (!_isDebtIncrease && _USDCChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt)- vars.netDebtChange);
            _requireValidUSDCRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientUSDCBalance(contractsCache.usdcToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateVaultFromAdjustment(contractsCache.vaultManager, _borrower, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.oETHFee);
        vars.stake = contractsCache.vaultManager.updateStakeAndTotalStakes(_borrower);

        // Re-insert vault in to the sorted list
        uint newNICR = _getNewNominalICRFromVaultChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.oETHFee);
        sortedVaults.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        emit VaultUpdated(_borrower, vars.newDebt, vars.newColl, vars.stake,uint8(BorrowerOperation.adjustVault));
        emit BorrowFeeInoETH(msg.sender, vars.oETHFee);

        // Use the unmodified _USDCChange here, as we don't send the fee to the user
        _moveTokensAndoETHFromAdjustment(
            contractsCache.activePool,
            contractsCache.usdcToken,
            contractsCache.oethToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _USDCChange,
            _isDebtIncrease,
            vars.netDebtChange,
            vars.oETHFee
        );

    }

    function closeVault() external override {
        IVaultManager vaultManagerCached = vaultManager;
        IActivePool activePoolCached = activePool;
        IUSDCToken usdcTokenCached = usdcToken;

        _requireVaultisActive(vaultManagerCached, msg.sender);
        uint price = priceFeed.fetchPrice();
        _requireNotInRecoveryMode(price);

        vaultManagerCached.applyStakingRewards(msg.sender);

        uint coll = vaultManagerCached.getVaultColl(msg.sender);
        uint debt = vaultManagerCached.getVaultDebt(msg.sender);

        _requireSufficientUSDCBalance(usdcTokenCached, msg.sender, debt - USDC_GAS_COMPENSATION);

        uint newTCR = _getNewTCRFromVaultChange(coll, false, debt, false, 0, price);
        _requireNewTCRisAboveCCR(newTCR);

        vaultManagerCached.removeStake(msg.sender);
        vaultManagerCached.closeVault(msg.sender);

        emit VaultUpdated(msg.sender, 0, 0, 0, uint8(BorrowerOperation.closeVault));

        // Burn the repaid USDC from the user's balance and the gas compensation from the Gas Pool
        _repayUSDC(activePoolCached, usdcTokenCached, msg.sender, debt - USDC_GAS_COMPENSATION);
        gas_pool.approveWhileCloseVault();
        _repayUSDC(activePoolCached, usdcTokenCached, gasPoolAddress, USDC_GAS_COMPENSATION);

        // Send the collateral back to the user
        activePoolCached.sendoETH(msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral() external override {
        // send oETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(IVaultManager _vaultManager, uint _USDCAmount, uint _maxFeePercentage, uint _price) internal returns (uint) {
        _vaultManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint USDCFee = _vaultManager.getBorrowingFee(_USDCAmount); // USDCFee in 10e6 precision 

        _requireUserAcceptsFee(USDCFee, _USDCAmount, _maxFeePercentage); // Max fee percentage in 10e18 precsion
        
        // Send fee to ORUM staking contract
        uint oETHFee = (USDCFee * DECIMAL_PRECISION * (DECIMAL_PRECISION / USDC_DECIMAL_PRECISION))/ _price; // oETH fee should be in 1e18 precision
        return oETHFee;
    }

    function _getUSDValue(uint _coll, uint _price) internal pure returns (uint) {
        uint usdValue = (_price * _coll) / DECIMAL_PRECISION;

        return usdValue;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
            isCollIncrease = false;
        }
    }

    // Update vault's coll and debt based on whether they increase or decrease
    function _updateVaultFromAdjustment
    (
        IVaultManager _vaultManager,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _borrowFee
    )
        internal
        returns (uint, uint)
    {
        uint newColl = (_isCollIncrease) ? _vaultManager.increaseVaultColl(_borrower, _collChange)
                                        : _vaultManager.decreaseVaultColl(_borrower, _collChange);
        newColl = (_isDebtIncrease) ? _vaultManager.decreaseVaultColl(_borrower, _borrowFee): newColl;
        uint newDebt = (_isDebtIncrease) ? _vaultManager.increaseVaultDebt(_borrower, _debtChange)
                                        : _vaultManager.decreaseVaultDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndoETHFromAdjustment
    (
        IActivePool _activePool,
        IUSDCToken _usdcToken,
        IoETHToken _oETHToken,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _USDCChange,
        bool _isDebtIncrease,
        uint _netDebtChange,
        uint _borrowFee
    )
        internal
    {
        if (_isDebtIncrease ) {
            _withdrawUSDC(_activePool, _usdcToken, _borrower, _USDCChange, _netDebtChange);
            _activePool.sendoETH(orumFeeDistributionAddress, _borrowFee);
            
        } else {
            _repayUSDC(_activePool, _usdcToken, _borrower, _USDCChange);
        }

        if (_isCollIncrease) {
            oethToken.sendToPool(msg.sender, address(activePool), _collChange);
            _activePool.receiveoETH(_collChange);
        } else {
            _activePool.sendoETH(_borrower, _collChange); 
        }
    }


    // Issue the specified amount of USDC to _account and increases the total active debt (_netDebtIncrease potentially includes a USDCFee)
    function _withdrawUSDC(IActivePool _activePool, IUSDCToken _usdcToken, address _account, uint _USDCAmount, uint _netDebtIncrease) internal {
        // ILendingPool lendingPoolChached = lendingPool;
        _activePool.increaseUSDCDebt(_netDebtIncrease);
        // _usdcToken.mint(_account, _USDCAmount);
        lendingPool.sendUSDCtoBorrower(_account, _USDCAmount);
    }

    // Burn the specified amount of USDC from _account and decreases the total active debt
    function _repayUSDC(IActivePool _activePool, IUSDCToken _usdcToken, address _account, uint _USDC) internal {
        _activePool.decreaseUSDCDebt(_USDC);
        _usdcToken.transferFrom(_account, bufferPoolAddress, _USDC);
        lendingPool.decreaseLentAmount(_USDC);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint _collWithdrawal, bool _isCollIncrease) internal view {
        require(_isCollIncrease == true || _collWithdrawal == 0, "BorrowerOps: Cannot withdraw and add coll");
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(msg.sender == _borrower, "BorrowerOps: Caller must be the borrower for a withdrawal");
    }

    function _requireNonZeroAdjustment(bool _isCollIncrease, uint _collWithdrawal, uint _USDCChange) internal view {
        require( _isCollIncrease == false || _collWithdrawal != 0 || _USDCChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");
    }

    function _requireVaultisActive(IVaultManager _vaultManager, address _borrower) internal view {
        uint status = _vaultManager.getVaultStatus(_borrower);
        require(status == 1, "BorrowerOps: Vault does not exist or is closed");
    }

    function _requireVaultisNotActive(IVaultManager _vaultManager, address _borrower) internal view {
        uint status = _vaultManager.getVaultStatus(_borrower);
        require(status != 1, "BorrowerOps: Vault is active");
    }

    function _requireNonZeroDebtChange(uint _USDCChange) internal pure {
        require(_USDCChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }
   
    function _requireNotInRecoveryMode(uint _price) internal view {
        require(!_checkRecoveryMode(_price), "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireNoCollWithdrawal(bool _isCollIncrease) internal pure {
        require(_isCollIncrease, "BorrowerOps: Collateral withdrawal not permitted Recovery Mode");
    }

    function _requireValidAdjustmentInCurrentMode 
    (
        bool _isRecoveryMode,
        uint _USDCChange,
        bool _isDebtIncrease, 
        LocalVariables_adjustVault memory _vars
    ) 
        internal 
        // view 
    {
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
            _requireNoCollWithdrawal((_vars.isCollIncrease && _USDCChange == 0) || ( _USDCChange > 0 && !_isDebtIncrease));
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_vars.newICR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }       
        } else { // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromVaultChange(_vars.collChange, _vars.isCollIncrease, _vars.netDebtChange, _isDebtIncrease, _vars.oETHFee, _vars.price);
            _requireNewTCRisAboveCCR(_vars.newTCR);  
        }
    }

    function _requireICRisAboveMCR(uint _newICR) internal view {
        require(_newICR >= MCR, "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireICRisAboveCCR(uint _newICR) internal view {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave vault with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint _newICR, uint _oldICR) internal pure {
        require(_newICR >= _oldICR, "BorrowerOps: Cannot decrease your Vault's ICR in Recovery Mode");
    }

    function _requireNewTCRisAboveCCR(uint _newTCR) internal view {
        require(_newTCR >= CCR, "BorrowerOps: An operation that would result in TCR < CCR is not permitted");
    }

    function _requireAtLeastMinNetDebt(uint _netDebt) internal view {
        require (_netDebt >= MIN_NET_DEBT, "BorrowerOps: Vault's net debt must be greater than minimum");
    }

    function _requireValidUSDCRepayment(uint _currentDebt, uint _debtRepayment) internal view {
        require(_debtRepayment <= _currentDebt - USDC_GAS_COMPENSATION, "BorrowerOps: Amount repaid must not be larger than the Vault's debt");
    }

    function _requireCallerIsLendingPool() internal view {
        require(msg.sender == lendingPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }

     function _requireSufficientUSDCBalance(IUSDCToken _usdcToken, address _borrower, uint _debtRepayment) internal view {
        require(_usdcToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough USDC to make repayment");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage, bool _isRecoveryMode) internal view {
        if (_isRecoveryMode) {
            require(_maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%");
        } else {
            require(_maxFeePercentage >= BORROWING_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.75% and 100%");
        }
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromVaultChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _borrowFee
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewVaultAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease, _borrowFee);

        uint newNICR = OrumMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromVaultChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _borrowFee,
        uint _price
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewVaultAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease, _borrowFee);

        uint newICR = OrumMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewVaultAmounts(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _borrowFee
    )
        internal
        pure
        returns (uint, uint)
    {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll +_collChange:  _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;
        newColl = _isDebtIncrease ? newColl - _borrowFee: newColl;

        return (newColl, newDebt);
    }

    function _getNewTCRFromVaultChange
    (
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _borrowFee,
        uint _price
    )
        internal
        view
        returns (uint)
    {
        uint totalColl = getEntireSystemColl();
        uint totalDebt = getEntireSystemDebt();

        totalColl = _isCollIncrease ? totalColl + _collChange : totalColl - _collChange;
        totalDebt = _isDebtIncrease ? totalDebt + _debtChange: totalDebt - _debtChange;
        totalColl = _isDebtIncrease ? totalColl - _borrowFee: totalColl;

        uint newTCR = OrumMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    function getCompositeDebt(uint _debt) external view override returns (uint) {
        return _getCompositeDebt(_debt);
    }

    function changeTreasuryAddress(address _orumFeeDistributionAddress) external onlyOwner{
        checkContract(_orumFeeDistributionAddress);
        orumFeeDistributionAddress = _orumFeeDistributionAddress;
        emit OrumRevenueAddressChanged(_orumFeeDistributionAddress);
    }
    function changeBorrowFeeFloor(uint _newBorrowFeeFloor) external onlyOwner{
        BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * _newBorrowFeeFloor;
    }
    function changeMCR(uint _newMCR) external onlyOwner{
        MCR = _newMCR;
    }
    function changeCCR(uint _newCCR) external onlyOwner{
        CCR = _newCCR;
    }
    function changeMinNetDebt(uint _newMinDebt) external onlyOwner{
        MIN_NET_DEBT = _newMinDebt;
    }
    function changeGasCompensation(uint _USDCGasCompensation) external onlyOwner{
        USDC_GAS_COMPENSATION = _USDCGasCompensation;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

pragma solidity >=0.8.0;

import "IoETHToken.sol";

interface IBorrowerOps {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oETHTokenAddressChanged(address _oETHTokenAddress);

    event VaultCreated(address indexed _borrower, uint arrayIndex);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event BorrowFeeInoETH(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToTreasury(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToOrumRevenue(address indexed _borrower, uint _borrowFee);

    // --- Functions ---
    function openVault(uint _maxFee, uint _debtAmount, uint _colloETHamount, address _upperHint, address _lowerHint) external payable;
    // function addColl(address _upperHint, address _lowerHint) external payable;
    function addColl(uint _collAddition, address _upperHint, address _lowerHint) external payable;
    function moveoETHGainToVault(address _upperHint, address _lowerHint) external payable;
    function moveoETHGainToVaultFromLendingPool(address _borrower, uint depositorROSEGain, address _upperHint, address _lowerHint) external payable;
    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;
    function withdrawUSDC(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;
    function repayUSDC(uint _amount, address _upperHint, address _lowerHint) external;
    function closeVault() external;
    function claimCollateral() external;
    function getCompositeDebt(uint _debt) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IoETHToken is IERC20, IERC2612 { 
    
    // --- Events ---


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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

pragma solidity >=0.8.0;

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
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
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

pragma solidity >=0.8.0;

import "IOrumBase.sol";


// Common interface for the Vault Manager.
interface IVaultManager is IOrumBase {
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event USDCTokenAddressChanged(address _newUSDCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oETHTokenAddressChanged(address _newoETHTokenAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _USDCGasCompensation);
    event Test_LiquidationoETHFee(uint _oETHFee);
    event Redemption(uint _attemptedUSDCAmount, uint _actualUSDCAmount, uint _oETHSent, uint _oETHFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event VaultIndexUpdated(address _borrower, uint _newIndex);
    event TEST_error(uint _debtInoETH, uint _collToSP, uint _collToOrum, uint _totalCollProfits);
    event TEST_liquidationfee(uint _totalCollToSendToSP, uint _totalCollToSendToOrumRevenue);
    event TEST_account(address _borrower, uint _amount);
    event TEST_normalModeCheck(bool _mode, address _borrower, uint _amount, uint _coll, uint _debt, uint _price);
    event TEST_debt(uint _debt);
    event TEST_offsetValues(uint _debtInoETH, uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint _totalCollProfit, uint _stakingRToRedistribute);
    event Coll_getOffsetValues(uint _debt, uint _coll, uint _stakingRToRedistribute);
    event LTermsUpdated(uint _L_STAKINGR);
    event VaultSnapshotsUpdated(uint L_STAKINGR);
    event SystemSnapshotsUpdated(uint totalStakesSnapshot, uint totalCollateralSnapshot);
    // --- Functions ---
    function getVaultOwnersCount() external view returns (uint);

    function getVaultFromVaultOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);

    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateVaults(uint _n) external;

    function batchLiquidateVaults(address[] calldata _VaultArray) external; 

    function addVaultOwnerToArray(address _borrower) external returns (uint index);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll,
        uint pendingStakingReward
    );

    function closeVault(address _borrower) external;

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint USDCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _USDCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getVaultStatus(address _borrower) external view returns (uint);

    function getVaultDebt(address _borrower) external view returns (uint);

    function getVaultColl(address _borrower) external view returns (uint);

    function setVaultStatus(address _borrower, uint num) external;

    function increaseVaultColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseVaultColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseVaultDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);

    function applyStakingRewards(address _borrower) external;

    function updateVaultRewardSnapshots(address _borrower) external;

    function getPendingStakingoethReward(address _borrower) external view returns (uint);

    function removeStake(address _borrower) external;

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function redistributeStakingRewards(uint _coll) external;

    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IPriceFeed.sol";

interface IOrumBase {
    function priceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IPriceFeed {
    // -- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // ---Function---
    function fetchPrice() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event LendingPoolAddressChanged(address _newLendingPoolAddress);

    event USDCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event oETHSent(address _to, uint _amount);
    event CollSurplusoETHBalanceUpdated(uint _oETH);
    event Test_event_call_sruplus(uint number_coll);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _activePoolAddress,
        address _oETHTokenAddress
    ) external;

    function getoETH() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;

    function receiveoETHInCollSurplusPool(uint new_coll) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// Common interface for the SortedVaults Doubly Linked List.
interface ISortedVaults {

    // --- Events ---
    
    event SortedVaultsAddressChanged(address _sortedDoublyLinkedListAddress);
    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _VaultManagerAddress, address _borrowerOpsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "OrumMath.sol";
import "IActivePool.sol";
import "IPriceFeed.sol";
import "IOrumBase.sol";
import "IBorrowersRewardsPool.sol";


/* 
* Base contract for VaultManager, BorrowerOps and LendingPool. Contains global system constants and
* common functions. 
*/
contract OrumBase is IOrumBase {
    using SafeMath for uint;

    uint constant public DECIMAL_PRECISION = 1e18;

    uint constant public USDC_DECIMAL_PRECISION = 1e6;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual Vaults
    uint public MCR = 1100000000000000000; // 110%;

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint public CCR = 1500000000000000000; // 150%

    // Amount of USDC to be locked in gas pool on opening vaults
    uint public USDC_GAS_COMPENSATION = 200e6;

    // Minimum amount of net USDC debt a vault must have
    uint public MIN_NET_DEBT = 2000e6;

    uint public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 10000 * 75 ; // 0.75%

    uint public TREASURY_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * 20; // 20%
    


    address public contractOwner;

    IActivePool public activePool;

    IBorrowersRewardsPool public borrowersRewardsPool; 


    IPriceFeed public override priceFeed;

    constructor() {
        contractOwner = msg.sender;
    }
    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a vault, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal view  returns (uint) {
        return _debt.add(USDC_GAS_COMPENSATION);
    }
    function _getNetDebt(uint _debt) internal view returns (uint) {
        return _debt.sub(USDC_GAS_COMPENSATION);
    }
    // Return the amount of oETH to be drawn from a vault's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal view returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }
    
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getoETH();
        uint borrowerRewards = borrowersRewardsPool.getBorrowersoETHRewards();
        return activeColl.add(borrowerRewards);
    }

    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getUSDCDebt();
        return activeDebt;
    }
    function _getTreasuryLiquidationProfit(uint _amount) internal view returns (uint){
        return _amount.mul(TREASURY_LIQUIDATION_PROFIT).div(DECIMAL_PRECISION);
    }
    function _getTCR(uint _price) internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();

        TCR = OrumMath._computeCR(entireSystemColl, entireSystemDebt, _price);
        return TCR;
    }

    function _checkRecoveryMode(uint _price) internal view returns (bool) {
        uint TCR = _getTCR(_price);

        return TCR < CCR;
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }

    function _requireCallerIsOwner() internal view {
        require(msg.sender == contractOwner, "OrumBase: caller not owner");
    }

    function changeOwnership(address _newOwner) external {
        require(msg.sender == contractOwner, "OrumBase: Caller not owner");
        contractOwner = _newOwner;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "SafeMath.sol";

library OrumMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    uint internal constant USDC_DECIMAL_PRECISION = 1e6;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
    *
    * - Making it "too high" could lead to overflows.
    * - Making it "too low" could lead to an ICR equal to zero, due to truncation from Solidity floor division.
    *
    * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 oETH,
    * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
    *
    */

    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }
    function _max(int _a, int _b) internal pure returns (uint) {
        return (_a >= _b) ? uint(_a) : uint(_b);
    }

    /*
    * Multiply two decimal numbers and use normal rounding rules
    * - round product up if 19'th mantissa digit >= 5
    * - round product down if 19'th mantissa digit < 5
    * 
    * Used only inside exponentiation, _decPow().
    */

    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);
        decProd = prod_xy.add(DECIMAL_PRECISION/2).div(DECIMAL_PRECISION);
    }
    
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt).mul(USDC_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt).mul(USDC_DECIMAL_PRECISION).div(DECIMAL_PRECISION);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoETHToken.sol";


interface IActivePool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolUSDCDebtUpdated(uint _USDCDebt);
    event ActivePooloETHBalanceUpdated(uint oETH);
    event SentoETHActiveVault(address _to,uint _amount );
    event ActivePoolReceivedETH(uint _ETH);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);
    event oETHSent(address _to, uint _amount);

    // --- Functions ---
    function sendoETH(address _account, uint _amount) external;
    function receiveoETH(uint new_coll) external;
    function getoETH() external view returns (uint);
    function getUSDCDebt() external view returns (uint);
    function increaseUSDCDebt(uint _amount) external;
    function decreaseUSDCDebt(uint _amount) external;
    function offsetLiquidation(uint _collAmount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoETHToken.sol";


interface IBorrowersRewardsPool  {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event BorrowersRewardsPoolborrowersoETHRewardsBalanceUpdated(uint _borrowersoETHRewards);
    event BorrowersRewardsPoolborrowersoETHRewardsBalanceUpdated_before(uint _borrowersoETHRewards);
    event borrowersoETHRewardsSent(address activePool, uint _amount);
    event BorrowersRewardsPooloETHBalanceUpdated(uint _OrumwithdrawalborrowersoETHRewards);
    event  ActivePoolAddressChanged(address _activePoolAddress);

    // --- Functions ---
    function sendborrowersoETHRewardsToActivePool(uint _amount) external;
    function receiveoETHBorrowersRewardsPool(uint new_coll) external;
    function getBorrowersoETHRewards() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IUSDCToken.sol";

interface ILendingPool {
    // Events
    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);
    event LendingPoolUSDCBalanceUpdated(uint _newBalance);
    event LendingPoolReceivedETH(uint value);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event sendUSDCtoBorrowerEvent(address _to,uint _amount);
    event USDCSent(address _to,uint _amount);
    event DepositSnapshotUpdated(address _depositor, uint _P, uint _G);
    event BufferRatioUpdated(uint _buffer, uint _staking);

    // Functions

    function provideToLendingPool(uint _amount) external;
    
    function decreaseLentAmount(uint _amount) external;

    function allowBorrow() external returns (bool);

    function withdrawFromLendingPool(uint _amount) external;

    function sendUSDCtoBorrower(address _to, uint _amount) external;

    function getDepositorOrumGain(address _depositor) external returns (uint);

    function getUSDCDeposits() external returns (uint);

    function getUtilisationRatio() external view returns (uint);

    function convertOUSDCToUSDC(uint _amount) external view returns (uint);

    function convertUSDCToOUSDC(uint _amount) external view returns (uint);

    function rewardsOffset(uint _rewards) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ICollateralPool {
    // --- Events ---
    event oETHTokenAddressChanged(address _oETHTokenAddress);
    event OETHTokenMintedTo(address _account, uint _amount);
    event oethSwappedToeth(address _from, address _to,uint _amount);
    event BufferRatioUpdated(uint _buffer, uint staking);

    // --- Functions ---
    function swapoETHtoETH(uint _amount) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


interface IGasPool  {
    // --- Events ---


    // --- Functions ---
    function sendToLiquidator(uint _amount, address _liquidator) external;

    function approveWhileCloseVault() external;

}