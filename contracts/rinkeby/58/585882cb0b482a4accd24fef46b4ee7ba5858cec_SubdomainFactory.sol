/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// File: contracts/Subdomains/IReverseResolver.sol

pragma solidity ^0.8.4;

interface IReverseResolver {
	function setName(string memory name) external;
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @ensdomains/ens-contracts/contracts/registry/ENS.sol

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Subdomains/NFTSubdomain.sol

pragma solidity ^0.8.4;






contract NFTSubdomain is Ownable {
	using Strings for uint256;

	address constant REVERSE_RESOLVER_ADDRESS = 0x084b1c3C81545d370f3634392De611CaaBFf8148;

	IReverseResolver public constant ReverseResolver = IReverseResolver(REVERSE_RESOLVER_ADDRESS);
	ENS private constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
	IERC721 public nft;
	bytes32 public domainHash;
	mapping(bytes32 => mapping(string => string)) public texts;

	string public domainLabel;

	mapping(bytes32 => uint256) public hashToIdMap;
	mapping(uint256 => bytes32) public tokenHashmap;
	mapping(bytes32 => string) public hashToDomainMap;

	event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
	event RegisterSubdomain(address indexed registrar, uint256 indexed token_id, string indexed label);

	event AddrChanged(bytes32 indexed node, address a);

	constructor(
		address _nftContractAddress,
		string memory _domainLabel,
		bytes32 _domainHash
	) {
		nft = IERC721(_nftContractAddress);
		domainLabel = _domainLabel;
		domainHash = _domainHash;
	}

	//<interface-functions>
	function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
		return
			interfaceID == 0x3b3b57de || //addr
			interfaceID == 0x59d1d43c || //text
			interfaceID == 0x691f3431 || //name
			interfaceID == 0x01ffc9a7; //supportsInterface << [inception]
	}

	function text(bytes32 node, string calldata key) external view returns (string memory) {
		uint256 token_id = hashToIdMap[node];
		require(tokenHashmap[token_id] != 0x0, 'Invalid address');
		if (keccak256(abi.encodePacked(key)) == keccak256('avatar')) {
			return
				string(
					abi.encodePacked('eip155:1/erc721:0x4b10701Bfd7BFEdc47d50562b76b436fbB5BdB3B/', token_id.toString())
				);
		} else {
			return texts[node][key];
		}
	}

	function addr(bytes32 nodeID) public view returns (address) {
		uint256 token_id = hashToIdMap[nodeID];
		require(tokenHashmap[token_id] != 0x0, 'Invalid address');
		return nft.ownerOf(token_id);
	}

	function name(bytes32 node) public view returns (string memory) {
		return
			(bytes(hashToDomainMap[node]).length == 0)
				? ''
				: string(abi.encodePacked(hashToDomainMap[node], '.', domainLabel, '.eth'));
	}

	//</interface-functions>

	//--------------------------------------------------------------------------------------------//

