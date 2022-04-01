//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Reveal Buds
//
// by LOOK LABS
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ILL420BudStaking.sol";
import "./libraries/MerkleMultiProof.sol";
import "./libraries/ArraySort.sol";

/**
 * @title LL420BudReveal
 * @dev Store the revealed timestamp to the staking contract, and also set the THC of a bud to the staking contract,
 * based on the verification of merkle proof
 *
 */
contract LL420BudReveal is Ownable, Pausable, ReentrancyGuard {
    uint16 public constant TOTAL_SUPPLY = 20000;
    uint256 public revealPeriod = 7 days;
    bytes32 public merkleRoot;

    address public immutable stakingContractAddress;
    mapping(uint256 => bool) public requested;

    event RequestReveal(uint256 indexed _budId, address indexed _user, uint256 indexed _timestamp);

    constructor(address _stakingAddress) {
        require(_stakingAddress != address(0), "Zero address");

        stakingContractAddress = _stakingAddress;
    }

    /* ==================== External METHODS ==================== */

    /**
     * @dev Reveal the buds
     *
     * @param _id Id of game key
     * @param _ids Id array of buds
     */
    function reveal(uint256 _id, uint256[] memory _ids) external nonReentrant whenNotPaused {
        require(_ids.length <= TOTAL_SUPPLY, "Incorrect bud ids");

        uint256 _revealPeriod = revealPeriod;
        ILL420BudStaking BUD_STAKING = ILL420BudStaking(stakingContractAddress);

        uint256[] memory budIds = BUD_STAKING.getGKBuds(_id, _msgSender());
        /// Check if the ids belong to correct owner
        /// Check if the id is in pending of reveal
        for (uint256 i = 0; i < _ids.length; i++) {
            require(!requested[_ids[i]], "Bud is already requested to reveal");

            bool belong = false;
            for (uint256 j = 0; j < budIds.length; j++) {
                if (_ids[i] == budIds[j]) {
                    belong = true;
                    break;
                }
            }
            require(belong, "Bud not belong to the sender");
        }

        /// Check if Buds can be revealed
        (uint256[] memory periods, ) = BUD_STAKING.getBudInfo(_ids);
        for (uint256 i = 0; i < periods.length; i++) {
            require(periods[i] >= _revealPeriod, "Staked more than limit");

            requested[_ids[i]] = true;

            emit RequestReveal(_ids[i], _msgSender(), block.timestamp);
        }

        BUD_STAKING.setRevealTimestamps(block.timestamp, _msgSender());
    }

    /**
     * @dev Set THCs of revealed buds
     *
     * @param _ids bud id array
     * @param _thcs THC array
     * @param _proofs Multi-merkle proofs
     * @param _proofFlags Proof flags
     */
    function setBudTHCs(
        uint256[] calldata _ids,
        uint256[] calldata _thcs,
        bytes32[] calldata _proofs,
        bool[] calldata _proofFlags
    ) external whenNotPaused nonReentrant {
        require(_ids.length == _thcs.length && _ids.length > 0, "Unmatched thc count");
        require(merkleRoot != 0, "Merklet root not set");

        bytes32[] memory nodes = new bytes32[](_ids.length);
        uint256 factor = 10**18;
        for (uint256 i = 0; i < _ids.length; i++) {
            nodes[i] = keccak256(abi.encodePacked(_ids[i] * factor, _thcs[i] * factor));
        }

        nodes = ArraySort.sort(nodes);

        bool isValid = MerkleMultiProof.verifyMultiProof(merkleRoot, nodes, _proofs, _proofFlags);
        require(isValid, "Invalid proof");

        ILL420BudStaking(stakingContractAddress).setRevealedTHC(_ids, _thcs);
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev this set the reveal lock period for test from owner side.
     * @param _seconds reveal period in seconds
     */
    function setRevealPeriod(uint256 _seconds) external onlyOwner {
        revealPeriod = _seconds;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Bud / Game Key Staking Interface
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface ILL420BudStaking {
    function setRevealedTHC(uint256[] calldata _ids, uint256[] calldata _thc) external;

    function getBudInfo(uint256[] memory _ids) external view returns (uint256[] memory, uint256[] memory);

    function getGKBuds(uint256 _id, address _user) external view returns (uint256[] memory);

    function setRevealTimestamps(uint256 _timestamp, address _address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// @credit: https://github.com/miguelmota/merkletreejs-multiproof-solidity#example
library MerkleMultiProof {
    function calculateMultiMerkleRoot(
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    ) public pure returns (bytes32 merkleRoot) {
        uint256 leafsLen = leafs.length;
        uint256 totalHashes = proofFlag.length;
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        for (uint256 i = 0; i < totalHashes; i++) {
            hashes[i] = hashPair(
                proofFlag[i] ? (leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++]) : proofs[proofPos++],
                leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++]
            );
        }

        return hashes[totalHashes - 1];
    }

    function hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? hash_node(a, b) : hash_node(b, a);
    }

    function hash_node(bytes32 left, bytes32 right) private pure returns (bytes32 hash) {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }

    function verifyMultiProof(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    ) public pure returns (bool) {
        return calculateMultiMerkleRoot(leafs, proofs, proofFlag) == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library ArraySort {
    /**
     * Sort an array
     * @param array a bytes32 array
     */
    function sort(bytes32[] memory array) public pure returns (bytes32[] memory) {
        _quickSort(array, 0, array.length);
        return array;
    }

    function _quickSort(
        bytes32[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        if (j - i < 2) return;

        uint256 p = i;
        for (uint256 k = i + 1; k < j; ++k) {
            if (array[i] > array[k]) {
                _swap(array, ++p, k);
            }
        }
        _swap(array, i, p);
        _quickSort(array, i, p);
        _quickSort(array, p + 1, j);
    }

    function _swap(
        bytes32[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        (array[i], array[j]) = (array[j], array[i]);
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