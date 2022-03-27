// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/EnumerableSet.sol";
import "../interface/IChamber.sol";
import "../interface/IOracle.sol";
import "../interface/IChamberController.sol";
import "./Controllable.sol";
import "../lib/SlotsLib.sol";

contract ChamberController is Controllable, IChamberController {
  using SlotsLib for bytes32;
  using EnumerableSet for EnumerableSet.AddressSet;

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";

  // ---- VARIABLES ----

  mapping(address => bool) public override validChambers;
  mapping(uint => mapping(uint => EnumerableSet.AddressSet)) internal _chambersByTypeAndLevel;

  // ---- EVENTS ----

  event ChamberRegistered(address chamber);
  event ChamberRemoved(address chamber);

  // ---- INITIALIZER ----

  function init(
    address controller_
  ) external initializer {
    __Controllable_init(controller_);
  }

  // ---- RESTRICTIONS ----

  function onlyGovernance() internal view {
    require(_isGovernance(msg.sender), "Not gov");
  }

  // ---- VIEWS ----

  function chambersByTypeAndLevel(uint cType, uint level, uint index) external override view returns (address) {
    return _chambersByTypeAndLevel[cType][level].at(index);
  }

  function chambersByTypeAndLevelLength(uint cType, uint level) external view override returns (uint) {
    return _chambersByTypeAndLevel[cType][level].length();
  }

  function _oracle() internal view returns (IOracle) {
    return IOracle(IController(_controller()).oracle());
  }

  // ---- REGISTER ACTIONS ----

  function registerChambers(address[] calldata chambers_) external {
    onlyGovernance();
    for (uint i; i < chambers_.length; i++) {
      IChamber c = IChamber(chambers_[i]);
      require(!validChambers[address(c)], "Already registered");
      bool valid = false;
      try c.isChamber() returns (bool) {
        valid = true;
      } catch {}
      require(valid, "Not chamber");
      validChambers[address(c)] = true;
      require(
        _chambersByTypeAndLevel[c.chamberType()][c.chamberLevel()].add(address(c)),
        "Already registered in set");
      emit ChamberRegistered(chambers_[i]);
    }
  }

  function removeChambers(address[] calldata chambers_) external {
    onlyGovernance();
    for (uint i; i < chambers_.length; i++) {
      IChamber c = IChamber(chambers_[i]);
      require(validChambers[address(c)], "Not registered");
      delete validChambers[address(c)];
      require(_chambersByTypeAndLevel[c.chamberType()][c.chamberLevel()].remove(address(c)), "Not registered in set");
      emit ChamberRemoved(chambers_[i]);
    }
  }

  // ---- ACTIONS ----

  /// @dev Chances in range 0-100e18
  function getRandomChamber(uint[] memory cTypes, uint[] memory chances, uint dungeonLevel) external override returns (address) {
    uint cTypesLength = cTypes.length;
    require(cTypesLength != 0 && cTypesLength == chances.length, "Wrong input");
    uint cType;
    if (cTypesLength > 1) {
      uint random = _oracle().getRandomNumber(100e18);
      uint minChance = 101e18;
      for (uint i; i < cTypesLength;) {
        if ((100e18 - chances[i]) <= random) {
          if (chances[i] < minChance) {
            // chamber set can contain empty chambers, ignore them
            if (cTypes[i] == 0) {
            unchecked{++i;}
              continue;
            }
            minChance = chances[i];
            cType = cTypes[i];
          }
        }
      unchecked{++i;}
      }
    } else {
      cType = cTypes[0];
    }
    require(cType != 0, "Unknown chamber type");
    EnumerableSet.AddressSet storage c = _chambersByTypeAndLevel[cType][dungeonLevel];
    uint cLength = c.length();
    require(cLength != 0, "Empty chambers");
    if(cLength == 1) {
      return c.at(0);
    }
    return c.at(_oracle().getRandomNumber(cLength - 1));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

pragma solidity 0.8.4;

import "./IFightCalculator.sol";

interface IChamber {

  struct ChamberResult {
    address chamber;
    address heroToken;
    uint heroTokenId;
    bool kill;
    uint experience;
    uint heal;
    uint manaRegen;
    uint damage;
    uint manaConsumed;
    address[] mintItems;
    uint[] attackerDmgHistory;
    uint[] defenderDmgHistory;
    IFightCalculator.FighterInfo heroInfo;
    IFightCalculator.FighterInfo monsterInfo;
  }

  function isChamber() external pure returns (bool);

  function chamberName() external view returns (string memory);

  function URI() external view returns (string memory);

  function chamberType() external view returns (uint);

  function chamberLevel() external view returns (uint);

  function open(address heroToken, uint heroTokenId, bytes calldata data) external returns (ChamberResult memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IOracle {

  function getRandomNumber(uint max) external returns (uint);

  function getRandomNumberInRange(uint min, uint max) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IChamberController {

  enum ChamberType {
    UNKNOWN, // 0
    ENEMY_NPC, // 1
    ENEMY_NPC_RARE, // 2
    BOSS, // 3
    SHRINE, // 4
    CHEST, // 5
    SLOT_6,
    SLOT_7,
    SLOT_8,
    SLOT_9,
    SLOT_10,
    SLOT_11,
    SLOT_12,
    SLOT_13,
    SLOT_14,
    SLOT_15,
    SLOT_16,
    SLOT_17,
    SLOT_18,
    SLOT_19,
    SLOT_20,
    SLOT_21,
    SLOT_22,
    SLOT_23,
    SLOT_24,
    SLOT_25,
    SLOT_26,
    SLOT_27,
    SLOT_28,
    SLOT_29,
    SLOT_30
  }

  function validChambers(address chamber) external view returns (bool);

  function chambersByTypeAndLevel(uint cType, uint level, uint index) external view returns (address);

  function chambersByTypeAndLevelLength(uint cType, uint level) external view returns (uint);

  function getRandomChamber(uint[] memory cTypes, uint[] memory chances, uint dungeonLevel) external returns (address);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IController.sol";
import "../lib/SlotsLib.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "1.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) public onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IStatController.sol";

interface IFightCalculator {

  enum AttackType {
    UNKNOWN, // 0
    MELEE, // 1
    MAGIC, // 2
    SLOT_3,
    SLOT_4,
    SLOT_5,
    SLOT_6,
    SLOT_7,
    SLOT_8,
    SLOT_9,
    SLOT_10
  }

  struct AttackInfo {
    AttackType attackType;
    address attackToken;
    uint attackTokenId;
    address[] skillTokens;
    uint[] skillTokenIds;
  }

  struct FighterInfo {
    IStatController.Attributes fighterAttributes;
    IStatController.ChangeableStats fighterStats;
    AttackType attackType;
    address attackToken;
    uint attackTokenId;
  }

  struct FightResult {
    uint attackerHealth;
    uint defenderHealth;
    uint attackerManaConsumed;
    uint defenderManaConsumed;
    uint[] attackerDmgHistory;
    uint[] defenderDmgHistory;
  }

  function fight(
    FighterInfo memory attackerInfo,
    FighterInfo memory defenderInfo
  ) external returns (FightResult memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IStatController {

  struct Attributes {
    // core
    uint strength;
    uint dexterity;
    uint vitality;
    uint energy;
    // attributes
    uint damageMin;
    uint damageMax;
    uint attackRating;
    uint defense;
    uint blockRating;
    uint life;
    uint mana;
    // resistance
    uint fireResistance;
    uint coldResistance;
    uint lightningResistance;
  }

  struct CoreAttributes {
    uint strength;
    uint dexterity;
    uint vitality;
    uint energy;
  }

  struct ChangeableStats {
    uint level;
    uint experience;
    uint life;
    uint mana;
  }

  enum MagicAttackType {
    UNKNOWN, // 0
    FIRE, // 1
    COLD, // 2
    LIGHTNING, // 3
    CHAOS // 4
  }

  struct MagicAttack {
    MagicAttackType aType;
    uint min;
    uint max;
    CoreAttributes attribute;
    uint attributeFactor;
    uint manaConsume;
  }

  enum ItemSlots {
    UNKNOWN, // 0
    HEAD, // 1
    BODY, // 2
    GLOVES, // 3
    BELT, // 4
    AMULET, // 5
    BOOTS, // 6
    RIGHT_RING, // 7
    LEFT_RING, // 8
    RIGHT_HAND, // 9
    LEFT_HAND, // 10
    TWO_HAND, // 11
    SKILL_1, // 12
    SKILL_2, // 13
    SKILL_3, // 14
    SLOT_15, // 15
    SLOT_16, // 16
    SLOT_17, // 17
    SLOT_18, // 18
    SLOT_19, // 19
    SLOT_20, // 20
    SLOT_21, // 21
    SLOT_22, // 22
    SLOT_23, // 23
    SLOT_24, // 24
    SLOT_25, // 25
    SLOT_26, // 26
    SLOT_27, // 27
    SLOT_28, // 28
    SLOT_29, // 29
    SLOT_30 // 30
  }

  struct NftItem {
    address token;
    uint tokenId;
  }

  function initNewHero(address token, uint tokenId, uint heroClass) external;

  function heroAttributes(address token, uint tokenId) external view returns (Attributes memory);

  function heroStats(address token, uint tokenId) external view returns (ChangeableStats memory);

  function heroItemSlot(address token, uint tokenId, uint itemSlot) external view returns (NftItem memory);

  function isHeroAlive(address heroToken, uint heroTokenId) external view returns (bool);

  function levelUp(address token, uint tokenId, uint heroClass, CoreAttributes calldata change) external;

  function changeHeroItemSlot(
    address heroToken,
    uint heroTokenId,
    uint itemType,
    uint itemSlot,
    address itemToken,
    uint itemTokenId,
    bool equip
  ) external;

  function changeCurrentStats(
    address token,
    uint tokenId,
    ChangeableStats calldata change,
    bool increase
  ) external;

  function changeTemporallyAttributes(
    address heroToken,
    uint heroTokenId,
    Attributes calldata changeAttributes,
    bool increase
  ) external;

  function clearTemporallyAttributes(address heroToken, uint heroTokenId) external;

  function addBonusAttributes(
    address token,
    uint tokenId,
    Attributes calldata bonus
  ) external;

  function removeBonusAttributes(
    address token,
    uint tokenId,
    Attributes calldata bonus
  ) external;

  function buffHero(
    address heroToken,
    uint heroTokenId,
    uint heroLevel,
    address[] memory skillTokens,
    uint[] memory skillTokenIds
  ) external view returns (Attributes memory attributes, uint manaConsumed);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
    // contract may have been reentered.
    require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} modifier, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  function _isConstructor() private view returns (bool) {
    return !Address.isContract(address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  function governance() external view returns (address);

  function statController() external view returns (address);

  function chamberController() external view returns (address);

  function oracle() external view returns (address);

  function treasury() external view returns (address);

  function fightCalculator() external view returns (address);

  function dungeonFactory() external view returns (address);

  function fightDelay() external view returns (uint);

  function dungeonMultiplierByLevel(uint level) external view returns (uint);

  function validHeroes(address hero) external view returns (bool);

  function validDungeons(address dungeon) external view returns (bool);

  function validItems(address item) external view returns (bool);

  function heroes(uint id) external view returns (address);

  function dungeons(uint id) external view returns (address);

  function items(uint id) external view returns (address);

  function heroesLength() external view returns (uint);

  function dungeonsLength() external view returns (uint);

  function itemsLength() external view returns (uint);

  function dungeonImplementationsByLevel(uint level, uint index) external view returns (address);

  function dungeonImplementationsLength(uint level) external view returns (uint);

  function registerDungeon(address dungeon_) external;

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