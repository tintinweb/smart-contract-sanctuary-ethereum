// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "../utils/Governable.sol";
import "../interfaces/risk/ICoverageDataProvider.sol";
import "../interfaces/utils/IRegistry.sol";
import "../interfaces/risk/IRiskManager.sol";

/**
 * @title RiskManager
 * @author solace.fi
 * @notice Calculates the acceptable risk, sellable cover, and capital requirements of Solace products and capital pool.
 *
 * The total amount of sellable coverage is proportional to the assets in the [**risk backing capital pool**](./Vault). The max cover is split amongst products in a weighting system. [**Governance**](/docs/protocol/governance) can change these weights and with it each product's sellable cover.
 *
 * The minimum capital requirement is proportional to the amount of cover sold to active policies.
 *
 * Solace can use leverage to sell more cover than the available capital. The amount of leverage is stored as [`partialReservesFactor`](#partialreservesfactor) and is settable by [**governance**](/docs/protocol/governance).
 */
contract RiskManager is IRiskManager, Governable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice Holds mapping strategy => inddex.
    mapping(address => uint256) private _strategyToIndex;
    /// @notice Holds mapping index => strategy.
    mapping(uint256 => address) private _indexToStrategy;
    /// @notice Holds strategies.
    mapping(address => Strategy) private _strategies;
    /// @notice Returns true if the caller valid cover limit updater.
    mapping(address => bool) public canUpdateCoverLimit;
    // The current amount covered (in wei).
    uint256 internal _activeCoverLimit;
    /// @notice The current amount covered (in wei) per strategy;
    mapping(address => uint256) internal _activeCoverLimitPerStrategy;
    /// @notice The total strategy count.
    uint256 private _strategyCount;
    /// @notice The total weight sum of all strategies.
    uint32 private _weightSum;
    /// @notice Multiplier for minimum capital requirement in BPS.
    uint16 private _partialReservesFactor;
    /// @notice 10k basis points (100%).
    uint16 private constant MAX_BPS = 10000;

    /// @notice Registry contract.
    IRegistry private _registry;

    /**
     * @notice Constructs the RiskManager contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ Address of registry.
     */
    constructor(address governance_, address registry_) Governable(governance_) {
        require(registry_ != address(0x0), "zero address registry");
        _registry = IRegistry(registry_);
        _partialReservesFactor = MAX_BPS;
    }

    /***************************************
    RISK MANAGER MUTUATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a new `Risk Strategy` to the `Risk Manager`. The community votes the strategy for coverage weight allocation.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @return index The index of the risk strategy.
    */
    function addRiskStrategy(address strategy_) external override onlyGovernance returns (uint256 index) {
        require(strategy_ != address(0x0), "zero address strategy");
        require(_strategyToIndex[strategy_] == 0, "duplicate strategy");

        uint256 strategyCount = _strategyCount;
        _strategies[strategy_] = Strategy({
            id: ++strategyCount,
            weight: 0,
            status: StrategyStatus.INACTIVE,
            timestamp: block.timestamp
        });
        _strategyToIndex[strategy_] = strategyCount;
        _indexToStrategy[strategyCount] = strategy_;
        _strategyCount = strategyCount;
        emit StrategyAdded(strategy_);
        return strategyCount;
    }

    /**
     * @notice Sets the weight of the `Risk Strategy`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @param weight_ The value to set.
    */
    function setWeightAllocation(address strategy_, uint32 weight_) external override onlyGovernance {
        require(weight_ > 0, "invalid weight!");
        require(strategyIsActive(strategy_), "inactive strategy");
        require(validateAllocation(strategy_, weight_), "invalid weight allocation");
        Strategy storage riskStrategy = _strategies[strategy_];
        _weightSum = (_weightSum + weight_) - riskStrategy.weight;
        riskStrategy.weight = weight_;
        emit RiskStrategyWeightAllocationSet(strategy_, weight_);
    }

    /**
     * @notice Sets the status of the `Risk Strategy`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @param status_ The status to set.
    */
    function setStrategyStatus(address strategy_, uint8 status_) public override onlyGovernance {
        require(strategy_ != address(0x0), "zero address strategy");
        require(_strategyToIndex[strategy_] > 0, "non-exist strategy");
        Strategy storage riskStrategy = _strategies[strategy_];
        riskStrategy.status = StrategyStatus(status_);
        emit StrategyStatusUpdated(strategy_, status_);
    }

   /**
     * @notice Updates the active cover limit amount for the given strategy. 
     * This function is only called by valid requesters when a new policy is bought or updated.
     * @dev The policy manager and soteria will call this function for now.
     * @param strategy The strategy address to add cover limit.
     * @param currentCoverLimit The current cover limit amount of the strategy's product.
     * @param newCoverLimit The new cover limit amount of the strategy's product.
    */
    function updateActiveCoverLimitForStrategy(address strategy, uint256 currentCoverLimit, uint256 newCoverLimit) external override {
        require(canUpdateCoverLimit[msg.sender], "unauthorized caller");
        require(strategyIsActive(strategy), "inactive strategy");
        uint256 oldCoverLimitOfStrategy = _activeCoverLimitPerStrategy[strategy];
        _activeCoverLimit = _activeCoverLimit - currentCoverLimit + newCoverLimit;
        uint256 newCoverLimitOfStrategy = oldCoverLimitOfStrategy - currentCoverLimit + newCoverLimit;
        _activeCoverLimitPerStrategy[strategy] = newCoverLimitOfStrategy;
        emit ActiveCoverLimitUpdated(strategy, oldCoverLimitOfStrategy, newCoverLimitOfStrategy);
    }

    /**
     * @notice Adds new address to allow updating cover limit amounts.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updater The address that can update cover limit.
    */
    function addCoverLimitUpdater(address updater) external override onlyGovernance {
        require(updater != address(0x0), "zero address coverlimit updater");
        canUpdateCoverLimit[updater] = true;
        emit CoverLimitUpdaterAdded(updater);
    }

    /**
     * @notice Removes the cover limit updater.
     * @param updater The address of updater to remove.
    */
    function removeCoverLimitUpdater(address updater) external override onlyGovernance {
        require(updater != address(0x0), "zero address coverlimit updater");
        delete canUpdateCoverLimit[updater];
        emit CoverLimitUpdaterDeleted(updater);
    }

    /***************************************
    RISK MANAGER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Checks if the given risk strategy is active.
     * @param strategy_ The risk strategy.
     * @return status True if the strategy is active.
     */
    function strategyIsActive(address strategy_) public view override returns (bool status) {
        return _strategies[strategy_].status == StrategyStatus.ACTIVE;
    }

    /**
    * @notice Return the strategy at an index.
    * @dev Enumerable `[1, numStrategies]`.
    * @param index_ Index to query.
    * @return strategy The product address.
    */
    function strategyAt(uint256 index_) external view override returns (address strategy) {
       return _indexToStrategy[index_];
    }

    /**
     * @notice Returns the number of registered strategies..
     * @return count The number of strategies.
    */
    function numStrategies() external view override returns (uint256 count) {
        return _strategyCount;
    }

    /**
     * @notice Returns the risk strategy information.
     * @param strategy_ The risk strategy.
     * @return id The id of the risk strategy.
     * @return weight The risk strategy weight allocation.
     * @return status The status of risk strategy.
     * @return timestamp The added time of the risk strategy.
     *
    */
    function strategyInfo(address strategy_) external view override returns (uint256 id, uint32 weight, StrategyStatus status, uint256 timestamp) {
        Strategy memory strategy = _strategies[strategy_];
        return (strategy.id, strategy.weight, strategy.status, strategy.timestamp);
    }

    /**
     * @notice Returns the allocated weight for the risk strategy.
     * @param strategy_ The risk strategy.
     * @return weight The risk strategy weight allocation.
    */
    function weightPerStrategy(address strategy_) public view override returns (uint32 weight) {
        Strategy memory strategy = _strategies[strategy_];
        return strategy.weight;
    }

    /**
     * @notice The maximum amount of cover that Solace as a whole can sell.
     * @return cover The max amount of cover in wei.
     */
    function maxCover() public view override returns (uint256 cover) {
        return ICoverageDataProvider(_registry.get("coverageDataProvider")).maxCover() * MAX_BPS / _partialReservesFactor;
    }

    /**
     * @notice The maximum amount of cover for given strategy can sell.
     * @return cover The max amount of cover in wei.
     */
     function maxCoverPerStrategy(address strategy_) public view override returns (uint256 cover) {
        if (!strategyIsActive(strategy_)) return 0;
        uint256 maxCoverage = maxCover();
        uint32 weight = weightPerStrategy(strategy_);
        return maxCoverage = (maxCoverage * weight) / weightSum();
    }

    /**
     * @notice Returns the sum of allocation weights for all strategies.
     * @return sum WeightSum.
     */
    function weightSum() public view override returns (uint32 sum) {
        return _weightSum == 0 ? type(uint32).max : _weightSum;
    }

    /**
     * @notice Returns the current amount covered (in wei).
     * @return amount The covered amount (in wei).
    */
    function activeCoverLimit() public view override returns (uint256 amount) {
        return _activeCoverLimit;
    }

    /**
     * @notice Returns the current amount covered (in wei).
     * @param riskStrategy The risk strategy address.
     * @return amount The covered amount (in wei).
    */
    function activeCoverLimitPerStrategy(address riskStrategy) public view override returns (uint256 amount) {
        return _activeCoverLimitPerStrategy[riskStrategy];
    }

    /***************************************
    MIN CAPITAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @return mcr The minimum capital requirement.
     */
    function minCapitalRequirement() external view override returns (uint256 mcr) {
        return activeCoverLimit() * _partialReservesFactor / MAX_BPS;
    }

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @dev The strategy could have active policies when it is disabled. Because of that
     * we are not adding "strategyIsActive()" require statement.
     * @param strategy The risk strategy.
     * @return smcr The strategy minimum capital requirement.
     */
    function minCapitalRequirementPerStrategy(address strategy) public view override returns (uint256 smcr) {
        return activeCoverLimitPerStrategy(strategy) * _partialReservesFactor / MAX_BPS;
    }

    /**
     * @notice Multiplier for minimum capital requirement.
     * @return factor Partial reserves factor in BPS.
     */
    function partialReservesFactor() external view override returns (uint16 factor) {
        return _partialReservesFactor;
    }

    /**
     * @notice Sets the partial reserves factor.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param partialReservesFactor_ New partial reserves factor in BPS.
     */
    function setPartialReservesFactor(uint16 partialReservesFactor_) external override onlyGovernance {
        _partialReservesFactor = partialReservesFactor_;
        emit PartialReservesFactorSet(partialReservesFactor_);
    }

    /**
     * @notice The function checks if the new weight allocation is valid.
     * @param strategy_ The strategy address.
     * @param weight_ The weight allocation to set.
     * @return status True if the weight allocation is valid.
    */
    function validateAllocation(address strategy_, uint32 weight_) private view returns(bool status) {
        Strategy memory riskStrategy = _strategies[strategy_];
        uint32 weightsum = _weightSum;
        // check if new allocation is valid for the strategy
        uint256 smcr = minCapitalRequirementPerStrategy(strategy_);
        uint256 mc = maxCover();
        weightsum = weightsum + weight_ - riskStrategy.weight;
        uint256 newAllocationAmount = (mc * weight_) / weightsum;

        if (newAllocationAmount < smcr) return false;

        // check other risk strategies
        uint256 strategyCount = _strategyCount;
        for (uint256 i = strategyCount; i > 0; i--) {
            address strategy = _indexToStrategy[i];
            riskStrategy = _strategies[strategy];
            smcr = minCapitalRequirementPerStrategy(strategy);

            if (strategy == strategy_ || riskStrategy.weight == 0 || smcr == 0) continue;
            newAllocationAmount = (mc * riskStrategy.weight) / weightsum;
            if (newAllocationAmount < smcr) return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../interfaces/utils/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./../interfaces/utils/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() public view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title ICoverageDataProvider
 * @author solace.fi
 * @notice Holds underwriting pool amounts in `USD`. Provides information to the [**Risk Manager**](./RiskManager.sol) that is the maximum amount of cover that `Solace` protocol can sell as a coverage.
*/
interface ICoverageDataProvider {
    /***************************************
     EVENTS
    ***************************************/

    /// @notice Emitted when the underwriting pool is set.
    event UnderwritingPoolSet(string uwpName, uint256 amount);

    /// @notice Emitted when underwriting pool is removed.
    event UnderwritingPoolRemoved(string uwpName);

    /// @notice Emitted when underwriting pool updater is set.
    event UwpUpdaterSet(address uwpUpdater);

    /***************************************
     MUTUATOR FUNCTIONS
    ***************************************/

    /**
      * @notice Resets the underwriting pool balances.
      * @param uwpNames The underwriting pool values to set.
      * @param amounts The underwriting pool balances.
    */
    function reset(string[] calldata uwpNames, uint256[] calldata amounts) external;

    /**
     * @notice Sets the balance of the given underwriting pool.
     * @param uwpName The underwriting pool name to set balance.
     * @param amount The balance of the underwriting pool in `USD`.
    */
    function set(string calldata uwpName, uint256 amount) external;

    /**
     * @notice Removes the given underwriting pool.
     * @param uwpName The underwriting pool name to remove.
    */
    function remove(string calldata uwpName) external;

    /***************************************
     VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The maximum amount of cover in `USD` that Solace as a whole can sell.
     * @return cover The max amount of cover in `USD`.
    */
    function maxCover() external view returns (uint256 cover);

    /**
     * @notice Returns the balance of the underwriting pool in `USD`.
     * @param uwpName The underwriting pool name to get balance.
     * @return amount The balance of the underwriting pool in `USD`.
    */
    function balanceOf(string memory uwpName) external view returns (uint256 amount); 

    /**
     * @notice Returns underwriting pool name for given index.
     * @param index The underwriting pool index to get.
     * @return uwpName The underwriting pool name.
    */
    function poolOf(uint256 index) external view returns (string memory uwpName);

    /**
     * @notice Returns the underwriting pool bot updater address.
     * @return uwpUpdater The bot address.
    */
    function getUwpUpdater() external view returns (address uwpUpdater);

    /***************************************
     GOVERNANCE FUNCTIONS
    ***************************************/
    
    /**
     * @notice Sets the underwriting pool bot updater.
     * @param uwpUpdater The bot address to set.
    */
    function setUwpUpdater(address uwpUpdater) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * A key is a unique identifier for each contract. Use [`get(key)`](#get) or [`tryGet(key)`](#tryget) to get the address of the contract. Enumerate the keys with [`length()`](#length) and [`getKey(index)`](#getkey).
 */
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a record is set.
    event RecordSet(string indexed key, address indexed value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice The number of unique keys.
    function length() external view returns (uint256);

    /**
     * @notice Gets the `value` of a given `key`.
     * Reverts if the key is not in the mapping.
     * @param key The key to query.
     * @param value The value of the key.
     */
    function get(string calldata key) external view returns (address value);

    /**
     * @notice Gets the `value` of a given `key`.
     * Fails gracefully if the key is not in the mapping.
     * @param key The key to query.
     * @param success True if the key was found, false otherwise.
     * @param value The value of the key or zero if it was not found.
     */
    function tryGet(string calldata key) external view returns (bool success, address value);

    /**
     * @notice Gets the `key` of a given `index`.
     * @dev Iterable [1,length].
     * @param index The index to query.
     * @return key The key at that index.
     */
    function getKey(uint256 index) external view returns (string memory key);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets keys and values.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param keys The keys to set.
     * @param values The values to set.
     */
    function set(string[] calldata keys, address[] calldata values) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRiskManager
 * @author solace.fi
 * @notice Calculates the acceptable risk, sellable cover, and capital requirements of Solace products and capital pool.
 *
 * The total amount of sellable coverage is proportional to the assets in the [**risk backing capital pool**](../Vault). The max cover is split amongst products in a weighting system. [**Governance**](/docs/protocol/governance). can change these weights and with it each product's sellable cover.
 *
 * The minimum capital requirement is proportional to the amount of cover sold to [active policies](../PolicyManager).
 *
 * Solace can use leverage to sell more cover than the available capital. The amount of leverage is stored as [`partialReservesFactor`](#partialreservesfactor) and is settable by [**governance**](/docs/protocol/governance).
 */
interface IRiskManager {

    /***************************************
    TYPE DEFINITIONS
    ***************************************/

    enum StrategyStatus {
       INACTIVE,
       ACTIVE
    }

    struct Strategy {
        uint256 id;
        uint32 weight;
        StrategyStatus status;
        uint256 timestamp;
    }

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when new strategy is created.
    event StrategyAdded(address strategy);

    /// @notice Emitted when strategy status is updated.
    event StrategyStatusUpdated(address strategy, uint8 status);

    /// @notice Emitted when strategy's allocation weight is increased.
    event RiskStrategyWeightAllocationIncreased(address strategy, uint32 weight);

    /// @notice Emitted when strategy's allocation weight is decreased.
    event RiskStrategyWeightAllocationDecreased(address strategy, uint32 weight);

    /// @notice Emitted when strategy's allocation weight is set.
    event RiskStrategyWeightAllocationSet(address strategy, uint32 weight);

    /// @notice Emitted when the partial reserves factor is set.
    event PartialReservesFactorSet(uint16 partialReservesFactor);

    /// @notice Emitted when the cover limit amount of the strategy is updated.
    event ActiveCoverLimitUpdated(address strategy, uint256 oldCoverLimit, uint256 newCoverLimit);

    /// @notice Emitted when the cover limit updater is set.
    event CoverLimitUpdaterAdded(address updater);

    /// @notice Emitted when the cover limit updater is removed.
    event CoverLimitUpdaterDeleted(address updater);

    /***************************************
    RISK MANAGER MUTUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a new `Risk Strategy` to the `Risk Manager`. The community votes the strategy for coverage weight allocation.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @return index The index of the risk strategy.
    */
    function addRiskStrategy(address strategy_) external returns (uint256 index);

    /**
     * @notice Sets the weight of the `Risk Strategy`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @param weight_ The value to set.
    */
    function setWeightAllocation(address strategy_, uint32 weight_) external;

    /**
     * @notice Sets the status of the `Risk Strategy`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @param status_ The status to set.
    */
    function setStrategyStatus(address strategy_, uint8 status_) external;

   /**
     * @notice Updates the active cover limit amount for the given strategy. 
     * This function is only called by valid requesters when a new policy is bought or updated.
     * @dev The policy manager and soteria will call this function for now.
     * @param strategy The strategy address to add cover limit.
     * @param currentCoverLimit The current cover limit amount of the strategy's product.
     * @param newCoverLimit The new cover limit amount of the strategy's product.
    */
    function updateActiveCoverLimitForStrategy(address strategy, uint256 currentCoverLimit, uint256 newCoverLimit) external;

    /**
     * @notice Adds new address to allow updating cover limit amounts.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updater The address that can update cover limit.
    */
    function addCoverLimitUpdater(address updater) external ;

    /**
     * @notice Removes the cover limit updater.
     * @param updater The address of updater to remove.
    */
    function removeCoverLimitUpdater(address updater) external;

    /***************************************
    RISK MANAGER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Checks is an address is an active strategy.
     * @param strategy_ The risk strategy.
     * @return status True if the strategy is active.
    */
    function strategyIsActive(address strategy_) external view returns (bool status);

     /**
      * @notice Return the strategy at an index.
      * @dev Enumerable `[1, numStrategies]`.
      * @param index_ Index to query.
      * @return strategy The product address.
    */
    function strategyAt(uint256 index_) external view returns (address strategy);

    /**
     * @notice Returns the number of registered strategies..
     * @return count The number of strategies.
    */
    function numStrategies() external view returns (uint256 count);

    /**
     * @notice Returns the risk strategy information.
     * @param strategy_ The risk strategy.
     * @return id The id of the risk strategy.
     * @return weight The risk strategy weight allocation.
     * @return status The status of risk strategy.
     * @return timestamp The added time of the risk strategy.
     *
    */
    function strategyInfo(address strategy_) external view returns (uint256 id, uint32 weight, StrategyStatus status, uint256 timestamp);

    /**
     * @notice Returns the allocated weight for the risk strategy.
     * @param strategy_ The risk strategy.
     * @return weight The risk strategy weight allocation.
    */
    function weightPerStrategy(address strategy_) external view returns (uint32 weight);

    /**
     * @notice The maximum amount of cover for given strategy can sell.
     * @return cover The max amount of cover in wei.
     */
    function maxCoverPerStrategy(address strategy_) external view returns (uint256 cover);

    /**
     * @notice Returns the current amount covered (in wei).
     * @return amount The covered amount (in wei).
    */
    function activeCoverLimit() external view returns (uint256 amount);

    /**
     * @notice Returns the current amount covered (in wei).
     * @param riskStrategy The risk strategy address.
     * @return amount The covered amount (in wei).
    */
    function activeCoverLimitPerStrategy(address riskStrategy) external view returns (uint256 amount);

    /***************************************
    MAX COVER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The maximum amount of cover that Solace as a whole can sell.
     * @return cover The max amount of cover in wei.
     */
    function maxCover() external view returns (uint256 cover);

    /**
     * @notice Returns the sum of allocation weights for all strategies.
     * @return sum WeightSum.
     */
    function weightSum() external view returns (uint32 sum);

    /***************************************
    MIN CAPITAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @return mcr The minimum capital requirement.
     */
    function minCapitalRequirement() external view returns (uint256 mcr);

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @param strategy_ The risk strategy.
     * @return mcr The minimum capital requirement.
     */
    function minCapitalRequirementPerStrategy(address strategy_) external view returns (uint256 mcr);

    /**
     * @notice Multiplier for minimum capital requirement.
     * @return factor Partial reserves factor in BPS.
     */
    function partialReservesFactor() external view returns (uint16 factor);

    /**
     * @notice Sets the partial reserves factor.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param partialReservesFactor_ New partial reserves factor in BPS.
     */
    function setPartialReservesFactor(uint16 partialReservesFactor_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}