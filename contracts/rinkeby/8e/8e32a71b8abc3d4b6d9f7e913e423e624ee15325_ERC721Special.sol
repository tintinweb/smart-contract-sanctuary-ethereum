/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
// Developed by: tokenstation.dev (pafaul)
// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/FeesDistribution.sol


// Developed by: tokenstation.dev (pafaul)

pragma solidity >= 0.8.10;

contract FeesDistribution {
    uint256 internal totalPercentage;
    uint256 internal totalFees;
    mapping (address => uint256) public _comissionPercentage;
    mapping (address => uint256) internal _lastKnownAmount;

    function _getFeeAmount(address user, uint256 currentAmount) public view returns(uint256) {
        return (currentAmount - _lastKnownAmount[user]) * _comissionPercentage[user] / (totalPercentage == 0 ? 1 : totalPercentage);
    }

    function _setLastKnownAmount(address user, uint256 amount) internal {
        _lastKnownAmount[user] = amount;
    }

    function _setUserPercentage(address user, uint256 percentage) internal {
        if (totalPercentage > 0) {
            totalPercentage -= _comissionPercentage[user];
        }
        _comissionPercentage[user] = percentage;
        totalPercentage += percentage;
    }
}
// File: contracts/MerkleProof.sol


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
// File: contracts/Whitelist.sol


// Developed by: tokenstation.dev (pafaul)

pragma solidity ^0.8.0;



contract Whitelist {
    bytes32 internal _whitelistRoot = 0x00;

    function _setWhitelistRoot(bytes32 root) internal {
        _whitelistRoot = root;
    }

    function __Whitelist_init(bytes32 root) internal {
        _setWhitelistRoot(root);
    }

    function isWhitelistRootSeted() public view returns(bool){
        return (_whitelistRoot != bytes32(0));
    }

    function inWhitelist(address addr, bytes32[] memory proof) public view returns (bool) {
        require(_whitelistRoot != 0x00, "Whitelist merkle proof root not setted");
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, _whitelistRoot, leaf);
    }
}
// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;



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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: contracts/ERC721.sol


// Developed by: tokenstation.dev (pafaul)

pragma solidity >= 0.8.10;








