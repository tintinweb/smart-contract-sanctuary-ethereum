// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized and flexible operator filterer to abide to OpenSea's
/// mandatory on-chain royalty enforcement in order for new collections to
/// receive royalties.
/// For more information, see:
/// See: https://github.com/ProjectOpenSea/operator-filter-registry
abstract contract OperatorFilterer {
    /// @dev The default OpenSea operator blocklist subscription.
    address internal constant _DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /// @dev The OpenSea operator filter registry.
    address internal constant _OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev Registers the current contract to OpenSea's operator filter,
    /// and subscribe to the default OpenSea operator blocklist.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering() internal virtual {
        _registerForOperatorFiltering(_DEFAULT_SUBSCRIPTION, true);
    }

    /// @dev Registers the current contract to OpenSea's operator filter.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            let functionSelector := 0x7d3e3dbe // `registerAndSubscribe(address,address)`.

            // Clean the upper 96 bits of `subscriptionOrRegistrantToCopy` in case they are dirty.
            subscriptionOrRegistrantToCopy := shr(96, shl(96, subscriptionOrRegistrantToCopy))

            for {} iszero(subscribe) {} {
                if iszero(subscriptionOrRegistrantToCopy) {
                    functionSelector := 0x4420e486 // `register(address)`.
                    break
                }
                functionSelector := 0xa0af2903 // `registerAndCopyEntries(address,address)`.
                break
            }
            // Store the function selector.
            mstore(0x00, shl(224, functionSelector))
            // Store the `address(this)`.
            mstore(0x04, address())
            // Store the `subscriptionOrRegistrantToCopy`.
            mstore(0x24, subscriptionOrRegistrantToCopy)
            // Register into the registry.
            if iszero(call(gas(), _OPERATOR_FILTER_REGISTRY, 0, 0x00, 0x44, 0x00, 0x04)) {
                // If the function selector has not been overwritten,
                // it is an out-of-gas error.
                if eq(shr(224, mload(0x00)), functionSelector) {
                    // To prevent gas under-estimation.
                    revert(0, 0)
                }
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, because of Solidity's memory size limits.
            mstore(0x24, 0)
        }
    }

    /// @dev Modifier to guard a function and revert if the caller is a blocked operator.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            if (!_isPriorityOperator(msg.sender)) {
                if (_operatorFilteringEnabled()) _revertIfBlocked(msg.sender);
            }
        }
        _;
    }

    /// @dev Modifier to guard a function from approving a blocked operator..
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        if (!_isPriorityOperator(operator)) {
            if (_operatorFilteringEnabled()) _revertIfBlocked(operator);
        }
        _;
    }

    /// @dev Helper function that reverts if the `operator` is blocked by the registry.
    function _revertIfBlocked(address operator) private view {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `isOperatorAllowed(address,address)`,
            // shifted left by 6 bytes, which is enough for 8tb of memory.
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xc6171134001122334455)
            // Store the `address(this)`.
            mstore(0x1a, address())
            // Store the `operator`.
            mstore(0x3a, operator)

            // `isOperatorAllowed` always returns true if it does not revert.
            if iszero(staticcall(gas(), _OPERATOR_FILTER_REGISTRY, 0x16, 0x44, 0x00, 0x00)) {
                // Bubble up the revert if the staticcall reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // We'll skip checking if `from` is inside the blacklist.
            // Even though that can block transferring out of wrapper contracts,
            // we don't want tokens to be stuck.

            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev For deriving contracts to override, so that operator filtering
    /// can be turned on / off.
    /// Returns true by default.
    function _operatorFilteringEnabled() internal view virtual returns (bool) {
        return true;
    }

    /// @dev For deriving contracts to override, so that preferred marketplaces can
    /// skip operator filtering, helping users save gas.
    /// Returns false for all inputs by default.
    function _isPriorityOperator(address) internal view virtual returns (bool) {
        return false;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

uint256 constant EDITION_SIZE = 20;
uint256 constant EDITION_RELEASE_SCHEDULE = 24 hours;

uint256 constant PRESALE_PERIOD = 48 hours;
uint256 constant EDITION_SALE_PERIOD = EDITION_RELEASE_SCHEDULE * EDITION_SIZE;
uint256 constant UNSOLD_TIMELOCK = EDITION_SALE_PERIOD + 10 days;
uint256 constant PRINT_CLAIM_PERIOD = UNSOLD_TIMELOCK + 30 days;
uint256 constant REAL_ID_MULTIPLIER = 100;

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IRootsEditions {
    function mintArtistProof() external;

    function mintEdition(
        uint128 price,
        uint32 starts,
        uint8 presaleAmount,
        bytes32 presaleRoot
    ) external;

    function collectInPresale(uint256 id, bytes32[] calldata proof) external payable;

    function collect(uint256 id) external payable;

    function closeEdition(uint256 id) external;

    function setPresaleAmountForEdition(uint256 id, uint8 presaleAmount) external;

    function setPresaleRootForEdition(uint256 id, bytes32 presaleRoot) external;

    function removePresaleRequirementForEdition(uint256 id) external;

    function getHasArtistProofBeenMinted(uint256 id) external view returns (bool);

    function getHasArtworkEditionBeenMinted(uint256 id) external view returns (bool);

    function getArtworkEditionSize(uint256 id) external view returns (uint256);

    function getArtworkPresaleAmount(uint256 id) external view returns (uint256);

    function getArtworkSalePrice(uint256 id) external view returns (uint256);

    function getArtworkSaleStartTime(uint256 id) external view returns (uint256);

    function getArtworkEditionsSold(uint256 id) external view returns (uint256);

    function getArtworkEditionsSoldInPresale(uint256 id) external view returns (uint256);

    function getArtworkEditionsCurrentlyAvailable(uint256 id) external view returns (uint256);

    function getArtworkEditionsNextReleaseTime(uint256 id) external view returns (uint256);

    function getArtworkRealTokenId(uint256 id, uint256 edition) external view returns (uint256);

    function getArtworkIdFromRealId(uint256 realId) external view returns (uint256);

    function getArtworkEditionNumberFromRealId(uint256 realId) external view returns (uint256);

    function getArtworkInformation(uint256 id)
        external
        view
        returns (
            bool artistProofMinted,
            uint256 editionSize,
            uint256 price,
            uint256 starts,
            uint256 nextEditionReleaseTime,
            uint256 editionsCurrentlyAvailable,
            uint256 presaleAmount,
            bytes32 presaleRoot,
            uint256 soldPresale,
            uint256 sold,
            bool editionMinted
        );
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**          

      `7MM"""Mq.                     mm           
        MM   `MM.                    MM           
        MM   ,M9  ,pW"Wq.   ,pW"Wq.mmMMmm ,pP"Ybd 
        MMmmdM9  6W'   `Wb 6W'   `Wb MM   8I   `" 
        MM  YM.  8M     M8 8M     M8 MM   `YMMMa. 
        MM   `Mb.YA.   ,A9 YA.   ,A9 MM   L.   I8 
      .JMML. .JMM.`Ybmd9'   `Ybmd9'  `MbmoM9mmmP' 

      E D I T I O N S
                
      https://roots.samking.photo/editions

*/

import "./Constants.sol";
import {SKS721} from "./SKS721.sol";
import {IRootsEditions} from "./IRootsEditions.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * @author Sam King (samkingstudio.eth)
 * @title  Roots Editions
 * @notice Numbered edition ERC721 NFTs as an extension of Roots by Sam King
 */
contract RootsEditions is IRootsEditions, SKS721 {
    struct ArtworkData {
        uint8 editionSize;
        uint128 price;
        uint32 starts;
        uint8 presaleAmount;
        uint8 soldPresale;
        uint8 sold;
        bool artistProofMinted;
    }

    /// @dev A mapping of original artwork ids to artwork data
    mapping(uint256 => ArtworkData) internal _artworks;

    /// @notice A mapping of original artwork ids to merkle roots for presale groups
    mapping(uint256 => bytes32) public presaleRoots;

    /// @dev A mapping of address => artwork id => presale collected
    mapping(address => mapping(uint256 => bool)) internal _presaleCollected;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error ArtistProofAlreadyMinted();
    error ArtistProofNotMinted();
    error CannotSetZeroStartTime();
    error CannotUsePresaleWithoutRoot();

    error ArtworkDoesNotExist();

    error SaleAlreadyStarted();
    error PresaleAmountExceedsEditionSize();

    error PresaleNotRequired();
    error PresaleInvalidProof();
    error PresaleNotStarted();
    error PresaleConcluded();
    error PresaleSoldOut();
    error PresaleAlreadyCollected();

    error IncorrectPrice();
    error ArtworkSoldOut();
    error ArtworkNotForSale();
    error ArtworkNoEditionsCurrentlyAvailable();
    error ArtworkAlreadyCollected();
    error NoMoreEditionsToRelease();

    error UnsoldTimelockNotElapsed();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When a new artist proof has been minted
     * @param id The artwork id
     */
    event ArtistProofMint(uint256 indexed id);

    /**
     * @notice When a new edition has been released and minted to the artist
     * @param id The artwork id
     * @param price The price to collect an edition
     * @param starts When the artwork can be collected
     */
    event EditionMint(uint256 indexed id, uint256 indexed price, uint256 indexed starts);

    /**
     * @notice When a presale amount is updated for an artwork
     * @param id The artwork id
     * @param amount The new presale amount
     */
    event PresaleAmountSet(uint256 indexed id, uint256 indexed amount);

    /**
     * @notice When a presale merkle root is updated for an artwork
     * @param id The artwork id
     * @param root The merkle root
     */
    event PresaleRootSet(uint256 indexed id, bytes32 indexed root);

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner, address metadata)
        SKS721(owner, "Roots Editions", "ROOTED", metadata)
    {}

    /* ------------------------------------------------------------------------
       M I N T   R E L E A S E
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Mints an artist proof for an edition to the artist
     *
     * @dev
     * The full edition can only be minted once the artist proof has been minted. Reverts if
     * the artist proof has already been minted before the full edition has been minted.
     */
    function mintArtistProof() external onlyOwner {
        ArtworkData memory artwork = _artworks[nextId];

        // Revert if the proof has already been minted
        if (artwork.artistProofMinted) revert ArtistProofAlreadyMinted();

        // Set the initial artwork data
        artwork.editionSize = uint8(EDITION_SIZE);
        artwork.artistProofMinted = true;
        _artworks[nextId] = artwork;

        // Mint the proof to the artist
        _mint(artist, _getRealTokenId(nextId, 0));
        emit ArtistProofMint(nextId);
    }

    /**
     * @notice
     * Mints the next release to the artist with a price, start time, and presale options
     *
     * @dev
     * Emits multiple `Transfer` events and doesn't update ownership in storage to save gas.
     * If there are leftover tokens after the sale period, the artist can take actual ownership of
     * the remaining tokens.
     *
     * Reverts if:
     *  - the artist proof for the release has not been minted
     *  - the start time is set to zero since that determines if artwork data exists
     *  - a presale amount is set, but no presale root is provided
     *
     * @param price The sale price for the next release
     * @param starts The start time of the sale period
     * @param presaleAmount The number of editions that require a proof to collect
     * @param presaleRoot The merkle root for the next release
     */
    function mintEdition(
        uint128 price,
        uint32 starts,
        uint8 presaleAmount,
        bytes32 presaleRoot
    ) external onlyOwner {
        ArtworkData memory artwork = _artworks[nextId];

        // Can only mint the edition when the artist proof has been minted
        if (!artwork.artistProofMinted) revert ArtistProofNotMinted();

        // Must specify a start time
        if (starts == 0) revert CannotSetZeroStartTime();

        // Can only create with a presale if a presale merkle root is provided
        if (presaleAmount > 0 && presaleRoot == bytes32(0)) revert CannotUsePresaleWithoutRoot();

        // Save the presale root if provided
        if (presaleRoot != bytes32(0)) {
            presaleRoots[nextId] = presaleRoot;
            emit PresaleRootSet(nextId, presaleRoot);
        }

        // Emit an event if there's a presale allocation
        if (presaleAmount > 0) {
            artwork.presaleAmount = presaleAmount;
            emit PresaleAmountSet(nextId, presaleAmount);
        }

        // Save the artwork data
        artwork.price = price;
        artwork.starts = starts;
        _artworks[nextId] = artwork;

        /**
         * Transfer from the artist to `to`
         *
         * Safety:
         *   1. the edition size is small and will likely never overflow for this project.
         */
        unchecked {
            _balanceOf[artist] += EDITION_SIZE;
        }
        for (uint256 i = 0; i < EDITION_SIZE; i++) {
            emit Transfer(address(0), artist, _getRealTokenId(nextId, i + 1));
        }

        // Emit that the edition was minted
        emit EditionMint(nextId, price, starts);

        /**
         * Increment the counter ready for the next artwork
         *
         * Safety:
         *   1. the next edition id will never overflow
         */
        unchecked {
            ++nextId;
        }
    }

    /** INTERNAL ----------------------------------------------------------- */

    /**
     * @notice
     * Internal function to transfer the next edition from the artist to `to`
     *
     * @param id The artwork id
     * @param to The account to transfer the edition to
     * @param artwork The artwork sale data
     */
    function _transferFromArtist(
        uint256 id,
        address to,
        ArtworkData memory artwork
    ) internal {
        uint256 realId = _getRealTokenId(id, artwork.soldPresale + artwork.sold);
        if (_ownerOf[realId] != address(0)) revert ArtworkAlreadyCollected();

        /**
         * Transfer from the artist to `to`
         *
         * Safety:
         *   1. Artist balance is always above 1 given a transfer can only happen once a
         *      pre-mint has happened.
         *   2. Unlikely that `to` balance will ever overflow for this project.
         */
        unchecked {
            _balanceOf[artist]--;
            _balanceOf[to]++;
        }
        _ownerOf[realId] = to;

        emit Transfer(artist, to, realId);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice
     * Admin function to set the number of editions that are reserved for presale
     *
     * @dev
     * Reverts if:
     *  - the artwork does not exist
     *  - the presale amount exceeds the standard edition size
     *  - the sale has already started.
     *
     * @param id The artwork id
     * @param presaleAmount The number of editions reserved for presale
     */
    function setPresaleAmountForEdition(uint256 id, uint8 presaleAmount) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (presaleAmount > EDITION_SIZE) revert PresaleAmountExceedsEditionSize();
        if (block.timestamp > artwork.starts) revert SaleAlreadyStarted();

        // Set the number of editions to reserve
        _artworks[id].presaleAmount = presaleAmount;
        emit PresaleAmountSet(id, presaleAmount);
    }

    /**
     * @notice
     * Admin function to set a merkle root for a particular artwork
     *
     * @dev
     * Reverts if:
     * - the artwork does not exist
     * - the presale amount is greater than zero, and the root is empty
     *
     * @param id The artwork id
     * @param presaleRoot The new merkle root
     */
    function setPresaleRootForEdition(uint256 id, bytes32 presaleRoot) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.presaleAmount > 0 && presaleRoot == bytes32(0)) {
            revert CannotUsePresaleWithoutRoot();
        }

        // Set the new merkle root
        presaleRoots[id] = presaleRoot;
        emit PresaleRootSet(id, presaleRoot);
    }

    /**
     * @notice
     * Admin function to remove any presale requirements for a particular artwork
     *
     * @dev
     * Reverts if:
     * - the artwork does not exist
     *
     * @param id The artwork id
     */
    function removePresaleRequirementForEdition(uint256 id) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();

        artwork.presaleAmount = 0;
        _artworks[id] = artwork;

        presaleRoots[id] = bytes32(0);

        emit PresaleAmountSet(id, 0);
        emit PresaleRootSet(id, bytes32(0));
    }

    /** GETTERS ------------------------------------------------------------ */

    /**
     * @notice
     * Checks if the artist proof for an edition has been minted
     *
     * @param id The artwork id
     * @return artistProofMinted If the artist proof has been minted
     */
    function getHasArtistProofBeenMinted(uint256 id) external view returns (bool) {
        ArtworkData memory artwork = _artworks[id];
        return artwork.artistProofMinted;
    }

    /**
     * @notice
     * Gets the edition size for a particular artwork
     *
     * @dev
     * Reverts if:
     *  - the artist proof has not been minted
     *
     * @param id The artwork id
     * @return editionMinted If the edition has been minted
     */
    function getHasArtworkEditionBeenMinted(uint256 id) external view returns (bool) {
        ArtworkData memory artwork = _artworks[id];
        if (!artwork.artistProofMinted) revert ArtistProofNotMinted();
        return artwork.starts > 0;
    }

    /**
     * @notice
     * Gets the edition size for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return editionSize The edition size of the artwork
     */
    function getArtworkEditionSize(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.editionSize;
    }

    /**
     * @notice
     * Gets the number of editions available for presale for a given artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return presaleAmount The number of editions available for presale
     */
    function getArtworkPresaleAmount(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.presaleAmount;
    }

    /**
     * @notice
     * Gets the sale price for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return price The sale price of the artwork
     */
    function getArtworkSalePrice(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.price;
    }

    /**
     * @notice
     * Gets the sale start time in seconds for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return starts The sale start time in seconds
     */
    function getArtworkSaleStartTime(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.starts;
    }

    /**
     * @notice
     * Gets the total number of editions sold for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return editionsSold The number of editions sold
     */
    function getArtworkEditionsSold(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.soldPresale + artwork.sold;
    }

    /**
     * @notice
     * Gets the number of editions sold in the presale for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return soldInPresale The number of editions sold in the presale
     */
    function getArtworkEditionsSoldInPresale(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.soldPresale;
    }

    /**
     * @notice
     * Gets the number of editions that are currently collectable
     *
     * @dev
     * Every `EDITION_RELEASE_SCHEDULE` that has elapsed from the start, the available
     * amount increases by one, and each sale decreases the amount by one.
     *
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return editionsSold The number of editions sold
     */
    function getArtworkEditionsCurrentlyAvailable(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _artworkEditionsAvailable(artwork);
    }

    /**
     * @notice
     * Internal function to get the number of editions currently available to collect
     *
     * @dev
     * Uses the sale period and the amount sold to calculate how many editions can be
     * collected at the current block timestamp.
     *
     * @param artwork The artwork information
     * @return available The current number of editions that are available to collect
     */
    function _artworkEditionsAvailable(ArtworkData memory artwork) internal view returns (uint256) {
        if (block.timestamp < artwork.starts || artwork.starts == 0) return 0;
        uint256 released = _artworkEditionsReleased(artwork);
        uint256 max = (EDITION_SIZE - artwork.soldPresale);
        return (released >= max ? max : released) - artwork.sold;
    }

    /**
     * @notice
     * Gets the next release time of an edition from a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return nextReleaseTime The next edition release time in seconds
     */
    function getArtworkEditionsNextReleaseTime(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _artworkEditionsNextReleaseTime(artwork);
    }

    /**
     * @notice
     * Internal function to get the number of editions released since the start
     *
     * @dev
     * Caps the number at `EDITION_SIZE`
     *
     * @param artwork The artwork information
     * @return editionsReleased The number of editions released since the start
     */
    function _artworkEditionsReleased(ArtworkData memory artwork) internal view returns (uint256) {
        if (block.timestamp < artwork.starts) return 0;
        if (block.timestamp < artwork.starts + EDITION_RELEASE_SCHEDULE) return 1;
        uint256 released = ((block.timestamp - artwork.starts) / EDITION_RELEASE_SCHEDULE) + 1;
        return released > EDITION_SIZE ? EDITION_SIZE : released;
    }

    /**
     * @notice
     * Internal function to get the next release time of an edition
     *
     * @param artwork The artwork information
     * @return nextReleaseTime The next edition release time in seconds
     */
    function _artworkEditionsNextReleaseTime(ArtworkData memory artwork)
        internal
        view
        returns (uint256)
    {
        uint256 released = _artworkEditionsReleased(artwork);
        return artwork.starts + (released * EDITION_RELEASE_SCHEDULE);
    }

    /**
     * @notice
     * Gets the real token id for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @param edition The edition number
     * @return realId The real token id
     */
    function getArtworkRealTokenId(uint256 id, uint256 edition) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _getRealTokenId(id, edition);
    }

    /**
     * @notice
     * Gets the original artwork id from a real token id for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param realId The real token id
     * @return originalId The original artwork id
     */
    function getArtworkIdFromRealId(uint256 realId) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[_getIdFromRealTokenId(realId)];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _getIdFromRealTokenId(realId);
    }

    /**
     * @notice
     * Gets the edition number from a real token id for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param realId The real token id
     * @return edition The edition number
     */
    function getArtworkEditionNumberFromRealId(uint256 realId) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[_getIdFromRealTokenId(realId)];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _getEditionFromRealTokenId(realId);
    }

    /**
     * @notice
     * Gets information about a particular artwork
     *
     * @param id The artwork id
     */
    function getArtworkInformation(uint256 id)
        external
        view
        returns (
            bool artistProofMinted,
            uint256 editionSize,
            uint256 price,
            uint256 starts,
            uint256 nextEditionReleaseTime,
            uint256 editionsCurrentlyAvailable,
            uint256 presaleAmount,
            bytes32 presaleRoot,
            uint256 soldPresale,
            uint256 sold,
            bool editionMinted
        )
    {
        ArtworkData memory artwork = _artworks[id];

        artistProofMinted = artwork.artistProofMinted;
        editionSize = artwork.editionSize;
        price = artwork.price;
        starts = artwork.starts;
        nextEditionReleaseTime = _artworkEditionsNextReleaseTime(artwork);
        editionsCurrentlyAvailable = _artworkEditionsAvailable(artwork);
        presaleAmount = artwork.presaleAmount;
        presaleRoot = presaleRoots[id];
        soldPresale = artwork.soldPresale;
        sold = artwork.sold;
        editionMinted = artwork.starts > 0;
    }

    /* ------------------------------------------------------------------------
       P R E S A L E
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows a verified account to collect an edition in the presale period
     *
     * @dev
     * Reverts if:
     *  - the artwork does not exist
     *  - there is no presale for the artwork
     *  - the caller has already collected in the presale
     *  - the presale has not started yet
     *  - the presale has concluded
     *  - the presale has sold out
     *  - the price does not match the sale price
     *  - the provided proof is not valid
     *
     * @param id The artwork id
     * @param proof The merkle proof that allows the caller to collect
     */
    function collectInPresale(uint256 id, bytes32[] calldata proof) external payable {
        ArtworkData memory artwork = _artworks[id];

        // Check the presale conditions
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.presaleAmount == 0) revert PresaleNotRequired();
        if (_presaleCollected[msg.sender][id]) revert PresaleAlreadyCollected();
        if (artwork.starts - PRESALE_PERIOD > block.timestamp) revert PresaleNotStarted();
        if (block.timestamp >= artwork.starts) revert PresaleConcluded();
        if (artwork.soldPresale == artwork.presaleAmount) revert PresaleSoldOut();
        if (artwork.price != msg.value) revert IncorrectPrice();
        if (!_verifyProof(id, msg.sender, proof)) revert PresaleInvalidProof();

        /**
         * Increment the sold counter for the presale
         *
         * Safety:
         *   1. We check above that the presale amount does not exceed the allowed amount
         *      so an overflow will not happen.
         */
        unchecked {
            ++artwork.soldPresale;
        }
        _artworks[id] = artwork;

        // Prevent collecting multiple times in the same presale
        _presaleCollected[msg.sender][id] = true;

        // Transfer the artwork from the artist
        _transferFromArtist(id, msg.sender, artwork);
    }

    /**
     * @notice
     * Internal function to verify a merkle proof for a given artwork
     *
     * @param id The artwork id
     * @param account The account to verify the proof for
     * @param proof The merkle proof to verify
     */
    function _verifyProof(
        uint256 id,
        address account,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        return MerkleProof.verify(proof, presaleRoots[id], keccak256(abi.encodePacked(account)));
    }

    /** GETTERS ------------------------------------------------------------ */

    /**
     * @notice
     * Checks if an account can collect an edition in the presale for an artwork
     *
     * @dev
     * Skips proof checks if the artwork does not require it.
     * Reverts if the artwork does not exist.
     *
     * @param id The artwork id
     * @param account The account to check
     * @return allowedToCollect If the account can collect an edition with the provided proof
     */
    function getCanCollectInPresale(
        uint256 id,
        address account,
        bytes32[] calldata proof
    ) external view returns (bool) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.presaleAmount == 0) return true;
        return _verifyProof(id, account, proof);
    }

    /* ------------------------------------------------------------------------
       C O L L E C T
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Collect an edition of the specified id
     *
     * @dev
     * Transfers the artwork from the artist to the msg.sender
     *
     * Reverts if:
     *  - the artwork does not exist
     *  - the sale period has not started yet
     *  - the price does not match the sale price
     *  - the edition is sold out
     *  - the next edition is not purchasable yet
     *
     * @param id The artwork id to collect
     */
    function collect(uint256 id) external payable {
        ArtworkData memory artwork = _artworks[id];

        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.starts > block.timestamp) revert ArtworkNotForSale();
        if (artwork.price != msg.value) revert IncorrectPrice();
        if (artwork.soldPresale + artwork.sold == artwork.editionSize) revert ArtworkSoldOut();
        if (_artworkEditionsAvailable(artwork) == 0) revert ArtworkNoEditionsCurrentlyAvailable();

        /**
         * Increment the sold counter for the presale
         *
         * Safety:
         *   1. We check above that the sold amount does not exceed the allowed amount
         *      so an overflow will not happen.
         */
        unchecked {
            ++artwork.sold;
        }
        _artworks[id] = artwork;

        // Transfer the artwork from the artist
        _transferFromArtist(id, msg.sender, artwork);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice
     * Allows the artist to close the edition once the time lock has elapsed. Any
     * unsold editions are burned, and the edition size is set to the amount sold.
     *
     * @dev
     * Since the `_ownerOf` was never set in storage when pre-minting to the artist, the
     * burning is also done by only emitting transfer events to save gas.
     *
     * Reverts if:
     *  - the artwork does not exist
     *  - the sale period has not started yet
     *  - the time lock has not elapsed
     *  - the edition is sold out
     *
     * @param id The artwork id to take ownership of unsold editions
     */
    function closeEdition(uint256 id) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        uint256 totalSold = artwork.soldPresale + artwork.sold;

        // Check the unsold editions ownership can be set
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.starts + UNSOLD_TIMELOCK > block.timestamp) revert UnsoldTimelockNotElapsed();
        if (totalSold == artwork.editionSize) revert ArtworkSoldOut();

        // Emit burn events for the token
        for (uint256 edition = totalSold + 1; edition <= EDITION_SIZE; edition++) {
            emit Transfer(artist, address(0), _getRealTokenId(id, edition));
        }

        // Set the new edition size to the total sold amount
        artwork.editionSize = uint8(totalSold);
        _artworks[id] = artwork;

        // Update the burned counter for the whole collection
        burned += totalSold;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {REAL_ID_MULTIPLIER, EDITION_SIZE, EDITION_RELEASE_SCHEDULE} from "./Constants.sol";
