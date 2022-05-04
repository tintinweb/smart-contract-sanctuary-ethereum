/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-04-29
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.0;

interface ITech {
    event OnSuspectVote(address indexed voter, address indexed token, uint256 indexed voteTokenId, uint256 suspectTokenId);
    event OnSuspectVoteBatch(address indexed voter, address indexed token, uint256[] indexed voteTokenIds, uint256 suspectTokenId);
    event OnSuspectVoteRecall(address indexed recaller, address indexed token, uint256 indexed voteTokenId, uint256 suspectTokenId);
    event OnAddNftToPreList(address indexed caller, address indexed token, uint256 indexed suspectTokenId);

    /**
     * @dev Returns the poll of a suspect NFT by 'token' and 'suspectTokenId'.
     */
    function suspectPoll(address token, uint256 suspectTokenId) external view returns (uint256 poll);

    /**
     * @dev Get all of NFTs of a specific NFT contract in the pre list.
     * @param `token` NFT contract address.
     * @return Returns all of NFTs of a specific NFT contract in the pre list.
     */
    function preList(address token) external view returns (uint256[] memory);

    /**
    * @dev Get all of the contract addresses in the pre list.
    * @return Returns all of the contract addresses in the pre list.
     */
    function contrList() external view returns (address[] memory);
    /**
     * @dev Adds a suspect NFT to the pre list for being voted and emits a {OnAddNftToPreList} event.
     * @param `token` NFT contract address.
     * @param `suspectTokenId` ID of the suspect NFT.
     * @return Returns a boolean value indicating whether the operation succeeded.
     */
    function addNftToPreList(address token, uint256 suspectTokenId) external returns (bool);
    /**
     * @dev Votes to the suspect NFT and emits a {OnSuspectVote} event.
     * @param `token` NFT contract address.
     * @param `voteTokenId` ID of the NFT which will be used to vote.
     * @param `suspectTokenId` ID of the suspect NFT.
     * @return Returns a boolean value indicating whether the operation succeeded.
     */
    function suspectVote(address token, uint256 voteTokenId, uint256 suspectTokenId) external returns (bool);
    /**
     * @dev Votes to the suspect NFT and emits a {OnSuspectVoteBatch} event.
     * @param `token` NFT contract address.
     * @param `voteTokenIds` IDs of the NFTs which will be used to vote.
     * @param `suspectTokenId` ID of the suspect NFT.
     * @return Returns a boolean value indicating whether the operation succeeded.
     */
    function suspectVoteBatch(address token, uint256[] calldata voteTokenIds, uint256 suspectTokenId) external returns (bool);
    /**
     * @dev Recalls a vote to the suspect NFT and emits a {OnSuspectVoteRecall} event.
     * @param `token` NFT contract address.
     * @param `voteTokenId` ID of the NFT which was used to vote.
     * @param `suspectTokenId` ID of the suspect NFT.
     * @return Returns a boolean value indicating whether the operation succeeded.
     */
    function suspectVoteRecall(address token, uint256 voteTokenId, uint256 suspectTokenId) external returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }

    function moveTo(Counter storage counter,uint256 target) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value = target;
    }
}

library EnumAddressSet {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

    function values(AddressSet storage set) internal view returns (address[] memory) {
        uint256 len = length(set);
        address[] memory addresses = new address[](len);
        for(uint256 i = 0 ;i< len;i++){
            addresses[i] = at(set,i);
        }
        return addresses;
    }
}

library EnumerableSet {
    struct Set {
        // Storage of set values
        uint256[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(uint256 => uint256) _indexes;//[value,index]
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, uint256 value) private returns (bool) {
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
    function _remove(Set storage set, uint256 value) private returns (bool) {
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
                uint256 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex;
                // Replace lastvalue's index to valueIndex
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
    function _contains(Set storage set, uint256 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (uint256) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (uint256[] memory) {
        return set._values;
    }

    function _clear(Set storage set) private returns (bool) {
        uint256 len = set._values.length;
        for(uint256 i = 0; i < len; i++){
            _remove(set,set._values[i]);
        }

        return true;
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
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, value);
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

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        return _values(set._inner);
    }

    function clear(UintSet storage set) internal returns (bool) {
        return _clear(set._inner);
    }
}

contract Tech is ITech
 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumAddressSet for EnumAddressSet.AddressSet;

    mapping(address => mapping(uint256 => Counters.Counter)) private _polls;//token->(suspectTokenId->poll)
    mapping(address => mapping(uint256 => bool)) private _voted;//token->(voteTokenId->bVoted)
    mapping(address => EnumerableSet.UintSet) private _preList;
    EnumAddressSet.AddressSet private _contrList;

    function suspectPoll(address token, uint256 suspectTokenId) external override view returns (uint256 poll){
        return _polls[token][suspectTokenId].current();
    }

    function preList(address token) external override view returns (uint256[] memory){
        return _preList[token].values();
    }

    function contrList() external override view returns (address[] memory){
        return _contrList.values();
    }

    function addNftToPreList(address token, uint256 suspectTokenId) external override returns (bool){
        require(IERC721(token).balanceOf(msg.sender) > 0, "Must own 1 NFT at least");
        require(IERC721(token).ownerOf(suspectTokenId) != address(0), "Invalid NFT");
        _contrList.add(token);
        emit OnAddNftToPreList(msg.sender, token, suspectTokenId);
        return _preList[token].add(suspectTokenId);
    }

    function suspectVoteBatch(address token, uint256[] calldata voteTokenIds, uint256 suspectTokenId) external override returns (bool){
        for (uint i = 0; i < voteTokenIds.length; i++) {
            _suspectVote(token, voteTokenIds[i], suspectTokenId);
        }
        emit OnSuspectVoteBatch(msg.sender, token, voteTokenIds, suspectTokenId);
        return true;
    }

    function suspectVote(address token, uint256 voteTokenId, uint256 suspectTokenId) external override returns (bool){
        _suspectVote(token, voteTokenId, suspectTokenId);
        emit OnSuspectVote(msg.sender, token, voteTokenId, suspectTokenId);
        return true;
    }

    function _suspectVote(address token, uint256 voteTokenId, uint256 suspectTokenId) internal {
        require(IERC721(token).ownerOf(voteTokenId) == msg.sender, "Voter must be the owner of the NFT for voting");
        require(!_voted[token][voteTokenId], "Voted already");
        require(_preList[token].contains(suspectTokenId), "target NFT not in the pre list");
        _polls[token][suspectTokenId].increment();
        _voted[token][voteTokenId] = true;
    }

    function suspectVoteRecall(address token, uint256 voteTokenId, uint256 suspectTokenId) external override returns (bool){
        require(IERC721(token).ownerOf(voteTokenId) == msg.sender, "Caller must be the owner of the NFT for recalling");
        require(_voted[token][voteTokenId], "Not voted yet");
        _polls[token][suspectTokenId].increment();
        _voted[token][voteTokenId] = false;

        _polls[token][suspectTokenId].decrement();
        emit OnSuspectVoteRecall(msg.sender, token, voteTokenId, suspectTokenId);
        return true;
    }
}