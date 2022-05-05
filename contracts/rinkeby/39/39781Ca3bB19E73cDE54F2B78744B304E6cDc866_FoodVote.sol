//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Contract for voting for the damn food
 * @author Ask Joe Mama
 */
contract FoodVote {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    error InvalidVoting();
    error VotingStillOngoing();
    error VotingIsNotOngoing();
    error OnlyMember();
    error VoterAlreadyVoted();
    error VoterNotVotedYet();
    error FoodNotFound();
    error WrongVotingCreator();
    error FinishLatestVotingFirst(uint256 latestVotingId);
    error WrongVotingTopic();

    Counters.Counter private _foodId;
    Counters.Counter private _votingId;
    EnumerableSet.AddressSet private _members;

    enum VotingTopics {
        INVALID,
        FOOD,
        ADD_MEMBER,
        KICK_MEMBER
    }

    enum VotingStatus {
        INVALID,
        ONGOING,
        FINISHED,
        CANCELED
    }

    struct Voting {
        uint128 createdAt;
        uint128 finishedAt;
        address creator;
        VotingTopics topic;
        VotingStatus status;
        EnumerableSet.AddressSet votedAddresses;
    }

    mapping(uint256 => Voting) private _votings;
    mapping(VotingTopics => uint256) _latestVotingIds;

    mapping(uint256 => string) private _foods;
    mapping(uint256 => uint256[]) private _foodVotings;

    mapping(uint256 => address) private _memberVotings;

    mapping(address => EnumerableSet.UintSet) private _memberActiveVotings;

    constructor() {
        _members.add(msg.sender);
    }

    modifier onlyValidVoting(uint256 votingId) {
        if (_votings[votingId].createdAt == 0) revert InvalidVoting();
        _;
    }

    modifier onlyOngoingVoting(uint256 votingId) {
        if (_votings[votingId].status != VotingStatus.ONGOING) revert VotingIsNotOngoing();
        _;
    }

    modifier onlyMember() {
        if (!_members.contains(msg.sender)) revert OnlyMember();
        _;
    }

    function addFood(string memory name) external onlyMember {
        uint256 currentFoodId = _foodId.current();
        _foodId.increment();

        _foods[currentFoodId] = name;
    }

    function addMemberVoting(address newMemberAddress) external onlyMember {
        _createVoting(VotingTopics.ADD_MEMBER, newMemberAddress);
    }

    function kickMemberVoting(address newMemberAddress) external onlyMember {
        _createVoting(VotingTopics.KICK_MEMBER, newMemberAddress);
    }

    function foodVoting() external onlyMember {
        _createVoting(VotingTopics.FOOD, address(0));
    }

    function vote(uint256 votingId) external onlyMember onlyValidVoting(votingId) onlyOngoingVoting(votingId) {
        Voting storage voting = _votings[votingId];
        if (voting.topic == VotingTopics.FOOD) revert WrongVotingTopic();
        if (voting.votedAddresses.contains(msg.sender)) revert VoterAlreadyVoted();

        voting.votedAddresses.add(msg.sender);
    }

    function revokeVote(uint256 votingId) external onlyValidVoting(votingId) onlyOngoingVoting(votingId) {
        Voting storage voting = _votings[votingId];
        if (voting.topic == VotingTopics.FOOD) revert WrongVotingTopic();
        if (!voting.votedAddresses.contains(msg.sender)) revert VoterNotVotedYet();

        voting.votedAddresses.remove(msg.sender);
    }

    function voteForFood(uint256 foodId) external onlyMember {
        uint256 latestVotingId = _latestVotingIds[VotingTopics.FOOD];
        Voting storage voting = _votings[latestVotingId];
        if (foodId >= _foodId.current()) revert FoodNotFound();
        if (voting.status != VotingStatus.ONGOING) revert VotingIsNotOngoing();
        if (voting.votedAddresses.contains(msg.sender)) revert VoterAlreadyVoted();

        voting.votedAddresses.add(msg.sender);
        _foodVotings[latestVotingId].push(foodId);
    }

    function finishVoting(uint256 votingId) external onlyValidVoting(votingId) onlyOngoingVoting(votingId) {
        Voting storage voting = _votings[votingId];
        if (voting.creator != msg.sender) revert WrongVotingCreator();

        voting.finishedAt = uint128(block.timestamp);
        voting.status = VotingStatus.FINISHED;

        // remove voting id from member
        _memberActiveVotings[msg.sender].remove(votingId);

        if (getVoteResult(votingId, true)) {
            if (voting.topic == VotingTopics.ADD_MEMBER) _members.add(_memberVotings[votingId]);
            if (voting.topic == VotingTopics.KICK_MEMBER) {
                _members.remove(_memberVotings[votingId]);

                for (uint256 i = 0; i < _memberActiveVotings[msg.sender].length(); i++) {
                    Voting storage votingMember = _votings[_memberActiveVotings[msg.sender].at(i)];

                    votingMember.finishedAt = uint128(block.timestamp);
                    votingMember.status = VotingStatus.CANCELED;
                }

                delete _memberActiveVotings[msg.sender];
            }
        }
    }

    function cancelVoting(uint256 votingId) external onlyValidVoting(votingId) onlyOngoingVoting(votingId) {
        Voting storage voting = _votings[votingId];
        if (voting.creator != msg.sender) revert WrongVotingCreator();

        voting.finishedAt = uint128(block.timestamp);
        voting.status = VotingStatus.CANCELED;

        // remove voting id from member
        _memberActiveVotings[msg.sender].remove(votingId);
    }

    function getAllFoods() external view returns (string[] memory foods) {
        foods = new string[](_foodId.current());

        for (uint256 i = 0; i < foods.length; i++) {
            foods[i] = string(abi.encodePacked(Strings.toString(i), "-", _foods[i]));
        }
    }

    function getLatestFoodVoteResult(bool onlyFinished) external view returns (uint256[] memory votings) {
        uint256 latestVotingId = _latestVotingIds[VotingTopics.FOOD];
        votings = getFoodVoteResult(latestVotingId, onlyFinished);
    }

    function getVoteResult(uint256 votingId, bool onlyFinished) public view returns (bool accepted) {
        Voting storage voting = _votings[votingId];
        if (onlyFinished && voting.status == VotingStatus.ONGOING) revert VotingStillOngoing();

        accepted = _votingCheck(_members.length(), voting.votedAddresses.length());
    }

    function getFoodVoteResult(uint256 votingId, bool onlyFinished) public view returns (uint256[] memory votings) {
        Voting storage voting = _votings[votingId];
        if (onlyFinished && voting.status == VotingStatus.ONGOING) revert VotingStillOngoing();

        votings = _foodVotings[votingId];
    }

    function _createVoting(VotingTopics topic, address newMemberAddress) private {
        uint256 latestVotingId = _latestVotingIds[topic];
        if (_votings[latestVotingId].status == VotingStatus.ONGOING)
            revert FinishLatestVotingFirst({ latestVotingId: latestVotingId });

        uint256 currentVotingId = _votingId.current();
        _votingId.increment();

        Voting storage voting = _votings[currentVotingId];
        voting.createdAt = uint128(block.timestamp);
        voting.creator = msg.sender;
        voting.topic = topic;
        voting.status = VotingStatus.ONGOING;

        // creator votes by default (if not food)
        if (topic != VotingTopics.FOOD) {
            voting.votedAddresses.add(msg.sender);
        }

        // add voting id to member
        _memberActiveVotings[msg.sender].add(currentVotingId);

        // latest voting id
        _latestVotingIds[topic] = currentVotingId;

        if (topic == VotingTopics.ADD_MEMBER || topic == VotingTopics.KICK_MEMBER)
            _memberVotings[currentVotingId] = newMemberAddress;
    }

    function _votingCheck(uint256 memberCount, uint256 voterCount) private pure returns (bool legit) {
        legit = (voterCount * 10e18) / memberCount > 5 * 10e17;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}