	//<read-functions>
	function domainMap(string calldata label) public view returns (bytes32) {
		bytes32 encoded_label = keccak256(abi.encodePacked(label));
		bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));
		return hashToIdMap[big_hash] > 0 ? big_hash : bytes32(0x0);
	}

	function getTokenDomain(uint256 token_id) private view returns (string memory uri) {
		require(tokenHashmap[token_id] != 0x0, 'Token does not have an ENS register');
		uri = string(abi.encodePacked(hashToDomainMap[tokenHashmap[token_id]], '.', domainLabel, '.eth'));
	}

	function getTokensDomains(uint256[] memory token_ids) external view returns (string[] memory) {
		string[] memory uris = new string[](token_ids.length);
		for (uint256 i; i < token_ids.length; i++) {
			uris[i] = getTokenDomain(token_ids[i]);
		}
		return uris;
	}

	//</read-functions>

	//--------------------------------------------------------------------------------------------//

	//<authorised-functions>
	function claimSubdomain(string calldata label, uint256 token_id) public isAuthorised(token_id) {
		require(tokenHashmap[token_id] == 0x0, 'Token has already been set');

		bytes32 encoded_label = keccak256(abi.encodePacked(label));
		bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

		//ens.recordExists seems to not be reliable (tested removing records through ENS control panel and this still returns true)
		require(!ens.recordExists(big_hash) || msg.sender == owner(), 'sub-domain already exists');

		ens.setSubnodeRecord(domainHash, encoded_label, owner(), address(this), 0);

		hashToIdMap[big_hash] = token_id;
		tokenHashmap[token_id] = big_hash;
		hashToDomainMap[big_hash] = label;

		address token_owner = nft.ownerOf(token_id);

		emit RegisterSubdomain(token_owner, token_id, label);
		emit AddrChanged(big_hash, token_owner);
	}

	function setText(
		bytes32 node,
		string calldata key,
		string calldata value
	) external isAuthorised(hashToIdMap[node]) {
		uint256 token_id = hashToIdMap[node];
		require(tokenHashmap[token_id] != 0x0, 'Invalid address');
		require(keccak256(abi.encodePacked(key)) != keccak256('avatar'), 'cannot set avatar');

		texts[node][key] = value;
		emit TextChanged(node, key, key);
	}

	//this is to output an event because it seems that etherscan use
	//the graph events for their reverse resolution. If a linked NFT
	//is transfered then it can't callback to this contract so we provide this
	//method for users to do it manually. Anyone can call this method.
	function updateAddresses(uint256[] calldata _ids) external {
		uint256 len = _ids.length;
		for (uint256 i; i < len; ) {
			bytes32 big_hash = tokenHashmap[_ids[i]];
			require(big_hash != 0x0, 'no subdomain on this token');
			emit AddrChanged(big_hash, nft.ownerOf(_ids[i]));
			unchecked {
				++i;
			}
		}
	}

	function setContractName(string calldata _name) external onlyOwner {
		ReverseResolver.setName(_name);
	}

	function resetHash(uint256 token_id) public isAuthorised(token_id) {
		bytes32 domain = tokenHashmap[token_id];
		require(ens.recordExists(domain), 'Sub-domain does not exist');

		//reset domain mappings
		delete hashToDomainMap[domain];
		delete hashToIdMap[domain];
		delete tokenHashmap[token_id];

		emit AddrChanged(domain, address(0));
	}

	//</authorised-functions>

	//--------------------------------------------------------------------------------------------//

	// <owner-functions>

	function renounceOwnership() public override onlyOwner {
		require(false, 'ENS is responsibility. You cannot renounce ownership.');
		super.renounceOwnership();
	}

	//</owner-functions>

	modifier isAuthorised(uint256 tokenId) {
		require(owner() == msg.sender || nft.ownerOf(tokenId) == msg.sender, 'Not authorised');
		_;
	}
}

// File: contracts/Subdomains/BuildENSMain.sol

pragma solidity ^0.8.4;







contract MerkleSubdomain is Ownable {
	using Strings for uint256;

	bytes32 merkleHash;
	bytes32 public domainHash;
	string public domainLabel;

	address constant REVERSE_RESOLVER_ADDRESS = 0x084b1c3C81545d370f3634392De611CaaBFf8148;

	IReverseResolver public constant ReverseResolver = IReverseResolver(REVERSE_RESOLVER_ADDRESS);
	ENS private constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

	mapping(bytes32 => address) public hashToAddressMap;
	mapping(bytes32 => string) public hashToDomainMap;
	mapping(address => bytes32) public addressToHashmap;
	mapping(bytes32 => mapping(string => string)) public texts;

	event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
	event RegisterSubdomain(address indexed registrar, string indexed label);

	event AddrChanged(bytes32 indexed node, address a);
	event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);

	constructor(
		bytes32 _merkleHash,
		string memory _domainLabel,
		bytes32 _domainHash
	) {
		merkleHash = _merkleHash;
		domainLabel = _domainLabel;
		domainHash = _domainHash;
	}

	//<interface-functions>
	function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
		return
			interfaceID == 0x3b3b57de || //addr
			interfaceID == 0x59d1d43c || //text
			interfaceID == 0x691f3431 || //name
			interfaceID == 0x01ffc9a7; //supportsInterface << [inception]
	}

	function text(bytes32 node, string calldata key) external view returns (string memory) {
		address currentAddress = hashToAddressMap[node];
		require(addressToHashmap[currentAddress] != 0x0, 'Invalid address');
		return texts[node][key];
	}

	function addr(bytes32 nodeID) public view returns (address) {
		address currentAddress = hashToAddressMap[nodeID];
		// update the check for null address
		require(addressToHashmap[currentAddress] != 0x0, 'Invalid address');
		return hashToAddressMap[nodeID];
	}

	function name(bytes32 node) public view returns (string memory) {
		return
			(bytes(hashToDomainMap[node]).length == 0)
				? ''
				: string(abi.encodePacked(hashToDomainMap[node], '.', domainLabel, '.eth'));
	}

	//</interface-functions>

	//--------------------------------------------------------------------------------------------//

	//<read-functions>
	function domainMap(string calldata label) public view returns (bytes32) {
		bytes32 encoded_label = keccak256(abi.encodePacked(label));
		bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

		return hashToAddressMap[big_hash] != address(0) ? big_hash : bytes32(0x0);
	}

	//</read-functions>

	//--------------------------------------------------------------------------------------------//

	//<authorised-functions>
	function claimSubdomain(string calldata label, bytes32[] calldata proof) public isAuthorised(proof) {
		require(addressToHashmap[msg.sender] == 0x0, 'Address already claimed subdomain');

		bytes32 encoded_label = keccak256(abi.encodePacked(label));
		bytes32 big_hash = keccak256(abi.encodePacked(domainHash, encoded_label));

		//ens.recordExists seems to not be reliable (tested removing records through ENS control panel and this still returns true)

		require(!ens.recordExists(big_hash), 'sub-domain already exists');

		ens.setSubnodeRecord(domainHash, encoded_label, msg.sender, address(this), 0);

		hashToAddressMap[big_hash] = msg.sender;
		addressToHashmap[msg.sender] = big_hash;
		hashToDomainMap[big_hash] = label;

		emit RegisterSubdomain(msg.sender, label);
		emit AddrChanged(big_hash, msg.sender);
	}

	function setText(
		bytes32 node,
		string calldata key,
		string calldata value,
		bytes32[] calldata proof
	) external isAuthorised(proof) {
		address currentAddress = hashToAddressMap[node];
		require(currentAddress == msg.sender, "Can't change someone else subdomain text");
		require(addressToHashmap[currentAddress] != 0x0, 'Invalid address');

		texts[node][key] = value;
		emit TextChanged(node, key, key);
	}

	// @abhishek not sure what this does, but anyone can do this. Irrespective of the user is authorised or not
	function setContractName(string calldata _name) external {
		ReverseResolver.setName(_name);
	}

	function resetHash(bytes32[] calldata proof) public isAuthorised(proof) {
		bytes32 currDomainHash = addressToHashmap[msg.sender];
		require(ens.recordExists(currDomainHash), 'Sub-domain does not exist');

		//reset domain mappings
		delete hashToDomainMap[currDomainHash];
		delete hashToAddressMap[currDomainHash];
		delete addressToHashmap[msg.sender];

		emit AddrChanged(currDomainHash, address(0));
	}

	function updateMerkleHash(bytes32 _merkleHash) public onlyOwner {
		merkleHash = _merkleHash;
	}

	//</authorised-functions>

	//--------------------------------------------------------------------------------------------//

	// <owner-functions>

	function isValid(bytes32[] calldata proof) public view returns (bool) {
		return MerkleProof.verify(proof, merkleHash, keccak256(abi.encodePacked(msg.sender)));
	}

	modifier isAuthorised(bytes32[] calldata proof) {
		require(isValid(proof), 'Unauthorised user');
		_;
	}

	// </owner-functions>
}