abstract contract ERC721 is Initializable, ContextUpgradeable, IERC721MetadataUpgradeable {

    using StringsUpgradeable for uint256;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    
    uint256 public constant MINTING_LIMIT = 10000;

    address[MINTING_LIMIT] internal _owners;
    address[MINTING_LIMIT] internal _allowances;
    mapping(address => uint256) internal _balances;

    mapping (address => mapping (address => bool)) internal _operatorAllowances;

    string internal _name;
    string internal _symbol;
    string internal _uri;

    /*************************************************************************** */
    //                           ERC-721 Metadata                                //

    function __ERC721_init(
        string calldata name_,
        string calldata symbol_,
        string calldata uri_
    ) internal {
        _name = name_;
        _symbol = symbol_;
        _uri = uri_;

    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                           ERC-721 Metadata                                //

    function name() public view override returns(string memory) {
        return _name;
    }

    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(_uri, tokenId.toString()));
    }

    /*************************************************************************** */

    /*************************************************************************** */
    //                               ERC-721:                                    //

    function balanceOf(address _user) public view override returns (uint256) {
        return _balances[_user];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return _owners[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) 
        external 
        override 
    {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external 
        override
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) 
        external 
        override
        transferApproved(_tokenId)
        validTokenId(_tokenId) 
        notZeroAddress(_to)
    {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) 
        external 
        override
        validTokenId(_tokenId)
        canOperate(_tokenId)
    {
        address tokenOwner = _owners[_tokenId];
        if (_approved != tokenOwner) {
            _allowances[_tokenId] = _approved;
            emit Approval(tokenOwner, _approved, _tokenId);
        }
    }

    function getApproved(uint256 _tokenId) external view override
        returns (address) 
    {
        return _allowances[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        _operatorAllowances[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _user, address _operator) external view override returns (bool) {
        return _operatorAllowances[_user][_operator];
    }


    /*************************************************************************** */
    //                             ERC-721 internal                              //

    function _transfer(address _from, address _to, uint256 _tokenId) private 
        validTokenId(_tokenId) 
        transferApproved(_tokenId) 
        notZeroAddress(_to) 
    {
        _balances[_from] -= 1;
        _owners[_tokenId] = _to;
        _balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private 
    {
        _transfer(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = IERC721ReceiverUpgradeable(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                                Service:                                   //

    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    /*************************************************************************** */

    /*************************************************************************** */
    //                             Modifiers:                                    //

    modifier notZeroAddress(address _addr) {
        require(
            _addr != address(0), 
            "Address is zero"
        );
        _;
    }

    modifier transferApproved(uint256 _tokenId) {
        address tokenOwner = _owners[_tokenId];
        require(
            tokenOwner == msg.sender  || 
            _allowances[_tokenId] == msg.sender || 
            _operatorAllowances[tokenOwner][msg.sender],
            "Transfer is not approved"
        );
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(
            _owners[_tokenId] != address(0), 
            "Token is not minted or burned"
        );
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = _owners[_tokenId];
        require(
            tokenOwner == msg.sender || 
            ((_operatorAllowances[tokenOwner][msg.sender] == true) && tokenOwner != address(0)), 
            "Operation is not allowed"
        );
        _;
    }

    /*************************************************************************** */
}
// File: @openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;






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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: contracts/Roles.sol


// Developed by: tokenstation.dev (pafaul)

pragma solidity >= 0.8.0;


contract ContractRoles is AccessControlUpgradeable {
    bytes32 internal constant ADMIN_ROLE = "ADMIN_ROLE";
    bytes32 internal constant REWARD_ROLE = "REWARD_ROLE";
    bytes32 internal constant AIRDROP_ROLE = "AIRDROP_ROLE";

    address internal _owner;
    
    function __ContractRoles_init() internal {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(REWARD_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);
        _owner = msg.sender;
    }

    function setAdminRole(address user, bool state) external _hasRole(ADMIN_ROLE) {
        if (state)
            _grantRole(ADMIN_ROLE, user);
        else
            _revokeRole(ADMIN_ROLE, user);
    }

    function setRewardRole(address user, bool state) external _onlyOwner {
        if (state)
            _grantRole(REWARD_ROLE, user);
        else
            _revokeRole(REWARD_ROLE, user);
    }

    function setAirdropRole(address user, bool state) external _hasRole(ADMIN_ROLE) {
        if (state)
            _grantRole(AIRDROP_ROLE, user);
        else
            _revokeRole(AIRDROP_ROLE, user);
    }


    function grantRole(bytes32 role, address user) public override _onlyOwner {
        _grantRole(role, user);
    }

    function userHasRole(bytes32 role, address user) public view returns(bool) {
        return hasRole(role, user);
    }

    function transferOwnership(address to) external _onlyOwner {
        _revokeRole(AIRDROP_ROLE, _owner);
        _revokeRole(REWARD_ROLE, _owner);
        _revokeRole(ADMIN_ROLE, _owner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _owner);
        _owner = to;
    }

    modifier _onlyOwner() {
        require(
            msg.sender == _owner,
            "User is not owner"
        );
        _;
    }

    modifier _hasRole(bytes32 role) {
        require(
            hasRole(role, msg.sender),
            "User doesn't have required role"
        );
        _;
    }
}

// File: contracts/ERC721Special.sol


// Developed by: tokenstation.dev (pafaul)

pragma solidity >= 0.8.10;







contract ERC721Special is Initializable, ERC721, ContractRoles, Whitelist, FeesDistribution {

    bool public whitelistEnabled = true;
    bool public isMintingEnabled = false;
    
    //Service:
    bool internal isReentrancyLock = false;

    uint256 private constant AIRDROP_LIMIT = 20;
    uint256 public WHITELIST_LIMIT = 5;

    uint256 public _defaultMintingPrice = 2e3;
    uint256 public _whitelistMintingPrice = 1e3;

    uint256 public totalSupply;
    uint256 public whitelistMinted;
    uint256 public whitelistNFTLimit;

    // Random
    uint256 internal nonce;

    uint256[MINTING_LIMIT] internal indices;
    mapping(address => uint256) public whitelistMintedByUsers;
 
    /*************************************************************************** */
    //                              Initialization                               /

    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata uri_,
        bytes32 whitelistRoot,
        uint256 reservedWhitelistNfts
    ) public initializer {
        __ContractRoles_init();
        __Whitelist_init(whitelistRoot);
        __ERC721_init(name_, symbol_, uri_);
        whitelistNFTLimit = reservedWhitelistNfts;
    }

    /*************************************************************************** */

    /*************************************************************************** */
    //                               ERC165                                      //

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, IERC165Upgradeable) returns(bool) {
        return 
            interfaceId == type(IERC721Upgradeable).interfaceId || 
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC165Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*************************************************************************** */

    /*************************************************************************** */
    //                             Enumerable                                    //

    function getNotMintedAmount() external view returns(uint256) {
        return MINTING_LIMIT - totalSupply;
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                                  Mint                                     //
    function mint() 
        external 
        payable 
        reentrancyGuard 
        mintingEnabled 
        whitelistDisabled 
        returns (uint256[AIRDROP_LIMIT] memory _mintedTokensId) 
    {
        uint256 mintingAmount = max(msg.value / _defaultMintingPrice, AIRDROP_LIMIT);
        require(
            MINTING_LIMIT + whitelistMinted - whitelistNFTLimit - totalSupply >= mintingAmount,
            "All available NFTs minted"
        );
        _mintedTokensId = _mint(msg.sender, _defaultMintingPrice, mintingAmount);
    }

    function mintWhitelist(bytes32[] calldata proof) 
        external 
        payable 
        reentrancyGuard 
        mintingEnabled 
        returns (uint256[AIRDROP_LIMIT] memory _mintedTokensId) 
    {
        uint256 mintingAmount = max(msg.value / _whitelistMintingPrice, WHITELIST_LIMIT - whitelistMintedByUsers[msg.sender]);
        require(
            whitelistMinted < whitelistNFTLimit &&
            whitelistMintedByUsers[msg.sender] < WHITELIST_LIMIT &&
            inWhitelist(msg.sender, proof),
            "User cannot mint using whitelist"
        );

        _mintedTokensId = _mint(msg.sender, _whitelistMintingPrice, mintingAmount);
    }

    function airdropMintTo(
        address _tokenReceiver, 
        uint256 amountToMint
    ) 
        external 
        reentrancyGuard 
        mintingEnabled 
        _hasRole(AIRDROP_ROLE) 
        returns(uint256[AIRDROP_LIMIT] memory _mintedTokensId) 
    {
        require(
            MINTING_LIMIT + whitelistMinted - whitelistNFTLimit - totalSupply >= amountToMint,
            "There is not enough free NFTs for airdrop"
        );
        require(
            amountToMint <= AIRDROP_LIMIT,
            "Amount to mint is greater than AIRDROP_LIMIT"
        );

        _mintedTokensId = _mint(_tokenReceiver, 0, amountToMint);
    }

    function _mint(address _to, uint256 _mintCost, uint256 _mintAmount) 
        internal 
        notZeroAddress(_to) 
        returns (uint256[AIRDROP_LIMIT] memory _mintedTokensId) 
    {
        if (_mintCost > 0) {
            uint256 mintCost = _mintCost * _mintAmount;
            require(
                msg.value >= mintCost, 
                "msg.value is too low for minting"
            );
            if (msg.value > mintCost) {
                payable(_to).transfer(msg.value - mintCost);
            }
            totalFees += mintCost;
        }
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint randomId = _generateRandomId();
            totalSupply++;

            _balances[_to] += 1;
            _owners[randomId] = _to;
            _mintedTokensId[i] = randomId;

            emit Transfer(address(0), _to, randomId);
        }
        
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                           Fees distribution                               //

    function addFeeWithdrawer(address user, uint256 percentage) external _hasRole(REWARD_ROLE) {
        _withdrawFees(user);
        _setUserPercentage(user, percentage);
        _setLastKnownAmount(user, totalFees);
    }

    function removeFeeWithdrawer(address user) external _hasRole(REWARD_ROLE) {
        _withdrawFees(user);
        _setUserPercentage(user, 0);
    }

    function withdrawFees() external {
        _withdrawFees(msg.sender);
    }

    function _withdrawFees(address user) internal reentrancyGuard {
        uint256 userFee = _getFeeAmount(user, totalFees);
        _setLastKnownAmount(user, totalFees);
        if(userFee > 0) {
            payable(user).transfer(userFee);
        }
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                            Roles functions                                //

    
    function setTokenURI(string memory uri_) external _onlyOwner {
        _uri = uri_;
    }

    function setWhitelistState(bool state) external _hasRole(ADMIN_ROLE) {
        require(
            whitelistEnabled != state,
            "Whitelist state is in correct state"
        );
        whitelistEnabled = state;
    }

    function setMintingState(bool state) external _hasRole(ADMIN_ROLE) {
        require(
            isMintingEnabled != state,
            "Minting in already in correct state"
        );
        isMintingEnabled = state;
        if (state)
            emit MintingEnabled();
        else
            emit MintingDisabled();
    }

    function setMintingPrice(uint256 defaultMintingPrice_, uint256 whitelistMintingPrice_) external _onlyOwner reentrancyGuard {
        _defaultMintingPrice = defaultMintingPrice_;
        _whitelistMintingPrice = whitelistMintingPrice_;
    }

    function setWhitelistParams(bytes32 whitelistRoot, uint256 reservedTokens, uint256 mintPerPerson) external _hasRole(ADMIN_ROLE) {
        require(
            reservedTokens % mintPerPerson == 0,
            "Invalid reserved tokens amount"
        );
        _setWhitelistRoot(whitelistRoot);
        whitelistNFTLimit = reservedTokens;
        WHITELIST_LIMIT = mintPerPerson;
    }

    function setUserPercentage(address user, uint256 percentage) external _hasRole(REWARD_ROLE) {
        _setUserPercentage(user, percentage);
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                             Service:

    function _generateRandomId() private returns (uint256) {
        uint256 totalSize = MINTING_LIMIT - totalSupply;
        uint256 rnd = uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp)));
        uint256 index = rnd % totalSize;
        uint256 value = 0;

        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;    // Array position not initialized, so use position
        } else { 
            indices[index] = indices[totalSize - 1];   // Array position holds a value so use that
        }
        nonce++;
        
        return value;
    }

    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        return a > b ? a : b;
    }

    /*************************************************************************** */


    /*************************************************************************** */
    //                             Modifiers:                                    //

    modifier reentrancyGuard {
        require(
            !isReentrancyLock,
            "Reentrancy guard"
        );
        isReentrancyLock = true;
        _;
        isReentrancyLock = false;
    }

    modifier mintingEnabled() {
        require(
            isMintingEnabled, 
            "Minting is disabled"
        );
        _;
    }

    modifier whitelistDisabled() {
        require(
            !whitelistEnabled,
            "Only for whitelisted members"
        );
        _;
    }

    /*************************************************************************** */

    /*************************************************************************** */
    //                                 Events                                    // 

    // TOKENS is deposited into the contract.
    event Deposit(address indexed account, uint amount);
    //TOKENS is withdrawn from the contract.
    event Withdraw(address indexed account, uint amount);

    event MintingEnabled();
    event MintingDisabled();
}