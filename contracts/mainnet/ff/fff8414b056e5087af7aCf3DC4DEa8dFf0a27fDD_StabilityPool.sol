// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/IARTHValuecoin.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/ICommunityIssuance.sol";
import "./Dependencies/LiquityBase.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/LiquitySafeMath128.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";

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
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and ETH gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and ETH gain, we simply update two state variables:
 * a product P, and a sum S.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated ETH gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Stability Pool, they get a snapshot of the latest P and S: P_t and S_t, respectively.
 *
 * The formula for a depositor's accumulated ETH gain is derived here:
 * https://github.com/liquity/dev/blob/main/packages/contracts/mathProofs/Scalable%20Compounding%20Stability%20Pool%20Deposits.pdf
 *
 * For a given deposit d_t, the ratio P/P_t tells us the factor by which a deposit has decreased since it joined the Stability Pool,
 * and the term d_t * (S - S_t)/P_t gives us the deposit's total accumulated ETH gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding ETH gain
 * can be calculated using the initial deposit, the depositor’s snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated ETH gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range ]0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range ]0,1[.
 * Unfortunately, Solidity floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Pool (and thus each multiply P by a very small number in range ]0,1[ ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Pool hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0 by Solidity),
 * we first multiply P by 1e9, and increment a currentScale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the
 * order of 1e-9.
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Stability Pool, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Stability Pool is emptied by a liquidation, we reset P = 1 and currentScale = 0, and increment the currentEpoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the currentEpoch and the currentScale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by d_t * P/P_t.
 * If it spans one scale change, it is given by d_t * P/(P_t * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion ARTH has depleted to < 1 ARTH).
 *
 *
 *  --- TRACKING DEPOSITOR'S ETH GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated ETH gain, during the epoch in which the deposit was non-zero and earned ETH.
 *
 * We calculate the depositor's accumulated ETH gain for the scale at which they made the deposit, using the ETH gain formula:
 * e_1 = d_t * (S - S_t) / P_t
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * e_2 = d_t * S / (P_t * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (e_1 + e_2) captures the depositor's total accumulated ETH gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 * --- UPDATING P WHEN A LIQUIDATION OCCURS ---
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
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
 *
 * We use the same mathematical product-sum approach to track MAHA gains for depositors, where 'G' is the sum corresponding to MAHA gains.
 * The product P (and snapshot P_t) is re-used, as the ratio P/P_t tracks a deposit's depletion due to liquidations.
 *
 */
contract StabilityPool is LiquityBase, Ownable, CheckContract, IStabilityPool {
    using LiquitySafeMath128 for uint128;
    using SafeMath for uint256;

    string public constant NAME = "StabilityPool";

    IBorrowerOperations public borrowerOperations;

    ITroveManager public troveManager;

    IARTHValuecoin public arthToken;

    // Needed to check if there are pending liquidations
    ISortedTroves public sortedTroves;

    ICommunityIssuance public communityIssuance;

    uint256 internal ETH; // deposited ether tracker

    // Tracker for ARTH held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
    uint256 internal totalARTHDeposits;

    // --- Data structures ---

    struct FrontEnd {
        uint256 kickbackRate;
        bool registered;
    }

    struct Deposit {
        uint256 initialValue;
        address frontEndTag;
    }

    struct Snapshots {
        uint256 S;
        uint256 P;
        uint256 G;
        uint128 scale;
        uint128 epoch;
    }

    mapping(address => Deposit) public deposits; // depositor address -> Deposit struct
    mapping(address => Snapshots) public depositSnapshots; // depositor address -> snapshots struct

    mapping(address => FrontEnd) public frontEnds; // front end address -> FrontEnd struct
    mapping(address => uint256) public frontEndStakes; // front end address -> last recorded total deposits, tagged with that front end
    mapping(address => Snapshots) public frontEndSnapshots; // front end address -> snapshots struct

    /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
     * after a series of liquidations have occurred, each of which cancel some ARTH debt with the deposit.
     *
     * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
     * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
     */
    uint256 public P = DECIMAL_PRECISION;

    uint256 public constant SCALE_FACTOR = 1e9;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;

    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    /* ETH Gain sum 'S': During its lifetime, each deposit d_t earns an ETH gain of ( d_t * [S - S_t] )/P_t, where S_t
     * is the depositor's snapshot of S taken at the time t when the deposit was made.
     *
     * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
     *
     * - The inner mapping records the sum S at different scales
     * - The outer mapping records the (scale => sum) mappings, for different epochs.
     */
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToSum;

    /*
     * Similarly, the sum 'G' is used to calculate MAHA gains. During it's lifetime, each deposit d_t earns a MAHA gain of
     *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
     *
     *  MAHA reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
     *  In each case, the MAHA reward is issued (i.e. G is updated), before other state changes are made.
     */
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

    // Error tracker for the error correction in the MAHA issuance calculation
    uint256 public lastMAHAError;

    // Error trackers for the error correction in the offset calculation
    uint256 public lastETHError_Offset;
    uint256 public lastARTHLossError_Offset;

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _arthTokenAddress,
        address _sortedTrovesAddress,
        address _governanceAddress,
        address _communityIssuanceAddress
    ) external override onlyOwner {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_arthTokenAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_governanceAddress);
        checkContract(_communityIssuanceAddress);

        borrowerOperations = IBorrowerOperations(_borrowerOperationsAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        arthToken = IARTHValuecoin(_arthTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        governance = IGovernance(_governanceAddress);
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit ARTHTokenAddressChanged(_arthTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit GovernanceAddressChanged(_governanceAddress);
        emit CommunityIssuanceAddressChanged(_communityIssuanceAddress);

        // _renounceOwnership(); // renounce ownership after migration is done
    }

    // --- Getters for public variables. Required by IPool interface ---

    function getETH() external view override returns (uint256) {
        return ETH;
    }

    function getTotalARTHDeposits() external view override returns (uint256) {
        return totalARTHDeposits;
    }

    // --- External Depositor Functions ---

    /*  provideToSP():
     *
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (MAHA, ETH) to depositor
     * - Sends the tagged front end's accumulated MAHA gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external override {
        _provideToSP(msg.sender, msg.sender, _amount, _frontEndTag);
    }

    // provide ARTH in return for
    function provideToSPFor(
        address _who,
        uint256 _amount,
        address _frontEndTag
    ) external onlyOwner {
        _provideToSP(_who, msg.sender, _amount, _frontEndTag);
    }

    function _provideToSP(
        address _who,
        address _arthFrom,
        uint256 _amount,
        address _frontEndTag
    ) internal {
        _requireFrontEndIsRegisteredOrZero(_frontEndTag);
        _requireFrontEndNotRegistered(_who);
        _requireNonZeroAmount(_amount);

        uint256 initialDeposit = deposits[_who].initialValue;

        ICommunityIssuance communityIssuanceCached = communityIssuance;
        _triggerMAHAIssuance(communityIssuanceCached);

        if (initialDeposit == 0) _setFrontEndTag(_who, _frontEndTag);
        uint256 depositorETHGain = getDepositorETHGain(_who);
        uint256 compoundedARTHDeposit = getCompoundedARTHDeposit(_who);
        uint256 ARTHLoss = initialDeposit.sub(compoundedARTHDeposit); // Needed only for event log

        // First pay out any MAHA gains
        address frontEnd = deposits[_who].frontEndTag;
        _payOutMAHAGains(communityIssuanceCached, _who, frontEnd);

        // Update front end stake
        uint256 compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint256 newFrontEndStake = compoundedFrontEndStake.add(_amount);
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, _who);

        _sendARTHtoStabilityPool(_arthFrom, _amount);

        uint256 newDeposit = compoundedARTHDeposit.add(_amount);
        _updateDepositAndSnapshots(_who, newDeposit);
        emit UserDepositChanged(_who, newDeposit);

        emit ETHGainWithdrawn(_who, depositorETHGain, ARTHLoss); // ARTH Loss required for event log

        _sendETHGainToDepositor(depositorETHGain);
    }

    /*  withdrawFromSP():
     *
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (MAHA, ETH) to depositor
     * - Sends the tagged front end's accumulated MAHA gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external override {
        if (_amount != 0) {
            _requireNoUnderCollateralizedTroves();
        }
        uint256 initialDeposit = deposits[msg.sender].initialValue;
        _requireUserHasDeposit(initialDeposit);

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerMAHAIssuance(communityIssuanceCached);

        uint256 depositorETHGain = getDepositorETHGain(msg.sender);

        uint256 compoundedARTHDeposit = getCompoundedARTHDeposit(msg.sender);
        uint256 ARTHtoWithdraw = LiquityMath._min(_amount, compoundedARTHDeposit);
        uint256 ARTHLoss = initialDeposit.sub(compoundedARTHDeposit); // Needed only for event log

        // First pay out any MAHA gains
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutMAHAGains(communityIssuanceCached, msg.sender, frontEnd);

        // Update front end stake
        uint256 compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint256 newFrontEndStake = compoundedFrontEndStake.sub(ARTHtoWithdraw);
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);

        _sendARTHToDepositor(msg.sender, ARTHtoWithdraw);

        // Update deposit
        uint256 newDeposit = compoundedARTHDeposit.sub(ARTHtoWithdraw);
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit ETHGainWithdrawn(msg.sender, depositorETHGain, ARTHLoss); // ARTH Loss required for event log
        _sendETHGainToDepositor(depositorETHGain);
    }

    /* withdrawETHGainToTrove:
     * - Triggers a MAHA issuance, based on time passed since the last issuance. The MAHA issuance is shared between *all* depositors and front ends
     * - Sends all depositor's MAHA gain to  depositor
     * - Sends all tagged front end's MAHA gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external override {
        uint256 initialDeposit = deposits[msg.sender].initialValue;
        _requireUserHasDeposit(initialDeposit);
        _requireUserHasTrove(msg.sender);
        _requireUserHasETHGain(msg.sender);

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerMAHAIssuance(communityIssuanceCached);

        uint256 depositorETHGain = getDepositorETHGain(msg.sender);

        uint256 compoundedARTHDeposit = getCompoundedARTHDeposit(msg.sender);
        uint256 ARTHLoss = initialDeposit.sub(compoundedARTHDeposit); // Needed only for event log

        // First pay out any MAHA gains
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutMAHAGains(communityIssuanceCached, msg.sender, frontEnd);

        // Update front end stake
        uint256 compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint256 newFrontEndStake = compoundedFrontEndStake;
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);

        _updateDepositAndSnapshots(msg.sender, compoundedARTHDeposit);

        /* Emit events before transferring ETH gain to Trove.
         This lets the event log make more sense (i.e. so it appears that first the ETH gain is withdrawn
        and then it is deposited into the Trove, not the other way around). */
        emit ETHGainWithdrawn(msg.sender, depositorETHGain, ARTHLoss);
        emit UserDepositChanged(msg.sender, compoundedARTHDeposit);

        ETH = ETH.sub(depositorETHGain);
        emit StabilityPoolETHBalanceUpdated(ETH);
        emit EtherSent(msg.sender, depositorETHGain);

        borrowerOperations.moveETHGainToTrove{value: depositorETHGain}(
            msg.sender,
            _upperHint,
            _lowerHint
        );
    }

    // --- MAHA issuance functions ---

    function _triggerMAHAIssuance(ICommunityIssuance _communityIssuance) internal {
        uint256 MAHAIssuance = _communityIssuance.issueMAHA();
        _updateG(MAHAIssuance);
    }

    function _updateG(uint256 _MAHAIssuance) internal {
        uint256 totalARTH = totalARTHDeposits; // cached to save an SLOAD
        /*
         * When total deposits is 0, G is not updated. In this case, the MAHA issued can not be obtained by later
         * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
         *
         */
        if (totalARTH == 0 || _MAHAIssuance == 0) {
            return;
        }

        uint256 MAHAPerUnitStaked;
        MAHAPerUnitStaked = _computeMAHAPerUnitStaked(_MAHAIssuance, totalARTH);

        uint256 marginalMAHAGain = MAHAPerUnitStaked.mul(P);
        epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale]
            .add(marginalMAHAGain);

        emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
    }

    function _computeMAHAPerUnitStaked(uint256 _MAHAIssuance, uint256 _totalARTHDeposits)
        internal
        returns (uint256)
    {
        /*
         * Calculate the MAHA-per-unit staked.  Division uses a "feedback" error correction, to keep the
         * cumulative error low in the running total G:
         *
         * 1) Form a numerator which compensates for the floor division error that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratio.
         * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
         * 4) Store this error for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 MAHANumerator = _MAHAIssuance.mul(DECIMAL_PRECISION).add(lastMAHAError);

        uint256 MAHAPerUnitStaked = MAHANumerator.div(_totalARTHDeposits);
        lastMAHAError = MAHANumerator.sub(MAHAPerUnitStaked.mul(_totalARTHDeposits));

        return MAHAPerUnitStaked;
    }

    // --- Liquidation functions ---

    /*
     * Cancels out the specified debt against the ARTH contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debtToOffset, uint256 _collToAdd) external override {
        _requireCallerIsTroveManager();
        uint256 totalARTH = totalARTHDeposits; // cached to save an SLOAD
        if (totalARTH == 0 || _debtToOffset == 0) {
            return;
        }

        _triggerMAHAIssuance(communityIssuance);

        (uint256 ETHGainPerUnitStaked, uint256 ARTHLossPerUnitStaked) = _computeRewardsPerUnitStaked(
            _collToAdd,
            _debtToOffset,
            totalARTH
        );

        _updateRewardSumAndProduct(ETHGainPerUnitStaked, ARTHLossPerUnitStaked); // updates S and P
        _moveOffsetCollAndDebt(_collToAdd, _debtToOffset);
    }

    // --- Offset helper functions ---

    function _computeRewardsPerUnitStaked(
        uint256 _collToAdd,
        uint256 _debtToOffset,
        uint256 _totalARTHDeposits
    ) internal returns (uint256 ETHGainPerUnitStaked, uint256 ARTHLossPerUnitStaked) {
        /*
         * Compute the ARTH and ETH rewards. Uses a "feedback" error correction, to keep
         * the cumulative error in the P and S state variables low:
         *
         * 1) Form numerators which compensate for the floor division errors that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratios.
         * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
         * 4) Store these errors for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 ETHNumerator = _collToAdd.mul(DECIMAL_PRECISION).add(lastETHError_Offset);

        assert(_debtToOffset <= _totalARTHDeposits);
        if (_debtToOffset == _totalARTHDeposits) {
            ARTHLossPerUnitStaked = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
            lastARTHLossError_Offset = 0;
        } else {
            uint256 ARTHLossNumerator = _debtToOffset.mul(DECIMAL_PRECISION).sub(
                lastARTHLossError_Offset
            );
            /*
             * Add 1 to make error in quotient positive. We want "slightly too much" ARTH loss,
             * which ensures the error in any given compoundedARTHDeposit favors the Stability Pool.
             */
            ARTHLossPerUnitStaked = (ARTHLossNumerator.div(_totalARTHDeposits)).add(1);
            lastARTHLossError_Offset = (ARTHLossPerUnitStaked.mul(_totalARTHDeposits)).sub(
                ARTHLossNumerator
            );
        }

        ETHGainPerUnitStaked = ETHNumerator.div(_totalARTHDeposits);
        lastETHError_Offset = ETHNumerator.sub(ETHGainPerUnitStaked.mul(_totalARTHDeposits));

        return (ETHGainPerUnitStaked, ARTHLossPerUnitStaked);
    }

    // Update the Stability Pool reward sum S and product P
    function _updateRewardSumAndProduct(
        uint256 _ETHGainPerUnitStaked,
        uint256 _ARTHLossPerUnitStaked
    ) internal {
        uint256 currentP = P;
        uint256 newP;

        assert(_ARTHLossPerUnitStaked <= DECIMAL_PRECISION);
        /*
         * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool ARTH in the liquidation.
         * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - ARTHLossPerUnitStaked)
         */
        uint256 newProductFactor = uint256(DECIMAL_PRECISION).sub(_ARTHLossPerUnitStaked);

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];

        /*
         * Calculate the new S first, before we update P.
         * The ETH gain for any given depositor from a liquidation depends on the value of their deposit
         * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
         *
         * Since S corresponds to ETH gain, and P to deposit loss, we update S first.
         */
        uint256 marginalETHGain = _ETHGainPerUnitStaked.mul(currentP);
        uint256 newS = currentS.add(marginalETHGain);
        epochToScaleToSum[currentEpochCached][currentScaleCached] = newS;
        emit S_Updated(newS, currentEpochCached, currentScaleCached);

        // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
        if (newProductFactor == 0) {
            currentEpoch = currentEpochCached.add(1);
            emit EpochUpdated(currentEpoch);
            currentScale = 0;
            emit ScaleUpdated(currentScale);
            newP = DECIMAL_PRECISION;

            // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
        } else if (currentP.mul(newProductFactor).div(DECIMAL_PRECISION) < SCALE_FACTOR) {
            newP = currentP.mul(newProductFactor).mul(SCALE_FACTOR).div(DECIMAL_PRECISION);
            currentScale = currentScaleCached.add(1);
            emit ScaleUpdated(currentScale);
        } else {
            newP = currentP.mul(newProductFactor).div(DECIMAL_PRECISION);
        }

        assert(newP > 0);
        P = newP;

        emit P_Updated(newP);
    }

    function _moveOffsetCollAndDebt(uint256 _collToAdd, uint256 _debtToOffset) internal {
        IActivePool activePoolCached = activePool;

        // Cancel the liquidated ARTH debt with the ARTH in the stability pool
        activePoolCached.decreaseARTHDebt(_debtToOffset);
        _decreaseARTH(_debtToOffset);

        // Burn the debt that was successfully offset
        arthToken.burn(address(this), _debtToOffset);

        activePoolCached.sendETH(address(this), _collToAdd);
    }

    function _decreaseARTH(uint256 _amount) internal {
        uint256 newTotalARTHDeposits = totalARTHDeposits.sub(_amount);
        totalARTHDeposits = newTotalARTHDeposits;
        emit StabilityPoolARTHBalanceUpdated(newTotalARTHDeposits);
    }

    // --- Reward calculator functions for depositor and front end ---

    /* Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     * Given by the formula:  E = d0 * (S - S(0))/P(0)
     * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
     * d0 is the last recorded deposit value.
     */
    function getDepositorETHGain(address _depositor) public view override returns (uint256) {
        uint256 initialDeposit = deposits[_depositor].initialValue;

        if (initialDeposit == 0) {
            return 0;
        }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint256 ETHGain = _getETHGainFromSnapshots(initialDeposit, snapshots);
        return ETHGain;
    }

    function _getETHGainFromSnapshots(uint256 initialDeposit, Snapshots memory snapshots)
        internal
        view
        returns (uint256)
    {
        /*
         * Grab the sum 'S' from the epoch at which the stake was made. The ETH gain may span up to one scale change.
         * If it does, the second portion of the ETH gain is scaled by 1e9.
         * If the gain spans no scale change, the second portion will be 0.
         */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint256 S_Snapshot = snapshots.S;
        uint256 P_Snapshot = snapshots.P;

        uint256 firstPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot].sub(S_Snapshot);
        uint256 secondPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot.add(1)].div(
            SCALE_FACTOR
        );

        uint256 ETHGain = initialDeposit.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(
            DECIMAL_PRECISION
        );

        return ETHGain;
    }

    /*
     * Calculate the MAHA gain earned by a deposit since its last snapshots were taken.
     * Given by the formula:  MAHA = d0 * (G - G(0))/P(0)
     * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
     * d0 is the last recorded deposit value.
     */
    function getDepositorMAHAGain(address _depositor) public view override returns (uint256) {
        uint256 initialDeposit = deposits[_depositor].initialValue;
        if (initialDeposit == 0) {
            return 0;
        }

        address frontEndTag = deposits[_depositor].frontEndTag;

        /*
         * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
         * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
         * which they made their deposit.
         */
        uint256 kickbackRate = frontEndTag == address(0)
            ? DECIMAL_PRECISION
            : frontEnds[frontEndTag].kickbackRate;

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint256 MAHAGain = kickbackRate
            .mul(_getMAHAGainFromSnapshots(initialDeposit, snapshots))
            .div(DECIMAL_PRECISION);

        return MAHAGain;
    }

    /*
     * Return the MAHA gain earned by the front end. Given by the formula:  E = D0 * (G - G(0))/P(0)
     * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
     *
     * D0 is the last recorded value of the front end's total tagged deposits.
     */
    function getFrontEndMAHAGain(address _frontEnd) public view override returns (uint256) {
        uint256 frontEndStake = frontEndStakes[_frontEnd];
        if (frontEndStake == 0) {
            return 0;
        }

        uint256 kickbackRate = frontEnds[_frontEnd].kickbackRate;
        uint256 frontEndShare = uint256(DECIMAL_PRECISION).sub(kickbackRate);

        Snapshots memory snapshots = frontEndSnapshots[_frontEnd];

        uint256 MAHAGain = frontEndShare
            .mul(_getMAHAGainFromSnapshots(frontEndStake, snapshots))
            .div(DECIMAL_PRECISION);
        return MAHAGain;
    }

    function _getMAHAGainFromSnapshots(uint256 initialStake, Snapshots memory snapshots)
        internal
        view
        returns (uint256)
    {
        /*
         * Grab the sum 'G' from the epoch at which the stake was made. The MAHA gain may span up to one scale change.
         * If it does, the second portion of the MAHA gain is scaled by 1e9.
         * If the gain spans no scale change, the second portion will be 0.
         */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint256 G_Snapshot = snapshots.G;
        uint256 P_Snapshot = snapshots.P;

        uint256 firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot].sub(G_Snapshot);
        uint256 secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot.add(1)].div(
            SCALE_FACTOR
        );

        uint256 MAHAGain = initialStake.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(
            DECIMAL_PRECISION
        );

        return MAHAGain;
    }

    // --- Compounded deposit and compounded front end stake ---

    /*
     * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
     * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
     */
    function getCompoundedARTHDeposit(address _depositor) public view override returns (uint256) {
        uint256 initialDeposit = deposits[_depositor].initialValue;
        if (initialDeposit == 0) {
            return 0;
        }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint256 compoundedDeposit = _getCompoundedStakeFromSnapshots(initialDeposit, snapshots);
        return compoundedDeposit;
    }

    /*
     * Return the front end's compounded stake. Given by the formula:  D = D0 * P/P(0)
     * where P(0) is the depositor's snapshot of the product P, taken at the last time
     * when one of the front end's tagged deposits updated their deposit.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) public view override returns (uint256) {
        uint256 frontEndStake = frontEndStakes[_frontEnd];
        if (frontEndStake == 0) {
            return 0;
        }

        Snapshots memory snapshots = frontEndSnapshots[_frontEnd];

        uint256 compoundedFrontEndStake = _getCompoundedStakeFromSnapshots(frontEndStake, snapshots);
        return compoundedFrontEndStake;
    }

    // Internal function, used to calculcate compounded deposits and compounded front end stakes.
    function _getCompoundedStakeFromSnapshots(uint256 initialStake, Snapshots memory snapshots)
        internal
        view
        returns (uint256)
    {
        uint256 snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) {
            return 0;
        }

        uint256 compoundedStake;
        uint128 scaleDiff = currentScale.sub(scaleSnapshot);

        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
         * account for it. If more than one scale change was made, then the stake has decreased by a factor of
         * at least 1e-9 -- so return 0.
         */
        if (scaleDiff == 0) {
            compoundedStake = initialStake.mul(P).div(snapshot_P);
        } else if (scaleDiff == 1) {
            compoundedStake = initialStake.mul(P).div(snapshot_P).div(SCALE_FACTOR);
        } else {
            // if scaleDiff >= 2
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
        if (compoundedStake < initialStake.div(1e9)) {
            return 0;
        }

        return compoundedStake;
    }

    // --- Sender functions for ARTH deposit, ETH gains and MAHA gains ---

    // Transfer the ARTH tokens from the user to the Stability Pool's address, and update its recorded ARTH
    function _sendARTHtoStabilityPool(address _address, uint256 _amount) internal {
        arthToken.sendToPool(_address, address(this), _amount);
        uint256 newTotalARTHDeposits = totalARTHDeposits.add(_amount);
        totalARTHDeposits = newTotalARTHDeposits;
        emit StabilityPoolARTHBalanceUpdated(newTotalARTHDeposits);
    }

    function _sendETHGainToDepositor(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        uint256 newETH = ETH.sub(_amount);
        ETH = newETH;
        emit StabilityPoolETHBalanceUpdated(newETH);
        emit EtherSent(msg.sender, _amount);

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "StabilityPool: sending ETH failed");
    }

    // Send ARTH to user and decrease ARTH in Pool
    function _sendARTHToDepositor(address _depositor, uint256 ARTHWithdrawal) internal {
        if (ARTHWithdrawal == 0) {
            return;
        }

        arthToken.returnFromPool(address(this), _depositor, ARTHWithdrawal);
        _decreaseARTH(ARTHWithdrawal);
    }

    // --- External Front End functions ---

    // Front end makes a one-time selection of kickback rate upon registering
    function registerFrontEnd(uint256 _kickbackRate) external override {
        _requireFrontEndNotRegistered(msg.sender);
        _requireUserHasNoDeposit(msg.sender);
        _requireValidKickbackRate(_kickbackRate);

        frontEnds[msg.sender].kickbackRate = _kickbackRate;
        frontEnds[msg.sender].registered = true;

        emit FrontEndRegistered(msg.sender, _kickbackRate);
    }

    // --- Stability Pool Deposit Functionality ---

    function _setFrontEndTag(address _depositor, address _frontEndTag) internal {
        deposits[_depositor].frontEndTag = _frontEndTag;
        emit FrontEndTagSet(_depositor, _frontEndTag);
    }

    function _updateDepositAndSnapshots(address _depositor, uint256 _newValue) internal {
        deposits[_depositor].initialValue = _newValue;

        if (_newValue == 0) {
            delete deposits[_depositor].frontEndTag;
            delete depositSnapshots[_depositor];
            emit DepositSnapshotUpdated(_depositor, 0, 0, 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentP = P;

        // Get S and G for the current epoch and current scale
        uint256 currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];
        uint256 currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P, sum S, and sum G, for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].S = currentS;
        depositSnapshots[_depositor].G = currentG;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(_depositor, currentP, currentS, currentG);
    }

    function _updateFrontEndStakeAndSnapshots(address _frontEnd, uint256 _newValue) internal {
        frontEndStakes[_frontEnd] = _newValue;

        if (_newValue == 0) {
            delete frontEndSnapshots[_frontEnd];
            emit FrontEndSnapshotUpdated(_frontEnd, 0, 0);
            return;
        }

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentP = P;

        // Get G for the current epoch and current scale
        uint256 currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P and sum G for the front end
        frontEndSnapshots[_frontEnd].P = currentP;
        frontEndSnapshots[_frontEnd].G = currentG;
        frontEndSnapshots[_frontEnd].scale = currentScaleCached;
        frontEndSnapshots[_frontEnd].epoch = currentEpochCached;

        emit FrontEndSnapshotUpdated(_frontEnd, currentP, currentG);
    }

    function _payOutMAHAGains(
        ICommunityIssuance _communityIssuance,
        address _depositor,
        address _frontEnd
    ) internal {
        // Pay out front end's MAHA gain
        if (_frontEnd != address(0)) {
            uint256 frontEndMAHAGain = getFrontEndMAHAGain(_frontEnd);
            _communityIssuance.sendMAHA(_frontEnd, frontEndMAHAGain);
            emit MAHAPaidToFrontEnd(_frontEnd, frontEndMAHAGain);
        }

        // Pay out depositor's MAHA gain
        uint256 depositorMAHAGain = getDepositorMAHAGain(_depositor);
        _communityIssuance.sendMAHA(_depositor, depositorMAHAGain);
        emit MAHAPaidToDepositor(_depositor, depositorMAHAGain);
    }

    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == address(activePool), "StabilityPool: Caller is not ActivePool");
    }

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == address(troveManager), "StabilityPool: Caller is not TroveManager");
    }

    function _requireNoUnderCollateralizedTroves() internal {
        uint256 price = getPriceFeed().fetchPrice();
        address lowestTrove = sortedTroves.getLast();
        uint256 ICR = troveManager.getCurrentICR(lowestTrove, price);
        require(ICR >= MCR, "StabilityPool: Cannot withdraw while there are troves with ICR < MCR");
    }

    function _requireUserHasDeposit(uint256 _initialDeposit) internal pure {
        require(_initialDeposit > 0, "StabilityPool: User must have a non-zero deposit");
    }

    function _requireUserHasNoDeposit(address _address) internal view {
        uint256 initialDeposit = deposits[_address].initialValue;
        require(initialDeposit == 0, "StabilityPool: User must have no deposit");
    }

    function _requireNonZeroAmount(uint256 _amount) internal pure {
        require(_amount > 0, "StabilityPool: Amount must be non-zero");
    }

    function _requireUserHasTrove(address _depositor) internal view {
        require(
            troveManager.getTroveStatus(_depositor) == 1,
            "StabilityPool: caller must have an active trove to withdraw ETHGain to"
        );
    }

    function _requireUserHasETHGain(address _depositor) internal view {
        uint256 ETHGain = getDepositorETHGain(_depositor);
        require(ETHGain > 0, "StabilityPool: caller must have non-zero ETH Gain");
    }

    function _requireFrontEndNotRegistered(address _address) internal view {
        require(
            !frontEnds[_address].registered,
            "StabilityPool: must not already be a registered front end"
        );
    }

    function _requireFrontEndIsRegisteredOrZero(address _address) internal view {
        require(
            frontEnds[_address].registered || _address == address(0),
            "StabilityPool: Tag must be a registered front end, or the zero address"
        );
    }

    function _requireValidKickbackRate(uint256 _kickbackRate) internal pure {
        require(
            _kickbackRate <= DECIMAL_PRECISION,
            "StabilityPool: Kickback rate must be in range [0,1]"
        );
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        ETH = ETH.add(msg.value);
        StabilityPoolETHBalanceUpdated(ETH);
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

interface ICommunityIssuance {
    // --- Events ---
    event TotalMAHAIssuedUpdated(uint256 _totalMAHAIssued);
    event RewardAdded(uint256 reward);

    // --- Functions ---

    function issueMAHA() external returns (uint256);

    function sendMAHA(address _account, uint256 _MAHAamount) external;

    function lastTimeRewardApplicable() external view returns (uint256);

    function notifyRewardAmount(uint256 reward) external;
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

// uint128 addition and subtraction, with overflow protection.

library LiquitySafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "LiquitySafeMath128: addition overflow");

        return c;
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "LiquitySafeMath128: subtraction overflow");
        uint128 c = a - b;

        return c;
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