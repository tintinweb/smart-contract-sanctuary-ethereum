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
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';

import './libraries/Bytes16Set.sol';

/// @custom:security-contact [email protected]
contract GoldenSchema is Ownable {
    using Bytes16Set for Bytes16Set.Set;
    Bytes16Set.Set _predicateIDs;
    mapping(bytes16 => bytes32) public predicateIDToLatestCID;

    struct Predicate {
        bytes16 predicateID;
        bytes32 latestCID;
    }

    event PredicateAdded(
        bytes16 indexed predicateID,
        bytes32 indexed latestCID
    );
    event PredicateUpdated(
        bytes16 indexed predicateID,
        bytes32 indexed latestCID
    );
    event PredicateRemoved(
        bytes16 indexed predicateID,
        bytes32 indexed latestCID
    );

    constructor(Predicate[] memory initialPredicates) Ownable() {
        uint256 predicateCount = initialPredicates.length;
        for (uint256 i = 0; i < predicateCount; i++) {
            addPredicate(
                initialPredicates[i].predicateID,
                initialPredicates[i].latestCID
            );
        }
    }

    function predicates() public view returns (Predicate[] memory) {
        Predicate[] memory _predicates = new Predicate[](
            _predicateIDs.keyList.length
        );
        for (uint256 i = 0; i < _predicates.length; i++) {
            _predicates[i].predicateID = _predicateIDs.keyAtIndex(i);
            _predicates[i].latestCID = predicateIDToLatestCID[
                _predicateIDs.keyAtIndex(i)
            ];
        }
        return _predicates;
    }

    function addPredicate(bytes16 predicateID, bytes32 predicateCID)
        public
        onlyOwner
    {
        _predicateIDs.insert(predicateID);
        predicateIDToLatestCID[predicateID] = predicateCID;
        emit PredicateAdded(predicateID, predicateCID);
    }

    function updatePredicate(bytes16 predicateID, bytes32 predicateCID)
        public
        onlyOwner
    {
        predicateIDToLatestCID[predicateID] = predicateCID;
        emit PredicateUpdated(predicateID, predicateCID);
    }

    function removePredicate(bytes16 predicateID) public onlyOwner {
        _predicateIDs.remove(predicateID);
        emit PredicateRemoved(predicateID, predicateIDToLatestCID[predicateID]);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

// Inspired by: https://github.com/rob-Hitchens/SetTypes

library Bytes16Set {
    struct Set {
        mapping(bytes16 => uint256) keyPointers;
        bytes16[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, bytes16 key) internal {
        require(
            !exists(self, key),
            'Bytes16Set: key already exists in the set.'
        );
        self.keyPointers[key] = self.keyList.length;
        self.keyList.push(key);
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, bytes16 key) internal {
        require(
            exists(self, key),
            'Bytes16Set: key does not exist in the set.'
        );
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            bytes16 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, bytes16 key)
        internal
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        internal
        view
        returns (bytes16)
    {
        return self.keyList[index];
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
}