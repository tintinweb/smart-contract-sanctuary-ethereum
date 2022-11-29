// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @notice Simple contract exposing a modifier used on setup functions
/// to prevent them from being called more than once
/// @author Solid World DAO
abstract contract PostConstruct {
    error AlreadyInitialized();

    bool private _initialized;

    modifier postConstruct() {
        if (_initialized) {
            revert AlreadyInitialized();
        }
        _initialized = true;
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ISolidStaking.sol";
import "./interfaces/rewards/IRewardsController.sol";
import "./PostConstruct.sol";
import "./libraries/GPv2SafeERC20.sol";

contract SolidStaking is ISolidStaking, ReentrancyGuard, Ownable, PostConstruct {
    using GPv2SafeERC20 for IERC20;

    /// @dev All stakable lp tokens.
    address[] public tokens;

    /// @dev Mapping with added tokens.
    mapping(address => bool) public tokenAdded;

    /// @dev Mapping with the staked amount of each account for each token.
    /// @dev token => user => amount
    mapping(address => mapping(address => uint)) public userStake;

    /// @dev Main contract used for interacting with rewards mechanism.
    IRewardsController public rewardsController;

    modifier validToken(address token) {
        if (!tokenAdded[token]) {
            revert InvalidTokenAddress(token);
        }
        _;
    }

    function setup(IRewardsController _rewardsController, address owner) external postConstruct {
        rewardsController = _rewardsController;
        transferOwnership(owner);
    }

    /// @inheritdoc ISolidStakingOwnerActions
    function addToken(address token) external override onlyOwner {
        if (tokenAdded[token]) {
            revert TokenAlreadyAdded(token);
        }

        tokens.push(token);
        tokenAdded[token] = true;

        emit TokenAdded(token);
    }

    /// @inheritdoc ISolidStakingActions
    function stake(address token, uint amount) external override nonReentrant validToken(token) {
        uint oldUserStake = _balanceOf(token, msg.sender);
        uint oldTotalStake = _totalStaked(token);

        userStake[token][msg.sender] = oldUserStake + amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        rewardsController.handleAction(token, msg.sender, oldUserStake, oldTotalStake);

        emit Stake(msg.sender, token, amount);
    }

    /// @inheritdoc ISolidStakingActions
    function withdraw(address token, uint amount) external override nonReentrant validToken(token) {
        uint oldUserStake = _balanceOf(token, msg.sender);
        uint oldTotalStake = _totalStaked(token);

        userStake[token][msg.sender] = oldUserStake - amount;

        IERC20(token).safeTransfer(msg.sender, amount);

        rewardsController.handleAction(token, msg.sender, oldUserStake, oldTotalStake);

        emit Withdraw(msg.sender, token, amount);
    }

    /// @inheritdoc ISolidStakingViewActions
    function balanceOf(address token, address account)
        external
        view
        override
        validToken(token)
        returns (uint)
    {
        return _balanceOf(token, account);
    }

    /// @inheritdoc ISolidStakingViewActions
    function totalStaked(address token) external view override validToken(token) returns (uint) {
        return _totalStaked(token);
    }

    /// @inheritdoc ISolidStakingViewActions
    function getTokens() external view override returns (address[] memory _tokens) {
        _tokens = tokens;
    }

    function _balanceOf(address token, address account) internal view returns (uint) {
        return userStake[token][account];
    }

    function _totalStaked(address token) internal view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./solid-staking/ISolidStakingOwnerActions.sol";
import "./solid-staking/ISolidStakingEvents.sol";
import "./solid-staking/ISolidStakingActions.sol";
import "./solid-staking/ISolidStakingViewActions.sol";
import "./solid-staking/ISolidStakingErrors.sol";

/// @title The interface for the Solid World staking contract
/// @notice The staking contract facilitates (un)staking of ERC20 tokens
/// @author Solid World DAO
/// @dev The interface is broken up into smaller pieces
interface ISolidStaking is
    ISolidStakingActions,
    ISolidStakingEvents,
    ISolidStakingOwnerActions,
    ISolidStakingViewActions,
    ISolidStakingErrors
{

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6 <0.9.0;

interface IEACAggregatorProxy {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IRewardsDistributor.sol";
import "../../libraries/RewardsDataTypes.sol";

/// @title IRewardsController
/// @author Aave
/// @notice Defines the basic interface for a Rewards Controller.
interface IRewardsController is IRewardsDistributor {
    error UnauthorizedClaimer(address claimer, address user);
    error NotSolidStaking(address sender);
    error InvalidRewardOracle(address reward, address rewardOracle);

    /// @dev Emitted when a new address is whitelisted as claimer of rewards on behalf of a user
    /// @param user The address of the user
    /// @param claimer The address of the claimer
    event ClaimerSet(address indexed user, address indexed claimer);

    /// @dev Emitted when rewards are claimed
    /// @param user The address of the user rewards has been claimed on behalf of
    /// @param reward The address of the token reward is claimed
    /// @param to The address of the receiver of the rewards
    /// @param claimer The address of the claimer
    /// @param amount The amount of rewards claimed
    event RewardsClaimed(
        address indexed user,
        address indexed reward,
        address indexed to,
        address claimer,
        uint256 amount
    );

    /// @dev Emitted when the reward oracle is updated
    /// @param reward The address of the token reward
    /// @param rewardOracle The address of oracle
    event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);

    /// @dev Whitelists an address to claim the rewards on behalf of another address
    /// @param user The address of the user
    /// @param claimer The address of the claimer
    function setClaimer(address user, address claimer) external;

    /// @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
    /// @notice At the moment of reward configuration, the Incentives Controller performs
    /// a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
    /// This check is enforced for integrators to be able to show incentives at
    /// the current Aave UI without the need to setup an external price registry
    /// @param reward The address of the reward to set the price aggregator
    /// @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

    /// @dev Get the price aggregator oracle address
    /// @param reward The address of the reward
    /// @return The price oracle of the reward
    function getRewardOracle(address reward) external view returns (address);

    /// @return Account that secures ERC20 rewards.
    function getRewardsVault() external view returns (address);

    /// @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
    /// @param user The address of the user
    /// @return The claimer address
    function getClaimer(address user) external view returns (address);

    /// @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
    /// @param config The assets configuration input, the list of structs contains the following fields:
    ///   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
    ///   uint256 totalStaked: The total amount staked of the asset
    ///   uint40 distributionEnd: The end of the distribution of the incentives for an asset
    ///   address asset: The asset address to incentivize
    ///   address reward: The reward token address
    ///   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
    ///                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
    function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

    /// @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
    /// @param asset The incentivized asset address
    /// @param user The address of the user whose asset balance has changed
    /// @param userStake The amount of assets staked by the user, prior to stake change
    /// @param totalStaked The total amount staked of the asset, prior to stake change
    function handleAction(
        address asset,
        address user,
        uint256 userStake,
        uint256 totalStaked
    ) external;

    /// @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
    /// @param assets The list of assets to check eligible distributions before claiming rewards
    /// @param to The address that will be receiving the rewards
    /// @return rewardsList List of addresses of the reward tokens
    /// @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    /// @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
    /// be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
    /// @param assets The list of assets to check eligible distributions before claiming rewards
    /// @param user The address to check and claim rewards
    /// @param to The address that will be receiving the rewards
    /// @return rewardsList List of addresses of the reward tokens
    /// @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    /// @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
    /// @param assets The list of assets to check eligible distributions before claiming rewards
    /// @return rewardsList List of addresses of the reward tokens
    /// @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title IRewardsDistributor
/// @author Aave
/// @notice Defines the basic interface for a Rewards Distributor.
interface IRewardsDistributor {
    error NotEmissionManager(address sender);
    error InvalidInput();
    error InvalidAssetDecimals(address asset);
    error IndexOverflow(uint newIndex);
    error DistributionNonExistent(address asset, address reward);

    /// @dev Emitted when the configuration of the rewards of an asset is updated.
    /// @param asset The address of the incentivized asset
    /// @param reward The address of the reward token
    /// @param oldEmission The old emissions per second value of the reward distribution
    /// @param newEmission The new emissions per second value of the reward distribution
    /// @param oldDistributionEnd The old end timestamp of the reward distribution
    /// @param newDistributionEnd The new end timestamp of the reward distribution
    /// @param assetIndex The index of the asset distribution
    event AssetConfigUpdated(
        address indexed asset,
        address indexed reward,
        uint256 oldEmission,
        uint256 newEmission,
        uint256 oldDistributionEnd,
        uint256 newDistributionEnd,
        uint256 assetIndex
    );

    /// @dev Emitted when rewards of an asset are accrued on behalf of a user.
    /// @param asset The address of the incentivized asset
    /// @param reward The address of the reward token
    /// @param user The address of the user that rewards are accrued on behalf of
    /// @param assetIndex The index of the asset distribution
    /// @param userIndex The index of the asset distribution on behalf of the user
    /// @param rewardsAccrued The amount of rewards accrued
    event Accrued(
        address indexed asset,
        address indexed reward,
        address indexed user,
        uint256 assetIndex,
        uint256 userIndex,
        uint256 rewardsAccrued
    );

    /// @dev Emitted when the emission manager address is updated.
    /// @param oldEmissionManager The address of the old emission manager
    /// @param newEmissionManager The address of the new emission manager
    event EmissionManagerUpdated(
        address indexed oldEmissionManager,
        address indexed newEmissionManager
    );

    /// @param asset The address of the incentivized asset
    /// @param reward The address of the reward token
    error UpdateOngoingRewardDistribution(address asset, address reward);

    /// @dev Sets the end date for the distribution
    /// @param asset The asset to incentivize
    /// @param reward The reward token that incentives the asset
    /// @param newDistributionEnd The end date of the incentivization, in unix time format
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external;

    /// @dev Sets the emission per second of a set of reward distributions
    /// @param asset The asset is being incentivized
    /// @param rewards List of reward addresses are being distributed
    /// @param newEmissionsPerSecond List of new reward emissions per second
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external;

    /// @dev Updates weekly reward distributions
    /// @param assets List of incentivized assets getting updated
    /// @param rewards List of reward tokens getting updated
    /// @param rewardAmounts List of carbon reward amounts getting distributed
    function updateRewardDistribution(
        address[] calldata assets,
        address[] calldata rewards,
        uint[] calldata rewardAmounts
    ) external;

    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return true, if rewards are still being distributed for the asset - reward pair
    function isOngoingDistribution(address asset, address reward) external view returns (bool);

    /// @dev Gets the end date for the distribution
    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return The timestamp with the end of the distribution, in unix time format
    function getDistributionEnd(address asset, address reward) external view returns (uint256);

    /// @dev Returns the index of a user on a reward distribution
    /// @param user Address of the user
    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return The current user asset index, not including new distributions
    function getUserAssetIndex(
        address user,
        address asset,
        address reward
    ) external view returns (uint256);

    /// @dev Returns the configuration of the distribution reward for a certain asset
    /// @param asset The incentivized asset
    /// @param reward The reward token of the incentivized asset
    /// @return The index of the asset distribution
    /// @return The emission per second of the reward distribution
    /// @return The timestamp of the last update of the index
    /// @return The timestamp of the distribution end
    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /// @dev Returns the list of available reward token addresses of an incentivized asset
    /// @param asset The incentivized asset
    /// @return List of rewards addresses of the input asset
    function getRewardsByAsset(address asset) external view returns (address[] memory);

    /// @dev Returns the list of available reward addresses
    /// @return List of rewards supported in this contract
    function getRewardsList() external view returns (address[] memory);

    /// @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
    /// @param user The address of the user
    /// @param reward The address of the reward token
    /// @return Unclaimed rewards, not including new distributions
    function getUserAccruedRewards(address user, address reward) external view returns (uint256);

    /// @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
    /// @param assets List of incentivized assets to check eligible distributions
    /// @param user The address of the user
    /// @param reward The address of the reward token
    /// @return The rewards amount
    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    /// @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
    /// @param assets List of incentivized assets to check eligible distributions
    /// @param user The address of the user
    /// @return The list of reward addresses
    /// @return The list of unclaimed amount of rewards
    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        returns (address[] memory, uint256[] memory);

    /// @dev Returns the decimals of an asset to calculate the distribution delta
    /// @param asset The address to retrieve decimals
    /// @return The decimals of an underlying asset
    function getAssetDecimals(address asset) external view returns (uint8);

    /// @dev Returns the address of the emission manager
    /// @return The address of the EmissionManager
    function getEmissionManager() external view returns (address);

    /// @dev Updates the address of the emission manager
    /// @param emissionManager The address of the new EmissionManager
    function setEmissionManager(address emissionManager) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Permissionless state-mutating actions
/// @notice Contains state-mutating functions that can be called by anyone
/// @author Solid World DAO
interface ISolidStakingActions {
    /// @dev Stakes tokens for the caller into the staking contract
    /// @param token the token to stake
    /// @param amount the amount to stake
    function stake(address token, uint amount) external;

    /// @dev Withdraws tokens for the caller from the staking contract
    /// @param token the token to withdraw
    /// @param amount the amount to withdraw
    function withdraw(address token, uint amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Errors thrown by the staking contract
/// @author Solid World DAO
interface ISolidStakingErrors {
    error InvalidTokenAddress(address token);
    error TokenAlreadyAdded(address token);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Events emitted by the staking contract
/// @notice Contains all events emitted by the staking contract
/// @author Solid World DAO
interface ISolidStakingEvents {
    /// @dev Emitted when an account stakes tokens
    /// @param account the account that staked tokens
    /// @param token the token that was staked
    /// @param amount the amount of tokens that were staked
    event Stake(address indexed account, address indexed token, uint indexed amount);

    /// @dev Emitted when an account un-stakes tokens
    /// @param account the account that withdrew tokens
    /// @param token the token that was withdrawn
    /// @param amount the amount of tokens that were withdrawn
    event Withdraw(address indexed account, address indexed token, uint indexed amount);

    /// @dev Emitted when a new token is added to the staking contract
    /// @param token the token that was added
    event TokenAdded(address indexed token);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Permissioned staking actions
/// @notice Contains staking methods may only be called by the owner
/// @author Solid World DAO
interface ISolidStakingOwnerActions {
    /// @dev Adds a new token to the staking contract
    /// @param token the token to add
    function addToken(address token) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Permissionless view actions
/// @notice Contains view functions that can be called by anyone
/// @author Solid World DAO
interface ISolidStakingViewActions {
    /// @dev Computes the amount of tokens that the `account` has staked
    /// @param token the token to check
    /// @param account the account to check
    /// @return the amount of `token` tokens that the `account` has staked
    function balanceOf(address token, address account) external view returns (uint);

    /// @dev Computes the total amount of tokens that have been staked
    /// @param token the token to check
    /// @return the total amount of `token` tokens that have been staked
    function totalStaked(address token) external view returns (uint);

    /// @dev Returns the list of tokens that can be staked
    /// @return the list of tokens that can be staked
    function getTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token) private view returns (bool success) {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interfaces/rewards/IEACAggregatorProxy.sol";

library RewardsDataTypes {
    struct RewardsConfigInput {
        uint88 emissionPerSecond;
        uint256 totalStaked;
        uint32 distributionEnd;
        address asset; // hypervisor
        address reward; // CBT, USDC, Governance token
        IEACAggregatorProxy rewardOracle;
    }

    struct UserAssetBalance {
        address asset;
        uint256 userStake;
        uint256 totalStaked;
    }

    struct UserData {
        uint104 index;
        uint128 accrued;
    }

    struct RewardData {
        uint104 index;
        uint88 emissionPerSecond;
        uint32 lastUpdateTimestamp;
        uint32 distributionEnd;
        mapping(address => UserData) usersData;
    }

    struct AssetData {
        mapping(address => RewardData) rewards;
        mapping(uint128 => address) availableRewards;
        uint128 availableRewardsCount;
        uint8 decimals;
    }
}