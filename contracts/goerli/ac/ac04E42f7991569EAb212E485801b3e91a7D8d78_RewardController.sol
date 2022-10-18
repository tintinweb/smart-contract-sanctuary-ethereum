// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IHATVault.sol";
import "./interfaces/IRewardController.sol";



contract RewardController is IRewardController, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct VaultInfo {
        uint256 rewardPerShare;
        uint256 lastProcessedVaultUpdate;
        uint256 lastRewardBlock;
        uint256 allocPoint;
    }

    struct VaultUpdate {
        uint256 blockNumber;// update blocknumber
        uint256 totalAllocPoint; //totalAllocPoint
    }

    uint256 public constant REWARD_PRECISION = 1e12;
    uint256 public constant NUMBER_OF_EPOCHS = 24;

    // Block from which the contract will start rewarding.
    uint256 public startBlock;
    uint256 public epochLength;
    // the ERC20 contract in which rewards are distributed
    IERC20Upgradeable public rewardToken;
    // amount of tokens rewarded in each block, per epoch
    uint256[24] public epochRewardPerBlock;
    VaultUpdate[] public globalVaultsUpdates;
    mapping(address => VaultInfo) public vaultInfo;
    // vault address => user address => reward debt amount
    mapping(address => mapping(address => uint256)) public rewardDebt;
    // vault address => user address => unclaimed reward amount
    mapping(address => mapping(address => uint256)) public unclaimedReward;

    /** @notice See {IRewardController-initialize}. */
    function initialize(
        address _rewardToken,
        address _hatsGovernance,
        uint256 _startRewardingBlock,
        uint256 _epochLength,
        uint256[24] memory _epochRewardPerBlock
    ) external initializer {
        if (_epochLength == 0) revert EpochLengthZero();
        rewardToken = IERC20Upgradeable(_rewardToken);
        startBlock = _startRewardingBlock;
        epochLength = _epochLength;
        epochRewardPerBlock = _epochRewardPerBlock;
        _transferOwnership(_hatsGovernance);
    }

    /** @notice See {IRewardController-setAllocPoint}. */
    function setAllocPoint(address _vault, uint256 _allocPoint) external onlyOwner {        
        _setAllocPoint(_vault, _allocPoint);
    }

    /** @notice See {IRewardController-updateVault}. */
    function updateVault(address _vault) public {
        VaultInfo storage vault = vaultInfo[_vault];
        uint256 lastRewardBlock = vault.lastRewardBlock;
        if (lastRewardBlock == 0) {
            vaultInfo[_vault].lastRewardBlock = block.number > startBlock ? block.number : startBlock;
            return;
        }
        if (block.number <= lastRewardBlock) {
            return;
        }

        vault.lastRewardBlock = block.number;

        uint256 totalShares = IERC20Upgradeable(_vault).totalSupply();

        if (totalShares != 0) {
            uint256 reward = getVaultReward(_vault, lastRewardBlock);
            vault.rewardPerShare += (reward * REWARD_PRECISION / totalShares);
        }

        if (globalVaultsUpdates.length != 0) {
            vaultInfo[_vault].lastProcessedVaultUpdate = globalVaultsUpdates.length - 1;
        }
    }

    /** @notice See {IRewardController-setEpochRewardPerBlock}. */
    function setEpochRewardPerBlock(uint256[24] memory _epochRewardPerBlock) external onlyOwner {
        // if rewards have not started yet, update the full list
        if (block.number < startBlock) {
            epochRewardPerBlock = _epochRewardPerBlock;
        }  else {
            uint256 nextEpoch = (block.number - startBlock) / epochLength + 1;
            // if rewards are ongoing, update the future rewards but keep past and current
            for (; nextEpoch < NUMBER_OF_EPOCHS; nextEpoch++) {
                epochRewardPerBlock[nextEpoch] = _epochRewardPerBlock[nextEpoch];
            }
        }
        emit SetEpochRewardPerBlock(epochRewardPerBlock);
    }

    function _setAllocPoint(address _vault, uint256 _allocPoint) internal {
        updateVault(_vault);
        uint256 totalAllocPoint = (globalVaultsUpdates.length == 0) ? _allocPoint :
        globalVaultsUpdates[globalVaultsUpdates.length-1].totalAllocPoint - vaultInfo[_vault].allocPoint + _allocPoint;
        if (globalVaultsUpdates.length > 0 &&
            globalVaultsUpdates[globalVaultsUpdates.length-1].blockNumber == block.number) {
            // already update in this block
            globalVaultsUpdates[globalVaultsUpdates.length-1].totalAllocPoint = totalAllocPoint;
        } else {
            globalVaultsUpdates.push(VaultUpdate({
                blockNumber: block.number,
                totalAllocPoint: totalAllocPoint
            }));
        }

        vaultInfo[_vault].allocPoint = _allocPoint;
    }

    function _commitUserBalance(
        address _vault,
        address _user,
        uint256 _sharesChange,
        bool _isDeposit
    ) internal {
        if (IHATVault(_vault).rewardControllerRemoved(address(this))) {
            return;
        }
        updateVault(_vault);

        uint256 userShares = IERC20Upgradeable(_vault).balanceOf(_user);
        uint256 rewardPerShare = vaultInfo[_vault].rewardPerShare;
        if (userShares != 0) {
            unclaimedReward[_vault][_user] += userShares * rewardPerShare / REWARD_PRECISION - rewardDebt[_vault][_user];
        }

        if (_sharesChange != 0) {
            if (_isDeposit) {
                userShares += _sharesChange;
            } else {
                userShares -= _sharesChange;
            }
        }
        rewardDebt[_vault][_user] = userShares * rewardPerShare / REWARD_PRECISION;
    }

    /** @notice See {IRewardController-commitUserBalance}. */
    function commitUserBalance(address _user, uint256 _sharesChange, bool _isDeposit) external {
        _commitUserBalance(msg.sender, _user, _sharesChange, _isDeposit);
    }

    /** @notice See {IRewardController-claimReward}. */
    function claimReward(address _vault, address _user) external {
        _commitUserBalance(_vault, _user, 0, true);

        uint256 userUnclaimedReward = unclaimedReward[_vault][_user];
        if (userUnclaimedReward > 0) {
            unclaimedReward[_vault][_user] = 0;
            rewardToken.safeTransfer(_user, userUnclaimedReward);
        }

        emit ClaimReward(_vault, _user, userUnclaimedReward);
    }

    /** @notice See {IRewardController-getVaultReward}. */
    function getVaultReward(address _vault, uint256 _fromBlock) public view returns(uint256 reward) {
        if (globalVaultsUpdates.length == 0) {
            return 0;
        }
        uint256 vaultAllocPoint = vaultInfo[_vault].allocPoint;
        uint256 i = vaultInfo[_vault].lastProcessedVaultUpdate;
        for (; i < globalVaultsUpdates.length-1; i++) {
            uint256 nextUpdateBlock = globalVaultsUpdates[i+1].blockNumber;
            reward += getRewardForBlocksRange(_fromBlock,
                                            nextUpdateBlock,
                                            vaultAllocPoint,
                                            globalVaultsUpdates[i].totalAllocPoint);
            _fromBlock = nextUpdateBlock;
        }
        return reward + getRewardForBlocksRange(_fromBlock,
                                                block.number,
                                                vaultAllocPoint,
                                                globalVaultsUpdates[i].totalAllocPoint);
    }

    function getRewardForBlocksRange(uint256 _fromBlock, uint256 _toBlock, uint256 _allocPoint, uint256 _totalAllocPoint)
    public
    view
    returns (uint256 reward) {
        if ((_fromBlock >= startBlock && _toBlock >= _fromBlock) && _totalAllocPoint > 0) {
            uint256 result;
            uint256 i = (_fromBlock - startBlock) / epochLength + 1;
            for (; i <= NUMBER_OF_EPOCHS; i++) {
                uint256 endBlock = epochLength * i + startBlock;
                if (_toBlock <= endBlock) {
                    break;
                }
                result += (endBlock - _fromBlock) * epochRewardPerBlock[i-1];
                _fromBlock = endBlock;
            }
            result += (_toBlock - _fromBlock) * (i > NUMBER_OF_EPOCHS ? 0 : epochRewardPerBlock[i-1]);
            reward = result * _allocPoint / _totalAllocPoint;
        }
    }

    /** @notice See {IRewardController-getPendingReward}. */
    function getPendingReward(address _vault, address _user) external view returns (uint256) {
        if (IHATVault(_vault).rewardControllerRemoved(address(this))) {
            return unclaimedReward[_vault][_user];
        }
        VaultInfo memory vault = vaultInfo[_vault];
        uint256 rewardPerShare = vault.rewardPerShare;
        uint256 totalShares = IERC20Upgradeable(_vault).totalSupply();

        if (vault.lastRewardBlock != 0 && block.number > vault.lastRewardBlock && totalShares > 0) {
            uint256 reward = getVaultReward(_vault, vault.lastRewardBlock);
            rewardPerShare += (reward * REWARD_PRECISION / totalShares);
        }

        return IERC20Upgradeable(_vault).balanceOf(_user) * rewardPerShare / REWARD_PRECISION + 
                unclaimedReward[_vault][_user] -
                rewardDebt[_vault][_user];
    }

    /** @notice See {IRewardController-sweepToken}. */
    function sweepToken(IERC20Upgradeable _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(msg.sender, _amount);
    }

    function getGlobalVaultsUpdatesLength() external view returns (uint256) {
        return globalVaultsUpdates.length;
    }

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
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "./IHATVaultsRegistry.sol";
import "./IRewardController.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title Interface for Hats.finance Vaults
 * @author Hats.finance
 * @notice A HATVault holds the funds for a specific project's bug bounties.
 * The HATVault can be deposited into in a permissionless maner using
 * the vault’s native token. When a bug is submitted and approved, the bounty 
 * is paid out using the funds in the vault. Bounties are paid out as a
 * percentage of the vault. The percentage is set according to the severity of
 * the bug. Vaults have regular safety periods (typically for an hour twice a
 * day) which are time for the committee to make decisions.
 *
 * In addition to the roles defined in the HATVaultsRegistry, every HATVault 
 * has the roles:
 * Committee - The only address which can submit a claim for a bounty payout
 * and set the maximum bounty.
 * User - Anyone can deposit the vault's native token into the vault and 
 * recieve shares for it. Shares represent the user's relative part in the
 * vault, and when a bounty is paid out, users lose part of their deposits
 * (based on percentage paid), but keep their share of the vault.
 * Users also receive rewards for their deposits, which can be claimed at any
 *  time.
 * To withdraw previously deposited tokens, a user must first send a withdraw
 * request, and the withdrawal will be made available after a pending period.
 * Withdrawals are not permitted during safety periods or while there is an 
 * active claim for a bounty payout.
 *
 * Bounties are payed out distributed between a few channels, and that 
 * distribution is set upon creation (the hacker gets part in direct transfer,
 * part in vested reward and part in vested HAT token, part gets rewarded to
 * the committee, part gets swapped to HAT token and burned and/or sent to Hats
 * governance).
 *
 * NOTE: Vaults should not use tokens which do not guarantee that the amount
 * specified is the amount transferred
 *
 * This project is open-source and can be found at:
 * https://github.com/hats-finance/hats-contracts
 */