// File: contracts/Subdomains/Factory.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;




contract SubdomainFactory is Ownable {
	bytes32 constant ensHash = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

	enum ContractType {
		Merkle,
		NFT
	}

	struct NFTSubdomainContractsInfo {
		NFTSubdomain subdomain;
		address creator;
	}

	struct MerkleSubdomainContractsInfo {
		MerkleSubdomain subdomain;
		address creator;
	}

	MerkleSubdomainContractsInfo[] public merkleContracts;
	NFTSubdomainContractsInfo[] public nftContracts;

	constructor() {}

	function createNFTContract(address _nftContractAddress, string memory _domainName) public {
		bytes32 domainHash = getDomainHash(_domainName);
		NFTSubdomain newBuild = new NFTSubdomain(_nftContractAddress, _domainName, domainHash);
		nftContracts.push(NFTSubdomainContractsInfo({ subdomain: newBuild, creator: msg.sender }));
	}

	function createMerkleContract(bytes32 _merkleHash, string memory _domainName) public {
		bytes32 domainHash = getDomainHash(_domainName);
		MerkleSubdomain newBuild = new MerkleSubdomain(_merkleHash, _domainName, domainHash);
		merkleContracts.push(MerkleSubdomainContractsInfo({ subdomain: newBuild, creator: msg.sender }));
	}

	function updateMerkleHash(uint256 _id, bytes32 _hash) public onlyCreator(ContractType.Merkle, _id) {
		// @abhishek how can we verify that the hash is right? And only then update the merkle hash
		merkleContracts[_id].subdomain.updateMerkleHash(_hash);
	}

	/**
		Modifies
	 */
	modifier onlyCreator(ContractType _type, uint256 _id) {
		if (_type == ContractType.Merkle) {
			require(msg.sender == merkleContracts[_id].creator, 'Not the creator of this merkle contract');
			_;
		}

		if (_type == ContractType.NFT) {
			require(msg.sender == nftContracts[_id].creator, 'Not the creator of this NFT contract');
			_;
		}

		require(false, 'Somethings not right');
		_;
	}

	/**
		Utils method
	 */

	function getDomainHash(string memory domain) public pure returns (bytes32) {
		bytes32 label = keccak256(bytes(domain));
		bytes32 domainHash = keccak256(abi.encodePacked(ensHash, label));
		return domainHash;
	}
}