// SPDX-License-Identifier: SPDX-License
/// @author aboltc
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HighriseReserve is Ownable {
	constructor(uint8 lowerTokenIdBound_, uint8 upperTokenIdBound_) {
		// merkleRoot = _merkleRoot;
		lowerTokenIdBound = lowerTokenIdBound_;
		upperTokenIdBound = upperTokenIdBound_;
	}

	/**--------------------------
	 * Merkle root allowlist
	 */
	/// @notice root of hash generated in scripts directory
	bytes32 merkleRoot;

	/**
	 * @notice reset merkle root
	 * @param _merkleRoot root of hash generated in scripts directory
	 */
	function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
		merkleRoot = _merkleRoot;
	}

	/**--------------------------
	 * Opening mechanics
	 */
	bool public isPrivateReserveOpen = false;
	bool public isPublicReserveOpen = false;

	// function handleEndDrop() public onlyOwner {
	// 	isPrivateReserveOpen = false;
	// 	isPublicReserveOpen = false;
	// 	currentDropIndex = currentDropIndex + 1;
	// }

	function openPrivateReserve() public onlyOwner {
		isPrivateReserveOpen = true;
	}

	function openPublicReserve() public onlyOwner {
		isPublicReserveOpen = true;
	}

	/**--------------------------
	 * Reserve mechanics
	 */
	uint8 lowerTokenIdBound;
	uint8 upperTokenIdBound;
	mapping(uint8 => address) public tokenAddressMap;

	function getCurrentReserve() public view returns (address[] memory) {
		require(lowerTokenIdBound < upperTokenIdBound, "TOKEN_BOUNDS_ERROR");

		address[] memory currentReserve = new address[](
			upperTokenIdBound - lowerTokenIdBound
		);
		for (uint8 i = 0; i < upperTokenIdBound - lowerTokenIdBound; i++) {
			currentReserve[i] = tokenAddressMap[i];
		}

		return currentReserve;
	}

	function setTokenBounds(uint8 lowerTokenIdBound_, uint8 upperTokenIdBound_)
		public
		onlyOwner
	{
		require(lowerTokenIdBound < upperTokenIdBound, "TOKEN_BOUNDS_ERROR");
		lowerTokenIdBound = lowerTokenIdBound_;
		upperTokenIdBound = upperTokenIdBound_;
	}

	function reserve(uint8 tokenId) public {
		require(
			tokenId >= lowerTokenIdBound && tokenId <= upperTokenIdBound,
			"TOKEN_OUT_OF_BOUNDS"
		);

		tokenAddressMap[tokenId] = msg.sender;
	}

	// function privateReserveTokenId(uint8 tokenId, bytes32 calldata _merkleProof) public {

	// }

	// function isAddressOnAllowList(address _address) pure private returns (bool) {
	//     bytes32 leaf = keccak256(abi.encodePacked(_address));
	//     return MerkleProof.verify(proof, root, leaf);
	// }

	// function privateReserveTokenId(uint8 tokenId, bytes32 calldata _merkleProof) public {
	// require(
	// 	addressReserve[currentDropIndex][msg.sender] != true,
	// 	"ADDRESS_ALREADY_RESERVED"
	// );
	// 	require(
	// 		addressTokenReserve[currentDropIndex][tokenId] == address(0),
	// 		"TOKEN_ALREADY_RESERVED"
	// 	);
	// 	require(
	// 		isPrivateReserveOpen && isAddressOnAllowList(msg.sender),
	// 		"NOT_ON_LIST"
	// 	);

	// 	addressReserve[currentDropIndex][msg.sender] = true;
	// 	addressTokenReserve[currentDropIndex][tokenId] = msg.sender;
	// }
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