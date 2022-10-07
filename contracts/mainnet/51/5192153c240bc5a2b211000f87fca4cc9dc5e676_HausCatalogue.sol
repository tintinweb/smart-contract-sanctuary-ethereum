pragma solidity ^0.8.4;

import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {Ownable} from "./lib/utils/Ownable.sol";
import {UUPS} from "./lib/proxy/UUPS.sol";
import {ERC721} from "./lib/token/ERC721.sol";

/**
--------------------------------------------------------------------------------------------------------------------

 :::      :::  === :::===== ::: :::====  :::  === :::====  :::  === :::===
 :::      :::  === :::      ::: :::  === :::  === :::  === :::  === :::
 ===      ===  === ===      === ===  === ======== ======== ===  ===  =====
 ===      ===  === ===      === ===  === ===  === ===  === ===  ===     ===
 ========  ======   ======= === =======  ===  === ===  ===  ======  ======



 :::===== :::====  :::==== :::====  :::      :::====  :::=====  :::  === :::=====
 :::      :::  === :::==== :::  === :::      :::  === :::       :::  === :::
 ===      ========   ===   ======== ===      ===  === === ===== ===  === ======
 ===      ===  ===   ===   ===  === ===      ===  === ===   === ===  === ===
  ======= ===  ===   ===   ===  === ========  ======   =======   ======  ========

---------------------------------------------------------------------------------------------------------------------                                                                                                                                                                                                                                                                                                                           

@title                      :   LucidHaus Catalogue
@author                     :   @taayyohh
@dev                        :   The LucidHaus Catalogue Shared Creator Contract is an upgradeable ERC721 contract,
                                purpose built to facilitate the creation of  LucidHaus Catalogue Releases.
                                Upgradeable ERC721 Contract, inherits functionality from ERC721Upgradeable.
                                This contract conforms to the EIP-2981 NFT Royalty Standard.

---------------------------------------------------------------------------------------------------------------------    
 */