import {IMetadata} from "./IMetadata.sol";

/**
 * @author Sam King (samkingstudio.eth)
 * @title  Sam King Studio ECR721
 * @notice Uses solmate ERC721 and includes royalties, operator filtering, withdrawing
 * and an upgradeable metadata contract.
 */
contract SKS721 is ERC721, OperatorFilterer, Owned {
    /// @notice The public address of the artist, Sam King
    address public artist;

    /// @notice The next original token id
    uint256 public nextId = 1;

    /// @notice The total count of burned tokens
    uint256 public burned;

    /// @notice Mapping of burned token ids
    mapping(uint256 => bool) public tokenBurned;

    struct RoyaltyInfo {
        address receiver;
        uint96 amount;
    }

    /// @dev Store info about token royalties
    RoyaltyInfo internal _royaltyInfo;

    /// @notice If operator filtering is enabled for royalties
    bool public operatorFilteringEnabled;

    /// @dev Metadata rendering contract
    IMetadata internal _metadata;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error ZeroBalance();
    error WithdrawFailed();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract is initialized
     */
    event Initialized();

    /**
     * @notice When the royalty information is updated
     * @param receiver The new receiver of royalties
     * @param amount The new royalty amount with two decimals (10,000 = 100)
     */
    event RoyaltiesUpdated(address indexed receiver, uint256 indexed amount);

    /**
     * @notice When the metadata rendering contract is updated
     * @param prevMetadata The current metadata address
     * @param metadata The new metadata address
     */
    event MetadataUpdated(address indexed prevMetadata, address indexed metadata);

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(
        address owner,
        string memory name,
        string memory symbol,
        address metadata
    ) ERC721(name, symbol) Owned(owner) {
        artist = owner;
        _royaltyInfo = RoyaltyInfo(owner, uint96(5_00));
        _metadata = IMetadata(metadata);

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        emit Initialized();
        emit RoyaltiesUpdated(owner, 5_00);
        emit MetadataUpdated(address(0), metadata);
    }

    /* ------------------------------------------------------------------------
       M E T A D A T A
    ------------------------------------------------------------------------ */

    /**
     * @notice {ERC721.tokenURI} that calls to an external contract to render metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "INVALID_ID");
        return _metadata.tokenURI(tokenId);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice Admin function to set the metadata rendering contract address
     * @param metadata The new metadata contract address
     */
    function setMetadata(address metadata) public onlyOwner {
        emit MetadataUpdated(address(_metadata), metadata);
        _metadata = IMetadata(metadata);
    }

    /* ------------------------------------------------------------------------
       R O Y A L T I E S
    ------------------------------------------------------------------------ */

    /**
     * @notice EIP-2981 royalty standard for on-chain royalties
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyInfo.receiver;
        royaltyAmount = (salePrice * _royaltyInfo.amount) / 10_000;
    }

    /**
     * @dev Extend `supportsInterface` to support EIP-2981
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // EIP-2981 = bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice Admin function to update royalty information
     * @param receiver The receiver of royalty payments
     * @param amount The royalty percentage with two decimals (10000 = 100)
     */
    function setRoyaltyInfo(address receiver, uint96 amount) external onlyOwner {
        emit RoyaltiesUpdated(receiver, amount);
        _royaltyInfo = RoyaltyInfo(receiver, uint96(amount));
    }

    /**
     * @notice Admin function to enable OpenSea operator filtering
     * @param enabled If operator filtering should be enabled
     */
    function setOperatorFilteringEnabled(bool enabled) external onlyOwner {
        operatorFilteringEnabled = enabled;
    }

    /** INTERNAL ----------------------------------------------------------- */

    /**
     * @notice Internal override for {OperatorFilterer} to determine if filtering is enabled
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /**
     * @notice Internal override for {OperatorFilterer} to determine if operator checks
     * should be skipped for a particular operator to save on gas
     */
    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /* ------------------------------------------------------------------------
       W I T H D R A W
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to withdraw all ETH from the contract to the owner
     */
    function withdrawETH() external onlyOwner {
        if (address(this).balance == 0) revert ZeroBalance();
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    /**
     * @notice Admin function to withdraw all ERC20 tokens from the contract to the owner
     * @param token The ERC20 token contract address to withdraw
     */
    function withdrawERC20(address token) external onlyOwner {
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }

    /* ------------------------------------------------------------------------
       U T I L S
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Internal function to convert an id and edition number into an _actual_ artwork id
     *
     * @param id The original artwork id e.g. 1, 2, 3
     * @param edition The edition number
     * @return tokenId The real id which is a combination of the original id and edition number
     */
    function _getRealTokenId(uint256 id, uint256 edition) internal pure returns (uint256) {
        return id * REAL_ID_MULTIPLIER + edition;
    }

    /**
     * @notice
     * Internal function to get the original artwork id from the _actual_ artwork id
     *
     * @param realId The artwork id including the edition number
     * @return id The original artwork id e.g. 1, 2, 3
     */
    function _getIdFromRealTokenId(uint256 realId) internal pure returns (uint256) {
        return realId / REAL_ID_MULTIPLIER;
    }

    /**
     * @notice
     * Internal function to get the edition number from the _actual_ artwork id
     *
     * @param realId The artwork id including the edition number
     * @return edition The edition number
     */
    function _getEditionFromRealTokenId(uint256 realId) internal pure returns (uint256) {
        return realId % REAL_ID_MULTIPLIER;
    }

    /* ------------------------------------------------------------------------
       E R C - 7 2 1
    ------------------------------------------------------------------------ */

    /**
     * @notice Overrides {ERC721.ownerOf} to return the artist for minted and unsold editions
     * @param id The real artwork id including the edition number
     */
    function ownerOf(uint256 id) public view override returns (address owner) {
        owner = _ownerOf[id];
        if (owner == address(0)) {
            uint256 originalId = _getIdFromRealTokenId(id);
            require(originalId > 0 && originalId < nextId, "NOT_MINTED");
            require(tokenBurned[id] == false, "BURNED");
            owner = artist;
        }
    }

    /**
     * @notice Burns an NFT
     * @param id The real artwork id including the edition number
     */
    function burn(uint256 id) external {
        require(_ownerOf[id] == msg.sender, "NOT_OWNER");
        _burn(id);
        tokenBurned[id] = true;
        ++burned;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function totalSupply() external view returns (uint256) {
        return ((nextId - 1) * EDITION_SIZE) - burned;
    }
}