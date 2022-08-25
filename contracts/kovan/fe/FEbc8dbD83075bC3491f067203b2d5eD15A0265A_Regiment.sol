import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
pragma solidity 0.8.9;

contract Regiment {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    address private controller;
    uint256 private memberJoinLimit;
    uint256 private regimentLimit;
    uint256 private maximumAdminsCount;

    uint256 public DefaultMemberJoinLimit = 256;
    uint256 public DefaultRegimentLimit = 1024;
    uint256 public DefaultMaximumAdminsCount = 3;
    uint256 public regimentCount;
    mapping(bytes32 => RegimentInfo) private regimentInfoMap;
    mapping(bytes32 => EnumerableSet.AddressSet) private regimentMemberListMap;

    event RegimentCreated(
        uint256 createTime,
        address manager,
        address[] initialMemberList,
        bytes32 regimentId
    );

    event NewMemberApplied(bytes32 regimentId, address applyMemberAddress);
    event NewMemberAdded(
        bytes32 regimentId,
        address newMemberAddress,
        address operatorAddress
    );

    event RegimentMemberLeft(
        bytes32 regimentId,
        address leftMemberAddress,
        address operatorAddress
    );

    struct RegimentInfo {
        uint256 createTime;
        address manager;
        EnumerableSet.AddressSet admins;
        bool isApproveToJoin;
    }
    struct RegimentInfoForView {
        uint256 createTime;
        address manager;
        address[] admins;
        bool isApproveToJoin;
    }
    modifier assertSenderIsController() {
        require(msg.sender == controller, 'Sender is not the Controller.');
        _;
    }

    constructor(
        uint256 _memberJoinLimit,
        uint256 _regimentLimit,
        uint256 _maximumAdminsCount
    ) {
        require(
            _memberJoinLimit <= DefaultMemberJoinLimit,
            'Invalid memberJoinLimit'
        );
        require(
            _regimentLimit <= DefaultRegimentLimit,
            'Invalid regimentLimit'
        );
        require(
            _maximumAdminsCount <= DefaultMaximumAdminsCount,
            'Invalid maximumAdminsCount'
        );
        controller = msg.sender;
        memberJoinLimit = _memberJoinLimit;
        regimentLimit = _regimentLimit;
        maximumAdminsCount = _maximumAdminsCount == 0
            ? DefaultMaximumAdminsCount
            : _maximumAdminsCount;
        require(memberJoinLimit <= regimentLimit, 'Incorrect MemberJoinLimit.');
    }

    function CreateRegiment(
        address manager,
        address[] calldata initialMemberList,
        bool isApproveToJoin
    ) external assertSenderIsController returns (bytes32) {
        bytes32 regimentId = sha256(abi.encodePacked(regimentCount, manager));
        regimentCount = regimentCount.add(1);
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        for (uint256 i; i < initialMemberList.length; i++) {
            memberList.add(initialMemberList[i]);
        }
        if (!memberList.contains(manager)) {
            memberList.add(manager);
        }
        require(
            memberList.length() <= memberJoinLimit,
            'Too many initial members.'
        );
        regimentInfoMap[regimentId].createTime = block.timestamp;
        regimentInfoMap[regimentId].manager = manager;
        regimentInfoMap[regimentId].isApproveToJoin = isApproveToJoin;
        emit RegimentCreated(
            block.timestamp,
            manager,
            initialMemberList,
            regimentId
        );
        return regimentId;
    }

    function JoinRegiment(
        bytes32 regimentId,
        address newMerberAddess,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(
            memberList.length() <= regimentLimit,
            'Regiment member reached the limit'
        );
        if (
            regimentInfo.isApproveToJoin ||
            memberList.length() >= memberJoinLimit
        ) {
            emit NewMemberApplied(regimentId, newMerberAddess);
        } else {
            memberList.add(newMerberAddess);
            emit NewMemberAdded(
                regimentId,
                newMerberAddess,
                originSenderAddress
            );
        }
    }

    function LeaveRegiment(
        bytes32 regimentId,
        address leaveMemberAddress,
        address originSenderAddress
    ) external assertSenderIsController {
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(originSenderAddress == leaveMemberAddress, 'No permission.');
        memberList.remove(leaveMemberAddress);
        emit RegimentMemberLeft(
            regimentId,
            leaveMemberAddress,
            originSenderAddress
        );
    }

    function AddRegimentMember(
        bytes32 regimentId,
        address newMerberAddess,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(
            memberList.length() <= regimentLimit,
            'Regiment member reached the limit'
        );
        require(
            regimentInfo.admins.contains(originSenderAddress) ||
                regimentInfo.manager == originSenderAddress,
            'Origin sender is not manager or admin of this regiment'
        );
        memberList.add(newMerberAddess);
        emit NewMemberAdded(regimentId, newMerberAddess, originSenderAddress);
    }

    function DeleteRegimentMember(
        bytes32 regimentId,
        address leaveMemberAddress,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(
            memberList.length() <= regimentLimit,
            'Regiment member reached the limit'
        );
        require(
            regimentInfo.admins.contains(originSenderAddress) ||
                regimentInfo.manager == originSenderAddress,
            'Origin sender is not manager or admin of this regiment'
        );
        memberList.remove(leaveMemberAddress);
        emit RegimentMemberLeft(
            regimentId,
            leaveMemberAddress,
            originSenderAddress
        );
    }

    function ChangeController(address _controller)
        external
        assertSenderIsController
    {
        controller = _controller;
    }

    function ResetConfig(
        uint256 _memberJoinLimit,
        uint256 _regimentLimit,
        uint256 _maximumAdminsCount
    ) external assertSenderIsController {
        memberJoinLimit = _memberJoinLimit == 0
            ? memberJoinLimit
            : _memberJoinLimit;
        regimentLimit = _regimentLimit == 0 ? regimentLimit : _regimentLimit;
        maximumAdminsCount = _maximumAdminsCount == 0
            ? maximumAdminsCount
            : _maximumAdminsCount;
        require(memberJoinLimit <= regimentLimit, 'Incorrect MemberJoinLimit.');
    }

    function TransferRegimentOwnership(
        bytes32 regimentId,
        address newManagerAddress,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        require(originSenderAddress == regimentInfo.manager, 'No permission.');
        regimentInfo.manager = newManagerAddress;
    }

    function AddAdmins(
        bytes32 regimentId,
        address[] calldata newAdmins,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        require(originSenderAddress == regimentInfo.manager, 'No permission.');
        for (uint256 i; i < newAdmins.length; i++) {
            require(
                !regimentInfo.admins.contains(newAdmins[i]),
                'someone is already an admin'
            );
            regimentInfo.admins.add(newAdmins[i]);
        }
        require(
            regimentInfo.admins.length() <= maximumAdminsCount,
            'Admins count cannot greater than maximumAdminsCount'
        );
    }

    function DeleteAdmins(
        bytes32 regimentId,
        address[] calldata deleteAdmins,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        require(originSenderAddress == regimentInfo.manager, 'No permission.');
        for (uint256 i; i < deleteAdmins.length; i++) {
            require(
                regimentInfo.admins.contains(deleteAdmins[i]),
                'someone is not an admin'
            );
            regimentInfo.admins.remove(deleteAdmins[i]);
        }
    }

    //view functions

    function GetController() external view returns (address) {
        return controller;
    }

    function GetConfig()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (maximumAdminsCount, memberJoinLimit, regimentLimit);
    }

    function GetRegimentInfo(bytes32 regimentId)
        external
        view
        returns (RegimentInfoForView memory)
    {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        return
            RegimentInfoForView({
                createTime: regimentInfo.createTime,
                manager: regimentInfo.manager,
                admins: regimentInfo.admins.values(),
                isApproveToJoin: regimentInfo.isApproveToJoin
            });
    }

    function IsRegimentMember(bytes32 regimentId, address memberAddress)
        external
        view
        returns (bool)
    {
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        return memberList.contains(memberAddress);
    }

    function IsRegimentAdmin(bytes32 regimentId, address adminAddress)
        external
        view
        returns (bool)
    {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        return regimentInfo.admins.contains(adminAddress);
    }

    function IsRegimentManager(bytes32 regimentId, address managerAddress)
        external
        view
        returns (bool)
    {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        return regimentInfo.manager == managerAddress;
    }

    function GetRegimentMemberList(bytes32 regimentId)
        external
        view
        returns (address[] memory)
    {
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        return memberList.values();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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