interface IHATVault is IERC4626Upgradeable {

    enum ArbitratorCanChangeBounty{ NO, YES, DEFAULT }

    // How to divide the bounty - after deducting the part that is swapped to
    // HAT tokens ( {IHATVaultsRegistry.HATBountySplit} )
    // values are in percentages and should add up to 100% (defined as 10000)
    struct BountySplit {
        // the percentage of reward sent to the hacker via vesting contract
        uint256 hackerVested;
        // the percentage of tokens that are sent directly to the hacker
        uint256 hacker;
        // the percentage sent to the committee
        uint256 committee;
    }

    // How to divide a bounty for a claim that has been approved
    // used to keep track of payouts, amounts are in vault's native token
    struct ClaimBounty {
        uint256 hacker;
        uint256 hackerVested;
        uint256 committee;
        uint256 hackerHatVested;
        uint256 governanceHat;
    }

    /**
    * @notice Initialization parameters for the vault
    * @param rewardController The reward controller for the vault
    * @param vestingDuration Duration of the vesting period of the vault's
    * token vested part of the bounty
    * @param vestingPeriods The number of vesting periods of the vault's token
    * vested part of the bounty
    * @param maxBounty The maximum percentage of the vault that can be paid
    * out as a bounty
    * @param bountySplit The way to split the bounty between the hacker, 
    * hacker vested, and committee.
    *   Each entry is a number between 0 and `HUNDRED_PERCENT`.
    *   Total splits should be equal to `HUNDRED_PERCENT`.
    * @param asset The vault's native token
    * @param owner The address of the vault's owner 
    * @param committee The address of the vault's committee 
    * @param isPaused Whether to initialize the vault with deposits disabled
    * @dev Needed to avoid a "stack too deep" error
    */
    struct VaultInitParams {
        IRewardController rewardController;
        uint256 vestingDuration;
        uint256 vestingPeriods;
        uint256 maxBounty;
        IHATVault.BountySplit bountySplit;
        IERC20 asset;
        address owner;
        address committee;
        bool isPaused;
        string descriptionHash;
    }

