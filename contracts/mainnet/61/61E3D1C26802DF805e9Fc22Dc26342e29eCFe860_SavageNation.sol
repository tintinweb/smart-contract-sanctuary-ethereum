// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
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
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
* @dev Required interface of an ERC173 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-173[EIP].
*/
interface IERC173 /* is IERC165 */ {
    /// @dev This emits when ownership of a contract changes.    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view external returns(address);
	
    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract    
    function transferOwnership(address _newOwner) external;	
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity 0.8.17;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is IERC165 */ {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer( address indexed from_, address indexed to_, uint256 indexed tokenId_ );

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval( address indexed owner_, address indexed approved_, uint256 indexed tokenId_ );

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll( address indexed owner_, address indexed operator_, bool approved_ );

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner_ An address for whom to query the balance
  /// @return The number of NFTs owned by `owner_`, possibly zero
  function balanceOf( address owner_ ) external view returns ( uint256 );

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId_ The identifier for an NFT
  /// @return The address of the owner of the NFT
  function ownerOf( uint256 tokenId_ ) external view returns ( address );

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from_` is
  ///  not the current owner. Throws if `to_` is the zero address. Throws if
  ///  `tokenId_` is not a valid NFT. When transfer is complete, this function
  ///  checks if `to_` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `to_` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  /// @param data_ Additional data with no specified format, sent in call to `to_`
  function safeTransferFrom( address from_, address to_, uint256 tokenId_, bytes calldata data_ ) external;

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  function safeTransferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `to_` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from_` is
  ///  not the current owner. Throws if `to_` is the zero address. Throws if
  ///  `tokenId_` is not a valid NFT.
  /// @param from_ The current owner of the NFT
  /// @param to_ The new owner
  /// @param tokenId_ The NFT to transfer
  function transferFrom( address from_, address to_, uint256 tokenId_ ) external;

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param approved_ The new approved NFT controller
  /// @param tokenId_ The NFT to approve
  function approve( address approved_, uint256 tokenId_ ) external;

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `msg.sender`'s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param operator_ Address to add to the set of authorized operators
  /// @param approved_ True if the operator is approved, false to revoke approval
  function setApprovalForAll( address operator_, bool approved_ ) external;

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `tokenId_` is not a valid NFT.
  /// @param tokenId_ The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved( uint256 tokenId_ ) external view returns ( address );

  /// @notice Query if an address is an authorized operator for another address
  /// @param owner_ The address that owns the NFTs
  /// @param operator_ The address that acts on behalf of the owner
  /// @return True if `operator_` is an approved operator for `owner_`, false otherwise
  function isApprovedForAll( address owner_, address operator_ ) external view returns ( bool );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is IERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns ( uint256 );

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `index_` >= `totalSupply()`.
    /// @param index_ A counter less than `totalSupply()`
    /// @return The token identifier for the `index_`th NFT,
    ///  (sort order not specified)
    function tokenByIndex( uint256 index_ ) external view returns ( uint256 );

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `index_` >= `balanceOf(owner_)` or if
    ///  `owner_` is the zero address, representing invalid NFTs.
    /// @param owner_ An address where we are interested in NFTs owned by them
    /// @param index_ A counter less than `balanceOf(owner_)`
    /// @return The token identifier for the `index_`th NFT assigned to `owner_`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex( address owner_, uint256 index_ ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC721Errors {
  /**
  * @dev Thrown when `operator` has not been approved to manage `tokenId` on behalf of `tokenOwner`.
  * 
  * @param tokenOwner : address owning the token
  * @param operator   : address trying to manage the token
  * @param tokenId    : identifier of the NFT being referenced
  */
  error IERC721_CALLER_NOT_APPROVED( address tokenOwner, address operator, uint256 tokenId );
  /**
  * @dev Thrown when `operator` tries to approve themselves for managing a token they own.
  * 
  * @param operator : address that is trying to approve themselves
  */
  error IERC721_INVALID_APPROVAL( address operator );
  /**
  * @dev Thrown when a token is being transferred to the zero address.
  */
  error IERC721_INVALID_TRANSFER();
  /**
  * @dev Thrown when a token is being transferred from an address that doesn't own it.
  * 
  * @param tokenOwner : address owning the token
  * @param from       : address that the NFT is being transferred from
  * @param tokenId    : identifier of the NFT being referenced
  */
  error IERC721_INVALID_TRANSFER_FROM( address tokenOwner, address from, uint256 tokenId );
  /**
  * @dev Thrown when the requested token doesn't exist.
  * 
  * @param tokenId : identifier of the NFT being referenced
  */
  error IERC721_NONEXISTANT_TOKEN( uint256 tokenId );
  /**
  * @dev Thrown when a token is being safely transferred to a contract unable to handle it.
  * 
  * @param receiver : address unable to receive the token
  */
  error IERC721_NON_ERC721_RECEIVER( address receiver );
  /**
  * @dev Thrown when trying to get the token at an index that doesn't exist.
  * 
  * @param index : the inexistant index
  */
  error IERC721Enumerable_INDEX_OUT_OF_BOUNDS( uint256 index );
  /**
  * @dev Thrown when trying to get the token owned by `tokenOwner` at an index that doesn't exist.
  * 
  * @param tokenOwner : address owning the token
  * @param index      : the inexistant index
  */
  error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS( address tokenOwner, uint256 index );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is IERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns ( string memory _name );

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns ( string memory _symbol );

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI( uint256 _tokenId ) external view returns ( string memory );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721Receiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param operator_ The address which called `safeTransferFrom` function
    /// @param from_ The address which previously owned the token
    /// @param tokenId_ The NFT identifier which is being transferred
    /// @param data_ Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received( address operator_, address from_, uint256 tokenId_, bytes calldata data_ ) external returns( bytes4 );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator)
        external
        view
        returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(address registrant, address subscription)
        external;

    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external;

    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    function subscribe(address registrant, address registrantToSubscribe)
        external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(address registrant)
        external
        returns (address[] memory);

    function subscriberAt(address registrant, uint256 index)
        external
        returns (address);

    function copyEntriesOf(address registrant, address registrantToCopy)
        external;

    function isOperatorFiltered(address registrant, address operator)
        external
        returns (bool);

    function isCodeHashOfFiltered(address registrant, address operatorWithCode)
        external
        returns (bool);

    function isCodeHashFiltered(address registrant, bytes32 codeHash)
        external
        returns (bool);

    function filteredOperators(address addr)
        external
        returns (address[] memory);

    function filteredCodeHashes(address addr)
        external
        returns (bytes32[] memory);

    function filteredOperatorAt(address registrant, uint256 index)
        external
        returns (address);

    function filteredCodeHashAt(address registrant, uint256 index)
        external
        returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !(operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                ) &&
                    operatorFilterRegistry.isOperatorAllowed(
                        address(this),
                        from
                    ))
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

/**
 * Author: Lambdalf the White
 */

pragma solidity 0.8.17;

import "./interfaces/IERC721Errors.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Enumerable.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Receiver.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 * This contract features:
 * ~ Very Cheap batch minting
 * ~ Token tracker support
 *
 * Note: This implementation imposes a very expensive `balanceOf()` and `ownerOf()`.
 * It is not recommended to interract with those from another contract.
 */
abstract contract Reg_ERC721Batch is
    IERC721Errors,
    IERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    uint256 private _nextId = 1;
    string public name;
    string public symbol;

