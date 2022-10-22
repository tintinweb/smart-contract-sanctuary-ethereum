/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

/**********************************************************************************************************
      ___           ___           ___           ___           ___          _____    
     /  /\         /  /\         /  /\         /  /\         /__/\        /  /::\   
    /  /::\       /  /::\       /  /::\       /  /::\        \  \:\      /  /:/\:\  
   /  /:/\:\     /  /:/\:\     /  /:/\:\     /  /:/\:\        \  \:\    /  /:/  \:\ 
  /  /:/  \:\   /  /:/~/:/    /  /:/~/::\   /  /:/~/::\   _____\__\:\  /__/:/ \__\:|
 /__/:/ \__\:\ /__/:/ /:/___ /__/:/ /:/\:\ /__/:/ /:/\:\ /__/::::::::\ \  \:\ /  /:/
 \  \:\ /  /:/ \  \:\/:::::/ \  \:\/:/__\/ \  \:\/:/__\/ \  \:\~~\~~\/  \  \:\  /:/ 
  \  \:\  /:/   \  \::/~~~~   \  \::/       \  \::/       \  \:\         \  \:\/:/  
   \  \:\/:/     \  \:\        \  \:\        \  \:\        \  \:\         \  \::/   
    \  \::/       \  \:\        \  \:\        \  \:\        \  \:\         \__\/    
     \__\/         \__\/         \__\/         \__\/         \__\/                  


To obtain a Base64 encoded version of a Token's PRG you can call the function:

function getTokenPRGBase64(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume)

where:

  tokenId                - the id of the token
  pal                    - true for a pal version, false for ntsc
  filterResonanceRouting - 0 for default, otherwise a byte value in the format the SID register $d417 expects:
                             bit 0:    set to 1 to filter voice 1
                             bit 1:    set to 1 to filter voice 2
                             bit 2:    set to 1 to filter voice 3
                             bit 3:    set to 1 to filter external voice (not used)
                             bits 4-7: filter resonance (0-15)

  filterModeVolume       - 0 for default, otherwise a byte value in the format the SID register $d418 expects:
                             bits 0-3: volume (0-15)
                             bit 4:    set to 1 to enable the low pass filter
                             bit 5:    set to 1 to enable the band pass filter
                             bit 6:    set to 1 to enable the high pass filter
                             bit 7:    set to 1 to disable voice 3

The filters in some older model C64s may produce excessive distortion. If you intend to run the PRG
on one of these models, a value of 240 for filterResonanceRouting may produce a better output than
the default value.

**********************************************************************************************************/

// File: @openzeppelin/[email protected]/utils/Strings.sol


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

// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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

// File: @openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: oraand.sol

pragma solidity ^0.8.4;





interface IOraandURI {
  function tokenURI(IOraandPRGToken tokenContract, uint256 tokenId) external view returns (string memory);
}

interface IOraandPRGToken {
  function getTokenPRGBase64(uint256 tokenId, bool patchedVersion) external view returns (string memory);
  function getTokenPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume) external view returns (bytes memory);
  function getTokenPatchedPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume) external view returns (bytes memory);
  function getTokenAttributes(uint256 tokenId) external view returns (string memory);
  function getTokenParams(uint256 tokenId) external view returns (uint64);
  function getTokenModes(uint256 tokenId) external view returns (uint8);
  function getTokenPatchUnlocked(uint256 tokenId) external view returns (bool);
}

