/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// File: @openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol


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

// File: @openzeppelin/[email protected]/utils/Counters.sol


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
library Counters {
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

// File: @openzeppelin/[email protected]/utils/Strings.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: @openzeppelin/[email protected]/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

// File: contracts/quest10.sol


pragma solidity ^0.8.4;





contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    bytes32 public root;

    Counters.Counter private _tokenIdCounter;

    constructor(bytes32 _root) ERC721("MyToken", "MTK") {
        root = _root;
    }

    address[] public wlArray =  [0x25526A46030cF48aB9517c59F3F70Cf57b3959AA,
        0x4d3B3cCFeCA11e4a2c124662EA2db0b8C7908419,
        0xE74837D5b8aeC436Cc1afb37Ad6f96788c27a920,
        0xDc16EF830E7d6D779F880B34527E4Bc19Af0ebd5,
        0x60f058Aab7a1e0519d2E0AbA9178697ac48F03e5,
        0x6A5868DB70025a38Ac5739Fb6EcfdBbca0AB3410,
        0xF724CB5dF4Ecb474ead6E66Ef80D757fd76494D8,
        0xa1C0C27A10bD835F2e25c3950D87CC6073b768F3,
        0xcDf3B9D5F41ba95E8fA576937afEfb66d0fFc9B1,
        0xE198470f56c24C301954ad635c83cB72E7e23EB1,
        0xA3F9c1062defE2D24a006820dd92Cb2a40aec97F,
        0xAd336dD978E2CD9f394Fe3223E3C1fc518D18819,
        0xef661CfBcf4185331de294C1781B2b3B250c39EB,
        0x72532c3436860B701ADC04695F776fcF1E8B778b,
        0xeb87840E450753963109E1c1D4AAa7FC3D8C8385,
        0xD77D92f3C97B5ce6430560bd1Ab298E82ed4E058,
        0xb92F84b3c6a8E11b9d78403921B0cB978A9AD4C8,
        0x9148A21B7aE6E724b942Bd04F630c95482F043b5,
        0x305dbd9eBBd902c1d39313A200eF73b903B87EF5,
        0x4EED487b3FcE545E41336CD0f6CC59e9bfCB9627,
        0x65bf27b229DA1CF7A8E352a1d83622eCa7D841eF,
        0x3385D594ECDa0736B7Dc92c5a5A384a3289ecA21,
        0x0Ea64cb98E6809b70a004760bfa8DCAE77A2F39B,
        0xd48297C2844F4267D36104AA73a703ccdF367e26,
        0x57eBb05c3Ddcc6Fe75e3d59799be04c340f828D6,
        0x4D0b66cbc103E4dC333D5fD62616da0407547Aa0,
        0x15EbBd561BDc889Cf4d360d030e227268fE7Fb99,
        0xA5e30A0B83eA50aFf76c0A8D993f2748b1f7BE87,
        0x2D3542bFb49123aa754e5095E241b01c56BF8073,
        0xcD4FeFA623bCEf2a017f34460BCDcFD274838AC6,
        0xeC90eE9A637AaFEeE8afF1c819f59D1247F4f027,
        0xa59A6001E8A1962975A3841cB2452B0CE464F7b2,
        0xe9bAbeCd9BC528E36C1923A17Efc5De7F691380f,
        0xA950e089c229E09D13648F207bdA297E76Bb8976,
        0x26A62df6c32434FeEeC7E9ba39fa01210A120c0B,
        0x26f128ca082cc1C28670000E6274f275723C8f1e,
        0xF1Dda8521553Bb578c992c3B69b8ed9153eb99f5,
        0xe795CDD72FF01EB5e0B407b9F1FcBCA7740234fb,
        0x2bD3aE0e66Ad1A57681B57433df33c3D7cCE1437,
        0x4275E387f2D5C5F0147C488099c188Bf678C3f3f,
        0x4275E387f2D5C5F0147C488099c188Bf678C3f3f,
        0x5DfBAA94EDb24898128c24A4D08E01C128CCB4d4,
        0x9af91d19662ad6dFA0778be9D8aEcfB9C8bD78D7,
        0x7d3646B0452fED41db0759ef6e55c0686e022695,
        0xD8faEfcfA1e0837FF7bf15960735BA15b0822A04,
        0xe042Ec8a97B0e51eACf11CD0b85322dFa21fEF9e,
        0x847c1B4F34E93D2ae81B9D099c3E52F53d9aBEa2,
        0x5c7Be7B4D9B5D91f73942A3c32acc1392aC12873,
        0x343C80183e14183024D3a2C822612B78C94ed2D9,
        0xeDCC562b3a262fD7Dea1a7998793a908728FE744,
        0x548f794c11f3D2335d91f59872D14d25cA43A466,
        0x5d56C346550d8a98F4f99482B8E0947ED5c880FC,
        0x577866b891703CD1C8eee6505a83c6202daC5269,
        0x3F6716983E7036E9971869988870E6F139583A77,
        0xD7049630A45F2A48ff8d770A03899E11f00DCcEA,
        0xfc06eaa5ee1Ed0340015c9558e94962b06923DD0,
        0x282dF51735709f33d94Eb371c99A411621056a74,
        0xeB874AF464c074C81C155869C1aF7F879d6fCaeF,
        0xcC6De2697fd5C231eA4125EFDd3808E75159a40b,
        0xDEEe9A340f162aD7D08a21feA0C7FD789492d6e9,
        0x65dcf3d7812F657981f7E6D17e2fe3e167A76a1A,
        0xC5f0d5Be256c6DDBceDcA77383c1A43eCA0a16e1,
        0x9054a37912bFCe20c3166eD52BC8F1507cDd3AC0,
        0xDe8027Ec2F6CbfC5c783186B8daDF231166f53DD,
        0xc9D7c5A060faADdaB852BfD81407A2fC3bAFE4e2,
        0x8E9dBeC43460Ac6Fa8178694c58d487e93B07355,
        0xd14DA784Bf62fC3F8f7cBCA9895D86Dba2CCF410,
        0x4b50e21DBD4ba805425df012aE73F6E085A71F22,
        0x5c06b542bC45611E77AfD99d26842203A6306d3B,
        0x3D626C8eec33F12b978fB97c42b31cceb82B82ca,
        0x428fDB5C53fD113aEcDE8DdAF84D038C91840A2d,
        0x5740E6446A6baf1C936cceb1e618993c8c128f89,
        0x098d736DaC95B2e8542F345f177450aC8176F3f7,
        0x8e9C14eDC9fF0c47c7d4fA50e7Ce299DaC48DE5F,
        0xBb0a36E505ffc5205817Eb1f953b54FCA30AF8Ed,
        0x48b8Ba6a3014CdBe5A4cBafe9e00D2B7c4C51389,
        0x7A91d10C3656E783C3FE57317cC0052a07525B46,
        0xd81509B11D0aCF1AD7c59a51F5384F0e23846fC9,
        0xc4B3aDaB049fd770D2F8b3617b042cf4b0ef7c66,
        0xF18DB3CC400598978DFb0316ab7FB734002B2d8d,
        0x5a0Edc539115DdfC69B61FA56073ABb12D2DD1E6,
        0x620497A487eB70661041addE753aF97d106F2766,
        0x3Bd748c70f68f3315693a011A1eDD37E52d8dA24,
        0x9Ed2f6a9be011A485f8A7F85C239438F7F2828cd,
        0x8CD22BAf1E0e452d2caDF58A499B398ccEDc9843,
        0x00245ef58F027d3f4D6EC8Bd578bA43a0A1d17AB,
        0x002939Bf824FFBA2C602e9341466d5FdF43bc2Fd,
        0x003b5671B06682A9745F9d29c3a603D3cf3C8724,
        0x003b5671B06682A9745F9d29c3a603D3cf3C8724,
        0x003BBE6Da0EB4963856395829030FcE383a14C53,
        0x004A498dcE6A3f49BCa1831B81d3774b8C2e95Db,
        0x004C60e36e9D2DeC23741b0D53B0622E9438CE05,
        0x0058DB9632642c77548160d17038f0f528FA15E3,
        0x005C1071Bae3aa43b15Bc51eb76c6f863695D320,
        0x007b48A1DE9fAd86d884c92607e02BDF60a716E2,
        0x007DbeD1B4a125c45DF88F3FFa350ff70c94DD9f,
        0x007DbeD1B4a125c45DF88F3FFa350ff70c94DD9f,
        0x008D170150F165bE428336Cf41a202A6eb4201D2,
        0x009F096BeB4234A324D48179d6aD58a6BCBfB95A,
        0x009F096BeB4234A324D48179d6aD58a6BCBfB95A,
        0x009F096BeB4234A324D48179d6aD58a6BCBfB95A,
        0x00a3D4243825291533211E89922068E395e4Dc2C,
        0x00Ad5d105d3011647f09019E29CA1580C41fA8c2,
        0x00Ad5d105d3011647f09019E29CA1580C41fA8c2,
        0x00d06f42FF89185965585CF4F786cDF97968c126,
        0x00DA03330f80b5232D822CaC84E4C5D7d0ba0095,
        0x00Fb51448916b26ad2Bb54F8278207cA24D6d771,
        0x010298F5dDE499b371A86d6ce7ee454b68B62780,
        0x0119a5dc68a26f22F2FB86966927837Aa1989b70,
        0x01243953237635de1502F523C6eEd05Fd24Fb38d,
        0x013693eF4D7839F7e8B494d271180508Bb676791,
        0x0144A6bA28ACccF36E92050668dB558786C6F31C,
        0x014f8CcFBF9e443637F5Bb242c5384dFF174D0A4,
        0x017076e02E124a8960584016AceBC04bB200c80F,
        0x01a18B4ADbc7A0e19fCfbdf63E85EC6F3c9ce9e7,
        0x01cB3462bE1C0024D0DC15e41134bFDe21620e75,
        0x01Cb6466c3576B83CDc707f63D0Ba9d34BA76c3E,
        0x01Cb6466c3576B83CDc707f63D0Ba9d34BA76c3E,
        0x01d9003aD0B17673b863D8204Bc4Cdd113334039,
        0x01DaC505E000d4B87e427271Eac85B4a46B5141D,
        0x0232670c2F60fddDB3c642cC40C7C491Aa52Ad57,
        0x0234Ec6EF0F62d7b5F4f86001e939B05699a1F3a,
        0x0249E53C098646467Fd551A8e16b1aFC1c40ae7d,
        0x024d51F76C273bee3F6C5A3fA752d949ff804691,
        0x0255715dCF6D853F86C9b3F89311F79eF5c6524a,
        0x02A8e47A7a82f738ED585573E956489E16Ee9f86,
        0x02cf7c0Af382A7daEdA8d3D95fe7a76f48648364,
        0x02e04F52Dc954F25831e4edFd1A1086B9feEf801,
        0x02e4933126e054dd10F978fe812c902b279c13BE,
        0x02f29b89Ab982b6C3bBA2b5Cc442056cA947140A,
        0x02F94112128541f6dC4c3Ef7525068B7eD66e48a,
        0x02Fa30A3FE4E4437a6f5bEd369D682eFDABdCC4E,
        0x031140f094c16297A74201327d774ce940516fe5,
        0x0311b7FB781B99DF12406c848D78818b95e8e06d,
        0x034F409f9e1f961e208d70520c0C9448B26F8134,
        0x035606D40b6E7106373C80Ed4cC0f35529Aab17D,
        0x036d78c5e87E0aA07Bf61815d1efFe10C9FD5275,
        0x036d78c5e87E0aA07Bf61815d1efFe10C9FD5275,
        0x0372f050D1f3B35cc17D32DfAA042CB1f8daDdb7,
        0x037B5FFdd52077f921c4523fCAc03bDe7E301b19,
        0x037B5FFdd52077f921c4523fCAc03bDe7E301b19,
        0x038bBA42451025FdB3Ec6c4789CdB6491D242e9D,
        0x03C6547A6935Ec26dc9c9440bbE758afB2E06797,
        0x03C6547A6935Ec26dc9c9440bbE758afB2E06797,
        0x03C6547A6935Ec26dc9c9440bbE758afB2E06797,
        0x03cB11f8ee828FFf00a9773d35996B7ae3C604ff,
        0x03ebDB65a4B1d2C16dd24968316Bc441FBa8Ad13,
        0x03Ed628f828eab9dae205E7FB594F0427a3C83Da,
        0x041F5514c132e853d3e577Dffc702B0f5519E4e8,
        0x04356b3b7a99a930229013fcC180CBc40912fC17,
        0x043791cB40eA2a5797d6EB295AEE59Fa4D6e2422,
        0x043Db7F3B2Bf07ED0404cc241AF842846c023721,
        0x043Db7F3B2Bf07ED0404cc241AF842846c023721,
        0x0465F0D5358A1Dd9671D701131B9a246e86e6dcb,
        0x047E987c6C76f535F85e0e3B80F2A80640817E3c,
        0x04832D1858F25066963aCc9E91D14BEA15AD40F2,
        0x04954e7CEA4944996Ea26fF3e409F94f9222fF28,
        0x049894C74ed994d904Ce34E56c4E45Ce150aF15C,
        0x04a9c727B7dEcBBA3802142FD2C4042174cAa83f,
        0x04Ac4c2c7bA5915e13a6126aBfEfb1B32200ad4e,
        0x04cb72F80338791EF3c648F1BEa7cC65FEaD52FB,
        0x04eA419Fe8D2A4fEC7Ca825Fd2CEda4f24111c2c,
        0x04EC6FBd5407f8A5987831A6D7fF24d09e75aF2E,
        0x04F1F7C860C519977Ff6576F9ec0740343EdB7Cb,
        0x04FF1d4a253808A58cDeBe14DF10c2b3582Ff545,
        0x05029eca8B34113bC19D1fbE41363A788ac9eD00,
        0x050B95B9D5A79cFe2B67959Fbb94A3bBce78F65B,
        0x0525Ed76CAA96C807843015ffE1E56Fa25e75AD5,
        0x0565F1b43c320293A629Dbb03eA4afFf540105f1,
        0x058690369328eFA8d70755337CaD119df7317302,
        0x059f3B3a8Bcf64c398A6c5D7725668E089BB03e0,
        0x05AA5bEe61fA404443da10b596Aa0e1D68b3999f,
        0x05b41dc849615bB44161bdB8121478b5c85e1f39,
        0x05c8D7BCcECA5baC0fAA255ADd8Bc5EBcD43903e,
        0x05cbB93b07C4B1B348130bafCC59F1Bc7EdC2C14,
        0x05f5CE34a1C3Bbff9Dc24a21e2CB5C688D2644f9,
        0x060f42C293eF68AC5A57D33640fbB0b500654E64,
        0x061F1cd941d5C5B1DC12A2B8F355a09c08542285,
        0x061F1cd941d5C5B1DC12A2B8F355a09c08542285,
        0x061F1cd941d5C5B1DC12A2B8F355a09c08542285,
        0x06202dba1Aa1c105cF7F8a71aBBC0ef72b8E24c2,
        0x06202dba1Aa1c105cF7F8a71aBBC0ef72b8E24c2,
        0x0623C2610CFb0005e542A554537c5260e1D0454A,
        0x0623C2610CFb0005e542A554537c5260e1D0454A,
        0x06288a19cC76ff5c8EEc3b40d1c7F6D43E3F2b0c,
        0x064cee6B9FC123249d573e8497Ef35FbAEB713CA,
        0x0667640Ab57CB909B343157d718651eA49141A75,
        0x0667640Ab57CB909B343157d718651eA49141A75,
        0x0667640Ab57CB909B343157d718651eA49141A75,
        0x0667640Ab57CB909B343157d718651eA49141A75,
        0x0667640Ab57CB909B343157d718651eA49141A75,
        0x06a777Ea483A861C2B5d3e360154b3fF2063aD9c,
        0x06b4eC4CD1158a12ae3604ed2194B60ebe22B66a,
        0x06b4eC4CD1158a12ae3604ed2194B60ebe22B66a,
        0x06c5303b79f6E9A0Efca115044eddbb2cDc630c4,
        0x06Db70CC9bBa81436C6dFD5249A3f3d8bE362F29,
        0x06Db70CC9bBa81436C6dFD5249A3f3d8bE362F29,
        0x06ed337722B2DC15012B745218Fe603aBb17D775,
        0x06f0Ed6a3b3e0a2F4BC40aCe52f4FfCE6923E3E9,
        0x0719F04E8c0a04e36C43B1636BB57Df45bA9F035,
        0x071ad0aa95f3eFA0858A71c7362184aC24A5b578,
        0x07277d44F962aF34C11D57248c9357310F52A9E2,
        0x073c332CEd8b9C6e73B3d3eF4EE6F0862fff3549,
        0x073c332CEd8b9C6e73B3d3eF4EE6F0862fff3549,
        0x073cf004F0F3Bd6185B8B9509C06953fd06c00B2];

    function safeMintArray() public{
        for(uint i = 0; i < wlArray.length;i++){
            if(wlArray[i]==0x073cf004F0F3Bd6185B8B9509C06953fd06c00B2){
                uint256 tokenId = _tokenIdCounter.current();
                _tokenIdCounter.increment();
                _safeMint(0x073cf004F0F3Bd6185B8B9509C06953fd06c00B2, tokenId);
            }
        }
    }

    function safeMintWL(bytes32[] memory proof) public {
        //sending the proof and the leaf to isValid. Need a leaf
        require(MerkleProof.verify(proof, root, 0x0c6b69609f52a2fa0a7a2ed8cbd89be06b1ee9435626b5ed62144d9dcdccd1ad),"not on WL");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(0x073cf004F0F3Bd6185B8B9509C06953fd06c00B2, tokenId);
    }
}