    // Mapping from token ID to approved address
    mapping(uint256 => address) public getApproved;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // List of owner addresses
    mapping(uint256 => address) private _owners;

    // Token Base URI
    string private _baseURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __init_ERC721Metadata(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal {
        name = name_;
        symbol = symbol_;
        _baseURI = baseURI_;
    }

    // **************************************
    // *****          MODIFIER          *****
    // **************************************
    /**
     * @dev Ensures the token exist.
     * A token exists if it has been minted and is not owned by the null address.
     *
     * @param tokenId_ : identifier of the NFT being referenced
     */
    modifier exists(uint256 tokenId_) {
        if (!_exists(tokenId_)) {
            revert IERC721_NONEXISTANT_TOKEN(tokenId_);
        }
        _;
    }

    // **************************************

    // **************************************
    // *****          INTERNAL          *****
    // **************************************
    /**
     * @dev Internal function returning the number of tokens in `tokenOwner_`'s account.
     */
    function _balanceOf(address tokenOwner_)
        internal
        view
        virtual
        returns (uint256)
    {
        if (tokenOwner_ == address(0)) {
            return 0;
        }

        uint256 _count_ = 0;
        address _currentTokenOwner_;
        for (uint256 i = 1; i < _nextId; ++i) {
            if (_exists(i)) {
                if (_owners[i] != address(0)) {
                    _currentTokenOwner_ = _owners[i];
                }
                if (tokenOwner_ == _currentTokenOwner_) {
                    _count_++;
                }
            }
        }
        return _count_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        //
        // IMPORTANT
        // It is unsafe to assume that an address not flagged by this method
        // is an externally-owned account (EOA) and not a contract.
        //
        // Among others, the following types of addresses will not be flagged:
        //
        //  - an externally-owned account
        //  - a contract in construction
        //  - an address where a contract will be created
        //  - an address where a contract lived, but was destroyed
        uint256 _size_;
        assembly {
            _size_ := extcodesize(to_)
        }

        // If address is a contract, check that it is aware of how to handle ERC721 tokens
        if (_size_ > 0) {
            try
                IERC721Receiver(to_).onERC721Received(
                    msg.sender,
                    from_,
                    tokenId_,
                    data_
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert IERC721_NON_ERC721_RECEIVER(to_);
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function returning whether a token exists.
     * A token exists if it has been minted and is not owned by the null address.
     *
     * @param tokenId_ uint256 ID of the token to verify
     *
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        if (tokenId_ == 0) {
            return false;
        }
        return tokenId_ < _nextId;
    }

    /**
     * @dev Internal function returning whether `operator_` is allowed
     * to manage tokens on behalf of `tokenOwner_`.
     *
     * @param tokenOwner_ address that owns tokens
     * @param operator_ address that tries to manage tokens
     *
     * @return bool whether `operator_` is allowed to handle the token
     */
    function _isApprovedForAll(address tokenOwner_, address operator_)
        internal
        view
        virtual
        returns (bool)
    {
        return _operatorApprovals[tokenOwner_][operator_];
    }

    /**
     * @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
     *
     * Note: To avoid multiple checks for the same data, it is assumed that existence of `tokeId_`
     * has been verified prior via {_exists}
     * If it hasn't been verified, this function might panic
     *
     * @param operator_ address that tries to handle the token
     * @param tokenId_ uint256 ID of the token to be handled
     *
     * @return bool whether `operator_` is allowed to handle the token
     */
    function _isApprovedOrOwner(
        address tokenOwner_,
        address operator_,
        uint256 tokenId_
    ) internal view virtual returns (bool) {
        bool _isApproved_ = operator_ == tokenOwner_ ||
            operator_ == getApproved[tokenId_] ||
            _isApprovedForAll(tokenOwner_, operator_);
        return _isApproved_;
    }

    /**
     * @dev Mints `qty_` tokens and transfers them to `to_`.
     *
     * This internal function can be used to perform token minting.
     *
     * Emits one or more {Transfer} event.
     */
    function _mint(address to_, uint256 qty_) internal virtual {
        uint256 _firstToken_ = _nextId;
        uint256 _nextStart_ = _firstToken_ + qty_;
        uint256 _lastToken_ = _nextStart_ - 1;

        _owners[_firstToken_] = to_;
        if (_lastToken_ > _firstToken_) {
            _owners[_lastToken_] = to_;
        }
        _nextId = _nextStart_;

        if (!_checkOnERC721Received(address(0), to_, _firstToken_, "")) {
            revert IERC721_NON_ERC721_RECEIVER(to_);
        }

        for (uint256 i = _firstToken_; i < _nextStart_; ++i) {
            emit Transfer(address(0), to_, i);
        }
    }

    /**
     * @dev Internal function returning the owner of the `tokenId_` token.
     *
     * @param tokenId_ uint256 ID of the token to verify
     *
     * @return address the address of the token owner
     */
    function _ownerOf(uint256 tokenId_)
        internal
        view
        virtual
        returns (address)
    {
        uint256 _tokenId_ = tokenId_;
        address _tokenOwner_ = _owners[_tokenId_];
        while (_tokenOwner_ == address(0)) {
            _tokenId_--;
            _tokenOwner_ = _owners[_tokenId_];
        }

        return _tokenOwner_;
    }

    /**
     * @dev Internal function used to set the base URI of the collection.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function returning the total supply.
     */
    function _totalSupply() internal view virtual returns (uint256) {
        return supplyMinted();
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
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
     * @dev Transfers `tokenId_` from `from_` to `to_`.
     *
     * This internal function can be used to implement alternative mechanisms to perform
     * token transfer, such as signature-based, or token burning.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        getApproved[tokenId_] = address(0);
        uint256 _previousId_ = tokenId_ > 1 ? tokenId_ - 1 : 1;
        uint256 _nextId_ = tokenId_ + 1;
        bool _previousShouldUpdate_ = _previousId_ < tokenId_ &&
            _exists(_previousId_) &&
            _owners[_previousId_] == address(0);
        bool _nextShouldUpdate_ = _exists(_nextId_) &&
            _owners[_nextId_] == address(0);

        if (_previousShouldUpdate_) {
            _owners[_previousId_] = from_;
        }

        if (_nextShouldUpdate_) {
            _owners[_nextId_] = from_;
        }

        _owners[tokenId_] = to_;

        emit Transfer(from_, to_, tokenId_);
    }

    // **************************************

    // **************************************
    // *****           PUBLIC           *****
    // **************************************
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to_, uint256 tokenId_)
        public
        virtual
        exists(tokenId_)
    {
        address _operator_ = msg.sender;
        address _tokenOwner_ = _ownerOf(tokenId_);
        if (to_ == _tokenOwner_) {
            revert IERC721_INVALID_APPROVAL(to_);
        }

        bool _isApproved_ = _isApprovedOrOwner(
            _tokenOwner_,
            _operator_,
            tokenId_
        );
        if (!_isApproved_) {
            revert IERC721_CALLER_NOT_APPROVED(
                _tokenOwner_,
                _operator_,
                tokenId_
            );
        }

        getApproved[tokenId_] = to_;
        emit Approval(_tokenOwner_, to_, tokenId_);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *
     * Note: We can ignore `from_` as we can compare everything to the actual token owner,
     * but we cannot remove this parameter to stay in conformity with IERC721
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *
     * Note: We can ignore `from_` as we can compare everything to the actual token owner,
     * but we cannot remove this parameter to stay in conformity with IERC721
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual override {
        transferFrom(from_, to_, tokenId_);
        if (!_checkOnERC721Received(from_, to_, tokenId_, data_)) {
            revert IERC721_NON_ERC721_RECEIVER(to_);
        }
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator_, bool approved_)
        public
        virtual
        override
    {
        address _account_ = msg.sender;
        if (operator_ == _account_) {
            revert IERC721_INVALID_APPROVAL(operator_);
        }

        _operatorApprovals[_account_][operator_] = approved_;
        emit ApprovalForAll(_account_, operator_, approved_);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *
     * Note: We can ignore `from_` as we can compare everything to the actual token owner,
     * but we cannot remove this parameter to stay in conformity with IERC721
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual exists(tokenId_) {
        if (to_ == address(0)) {
            revert IERC721_INVALID_TRANSFER();
        }

        address _operator_ = msg.sender;
        address _tokenOwner_ = _ownerOf(tokenId_);
        if (from_ != _tokenOwner_) {
            revert IERC721_INVALID_TRANSFER_FROM(_tokenOwner_, from_, tokenId_);
        }

        bool _isApproved_ = _isApprovedOrOwner(
            _tokenOwner_,
            _operator_,
            tokenId_
        );
        if (!_isApproved_) {
            revert IERC721_CALLER_NOT_APPROVED(
                _tokenOwner_,
                _operator_,
                tokenId_
            );
        }

        _transfer(_tokenOwner_, to_, tokenId_);
    }

    // **************************************

    // **************************************
    // *****            VIEW            *****
    // **************************************
    /**
     * @dev Returns the number of tokens in `tokenOwner_`'s account.
     */
    function balanceOf(address tokenOwner_)
        public
        view
        virtual
        returns (uint256)
    {
        return _balanceOf(tokenOwner_);
    }

    /**
     * @dev Returns if the `operator_` is allowed to manage all of the assets of `tokenOwner_`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address tokenOwner_, address operator_)
        public
        view
        virtual
        returns (bool)
    {
        return _isApprovedForAll(tokenOwner_, operator_);
    }

    /**
     * @dev Returns the owner of the `tokenId_` token.
     *
     * Requirements:
     *
     * - `tokenId_` must exist.
     */
    function ownerOf(uint256 tokenId_)
        public
        view
        virtual
        exists(tokenId_)
        returns (address)
    {
        return _ownerOf(tokenId_);
    }

    /**
     * @dev Returns the total number of tokens minted
     *
     * @return uint256 the number of tokens that have been minted so far
     */
    function supplyMinted() public view virtual returns (uint256) {
        return _nextId - 1;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId_ == type(IERC721Enumerable).interfaceId ||
            interfaceId_ == type(IERC721Metadata).interfaceId ||
            interfaceId_ == type(IERC721).interfaceId ||
            interfaceId_ == type(IERC165).interfaceId;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (index_ >= supplyMinted()) {
            revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS(index_);
        }
        return index_ + 1;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address tokenOwner_, uint256 index_)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        if (index_ >= _balanceOf(tokenOwner_)) {
            revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS(
                tokenOwner_,
                index_
            );
        }

        uint256 _count_ = 0;
        for (uint256 i = 1; i < _nextId; i++) {
            if (_exists(i) && tokenOwner_ == _ownerOf(i)) {
                if (index_ == _count_) {
                    return i;
                }
                _count_++;
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        exists(tokenId_)
        returns (string memory)
    {
        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, _toString(tokenId_)))
                : _toString(tokenId_);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply();
    }
    // **************************************
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Contract by @AsteriaLabs
import "./Reg_ERC721Batch.sol";
import "./utils/Whitelist_Merkle.sol";
import "./utils/ERC173.sol";
import "./interfaces/DefaultOperatorFilterer.sol";

/// @title Savage Nation
/// @author Goku <@Suleman132446>
contract SavageNation is
    Reg_ERC721Batch,
    Whitelist_Merkle,
    ERC173,
    DefaultOperatorFilterer
{
    using MerkleProof for bytes32[];

    uint256 public whitelistPrice = 0.039 ether;
    uint256 public publicPrice = 0.059 ether;
    uint256 public maxPerWhitelist = 2;
    uint256 public maxPerPublic = 2;
    uint256 public maxSupply = 10000;

    /**
     @dev An enum representing the sale state
     */
    enum Sale {
        PAUSED,
        PRIVATE,
        PUBLIC
    }

    Sale public saleState = Sale.PAUSED;
    // Mapping of nft minted by a wallet in public
    mapping(address => uint256) public mintedPerWallet;

    // Modifier to allow only owner

    // Modifier to check the sale state
    modifier isSaleState(Sale sale_) {
        require(saleState == sale_, "Sale not active");
        _;
    }

    // Modifier to block the other contracts
    modifier blockContracts() {
        require(tx.origin == msg.sender, "No smart contracts are allowed");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) {
        __init_ERC721Metadata(name_, symbol_, baseURI_);
        _setOwner(msg.sender);
    }

    /**
     * @dev tranfer the funds from contract
     *
     * @param to_ : the address of the wallet to transfer the funds
     */
    function withdraw(address to_, uint amount_) public onlyOwner {
        uint256 _balance_ = address(this).balance;
        require(_balance_ > 0, "No balance to withdraw");
        require(amount_ <= _balance_, "Amount is not valid");
        address _recipient_ = payable(to_);
        (bool _success_, ) = _recipient_.call{value: amount_}("");
        require(_success_, "Transaction failed");
    }

    /**
     * @dev set the whiltelist price
     *
     * @param price_ : the price of whitelist mint
     */
    function setWhitelistPrice(uint256 price_) external onlyOwner {
        whitelistPrice = price_;
    }

    /**
     * @dev set the public mint price
     *
     * @param price_ : the price of public mint
     */
    function setPublicPrice(uint256 price_) external onlyOwner {
        publicPrice = price_;
    }

    /**
     * @dev set the mints per wallet in whitelist
     *
     * @param mints_ : the amount of for whitelist mint
     */
    function setMintsPerWhitelist(uint256 mints_) external onlyOwner {
        maxPerWhitelist = mints_;
    }

    /**
     * @dev set the mints per wallet in public
     *
     * @param mints_ : the amount of for public mint
     */
    function setMintsPerPublic(uint256 mints_) external onlyOwner {
        maxPerPublic = mints_;
    }

    /**
     * @dev set the max supply for collection
     *
     * @param supply_ : the amount for  supply
     */
    function setMaxSupply(uint256 supply_) external onlyOwner {
        uint _currentSupply_ = totalSupply();
        require(
            supply_ > _currentSupply_,
            "Max supply should be greater than current supply"
        );
        require(
            supply_ < maxSupply,
            "Max supply should be greater than previous max supply"
        );
        maxSupply = supply_;
    }

    /**
     * @dev set the merkle root for whitelist
     *
     * @param root_ : the merkle for whitelist
     */
    function setWhitelistRoot(bytes32 root_) external onlyOwner {
        _setWhitelist(root_);
    }

    /**
     * @dev set the base uri for collection
     *
     * @param baseURI_ : the base uri for collection
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @dev set the sale state
     *
     * @param sale_ : the new sale state
     */
    function setSaleState(Sale sale_) external onlyOwner {
        saleState = sale_;
    }

    /**
     * @dev mint the token in whitelist sale
     *
     * @param proof_ : the proof for verificaton
     * @param qty_ : the quantity of mint
     */
    function mintWhitelist(bytes32[] memory proof_, uint256 qty_)
        external
        payable
        blockContracts
        isSaleState(Sale.PRIVATE)
        isWhitelisted(msg.sender, proof_, maxPerWhitelist, qty_)
    {
        uint _supply_ = totalSupply();
        require(_supply_ + qty_ <= maxSupply, "Exceeds supply");
        require(
            msg.value == qty_ * whitelistPrice,
            "Ether sent is not correct"
        );
        _mint(msg.sender, qty_);
        _consumeWhitelist(msg.sender, qty_);
    }

    /**
     * @dev mint the token for airdrop
     *
     * @param qty_ : the quantity of mint
     * @param to_: the address to send to
     */
    function airdrop( uint256 qty_ , address to_) onlyOwner
        external
        payable
        blockContracts
    {
        uint _supply_ = totalSupply();
        require(_supply_ + qty_ <= maxSupply, "Exceeds supply");
        _mint(to_, qty_);
    }

    /**
     * @dev mint the token in public sale
     *
     * @param qty_ : the quantity of mint
     */
    function mintPublic(uint256 qty_)
        external
        payable
        blockContracts
        isSaleState(Sale.PUBLIC)
    {
        uint _supply_ = totalSupply();
        require(
            mintedPerWallet[msg.sender] + qty_ <= maxPerPublic,
            "Exceeds mint per wallet"
        );
        require(_supply_ + qty_ <= maxSupply, "Exceeds supply");
        require(msg.value == qty_ * publicPrice, "Ether sent is not correct");
        _mint(msg.sender, qty_);
        mintedPerWallet[msg.sender] += qty_;
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
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC173.sol";

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
abstract contract ERC173 is IERC173 {
	// Errors
  /**
  * @dev Thrown when `operator` is not the contract owner.
  * 
  * @param operator : address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER( address operator );

	// The owner of the contract
	address private _owner;

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		address _sender_ = msg.sender;
		if ( owner() != _sender_ ) {
			revert IERC173_NOT_OWNER( _sender_ );
		}
		_;
	}

	/**
	* @dev Sets the contract owner.
	* 
	* Note: This function needs to be called in the contract constructor to initialize the contract owner, 
	* if it is not, then parts of the contract might be non functional
	* 
	* @param owner_ : address that owns the contract
	*/
	function _setOwner( address owner_ ) internal {
		_owner = owner_;
	}

	/**
	* @dev Returns the address of the current contract owner.
	* 
	* @return address : the current contract owner
	*/
	function owner() public view virtual returns ( address ) {
		return _owner;
	}

	/**
	* @dev Transfers ownership of the contract to `newOwner_`.
	* 
	* @param newOwner_ : address of the new contract owner
	* 
	* Requirements:
	* 
  * - Caller must be the contract owner.
	*/
	function transferOwnership( address newOwner_ ) public virtual onlyOwner {
		address _oldOwner_ = _owner;
		_owner = newOwner_;
		emit OwnershipTransferred( _oldOwner_, newOwner_ );
	}
}

// SPDX-License-Identifier: MIT

/**
 * Author: Lambdalf the White
 * Edit  : Squeebo
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Whitelist_Merkle {
    // Errors
    /**
     * @dev Thrown when trying to query the whitelist while it's not set
     */
    error Whitelist_NOT_SET();
    /**
     * @dev Thrown when `account` has consumed their alloted access and tries to query more
     *
     * @param account : address trying to access the whitelist
     */
    error Whitelist_CONSUMED(address account);
    /**
     * @dev Thrown when `account` does not have enough alloted access to fulfil their query
     *
     * @param account : address trying to access the whitelist
     */
    error Whitelist_FORBIDDEN(address account);

    bytes32 private _root;
    mapping(address => uint256) private _consumed;

    /**
     * @dev Ensures that `account_` has `qty_` alloted access on the whitelist.
     *
     * @param account_ : the address to validate access
     * @param proof_   : the Merkle proof to validate whitelist allocation
     * @param alloted_ : the max amount of whitelist spots allocated
     * @param qty_     : the amount of whitelist access requested
     */
    modifier isWhitelisted(
        address account_,
        bytes32[] memory proof_,
        uint256 alloted_,
        uint256 qty_
    ) {
        if (qty_ > alloted_) {
            revert Whitelist_FORBIDDEN(account_);
        }

        uint256 _allowed_ = checkWhitelistAllowance(account_, proof_, alloted_);

        if (_allowed_ < qty_) {
            revert Whitelist_FORBIDDEN(account_);
        }

        _;
    }

    /**
     * @dev Internal function setting the pass to protect the whitelist.
     *
     * @param root_ : the Merkle root to hold the whitelist
     */
    function _setWhitelist(bytes32 root_) internal virtual {
        _root = root_;
    }

    /**
     * @dev Returns the amount that `account_` is allowed to access from the whitelist.
     *
     * @param account_ : the address to validate access
     * @param proof_   : the Merkle proof to validate whitelist allocation
     *
     * @return uint256 : the total amount of whitelist allocation remaining for `account_`
     *
     * Requirements:
     *
     * - `_root` must be set.
     */
    function checkWhitelistAllowance(
        address account_,
        bytes32[] memory proof_,
        uint256 alloted_
    ) public view returns (uint256) {
        if (_root == 0) {
            revert Whitelist_NOT_SET();
        }

        if (_consumed[account_] >= alloted_) {
            revert Whitelist_CONSUMED(account_);
        }

        if (!_computeProof(account_, proof_)) {
            revert Whitelist_FORBIDDEN(account_);
        }

        uint256 _res_;
        unchecked {
            _res_ = alloted_ - _consumed[account_];
        }

        return _res_;
    }

    /**
     * @dev Processes the Merkle proof to determine if `account_` is whitelisted.
     *
     * @param account_ : the address to validate access
     * @param proof_   : the Merkle proof to validate whitelist allocation
     *
     * @return bool : whether `account_` is whitelisted or not
     */
    function _computeProof(address account_, bytes32[] memory proof_)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(account_));
        return MerkleProof.processProof(proof_, leaf) == _root;
    }

    /**
     * @dev Consumes `amount_` whitelist access passes from `account_`.
     *
     * @param account_ : the address to consume access from
     *
     * Note: Before calling this function, eligibility should be checked through {Whitelistable-checkWhitelistAllowance}.
     */
    function _consumeWhitelist(address account_, uint256 qty_) internal {
        unchecked {
            _consumed[account_] += qty_;
        }
    }
}