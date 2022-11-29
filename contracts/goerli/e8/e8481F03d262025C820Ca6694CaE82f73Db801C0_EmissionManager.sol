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

/// @title The interface weekly carbon rewards processing
/// @notice Computes and mints weekly carbon rewards
/// @author Solid World DAO
interface IWeeklyCarbonRewardsManager {
    event WeeklyRewardMinted(address indexed rewardToken, uint indexed rewardAmount);

    /// @dev Thrown if minting weekly rewards is called by an unauthorized account
    error UnauthorizedRewardMinting(address account);

    /// @param _weeklyRewardsMinter The only account allowed to mint weekly carbon rewards
    function setWeeklyRewardsMinter(address _weeklyRewardsMinter) external;

    /// @param assets The incentivized assets (LP tokens)
    /// @param _categoryIds The categories to which the incentivized assets belong
    /// @return carbonRewards List of carbon rewards getting distributed.
    /// @return rewardAmounts List of carbon reward amounts getting distributed
    function computeWeeklyCarbonRewards(address[] calldata assets, uint[] calldata _categoryIds)
        external
        view
        returns (address[] memory carbonRewards, uint[] memory rewardAmounts);

    /// @param carbonRewards List of carbon rewards to mint
    /// @param rewardAmounts List of carbon reward amounts to mint
    /// @param rewardsVault Account that secures ERC20 rewards
    function mintWeeklyCarbonRewards(
        address[] calldata carbonRewards,
        uint[] calldata rewardAmounts,
        address rewardsVault
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6 <0.9.0;

interface IEACAggregatorProxy {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../../libraries/RewardsDataTypes.sol";
import "./IRewardsController.sol";

/// @title IEmissionManager
/// @author Aave
/// @notice Defines the basic interface for the Emission Manager
interface IEmissionManager {
    error NotEmissionAdmin(address sender, address reward);

    /// @dev Emitted when the admin of a reward emission is updated.
    /// @param reward The address of the rewarding token
    /// @param oldAdmin The address of the old emission admin
    /// @param newAdmin The address of the new emission admin
    event EmissionAdminUpdated(
        address indexed reward,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    /// @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
    /// @dev Only callable by the emission admin of the given rewards
    /// @param config The assets configuration input, the list of structs contains the following fields:
    ///   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
    ///   uint256 totalSupply: The total supply of the asset to incentivize
    ///   uint40 distributionEnd: The end of the distribution of the incentives for an asset
    ///   address asset: The asset address to incentivize
    ///   address reward: The reward token address
    ///   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
    ///                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
    function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

    /// @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
    /// @dev Only callable by the emission admin of the given reward
    /// @notice At the moment of reward configuration, the Incentives Controller performs
    /// a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
    /// This check is enforced for integrators to be able to show incentives at
    /// the current Aave UI without the need to setup an external price registry
    /// @param reward The address of the reward to set the price aggregator
    /// @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

    /// @dev Sets the end date for the distribution
    /// @dev Only callable by the emission admin of the given reward
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

    /// @dev Computes and mints weekly carbon rewards, and instructs RewardsController how to distribute them
    /// @param assets The incentivized assets (hypervisors)
    /// @param _categoryIds The categories to which the incentivized assets belong
    function updateCarbonRewardDistribution(address[] calldata assets, uint[] calldata _categoryIds)
        external;

    /// @dev Whitelists an address to claim the rewards on behalf of another address
    /// @dev Only callable by the owner of the EmissionManager
    /// @param user The address of the user
    /// @param claimer The address of the claimer
    function setClaimer(address user, address claimer) external;

    /// @dev Updates the address of the emission manager
    /// @dev Only callable by the owner of the EmissionManager
    /// @param emissionManager The address of the new EmissionManager
    function setEmissionManager(address emissionManager) external;

    /// @dev Updates the admin of the reward emission
    /// @dev Only callable by the owner of the EmissionManager
    /// @param reward The address of the reward token
    /// @param admin The address of the new admin of the emission
    function setEmissionAdmin(address reward, address admin) external;

    /// @dev Updates the address of the rewards controller
    /// @dev Only callable by the owner of the EmissionManager
    /// @param controller the address of the RewardsController contract
    function setRewardsController(address controller) external;

    /// @dev Returns the rewards controller address
    /// @return The address of the RewardsController contract
    function getRewardsController() external view returns (IRewardsController);

    /// @dev Returns the admin of the given reward emission
    /// @param reward The address of the reward token
    /// @return The address of the emission admin
    function getEmissionAdmin(address reward) external view returns (address);

    /// @return The address of the IWeeklyCarbonRewardsManager implementation contract
    function getCarbonRewardsManager() external view returns (address);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/rewards/IEmissionManager.sol";
import "../interfaces/manager/IWeeklyCarbonRewardsManager.sol";
import "../PostConstruct.sol";

/// @title EmissionManager
/// @author Aave
/// @notice It manages the list of admins of reward emissions and provides functions to control reward emissions.
contract EmissionManager is Ownable, IEmissionManager, PostConstruct {
    // reward => emissionAdmin
    mapping(address => address) internal _emissionAdmins;

    IWeeklyCarbonRewardsManager internal _carbonRewardsManager;
    IRewardsController internal _rewardsController;
    address internal carbonRewardAdmin;

    /// @dev Only emission admin of the given reward can call functions marked by this modifier.
    modifier onlyEmissionAdmin(address reward) {
        if (_emissionAdmins[reward] != msg.sender) {
            revert NotEmissionAdmin(msg.sender, reward);
        }
        _;
    }

    function setup(
        IWeeklyCarbonRewardsManager carbonRewardsManager,
        IRewardsController controller,
        address owner
    ) external postConstruct {
        _carbonRewardsManager = carbonRewardsManager;
        _rewardsController = controller;
        transferOwnership(owner);
    }

    /// @inheritdoc IEmissionManager
    function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config)
        external
        override
    {
        for (uint i; i < config.length; i++) {
            if (_emissionAdmins[config[i].reward] != msg.sender) {
                revert NotEmissionAdmin(msg.sender, config[i].reward);
            }
        }
        _rewardsController.configureAssets(config);
    }

    /// @inheritdoc IEmissionManager
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle)
        external
        override
        onlyEmissionAdmin(reward)
    {
        _rewardsController.setRewardOracle(reward, rewardOracle);
    }

    /// @inheritdoc IEmissionManager
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external override onlyEmissionAdmin(reward) {
        _rewardsController.setDistributionEnd(asset, reward, newDistributionEnd);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external override {
        for (uint i; i < rewards.length; i++) {
            if (_emissionAdmins[rewards[i]] != msg.sender) {
                revert NotEmissionAdmin(msg.sender, rewards[i]);
            }
        }
        _rewardsController.setEmissionPerSecond(asset, rewards, newEmissionsPerSecond);
    }

    /// @inheritdoc IEmissionManager
    function updateCarbonRewardDistribution(address[] calldata assets, uint[] calldata categoryIds)
        external
        override
    {
        (address[] memory carbonRewards, uint[] memory rewardAmounts) = _carbonRewardsManager
            .computeWeeklyCarbonRewards(assets, categoryIds);

        _rewardsController.updateRewardDistribution(assets, carbonRewards, rewardAmounts);

        _carbonRewardsManager.mintWeeklyCarbonRewards(
            carbonRewards,
            rewardAmounts,
            _rewardsController.getRewardsVault()
        );
    }

    /// @inheritdoc IEmissionManager
    function setClaimer(address user, address claimer) external override onlyOwner {
        _rewardsController.setClaimer(user, claimer);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionManager(address emissionManager) external override onlyOwner {
        _rewardsController.setEmissionManager(emissionManager);
    }

    /// @inheritdoc IEmissionManager
    function setEmissionAdmin(address reward, address admin) external override onlyOwner {
        address oldAdmin = _emissionAdmins[reward];
        _emissionAdmins[reward] = admin;
        emit EmissionAdminUpdated(reward, oldAdmin, admin);
    }

    /// @inheritdoc IEmissionManager
    function setRewardsController(address controller) external override onlyOwner {
        _rewardsController = IRewardsController(controller);
    }

    /// @inheritdoc IEmissionManager
    function getRewardsController() external view override returns (IRewardsController) {
        return _rewardsController;
    }

    /// @inheritdoc IEmissionManager
    function getEmissionAdmin(address reward) external view override returns (address) {
        return _emissionAdmins[reward];
    }

    /// @inheritdoc IEmissionManager
    function getCarbonRewardsManager() external view override returns (address) {
        return address(_carbonRewardsManager);
    }
}