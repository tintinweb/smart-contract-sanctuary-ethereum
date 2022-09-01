// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/GamePlayTest.sol


// File: @opengsn/gsn/contracts/interfaces/IRelayRecipient.sol


pragma solidity >=0.6.2;









//change pickwinner fn to get randomnum


/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

// File: @opengsn/gsn/contracts/BaseRelayRecipient.sol


// solhint-disable no-inline-assembly
pragma solidity >=0.6.2;


/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}

// File: contracts/TestGasLessGame.sol


// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */



contract GamePlayTest is BaseRelayRecipient,IERC721Receiver {

    uint public entryPrice;
    address  payable public contractOwner;
    uint public active_houses; 
    uint public completed_houses; 
    uint public totalTokensAvailable;
    uint public counter;
    mapping(address=>address) tokenOracleMapping;
    mapping(address=>uint) TokenDecimals;
    mapping(address=>uint) ChainLinkDecimals;
    uint  public predictionUpperLimit;
    uint public  minimumBettingPrice;
    



    //event addedTimeStamps(uint _predictedTimeStamp,uint _joinuntilTimestamp, uint _houseId);


    event houseAdded(uint _houseId,string _name, string _description, uint _joinuntilTimestamp,address _creator);

    event ERC20HouseAdded(uint _houseId,uint bettingtokenAmount , bool _acceptsOtherToken);

    event bettingGameAdded(uint _houseId,uint _predictedTimeStamp,address _predictedTokenAddress,uint _predictionUpperPrice,uint _predictionLowerPrice);

    event enteredERC20House(uint _houseId,address _secondPlayer, address _bettingTokenAddress , uint _bettingAmount, uint _joinedAt);

    event entryPriceChanged(uint _newPriceInUSD);

    event upperTimeLimitChanged(uint _newUpperTimeStamp);

    event minimumBettingPriceChanged(uint _minBettingPrice);

    event winnerSelected(uint _houseId, address _winner);

    event gameCancelled(uint _houseId);

    event leaveGame(uint _houseId , address _secondPlayer);

    event prizeclaimed(uint _houseId , address _creator);
    
    
    struct PlayHouse{
        string housename;
        string gameDescription;
        bool isActive;
        address creator;
        address winner;
        uint totalEntries;
        mapping(uint=>address) entries;
        mapping(address => bool)  isInGame;
        mapping(uint=>uint) bettingPrices;
        mapping(uint=>address) tokenAddresses;
        uint houseId;

        mapping (address => bool) hasConfirmedToProceed;
        mapping(uint=>bool) isOtherToken;
        uint totalApprovals;
        bool acceptOtherToken;
        bool isNFT;
        string timeStamp;
        uint startedTimestamp;
        uint entryTillTimestamp;
        NFTbet creatorNFT;
        NFTbet secondPersonNFT;
        bool isBettingGame;                 //0-betting , 1-sports
        BettingGame bettingGame;
        SportsGame  sportsGame;

    }

    struct NFTbet{
        address contractAddress;
        uint tokenID;
    }

    struct SportsGame{
        string name;
    }

    struct BettingGame{
        address tokenAddr;
        uint timestamp;
        PredictedAmount predictedAmount;
        uint amountToPickWinner;
        //This is the amount in future time... at the time jasma bet garera yeti huncha vaneko cha 
    }

    struct PredictedAmount{
        uint predictedAmountUpper;
        uint predictedAmountLower;
    }

    


    

    //here house id will map to individual playHouse
    mapping(uint => PlayHouse) playhouses;

    //here activeTimestamps will map to array of houses after 2 entries
    mapping(uint=>uint[]) timetoPredictMapToHouses;

//here joinuntilTime will map to array of houses.
    mapping (uint=>uint[]) joinuntilTimeMapToHouses;

    // mapping(uint=>uint) houseToUSDpriceAtPredictedTime;     //house ma.... time pugda ko huni latest value
    uint public totalPlayHouses; 
    //uint[] activeHousesId;
    //uint[]  activetimestamps;

    // uint public  toUpdateHouseId; 
    //The playhouse that needs to be updated when checked through upkeep

    address private EthAdress = 0x0000000000000000000000000000000000000000;
   
	//string public override versionRecipient = "2.0.0";
     function versionRecipient() public pure override  returns (string memory){
         return "2.0.0";
     }


      modifier only_owner(uint playHouseId){
        require( playhouses[playHouseId].creator==_msgSender());
        _;
    }

    modifier only_contract_creator(){
        require( _msgSender()==contractOwner);
        _;
    }


     
    constructor(uint _entryPrice, uint _upperLimitTimestamp,uint _minimumBettingPrice, address _forwarder) {
        trustedForwarder = _forwarder;
        contractOwner = payable(_msgSender());
        entryPrice = _entryPrice;
        minimumBettingPrice = _minimumBettingPrice;
        predictionUpperLimit = _upperLimitTimestamp;
    }

    

    // function getActiveGamesId() public view returns(uint[] memory ids){
    //     uint[] memory _temp;
    //     return  _temp;
    // }

//     function removeFromActiveHouses(uint data) public{
   
//     for(uint i =0; i<activeHousesId.length;i++){
//         if(activeHousesId[i]==data){
           
//             activeHousesId[i] = activeHousesId[activeHousesId.length - 1];
//             activeHousesId.pop();
//             break;
//         }
//     }
    
//   }


//   function sort_array(uint[] memory arr) private pure returns (uint[] memory) {
//         uint256 l = arr.length;
//         for(uint i = 0; i < l; i++) {
//             for(uint j = i+1; j < l ;j++) {
//                 if(arr[i] < arr[j]) {
//                     uint temp = arr[i];
//                     arr[i] = arr[j];
//                     arr[j] = temp;
//                 }
//             }
//         }
//         return arr;
//     }


//-------------- from automated InputScript--------------------


    function addTokenDecimals(address tokenAddr,uint decimalVal) public {
        TokenDecimals[tokenAddr] = decimalVal;
    }
     function addChainLinkDecimals(address tokenAddr,uint decimalVal) public {
        ChainLinkDecimals[tokenAddr] = decimalVal;
    }

    //---------------Set via constructor.. you can change yeti

    function setUpperLimit(uint _newTimeLimit) public only_contract_creator{
        predictionUpperLimit = _newTimeLimit;
        emit upperTimeLimitChanged(_newTimeLimit);
    }

    function setNewEntryPrice(uint _entryPrice) public only_contract_creator{
        //It is in dollars 8 decimal value
        entryPrice = _entryPrice;

        emit entryPriceChanged(_entryPrice);
    }

    function setMinimumBettingPrice(uint _bettingPrice) public only_contract_creator{
        minimumBettingPrice = _bettingPrice;
         //It is in dollars 8 decimal value
         emit minimumBettingPriceChanged(_bettingPrice);
         
    }


    address public callerForAutomated;

  

//   function checkIf(uint houseId) public view returns(bool){
//       return playhouses[houseId].bettingGame.timestamp < block.timestamp;
//   }



 
//   function checktimestamps(uint houseId) public view returns(uint actualTimeStamp,uint betting_time){
//     return (block.timestamp,playhouses[houseId].bettingGame.timestamp);
//   }


//    function checkUpkeep(bytes calldata  /*checkData*/ ) external view  override returns (bool upkeepNeeded, bytes memory  /* performData */ ) {
//         bool _temp= false;
       
//         for(uint i =0 ; i <activeHousesId.length; i++){
//             if((playhouses[activeHousesId[i]].bettingGame.timestamp < block.timestamp) && playhouses[activeHousesId[i]].totalEntries==2){
//                 _temp = true;
//                 break;
//             }                   //homeID which is active
//         }
//         upkeepNeeded = _temp;
//         // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
//         // performData= checkData;
//     }

    // function performUpkeep(bytes calldata  /*performData*/ ) external override {

    //    //  automateWinnerSelection();
        
    //     // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    // }

    
    // function manualThird() public view returns(uint latestval,bool greatorthan){
    //     PlayHouse storage toUpdateHouse =  playhouses[0]; 
    //         address chainAddress = tokenOracleMapping[toUpdateHouse.bettingGame.tokenAddr];
    //         uint latestValue = uint(getLatestUSDPrice(chainAddress));
            
    //         bool _creatorbetForgreaterThan = toUpdateHouse.bettingGame.willbeGreaterthan;
    //     return (latestValue,_creatorbetForgreaterThan);
    // }

            function automateWinnerSelection(uint _houseId) public {

                    require(playhouses[_houseId].bettingGame.timestamp < block.timestamp);

                    callerForAutomated = _msgSender();

                    uint _toUpdateHouseId = _houseId;
                    PlayHouse storage toUpdateHouse =  playhouses[_toUpdateHouseId];
                // address chainAddress = tokenOracleMapping[toUpdateHouse.bettingGame.tokenAddr];
                    uint latestValue = uint(getLatestUSDPrice(toUpdateHouse.bettingGame.tokenAddr));
                    toUpdateHouse.bettingGame.amountToPickWinner =latestValue;
                    address _winner;

                if((toUpdateHouse.bettingGame.predictedAmount.predictedAmountUpper> latestValue) && (latestValue > toUpdateHouse.bettingGame.predictedAmount.predictedAmountLower)){
                    _winner = toUpdateHouse.entries[0];
                    
                }   else{
                    _winner = toUpdateHouse.entries[1];
                }

                    toUpdateHouse.winner= _winner;
                    toUpdateHouse.isActive = false;
      
                    active_houses--;
                    completed_houses++;
                    emit winnerSelected(_houseId, _winner);


               // activetimestamps.pop();
               // removeFromActiveHouses(_toUpdateHouseId);
            }

        
        
              
            //    uint _toUpdateHouseId = activeHousesId[i];
            //    PlayHouse storage toUpdateHouse =  playhouses[_toUpdateHouseId];
            //         //We highly recommend revalidating the upkeep in the performUpkeep function

            //         //winner pick garni ... for betting...
            //     address chainAddress = tokenOracleMapping[toUpdateHouse.bettingGame.tokenAddr];
            //     uint latestValue = uint(getLatestUSDPrice(chainAddress));
            //     timestampToUSDprice[playhouses[activeHousesId[i]].bettingGame.timestamp] = latestValue;
            //     activetimestamps.pop();
            //     removeFromActiveHouses(_toUpdateHouseId);

                //   bool _creatorbetForgreaterThan = toUpdateHouse.bettingGame.willbeGreaterthan;

                // //toUpdateHouse.bettingGame.amountToPickWinner = latestValue;
                // if(_creatorbetForgreaterThan){
                //         if(latestValue>toUpdateHouse.bettingGame.predictedAmount){
                //     //winner is the creator...
                //              pickWinner(_toUpdateHouseId,0,toUpdateHouse.isNFT );
                //         }
                //         else{
                //     //winner is the second person
                //                 pickWinner(_toUpdateHouseId,1,toUpdateHouse.isNFT );
                //         }
                // }
                // else{
                //         if(latestValue<toUpdateHouse.bettingGame.predictedAmount){
                //     //winner is the creator...
                //         pickWinner(_toUpdateHouseId,0,toUpdateHouse.isNFT );
                //         }
                //         else{
                //             pickWinner(_toUpdateHouseId,1,toUpdateHouse.isNFT );
                //     //winner is the second person
                //         }
                // }
                
                               //homeID which is active
        
    


    // function manuallyperformUpkeep() public {
    //    // uint _toUpdateHouseId;

    //     counter++;
    //     for(uint i =0 ; i <activeHousesId.length; i++){
    //         if(playhouses[activeHousesId[i]].bettingGame.timestamp < block.timestamp){
    //            uint _toUpdateHouseId = activeHousesId[i];
    //            PlayHouse storage toUpdateHouse =  playhouses[_toUpdateHouseId];
    //                 //We highly recommend revalidating the upkeep in the performUpkeep function

    //                 //winner pick garni ... for betting...
    //             address chainAddress = tokenOracleMapping[toUpdateHouse.bettingGame.tokenAddr];
    //             uint latestValue = uint(getLatestUSDPrice(chainAddress));

    //             toUpdateHouse.bettingGame.amountToPickWinner = latestValue;
    //             break;
    //         }                   //homeID which is active
    //     }
        
     
    // }

    function claimPoolPrize(uint homeID) public {
        PlayHouse storage p4 =  playhouses[homeID];
        require(_msgSender()==p4.winner,"You are not the winner");
       // bool _creatorbetForgreaterThan = p4.bettingGame.willbeGreaterthan;
       

               bool isNFT = p4.isNFT;
               address _winnerAddress= p4.winner;
       
       if(isNFT){
            
                    IERC721 nft1 = IERC721(p4.creatorNFT.contractAddress);
                    IERC721 nft2 = IERC721(p4.secondPersonNFT.contractAddress);

                    nft1.transferFrom(address(this),_winnerAddress,p4.creatorNFT.tokenID);
                    nft2.transferFrom(address(this),_winnerAddress,p4.secondPersonNFT.tokenID);
            
       }
       else{
           require(!p4.isNFT,"A NFT project");
             if(p4.tokenAddresses[0]==p4.tokenAddresses[1]){
               uint _total = p4.bettingPrices[0]+p4.bettingPrices[1];

               if(p4.tokenAddresses[0]==EthAdress){
                     payable(_winnerAddress).transfer(_total);
                }
                 else{
                     IERC20 token = IERC20(p4.tokenAddresses[0]);
                     token.transfer(_winnerAddress,_total);
                }
              
           }
           else{
            for(uint i =0 ; i <2 ; i++){
                 if(p4.tokenAddresses[i]==EthAdress){
                     payable(_winnerAddress).transfer(p4.bettingPrices[i]);
                 }
                 else{
                    // otherTokenTransfer(_homeId,i,_winnerAddress);
                    IERC20 token = IERC20(p4.tokenAddresses[i]);
                    token.transfer(_winnerAddress,p4.bettingPrices[i]);
                 }
            
            }

           }
       }

       emit prizeclaimed(homeID , _winnerAddress);
    }


    

    




   
    // function createBettingGame() public{

    // }

    // function createSportsGame() public{
        
    // }

        

    function addPlayHouse(string memory _name , string memory _description , uint _entryTillTimestamp, uint _houseId) internal{
           
           require(_entryTillTimestamp>0);
            PlayHouse storage p1 =  playhouses[_houseId];
            p1.housename = _name;
            p1.gameDescription = _description;
            p1.creator = _msgSender();
            p1.isActive = true;
            p1.isInGame[_msgSender()] = true; 
            p1.entries[0]=(_msgSender());
            p1.totalEntries+=1;
           // activeHousesId.push(totalPlayHouses);
            p1.startedTimestamp = block.timestamp;
            p1.entryTillTimestamp=_entryTillTimestamp+block.timestamp;

            joinuntilTimeMapToHouses[_entryTillTimestamp+block.timestamp].push(totalPlayHouses);
            p1.houseId = totalPlayHouses;
           

            //event houseAdded(uint _houseId,string _name, string _description,address _creator);
            emit houseAdded(totalPlayHouses,_name,_description,_entryTillTimestamp,_msgSender());
            
            totalPlayHouses++;
            active_houses++;
    }

    function addNFTPlayHouse(address ownerContract,uint ownerTokenId,address secondContract,uint secondTokenId,uint _houseId) internal{
             PlayHouse storage p1 =  playhouses[_houseId];
            p1.creatorNFT.contractAddress = ownerContract;
            p1.creatorNFT.tokenID = ownerTokenId;
            p1.secondPersonNFT.contractAddress = secondContract;
            p1.secondPersonNFT.tokenID = secondTokenId;
            p1.isNFT = true;
    }

    function addERC20PlayHouse(uint _bettingPrice,address tokenAddr,bool _acceptOtherToken,bool _isOtherToken,uint _houseId) internal{
            PlayHouse storage p1 =  playhouses[_houseId];
            p1.bettingPrices[0]=(_bettingPrice);
            p1.tokenAddresses[0]=(tokenAddr);
            p1.acceptOtherToken = _acceptOtherToken;
            p1.isOtherToken[0] = _isOtherToken;

            emit ERC20HouseAdded(_houseId, _bettingPrice , _acceptOtherToken);
    }
    
    function  addBettingGame(uint predictedValueUpper,uint predictedValueLower,address tokenToWatch,uint _predictedTimestamp,uint _houseId) private {
                    require(_predictedTimestamp<(block.timestamp+predictionUpperLimit),"Limit crossed");
                    require(predictedValueUpper>0 && predictedValueLower>0,"zero this is");
  PlayHouse storage p1 =  playhouses[_houseId];
                    //p1.bettingGame.willbeGreaterthan = willIncrease;  
                    p1.bettingGame.predictedAmount.predictedAmountUpper = predictedValueUpper;  
                    p1.bettingGame.predictedAmount.predictedAmountLower = predictedValueLower;  
                    p1.bettingGame.timestamp = _predictedTimestamp;  
                    p1.bettingGame.tokenAddr = tokenToWatch;
                  
                    p1.isBettingGame = true;
                    p1.totalApprovals = 1;
                    p1.hasConfirmedToProceed[_msgSender()] = true;


                    // event bettingGameAdded(uint _houseId,uint _predictedTimeStamp,address _predictedTokenAddress,address _predictionUpperPrice,address _predictionLowerPrice);

                    emit bettingGameAdded(_houseId, _predictedTimestamp,tokenToWatch,predictedValueUpper,predictedValueLower);
                   
    }

    

    function createHouseForERC20withEth(string memory _name ,uint _joinuntilTimestamp, string memory _description ,uint _bettingPrice,bool acceptOtherToken,bool isBettingGame,address tokenToWatch,uint predictedValueUpper,uint predictedValueLower,uint predictedTimestamp) public payable{
            
            uint _entryPrice = convertUSDToTokenAmount(entryPrice,EthAdress);
          
           //require(_bettingPrice>=minimumBettingPrice,"Minimum betting price");
            uint _bettingAmount = convertUSDToTokenAmount(minimumBettingPrice,EthAdress);

            require(_bettingPrice>=_bettingAmount,"LEss than minimum betting amount");
           

       
            require(msg.value>=(_bettingPrice+_entryPrice),"Invalid amount");
        //    PlayHouse storage p1 =  playhouses[totalPlayHouses];

           
          addERC20PlayHouse(_bettingPrice,0x0000000000000000000000000000000000000000,acceptOtherToken,false,totalPlayHouses);
        

            if(isBettingGame){

                addBettingGame( predictedValueUpper, predictedValueLower, tokenToWatch,predictedTimestamp,totalPlayHouses);
                  
            }
            else{

            }
              addPlayHouse(_name,_description,_joinuntilTimestamp,totalPlayHouses);

          
            
    }

        function createHourseForERC20withERC20(string memory _name ,uint _joinuntilTimestamp, string memory _description ,uint _bettingAmount, address tokenAddr,bool acceptOtherToken,bool isBettingGame,address tokenToWatch,uint predictedValueUpper,uint predictedValueLower,uint predictedTimestamp) public payable{

            IERC20 token = IERC20(tokenAddr);

            require(msg.value>=(convertUSDToTokenAmount(entryPrice,EthAdress)),"less entryprice");

            require((token.balanceOf(_msgSender())>_bettingAmount),"Balance must be greater");
       
            require(_bettingAmount>=minimumBettingPrice);

            uint _bettingToken = convertUSDToTokenAmount(minimumBettingPrice,tokenAddr);

                require(_bettingAmount>=_bettingToken,"Less betting");
     
            token.transferFrom(_msgSender(),address(this),_bettingAmount);

           uint _houseId =  totalPlayHouses;
            addERC20PlayHouse(_bettingAmount,tokenAddr,acceptOtherToken,false,_houseId);
         if(isBettingGame){
                addBettingGame( predictedValueUpper,predictedValueLower, tokenToWatch,predictedTimestamp,_houseId);
            }
            else{
            }
            addPlayHouse(_name,_description,_joinuntilTimestamp,_houseId);
            // emit addedTimeStamps(predictedTimestamp,(_joinuntilTimestamp+block.timestamp),totalPlayHouses);
         
     
    }

    function convertUSDToTokenAmount(uint USDamount,address tokenToConvert) public view returns (uint){
         uint _latestPrice = uint(getLatestUSDPrice(tokenToConvert));
         uint _getDecimalsOfToken = TokenDecimals[tokenToConvert];
         uint _temp;

         //latestPrice always has 8 decimals , to get the token ko decimal ... 
         if(_getDecimalsOfToken>8){
            _temp = uint((((USDamount) *(10**_getDecimalsOfToken))/(_latestPrice))*10**(_getDecimalsOfToken-8));
         }
         else{
            _temp = uint((((USDamount) *(10**_getDecimalsOfToken))/(_latestPrice))/10**(8-_getDecimalsOfToken));
         }
          
           return    uint(((USDamount) *(10**_getDecimalsOfToken))/(_latestPrice));
    }

 

    // function createHouseForNFT(string memory _name,uint _joinuntilTimestamp,address ownerContract,uint ownerTokenId,address secondContract,uint secondTokenId,bool isBettingGame,bool willIncrease,address tokenToWatch,uint predictedValue,uint predictedTimestamp) public payable{

    //         require(msg.value>=(entryPrice));
    //         address firstNFTOwner= getNFTOwner(ownerContract,ownerTokenId);
    //         require(firstNFTOwner==_msgSender());

    //         address secondNFTOwner= getNFTOwner(secondContract,secondTokenId);
    //         require(secondNFTOwner!=_msgSender());


    //         IERC721 nft = IERC721(ownerContract);
    //         nft.safeTransferFrom(_msgSender(),address(this),ownerTokenId);

    //         PlayHouse storage p1 =  playhouses[totalPlayHouses];        
    //         addNFTPlayHouse(ownerContract,ownerTokenId,secondContract,secondTokenId,p1);

    //          if(isBettingGame){
                 
    //             addBettingGame(willIncrease, tokenToWatch, predictedValue,predictedTimestamp,p1);

    //         }
    //               //For sports game 
    //         else{

    //         }
    //        // addPlayHouse(_name,'',_joinuntilTimestamp,p1);

    // }

    function entryForNFT(address _contract,uint _tokenId,uint _hId) public payable{
            address secondNFTOwner= getNFTOwner(_contract,_tokenId);
            require(msg.value>=(entryPrice),"Insufficient entry price");
            
            require(secondNFTOwner==_msgSender(),"You donot own the NFT");
            PlayHouse storage p1 =  playhouses[_hId]; 
            require(_contract==p1.secondPersonNFT.contractAddress,"Different contract address");
            require(_tokenId==p1.secondPersonNFT.tokenID,"Different tokenId");

            IERC721 nft = IERC721(_contract);
            nft.safeTransferFrom(_msgSender(),address(this),_tokenId);
             

        p1.entries[1]=(_msgSender());
        p1.totalEntries++;
        p1.isInGame[_msgSender()]=true;



    }

    function getPlayer(uint hId,uint playerId) public view returns(address player){
        return playhouses[hId].entries[playerId];
    }

     function getTokenAddr(uint hId,uint playerId) public view returns(address tokenAddr){
        return playhouses[hId].tokenAddresses[playerId];
    }

     function getBettingPrice(uint hId,uint playerId) public view returns(uint bettingPrice){
        return playhouses[hId].bettingPrices[playerId];
    }

    function getchainLinkDecimals(address _tokenADdr) public view returns(uint _chainLinkDecimals){
        return ChainLinkDecimals[_tokenADdr];
    }

    function getLatestUSDPrice(address _tokenAddress) public view returns (int) {
        address _chainAddress = tokenOracleMapping[_tokenAddress];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_chainAddress);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getRequiredConversionPrice(address from, address to,uint amount) public view returns(uint){

        int fromData;
        uint fromDecimals;

      
            fromData= getLatestUSDPrice(from);
            fromDecimals = TokenDecimals[from];
        
        
        int toData = getLatestUSDPrice(to);
      //  uint decimalDifference = TokenDecimals[]
      
      uint toDecimals = TokenDecimals[to];
     
      uint toReturn;

      

            if(fromDecimals>=toDecimals){
        toReturn =((uint(fromData)*amount)/(uint(toData)*10**(fromDecimals-toDecimals)));
        }
        else{
        toReturn =((uint(fromData)*amount*10**(toDecimals-fromDecimals))/uint(toData));
            }

      

     


        return toReturn;
        
    }

    //  function getActiveHousesId() public view returns(uint[] memory){
    //   uint[] memory _data = activeHousesId;
    //   return _data;
    //  }

     function getTimestampMapToHouses(uint timestamp) public view returns(uint[] memory _data){
         uint[] memory _temp = timetoPredictMapToHouses[timestamp];
         return _temp;
     }
     function getJoinUntilTimeMapToHouses(uint timestamp) public view returns(uint[] memory _data){
          uint[] memory _temp = joinuntilTimeMapToHouses[timestamp];
         return _temp;
     }

    //  function getACtiveTimeStamps() public view returns(uint[] memory _data){
    //      uint[] memory _temp = activetimestamps;
    //      return _temp;
    //  }

    function getCurrentTimestamp() public view returns(uint){
        return block.timestamp;
    }

    // function gethouseToUSDpriceAtPredictedTime(uint _hid) public view returns(uint){
    //     return houseToUSDpriceAtPredictedTime[_hid];
    // }


      function getApprovalCount(uint _hid) public view returns(uint){
      return  playhouses[_hid].totalApprovals;
    }
    
    function getNFTOwner(address contractAddr,uint tokenID) public view returns(address){
        IERC721 nft = IERC721(contractAddr);
        return nft.ownerOf(tokenID);
    }

    // function getTokens(uint hId) public view returns(string memory players){
    //     string memory temp="" ;
    //     for(uint x =0 ; x < playhouses[hId].totalEntries;x++){
    //         temp= string(abi.encodePacked(temp, playhouses[hId].entries[x]));
    //     }
    //     return temp;
    // }

   
    // function deposit(uint _bettingAmount, address tokenAddr) public {
    //     IERC20 token = IERC20(tokenAddr);
    //    token.transfer((address(this)),_bettingAmount);
    // }

    // function tokenApproval(uint _bettingAmount, address tokenAddr) public{
    //      IERC20 token = IERC20(tokenAddr);
    //     token.approve(address(this), _bettingAmount);
    // }

//     function getAllowance(address tokenAddr) public view returns(uint){
//   IERC20 token = IERC20(tokenAddr);
//   return token.allowance(_msgSender(),address(this));
//     }


    function getPlayHouseDatas(uint playHouseId) public view returns(
        uint _houseId,
        string memory _name ,
        string memory _description ,
        address _creator ,
        uint _totalEntries,
        bool isActive,
        bool acceptOther,
        bool isNFT,
        bool isBettingGame,
        uint joinUntil,
        address _winner
        ){
          PlayHouse storage p5 =  playhouses[playHouseId];
        return(
       p5.houseId,
       p5.housename,
       p5.gameDescription,
       p5.creator,
       p5.totalEntries,
       p5.isActive, 
       p5.acceptOtherToken,
       p5.isNFT,
       p5.isBettingGame,
       p5.entryTillTimestamp,
       p5.winner
       );

    }

        // address tokenAddr;
        // uint timestamp;
        // uint predictedAmount;
        // bool willbeGreaterthan;

    function getBettingGameDetails(uint playHouseId) public view returns(
        address predictedToken,
        uint predictedPriceUpper,
        uint predictedPriceLower,
        uint predictedTimeStamp,
        uint priceAtResultTime
    ){
          PlayHouse storage p5 =  playhouses[playHouseId];
    return(
        p5.bettingGame.tokenAddr,
        p5.bettingGame.predictedAmount.predictedAmountUpper,
        p5.bettingGame.predictedAmount.predictedAmountLower,
        p5.bettingGame.timestamp,
         p5.bettingGame.amountToPickWinner
        );
    }

    function getNFTHouseData(uint playHouseId) public view returns(
        address ownerContract,
        address secondContract,
        uint ownerTokenId,
        uint secondTokenId){
             PlayHouse storage p5 =  playhouses[playHouseId];
             address _ownerContract = p5.creatorNFT.contractAddress;
             address _secondContract = p5.secondPersonNFT.contractAddress;
             uint _ownerTokenId = p5.creatorNFT.tokenID;
             uint _secondTokenId = p5.secondPersonNFT.tokenID;

             return(_ownerContract,_secondContract,_ownerTokenId,_secondTokenId);

    }

    
    function addTokenOracleMap(address tokenAddr, address oracleAddr) public only_contract_creator{
            tokenOracleMapping[tokenAddr] = oracleAddr;
            totalTokensAvailable++;
    }

    function entry(uint _playHouseId,address tokenAddr,uint bettingAmount) public payable{


            require(playhouses[_playHouseId].isActive);
            require(!playhouses[_playHouseId].isInGame[_msgSender()],"Player is already in the game");
            require(playhouses[_playHouseId].totalEntries==1 );
            require(block.timestamp<(playhouses[_playHouseId].entryTillTimestamp));
            uint _ethEntryPrice = (convertUSDToTokenAmount(entryPrice,EthAdress));

            if(playhouses[_playHouseId].isBettingGame){


                    if(playhouses[_playHouseId].tokenAddresses[0]==tokenAddr){    //same token/eth used 

                        if(tokenAddr==EthAdress){         //if eth used
                            require((_msgSender().balance)>playhouses[_playHouseId].bettingPrices[0]+_ethEntryPrice);
                           
                            require(msg.value>= (_ethEntryPrice+playhouses[_playHouseId].bettingPrices[0]),"less entryprice");
                        }else{                              //if token used
                            require(msg.value >=_ethEntryPrice,"Insufficient Entry price");
                            IERC20 token = IERC20(tokenAddr);
                            require(token.balanceOf(_msgSender())>=bettingAmount,"Insufficient funds");
                            token.transferFrom(_msgSender(),address(this),bettingAmount);
                        }

                    }
                 else{                                                          //different token / eth value used 
                        if(tokenAddr==EthAdress){ 
                          //convert and check 
                        uint _convertedAmount = getRequiredConversionPrice(playhouses[_playHouseId].tokenAddresses[0],tokenAddr,playhouses[_playHouseId].bettingPrices[0]);
                        require((_msgSender().balance)>_convertedAmount+_ethEntryPrice);
                        require(msg.value >=(_convertedAmount+_ethEntryPrice),"Insufficient entry price");
                        }
                        else{
                        require(msg.value >=_ethEntryPrice,"Insufficient Entry price");
                        IERC20 token = IERC20(tokenAddr);
                            uint _convertedAmount = getRequiredConversionPrice(playhouses[_playHouseId].tokenAddresses[0],tokenAddr,playhouses[_playHouseId].bettingPrices[0]);
                        //convert and check 
                        require(token.balanceOf(_msgSender())>=_convertedAmount,"Insufficient funds here");
                        require(bettingAmount>=_convertedAmount,"Insufficient beting here");
                        token.transferFrom(_msgSender(),address(this),bettingAmount);
                         }
                    }

                    playhouses[_playHouseId].hasConfirmedToProceed[_msgSender()] = true;
                    playhouses[_playHouseId].totalApprovals +=1;
                    timetoPredictMapToHouses[playhouses[_playHouseId].bettingGame.timestamp].push(_playHouseId);
                   // activetimestamps.push(playhouses[_playHouseId].bettingGame.timestamp);
                    //activetimestamps = sort_array(activetimestamps);
                    

                        //event enteredERC20House(uint _houseId,address _secondPlayer, address _bettingTokenAddress , uint _bettingAmount, uint _joinedAt);

                        emit enteredERC20House(_playHouseId,_msgSender(),tokenAddr,bettingAmount,block.timestamp);

           
           
           
            }
            else{
                //for sports game
            }

            

        
        playhouses[_playHouseId].tokenAddresses[1]=(tokenAddr);
        playhouses[_playHouseId].bettingPrices[1]=(bettingAmount);

        playhouses[_playHouseId].entries[1]=(_msgSender());
        playhouses[_playHouseId].totalEntries++;
        playhouses[_playHouseId].isInGame[_msgSender()]=true;


        //If 2 people are there... emit event to say.. no need to look after joinun


    }


    // function checkAllowance(address tokenAddr) public view returns(uint) {
    //     IERC20 token = IERC20(tokenAddr);
    //     return token.allowance(_msgSender(),address(this));

    // }

    // function withdraw() public only_contract_creator payable only_contract_creator{
    //    uint currentBalance= address(this).balance;
    //     payable(contractOwner).transfer(currentBalance);
    // } 
    
    // function getContractBalance() public only_contract_creator view returns(uint) {
    //     return (address(this).balance);
    // } 

    // function getContractTokenBalance(address tokenAddr) public only_contract_creator view returns(uint) {
    //     IERC20 token = IERC20(tokenAddr);
    //     return token.balanceOf(address(this));
    // }



    function cancelGameHouse(uint _playhouseId) public {
       //shouuld only be done by relayer...
        require(playhouses[_playhouseId].totalEntries==1);
        require(block.timestamp>playhouses[_playhouseId].entryTillTimestamp);
        require(playhouses[_playhouseId].isActive);
        playhouses[_playhouseId].isActive = false;


        emit gameCancelled(_playhouseId);

        //event gameCancelled(uint _houseId);

        
    }

    function refundOnCancel(uint _playhouseId) public payable only_owner(_playhouseId){
        require(playhouses[_playhouseId].totalEntries==1,"Already 2 people");
        require(!playhouses[_playhouseId].isActive);

            IERC20 token = IERC20(playhouses[_playhouseId].tokenAddresses[0]);
            token.transfer(playhouses[_playhouseId].entries[0],playhouses[_playhouseId].bettingPrices[0]);

            emit prizeclaimed(_playhouseId , _msgSender());
    }


    // function startGame(uint _playHouseId) public {
    //      require (playhouses[_playHouseId].creator == _msgSender(),"Other cannot start");
    //      playhouses[_playHouseId].totalApprovals = 1;
    //      playhouses[_playHouseId].hasConfirmedToProceed[_msgSender()] = true;
    // }
   

    // function approveByOtherPlayer(uint _playHouseId,uint randomNum) public{
    //     PlayHouse storage p3 =  playhouses[_playHouseId];
    //     require(p3.isActive,"Already completed");
    //     require(p3.isInGame[_msgSender()],"Player is not in game");
    //     require(!p3.hasConfirmedToProceed[_msgSender()],"Already procedded");
    //      p3.hasConfirmedToProceed[_msgSender()] = true;
    //     p3.totalApprovals +=1;

    //     if(p3.isBettingGame){

    //     }
    //     else{

    //     pickWinner(_playHouseId,randomNum);

    //     }
         
    // }

    function changeEntryPrice(uint _entryPrice) public only_contract_creator{
            entryPrice = _entryPrice;
    }



    // function leaveGame(uint _playHouseId) public{
        
    //     PlayHouse storage p2 =  playhouses[_playHouseId];
    //     require(p2.isInGame[_msgSender()]);
        
    //     require(p2.isActive);
    //     p2.isInGame[_msgSender()] = false;
    //     p2.totalEntries = p2.totalEntries-1;
    //     if(p2.creator!=_msgSender()){
    //          p2.isInGame[_msgSender()]=false;
            
    //         //Here, for the coin flip, we give out the result almost instantly,, 
    //         //but for others game, user may leave game before its completion... soooo

    //         if(p2.hasConfirmedToProceed[_msgSender()]){
    //             p2.hasConfirmedToProceed[_msgSender()] = false;
    //             p2.totalApprovals -=1;

    //         }
    //     }

    // }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external pure returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    // function pickWinner (uint _homeId,uint _index) public payable{

    //    PlayHouse storage p4 =  playhouses[_homeId];
    //    require(p4.totalApprovals==2,"Less approval");
    //    address _winnerAddress = p4.entries[_index];
       
    //    p4.winner = _winnerAddress;
    //    p4.isActive = false;
      
    //    active_houses--;
    //    completed_houses++;
        
    // }

      function checkIfTimeHasArrived(uint _timestamp) public view returns(bool){
      return _timestamp<block.timestamp;
  }

    // function otherTokenTransfer(uint hid,uint id,address _winnerAddress) public payable{
    //                 IERC20 token = IERC20(playhouses[hid].tokenAddresses[id]);
    //                 token.transfer(_winnerAddress,playhouses[hid].bettingPrices[id]);
    // }

    // function checkContractBalance(address tokenAddr) public view returns(uint){
    //       IERC20 token = IERC20(tokenAddr);
    //                return token.balanceOf(address(this));
    // }

    //   function checkUserNFTBalance(address userAddr, address contractAddr) public view returns(uint){
    //      IERC721 nft = IERC721(contractAddr);
    //      return nft.balanceOf(userAddr);
    // }

    // function NFTdetails(address contractAddr) public view returns(string memory name, string memory symbol,uint totalSupply){
    //         IERC721 nft = IERC721(contractAddr);
    //         IERC721Enumerable nft2 = IERC721Enumerable(contractAddr);
    //         string memory _name = nft.name();
    //         string memory _symbol = nft.symbol();
    //         uint _totSupply = nft2.totalSupply();

    //         return(_name,_symbol,_totSupply);

    // }

    

    // function getTokenIDFromIndexOfUser(address contractAddr,uint index) public view returns (uint tokenID){
    //      IERC721Enumerable nft = IERC721Enumerable(contractAddr);
    //     return nft.tokenOfOwnerByIndex(msg.sender,index);
    // }

    // function getTokenURI(address contractAddr,uint tokenId) public view returns(string memory uri){
    //     IERC721 nft = IERC721(contractAddr);
    //     return nft.tokenURI(tokenId);
    // }
}