    // Only committee
    error OnlyCommittee();
    // Active claim exists
    error ActiveClaimExists();
    // Safety period
    error SafetyPeriod();
    // Not safety period
    error NotSafetyPeriod();
    // Bounty percentage is higher than the max bounty
    error BountyPercentageHigherThanMaxBounty();
    // Only callable by arbitrator or after challenge timeout period
    error OnlyCallableByArbitratorOrAfterChallengeTimeOutPeriod();
    // No active claim exists
    error NoActiveClaimExists();
    // Claim Id specified is not the active claim Id
    error ClaimIdIsNotActive();
    // Not enough fee paid
    error NotEnoughFeePaid();
    // No pending max bounty
    error NoPendingMaxBounty();
    // Delay period for setting max bounty had not passed
    error DelayPeriodForSettingMaxBountyHadNotPassed();
    // Committee already checked in
    error CommitteeAlreadyCheckedIn();
    // Total bounty split % should be `HUNDRED_PERCENT`
    error TotalSplitPercentageShouldBeHundredPercent();
    // Vesting duration is too long
    error VestingDurationTooLong();
    // Vesting periods cannot be zero
    error VestingPeriodsCannotBeZero();
    // Vesting duration smaller than periods
    error VestingDurationSmallerThanPeriods();
    // Max bounty cannot be more than `MAX_BOUNTY_LIMIT`
    error MaxBountyCannotBeMoreThanMaxBountyLimit();
    // Committee bounty split cannot be more than `MAX_COMMITTEE_BOUNTY`
    error CommitteeBountyCannotBeMoreThanMax();
    // Only registry owner
    error OnlyRegistryOwner();
    // Only fee setter
    error OnlyFeeSetter();
    // Fee must be less than or equal to 2%
    error WithdrawalFeeTooBig();
    // Set shares arrays must have same length
    error SetSharesArraysMustHaveSameLength();
    // Committee not checked in yet
    error CommitteeNotCheckedInYet();
    // Not enough user balance
    error NotEnoughUserBalance();
    // Only arbitrator or registry owner
    error OnlyArbitratorOrRegistryOwner();
    // Unchalleged claim can only be approved if challenge period is over
    error UnchallengedClaimCanOnlyBeApprovedAfterChallengePeriod();
    // Challenged claim can only be approved by arbitrator before the challenge timeout period
    error ChallengedClaimCanOnlyBeApprovedByArbitratorUntilChallengeTimeoutPeriod();
    // Claim has expired
    error ClaimExpired();
    // Challenge period is over
    error ChallengePeriodEnded();
    // claim can be challenged only once
    error ClaimAlreadyChallenged();
    // Only callable if challenged
    error OnlyCallableIfChallenged();
    // Cannot deposit to another user with withdraw request
    error CannotTransferToAnotherUserWithActiveWithdrawRequest();
    // Withdraw amount must be greater than zero
    error WithdrawMustBeGreaterThanZero();
    // Redeem amount cannot be more than maximum for user
    error RedeemMoreThanMax();
    // System is in an emergency pause
    error SystemInEmergencyPause();
    // Cannot set a reward controller that was already used in the past
    error CannotSetToPerviousRewardController();
    // Cannot mint burn or transfer 0 amount of shares
    error AmountCannotBeZero();
    // Cannot transfer shares to self
    error CannotTransferToSelf();

    
    event SubmitClaim(
        bytes32 indexed _claimId,
        address indexed _committee,
        address indexed _beneficiary,
        uint256 _bountyPercentage,
        string _descriptionHash
    );
    event ChallengeClaim(bytes32 indexed _claimId);
    event ApproveClaim(
        bytes32 indexed _claimId,
        address indexed _committee,
        address indexed _beneficiary,
        uint256 _bountyPercentage,
        address _tokenLock,
        ClaimBounty _claimBounty
    );
    event DismissClaim(bytes32 indexed _claimId);
    event SetCommittee(address indexed _committee);
    event SetVestingParams(
        uint256 _duration,
        uint256 _periods
    );
    event SetBountySplit(BountySplit _bountySplit);
    event SetWithdrawalFee(uint256 _newFee);
    event CommitteeCheckedIn();
    event SetPendingMaxBounty(uint256 _maxBounty, uint256 _timeStamp);
    event SetMaxBounty(uint256 _maxBounty);
    event SetRewardController(IRewardController indexed _newRewardController);
    event SetDepositPause(bool _depositPause);
    event SetVaultDescription(string _descriptionHash);
    event SetHATBountySplit(uint256 _bountyGovernanceHAT, uint256 _bountyHackerHATVested);
    event SetArbitrator(address indexed _arbitrator);
    event SetChallengePeriod(uint256 _challengePeriod);
    event SetChallengeTimeOutPeriod(uint256 _challengeTimeOutPeriod);
    event SetArbitratorCanChangeBounty(ArbitratorCanChangeBounty _arbitratorCanChangeBounty);
    event WithdrawRequest(
        address indexed _beneficiary,
        uint256 _withdrawEnableTime
    );

    /**
    * @notice Initialize a vault instance
    * @param _params The vault initialization parameters
    * @dev See {IHATVault-VaultInitParams} for more details
    * @dev Called when the vault is created in {IHATVaultsRegistry-createVault}
    */
    function initialize(VaultInitParams memory _params) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Claim --------------------------------------- */

    /**
     * @notice Called by the committee to submit a claim for a bounty payout.
     * This function should be called only on a safety period, when withdrawals
     * are disabled, and while there's no other active claim. Cannot be called
     * when the registry is in an emergency pause.
     * Upon a call to this function by the committee the vault's withdrawals
     * will be disabled until the claim is approved or dismissed. Also from the
     * time of this call the arbitrator will have a period of 
     * {HATVaultsRegistry.challengePeriod} to challenge the claim.
     * @param _beneficiary The submitted claim's beneficiary
     * @param _bountyPercentage The submitted claim's bug requested reward percentage
     */
    function submitClaim(
        address _beneficiary, 
        uint256 _bountyPercentage, 
        string calldata _descriptionHash
    )
        external
        returns (bytes32 claimId);

   
    /**
    * @notice Called by the arbitrator or governance to challenge a claim for a bounty
    * payout that had been previously submitted by the committee.
    * Can only be called during the challenge period after submission of the
    * claim.
    * @param _claimId The claim ID
    */
    function challengeClaim(bytes32 _claimId) external;

