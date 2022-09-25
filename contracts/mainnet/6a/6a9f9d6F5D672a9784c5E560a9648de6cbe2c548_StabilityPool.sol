// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ITroveManagerHelpers.sol";
import "./Interfaces/IDCHFToken.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/ICommunityIssuance.sol";
import "./Dependencies/DfrancBase.sol";
import "./Dependencies/DfrancSafeMath128.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/SafetyTransfer.sol";
import "./Dependencies/Initializable.sol";

contract StabilityPool is
	DfrancBase,
	CheckContract,
	ReentrancyGuard,
	Initializable,
	IStabilityPool
{
	using SafeMath for uint256;
	using DfrancSafeMath128 for uint128;
	using SafeERC20 for IERC20;

	string public constant NAME = "StabilityPool";
	bytes32 public constant STABILITY_POOL_NAME_BYTES =
		0xf704b47f65a99b2219b7213612db4be4a436cdf50624f4baca1373ef0de0aac7;

	IBorrowerOperations public borrowerOperations;

	ITroveManager public troveManager;

	ITroveManagerHelpers public troveManagerHelpers;

	IDCHFToken public dchfToken;

	// Needed to check if there are pending liquidations
	ISortedTroves public sortedTroves;

	ICommunityIssuance public communityIssuance;

	address internal assetAddress;

	uint256 internal assetBalance; // deposited ether tracker

	// Tracker for DCHF held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
	uint256 internal totalDCHFDeposits;

	// --- Data structures ---

	struct Snapshots {
		uint256 S;
		uint256 P;
		uint256 G;
		uint128 scale;
		uint128 epoch;
	}

	mapping(address => uint256) public deposits; // depositor address -> Deposit struct
	mapping(address => Snapshots) public depositSnapshots; // depositor address -> snapshots struct

	uint256 public totalStakes;
	Snapshots public systemSnapshots;

	/*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
	 * after a series of liquidations have occurred, each of which cancel some DCHF debt with the deposit.
	 *
	 * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
	 * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
	 */
	uint256 public P;

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
	 * Similarly, the sum 'G' is used to calculate MON gains. During it's lifetime, each deposit d_t earns a MON gain of
	 *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
	 *
	 *  MON reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
	 *  In each case, the MON reward is issued (i.e. G is updated), before other state changes are made.
	 */
	mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

	// Error tracker for the error correction in the MON issuance calculation
	uint256 public lastMONError;
	// Error trackers for the error correction in the offset calculation
	uint256 public lastAssetError_Offset;
	uint256 public lastDCHFLossError_Offset;

	bool public isInitialized;

	// --- Contract setters ---

	function getNameBytes() external pure override returns (bytes32) {
		return STABILITY_POOL_NAME_BYTES;
	}

	function getAssetType() external view override returns (address) {
		return assetAddress;
	}

	function setAddresses(
		address _assetAddress,
		address _borrowerOperationsAddress,
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _dchfTokenAddress,
		address _sortedTrovesAddress,
		address _communityIssuanceAddress,
		address _dfrancParamsAddress
	) external initializer onlyOwner {
		require(!isInitialized, "Already initialized");
		checkContract(_borrowerOperationsAddress);
		checkContract(_troveManagerAddress);
		checkContract(_troveManagerHelpersAddress);
		checkContract(_dchfTokenAddress);
		checkContract(_sortedTrovesAddress);
		checkContract(_communityIssuanceAddress);
		checkContract(_dfrancParamsAddress);

		isInitialized = true;

		if (_assetAddress != ETH_REF_ADDRESS) {
			checkContract(_assetAddress);
		}

		assetAddress = _assetAddress;
		borrowerOperations = IBorrowerOperations(_borrowerOperationsAddress);
		troveManager = ITroveManager(_troveManagerAddress);
		troveManagerHelpers = ITroveManagerHelpers(_troveManagerHelpersAddress);
		dchfToken = IDCHFToken(_dchfTokenAddress);
		sortedTroves = ISortedTroves(_sortedTrovesAddress);
		communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
		setDfrancParameters(_dfrancParamsAddress);

		P = DECIMAL_PRECISION;

		emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
		emit TroveManagerAddressChanged(_troveManagerAddress);
		emit DCHFTokenAddressChanged(_dchfTokenAddress);
		emit SortedTrovesAddressChanged(_sortedTrovesAddress);
		emit CommunityIssuanceAddressChanged(_communityIssuanceAddress);
	}

	// --- Getters for public variables. Required by IPool interface ---

	function getAssetBalance() external view override returns (uint256) {
		return assetBalance;
	}

	function getTotalDCHFDeposits() external view override returns (uint256) {
		return totalDCHFDeposits;
	}

	// --- External Depositor Functions ---

	/*  provideToSP():
	 *
	 * - Triggers a MON issuance, based on time passed since the last issuance. The MON issuance is shared between *all* depositors
	 * - Sends depositor's accumulated gains (MON, ETH) to depositor
	 * - Increases deposit and system stake, and takes new snapshots for each.
	 */
	function provideToSP(uint256 _amount) external override nonReentrant {
		_requireNonZeroAmount(_amount);

		uint256 initialDeposit = deposits[msg.sender];

		ICommunityIssuance communityIssuanceCached = communityIssuance;
		_triggerMONIssuance(communityIssuanceCached);

		uint256 depositorAssetGain = getDepositorAssetGain(msg.sender);
		uint256 depositorAssetGainEther = getDepositorAssetGain1e18(msg.sender);

		uint256 compoundedDCHFDeposit = getCompoundedDCHFDeposit(msg.sender);
		uint256 DCHFLoss = initialDeposit.sub(compoundedDCHFDeposit); // Needed only for event log

		// First pay out any MON gains
		_payOutMONGains(communityIssuanceCached, msg.sender);

		// Update System stake
		uint256 compoundedStake = getCompoundedTotalStake();
		uint256 newStake = compoundedStake.add(_amount);
		_updateStakeAndSnapshots(newStake);
		emit StakeChanged(newStake, msg.sender);

		_sendDCHFtoStabilityPool(msg.sender, _amount);

		uint256 newDeposit = compoundedDCHFDeposit.add(_amount);
		_updateDepositAndSnapshots(msg.sender, newDeposit);

		emit UserDepositChanged(msg.sender, newDeposit);
		emit AssetGainWithdrawn(msg.sender, depositorAssetGain, DCHFLoss); // DCHF Loss required for event log

		_sendAssetGainToDepositor(depositorAssetGain, depositorAssetGainEther);
	}

	/*  withdrawFromSP():
	 *
	 * - Triggers a MON issuance, based on time passed since the last issuance. The MON issuance is shared between *all* depositors
	 * - Sends all depositor's accumulated gains (MON, ETH) to depositor
	 * - Decreases deposit and system stake, and takes new snapshots for each.
	 *
	 * If _amount > userDeposit, the user withdraws all of their compounded deposit.
	 */
	function withdrawFromSP(uint256 _amount) external override nonReentrant {
		if (_amount != 0) {
			_requireNoUnderCollateralizedTroves();
		}
		uint256 initialDeposit = deposits[msg.sender];
		_requireUserHasDeposit(initialDeposit);

		ICommunityIssuance communityIssuanceCached = communityIssuance;

		_triggerMONIssuance(communityIssuanceCached);

		uint256 depositorAssetGain = getDepositorAssetGain(msg.sender);
		uint256 depositorAssetGainEther = getDepositorAssetGain1e18(msg.sender);

		uint256 compoundedDCHFDeposit = getCompoundedDCHFDeposit(msg.sender);
		uint256 DCHFtoWithdraw = DfrancMath._min(_amount, compoundedDCHFDeposit);
		uint256 DCHFLoss = initialDeposit.sub(compoundedDCHFDeposit); // Needed only for event log

		// First pay out any MON gains
		_payOutMONGains(communityIssuanceCached, msg.sender);

		// Update System stake
		uint256 compoundedStake = getCompoundedTotalStake();
		uint256 newStake = compoundedStake.sub(DCHFtoWithdraw);
		_updateStakeAndSnapshots(newStake);
		emit StakeChanged(newStake, msg.sender);

		_sendDCHFToDepositor(msg.sender, DCHFtoWithdraw);

		// Update deposit
		uint256 newDeposit = compoundedDCHFDeposit.sub(DCHFtoWithdraw);
		_updateDepositAndSnapshots(msg.sender, newDeposit);
		emit UserDepositChanged(msg.sender, newDeposit);

		emit AssetGainWithdrawn(msg.sender, depositorAssetGain, DCHFLoss); // DCHF Loss required for event log

		_sendAssetGainToDepositor(depositorAssetGain, depositorAssetGainEther);
	}

	/* withdrawETHGainToTrove:
	 * - Triggers a MON issuance, based on time passed since the last issuance. The MON issuance is shared between *all* depositors
	 * - Sends all depositor's MON gain to  depositor
	 * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
	 * - Leaves their compounded deposit in the Stability Pool
	 * - Updates snapshots for deposit and system stake */
	function withdrawAssetGainToTrove(address _upperHint, address _lowerHint) external override {
		uint256 initialDeposit = deposits[msg.sender];
		_requireUserHasDeposit(initialDeposit);
		_requireUserHasTrove(msg.sender);
		_requireUserHasETHGain(msg.sender);

		ICommunityIssuance communityIssuanceCached = communityIssuance;

		_triggerMONIssuance(communityIssuanceCached);

		uint256 depositorAssetGain = getDepositorAssetGain1e18(msg.sender);

		uint256 compoundedDCHFDeposit = getCompoundedDCHFDeposit(msg.sender);
		uint256 DCHFLoss = initialDeposit.sub(compoundedDCHFDeposit); // Needed only for event log

		// First pay out any MON gains
		_payOutMONGains(communityIssuanceCached, msg.sender);

		// Update System stake
		uint256 compoundedSystemStake = getCompoundedTotalStake();
		_updateStakeAndSnapshots(compoundedSystemStake);
		emit StakeChanged(compoundedSystemStake, msg.sender);

		_updateDepositAndSnapshots(msg.sender, compoundedDCHFDeposit);

		/* Emit events before transferring ETH gain to Trove.
         This lets the event log make more sense (i.e. so it appears that first the ETH gain is withdrawn
        and then it is deposited into the Trove, not the other way around). */
		emit AssetGainWithdrawn(msg.sender, depositorAssetGain, DCHFLoss);
		emit UserDepositChanged(msg.sender, compoundedDCHFDeposit);

		assetBalance = assetBalance.sub(depositorAssetGain);
		emit StabilityPoolAssetBalanceUpdated(assetBalance);
		emit AssetSent(msg.sender, depositorAssetGain);

		borrowerOperations.moveETHGainToTrove{
			value: assetAddress == address(0) ? depositorAssetGain : 0
		}(assetAddress, depositorAssetGain, msg.sender, _upperHint, _lowerHint);
	}

	// --- MON issuance functions ---

	function _triggerMONIssuance(ICommunityIssuance _communityIssuance) internal {
		uint256 MONIssuance = _communityIssuance.issueMON();
		_updateG(MONIssuance);
	}

	function _updateG(uint256 _MONIssuance) internal {
		uint256 totalDCHF = totalDCHFDeposits; // cached to save an SLOAD
		/*
		 * When total deposits is 0, G is not updated. In this case, the MON issued can not be obtained by later
		 * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
		 *
		 */
		if (totalDCHF == 0 || _MONIssuance == 0) {
			return;
		}

		uint256 MONPerUnitStaked;
		MONPerUnitStaked = _computeMONPerUnitStaked(_MONIssuance, totalDCHF);

		uint256 marginalMONGain = MONPerUnitStaked.mul(P);
		epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale]
			.add(marginalMONGain);

		emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
	}

	function _computeMONPerUnitStaked(uint256 _MONIssuance, uint256 _totalDCHFDeposits)
		internal
		returns (uint256)
	{
		/*
		 * Calculate the MON-per-unit staked.  Division uses a "feedback" error correction, to keep the
		 * cumulative error low in the running total G:
		 *
		 * 1) Form a numerator which compensates for the floor division error that occurred the last time this
		 * function was called.
		 * 2) Calculate "per-unit-staked" ratio.
		 * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
		 * 4) Store this error for use in the next correction when this function is called.
		 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
		 */
		uint256 MONNumerator = _MONIssuance.mul(DECIMAL_PRECISION).add(lastMONError);

		uint256 MONPerUnitStaked = MONNumerator.div(_totalDCHFDeposits);
		lastMONError = MONNumerator.sub(MONPerUnitStaked.mul(_totalDCHFDeposits));

		return MONPerUnitStaked;
	}

	// --- Liquidation functions ---

	/*
	 * Cancels out the specified debt against the DCHF contained in the Stability Pool (as far as possible)
	 * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the TroveManager.
	 */
	function offset(uint256 _debtToOffset, uint256 _collToAdd) external override {
		_requireCallerIsTroveManager();
		uint256 totalDCHF = totalDCHFDeposits; // cached to save an SLOAD
		if (totalDCHF == 0 || _debtToOffset == 0) {
			return;
		}

		_triggerMONIssuance(communityIssuance);

		(
			uint256 AssetGainPerUnitStaked,
			uint256 DCHFLossPerUnitStaked
		) = _computeRewardsPerUnitStaked(_collToAdd, _debtToOffset, totalDCHF);

		_updateRewardSumAndProduct(AssetGainPerUnitStaked, DCHFLossPerUnitStaked); // updates S and P

		_moveOffsetCollAndDebt(_collToAdd, _debtToOffset);
	}

	// --- Offset helper functions ---

	function _computeRewardsPerUnitStaked(
		uint256 _collToAdd,
		uint256 _debtToOffset,
		uint256 _totalDCHFDeposits
	) internal returns (uint256 AssetGainPerUnitStaked, uint256 DCHFLossPerUnitStaked) {
		/*
		 * Compute the DCHF and ETH rewards. Uses a "feedback" error correction, to keep
		 * the cumulative error in the P and S state variables low:
		 *
		 * 1) Form numerators which compensate for the floor division errors that occurred the last time this
		 * function was called.
		 * 2) Calculate "per-unit-staked" ratios.
		 * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
		 * 4) Store these errors for use in the next correction when this function is called.
		 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
		 */
		uint256 AssetNumerator = _collToAdd.mul(DECIMAL_PRECISION).add(lastAssetError_Offset);

		assert(_debtToOffset <= _totalDCHFDeposits);
		if (_debtToOffset == _totalDCHFDeposits) {
			DCHFLossPerUnitStaked = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
			lastDCHFLossError_Offset = 0;
		} else {
			uint256 DCHFLossNumerator = _debtToOffset.mul(DECIMAL_PRECISION).sub(
				lastDCHFLossError_Offset
			);
			/*
			 * Add 1 to make error in quotient positive. We want "slightly too much" DCHF loss,
			 * which ensures the error in any given compoundedDCHFDeposit favors the Stability Pool.
			 */
			DCHFLossPerUnitStaked = (DCHFLossNumerator.div(_totalDCHFDeposits)).add(1);
			lastDCHFLossError_Offset = (DCHFLossPerUnitStaked.mul(_totalDCHFDeposits)).sub(
				DCHFLossNumerator
			);
		}

		AssetGainPerUnitStaked = AssetNumerator.div(_totalDCHFDeposits);
		lastAssetError_Offset = AssetNumerator.sub(AssetGainPerUnitStaked.mul(_totalDCHFDeposits));

		return (AssetGainPerUnitStaked, DCHFLossPerUnitStaked);
	}

	// Update the Stability Pool reward sum S and product P
	function _updateRewardSumAndProduct(
		uint256 _AssetGainPerUnitStaked,
		uint256 _DCHFLossPerUnitStaked
	) internal {
		uint256 currentP = P;
		uint256 newP;

		assert(_DCHFLossPerUnitStaked <= DECIMAL_PRECISION);
		/*
		 * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool DCHF in the liquidation.
		 * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - DCHFLossPerUnitStaked)
		 */
		uint256 newProductFactor = uint256(DECIMAL_PRECISION).sub(_DCHFLossPerUnitStaked);

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
		uint256 marginalAssetGain = _AssetGainPerUnitStaked.mul(currentP);
		uint256 newS = currentS.add(marginalAssetGain);
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
		IActivePool activePoolCached = dfrancParams.activePool();

		// Cancel the liquidated DCHF debt with the DCHF in the stability pool
		activePoolCached.decreaseDCHFDebt(assetAddress, _debtToOffset);
		_decreaseDCHF(_debtToOffset);

		// Burn the debt that was successfully offset
		dchfToken.burn(address(this), _debtToOffset);

		activePoolCached.sendAsset(assetAddress, address(this), _collToAdd);
	}

	function _decreaseDCHF(uint256 _amount) internal {
		uint256 newTotalDCHFDeposits = totalDCHFDeposits.sub(_amount);
		totalDCHFDeposits = newTotalDCHFDeposits;
		emit StabilityPoolDCHFBalanceUpdated(newTotalDCHFDeposits);
	}

	// --- Reward calculator functions for depositor ---

	/* Calculates the ETH gain earned by the deposit since its last snapshots were taken.
	 * Given by the formula:  E = d0 * (S - S(0))/P(0)
	 * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
	 * d0 is the last recorded deposit value.
	 */
	function getDepositorAssetGain(address _depositor) public view override returns (uint256) {
		uint256 initialDeposit = deposits[_depositor];

		if (initialDeposit == 0) {
			return 0;
		}

		Snapshots memory snapshots = depositSnapshots[_depositor];

		return
			SafetyTransfer.decimalsCorrection(
				assetAddress,
				_getAssetGainFromSnapshots(initialDeposit, snapshots)
			);
	}

	function getDepositorAssetGain1e18(address _depositor) public view returns (uint256) {
		uint256 initialDeposit = deposits[_depositor];

		if (initialDeposit == 0) {
			return 0;
		}

		Snapshots memory snapshots = depositSnapshots[_depositor];

		return _getAssetGainFromSnapshots(initialDeposit, snapshots);
	}

	function _getAssetGainFromSnapshots(uint256 initialDeposit, Snapshots memory snapshots)
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

		uint256 AssetGain = initialDeposit
			.mul(firstPortion.add(secondPortion))
			.div(P_Snapshot)
			.div(DECIMAL_PRECISION);

		return AssetGain;
	}

	/*
	 * Calculate the MON gain earned by a deposit since its last snapshots were taken.
	 * Given by the formula:  MON = d0 * (G - G(0))/P(0)
	 * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
	 * d0 is the last recorded deposit value.
	 */
	function getDepositorMONGain(address _depositor) public view override returns (uint256) {
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		Snapshots memory snapshots = depositSnapshots[_depositor];
		return _getMONGainFromSnapshots(initialDeposit, snapshots);
	}

	function _getMONGainFromSnapshots(uint256 initialStake, Snapshots memory snapshots)
		internal
		view
		returns (uint256)
	{
		/*
		 * Grab the sum 'G' from the epoch at which the stake was made. The MON gain may span up to one scale change.
		 * If it does, the second portion of the MON gain is scaled by 1e9.
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

		uint256 MONGain = initialStake.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(
			DECIMAL_PRECISION
		);

		return MONGain;
	}

	// --- Compounded deposit and compounded System stake ---

	/*
	 * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
	 * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
	 */
	function getCompoundedDCHFDeposit(address _depositor)
		public
		view
		override
		returns (uint256)
	{
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		return _getCompoundedStakeFromSnapshots(initialDeposit, depositSnapshots[_depositor]);
	}

	/*
	 * Return the system's compounded stake. Given by the formula:  D = D0 * P/P(0)
	 * where P(0) is the depositor's snapshot of the product P
	 *
	 * The system's compounded stake is equal to the sum of its depositors' compounded deposits.
	 */
	function getCompoundedTotalStake() public view override returns (uint256) {
		uint256 cachedStake = totalStakes;
		if (cachedStake == 0) {
			return 0;
		}

		return _getCompoundedStakeFromSnapshots(cachedStake, systemSnapshots);
	}

	// Internal function, used to calculcate compounded deposits and compounded stakes.
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

	// --- Sender functions for DCHF deposit, ETH gains and MON gains ---

	// Transfer the DCHF tokens from the user to the Stability Pool's address, and update its recorded DCHF
	function _sendDCHFtoStabilityPool(address _address, uint256 _amount) internal {
		dchfToken.sendToPool(_address, address(this), _amount);
		uint256 newTotalDCHFDeposits = totalDCHFDeposits.add(_amount);
		totalDCHFDeposits = newTotalDCHFDeposits;
		emit StabilityPoolDCHFBalanceUpdated(newTotalDCHFDeposits);
	}

	function _sendAssetGainToDepositor(uint256 _amount, uint256 _amountEther) internal {
		if (_amount == 0) {
			return;
		}

		assetBalance = assetBalance.sub(_amountEther);

		if (assetAddress == ETH_REF_ADDRESS) {
			(bool success, ) = msg.sender.call{ value: _amountEther }("");
			require(success, "StabilityPool: sending ETH failed");
		} else {
			IERC20(assetAddress).safeTransfer(msg.sender, _amount);
		}

		emit StabilityPoolAssetBalanceUpdated(assetBalance);
		emit AssetSent(msg.sender, _amount);
	}

	// Send DCHF to user and decrease DCHF in Pool
	function _sendDCHFToDepositor(address _depositor, uint256 DCHFWithdrawal) internal {
		if (DCHFWithdrawal == 0) {
			return;
		}

		dchfToken.returnFromPool(address(this), _depositor, DCHFWithdrawal);
		_decreaseDCHF(DCHFWithdrawal);
	}

	// --- Stability Pool Deposit Functionality ---

	function _updateDepositAndSnapshots(address _depositor, uint256 _newValue) internal {
		deposits[_depositor] = _newValue;

		if (_newValue == 0) {
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

		Snapshots storage depositSnap = depositSnapshots[_depositor];

		// Record new snapshots of the latest running product P, sum S, and sum G, for the depositor
		depositSnap.P = currentP;
		depositSnap.S = currentS;
		depositSnap.G = currentG;
		depositSnap.scale = currentScaleCached;
		depositSnap.epoch = currentEpochCached;

		emit DepositSnapshotUpdated(_depositor, currentP, currentS, currentG);
	}

	function _updateStakeAndSnapshots(uint256 _newValue) internal {
		Snapshots storage snapshots = systemSnapshots;
		totalStakes = _newValue;

		uint128 currentScaleCached = currentScale;
		uint128 currentEpochCached = currentEpoch;
		uint256 currentP = P;

		// Get G for the current epoch and current scale
		uint256 currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

		// Record new snapshots of the latest running product P and sum G for the system
		snapshots.P = currentP;
		snapshots.G = currentG;
		snapshots.scale = currentScaleCached;
		snapshots.epoch = currentEpochCached;

		emit SystemSnapshotUpdated(currentP, currentG);
	}

	function _payOutMONGains(ICommunityIssuance _communityIssuance, address _depositor)
		internal
	{
		// Pay out depositor's MON gain
		uint256 depositorMONGain = getDepositorMONGain(_depositor);
		_communityIssuance.sendMON(_depositor, depositorMONGain);
		emit MONPaidToDepositor(_depositor, depositorMONGain);
	}

	// --- 'require' functions ---

	function _requireCallerIsActivePool() internal view {
		require(
			msg.sender == address(dfrancParams.activePool()),
			"StabilityPool: Caller is not ActivePool"
		);
	}

	function _requireCallerIsTroveManager() internal view {
		require(
			msg.sender == address(troveManager) || msg.sender == address(troveManagerHelpers),
			"SortedTroves: Caller is not the TroveManager"
		);
	}

	function _requireNoUnderCollateralizedTroves() public {
		uint256 price = dfrancParams.priceFeed().fetchPrice(assetAddress);
		address lowestTrove = sortedTroves.getLast(assetAddress);
		uint256 ICR = troveManagerHelpers.getCurrentICR(assetAddress, lowestTrove, price);
		require(
			ICR >= dfrancParams.MCR(assetAddress),
			"StabilityPool: Cannot withdraw while there are troves with ICR < MCR"
		);
	}

	function _requireUserHasDeposit(uint256 _initialDeposit) internal pure {
		require(_initialDeposit > 0, "StabilityPool: User must have a non-zero deposit");
	}

	function _requireNonZeroAmount(uint256 _amount) internal pure {
		require(_amount > 0, "StabilityPool: Amount must be non-zero");
	}

	function _requireUserHasTrove(address _depositor) internal view {
		require(
			troveManagerHelpers.getTroveStatus(assetAddress, _depositor) == 1,
			"StabilityPool: caller must have an active trove to withdraw AssetGain to"
		);
	}

	function _requireUserHasETHGain(address _depositor) internal view {
		uint256 AssetGain = getDepositorAssetGain(_depositor);
		require(AssetGain > 0, "StabilityPool: caller must have non-zero ETH Gain");
	}

	// --- Fallback function ---

	function receivedERC20(address _asset, uint256 _amount) external override {
		_requireCallerIsActivePool();

		require(_asset == assetAddress, "Receiving the wrong asset in StabilityPool");

		if (assetAddress != ETH_REF_ADDRESS) {
			assetBalance = assetBalance.add(_amount);
			emit StabilityPoolAssetBalanceUpdated(assetBalance);
		}
	}

	receive() external payable {
		_requireCallerIsActivePool();
		assetBalance = assetBalance.add(msg.value);
		emit StabilityPoolAssetBalanceUpdated(assetBalance);
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

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

// Common interface for the Trove Manager.
interface IBorrowerOperations {
	// --- Events ---

	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event StabilityPoolAddressChanged(address _stabilityPoolAddress);
	event GasPoolAddressChanged(address _gasPoolAddress);
	event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
	event SortedTrovesAddressChanged(address _sortedTrovesAddress);
	event DCHFTokenAddressChanged(address _dchfTokenAddress);
	event MONStakingAddressChanged(address _MONStakingAddress);

	event TroveCreated(address indexed _asset, address indexed _borrower, uint256 arrayIndex);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		uint8 operation
	);
	event DCHFBorrowingFeePaid(
		address indexed _asset,
		address indexed _borrower,
		uint256 _DCHFFee
	);

	// --- Functions ---

	function setAddresses(
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _stabilityPoolAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _sortedTrovesAddress,
		address _dchfTokenAddress,
		address _MONStakingAddress,
		address _dfrancParamsAddress
	) external;

	function openTrove(
		address _asset,
		uint256 _tokenAmount,
		uint256 _maxFee,
		uint256 _DCHFamount,
		address _upperHint,
		address _lowerHint
	) external payable;

	function addColl(
		address _asset,
		uint256 _assetSent,
		address _upperHint,
		address _lowerHint
	) external payable;

	function moveETHGainToTrove(
		address _asset,
		uint256 _amountMoved,
		address _user,
		address _upperHint,
		address _lowerHint
	) external payable;

	function withdrawColl(
		address _asset,
		uint256 _amount,
		address _upperHint,
		address _lowerHint
	) external;

	function withdrawDCHF(
		address _asset,
		uint256 _maxFee,
		uint256 _amount,
		address _upperHint,
		address _lowerHint
	) external;

	function repayDCHF(
		address _asset,
		uint256 _amount,
		address _upperHint,
		address _lowerHint
	) external;

	function closeTrove(address _asset) external;

	function adjustTrove(
		address _asset,
		uint256 _assetSent,
		uint256 _maxFee,
		uint256 _collWithdrawal,
		uint256 _debtChange,
		bool isDebtIncrease,
		address _upperHint,
		address _lowerHint
	) external payable;

	function claimCollateral(address _asset) external;

	function getCompositeDebt(address _asset, uint256 _debt) external view returns (uint256);

	function isContractBorrowerOps() external pure returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
	// --- Events ---
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

	// --- Functions ---

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

pragma solidity ^0.8.14;
import "./IDfrancBase.sol";
import "./IStabilityPool.sol";
import "./IDCHFToken.sol";
import "./IMONStaking.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IStabilityPoolManager.sol";
import "./ITroveManagerHelpers.sol";

// Common interface for the Trove Manager.
interface ITroveManager is IDfrancBase {
	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	// Store the necessary data for a trove
	struct Trove {
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	/*
	 * --- Variable container structs for liquidations ---
	 *
	 * These structs are used to hold, return and assign variables inside the liquidation functions,
	 * in order to avoid the error: "CompilerError: Stack too deep".
	 **/

	struct LocalVariables_OuterLiquidationFunction {
		uint256 price;
		uint256 DCHFInStabPool;
		bool recoveryModeAtStart;
		uint256 liquidatedDebt;
		uint256 liquidatedColl;
	}

	struct LocalVariables_InnerSingleLiquidateFunction {
		uint256 collToLiquidate;
		uint256 pendingDebtReward;
		uint256 pendingCollReward;
	}

	struct LocalVariables_LiquidationSequence {
		uint256 remainingDCHFInStabPool;
		uint256 i;
		uint256 ICR;
		address user;
		bool backToNormalMode;
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
		uint256 collGasCompensation;
		uint256 DCHFGasCompensation;
		uint256 debtToOffset;
		uint256 collToSendToSP;
		uint256 debtToRedistribute;
		uint256 collToRedistribute;
		uint256 collSurplus;
	}

	struct LiquidationTotals {
		uint256 totalCollInSequence;
		uint256 totalDebtInSequence;
		uint256 totalCollGasCompensation;
		uint256 totalDCHFGasCompensation;
		uint256 totalDebtToOffset;
		uint256 totalCollToSendToSP;
		uint256 totalDebtToRedistribute;
		uint256 totalCollToRedistribute;
		uint256 totalCollSurplus;
	}

	struct ContractsCache {
		IActivePool activePool;
		IDefaultPool defaultPool;
		IDCHFToken dchfToken;
		IMONStaking monStaking;
		ISortedTroves sortedTroves;
		ICollSurplusPool collSurplusPool;
		address gasPoolAddress;
	}
	// --- Variable container structs for redemptions ---

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

	// --- Events ---

	event Liquidation(
		address indexed _asset,
		uint256 _liquidatedDebt,
		uint256 _liquidatedColl,
		uint256 _collGasCompensation,
		uint256 _DCHFGasCompensation
	);
	event Redemption(
		address indexed _asset,
		uint256 _attemptedDCHFAmount,
		uint256 _actualDCHFAmount,
		uint256 _AssetSent,
		uint256 _AssetFee
	);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
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
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(
		address indexed _asset,
		uint256 _totalStakesSnapshot,
		uint256 _totalCollateralSnapshot
	);
	event LTermsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_DCHFDebt);
	event TroveSnapshotsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_DCHFDebt);
	event TroveIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
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
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	// --- Functions ---
	function isContractTroveManager() external pure returns (bool);

	function troveManagerHelpers() external view returns (ITroveManagerHelpers);

	function setAddresses(
		address _stabilityPoolManagerAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _dchfTokenAddress,
		address _sortedTrovesAddress,
		address _monStakingAddress,
		address _dfrancParamsAddress,
		address _troveManagerHelpersAddress
	) external;

	function stabilityPoolManager() external view returns (IStabilityPoolManager);

	function dchfToken() external view returns (IDCHFToken);

	function monStaking() external view returns (IMONStaking);

	function liquidate(address _asset, address borrower) external;

	function liquidateTroves(address _asset, uint256 _n) external;

	function batchLiquidateTroves(address _asset, address[] memory _troveArray) external;

	function redeemCollateral(
		address _asset,
		uint256 _DCHFamount,
		address _firstRedemptionHint,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint,
		uint256 _partialRedemptionHintNICR,
		uint256 _maxIterations,
		uint256 _maxFee
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IDfrancBase.sol";
import "./IStabilityPool.sol";
import "./IDCHFToken.sol";
import "./IMONStaking.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IStabilityPoolManager.sol";

// Common interface for the Trove Manager.
interface ITroveManagerHelpers is IDfrancBase {
	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	// Store the necessary data for a trove
	struct Trove {
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	/*
	 * --- Variable container structs for liquidations ---
	 *
	 * These structs are used to hold, return and assign variables inside the liquidation functions,
	 * in order to avoid the error: "CompilerError: Stack too deep".
	 **/

	struct LocalVariables_OuterLiquidationFunction {
		uint256 price;
		uint256 DCHFInStabPool;
		bool recoveryModeAtStart;
		uint256 liquidatedDebt;
		uint256 liquidatedColl;
	}

	struct LocalVariables_InnerSingleLiquidateFunction {
		uint256 collToLiquidate;
		uint256 pendingDebtReward;
		uint256 pendingCollReward;
	}

	struct LocalVariables_LiquidationSequence {
		uint256 remainingDCHFInStabPool;
		uint256 i;
		uint256 ICR;
		address user;
		bool backToNormalMode;
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
		uint256 collGasCompensation;
		uint256 DCHFGasCompensation;
		uint256 debtToOffset;
		uint256 collToSendToSP;
		uint256 debtToRedistribute;
		uint256 collToRedistribute;
		uint256 collSurplus;
	}

	struct LiquidationTotals {
		uint256 totalCollInSequence;
		uint256 totalDebtInSequence;
		uint256 totalCollGasCompensation;
		uint256 totalDCHFGasCompensation;
		uint256 totalDebtToOffset;
		uint256 totalCollToSendToSP;
		uint256 totalDebtToRedistribute;
		uint256 totalCollToRedistribute;
		uint256 totalCollSurplus;
	}

	struct ContractsCache {
		IActivePool activePool;
		IDefaultPool defaultPool;
		IDCHFToken dchfToken;
		IMONStaking monStaking;
		ISortedTroves sortedTroves;
		ICollSurplusPool collSurplusPool;
		address gasPoolAddress;
	}
	// --- Variable container structs for redemptions ---

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

	// Object containing the ETH and DCHF snapshots for a given active trove
	struct RewardSnapshot {
		uint256 asset;
		uint256 DCHFDebt;
	}

	// --- Events ---

	event Liquidation(
		address indexed _asset,
		uint256 _liquidatedDebt,
		uint256 _liquidatedColl,
		uint256 _collGasCompensation,
		uint256 _DCHFGasCompensation
	);
	event Redemption(
		address indexed _asset,
		uint256 _attemptedDCHFAmount,
		uint256 _actualDCHFAmount,
		uint256 _AssetSent,
		uint256 _AssetFee
	);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
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
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(
		address indexed _asset,
		uint256 _totalStakesSnapshot,
		uint256 _totalCollateralSnapshot
	);
	event LTermsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_DCHFDebt);
	event TroveSnapshotsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_DCHFDebt);
	event TroveIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
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
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	// Functions

	function addTroveOwnerToArray(address _asset, address _borrower)
		external
		returns (uint256 index);

	function applyPendingRewards(address _asset, address _borrower) external;

	function checkRecoveryMode(address _asset, uint256 _price) external returns (bool);

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

	function getEntireDebtAndColl(address _asset, address _borrower)
		external
		view
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingDCHFDebtReward,
			uint256 pendingAssetReward
		);

	function getNominalICR(address _asset, address _borrower) external view returns (uint256);

	function getPendingAssetReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function getPendingDCHFDebtReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw)
		external
		view
		returns (uint256);

	function getRedemptionRate(address _asset) external view returns (uint256);

	function getRedemptionRateWithDecay(address _asset) external view returns (uint256);

	function getTCR(address _asset, uint256 _price) external view returns (uint256);

	function getTroveColl(address _asset, address _borrower) external view returns (uint256);

	function getTroveDebt(address _asset, address _borrower) external view returns (uint256);

	function getTroveStake(address _asset, address _borrower) external view returns (uint256);

	function getTroveStatus(address _asset, address _borrower) external view returns (uint256);

	function hasPendingRewards(address _asset, address _borrower) external view returns (bool);

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

	function updateTroveRewardSnapshots(address _asset, address _borrower) external;

	function getBorrowingFeeWithDecay(address _asset, uint256 _DCHFDebt)
		external
		view
		returns (uint256);

	function getTroveOwnersCount(address _asset) external view returns (uint256);

	function getTroveFromTroveOwnersArray(address _asset, uint256 _index)
		external
		view
		returns (address);

	function setTroveDeptAndColl(
		address _asset,
		address _borrower,
		uint256 _debt,
		uint256 _coll
	) external;

	function isTroveActive(address _asset, address _borrower) external view returns (bool);

	function movePendingTroveRewardsToActivePool(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _DCHF,
		uint256 _amount
	) external;

	function removeStake(address _asset, address _borrower) external;

	function closeTrove(
		// access control
		address _asset,
		address _borrower,
		Status closedStatus
	) external;

	function redistributeDebtAndColl(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _debt,
		uint256 _coll
	) external;

	function updateSystemSnapshots_excludeCollRemainder(
		// access control
		address _asset,
		IActivePool _activePool,
		uint256 _collRemainder
	) external;

	function _checkPotentialRecoveryMode(
		// access control
		address _asset,
		uint256 _entireSystemColl,
		uint256 _entireSystemDebt,
		uint256 _price
	) external view returns (bool);

	function updateBaseRateFromRedemption(
		address _asset,
		uint256 _ETHDrawn,
		uint256 _price,
		uint256 _totalDCHFSupply
	) external returns (uint256);

	function updateStakeAndTotalStakes(address _asset, address _borrower)
		external
		returns (uint256);

	function _requireValidMaxFeePercentage(address _asset, uint256 _maxFeePercentage)
		external
		view;

	function _requireTCRoverMCR(address _asset, uint256 _price) external view;

	function _requireAmountGreaterThanZero(uint256 _amount) external pure;

	function _requireDCHFBalanceCoversRedemption(
		IDCHFToken _dchfToken,
		address _redeemer,
		uint256 _amount
	) external view;

	function applyPendingRewards(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower
	) external;

	function _getRedemptionFee(address _asset, uint256 _assetDraw)
		external
		view
		returns (uint256);

	function getTrove(address _asset, address _borrower)
		external
		view
		returns (
			address,
			uint256,
			uint256,
			uint256,
			Status,
			uint128
		);

	function getRewardSnapshots(address _asset, address _troveOwner)
		external
		view
		returns (uint256 asset, uint256 DCHFDebt);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "../Dependencies/ERC20Permit.sol";
import "../Interfaces/IStabilityPoolManager.sol";

abstract contract IDCHFToken is ERC20Permit {
	// --- Events ---

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {
	// --- Events ---

	event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
	event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
	event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
	event NodeRemoved(address indexed _asset, address _id);

	// --- Functions ---

	function setParams(
		address _TroveManagerAddress,
		address _troveManagerHelpersAddress,
		address _borrowerOperationsAddress
	) external;

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

pragma solidity ^0.8.14;

interface ICommunityIssuance {
	// --- Events ---

	event MONTokenAddressSet(address _MONTokenAddress);
	event StabilityPoolAddressSet(address _stabilityPoolAddress);
	event TotalMONIssuedUpdated(address indexed stabilityPool, uint256 _totalMONIssued);

	// --- Functions ---

	function setAddresses(
		address _MONTokenAddress,
		address _stabilityPoolAddress,
		address _adminContract
	) external;

	function issueMON() external returns (uint256);

	function sendMON(address _account, uint256 _MONamount) external;

	function addFundToStabilityPool(address _pool, uint256 _assignedSupply) external;

	function addFundToStabilityPoolFrom(
		address _pool,
		uint256 _assignedSupply,
		address _spender
	) external;

	function transferFundToAnotherStabilityPool(
		address _target,
		address _receiver,
		uint256 _quantity
	) external;

	function setWeeklyDfrancDistribution(address _stabilityPool, uint256 _weeklyReward) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseMath.sol";
import "./DfrancMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IDfrancBase.sol";

/*
 * Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
contract DfrancBase is BaseMath, IDfrancBase, Ownable {
	using SafeMath for uint256;
	address public constant ETH_REF_ADDRESS = address(0);

	IDfrancParameters public override dfrancParams;

	function setDfrancParameters(address _vaultParams) public onlyOwner {
		dfrancParams = IDfrancParameters(_vaultParams);
		emit VaultParametersBaseChanged(_vaultParams);
	}

	// --- Gas compensation functions ---

	// Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
	function _getCompositeDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.add(dfrancParams.DCHF_GAS_COMPENSATION(_asset));
	}

	function _getNetDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.sub(dfrancParams.DCHF_GAS_COMPENSATION(_asset));
	}

	// Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
	function _getCollGasCompensation(address _asset, uint256 _entireColl)
		internal
		view
		returns (uint256)
	{
		return _entireColl / dfrancParams.PERCENT_DIVISOR(_asset);
	}

	function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
		uint256 activeColl = dfrancParams.activePool().getAssetBalance(_asset);
		uint256 liquidatedColl = dfrancParams.defaultPool().getAssetBalance(_asset);

		return activeColl.add(liquidatedColl);
	}

	function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
		uint256 activeDebt = dfrancParams.activePool().getDCHFDebt(_asset);
		uint256 closedDebt = dfrancParams.defaultPool().getDCHFDebt(_asset);

		return activeDebt.add(closedDebt);
	}

	function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
		uint256 entireSystemColl = getEntireSystemColl(_asset);
		uint256 entireSystemDebt = getEntireSystemDebt(_asset);

		TCR = DfrancMath._computeCR(entireSystemColl, entireSystemDebt, _price);

		return TCR;
	}

	function _checkRecoveryMode(address _asset, uint256 _price) internal view returns (bool) {
		uint256 TCR = _getTCR(_asset, _price);

		return TCR < dfrancParams.CCR(_asset);
	}

	function _requireUserAcceptsFee(
		uint256 _fee,
		uint256 _amount,
		uint256 _maxFeePercentage
	) internal view {
		uint256 feePercentage = _fee.mul(dfrancParams.DECIMAL_PRECISION()).div(_amount);
		require(feePercentage <= _maxFeePercentage, "FM");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

// uint128 addition and subtraction, with overflow protection.

library DfrancSafeMath128 {
	function add(uint128 a, uint128 b) internal pure returns (uint128) {
		uint128 c = a + b;
		require(c >= a, "DfrancSafeMath128: addition overflow");

		return c;
	}

	function sub(uint128 a, uint128 b) internal pure returns (uint128) {
		require(b <= a, "DfrancSafeMath128: subtraction overflow");
		uint128 c = a - b;

		return c;
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

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20Decimals.sol";

library SafetyTransfer {
	using SafeMath for uint256;

	//_amount is in ether (1e18) and we want to convert it to the token decimal
	function decimalsCorrection(address _token, uint256 _amount)
		internal
		view
		returns (uint256)
	{
		if (_token == address(0)) return _amount;
		if (_amount == 0) return 0;

		uint8 decimals = ERC20Decimals(_token).decimals();
		if (decimals < 18) {
			return _amount.div(10**(18 - decimals));
		} else {
			return _amount.mul(10**(decimals - 18));
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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

pragma solidity ^0.8.14;

interface IDeposit {
	function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IDfrancParameters.sol";

interface IDfrancBase {
	event VaultParametersBaseChanged(address indexed newAddress);

	function dfrancParams() external view returns (IDfrancParameters);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMONStaking {
	// --- Events --

	event TreasuryAddressChanged(address _treausury);
	event SentToTreasury(address indexed _asset, uint256 _amount);
	event MONTokenAddressSet(address _MONTokenAddress);
	event DCHFTokenAddressSet(address _dchfTokenAddress);
	event TroveManagerAddressSet(address _troveManager);
	event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
	event ActivePoolAddressSet(address _activePoolAddress);

	event StakeChanged(address indexed staker, uint256 newStake);
	event StakingGainsAssetWithdrawn(
		address indexed staker,
		address indexed asset,
		uint256 AssetGain
	);
	event StakingGainsDCHFWithdrawn(address indexed staker, uint256 DCHFGain);
	event F_AssetUpdated(address indexed _asset, uint256 _F_ASSET);
	event F_DCHFUpdated(uint256 _F_DCHF);
	event TotalMONStakedUpdated(uint256 _totalMONStaked);
	event AssetSent(address indexed _asset, address indexed _account, uint256 _amount);
	event StakerSnapshotsUpdated(address _staker, uint256 _F_Asset, uint256 _F_DCHF);

	function monToken() external view returns (IERC20);

	// --- Functions ---

	function setAddresses(
		address _MONTokenAddress,
		address _dchfTokenAddress,
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _borrowerOperationsAddress,
		address _activePoolAddress,
		address _treasury
	) external;

	function stake(uint256 _MONamount) external;

	function unstake(uint256 _MONamount) external;

	function increaseF_Asset(address _asset, uint256 _AssetFee) external;

	function increaseF_DCHF(uint256 _MONFee) external;

	function getPendingAssetGain(address _asset, address _user) external view returns (uint256);

	function getPendingDCHFGain(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {
	// --- Events ---

	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event ActivePoolAddressChanged(address _newActivePoolAddress);

	event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
	event AssetSent(address _to, uint256 _amount);

	// --- Contract setters ---

	function setAddresses(
		address _borrowerOperationsAddress,
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
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

pragma solidity ^0.8.14;
import "./IPool.sol";

interface IActivePool is IPool {
	// --- Events ---
	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event ActivePoolDCHFDebtUpdated(address _asset, uint256 _DCHFDebt);
	event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IPool.sol";

interface IDefaultPool is IPool {
	// --- Events ---
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event DefaultPoolDCHFDebtUpdated(address _asset, uint256 _DCHFDebt);
	event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

pragma solidity ^0.8.14;

import "./IStabilityPool.sol";

interface IStabilityPoolManager {
	event StabilityPoolAdded(address asset, address stabilityPool);
	event StabilityPoolRemoved(address asset, address stabilityPool);

	function isStabilityPool(address stabilityPool) external view returns (bool);

	function addStabilityPool(address asset, address stabilityPool) external;

	function getAssetStabilityPool(address asset) external view returns (IStabilityPool);

	function unsafeGetAssetStabilityPool(address asset) external view returns (address);
}

pragma solidity ^0.8.14;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";
import "./IDfrancBase.sol";

interface IDfrancParameters {
	error SafeCheckError(
		string parameter,
		uint256 valueEntered,
		uint256 minValue,
		uint256 maxValue
	);

	event MCRChanged(uint256 oldMCR, uint256 newMCR);
	event CCRChanged(uint256 oldCCR, uint256 newCCR);
	event GasCompensationChanged(uint256 oldGasComp, uint256 newGasComp);
	event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
	event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
	event BorrowingFeeFloorChanged(uint256 oldBorrowingFloorFee, uint256 newBorrowingFloorFee);
	event MaxBorrowingFeeChanged(uint256 oldMaxBorrowingFee, uint256 newMaxBorrowingFee);
	event RedemptionFeeFloorChanged(
		uint256 oldRedemptionFeeFloor,
		uint256 newRedemptionFeeFloor
	);
	event RedemptionBlockRemoved(address _asset);
	event PriceFeedChanged(address indexed addr);

	function DECIMAL_PRECISION() external view returns (uint256);

	function _100pct() external view returns (uint256);

	// Minimum collateral ratio for individual troves
	function MCR(address _collateral) external view returns (uint256);

	// Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
	function CCR(address _collateral) external view returns (uint256);

	function DCHF_GAS_COMPENSATION(address _collateral) external view returns (uint256);

	function MIN_NET_DEBT(address _collateral) external view returns (uint256);

	function PERCENT_DIVISOR(address _collateral) external view returns (uint256);

	function BORROWING_FEE_FLOOR(address _collateral) external view returns (uint256);

	function REDEMPTION_FEE_FLOOR(address _collateral) external view returns (uint256);

	function MAX_BORROWING_FEE(address _collateral) external view returns (uint256);

	function redemptionBlock(address _collateral) external view returns (uint256);

	function activePool() external view returns (IActivePool);

	function defaultPool() external view returns (IDefaultPool);

	function priceFeed() external view returns (IPriceFeed);

	function setAddresses(
		address _activePool,
		address _defaultPool,
		address _priceFeed,
		address _adminContract
	) external;

	function setPriceFeed(address _priceFeed) external;

	function setMCR(address _asset, uint256 newMCR) external;

	function setCCR(address _asset, uint256 newCCR) external;

	function sanitizeParameters(address _asset) external;

	function setAsDefault(address _asset) external;

	function setAsDefaultWithRemptionBlock(address _asset, uint256 blockInDays) external;

	function setDCHFGasCompensation(address _asset, uint256 gasCompensation) external;

	function setMinNetDebt(address _asset, uint256 minNetDebt) external;

	function setPercentDivisor(address _asset, uint256 precentDivisor) external;

	function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor) external;

	function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee) external;

	function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor) external;

	function removeRedemptionBlock(address _asset) external;
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.14;

interface IPriceFeed {
	struct ChainlinkResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	struct RegisterOracle {
		AggregatorV3Interface chainLinkOracle;
		AggregatorV3Interface chainLinkIndex;
		bool isRegistered;
	}

	enum Status {
		chainlinkWorking,
		chainlinkUntrusted
	}

	// --- Events ---
	event PriceFeedStatusChanged(Status newStatus);
	event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
	event LastGoodIndexUpdated(address indexed token, uint256 _lastGoodIndex);
	event RegisteredNewOracle(
		address token,
		address chainLinkAggregator,
		address chianLinkIndex
	);

	// --- Function ---
	function addOracle(
		address _token,
		address _chainlinkOracle,
		address _chainlinkIndexOracle
	) external;

	function fetchPrice(address _token) external returns (uint256);

	function getDirectPrice(address _asset) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IDeposit.sol";

// Common interface for the Pools.
interface IPool is IDeposit {
	// --- Events ---

	event AssetBalanceUpdated(uint256 _newBalance);
	event DCHFBalanceUpdated(uint256 _newBalance);
	event ActivePoolAddressChanged(address _newActivePoolAddress);
	event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
	event AssetAddressChanged(address _assetAddress);
	event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
	event AssetSent(address _to, address indexed _asset, uint256 _amount);

	// --- Functions ---

	function getAssetBalance(address _asset) external view returns (uint256);

	function getDCHFDebt(address _asset) external view returns (uint256);

	function increaseDCHFDebt(address _asset, uint256 _amount) external;

	function decreaseDCHFDebt(address _asset, uint256 _amount) external;
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

pragma solidity ^0.8.14;
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

pragma solidity ^0.8.14;

interface ERC20Decimals {
	function decimals() external view returns (uint8);
}