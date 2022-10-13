// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import './interfaces/IGaugeController.sol';
import '../token/interfaces/IVotingEscrow.sol';
import './ControllerStorage.sol';
import '../access/SafeOwnableUpgradeable.sol';

contract GaugeControllerUpgradeable is
  ControllerStorage,
  IGaugeController,
  UUPSUpgradeable,
  SafeOwnableUpgradeable,
  PausableUpgradeable
{
  using Math for uint256;
  // 7 * 86400 seconds - all future times are rounded by week
  uint256 public constant WEEK = 604800;
  uint256 public constant MULTIPLIER = 10**18;

  // Cannot change weight votes more often than once in 10 days
  uint256 public constant WEIGHT_VOTE_DELAY = 10 * 86400;

  /**
   * @notice set new votingEscrow
   * @param newVotingEscrow address of votingEscrow
   */
  function setVotingEscrow(IVotingEscrow newVotingEscrow) external virtual override onlyOwner {
    IVotingEscrow oldVotingEscrow = votingEscrow;
    require(address(newVotingEscrow) != address(0), 'GC: ve can not 0');
    votingEscrow = newVotingEscrow;
    emit SetVotingEscrow(oldVotingEscrow, newVotingEscrow);
  }

  /**
   * @notice set new p12CoinFactory
   * @param newP12Factory address of newP12Factory
   */
  function setP12CoinFactory(address newP12Factory) external virtual override onlyOwner {
    address oldP12Factory = p12CoinFactory;
    require(newP12Factory != address(0), 'GC: ve can not 0');
    p12CoinFactory = newP12Factory;
    emit SetP12Factory(oldP12Factory, newP12Factory);
  }

  /**
   * @notice Get gauge type for address
   * @param addr Gauge address
   * @return Gauge type id
   */
  function getGaugeTypes(address addr) external view virtual override returns (int128) {
    int128 gaugeType = gaugeTypes[addr];
    require(gaugeType != 0, 'GC: wrong gauge type');
    return gaugeType - 1;
  }

  /**
   * @notice Add gauge `addr` of type `gaugeType` with weight `weight`
   * @param addr Gauge address
   * @param gaugeType Gauge type
   * @param weight Gauge weight
   */
  function addGauge(
    address addr,
    int128 gaugeType,
    uint256 weight
  ) external virtual override {
    require(msg.sender == owner() || msg.sender == address(p12CoinFactory), 'GC: only admin or p12CoinFactory');
    require(gaugeType >= 0 && gaugeType < nGaugeTypes, 'GC: gaugeType error');
    require(gaugeTypes[addr] == 0, 'GC: duplicated gauge type'); //dev: cannot add the same gauge twice

    int128 n = nGauges;
    nGauges = n + 1;
    gauges[n] = addr;

    gaugeTypes[addr] = gaugeType + 1;
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    if (weight > 0) {
      uint256 typeWeight = _getTypeWeight(gaugeType);
      uint256 oldSum = _getSum(gaugeType);
      uint256 oldTotal = _getTotal();

      pointsSum[gaugeType][nextTime].bias = weight + oldSum;
      timeSum[gaugeType] = nextTime;
      pointsTotal[nextTime] = oldTotal + typeWeight * weight;
      timeTotal = nextTime;

      pointsWeight[addr][nextTime].bias = weight;
    }

    if (timeSum[gaugeType] == 0) {
      timeSum[gaugeType] = nextTime;
    }
    timeWeight[addr] = nextTime;

    emit NewGauge(addr, gaugeType, weight);
  }

  /**
   * @notice Checkpoint to fill data common for all gauges
   */
  function checkpoint() external virtual override {
    _getTotal();
  }

  /**
   * @notice Checkpoint to fill data for both a specific gauge and common for all gauges
   * @param addr Gauge address
   */
  function checkpointGauge(address addr) external virtual override {
    _getWeight(addr);
    _getTotal();
  }

  /**
   * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
   *        (e.g. 1.0 == 1e18). Inflation which will be received by it is
   *        inflation_rate * relative_weight / 1e18
   * @param addr Gauge address
   * @param time Relative weight at the specified timestamp in the past or present
   * @return Value of relative weight normalized to 1e18
   */
  function gaugeRelativeWeight(address addr, uint256 time) external view virtual override returns (uint256) {
    return _gaugeRelativeWeight(addr, time);
  }

  /**
   * @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
   *     values for type and gauge records
   * @dev Any address can call, however nothing is recorded if the values are filled already
   * @param addr Gauge address
   * @param time Relative weight at the specified timestamp in the past or present
   * @return Value of relative weight normalized to 1e18
   */
  function gaugeRelativeWeightWrite(address addr, uint256 time) external virtual override returns (uint256) {
    _getWeight(addr);
    _getTotal(); // Also calculates get_sum
    return _gaugeRelativeWeight(addr, time);
  }

  /**
   * @notice Add gauge type with name `name` and weight `weight`
   * @param name Name of gauge type
   * @param weight Weight of gauge type
   */
  function addType(string memory name, uint256 weight) external virtual override onlyOwner {
    int128 typeId = nGaugeTypes;
    gaugeTypeNames[typeId] = name;
    nGaugeTypes = typeId + 1;
    if (weight != 0) {
      _changeTypeWeight(typeId, weight);
      emit AddType(name, typeId);
    }
  }

  /**
   * @notice Change gauge type `typeId` weight to `weight`
   * @param typeId Gauge type id
   * @param weight New Gauge weight
   */
  function changeTypeWeight(int128 typeId, uint256 weight) external virtual override onlyOwner {
    _changeTypeWeight(typeId, weight);
  }

  /**
   * @notice Change weight of gauge `addr` to `weight`
   * @param addr `GaugeController` contract address
   * @param weight New Gauge weight
   */
  function changeGaugeWeight(address addr, uint256 weight) external virtual override onlyOwner {
    _changeGaugeWeight(addr, weight);
  }

  /**
   * @notice Allocate voting power for changing pool weights
   * @param gaugeAddr Gauge which `msg.sender` votes for
   * @param userWeight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
   */
  function voteForGaugeWeights(address gaugeAddr, uint256 userWeight) external virtual override whenNotPaused {
    uint256 slope = uint256(votingEscrow.getLastUserSlope(msg.sender));
    uint256 lockEnd = votingEscrow.lockedEnd(msg.sender);
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    require(lockEnd > nextTime, 'GC: no valid ve');
    require(userWeight <= 10000, 'GC: no enough voting power');
    require(block.timestamp >= lastUserVote[msg.sender][gaugeAddr] + WEIGHT_VOTE_DELAY, 'GC: Cannot vote so often');

    TmpBias memory tmp1;
    int128 gaugeType = gaugeTypes[gaugeAddr] - 1;
    require(gaugeType >= 0, 'GC: Gauge not added');
    // Prepare slopes and biases in memory
    VotedSlope memory oldSlope = voteUserSlopes[msg.sender][gaugeAddr];
    uint256 oldDt = 0;
    if (oldSlope.end > nextTime) {
      oldDt = oldSlope.end - nextTime;
    }
    tmp1.oldBias = oldSlope.slope * oldDt;
    VotedSlope memory newSlope = VotedSlope({ slope: (slope * userWeight) / 10000, end: lockEnd, power: userWeight });
    uint256 newDt = lockEnd - nextTime; // dev: raises when expired
    tmp1.newBias = newSlope.slope * newDt;

    // Check and update powers (weights) used
    voteUserPower[msg.sender] = voteUserPower[msg.sender] + newSlope.power - oldSlope.power;
    require(voteUserPower[msg.sender] <= 10000, 'GC: Used too much power');

    // Remove old and schedule new slope changes
    // Remove slope changes for old slopes
    // Schedule recording of initial slope for nextTime

    {
      TmpBiasAndSlope memory tmp2;
      tmp2.oldWeightBias = _getWeight(gaugeAddr);
      tmp2.oldWeightSlope = pointsWeight[gaugeAddr][nextTime].slope;
      tmp2.oldSumBias = _getSum(gaugeType);
      tmp2.oldSumSlope = pointsSum[gaugeType][nextTime].slope;

      pointsWeight[gaugeAddr][nextTime].bias = Math.max(tmp2.oldWeightBias + tmp1.newBias, tmp1.oldBias) - tmp1.oldBias;
      pointsSum[gaugeType][nextTime].bias = Math.max(tmp2.oldSumBias + tmp1.newBias, tmp1.oldBias) - tmp1.oldBias;
      if (oldSlope.end > nextTime) {
        pointsWeight[gaugeAddr][nextTime].slope =
          Math.max(tmp2.oldWeightSlope + newSlope.slope, oldSlope.slope) -
          oldSlope.slope;
        pointsSum[gaugeType][nextTime].slope = Math.max(tmp2.oldSumSlope + newSlope.slope, oldSlope.slope) - oldSlope.slope;
      } else {
        pointsWeight[gaugeAddr][nextTime].slope += newSlope.slope;
        pointsSum[gaugeType][nextTime].slope += newSlope.slope;
      }
    }

    if (oldSlope.end > block.timestamp) {
      // Cancel old slope changes if they still didn't happen
      changesWeight[gaugeAddr][oldSlope.end] -= oldSlope.slope;
      changesSum[gaugeType][oldSlope.end] -= oldSlope.slope;
    }

    // Add slope changes for new slopes

    changesWeight[gaugeAddr][newSlope.end] += newSlope.slope;
    changesSum[gaugeType][newSlope.end] += newSlope.slope;

    _getTotal();

    voteUserSlopes[msg.sender][gaugeAddr] = newSlope;

    // Record last action time
    lastUserVote[msg.sender][gaugeAddr] = block.timestamp;
    emit VoteForGauge(block.timestamp, msg.sender, gaugeAddr, userWeight);
  }

  /**
   * @notice Get current gauge weight
   * @param addr Gauge address
   * @return Gauge weight
   */
  function getGaugeWeight(address addr) external view virtual override returns (uint256) {
    return pointsWeight[addr][timeWeight[addr]].bias;
  }

  /**
   * @notice Get current type weight
   * @param typeId Type id
   * @return Type weight
   */
  function getTypeWeight(int128 typeId) external view virtual override returns (uint256) {
    return pointsTypeWeight[typeId][timeTypeWeight[typeId]];
  }

  /**
   * @notice Get current total (type-weighted) weight
   * @return Total weight
   */
  function getTotalWeight() external view virtual override returns (uint256) {
    return pointsTotal[timeTotal];
  }

  /**
   * @notice Get sum of gauge weights per type
   * @param typeId Type id
   * @return Sum of gauge weights
   */
  function getWeightsSumPerType(int128 typeId) external view virtual override returns (uint256) {
    return pointsSum[typeId][timeSum[typeId]].bias;
  }

  //-----------public----------

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function initialize(address votingEscrow_, address p12CoinFactory_) public initializer {
    require(votingEscrow_ != address(0) && p12CoinFactory_ != address(0), 'GC: address can not 0');
    votingEscrow = IVotingEscrow(votingEscrow_);
    p12CoinFactory = p12CoinFactory_;

    __Pausable_init_unchained();
    __Ownable_init_unchained();
  }

  //-----------internal----------
  /** upgrade function */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  /**
   * @notice Fill historic type weights week-over-week for missed checkins
   *     and return the type weight for the future week
   * @param gaugeType Gauge type id
   * @return Type weight
   */
  function _getTypeWeight(int128 gaugeType) internal virtual returns (uint256) {
    uint256 t = timeTypeWeight[gaugeType];
    if (t > 0) {
      uint256 w = pointsTypeWeight[gaugeType][t];
      for (uint256 i = 0; i < 500; i++) {
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        pointsTypeWeight[gaugeType][t] = w;
        if (t > block.timestamp) {
          timeTypeWeight[gaugeType] = t;
        }
      }
      return w;
    } else {
      return 0;
    }
  }

  /**
   * @notice Fill sum of gauge weights for the same type week-over-week for
   *     missed checkins and return the sum for the future week
   * @param gaugeType Gauge type id
   * @return Sum of weights
   */
  function _getSum(int128 gaugeType) internal virtual returns (uint256) {
    uint256 t = timeSum[gaugeType];
    if (t > 0) {
      Point memory pt = pointsSum[gaugeType][t];
      for (uint256 i = 0; i < 500; i++) {
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        uint256 dBias = pt.slope * WEEK;
        if (pt.bias > dBias) {
          pt.bias -= dBias;
          uint256 dSlope = changesSum[gaugeType][t];
          pt.slope -= dSlope;
        } else {
          pt.bias = 0;
          pt.slope = 0;
        }
        pointsSum[gaugeType][t] = pt;
        if (t > block.timestamp) {
          timeSum[gaugeType] = t;
        }
      }
      return pt.bias;
    } else {
      return 0;
    }
  }

  /**
   * @notice Fill historic total weights week-over-week for missed checkins
   *  and return the total for the future week
   * @return Total weight
   */
  function _getTotal() internal virtual returns (uint256) {
    uint256 t = timeTotal;
    int128 _nGaugeTypes = nGaugeTypes;
    if (t > block.timestamp) {
      // If we have already checkpointed - still need to change the value
      t -= WEEK;
    }

    uint256 pt = pointsTotal[t];
    for (int128 gaugeType = 0; gaugeType < 100; gaugeType++) {
      if (gaugeType == _nGaugeTypes) {
        break;
      }
      _getSum(gaugeType);
      _getTypeWeight(gaugeType);
    }

    for (uint256 i = 0; i < 500; i++) {
      if (t > block.timestamp) {
        break;
      }

      t += WEEK;
      pt = 0;
      // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
      for (int128 gaugeType = 0; gaugeType < 100; gaugeType++) {
        if (gaugeType == nGaugeTypes) {
          break;
        }
        uint256 typeSum = pointsSum[gaugeType][t].bias;
        uint256 typeWeight = pointsTypeWeight[gaugeType][t];
        pt += typeSum * typeWeight;
      }
      pointsTotal[t] = pt;

      if (t > block.timestamp) {
        timeTotal = t;
      }
    }
    return pt;
  }

  /**
   * @notice Fill historic gauge weights week-over-week for missed checkins
   *     and return the total for the future week
   * @param gaugeAddr Address of the gauge
   * @return Gauge weight
   */
  function _getWeight(address gaugeAddr) internal virtual returns (uint256) {
    uint256 t = timeWeight[gaugeAddr];
    if (t > 0) {
      Point memory pt = pointsWeight[gaugeAddr][t];
      for (uint256 i = 0; i < 500; i++) {
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        uint256 dBias = pt.slope * WEEK;
        if (pt.bias > dBias) {
          pt.bias -= dBias;
          uint256 dSlope = changesWeight[gaugeAddr][t];
          pt.slope -= dSlope;
        } else {
          pt.bias = 0;
          pt.slope = 0;
        }
        pointsWeight[gaugeAddr][t] = pt;
        if (t > block.timestamp) {
          timeWeight[gaugeAddr] = t;
        }
      }
      return pt.bias;
    } else {
      return 0;
    }
  }

  /**
   * @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
   *         (e.g. 1.0 == 1e18). Inflation which will be received by it is
   *         inflation_rate * relative_weight / 1e18
   * @param addr Gauge address
   * @param time Relative weight at the specified timestamp in the past or present
   * @return Value of relative weight normalized to 1e18
   */
  function _gaugeRelativeWeight(address addr, uint256 time) internal view virtual returns (uint256) {
    uint256 t = (time / WEEK) * WEEK;

    uint256 totalWeight = pointsTotal[t];

    if (totalWeight > 0) {
      int128 gaugeType = gaugeTypes[addr] - 1;
      uint256 typeWeight = pointsTypeWeight[gaugeType][t];
      uint256 gaugeWeight = pointsWeight[addr][t].bias;
      return (MULTIPLIER * typeWeight * gaugeWeight) / totalWeight;
    } else {
      return 0;
    }
  }

  function _changeTypeWeight(int128 typeId, uint256 weight) internal virtual {
    uint256 oldWeight = _getTypeWeight(typeId);
    uint256 oldSum = _getSum(typeId);
    uint256 totalWeight = _getTotal();
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    totalWeight = totalWeight + oldSum * weight - oldSum * oldWeight;
    pointsTotal[nextTime] = totalWeight;
    pointsTypeWeight[typeId][nextTime] = weight;
    timeTotal = nextTime;
    timeTypeWeight[typeId] = nextTime;

    emit NewTypeWeight(typeId, nextTime, weight, totalWeight);
  }

  function _changeGaugeWeight(address addr, uint256 weight) internal virtual {
    // Change gauge weight
    // Only needed when testing in reality
    int128 gaugeType = gaugeTypes[addr] - 1;
    uint256 oldGaugeWeight = _getWeight(addr);
    uint256 typeWeight = _getTypeWeight(gaugeType);
    uint256 oldSum = _getSum(gaugeType);
    uint256 totalWeight = _getTotal();
    uint256 nextTime = ((block.timestamp + WEEK) / WEEK) * WEEK;

    pointsWeight[addr][nextTime].bias = weight;
    timeWeight[addr] = nextTime;

    uint256 newSum = oldSum + weight - oldGaugeWeight;
    pointsSum[gaugeType][nextTime].bias = newSum;
    timeSum[gaugeType] = nextTime;

    totalWeight = totalWeight + newSum * typeWeight - oldSum * typeWeight;
    pointsTotal[nextTime] = totalWeight;
    timeTotal = nextTime;

    emit NewGaugeWeight(addr, block.timestamp, weight, totalWeight);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library Math {
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '../../token/interfaces/IVotingEscrow.sol';

interface IGaugeController {
  event CommitOwnership(address admin);

  event ApplyOwnership(address admin);

  event AddType(string name, int128 typeId);

  event NewTypeWeight(int128 typeId, uint256 time, uint256 weight, uint256 totalWeight);

  event NewGaugeWeight(address gaugeAddress, uint256 time, uint256 weight, uint256 totalWeight);

  event VoteForGauge(uint256 time, address user, address gaugeAddress, uint256 weight);

  event NewGauge(address addr, int128 gaugeType, uint256 weight);

  event SetVotingEscrow(IVotingEscrow oldVotingEscrow, IVotingEscrow newVotingEscrow);

  event SetP12Factory(address oldP12Factory, address newP12Factory);

  function getGaugeTypes(address addr) external returns (int128);

  function checkpoint() external;

  function gaugeRelativeWeightWrite(address addr, uint256 time) external returns (uint256);

  function changeTypeWeight(int128 typeId, uint256 weight) external;

  function changeGaugeWeight(address addr, uint256 weight) external;

  function voteForGaugeWeights(address gaugeAddr, uint256 userWeight) external;

  function checkpointGauge(address addr) external;

  function gaugeRelativeWeight(address lpToken, uint256 time) external returns (uint256);

  function getGaugeWeight(address addr) external returns (uint256);

  function getTypeWeight(int128 typeId) external returns (uint256);

  function getTotalWeight() external returns (uint256);

  function getWeightsSumPerType(int128 typeId) external returns (uint256);

  function addGauge(
    address addr,
    int128 gaugeType,
    uint256 weight
  ) external;

  function addType(string memory name, uint256 weight) external;

  function setVotingEscrow(IVotingEscrow newVotingEscrow) external;

  function setP12CoinFactory(address newP12Factory) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

interface IVotingEscrow {
  function getLastUserSlope(address addr) external returns (int256);

  function lockedEnd(address addr) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '../token/interfaces/IVotingEscrow.sol';

contract ControllerStorage {
  IVotingEscrow public votingEscrow; // Voting escrow
  address public p12CoinFactory;
  // Gauge parameters
  // All numbers are "fixed point" on the basis of 1e18
  int128 public nGaugeTypes;
  int128 public nGauges;
  uint256 public timeTotal; // last scheduled time

  uint256[45] private __gap;

  mapping(int128 => string) public gaugeTypeNames;
  // Needed for enumeration
  mapping(int128 => address) public gauges;

  // we increment values by 1 prior to storing them here so we can rely on a value
  // of zero as meaning the gauge has not been set
  mapping(address => int128) public gaugeTypes;

  mapping(address => mapping(address => VotedSlope)) public voteUserSlopes; // user -> gauge_addr -> VotedSlope
  mapping(address => uint256) public voteUserPower; // Total vote power used by user
  mapping(address => mapping(address => uint256)) public lastUserVote; // Last user vote's timestamp for each gauge address

  // Past and scheduled points for gauge weight, sum of weights per type, total weight
  // Point is for bias+slope
  // changes_* are for changes in slope
  // time_* are for the last change timestamp
  // timestamps are rounded to whole weeks

  mapping(address => mapping(uint256 => Point)) public pointsWeight; // gauge_addr -> time -> Point
  mapping(address => mapping(uint256 => uint256)) internal changesWeight; // gauge_addr -> time -> slope
  mapping(address => uint256) public timeWeight; // gauge_addr -> last scheduled time (next week)

  mapping(int128 => mapping(uint256 => Point)) public pointsSum; // type_id -> time -> Point
  mapping(int128 => mapping(uint256 => uint256)) internal changesSum; // type_id -> time -> slope
  mapping(int128 => uint256) public timeSum; // type_id -> last scheduled time (next week)

  mapping(uint256 => uint256) public pointsTotal; // time -> total weight

  mapping(int128 => mapping(uint256 => uint256)) public pointsTypeWeight; // type_id -> time -> type weight
  mapping(int128 => uint256) public timeTypeWeight; // type_id -> last scheduled time (next week)

  struct Point {
    uint256 bias;
    uint256 slope;
  }

  struct VotedSlope {
    uint256 slope;
    uint256 power;
    uint256 end;
  }

  struct TmpBiasAndSlope {
    uint256 oldWeightBias;
    uint256 oldWeightSlope;
    uint256 oldSumBias;
    uint256 oldSumSlope;
  }

  struct TmpBias {
    uint256 oldBias;
    uint256 newBias;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// Refer to https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol and https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/OwnableUpgradeable.sol

pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol';

contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable, ERC1967UpgradeUpgradeable {
  address private _owner;
  address private _pendingOwner;

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
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Return the address of the pending owner
   */
  function pendingOwner() public view virtual returns (address) {
    return _pendingOwner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), 'SafeOwnable: caller not owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   * Note If direct is false, it will set an pending owner and the OwnerShipTransferring
   * only happens when the pending owner claim the ownership
   */
  function transferOwnership(address newOwner, bool direct) public virtual onlyOwner {
    require(newOwner != address(0), 'SafeOwnable: new owner is 0');
    if (direct) {
      _transferOwnership(newOwner);
    } else {
      _transferPendingOwnership(newOwner);
    }
  }

  /**
   * @dev pending owner call this function to claim ownership
   */
  function claimOwnership() public {
    require(msg.sender == _pendingOwner, 'SafeOwnable: caller != pending');

    _claimOwnership();
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    // compatible with hardhat-deploy, maybe removed later
    assembly {
      sstore(_ADMIN_SLOT, newOwner)
    }

    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev set the pending owner address
   * Internal function without access restriction.
   */
  function _transferPendingOwnership(address newOwner) internal virtual {
    _pendingOwner = newOwner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _claimOwnership() internal virtual {
    address oldOwner = _owner;
    emit OwnershipTransferred(oldOwner, _pendingOwner);

    _owner = _pendingOwner;
    _pendingOwner = address(0);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}