    /**
    * @notice Approve a claim for a bounty submitted by a committee, and
    * pay out bounty to hacker and committee. Also transfer to the 
    * HATVaultsRegistry the part of the bounty that will be swapped to HAT 
    * tokens.
    * If the claim had been previously challenged, this is only callable by
    * the arbitrator. Otherwise, callable by anyone after challengePeriod had
    * passed.
    * @param _claimId The claim ID
    * @param _bountyPercentage The percentage of the vault's balance that will
    * be sent as a bounty. This value will be ignored if the caller is not the
    * arbitrator.
    */
    function approveClaim(bytes32 _claimId, uint256 _bountyPercentage)
        external;

    /**
    * @notice Dismiss the active claim for bounty payout submitted by the
    * committee.
    * Called either by the arbitrator, or by anyone if the claim has timed out.
    * @param _claimId The claim ID
    */
    function dismissClaim(bytes32 _claimId) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Params -------------------------------------- */

    /**
    * @notice Set new committee address. Can be called by existing committee,
    * or by the governance in the case that the committee hadn't checked in
    * yet.
    * @param _committee The address of the new committee 
    */
    function setCommittee(address _committee) external;

    /**
    * @notice Called by the vault's owner to set the vesting params for the
    * part of the bounty that the hacker gets vested in the vault's native
    * token
    * @param _duration Duration of the vesting period. Must be smaller than
    * 120 days and bigger than `_periods`
    * @param _periods Number of vesting periods. Cannot be 0.
    */
    function setVestingParams(uint256 _duration, uint256 _periods) external;

    /**
    * @notice Called by the vault's owner to set the vault token bounty split
    * upon an approval.
    * Can only be called if is no active claim and not during safety periods.
    * @param _bountySplit The bounty split
    */
    function setBountySplit(BountySplit memory _bountySplit) external;

    /**
    * @notice Called by the registry's fee setter to set the fee for 
    * withdrawals from the vault.
    * @param _fee The new fee. Must be smaller than or equal to `MAX_WITHDRAWAL_FEE`
    */
    function setWithdrawalFee(uint256 _fee) external;

    /**
    * @notice Called by the vault's committee to claim it's role.
    * Deposits are enabled only after committee check in.
    */
    function committeeCheckIn() external;

    /**
    * @notice Called by the vault's owner to set a pending request for the
    * maximum percentage of the vault that can be paid out as a bounty.
    * Cannot be called if there is an active claim that has been submitted.
    * Max bounty should be less than or equal to 90% (defined as 9000).
    * The pending value can be set by the owner after the time delay (of 
    * {HATVaultsRegistry.generalParameters.setMaxBountyDelay}) had passed.
    * @param _maxBounty The maximum bounty percentage that can be paid out
    */
    function setPendingMaxBounty(uint256 _maxBounty) external;

    /**
    * @notice Called by the vault's owner to set the vault's max bounty to
    * the already pending max bounty.
    * Cannot be called if there are active claims that have been submitted.
    * Can only be called if there is a max bounty pending approval, and the
    * time delay since setting the pending max bounty had passed.
    */
    function setMaxBounty() external;

    /**
    * @notice Called by the vault's owner to disable all deposits to the vault
    * @param _depositPause Are deposits paused
    */
    function setDepositPause(bool _depositPause) external;

    /**
    * @notice Called by the vault's owner to change the description of the
    * vault in the Hats.finance UI
    * @param _descriptionHash the hash of the vault's description
    */
    function setVaultDescription(string memory _descriptionHash) external;

    /**
    * @notice Called by vault's owner to set the vault's reward controller
    * @param _newRewardController The new reward controller
    */
    function setRewardController(IRewardController _newRewardController) external;

    /**
    * @notice Called by the registry's owner to set the vault HAT token bounty 
    * split upon an approval.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _bountyGovernanceHAT The HAT bounty for governance
    * @param _bountyHackerHATVested The HAT bounty vested for the hacker
    */
    function setHATBountySplit(
        uint256 _bountyGovernanceHAT,
        uint256 _bountyHackerHATVested
    ) 
        external;

    /**
    * @notice Called by the registry's owner to set the vault arbitrator
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _arbitrator The address of vault's arbitrator
    */
    function setArbitrator(address _arbitrator) external;

    /**
    * @notice Called by the registry's owner to set the period of time after
    * a claim for a bounty payout has been submitted that it can be challenged
    * by the arbitrator.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _challengePeriod The vault's challenge period
    */
    function setChallengePeriod(uint256 _challengePeriod) external;

    /**
    * @notice Called by the registry's owner to set the period of time after
    * which a claim for a bounty payout can be dismissed by anyone.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _challengeTimeOutPeriod The vault's challenge timeout period
    */
    function setChallengeTimeOutPeriod(uint256 _challengeTimeOutPeriod)
        external;

    /**
    * @notice Called by the registry's owner to set whether the arbitrator
    * can change a claim bounty percentage
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _arbitratorCanChangeBounty Whether the arbitrator can change a claim bounty percentage
    */
    function setArbitratorCanChangeBounty(ArbitratorCanChangeBounty _arbitratorCanChangeBounty) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Vault --------------------------------------- */

    /**
    * @notice Submit a request to withdraw funds from the vault.
    * The request will only be approved if there is no previous active
    * withdraw request.
    * The request will be pending for a period of
    * {HATVaultsRegistry.generalParameters.withdrawRequestPendingPeriod},
    * after which a withdraw will be possible for a duration of
    * {HATVaultsRegistry.generalParameters.withdrawRequestEnablePeriod}
    */
    function withdrawRequest() external;

