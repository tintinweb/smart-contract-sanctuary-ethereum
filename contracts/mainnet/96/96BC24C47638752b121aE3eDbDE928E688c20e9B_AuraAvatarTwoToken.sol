// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MathUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import {PausableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {SafeERC20Upgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from
    "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {BaseAvatar} from "../lib/BaseAvatar.sol";
import {MAX_BPS, PRECISION} from "../BaseConstants.sol";
import {BpsConfig, TokenAmount} from "../BaseStructs.sol";
import {AuraAvatarUtils} from "./AuraAvatarUtils.sol";
import {IBaseRewardPool} from "../interfaces/aura/IBaseRewardPool.sol";
import {IAsset} from "../interfaces/balancer/IAsset.sol";
import {IBalancerVault, JoinKind} from "../interfaces/balancer/IBalancerVault.sol";
import {KeeperCompatibleInterface} from "../interfaces/chainlink/KeeperCompatibleInterface.sol";

/// @title AuraAvatarTwoToken
/// @notice This contract handles two Balancer Pool Token (BPT) positions on behalf of an owner. It stakes the BPTs on
///         Aura and has the resulting BAL and AURA rewards periodically harvested by a keeper. Only the owner can
///         deposit and withdraw funds through this contract.
///         The owner also has admin rights and can make arbitrary calls through this contract.
/// @dev The avatar is never supposed to hold funds and only acts as an intermediary to facilitate staking and ease
///      accounting.
contract AuraAvatarTwoToken is BaseAvatar, PausableUpgradeable, AuraAvatarUtils, KeeperCompatibleInterface {
    ////////////////////////////////////////////////////////////////////////////
    // LIBRARIES
    ////////////////////////////////////////////////////////////////////////////

    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    ////////////////////////////////////////////////////////////////////////////
    // IMMUTABLES
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Pool ID (in AURA Booster) of the first token.
    uint256 public immutable pid1;
    /// @notice Pool ID (in AURA Booster) of the second token.
    uint256 public immutable pid2;

    /// @notice Address of the first BPT.
    IERC20MetadataUpgradeable public immutable asset1;
    /// @notice Address of the second BPT.
    IERC20MetadataUpgradeable public immutable asset2;

    /// @notice Address of the staking rewards contract for the first token.
    IBaseRewardPool public immutable baseRewardPool1;
    /// @notice Address of the staking rewards contract for the second token.
    IBaseRewardPool public immutable baseRewardPool2;

    ////////////////////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Address of the manager of the avatar. Manager has limited permissions and can harvest rewards or
    ///         fine-tune operational settings.
    address public manager;
    /// @notice Address of the keeper of the avatar. Keeper can only harvest rewards at a predefined frequency.
    address public keeper;

    /// @notice The frequency (in seconds) at which the keeper should harvest rewards.
    uint256 public claimFrequency;
    /// @notice The duration for which AURA and BAL/ETH BPT TWAPs should be calculated. The TWAPs are used to set
    ///         slippage constraints during swaps.
    uint256 public twapPeriod;

    /// @notice The proportion of BAL that is sold for USDC.
    uint256 public sellBpsBalToUsdc;
    /// @notice The proportion of AURA that is sold for USDC.
    uint256 public sellBpsAuraToUsdc;

    /// @notice The current and minimum value (in bps) controlling the minimum executable price (as proprtion of oracle
    ///         price) for a BAL to USDC swap.
    BpsConfig public minOutBpsBalToUsdc;
    /// @notice The current and minimum value (in bps) controlling the minimum executable price (as proprtion of oracle
    ///         price) for an AURA to USDC swap.
    BpsConfig public minOutBpsAuraToUsdc;

    /// @notice The current and minimum value (in bps) controlling the minimum executable price (as proprtion of oracle
    ///         price) for a BAL to BAL/ETH BPT swap.
    BpsConfig public minOutBpsBalToBpt;

    /// @notice The timestamp at which rewards were last claimed and harvested.
    uint256 public lastClaimTimestamp;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NotOwnerOrManager(address caller);
    error NotKeeper(address caller);

    error InvalidBps(uint256 bps);
    error LessThanBpsMin(uint256 bpsVal, uint256 bpsMin);
    error MoreThanBpsVal(uint256 bpsMin, uint256 bpsVal);
    error ZeroTwapPeriod();

    error NothingToDeposit();
    error NothingToWithdraw();
    error NoRewards();

    error TooSoon(uint256 currentTime, uint256 updateTime, uint256 minDuration);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event ManagerUpdated(address indexed newManager, address indexed oldManager);
    event KeeperUpdated(address indexed newKeeper, address indexed oldKeeper);

    event TwapPeriodUpdated(uint256 newTwapPeriod, uint256 oldTwapPeriod);
    event ClaimFrequencyUpdated(uint256 newClaimFrequency, uint256 oldClaimFrequency);

    event SellBpsBalToUsdcUpdated(uint256 newValue, uint256 oldValue);
    event SellBpsAuraToUsdcUpdated(uint256 newValue, uint256 oldValue);

    event MinOutBpsBalToUsdcMinUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsAuraToUsdcMinUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsBalToBptMinUpdated(uint256 newValue, uint256 oldValue);

    event MinOutBpsBalToUsdcValUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsAuraToUsdcValUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsBalToBptValUpdated(uint256 newValue, uint256 oldValue);

    event Deposit(address indexed token, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed token, uint256 amount, uint256 timestamp);

    event RewardClaimed(address indexed token, uint256 amount, uint256 timestamp);
    event RewardsToStable(address indexed token, uint256 amount, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Derives the assets to be handled and corresponding reward pools based on the Aura Pool IDs supplied.
    /// @param _pid1 Pool ID of the first token.
    /// @param _pid2 Pool ID of the second token.
    constructor(uint256 _pid1, uint256 _pid2) {
        pid1 = _pid1;
        pid2 = _pid2;

        (address lpToken1,,, address crvRewards1,,) = AURA_BOOSTER.poolInfo(_pid1);
        (address lpToken2,,, address crvRewards2,,) = AURA_BOOSTER.poolInfo(_pid2);

        asset1 = IERC20MetadataUpgradeable(lpToken1);
        asset2 = IERC20MetadataUpgradeable(lpToken2);

        baseRewardPool1 = IBaseRewardPool(crvRewards1);
        baseRewardPool2 = IBaseRewardPool(crvRewards2);
    }

    /// @notice Initializes the avatar. Calls parent intializers, sets default variable values and does token approvals.
    ///         Can only be called once.
    /// @param _owner Address of the initial owner.
    /// @param _manager Address of the initial manager.
    /// @param _keeper Address of the initial keeper.
    function initialize(address _owner, address _manager, address _keeper) public initializer {
        __BaseAvatar_init(_owner);
        __Pausable_init();

        manager = _manager;
        keeper = _keeper;

        claimFrequency = 1 weeks;
        twapPeriod = 1 hours;

        sellBpsBalToUsdc = 7000; // 70%
        sellBpsAuraToUsdc = 3000; // 30%

        minOutBpsBalToUsdc = BpsConfig({
            val: 9750, // 97.5%
            min: 9000 // 90%
        });
        minOutBpsAuraToUsdc = BpsConfig({
            val: 9750, // 97.5%
            min: 9000 // 90%
        });
        minOutBpsBalToBpt = BpsConfig({
            val: 9950, // 99.5%
            min: 9000 // 90%
        });

        // Booster approval for both bpt
        asset1.safeApprove(address(AURA_BOOSTER), type(uint256).max);
        asset2.safeApprove(address(AURA_BOOSTER), type(uint256).max);

        // Balancer vault approvals
        BAL.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        AURA.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        BPT_80BAL_20WETH.safeApprove(address(BALANCER_VAULT), type(uint256).max);

        AURA.safeApprove(address(AURA_LOCKER), type(uint256).max);

        BPT_80BAL_20WETH.safeApprove(address(AURABAL_DEPOSITOR), type(uint256).max);
        AURABAL.safeApprove(address(BAURABAL), type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Checks whether a call is from the owner or manager.
    modifier onlyOwnerOrManager() {
        if (msg.sender != owner() && msg.sender != manager) {
            revert NotOwnerOrManager(msg.sender);
        }
        _;
    }

    /// @notice Checks whether a call is from the keeper.
    modifier onlyKeeper() {
        if (msg.sender != keeper) {
            revert NotKeeper(msg.sender);
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner - Pausing
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Pauses harvests. Can only be called by the owner or the manager.
    function pause() external onlyOwnerOrManager {
        _pause();
    }

    /// @notice Unpauses harvests. Can only be called by the owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner - Config
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Updates the manager address. Can only be called by owner.
    /// @param _manager Address of the new manager.
    function setManager(address _manager) external onlyOwner {
        address oldManager = manager;

        manager = _manager;
        emit ManagerUpdated(_manager, oldManager);
    }

    /// @notice Updates the keeper address. Can only be called by owner.
    /// @param _keeper Address of the new keeper.
    function setKeeper(address _keeper) external onlyOwner {
        address oldKeeper = keeper;

        keeper = _keeper;
        emit KeeperUpdated(_keeper, oldKeeper);
    }

    /// @notice Updates the duration for which Balancer TWAPs are calculated. Can only be called by owner.
    /// @param _twapPeriod The new TWAP period in seconds.
    function setTwapPeriod(uint256 _twapPeriod) external onlyOwner {
        if (_twapPeriod == 0) {
            revert ZeroTwapPeriod();
        }

        uint256 oldTwapPeriod = twapPeriod;

        twapPeriod = _twapPeriod;
        emit TwapPeriodUpdated(_twapPeriod, oldTwapPeriod);
    }

    /// @notice Updates the frequency at which rewards are processed by the keeper. Can only be called by owner.
    /// @param _claimFrequency The new claim frequency in seconds.
    function setClaimFrequency(uint256 _claimFrequency) external onlyOwner {
        uint256 oldClaimFrequency = claimFrequency;

        claimFrequency = _claimFrequency;
        emit ClaimFrequencyUpdated(_claimFrequency, oldClaimFrequency);
    }

    /// @notice Updates the proportion of BAL that is sold for USDC. Can only be called by owner.
    /// @param _sellBpsBalToUsdc The new proportion in bps.
    function setSellBpsBalToUsdc(uint256 _sellBpsBalToUsdc) external onlyOwner {
        if (_sellBpsBalToUsdc > MAX_BPS) {
            revert InvalidBps(_sellBpsBalToUsdc);
        }

        uint256 oldSellBpsBalToUsdc = sellBpsBalToUsdc;
        sellBpsBalToUsdc = _sellBpsBalToUsdc;

        emit SellBpsBalToUsdcUpdated(_sellBpsBalToUsdc, oldSellBpsBalToUsdc);
    }

    /// @notice Updates the proportion of AURA that is sold for USDC. Can only be called by owner.
    /// @param _sellBpsAuraToUsdc The new proportion in bps.
    function setSellBpsAuraToUsdc(uint256 _sellBpsAuraToUsdc) external onlyOwner {
        if (_sellBpsAuraToUsdc > MAX_BPS) {
            revert InvalidBps(_sellBpsAuraToUsdc);
        }

        uint256 oldSellBpsAuraToUsdc = sellBpsAuraToUsdc;
        sellBpsAuraToUsdc = _sellBpsAuraToUsdc;

        emit SellBpsAuraToUsdcUpdated(_sellBpsAuraToUsdc, oldSellBpsAuraToUsdc);
    }

    /// @notice Updates the minimum possible value for the minimum executable price (in bps as proportion of an oracle
    ///         price) for a BAL to USDC swap. Can only be called by owner.
    /// @param _minOutBpsBalToUsdcMin The new minimum value in bps.
    function setMinOutBpsBalToUsdcMin(uint256 _minOutBpsBalToUsdcMin) external onlyOwner {
        if (_minOutBpsBalToUsdcMin > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToUsdcMin);
        }

        uint256 minOutBpsBalToUsdcVal = minOutBpsBalToUsdc.val;
        if (_minOutBpsBalToUsdcMin > minOutBpsBalToUsdcVal) {
            revert MoreThanBpsVal(_minOutBpsBalToUsdcMin, minOutBpsBalToUsdcVal);
        }

        uint256 oldMinOutBpsBalToUsdcMin = minOutBpsBalToUsdc.min;
        minOutBpsBalToUsdc.min = _minOutBpsBalToUsdcMin;

        emit MinOutBpsBalToUsdcMinUpdated(_minOutBpsBalToUsdcMin, oldMinOutBpsBalToUsdcMin);
    }

    /// @notice Updates the minimum possible value for the minimum executable price (in bps as proportion of an oracle
    ///         price) for an AURA to USDC swap. Can only be called by owner.
    /// @param _minOutBpsAuraToUsdcMin The new minimum value in bps.
    function setMinOutBpsAuraToUsdcMin(uint256 _minOutBpsAuraToUsdcMin) external onlyOwner {
        if (_minOutBpsAuraToUsdcMin > MAX_BPS) {
            revert InvalidBps(_minOutBpsAuraToUsdcMin);
        }

        uint256 minOutBpsAuraToUsdcVal = minOutBpsAuraToUsdc.val;
        if (_minOutBpsAuraToUsdcMin > minOutBpsAuraToUsdcVal) {
            revert MoreThanBpsVal(_minOutBpsAuraToUsdcMin, minOutBpsAuraToUsdcVal);
        }

        uint256 oldMinOutBpsAuraToUsdcMin = minOutBpsAuraToUsdc.min;
        minOutBpsAuraToUsdc.min = _minOutBpsAuraToUsdcMin;

        emit MinOutBpsAuraToUsdcMinUpdated(_minOutBpsAuraToUsdcMin, oldMinOutBpsAuraToUsdcMin);
    }

    /// @notice Updates the minimum possible value for the minimum executable price (in bps as proportion of an oracle
    ///         price) for a BAL to 80BAL-20WETH BPT swap. Can only be called by owner.
    /// @param _minOutBpsBalToBptMin The new minimum value in bps.
    function setMinOutBpsBalToBptMin(uint256 _minOutBpsBalToBptMin) external onlyOwner {
        if (_minOutBpsBalToBptMin > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToBptMin);
        }

        uint256 minOutBpsBalToBptVal = minOutBpsBalToBpt.val;
        if (_minOutBpsBalToBptMin > minOutBpsBalToBptVal) {
            revert MoreThanBpsVal(_minOutBpsBalToBptMin, minOutBpsBalToBptVal);
        }

        uint256 oldMinOutBpsBalToBptMin = minOutBpsBalToBpt.min;
        minOutBpsBalToBpt.min = _minOutBpsBalToBptMin;

        emit MinOutBpsBalToBptMinUpdated(_minOutBpsBalToBptMin, oldMinOutBpsBalToBptMin);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Manager - Config
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Updates the current value for the minimum executable price (in bps as proportion of an oracle price)
    ///         for a BAL to USDC swap. The value should be more than the minimum value. Can be called by the owner or
    ///         the manager.
    /// @param _minOutBpsBalToUsdcVal The new value in bps.
    function setMinOutBpsBalToUsdcVal(uint256 _minOutBpsBalToUsdcVal) external onlyOwnerOrManager {
        if (_minOutBpsBalToUsdcVal > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToUsdcVal);
        }

        uint256 minOutBpsBalToUsdcMin = minOutBpsBalToUsdc.min;
        if (_minOutBpsBalToUsdcVal < minOutBpsBalToUsdcMin) {
            revert LessThanBpsMin(_minOutBpsBalToUsdcVal, minOutBpsBalToUsdcMin);
        }

        uint256 oldMinOutBpsBalToUsdcVal = minOutBpsBalToUsdc.val;
        minOutBpsBalToUsdc.val = _minOutBpsBalToUsdcVal;

        emit MinOutBpsBalToUsdcValUpdated(_minOutBpsBalToUsdcVal, oldMinOutBpsBalToUsdcVal);
    }

    /// @notice Updates the current value for the minimum executable price (in bps as proportion of an oracle price)
    ///         for an AURA to USDC swap. The value should be more than the minimum value. Can be called by the owner or
    ///         the manager.
    /// @param _minOutBpsAuraToUsdcVal The new value in bps.
    function setMinOutBpsAuraToUsdcVal(uint256 _minOutBpsAuraToUsdcVal) external onlyOwnerOrManager {
        if (_minOutBpsAuraToUsdcVal > MAX_BPS) {
            revert InvalidBps(_minOutBpsAuraToUsdcVal);
        }

        uint256 minOutBpsAuraToUsdcMin = minOutBpsAuraToUsdc.min;
        if (_minOutBpsAuraToUsdcVal < minOutBpsAuraToUsdcMin) {
            revert LessThanBpsMin(_minOutBpsAuraToUsdcVal, minOutBpsAuraToUsdcMin);
        }

        uint256 oldMinOutBpsAuraToUsdcVal = minOutBpsAuraToUsdc.val;
        minOutBpsAuraToUsdc.val = _minOutBpsAuraToUsdcVal;

        emit MinOutBpsAuraToUsdcValUpdated(_minOutBpsAuraToUsdcVal, oldMinOutBpsAuraToUsdcVal);
    }

    /// @notice Updates the current value for the minimum executable price (in bps as proportion of an oracle price)
    ///         for a BAL to 80BAL-20WETH BPT swap. The value should be more than the minimum value. Can be called by
    ///         the owner or the manager.
    /// @param _minOutBpsBalToBptVal The new value in bps.
    function setMinOutBpsBalToBptVal(uint256 _minOutBpsBalToBptVal) external onlyOwnerOrManager {
        if (_minOutBpsBalToBptVal > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToBptVal);
        }

        uint256 minOutBpsBalToBptMin = minOutBpsBalToBpt.min;
        if (_minOutBpsBalToBptVal < minOutBpsBalToBptMin) {
            revert LessThanBpsMin(_minOutBpsBalToBptVal, minOutBpsBalToBptMin);
        }

        uint256 oldMinOutBpsBalToBptVal = minOutBpsBalToBpt.val;
        minOutBpsBalToBpt.val = _minOutBpsBalToBptVal;

        emit MinOutBpsBalToBptValUpdated(_minOutBpsBalToBptVal, oldMinOutBpsBalToBptVal);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Takes a given amount of assets from the owner and stakes them on the AURA Booster. Can only be called by owner.
    /// @dev This also initializes the lastClaimTimestamp variable if there are no other deposits.
    /// @param _amountAsset1 Amount of asset1 to be staked.
    /// @param _amountAsset2 Amount of asset2 to be staked.
    function deposit(uint256 _amountAsset1, uint256 _amountAsset2) external onlyOwner {
        if (_amountAsset1 == 0 && _amountAsset2 == 0) {
            revert NothingToDeposit();
        }

        uint256 bptDeposited1 = baseRewardPool1.balanceOf(address(this));
        uint256 bptDeposited2 = baseRewardPool2.balanceOf(address(this));
        if (bptDeposited1 == 0 && bptDeposited2 == 0) {
            // Initialize at first deposit
            lastClaimTimestamp = block.timestamp;
        }

        if (_amountAsset1 > 0) {
            asset1.safeTransferFrom(msg.sender, address(this), _amountAsset1);
            AURA_BOOSTER.deposit(pid1, _amountAsset1, true);

            emit Deposit(address(asset1), _amountAsset1, block.timestamp);
        }
        if (_amountAsset2 > 0) {
            asset2.safeTransferFrom(msg.sender, address(this), _amountAsset2);
            AURA_BOOSTER.deposit(pid2, _amountAsset2, true);

            emit Deposit(address(asset2), _amountAsset2, block.timestamp);
        }
    }

    /// @notice Unstakes all staked assets and transfers them back to owner. Can only be called by owner.
    /// @dev This function doesn't claim any rewards.
    function withdrawAll() external onlyOwner {
        uint256 bptDeposited1 = baseRewardPool1.balanceOf(address(this));
        uint256 bptDeposited2 = baseRewardPool2.balanceOf(address(this));

        _withdraw(bptDeposited1, bptDeposited2);
    }

    /// @notice Unstakes the given amount of assets and transfers them back to owner. Can only be called by owner.
    /// @dev This function doesn't claim any rewards.
    /// @param _amountAsset1 Amount of asset1 to be unstaked.
    /// @param _amountAsset2 Amount of asset2 to be unstaked.
    function withdraw(uint256 _amountAsset1, uint256 _amountAsset2) external onlyOwner {
        _withdraw(_amountAsset1, _amountAsset2);
    }

    /// @notice Claims any pending BAL and AURA rewards and sends them to owner. Can only be called by owner.
    /// @dev This is a failsafe to handle rewards manually in case anything goes wrong (eg. rewards need to be sold
    ///      through other pools)
    function claimRewardsAndSendToOwner() external onlyOwner {
        // 1. Claim BAL and AURA rewards
        (uint256 totalBal, uint256 totalAura) = claimAndRegisterRewards();

        // 2. Send to owner
        address ownerCached = owner();
        BAL.safeTransfer(ownerCached, totalBal);
        AURA.safeTransfer(ownerCached, totalAura);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner/Manager
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Claim and process BAL and AURA rewards, selling some of it to USDC and depositing the rest to bauraBAL
    ///         and vlAURA. Can be called by the owner or manager.
    /// @dev This can be called by the owner or manager to opportunistically harvest in good market conditions.
    /// @param _auraPriceInUsd A reference price for AURA in USD (in 8 decimal precision) to compare with TWAP price. Leave as 0 to use only TWAP.
    /// @return processed_ An array containing addresses and amounts of harvested tokens (i.e. tokens that have finally
    ///                    been swapped into).
    function processRewards(uint256 _auraPriceInUsd)
        external
        onlyOwnerOrManager
        returns (TokenAmount[] memory processed_)
    {
        processed_ = processRewardsInternal(_auraPriceInUsd);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Keeper
    ////////////////////////////////////////////////////////////////////////////

    /// @notice A function to process pending BAL and AURA rewards at regular intervals. Can only be called by the
    ///         keeper when the contract is not paused.
    function performUpkeep(bytes calldata _performData) external override onlyKeeper whenNotPaused {
        uint256 lastClaimTimestampCached = lastClaimTimestamp;
        uint256 claimFrequencyCached = claimFrequency;
        if ((block.timestamp - lastClaimTimestampCached) < claimFrequencyCached) {
            revert TooSoon(block.timestamp, lastClaimTimestampCached, claimFrequencyCached);
        }

        uint256 auraPriceInUsd = abi.decode(_performData, (uint256));
        processRewardsInternal(auraPriceInUsd);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC VIEW
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The total amounts of both BPT tokens that the avatar is handling.
    function totalAssets() external view returns (uint256 asset1Amounts_, uint256 asset2Amounts_) {
        asset1Amounts_ = baseRewardPool1.balanceOf(address(this));
        asset2Amounts_ = baseRewardPool2.balanceOf(address(this));
    }

    /// @notice The pending BAL and AURA rewards that are yet to be processed.
    /// @dev Includes any BAL and AURA tokens in the contract.
    /// @return totalBal_ Pending BAL rewards.
    /// @return totalAura_ Pending AURA rewards.
    function pendingRewards() public view returns (uint256 totalBal_, uint256 totalAura_) {
        uint256 balEarned = baseRewardPool1.earned(address(this));
        balEarned += baseRewardPool2.earned(address(this));

        totalBal_ = balEarned + BAL.balanceOf(address(this));
        totalAura_ = getMintableAuraForBalAmount(balEarned) + AURA.balanceOf(address(this));
    }

    /// @notice Checks whether an upkeep is to be performed.
    /// @return upkeepNeeded_ A boolean indicating whether an upkeep is to be performed.
    function checkUpkeep(bytes calldata) external override returns (bool upkeepNeeded_, bytes memory performData_) {
        uint256 balPending1 = baseRewardPool1.earned(address(this));
        uint256 balPending2 = baseRewardPool2.earned(address(this));

        uint256 balBalance = BAL.balanceOf(address(this));

        if ((block.timestamp - lastClaimTimestamp) >= claimFrequency) {
            if (balPending1 > 0 || balPending2 > 0 || balBalance > 0) {
                upkeepNeeded_ = true;

                (, uint256 totalAura) = pendingRewards();
                performData_ = abi.encode(getAuraPriceInUsdSpot(totalAura));
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Unstakes the given amount of assets and transfers them back to owner.
    /// @dev This function doesn't claim any rewards. Caller can only be owner.
    /// @param _amountAsset1 Amount of asset1 to be unstaked.
    /// @param _amountAsset2 Amount of asset2 to be unstaked.
    function _withdraw(uint256 _amountAsset1, uint256 _amountAsset2) internal {
        if (_amountAsset1 == 0 && _amountAsset2 == 0) {
            revert NothingToWithdraw();
        }

        if (_amountAsset1 > 0) {
            baseRewardPool1.withdrawAndUnwrap(_amountAsset1, false);
            asset1.safeTransfer(msg.sender, _amountAsset1);

            emit Withdraw(address(asset1), _amountAsset1, block.timestamp);
        }
        if (_amountAsset2 > 0) {
            baseRewardPool2.withdrawAndUnwrap(_amountAsset2, false);
            asset2.safeTransfer(msg.sender, _amountAsset2);

            emit Withdraw(address(asset2), _amountAsset2, block.timestamp);
        }
    }

    /// @notice Claim and process BAL and AURA rewards, selling some of it to USDC and depositing the rest to bauraBAL
    ///         and vlAURA.
    /// @param _auraPriceInUsd A reference price for AURA in USD (in 8 decimal precision) to compare with TWAP price. Leave as 0 to use only TWAP.
    /// @return processed_ An array containing addresses and amounts of harvested tokens (i.e. tokens that have finally
    ///                    been swapped into).
    function processRewardsInternal(uint256 _auraPriceInUsd) internal returns (TokenAmount[] memory processed_) {
        // 1. Claim BAL and AURA rewards
        (uint256 totalBal, uint256 totalAura) = claimAndRegisterRewards();

        // 2. Swap some for USDC and send to owner
        uint256 balForUsdc = (totalBal * sellBpsBalToUsdc) / MAX_BPS;
        uint256 auraForUsdc = (totalAura * sellBpsAuraToUsdc) / MAX_BPS;

        uint256 usdcEarnedFromBal = swapBalForUsdc(balForUsdc);
        uint256 usdcEarnedFromAura = swapAuraForUsdc(auraForUsdc, _auraPriceInUsd);

        uint256 totalUsdcEarned = usdcEarnedFromBal + usdcEarnedFromAura;

        address ownerCached = owner();
        USDC.safeTransfer(ownerCached, totalUsdcEarned);

        // 3. Deposit remaining BAL to 80BAL-20ETH BPT
        depositBalToBpt(totalBal - balForUsdc);

        // 4. Swap BPT for auraBAL or lock
        swapBptForAuraBal(BPT_80BAL_20WETH.balanceOf(address(this)));

        // 5. Dogfood auraBAL in Badger vault on behalf of owner
        uint256 bauraBalBefore = BAURABAL.balanceOf(ownerCached);
        BAURABAL.depositFor(ownerCached, AURABAL.balanceOf(address(this)));
        uint256 bauraBalAfter = BAURABAL.balanceOf(ownerCached);

        // 6. Lock remaining AURA on behalf of Badger voter msig
        uint256 auraToLock = totalAura - auraForUsdc;
        AURA_LOCKER.lock(BADGER_VOTER, auraToLock);

        // Return processed amounts
        processed_ = new TokenAmount[](3);
        processed_[0] = TokenAmount(address(USDC), totalUsdcEarned);
        processed_[1] = TokenAmount(address(AURA), auraToLock);
        processed_[2] = TokenAmount(address(BAURABAL), bauraBalAfter - bauraBalBefore);

        // Emit events for analysis
        emit RewardsToStable(address(USDC), totalUsdcEarned, block.timestamp);
    }

    /// @notice Claims pending BAL and AURA rewards from both staking contracts and sets the lastClaimTimestamp value.
    /// @return totalBal_ The total BAL in contract after claiming.
    /// @return totalAura_ The total AURA in contract after claiming.
    function claimAndRegisterRewards() internal returns (uint256 totalBal_, uint256 totalAura_) {
        // Update last claimed time
        lastClaimTimestamp = block.timestamp;

        if (baseRewardPool1.earned(address(this)) > 0) {
            baseRewardPool1.getReward();
        }

        if (baseRewardPool2.earned(address(this)) > 0) {
            baseRewardPool2.getReward();
        }

        totalBal_ = BAL.balanceOf(address(this));
        totalAura_ = AURA.balanceOf(address(this));

        if (totalBal_ == 0) {
            revert NoRewards();
        }

        // Emit events for analysis
        emit RewardClaimed(address(BAL), totalBal_, block.timestamp);
        emit RewardClaimed(address(AURA), totalAura_, block.timestamp);
    }

    /// @notice Swaps the given amount of BAL for USDC.
    /// @dev The swap is only carried out if the execution price is within a predefined threshold (given by
    ///      minOutBpsBalToUsdc.val) of the oracle price.
    ///      A BAL-USD Chainlink price feed is used as the oracle.
    /// @param _balAmount The amount of BAL to sell.
    /// @return usdcEarned_ The amount of USDC earned.
    function swapBalForUsdc(uint256 _balAmount) internal returns (uint256 usdcEarned_) {
        IAsset[] memory assetArray = new IAsset[](3);
        assetArray[0] = IAsset(address(BAL));
        assetArray[1] = IAsset(address(WETH));
        assetArray[2] = IAsset(address(USDC));

        int256[] memory limits = new int256[](3);
        limits[0] = int256(_balAmount);
        limits[2] = -int256((getBalAmountInUsdc(_balAmount) * minOutBpsBalToUsdc.val) / MAX_BPS);
        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](2);
        // BAL --> WETH
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: BAL_WETH_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: _balAmount,
            userData: new bytes(0)
        });
        // WETH --> USDC
        swaps[1] = IBalancerVault.BatchSwapStep({
            poolId: USDC_WETH_POOL_ID,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // 0 means all from last step
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory assetBalances = BALANCER_VAULT.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, swaps, assetArray, fundManagement, limits, type(uint256).max
        );

        usdcEarned_ = uint256(-assetBalances[assetBalances.length - 1]);
    }

    /// @notice Swaps the given amount of AURA for USDC.
    /// @dev The swap is only carried out if the execution price is within a predefined threshold (given by
    ///      minOutBpsAuraToUsdc.val) of the oracle price.
    ///      A combination of the Balancer TWAP for the 80AURA-20WETH pool and a ETH-USD Chainlink price feed is used
    ///      as the oracle.
    /// @param _auraAmount The amount of AURA to sell.
    /// @param _auraPriceInUsd A reference price for AURA in USD (in 8 decimal precision) to compare with TWAP price. Leave as 0 to use only TWAP.
    /// @return usdcEarned_ The amount of USDC earned.
    function swapAuraForUsdc(uint256 _auraAmount, uint256 _auraPriceInUsd) internal returns (uint256 usdcEarned_) {
        IAsset[] memory assetArray = new IAsset[](3);
        assetArray[0] = IAsset(address(AURA));
        assetArray[1] = IAsset(address(WETH));
        assetArray[2] = IAsset(address(USDC));

        int256[] memory limits = new int256[](3);
        limits[0] = int256(_auraAmount);
        // Use max(TWAP price, reference price) as oracle price for AURA.
        // If reference price is the spot price then swap will only process if:
        //  1. TWAP price is less than spot price.
        //  2. TWAP price is within the slippage threshold of spot price.
        uint256 expectedUsdcOut = MathUpgradeable.max(
            _auraAmount * _auraPriceInUsd / AURA_USD_SPOT_FACTOR, getAuraAmountInUsdc(_auraAmount, twapPeriod)
        );
        // Assumes USDC is pegged. We should sell for other stableecoins if not
        limits[2] = -int256((expectedUsdcOut * minOutBpsAuraToUsdc.val) / MAX_BPS);

        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](2);
        // AURA --> WETH
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: AURA_WETH_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: _auraAmount,
            userData: new bytes(0)
        });
        // WETH --> USDC
        swaps[1] = IBalancerVault.BatchSwapStep({
            poolId: USDC_WETH_POOL_ID,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // 0 means all from last step
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory assetBalances = BALANCER_VAULT.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, swaps, assetArray, fundManagement, limits, type(uint256).max
        );

        usdcEarned_ = uint256(-assetBalances[assetBalances.length - 1]);
    }

    /// @notice Deposits the given amount of BAL into the 80BAL-20WETH pool.
    /// @dev The deposit is only carried out if the exchange rate is within a predefined threshold (given by
    ///      minOutBpsBalToBpt.val) of the Balancer TWAP.
    /// @param _balAmount The amount of BAL to deposit.
    function depositBalToBpt(uint256 _balAmount) internal {
        IAsset[] memory assetArray = new IAsset[](2);
        assetArray[0] = IAsset(address(BAL));
        assetArray[1] = IAsset(address(WETH));

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = _balAmount;
        maxAmountsIn[1] = 0;

        BALANCER_VAULT.joinPool(
            BAL_WETH_POOL_ID,
            address(this),
            address(this),
            IBalancerVault.JoinPoolRequest({
                assets: assetArray,
                maxAmountsIn: maxAmountsIn,
                userData: abi.encode(
                    JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                    maxAmountsIn,
                    (getBalAmountInBpt(_balAmount) * minOutBpsBalToBpt.val) / MAX_BPS
                    ),
                fromInternalBalance: false
            })
        );
    }

    /// @notice Either swaps or deposits the given amount of 80BAL-20WETH BPT for auraBAL.
    /// @dev A swap is carried out if the execution price is better than 1:1, otherwise falls back to a deposit.
    /// @param _bptAmount The amount of 80BAL-20WETH BPT to swap or deposit.
    function swapBptForAuraBal(uint256 _bptAmount) internal {
        IBalancerVault.SingleSwap memory swapParam = IBalancerVault.SingleSwap({
            poolId: AURABAL_BAL_WETH_POOL_ID,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(address(BPT_80BAL_20WETH)),
            assetOut: IAsset(address(AURABAL)),
            amount: _bptAmount,
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        // Take the trade if we get more than 1: 1 auraBal out
        try BALANCER_VAULT.swap(
            swapParam,
            fundManagement,
            _bptAmount, // minOut
            type(uint256).max
        ) returns (uint256) {} catch {
            // Otherwise deposit
            AURABAL_DEPOSITOR.deposit(_bptAmount, true, address(0));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TokenAmount {
    address token;
    uint256 amount;
}

struct BpsConfig {
    uint256 val;
    uint256 min;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant MAX_BPS = 10000;
uint256 constant PRECISION = 1e18;
uint256 constant PRECISION_DOUBLE = 1e36;

address constant CHAINLINK_KEEPER_REGISTRY = 0x02777053d6764996e594c3E88AF1D58D5363a2e6;

address constant BADGER_PROXY_ADMIN = 0x20Dce41Acca85E8222D6861Aa6D23B6C941777bF;

// Aura
uint256 constant PID_80BADGER_20WBTC = 33;
uint256 constant PID_40WBTC_40DIGG_20GRAVIAURA = 34;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Enum, Executor} from "../../lib/safe-contracts/contracts/base/Executor.sol";

import {GlobalAccessControlManaged} from "./GlobalAccessControlManaged.sol";

/// Avatar
/// Forwards calls from the owner
contract BaseAvatar is OwnableUpgradeable, Executor {
    ////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    ////////////////////////////////////////////////////////////////////////////

    function __BaseAvatar_init(address _owner) public onlyInitializing {
        __Ownable_init();

        transferOwnership(_owner);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Make arbitrary Ethereum call
    /// @param to Address to call
    /// @param value ETH value
    /// @param data TX data
    function doCall(address to, uint256 value, bytes memory data)
        public
        payable
        virtual
        onlyOwner
        returns (bool success)
    {
        success = execute(to, value, data, Enum.Operation.Call, gasleft());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PRECISION, PRECISION_DOUBLE} from "../BaseConstants.sol";
import {LogExpMath} from "../lib/balancer/LogExpMath.sol";
import {AuraConstants} from "./AuraConstants.sol";

import {IAuraToken} from "../interfaces/aura/IAuraToken.sol";
import {IAsset} from "../interfaces/balancer/IAsset.sol";
import {IBalancerVault} from "../interfaces/balancer/IBalancerVault.sol";
import {IWeightedPool} from "../interfaces/balancer/IWeightedPool.sol";
import {IPriceOracle} from "../interfaces/balancer/IPriceOracle.sol";
import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";

contract AuraAvatarUtils is AuraConstants {
    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error StalePriceFeed(uint256 currentTime, uint256 updateTime, uint256 maxPeriod);

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL VIEW
    ////////////////////////////////////////////////////////////////////////////

    function getAuraPriceInUsdSpot(uint256 _auraAmount) internal returns (uint256 usdPrice_) {
        usdPrice_ = querySwapAuraForUsdc(_auraAmount) * AURA_USD_SPOT_FACTOR / _auraAmount;
    }

    function getBalAmountInUsdc(uint256 _balAmount) internal view returns (uint256 usdcAmount_) {
        uint256 balInUsd = fetchPriceFromClFeed(BAL_USD_FEED, CL_FEED_HEARTBEAT_BAL);
        // Divisor is 10^20 and uint256 max ~ 10^77 so this shouldn't overflow for normal amounts
        usdcAmount_ = (_balAmount * balInUsd) / BAL_USD_FEED_DIVISOR;
    }

    function getAuraAmountInUsdc(uint256 _auraAmount, uint256 _twapPeriod)
        internal
        view
        returns (uint256 usdcAmount_)
    {
        uint256 auraInEth = fetchPriceFromBalancerTwap(BPT_80AURA_20WETH, _twapPeriod);
        uint256 ethInUsd = fetchPriceFromClFeed(ETH_USD_FEED, CL_FEED_HEARTBEAT_ETH_USD);
        // Divisor is 10^38 and uint256 max ~ 10^77 so this shouldn't overflow for normal amounts
        usdcAmount_ = (_auraAmount * auraInEth * ethInUsd) / AURA_USD_TWAP_DIVISOR;
    }

    function getBalAmountInBpt(uint256 _balAmount) internal view returns (uint256 bptAmount_) {
        uint256 bptPriceInBal = getBptPriceInBal();
        bptAmount_ = (_balAmount * PRECISION) / bptPriceInBal;
    }

    function querySwapAuraForUsdc(uint256 _auraAmount) internal returns (uint256 usdcEarned_) {
        IAsset[] memory assetArray = new IAsset[](3);
        assetArray[0] = IAsset(address(AURA));
        assetArray[1] = IAsset(address(WETH));
        assetArray[2] = IAsset(address(USDC));

        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](2);
        // AURA --> WETH
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: AURA_WETH_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: _auraAmount,
            userData: new bytes(0)
        });
        // WETH --> USDC
        swaps[1] = IBalancerVault.BatchSwapStep({
            poolId: USDC_WETH_POOL_ID,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // 0 means all from last step
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory assetDeltas =
            BALANCER_VAULT.queryBatchSwap(IBalancerVault.SwapKind.GIVEN_IN, swaps, assetArray, fundManagement);

        usdcEarned_ = uint256(-assetDeltas[assetDeltas.length - 1]);
    }

    /// @notice Calculates the price of 80BAL-20WETH BPT in BAL using the BAL-ETH CL feed.
    /// @return bptPriceInBal_ The price of 80BAL-20WETH BPT in BAL.
    function getBptPriceInBal() internal view returns (uint256 bptPriceInBal_) {
        uint256 ethPriceInBal = PRECISION_DOUBLE / fetchPriceFromClFeed(BAL_ETH_FEED, CL_FEED_HEARTBEAT_BAL);

        uint256 invariant = IWeightedPool(address(BPT_80BAL_20WETH)).getInvariant();
        uint256 totalSupply = BPT_80BAL_20WETH.totalSupply();

        // p1: Price of BAL
        // p2: Price of ETH
        //        w1         w2
        //  / p1 \     / p2 \
        // |  --  | . |  --  |
        //  \ w1 /     \ w2 /
        // -------------------
        //          p1
        uint256 priceMultiplier = LogExpMath.pow(
            ethPriceInBal * W1_BPT_80BAL_20WETH / W2_BPT_80BAL_20WETH, W2_BPT_80BAL_20WETH
        ) * PRECISION / W1_BPT_80BAL_20WETH;

        bptPriceInBal_ = invariant * priceMultiplier / totalSupply;
    }

    /// @notice Calculates the expected amount of AURA minted given some BAL rewards.
    /// @dev ref: https://etherscan.io/address/0xc0c293ce456ff0ed870add98a0828dd4d2903dbf#code#F1#L86
    /// @param _balAmount The input BAL reward amount.
    /// @return auraAmount_ The expected amount of AURA minted.
    function getMintableAuraForBalAmount(uint256 _balAmount) internal view returns (uint256 auraAmount_) {
        // NOTE: Only correct if AURA.minterMinted() == 0
        // minterMinted is a private var in the contract, so no way to access it on-chain
        uint256 emissionsMinted = AURA.totalSupply() - IAuraToken(address(AURA)).INIT_MINT_AMOUNT();

        uint256 cliff = emissionsMinted / IAuraToken(address(AURA)).reductionPerCliff();
        uint256 totalCliffs = IAuraToken(address(AURA)).totalCliffs();

        if (cliff < totalCliffs) {
            uint256 reduction = (((totalCliffs - cliff) * 5) / 2) + 700;
            auraAmount_ = (_balAmount * reduction) / totalCliffs;

            uint256 amtTillMax = IAuraToken(address(AURA)).EMISSIONS_MAX_SUPPLY() - emissionsMinted;
            if (auraAmount_ > amtTillMax) {
                auraAmount_ = amtTillMax;
            }
        }
    }

    function fetchPriceFromClFeed(IAggregatorV3 _feed, uint256 _maxStalePeriod)
        internal
        view
        returns (uint256 answerUint256_)
    {
        (, int256 answer,, uint256 updateTime,) = _feed.latestRoundData();

        if (block.timestamp - updateTime > _maxStalePeriod) {
            revert StalePriceFeed(block.timestamp, updateTime, _maxStalePeriod);
        }

        answerUint256_ = uint256(answer);
    }

    function fetchPriceFromBalancerTwap(IPriceOracle _pool, uint256 _twapPeriod)
        internal
        view
        returns (uint256 price_)
    {
        IPriceOracle.OracleAverageQuery[] memory queries = new IPriceOracle.OracleAverageQuery[](1);

        queries[0].variable = IPriceOracle.Variable.PAIR_PRICE;
        queries[0].secs = _twapPeriod;
        queries[0].ago = 0; // now

        // Gets the balancer time weighted average price denominated in BAL
        price_ = _pool.getTimeWeightedAverage(queries)[0];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
// solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAsset} from "./IAsset.sol";

enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
}

enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
    ADD_TOKEN // for Managed Pool
}

interface IBalancerVault {
    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        payable
        returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseRewardPool {
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function addExtraReward(address _reward) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function clearExtraRewards() external;

    function currentRewards() external view returns (uint256);

    function donate(uint256 _amount) external returns (bool);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function historicalRewards() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function newRewardRatio() external view returns (uint256);

    function operator() external view returns (address);

    function periodFinish() external view returns (uint256);

    function pid() external view returns (uint256);

    function processIdleRewards() external;

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function queuedRewards() external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

import {PausableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";

import {IGac} from "../interfaces/badger/IGac.sol";

/**
 * @title Global Access Control Managed - Base Class
 * @notice allows inheriting contracts to leverage global access control permissions conveniently, as well as granting contract-specific pausing functionality
 */
contract GlobalAccessControlManaged is PausableUpgradeable {
    IGac public gac;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    /// =======================
    /// ===== Initializer =====
    /// =======================

    /**
     * @notice Initializer
     * @dev this is assumed to be used in the initializer of the inhereiting contract
     * @param _globalAccessControl global access control which is pinged to allow / deny access to permissioned calls by role
     */
    function __GlobalAccessControlManaged_init(address _globalAccessControl) public onlyInitializing {
        __Pausable_init_unchained();
        gac = IGac(_globalAccessControl);
    }

    /// =====================
    /// ===== Modifiers =====
    /// =====================

    // @dev only holders of the given role on the GAC can call
    modifier onlyRole(bytes32 role) {
        require(gac.hasRole(role, msg.sender), "GAC: invalid-caller-role");
        _;
    }

    // @dev only holders of any of the given set of roles on the GAC can call
    modifier onlyRoles(bytes32[] memory roles) {
        bool validRoleFound = false;
        for (uint256 i = 0; i < roles.length; i++) {
            bytes32 role = roles[i];
            if (gac.hasRole(role, msg.sender)) {
                validRoleFound = true;
                break;
            }
        }
        require(validRoleFound, "GAC: invalid-caller-role");
        _;
    }

    // @dev only holders of the given role on the GAC can call, or a specified address
    // @dev used to faciliate extra contract-specific permissioned accounts
    modifier onlyRoleOrAddress(bytes32 role, address account) {
        require(gac.hasRole(role, msg.sender) || msg.sender == account, "GAC: invalid-caller-role-or-address");
        _;
    }

    /// @dev can be pausable by GAC or local flag
    modifier gacPausable() {
        require(!gac.paused(), "global-paused");
        require(!paused(), "local-paused");
        _;
    }

    /// ================================
    /// ===== Permissioned actions =====
    /// ================================

    function pause() external {
        require(gac.hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() external {
        require(gac.hasRole(UNPAUSER_ROLE, msg.sender));
        _unpause();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <=0.9.0;

interface IGac {
    function paused() external view returns (bool);

    function unpause() external;

    function pause() external;

    function enableTransferFrom() external;

    function disableTransferFrom() external;

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20MetadataUpgradeable} from
    "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {IAuraLocker} from "../interfaces/aura/IAuraLocker.sol";
import {IBaseRewardPool} from "../interfaces/aura/IBaseRewardPool.sol";
import {IBooster} from "../interfaces/aura/IBooster.sol";
import {ICrvDepositorWrapper} from "../interfaces/aura/ICrvDepositorWrapper.sol";
import {ICrvDepositor} from "../interfaces/aura/ICrvDepositor.sol";
import {IVault} from "../interfaces/badger/IVault.sol";
import {IBalancerVault} from "../interfaces/balancer/IBalancerVault.sol";
import {IPriceOracle} from "../interfaces/balancer/IPriceOracle.sol";
import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";

abstract contract AuraConstants {
    IBalancerVault internal constant BALANCER_VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    IBooster internal constant AURA_BOOSTER = IBooster(0x7818A1DA7BD1E64c199029E86Ba244a9798eEE10);
    IAuraLocker internal constant AURA_LOCKER = IAuraLocker(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);
    ICrvDepositor internal constant AURABAL_DEPOSITOR = ICrvDepositor(0xeAd792B55340Aa20181A80d6a16db6A0ECd1b827);
    ICrvDepositorWrapper internal constant AURABAL_DEPOSITOR_WRAPPER =
        ICrvDepositorWrapper(0x68655AD9852a99C87C0934c7290BB62CFa5D4123);

    IBaseRewardPool internal constant AURABAL_REWARDS = IBaseRewardPool(0x5e5ea2048475854a5702F5B8468A51Ba1296EFcC);

    IVault internal constant BAURABAL = IVault(0x37d9D2C6035b744849C15F1BFEE8F268a20fCBd8);
    address internal constant BADGER_VOTER = 0xA9ed98B5Fb8428d68664f3C5027c62A10d45826b;

    IERC20MetadataUpgradeable internal constant AURA =
        IERC20MetadataUpgradeable(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20MetadataUpgradeable internal constant BAL =
        IERC20MetadataUpgradeable(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20MetadataUpgradeable internal constant WETH =
        IERC20MetadataUpgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20MetadataUpgradeable internal constant USDC =
        IERC20MetadataUpgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20MetadataUpgradeable internal constant AURABAL =
        IERC20MetadataUpgradeable(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    IERC20MetadataUpgradeable internal constant BPT_80BAL_20WETH =
        IERC20MetadataUpgradeable(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);

    bytes32 internal constant BAL_WETH_POOL_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    bytes32 internal constant AURA_WETH_POOL_ID = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274; // 50AURA-50WETH
    bytes32 internal constant USDC_WETH_POOL_ID = 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;
    bytes32 internal constant AURABAL_BAL_WETH_POOL_ID =
        0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249; // Stable pool

    IAggregatorV3 internal constant BAL_USD_FEED = IAggregatorV3(0xdF2917806E30300537aEB49A7663062F4d1F2b5F);
    IAggregatorV3 internal constant BAL_ETH_FEED = IAggregatorV3(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);
    IAggregatorV3 internal constant ETH_USD_FEED = IAggregatorV3(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    uint256 internal constant CL_FEED_HEARTBEAT_ETH_USD = 1 hours;
    uint256 internal constant CL_FEED_HEARTBEAT_BAL = 24 hours;

    IPriceOracle internal constant BPT_80AURA_20WETH = IPriceOracle(0xc29562b045D80fD77c69Bec09541F5c16fe20d9d); // POL from AURA

    uint256 internal constant BAL_USD_FEED_DIVISOR = 1e20;
    uint256 internal constant AURA_USD_TWAP_DIVISOR = 1e38;

    uint256 internal constant AURA_USD_SPOT_FACTOR = 1e20;

    uint256 internal constant W1_BPT_80BAL_20WETH = 0.8e18;
    uint256 internal constant W2_BPT_80BAL_20WETH = 0.2e18;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BalancerErrors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x >> 255 == 0, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT, Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = _ln_36(base);
        } else {
            logBase = _ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = _ln_36(arg);
        } else {
            logArg = _ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Errors.OUT_OF_BOUNDS);
        if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
            return _ln_36(a) / ONE_18;
        } else {
            return _ln(a);
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuraToken {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Initialised();
    event OperatorChanged(address indexed previousOperator, address indexed newOperator);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function EMISSIONS_MAX_SUPPLY() external view returns (uint256);

    function INIT_MINT_AMOUNT() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function init(address _to, address _minter) external;

    function mint(address _to, uint256 _amount) external;

    function minter() external view returns (address);

    function minterMint(address _to, uint256 _amount) external;

    function name() external view returns (string memory);

    function operator() external view returns (address);

    function reductionPerCliff() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalCliffs() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function updateOperator() external;

    function vecrvProxy() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for querying historical data from a Pool that can be used as a Price Oracle.
 *
 * This lets third parties retrieve average prices of tokens held by a Pool over a given period of time, as well as the
 * price of the Pool share token (BPT) and invariant. Since the invariant is a sensible measure of Pool liquidity, it
 * can be used to compare two different price sources, and choose the most liquid one.
 *
 * Once the oracle is fully initialized, all queries are guaranteed to succeed as long as they require no data that
 * is not older than the largest safe query window.
 */
interface IPriceOracle {
    // The three values that can be queried:
    //
    // - PAIR_PRICE: the price of the tokens in the Pool, expressed as the price of the second token in units of the
    //   first token. For example, if token A is worth $2, and token B is worth $4, the pair price will be 2.0.
    //   Note that the price is computed *including* the tokens decimals. This means that the pair price of a Pool with
    //   DAI and USDC will be close to 1.0, despite DAI having 18 decimals and USDC 6.
    //
    // - BPT_PRICE: the price of the Pool share token (BPT), in units of the first token.
    //   Note that the price is computed *including* the tokens decimals. This means that the BPT price of a Pool with
    //   USDC in which BPT is worth $5 will be 5.0, despite the BPT having 18 decimals and USDC 6.
    //
    // - INVARIANT: the value of the Pool's invariant, which serves as a measure of its liquidity.
    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    /**
     * @dev Returns the time average weighted price corresponding to each of `queries`. Prices are represented as 18
     * decimal fixed point values.
     */
    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);

    /**
     * @dev Returns latest sample of `variable`. Prices are represented as 18 decimal fixed point values.
     */
    function getLatest(Variable variable) external view returns (uint256);

    /**
     * @dev Information for a Time Weighted Average query.
     *
     * Each query computes the average over a window of duration `secs` seconds that ended `ago` seconds ago. For
     * example, the average over the past 30 minutes is computed by settings secs to 1800 and ago to 0. If secs is 1800
     * and ago is 1800 as well, the average between 60 and 30 minutes ago is computed instead.
     */
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    /**
     * @dev Returns largest time window that can be safely queried, where 'safely' means the Oracle is guaranteed to be
     * able to produce a result and not revert.
     *
     * If a query has a non-zero `ago` value, then `secs + ago` (the oldest point in time) must be smaller than this
     * value for 'safe' queries.
     */
    function getLargestSafeQueryWindow() external view returns (uint256);

    /**
     * @dev Returns the accumulators corresponding to each of `queries`.
     */
    function getPastAccumulators(OracleAccumulatorQuery[] memory queries)
        external
        view
        returns (int256[] memory results);

    /**
     * @dev Information for an Accumulator query.
     *
     * Each query estimates the accumulator at a time `ago` seconds ago.
     */
    struct OracleAccumulatorQuery {
        Variable variable;
        uint256 ago;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestTimestamp() external view returns (uint256);

    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWeightedPool {
    /**
     * @dev Returns the current value of the invariant.
     */
    function getInvariant() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getNormalizedWeights() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBooster {
    event ArbitratorUpdated(address newArbitrator);
    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event FactoriesUpdated(address rewardFactory, address stashFactory, address tokenFactory);
    event FeeInfoChanged(address feeDistro, bool active);
    event FeeInfoUpdated(address feeDistro, address lockFees, address feeToken);
    event FeeManagerUpdated(address newFeeManager);
    event FeesUpdated(uint256 lockIncentive, uint256 stakerIncentive, uint256 earmarkIncentive, uint256 platformFee);
    event OwnerUpdated(address newOwner);
    event PoolAdded(address lpToken, address gauge, address token, address rewardPool, address stash, uint256 pid);
    event PoolManagerUpdated(address newPoolManager);
    event PoolShutdown(uint256 poolId);
    event RewardContractsUpdated(address lockRewards, address stakerRewards);
    event TreasuryUpdated(address newTreasury);
    event VoteDelegateUpdated(address newVoteDelegate);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

    function FEE_DENOMINATOR() external view returns (uint256);

    function MaxFees() external view returns (uint256);

    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns (bool);

    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    function crv() external view returns (address);

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function earmarkFees(address _feeToken) external returns (bool);

    function earmarkIncentive() external view returns (uint256);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function feeManager() external view returns (address);

    function feeTokens(address) external view returns (address distro, address rewards, bool active);

    function gaugeMap(address) external view returns (bool);

    function isShutdown() external view returns (bool);

    function lockIncentive() external view returns (uint256);

    function lockRewards() external view returns (address);

    function minter() external view returns (address);

    function owner() external view returns (address);

    function platformFee() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);

    function poolLength() external view returns (uint256);

    function poolManager() external view returns (address);

    function rewardArbitrator() external view returns (address);

    function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns (bool);

    function rewardFactory() external view returns (address);

    function setArbitrator(address _arb) external;

    function setFactories(address _rfactory, address _sfactory, address _tfactory) external;

    function setFeeInfo(address _feeToken, address _feeDistro) external;

    function setFeeManager(address _feeM) external;

    function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external;

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function setOwner(address _owner) external;

    function setPoolManager(address _poolM) external;

    function setRewardContracts(address _rewards, address _stakerRewards) external;

    function setTreasury(address _treasury) external;

    function setVote(bytes32 _hash, bool valid) external returns (bool);

    function setVoteDelegate(address _voteDelegate) external;

    function shutdownPool(uint256 _pid) external returns (bool);

    function shutdownSystem() external;

    function staker() external view returns (address);

    function stakerIncentive() external view returns (uint256);

    function stakerRewards() external view returns (address);

    function stashFactory() external view returns (address);

    function tokenFactory() external view returns (address);

    function treasury() external view returns (address);

    function updateFeeInfo(address _feeToken, bool _active) external;

    function vote(uint256 _voteId, address _votingAddress, bool _support) external returns (bool);

    function voteDelegate() external view returns (address);

    function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight) external returns (bool);

    function voteOwnership() external view returns (address);

    function voteParameter() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuraLocker {
    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct Balances {
        uint112 locked;
        uint32 nextUnlockIndex;
    }

    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    struct Epoch {
        uint224 supply;
        uint32 date; //epoch start date
    }

    function lock(address _account, uint256 _amount) external;

    function getReward(address _account) external;

    function getReward(address _account, bool _stake) external;

    function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);

    function rewardTokens(uint256 _index) external view returns (address token);

    function rewardPerToken(address _rewardsToken) external view returns (uint256);

    function lastTimeRewardApplicable(address _rewardsToken) external view returns (uint256);

    //BOOSTED balance of an account which only includes properly locked tokens as of the most recent eligible epoch
    function balanceOf(address _user) external view returns (uint256 amount);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function balances(address _user) external view returns (Balances memory bals);

    function userLocks(address _user, uint256 _index) external view returns (LockedBalance memory lockedBals);

    function lockedBalances(address _user)
        external
        view
        returns (uint256 total, uint256 unlockable, uint256 locked, LockedBalance[] memory lockData);

    function findEpochId(uint256 _time) external view returns (uint256 epoch);

    function epochs(uint256 _index) external view returns (Epoch memory epoch);

    function lockedSupply() external view returns (uint256);

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function processExpiredLocks(bool _relock, uint256 _spendRatio, address _withdrawTo) external;

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function processExpiredLocks(bool _relock) external;

    function delegate(address newDelegatee) external;

    function delegates(address account) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function token() external view returns (address);

    function reportHarvest(uint256 _harvestedAmount) external;

    function reportAdditionalToken(address _token) external;

    // Fees
    function performanceFeeGovernance() external view returns (uint256);

    function performanceFeeStrategist() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    // Actors
    function governance() external view returns (address);

    function keeper() external view returns (address);

    function guardian() external view returns (address);

    function strategist() external view returns (address);

    function treasury() external view returns (address);

    // External
    function deposit(uint256 _amount) external;

    function depositFor(address, uint256) external;

    function depositAll() external;

    function balanceOf(address) external view returns (uint256);

    function setStrategy(address _strategy) external;

    function setGovernance(address _governance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrvDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(uint256, uint256, bool, address _stakeAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrvDepositor {
    function deposit(uint256 _amount, bool _lock, address _stakeAddress) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) {
        _revert(errorCode);
    }
}

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode, bytes3 prefix) pure {
    if (!condition) {
        _revert(errorCode, prefix);
    }
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _revert(uint256 errorCode) pure {
    _revert(errorCode, 0x42414c); // This is the raw byte representation of "BAL"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode, bytes3 prefix) pure {
    uint256 prefixUint = uint256(uint24(prefix));
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string.
        // We first append the '#' character (0x23) to the prefix. In the case of 'BAL', it results in 0x42414c23 ('BAL#')
        // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).
        let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

        let revertReason := shl(200, add(formattedPrefix, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant FEATURE_DISABLED = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
    uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
    uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
    uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
    uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
    uint256 internal constant MAX_WEIGHT = 350;
    uint256 internal constant UNAUTHORIZED_JOIN = 351;
    uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;
    uint256 internal constant FRACTIONAL_TARGET = 353;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
    uint256 internal constant INVALID_OPERATION = 435;
    uint256 internal constant CODEC_OVERFLOW = 436;
    uint256 internal constant IN_RECOVERY_MODE = 437;
    uint256 internal constant NOT_IN_RECOVERY_MODE = 438;
    uint256 internal constant INDUCED_FAILURE = 439;
    uint256 internal constant EXPIRED_SIGNATURE = 440;
    uint256 internal constant MALFORMED_SIGNATURE = 441;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_UINT64 = 442;
    uint256 internal constant UNHANDLED_FEE_TYPE = 443;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
    uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;

    // Misc
    uint256 internal constant UNIMPLEMENTED = 998;
    uint256 internal constant SHOULD_NOT_HAPPEN = 999;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
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
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}