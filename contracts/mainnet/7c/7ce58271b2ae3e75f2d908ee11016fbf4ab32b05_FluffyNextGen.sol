/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: erc721a/contracts/IERC721A.sol


// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

    // ==============================
    //        IERC721Metadata
    // ==============================

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

// File: erc721a/contracts/ERC721A.sol


// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;
    
    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID. 
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count. 
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev Casts the boolean to uint256 without branching.
     */
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                getApproved(tokenId) == _msgSenderERC721A());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED | 
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// File: erc721a/contracts/extensions/IERC721AQueryable.sol


// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// File: erc721a/contracts/extensions/ERC721AQueryable.sol


// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;



/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// File: contracts/FluffyFucksReborn.sol



pragma solidity >=0.7.0 <0.9.0;




contract FluffyFucksReborn is ERC721AQueryable, Ownable {
  using Strings for uint256;

  string public uriPrefix = ""; //http://www.site.com/data/
  string public uriSuffix = ".json";

  string public _contractURI = "";

  uint256 public maxSupply = 6061;

  bool public paused = false;

  constructor() ERC721A("Fluffy Fucks", "FFXv2") {
  }

  function _startTokenId()
        internal
        pure
        override
        returns(uint256)
    {
        return 1;
    }

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(!paused, "The contract is paused!");
    require(totalSupply() + _mintAmount < maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function mintForAddressMultiple(address[] calldata addresses, uint256[] calldata amount) public onlyOwner
  {
    require(!paused, "The contract is paused!");
    require(addresses.length == amount.length, "Address and amount length mismatch");

    for (uint256 i; i < addresses.length; ++i)
    {
      _safeMint(addresses[i], amount[i]);
    }

    require(totalSupply() < maxSupply, "Max supply exceeded!");
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override (ERC721A, IERC721A)
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function contractURI()
  public
  view
  returns (string memory)
  {
        return bytes(_contractURI).length > 0
          ? string(abi.encodePacked(_contractURI))
          : "";
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setContractURI(string memory newContractURI) public onlyOwner {
    _contractURI = newContractURI;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}

// File: contracts/FluffyStaker.sol


pragma solidity >=0.8.0 <0.9.0;




contract FluffyStaker is IERC721Receiver, ReentrancyGuard {
    address public ownerAddress;
    bool public active = true;

    mapping(uint256 => address) staked;

    FluffyFucksReborn public ffxr;

    constructor()
    {
        ownerAddress = msg.sender;
    }

    fallback() external payable nonReentrant 
    {
        revert();
    }
    receive() external payable nonReentrant 
    {
        revert();
    }

    /**
     * on token received
     */
    function onERC721Received
    (
        address /*operator*/,
        address from, 
        uint256 tokenId, 
        bytes calldata /*data*/
    ) 
        public
        override
        onlyFromFluffyContract(msg.sender)
        returns(bytes4) 
    {
        staked[tokenId] = from;
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * ADMIN ONLY
    */

    function setFluffyAddress(address contractAddress)
        public
        onlyOwner
    {
        ffxr = FluffyFucksReborn(contractAddress);
    }

    function restoreOddball(uint256 tokenId, address restoreTo)
        public
        onlyOwner
    {
        require(staked[tokenId] == address(0x0), "Token has a known owner.");
        ffxr.safeTransferFrom(address(this), restoreTo, tokenId);
    }

    function forceUnstake(uint256 tokenId)
        public
        onlyOwner
    {
        _forceUnstake(tokenId);
    }

    function forceUnstakeBatch(uint256[] calldata tokenIds)
        public
        onlyOwner
    {
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            _forceUnstake(tokenIds[i]);
        }
    }

    function forceUnstakeAll()
        public
        onlyOwner
    {
        uint256[] memory tokens = ffxr.tokensOfOwner(address(this));
        for(uint256 i = 0; i < tokens.length; ++i) {
            _forceUnstake(tokens[i]);
        }
    }

    function _forceUnstake(uint256 tokenId)
        private
        onlyOwner
    {
        if(staked[tokenId] != address(0x0)) {
            ffxr.safeTransferFrom(address(this), staked[tokenId], tokenId);
            staked[tokenId] = address(0x0);
        }
    }

    function toggleActive(bool setTo) 
        public
        onlyOwner
    {
        active = setTo;
    }

    /**
     * LOOKUPS
     */

    function tokenStaker(uint256 tokenId) 
        public 
        view
        returns(address) 
    {
        return staked[tokenId];
    }

    function tokenStakers(uint256[] calldata tokenIds)
        public
        view
        returns(address[] memory)
    {
        address[] memory stakers = new address[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            stakers[i] = staked[tokenIds[i]];
        }
        return stakers;
    }

    function allTokenStakers()
        isFluffyContractSet
        public 
        view
        returns (uint256[] memory, address[] memory)
    {
        uint256[] memory tokens = ffxr.tokensOfOwner(address(this));

        uint256[] memory stakedTokens;
        address[] memory stakers;
        
        uint256 count = 0;
        for(uint256 i = 0; i < tokens.length; ++i) {
            if (staked[tokens[i]] != address(0x0)) {
                ++count;
            }
        }

        stakedTokens = new uint256[](count);
        stakers = new address[](count);
        count = 0;

        for(uint256 i = 0; i < tokens.length; ++i) {
            stakedTokens[count] = tokens[i];
            stakers[count] = staked[tokens[i]];
            count++;
        }

        return (stakedTokens, stakers);
    }

    function totalStaked()
        isFluffyContractSet
        public
        view
        returns (uint256 count)
    {
        uint256[] memory tokens = ffxr.tokensOfOwner(address(this));
        count = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (staked[tokens[i]] != address(0x0)) {
                ++count;
            }
        }
    }

    function tokensStakedByAddress(address ogOwner)
        public
        view
        returns(uint256[] memory tokenIds)
    {
        uint256[] memory tokens = ffxr.tokensOfOwner(address(this));
        uint256 owned = 0;
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (ogOwner == staked[tokens[i]]) {
                ++owned;
            }
        }

        tokenIds = new uint256[](owned);
        owned = 0;
        for (uint256 i = 0; i < tokens.length; ++i) {
            if (ogOwner == staked[tokens[i]]) {
                tokenIds[owned] = tokens[i];
                ++owned;
            }
        }
    }

    function isStakingEnabled()
        public
        view
        returns (bool)
    {
        return this.isStakingEnabled(msg.sender);
    }

    function isStakingEnabled(address send)
        public
        view
        returns (bool)
    {
        return ffxr.isApprovedForAll(send, address(this));
    }

    function oddballTokensThatShouldNotBeHere()
        public
        view
        returns (uint256[] memory tokenIds)
    {
        uint256 count = 0;
        uint256[] memory tokens = ffxr.tokensOfOwner(address(this));
        for(uint256 i = 0; i < tokens.length; ++i) {
            if (staked[tokens[i]] == address(0x0)) {
                ++count;
            }
        }

        tokenIds = new uint256[](count);
        count = 0;
        for(uint256 i = 0; i < tokens.length; ++i) {
            if (staked[tokens[i]] == address(0x0)) {
                tokenIds[count] = tokens[i];
                ++count;
            }
        }
    }

    /**
     * STAKING
     */

    function stakeBatch(uint256[] calldata tokenIds)
        isStakingActive
        isApproved(msg.sender)
        external
    {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _stake(tokenIds[i]);
        }
    }

    function stake(uint256 tokenId)
        isStakingActive
        isApproved(msg.sender)
        external
    {
        _stake(tokenId);
    }

    function _stake(uint256 tokenId)
        isFluffyContractSet
        private
    {
        ffxr.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    /**
     * UNSTAKING
     */

    function unstakeBatch(uint256[] calldata tokenIds)
        external
    {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _unstake(tokenIds[i]);
        }
    }

    function unstake(uint256 tokenId)
        external
    {
        _unstake(tokenId);
    }

    function _unstake(uint256 tokenId)
        isFluffyContractSet
        onlyOriginalTokenOwner(tokenId)
        private
    {
        ffxr.safeTransferFrom(address(this), staked[tokenId], tokenId);
        staked[tokenId] = address(0x0);
    }

    /**
     * MODIFIERS
     */
    modifier onlyOriginalTokenOwner(uint256 tokenId)
    {
        require(msg.sender == staked[tokenId], "You are not tokens original owner");
        _;
    }

    modifier onlyOwner()
    {
        require(msg.sender == ownerAddress, "You are not owner.");
        _;
    }

    modifier onlyFromFluffyContract(address sentFromAddress)
    {
        require(sentFromAddress == address(ffxr), "Not sent from Fluffy contract.");
        _;
    }

    modifier isFluffyContractSet()
    {
        require(address(ffxr) != address(0x0), "Fluffy address is not set");
        _;
    }

    modifier isApproved(address send)
    {
        require(this.isStakingEnabled(send), "You have not approved FluffyStaker.");
        _;
    }

    modifier isStakingActive()
    {
        require(active, "Staking is not active.");
        _;
    }
}
// File: contracts/FluffyNextGen.sol

/**
 * SPDX-License-Identifier: UNLICENSED
 */

pragma solidity >=0.8.0 <0.9.0;








contract FluffyNextGen is ERC721AQueryable, Ownable, ReentrancyGuard
{
    FluffyFucksReborn public ffxr;
    bool public paused = true;
    bool public holderWlMintOpen = false;
    bool public publicMintOpen = false;
    uint256 public supply = 1212;
    uint256 public teamSupply = 30;
    uint256 public defaultMaxPerWallet = 5;
    uint256 public price = 0.0069 ether;
    bytes32 public merkleRoot;
    
    string private contractMetadataUrl;
    string private tokenMetadataUrlRoot;
    mapping(address => uint256) private addressHasMinted;
    mapping(address => uint256) private stakerHasMintedFree;

    mapping(address => uint256) private stakerSnapshot;

    /**
     * CONSTRUCTOR
     */

    constructor () ERC721A("FluffyFucks Koalas", "FFXg2.0")
    {
        deploySnapshot();
    }

    /**
     * MINTING
     */

    // team mint
    function teamMint(uint256 _quantity)
        public
        onlyOwner
        nonReentrant
        supplyExists(_quantity)
    {
        require(addressHasMinted[msg.sender] + _quantity <= teamSupply);
        _safeMint(msg.sender, _quantity);
        addressHasMinted[msg.sender] += _quantity;
    }

    // mint
    function mint(
        uint256 _quantity,
        uint256 _freeMints,
        bytes32[] calldata _proof
    )
        public
        payable
        isMintingOpen
        nonReentrant
        supplyExists(_quantity + _freeMints)
    {
        require(_quantity + _freeMints > 0, "No point minting nothing.");

        // checking if person is an active staker
        if(stakerSnapshot[msg.sender] > 0) {
            return stakerMint(stakerSnapshot[msg.sender], msg.sender, _quantity, _freeMints, msg.value);
        }

        require(_quantity > 0, "No point minting no fluffs.");

        // checking if person is an active holder
        uint256 balance = ffxr.balanceOf(msg.sender);
        if (balance > 0) {
            return holderMint(msg.sender, _quantity, msg.value);
        }

        // checking if person is whitelisted
        if (isAddressWhitelisted(msg.sender, _proof)) {
            return whitelistMint(msg.sender, _quantity, msg.value);
        }

        // defaulting to public mint
        return publicMint(msg.sender, _quantity, msg.value);
    }

    // staker mint
    function stakerMint(uint256 _numberStaked, address _minter, uint256 _quantity, uint256 _freeMints, uint256 _payment)
        private
        hasFunds(_quantity, _payment)
    {
        (uint256 maxFreeMints, uint256 maxMinted) = howManyCanStakerMint(_numberStaked);
        require(_freeMints + stakerHasMintedFree[_minter] <= maxFreeMints, "You cannot mint this many free mints.");
        require(_quantity + _freeMints + addressHasMinted[_minter] <= maxMinted, "You cannot mint this many fluffs.");
        _safeMint(_minter, _quantity + _freeMints);
        addressHasMinted[_minter] += _quantity + _freeMints;
        stakerHasMintedFree[_minter] += _freeMints;
    }

    // whitelist mint
    function whitelistMint(address _minter, uint256 _quantity, uint256 _payment)
        private
        isHolderWlMintOpen
        hasFunds(_quantity, _payment)
        canMintAmount(_minter, _quantity)
    {
        _safeMint(_minter, _quantity);
        addressHasMinted[_minter] += _quantity;
    }

    // holder mint
    function holderMint(address _minter, uint256 _quantity, uint256 _payment)
        private
        isHolderWlMintOpen
        hasFunds(_quantity, _payment)
        canMintAmount(_minter, _quantity)
    {
        _safeMint(_minter, _quantity);
        addressHasMinted[_minter] += _quantity;
    }

    // public mint
    function publicMint(address _minter, uint256 _quantity, uint256 _payment)
        private
        isPublicMintOpen
        hasFunds(_quantity, _payment)
        canMintAmount(_minter, _quantity)
    {
        _safeMint(_minter, _quantity);
        addressHasMinted[_minter] += _quantity;
    }

    /**
     * GETTERS AND SETTERS
     */

    function setPaused(bool _paused) 
        public
        onlyOwner
    {
        paused = _paused;
    }

    function setPublicMintOpen(bool _publicOpen)
        public
        onlyOwner
    {
        publicMintOpen = _publicOpen;
    }

    function setHolderWlMintOpen(bool _holdWlOpen)
        public
        onlyOwner
    {
        holderWlMintOpen = _holdWlOpen;
    }

    function setFluffyContract(address _contract)
        public
        onlyOwner
    {
        ffxr = FluffyFucksReborn(_contract);
    }

    function setMerkleRoot(bytes32 _merkle)
        public
        onlyOwner
    {
        merkleRoot = _merkle;
    }

    function setContractMetadataUrl(string calldata _metadataUrl)
        public
        onlyOwner
    {
        contractMetadataUrl = _metadataUrl;
    }

    function setTokenMetadataUrlRoot(string calldata _tokenMetadataRoot)
        public
        onlyOwner
    {
        tokenMetadataUrlRoot = _tokenMetadataRoot;
    }

    /**
     * VIEWS
     */

    function howManyCanSomeoneMint(address _minter)
        public
        view
        returns(uint256 freeMints, uint256 maxMints)
    {
        if(stakerSnapshot[_minter] > 1) {
            (freeMints, maxMints) = howManyCanStakerMint(stakerSnapshot[_minter]);
            return (
                freeMints - stakerHasMintedFree[_minter],
                maxMints - addressHasMinted[_minter]
            );
        } else {
            return (0, defaultMaxPerWallet - addressHasMinted[_minter]);
        }
    }

    function howManyCanStakerMint(uint256 _staked)
        public
        pure
        returns(uint256 freeMints, uint256 maxMints)
    {
        if (_staked == 0) {
            // 0 staked
            return (0, 0);
        } else if (_staked == 1) {
            // 1 staked
            return (0, 5);
        } else if (_staked < 10) {
            // less than 10
            return (_staked / 2, 5);
        } else if (_staked < 20) {
            // less than 20
            return (_staked / 2, 10);
        } else if (_staked < 40) {
            // less than 40
            return (10, 20);
        } else if (_staked < 69) {
            // less than 69
            return (20, 40);
        } else {
            // 69 or more
            return (35, 69);
        }
    }

    function isAddressWhitelisted(address _minter, bytes32[] calldata _proof)
        private
        view
        returns(bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_minter)));
    }

    /**
     * MODIFIERS
     */

    modifier isMintingOpen()
    {
        require(paused == false, "Minting is not active.");
        _;
    }

    modifier isPublicMintOpen()
    {
        require(publicMintOpen, "Public mint is not open.");
        _;
    }

    modifier isHolderWlMintOpen()
    {
        require(holderWlMintOpen, "Holder and Whitelist mint is not open.");
        _;
    }

    modifier supplyExists(uint256 _quantity)
    {
        require(_totalMinted() + _quantity <= supply, "This would exceed minting supply.");
        _;
    }

    modifier hasFunds(uint256 _quantity, uint256 _payment)
    {
        require(_quantity * price <= _payment, "You do not have enough money to mint.");
        _;
    }

    modifier canMintAmount(address _minter, uint256 _quantity)
    {
        require(addressHasMinted[_minter] + _quantity <= defaultMaxPerWallet, "You cannot mint this many");
        _;
    }

    /**
     * CONTRACT STUFF
     */

    function _startTokenId()
        internal
        pure
        override
        returns(uint256)
    {
        return 1;
    }

    function withdraw() 
        public 
        onlyOwner 
        nonReentrant
    {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

        function contractURI()
        public
        view
        returns(string memory)
    {
        return contractMetadataUrl;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return tokenMetadataUrlRoot;
    }

    /**
     * SNAPSHOT
     */
    function deploySnapshot()
        private
    {
        stakerSnapshot[0x0066A1C2137Ee60fEc2ac1f51E26DCd78Ae0f42d] = 6;
        stakerSnapshot[0x0071e278144a040EE373331d1c3d9e6fD3BB7339] = 2;
        stakerSnapshot[0x01850e6686a222edc136f11C93D824cDa433e364] = 4;
        stakerSnapshot[0x0287E8dfC37544995fb75af20fdaB57c74f4860D] = 2;
        stakerSnapshot[0x045e6833Fa2B7BBd1a6cfc3CC2630A6e20Ff9E87] = 6;
        stakerSnapshot[0x06E5D82B5A8dF0435CE8046bc15290594bC0c710] = 2;
        stakerSnapshot[0x07035d0e0cFb5e89218be943507694526A4EBE54] = 4;
        stakerSnapshot[0x074DB7F6c8dbD545e53411795B182529f494779A] = 2;
        stakerSnapshot[0x08132a6899DdcfD77bAA15990D96f6645a9390da] = 2;
        stakerSnapshot[0x08834D1ac96cb6D533C5a742511C759EE83B0d61] = 8;
        stakerSnapshot[0x08e6c66Ce1fdEE6004a63B06cA0Ff324b8aa5826] = 2;
        stakerSnapshot[0x090459ae119b904A0808568E763A4f5556B49FE0] = 2;
        stakerSnapshot[0x0945BE11418b180Ec8DfE0447a9bE1c15FB1BeaD] = 2;
        stakerSnapshot[0x09Cb303EcAba558422d63B7392d095C7ffE37D36] = 2;
        stakerSnapshot[0x0aAB45d1B9C821EBfd03a77117c12355e8739c85] = 13;
        stakerSnapshot[0x0bC8801f28baf3F5cEbA2bC3f0Cdfcaf37C2846e] = 6;
        stakerSnapshot[0x0bE9F7f7a5d1e19311989bbE307c4796A534d6E8] = 4;
        stakerSnapshot[0x0c4DB5ECb43303d925EDa8F11Fe592D59d3C6cC3] = 7;
        stakerSnapshot[0x0C645D0c6Ec9ec7DDe5BB8f5E655e11775f44277] = 2;
        stakerSnapshot[0x0d47A223Fd09C174184131a9a539562b4a026E57] = 4;
        stakerSnapshot[0x0dd201E9243320cb0651AcdCb134e086f4582645] = 2;
        stakerSnapshot[0x0DfAb02678695f56E9373aA072A59fbDA5938a49] = 2;
        stakerSnapshot[0x0E96cC0F0001Ab39659d48050d5e5A4361330a4B] = 2;
        stakerSnapshot[0x1059650DC09681949F7686974F61D95c2135B091] = 2;
        stakerSnapshot[0x105c9EF0a0531a3B1B692508EFe7994880d942B7] = 4;
        stakerSnapshot[0x106aBAfcD4C1F615eBF14EFDD7e52EDFb33217aB] = 2;
        stakerSnapshot[0x134aed007F8935746749Ab25bD3CE88231BF555a] = 2;
        stakerSnapshot[0x139734BaAd745912286B55cE07a6D113C19A9AD9] = 2;
        stakerSnapshot[0x142875238256444be2243b01CBe613B0Fac3f64E] = 2;
        stakerSnapshot[0x14573a0484D8639e024264e0159905AC1eB9B453] = 2;
        stakerSnapshot[0x15384d0578CFcBA6C9E29777599871c8E0878513] = 4;
        stakerSnapshot[0x167f12fEFB578f29bEd2585e84ae6C5A72fF21Cd] = 2;
        stakerSnapshot[0x169eB0789887fedA30DcBD91b4002089A98Ab241] = 2;
        stakerSnapshot[0x190237dcED5114bD6c482772ce20faD0Be407b4A] = 6;
        stakerSnapshot[0x1a2f95a9dc750b581632C567a2d7B96650D6e019] = 6;
        stakerSnapshot[0x1Ba3a102D292e988E8eE55d30ad98e5B4BdA32dc] = 2;
        stakerSnapshot[0x1E50CA5bfc75d6B4af207503E3A6D4A4c5ec05cd] = 4;
        stakerSnapshot[0x205BBBE1b5EE65efFe19c5DD59b84AD1413BBB77] = 4;
        stakerSnapshot[0x2129bCA7cA8B37956ec24c5b7411fd5424370DBF] = 15;
        stakerSnapshot[0x2245Ec2b9773e5B6A457F883c3183374Fe4D0864] = 4;
        stakerSnapshot[0x23f3c4dD6297A36A2140d5478188D9e773D3Ac9E] = 2;
        stakerSnapshot[0x252723A88a9c2279E998D4eD363DB120553C715C] = 5;
        stakerSnapshot[0x252d74d7d69f5cC3Bb2Cd2fdbE3b37DC1F1edC2f] = 4;
        stakerSnapshot[0x2581F074fDA1454a2869862D61429Dd5871cE4DA] = 2;
        stakerSnapshot[0x25A1Cfac8c9eADAB7c12FB59d54144593Aa96436] = 4;
        stakerSnapshot[0x2735B84B6AfB1328EA7809ce212589C5175D71Fb] = 2;
        stakerSnapshot[0x2760F7d38377AcF2Fc26c08915B4669eBeE1420A] = 4;
        stakerSnapshot[0x27f0A1677a3185d360ac5985f3BbC766ca34b00E] = 14;
        stakerSnapshot[0x29adfe4efD359939322493eD8B386d45877E7749] = 8;
        stakerSnapshot[0x2A9a201B97305F52E3771ACDbFbaDc015fbD155F] = 2;
        stakerSnapshot[0x2b604baEe38Fd5d9eF2b236e4d8462C27A66aD5d] = 2;
        stakerSnapshot[0x2bEcCB8975aEee773b03a3CB29a81304D5AC6122] = 2;
        stakerSnapshot[0x2c82C2B69d7B56EE7f475d1320e362e87b51Ae4d] = 6;
        stakerSnapshot[0x2FE38f5092E76b27e278bf2417e2a56375bB6b8B] = 8;
        stakerSnapshot[0x3020136b9958642cf8E3972E06DB21F3884DF56A] = 2;
        stakerSnapshot[0x31aBDFd780A044b034270862F46853d1e34Dd6aE] = 2;
        stakerSnapshot[0x31B685C06590d72c67609C2d940C41C79966D2E3] = 6;
        stakerSnapshot[0x31e4662AAE7529E0A95BeD463c48d8B398cfAB73] = 12;
        stakerSnapshot[0x34A0c4799a177a95EA6611aEbf377639f551eaa3] = 33;
        stakerSnapshot[0x3578234C0FD2d531E84eEc84CAbf64FF5B246c30] = 2;
        stakerSnapshot[0x3609840fb53EBEa9F39c2c97e4A39438a825a89e] = 20;
        stakerSnapshot[0x36214d560aaa853d5c0853920FFe27779803419D] = 7;
        stakerSnapshot[0x362DC61A04cb099aB6b912DB07e0D6270342f16D] = 25;
        stakerSnapshot[0x3765A89463A19D5c2413544808Cb8b537Ac406eF] = 2;
        stakerSnapshot[0x37FFe79d00C8c33E3f9622ac940e46BFa56d70a7] = 5;
        stakerSnapshot[0x39E121297240Ac7F72E7487D799a0fC06422e216] = 2;
        stakerSnapshot[0x3A410941d1A1f9d6d09a2F479Be991C237DD2A68] = 2;
        stakerSnapshot[0x3a95e5407E32A1CC7f6923F3297aF09D2279bBDC] = 2;
        stakerSnapshot[0x3Aa17002F448bee09284dDe391A595E51DCd8c39] = 5;
        stakerSnapshot[0x3cbE9F5d49a2b92FA49cc01B4547C0860Bae4f99] = 2;
        stakerSnapshot[0x3ccc9E75E6C63fcb68E30B81A3bc3209dB09A9f9] = 8;
        stakerSnapshot[0x3d5A925EeD67A613778d7Ad9254aB75241348EBc] = 6;
        stakerSnapshot[0x3E311f18653300f9441aC0D886DFF51e1278aAEB] = 3;
        stakerSnapshot[0x3E6D9477BA6b136bAb6FA4BE2E40373de2eC704F] = 2;
        stakerSnapshot[0x3ec6d18f4A52dd8dBCb013eE920f935738C6223C] = 79;
        stakerSnapshot[0x3eC8A6f383Fdda0A21996b4233946717f9EacB26] = 2;
        stakerSnapshot[0x3eddd4CC257564889Ba377f5Fdb9e827e9503F96] = 2;
        stakerSnapshot[0x3Ff0df7EC6Ab47725272691a030c22a59bc87B1D] = 2;
        stakerSnapshot[0x419D36f006Ba8933fFb99B5BC8d189505c0836d3] = 2;
        stakerSnapshot[0x42B83becC570F4e2D9b40544d59984541Aa52168] = 2;
        stakerSnapshot[0x433eE230C45Fd079E60CF5d428b76Caa0055558c] = 22;
        stakerSnapshot[0x434eD1DecDE9dCB0ca6c9E5c29C95D22f085400F] = 1;
        stakerSnapshot[0x4526E96ceDb7A4F570944c37A544B0E44b946ea4] = 69;
        stakerSnapshot[0x46A8E8B740292775F036da3Bd279f1994864bf53] = 2;
        stakerSnapshot[0x46bE8E0a5e919E1A174978636B6be161b21E2f1A] = 6;
        stakerSnapshot[0x47e44738be0732119E0687EaA3BC18F5c8e58399] = 2;
        stakerSnapshot[0x47F740c1Ea213A267B483640c1C3aEC8B262f25e] = 26;
        stakerSnapshot[0x48ec7Fe34E0C7843133c0e7571c2f17AB8C7bf32] = 4;
        stakerSnapshot[0x49a15aD9eCa0d7aDc9dABe42869DFc304C26FD53] = 2;
        stakerSnapshot[0x4aC3728c8C2CCAAf89784ea9C9Ae886A9a30B56c] = 6;
        stakerSnapshot[0x4ae0e898A9E0deE985E7f35F5630e2eDe0cD6216] = 4;
        stakerSnapshot[0x4bf1fF6D70a2ECe1cBA5Bb18FDC2444f3D40Aa1d] = 2;
        stakerSnapshot[0x4C0aCA1031913e3C0cA7A1147F39A8588E04c55d] = 2;
        stakerSnapshot[0x4C981C345e9047524f793e8b5E15f2089320842b] = 2;
        stakerSnapshot[0x4Ce8BDc18e257dB9ea29D11E290DfbA99431dDd9] = 7;
        stakerSnapshot[0x4F4567044DE8f48A70e9e17Bd80fFA3F8e80C836] = 4;
        stakerSnapshot[0x4f56215bFB5E76fA6849Ae3FdEf417C19cD9AA23] = 4;
        stakerSnapshot[0x4F94eE0B6d2a31cb9BeFEEF2d95bF19F3a63E7Dd] = 4;
        stakerSnapshot[0x535FF5ACFeE41Fd02F01667dDd25772D8f8A231D] = 1;
        stakerSnapshot[0x53965cd7992BC61b4807Aa7aCe3Bec0062c90dE2] = 2;
        stakerSnapshot[0x542B659331442eAcFE2EF1a135F31aF1c107FE3A] = 4;
        stakerSnapshot[0x5615bCb489147674E6bceb3Cda97342B654aBA81] = 3;
        stakerSnapshot[0x5709D86f9946D93a2e1c6b2B6C15D6e25F37B19B] = 3;
        stakerSnapshot[0x57140a5EC315C7193DeFA29356B1cBd9a1393435] = 7;
        stakerSnapshot[0x575543b79Ab9913FA322295e322B08ef6C023a88] = 2;
        stakerSnapshot[0x5758bc7DcBcb32E6eBDa8Fe951E5a588e8a7A097] = 2;
        stakerSnapshot[0x578D7d391B4F34E35B4ca669F6a1dC18c04bB451] = 2;
        stakerSnapshot[0x581ddECBf2E27a06A069D67Fc7fb185eFB3c3d5f] = 3;
        stakerSnapshot[0x584a1d14920A49C8d19110636A2b435670CAf367] = 1;
        stakerSnapshot[0x5970F4d785A81b774D58330f47cD470fc3599848] = 3;
        stakerSnapshot[0x59b8130B9b1Aa6313776649B17326AA668f7b7a6] = 6;
        stakerSnapshot[0x5A512866D6E2a5d34BcdA0C4a28e207D2a310B60] = 2;
        stakerSnapshot[0x5C55F7eD0CDfE0928b19CA0B076C26F98080a136] = 2;
        stakerSnapshot[0x5Da07C2959C9815FEcEaC21FD7547C7E684c2431] = 2;
        stakerSnapshot[0x5DF596aa9315cd8B56e5C1213762F5b482Cb8aDA] = 1;
        stakerSnapshot[0x5f5B53E9e65CEbDc9085A73B017451f79B9d0158] = 2;
        stakerSnapshot[0x5fa19516d4A9AB74B89CeBc4E739f9AbdF69d7Bd] = 4;
        stakerSnapshot[0x5FDC2E1c58308289d8dD719Db2f952258e28ec96] = 1;
        stakerSnapshot[0x600cFB1736626C03dF54964ef481861eD092A7a0] = 2;
        stakerSnapshot[0x60cF1FCb21F08E538B16B0579009EF35107fDd53] = 1;
        stakerSnapshot[0x612E900a95Cd662D6c7434ECcCaA92C5CDf05F25] = 12;
        stakerSnapshot[0x61D7f4Dd8b5D8E9416fE8Fd81224171cAA32112b] = 2;
        stakerSnapshot[0x62e0C4336370184873224EC5ebeE4B6567d5602d] = 2;
        stakerSnapshot[0x62E725f096666Ef2f05fF3AAF4d0b042b3Eef5B8] = 7;
        stakerSnapshot[0x63E80354A787f7C876eb3C862BC93e36fCC1F310] = 4;
        stakerSnapshot[0x64Bc737b1A030aaC323c073f11939DB7b9e8F347] = 10;
        stakerSnapshot[0x6576082983708D32418d7abe400E2Df4360aa550] = 1;
        stakerSnapshot[0x657C61B33779B526BBbd6d5A24D82a569717dCeE] = 3;
        stakerSnapshot[0x668ca185c3cDfA625115b0A5b0d35BCDADfe0327] = 81;
        stakerSnapshot[0x6868B90BA68E48b3571928A7727201B9efE1D374] = 30;
        stakerSnapshot[0x68E9D76F37bE57387CF6b9E1835b04CC957aa2E7] = 20;
        stakerSnapshot[0x695f28D97aDF81DE4C8081aEf62d16d7B60fD35B] = 10;
        stakerSnapshot[0x697Dc0e8A3b3e3758f59f32BE847b2290823dBC1] = 42;
        stakerSnapshot[0x698f345481Fc1007C5094D8495b01DF375E4E4a7] = 2;
        stakerSnapshot[0x69B2803c04fec9505113038E1F91257A337DF63e] = 2;
        stakerSnapshot[0x69fD02C1Cf7659D3D095c4Ce73B5d5C23886B5f6] = 3;
        stakerSnapshot[0x6b140e5a9F6B6967Af30F789414840E2FFe1bdE9] = 2;
        stakerSnapshot[0x6B703CbB3cA5FE26cA9054F95c808facD7B57bCA] = 2;
        stakerSnapshot[0x6bA9BAb89e215DA976776788630Bce75E331B87d] = 1;
        stakerSnapshot[0x6C719836105879783760EAef03A8E004482eD33C] = 7;
        stakerSnapshot[0x6C87622a5de8cf0B5E7d4Dd2e6d9EBedBBF6289C] = 6;
        stakerSnapshot[0x6c9E0941eD2Fe399bfdd30Afb91A89db3f719f78] = 20;
        stakerSnapshot[0x6D28439B6c5A022B8C50C1AA0b8a8dA4B416FA6f] = 1;
        stakerSnapshot[0x6F8a67326832E81F0c13c69EcC9Bec618F707526] = 6;
        stakerSnapshot[0x6F9fc508dC77FD4ABEa9d72c91E7133703a2F38F] = 20;
        stakerSnapshot[0x7270B7aC52ee19a1c07EFE24574B0360f9bCaa76] = 2;
        stakerSnapshot[0x72b113664DEC5094Efb4431C39Ed4da003De59cd] = 74;
        stakerSnapshot[0x7357f081E79760e157E6C4215a35ad0233260f66] = 1;
        stakerSnapshot[0x74F499133eD684dA42B83afb1592aEc92F48228a] = 2;
        stakerSnapshot[0x75f9406bb829b6ad1313dB7FFf421E1E959D010b] = 8;
        stakerSnapshot[0x76239D6b1D37E0058D89C06c21BE4A14C492b301] = 2;
        stakerSnapshot[0x76E8D76759Acd20220F17f0dCdeb5768Be535152] = 2;
        stakerSnapshot[0x76F8a5c06857b44E1D459671b00708c7502c7999] = 2;
        stakerSnapshot[0x7836989949554501AC5D021b7BaeF6c992f1B854] = 3;
        stakerSnapshot[0x798A7D6F30DCaa0c060c8514E461c005A0400458] = 2;
        stakerSnapshot[0x79adc74978a81EB68D11Ab69558b11BECDD88DeC] = 6;
        stakerSnapshot[0x79c837F954CaEae493FaA298B0e0DcF0d5BAb20d] = 2;
        stakerSnapshot[0x7A0AB4A019f5B9626db6590F02d07f8Ee504Ae8A] = 2;
        stakerSnapshot[0x7a600C045eF72CE5483f7E76d4Fe5bEfFCdEE6aC] = 7;
        stakerSnapshot[0x7A60A3f8377a202E31d9Ff70A9Ebaee6c60D8db8] = 2;
        stakerSnapshot[0x7a6651c84D768c8c6cB380B229e65590c0BD4D78] = 13;
        stakerSnapshot[0x7b9D9cD877784D19A0977Aedb9f8697Bf7aaad9E] = 2;
        stakerSnapshot[0x7C68f66C70836c9745AC42a5Ab2A5C3f8F3D3294] = 2;
        stakerSnapshot[0x7CdA50Bed220eA0860d60095B27Ee4F744511bb9] = 1;
        stakerSnapshot[0x7D198D4643DB60Fd6E772470B03A079e920EcC19] = 31;
        stakerSnapshot[0x7E5F3d3C54B4185b3430005E2354817331F23550] = 3;
        stakerSnapshot[0x7Efbcb80C47514a78Cdf167f8D0eed3d8a1D7a00] = 6;
        stakerSnapshot[0x812005457367912B4FcCf527a13b4947d177E8c6] = 1;
        stakerSnapshot[0x816F81C3fA8368CDB1EaaD755ca50c62fdA9b60D] = 3;
        stakerSnapshot[0x82023a7bf582E1C772a1BcD749e10C0AFD7aB04E] = 2;
        stakerSnapshot[0x824189a4C3bc22089bC771b5c9D60131Fd1252a7] = 20;
        stakerSnapshot[0x82e928D20c021cAbBd150E7335f751F71A30cBcA] = 2;
        stakerSnapshot[0x83A9e7FCCb02a20E7ba0803a6dc74600803BB320] = 8;
        stakerSnapshot[0x849f03ACc35C6F4A861b76e1F271d217CD24b18C] = 2;
        stakerSnapshot[0x854C162aA246Ffe344262FC1175B6F064dB7250E] = 20;
        stakerSnapshot[0x870Bf9b18227aa0d28C0f21689A21931aA4FE3DE] = 2;
        stakerSnapshot[0x87cF0dd1272a6827df5659758859a96De9837EC5] = 8;
        stakerSnapshot[0x8902B48123201dBBadC20c40B1005C5Ad6250cc5] = 6;
        stakerSnapshot[0x89B91536A411D97837163987f3a33C15C5599479] = 2;
        stakerSnapshot[0x89d687021563f1A62DCD3AcaDDc64feF948F8fcb] = 40;
        stakerSnapshot[0x8a4892a38196d4A284e585eBC5D1545E5085583a] = 2;
        stakerSnapshot[0x8C2Bf3a4504888b0DE9688AEccf38a905DcEC940] = 4;
        stakerSnapshot[0x8c2Db300315DcB15e0A8869eA94F843E218a78B4] = 4;
        stakerSnapshot[0x8C409C76690F16a0C520EF4ECECBB8ad71017480] = 20;
        stakerSnapshot[0x8c7e78d32CB350D7B560372285610b5E46e67981] = 4;
        stakerSnapshot[0x8cCc7DA43DcbA6FEf07a318f88965e7aEEdB5eBc] = 12;
        stakerSnapshot[0x8D757F5675405271de9DDff392f7E7A717b5bddb] = 4;
        stakerSnapshot[0x8D98139512ac57459A468BC10ccf30Fd9dd6149A] = 12;
        stakerSnapshot[0x8f0CaCC1B3d0066A31Fc97c6CF1db1b0F56f073f] = 2;
        stakerSnapshot[0x8Fa3e7cb0c9C14FfBe750080A97ee678AD71a216] = 2;
        stakerSnapshot[0x8fd974089B612041C37eB643980C2A9C9BA85058] = 1;
        stakerSnapshot[0x9251af98d5649d1BC949f62E955095938897289d] = 2;
        stakerSnapshot[0x92aC315cb47B620F84238C57d3b3cc7F42078781] = 4;
        stakerSnapshot[0x92b398370dda6392cf5b239561aB1bD3ba393CB6] = 6;
        stakerSnapshot[0x92B99779Bc3471706A8f9Eb0F3975331e6664678] = 4;
        stakerSnapshot[0x93d751d48693AD3384C5021F821122bc4192B504] = 7;
        stakerSnapshot[0x945A81369C1bc7E73eb2D509AF1f7a067A253702] = 4;
        stakerSnapshot[0x95e3C7af64fFCDdA13630C7C10646775dc638275] = 27;
        stakerSnapshot[0x960A84baf0Ac4162a83D421CDB7a00Cc2777b22D] = 2;
        stakerSnapshot[0x964afBC4d4a80346861bB87dbC31a8610AE87fC4] = 4;
        stakerSnapshot[0x97111A057171E93aa7b2d63B4f6B5b7Bdc33EF8D] = 4;
        stakerSnapshot[0x995B7FABDae160217F378BbB05669Aa4bDcdc81f] = 1;
        stakerSnapshot[0x9B687413591Ad92cC1BC5cD5Fd442c04872D97DB] = 6;
        stakerSnapshot[0x9C9964733479a6E0758d97A7B89DcE81C20b19d7] = 1;
        stakerSnapshot[0x9e01852683b88D829551895C7BFd1799b121fdBC] = 4;
        stakerSnapshot[0x9f137fb2330e499607E1b1233dE2C1b90b1A7a85] = 4;
        stakerSnapshot[0x9FC7EdAC9dF5bCc75671EFF5A2c2898Fc4242636] = 22;
        stakerSnapshot[0x9Fe697f4d0D447409331681e0401a4f7E756fdD7] = 5;
        stakerSnapshot[0xA01D7E4e848467CBD2CA864150f27A9D286C86C8] = 9;
        stakerSnapshot[0xa07cb2c3861D34FA5686d52018dC401FF413F05D] = 7;
        stakerSnapshot[0xA0843Cf5DbEaf1EB3d7Cd31B372d6Cc06180b1Ab] = 2;
        stakerSnapshot[0xa0C737617b7E63e1CbF87C45c11cd766CF57Bd9D] = 2;
        stakerSnapshot[0xA1bE91b15E959294Cb6eFD7891c846cAf7ef7602] = 4;
        stakerSnapshot[0xa235Fbd83AD5B143bCd18719834C60BA7c925C52] = 2;
        stakerSnapshot[0xA2bff178071A266D14e360e3f3CE226B19D3F809] = 2;
        stakerSnapshot[0xa55F7eA2F6001DC6d046cFe799c3Ec4dC79cc5b8] = 3;
        stakerSnapshot[0xa62CBb35f5a51695F1cC550f3a8506Fc458D681D] = 2;
        stakerSnapshot[0xA6E3F06461A5d34fB3344FF6b45d6C92D207c35d] = 38;
        stakerSnapshot[0xa731325b4D01250Fe8852Fe76974F084d968e75D] = 20;
        stakerSnapshot[0xa784224c2F3c82c47abEda5D640e911633Cd24Da] = 4;
        stakerSnapshot[0xA8047DcE2A42968379E68870274ED2F534082Edd] = 3;
        stakerSnapshot[0xa8ad3C8D9039a0D10040d187C44336e57456fecE] = 2;
        stakerSnapshot[0xAa5B7f29C81B7409A021a2Bfe1E0FCec27EAD33E] = 2;
        stakerSnapshot[0xAaCDB53292F7703A608926799C9A02C9662923aa] = 4;
        stakerSnapshot[0xAb48De856930c018238c226D166Feaed3541Ec7d] = 1;
        stakerSnapshot[0xab516c4a5A0b705025a079814bDe84e846bCe019] = 20;
        stakerSnapshot[0xAb532bE7866818326D5A9cf86134eb0C2E95A8cE] = 2;
        stakerSnapshot[0xABa93498a69373b5E5f72254a513Bfaf77253d16] = 2;
        stakerSnapshot[0xACa79E56C92DeD769D2B773C8bab2aB552Ec5172] = 69;
        stakerSnapshot[0xAdc81042fEc23050b99EA6E08552a2bA439Df481] = 2;
        stakerSnapshot[0xaF9938ec47EbD29c93208f71f63d27b61E517522] = 20;
        stakerSnapshot[0xAfC9D3054f3047AA99347f4266a256BF2F6e12ca] = 2;
        stakerSnapshot[0xB0ea4466D71431E87B4c00fa2AECe86742e507b0] = 23;
        stakerSnapshot[0xb1ce4373890A21CC3Fd65480D72770496689a7Ba] = 20;
        stakerSnapshot[0xb1e2E3EA2A52Ee700403fc504429012FD733dD72] = 22;
        stakerSnapshot[0xB2A7CE5B1fAF0d1f4fF1a59fCa9D7ee24917FF81] = 4;
        stakerSnapshot[0xb37e6F4F7E3f74e447d860aAeB0E8783320c66bF] = 6;
        stakerSnapshot[0xb3C4fC3a65C2DF5d0f4e748BdC563bAB49d0399d] = 8;
        stakerSnapshot[0xB47832cA65E661b2b54dE39F24775C1d82C216f9] = 2;
        stakerSnapshot[0xb5048a3518C05F2dD51976e941047B54b0539ECD] = 2;
        stakerSnapshot[0xb5cA180081211730DD00d4fac6f4bEDF74e932Da] = 71;
        stakerSnapshot[0xB666A384e23da54C7DA222a2c3dE69a009Fae620] = 2;
        stakerSnapshot[0xB7Afe2297B5756B740193076e5CB2753aC582543] = 2;
        stakerSnapshot[0xB84404f79EbeF00233E1AEdB273c67c917B8840f] = 40;
        stakerSnapshot[0xB8545d529234eB2848C85c0CcC0a5Ce9B30a3C0b] = 6;
        stakerSnapshot[0xb87c4158b4A5766D67aA8591064bbe5126823514] = 2;
        stakerSnapshot[0xb908B613d695c350BF8b88007F3f2799b91f86c4] = 1;
        stakerSnapshot[0xBaB80520D514Df65B765A1f8990cc195559E6778] = 2;
        stakerSnapshot[0xBd50C7a6CF80A5221FCb798a7F3305A036303d2D] = 2;
        stakerSnapshot[0xBde69E440Bd3AbC059db71cE0bb75f31b92F37E1] = 2;
        stakerSnapshot[0xBE331A01056066311C9989437c58293AF56b59cA] = 4;
        stakerSnapshot[0xBe546e6a5CA1c2CfcB486Bb9de4baD98C88e7109] = 2;
        stakerSnapshot[0xBeaa9B4b26aEA31459dCA6E64e12A0b83e21A0dd] = 12;
        stakerSnapshot[0xBfEcB5bD1726Afa7095f924374f3cE5d6375F24A] = 2;
        stakerSnapshot[0xC25cea4227fA68348F025A8C09768378D338F8d6] = 2;
        stakerSnapshot[0xC261c472a5fea6f1002dA278d55D2D4463f000ef] = 4;
        stakerSnapshot[0xc3cf1A2962b750eb552C4A1A61259Fd35063e74e] = 2;
        stakerSnapshot[0xc42480b588Aff1B9f15Db3845fb74299195C8FCE] = 6;
        stakerSnapshot[0xC800391fDDcC6F899DCA185d5B16994B7D0CB13e] = 2;
        stakerSnapshot[0xcac8ca2C41b14304906c884DB9603A7B29D98Adb] = 5;
        stakerSnapshot[0xcB85e96ADE0D281eA3B5B8165cdC808b16Ac13b9] = 2;
        stakerSnapshot[0xcB91368B760f0d6F2160114b422A93aE50e44542] = 4;
        stakerSnapshot[0xcBa18510a6336F3975Cea1164B9C5d029E1A7C82] = 2;
        stakerSnapshot[0xCBc6C9CeF4f3C7cbBb8Eb82A2aD60c00e631A8C1] = 8;
        stakerSnapshot[0xcC507e6DDc3a6C992BC02019fbEeb8f81Be9FBb2] = 69;
        stakerSnapshot[0xcCE8A3fb91290071b377FE0EC3df0eb7ceA8AFFC] = 2;
        stakerSnapshot[0xcd1C78538E3Cc0D2ceadd87b8124357d86566365] = 3;
        stakerSnapshot[0xcE046B2a56fea1559dB99f7fB4e4570aaaFF9889] = 6;
        stakerSnapshot[0xce83bc7517B8435Eb08EB515Aa3f6c9386b1E2A0] = 6;
        stakerSnapshot[0xCF0268111e06d26e1B9ea813Fe49c40A4227778D] = 6;
        stakerSnapshot[0xCf7346Ba8d7D4D2A3A256b2FA00Daf5c7566351b] = 2;
        stakerSnapshot[0xd03a4E75A730eb5f700dfE71703CbaA99CB67532] = 6;
        stakerSnapshot[0xd054952345f497F7A9461a202E8f1284b885eE2F] = 6;
        stakerSnapshot[0xd2A41a1Aa5698f88f947b6ba9Ce4d3109623c223] = 2;
        stakerSnapshot[0xD4658C7c5b42cAd999b5b881305D60A72590f247] = 7;
        stakerSnapshot[0xd696d9f21f2bC4aE97d351E9C14Fa1928C886c61] = 2;
        stakerSnapshot[0xd69A21f89c463a96F9E916F84a7AA5ca8A9DD595] = 1;
        stakerSnapshot[0xd76A10B1916404eE78f48571c1a5Fa913aaAF72b] = 21;
        stakerSnapshot[0xD7d28e62b7221A82094292Ed59F1d9D86D32c39c] = 7;
        stakerSnapshot[0xD9AF96861dE6992b299e9aC004Aa4c68771d0815] = 2;
        stakerSnapshot[0xD9C925E7dB3c6F64c2b347107CAfDc75390A8744] = 4;
        stakerSnapshot[0xDafF72174cf270D194f79C4d5F1e1cDAb748fE14] = 6;
        stakerSnapshot[0xdb955C787Ea67964e1d47b752657C307283aE8c2] = 6;
        stakerSnapshot[0xDBbce16eDeE36909115d374a886aE0cD6be56EB6] = 2;
        stakerSnapshot[0xdc5B1B4A9730C4d980FE4e9d5E7355c501480d73] = 2;
        stakerSnapshot[0xDC6eB1077c9D84260b2c7a5b5F1926273Ae54578] = 2;
        stakerSnapshot[0xDD262F615BfAc068C640269E53A797C58410bAFc] = 42;
        stakerSnapshot[0xdDd1918AC0D873eb02feD2ac24251da75d983Fed] = 2;
        stakerSnapshot[0xE11D08e4EA85dc79d63020d99f02f659B17F36DB] = 3;
        stakerSnapshot[0xE18ff984BdDD7DbE2E1D83B6B4C5B8ab6BC7Daf6] = 2;
        stakerSnapshot[0xE2F7c36A7cFC5F54CfEA051900117695Cb3c6b2f] = 6;
        stakerSnapshot[0xe367B61Ab9bC05100fDA392fec1B6Ff2b226cF6E] = 23;
        stakerSnapshot[0xe54DEBc68b0676d8F800Aff820Dfe63E5C854091] = 2;
        stakerSnapshot[0xe5A923B2Db4b828Ab1592D10C53cfeA7080245B3] = 71;
        stakerSnapshot[0xE5b0e824DA704b77f5190895b17b990024a22A3E] = 2;
        stakerSnapshot[0xe66a52474370E0CbDa0F867da4D25471aA3C1615] = 9;
        stakerSnapshot[0xe717472C2683B6bca8688f030b9e0C65cFc52c99] = 2;
        stakerSnapshot[0xE7b770c6cf75325A6525E79A6Afae60888f3F498] = 2;
        stakerSnapshot[0xE8969399b899244291cE9AB2f175B3229Cd42ECd] = 6;
        stakerSnapshot[0xE9275ac6c2378c0Fb93C738fF55D54a80b3E2d8a] = 2;
        stakerSnapshot[0xe978aE285E6ca04Ef40Af882371A2E4A97cFC812] = 7;
        stakerSnapshot[0xEa02AB878834bA9551987CbA64B94C514DDe194F] = 2;
        stakerSnapshot[0xEA99a428D69aa84aD9a20D782Cde4a1e6c3E9017] = 6;
        stakerSnapshot[0xEa9f6ec11914703227A737A670c4Fc5A7b20CBFc] = 65;
        stakerSnapshot[0xECA576463eA8aFB5A21e0335f0c4F4e4a414156b] = 2;
        stakerSnapshot[0xeCBCeA720dAc9dCFaA7024B80DB92755b8836785] = 4;
        stakerSnapshot[0xeE2020eeD81905C8964A4B236B858A1A6eB5889e] = 2;
        stakerSnapshot[0xEf85AB7726Fb85CEf041F1e035AbD5e6844B660E] = 2;
        stakerSnapshot[0xeFeb821368e89336f7110390A12c98fF95794fa8] = 2;
        stakerSnapshot[0xF1595c576370A794d2Ef783624cd521d5C614b62] = 2;
        stakerSnapshot[0xF2557A90C56CbB18b1955237b212A0f86A834909] = 4;
        stakerSnapshot[0xf2cfA31187616a4669369CD64853D96739ef999C] = 7;
        stakerSnapshot[0xf39C00D5bCDF098bAB69385b56ee8140EeB105a1] = 2;
        stakerSnapshot[0xF3D47f776F035333Aaf3847eBB41EA8955a149F4] = 2;
        stakerSnapshot[0xf416526650C9596Ed5A5aAFEd2880A6b3f9daEfc] = 4;
        stakerSnapshot[0xF45bE2e48dFD057eB700653aDA23d95108928FEF] = 2;
        stakerSnapshot[0xF7f9eF971B6377493Da1CD7a7206F603f190CDa5] = 2;
        stakerSnapshot[0xF90A20105A8EE1C7cc00466ebcC72060887cc099] = 12;
        stakerSnapshot[0xf944f5715314af4D0c882A868599d7849AAC266F] = 6;
        stakerSnapshot[0xF98DA3CC07028722547Bb795ce57D96bEbA936bd] = 4;
        stakerSnapshot[0xfb5D7141feaCBBd6678fD37D58EE9D19e01Df8EE] = 2;
        stakerSnapshot[0xfBBAc3c308799E744C939eaB11449E3649C1e52D] = 20;
        stakerSnapshot[0xFCc36706699c5cB1C324681e826992969dbE0dBA] = 6;
        stakerSnapshot[0xfE3Cf487565A3Cd275cb2cbf96a395F023637D86] = 2;
        stakerSnapshot[0xFeb244CDc87A2f3Feb9B10908B89fEd816E67B5a] = 70;
        stakerSnapshot[0xFECE31D9eD6B02F774eB559C503f75fc9b0bcE4E] = 2;
    }
}