// ORAAND contract
contract ORAAND is ERC721, ERC721Enumerable, Ownable, IOraandPRGToken {
  using Strings for uint256;

  string constant tokenName   = "oraand";
  string constant tokenSymbol = "oraand";

  string private description = "2048 byte on chain PRG for the Commodore 64";

  uint256 constant MAX_NUMBER_TOKENS = 1024;

  uint256 public mintPrice = .0256e18;

  uint256 constant DAY_SECONDS = 24 * 60 * 60;

  string private imageBaseURI     = "https://nopsta.com/oraand/i/";
  string private animationBaseURI = "https://nopsta.com/oraand/v/";
  string private externalBaseURI  = "https://nopsta.com/oraand/";

  bytes constant basePRGData = hex"01080b0800009e323036320000000078a9358501a97f8d0ddc8d0dddad0ddcad0ddda92c8dfaffa90a8dfbffa9018d1ad0a9188d11d0a9ff8dfeffa9098dffffa2fd8e12d0a9009d00309dfc309df93195019dff1fa9089dffd79dfcd89df9d99deadabdbe0c9d0f20bdf60c9d2723cad0d3a93c855ba9e88d18d0a0b4a9038560a9008556b9f20b8848293f9d0070e86829c005564a4a8556c660d0e89d0070e898d0d920c70fa2208e30348666a2488665a7b88d003418bd003469089d0134bd303469009d3134e8e02ed0eaa438be0070bd003485618567bd30348562a9238568be2270bd00348563bd30348564a007b16749ff3163116191658810f3a908a26520f309e638a538c922d0c0a900856c20e20aa203a9ec8dff59a9008d3f5abdcf0a8d3f0a8d500a8d580abdd50a8d440abdd60a8d560abdd40a8596bdd30a8597bdda0a8598bdde0a85998656a22b869ba2fe869da000a201a599202d0ae8e009d0f8a6978696a219869ba202869da207202d0acad0faa656ca1099a9008d20d08d21d0a91f8588a9f4858758af00dcc52ff03b852f2904d002e6578a2908d002c6578a2901d008a558c908f002e6588a2902d006a558f002c6588a2910d00fe66ca56cc9043004a900856c20e20aa66cf01abdec0b8deb09bdef0b8dec09a56ddda80c3007a900856d20b50a20f20a4c8d0918750095009002f601a69e60488a489848a9ff8d19d0204a0de66da55ef014a55b855d4904855bad18d049108d18d0a900855e68a868aa684040869c186596484818a59b659d859b859a68990050481869ffc01d1006e49cd002a9ff99005168481869f8990052681865984818b9ff59659a99005ab93f5a690099405aa902859a68c8cad0c568a69c60ada70cf0030a9002492d8da70c60a9308551a9008550a9408537a000b1508556a007b350a556915086568810f5a908a25020f309c637d0e260c66e3002d004a908856e6018a5586901c909d002a900855860004080c00108fff80108fff90907f7f8084737a9088558a964856da900856e20470d60a55ef002ea60a55b8551a204a000988550915088d0fbe651cad0f1a5572903aabdcf0a8d610b8d770b8d840ba558d003e65e608536a9008554a9308555a93e8530a55b8531a56ef004c536d003205b0b38a530e9288530b002c631a940a25420f309c636d0dfe65e60a200eaeaeabc0050b154f07a18bd005a65308550bd405a65318551bc0051b154c0ffd002a9008533bc0052b15485328660a000b350bd4470e000f00ac909d006a633f002a9019150c8b350bd6f70e000f00ac90fd006a632f002a9019150a028b150f006a903a633d002a9029150c8a9049150a050b350bd9a709150c8b350bdc5709150a660e8e040f0034c5d0b6000070ec1b68b0a0a0aa11fa0088808a1209f5ddc9f5fdfe2a11e5e5ee0de08880808881f48dd9c48c82a8787595a98ea999959a99b9a5897564747470747d9589b1a5987075796150752d2a79414536828a853e75212d25212925352114f13145111515206d14f0f062666a3a625e48e0ece0ece8ea4664d25e44d8d0ccc0ecd0c0a89ce0cc5490a85c55cdf5d5695535550c704428b088584020dc80544c10786030107870645850548480888080787070747c70646860645850545457500280a05000a0a0560500a145028141ea05050220000328000e000f800fe008000e000f800fe000103070f1f3f7fff00000000000000000000000000000000ff003f000f000300fffefcf8f0e0c0800103070f1f3f7fff80c0e0f0f8fcfeffff7f3f1f0f070301fffefcf8f0e0c0802d435a7c5285a95a5a85b4f7a30a52b45a85b4f7a30a52b402030405070603040406080a0e0d07080406080a0e0d07084c7a0fa528d00aa52ba28520f3094c680d38a585e52b8585b007c686100320bd0fc629d00dc62ad009a5284901852820b40fc6241004a94f8524a202a524d007d60fd00320670ebcea0b18b970007509997000b97100750c997100b574c951f03cb5b9d01a18b972007db00c997200900eb973006900290fd002f6b9997300b5b9f01a38b97200fdb00c997200b00eb97300e900290fd002d6b9997300d612d015b506f011b9740049019974004ab5069002b5039512b515f032d615d02eb51ef005d6184c100ef618b51818862d351b7521aab97400c981f00cbd170d997000bd2f0d997100a62db5259515ca30034c830da218b5709d00d4ca10f860100804010707070fa0a0a00a140000000808020032001e0014b4321111418161dddebfbd440ea46cd0010a950fb9b70c852b207d0a39480e0903951b207d0a39470e79530e29079521207d0a2901951ea903855fb9ac0c9525c001d004a9288526c908d002065fa55f95039512207d0ad95b0ea900b002a9029506f612a9019515a941bcea0b997400a46ce002d01a207d0ad9bb0ca900b00e207d0ac920b004a9158582207d0a850e207d0ad9570eb008a9518574a9018573b9b30c859fe000d02d20bd0fc003d0268609207d0ac932b01d290385098625207d0ac932a981b002a9158574861ba55f8503a9028506207d0ad9590eb006a9008523851d98d035bcea0ba911997400e002d00b207d0a2903a8b95f0e8582a92895039512a9789506f612207d0a2907a8b94c0e9525207d0a2901850a60a9018524a214a9009503e0031029bcea0ba56cd010bd650e997500bd620e090d997600d00ba911997500bd620e997600967320670ef60fca10cca9648529a901852a60a59f8586a9008528f0eda9308551a207a03fe007f004b14ef00c207d0addf70fb004a90191508810e9a551854f18a550854e694085509002e651ca10d3603c648cdc";

  uint constant FILTERRESONANCEROUTINGPOSITION = 0x18a;
  uint constant FILTERMODEVOLUMEPOSITION       = 0x186;

  // prg data 1
  uint constant PRGDATA1SEGMENTLENGTH = 56;
  uint constant PRGDATA1POSITION      = 0x7c8;
  bytes constant prgData1 = hex"a9308551a207a03feea70c207d0addf20fb004a90191508810eea551854f869ea940a25020f309ca10dc60080e141e3250648c0000000000207d0a293f692ec9549008a2088eab0c8eaf0c85a0a9308551a207a03f207d0ac5a0b004a90191508810f2869ea940a25020f309ca10e460a9a085a0207d0a2907855f29fdd002e65fa9308551a207a03f207d0ac5a0b004a90191503898e55fa810ee869ea940a25020f309ca10e060";
  
  // prg data 2
  uint constant PRGDATA2SEGMENTLENGTH = 239;
  uint constant PRGDATA2POSITION      = 0x711;
  bytes constant prgData2 = hex"207d0a297fc90ab002690a85a0a9308551a9008550a207a03f207d0ac5a0b004a90191508810f2869ea940a25020f309ca10e4a907859ca003a207bd00309d3830ca10f7a9084820ef0f6838ad4f0fe9088d4f0f8810e2a92020ef0f18ad4f0f69608d4f0f9003ee500fc69c10c9a940859ca003a204b900309d0030e88810f618ad870f69088d870f9003ee880f18ad8a0f69088d8a0f9003ee8b0fc69cd0d2207d0a9031a204a0308451c8844fa9008550a9c0854ea03fb150914e8810f9869ea940a25020f30938a54ee940854eb002c64fcad0e0a9088dab0c8daf0c60186d4c0f8d4c0f9003ee4d0f60000000207d0a290785b4207d0a2907690e859cd006a59c2903d017a9308551207d0a2903d002e651207d0a29db1869008550207d0a25b4aa207d0aa59c2903a8b9dc0f855f20e00fc69cd0c9a907859ca003a207bd00309d3830ca10f7a9084820cf0f6838ad650fe9088d650f8810e2a92020cf0f18ad650f69608d650f9003ee660fc69c10c9a940859ca003a204b900309d0030e88810f618ad9d0f69088d9d0f9003ee9e0f18ada00f69088da00f9003eea10fc69cd0d2a9088dab0c8daf0c60186d620f8d620f9003ee630f6000010840a000a9019150869ea55fa25020f309ca10f060000000000000000000000000207d0a290785b4207d0a2907690e859cd006a59c2903d017a9308551207d0a2903d002e651207d0a29db1869008550207d0a25b4aa207d0aa59c2903a8b9dc0f855f20e00fc69cd0c9a907859ca003a207bd00309d3830ca10f7a9084820cf0f6838ad650fe9088d650f8810e2a92020cf0f18ad650f69608d650f9003ee660fc69c10c9a940859ca003a204b900309d0030e88810f618ad9d0f69088d9d0f9003ee9e0f18ada00f69088da00f9003eea10fc69cd0d2a9088dab0c8daf0c60186d620f8d620f9003ee630f60000105bda000a9019150869ea55fa25020f309ca10f060000000000000000000000000207d0a290f69028de00fa90f85b4207d0a29076906859cd006a59c2903d017a9308551207d0a2903d002e651207d0a29db1869008550207d0a25b4aaa59c2901a8b9e00f855f20e40fc69cd0cca907859ca003a207bd00309d3830ca10f7a9084820d30f6838ad690fe9088d690f8810e2a92020d30f18ad690f69608d690f9003ee6a0fc69c10c9a940859ca003a204b900309d0030e88810f618ada10f69088da10f9003eea20f18ada40f69088da40f9003eea50fc69cd0d2a9088dab0c8daf0c60186d660f8d660f9003ee670f6000010840a000a9019150869eade00fa25020f309ca10ef6000000000000000";

  // prg data 3
  uint constant PRGDATA3LENGTH   = 457;
  uint constant PRGDATA3POSITION = 0x548;
  bytes constant prgData3 = hex"4c740ea46cc624c6a9d00aa98085a9a52849018528a528d00aa5aca28520f3094c750d38a585e5ac8585b002c68618a57f65bc857fc4cff004a524d02da5a739620ed026207d0ad9bb0ca900b003207d0a85bca524d013207d0ac964290885cfb9540eb003b9580e85ada20286a818a5a73d650e6524d005207d0a95b5bcea0bb97400c951f039b5b9d01a18b972007db00c997200900eb973006900290fd002f6b9997300b5b9f01a38b97200fdb00c997200b00eb97300e900290fd002d6b9997300a524d01db51829071875b5f618aabd0060997000bd0061997100a6a8b5ad997400a524d5a1d008b9740029fe997400ca30034cb30da524d006a5aa8524e6a7a218b5709d00d4ca10f8601141414115514151899cdd8689d9031f0f1f3f7f6e8c6e0208080c0c04080a0fa200207d0a291fc91810f7a8b9170dc5b3f0ef85b39d0060b92f0d9d0061cad0e1a214a900950385a7e0031053207d0a9518a94195ada46cb9ac0c85aabcea0b9673a910997500bd5f0e997600a56cd018a9ff85aaa91195ada9f0997500bd5c0e997600bd680ed015c901d005bd6b0ed00cc902d005bd6e0ed003bd710e95a1ca10a0a901852485a98528a46ca9788585b9b30c8586b9b70c85ac60";

  // prg data 4
  uint constant PRGDATA4LENGTH   = 457;
  uint constant PRGDATA4POSITION = 0x548;
  bytes constant prgData4 = hex"4c7b0ea200d00ffe00d8fe00d9fe00dafe00dbcad0f1a46cc003d004a915d00e6674e6bda5bd29036900aabd6f0e8574c624c6a9d007a98085a920010fa5aca28520f30918a57f65bc857fc000f004a524d016a5a7395d0ed00f207d0ad9bb0ca900b003207d0a85bc207d0ac964b94f0eb003b9530e85ada20286a818a5a73d600e6524d005207d0a95b5bcea0b38b97000e906997000b00fb97100e900997100b005a90099710018b972007db00c997200b973006900997300a524d023a46cb51839770ebcea0b1875b5f618aabd0060997000bd0061997100a6a8b5ad997400a524d5a1d005a920997400ca108ba524d006a5aa8524e6a7a901857aa218b5709d00d4ca10f8604141414115514151ed98fae698fa031f0f1f3f7f648c6e010303070704080a0f5020508000070a0807000307a200207d0a291fc91810f7a8b9170dc5b3f0ef85b39d0060b92f0d9d0061cad0e1a214a900950385a7e003104e207d0a9518a94195ada46cb9730e85aabcea0b9673a910997500bd5a0e997600a56cd013a90a85aaa94195adbd570e997600bd630ed015c901d005bd660ed00cc902d005bd690ed003bd6c0e95a1ca10a5a901852485a98528a46cb9b30c8586b9b70c85ac60a930";

  // prg data 5
  uint constant PRGDATA5POSITION      = 0x518;
  uint constant PRGDATA5SEGMENTLENGTH = 24;
  bytes constant prgData5 = hex"1727394b5f748aa1bad4f00e2d4e7196bee8144374a9e11c5a9ce22d7ccf2885e852c137b439c55af79e4f0ad1a3826e68718ab3ee3c9e15a24604dcd0e21467dd793c29448d08b8a1c528cdbaf17853871a10710c1c2d3f52667b92aac3defa18385a7ea4ccf7245486bcf53171b5fc4898ee48a90d79ea62e26af89030dc90521af2d4c4c4d4f02060b820a434e4a88888a8e040c070404868c850101050c08080e08090d090a0";

  // prg data 6
  uint constant PRGDATA6POSITION = 0x530;
  bytes constant prgData6 = hex"0101010101010101010101020202020202020303030303040404040505050606060707080809090a0a0b0c0d0d0e0f10111213141517181a1b1d1f20222427292b2e3134373a3e4145494e52575c62686e757c83010101010101010101010101020202020202020303030303040404040505050606070707080809090a0b0b0c0d0e0e0f10111213151617191a1c1d1f212325272a2c2f3235383b3f43474b4f54595e646a70777e";

  // prg data 7
  uint constant PRGDATA7POSITION = 0x56;
  bytes constant prgData7 = hex"000b0b0402060d010a0c0b06060e000f000f0f010b0d01000607000f000b0e06";

  // prg data 8
  uint constant PRGDATA8POSITION = 0x17e;
  bytes constant prgData8 = hex"010f000101010506020b0c0e0e060f0b0f0b0004010002070302030b010f060e";

  // prg data 9
  uint constant PRGDATA9POSITION = 0x287;
  bytes constant prgData9 = hex"1d2b2d4d5f63656971878da9c3cfe7f5";

  // prg data 10
  uint constant PRGDATA10SEGMENTLENGTH = 3;
  uint constant PRGDATA10POSITION      = 0x4b1;
  bytes constant prgData10 = hex"08000014000a14005014281478785050505060500a020408";

  // increment prob
  // length 16
  uint constant PRGDATA11SEGMENTLENGTH = 4;
  uint constant PRGDATA11POSITION      = 0x4bc;

  // prg data 11
  bytes constant prgData11 = hex"320000141400001e0a00001420000020";

  // prg data 12
  uint constant PRGDATA12SEGMENTLENGTH = 4;
  uint constant PRGDATA12POSITION      = 0x4b8; 
  bytes constant prgData12 = hex"1ea05050325050a0";

  // prg data 13
  uint constant PRGDATA13SEGMENTLENGTH = 56;
  uint constant PRGDATA13POSITION      = 0x4c0;
  bytes constant prgData13 = hex"8000e000f800fe008000e000f800fe000102070a1f2a7faa00000000000000000000000000000000ff003f000f000300ffaafca8f0a0c08080c0a0908884828180c0a0908884828101030509112141810102040810204080804020100804020181412111090503018182848890a0c08080c0e0f0f8fcfeff80c0e0f0f8fcfeff0103070f1f3f7fff00000000000000000000000000000000ff7f3f1f0f070301fffefcf8f0e0c08080c0e0f0f8fcfeff80c0e0f0f8fcfeff0103050911214181010204081020408080402010080402017f3f1f0f07030100010204081020408020104864524944422010486452494442040812264a922242000001020408102000008040201008044222120a06020000424448506040000080402090c8e4723980402090c8e472390102040913274e9c010204081020408080402010080402019c4e2713090402013972e4c8902040808040209048a452298040209048a452290102040912254a9401020408102040808040201008040201944a2512090402012952a4489020408080c0e0b0988c868380c0e0b0988c86830103070d193161c101020408102040808040201008040201c16131190d07030183868c98b0e0c08080c0e0b0d8acd6ab80c0e0b0d8acd6ab0103070d1b356bd501020408102040808040201008040201d56b351b0d070301abd6acd8b0e0c08080c0a0908884c2a180402010088442210102050b162d5bb70102040810204080804020100804020190482412090402016fdebc78f0e0c08080c0a09098a4c28180c0a09098a4c28101030509192543810102040810204080804020100804020181412111090503018182848890a0c08080c0a09088a492a980402010082412290103070f1d3b75eb01020408102040808040201008040201944a241208040201d7aedcb8f0e0c08080c0e0f0f8fcfeff80c0e0f0f8fcfeff0103070f1f3f7fff01020408102040808040201008040201ff7f3f1f0f070301fffefcf8f0e0c0808000200088002200800020008800220000000200080022000000000000000000000000000000000088002200080002008800200080000000804020904824924980402090482492490102050b162d5bb60102040810204080804020100804020192492412090402016ddab468d0a0408000c000f000fc00ff00c000f000fc00ff0103050e173b5dee00000000000000000000000000000000007f001f0007000177badce870a0c0808000a000a800aa008000a000a800aa000102070a1f2a7faa00000000000000000000000000000000aa002a000a000200ffaafca8f0a0c08080c0a0d0a8d4aad58040a050a854aa550103070f1f3f7fff01020408102040808040201008040201aa552a150a050201fffefcf8f0e0c08080c0a09088c4a29180402010884422110103070f1e3d7bf7010204081020408080402010080402018844221108040201efdebc78f0e0c0808040209048a452298040209048a452290102050b162d5bb601020408102040808040201008040201944a2512090402016ddab468d0a04080804020100804020180402010080402010102040810204080010204081020408080402010080402018040201008040201010204081020408080402090c864b2d980402090c864b2d90102040913264d9b01020408102040808040201008040201ec763b1d0e070301376edcb870e0c0808000e000f800fe008000e000f800fe00010007001f007f0000000000000000000000000000000000ff003f000f000300ff00fc00f000c0008040a050a854aa558040a050a854aa55000102050a152a5500000000000000000000000000000000aa552a150a050201aa54a850a04080008040201088442211804020108844221101020408112244880102040810204080804020100804020188442211080402011122448810204080000080002000880000008000200088000101040613194c660000000000000000000000000000000022000800020000003398cc603080c000000080402010884400008040201088440101040613194c660000000000000000000000000000000022110804020100003398cc603080c0008000a000a800aa008000a000a800aa00000002000a002a0000000000000000000000000000000000aa002a000a000200aa00a800a000800080c0a0908884828180402010080402010103070f1f3f7fff010204081020408080402010080402018040201008040201fefcf8f0e0c08000008000a000a800aa008000a000a800aa0102050a152a55aa00000000000000000000000000000000002a000a0002000055aa54a850a040808040a050a854aa558040a050a854aa550103070f1f3f7fff01020408102040808040201008040201aa552a150a050201fffefcf8f0e0c080";

  // prg data 14
  bytes constant prgData14 = hex"0c13181f22181618181f242b2e242224181f242b2e2422240c13181c211f1518181f24282d2b2124181f24282d2b21240c13181b221f1618181f24272e2b2224181f24272e2b22240c13181c231f1718181f24282f2b2324181f24282f2b23240c13181c231f1718181f24282f2b2324302b24283b3723300c13181c221f1618181f24282e2b2224302b24283a3722300c12181b221e1618181e24272e2a2224302a24273a3622300c12181b211e1518181e24272d2a2124302a243339362130";

  // prg data 15
  uint constant PRGDATA15LENGTH   = 4;
  uint constant PRGDATA15POSITION = 0x4a9;
  bytes constant prgData15 = hex"00300C06";

  // prg data 16
  uint constant PRGDATA16POSITION = 0x4ad;
  bytes constant prgData16 = hex"000C0C06";

  // prg data 17
  uint constant PRGDATA17POSITION = 0x64d;
  bytes constant prgData17 = hex"c0c0c00c18";

  // patch data 1
  uint constant PATCHDATA1LENGTH   = 13;
  uint constant PATCHDATA1POSITION = 0x2c2;
  bytes constant patchData1 = hex"18ad18d06902290e09e08d18d0";
  
  // patch data 2
  uint constant PATCHDATA2LENGTH   = 6;
  uint constant PATCHDATA2POSITION = 0x2b7;
  bytes constant patchData2 = hex"a9e88d18d060";

  // patch data 3
  uint constant PATCHDATA3LENGTH   = 8;
  uint constant PATCHDATA3POSITION = 0x2a0;
  bytes constant patchData3 = hex"207d0a29019150ea";

  // patch data 4
  uint constant PATCHDATA4LENGTH   = 13;
  uint constant PATCHDATA4POSITION = 0x28c;
  bytes constant patchData4 = hex"207d0a8d0020207d0a8d042060";

  // patch data 5
  uint constant PATCHDATA5LENGTH    = 6;
  uint constant PATCHDATA5POSITION1 = 0x2f3;
  uint constant PATCHDATA5POSITION2 = 0x33a;
  bytes constant patchData5 = hex"ee21d0ee20d0";

  // TokenData has the values specific to each token
  struct TokenData {
    uint64 params;

    uint8 modes;
    uint8 defaultMode;

    bool patchUnlocked;

    uint256 lastTransfer;
  }

  // mapping of tokenIds to the token's data
  mapping(uint256 => TokenData) tokenData;

  // the number of tokens minted
  uint256 _tokenIdCounter;

  IOraandURI public tokenURIContract;

  constructor() ERC721(tokenName, tokenSymbol) {
  }


  // ----------------------------- mint ----------------------------- //

  function mintToken()
    public
    payable
    returns (uint256)
  {
    require (_tokenIdCounter < MAX_NUMBER_TOKENS, "Mint over");

    require (balanceOf(msg.sender) < 16, "Limit 16");
    require (msg.value >= mintPrice, "Mint price");

    uint256 tokenId = _tokenIdCounter;

    unchecked {
      _tokenIdCounter = _tokenIdCounter + 1;
    }

    _safeMint(msg.sender, tokenId);

    tokenData[tokenId].params = uint64(bytes8(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId.toString()))));

    tokenData[tokenId].lastTransfer = block.timestamp;

    return tokenId;
  }

  // ---------------------- token information ----------------------- //

  function tokenURI(uint256 tokenId) 
    override 
    public 
    view 
    returns (string memory) 
  {
    checkTokenId(tokenId);

    if (address(tokenURIContract) != address(0)) {
      return tokenURIContract.tokenURI(IOraandPRGToken(this), tokenId);
    }    

    string memory tokenIdString = Strings.toString(tokenId);

    string memory json = base64Encode(bytes(string(abi.encodePacked(
      '{"name":"oraand ', tokenIdString,
      '","description":"', description, '",',
      getTokenURIs(tokenIdString),
      ',"attributes":', getTokenAttributes(tokenId),
      ',"prg":"data:application/x-c64-program;base64,', getTokenPRGBase64(tokenId, false), 
      '"}'
    ))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }


  function getTokenURIs(string memory tokenIdString) 
    internal
    view 
    returns (string memory) 
  {
    string memory uriString = string(abi.encodePacked(
      '"image":"', imageBaseURI, tokenIdString,
      '.png","animation_url":"', animationBaseURI, tokenIdString,
      '","external_url":"', externalBaseURI, tokenIdString, '"'
    ));

    return uriString;
  }

  function getTokenAttributes(uint256 tokenId) 
    override(IOraandPRGToken)
    public
    view 
    returns (string memory) 
  {
    checkTokenId(tokenId);

    uint8 param = uint8((tokenData[tokenId].params >> 8) & 0x1f);

    string memory patch = "No";
    if(tokenData[tokenId].patchUnlocked) {
      patch = "Yes";
    }

    return string(
      abi.encodePacked('[{"trait_type":"Type","value":"', 
        Strings.toString(tokenData[tokenId].params & 7 ) ,'"},{"trait_type":"FG","value":"', 
        Strings.toString(uint8(prgData7[param])) ,'"},{"trait_type":"BG","value":"', 
        Strings.toString(uint8(prgData8[param])) ,'"}, {"trait_type":"Charset","value":"', 
        Strings.toString((tokenData[tokenId].params >> 32) & 0x1f) ,'"},{"trait_type":"Modes","value":"', 
        Strings.toString(tokenData[tokenId].modes),     
        '"}, {"trait_type":"Patch","value":"',patch,
        '"}]'
    ));
  }

  function getTokenSecondsSinceLastTransfer(uint256 tokenId)
    external
    view
    returns (uint256)
  {
    checkTokenId(tokenId);

    return block.timestamp - tokenData[tokenId].lastTransfer;
  }

  function getTokenParams(uint256 tokenId) 
    override(IOraandPRGToken)
    external
    view
    returns (uint64) 
  {
    checkTokenId(tokenId);
    
    return tokenData[tokenId].params;
  }

  function getTokenModes(uint256 tokenId) 
    override(IOraandPRGToken)
    external 
    view
    returns (uint8) 
  {
    checkTokenId(tokenId);
    
    return tokenData[tokenId].modes;
  }

  function getTokenPatchUnlocked(uint256 tokenId) 
    override(IOraandPRGToken)
    external
    view
    returns (bool)
  {
    checkTokenId(tokenId);
    
    return tokenData[tokenId].patchUnlocked;
  }

  function getTokenPRGBase64(uint256 tokenId, bool patchedVersion) 
    override(IOraandPRGToken)
    public
    view
    returns (string memory)
  {
    checkTokenId(tokenId);

    if (patchedVersion) {
      return getTokenPatchedPRGBase64(tokenId, true, 0, 0);
    } else {
      return getTokenPRGBase64(tokenId, true, 0, 0);
    }
  }

  function getTokenPRGBase64(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume)
    public
    view
    returns (string memory)
  {
    return base64Encode(getTokenPRG(tokenId, pal, filterResonanceRouting, filterModeVolume));
  }

  function getTokenPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume)
    override(IOraandPRGToken)
    public
    view
    returns (bytes memory)
  {
    checkTokenId(tokenId);

    bytes memory tokenPRG = basePRGData;

    unchecked {

      uint i;
      uint offset = 0;

      uint param = uint(tokenData[tokenId].params & 0x7);

      if (param > 0 && param < 4) {
        offset = uint((param - 1) * 56);
        for (i = 0; i < PRGDATA1SEGMENTLENGTH; i++) {
          tokenPRG[PRGDATA1POSITION + i] = prgData1[i + offset];
        }
      } else if (param > 3) {
        offset = uint((param - 4) * 239);

        for (i = 0; i < PRGDATA2SEGMENTLENGTH; i++) {
          tokenPRG[PRGDATA2POSITION + i] = prgData2[i + offset];
        }
      } 

      if (param > 3) {
        for (i = 0; i < PRGDATA3LENGTH; i++) {
          tokenPRG[PRGDATA3POSITION + i] = prgData3[i];
        }
        tokenPRG[0xa5] = bytes1(0x10);
        tokenPRG[0xa6] = bytes1(0x0f);
      } else {

        if ((tokenData[tokenId].params >> 3) & 0x1 > 0) {
          tokenPRG[0x651] = hex"0a";
        }
      }

      if (filterResonanceRouting != 0) {
        tokenPRG[FILTERRESONANCEROUTINGPOSITION] = bytes1(filterResonanceRouting);
      }

      if (filterModeVolume != 0) {
        tokenPRG[FILTERMODEVOLUMEPOSITION] = bytes1(filterModeVolume); 
      }

      offset = uint((tokenData[tokenId].params >> 16) & 0x7) * 24;

      uint noteOffset = uint((tokenData[tokenId].params >> 24) & 0xf);

      if (!pal) {
        noteOffset += 84;

        for (i = 0; i < PRGDATA15LENGTH; i++) {
          tokenPRG[PRGDATA15POSITION + i] = prgData15[i];
          tokenPRG[PRGDATA16POSITION + i] = prgData16[i];
        }

        if (param < 4) {
          for (i = 0; i < 4; i++) {
            tokenPRG[PRGDATA17POSITION + i] = prgData17[i];
          }

          if ((tokenData[tokenId].params >> 3) & 0x1 > 0) {
            tokenPRG[0x651] = hex"0c";
          } else {
            tokenPRG[0x651] = hex"18";
          }

          tokenPRG[0x696] = hex"04";
          tokenPRG[0x57f] = hex"5f";
          tokenPRG[0x6ae] = hex"30";
          tokenPRG[0x75d] = hex"30";
          tokenPRG[0x763] = hex"90";
        }
      }


      for (i = 0; i < PRGDATA5SEGMENTLENGTH; i++) {
        param = uint(uint8(prgData14[i + offset])) + noteOffset;
        tokenPRG[PRGDATA5POSITION + i] = prgData5[param];
        tokenPRG[PRGDATA6POSITION + i] = prgData6[param];
      }

      param = uint((tokenData[tokenId].params >> 8) & 0x1f);

      tokenPRG[PRGDATA8POSITION] = prgData8[param];
      tokenPRG[PRGDATA7POSITION] = prgData7[param];

      offset = uint((tokenData[tokenId].params >> 32) & 0x1f) * 56;

      if (offset < 1736) {
        for (i = 0; i < PRGDATA13SEGMENTLENGTH; i++) {
          tokenPRG[PRGDATA13POSITION + i] = prgData13[offset + i];
        }
      }

      param = uint((tokenData[tokenId].params >> 40) & 0xff);
      tokenPRG[0xca7 - 0x7ff] = bytes1(uint8(param));

      param = uint((tokenData[tokenId].params >> 48) & 0xf );
      tokenPRG[PRGDATA9POSITION] = prgData9[param];

      param = uint(((tokenData[tokenId].params >> 56) & 0x7) * 3);
      for (i = 0; i < PRGDATA10SEGMENTLENGTH; i++) {
        tokenPRG[PRGDATA10POSITION + i] = prgData10[i + param];
      }

      param = uint(((tokenData[tokenId].params >> 59) & 0x3) * 4);
      for (i = 0; i < PRGDATA11SEGMENTLENGTH; i++) {
        tokenPRG[PRGDATA11POSITION + i] = prgData11[i + param];
      }

      param = uint(((tokenData[tokenId].params >> 61) & 0x1) * 4);
      for (i = 0; i < PRGDATA12SEGMENTLENGTH; i++) {
        tokenPRG[PRGDATA12POSITION + i] = prgData12[i + param];
      }

      tokenPRG[0x1c6] = bytes1(tokenData[tokenId].modes + 1);

      if (tokenData[tokenId].defaultMode != 0) {
        tokenPRG[0x10e] = bytes1(tokenData[tokenId].defaultMode);
      }
    }

    return tokenPRG;
  }

  // Returns the patched PRG as base64 encoded data, requires patch to be unlocked
  function getTokenPatchedPRGBase64(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume)
    public
    view
    returns (string memory)
  {
    return base64Encode(getTokenPatchedPRG(tokenId, pal, filterResonanceRouting, filterModeVolume));
  }

  // Returns the patched PRG as bytes, requires patch to be unlocked
  function getTokenPatchedPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume)
    override(IOraandPRGToken)
    public
    view
    returns (bytes memory)
  {
    checkTokenId( tokenId );

    require (tokenData[tokenId].patchUnlocked, "Locked");
    
    bytes memory tokenPRG = getTokenPRG(tokenId, pal, filterResonanceRouting, filterModeVolume);

    uint256 i = 0;

    unchecked {
      // apply patches

      for (i = 0; i < PRGDATA4LENGTH; i++) {
        tokenPRG[PRGDATA4POSITION + i] = prgData4[i];
      }

      if (uint8((tokenData[tokenId].params >> 1) & 3) == 3) {
        tokenPRG[0x6ce] = hex"0f";
      }

      if (!pal) {
        tokenPRG[0x6ce] = hex"0c";
        tokenPRG[0x66d] = hex"0a";
        tokenPRG[0x675] = hex"08";
        tokenPRG[0x676] = hex"0c";
        tokenPRG[0x677] = hex"0a";
      }

      uint param = uint((tokenData[tokenId].params >> 2) & 7);

      if (param > 3) {
        tokenPRG[0x35e] = 0xee;
        tokenPRG[0x360] = 0xd0;

        if (param == 4) {
          tokenPRG[0x54d] = 0xd0;  

          param = uint((tokenData[tokenId].params >> 7) & 0x2);     

          tokenPRG[0x35f] = bytes1(0x16 + uint8(param));
        } else if (param == 5) {
          tokenPRG[0x35f] = 0x21;
        } else if (param == 6) {
          tokenPRG[0x360] = 0x20;
          tokenPRG[0x35f] = 0x00;
        } else {
          tokenPRG[0x35f] = 0x16;
        }
      } else if (param == 3) {
        tokenPRG[0x330] = 0xa5;
        tokenPRG[0x331] = 0x70; // or other sid shado
      } else if (param == 2) {
        tokenPRG[0x347] = bytes1(uint8(tokenData[tokenId].params & 0xff));
      } else if(param == 1) {
        if (uint((tokenData[tokenId].params) >> 6 & 1) == 0) {
          for (i = 0; i < PATCHDATA5LENGTH; i++) {
            tokenPRG[PATCHDATA5POSITION1 + i] = patchData5[i];
          }
        } else {
          for (i = 0; i < PATCHDATA5LENGTH; i++) {
            tokenPRG[PATCHDATA5POSITION2 + i] = patchData5[i];
          }
        }
      } else {
        tokenPRG[0x2ff] = 0xa4;
        tokenPRG[0x300] = 0x81;
      }

      if (((tokenData[tokenId].params >> 8) & 0xff) > 190) {
        tokenPRG[0x55]   = 0x8a;
        tokenPRG[0x56] = 0xea;
      }

      if (((tokenData[tokenId].params >> 14) & 0xff) > 60) {
        for (i = 0; i < PATCHDATA1LENGTH; i++) {
          tokenPRG[PATCHDATA1POSITION + i] = patchData1[i];
        } 

        for(i = 0; i < PATCHDATA2LENGTH; i++) {
          tokenPRG[PATCHDATA2POSITION + i] = patchData2[i];
        }
      } else {
        tokenPRG[0x304] = 0xea;
        tokenPRG[0x305] = 0xea;
      }

      if (((tokenData[tokenId].params >> 22) & 0xff) > 127) {
        for(i = 0; i < 8; i++) {
          tokenPRG[PATCHDATA3POSITION + i] = patchData3[i];
        }
      } else {
        for(i = 0; i < 13; i++) {
          tokenPRG[PATCHDATA4POSITION + i] = patchData4[i];      
        }
      }
    }

    return tokenPRG;
  }

  // ------------------------ check criteria ------------------------ //

  // Check tokenId is less than the total number of tokens
  function checkTokenId(uint256 tokenId) 
    public
    view
  {
    require (tokenId < _tokenIdCounter, "Invalid id");
  }

  // Check tokenId is valid and sender is the owner of the token
  function checkIsTokenOwner(address sender, uint256 tokenId) 
    public
    view
  {
    checkTokenId(tokenId);
    require (ERC721.ownerOf(tokenId) == sender, "Not owner");
  }

  // Check tokenId is valid and the token has been held for the time requirement
  function checkHoldTime(address sender, uint256 tokenId, uint256 timeRequirement) 
    public
    view
  {
    checkIsTokenOwner(sender, tokenId);

    string memory message = string(abi.encodePacked("Req time ", timeRequirement.toString()));
    require ((block.timestamp - tokenData[tokenId].lastTransfer) >= timeRequirement, message);
  }

  // Check if modes can be unlocked 
  function checkCanUnlockModes(address sender, uint256 tokenId, uint8 modes)
    public
    view
  {
    require (modes < 4, "Invalid");

    uint256[4] memory timeReq = [0, 8 * DAY_SECONDS, 16 * DAY_SECONDS, 32 * DAY_SECONDS];
    uint256 timeRequirement = timeReq[modes];
    checkHoldTime(sender, tokenId, timeRequirement);
  }

  // Check if meet requirements to unlock the patch (held for 64 days)
  function checkCanUnlockPatch(address sender, uint256 tokenId)
    public
    view
  {
    uint256 timeRequirement = 64 * DAY_SECONDS;
    checkHoldTime(sender, tokenId, timeRequirement);
  }


  // ------------------------ token modify  ------------------------- //

  // Set the maximum mode for the token
  function unlockModes(uint256 tokenId, uint8 modes)
    external
  {
    checkCanUnlockModes(msg.sender, tokenId, modes);

    tokenData[tokenId].modes = modes;
  }

  // Set the default mode for the token
  function setDefaultMode(uint256 tokenId, uint8 defaultMode)
    external
  {
    checkIsTokenOwner(msg.sender, tokenId);

    require (defaultMode <= tokenData[tokenId].modes, "Locked");

    tokenData[tokenId].defaultMode = defaultMode;
  }

  // Unlock the patch
  function unlockPatch(uint256 tokenId)
    external
  {
    checkCanUnlockPatch(msg.sender, tokenId);

    tokenData[tokenId].patchUnlocked = true;
  }

  // --------------- ERC721, ERC721Enumerable overrides --------------//

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
      return super.supportsInterface( interfaceId );
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);

    if (tokenId < _tokenIdCounter) {
      tokenData[tokenId].lastTransfer = block.timestamp;
    }
  }

  // ------------------------ contract owner ------------------------ //

  function setMintPrice(uint256 price)
    external
    Ownable.onlyOwner
  {
    mintPrice = price;
  }

  function withdraw(uint256 amount)
    external
    Ownable.onlyOwner
  {
    require (amount <= address(this).balance, "Amt");

    payable(msg.sender).transfer(amount);
  }

  function setImageBaseURI(string memory baseURI) //, string memory extension )
    external
    Ownable.onlyOwner
  {
    imageBaseURI = baseURI;
  }

  function setAnimationBaseURI(string memory baseURI) //, string memory extension )
    external
    Ownable.onlyOwner 
  {
    animationBaseURI = baseURI;
  }

  function setExternalBaseURI(string memory baseURI)
    external
    Ownable.onlyOwner 
  {
    externalBaseURI = baseURI;
  }

  function setDescription(string memory desc)
    external
    Ownable.onlyOwner 
  {
    description = desc;
  }

  function setTokenURIContract(IOraandURI uriContract)
    external
    onlyOwner
  {
    tokenURIContract = uriContract;
  }

  // ---------------------------- base64 ---------------------------- //

  // From OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol) - MIT Licence
  // @dev Base64 Encoding/Decoding Table
  string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  //@dev Converts a `bytes` to its Bytes64 `string` representation.

  function base64Encode(bytes memory data) internal pure returns (string memory) {

      // Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
      // https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
      if (data.length == 0) return "";

      // Loads the table into memory
      string memory table = _TABLE;

      // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
      // and split into 4 numbers of 6 bits.
      // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
      // - `data.length + 2`  -> Round up
      // - `/ 3`              -> Number of 3-bytes chunks
      // - `4 *`              -> 4 characters for each chunk
      string memory result = new string(4 * ((data.length + 2) / 3));

      /// @solidity memory-safe-assembly
      assembly {
          // Prepare the lookup table (skip the first "length" byte)
          let tablePtr := add(table, 1)

          // Prepare result pointer, jump over length
          let resultPtr := add(result, 32)

          // Run over the input, 3 bytes at a time
          for {
              let dataPtr := data
              let endPtr := add(data, mload(data))
          } lt(dataPtr, endPtr) {

          } {
              // Advance 3 bytes
              dataPtr := add(dataPtr, 3)
              let input := mload(dataPtr)

              // To write each character, shift the 3 bytes (18 bits) chunk
              // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
              // and apply logical AND with 0x3F which is the number of
              // the previous character in the ASCII table prior to the Base64 Table
              // The result is then added to the table to get the character to write,
              // and finally write it in the result pointer but with a left shift
              // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

              mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
              resultPtr := add(resultPtr, 1) // Advance

              mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
              resultPtr := add(resultPtr, 1) // Advance

              mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
              resultPtr := add(resultPtr, 1) // Advance

              mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
              resultPtr := add(resultPtr, 1) // Advance
          }

          // When data `bytes` is not exactly 3 bytes long
          // it is padded with `=` characters at the end
          switch mod(mload(data), 3)
          case 1 {
              mstore8(sub(resultPtr, 1), 0x3d)
              mstore8(sub(resultPtr, 2), 0x3d)
          }
          case 2 {
              mstore8(sub(resultPtr, 1), 0x3d)
          }
      }
      return result;
  }
}