// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../IWCNFTErrorCodes.sol";

contract EnglishAuctionHouse is IWCNFTErrorCodes {
    struct EnglishAuction {
        uint256 lotSize; // number of tokens to be sold
        uint256 highestBid; // current highest bid, in WEI
        uint256 outbidBuffer; // new bids must exceed highestBid by this, in WEI
        uint256 startTime; // unix timestamp in seconds at start of the auction
        uint256 endTime; // unix timestamp in seconds at the end of the auction
        address highestBidder; // current highest bidder
        bool settled; // flag to mark the auction as settled
    }

    uint256 public numberOfEnglishAuctions;
    uint256 private constant _MAXIMUM_START_DELAY = 1 weeks;
    uint256 private constant _MAXIMUM_DURATION = 1 weeks;
    uint256 private constant _MINIMUM_DURATION = 1 hours;
    uint256 private constant _MINIMUM_TIME_BUFFER = 2 hours; // cannot stop auction within 2 hours of end
    uint256 private _maxRefundGas = 2300; // max gas sent with refunds
    mapping(uint256 => EnglishAuction) internal _englishAuctions;

    /**************************************************************************
     * CUSTOM ERRORS
     */

    /// Bid must exceed the current highest bid, plus buffer price
    error BidTooLow();

    /// Auctions cannot be stopped within 2 hours of their end time
    error CannotStopAuction();

    /// attempting to initialize an auction that is already initialized
    error EnglishAuctionAlreadyInitialized();

    /// requested English auction has ended
    error EnglishAuctionHasEnded();

    /// The requested English auction is not currently accepting bids
    error EnglishAuctionIsNotBiddable();

    /// The requested English auction is not ended and settled
    error EnglishAuctionIsNotComplete();

    /// The requested English auction has already been settled
    error EnglishAuctionIsSettled();

    /**
     * The requested English auction has not ended. It is not
     * necessarily active, as the start may be delayed
     */
    error EnglishAuctionNotEnded();

    /// Duration cannot exceed _MAXIMUM_DURATION
    error ExceedsMaximumDuration();

    /// Cannot start too far in the future
    error ExceedsMaximumStartDelay();

    /// Duration must exceed _MINIMUM_DURATION
    error InsufficientDuration();

    /// The requested EnglishAuction does not exist in this contract
    error InvalidEnglishAuctionId();

    /**************************************************************************
     * EVENTS
     */

    /**
     * @dev emitted when an English auction is created
     * @param auctionId identifier for the English auction
     * @param lotSize number of tokens sold in this auction
     * @param startingBid initial bid in wei
     */
    event EnglishAuctionCreated(
        uint256 indexed auctionId,
        uint256 lotSize,
        uint256 startingBid
    );

    /**
     * @dev emitted when an English auction is started
     * @param auctionId identifier for the English auction
     * @param auctionStartTime unix timestamp in seconds of the auction start
     * @param auctionEndTime unix timestamp in seconds of the auction end
     */
    event EnglishAuctionStarted(
        uint256 indexed auctionId,
        uint256 auctionStartTime,
        uint256 auctionEndTime
    );

    /**
     * @dev emitted when an auction is settled
     * @param auctionId identifier for the English auction
     * @param salePrice strike price for the lot
     * @param lotSize number of tokens sold in this auction
     * @param winner address of the winning bidder
     */
    event EnglishAuctionSettled(
        uint256 indexed auctionId,
        uint256 salePrice,
        uint256 lotSize,
        address winner
    );

    /**
     * @dev emitted when an auction is force-stopped
     * @param auctionId identifier for the English auction
     * @param currentHighBidder address of the current leading bidder
     * @param currentHighestBid value in wei of the current highest bid
     */
    event EnglishAuctionForceStopped(
        uint256 indexed auctionId,
        address currentHighBidder,
        uint256 currentHighestBid
    );

    /**
     * @dev emitted when a new high bid is received
     * @param auctionId identifier for the English auction
     * @param bidder address of the new high bidder
     * @param bid value in wei of the new bid
     */
    event NewHighBid(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bid
    );

    /**
     * @dev emitted when an auto refund fails
     * @param auctionId identifier for the English auction
     * @param recipient address of the user whose refund has been lodged
     * @param amount amount in wei of the refund
     */
    event RefundLodged(
        uint256 indexed auctionId,
        address indexed recipient,
        uint256 amount
    );

    /**************************************************************************
     * GUARD FUNCTIONS - replace modifiers
     */

    /**
     * @dev reverts if a given English auction is not active
     * @param auctionId identifier for the English auction
     */
    function _revertIfEnglishAuctionNotValid(uint256 auctionId) internal view {
        if (auctionId == 0 || auctionId > numberOfEnglishAuctions) {
            revert InvalidEnglishAuctionId();
        }
    }

    /**************************************************************************
     * ADMIN FUNCTIONS - start, stop, edit, etc.
     */

    /**
     * @dev edit the maximum gas sent with refunds during an English Auction.
     *  Gas limit initialized to 2300, but modifiable in case of future need.
     *
     *  Refunds are sent when:
     *  i) a high-bidder is outbid (their bid is returned)
     *  ii) an English Auction is force-stopped (current leader is refunded)
     *
     *  If this is set too low, all refunds using _gasLimitedCall() will
     *  fail.
     * @param maxGas maximum gas units for the call
     */
    function _editMaxRefundGas(uint256 maxGas) internal {
        _maxRefundGas = maxGas;
    }

    /**
     * @dev set up a new English auction (ascending price auction). This does
     *  NOT start the auction.
     *
     * Start time and duration are set when auction is started with
     *  _startEnglishAuction().
     *
     * outbidBuffer is to prevent 1 wei increments on the winning bid, and is
     *  the minimum buffer new bids must exceed the current highest by.
     *
     * @param lotSize_ number of tokens to be sold in one bundle in this auction
     * @param startingBidInWei starting bid for the auction
     * @param outbidBufferInWei bids must exceed current highest by this price
     * @return auctionId sequential auction identifier, starting at 1.
     */
    function _setUpEnglishAuction(
        uint256 lotSize_,
        uint256 startingBidInWei,
        uint256 outbidBufferInWei
    )
        internal
        returns (uint256)
    {
        // set up new auction - auctionId initializes to 1
        uint256 auctionId = ++numberOfEnglishAuctions;

        EnglishAuction storage ea = _englishAuctions[auctionId];
        ea.lotSize = lotSize_;
        ea.highestBid = startingBidInWei;
        ea.outbidBuffer = outbidBufferInWei;

        emit EnglishAuctionCreated(auctionId, lotSize_, startingBidInWei);

        return auctionId;
    }

    /**
     * @dev start an English auction which has been set up already.
     * @param auctionId the auction to start
     * @param startDelayInSeconds set 0 to start immediately, or delay the start
     * @param durationInSeconds the number of seconds the auction will run for
     */
    function _startEnglishAuction(
        uint256 auctionId,
        uint256 startDelayInSeconds,
        uint256 durationInSeconds
    )
        internal
    {
        _revertIfEnglishAuctionNotValid(auctionId);

        EnglishAuction storage ea = _englishAuctions[auctionId];

        // check the auction has not been initialized yet
        if (ea.startTime != 0 && ea.endTime != 0) {
            revert EnglishAuctionAlreadyInitialized();
        }

        if (startDelayInSeconds > _MAXIMUM_START_DELAY) {
            revert ExceedsMaximumStartDelay();
        }

        if (durationInSeconds < _MINIMUM_DURATION) {
            revert InsufficientDuration();
        }

        if (durationInSeconds > _MAXIMUM_DURATION) {
            revert ExceedsMaximumDuration();
        }

        // get the start time
        uint256 startTime_ = block.timestamp + startDelayInSeconds;
        uint256 endTime_ = startTime_ + durationInSeconds;

        ea.startTime = startTime_;
        ea.endTime = endTime_;

        emit EnglishAuctionStarted(auctionId, startTime_, endTime_);
    }

    /**
     * @dev force stop an English auction, useful if incorrect parameters
     *  were set by mistake. To protect bidders, this cannot be used within 2
     *  hours of an auction's end time.
     * @param auctionId identifier for the auction
     */
    function _forceStopEnglishAuction(uint256 auctionId) internal {
        _revertIfEnglishAuctionNotValid(auctionId);

        EnglishAuction storage ea = _englishAuctions[auctionId];

        // if the auction has started, check there is longer than 2 hours left
        if (ea.endTime != 0) {
            if (block.timestamp >= ea.endTime) {
                revert EnglishAuctionHasEnded();
            }
            if (block.timestamp > (ea.endTime - _MINIMUM_TIME_BUFFER)) {
                revert CannotStopAuction();
            }
        }

        // end the auction
        ea.endTime = block.timestamp;
        ea.settled = true;

        // return eth to highest bidder
        address currentHighBidder = ea.highestBidder;
        uint256 currentBid = ea.highestBid;
        ea.highestBid = 0;

        if (currentHighBidder != address(0)) {
            bool refundSuccess = _gasLimitedCall(currentHighBidder, currentBid);
            if (!refundSuccess) {
                // register the failed refund
                emit RefundLodged(auctionId, currentHighBidder, currentBid);
            }
        }

        emit EnglishAuctionForceStopped(
            auctionId,
            currentHighBidder,
            currentBid
        );
    }

    /**
     * @dev checks an auction has ended, then marks it as settled, emitting an
     *  event. Set this when all accounting has been completed to block multiple
     *  claims, e.g. the winner receives their token, all refunds are sent etc.
     * @param auctionId identifier for the auction
     */
    function _markSettled(uint256 auctionId) internal {
        _revertIfEnglishAuctionNotValid(auctionId);

        if (!_englishAuctionEnded(auctionId)) {
            revert EnglishAuctionNotEnded();
        }

        EnglishAuction storage ea = _englishAuctions[auctionId];

        if (ea.settled) revert EnglishAuctionIsSettled();
        ea.settled = true;

        emit EnglishAuctionSettled(
            auctionId,
            ea.highestBid,
            ea.lotSize,
            ea.highestBidder
        );
    }

    /**************************************************************************
     * ACCESS FUNCTIONS - get information
     */

    /**
     * @dev get structured information about an English auction. If all entries
     *  are zero or false, the auction with this ID may not have been created.
     * @param auctionId the auction id to query
     * @return EnglishAuction structured information about the auction,
     *  returned as a tuple.
     */
    function getEnglishAuctionInfo(uint256 auctionId)
        public
        view
        returns (EnglishAuction memory)
    {
        return _englishAuctions[auctionId];
    }

    /**
     * @notice get the minimum bid to become the highest bidder on
     *   an English auction. This does not check if auction is active or ended.
     * @param auctionId identifier for the auction
     * @return minimumBid minimum bid to become the highest bidder
     */
    function getEnglishAuctionMinimumBid(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        _revertIfEnglishAuctionNotValid(auctionId);

        EnglishAuction storage ea = _englishAuctions[auctionId];
        return ea.highestBid + ea.outbidBuffer;
    }

    /**
     * @dev return the time remaining in an English auction.
     *  Does not check if the auction has been initialized and will
     *  return 0 if it does not exist.
     * @param auctionId the auctionId to query
     * @return remainingTime the time remaining in seconds
     */
    function getRemainingEnglishAuctionTime(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        uint256 endTime_ = _englishAuctions[auctionId].endTime;
        uint256 remaining = endTime_ <= block.timestamp
            ? 0
            : endTime_ - block.timestamp;

        return remaining;
    }

    /**************************************************************************
     * OPERATION
     */

    /**
     * @notice bid on an English auction. If you are the highest bidder already
     *  extra bids are added to your current bid. All bids are final and cannot
     *  be revoked.
     *
     * NOTE: if bidding from a contract ensure it can use any tokens received.
     *  This does not check onERC721Received().
     *
     * @param auctionId identifier for the auction
     */
    function _bidEnglish(uint256 auctionId) internal {
        _revertIfEnglishAuctionNotValid(auctionId);

        if (!englishAuctionBiddable(auctionId)) {
            revert EnglishAuctionIsNotBiddable();
        }

        EnglishAuction storage ea = _englishAuctions[auctionId];

        uint256 currentBid = ea.highestBid;
        address currentHighBidder = ea.highestBidder;

        /*
         * high bidder can add to their bid,
         * new bidders must exceed existing high bid + buffer
         */
        if (msg.sender == currentHighBidder) {
            ea.highestBid = currentBid + msg.value;
            emit NewHighBid(auctionId, msg.sender, currentBid + msg.value);
        } else {
            // new bidder
            if (msg.value < currentBid + ea.outbidBuffer) {
                revert BidTooLow();
            } else {
                // we have a new highest bid
                ea.highestBid = msg.value;
                ea.highestBidder = msg.sender;
                emit NewHighBid(auctionId, msg.sender, msg.value);

                // refund the previous highest bidder.
                // This must not revert due to the receiver.
                if (currentHighBidder != address(0)) {
                    bool refundSuccess = _gasLimitedCall(
                        currentHighBidder,
                        currentBid
                    );
                    if (!refundSuccess) {
                        // register the failed refund
                        emit RefundLodged(
                            auctionId,
                            currentHighBidder,
                            currentBid
                        );
                    }
                }
            }
        }
    }

    /**
     * @dev send ETH, limiting gas and not reverting on failure.
     * @param receiver transaction recipient
     * @param amount value to send
     * @return success true if transaction is successful, false otherwise
     */
    function _gasLimitedCall(address receiver, uint256 amount)
        internal
        returns (bool)
    {
        (bool success, ) = receiver.call{value: amount, gas: _maxRefundGas}("");
        return success;
    }

    /**************************************************************************
     * HELPERS
     */

    /**
     * @dev returns true if an auction has been 'started' but has not ended.
     *  The auction may be pending (start time has been set in the future) or
     *  live-and-biddable (start time has passed and the auction is biddable).
     * @param auctionId identifier for the auction
     * @return active true (active / pending) or false (ended / not initialized)
     */
    function englishAuctionActive(uint256 auctionId)
        public
        view
        returns (bool)
    {
        // if ea.endTime == 0 : auction has not been started >> false
        // if ea.endTime <= block.timestamp : auction has ended >> false
        // if ea.endTime > block.timestamp : auction is pending or live >> true

        return (_englishAuctions[auctionId].endTime > block.timestamp);
    }

    /**
     * @dev returns true if an auction is currently live-and-biddable
     * @param auctionId identifier for the auction
     * @return biddable true (live-and-biddable) or false (ended / not started)
     */
    function englishAuctionBiddable(uint256 auctionId)
        public
        view
        returns (bool)
    {
        EnglishAuction storage ea = _englishAuctions[auctionId];

        return (
            ea.startTime <= block.timestamp &&
            block.timestamp < ea.endTime
        );
    }

    /**
     * @dev returns true if the requested auction has been settled,
     *  false otherwise.
     * @param auctionId identifier for the auction
     */
    function englishAuctionSettled(uint256 auctionId)
        public
        view
        returns (bool)
    {
        return _englishAuctions[auctionId].settled;
    }

    /**
     * @dev returns true if an auction has ended, false if it is still active,
     *  or not initialized.
     * @param auctionId identifier for the auction
     * @return ended true (ended / non-existent) or false (active / yet-to-begin)
     */
    function _englishAuctionEnded(uint256 auctionId)
        internal
        view
        returns (bool)
    {
        EnglishAuction storage ea = _englishAuctions[auctionId];

        // if ea.endTime == 0 : auction never started / does not exist >> false
        // else :
        // if ea.endTime <= block.timestamp : auction has ended >> true
        // if ea.endTime > block.timestamp : auction still active >> false

        return (ea.endTime != 0 && ea.endTime <= block.timestamp);
    }

    /**
     * @dev returns true if the requested auction has been started but is NOT
     *  settled. It may have ended, or may still be biddable but it has not
     *  been settled. Returns false if auction has not started or if it has
     *  been ended and settled.
     * @param auctionId identifier for the auction
     */
    function _englishAuctionActiveNotSettled(uint256 auctionId)
        internal
        view
        returns (bool)
    {
        EnglishAuction storage ea = _englishAuctions[auctionId];

        // if ea.endTime == 0 : auction never started / does not exist >> false
        // else: (the auction has been started)
        // if the auction is active >> true
        // if the auction is ended-but-not-settled >> true
        // if the auction is ended-and-settled >> false
        // if the auction is settled, it must already have ended
        
        return (ea.endTime != 0 && ea.settled == false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Utility contract for managing multiple allow lists under by the same
 * 4-parameter merkle root.
 *
 * Two keys are used to nest each allow list mint count.
 */
contract MerkleFourParams {
    bytes32 public merkleRoot; // merkle root governing all allow lists

    /**
     * @dev store the allow list mints per address, per two keys
     *  we map: (address => (key1 => (key2 => minted)))
     */
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _allowListMinted;

    bool internal _allowListActive = false;

    /**************************************************************************
     * CUSTOM ERRORS
     */

    /// Attempted access while allow list is active
    error AllowListIsActive();

    /// Attempted access to inactive presale
    error AllowListIsNotActive();

    /// Exceeds allow list quota
    error ExceedsAllowListQuota();

    /// Merkle proof and user do not resolve to merkleRoot
    error NotOnAllowList();

    /**************************************************************************
     * EVENTS
     */

    /**
     * @dev emitted when an account has claimed some tokens
     * @param account address of the claimer
     * @param key1 first key to the allow list
     * @param key2 second key to the allow list
     * @param amount number of tokens claimed in this transaction 
     */
    event Claimed(
        address indexed account,
        uint256 indexed key1,
        uint256 indexed key2,
        uint256 amount
    );

    /**
     * @dev emitted when the merkle root changes
     * @param merkleRoot new merkle root
     */
    event MerkleRootChanged(bytes32 merkleRoot);

    /**
     * @dev reverts when allow list is not active
     */
    modifier isAllowListActive() virtual {
        if (!_allowListActive) revert AllowListIsNotActive();
        _;
    }

    /**
     * @dev throws when number of tokens exceeds total token quota, for a
     *  given 2-key combination.
     * @param to user address to query
     * @param numberOfTokens check if this many tokens are available
     * @param tokenQuota the user's initial token allowance
     * @param key1 first key to the allow list
     * @param key2 second key to the allow list
     */
    modifier tokensAvailable(
        address to,
        uint256 numberOfTokens,
        uint256 tokenQuota,
        uint256 key1,
        uint256 key2
    ) virtual {
        uint256 claimed = _allowListMinted[to][key1][key2];
        if (claimed + numberOfTokens > tokenQuota) {
            revert ExceedsAllowListQuota();
        }
        _;
    }

    /**
     * @dev throws when parameters sent by claimer are incorrect
     * @param claimer the claimer's address
     * @param tokenQuota initial token allowance for claimer
     * @param key1 first key to the allow list
     * @param key2 second key to the allow list
     * @param proof merkle proof
     */
    modifier ableToClaim(
        address claimer,
        uint256 tokenQuota,
        uint256 key1,
        uint256 key2,
        bytes32[] memory proof
    ) virtual {
        if (!onAllowList(claimer, tokenQuota, key1, key2, proof)) {
            revert NotOnAllowList();
        }
        _;
    }

    /**
     * @dev sets the state of the allow list
     */
    function _setAllowListActive(bool allowListActive_) internal virtual {
        _allowListActive = allowListActive_;
    }

    /**
     * @dev sets the merkle root
     */
    function _setAllowList(bytes32 merkleRoot_) internal virtual {
        merkleRoot = merkleRoot_;

        emit MerkleRootChanged(merkleRoot);
    }

    /**
     * @dev gets the number of tokens minted by an address for given keys
     * @param from the address to query
     * @param key1 first key to the allow list
     * @param key2 second key to the allow list
     * @return minted the number of items minted by the address
     */
    function getAllowListMinted(
        address from,
        uint256 key1,
        uint256 key2
    ) public view virtual returns (uint256) {
        return _allowListMinted[from][key1][key2];
    }

    /**
     * @dev adds the number of tokens to an address's total for given keys
     * @param to the address to increment mints against
     * @param key1 first key to the allow list
     * @param key2 second key to the allow list
     * @param numberOfTokens the number of mints to increment
     */
    function _setAllowListMinted(
        address to,
        uint256 key1,
        uint256 key2,
        uint256 numberOfTokens
    ) internal virtual {
        _allowListMinted[to][key1][key2] += numberOfTokens;

        emit Claimed(to, key1, key2, numberOfTokens);
    }

    /**
     * @dev checks if the claimer has a valid proof
     * @param claimer the claimer's address
     * @param tokenQuota initial allow list quota for claimer
     * @param key1 first key to the allow list
     * @param key2 second key to the allow list
     * @return valid true if the claimer has a valid proof for these arguments
     */
    function onAllowList(
        address claimer,
        uint256 tokenQuota,
        uint256 key1,
        uint256 key2,
        bytes32[] memory proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(claimer, tokenQuota, key1, key2)
        );
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev Allows derived contracts to implement multiple parallel Dutch auctions,
 *  where the auction price decreases in steps.
 */
contract DutchAuctionHouse {
    struct DutchAuction {
        bool auctionActive; // flag to mark the auction active or inactive
        uint80 startTime; // set automatically when auction started
        uint80 duration; // time for price to drop from startPrice to finalPrice
        uint88 startPrice; // price declines from here
        uint88 finalPrice; // price rests here after declining
        uint88 priceStep; // price declines in this step size
        uint80 timeStepSeconds; // time between price drop steps
    }

    uint256 public numberOfDutchAuctions; // track number of auctions

    // Map auctionId => DutchAuction
    mapping(uint256 => DutchAuction) internal _dutchAuctions;

    // Track user mints per Dutch auction:
    // (auctionId => (address => mints))
    mapping(uint256 => mapping(address => uint256)) private _dutchAuctionMints;

    /**************************************************************************
     * CUSTOM ERRORS
     */

    /// The price and timestep parameters result in too great a duration
    error ComputedDurationOverflows();

    /// Attempting to resume a Dutch auction that has not started
    error DutchAuctionHasNotStarted();

    /// Attempted access to an active Dutch auction
    error DutchAuctionIsActive();

    /// Attempted mint on an inactive Dutch auction
    error DutchAuctionIsNotActive();

    /// Ensure auction prices, price steps and step interval are valid
    error InvalidDutchAuctionParameters();

    /// This auctionId has not been initialised yet
    error NonExistentDutchAuctionID();

    /**************************************************************************
     * EVENTS
     */

    /**
     * @dev emitted when a Dutch auction is created
     * @param auctionId identifier for the Dutch auction
     */
    event DutchAuctionCreated(uint256 auctionId);

    /**
     * @dev emitted when a Dutch auction starts
     * @param auctionId identifier for the Dutch auction
     * @param auctionStartTime unix timestamp in seconds of the auction start
     * @param auctionDuration auction duration in seconds
     */
    event DutchAuctionStart(
        uint256 indexed auctionId,
        uint80 auctionStartTime,
        uint80 auctionDuration
    );

    /**
     * @dev emitted when a Dutch auction ends
     * @param auctionId identifier for the Dutch auction
     * @param auctionEndTime unix timestamp in seconds of the auction end
     */
    event DutchAuctionEnd(uint256 indexed auctionId, uint256 auctionEndTime);

    /**************************************************************************
     * GUARD FUNCTIONS
     */

    /**
     * @dev reverts when an non-existent Dutch auction is requested
     * @param auctionId Dutch auction ID to query
     */
    function _revertIfDutchAuctionDoesNotExist(uint256 auctionId)
        internal
        view
    {
        if (auctionId == 0 || auctionId > numberOfDutchAuctions) {
            revert NonExistentDutchAuctionID();
        }
    }

    /**************************************************************************
     * FUNCTIONS
     */

    /**
     * @dev get structured information about a Dutch auction, returned as tuple
     * @param auctionId the Dutch auctionId to query.
     * @return auctionInfo information about the Dutch auction, struct returned
     *  as a tuple. See {struct DutchAuction} for details.
     */
    function getDutchAuctionInfo(uint256 auctionId)
        public
        view
        returns (DutchAuction memory)
    {
        return _dutchAuctions[auctionId];
    }

    /**
     * @notice get the number of mints by a user in a Dutch auction
     * @param auctionId the auction to query
     * @param user the minter address to query
     */
    function getDutchAuctionMints(uint256 auctionId, address user)
        public
        view
        returns (uint256)
    {
        return _dutchAuctionMints[auctionId][user];
    }

    /**
     * @dev calculates the current Dutch auction price. If not begun, returns
     *  the start price.
     * @param auctionId Dutch auction ID to query.
     * @return price current price in wei
     */
    function getDutchAuctionPrice(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        _revertIfDutchAuctionDoesNotExist(auctionId);

        DutchAuction storage a = _dutchAuctions[auctionId];
        uint256 elapsed = _getElapsedDutchAuctionTime(auctionId);

        if (elapsed >= a.duration) {
            return a.finalPrice;
        }

        // step function
        uint256 steps = elapsed / a.timeStepSeconds;
        uint256 auctionPriceDecrease = steps * a.priceStep;

        return a.startPrice - auctionPriceDecrease;
    }

    /**
     * @dev returns the remaining time until a Dutch auction's resting price is
     *  hit. If the sale has not started yet, the auction duration is returned.
     *
     * Returning "0" shows the price has reached its final value - the auction
     *  may still be biddable.
     *
     * Use _endDutchAuction() to stop the auction and prevent further bids.
     *
     * @param auctionId Dutch auction ID to query
     * @return remainingTime seconds until resting price is reached
     */
    function getRemainingDutchAuctionTime(uint256 auctionId)
        public
        view
        returns (uint256)
    {
        _revertIfDutchAuctionDoesNotExist(auctionId);

        DutchAuction storage a = _dutchAuctions[auctionId];

        if (a.startTime == 0) {
            // not started yet
            return a.duration;
        } else if (_getElapsedDutchAuctionTime(auctionId) >= a.duration) {
            // already at the resting price
            return 0;
        }

        return (a.startTime + a.duration) - block.timestamp;
    }

    /**
     * @notice check if the Dutch auction with ID auctionId is active
     * @param auctionId Dutch auction ID to query
     * @return bool true if the auction is active, false if not
     */
    function _checkDutchAuctionActive(uint256 auctionId)
        internal
        view
        returns (bool)
    {
        return _dutchAuctions[auctionId].auctionActive;
    }

    /**
     * @dev initialise a new Dutch auction and return its ID
     * @param startPrice_ starting price in wei
     * @param finalPrice_ final resting price in wei
     * @param priceStep_ incremental price decrease in wei
     * @param timeStepSeconds_ time between each price decrease in seconds
     * @return newAuctionId the new Dutch auction ID
     */
    function _createNewDutchAuction(
        uint88 startPrice_,
        uint88 finalPrice_,
        uint88 priceStep_,
        uint80 timeStepSeconds_
    ) internal returns (uint256) {
        if (
            startPrice_ < finalPrice_ ||
            (startPrice_ - finalPrice_) < priceStep_
        ) {
            revert InvalidDutchAuctionParameters();
        }

        uint256 newAuctionID = ++numberOfDutchAuctions; // start with ID 1

        // create and map a new DutchAuction
        DutchAuction storage newAuction = _dutchAuctions[newAuctionID];

        newAuction.startPrice = startPrice_;
        newAuction.finalPrice = finalPrice_;
        newAuction.priceStep = priceStep_;
        newAuction.timeStepSeconds = timeStepSeconds_;

        uint256 duration = Math.ceilDiv(
            (startPrice_ - finalPrice_),
            priceStep_
        ) * timeStepSeconds_;

        if (duration == 0) revert InvalidDutchAuctionParameters();
        if (duration > type(uint80).max) revert ComputedDurationOverflows();

        newAuction.duration = uint80(duration);

        emit DutchAuctionCreated(newAuctionID);
        return newAuctionID;
    }

    /**
     * @dev starts a Dutch auction and emits an event.
     *
     * If an auction has been ended with _endDutchAuction() this will reset the
     *  auction and start it again with all of its initial arguments.
     *
     * @param auctionId ID of the Dutch auction to start
     */
    function _startDutchAuction(uint256 auctionId) internal {
        _revertIfDutchAuctionDoesNotExist(auctionId);

        DutchAuction storage a = _dutchAuctions[auctionId];

        if (a.auctionActive) revert DutchAuctionIsActive();

        a.startTime = uint80(block.timestamp);
        a.auctionActive = true;

        emit DutchAuctionStart(auctionId, a.startTime, a.duration);
    }

    /**
     * @dev if a Dutch auction was paused using _endDutchAuction it can be
     *  resumed with this function. No time is added to the duration so all
     *  elapsed time during the pause is lost.
     *
     * To restart a stopped Dutch auction from the startPrice with its full
     * duration, use _startDutchAuction() again.
     *
     * @param auctionId ID of the Dutch auction to resume
     */
    function _resumeDutchAuction(uint256 auctionId) internal {
        _revertIfDutchAuctionDoesNotExist(auctionId);

        DutchAuction storage a = _dutchAuctions[auctionId];

        if (a.startTime == 0) revert DutchAuctionHasNotStarted();
        if (a.auctionActive) revert DutchAuctionIsActive();

        a.auctionActive = true; // resume the auction
        emit DutchAuctionStart(auctionId, a.startTime, a.duration);
    }

    /**
     * @dev ends a Dutch auction and emits an event
     * @param auctionId ID of the Dutch auction to end
     */
    function _endDutchAuction(uint256 auctionId) internal {
        _revertIfDutchAuctionDoesNotExist(auctionId);

        if (!_dutchAuctions[auctionId].auctionActive) {
            revert DutchAuctionIsNotActive();
        }

        _dutchAuctions[auctionId].auctionActive = false;
        emit DutchAuctionEnd(auctionId, block.timestamp);
    }

    /**
     * @dev returns the elapsed time since the start of a Dutch auction.
     *  Does NOT check if the auction exists.
     *  Returns 0 if the auction has not started or does not exist.
     * @param auctionId Dutch auction ID to query
     * @return elapsedTime elapsed seconds, or 0 if auction does not exist.
     */
    function _getElapsedDutchAuctionTime(uint256 auctionId)
        internal
        view
        returns (uint256)
    {
        uint256 startTime_ = _dutchAuctions[auctionId].startTime;
        return startTime_ > 0 ? block.timestamp - startTime_ : 0;
    }

    /**
     * @notice set the mints for a user on a Dutch auction
     * @param auctionId the auction counter to modify
     * @param user the minter address to set
     * @param quantity increment the counter by this many
     */
    function _incrementDutchAuctionMints(
        uint256 auctionId,
        address user,
        uint256 quantity
    ) internal {
        _dutchAuctionMints[auctionId][user] += quantity;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @dev custom error codes common to many contracts are predefined here
 */
interface IWCNFTErrorCodes {
    /// Exceeds maximum tokens per transaction
    error ExceedsMaximumTokensPerTransaction();

    /// Exceeds maximum supply
    error ExceedsMaximumSupply();

    /// Exceeds maximum reserve supply
    error ExceedsReserveSupply();

    /// Attempted access to inactive public sale
    error PublicSaleIsNotActive();

    /// Failed withdrawal from contract
    error WithdrawFailed();

    /// The wrong ETH value has been sent with a transaction
    error WrongETHValueSent();

    /// The zero address 0x00..000 has been provided as an argument
    error ZeroAddressProvided();

    /// A zero quantity cannot be requested here
    error ZeroQuantityRequested();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @dev include SUPPORT_ROLE access control
 */
contract WCNFTAccessControl is AccessControl {
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
}

/**
 * @dev collect common elements for multiple contracts.
 *  Includes SUPPORT_ROLE access control and ERC2981 on chain royalty info.
 */
contract WCNFTToken is WCNFTAccessControl, Ownable, ERC2981 {
    constructor() {
        // set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    /***************************************************************************
     * Royalties
     */

    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) 
        external 
        onlyRole(SUPPORT_ROLE) 
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _resetTokenRoyalty(tokenId);
    }

    /***************************************************************************
     * Overrides
     */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒███▓▓▓▓▓███▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒███████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░▒██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░▒██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░▒██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░▒██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░▒██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒██▓░░░░░▒██▓░░░░░▒██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░▒██████████████████████████▒░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 */
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry-1.3.1/src/DefaultOperatorFilterer.sol";
import "./lib/auctions/DutchAuctionHouse.sol";
import "./lib/auctions/EnglishAuctionHouse.sol";
import "./lib/MerkleFourParams.sol";
import "./lib/IWCNFTErrorCodes.sol";
import "./lib/WCNFTToken.sol";

contract CryptoCitiesSuburbs is
    IWCNFTErrorCodes,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    DutchAuctionHouse,
    EnglishAuctionHouse,
    MerkleFourParams,
    Ownable,
    WCNFTToken,
    ERC721
{
    // Structs
    struct City {
        uint256 id;
        uint256 numberOfSuburbs;
        uint256 minTokenId;
        uint256 maxTokenId; // inclusive
        string name; // e.g. Neo Tokyo
        string baseURIExtended;
        mapping(uint256 => Suburb) suburbs; // first Suburb has id 1
    }

    struct Suburb {
        uint256 id; // 1, 2, 3... etc. local to each City, starts at 1
        uint256 cityId; // parent City
        uint256 dutchAuctionId; // identifier of current DutchAuction, see DutchAuctionHouse.sol
        uint256 englishAuctionId; // identifier of current EnglishAuction, see EnglishAuctionHouse.sol
        uint256 firstTokenId;
        uint256 maxSupply;
        uint256 currentSupply;
        uint256 pricePerToken;
        uint256 allowListPricePerToken;
        bool allowListActive;
        bool saleActive;
    }

    // State vars
    uint256 public numberOfCities;
    uint256 public totalSupply; // cumulative over all cities and suburbs
    uint256 public maxDutchAuctionMints = 1;
    string private _baseURIOverride; // override per-City baseURIs
    address public immutable shareholderAddress;

    // map the Cities
    mapping(uint256 => City) public cities; // first City has id 1

    /**************************************************************************
     * CUSTOM ERRORS
     */

    /// unable to find the City for this token
    error CityNotFound();

    /// cities and suburbs cannot be removed if they are not empty
    error CityOrSuburbNotEmpty();

    /// action would exceed token or mint allowance
    error ExceedsMaximumTokensDuringDutchAuction();

    /// action would exceed the maximum token supply of this Suburb
    error ExceedsSuburbMaximumSupply();

    /// an invalid cityId has been requested
    error InvalidCityId();

    /// cannot initialize a Suburb with zero supply
    error InvalidInputZeroSupply();

    /// an invalid Suburb has been requested
    error InvalidSuburbId();

    /// an invalid tokenId has been requested. Often it is out of bounds
    error InvalidTokenId();

    /// only the most recent City can be modified
    error NotTheMostRecentCity();

    /// only the most recent Suburb can be modified
    error NotTheMostRecentSuburb();

    /// cannot add new City if previous has no suburbs. addSuburb or removeCity
    error PreviousCityHasNoSuburbs();

    /// Refund unsuccessful
    error RefundFailed();

    /// cannot complete request when a sale or allowlist is active
    error SaleIsActive();

    /**************************************************************************
     * EVENTS
     */

    /**
     * @dev emitted when a Dutch auction is created and assigned to a Suburb
     * @param cityId the City hosting the Dutch auction
     * @param suburbId the Suburb hosting the Dutch auction
     * @param dutchAuctionId auction ID, see {DutchAuctionHouse}
     */
    event DutchAuctionCreatedInSuburb(
        uint256 indexed cityId,
        uint256 indexed suburbId,
        uint256 dutchAuctionId
    );

    /**
     * @dev emitted when an English Auction is created and assigned to a Suburb
     * @param cityId the City hosting the Dutch auction
     * @param suburbId the Suburb hosting the Dutch auction
     * @param englishAuctionId auction ID, see EnglishAuctionHouse.sol
     */
    event EnglishAuctionCreatedInSuburb(
        uint256 indexed cityId,
        uint256 indexed suburbId,
        uint256 englishAuctionId
    );

    /**************************************************************************
     * CONSTRUCTOR
     */

    /**
     * @dev CryptoSuburbs tokens represent lots belonging to SUBURBS of CITIES
     * @param shareholderAddress_ Recipient address for contract funds.
     */
    constructor(address payable shareholderAddress_)
        ERC721("Suburbs", "SUBURBS")
        WCNFTToken()
    {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();
        shareholderAddress = shareholderAddress_;
    }

    /**************************************************************************
     * GUARD FUNCTIONS
     */

    /**
     * @dev reverts if the cityId or suburbId is invalid / does not exist
     * @param cityId city ID to query
     * @param suburbId suburb ID to query
     */
    function _revertIfCityIdOrSuburbIdInvalid(uint256 cityId, uint256 suburbId)
        internal
        view
    {
        if (cityId == 0 || cityId > numberOfCities) revert InvalidCityId();
        if (suburbId == 0 || suburbId > cities[cityId].numberOfSuburbs) {
            revert InvalidSuburbId();
        }
    }

    /**
     * @dev reverts if the public sale or allow list is active in Suburb s
     * @param s Suburb to query
     */
    function _revertIfAnySaleActive(Suburb storage s) internal view {
        if (s.saleActive) revert SaleIsActive();
        if (s.allowListActive) revert AllowListIsActive();
    }

    /**
     * @dev reverts if a Dutch auction or English Auction is active in Suburb s
     * @param s Suburb to query
     */
    function _revertIfAnyAuctionActive(Suburb storage s) internal view {
        if (_checkDutchAuctionActive(s.dutchAuctionId)) {
            revert DutchAuctionIsActive();
        }

        // revert if an EA is active, or is ended-but-not-settled
        if (_englishAuctionActiveNotSettled(s.englishAuctionId)) {
            revert EnglishAuctionIsNotComplete();
        }
    }

    /**************************************************************************
     * SETUP FUNCTIONS - build cities and suburbs
     */

    /**
     * @notice add a new City to the contract
     * @dev By adding a new City, the previous City is LOCKED and no more
     *  suburbs can be added to it.
     *
     *  New Cities are initialized without suburbs and without baseURI - these
     *  must be added with addSuburb() and setBaseURI()
     * @param cityName A name for the City, e.g. "Neo Tokyo"
     * @return cityId id for the City - use in cities(cityId) to get City info
     */
    function addCity(string calldata cityName)
        external
        onlyRole(SUPPORT_ROLE)
        returns (uint256)
    {
        // new ID number, start at 1
        uint256 cityId = ++numberOfCities;

        if (cityId > 1 && cities[cityId - 1].numberOfSuburbs == 0) {
            revert PreviousCityHasNoSuburbs();
        }

        // starting token ID for this City: refer to previous City
        // first token is ID 1 - consistent with cityId/suburbId
        uint256 startingTokenId = cities[cityId - 1].maxTokenId + 1;

        // make a new City struct and add it to cities
        City storage c = cities[cityId];

        // init the City
        c.id = cityId;
        c.minTokenId = startingTokenId;
        c.maxTokenId = startingTokenId; // will increase when adding suburbs
        c.name = cityName;

        return cityId;
    }

    /**
     * @notice add a new Suburb to the current City under construction.
     * @dev Suburbs can only be added to the most recently added City
     *  i.e. the City with the highest ID.
     * @param cityId_ the City to add a Suburb to. Must be the current City.
     * @param maxSupplyInSuburb the number of available tokens in this Suburb,
     *  including all sale types.
     * @param pricePerToken_ price per token in wei, on the public sale.
     * @param allowListPricePerToken_ allowList price per token in wei. Set to
     *  an arbitrary value if there will be no allow list sale for this Suburb.
     * @return newSuburbId ID for the newly created Suburb - use in
     *  suburbs(cityId, suburbId) to get Suburb info.
     */
    function addSuburb(
        uint256 cityId_,
        uint256 maxSupplyInSuburb,
        uint256 pricePerToken_,
        uint256 allowListPricePerToken_
    ) external onlyRole(SUPPORT_ROLE) returns (uint256) {
        // Incrementing token IDs means suburbs can only be added to the most
        // recent City
        if (cityId_ != numberOfCities || cityId_ == 0) {
            revert NotTheMostRecentCity();
        }
        if (maxSupplyInSuburb == 0) revert InvalidInputZeroSupply();

        City storage c = cities[cityId_];
        uint256 newSuburbId = ++c.numberOfSuburbs; // also increments storage

        // set the first and last token IDs in the new Suburb
        Suburb storage previousSub = c.suburbs[newSuburbId - 1];
        uint256 firstTokenId_ = newSuburbId > 1
            ? previousSub.firstTokenId + previousSub.maxSupply
            : c.minTokenId; // first Suburb, avoid setting first token as 0
        uint256 highestTokenId = firstTokenId_ + maxSupplyInSuburb - 1;

        // update max token tracker in the City
        c.maxTokenId = highestTokenId;

        // init the new Suburb
        c.suburbs[newSuburbId] = Suburb({
            id: newSuburbId,
            cityId: cityId_,
            firstTokenId: firstTokenId_,
            maxSupply: maxSupplyInSuburb,
            currentSupply: 0,
            pricePerToken: pricePerToken_,
            allowListPricePerToken: allowListPricePerToken_,
            dutchAuctionId: 0,
            englishAuctionId: 0,
            allowListActive: false,
            saleActive: false
        });

        return newSuburbId;
    }

    /**
     * @dev If and only if the most recent City is EMPTY, it can be removed.
     *  This will allow the previous City to add more Suburbs etc.
     *
     *  Intended for accidentally added cities (e.g. multiple/stuck txs).
     *
     *  User must confirm the cityId as a sanity check, even though it must be
     *  the most recently constructed City.
     *
     * @param cityId the City to be removed. Must be the most recently
     *  constructed City.
     */
    function removeCity(uint256 cityId) external onlyRole(SUPPORT_ROLE) {
        // revert if not the most recent City
        if (cityId != numberOfCities || cityId == 0) {
            revert NotTheMostRecentCity();
        }

        // revert if any suburbs have been built
        if (cities[cityId].numberOfSuburbs != 0) revert CityOrSuburbNotEmpty();

        // clear the empty City and decrement City counter
        // nested suburbs mapping will not be cleared, but we know it is empty
        delete cities[cityId];
        numberOfCities--;
    }

    /**
     * @dev If and only if a Suburb is EMPTY, it can be removed with this.
     *  All sales must be closed and no tokens can have been minted from this
     *  Suburb.
     *
     *  Intended for accidentally added suburbs (e.g. multiple/stuck txs).
     *
     *  User must confirm the cityId and suburbId as a sanity check, even
     *  though they must be the most recently constructed City and Suburb.
     *
     * @param cityId the City where the Suburb is located. Must be the most
     *  recently constructed City.
     * @param suburbId the Suburb ID to remove. Must be the most recently
     *  constructed Suburb.
     */
    function removeSuburb(uint256 cityId, uint256 suburbId)
        external
        onlyRole(SUPPORT_ROLE)
    {
        // revert if not the most recent City
        if (cityId != numberOfCities || cityId == 0) {
            revert NotTheMostRecentCity();
        }

        City storage c = cities[cityId];

        // revert if not the most recent Suburb in the City
        if (suburbId != c.numberOfSuburbs || suburbId == 0) {
            revert NotTheMostRecentSuburb();
        }

        Suburb storage s = c.suburbs[suburbId];

        // revert if any tokens have been sold
        if (s.currentSupply != 0) revert CityOrSuburbNotEmpty();

        // revert if any sales are active
        _revertIfAnySaleActive(s);

        // revert if any auctions are active
        _revertIfAnyAuctionActive(s);

        // reset token range in City
        if (suburbId > 1) {
            c.maxTokenId -= s.maxSupply;
        } else {
            c.maxTokenId = c.minTokenId; // as if City was newly initialized
        }

        // clear the Suburb and decrement counter
        delete c.suburbs[suburbId];
        c.numberOfSuburbs--;
    }

    /**************************************************************************
     * CITY ACCESS - get information about a City/Suburb
     */

    /**
     * @notice return the cityId a token belongs to. Does not check if token
     *  exists.
     * @param tokenId the token to search for
     * @return cityId the City containing tokenId
     */
    function getCityId(uint256 tokenId) public view returns (uint256) {
        if (tokenId == 0) revert InvalidTokenId();

        for (uint256 cityId = 1; cityId <= numberOfCities; ) {
            if (cities[cityId].maxTokenId >= tokenId) {
                return cityId;
            }
            unchecked {
                ++cityId;
            }
        }
        // should only revert if tokenId is out of range
        revert CityNotFound();
    }

    /**
     * @notice get structured data for a Suburb.
     *  Refer to Suburb struct layout for field ordering in returned tuple.
     * @param cityId the City containing suburbId
     * @param suburbId the suburbId within cityId
     * @return Suburb structured data for the Suburb
     */
    function suburbs(uint256 cityId, uint256 suburbId)
        public
        view
        returns (Suburb memory)
    {
        return cities[cityId].suburbs[suburbId];
    }

    /**************************************************************************
     * CITY ADMIN
     */

    /**
     * @dev set the merkle root to govern all allow lists. Reset this for each 
        new allow list sale.
     * @param merkleRoot_ the new merkle root
     */
    function setAllowList(bytes32 merkleRoot_) external onlyRole(SUPPORT_ROLE) {
        _setAllowList(merkleRoot_);
    }

    /**
     * @dev start and stop the allow list sale for a Suburb.
     *   Can be active at the same time as a public sale.
     *   Cannot be active at the same time as an English or Dutch auction.
     * @param cityId the parent City of the Suburb with the allowlist
     * @param suburbId the Suburb hosting the allow list
     * @param allowListState "true" starts the sale, "false" stops the sale
     */
    function setAllowListActive(
        uint256 cityId,
        uint256 suburbId,
        bool allowListState
    )
        external
        onlyRole(SUPPORT_ROLE)
    {
        _revertIfCityIdOrSuburbIdInvalid(cityId, suburbId);
        Suburb storage s = cities[cityId].suburbs[suburbId];

        _revertIfAnyAuctionActive(s);

        s.allowListActive = allowListState;
    }

    /**
     * @notice sets the base uri for a City
     * @dev this baseURI applies to all suburbs in a City
     * @param cityId identifier for the City
     * @param baseURI_ the base uri for the City
     */
    function setBaseURI(uint256 cityId, string memory baseURI_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        if (cityId == 0 || cityId > numberOfCities) revert InvalidCityId();
        cities[cityId].baseURIExtended = baseURI_;
    }

    /**
     * @notice sets the base uri for ALL tokens, overriding City baseURIs.
     * @dev set this to override all the existing City-level baseURIs. The URI
     *  set here must include all tokens in the collection.
     *  To revert back to City-level baseURIs, set this to an empty string ("")
     * @param baseURI_ the base uri for the whole collection
     */
    function setBaseURIOverride(string memory baseURI_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _baseURIOverride = baseURI_;
    }

    /**
     * @dev start and stop the public sale for a Suburb.
     *   Can be active at the same time as an allow list sale.
     *   Cannot be active at the same time as an English or Dutch auction.
     * @param cityId the parent City of the Suburb hosting the sale
     * @param suburbId the Suburb hosting the sale
     * @param saleState "true" starts the sale, "false" stops the sale
     */
    function setSaleActive(
        uint256 cityId,
        uint256 suburbId,
        bool saleState
    )
        external
        onlyRole(SUPPORT_ROLE)
    {
        _revertIfCityIdOrSuburbIdInvalid(cityId, suburbId);
        Suburb storage s = cities[cityId].suburbs[suburbId];

        _revertIfAnyAuctionActive(s);

        s.saleActive = saleState;
    }

    /**************************************************************************
     * DUTCH AUCTIONS - create and manage Dutch auctions
     */

    /**
     * @dev set up a Dutch auction for a Suburb.
     *  This does not start the auction.
     *  This will replace any existing auction details for this Suburb.
     *  This cannot be called while a Dutch auction is active.
     *
     *  The auction duration is computed from the start price, final price,
     *  price step and time step. Before starting the auction, check the
     *  duration is correct by calling
     *  getDutchAuctionInfo(dutchAuctionId)
     *
     * @param cityId the parent City of the Suburb hosting the Dutch Auction
     * @param suburbId the Suburb to host the Dutch auction
     * @param startPriceInWei start price for the auction, in wei.
     * @param finalPriceInWei final price in wei. Lower than startPriceInWei.
     * @param priceStepInWei price decreases this amount of wei each time step.
     * @param timeStepInSeconds time between price decrease steps, in seconds.
     * @return dutchAuctionId the ID number associated with this auction.
     */
    function createNewDutchAuction(
        uint256 cityId,
        uint256 suburbId,
        uint88 startPriceInWei,
        uint88 finalPriceInWei,
        uint88 priceStepInWei,
        uint80 timeStepInSeconds
    )
        external
        onlyRole(SUPPORT_ROLE)
        returns (uint256)
    {
        _revertIfCityIdOrSuburbIdInvalid(cityId, suburbId);
        Suburb storage s = cities[cityId].suburbs[suburbId];

        _revertIfAnyAuctionActive(s);

        // create the auction, see {DutchAuctionHouse}
        uint256 dutchAuctionID_ = _createNewDutchAuction(
            startPriceInWei,
            finalPriceInWei,
            priceStepInWei,
            timeStepInSeconds
        );

        // store the auction ID
        s.dutchAuctionId = dutchAuctionID_;

        emit DutchAuctionCreatedInSuburb(cityId, suburbId, dutchAuctionID_);
        return dutchAuctionID_;
    }

    /**
     * @notice start a Dutch auction
     * @dev starts the most recently created Dutch auction in a Suburb.
     *  If called on an auction which has been ended, this restarts the auction,
     *  resetting price and timers.
     *
     *  Before starting the Dutch auction, check the parameters are correct by
     *  calling getDutchAuctionInfo(dutchAuctionId)
     *
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb hosting the Dutch auction
     */
    function startDutchAuction(uint256 cityId, uint256 suburbId)
        external
        onlyRole(SUPPORT_ROLE)
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];

        _revertIfAnySaleActive(s);
        _revertIfAnyAuctionActive(s);

        _startDutchAuction(s.dutchAuctionId);
    }

    /**
     * @dev resume a stopped auction without resetting price and time counters
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb hosting the Dutch auction
     */
    function resumeDutchAuction(uint256 cityId, uint256 suburbId)
        external
        onlyRole(SUPPORT_ROLE)
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];

        _revertIfAnySaleActive(s);
        _revertIfAnyAuctionActive(s);

        _resumeDutchAuction(s.dutchAuctionId);
    }

    /**
     * @dev end a Dutch auction
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb hosting the Dutch auction
     */
    function endDutchAuction(uint256 cityId, uint256 suburbId)
        external
        onlyRole(SUPPORT_ROLE)
    {
        uint256 auctionId = cities[cityId].suburbs[suburbId].dutchAuctionId;
        _endDutchAuction(auctionId);
    }

    /**
     * @notice get the current Dutch auction id in a Suburb. Use this in
     *  helper functions for Dutch auctions. Returns 0 if an invalid City or
     *  Suburb is requested.
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb to query
     * @return dutchAuctionId identifier for the current Dutch auction
     */
    function getDutchAuctionId(uint256 cityId, uint256 suburbId)
        external
        view
        returns (uint256)
    {
        return cities[cityId].suburbs[suburbId].dutchAuctionId;
    }

    /**
     * @dev set the maximum number of mints per wallet per Dutch Auction
     * @param maxMints maximum mints per wallet per Dutch Auction
     */
    function setMaxDutchAuctionMints(uint256 maxMints)
        external
        onlyRole(SUPPORT_ROLE)
    {
        maxDutchAuctionMints = maxMints;
    }

    /**************************************************************************
     * ENGLISH AUCTIONS - create and manage English auctions
     */

    /**
     * @dev set up a new English Auction (ascending price auction). This does
     *  NOT start the auction.
     *
     * Start time and duration are set when auction is started with
     *  startEnglishAuction().
     *
     * outbidBuffer is to prevent 1 wei increments on the winning bid, and is
     *  the minimum buffer new bids must exceed the current highest by.
     *
     * This will overwrite any unstarted English auctions in this Suburb.
     *
     * If any English auctions have been started in this Suburb, they must
     *  be ended and settled before creating a new one.
     *
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId Suburb to host the English Auction
     * @param lotSize_ number of tokens to be sold in one bundle in this auction
     * @param startingBidInWei_ starting bid in wei for the auction
     * @param outbidBufferInWei_ new bids must exceed current highest by this
     * @return auctionId id for the new English Auction
     */
    function createNewEnglishAuction(
        uint256 cityId,
        uint256 suburbId,
        uint256 lotSize_,
        uint256 startingBidInWei_,
        uint256 outbidBufferInWei_
    )
        external
        onlyRole(SUPPORT_ROLE)
        returns (uint256)
    {
        _revertIfCityIdOrSuburbIdInvalid(cityId, suburbId);
        if (lotSize_ == 0) revert InvalidInputZeroSupply();
        Suburb storage s = cities[cityId].suburbs[suburbId];

        // English Auction sale check, included in _revertIfAnyAuctionActive()
        // cases:
        //  ea not started >> continue >> overwrite the old one
        //  ea started >> revert
        //  ea ended && !settled >> revert
        //  ea ended && settled >> continue >> overwrite the old one

        _revertIfAnyAuctionActive(s);

        // check there is supply available in this Suburb
        if (s.currentSupply + lotSize_ > s.maxSupply) {
            revert ExceedsSuburbMaximumSupply();
        }

        // set up the English Auction
        uint256 newEnglishId = _setUpEnglishAuction(
            lotSize_,
            startingBidInWei_,
            outbidBufferInWei_
        );

        s.englishAuctionId = newEnglishId;
        emit EnglishAuctionCreatedInSuburb(cityId, suburbId, newEnglishId);
        return newEnglishId;
    }

    /**
     * @dev start an English Auction which has already been set up. It can be
     *  started immediately, or some time in the future. When this has been
     *  called, no other sales can be started until this English Auction ends
     *  or is force-stopped.
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId Suburb hosting the English Auction
     * @param startDelayInSeconds set 0 to start immediately, or delay the start
     * @param durationInSeconds the number of seconds the auction will run for
     */
    function startEnglishAuction(
        uint256 cityId,
        uint256 suburbId,
        uint256 startDelayInSeconds,
        uint256 durationInSeconds
    )
        external
        onlyRole(SUPPORT_ROLE)
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];

        // check all sales are inactive for this Suburb, before starting
        _revertIfAnySaleActive(s);
        _revertIfAnyAuctionActive(s);

        // recheck there is supply available for the lot size
        uint256 auctionId = s.englishAuctionId;
        if (
            s.currentSupply + _englishAuctions[auctionId].lotSize > s.maxSupply
        ) {
            revert ExceedsSuburbMaximumSupply();
        }

        _startEnglishAuction(auctionId, startDelayInSeconds, durationInSeconds);
    }

    /**
     * @dev marks an English Auction as settled and mints the winner's token(s)
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb hosting the English Auction
     */
    function settleEnglishAuction(uint256 cityId, uint256 suburbId)
        external
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];
        uint256 auctionId = s.englishAuctionId;

        // auction ended/settled checks done in _markSettled()
        _markSettled(auctionId);

        // mint token to the winner
        address winner = _englishAuctions[auctionId].highestBidder;

        if (winner != address(0)) {
            uint256 numberOfTokens_ = _englishAuctions[auctionId].lotSize;

            // to prevent _safeMint() reverting maliciously and sticking the
            // contract, we do not check onERC721Received(). Contracts bidding
            // in this English Auction do so at their own risk and should
            // ensure they can use their tokens once received, e.g. using
            // {IERC721-safeTransferFrom}
            _mintInSuburb(s, winner, numberOfTokens_);
        }
    }

    /**
     * @dev force stop an English Auction, returns ETH to highest bidder,
     *  the token is not sold.
     *  Cannot do this within the final 2 hours of an auction.
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb hosting the English Auction
     */
    function forceStopEnglishAuction(uint256 cityId, uint256 suburbId)
        external
        onlyRole(SUPPORT_ROLE)
        nonReentrant
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];

        uint256 auctionId = s.englishAuctionId;
        _forceStopEnglishAuction(auctionId);
    }

    /**
     * @notice get the current englishAuctionId in a Suburb. Use this in
     *  helper functions for English auctions.
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb to query
     * @return englishAuctionId identifier for the active English Auction
     */
    function getEnglishAuctionId(uint256 cityId, uint256 suburbId)
        external
        view
        returns (uint256)
    {
        return cities[cityId].suburbs[suburbId].englishAuctionId;
    }

    /**
     * @dev edit the maximum gas sent with refunds during an English Auction.
     *  Gas limit initialized to 2300, but modifiable in case of future need.
     *
     *  Refunds are sent when:
     *  i) a high-bidder is outbid (their bid is returned)
     *  ii) an English Auction is force-stopped (current leader is refunded)
     *
     *  If this is set too low, all refunds using _gasLimitedCall() will
     *  fail.
     * @param maxGas maximum gas units for the call
     */
    function editMaxRefundGas(uint256 maxGas) external onlyRole(SUPPORT_ROLE) {
        _editMaxRefundGas(maxGas);
    }

    /**************************************************************************
     * MINT FUNCTIONS - mint tokens using each sale type
     */

    /**
     * @notice mint tokens from a City-Suburb on the public sale.
     * @param cityId the City ID to mint from
     * @param suburbId the Suburb ID within cityId to mint from: 1, 2, 3...
     * @param numberOfTokens number of tokens to mint
     */
    function mint(
        uint256 cityId,
        uint256 suburbId,
        uint256 numberOfTokens
    )
        external
        payable
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];

        // check saleActive
        if (!s.saleActive) revert PublicSaleIsNotActive();

        // check sent value is correct
        uint256 price = s.pricePerToken;
        if (msg.value != price * numberOfTokens) revert WrongETHValueSent();

        _safeMintInSuburb(s, msg.sender, numberOfTokens);
    }

    /**
     * @notice mint tokens on the Allow List
     * @dev using {MerkleFourParams} to manage a multiparameter merkle tree
     * @param cityId the parent City of the Suburb to mint in
     * @param suburbId the Suburb to mint in
     * @param numberOfTokens how many tokens to mint
     * @param tokenQuotaInSuburb the total quota for this address in this
     *  Suburb, regardless of the number minted so far
     * @param merkleProof merkle proof for this address and Suburb combo
     */
    function mintAllowList(
        uint256 cityId,
        uint256 suburbId,
        uint256 numberOfTokens,
        uint256 tokenQuotaInSuburb,
        bytes32[] calldata merkleProof
    )
        external
        payable
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];
        if (!s.allowListActive) revert AllowListIsNotActive();

        // check minted quota
        uint256 claimed_ = getAllowListMinted(msg.sender, cityId, suburbId);
        if (claimed_ + numberOfTokens > tokenQuotaInSuburb) {
            revert ExceedsAllowListQuota();
        }

        // check user is on allowlist and has their tokenQuotaInSuburb
        if (
            !onAllowList(
                msg.sender,
                tokenQuotaInSuburb,
                cityId,
                suburbId,
                merkleProof
            )
        ) {
            revert NotOnAllowList();
        }

        // check the eth passed is correct for this Suburb
        if (msg.value != numberOfTokens * s.allowListPricePerToken) {
            revert WrongETHValueSent();
        }

        // update allowlist minted for user
        _setAllowListMinted(msg.sender, cityId, suburbId, numberOfTokens);

        _safeMintInSuburb(s, msg.sender, numberOfTokens);
    }

    /**
     * @notice Mint tokens in the Dutch auction for any tier
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId the Suburb hosting the Dutch auction
     * @param numberOfTokens The number of tokens to mint
     */
    function mintDutch(
        uint256 cityId,
        uint256 suburbId,
        uint256 numberOfTokens
    )
        external
        payable
        nonReentrant
    {
        Suburb storage s = cities[cityId].suburbs[suburbId];
        uint256 auctionId = s.dutchAuctionId;
        DutchAuction storage da = _dutchAuctions[auctionId];

        // check auction is active - see {DutchAuctionHouse}
        if (!da.auctionActive) revert DutchAuctionIsNotActive();

        // check current price
        uint256 tokenPrice = getDutchAuctionPrice(auctionId);
        uint256 salePrice = tokenPrice * numberOfTokens;
        if (msg.value < salePrice) revert WrongETHValueSent();

        // limit mints during price decline, unlimited at resting price
        if (tokenPrice > da.finalPrice) {
            if (
                (getDutchAuctionMints(auctionId, msg.sender) + numberOfTokens) >
                maxDutchAuctionMints
            ) {
                revert ExceedsMaximumTokensDuringDutchAuction();
            }
            // if resting price is already hit, this SSTORE is not needed
            _incrementDutchAuctionMints(auctionId, msg.sender, numberOfTokens);
        }

        _safeMintInSuburb(s, msg.sender, numberOfTokens);

        // refund if price declined before tx confirmed
        if (msg.value > salePrice) {
            uint256 refund = msg.value - salePrice;
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            if (!success) revert RefundFailed();
        }
    }

    /**
     * @notice Bid on an English Auction for a Suburb. If you are the highest
     *  bidder already, extra bids are added to your current bid. All bids are
     *  final and cannot be revoked.
     *
     * NOTE: if bidding from a contract ensure it can use any tokens received.
     *  This does not check onERC721Received().
     *
     * @dev refunds previous highest bidder when new highest bid received.
     * @param cityId parent City of the auctioning Suburb
     * @param suburbId Suburb hosting the auction
     */
    function bidEnglish(uint256 cityId, uint256 suburbId)
        external
        payable
        nonReentrant
    {
        uint256 auctionId = cities[cityId].suburbs[suburbId].englishAuctionId;
        _bidEnglish(auctionId);
    }

    /**
     * @dev mint reserve tokens to any address
     * @param cityId the City ID to mint from
     * @param suburbId the Suburb ID within cityId to mint from: 1, 2, 3...
     * @param to recipient address
     * @param numberOfTokens number of tokens to mint
     */
    function devMint(
        uint256 cityId,
        uint256 suburbId,
        address to,
        uint256 numberOfTokens
    )
        external
        onlyRole(SUPPORT_ROLE)
    {
        _revertIfCityIdOrSuburbIdInvalid(cityId, suburbId);
        Suburb storage s = cities[cityId].suburbs[suburbId];
        _revertIfAnyAuctionActive(s);

        _safeMintInSuburb(s, to, numberOfTokens);
    }

    /**************************************************************************
     * OWNER FUNCTIONS
     */

    /**
     * @dev withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 bal = address(this).balance;
        (bool success, ) = shareholderAddress.call{value: bal}("");

        if (!success) revert WithdrawFailed();
    }

    /**************************************************************************
     * INTERNAL MINT FUNCTIONS
     */

    /**
     * @dev internal mint helper - check and update supply, then return the
     *  next sequential ID to mint in the Suburb.
     * @param s the Suburb to mint in
     * @param quantity number of tokens to mint
     * @return nextId the next sequential ID to mint in the Suburb
     */
    function _mintChecksEffectsNextId(Suburb storage s, uint256 quantity)
        internal
        returns (uint256)
    {
        if (quantity == 0) revert ZeroQuantityRequested();

        // current supply check
        uint256 currentSupply_ = s.currentSupply;
        if (currentSupply_ + quantity > s.maxSupply) {
            revert ExceedsSuburbMaximumSupply();
        }

        // effects
        s.currentSupply = currentSupply_ + quantity;
        totalSupply += quantity;

        // return
        uint256 nextId = s.firstTokenId + currentSupply_;
        return nextId;
    }

    /**
     * @dev internal mint function using {ERC721-_mint} i.e. NOT checking
     *  {ERC721-onERC721Received}.
     * @param s the Suburb to mint in
     * @param receiver mint to this address
     * @param quantity number of tokens to mint
     */
    function _mintInSuburb(
        Suburb storage s,
        address receiver,
        uint256 quantity
    )
        internal
    {
        uint256 nextId = _mintChecksEffectsNextId(s, quantity);

        for (uint256 i; i < quantity; ) {
            _mint(receiver, nextId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev internal mint function using {ERC721-_safeMint}
     * @param s the Suburb to mint in
     * @param receiver mint to this address
     * @param quantity number of tokens to mint
     */
    function _safeMintInSuburb(
        Suburb storage s,
        address receiver,
        uint256 quantity
    )
        internal
    {
        uint256 nextId = _mintChecksEffectsNextId(s, quantity);

        for (uint256 i; i < quantity; ) {
            _safeMint(receiver, nextId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**************************************************************************
     * OVERRIDE SUPERS
     */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(WCNFTToken, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev each City has its own baseURI.
     * Adapted from {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert InvalidTokenId();
        string memory baseURI = _baseURIOverride;

        if (bytes(baseURI).length == 0) {
            uint256 cityId = getCityId(tokenId);
            baseURI = cities[cityId].baseURIExtended;

            if (bytes(baseURI).length == 0) {
                return "";
            }
        }

        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /***************************************************************************
     * Operator Filter
     */

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
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}