// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

pragma solidity 0.8.17;

import "openzeppelin-contracts/utils/Counters.sol";

import "./SlotEntry.sol";
import "../interfaces/IDaoCore.sol";

/**
 * @notice abstract contract used for Extension and DaoCore,
 * add a guard which accept only call from Adapters
 */
abstract contract Extension is SlotEntry {
    modifier onlyAdapter(bytes4 slot_) {
        require(
            IDaoCore(_core).getSlotContractAddr(slot_) == msg.sender,
            "Cores: not the right adapter"
        );
        _;
    }

    constructor(address core, bytes4 slot) SlotEntry(core, slot, true) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../helpers/Slot.sol";
import "../interfaces/ISlotEntry.sol";

/**
 * @notice abstract contract shared by Adapter, Extensions and
 * DaoCore, contains informations related to slots.
 *
 * @dev states of this contract are called to perform some checks,
 * especially when a new adapter or extensions is plugged to the
 * DAO
 */
abstract contract SlotEntry is ISlotEntry {
    address internal immutable _core;
    bytes4 public immutable override slotId;
    bool public immutable override isExtension;

    constructor(
        address core,
        bytes4 slot,
        bool isExt
    ) {
        require(core != address(0), "SlotEntry: zero address");
        require(slot != Slot.EMPTY, "SlotEntry: empty slot");
        _core = core;
        slotId = slot;
        isExtension = isExt;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

import "../abstracts/Extension.sol";
import "../interfaces/IBank.sol";
import "../interfaces/IProposerAdapter.sol";
import "../helpers/Constants.sol";

/**
 * @notice Should be the only contract to approve to move tokens
 *
 * Manage only the TBIO token
 */

contract Bank is Extension, ReentrancyGuard, IBank, Constants {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct User {
        Account account;
        mapping(bytes32 => Commitment) commitments;
        EnumerableSet.Bytes32Set commitmentsList;
    }

    struct Vault {
        bool isExist;
        EnumerableSet.AddressSet tokenList;
        mapping(address => Balance) balance;
    }

    address public immutable terraBioToken;
    uint32 internal immutable MAX_TIMESTAMP;

    mapping(address => User) private _users;
    mapping(bytes4 => Vault) private _vaults;

    constructor(address core, address terraBioTokenAddr) Extension(core, Slot.BANK) {
        terraBioToken = terraBioTokenAddr;
        MAX_TIMESTAMP = type(uint32).max;
    }

    /* //////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////// */
    /**
     * @notice allow users to lock TBIO in several period of time in the contract,
     * and receive a vote weight for a specific proposal
     *
     * User can commit only once, without cancelation, the contract check if the
     * user have already TBIO in his account, otherwise the contract take from
     * owner's balance (Bank must be approved).
     */
    function newCommitment(
        address user,
        bytes32 proposalId,
        uint96 lockedAmount,
        uint32 lockPeriod,
        uint96 advanceDeposit
    ) external onlyAdapter(Slot.VOTING) returns (uint96 voteWeight) {
        require(!_users[user].commitmentsList.contains(proposalId), "Bank: already committed");

        Account memory account_ = _users[user].account;

        // check for available balance
        if (block.timestamp >= account_.nextRetrieval) {
            account_ = _updateUserAccount(account_, user);
        }

        // calcul amount to deposit in the contract
        uint256 toTransfer;
        if (account_.availableBalance >= lockedAmount) {
            account_.availableBalance -= lockedAmount;
        } else {
            toTransfer = lockedAmount - account_.availableBalance;
            account_.availableBalance = 0;
        }

        _depositTransfer(user, toTransfer + advanceDeposit);

        uint32 retrievalDate = uint32(block.timestamp) + lockPeriod;
        account_.availableBalance += advanceDeposit;
        account_.lockedBalance += lockedAmount;

        if (account_.nextRetrieval > retrievalDate) {
            account_.nextRetrieval = retrievalDate;
        }

        voteWeight = _calculVoteWeight(lockPeriod, lockedAmount);

        // storage writing
        _users[user].commitmentsList.add(proposalId);
        _users[user].commitments[proposalId] = Commitment(
            lockedAmount,
            voteWeight,
            lockPeriod,
            retrievalDate
        );
        _users[user].account = account_;

        emit NewCommitment(proposalId, user, lockPeriod, lockedAmount);
    }

    /**
     * @notice allow member to withdraw available balance of TBIO, only from
     * owner's account.
     */
    function withdrawAmount(address user, uint128 amount) external onlyAdapter(Slot.VOTING) {
        Account memory account_ = _users[user].account;

        if (block.timestamp >= account_.nextRetrieval) {
            account_ = _updateUserAccount(account_, user);
        }

        require(account_.availableBalance <= amount, "Bank: insuffisant available balance");
        account_.availableBalance -= amount;
        _users[user].account = account_;
        _withdrawTransfer(user, amount);
        emit Withdrawn(user, amount);
    }

    /**
     * @notice allows member to deposit TBIO in their account, enable
     * deposit for several vote.
     *
     * NOTE users can also do an `advancedDeposit` when they call `newCommitment`
     */
    function advancedDeposit(address user, uint128 amount)
        external
        onlyAdapter(ISlotEntry(msg.sender).slotId())
    {
        _users[user].account.availableBalance += amount;
        _depositTransfer(user, amount);
    }

    /**
     * @notice used to deposit funds in a specific vault, funds are
     * stored on the Bank contract, from a specific address (which has
     * approved Bank)
     *
     * SECURITY! any member who has approved the Bank can be attacked
     * a security check should be implemented here or in `Financing`
     */
    function vaultDeposit(
        bytes4 vaultId,
        address tokenAddr,
        address tokenOwner,
        uint128 amount
    ) external onlyAdapter(Slot.FINANCING) {
        require(_vaults[vaultId].isExist, "Bank: inexistant vaultId");
        require(_vaults[vaultId].tokenList.contains(tokenAddr), "Bank: unregistred token");

        IERC20(tokenAddr).transferFrom(tokenOwner, address(this), amount);
        _vaults[vaultId].balance[tokenAddr].availableBalance += amount;
        emit VaultTransfer(vaultId, tokenAddr, tokenOwner, address(this), amount);
    }

    /**
     * @notice allow admin to create a vault in the Bank,
     * with an associated tokenList.
     *
     * address(0) is used to manage blockchain native token, checking
     * if tokenAddr is an ERC20 is not 100% useful, only prevent mistake
     */
    function createVault(bytes4 vaultId, address[] memory tokenList)
        external
        onlyAdapter(Slot.FINANCING)
    {
        require(!_vaults[vaultId].isExist, "Bank: vault already exist");
        for (uint256 i; i < tokenList.length; ) {
            //require(address(IERC20(tokenList[i])) != address(0), "Bank: non erc20 token");
            _vaults[vaultId].tokenList.add(tokenList[i]);
            unchecked {
                ++i;
            }
        }
        _vaults[vaultId].isExist = true;

        emit VaultCreated(vaultId);
    }

    /**
     * @notice called when a transaction request on a vault is done.
     * Funds are commited to prevent an overcommitment for member and thus
     * block the transaction request
     *
     * TODO funds committed must return available when the transaction request
     * is rejected
     */
    function vaultCommit(
        bytes4 vaultId,
        address tokenAddr,
        address destinationAddr,
        uint128 amount
    ) external onlyAdapter(Slot.FINANCING) {
        require(_vaults[vaultId].isExist, "Bank: inexistant vaultId");
        require(
            _vaults[vaultId].balance[tokenAddr].availableBalance >= amount,
            "Bank: not enough in the vault"
        );

        _vaults[vaultId].balance[tokenAddr].availableBalance -= amount;
        _vaults[vaultId].balance[tokenAddr].commitedBalance += amount;

        emit VaultAmountCommitted(vaultId, tokenAddr, destinationAddr, amount);
    }

    /**
     * @notice called when a transaction request is accepted,
     * funds are transferred to the destination address
     */
    function vaultTransfer(
        bytes4 vaultId,
        address tokenAddr,
        address destinationAddr,
        uint128 amount
    ) external nonReentrant onlyAdapter(Slot.FINANCING) returns (bool) {
        _vaults[vaultId].balance[tokenAddr].commitedBalance -= amount;

        if (
            tokenAddr == address(terraBioToken) &&
            IDaoCore(_core).hasRole(destinationAddr, ROLE_MEMBER)
        ) {
            // TBIO case
            // applicant is a member receive proposal amount on his internal account
            // he should withdraw it if needed
            _users[destinationAddr].account.availableBalance += amount;

            emit VaultTransfer(vaultId, tokenAddr, address(this), address(this), amount);
            return true;
        }

        // important nonReentrant here as we don't track proposalId and balance associated
        IERC20(tokenAddr).transfer(destinationAddr, amount);

        emit VaultTransfer(vaultId, tokenAddr, address(this), destinationAddr, amount);

        return true;
    }

    /* //////////////////////////
                GETTERS
    ////////////////////////// */
    function getBalances(address user)
        external
        view
        returns (uint128 availableBalance, uint128 lockedBalance)
    {
        Account memory account_ = _users[user].account;
        availableBalance = account_.availableBalance;
        lockedBalance = account_.lockedBalance;

        uint256 timestamp = block.timestamp;
        for (uint256 i; i < _users[user].commitmentsList.length(); ) {
            Commitment memory commitment_ = _users[user].commitments[
                _users[user].commitmentsList.at(i)
            ];
            if (timestamp >= commitment_.retrievalDate) {
                availableBalance += commitment_.lockedAmount;
                lockedBalance -= commitment_.lockedAmount;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getCommitmentsList(address user) external view returns (bytes32[] memory) {
        uint256 length = _users[user].commitmentsList.length();
        bytes32[] memory commitmentsList = new bytes32[](length);
        for (uint256 i; i < length; ) {
            commitmentsList[i] = _users[user].commitmentsList.at(i);

            unchecked {
                ++i;
            }
        }

        return commitmentsList;
    }

    function getCommitment(address user, bytes32 proposalId)
        external
        view
        returns (
            uint96,
            uint96,
            uint32,
            uint32
        )
    {
        Commitment memory commitment_ = _users[user].commitments[proposalId];
        require(commitment_.lockedAmount > 0, "Bank: inexistant commitment");
        return (
            commitment_.lockedAmount,
            commitment_.voteWeight,
            commitment_.lockPeriod,
            commitment_.retrievalDate
        );
    }

    function getNextRetrievalDate(address user) external view returns (uint32 nextRetrievalDate) {
        nextRetrievalDate = _users[user].account.nextRetrieval;

        if (block.timestamp >= nextRetrievalDate) {
            nextRetrievalDate = MAX_TIMESTAMP;
            uint256 timestamp = block.timestamp;
            for (uint256 i; i < _users[user].commitmentsList.length(); ) {
                Commitment memory commitment_ = _users[user].commitments[
                    _users[user].commitmentsList.at(i)
                ];

                if (commitment_.retrievalDate > timestamp) {
                    if (commitment_.retrievalDate < nextRetrievalDate) {
                        nextRetrievalDate = commitment_.retrievalDate;
                    }
                }

                unchecked {
                    ++i;
                }
            }

            // return 0 if no more commitments
            if (nextRetrievalDate == MAX_TIMESTAMP) {
                delete nextRetrievalDate;
            }
        }
    }

    function getVaultBalances(bytes4 vaultId, address tokenAddr)
        external
        view
        returns (uint128, uint128)
    {
        //require(this.isVaultExist(vaultId), "Bank: non-existent vaultId");
        //require(this.isTokenInVaultTokenList(vaultId, tokenAddr), "Bank: token not in vault list");
        Balance memory balance_ = _vaults[vaultId].balance[tokenAddr];
        return (balance_.availableBalance, balance_.commitedBalance);
    }

    function getVaultTokenList(bytes4 vaultId) external view returns (address[] memory) {
        uint256 length = _vaults[vaultId].tokenList.length();
        address[] memory tokenList = new address[](length);
        for (uint256 i; i < length; ) {
            tokenList[i] = _vaults[vaultId].tokenList.at(i);
            unchecked {
                ++i;
            }
        }
        return tokenList;
    }

    function isTokenInVaultTokenList(bytes4 vaultId, address tokenAddr)
        external
        view
        returns (bool)
    {
        return _vaults[vaultId].tokenList.contains(tokenAddr);
    }

    function isVaultExist(bytes4 vaultId) external view returns (bool) {
        return _vaults[vaultId].isExist;
    }

    /* //////////////////////////
        INTERNAL FUNCTIONS
    ////////////////////////// */
    function _depositTransfer(address account, uint256 amount) internal {
        if (amount > 0) {
            IERC20(terraBioToken).transferFrom(account, address(this), amount);
            emit Deposit(account, amount);
        }
    }

    function _withdrawTransfer(address account, uint256 amount) internal {
        IERC20(terraBioToken).transfer(account, amount);
        emit Withdrawn(account, amount);
    }

    function _updateUserAccount(Account memory account, address user)
        internal
        returns (Account memory)
    {
        uint256 timestamp = block.timestamp;
        uint32 nextRetrievalDate = MAX_TIMESTAMP;

        // check the commitments list

        // read each time? => _users[user].commitmentsList.length();
        for (uint256 i; i < _users[user].commitmentsList.length(); ) {
            bytes32 proposalId = _users[user].commitmentsList.at(i);
            Commitment memory commitment_ = _users[user].commitments[proposalId];

            // is over?
            if (timestamp >= commitment_.retrievalDate) {
                account.availableBalance += commitment_.lockedAmount;
                account.lockedBalance -= commitment_.lockedAmount;
                delete _users[user].commitments[proposalId];
                _users[user].commitmentsList.remove(proposalId);
            } else {
                // store the next retrieval
                if (nextRetrievalDate > commitment_.retrievalDate) {
                    nextRetrievalDate = commitment_.retrievalDate;
                }
            }

            // loop
            unchecked {
                ++i;
            }
        }
        account.nextRetrieval = nextRetrievalDate;

        // return memory object
        return account;
    }

    function _calculVoteWeight(uint32 lockPeriod, uint96 lockAmount)
        internal
        pure
        returns (uint96)
    {
        if (lockPeriod == 1 days) {
            return lockAmount / 10;
        } else if (lockPeriod == 7 days) {
            return lockAmount;
        } else if (lockPeriod == 15 days) {
            return lockAmount * 2;
        } else if (lockPeriod == 30 days) {
            return lockAmount * 4;
        } else if (lockPeriod == 120 days) {
            return lockAmount * 25;
        } else if (lockPeriod == 365 days) {
            return lockAmount * 50;
        } else {
            revert("Bank: incorrect lock period");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Constants used in the DAO
 */
contract Constants {
    // CREDIT
    bytes4 internal constant CREDIT_VOTE = bytes4(keccak256("credit-vote"));

    // VAULTS
    bytes4 internal constant TREASURY = bytes4(keccak256("treasury"));

    // VOTE PARAMS
    bytes4 internal constant VOTE_STANDARD = bytes4(keccak256("vote-standard"));

    /**
     * @dev Collection of roles available for DAO users
     */
    bytes4 internal constant ROLE_MEMBER = bytes4(keccak256("role-member"));
    bytes4 internal constant ROLE_PROPOSER = bytes4(keccak256("role-proposer"));
    bytes4 internal constant ROLE_ADMIN = bytes4(keccak256("role-admin"));
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev DAO Slot access collection
 */
library Slot {
    // GENERAL
    bytes4 internal constant EMPTY = 0x00000000;
    bytes4 internal constant CORE = 0xFFFFFFFF;

    // ADAPTERS
    bytes4 internal constant MANAGING = bytes4(keccak256("managing"));
    bytes4 internal constant ONBOARDING = bytes4(keccak256("onboarding"));
    bytes4 internal constant VOTING = bytes4(keccak256("voting"));
    bytes4 internal constant FINANCING = bytes4(keccak256("financing"));

    // EXTENSIONS
    bytes4 internal constant BANK = bytes4(keccak256("bank"));
    bytes4 internal constant AGORA = bytes4(keccak256("agora"));

    function concatWithSlot(bytes28 id, bytes4 slot) internal pure returns (bytes32) {
        return bytes32(bytes.concat(slot, id));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IBank {
    event NewCommitment(
        bytes32 indexed proposalId,
        address indexed account,
        uint256 indexed lockPeriod,
        uint256 lockedAmount
    );
    event Deposit(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    event VaultCreated(bytes4 indexed vaultId);

    event VaultTransfer(
        bytes4 indexed vaultId,
        address indexed tokenAddr,
        address from,
        address to,
        uint128 amount
    );

    event VaultAmountCommitted(
        bytes4 indexed vaultId,
        address indexed tokenAddr,
        address indexed destinationAddr,
        uint128 amount
    );

    struct Account {
        uint128 availableBalance;
        uint96 lockedBalance; // until 100_000 proposals
        uint32 nextRetrieval;
    }

    /**
     * @notice Max amount locked per proposal is 50_000
     * With a x50 multiplier the voteWeight is at 2.5**24
     * Which is less than 2**96 (uint96)
     * lockPeriod and retrievalDate can be stored in uint32
     * the retrieval date would overflow if it is set to 82 years
     */
    struct Commitment {
        uint96 lockedAmount;
        uint96 voteWeight;
        uint32 lockPeriod;
        uint32 retrievalDate;
    }

    struct Balance {
        uint128 availableBalance;
        uint128 commitedBalance;
    }

    function newCommitment(
        address user,
        bytes32 proposalId,
        uint96 lockedAmount,
        uint32 lockPeriod,
        uint96 advanceDeposit
    ) external returns (uint96 voteWeight);

    function advancedDeposit(address user, uint128 amount) external;

    function withdrawAmount(address user, uint128 amount) external;

    function vaultCommit(
        bytes4 vaultId,
        address tokenAddr,
        address destinationAddr,
        uint128 amount
    ) external;

    function vaultDeposit(
        bytes4 vaultId,
        address tokenAddr,
        address tokenOwner,
        uint128 amount
    ) external;

    function vaultTransfer(
        bytes4 vaultId,
        address tokenAddr,
        address destinationAddr,
        uint128 amount
    ) external returns (bool);

    function createVault(bytes4 vaultId, address[] memory tokenList) external;

    function terraBioToken() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IDaoCore {
    event SlotEntryChanged(
        bytes4 indexed slot,
        bool indexed isExtension,
        address oldContractAddr,
        address newContractAddr
    );

    event MemberStatusChanged(
        address indexed member,
        bytes4 indexed roles,
        bool indexed actualValue
    );

    struct Entry {
        bytes4 slot;
        bool isExtension;
        address contractAddr;
    }

    function changeSlotEntry(bytes4 slot, address contractAddr) external;

    function addNewAdmin(address account) external;

    function changeMemberStatus(
        address account,
        bytes4 role,
        bool value
    ) external;

    function membersCount() external returns (uint256);

    function hasRole(address account, bytes4 role) external returns (bool);

    function getRolesList() external returns (bytes4[] memory);

    function isSlotActive(bytes4 slot) external view returns (bool);

    function isSlotExtension(bytes4 slot) external view returns (bool);

    function getSlotContractAddr(bytes4 slot) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IProposerAdapter {
    function finalizeProposal(bytes32 proposalId) external;

    function deleteArchive(bytes32 proposalId) external;

    function pauseToggleAdapter() external;

    function desactive() external;

    function ongoingProposals() external view returns (uint256);

    function archivedProposals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ISlotEntry {
    function isExtension() external view returns (bool);

    function slotId() external view returns (bytes4);
}