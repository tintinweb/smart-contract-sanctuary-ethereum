// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./TurfShopEligibilityChecker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


// A Merklee Tree based eligiblity checker for Turf Shop.
// Requires the address to check, the Merkle proof, and the expected number of items to mint.
// That count is encoded into the tree. If all's well it will return that count to TurfShop for minting.

// Requires TurfShop to call back to confirmMint to mark this address as having been attended to.

// Don't use this for live checks, only snapshots, since it won't track plots that have changed hands.

contract MerkChecker is TurfShopEligibilityChecker, Ownable {

  address turfShopAddress;
  mapping(address => uint256) private _mintedPerAddress;

  bytes32 private _merkleRoot;

  constructor(address turfShopAddress_) {
    require(turfShopAddress_ != address(0), "Set the Turf Shop address!");
    turfShopAddress = turfShopAddress_;
  }

  function check(address addr, bytes32[] memory merkleProof, bytes memory data) external view returns (bool, uint) {

    require(_mintedPerAddress[addr] == 0, "already minted");

    (uint expectedCount) = abi.decode(data, (uint));
    
    bytes32 leaf = keccak256(abi.encodePacked(addr, expectedCount));
    if(MerkleProof.verify(merkleProof, _merkleRoot, leaf)){
      return (true, expectedCount);
    } else {
      return (false, 0);
    }  
  }

  function confirmMint(address addr, uint256 count) external {
    require(msg.sender == turfShopAddress, "nope");
    _mintedPerAddress[addr] = count;
  }

  function setMerkleRoot(bytes32 merkRoot) external onlyOwner {
    _merkleRoot = merkRoot;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/*
  Each TurfShop object's mint can be configured to refer to an external contract for eligiblity checks.
  This way we can arrange mints' "allow list" flexibly as the need arises, without having to hard code
  all possible situations in the primary TurfShop contract.

  For example, we might want a "Get a free item for every Turf plot you own" give away,
  which would entail that a Checker contract get a user's balance from the original Turf contract.

  Or we might just have a snapshot of some arbitrary data, stored in a Merkle Tree.

  Or maybe we want to interface with another community's contract, etc.

  Either way, we can develop that later, on a per-Turf Object basis.

  In our "get a plant for every Turf Plot" example, we'd return (true, 5)
  for a person that held 5 plots. This would inform TurfShop.sol to give that person
  5 plants. Or, if they held no Turf Plots, we'd return (false, 0).
*/

interface TurfShopEligibilityChecker {
  // @notice Confirms if the given address can mint this object, and, if so, how many items can they mint?
  // @param addr The address being checked.
  // @param merkleProof If a Merkle Tree is involved, pass in the proof.
  // @param data An optional chunk of data that can be used by Checker in any way.
  function check(address addr, bytes32[] memory merkleProof, bytes memory data) external view returns (bool, uint);

  /**
  @notice A method that TurfShop can call back to, following a succesful mint, to let this Checker know that the
  address minted a given amount of items. This might be used to update storage in this contract in order to prevent the address
  from minting more than once. 
  NOTE: Be sure to setup some logic to prevent this method from being called globally.
  For example, store TurfShop's address in the constructor, and check that it's the `msg.sender` inside this method.
  */
  // @param addr The address that minted.
  // @param count How many items were minted.
  function confirmMint(address addr, uint256 count) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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