// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IBorrowerOps.sol";
import "IStabilityPool.sol";
import "IVaultManager.sol";
import "IOSDToken.sol";
import "ISortedVaults.sol";
import "ICommunityIssuance.sol";
import "OrumBase.sol";
import "OrumSafeMath128.sol";
import "Ownable.sol";
import "CheckContract.sol";

contract StabilityPool is OrumBase, Ownable, CheckContract, IStabilityPool {

    string constant public NAME = "StabilityPool";

    IBorrowerOps public borrowerOps;

    IVaultManager public vaultManager;

    IOSDToken public osdToken;
    

    // Needed to check if there are pending liquidations
    ISortedVaults public sortedVaults;
    ICommunityIssuance public communityIssuance;


    uint256 internal ROSE;  // deposited ether tracker

    // Tracker for OSD held in the pool. Changes when users deposit/withdraw, and when Vault debt is offset.
    uint256 internal totalOSDDeposits;

   // --- Data structures ---

    struct Snapshots {
        uint S;
        uint P;
        uint G;
        uint128 scale;
        uint128 epoch;
    }

    mapping (address => uint) public deposits;  // depositor address -> deposited amount
    mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct

    /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
    * after a series of liquidations have occurred, each of which cancel some OSD debt with the deposit.
    *
    * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
    * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
    */
    uint public P = DECIMAL_PRECISION;

    uint public constant SCALE_FACTOR = 1e9;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;

    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    /* ROSE Gain sum 'S': During its lifetime, each deposit d_t earns an ROSE gain of ( d_t * [S - S_t] )/P_t, where S_t
    * is the depositor's snapshot of S taken at the time t when the deposit was made.
    *
    * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
    *
    * - The inner mapping records the sum S at different scales
    * - The outer mapping records the (scale => sum) mappings, for different epochs.
    */
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToSum;
    /*
    * Similarly, the sum 'G' is used to calculate LQTY gains. During it's lifetime, each deposit d_t earns a LQTY gain of
    *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
    *
    *  LQTY reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
    *  In each case, the LQTY reward is issued (i.e. G is updated), before other state changes are made.
    */
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToG;
    // Error tracker for the error correction in the LQTY issuance calculation
    uint public lastOrumError;
    // Error trackers for the error correction in the offset calculation
    uint public lastROSEError_Offset;
    uint public lastOSDLossError_Offset;

    event TEST_error(uint _error);
    event TEST_all(uint _coll, uint _debt, uint _total);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _activePoolAddress,
        address _osdTokenAddress,
        address _sortedVaultsAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    )
        external
        override
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_vaultManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_osdTokenAddress);
        checkContract(_sortedVaultsAddress);
        checkContract(_priceFeedAddress);
        checkContract(_communityIssuanceAddress);

        borrowerOps = IBorrowerOps(_borrowerOpsAddress);
        vaultManager = IVaultManager(_vaultManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        osdToken = IOSDToken(_osdTokenAddress);
        sortedVaults = ISortedVaults(_sortedVaultsAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit OSDTokenAddressChanged(_osdTokenAddress);
        emit SortedVaultsAddressChanged(_sortedVaultsAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit CommunityIssuanceAddressChanged(_communityIssuanceAddress);

    }

    // --- Getters for public variables. Required by IPool interface ---

    function getROSE() external view override returns (uint) {
        return ROSE;
    }

    function getTotalOSDDeposits() external view override returns (uint) {
        return totalOSDDeposits;
    }

    // --- External Depositor Functions ---

    /*  provideToSP():
    *
    * - Tags the deposit with the provided front end tag param, if it's a new deposit
    * - Sends depositor's accumulated gains (ROSE) to depositor
    * - Increases deposit and takes new snapshots.
    */
    function provideToSP(uint _amount) external override {
        _requireNonZeroAmount(_amount);

        uint initialDeposit = deposits[msg.sender];

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);


        uint depositorROSEGain = getDepositorROSEGain(msg.sender);
        uint compoundedOSDDeposit = getCompoundedOSDDeposit(msg.sender);
        uint OSDLoss = initialDeposit - compoundedOSDDeposit; // Needed only for event log

        _payOutOrumGains(communityIssuanceCached, msg.sender);

        _sendOSDtoStabilityPool(msg.sender, _amount);

        uint newDeposit = compoundedOSDDeposit + _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit ROSEGainWithdrawn(msg.sender, depositorROSEGain, OSDLoss); // OSD Loss required for event log

        _sendROSEGainToDepositor(depositorROSEGain);
     }

    /*  withdrawFromSP():
    * - Sends all depositor's accumulated gains (ROSE) to depositor
    * - Decreases deposit and takes new snapshots.
    *
    * If _amount > userDeposit, the user withdraws all of their compounded deposit.
    */
    function withdrawFromSP(uint _amount) external override {
        if (_amount !=0) {_requireNoUnderCollateralizedVaults();}
        uint initialDeposit = deposits[msg.sender];
        _requireUserHasDeposit(initialDeposit);
        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);

        uint depositorROSEGain = getDepositorROSEGain(msg.sender);

        uint compoundedOSDDeposit = getCompoundedOSDDeposit(msg.sender);
        uint OSDtoWithdraw = OrumMath._min(_amount, compoundedOSDDeposit);
        uint OSDLoss = initialDeposit - compoundedOSDDeposit; // Needed only for event log

        _payOutOrumGains(communityIssuanceCached, msg.sender);

        _sendOSDToDepositor(msg.sender, OSDtoWithdraw);

        // Update deposit
        uint newDeposit = compoundedOSDDeposit - OSDtoWithdraw;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit ROSEGainWithdrawn(msg.sender, depositorROSEGain, OSDLoss);  // OSD Loss required for event log

        _sendROSEGainToDepositor(depositorROSEGain);
    }

    /* withdrawROSEGainToVault:
    * - Transfers the depositor's entire ROSE gain from the Stability Pool to the caller's vault
    * - Leaves their compounded deposit in the Stability Pool
    * - Updates snapshots for deposit */
    function withdrawROSEGainToVault(address _upperHint, address _lowerHint) external override {
        uint initialDeposit = deposits[msg.sender];
        _requireUserHasDeposit(initialDeposit);
        _requireUserHasVault(msg.sender);
        _requireUserHasROSEGain(msg.sender);

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);

        uint depositorROSEGain = getDepositorROSEGain(msg.sender);

        uint compoundedOSDDeposit = getCompoundedOSDDeposit(msg.sender);
        uint OSDLoss = initialDeposit - compoundedOSDDeposit; // Needed only for event log
        _payOutOrumGains(communityIssuanceCached, msg.sender);


        _updateDepositAndSnapshots(msg.sender, compoundedOSDDeposit);

        /* Emit events before transferring ROSE gain to Vault.
         This lets the event log make more sense (i.e. so it appears that first the ROSE gain is withdrawn
        and then it is deposited into the Vault, not the other way around). */
        emit ROSEGainWithdrawn(msg.sender, depositorROSEGain, OSDLoss);
        emit UserDepositChanged(msg.sender, compoundedOSDDeposit);

        ROSE -= depositorROSEGain;
        emit StabilityPoolROSEBalanceUpdated(ROSE);
        emit RoseSent(msg.sender, depositorROSEGain);

        borrowerOps.moveROSEGainToVault{ value: depositorROSEGain }(msg.sender, _upperHint, _lowerHint);
    }

    // --- LQTY issuance functions ---

    function _triggerOrumIssuance(ICommunityIssuance _communityIssuance) internal {
        uint orumIssuance = _communityIssuance.issueOrum();
       _updateG(orumIssuance);
    }

    function _updateG(uint _orumIssuance) internal {
        uint totalOSD = totalOSDDeposits; // cached to save an SLOAD
        /*
        * When total deposits is 0, G is not updated. In this case, the LQTY issued can not be obtained by later
        * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
        *
        */
        if (totalOSD == 0 || _orumIssuance == 0) {return;}

        uint orumPerUnitStaked;
        orumPerUnitStaked =_computeOrumPerUnitStaked(_orumIssuance, totalOSD);

        uint marginalOrumGain = orumPerUnitStaked * P;
        epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale] + marginalOrumGain;

        emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
    }

    function _computeOrumPerUnitStaked(uint _orumIssuance, uint _totalOSDDeposits) internal returns (uint) {
        /*  
        * Calculate the LQTY-per-unit staked.  Division uses a "feedback" error correction, to keep the 
        * cumulative error low in the running total G:
        *
        * 1) Form a numerator which compensates for the floor division error that occurred the last time this 
        * function was called.  
        * 2) Calculate "per-unit-staked" ratio.
        * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
        * 4) Store this error for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint orumNumerator = (_orumIssuance * DECIMAL_PRECISION) + lastOrumError;

        uint orumPerUnitStaked = (orumNumerator / _totalOSDDeposits);
        lastOrumError = orumNumerator - (orumPerUnitStaked * _totalOSDDeposits);

        return orumPerUnitStaked;
    }


    // --- Liquidation functions ---

    /*
    * Cancels out the specified debt against the OSD contained in the Stability Pool (as far as possible)
    * and transfers the Vault's ROSE collateral from ActivePool to StabilityPool.
    * Only called by liquidation functions in the VaultManager.
    */
    function offset(uint _debtToOffset, uint _collToAdd) external override {
        _requireCallerIsVaultManager();
        uint totalOSD = totalOSDDeposits; // cached to save an SLOAD
        if (totalOSD == 0 || _debtToOffset == 0) { return; }

        _triggerOrumIssuance(communityIssuance);

        (uint ROSEGainPerUnitStaked,
            uint OSDLossPerUnitStaked) = _computeRewardsPerUnitStaked(_collToAdd, _debtToOffset, totalOSD);

        _updateRewardSumAndProduct(ROSEGainPerUnitStaked, OSDLossPerUnitStaked);  // updates S and P

        _moveOffsetCollAndDebt(_collToAdd, _debtToOffset);
    }

    // --- Offset helper functions ---

    function _computeRewardsPerUnitStaked(
        uint _collToAdd,
        uint _debtToOffset,
        uint _totalOSDDeposits
    )
        internal
        returns (uint ROSEGainPerUnitStaked, uint OSDLossPerUnitStaked)
    {
        /*
        * Compute the OSD and ROSE rewards. Uses a "feedback" error correction, to keep
        * the cumulative error in the P and S state variables low:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this 
        * function was called.  
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint ROSENumerator = (_collToAdd * DECIMAL_PRECISION) + lastROSEError_Offset;
        assert(_debtToOffset <= _totalOSDDeposits);
        if (_debtToOffset == _totalOSDDeposits) {
            OSDLossPerUnitStaked = DECIMAL_PRECISION;  // When the Pool depletes to 0, so does each deposit 
            lastOSDLossError_Offset = 0;
        } else {
            uint OSDLossNumerator = (_debtToOffset * DECIMAL_PRECISION) - lastOSDLossError_Offset;
            /*
            * Add 1 to make error in quotient positive. We want "slightly too much" OSD loss,
            * which ensures the error in any given compoundedOSDDeposit favors the Stability Pool.
            */
            OSDLossPerUnitStaked = (OSDLossNumerator / _totalOSDDeposits) + 1;
            lastOSDLossError_Offset = (OSDLossPerUnitStaked *_totalOSDDeposits) - OSDLossNumerator;
        }

        ROSEGainPerUnitStaked = ROSENumerator / _totalOSDDeposits;

        lastROSEError_Offset = ROSENumerator - (ROSEGainPerUnitStaked* _totalOSDDeposits);

        return (ROSEGainPerUnitStaked, OSDLossPerUnitStaked);
    }

    // Update the Stability Pool reward sum S and product P
    function _updateRewardSumAndProduct(uint _ROSEGainPerUnitStaked, uint _OSDLossPerUnitStaked) internal {
        uint currentP = P;
        uint newP;

        assert(_OSDLossPerUnitStaked <= DECIMAL_PRECISION);
        /*
        * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool OSD in the liquidation.
        * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - OSDLossPerUnitStaked)
        */
        uint newProductFactor = uint(DECIMAL_PRECISION - _OSDLossPerUnitStaked);

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];

        /*
        * Calculate the new S first, before we update P.
        * The ROSE gain for any given depositor from a liquidation depends on the value of their deposit
        * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
        *
        * Since S corresponds to ROSE gain, and P to deposit loss, we update S first.
        */
        uint marginalROSEGain = _ROSEGainPerUnitStaked * currentP;
        uint newS = currentS + marginalROSEGain;
        epochToScaleToSum[currentEpochCached][currentScaleCached] = newS;
        emit S_Updated(newS, currentEpochCached, currentScaleCached);

        // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
        if (newProductFactor == 0) {
            currentEpoch = currentEpochCached + 1;
            emit EpochUpdated(currentEpoch);
            currentScale = 0;
            emit ScaleUpdated(currentScale);
            newP = DECIMAL_PRECISION;

        // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
        } else if (currentP * newProductFactor / DECIMAL_PRECISION < SCALE_FACTOR) {
            newP = (currentP * newProductFactor * SCALE_FACTOR) / DECIMAL_PRECISION; 
            currentScale = currentScaleCached + 1;
            emit ScaleUpdated(currentScale);
        } else {
            newP = currentP * newProductFactor / DECIMAL_PRECISION;
        }

        assert(newP > 0);
        P = newP;

        emit P_Updated(newP);
    }

    function _moveOffsetCollAndDebt(uint _collToAdd, uint _debtToOffset) internal {
        IActivePool activePoolCached = activePool;

        // Cancel the liquidated OSD debt with the OSD in the stability pool
        activePoolCached.decreaseOSDDebt(_debtToOffset);
        _decreaseOSD(_debtToOffset);

        // Burn the debt that was successfully offset
        osdToken.burn(address(this), _debtToOffset);

        activePoolCached.sendROSE(address(this), _collToAdd);
    }

    function _decreaseOSD(uint _amount) internal {
        uint newTotalOSDDeposits = totalOSDDeposits - _amount;
        totalOSDDeposits = newTotalOSDDeposits;
        emit StabilityPoolOSDBalanceUpdated(newTotalOSDDeposits);
    }

    // --- Reward calculator functions for depositor and front end ---

    /* Calculates the ROSE gain earned by the deposit since its last snapshots were taken.
    * Given by the formula:  E = d0 * (S - S(0))/P(0)
    * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorROSEGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];

        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint ROSEGain = _getROSEGainFromSnapshots(initialDeposit, snapshots);
        return ROSEGain;
    }

    function _getROSEGainFromSnapshots(uint initialDeposit, Snapshots memory snapshots) internal view returns (uint) {
        /*
        * Grab the sum 'S' from the epoch at which the stake was made. The ROSE gain may span up to one scale change.
        * If it does, the second portion of the ROSE gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint S_Snapshot = snapshots.S;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot] - S_Snapshot;
        uint secondPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint ROSEGain = ((initialDeposit* (firstPortion + secondPortion)) / P_Snapshot) / DECIMAL_PRECISION;

        return ROSEGain;
    }
    /*
    * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
    * Given by the formula:  LQTY = d0 * (G - G(0))/P(0)
    * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorOrumGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) {return 0;}

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint orumGain = _getOrumGainFromSnapshots(initialDeposit, snapshots);

        return orumGain;
    }

    function _getOrumGainFromSnapshots(uint initialStake, Snapshots memory snapshots) internal view returns (uint) {
       /*
        * Grab the sum 'G' from the epoch at which the stake was made. The LQTY gain may span up to one scale change.
        * If it does, the second portion of the LQTY gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint G_Snapshot = snapshots.G;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot] - G_Snapshot;
        uint secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint orumGain = (initialStake * (firstPortion + secondPortion)) / P_Snapshot / DECIMAL_PRECISION;

        return orumGain;
    }



    // --- Compounded deposit ---

    /*
    * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
    * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
    */
    function getCompoundedOSDDeposit(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint compoundedDeposit = _getCompoundedStakeFromSnapshots(initialDeposit, snapshots);
        return compoundedDeposit;
    }

    // Internal function, used to calculcate compounded deposits and compounded front end stakes.
    function _getCompoundedStakeFromSnapshots(
        uint initialStake,
        Snapshots memory snapshots
    )
        internal
        view
        returns (uint)
    {
        uint snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) { return 0; }

        uint compoundedStake;
        uint128 scaleDiff = currentScale - scaleSnapshot;

        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
        * account for it. If more than one scale change was made, then the stake has decreased by a factor of
        * at least 1e-9 -- so return 0.
        */
        if (scaleDiff == 0) {
            compoundedStake = initialStake * P / snapshot_P;
        } else if (scaleDiff == 1) {
            compoundedStake = ((initialStake *P)/snapshot_P) / SCALE_FACTOR;
        } else { // if scaleDiff >= 2
            compoundedStake = 0;
        }

        /*
        * If compounded deposit is less than a billionth of the initial deposit, return 0.
        *
        * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
        * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
        * than it's theoretical value.
        *
        * Thus it's unclear whether this line is still really needed.
        */
        if (compoundedStake < initialStake /1e9) {return 0;}

        return compoundedStake;
    }

    // --- Sender functions for OSD deposit, ROSE gains and LQTY gains ---

    // Transfer the OSD tokens from the user to the Stability Pool's address, and update its recorded OSD
    function _sendOSDtoStabilityPool(address _address, uint _amount) internal {
        osdToken.sendToPool(_address, address(this), _amount);
        uint newTotalOSDDeposits = totalOSDDeposits + _amount;
        totalOSDDeposits = newTotalOSDDeposits;
        emit StabilityPoolOSDBalanceUpdated(newTotalOSDDeposits);
    }

    function _sendROSEGainToDepositor(uint _amount) internal {
        if (_amount == 0) {return;}
        uint newROSE = ROSE - _amount;
        ROSE = newROSE;
        emit StabilityPoolROSEBalanceUpdated(newROSE);
        emit RoseSent(msg.sender, _amount);

        (bool success, ) = msg.sender.call{ value: _amount }("");
        require(success, "StabilityPool: sending ROSE failed");
    }

    // Send OSD to user and decrease OSD in Pool
    function _sendOSDToDepositor(address _depositor, uint OSDWithdrawal) internal {
        if (OSDWithdrawal == 0) {return;}

        osdToken.returnFromPool(address(this), _depositor, OSDWithdrawal);
        _decreaseOSD(OSDWithdrawal);
    }
    // --- Stability Pool Deposit Functionality ---

    function _updateDepositAndSnapshots(address _depositor, uint _newValue) internal {
        deposits[_depositor] = _newValue;

        if (_newValue == 0) {
            delete depositSnapshots[_depositor];
            emit DepositSnapshotUpdated(_depositor, 0, 0, 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentP = P;

        // Get S and G for the current epoch and current scale
        uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];
        uint currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P and sum S for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].S = currentS;
        depositSnapshots[_depositor].G = currentG;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(_depositor, currentP, currentS, currentG);
    }

    function _payOutOrumGains(ICommunityIssuance _communityIssuance, address _depositor) internal {
        // Pay out depositor's LQTY gain
        uint depositorOrumGain = getDepositorOrumGain(_depositor);
        _communityIssuance.sendOrum(_depositor, depositorOrumGain);
        emit OrumPaidToDepositor(_depositor, depositorOrumGain);
    }
    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require( msg.sender == address(activePool), "StabilityPool: Caller is not ActivePool");
    }

    function _requireCallerIsVaultManager() internal view {
        require(msg.sender == address(vaultManager), "StabilityPool: Caller is not VaultManager");
    }

    function _requireNoUnderCollateralizedVaults() internal view {
        uint price = priceFeed.fetchPrice();
        address lowestVault = sortedVaults.getLast();
        uint ICR = vaultManager.getCurrentICR(lowestVault, price);
        require(ICR >= MCR, "StabilityPool: Cannot withdraw while there are vaults with ICR < MCR");
    }

    function _requireUserHasDeposit(uint _initialDeposit) internal pure {
        require(_initialDeposit > 0, 'StabilityPool: User must have a non-zero deposit');
    }

     function _requireUserHasNoDeposit(address _address) internal view {
        uint initialDeposit = deposits[_address];
        require(initialDeposit == 0, 'StabilityPool: User must have no deposit');
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, 'StabilityPool: Amount must be non-zero');
    }

    function _requireUserHasVault(address _depositor) internal view {
        require(vaultManager.getVaultStatus(_depositor) == 1, "StabilityPool: caller must have an active vault to withdraw ROSEGain to");
    }

    function _requireUserHasROSEGain(address _depositor) internal view {
        uint ROSEGain = getDepositorROSEGain(_depositor);
        require(ROSEGain > 0, "StabilityPool: caller must have non-zero ROSE Gain");
    }
    function changeMCR(uint _newMCR) onlyOwner external {
        MCR = _newMCR;
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        ROSE += msg.value;
        emit StabilityPoolROSEBalanceUpdated(ROSE);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBorrowerOps {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OSDTokenAddressChanged(address _osdTokenAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);

    event VaultCreated(address indexed _borrower, uint arrayIndex);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event BorrowFeeInROSE(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToTreasury(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToOrumRevenue(address indexed _borrower, uint _borrowFee);

    // --- Functions ---
    function openVault(uint _maxFee, uint _debtAmount, address _upperHint, address _lowerHint) external payable;
    function addColl(address _upperHint, address _lowerHint) external payable;
    function moveROSEGainToVault(address _user, address _upperHint, address _lowerHint) external payable;
    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;
    function withdrawOSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;
    function repayOSD(uint _amount, address _upperHint, address _lowerHint) external;
    function closeVault() external;
    function claimCollateral() external;
    function getCompositeDebt(uint _debt) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/*
 * The Stability Pool holds OSD tokens deposited by Stability Pool depositors.
 *
 * When a Vault is liquidated, then depending on system conditions, some of its OSD debt gets offset with
 * OSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of OSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a OSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ROSE gain, as the ROSE collateral of the liquidated Vault is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total OSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ROSE gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 */
interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolROSEBalanceUpdated(uint _newBalance);
    event StabilityPoolOSDBalanceUpdated(uint _newBalance);

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event OSDTokenAddressChanged(address _newOSDTokenAddress);
    event SortedVaultsAddressChanged(address _newSortedVaultsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);

    event ROSEGainWithdrawn(address indexed _depositor, uint _ROSE, uint _OSDLoss);
    event OrumPaidToDepositor(address indexed _depositor, uint _orum);
    event RoseSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOpsAddress,
        address _VaultManagerAddress,
        address _activePoolAddress,
        address _osdTokenAddress,
        address _sortedVaultsAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    function provideToSP(uint _amount) external;

    function withdrawFromSP(uint _amount) external;

    function withdrawROSEGainToVault(address _upperHint, address _lowerHint) external;

    function offset(uint _debt, uint _coll) external;

    function getROSE() external view returns (uint);

    function getTotalOSDDeposits() external view returns (uint);

    function getDepositorROSEGain(address _depositor) external view returns (uint);

    function getDepositorOrumGain(address _depositor) external view returns (uint);

    function getCompoundedOSDDeposit(address _depositor) external view returns (uint);

    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ROSE received
     * receive() external payable;
     */
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IOrumBase.sol";


// Common interface for the Vault Manager.
interface IVaultManager is IOrumBase {
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event OSDTokenAddressChanged(address _newOSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _OSDGasCompensation);
    event Test_LiquidationROSEFee(uint _ROSEFee);
    event Redemption(uint _attemptedOSDAmount, uint _actualOSDAmount, uint _ROSESent, uint _ROSEFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ROSE, uint _L_OSDDebt);
    event VaultSnapshotsUpdated(uint _L_ROSE, uint _L_OSDDebt);
    event VaultIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---
    function getVaultOwnersCount() external view returns (uint);

    function getVaultFromVaultOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateVaults(uint _n) external;

    function batchLiquidateVaults(address[] calldata _VaultArray) external;

    function redeemCollateral(
        uint _OSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateVaultRewardSnapshots(address _borrower) external;

    function addVaultOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingROSEReward(address _borrower) external view returns (uint);

    function getPendingOSDDebtReward(address _borrower) external view returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingOSDDebtReward, 
        uint pendingROSEReward
    );

    function closeVault(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ROSEDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint OSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _OSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getVaultStatus(address _borrower) external view returns (uint);
    
    function getVaultStake(address _borrower) external view returns (uint);

    function getVaultDebt(address _borrower) external view returns (uint);

    function getVaultColl(address _borrower) external view returns (uint);

    function setVaultStatus(address _borrower, uint num) external;

    function increaseVaultColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseVaultColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseVaultDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
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

interface IOSDToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);

    event OSDTokenBalanceUpdated(address _user, uint _amount);

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

interface ICommunityIssuance { 
    
    // --- Events ---
    
    event OrumTokenAddressSet(address _orumTokenAddress);
    event StabilityPoolAddressSet(address _stabilityPoolAddress);
    event TotalOrumIssuedUpdated(uint _totalOrumIssued);

    // --- Functions ---

    function setAddresses(address _orumTokenAddress, address _stabilityPoolAddress) external;

    function issueOrum() external returns (uint);

    function sendOrum(address _account, uint _orumAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "OrumMath.sol";
import "IActivePool.sol";
import "IDefaultPool.sol";
import "IPriceFeed.sol";
import "IOrumBase.sol";


/* 
* Base contract for VaultManager, BorrowerOps and StabilityPool. Contains global system constants and
* common functions. 
*/
contract OrumBase is IOrumBase {
    using SafeMath for uint;

    uint constant public DECIMAL_PRECISION = 1e18;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual Vaults
    uint public MCR = 1350000000000000000; // 135%;

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint public CCR = 1750000000000000000; // 175%

    // Amount of OSD to be locked in gas pool on opening vaults
    uint public OSD_GAS_COMPENSATION = 10e18;

    // Minimum amount of net OSD debt a vault must have
    uint public MIN_NET_DEBT = 50e18;

    uint public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 10000 * 75 ; // 0.75%

    uint public STABILITY_POOL_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * 20; // 20%
    


    address public contractOwner;

    IActivePool public activePool;

    IDefaultPool public defaultPool;

    IPriceFeed public override priceFeed;

    constructor() {
        contractOwner = msg.sender;
    }
    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a vault, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal view  returns (uint) {
        return _debt.add(OSD_GAS_COMPENSATION);
    }
    function _getNetDebt(uint _debt) internal view returns (uint) {
        return _debt.sub(OSD_GAS_COMPENSATION);
    }
    // Return the amount of ROSE to be drawn from a vault's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal view returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }
    // // change system base values
    // function changeMCR(uint _newMCR) external {
    //     _requireCallerIsOwner();
    //     MCR = _newMCR;
    // }
    // function changeCCR(uint _newCCR) external {
    //     _requireCallerIsOwner();
    //     CCR = _newCCR;
    // }
    // function changeLiquidationReward(uint8 _PERCENT_DIVISOR) external {
    //     _requireCallerIsOwner();
    //     PERCENT_DIVISOR = _PERCENT_DIVISOR;
    // }
    // function changeTreasuryFeeShare(uint8 _percent) external {
    //     _requireCallerIsOwner();
    //     TREASURY_FEE_DIVISOR = DECIMAL_PRECISION / 100 * _percent;
    // }
    // function changeSPLiquidationProfit(uint8 _percent) external {
    //     _requireCallerIsOwner();
    //     STABILITY_POOL_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * _percent;
    // }
    // function changeBorrowingFee(uint8 _newBorrowFee) external {
    //     _requireCallerIsOwner();
    //     BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * _newBorrowFee;
    // }
    // function changeMinNetDebt(uint _newMinDebt) external {
    //     _requireCallerIsOwner();
    //     MIN_NET_DEBT = _newMinDebt;
    // }
    // function changeGasCompensation(uint _OSDGasCompensation) external {
    //     _requireCallerIsOwner();
    //     OSD_GAS_COMPENSATION = _OSDGasCompensation;
    // }
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getROSE();
        uint liquidatedColl = defaultPool.getROSE();

        return activeColl.add(liquidatedColl);
    }

    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getOSDDebt();
        uint closedDebt = defaultPool.getOSDDebt();

        return activeDebt.add(closedDebt);
    }
    function _getSPLiquidationProfit(uint _amount) internal view returns (uint){
        return _amount.mul(STABILITY_POOL_LIQUIDATION_PROFIT).div(DECIMAL_PRECISION);
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

// Based on Liquity's OrumMath library: https://github.com/liquity/dev/blob/main/packages/contracts/contracts/Dependencies/OrumMath.sol

library OrumMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
    *
    * - Making it "too high" could lead to overflows.
    * - Making it "too low" could lead to an ICR equal to zero, due to truncation from Solidity floor division.
    *
    * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ROSE,
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
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt);

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

import "IPool.sol";


interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolOSDDebtUpdated(uint _OSDDebt);
    event ActivePoolROSEBalanceUpdated(uint _ROSE);

    // --- Functions ---
    function sendROSE(address _account, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event ROSEBalanceUpdated(uint _newBalance);
    event OSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event RoseSent(address _to, uint _amount);

    // --- Functions ---
    
    function getROSE() external view returns (uint);

    function getOSDDebt() external view returns (uint);

    function increaseOSDDebt(uint _amount) external;

    function decreaseOSDDebt(uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IPool.sol";


interface IDefaultPool is IPool {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event DefaultPoolOSDDebtUpdated(uint _OSDDebt);
    event DefaultPoolROSEBalanceUpdated(uint _ROSE);

    // --- Functions ---
    function sendROSEToActivePool(uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// uint128 addition and subtraction, with overflow protection.

library OrumSafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "OrumSafeMath128: addition overflow");

        return c;
    }
   
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "OrumSafeMath128: subtraction overflow");
        uint128 c = a - b;

        return c;
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