// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import './V2KeeperJob.sol';
import './utils/Pausable.sol';
import './utils/Keep3rMeteredStealthJob.sol';

contract HarvestV2Keep3rStealthJob is IKeep3rStealthJob, V2KeeperJob, Pausable, Keep3rMeteredStealthJob {
  constructor(
    address _governor,
    address _mechanicsRegistry,
    address _stealthRelayer,
    address _v2Keeper,
    uint256 _workCooldown
  ) Governable(_governor) V2KeeperJob(_v2Keeper, _mechanicsRegistry, _workCooldown) Keep3rMeteredStealthJob(_stealthRelayer) {
    _setGasMultiplier((gasMultiplier * 850) / 1_000); // expected 15% refunded gas
  }

  function workable(address _strategy) external view returns (bool) {
    return _workable(_strategy);
  }

  function _workable(address _strategy) internal view override returns (bool) {
    if (!super._workable(_strategy)) return false;
    return IBaseStrategy(_strategy).harvestTrigger(_getCallCosts(_strategy));
  }

  function _work(address _strategy) internal override {
    v2Keeper.harvest(_strategy);
  }

  // Keep3r actions
  function work(address _strategy) external upkeepStealthy notPaused {
    _workInternal(_strategy);
  }

  function forceWork(address _strategy) external onlyStealthRelayer {
    address _caller = IStealthRelayer(stealthRelayer).caller();
    _validateGovernorOrMechanic(_caller);
    _forceWork(_strategy);
  }

  function forceWorkUnsafe(address _strategy) external onlyGovernorOrMechanic {
    _forceWork(_strategy);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './utils/GasBaseFee.sol';
import './utils/MachineryReady.sol';
import '../interfaces/IV2KeeperJob.sol';
import '../interfaces/external/IV2Keeper.sol';
import '../interfaces/IBaseStrategy.sol';

abstract contract V2KeeperJob is IV2KeeperJob, MachineryReady, GasBaseFee {
  using EnumerableSet for EnumerableSet.AddressSet;
  IV2Keeper public v2Keeper;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  EnumerableSet.AddressSet internal _availableStrategies;
  mapping(address => uint256) public requiredAmount;
  mapping(address => uint256) public lastWorkAt;
  uint256 public workCooldown;

  constructor(
    address _v2Keeper,
    address _mechanicsRegistry,
    uint256 _workCooldown
  ) MachineryReady(_mechanicsRegistry) {
    v2Keeper = IV2Keeper(_v2Keeper);
    if (_workCooldown > 0) _setWorkCooldown(_workCooldown);
  }

  // views
  function strategies() public view returns (address[] memory _strategies) {
    _strategies = new address[](_availableStrategies.length());
    for (uint256 i; i < _availableStrategies.length(); i++) {
      _strategies[i] = _availableStrategies.at(i);
    }
  }

  // setters

  function setV2Keeper(address _v2Keeper) external onlyGovernor {
    _setV2Keeper(_v2Keeper);
  }

  function setWorkCooldown(uint256 _workCooldown) external onlyGovernorOrMechanic {
    _setWorkCooldown(_workCooldown);
  }

  function addStrategy(address _strategy, uint256 _requiredAmount) external onlyGovernorOrMechanic {
    _addStrategy(_strategy, _requiredAmount);
  }

  function addStrategies(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external onlyGovernorOrMechanic {
    if (_strategies.length != _requiredAmounts.length) revert WrongLengths();
    for (uint256 i; i < _strategies.length; i++) {
      _addStrategy(_strategies[i], _requiredAmounts[i]);
    }
  }

  function updateRequiredAmount(address _strategy, uint256 _requiredAmount) external onlyGovernorOrMechanic {
    _updateRequiredAmount(_strategy, _requiredAmount);
  }

  function updateRequiredAmounts(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external onlyGovernorOrMechanic {
    if (_strategies.length != _requiredAmounts.length) revert WrongLengths();
    for (uint256 i; i < _strategies.length; i++) {
      _updateRequiredAmount(_strategies[i], _requiredAmounts[i]);
    }
  }

  function removeStrategy(address _strategy) external onlyGovernorOrMechanic {
    _removeStrategy(_strategy);
  }

  // internals

  function _setV2Keeper(address _v2Keeper) internal {
    v2Keeper = IV2Keeper(_v2Keeper);
  }

  function _setWorkCooldown(uint256 _workCooldown) internal {
    if (_workCooldown == 0) revert ZeroCooldown();
    workCooldown = _workCooldown;
  }

  function _addStrategy(address _strategy, uint256 _requiredAmount) internal {
    if (_availableStrategies.contains(_strategy)) revert StrategyAlreadyAdded();
    _setRequiredAmount(_strategy, _requiredAmount);
    emit StrategyAdded(_strategy, _requiredAmount);
    _availableStrategies.add(_strategy);
  }

  function _updateRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
    if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
    _setRequiredAmount(_strategy, _requiredAmount);
    emit StrategyModified(_strategy, _requiredAmount);
  }

  function _removeStrategy(address _strategy) internal {
    if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
    delete requiredAmount[_strategy];
    _availableStrategies.remove(_strategy);
    emit StrategyRemoved(_strategy);
  }

  function _setRequiredAmount(address _strategy, uint256 _requiredAmount) internal {
    requiredAmount[_strategy] = _requiredAmount;
  }

  function _workable(address _strategy) internal view virtual returns (bool) {
    if (!_availableStrategies.contains(_strategy)) revert StrategyNotAdded();
    if (workCooldown == 0 || block.timestamp > lastWorkAt[_strategy] + workCooldown) return true;
    return false;
  }

  function _getCallCosts(address _strategy) internal view returns (uint256 _callCost) {
    uint256 gasAmount = requiredAmount[_strategy];
    if (gasAmount == 0) return 0;
    return gasAmount * _gasPrice();
  }

  // Keep3r actions
  function _workInternal(address _strategy) internal {
    if (!_workable(_strategy)) revert StrategyNotWorkable();
    lastWorkAt[_strategy] = block.timestamp;
    _work(_strategy);
    emit KeeperWorked(_strategy);
  }

  function _forceWork(address _strategy) internal {
    _work(_strategy);
    emit ForceWorked(_strategy);
  }

  function _work(address _strategy) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Governable.sol';
import '../../interfaces/utils/IPausable.sol';

abstract contract Pausable is IPausable, Governable {
  bool public paused;

  // setters

  function setPause(bool _paused) external onlyGovernor {
    _setPause(_paused);
  }

  // modifiers

  modifier notPaused() {
    if (paused) revert Paused();
    _;
  }

  // internals

  function _setPause(bool _paused) internal {
    if (paused == _paused) revert NoChangeInPause();
    paused = _paused;
    emit PauseSet(_paused);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;



import './Keep3rMeteredJob.sol';
import './Keep3rBondedJob.sol';
import './OnlyEOA.sol';

import '../../interfaces/utils/IKeep3rStealthJob.sol';
import '../../interfaces/external/IStealthRelayer.sol';

abstract contract Keep3rMeteredStealthJob is IKeep3rStealthJob, Keep3rMeteredJob, Keep3rBondedJob, OnlyEOA {
  address public stealthRelayer;

  constructor(address _stealthRelayer) {
    _setStealthRelayer(_stealthRelayer);
    gasBonus = 127_000;
  }

  // setters

  function setStealthRelayer(address _stealthRelayer) public onlyGovernor {
    _setStealthRelayer(_stealthRelayer);
  }

  // modifiers

  modifier onlyStealthRelayer() {
    if (msg.sender != stealthRelayer) revert OnlyStealthRelayer();
    _;
  }

  modifier upkeepStealthy() {
    uint256 _initialGas = _getGasLeft();
    if (msg.sender != stealthRelayer) revert OnlyStealthRelayer();
    address _keeper = IStealthRelayer(stealthRelayer).caller();
    _isValidKeeper(_keeper);

    _;

    uint256 _gasAfterWork = _getGasLeft();
    uint256 _reward = (_calculateGas(_initialGas - _gasAfterWork + gasBonus) * gasMultiplier) / BASE;
    uint256 _payment = IKeep3rHelper(keep3rHelper).quote(_reward);
    IKeep3rV2(keep3r).bondedPayment(_keeper, _payment);
    emit GasMetered(_initialGas, _gasAfterWork, gasBonus);
  }

  // internals

  function _isValidKeeper(address _keeper) internal override(Keep3rBondedJob, Keep3rJob) {
    if (onlyEOA) _validateEOA(_keeper);
    super._isValidKeeper(_keeper);
  }

  function _setStealthRelayer(address _stealthRelayer) internal {
    stealthRelayer = _stealthRelayer;
    emit StealthRelayerSet(_stealthRelayer);
  }

  /// @notice Return the gas left and add 1/64 in order to match real gas left at first level of depth (EIP-150)
  function _getGasLeft() internal view returns (uint256 _gasLeft) {
    _gasLeft = (gasleft() * 64) / 63;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

abstract contract GasBaseFee {
  // internals
  function _gasPrice() internal view virtual returns (uint256) {
    return block.basefee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@yearn-mechanics/contract-utils/solidity/contracts/utils/Machinery.sol';
import './Governable.sol';

abstract contract MachineryReady is Machinery, Governable {
  error OnlyGovernorOrMechanic();

  constructor(address _mechanicsRegistry) Machinery(_mechanicsRegistry) {}

  // setters

  function setMechanicsRegistry(address _mechanicsRegistry) external override {
    _setMechanicsRegistry(_mechanicsRegistry);
  }

  // modifiers

  modifier onlyGovernorOrMechanic() {
    _validateGovernorOrMechanic(msg.sender);
    _;
  }

  // internals

  function _validateGovernorOrMechanic(address _user) internal view {
    if (_user != governor && !isMechanic(_user)) revert OnlyGovernorOrMechanic();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
import './external/IV2Keeper.sol';

interface IV2KeeperJob {
  // Errors
  error StrategyAlreadyAdded();
  error StrategyNotAdded();
  error StrategyNotWorkable();
  error ZeroCooldown();

  // Setters
  event StrategyAdded(address _strategy, uint256 _requiredAmount);
  event StrategyModified(address _strategy, uint256 _requiredAmount);
  event StrategyRemoved(address _strategy);

  // Actions by Keeper
  event KeeperWorked(address _strategy);

  // Actions forced by governor
  event ForceWorked(address _strategy);

  // Getters
  function v2Keeper() external view returns (IV2Keeper _v2Keeper);

  function strategies() external view returns (address[] memory);

  function workable(address _strategy) external view returns (bool);

  // Setters
  function setV2Keeper(address _v2Keeper) external;

  function setWorkCooldown(uint256 _workCooldown) external;

  function addStrategies(address[] calldata _strategy, uint256[] calldata _requiredAmount) external;

  function addStrategy(address _strategy, uint256 _requiredAmount) external;

  function updateRequiredAmounts(address[] calldata _strategies, uint256[] calldata _requiredAmounts) external;

  function updateRequiredAmount(address _strategy, uint256 _requiredAmount) external;

  function removeStrategy(address _strategy) external;

  // Keeper actions
  function work(address _strategy) external;

  // Mechanics keeper bypass
  function forceWork(address _strategy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IV2Keeper {
  // Getters
  function jobs() external view returns (address[] memory);

  event JobAdded(address _job);
  event JobRemoved(address _job);

  // Setters
  function addJobs(address[] calldata _jobs) external;

  function addJob(address _job) external;

  function removeJob(address _job) external;

  // Jobs actions
  function tend(address _strategy) external;

  function harvest(address _strategy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBaseStrategy {
  // events
  event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

  // views

  function vault() external view returns (address _vault);

  function strategist() external view returns (address _strategist);

  function rewards() external view returns (address _rewards);

  function keeper() external view returns (address _keeper);

  function want() external view returns (address _want);

  function name() external view returns (string memory _name);

  function profitFactor() external view returns (uint256 _profitFactor);

  function maxReportDelay() external view returns (uint256 _maxReportDelay);

  function crv() external view returns (address _crv);

  // setters
  function setStrategist(address _strategist) external;

  function setKeeper(address _keeper) external;

  function setRewards(address _rewards) external;

  function tendTrigger(uint256 callCost) external view returns (bool);

  function tend() external;

  function harvestTrigger(uint256 callCost) external view returns (bool);

  function harvest() external;

  function setBorrowCollateralizationRatio(uint256 _c) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../../interfaces/utils/IMachinery.sol';
import '../../interfaces/mechanics/IMechanicsRegistry.sol';

contract Machinery is IMachinery {
  using EnumerableSet for EnumerableSet.AddressSet;

  IMechanicsRegistry internal _mechanicsRegistry;

  constructor(address __mechanicsRegistry) {
    _setMechanicsRegistry(__mechanicsRegistry);
  }

  modifier onlyMechanic() {
    require(_mechanicsRegistry.isMechanic(msg.sender), 'Machinery: not mechanic');
    _;
  }

  function setMechanicsRegistry(address __mechanicsRegistry) external virtual override {
    _setMechanicsRegistry(__mechanicsRegistry);
  }

  function _setMechanicsRegistry(address __mechanicsRegistry) internal {
    _mechanicsRegistry = IMechanicsRegistry(__mechanicsRegistry);
  }

  // View helpers
  function mechanicsRegistry() external view override returns (address _mechanicRegistry) {
    return address(_mechanicsRegistry);
  }

  function isMechanic(address _mechanic) public view override returns (bool _isMechanic) {
    return _mechanicsRegistry.isMechanic(_mechanic);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../interfaces/utils/IGovernable.sol';

abstract contract Governable is IGovernable {
  address public governor;
  address public pendingGovernor;

  constructor(address _governor) {
    if (_governor == address(0)) revert ZeroAddress();
    governor = _governor;
  }

  // setters

  function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptPendingGovernor() external onlyPendingGovernor {
    _acceptPendingGovernor();
  }

  // modifiers

  modifier onlyGovernor() {
    if (msg.sender != governor) revert OnlyGovernor();
    _;
  }

  modifier onlyPendingGovernor() {
    if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
    _;
  }

  // internals

  function _setPendingGovernor(address _pendingGovernor) internal {
    if (_pendingGovernor == address(0)) revert ZeroAddress();
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(governor, pendingGovernor);
  }

  function _acceptPendingGovernor() internal {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit PendingGovernorAccepted(governor);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IMachinery {
  // View helpers
  function mechanicsRegistry() external view returns (address _mechanicsRegistry);

  function isMechanic(address mechanic) external view returns (bool _isMechanic);

  // Setters
  function setMechanicsRegistry(address _mechanicsRegistry) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IMechanicsRegistry {
  event MechanicAdded(address _mechanic);
  event MechanicRemoved(address _mechanic);

  function addMechanic(address _mechanic) external;

  function removeMechanic(address _mechanic) external;

  function mechanics() external view returns (address[] memory _mechanicsList);

  function isMechanic(address mechanic) external view returns (bool _isMechanic);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

interface IGovernable is IBaseErrors {
  // events
  event PendingGovernorSet(address _governor, address _pendingGovernor);
  event PendingGovernorAccepted(address _newGovernor);

  // errors
  error OnlyGovernor();
  error OnlyPendingGovernor();

  // variables
  function governor() external view returns (address _governor);

  function pendingGovernor() external view returns (address _pendingGovernor);

  // methods
  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

interface IBaseErrors {
  /// @notice Throws if a variable is assigned to the zero address
  error ZeroAddress();

  /// @notice Throws if a set of correlated input param arrays differ in lengths
  error WrongLengths();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IPausable is IGovernable {
  // events
  event PauseSet(bool _paused);

  // errors
  error Paused();
  error NoChangeInPause();

  // variables
  function paused() external view returns (bool _paused);

  // methods
  function setPause(bool _paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJob.sol';
import '../../interfaces/external/IKeep3rHelper.sol';
import '../../interfaces/utils/IKeep3rMeteredJob.sol';

abstract contract Keep3rMeteredJob is Keep3rJob, IKeep3rMeteredJob {
  address public keep3rHelper = 0xD36Ac9Ff5562abb541F51345f340FB650547a661;
  /// @dev Fixed bonus to pay for unaccounted gas in small transactions
  uint256 public gasBonus = 86_000;
  uint256 public gasMultiplier = 12_000;
  uint32 public constant BASE = 10_000;
  uint256 public maxMultiplier = 15_000;

  // setters

  function setKeep3rHelper(address _keep3rHelper) public onlyGovernor {
    _setKeep3rHelper(_keep3rHelper);
  }

  function setGasBonus(uint256 _gasBonus) external onlyGovernor {
    _setGasBonus(_gasBonus);
  }

  function setMaxMultiplier(uint256 _maxMultiplier) external onlyGovernor {
    _setMaxMultiplier(_maxMultiplier);
  }

  function setGasMultiplier(uint256 _gasMultiplier) external onlyGovernor {
    _setGasMultiplier(_gasMultiplier);
  }

  // modifiers

  modifier upkeepMetered() {
    uint256 _initialGas = gasleft();
    _isValidKeeper(msg.sender);
    _;
    uint256 _gasAfterWork = gasleft();
    uint256 _reward = (_calculateGas(_initialGas - _gasAfterWork + gasBonus) * gasMultiplier) / BASE;
    uint256 _payment = IKeep3rHelper(keep3rHelper).quote(_reward);
    IKeep3rV2(keep3r).bondedPayment(msg.sender, _payment);
    emit GasMetered(_initialGas, _gasAfterWork, gasBonus);
  }

  // internals

  function _setKeep3rHelper(address _keep3rHelper) internal {
    keep3rHelper = _keep3rHelper;
    emit Keep3rHelperSet(_keep3rHelper);
  }

  function _setGasBonus(uint256 _gasBonus) internal {
    gasBonus = _gasBonus;
    emit GasBonusSet(gasBonus);
  }

  function _setMaxMultiplier(uint256 _maxMultiplier) internal {
    maxMultiplier = _maxMultiplier;
    emit MaxMultiplierSet(maxMultiplier);
  }

  function _setGasMultiplier(uint256 _gasMultiplier) internal {
    if (_gasMultiplier > maxMultiplier) revert MaxMultiplier();
    gasMultiplier = _gasMultiplier;
    emit GasMultiplierSet(gasMultiplier);
  }

  function _calculateGas(uint256 _gasUsed) internal view returns (uint256 _resultingGas) {
    _resultingGas = block.basefee * _gasUsed;
  }

  function _calculateCredits(uint256 _gasUsed) internal view returns (uint256 _credits) {
    return IKeep3rHelper(keep3rHelper).getRewardAmount(_calculateGas(_gasUsed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJob.sol';
import '../../interfaces/utils/IKeep3rBondedJob.sol';

abstract contract Keep3rBondedJob is Keep3rJob, IKeep3rBondedJob {
  address public requiredBond = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
  uint256 public requiredMinBond = 50 ether;
  uint256 public requiredEarnings;
  uint256 public requiredAge;

  // setters

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) public onlyGovernor {
    _setKeep3rRequirements(_bond, _minBond, _earned, _age);
  }

  // internals

  function _setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) internal {
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age);
  }

  function _isValidKeeper(address _keeper) internal virtual override {
    if (!IKeep3rV2(keep3r).isBondedKeeper(_keeper, requiredBond, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../interfaces/utils/IOnlyEOA.sol';
import './Governable.sol';

abstract contract OnlyEOA is IOnlyEOA, Governable {
  bool public onlyEOA;

  // setters

  function setOnlyEOA(bool _onlyEOA) external onlyGovernor {
    _setOnlyEOA(_onlyEOA);
  }

  // internals

  function _setOnlyEOA(bool _onlyEOA) internal {
    onlyEOA = _onlyEOA;
    // TODO: add event
  }

  function _validateEOA(address _caller) internal view {
    if (_caller != tx.origin) revert OnlyEOA();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IKeep3rJob.sol';

interface IKeep3rStealthJob is IKeep3rJob {
  event StealthRelayerSet(address _stealthRelayer);

  error OnlyStealthRelayer();

  function stealthRelayer() external view returns (address _stealthRelayer);

  function setStealthRelayer(address _stealthRelayer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import './IStealthTx.sol';

interface IStealthRelayer is IStealthTx {
  function caller() external view returns (address _caller);

  function forceBlockProtection() external view returns (bool _forceBlockProtection);

  function jobs() external view returns (address[] memory _jobsList);

  function setForceBlockProtection(bool _forceBlockProtection) external;

  function addJobs(address[] calldata _jobsList) external;

  function addJob(address _job) external;

  function removeJobs(address[] calldata _jobsList) external;

  function removeJob(address _job) external;

  function execute(
    address _address,
    bytes memory _callData,
    bytes32 _stealthHash,
    uint256 _blockNumber
  ) external payable returns (bytes memory _returnData);

  function executeAndPay(
    address _address,
    bytes memory _callData,
    bytes32 _stealthHash,
    uint256 _blockNumber,
    uint256 _payment
  ) external payable returns (bytes memory _returnData);

  function executeWithoutBlockProtection(
    address _address,
    bytes memory _callData,
    bytes32 _stealthHash
  ) external payable returns (bytes memory _returnData);

  function executeWithoutBlockProtectionAndPay(
    address _job,
    bytes memory _callData,
    bytes32 _stealthHash,
    uint256 _payment
  ) external payable returns (bytes memory _returnData);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Governable.sol';
import '../../interfaces/utils/IKeep3rJob.sol';
import '../../interfaces/external/IKeep3rV2.sol';

abstract contract Keep3rJob is IKeep3rJob, Governable {
  address public keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;

  // setters

  function setKeep3r(address _keep3r) public onlyGovernor {
    _setKeep3r(_keep3r);
  }

  // modifiers

  modifier upkeep() {
    _isValidKeeper(msg.sender);
    _;
    IKeep3rV2(keep3r).worked(msg.sender);
  }

  // internals

  function _setKeep3r(address _keep3r) internal {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function _isValidKeeper(address _keeper) internal virtual {
    if (!IKeep3rV2(keep3r).isKeeper(_keeper)) revert KeeperNotValid();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Keep3rHelper contract
/// @notice Contains all the helper functions used throughout the different files.
interface IKeep3rHelper {
  // Errors

  /// @notice Throws when none of the tokens in the liquidity pair is KP3R
  error LiquidityPairInvalid();

  // Variables

  /// @notice Address of KP3R token
  /// @return _kp3r Address of KP3R token
  // solhint-disable func-name-mixedcase
  function KP3R() external view returns (address _kp3r);

  /// @notice Address of KP3R-WETH pool to use as oracle
  /// @return _kp3rWeth Address of KP3R-WETH pool to use as oracle
  function KP3R_WETH_POOL() external view returns (address _kp3rWeth);

  /// @notice The minimum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
  ///         For example: if the quoted gas used is 1000, then the minimum amount to be paid will be 1000 * MIN / BOOST_BASE
  /// @return _multiplier The MIN multiplier
  function MIN() external view returns (uint256 _multiplier);

  /// @notice The maximum multiplier used to calculate the amount of gas paid to the Keeper for the gas used to perform a job
  ///         For example: if the quoted gas used is 1000, then the maximum amount to be paid will be 1000 * MAX / BOOST_BASE
  /// @return _multiplier The MAX multiplier
  function MAX() external view returns (uint256 _multiplier);

  /// @notice The boost base used to calculate the boost rewards for the keeper
  /// @return _base The boost base number
  function BOOST_BASE() external view returns (uint256 _base);

  /// @notice The targeted amount of bonded KP3Rs to max-up reward multiplier
  ///         For example: if the amount of KP3R the keeper has bonded is TARGETBOND or more, then the keeper will get
  ///                      the maximum boost possible in his rewards, if it's less, the reward boost will be proportional
  /// @return _target The amount of KP3R that comforms the TARGETBOND
  function TARGETBOND() external view returns (uint256 _target);

  // Methods
  // solhint-enable func-name-mixedcase

  /// @notice Calculates the amount of KP3R that corresponds to the ETH passed into the function
  /// @dev This function allows us to calculate how much KP3R we should pay to a keeper for things expressed in ETH, like gas
  /// @param _eth The amount of ETH
  /// @return _amountOut The amount of KP3R
  function quote(uint256 _eth) external view returns (uint256 _amountOut);

  /// @notice Returns the amount of KP3R the keeper has bonded
  /// @param _keeper The address of the keeper to check
  /// @return _amountBonded The amount of KP3R the keeper has bonded
  function bonds(address _keeper) external view returns (uint256 _amountBonded);

  /// @notice Calculates the reward (in KP3R) that corresponds to a keeper for using gas
  /// @param _keeper The address of the keeper to check
  /// @param _gasUsed The amount of gas used that will be rewarded
  /// @return _kp3r The amount of KP3R that should be awarded to the keeper
  function getRewardAmountFor(address _keeper, uint256 _gasUsed) external view returns (uint256 _kp3r);

  /// @notice Calculates the boost in the reward given to a keeper based on the amount of KP3R that keeper has bonded
  /// @param _bonds The amount of KP3R tokens bonded by the keeper
  /// @return _rewardBoost The reward boost that corresponds to the keeper
  function getRewardBoostFor(uint256 _bonds) external view returns (uint256 _rewardBoost);

  /// @notice Calculates the reward (in KP3R) that corresponds to tx.origin for using gas
  /// @param _gasUsed The amount of gas used that will be rewarded
  /// @return _amount The amount of KP3R that should be awarded to tx.origin
  function getRewardAmount(uint256 _gasUsed) external view returns (uint256 _amount);

  /// @notice Given a pool address, returns the underlying tokens of the pair
  /// @param _pool Address of the correspondant pool
  /// @return _token0 Address of the first token of the pair
  /// @return _token1 Address of the second token of the pair
  function getPoolTokens(address _pool) external view returns (address _token0, address _token1);

  /// @notice Defines the order of the tokens in the pair for twap calculations
  /// @param _pool Address of the correspondant pool
  /// @return _isKP3RToken0 Boolean indicating the order of the tokens in the pair
  function isKP3RToken0(address _pool) external view returns (bool _isKP3RToken0);

  /// @notice Given an array of secondsAgo, returns UniswapV3 pool cumulatives at that moment
  /// @param _pool Address of the pool to observe
  /// @param _secondsAgo Array with time references to observe
  /// @return _tickCumulative1 Cummulative sum of ticks until first time reference
  /// @return _tickCumulative2 Cummulative sum of ticks until second time reference
  /// @return _success Boolean indicating if the observe call was succesfull
  function observe(address _pool, uint32[] memory _secondsAgo)
    external
    view
    returns (
      int56 _tickCumulative1,
      int56 _tickCumulative2,
      bool _success
    );

  /// @notice Given a tick and a liquidity amount, calculates the underlying KP3R tokens
  /// @param _liquidityAmount Amount of liquidity to be converted
  /// @param _tickDifference Tick value used to calculate the quote
  /// @param _timeInterval Time value used to calculate the quote
  /// @return _kp3rAmount Amount of KP3R tokens underlying on the given liquidity
  function getKP3RsAtTick(
    uint256 _liquidityAmount,
    int56 _tickDifference,
    uint256 _timeInterval
  ) external pure returns (uint256 _kp3rAmount);

  /// @notice Given a tick and a token amount, calculates the output in correspondant token
  /// @param _baseAmount Amount of token to be converted
  /// @param _tickDifference Tick value used to calculate the quote
  /// @param _timeInterval Time value used to calculate the quote
  /// @return _quoteAmount Amount of credits deserved for the baseAmount at the tick value
  function getQuoteAtTick(
    uint128 _baseAmount,
    int56 _tickDifference,
    uint256 _timeInterval
  ) external pure returns (uint256 _quoteAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IKeep3rJob.sol';

interface IKeep3rMeteredJob is IKeep3rJob {
  // Events

  event Keep3rHelperSet(address keep3rHelper);
  event GasBonusSet(uint256 gasBonus);
  event GasMultiplierSet(uint256 gasMultiplier);
  event MaxMultiplierSet(uint256 maxMultiplier);
  event GasMetered(uint256 initialGas, uint256 gasAfterWork, uint256 bonus);

  // Errors
  error MaxMultiplier();

  // Variables

  // solhint-disable-next-line func-name-mixedcase, var-name-mixedcase
  function BASE() external view returns (uint32 _BASE);

  function keep3rHelper() external view returns (address _keep3rHelper);

  function gasBonus() external view returns (uint256 _gasBonus);

  function maxMultiplier() external view returns (uint256 _gasMultiplier);

  function gasMultiplier() external view returns (uint256 _gasMultiplier);

  // Methods

  function setKeep3rHelper(address _keep3rHelper) external;

  function setGasBonus(uint256 _gasBonus) external;

  function setGasMultiplier(uint256 _gasMultiplier) external;

  function setMaxMultiplier(uint256 _maxMultiplier) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IKeep3rJob is IGovernable {
  // events
  event Keep3rSet(address _keep3r);

  // errors
  error KeeperNotValid();

  // variables
  function keep3r() external view returns (address _keep3r);

  // methods
  function setKeep3r(address _keep3r) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IKeep3rV2 {
  /// @notice Stores the tick information of the different liquidity pairs
  struct TickCache {
    int56 current; // Tracks the current tick
    int56 difference; // Stores the difference between the current tick and the last tick
    uint256 period; // Stores the period at which the last observation was made
  }

  // Events

  /// @notice Emitted when the Keep3rHelper address is changed
  /// @param _keep3rHelper The address of Keep3rHelper's contract
  event Keep3rHelperChange(address _keep3rHelper);

  /// @notice Emitted when the Keep3rV1 address is changed
  /// @param _keep3rV1 The address of Keep3rV1's contract
  event Keep3rV1Change(address _keep3rV1);

  /// @notice Emitted when the Keep3rV1Proxy address is changed
  /// @param _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  event Keep3rV1ProxyChange(address _keep3rV1Proxy);

  /// @notice Emitted when the KP3R-WETH pool address is changed
  /// @param _kp3rWethPool The address of the KP3R-WETH pool
  event Kp3rWethPoolChange(address _kp3rWethPool);

  /// @notice Emitted when bondTime is changed
  /// @param _bondTime The new bondTime
  event BondTimeChange(uint256 _bondTime);

  /// @notice Emitted when _liquidityMinimum is changed
  /// @param _liquidityMinimum The new _liquidityMinimum
  event LiquidityMinimumChange(uint256 _liquidityMinimum);

  /// @notice Emitted when _unbondTime is changed
  /// @param _unbondTime The new _unbondTime
  event UnbondTimeChange(uint256 _unbondTime);

  /// @notice Emitted when _rewardPeriodTime is changed
  /// @param _rewardPeriodTime The new _rewardPeriodTime
  event RewardPeriodTimeChange(uint256 _rewardPeriodTime);

  /// @notice Emitted when the inflationPeriod is changed
  /// @param _inflationPeriod The new inflationPeriod
  event InflationPeriodChange(uint256 _inflationPeriod);

  /// @notice Emitted when the fee is changed
  /// @param _fee The new token credits fee
  event FeeChange(uint256 _fee);

  /// @notice Emitted when a slasher is added
  /// @param _slasher Address of the added slasher
  event SlasherAdded(address _slasher);

  /// @notice Emitted when a slasher is removed
  /// @param _slasher Address of the removed slasher
  event SlasherRemoved(address _slasher);

  /// @notice Emitted when a disputer is added
  /// @param _disputer Address of the added disputer
  event DisputerAdded(address _disputer);

  /// @notice Emitted when a disputer is removed
  /// @param _disputer Address of the removed disputer
  event DisputerRemoved(address _disputer);

  /// @notice Emitted when the bonding process of a new keeper begins
  /// @param _keeper The caller of Keep3rKeeperFundable#bond function
  /// @param _bonding The asset the keeper has bonded
  /// @param _amount The amount the keeper has bonded
  event Bonding(address indexed _keeper, address indexed _bonding, uint256 _amount);

  /// @notice Emitted when a keeper or job begins the unbonding process to withdraw the funds
  /// @param _keeperOrJob The keeper or job that began the unbonding process
  /// @param _unbonding The liquidity pair or asset being unbonded
  /// @param _amount The amount being unbonded
  event Unbonding(address indexed _keeperOrJob, address indexed _unbonding, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#activate is called
  /// @param _keeper The keeper that has been activated
  /// @param _bond The asset the keeper has bonded
  /// @param _amount The amount of the asset the keeper has bonded
  event Activation(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#withdraw is called
  /// @param _keeper The caller of Keep3rKeeperFundable#withdraw function
  /// @param _bond The asset to withdraw from the bonding pool
  /// @param _amount The amount of funds withdrawn
  event Withdrawal(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#slash is called
  /// @param _keeper The slashed keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#slash
  /// @param _amount The amount of credits slashed from the keeper
  event KeeperSlash(address indexed _keeper, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#revoke is called
  /// @param _keeper The revoked keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#revoke
  event KeeperRevoke(address indexed _keeper, address indexed _slasher);

  /// @notice Emitted when Keep3rJobFundableCredits#addTokenCreditsToJob is called
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being provided
  /// @param _provider The user that calls the function
  /// @param _amount The amount of credit being added to the job
  event TokenCreditAddition(address indexed _job, address indexed _token, address indexed _provider, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableCredits#withdrawTokenCreditsFromJob is called
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The credit being withdrawn from the job
  /// @param _receiver The user that receives the tokens
  /// @param _amount The amount of credit withdrawn
  event TokenCreditWithdrawal(address indexed _job, address indexed _token, address indexed _receiver, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableLiquidity#approveLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being approved
  event LiquidityApproval(address _liquidity);

  /// @notice Emitted when Keep3rJobFundableLiquidity#revokeLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being revoked
  event LiquidityRevocation(address _liquidity);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job to which liquidity will be added
  /// @param _liquidity The address of the liquidity being added
  /// @param _provider The user that calls the function
  /// @param _amount The amount of liquidity being added
  event LiquidityAddition(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _amount);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#withdrawLiquidityFromJob function is called
  /// @param _job The address of the job of which liquidity will be withdrawn from
  /// @param _liquidity The address of the liquidity being withdrawn
  /// @param _receiver The receiver of the liquidity tokens
  /// @param _amount The amount of liquidity being withdrawn from the job
  event LiquidityWithdrawal(address indexed _job, address indexed _liquidity, address indexed _receiver, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  /// @param _periodCredits The credits of the job for the current period
  event LiquidityCreditsReward(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits, uint256 _periodCredits);

  /// @notice Emitted when Keep3rJobFundableLiquidity#forceLiquidityCreditsToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  event LiquidityCreditsForced(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits);

  /// @notice Emitted when Keep3rJobManager#addJob is called
  /// @param _job The address of the job to add
  /// @param _jobOwner The job's owner
  event JobAddition(address indexed _job, address indexed _jobOwner);

  /// @notice Emitted when a keeper is validated before a job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of keeper validation
  event KeeperValidation(uint256 _gasLeft);

  /// @notice Emitted when a keeper works a job
  /// @param _credit The address of the asset in which the keeper is paid
  /// @param _job The address of the job the keeper has worked
  /// @param _keeper The address of the keeper that has worked the job
  /// @param _amount The amount that has been paid out to the keeper in exchange for working the job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of payment
  event KeeperWork(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _amount, uint256 _gasLeft);

  /// @notice Emitted when Keep3rJobOwnership#changeJobOwnership is called
  /// @param _job The address of the job proposed to have a change of owner
  /// @param _owner The current owner of the job
  /// @param _pendingOwner The new address proposed to be the owner of the job
  event JobOwnershipChange(address indexed _job, address indexed _owner, address indexed _pendingOwner);

  /// @notice Emitted when Keep3rJobOwnership#JobOwnershipAssent is called
  /// @param _job The address of the job which the proposed owner will now own
  /// @param _previousOwner The previous owner of the job
  /// @param _newOwner The newowner of the job
  event JobOwnershipAssent(address indexed _job, address indexed _previousOwner, address indexed _newOwner);

  /// @notice Emitted when Keep3rJobMigration#migrateJob function is called
  /// @param _fromJob The address of the job that requests to migrate
  /// @param _toJob The address at which the job requests to migrate
  event JobMigrationRequested(address indexed _fromJob, address _toJob);

  /// @notice Emitted when Keep3rJobMigration#acceptJobMigration function is called
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address at which the job had requested to migrate
  event JobMigrationSuccessful(address _fromJob, address indexed _toJob);

  /// @notice Emitted when Keep3rJobDisputable#slashTokenFromJob is called
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token being slashed
  /// @param _slasher The user that slashes the token
  /// @param _amount The amount of the token being slashed
  event JobSlashToken(address indexed _job, address _token, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rJobDisputable#slashLiquidityFromJob is called
  /// @param _job The address of the job from which the liquidity will be slashed
  /// @param _liquidity The address of the liquidity being slashed
  /// @param _slasher The user that slashes the liquidity
  /// @param _amount The amount of the liquidity being slashed
  event JobSlashLiquidity(address indexed _job, address _liquidity, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when a keeper or a job is disputed
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _disputer The user that called the function and disputed the keeper
  event Dispute(address indexed _jobOrKeeper, address indexed _disputer);

  /// @notice Emitted when a dispute is resolved
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _resolver The user that called the function and resolved the dispute
  event Resolve(address indexed _jobOrKeeper, address indexed _resolver);

  // Errors

  /// @notice Throws if the reward period is less than the minimum reward period time
  error MinRewardPeriod();

  /// @notice Throws if either a job or a keeper is disputed
  error Disputed();

  /// @notice Throws if there are no bonded assets
  error BondsUnexistent();

  /// @notice Throws if the time required to bond an asset has not passed yet
  error BondsLocked();

  /// @notice Throws if there are no bonds to withdraw
  error UnbondsUnexistent();

  /// @notice Throws if the time required to withdraw the bonds has not passed yet
  error UnbondsLocked();

  /// @notice Throws if the address is already a registered slasher
  error SlasherExistent();

  /// @notice Throws if caller is not a registered slasher
  error SlasherUnexistent();

  /// @notice Throws if the address is already a registered disputer
  error DisputerExistent();

  /// @notice Throws if caller is not a registered disputer
  error DisputerUnexistent();

  /// @notice Throws if the msg.sender is not a slasher or is not a part of governance
  error OnlySlasher();

  /// @notice Throws if the msg.sender is not a disputer or is not a part of governance
  error OnlyDisputer();

  /// @notice Throws when an address is passed as a job, but that address is not a job
  error JobUnavailable();

  /// @notice Throws when an action that requires an undisputed job is applied on a disputed job
  error JobDisputed();

  /// @notice Throws when the address that is trying to register as a job is already a job
  error AlreadyAJob();

  /// @notice Throws when the token is KP3R, as it should not be used for direct token payments
  error TokenUnallowed();

  /// @notice Throws when the token withdraw cooldown has not yet passed
  error JobTokenCreditsLocked();

  /// @notice Throws when the user tries to withdraw more tokens than it has
  error InsufficientJobTokenCredits();

  /// @notice Throws when trying to add a job that has already been added
  error JobAlreadyAdded();

  /// @notice Throws when the address that is trying to register as a keeper is already a keeper
  error AlreadyAKeeper();

  /// @notice Throws when the liquidity being approved has already been approved
  error LiquidityPairApproved();

  /// @notice Throws when the liquidity being removed has not been approved
  error LiquidityPairUnexistent();

  /// @notice Throws when trying to add liquidity to an unapproved pool
  error LiquidityPairUnapproved();

  /// @notice Throws when the job doesn't have the requested liquidity
  error JobLiquidityUnexistent();

  /// @notice Throws when trying to remove more liquidity than the job has
  error JobLiquidityInsufficient();

  /// @notice Throws when trying to add less liquidity than the minimum liquidity required
  error JobLiquidityLessThanMin();

  /// @notice Throws if a variable is assigned to the zero address
  error ZeroAddress();

  /// @notice Throws if the address claiming to be a job is not in the list of approved jobs
  error JobUnapproved();

  /// @notice Throws if the amount of funds in the job is less than the payment that must be paid to the keeper that works that job
  error InsufficientFunds();

  /// @notice Throws when the caller of the function is not the job owner
  error OnlyJobOwner();

  /// @notice Throws when the caller of the function is not the pending job owner
  error OnlyPendingJobOwner();

  /// @notice Throws when the address of the job that requests to migrate wants to migrate to its same address
  error JobMigrationImpossible();

  /// @notice Throws when the _toJob address differs from the address being tracked in the pendingJobMigrations mapping
  error JobMigrationUnavailable();

  /// @notice Throws when cooldown between migrations has not yet passed
  error JobMigrationLocked();

  /// @notice Throws when the token trying to be slashed doesn't exist
  error JobTokenUnexistent();

  /// @notice Throws when someone tries to slash more tokens than the job has
  error JobTokenInsufficient();

  /// @notice Throws when a job or keeper is already disputed
  error AlreadyDisputed();

  /// @notice Throws when a job or keeper is not disputed and someone tries to resolve the dispute
  error NotDisputed();

  // Variables

  /// @notice Address of Keep3rHelper's contract
  /// @return _keep3rHelper The address of Keep3rHelper's contract
  function keep3rHelper() external view returns (address _keep3rHelper);

  /// @notice Address of Keep3rV1's contract
  /// @return _keep3rV1 The address of Keep3rV1's contract
  function keep3rV1() external view returns (address _keep3rV1);

  /// @notice Address of Keep3rV1Proxy's contract
  /// @return _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  function keep3rV1Proxy() external view returns (address _keep3rV1Proxy);

  /// @notice Address of the KP3R-WETH pool
  /// @return _kp3rWethPool The address of KP3R-WETH pool
  function kp3rWethPool() external view returns (address _kp3rWethPool);

  /// @notice The amount of time required to pass after a keeper has bonded assets for it to be able to activate
  /// @return _days The required bondTime in days
  function bondTime() external view returns (uint256 _days);

  /// @notice The amount of time required to pass before a keeper can unbond what he has bonded
  /// @return _days The required unbondTime in days
  function unbondTime() external view returns (uint256 _days);

  /// @notice The minimum amount of liquidity required to fund a job per liquidity
  /// @return _amount The minimum amount of liquidity in KP3R
  function liquidityMinimum() external view returns (uint256 _amount);

  /// @notice The amount of time between each scheduled credits reward given to a job
  /// @return _days The reward period in days
  function rewardPeriodTime() external view returns (uint256 _days);

  /// @notice The inflation period is the denominator used to regulate the emission of KP3R
  /// @return _period The denominator used to regulate the emission of KP3R
  function inflationPeriod() external view returns (uint256 _period);

  /// @notice The fee to be sent to governance when a user adds liquidity to a job
  /// @return _amount The fee amount to be sent to governance when a user adds liquidity to a job
  function fee() external view returns (uint256 _amount);

  // solhint-disable func-name-mixedcase
  /// @notice The base that will be used to calculate the fee
  /// @return _base The base that will be used to calculate the fee
  function BASE() external view returns (uint256 _base);

  /// @notice The minimum rewardPeriodTime value to be set
  /// @return _minPeriod The minimum reward period in seconds
  function MIN_REWARD_PERIOD_TIME() external view returns (uint256 _minPeriod);

  /// @notice Maps an address to a boolean to determine whether the address is a slasher or not.
  /// @return _isSlasher Whether the address is a slasher or not
  function slashers(address _slasher) external view returns (bool _isSlasher);

  /// @notice Maps an address to a boolean to determine whether the address is a disputer or not.
  /// @return _isDisputer Whether the address is a disputer or not
  function disputers(address _disputer) external view returns (bool _isDisputer);

  /// @notice Tracks the total KP3R earnings of a keeper since it started working
  /// @return _workCompleted Total KP3R earnings of a keeper since it started working
  function workCompleted(address _keeper) external view returns (uint256 _workCompleted);

  /// @notice Tracks when a keeper was first registered
  /// @return timestamp The time at which the keeper was first registered
  function firstSeen(address _keeper) external view returns (uint256 timestamp);

  /// @notice Tracks if a keeper or job has a pending dispute
  /// @return _disputed Whether a keeper or job has a pending dispute
  function disputes(address _keeperOrJob) external view returns (bool _disputed);

  /// @notice Allows governance to create a dispute for a given keeper/job
  /// @param _jobOrKeeper The address in dispute
  function dispute(address _jobOrKeeper) external;

  /// @notice Allows governance to resolve a dispute on a keeper/job
  /// @param _jobOrKeeper The address cleared
  function resolve(address _jobOrKeeper) external;

  /// @notice Tracks how much a keeper has bonded of a certain token
  /// @return _bonds Amount of a certain token that a keeper has bonded
  function bonds(address _keeper, address _bond) external view returns (uint256 _bonds);

  /// @notice The current token credits available for a job
  /// @return _amount The amount of token credits available for a job
  function jobTokenCredits(address _job, address _token) external view returns (uint256 _amount);

  /// @notice Tracks the amount of assets deposited in pending bonds
  /// @return _pendingBonds Amount of a certain asset a keeper has unbonding
  function pendingBonds(address _keeper, address _bonding) external view returns (uint256 _pendingBonds);

  /// @notice Tracks when a bonding for a keeper can be activated
  /// @return _timestamp Time at which the bonding for a keeper can be activated
  function canActivateAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks when keeper bonds are ready to be withdrawn
  /// @return _timestamp Time at which the keeper bonds are ready to be withdrawn
  function canWithdrawAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks how much keeper bonds are to be withdrawn
  /// @return _pendingUnbonds The amount of keeper bonds that are to be withdrawn
  function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256 _pendingUnbonds);

  /// @notice Checks whether the address has ever bonded an asset
  /// @return _hasBonded Whether the address has ever bonded an asset
  function hasBonded(address _keeper) external view returns (bool _hasBonded);

  /// @notice Last block where tokens were added to the job [job => token => timestamp]
  /// @return _timestamp The last block where tokens were added to the job
  function jobTokenCreditsAddedAt(address _job, address _token) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Add credit to a job to be paid out for work
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being credited
  /// @param _amount The amount of credit being added
  function addTokenCreditsToJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Withdraw credit from a job
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The address of the token being withdrawn
  /// @param _amount The amount of token to be withdrawn
  /// @param _receiver The user that will receive tokens
  function withdrawTokenCreditsFromJob(
    address _job,
    address _token,
    uint256 _amount,
    address _receiver
  ) external;

  /// @notice Lists liquidity pairs
  /// @return _list An array of addresses with all the approved liquidity pairs
  function approvedLiquidities() external view returns (address[] memory _list);

  /// @notice Amount of liquidity in a specified job
  /// @param _job The address of the job being checked
  /// @param _liquidity The address of the liquidity we are checking
  /// @return _amount Amount of liquidity in the specified job
  function liquidityAmount(address _job, address _liquidity) external view returns (uint256 _amount);

  /// @notice Last time the job was rewarded liquidity credits
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was rewarded liquidity credits
  function rewardedAt(address _job) external view returns (uint256 _timestamp);

  /// @notice Last time the job was worked
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was worked
  function workedAt(address _job) external view returns (uint256 _timestamp);

  /// @notice Maps the job to the owner of the job (job => user)
  /// @return _owner The addres of the owner of the job
  function jobOwner(address _job) external view returns (address _owner);

  /// @notice Maps the owner of the job to its pending owner (job => user)
  /// @return _pendingOwner The address of the pending owner of the job
  function jobPendingOwner(address _job) external view returns (address _pendingOwner);

  /// @notice Maps the jobs that have requested a migration to the address they have requested to migrate to
  /// @return _toJob The address to which the job has requested to migrate to
  function pendingJobMigrations(address _fromJob) external view returns (address _toJob);

  // Methods

  /// @notice Sets the Keep3rHelper address
  /// @param _keep3rHelper The Keep3rHelper address
  function setKeep3rHelper(address _keep3rHelper) external;

  /// @notice Sets the Keep3rV1 address
  /// @param _keep3rV1 The Keep3rV1 address
  function setKeep3rV1(address _keep3rV1) external;

  /// @notice Sets the Keep3rV1Proxy address
  /// @param _keep3rV1Proxy The Keep3rV1Proxy address
  function setKeep3rV1Proxy(address _keep3rV1Proxy) external;

  /// @notice Sets the KP3R-WETH pool address
  /// @param _kp3rWethPool The KP3R-WETH pool address
  function setKp3rWethPool(address _kp3rWethPool) external;

  /// @notice Sets the bond time required to activate as a keeper
  /// @param _bond The new bond time
  function setBondTime(uint256 _bond) external;

  /// @notice Sets the unbond time required unbond what has been bonded
  /// @param _unbond The new unbond time
  function setUnbondTime(uint256 _unbond) external;

  /// @notice Sets the minimum amount of liquidity required to fund a job
  /// @param _liquidityMinimum The new minimum amount of liquidity
  function setLiquidityMinimum(uint256 _liquidityMinimum) external;

  /// @notice Sets the time required to pass between rewards for jobs
  /// @param _rewardPeriodTime The new amount of time required to pass between rewards
  function setRewardPeriodTime(uint256 _rewardPeriodTime) external;

  /// @notice Sets the new inflation period
  /// @param _inflationPeriod The new inflation period
  function setInflationPeriod(uint256 _inflationPeriod) external;

  /// @notice Sets the new fee
  /// @param _fee The new fee
  function setFee(uint256 _fee) external;

  /// @notice Registers a slasher by updating the slashers mapping
  function addSlasher(address _slasher) external;

  /// @notice Removes a slasher by updating the slashers mapping
  function removeSlasher(address _slasher) external;

  /// @notice Registers a disputer by updating the disputers mapping
  function addDisputer(address _disputer) external;

  /// @notice Removes a disputer by updating the disputers mapping
  function removeDisputer(address _disputer) external;

  /// @notice Lists all jobs
  /// @return _jobList Array with all the jobs in _jobs
  function jobs() external view returns (address[] memory _jobList);

  /// @notice Lists all keepers
  /// @return _keeperList Array with all the jobs in keepers
  function keepers() external view returns (address[] memory _keeperList);

  /// @notice Beginning of the bonding process
  /// @param _bonding The asset being bound
  /// @param _amount The amount of bonding asset being bound
  function bond(address _bonding, uint256 _amount) external;

  /// @notice Beginning of the unbonding process
  /// @param _bonding The asset being unbound
  /// @param _amount Allows for partial unbonding
  function unbond(address _bonding, uint256 _amount) external;

  /// @notice End of the bonding process after bonding time has passed
  /// @param _bonding The asset being activated as bond collateral
  function activate(address _bonding) external;

  /// @notice Withdraw funds after unbonding has finished
  /// @param _bonding The asset to withdraw from the bonding pool
  function withdraw(address _bonding) external;

  /// @notice Allows governance to slash a keeper based on a dispute
  /// @param _keeper The address being slashed
  /// @param _bonded The asset being slashed
  /// @param _amount The amount being slashed
  function slash(
    address _keeper,
    address _bonded,
    uint256 _amount
  ) external;

  /// @notice Blacklists a keeper from participating in the network
  /// @param _keeper The address being slashed
  function revoke(address _keeper) external;

  /// @notice Allows any caller to add a new job
  /// @param _job Address of the contract for which work should be performed
  function addJob(address _job) external;

  /// @notice Returns the liquidity credits of a given job
  /// @param _job The address of the job of which we want to know the liquidity credits
  /// @return _amount The liquidity credits of a given job
  function jobLiquidityCredits(address _job) external view returns (uint256 _amount);

  /// @notice Returns the credits of a given job for the current period
  /// @param _job The address of the job of which we want to know the period credits
  /// @return _amount The credits the given job has at the current period
  function jobPeriodCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates the total credits of a given job
  /// @param _job The address of the job of which we want to know the total credits
  /// @return _amount The total credits of the given job
  function totalJobCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates how many credits should be rewarded periodically for a given liquidity amount
  /// @dev _periodCredits = underlying KP3Rs for given liquidity amount * rewardPeriod / inflationPeriod
  /// @param _liquidity The liquidity to provide
  /// @param _amount The amount of liquidity to provide
  /// @return _periodCredits The amount of KP3R periodically minted for the given liquidity
  function quoteLiquidity(address _liquidity, uint256 _amount) external view returns (uint256 _periodCredits);

  /// @notice Observes the current state of the liquidity pair being observed and updates TickCache with the information
  /// @param _liquidity The liquidity pair being observed
  /// @return _tickCache The updated TickCache
  function observeLiquidity(address _liquidity) external view returns (TickCache memory _tickCache);

  /// @notice Gifts liquidity credits to the specified job
  /// @param _job The address of the job being credited
  /// @param _amount The amount of liquidity credits to gift
  function forceLiquidityCreditsToJob(address _job, uint256 _amount) external;

  /// @notice Approve a liquidity pair for being accepted in future
  /// @param _liquidity The address of the liquidity accepted
  function approveLiquidity(address _liquidity) external;

  /// @notice Revoke a liquidity pair from being accepted in future
  /// @param _liquidity The liquidity no longer accepted
  function revokeLiquidity(address _liquidity) external;

  /// @notice Allows anyone to fund a job with liquidity
  /// @param _job The address of the job to assign liquidity to
  /// @param _liquidity The liquidity being added
  /// @param _amount The amount of liquidity tokens to add
  function addLiquidityToJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Unbond liquidity for a job
  /// @dev Can only be called by the job's owner
  /// @param _job The address of the job being unbound from
  /// @param _liquidity The liquidity being unbound
  /// @param _amount The amount of liquidity being removed
  function unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Withdraw liquidity from a job
  /// @param _job The address of the job being withdrawn from
  /// @param _liquidity The liquidity being withdrawn
  /// @param _receiver The address that will receive the withdrawn liquidity
  function withdrawLiquidityFromJob(
    address _job,
    address _liquidity,
    address _receiver
  ) external;

  /// @notice Confirms if the current keeper is registered, can be used for general (non critical) functions
  /// @param _keeper The keeper being investigated
  /// @return _isKeeper Whether the address passed as a parameter is a keeper or not
  function isKeeper(address _keeper) external returns (bool _isKeeper);

  /// @notice Confirms if the current keeper is registered and has a minimum bond of any asset. Should be used for protected functions
  /// @param _keeper The keeper to check
  /// @param _bond The bond token being evaluated
  /// @param _minBond The minimum amount of bonded tokens
  /// @param _earned The minimum funds earned in the keepers lifetime
  /// @param _age The minimum keeper age required
  /// @return _isBondedKeeper Whether the `_keeper` meets the given requirements
  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool _isBondedKeeper);

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Automatically calculates the payment for the keeper
  /// @param _keeper Address of the keeper that performed the work
  function worked(address _keeper) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with KP3R
  /// @param _keeper Address of the keeper that performed the work
  /// @param _payment The reward that should be allocated for the job
  function bondedPayment(address _keeper, uint256 _payment) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with a specific token
  /// @param _token The asset being awarded to the keeper
  /// @param _keeper Address of the keeper that performed the work
  /// @param _amount The reward that should be allocated
  function directTokenPayment(
    address _token,
    address _keeper,
    uint256 _amount
  ) external;

  /// @notice Proposes a new address to be the owner of the job
  function changeJobOwnership(address _job, address _newOwner) external;

  /// @notice The proposed address accepts to be the owner of the job
  function acceptJobOwnership(address _job) external;

  /// @notice Initializes the migration process for a job by adding the request to the pendingJobMigrations mapping
  /// @param _fromJob The address of the job that is requesting to migrate
  /// @param _toJob The address at which the job is requesting to migrate
  function migrateJob(address _fromJob, address _toJob) external;

  /// @notice Completes the migration process for a job
  /// @dev Unbond/withdraw process doesn't get migrated
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address to which the job wants to migrate to
  function acceptJobMigration(address _fromJob, address _toJob) external;

  /// @notice Allows governance or slasher to slash a job specific token
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token that will be slashed
  /// @param _amount The amount of the token that will be slashed
  function slashTokenFromJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Allows governance or a slasher to slash liquidity from a job
  /// @param _job The address being slashed
  /// @param _liquidity The address of the liquidity that will be slashed
  /// @param _amount The amount of liquidity that will be slashed
  function slashLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IKeep3rJob.sol';

interface IKeep3rBondedJob is IKeep3rJob {
  // Events

  event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age);

  // Variables

  function requiredBond() external view returns (address _requiredBond);

  function requiredMinBond() external view returns (uint256 _requiredMinBond);

  function requiredEarnings() external view returns (uint256 _requiredEarnings);

  function requiredAge() external view returns (uint256 _requiredAge);

  // Methods

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IOnlyEOA {
  function onlyEOA() external returns (bool _onlyEOA);

  error OnlyEOA();

  function setOnlyEOA(bool _onlyEOA) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStealthTx {
  event StealthVaultSet(address _stealthVault);
  event PenaltySet(uint256 _penalty);
  event MigratedStealthVault(address _migratedTo);

  function stealthVault() external view returns (address);

  function penalty() external view returns (uint256);

  function setStealthVault(address _stealthVault) external;

  function setPenalty(uint256 _penalty) external;
}