    /** 
    * @notice Withdraw previously deposited funds from the vault and claim
    * the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds
    * @param owner Address of owner of the funds
    * @dev See {IERC4626-withdraw}.
    */
    function withdrawAndClaim(uint256 assets, address receiver, address owner)
        external 
        returns (uint256 shares);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets and claim the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-redeem}.
    */
    function redeemAndClaim(uint256 shares, address receiver, address owner)
        external 
        returns (uint256 assets);

    /** 
    * @notice Redeem all of the user's shares in the vault for the respective amount
    * of underlying assets without calling the reward controller, meaning user renounces
    * their uncommited part of the reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param receiver Address of receiver of the funds 
    */
    function emergencyWithdraw(address receiver) external returns (uint256 assets);

    /** 
    * @notice Withdraw previously deposited funds from the vault, without
    * transferring the accumulated HAT reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-withdraw}.
    */
    function withdraw(uint256 assets, address receiver, address owner)
        external 
        returns (uint256);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets, without transferring the accumulated HAT reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-redeem}.
    */
    function redeem(uint256 shares, address receiver, address owner)
        external  
        returns (uint256);

    /**
    * @dev Deposit funds to the vault. Can only be called if the committee had
    * checked in and deposits are not paused, and the registry is not in an emergency pause.
    * @param receiver Reciever of the shares from the deposit
    * @param assets Amount of vault's native token to deposit
    * @dev See {IERC4626-deposit}.
    */
    function deposit(uint256 assets, address receiver) 
        external
        returns (uint256);

    /* -------------------------------------------------------------------------------- */

    /* --------------------------------- Getters -------------------------------------- */

    /** 
    * @param _rewardController the reward controller to check
    * @return bool Whether the reward contoller was previously used in the vault and removed
    */
    function rewardControllerRemoved(address _rewardController) external view returns(bool);

    /** 
    * @notice Returns the vault HAT bounty split part that goes to the governance
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's HAT bounty split part that goes to the governance
    */
    function getBountyGovernanceHAT() external view returns(uint256);
    
    /** 
    * @notice Returns the vault HAT bounty split part that is veested for the hacker
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's HAT bounty split part that is veested for the hacker
    */
    function getBountyHackerHATVested() external view returns(uint256);

    /** 
    * @notice Returns the address of the vault's arbitrator
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The address of the vault's arbitrator
    */
    function getArbitrator() external view returns(address);

    /** 
    * @notice Returns the period of time after a claim for a bounty payout has
    * been submitted that it can be challenged by the arbitrator.
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's challenge period
    */
    function getChallengePeriod() external view returns(uint256);

    /** 
    * @notice Returns the period of time after which a claim for a bounty
    * payout can be dismissed by anyone.
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's challenge timeout period
    */
    function getChallengeTimeOutPeriod() external view returns(uint256);

    /** 
    * @notice Returns the amount of shares to be burned to give the user the exact
    * amount of assets requested plus cover for the fee. Also returns the amount assets
    * to be paid as fee.
    * @return shares The amount of shares to be burned to get the requested amount of assets
    * @return fee The amount of assets that will be paid as fee
    */
    function previewWithdrawAndFee(uint256 assets) external view returns (uint256 shares, uint256 fee);


    /** 
    * @notice Returns the amount of assets to be sent to the user for the exact
    * amount of shares to redeem. Also returns the amount assets to be paid as fee.
    * @return assets amount of assets to be sent in exchange for the amount of shares specified
    * @return fee The amount of assets that will be paid as fee
    */
    function previewRedeemAndFee(uint256 shares) external view returns (uint256 assets, uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRewardController {
    
    error EpochLengthZero();
    // Not enough rewards to transfer to user
    error NotEnoughRewardsToTransferToUser();

    event SetEpochRewardPerBlock(uint256[24] _epochRewardPerBlock);
    event ClaimReward(address indexed _vault, address indexed _user, uint256 _amount);

    /**
     * @notice Initializes the reward controller
     * @param _rewardToken The address of the ERC20 token to be distributed as rewards
     * @param _hatsGovernance The hats governance address, to be given ownership of the reward controller
     * @param _startRewardingBlock The block number from which to start rewarding
     * @param _epochLength The length of a rewarding epoch
     * @param _epochRewardPerBlock The reward per block for each of the 24 epochs
     */
    function initialize(
        address _rewardToken,
        address _hatsGovernance,
        uint256 _startRewardingBlock,
        uint256 _epochLength,
        uint256[24] memory _epochRewardPerBlock
    ) external;

    /**
     * @notice Called by the owner to set the allocation points for a vault, meaning the
     * vault's relative share of the total rewards
     * @param _vault The address of the vault
     * @param _allocPoint The allocation points for the vault
     */
    function setAllocPoint(address _vault, uint256 _allocPoint) external;

    /**
    * @notice Update the vault's reward per share, not more then once per block
    * @param _vault The vault's address
    */
    function updateVault(address _vault) external;

    /**
    * @notice Called by the owner to set reward per epoch
    * Reward can only be set for epochs which have not yet started
    * @param _epochRewardPerBlock reward per block for each epoch
    */
    function setEpochRewardPerBlock(uint256[24] memory _epochRewardPerBlock) external;

    /**
    * @notice Called by the vault to update a user claimable reward after deposit or withdraw.
    * This call should never revert.
    * @param _user The user address to updare rewards for
    * @param _sharesChange The user of shared the user deposited or withdrew
    * @param _isDeposit Whether user deposited or withdrew
    */
    function commitUserBalance(address _user, uint256 _sharesChange, bool _isDeposit) external;
    /**
    * @notice Transfer to the specified user their pending share of rewards.
    * @param _vault The vault address
    * @param _user The user address to claim for
    */
    function claimReward(address _vault, address _user) external;

    /**
    * @notice Calculate rewards for a vault by iterating over the history of totalAllocPoints updates,
    * and sum up all rewards periods from vault.lastRewardBlock until current block number.
    * @param _vault The vault address
    * @param _fromBlock The block from which to start calculation
    * @return reward The amount of rewards for the vault
    */
    function getVaultReward(address _vault, uint256 _fromBlock) external view returns(uint256 reward);

    /**
    * @notice Calculate the amount of rewards a user can claim for having contributed to a specific vault
    * @param _vault The vault address
    * @param _user The user for which the reward is calculated
    */
    function getPendingReward(address _vault, address _user) external view returns (uint256);

    /**
    * @notice Called by the owner to transfer any tokens held in this contract to the owner
    * @param _token The token to sweep
    * @param _amount The amount of token to sweep
    */
    function sweepToken(IERC20Upgradeable _token, uint256 _amount) external;

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

// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "./IRewardController.sol";
import "./IHATVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title Interface for the Hats.finance Vault Registry
 * @author hats.finance
 * @notice The Hats.finance Vault Registry is used to deploy Hats.finance
 * vaults and manage shared parameters.
 *
 * Hats.finance is a proactive bounty protocol for white hat hackers and
 * security experts, where projects, community members, and stakeholders
 * incentivize protocol security and responsible disclosure.
 * Hats create scalable vaults using the project’s own token. The value of the
 * bounty increases with the success of the token and project.
 *
 * The owner of the registry has the permission to set time limits and bounty
 * parameters and change vaults' info, and to set the other registry roles -
 * fee setter and arbitrator.
 * The arbitrator can challenge submitted claims for bounty payouts made by
 * vaults' committees, approve them with a different bounty percentage or
 * dismiss them.
 * The fee setter can set the fee on withdrawals on all vaults.
 *
 * This project is open-source and can be found at:
 * https://github.com/hats-finance/hats-contracts
 *
 * @dev New hats.finance vaults should be created through a call to {createVault}
 * so that they are linked to the registry
 */
interface IHATVaultsRegistry {

    // a struct with parameters for all vaults
    struct GeneralParameters {
        // vesting duration for the part of the bounty given to the hacker in HAT tokens
        uint256 hatVestingDuration;
        // vesting periods for the part of the bounty given to the hacker in HAT tokens
        uint256 hatVestingPeriods;
        // withdraw enable period. safetyPeriod starts when finished.
        uint256 withdrawPeriod;
        // withdraw disable period - time for the committee to gather and decide on actions,
        // withdrawals are not possible in this time. withdrawPeriod starts when finished.
        uint256 safetyPeriod;
        // period of time after withdrawRequestPendingPeriod where it is possible to withdraw
        // (after which withdrawals are not possible)
        uint256 withdrawRequestEnablePeriod;
        // period of time that has to pass after withdraw request until withdraw is possible
        uint256 withdrawRequestPendingPeriod;
        // period of time that has to pass after setting a pending max
        // bounty before it can be set as the new max bounty
        uint256 setMaxBountyDelay;
        // fee in ETH to be transferred with every logging of a claim
        uint256 claimFee;  
    }

    // How to divide the HAT part of bounties, in percentages (out of {HUNDRED_PERCENT})
    // The precentages are taken from the total bounty
    struct HATBountySplit {
        // the percentage of the total bounty to be swapped to HATs and sent to governance
        uint256 governanceHat;
        // the percentage of the total bounty to be swapped to HATs and sent to the hacker via vesting contract
        uint256 hackerHatVested;
    }

    /**
     * @notice Raised on {setWithdrawSafetyPeriod} if the withdraw period to
     * be set is shorter than 1 hour
     */
    error WithdrawPeriodTooShort();

    /**
     * @notice Raised on {setWithdrawSafetyPeriod} if the safety period to
     * be set is longer than 6 hours
     */
    error SafetyPeriodTooLong();

    /**
     * @notice Raised on {setWithdrawRequestParams} if the withdraw request
     * pending period to be set is shorter than 3 months
     */
    error WithdrawRequestPendingPeriodTooLong();

    /**
     * @notice Raised on {setWithdrawRequestParams} if the withdraw request
     * enabled period to be set is shorter than 6 hours
     */
    error WithdrawRequestEnabledPeriodTooShort();

    /**
     * @notice Raised on {setWithdrawRequestParams} if the withdraw request
     * enabled period to be set is longer than 100 days
     */
    error WithdrawRequestEnabledPeriodTooLong();

    /**
     * @notice Raised on {setHatVestingParams} if the vesting duration to be
     * set is longer than 180 days
     */
    error HatVestingDurationTooLong();

    /**
     * @notice Raised on {setHatVestingParams} if the vesting periods to be
     * set is 0
     */
    error HatVestingPeriodsCannotBeZero();
    
    /**
     * @notice Raised on {setHatVestingParams} if the vesting duration is 
     * smaller than the vesting periods
     */
    error HatVestingDurationSmallerThanPeriods();

    /**
     * @notice Raised on {setMaxBountyDelay} if the max bounty to be set is
     * shorter than 2 days
     */
    error DelayTooShort();

    /**
     * @notice Raised on {swapAndSend} if the amount to swap is zero
     */
    error AmountToSwapIsZero();

    /**
     * @notice Raised on {swapAndSend} if the swap was not successful
     */
    error SwapFailed();
    // Wrong amount received

    /**
     * @notice Raised on {swapAndSend} if the amount that was recieved in
     * the swap was less than the minimum amount specified
     */
    error AmountSwappedLessThanMinimum();

    /**
     * @notice Raised on {setDefaultHATBountySplit} if the split to be set is
     * greater than 20% (defined as 2000)
     */
    error TotalHatsSplitPercentageShouldBeUpToMaxHATSplit();

    /**
     * @notice Raised on {setDefaultChallengePeriod} if the challenge period
     *  to be set is shorter than 1 day
     */
    error ChallengePeriodTooShort();

    /**
     * @notice Raised on {setDefaultChallengePeriod} if the challenge period
     *  to be set is longer than 5 days
     */
    error ChallengePeriodTooLong();
        
    /**
     * @notice Raised on {setDefaultChallengeTimeOutPeriod} if the challenge
     * timeout period to be set is shorter than 1 day
     */
    error ChallengeTimeOutPeriodTooShort();

    /**
     * @notice Raised on {setDefaultChallengeTimeOutPeriod} if the challenge
     * timeout period to be set is longer than 85 days
     */
    error ChallengeTimeOutPeriodTooLong();
    
    /**
     * @notice Raised on {LogClaim} if the transaction was not sent with the
     * amount of ETH specified as {generalParameters.claimFee}
     */
    error NotEnoughFeePaid();

    /**
     * @notice Emitted when a claim is logged
     * @param _claimer The address of the claimer
     * @param _descriptionHash - a hash of an ipfs encrypted file which
     * describes the claim.
     */
    event LogClaim(address indexed _claimer, string _descriptionHash);

    /**
     * @notice Emitted when a new fee setter is set
     * @param _feeSetter The address of the new fee setter
     */
    event SetFeeSetter(address indexed _feeSetter);

    /**
     * @notice Emitted when new withdraw request time limits are set
     * @param _withdrawRequestPendingPeriod Time period where the withdraw
     * request is pending
     * @param _withdrawRequestEnablePeriod Time period after the peding period
     * has ended during which withdrawal is enabled
     */
    event SetWithdrawRequestParams(
        uint256 _withdrawRequestPendingPeriod,
        uint256 _withdrawRequestEnablePeriod
    );

    /**
     * @notice Emitted when a new fee for logging a claim for a bounty is set
     * @param _fee Claim fee in ETH to be transferred on any call of {logClaim}
     */
    event SetClaimFee(uint256 _fee);

    /**
     * @notice Emitted when new durations are set for withdraw period and
     * safety period
     * @param _withdrawPeriod Amount of time during which withdrawals are
     * enabled, and the bounty split can be changed by the governance
     * @param _safetyPeriod Amount of time during which claims for bounties 
     * can be submitted and withdrawals are disabled
     */
    event SetWithdrawSafetyPeriod(
        uint256 _withdrawPeriod,
        uint256 _safetyPeriod
    );

    /**
     * @notice Emitted when new HAT vesting parameters are set
     * @param _duration The duration of the vesting period
     * @param _periods The number of vesting periods
     */
    event SetHatVestingParams(uint256 _duration, uint256 _periods);

    /**
     * @notice Emitted when a new timelock delay for setting the
     * max bounty is set
     * @param _delay The time period for the delay
     */
    event SetMaxBountyDelay(uint256 _delay);

    /**
     * @notice Emitted when the UI visibility of a vault is changed
     * @param _vault The address of the vault to update
     * @param _visible Is this vault visible in the UI
     */
    event SetVaultVisibility(address indexed _vault, bool indexed _visible);

    /** @dev Emitted when a new vault is created
     * @param _vault The address of the vault to add to the registry
     * @param _asset The vault's native token
     * @param _committee The address of the vault's committee 
     * @param _rewardController The reward controller for the vault
     * @param _maxBounty The maximum percentage of the vault that can be paid
     * out as a bounty. Must be between 0 and 100% (defined as 10000)
     * @param _bountySplit The way to split the bounty between the hacker, 
     * hacker vested, and committee.
     *   Each entry is a number between 0 and 100%
     *   Total splits should be equal to 100%
     * @param _descriptionHash Hash of the vault description.
     * @param _bountyVestingDuration The duration of the vesting period of
     * the part of the bounty that is vested in vault's native token.
     * @param _bountyVestingDuration The number of vesting periods
     */
    event VaultCreated(
        address indexed _vault,
        address indexed _asset,
        address _committee,
        IRewardController _rewardController,
        uint256 _maxBounty,
        IHATVault.BountySplit _bountySplit,
        string _descriptionHash,
        uint256 _bountyVestingDuration,
        uint256 _bountyVestingPeriods,
        bool _isPaused
    );
    
    /** @notice Emitted when a swap of vault tokens to HAT tokens is done and
     * the HATS tokens are sent to beneficiary through vesting contract
     * @param _beneficiary Address of beneficiary
     * @param _amountSwapped Amount of vault's native tokens that was swapped
     * @param _amountSent Amount of HAT tokens sent to beneficiary
     * @param _tokenLock Address of the token lock contract that holds the HAT
     * tokens (address(0) if no token lock is used)
     */
    event SwapAndSend(
        address indexed _beneficiary,
        uint256 _amountSwapped,
        uint256 _amountSent,
        address indexed _tokenLock
    );

    /**
     * @notice Emitted when a new default HAT bounty split is set
     * @param _defaultBountyGovernanceHAT The new default HAT bounty part sent to governance
     * @param _defaultBountyHackerHATVested The new default HAT bounty part vseted for the hacker
     */
    event SetDefaultHATBountySplit(uint256 _defaultBountyGovernanceHAT, uint256 _defaultBountyHackerHATVested);

    /**
     * @notice Emitted when a new default arbitrator is set
     * @param _defaultArbitrator The address of the new arbitrator
     */
    event SetDefaultArbitrator(address indexed _defaultArbitrator);

    /**
     * @notice Emitted when a new default challenge period is set
     * @param _defaultChallengePeriod The new default challenge period
     */ 
    event SetDefaultChallengePeriod(uint256 _defaultChallengePeriod);

    /**
     * @notice Emitted when a new default challenge timeout period is set
     * @param _defaultChallengeTimeOutPeriod The new default challenge timeout
     * period
     */
    event SetDefaultChallengeTimeOutPeriod(uint256 _defaultChallengeTimeOutPeriod);

    /**
     * @notice Emitted when the default arbitrator can change bounty is set
     * @param _defaultArbitratorCanChangeBounty Whether the arbitrator can change bounty of claims
     */
    event SetDefaultArbitratorCanChangeBounty(bool _defaultArbitratorCanChangeBounty);

    /** @notice Emitted when the system is put into emergency pause/unpause
     * @param _isEmergencyPaused Is the system in an emergency pause
     */
    event SetEmergencyPaused(bool _isEmergencyPaused);

    /**
     * @notice Called by governance to pause/unpause the system in case of an
     * emergency
     * @param _isEmergencyPaused Is the system in an emergency pause
     */
    function setEmergencyPaused(bool _isEmergencyPaused) external;

    /**
     * @notice Emit an event that includes the given _descriptionHash
     * This can be used by the claimer as evidence that she had access to the
     * information at the time of the call
     * if a {generalParameters.claimFee} > 0, the caller must send that amount
     * of ETH for the claim to succeed
     * @param _descriptionHash - a hash of an IPFS encrypted file which 
     * describes the claim.
     */
    function logClaim(string memory _descriptionHash) external payable;

    /**
     * @notice Called by governance to set the default percentage of each claim bounty
     * that will be swapped for hats and sent to the governance or vested for the hacker
     * @param _defaultBountyGovernanceHAT The HAT bounty for governance
     * @param _defaultBountyHackerHATVested The HAT bounty vested for the hacker
     */
    function setDefaultHATBountySplit(
        uint256 _defaultBountyGovernanceHAT,
        uint256 _defaultBountyHackerHATVested
    ) 
        external;

    /** 
     * @dev Check that a given hats bounty split is legal, meaning that:
     *   Each entry is a number between 0 and less than `MAX_HAT_SPLIT`.
     *   Total splits should be less than `MAX_HAT_SPLIT`.
     * function will revert in case the bounty split is not legal.
     * @param _bountyGovernanceHAT The HAT bounty for governance
     * @param _bountyHackerHATVested The HAT bounty vested for the hacker
     */
    function validateHATSplit(uint256 _bountyGovernanceHAT, uint256 _bountyHackerHATVested)
         external
         pure;

    /**
     * @notice Called by governance to set the default arbitrator.
     * @param _defaultArbitrator The default arbitrator address
     */
    function setDefaultArbitrator(address _defaultArbitrator) external;

    /**
     * @notice Called by governance to set the default challenge period
     * @param _defaultChallengePeriod The default challenge period
     */
    function setDefaultChallengePeriod(uint256 _defaultChallengePeriod) 
        external;

    /**
     * @notice Called by governance to set the default challenge timeout
     * @param _defaultChallengeTimeOutPeriod The Default challenge timeout
     */
    function setDefaultChallengeTimeOutPeriod(
        uint256 _defaultChallengeTimeOutPeriod
    ) 
        external;

    /**
     * @notice Called by governance to set Whether the arbitrator can change bounty of claims.
     * @param _defaultArbitratorCanChangeBounty The default for whether the arbitrator can change bounty of claims
     */
    function setDefaultArbitratorCanChangeBounty(bool _defaultArbitratorCanChangeBounty) external;

    /**
     * @notice Check that the given challenge period is legal, meaning that it
     * is greater than 1 day and less than 5 days.
     * @param _challengePeriod The challenge period to check
     */
    function validateChallengePeriod(uint256 _challengePeriod) external pure;

    /**
     * @notice Check that the given challenge timeout period is legal, meaning
     * that it is greater than 2 days and less than 85 days.
     * @param _challengeTimeOutPeriod The challenge timeout period to check
     */
    function validateChallengeTimeOutPeriod(uint256 _challengeTimeOutPeriod) external pure;
   
    /**
     * @notice Called by governance to set the fee setter role
     * @param _feeSetter Address of new fee setter
     */
    function setFeeSetter(address _feeSetter) external;

    /**
     * @notice Called by governance to set time limits for withdraw requests
     * @param _withdrawRequestPendingPeriod Time period where the withdraw
     * request is pending
     * @param _withdrawRequestEnablePeriod Time period after the peding period
     * has ended during which withdrawal is enabled
     */
    function setWithdrawRequestParams(
        uint256 _withdrawRequestPendingPeriod,
        uint256  _withdrawRequestEnablePeriod
    )
        external;

    /**
     * @notice Called by governance to set the fee for logging a claim for a
     * bounty in any vault.
     * @param _fee Claim fee in ETH to be transferred on any call of
     * {logClaim}
     */
    function setClaimFee(uint256 _fee) external;

    /**
     * @notice Called by governance to set the withdraw period and safety
     * period, which are always interchanging.
     * The safety period is time that the committee can submit claims for 
     * bounty payouts, and during which withdrawals are disabled and the
     * bounty split cannot be changed.
     * @param _withdrawPeriod Amount of time during which withdrawals are
     * enabled, and the bounty split can be changed by the governance. Must be
     * at least 1 hour.
     * @param _safetyPeriod Amount of time during which claims for bounties 
     * can be submitted and withdrawals are disabled. Must be at most 6 hours.
     */
    function setWithdrawSafetyPeriod(
        uint256 _withdrawPeriod,
        uint256 _safetyPeriod
    ) 
        external;

    /**
     * @notice Called by governance to set vesting params for rewarding hackers
     * with rewardToken, for all vaults
     * @param _duration Duration of the vesting period. Must be less than 180
     * days.
     * @param _periods The number of vesting periods. Must be more than 0 and 
     * less then the vesting duration.
     */
    function setHatVestingParams(uint256 _duration, uint256 _periods) external;

    /**
     * @notice Called by governance to set the timelock delay for setting the
     * max bounty (the time between setPendingMaxBounty and setMaxBounty)
     * @param _delay The time period for the delay. Must be at least 2 days.
     */
    function setMaxBountyDelay(uint256 _delay) external;

    /**
     * @notice Create a new vault
     * NOTE: Vaults should not use tokens which do not guarantee that the 
     * amount specified is the amount transferred
     * @param _asset The vault's native token
     * @param _committee The address of the vault's committee 
     * @param _rewardController The reward controller for the vault
     * @param _maxBounty The maximum percentage of the vault that can be paid
     * out as a bounty. Must be between 0 and `HUNDRED_PERCENT`
     * @param _bountySplit The way to split the bounty between the hacker, 
     * hacker vested, and committee.
     *   Each entry is a number between 0 and `HUNDRED_PERCENT`.
     *   Total splits should be equal to `HUNDRED_PERCENT`.
     * @param _descriptionHash Hash of the vault description.
     * @param _bountyVestingDuration Vesting duration for the part of the bounty
     * that is paid vested in the vault's native token
     * @param _bountyVestingPeriods Vesting periods for the part of the bounty
     * that is paid vested in the vault's native token
     * @param _isPaused Whether to initialize the vault with deposits disabled
     * @return vault The address of the new vault
     */
    function createVault(
        IERC20 _asset,
        address _owner,
        address _committee,
        IRewardController _rewardController,
        uint256 _maxBounty,
        IHATVault.BountySplit memory _bountySplit,
        string memory _descriptionHash,
        uint256 _bountyVestingDuration,
        uint256 _bountyVestingPeriods,
        bool _isPaused
    ) 
    external 
    returns(address vault);

    /**
     * @notice Called by governance to change the UI visibility of a vault
     * @param _vault The address of the vault to update
     * @param _visible Is this vault visible in the UI
     * This parameter can be used by the UI to include or exclude the vault
     */
    function setVaultVisibility(address _vault, bool _visible) external;

    /**
     * @notice Transfer the part of the bounty that is supposed to be swapped
     * into HAT tokens from the HATVault to the registry, and keep track of
     * the amounts to be swapped and sent/burnt in a later transaction
     * @param _asset The vault's native token
     * @param _hacker The address of the beneficiary of the bounty
     * @param _hackersHatReward The amount of the vault's native token to be
     * swapped to HAT tokens and sent to the hacker via a vesting contract
     * @param _governanceHatReward The amount of the vault's native token to
     * be swapped to HAT tokens and sent to governance
     */
    function addTokensToSwap(
        IERC20 _asset,
        address _hacker,
        uint256 _hackersHatReward,
        uint256 _governanceHatReward
    ) external;

    /**
     * @notice Called by governance to swap the given asset to HAT tokens and 
     * distribute the HAT tokens: Send to governance their share and send to
     * beneficiaries their share through a vesting contract.
     * @param _asset The address of the token to be swapped to HAT tokens
     * @param _beneficiaries Addresses of beneficiaries
     * @param _amountOutMinimum Minimum amount of HAT tokens at swap
     * @param _routingContract Routing contract to call for the swap
     * @param _routingPayload Payload to send to the _routingContract for the
     * swap
     */
    function swapAndSend(
        address _asset,
        address[] calldata _beneficiaries,
        uint256 _amountOutMinimum,
        address _routingContract,
        bytes calldata _routingPayload
    ) external;
  
    /**
     * @notice Returns the general parameters for all vaults
     * @return {GeneralParameters} General parameters for all vaults
     */    
    function getGeneralParameters()
        external 
        view 
        returns(GeneralParameters memory);

    /**
     * @notice Returns the number of vaults that have been previously created
     * @return The number of vaults in the registry
     */
    function getNumberOfVaults() external view returns(uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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