contract HausCatalogue is ERC721, IERC2981Upgradeable, UUPS, Ownable {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /*

    EVENTS

  */

  event CreatorUpdated(uint256 indexed tokenId, address indexed creator);
  event ContentUpdated(uint256 indexed tokenId, bytes32 indexed contentHash, string contentURI);
  event MetadataUpdated(uint256 indexed tokenId, string metadataURI);
  event MerkleRootUpdated(bytes32 indexed merkleRoot);
  event RoyaltyUpdated(uint256 indexed tokenId, address indexed payoutAddress);

  /*
  
    STATE/STORAGE/CALLDATA
  
  */

  /// @notice Storage for readable properties of a Catalog NFT
  /// @param metadataURI URI of the metadata (ipfs://)
  /// @param creator Address of the creator
  /// @param royaltyPayout payout address for royalties (EIP2981)
  /// @param royaltyBPS royalty percentage (in basis points)
  /// @dev this struct is used to store the readable properties of a Catalog NFT
  struct TokenData {
    string metadataURI;
    address creator;
    address royaltyPayout;
    uint16 royaltyBPS;
  }

  /// @notice Calldata struct for input ContentData
  /// @param contentURI URI of the content (ipfs://)
  /// @param contentHash SHA256 hash of the content
  /// @dev this struct is not stored in storage, only used to emit events via input calldata
  struct ContentData {
    string contentURI;
    bytes32 contentHash;
  }

  /// Mapping and Storage
  mapping(uint256 => TokenData) private tokenData;
  /// Tracking tokenIds
  CountersUpgradeable.Counter private _tokenIdCounter;
  /// Merkle Root
  bytes32 public merkleRoot;

  /*

        INITIALIZATION

        @notice Initializes contract with default values
        @param _name name of the contract
        @param _symbol symbol of the contract
        @dev contains constructor logic, initializes proxied contract. must be called upon deployment.

   */
  function initialize(
    string memory _name,
    string memory _symbol,
    address _owner
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init(_owner);

    /// Start tokenId @ 1
    _tokenIdCounter.increment();
  }

  /*
        BURN

        @notice Burns a token, given input tokenId
        @param _tokenId identifier of token to burn
        @dev burns given tokenId, restricted to creator (when owned)
 */

  function burn(uint256 _tokenId) external {
    require((msg.sender == tokenData[_tokenId].creator && msg.sender == ownerOf(_tokenId)), "Only creator");
    _burn(_tokenId);
  }

  /*

      MINT

        @notice mints a new token
        @param _data input TokenData struct, containing metadataURI, creator, royaltyPayout, royaltyBPS
        @param _content input ContentData struct, containing contentURI, contentHash.
        @param _proof merkle proof for the artist address.
        @return tokenId of the minted token
        @dev mints a new token to msg.sender with a valid input creator address proof. Emits a ContentUpdated event to track contentURI/contentHash updates.
     */
  function mint(
    TokenData calldata _data,
    ContentData calldata _content,
    bytes32[] calldata _proof
  ) external returns (uint256) {
    require(
      MerkleProofUpgradeable.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_data.creator))),
      "!valid proof"
    );
    require(_data.royaltyBPS < 10000, "royalty !< 10000");

    uint256 tokenId = _tokenIdCounter.current();

    _mint(msg.sender, tokenId);
    tokenData[tokenId] = _data;

    // Emit event to track ContentURI
    emit ContentUpdated(tokenId, _content.contentHash, _content.contentURI);

    _tokenIdCounter.increment();
    return tokenId;
  }

  /*

        WRITE

        @notice Emits an event to be used to track content updates on a token
        @param _tokenId token id corresponding to the token to update
        @param _content struct containing new/updated contentURI and hash.
        @dev access controlled function, restricted to owner/admin.
   */

  function updateContentURI(uint256 _tokenId, ContentData calldata _content) external onlyOwner {
    emit ContentUpdated(_tokenId, _content.contentHash, _content.contentURI);
  }

  /**
        @notice updates the creator of a token, emits an event
        @param _tokenId token id corresponding to the token to update
        @param _creator address new creator of the token
        @dev access controlled function, restricted to owner/admin. used in case of compromised artist wallet.
   */
  function updateCreator(uint256 _tokenId, address _creator) external onlyOwner {
    emit CreatorUpdated(_tokenId, _creator);
    tokenData[_tokenId].creator = _creator;
  }

  /**
        @notice updates the merkle root of the allowlist
        @param _newRoot containing the new root hash, generated off-chain
        @dev access controlled function, restricted to owner/admin.
   */
  function updateRoot(bytes32 _newRoot) external onlyOwner {
    emit MerkleRootUpdated(_newRoot);
    merkleRoot = _newRoot;
  }

  /*
        @notice updates the metadata URI of a token, emits an event
        @param _tokenId token id corresponding to the token to update
        @param _metadataURI string containing new/updated metadata (e.g IPFS URI pointing to metadata.json)
        @dev access controlled, restricted to creator of token
   */
  function updateMetadataURI(uint256 _tokenId, string memory _metadataURI) external {
    require(msg.sender == tokenData[_tokenId].creator, "!creator");
    emit MetadataUpdated(_tokenId, _metadataURI);
    tokenData[_tokenId].metadataURI = _metadataURI;
  }

  /*
        @notice updates the royalty payout address and royalty BPS of a token, emits an event
        @param _tokenId token id corresponding to the token of which to update royalty payout
        @param _royaltyPayoutAddress address of new royalty payout address
        @dev access controlled to owner only. this function allows for emergency royalty control (i.e compromised wallet)
   */
  function updateRoyaltyInfo(uint256 _tokenId, address _royaltyPayoutAddress) external onlyOwner {
    emit RoyaltyUpdated(_tokenId, _royaltyPayoutAddress);
    tokenData[_tokenId].royaltyPayout = _royaltyPayoutAddress;
  }

  /*

        READ

        @notice gets the creator address of a given tokenId
        @param _tokenId identifier of token to get creator for
        @return creator address of given tokenId
        @dev basic public getter method for creator
   */

  function creator(uint256 _tokenId) public view returns (address) {
    address c = tokenData[_tokenId].creator;
    return c;
  }

  /*

        @notice gets the address for the royalty payout of a token/record
        @param _tokenId identifier of token to get royalty payout address for
        @return royalty payout address of given tokenId
        @dev basic public getter method for royalty payout address

   */
  function royaltyPayoutAddress(uint256 _tokenId) public view returns (address) {
    address r = tokenData[_tokenId].royaltyPayout;
    return r;
  }

  /*

        OVERRIDES

        @notice override function gets royalty information for a token (EIP-2981)
        @param _tokenId token id corresponding to the token of which to get royalty information
        @param _salePrice final sale price of token used to calculate royalty payout
        @dev conforms to EIP-2981
        @inheritdoc IERC2981Upgradeable
  */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (tokenData[_tokenId].royaltyPayout, (_salePrice * tokenData[_tokenId].royaltyBPS) / 10000);
  }

  /*
        @notice override function to check if contract supports given interface
        @param interfaceId id of interface to check
        @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(bytes4 _interfaceId) external pure override(ERC721, IERC165Upgradeable) returns (bool) {
    return
      _interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
      _interfaceId == 0x80ac58cd || // ERC721 Interface ID
      _interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID
  }

  /*
        @notice override function to get the URI of a token.
        @param _tokenId token id corresponding to the token of which to get metadata from
        @return string containing metadata URI (example: 'ipfs:///...')
        @dev override function, returns metadataURI of token stored in tokenData
   */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    return tokenData[_tokenId].metadataURI;
  }

  /*
        @notice override of UUPSUpgradeable authorizeUpgrade function.
        @param newImplementation address of the new implementation contract
        @dev access controlled to owner only, upgrades deployed proxy to input implementation. Can be modified to support different authorization schemes.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
library CountersUpgradeable {
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
library MerkleProofUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IOwnable } from "../interfaces/IOwnable.sol";
import { Initializable } from "../utils/Initializable.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (access/OwnableUpgradeable.sol)
/// - Uses custom errors declared in IOwnable
/// - Adds optional two-step ownership transfer (`safeTransferOwnership` + `acceptOwnership`)
abstract contract Ownable is IOwnable, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev The address of the owner
    address internal _owner;

    /// @dev The address of the pending owner
    address internal _pendingOwner;

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures the caller is the owner
    modifier onlyOwner() {
        if (msg.sender != _owner) revert ONLY_OWNER();
        _;
    }

    /// @dev Ensures the caller is the pending owner
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes contract ownership
    /// @param _initialOwner The initial owner address
    function __Ownable_init(address _initialOwner) internal onlyInitializing {
        _owner = _initialOwner;

        emit OwnerUpdated(address(0), _initialOwner);
    }

    /// @notice The address of the owner
    function owner() public view returns (address) {
        return _owner;
    }

    /// @notice The address of the pending owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @notice Forces an ownership transfer
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param _newOwner The new owner address
    function safeTransferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;

        emit OwnerPending(_owner, _newOwner);
    }

    /// @notice Accepts an ownership transfer
    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(_owner, msg.sender);

        _owner = _pendingOwner;

        delete _pendingOwner;
    }

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() public onlyOwner {
        emit OwnerCanceled(_owner, _pendingOwner);

        delete _pendingOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IUUPS } from "../interfaces/IUUPS.sol";
import { ERC1967Upgrade } from "./ERC1967Upgrade.sol";

/// @title UUPS
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/UUPSUpgradeable.sol)
/// - Uses custom errors declared in IUUPS
/// - Inherits a modified ERC1967Upgrade
abstract contract UUPS is IUUPS, ERC1967Upgrade {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @dev The address of the implementation
    address private immutable __self = address(this);

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures that execution is via proxy delegatecall with the same implementation
    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    /// @dev Ensures that execution is via direct call
    modifier notDelegated() {
        if (address(this) != __self) revert CANNOT_DELEGATECALL();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Hook to authorize an implementation upgrade
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal virtual;

    /// @notice Upgrades to an implementation
    /// @param _newImpl The new implementation address
    function upgradeTo(address _newImpl) external onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, "", false);
    }

    /// @notice Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function upgradeToAndCall(address _newImpl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, _data, true);
    }

    /// @notice The storage slot of the implementation address
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC721 } from "../interfaces/IERC721.sol";
import { Initializable } from "../utils/Initializable.sol";
import { ERC721TokenReceiver } from "../utils/TokenReceiver.sol";
import { Address } from "../utils/Address.sol";

/// @title ERC721
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/ERC721Upgradeable.sol)
/// - Uses custom errors declared in IERC721
abstract contract ERC721 is IERC721, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @notice The token name
    string public name;

    /// @notice The token symbol
    string public symbol;

    /// @notice The token owners
    /// @dev ERC-721 token id => Owner
    mapping(uint256 => address) internal owners;

    /// @notice The owner balances
    /// @dev Owner => Balance
    mapping(address => uint256) internal balances;

    /// @notice The token approvals
    /// @dev ERC-721 token id => Manager
    mapping(uint256 => address) internal tokenApprovals;

    /// @notice The balance approvals
    /// @dev Owner => Operator => Approved
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes an ERC-721 token
    /// @param _name The ERC-721 token name
    /// @param _symbol The ERC-721 token symbol
    function __ERC721_init(string memory _name, string memory _symbol) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    /// @notice The Uniform Resource Identifier (URI) for a token
    /// @param _tokenId The ERC-721 token id
    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {}

    /// @notice The Uniform Resource Identifier (URI) for a contract
    function contractURI() public view virtual returns (string memory) {}

    /// @notice If the contract implements an interface
    /// @param _interfaceId The interface id
    function supportsInterface(bytes4 _interfaceId) external pure virtual returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
            _interfaceId == 0x80ac58cd || // ERC721 Interface ID
            _interfaceId == 0x5b5e139f; // ERC721Metadata Interface ID
    }

    /// @notice The account approved to manage a token
    /// @param _tokenId The ERC-721 token id
    function getApproved(uint256 _tokenId) external view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /// @notice If an operator is authorized to manage all of an owner's tokens
    /// @param _owner The owner address
    /// @param _operator The operator address
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /// @notice The number of tokens owned
    /// @param _owner The owner address
    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) revert ADDRESS_ZERO();

        return balances[_owner];
    }

    /// @notice The owner of a token
    /// @param _tokenId The ERC-721 token id
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = owners[_tokenId];

        if (owner == address(0)) revert INVALID_OWNER();

        return owner;
    }

    /// @notice Authorizes an account to manage a token
    /// @param _to The account address
    /// @param _tokenId The ERC-721 token id
    function approve(address _to, uint256 _tokenId) external {
        address owner = owners[_tokenId];

        if (msg.sender != owner && !operatorApprovals[owner][msg.sender]) revert INVALID_APPROVAL();

        tokenApprovals[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }

    /// @notice Authorizes an account to manage all tokens
    /// @param _operator The account address
    /// @param _approved If permission is being given or removed
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Transfers a token from sender to recipient
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        if (_from != owners[_tokenId]) revert INVALID_OWNER();

        if (_to == address(0)) revert ADDRESS_ZERO();

        if (msg.sender != _from && !operatorApprovals[_from][msg.sender] && msg.sender != tokenApprovals[_tokenId]) revert INVALID_APPROVAL();

        _beforeTokenTransfer(_from, _to, _tokenId);

        unchecked {
            --balances[_from];

            ++balances[_to];
        }

        owners[_tokenId] = _to;

        delete tokenApprovals[_tokenId];

        emit Transfer(_from, _to, _tokenId);

        _afterTokenTransfer(_from, _to, _tokenId);
    }

    /// @notice Safe transfers a token from sender to recipient
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    /// @notice Safe transfers a token from sender to recipient with additional data
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external {
        transferFrom(_from, _to, _tokenId);

        if (
            Address.isContract(_to) &&
            ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) != ERC721TokenReceiver.onERC721Received.selector
        ) revert INVALID_RECIPIENT();
    }

    /// @dev Mints a token to a recipient
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _mint(address _to, uint256 _tokenId) internal virtual {
        if (_to == address(0)) revert ADDRESS_ZERO();

        if (owners[_tokenId] != address(0)) revert ALREADY_MINTED();

        _beforeTokenTransfer(address(0), _to, _tokenId);

        unchecked {
            ++balances[_to];
        }

        owners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);

        _afterTokenTransfer(address(0), _to, _tokenId);
    }

    /// @dev Burns a token to a recipient
    /// @param _tokenId The ERC-721 token id
    function _burn(uint256 _tokenId) internal virtual {
        address owner = owners[_tokenId];

        if (owner == address(0)) revert NOT_MINTED();

        _beforeTokenTransfer(owner, address(0), _tokenId);

        unchecked {
            --balances[owner];
        }

        delete owners[_tokenId];

        delete tokenApprovals[_tokenId];

        emit Transfer(owner, address(0), _tokenId);

        _afterTokenTransfer(owner, address(0), _tokenId);
    }

    /// @dev Hook called before a token transfer
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /// @dev Hook called after a token transfer
    /// @param _from The sender address
    /// @param _to The recipient address
    /// @param _tokenId The ERC-721 token id
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IOwnable
/// @author Rohan Kulkarni
/// @notice The external Ownable events, errors, and functions
interface IOwnable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();

    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;

    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IInitializable } from "../interfaces/IInitializable.sol";
import { Address } from "../utils/Address.sol";

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/Initializable.sol)
/// - Uses custom errors declared in IInitializable
abstract contract Initializable is IInitializable {
    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @dev Indicates the contract has been initialized
    uint8 internal _initialized;

    /// @dev Indicates the contract is being initialized
    bool internal _initializing;

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    /// @dev Ensures an initialization function is only called within an `initializer` or `reinitializer` function
    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    /// @dev Enables initializing upgradeable contracts
    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

        _initialized = 1;

        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;

            emit Initialized(1);
        }
    }

    /// @dev Enables initializer versioning
    /// @param _version The version to set
    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Prevents future initialization
    function _disableInitializers() internal virtual {
        if (_initializing) revert INITIALIZING();

        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;

            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { IERC1967Upgrade } from "./IERC1967Upgrade.sol";

/// @title IUUPS
/// @author Rohan Kulkarni
/// @notice The external UUPS errors and functions
interface IUUPS is IERC1967Upgrade, IERC1822Proxiable {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if not called directly
    error CANNOT_DELEGATECALL();

    /// @dev Reverts if not called via delegatecall
    error ONLY_DELEGATECALL();

    /// @dev Reverts if not called via proxy
    error ONLY_PROXY();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Upgrades to an implementation
    /// @param newImpl The new implementation address
    function upgradeTo(address newImpl) external;

    /// @notice Upgrades to an implementation with an additional function call
    /// @param newImpl The new implementation address
    /// @param data The encoded function call
    function upgradeToAndCall(address newImpl, bytes memory data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";

import { IERC1967Upgrade } from "../interfaces/IERC1967Upgrade.sol";
import { Address } from "../utils/Address.sol";

/// @title ERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Upgrade.sol)
/// - Uses custom errors declared in IERC1967Upgrade
/// - Removes ERC1967 admin and beacon support
abstract contract ERC1967Upgrade is IERC1967Upgrade {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.rollback')) - 1)
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Upgrades to an implementation with security checks for UUPS proxies and an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCallUUPS(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_newImpl);
        } else {
            try IERC1822Proxiable(_newImpl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert UNSUPPORTED_UUID();
            } catch {
                revert ONLY_UUPS();
            }

            _upgradeToAndCall(_newImpl, _data, _forceCall);
        }
    }

    /// @dev Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCall(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_newImpl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_newImpl, _data);
        }
    }

    /// @dev Performs an implementation upgrade
    /// @param _newImpl The new implementation address
    function _upgradeTo(address _newImpl) internal {
        _setImplementation(_newImpl);

        emit Upgraded(_newImpl);
    }

    /// @dev Stores the address of an implementation
    /// @param _impl The implementation address
    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_UPGRADE(_impl);

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    /// @dev The address of the current implementation
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IERC721
/// @author Rohan Kulkarni
/// @notice The external ERC721 events, errors, and functions
interface IERC721 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a token is transferred from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when an owner approves an account to manage a token
    /// @param owner The owner address
    /// @param approved The account address
    /// @param tokenId The ERC-721 token id
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @notice Emitted when an owner sets an approval for a spender to manage all tokens
    /// @param owner The owner address
    /// @param operator The spender address
    /// @param approved If the approval is being set or removed
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if a caller is not authorized to approve or transfer a token
    error INVALID_APPROVAL();

    /// @dev Reverts if a transfer is called with the incorrect token owner
    error INVALID_OWNER();

    /// @dev Reverts if a transfer is attempted to address(0)
    error INVALID_RECIPIENT();

    /// @dev Reverts if an existing token is called to be minted
    error ALREADY_MINTED();

    /// @dev Reverts if a non-existent token is called to be burned
    error NOT_MINTED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The number of tokens owned
    /// @param owner The owner address
    function balanceOf(address owner) external view returns (uint256);

    /// @notice The owner of a token
    /// @param tokenId The ERC-721 token id
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice The account approved to manage a token
    /// @param tokenId The ERC-721 token id
    function getApproved(uint256 tokenId) external view returns (address);

    /// @notice If an operator is authorized to manage all of an owner's tokens
    /// @param owner The owner address
    /// @param operator The operator address
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Authorizes an account to manage a token
    /// @param to The account address
    /// @param tokenId The ERC-721 token id
    function approve(address to, uint256 tokenId) external;

    /// @notice Authorizes an account to manage all tokens
    /// @param operator The account address
    /// @param approved If permission is being given or removed
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Safe transfers a token from sender to recipient with additional data
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    /// @param data The additional data sent in the call to the recipient
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /// @notice Safe transfers a token from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Transfers a token from sender to recipient
    /// @param from The sender address
    /// @param to The recipient address
    /// @param tokenId The ERC-721 token id
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC721/utils/ERC721Holder.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (token/ERC1155/utils/ERC1155Holder.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/Address.sol)
/// - Uses custom errors
/// - Adds toBytes32() util
library Address {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the target of a delegatecall is not a contract
    error INVALID_TARGET();

    /// @dev Reverts if a delegatecall has failed
    error DELEGATE_CALL_FAILED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Converts an address to bytes32
    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)) << 96);
    }

    /// @dev If an address is a contract
    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    /// @dev Performs a delegatecall on an address
    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    /// @dev Verifies a delegatecall was successful
    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IInitializable
/// @author Rohan Kulkarni
/// @notice The external Initializable events and errors
interface IInitializable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the contract has been initialized or reinitialized
    event Initialized(uint256 version);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if address(0) is incorrectly passed
    error ADDRESS_ZERO();

    /// @dev Reverts if attempting to disable initializers during initialization
    error INITIALIZING();

    /// @dev Reverts if calling an initialization function outside of initialization
    error NOT_INITIALIZING();

    /// @dev Reverts if attempting to reinitialize incorrectly
    error ALREADY_INITIALIZED();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice The external ERC1967Upgrade events and errors
interface IERC1967Upgrade {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the implementation is upgraded
    /// @param impl The address of the implementation
    event Upgraded(address impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);

    /// @dev Reverts if an implementation upgrade is not stored at the storage slot of the original
    error UNSUPPORTED_UUID();

    /// @dev Reverts if an implementation does not support ERC1822 proxiableUUID()
    error ONLY_UUPS();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}