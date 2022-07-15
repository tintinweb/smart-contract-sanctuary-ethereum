// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "Ownable.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";

import "ISwapRouter.sol";
import "IUniswapV3Pool.sol";

import "GammaLib.sol";
import "IGammaFarm.sol";

import "IStableSwapExchange.sol";
import "ILUSDToken.sol";
import "IStabilityPool.sol";
import "IPriceFeed.sol";
import "IWETH9.sol";

contract GammaFarmTestOnly is IGammaFarm, ReentrancyGuard, Ownable {
    IERC20 constant public malToken = IERC20(0x6619078Bdd8324E01E9a8D4b3d761b050E5ECF06);
    ILUSDToken constant public lusdToken = ILUSDToken(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
    IERC20 constant public lqtyToken = IERC20(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D);
    IWETH9 constant public wethToken = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant public usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant public daiToken = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IPriceFeed constant public priceFeed = IPriceFeed(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De);
    ISwapRouter constant public uniswapV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IStableSwapExchange constant public lusdCurvePool = IStableSwapExchange(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    IStabilityPool constant public lusdStabilityPool = IStabilityPool(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);

    uint256 constant public MAX_GOV_ONLY_EPOCH_DURATION_SECS = 7 * 24 * 60 * 60;  // 7 days
    uint256 constant public DECIMAL_PRECISION = 1e18;

    // --- Global MAL distribution parameters ---
    uint256 immutable public deploymentTime;
    uint256 immutable public malDistributionEndTime;
    uint256 immutable public malDecayPeriodSeconds;
    uint256 immutable public malDecayFactor;
    uint256 immutable public malToDistribute;
    uint256 immutable public malRewardPerSecond;

    // --- Data structures ---
    struct Snapshot {
        uint96 lusdProfitFactorCumP;
        uint160 malRewardPerAvailableCumS;
        uint256 malRewardPerStakedCumS;
    }
    struct AccountBalances {
        // lusdStakeData stores packed information about LUSD stake: {lusdToStake, lusdStaked, accountEpoch, shouldUnstake}, where:
        // * lusdToStake - amount of LUSD to be staked at the start of "accountEpoch + 1" epoch (uint112)
        // * lusdStaked - amount of LUSD staked at the start of "accountEpoch" epoch (uint112)
        // * accountEpoch - epoch of last user action (uint31)
        // * shouldUnstake - 0 or 1, whether an unstake should be done at the start of "accountEpoch + 1" epoch (bool)
        uint256 lusdStakeData;
        uint96 malRewards;  // amount of MAL rewards earned
        uint160 malRewardPerAvailableCumS;  // MAL cumulative sum value taken at the time of last account action
        uint256 lusdUnstaked;  // amount of LUSD unstaked
    }

    // --- Total balances and state variables ---
    uint128 public totalLusd;
    uint128 public totalLusdToStake;
    uint128 public totalLusdStaked;
    uint128 public totalLusdToUnstake;
    uint96 public lastTotalMalRewards;
    uint160 public lastMalRewardPerAvailableCumS;

    // --- Per account variables ---
    mapping(address => AccountBalances) public accountBalances;

    // --- Epoch variables ---
    mapping(uint32 => Snapshot) public epochSnapshots;  // snapshots of rewards state taken at the start of each epoch
    mapping(uint32 => uint32) public previousResetEpoch;
    uint256 public epochStartTime;
    uint32 public epoch;
    uint32 public lastResetEpoch;

    // --- Emergency variables ---
    bool public isEmergencyState;

    // --- Governance variables ---
    uint16 public malBurnPct = 3000;  // 30% (10000 = 100%)
    uint16 public minWethLusdAmountOutPct = 9500;  // 95% <=> 5% slippage (10000 = 100%)
    uint24 public defaultWethToStableTokenFee = 500;
    bool public defaultUseCurveForStableTokenToLusd = true;
    address public defaultWethToStableToken = address(usdcToken);

    constructor(
        uint256 _malToDistribute,
        uint256 _malDistributionPeriodSeconds,
        uint256 _malRewardPerSecond,
        uint256 _malDecayFactor,
        uint256 _malDecayPeriodSeconds
    ) {
        deploymentTime = block.timestamp;

        malDistributionEndTime = block.timestamp + _malDistributionPeriodSeconds;
        malDecayPeriodSeconds = _malDecayPeriodSeconds;
        malDecayFactor = _malDecayFactor;
        malToDistribute = _malToDistribute;
        malRewardPerSecond = _malRewardPerSecond;

        epochStartTime = block.timestamp;
        epochSnapshots[0].lusdProfitFactorCumP = uint96(DECIMAL_PRECISION);

        lqtyToken.approve(address(uniswapV3Router), type(uint256).max);
        wethToken.approve(address(uniswapV3Router), type(uint256).max);
        usdcToken.approve(address(lusdCurvePool), type(uint256).max);
        daiToken.approve(address(lusdCurvePool), type(uint256).max);
    }

    // --- Account methods ---

    function deposit(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external override nonReentrant {
        require(_lusdAmount >= 1e18, "minimum deposit is 1 LUSD");
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        // Transfer LUSD:
        lusdToken.permit(msg.sender, address(this), _lusdAmount, _deadline, _v, _r, _s);
        lusdToken.transferFrom(msg.sender, address(this), _lusdAmount);
        // Update total balances:
        totalLusd += uint128(_lusdAmount);
        totalLusdToStake += uint128(_lusdAmount);
        // Update account balances:
        (uint256 lusdToStake, uint256 lusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        newBalances.lusdStakeData = _packAccountStakeData(lusdToStake + _lusdAmount, lusdStaked, accountEpoch, shouldUnstake);
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
    }

    function unstake() external override nonReentrant {
        require(!isEmergencyState, "nothing to unstake");
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        (uint256 lusdToStake, uint256 lusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        require(lusdStaked != 0, "nothing to unstake");
        // Update total balances:
        if (!shouldUnstake) {
            totalLusdToUnstake += uint128(lusdStaked);
        }
        // Update account balances:
        newBalances.lusdStakeData = _packAccountStakeData(lusdToStake, lusdStaked, accountEpoch, true);
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
    }

    function withdraw() external override nonReentrant returns (uint256 _lusdAmountWithdrawn) {
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        (uint256 lusdToStake, uint256 lusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        bool isEmergencyState_ = isEmergencyState;
        // Allow withdrawing "staked" balance during emergency:
        _lusdAmountWithdrawn = lusdToStake + newBalances.lusdUnstaked + (isEmergencyState_ ? lusdStaked : 0);
        require(_lusdAmountWithdrawn != 0, "nothing to withdraw");
        // Transfer LUSD:
        lusdToken.transfer(msg.sender, _lusdAmountWithdrawn);
        // Transfer MAL:
        if (newBalances.malRewards != 0) {
            malToken.transfer(msg.sender, newBalances.malRewards);
            newBalances.malRewards = 0;
        }
        // Update total balances:
        totalLusd -= uint128(_lusdAmountWithdrawn);
        if (lusdToStake != 0) {
            totalLusdToStake -= uint128(lusdToStake);
            lusdToStake = 0;
        }
        if (isEmergencyState_ && lusdStaked != 0) {
            totalLusdStaked -= uint128(lusdStaked);
            lusdStaked = 0;
        }
        // Update account balances:
        newBalances.lusdStakeData = _packAccountStakeData(lusdToStake, lusdStaked, accountEpoch, shouldUnstake);
        newBalances.lusdUnstaked = 0;
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
        return _lusdAmountWithdrawn;
    }

    function unstakeAndWithdraw() external override nonReentrant returns (uint256 _lusdAmountWithdrawn) {
        require(!isEmergencyState, "nothing to unstake");
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        (uint256 lusdToStake, uint256 lusdStaked,, bool shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        require(lusdStaked != 0, "nothing to unstake");
        // Get staked LUSD amount at epoch start and after loss:
        uint256 totalLusdStakedBefore = totalLusdStaked;
        uint256 totalLusdStakedAfter = lusdStabilityPool.getCompoundedLUSDDeposit(address(this));
        require(totalLusdStakedBefore != 0 && totalLusdStakedAfter != 0, "nothing to unstake");
        // Calculate account new staked amount:
        uint256 lusdWithdrawnFromSP = lusdStaked * totalLusdStakedAfter / totalLusdStakedBefore;
        require(lusdWithdrawnFromSP != 0, "nothing to unstake");
        // Withdraw from stability pool:
        lusdStabilityPool.withdrawFromSP(lusdWithdrawnFromSP);
        _lusdAmountWithdrawn += lusdWithdrawnFromSP;
        // Withdraw from available balance:
        _lusdAmountWithdrawn += lusdToStake + newBalances.lusdUnstaked;
        // Transfer LUSD:
        lusdToken.transfer(msg.sender, _lusdAmountWithdrawn);
        // Transfer MAL:
        if (newBalances.malRewards != 0) {
            malToken.transfer(msg.sender, newBalances.malRewards);
        }
        // Update total balances:
        totalLusd -= uint128(lusdStaked + lusdToStake + newBalances.lusdUnstaked);
        totalLusdStaked = uint128(totalLusdStakedBefore - lusdStaked);
        if (lusdToStake != 0) {
            totalLusdToStake -= uint128(lusdToStake);
        }
        if (shouldUnstake) {
            totalLusdToUnstake -= uint128(lusdStaked);
        }
        // Update account balances:
        delete accountBalances[msg.sender];
    }

    function claim() external override nonReentrant {
        uint256 newLastMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        AccountBalances memory oldBalances = accountBalances[msg.sender];
        AccountBalances memory newBalances = _calculateAccountBalances(oldBalances, newLastMalRewardPerAvailableCumS);
        require(newBalances.malRewards != 0, "nothing to claim");
        // Transfer MAL:
        if (newBalances.malRewards != 0) {
            malToken.transfer(msg.sender, newBalances.malRewards);
            newBalances.malRewards = 0;
        }
        // Update account balances:
        _updateAccountBalances(msg.sender, oldBalances, newBalances);
    }

    // --- View balances methods ---

    function getAccountLUSDAvailable(address _account) public view override returns (uint256 _lusdAvailable) {
        (_lusdAvailable, , , ,) = getAccountBalances(_account);
    }

    function getAccountLUSDStaked(address _account) public view override returns (uint256 _lusdStaked) {
        (, _lusdStaked, , ,) = getAccountBalances(_account);
    }

    function getAccountMALRewards(address _account) public view override returns (uint256 _malRewards) {
        (, , _malRewards, ,) = getAccountBalances(_account);
    }

    function getAccountBalances(address _account) public view returns (uint256 _lusdAvailable, uint256 _lusdStaked, uint256 _malRewards, uint256 _lusdToStake, bool _shouldUnstake) {
        (,uint256 newLastMalRewardPerAvailableCumS) = _calculateMalRewardCumulativeSum(lastTotalMalRewards, lastMalRewardPerAvailableCumS);
        AccountBalances memory newBalances = _calculateAccountBalances(accountBalances[_account], newLastMalRewardPerAvailableCumS);
        (_lusdToStake, _lusdStaked,, _shouldUnstake) = _unpackAccountStakeData(newBalances.lusdStakeData);
        _lusdAvailable = _lusdToStake + newBalances.lusdUnstaked;
        _malRewards = newBalances.malRewards;
        if (isEmergencyState) {
            return (_lusdAvailable + _lusdStaked, 0, _malRewards, _lusdToStake + _lusdStaked, false);
        }
    }

    function getTotalBalances() public view returns (uint256, uint256) {
        return (totalLusd, isEmergencyState ? 0 : totalLusdStaked);
    }

    function getLastSnapshot() public view returns (Snapshot memory _snapshot) {
        return _buildSnapshot(lastMalRewardPerAvailableCumS, epoch);
    }

    // --- Governance methods ---

    function depositAsFarm(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external override onlyOwner {
        require(_lusdAmount >= 1e18, "minimum deposit is 1 LUSD");
        _updateMalRewardCumulativeSum();
        // Transfer LUSD to Farm:
        lusdToken.permit(msg.sender, address(this), _lusdAmount, _deadline, _v, _r, _s);
        lusdToken.transferFrom(msg.sender, address(this), _lusdAmount);
        // Update total balances:
        totalLusd += uint128(_lusdAmount);
        totalLusdToStake += uint128(_lusdAmount);
    }

    function setMALBurnPercentage(uint16 _pct) external override onlyOwner {
        require(_pct <= 10000, "must be <= 10000");
        malBurnPct = _pct;
    }

    function setDefaultTradeData(bytes memory _tradeData) external override onlyOwner {
        require(_tradeData.length != 0, "must not be empty");
        (defaultWethToStableToken, defaultWethToStableTokenFee, defaultUseCurveForStableTokenToLusd) = _validateTradeData(_tradeData);
    }

    /*
    * startNewEpoch():
    * - Harvest LUSD reward accumulated during this epoch
    * - Stake/withdraw from/to LUSD Stability Pool
    * - Save epoch snapshot
    */
    function startNewEpoch(bytes memory _tradeData) public override {
        require(!isEmergencyState, "must not be in emergency state");
        require(block.timestamp > epochStartTime, "must last at least one second");
        // Allow user to start new epoch if current epoch duration is above threshold:
        require(msg.sender == owner() || block.timestamp - epochStartTime > MAX_GOV_ONLY_EPOCH_DURATION_SECS, "caller must be an owner");

        // Cache:
        uint256 totalLusdToUnstake_ = totalLusdToUnstake;

        // Get staked LUSD amount at epoch start and after loss:
        uint256 totalLusdStakedBefore = totalLusdStaked;
        uint256 totalLusdStakedAfter = lusdStabilityPool.getCompoundedLUSDDeposit(address(this));

        // Harvest LQTY/ETH gains and unstake LUSD if needed:
        uint256 lusdToUnstake = 0;
        if (totalLusdStakedBefore != 0) {
            // Calculate amount to unstake taking into account compounding loss:
            lusdToUnstake = totalLusdStakedAfter * totalLusdToUnstake_ / totalLusdStakedBefore;
            lusdStabilityPool.withdrawFromSP(lusdToUnstake);
        }

        // Swap LQTY/ETH rewards for LUSD:
        uint256 lusdReward = _swapStabilityPoolRewardsForLUSD(_tradeData);

        // Calculate LUSD reward portion to unstake:
        uint256 lusdRewardToHold = 0;
        if (totalLusdStakedBefore != 0) {
            uint256 newTotalLusdToUnstake = (totalLusdStakedAfter + lusdReward) * totalLusdToUnstake_ / totalLusdStakedBefore;
            lusdRewardToHold = newTotalLusdToUnstake - lusdToUnstake;
        }

        // Stake LUSD to Stability Pool if needed:
        uint256 lusdToStake = totalLusdToStake + lusdReward - lusdRewardToHold;
        if (lusdToStake != 0) {
            lusdStabilityPool.provideToSP(lusdToStake, address(0));
        }

        // Calculate new total balances:
        uint256 newTotalLusd = totalLusd + lusdReward + totalLusdStakedAfter - totalLusdStakedBefore;
        uint256 newTotalLusdStaked = totalLusdStakedAfter + lusdToStake - lusdToUnstake;

        // Start new epoch:
        _updateNewEpochData(lusdReward, totalLusdStakedBefore, totalLusdStakedAfter, newTotalLusd);

        // Update total balances:
        totalLusd = uint128(newTotalLusd);
        totalLusdStaked = uint128(newTotalLusdStaked);
        totalLusdToStake = 0;
        totalLusdToUnstake = 0;
    }

    // --- Emergency methods ---

    function emergencyWithdraw(bytes memory _tradeData) external override onlyOwner {
        require(!isEmergencyState, "already in emergency state");
        require(block.timestamp > epochStartTime, "must last at least one second");
        // Set emergency state:
        isEmergencyState = true;

        // Cache:
        uint256 totalLusdToUnstake_ = totalLusdToUnstake;

        // Get staked LUSD amount at epoch start and after loss:
        uint256 totalLusdStakedBefore = totalLusdStaked;
        uint256 totalLusdStakedAfter = lusdStabilityPool.getCompoundedLUSDDeposit(address(this));

        // Withdraw everything from LUSD Stability Pool:
        if (totalLusdStakedBefore != 0) {
            lusdStabilityPool.withdrawFromSP(type(uint256).max);
        }

        // Swap LQTY/ETH rewards for LUSD:
        uint256 lusdReward = _swapStabilityPoolRewardsForLUSD(_tradeData);

        // Calculate stake/unstake amounts:
        uint256 lusdToUnstake = 0;
        uint256 lusdRewardToHold = 0;
        if (totalLusdStakedBefore != 0) {
            lusdToUnstake = totalLusdStakedAfter * totalLusdToUnstake_ / totalLusdStakedBefore;
            uint256 newTotalLusdToUnstake = (totalLusdStakedAfter + lusdReward) * totalLusdToUnstake_ / totalLusdStakedBefore;
            lusdRewardToHold = newTotalLusdToUnstake - lusdToUnstake;
        }
        uint256 lusdToStake = totalLusdToStake + lusdReward - lusdRewardToHold;

        // Calculate new total balances:
        uint256 newTotalLusd = totalLusd + lusdReward + totalLusdStakedAfter - totalLusdStakedBefore;
        uint256 newTotalLusdStaked = totalLusdStakedAfter + lusdToStake - lusdToUnstake;

        // Start new epoch:
        _updateNewEpochData(lusdReward, totalLusdStakedBefore, totalLusdStakedAfter, newTotalLusd);

        // Update total balances:
        totalLusd = uint128(newTotalLusd);
        totalLusdStaked = uint128(newTotalLusdStaked);
        totalLusdToStake = 0;
        totalLusdToUnstake = 0;
    }

    function emergencyRecover() external override onlyOwner {
        require(isEmergencyState, "must be in emergency state");
        // Unset emergency state:
        isEmergencyState = false;

        // Update cumulative sum:
        _updateMalRewardCumulativeSum();

        // Stake LUSD to Stability Pool:
        uint256 totalLusdStaked_ = totalLusdStaked;
        if (totalLusdStaked_ != 0) {
            lusdStabilityPool.provideToSP(totalLusdStaked_, address(0));
        }
    }

    // --- Internal methods ---

    /*
    * _updateNewEpochData():
    * - Update MAL cumulative sums
    * - Update LUSD profit cumulative product
    * - Save new epoch snapshot
    * - Advance epoch
    */
    function _updateNewEpochData(uint256 _lusdReward, uint256 _totalLusdStakedBefore, uint256 _totalLusdStakedAfter, uint256 _totalLusd) internal {
        uint32 epoch_ = epoch;
        Snapshot memory epochSnapshot = epochSnapshots[epoch_];
        // Calculate new MAL cumulative sums:
        uint256 newMalRewardPerAvailableCumS = _updateMalRewardCumulativeSum();
        uint256 newMalRewardPerStakedCumS = epochSnapshot.malRewardPerStakedCumS +
            (newMalRewardPerAvailableCumS - epochSnapshot.malRewardPerAvailableCumS) * epochSnapshot.lusdProfitFactorCumP / DECIMAL_PRECISION;
        // Calculate new LUSD profit cumulative product:
        uint256 newLusdProfitFactorCumP = (_totalLusdStakedBefore != 0)
            ? epochSnapshot.lusdProfitFactorCumP * (_lusdReward + _totalLusdStakedAfter) / _totalLusdStakedBefore
            : epochSnapshot.lusdProfitFactorCumP;
        if (newLusdProfitFactorCumP == 0) {
            newLusdProfitFactorCumP = DECIMAL_PRECISION;
            previousResetEpoch[epoch_ + 1] = lastResetEpoch;
            lastResetEpoch = epoch_ + 1;
        }
        // Save epoch snapshot:
        epochSnapshots[epoch_ + 1].lusdProfitFactorCumP = uint96(newLusdProfitFactorCumP);
        epochSnapshots[epoch_ + 1].malRewardPerAvailableCumS = uint160(newMalRewardPerAvailableCumS);
        epochSnapshots[epoch_ + 1].malRewardPerStakedCumS = newMalRewardPerStakedCumS;
        // Advance epoch:
        epoch = epoch_ + 1;
        epochStartTime = block.timestamp;
        // Report LUSD gain and loss:
        uint256 lusdProfitFactor = (_totalLusdStakedBefore != 0)
            ? (_lusdReward + _totalLusdStakedAfter) * DECIMAL_PRECISION / _totalLusdStakedBefore
            : DECIMAL_PRECISION;
        emit LUSDGainLossReported(epoch_, lusdProfitFactor, _lusdReward, _totalLusdStakedBefore - _totalLusdStakedAfter);
        // Emit new epoch started event:
        emit EpochStarted(epoch_ + 1, block.timestamp, _totalLusd);
    }

    // --- Update state methods ---

    function _updateAccountBalances(address _account, AccountBalances memory _oldBalances, AccountBalances memory _newBalances) internal {
        if ((_newBalances.lusdStakeData >> 32) == 0 && _newBalances.malRewards == 0 && _newBalances.lusdUnstaked == 0) {
            delete accountBalances[_account];
            return;
        }
        if (_oldBalances.lusdStakeData != _newBalances.lusdStakeData) {
            accountBalances[_account].lusdStakeData = _newBalances.lusdStakeData;
        }
        if (_oldBalances.malRewardPerAvailableCumS != _newBalances.malRewardPerAvailableCumS) {
            accountBalances[_account].malRewardPerAvailableCumS = _newBalances.malRewardPerAvailableCumS;
        }
        if (_oldBalances.malRewards != _newBalances.malRewards) {
            accountBalances[_account].malRewards = _newBalances.malRewards;
        }
        if (_oldBalances.lusdUnstaked != _newBalances.lusdUnstaked) {
            accountBalances[_account].lusdUnstaked = _newBalances.lusdUnstaked;
        }
    }

    function _updateMalRewardCumulativeSum() internal returns (uint256) {
        uint256 lastTotalMalRewards_ = lastTotalMalRewards;
        uint256 lastMalRewardPerAvailableCumS_ = lastMalRewardPerAvailableCumS;
        (uint256 newLastTotalMalRewards, uint256 newLastMalRewardPerAvailableCumS) = _calculateMalRewardCumulativeSum(
            lastTotalMalRewards_, lastMalRewardPerAvailableCumS_
        );
        if (lastTotalMalRewards_ != newLastTotalMalRewards) {
            lastTotalMalRewards = uint96(newLastTotalMalRewards);
        }
        if (lastMalRewardPerAvailableCumS_ != newLastMalRewardPerAvailableCumS) {
            lastMalRewardPerAvailableCumS = uint160(newLastMalRewardPerAvailableCumS);
        }
        return newLastMalRewardPerAvailableCumS;
    }

    // --- Calculate state methods ---

    function _buildSnapshot(uint256 _malRewardPerAvailableCumS, uint32 _epoch) internal view returns (Snapshot memory _snapshot) {
        _snapshot = epochSnapshots[_epoch];
        _snapshot.malRewardPerStakedCumS = _snapshot.malRewardPerStakedCumS +
            (_malRewardPerAvailableCumS - _snapshot.malRewardPerAvailableCumS) * _snapshot.lusdProfitFactorCumP / DECIMAL_PRECISION;
        _snapshot.malRewardPerAvailableCumS = uint160(_malRewardPerAvailableCumS);
    }

    function _calculateMalRewardCumulativeSum(uint256 _lastTotalMalRewards, uint256 _lastMalRewardsPerAvailableCumS) internal view returns (
        uint256 _newLastTotalMalRewards,
        uint256 _newLastMalRewardsPerAvailableCumS
    ) {
        _newLastMalRewardsPerAvailableCumS = _lastMalRewardsPerAvailableCumS;
        // Calculate MAL reward since last update:
        uint256 newUpdateTime = block.timestamp < malDistributionEndTime ? block.timestamp : malDistributionEndTime;
        _newLastTotalMalRewards = _calculateTotalMalRewards(newUpdateTime);
        uint256 malRewardSinceLastUpdate = _newLastTotalMalRewards - _lastTotalMalRewards;
        if (malRewardSinceLastUpdate == 0) {
            return (_newLastTotalMalRewards, _newLastMalRewardsPerAvailableCumS);
        }
        // Calculate new MAL cumulative sum:
        uint256 totalLusd_ = totalLusd;
        if (totalLusd_ != 0) {
            _newLastMalRewardsPerAvailableCumS += malRewardSinceLastUpdate * DECIMAL_PRECISION / totalLusd_;
        }
    }

    function _calculateAccountBalances(AccountBalances memory _oldBalances, uint256 _newLastMalRewardPerAvailableCumS) internal view returns (AccountBalances memory _newBalances) {
        uint32 epoch_ = epoch;
        uint32 lastResetEpoch_ = lastResetEpoch;
        (uint256 newLusdToStake, uint256 newLusdStaked, uint32 accountEpoch, bool shouldUnstake) = _unpackAccountStakeData(_oldBalances.lusdStakeData);
        uint256 newLusdUnstaked = _oldBalances.lusdUnstaked;
        uint256 newMalRewards = _oldBalances.malRewards;
        // Calculate account balances at the end of last account action epoch:
        Snapshot memory fromSnapshot = _buildSnapshot(_oldBalances.malRewardPerAvailableCumS, accountEpoch);
        if (accountEpoch != epoch_ && (newLusdToStake != 0 || shouldUnstake)) {
            Snapshot memory accountEpochSnapshot = epochSnapshots[accountEpoch + 1];
            (newLusdStaked, newMalRewards) = _calculateAccountBalancesFromToSnapshots(
                newLusdUnstaked + newLusdToStake, newLusdStaked, newMalRewards, fromSnapshot, accountEpochSnapshot
            );
            if (lastResetEpoch_ != 0 && (accountEpoch + 1 == lastResetEpoch_ || previousResetEpoch[accountEpoch + 1] != 0)) {
                newLusdStaked = 0;
            }
            // Perform adjustment:
            if (shouldUnstake) {
                newLusdUnstaked += newLusdStaked;
                newLusdStaked = 0;
                shouldUnstake = false;
            }
            if (newLusdToStake != 0) {
                newLusdStaked += newLusdToStake;
                newLusdToStake = 0;
            }
            fromSnapshot = accountEpochSnapshot;
        }
        // Check practically impossible event of epoch reset:
        if (lastResetEpoch_ != 0 && lastResetEpoch_ > accountEpoch + 1) {
            uint32 resetEpoch = lastResetEpoch_;
            while (previousResetEpoch[resetEpoch] > accountEpoch + 1) {
                resetEpoch = previousResetEpoch[resetEpoch];
            }
            Snapshot memory resetEpochSnapshot = epochSnapshots[resetEpoch];
            (newLusdStaked, newMalRewards) = _calculateAccountBalancesFromToSnapshots(
                newLusdUnstaked + newLusdToStake, newLusdStaked, newMalRewards, fromSnapshot, resetEpochSnapshot
            );
            newLusdStaked = 0;
            fromSnapshot = resetEpochSnapshot;
        }
        // Calculate account balance changes from fromSnapshot to lastSnapshot:
        Snapshot memory lastSnapshot = _buildSnapshot(_newLastMalRewardPerAvailableCumS, epoch_);
        (newLusdStaked, newMalRewards) = _calculateAccountBalancesFromToSnapshots(
            newLusdUnstaked + newLusdToStake, newLusdStaked, newMalRewards, fromSnapshot, lastSnapshot
        );
        // New balances:
        _newBalances.lusdStakeData = _packAccountStakeData(newLusdToStake, newLusdStaked, epoch_, shouldUnstake);
        _newBalances.malRewardPerAvailableCumS = uint160(_newLastMalRewardPerAvailableCumS);
        _newBalances.malRewards = uint96(newMalRewards);
        _newBalances.lusdUnstaked = newLusdUnstaked;
    }

    function _calculateAccountBalancesFromToSnapshots(
        uint256 _lusdAvailable, uint256 _lusdStaked, uint256 _malRewards,
        Snapshot memory _fromSnapshot, Snapshot memory _toSnapshot
    ) internal view returns (uint256 _lusdStakedAfter, uint256 _malRewardsAfter) {
        _malRewardsAfter = _malRewards +
            (_lusdStaked * (_toSnapshot.malRewardPerStakedCumS - _fromSnapshot.malRewardPerStakedCumS) / _fromSnapshot.lusdProfitFactorCumP) +
            (_lusdAvailable * (_toSnapshot.malRewardPerAvailableCumS - _fromSnapshot.malRewardPerAvailableCumS) / DECIMAL_PRECISION);
        _lusdStakedAfter = _lusdStaked * _toSnapshot.lusdProfitFactorCumP / _fromSnapshot.lusdProfitFactorCumP;
    }

    function _calculateTotalMalRewards(uint256 timestamp) internal view returns (uint256 _totalMalRewards) {
        uint256 F = malDecayFactor;
        uint256 elapsedSecs = timestamp - deploymentTime;
        if (F == DECIMAL_PRECISION) {
            return malRewardPerSecond * elapsedSecs;
        }
        uint256 decayT = malDecayPeriodSeconds;
        uint256 epochs = elapsedSecs / decayT;
        uint256 powF = _calculateDecayPower(F, epochs);
        uint256 cumFraction = (DECIMAL_PRECISION - powF) * DECIMAL_PRECISION / (DECIMAL_PRECISION - F);
        _totalMalRewards = (malRewardPerSecond * cumFraction / DECIMAL_PRECISION) * decayT;
        uint256 secs = elapsedSecs - decayT * epochs;
        if (secs != 0) {
            _totalMalRewards += (malRewardPerSecond * powF / DECIMAL_PRECISION) * secs;
        }
    }

    function _calculateDecayPower(uint256 _f, uint256 _n) internal pure returns (uint256) {
        return GammaLib.decPow(_f, _n);
    }

    function _packAccountStakeData(uint256 _lusdToStake, uint256 _lusdStaked, uint32 _epoch, bool _shouldUnstake) internal pure returns (uint256) {
        return (_lusdToStake << 144) | (_lusdStaked << 32) | (_epoch << 1) | (_shouldUnstake ? 1 : 0);
    }

    function _unpackAccountStakeData(uint256 _stakeData) internal pure returns (uint256 _lusdToStake, uint256 _lusdStaked, uint32 _epoch, bool _shouldUnstake) {
        _lusdToStake = _stakeData >> 144;
        _lusdStaked = (_stakeData >> 32) & ((1 << 112) - 1);
        _epoch = uint32((_stakeData >> 1) & ((1 << 31) - 1));
        _shouldUnstake = (_stakeData & 1) == 1;
    }

    // --- Trade methods ---

    /*
     * _swapStabilityPoolRewardsForLUSD(_tradeData):
     * Swaps ETH and LQTY balances for LUSD and returns LUSD amount received:
     * 1) LQTY is swapped for WETH on UniswapV3 via [LQTY/WETH/3000]
     * 2) "malBurnPct"% of received WETH is swapped for MAL on UniswapV3 via [WETH/MAL/3000] and burned
     * 3) Remaining WETH (+ETH amount) is swapped for LUSD using _tradeData:
     * If _tradeData is empty:
     *   WETH->LUSD swap is done using "default" contract variables (defaultWethToStableToken, defaultWethToStableTokenFee,
     *   defaultUseCurveForStableTokenToLusd) the same way as described below for _tradeData
     * Else _tradeData must encode 3 variables: [stableToken, wethToStableTokenFee, useCurveForStableTokenToLusd]
     *   - stableToken is an address of either LUSD, USDC or DAI,
     *   - wethToStableTokenFee is uint24 and is either 500 or 3000,
     *   - useCurveForStableTokenToLusd is a boolean
     *   If stableToken is LUSD:
     *     - wethToStableTokenFee must be 3000 and useCurveForStableTokenToLusd must be false
     *     - WETH is swapped for LUSD on UniswapV3 via [WETH/LUSD/3000]
     *   If stableToken is USDC or DAI:
     *     If useCurveForStableTokenToLusd is false:
     *       - WETH is swapped for LUSD on UniswapV3 via multihop swap: [WETH/stableToken/wethToStableTokenFee, stableToken/LUSD/500]
     *     If useCurveForStableTokenToLusd is true:
     *       - WETH is swapped for stableToken (USDC|DAI) on UniswapV3 via: [WETH/stableToken/wethToStableTokenFee]
     *       - Then stableToken (USDC|DAI) is swapped for LUSD on Curve LUSD3CRV-f Metapool
     * 4) Received LUSD amount is checked against PriceFeed ETH/USD price to limit slippage
    */
    function _swapStabilityPoolRewardsForLUSD(bytes memory _tradeData) internal returns (uint256) {
        // Get amounts to trade:
        uint256 lqtyAmount = lqtyToken.balanceOf(address(this));
        uint256 ethAmount = address(this).balance;
        if (lqtyAmount == 0 && ethAmount == 0) {
            return 0;
        }
        if (ethAmount != 0) {
            wethToken.deposit{value: ethAmount}();
        }

        // Check no trades were done in current block for UniswapV3 pools we are about to use (to avoid beign frontran):
        (address stableToken, uint24 wethToStableTokenFee, bool useCurveForStableTokenToLusd) = (_tradeData.length > 0) ?
            _validateTradeData(_tradeData)
            : (defaultWethToStableToken, defaultWethToStableTokenFee, defaultUseCurveForStableTokenToLusd);
        _requireNoTradesInCurrentBlock(stableToken, wethToStableTokenFee, useCurveForStableTokenToLusd);

        uint256 wethAmountToBuyLusd = ethAmount;
        if (lqtyAmount != 0) {
            // Swap LQTY rewards for WETH (via LQTY/WETH/3000):
            uint256 wethAmountOut = uniswapV3Router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(lqtyToken),
                    tokenOut: address(wethToken),
                    fee: uint24(3000),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: lqtyAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            // Swap "malBurnPct"% of received WETH for MAL (via WETH/MAL/3000):
            uint256 wethAmountToBuyMal = wethAmountOut * malBurnPct / 10000;
            wethAmountToBuyLusd += (wethAmountOut - wethAmountToBuyMal);
            uint256 malAmountOut = uniswapV3Router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(wethToken),
                    tokenOut: address(malToken),
                    fee: uint24(3000),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: wethAmountToBuyMal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            // Burn received MAL tokens:
            malToken.transfer(address(0x000000000000000000000000000000000000dEaD), malAmountOut);
        }
        if (wethAmountToBuyLusd == 0) {
            return 0;
        }

        // Calculate min amount out using oracle price:
        uint256 ethUsdPrice = priceFeed.fetchPrice();
        uint256 usdAmountOutMin = wethAmountToBuyLusd * ethUsdPrice * minWethLusdAmountOutPct / 10000 / DECIMAL_PRECISION;
        // Decode trade data:
        uint256 lusdAmountOut;
        if (useCurveForStableTokenToLusd || stableToken == address(lusdToken)) {
            // Swap WETH for "stableToken" on UniswapV3:
            uint256 stableTokenAmountOut = uniswapV3Router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(wethToken),
                    tokenOut: stableToken,
                    fee: uint24(wethToStableTokenFee),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: wethAmountToBuyLusd,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            // Swap "stableToken" for LUSD on Curve (if needed):
            if (stableToken == address(lusdToken)) {
                lusdAmountOut = stableTokenAmountOut;
            } else if (stableToken == address(usdcToken)) {
                lusdAmountOut = lusdCurvePool.exchange_underlying(2, 0, stableTokenAmountOut, usdAmountOutMin);
            } else if (stableToken == address(daiToken)) {
                lusdAmountOut = lusdCurvePool.exchange_underlying(1, 0, stableTokenAmountOut, usdAmountOutMin);
            }
        } else {
            // Swap WETH for LUSD on UniswapV3:
            lusdAmountOut = uniswapV3Router.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(address(wethToken), uint24(wethToStableTokenFee), stableToken, uint24(500), address(lusdToken)),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: wethAmountToBuyLusd,
                    amountOutMinimum: usdAmountOutMin
                })
            );
        }
        // Check slippage:
        require(lusdAmountOut >= usdAmountOutMin, "received too little");
        return lusdAmountOut;
    }

    function _requireNoTradesInCurrentBlock(address _wethToStableToken, uint24 _wethToStableTokenFee, bool _useCurveForStableTokenToLusd) internal {
        _requireNoUniswapV3PoolTradesInCurrentBlock(0xD1D5A4c0eA98971894772Dcd6D2f1dc71083C44E);  // LQTY/WETH/3000
        _requireNoUniswapV3PoolTradesInCurrentBlock(0x41506D56B16794e4F7F423AEFF366740D4bdd387);  // WETH/MAL/3000
        if (_wethToStableToken == address(lusdToken)) {
            _requireNoUniswapV3PoolTradesInCurrentBlock(0x9663f2CA0454acCad3e094448Ea6f77443880454);  // WETH/LUSD/3000
        } else if (_wethToStableToken == address(usdcToken)) {
            (_wethToStableTokenFee == 500) ?
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640)     // WETH/USDC/500
                : _requireNoUniswapV3PoolTradesInCurrentBlock(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8);  // WETH/USDC/3000
            if (!_useCurveForStableTokenToLusd) {
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x4e0924d3a751bE199C426d52fb1f2337fa96f736);  // USDC/LUSD/500
            }
        } else if (_wethToStableToken == address(daiToken)) {
            (_wethToStableTokenFee == 500) ?
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x60594a405d53811d3BC4766596EFD80fd545A270)     // WETH/DAI/500
                : _requireNoUniswapV3PoolTradesInCurrentBlock(0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8);  // WETH/DAI/3000
            if (!_useCurveForStableTokenToLusd) {
                _requireNoUniswapV3PoolTradesInCurrentBlock(0x16980C16811bDe2B3358c1Ce4341541a4C772Ec9);  // DAI/LUSD/500
            }
        }
        if (_useCurveForStableTokenToLusd) {
            _requireNoLusdCurvePoolTradesInCurrentBlock();
        }
    }

    function _requireNoUniswapV3PoolTradesInCurrentBlock(address _poolAddress) internal {
        (,,uint16 observationIndex,,,,) = IUniswapV3Pool(_poolAddress).slot0();
        (uint32 blockTimestamp,,,) = IUniswapV3Pool(_poolAddress).observations(observationIndex);
        require(blockTimestamp != block.timestamp, "frontrun protection");
    }

    function _requireNoLusdCurvePoolTradesInCurrentBlock() internal {
        require(lusdCurvePool.block_timestamp_last() != block.timestamp, "frontrun protection");
    }

    function _validateTradeData(bytes memory _tradeData) internal returns (address _stableToken, uint24 _wethToStableTokenFee, bool _useCurveForStableTokenToLusd) {
        (_stableToken, _wethToStableTokenFee, _useCurveForStableTokenToLusd) = abi.decode(_tradeData, (address, uint24, bool));
        require(_stableToken == address(lusdToken) || _stableToken == address(usdcToken) || _stableToken == address(daiToken), "invalid trade data");
        if (_stableToken == address(lusdToken)) {
            require(_wethToStableTokenFee == 3000 && _useCurveForStableTokenToLusd == false, "invalid trade data");
        } else {
            require(_wethToStableTokenFee == 500 || _wethToStableTokenFee == 3000, "invalid trade data");
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.7.0;

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

    constructor () {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "IUniswapV3PoolImmutables.sol";
import "IUniswapV3PoolState.sol";
import "IUniswapV3PoolDerivedState.sol";
import "IUniswapV3PoolActions.sol";
import "IUniswapV3PoolOwnerActions.sol";
import "IUniswapV3PoolEvents.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "SafeMath.sol";

library GammaLib {
    using SafeMath for uint256;

    uint256 internal constant DECIMAL_PRECISION = 1e18;

    /* 
    * Exponentiation function for 18-digit decimal base, and integer exponent n.
    * O(log(n)) complexity.
    */
    function decPow(uint256 _a, uint256 _n) internal pure returns (uint256) {
        if (_n == 0) {return DECIMAL_PRECISION;}

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _a;
        uint256 n = _n;
        while (n > 1) {
            if (n & 1 == 0) {
                x = _decMul(x, x);
                n = n.div(2);
            } else {
                y = _decMul(x, y);
                x = _decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }
        return _decMul(x, y);
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * - round product up if 19'th mantissa digit >= 5
    * - round product down if 19'th mantissa digit < 5
    */
    function _decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x.mul(y);
        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

interface IGammaFarm {
    function deposit(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
    function unstake() external;
    function withdraw() external returns (uint256);
    function unstakeAndWithdraw() external returns (uint256);
    function claim() external;

    // --- View methods ---
    function getAccountLUSDAvailable(address _account) external view returns (uint256);
    function getAccountLUSDStaked(address _account) external view returns (uint256);
    function getAccountMALRewards(address _account) external view returns (uint256);

    // --- Emergency methods ---
    function emergencyWithdraw(bytes memory _tradeData) external;
    function emergencyRecover() external;

    // --- Owner methods ---
    function startNewEpoch(bytes memory _tradeData) external;
    function depositAsFarm(uint256 _lusdAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
    function setMALBurnPercentage(uint16 _pct) external;
    function setDefaultTradeData(bytes memory _tradeData) external;

    // --- Events ---
    event EpochStarted(uint256 epoch, uint256 timestamp, uint256 totalLUSD);
    event LUSDGainLossReported(uint256 epoch, uint256 LUSDProfitFactor, uint256 LUSDGain, uint256 LUSDLoss);
}

// SPDX-License-Identifier: Copyright (c) Curve.Fi, 2021 - all rights reserved
pragma solidity =0.7.6;

interface IStableSwapExchange {
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function block_timestamp_last() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

import "IERC20.sol";

interface ILUSDToken is IERC20 {
    // --- Events ---
    event TroveManagerAddressChanged(address troveManagerAddress);
    event StabilityPoolAddressChanged(address newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address newBorrowerOperationsAddress);
    event LUSDTokenBalanceUpdated(address user, uint amount);

    // --- Functions ---
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function sendToPool(address sender,  address poolAddress, uint256 amount) external;
    function returnFromPool(address poolAddress, address receiver, uint256 amount) external;
    
    // --- EIP 2612 Functionality ---
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function domainSeparator() external view returns (bytes32);
    function permitTypeHash() external view returns (bytes32);

    // --- IERC20 Extra Functionality ---
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/*
 * The Stability Pool holds LUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its LUSD debt gets offset with
 * LUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of LUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a LUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total LUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- LQTY ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An LQTY issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued LQTY in proportion to the deposit as a share of total deposits. The LQTY earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#lqty-issuance-to-stability-providers
 */
interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolLUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _LUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint _LQTY);
    event LQTYPaidToFrontEnd(address indexed _frontEnd, uint _LQTY);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
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
    function registerFrontEnd(uint _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, uint _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint);

    /*
     * Returns LUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalLUSDDeposits() external view returns (uint);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint);

    /*
     * Return the LQTY gain earned by the front end.
     */
    function getFrontEndLQTYGain(address _frontEnd) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint);

    /*
     * Fallback function
     * Only callable by Active Pool, it just accounts for ETH received
     * receive() external payable;
     */
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // --- Function ---
    function fetchPrice() external returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}