/**
 *Submitted for verification at Etherscan.io on 2023-02-09
*/

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// File: collective.sol



pragma solidity ^0.8.0;





contract CollectivePortraitRegistry is ERC1155, ERC1155Supply, Ownable {
    /*
    DISCLAIMER: THIS CONTRACT IS CONFIDENTIAL AND SHOULD NOT BE SHARED WITH ANYONE OUTSIDE OF YOUR TEAM.

    This is an early version of the Collective Portrait contract. It has not been audited, but it has been deployed. It is a work in progress.

    */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* ETH/USD Oracle price feed through Chainlink, used to calculate the price of a Collective Portrait. Goerli usage. */
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */

    // Test if this works, instead of ERC1155.
    constructor() ERC1155("Collective Portrait") {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    /* 
    Function to update the priceFeed by the owner.
    */
    function setPriceFeed(address _priceFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * Returns the price in Wei for a given amount of USD.
     */
    function usdToWei(uint256 _amount) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjust_price = uint256(price) * 1e10;
        uint256 usd = _amount * 1e18;
        uint256 rate = (usd * 1e18) / adjust_price;
        return rate;
    }

    /* ERC-1155 contract information for OpenSea */
    string public name = "Collective Portrait";

    /* Portrait Treasury address
     */
    address public treasury = 0xd08d9592099eeB3aA16fedCE29e76a535dc88587;

    /*
    Function to set the treasury address by the owner.
    */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    /* Function to transfer ownership of the contract to a new address */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /*
    This is a basic structure to keep track of the portraitHash (IPFS CID) and the minimumControlShares. It's the bare minimum to update and govern a Collective Portrait.
    */
    struct Record {
        string portraitHash;
        uint256 minimumControlShares;
        uint256 validUntil;
    }

    /*
    Creating human readable names for Collective Portraits such that users can register unique names for their Portraits.
    This mapping stores the records for each name. The name is the key. The value is a struct containing the portraitHash and the minimumControlShares.
    */
    mapping(string => Record) public records;

    /*
    This mapping stores the names for each token ID. The token ID is the key. The value is the name.
    The reason this mapping exists is because the ERC1155 standard does not allow for 'id' of type string, it has to be uint256.
    We use the 'id' for ERC1155 functions such as 'balanceOf' and 'balanceOfBatch'.
    */
    mapping(uint256 => string) public namesByTokenId;

    /*
    This mapping stores the user balances for each token ID.
    The objective of this mapping is to keep track of the number of shares each user has for each token ID, so that we can prevent a scenario in which a user has less than the minimumControlShares.
    */
    mapping(uint256 => mapping(address => uint256))
        public tokenBalancesByTokenId;

    // Iteratable data structure to store the holders of a token ID.
    mapping(uint256 => address[]) public tokenHoldersByTokenId;

    /*
    As 'id' is of type uint256, we have to create an identifier for each token. This is the counter for the token IDs.
    */
    uint256 portraitCount;

    function mintPortrait(
        string memory _name,
        uint256 _shares,
        uint256 _minimumControlShares,
        uint256 _years
    ) public payable {
        // Require shares to be at least 1
        require(_shares >= 1, "shares can not be less than 1");

        // Require minimumControlShares to be less or equal to the total shares
        require(
            _minimumControlShares <= _shares,
            "minimumControlShares can not be more than the total shares"
        );

        // Require minimumControlShares to be at least 1
        require(
            _minimumControlShares >= 1,
            "minimumControlShares can not be less than 1"
        );

        string[] memory _names = new string[](1);
        _names[0] = _name;
        // The first value in the array of getStatus([name]) is the status code. 0 means the name is available.
        require(getStatus(_names)[0] == 0, "Name is not available");

        // Name can not be longer than 64 characters.
        require(
            bytes(_name).length <= 64,
            "Name can not be longer than 64 characters"
        );

        // Name has to be at least 3 char
        require(
            bytes(_name).length >= 3,
            "Name has to be at least 3 characters"
        );

        // Name can not be an Ethereum address
        require(!isAddress(_name), "Name can not be an Ethereum address");

        // Name can only have a-z and 0-9
        require(isAlphaNumeric(_name), "Name can only contain a-z and 0-9");

        uint256 price;

        // If isAuction, use the auctionPrice
        if (isAuction(_name)) {
            price = getAuctionPrice(_name) * _years;
        }
        // If not isAuction, use the registryPrice
        // We can use bytes(_name).length to get the length of the name in bytes because we only allow a-z and 0-9
        else {
            price = calculatePrice(bytes(_name).length, _years);
        }

        // Implement paying for the minting of the Collective Portrait
        require(msg.value >= price, "Not enough ETH sent");

        // Transfer the ETH to the treasury
        payable(treasury).transfer(msg.value);

        // Update the validUntil timestamp for the record to the current timestamp + _years
        records[_name].validUntil = block.timestamp + (_years * 365 days);

        // Create a new record for the name
        records[_name] = Record(
            "",
            _minimumControlShares,
            block.timestamp + (_years * 365 days)
        );

        // Update the name for the token ID
        namesByTokenId[portraitCount + 1] = _name;

        // Update the tokenBalancesByTokenId mapping
        tokenBalancesByTokenId[portraitCount + 1][msg.sender] = _shares;

        // Update the tokenHoldersByTokenId mapping
        tokenHoldersByTokenId[portraitCount + 1].push(msg.sender);

        // Increment the portraitCount by 1, so that the next token ID is unique
        portraitCount++;

        // Mint a Collective Portrait with an empty portraitHash
        _mint(msg.sender, portraitCount, _shares, "");
    }

    /*
    We override the _beforeTokenTransfer and _afterTokenTransfer function to verify, and keep track of the token balances.
    This is needed such that we can prevent a scenario in which no user has less than the minimumControlShares through the mapping tokenBalancesByTokenId.
    This means that at least one user has to have the minimumControlShares.
    The functions are used according to the ERC-1155 standard.
    */

    /*
    Override _beforeTokenTransfer to verify the token balances
    https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155-_beforeTokenTransfer-address-address-address-uint256---uint256---bytes-
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if (from != address(0)) {
                require(
                    tokenBalancesByTokenId[id][from] >= amount,
                    "Insufficient shares"
                );
                require(
                    tokenBalancesByTokenId[id][from] - amount >=
                        records[namesByTokenId[id]].minimumControlShares,
                    "Insufficient shares to reach minimumControlShares"
                );
            }
        }
    }

    /*
    Override _afterTokenTransfer to update the token balances
    https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155-_afterTokenTransfer-address-address-address-uint256---uint256---bytes-
    */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if (from != address(0)) {
                tokenBalancesByTokenId[id][from] -= amount;

                // Remove the address from the tokenHoldersByTokenId mapping if the balance is 0
                if (tokenBalancesByTokenId[id][from] == 0) {
                    for (
                        uint256 j = 0;
                        j < tokenHoldersByTokenId[id].length;
                        j++
                    ) {
                        if (tokenHoldersByTokenId[id][j] == from) {
                            tokenHoldersByTokenId[id][
                                j
                            ] = tokenHoldersByTokenId[id][
                                tokenHoldersByTokenId[id].length - 1
                            ];
                            tokenHoldersByTokenId[id].pop();
                            break;
                        }
                    }
                }
            }
            if (to != address(0)) {
                tokenBalancesByTokenId[id][to] += amount;

                // Add the address to the tokenHoldersByTokenId mapping if the address is not already in the mapping
                bool isAddressInMapping = false;
                for (uint256 j = 0; j < tokenHoldersByTokenId[id].length; j++) {
                    if (tokenHoldersByTokenId[id][j] == to) {
                        isAddressInMapping = true;
                        break;
                    }
                }

                if (!isAddressInMapping) {
                    tokenHoldersByTokenId[id].push(to);
                }
            }
        }
    }

    /*
    Update the minimumControlShares. This function can only be called by those who have the minimumControlShares.
    */
    function updateMinimumControlShares(
        string memory _name,
        uint256 _id,
        uint256 _minimumControlShares
    ) public {
        // Require validUntil to be in the future, use block.timestamp
        require(
            records[_name].validUntil > block.timestamp,
            "This Portrait does not exist or has expired"
        );

        // Require the user to have the minimumControlShares
        require(
            records[_name].minimumControlShares <= balanceOf(msg.sender, _id),
            "You do not have enough shares to update the minimumControlShares"
        );

        // Require minimumControlShares to be less or equal to the total shares
        require(
            _minimumControlShares <= totalSupply(_id),
            "minimumControlShares can not be more than the total shares"
        );

        // Require minimumControlShares to be at least 1
        require(
            _minimumControlShares >= 1,
            "minimumControlShares can not be less than 1"
        );

        // Require the _minimumControlShares not to be more than the current shares of the user
        require(
            _minimumControlShares <= balanceOf(msg.sender, _id),
            "minimumControlShares can not be more than the current shares of the user"
        );

        // Require the new minimumControlShares to be different from the current minimumControlShares
        require(
            _minimumControlShares != records[_name].minimumControlShares,
            "The minimumControlShares is the same as the current minimumControlShares"
        );

        records[_name].minimumControlShares = _minimumControlShares;
    }

    /*
    Function to do a n (multiplier) stock split for a token ID, only if the user has the minimumControlShares
    The minimumControlShares will be updated to the multiplier times the current minimumControlShares
    multiplier must be greater than 1
    We can use TransferBatch to mint the multiplier times shares minus the current shares
    We can use tokenBalancesByTokenId to fetch the shares, id, and address for a token */
    function stockSplit(uint256 _id, uint256 _multiplier) public {
        // Require the user to have the minimumControlShares
        require(
            records[namesByTokenId[_id]].minimumControlShares <=
                balanceOf(msg.sender, _id),
            "You do not have enough shares to do a stock split"
        );

        // Require the multiplier to be greater than 1
        require(_multiplier > 1, "The multiplier must be greater than 1");

        // Require the multiplier to be less than 100
        require(_multiplier < 100, "The multiplier must be less than 100");

        // Update the token balance for every address by going through the mapping of tokenHoldersByTokenId
        for (uint256 i = 0; i < tokenHoldersByTokenId[_id].length; i++) {
            tokenBalancesByTokenId[_id][tokenHoldersByTokenId[_id][i]] =
                _multiplier *
                tokenBalancesByTokenId[_id][tokenHoldersByTokenId[_id][i]];
        }

        // Update the minimumControlShares
        records[namesByTokenId[_id]].minimumControlShares =
            _multiplier *
            records[namesByTokenId[_id]].minimumControlShares;

        // Mint the multiplier times shares minus the current shares for every address by going through the mapping of tokenBalancesByTokenId
        for (uint256 i = 0; i < tokenHoldersByTokenId[_id].length; i++) {
            _mint(
                tokenHoldersByTokenId[_id][i],
                _id,
                _multiplier *
                    tokenBalancesByTokenId[_id][tokenHoldersByTokenId[_id][i]] -
                    tokenBalancesByTokenId[_id][tokenHoldersByTokenId[_id][i]],
                ""
            );
        }
    }

    /*
    Sets the portraitHash for a Collective Portrait if the user has the minimumControlShares.
    */
    function setPortraitHash(
        string memory _name,
        uint256 _id,
        string memory _portraitHash
    ) public {
        // Require validUntil to be in the future, use block.timestamp
        require(
            records[_name].validUntil > block.timestamp,
            "This Portrait does not exist or has expired"
        );

        // Require the user to have the minimumControlShares
        require(
            records[_name].minimumControlShares <= balanceOf(msg.sender, _id),
            "You do not have enough shares to set the portraitHash"
        );

        // Require the hash to be different from the current hash
        bytes32 _proposedHash = keccak256(abi.encodePacked(_portraitHash));
        bytes32 _currentHash = keccak256(
            abi.encodePacked(records[_name].portraitHash)
        );
        require(
            _proposedHash != _currentHash,
            "The portraitHash is the same as the current portraitHash"
        );

        // Set the portraitHash
        records[_name].portraitHash = _portraitHash;
    }

    /*
    This function returns the status of a Collective Portrait.
    If the status is 0, the Collective Portrait has expired, or does not exist.
    If the status is 1, the Collective Portrait is active.
    If the status is 2, the Collective Portrait is in the 90 day grace period to renew.
    */
    function getStatus(string[] memory _name)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory status = new uint256[](_name.length);

        for (uint256 i = 0; i < _name.length; i++) {
            if (records[_name[i]].validUntil > block.timestamp) {
                // If the validUntil is in the future, the Collective Portrait is active
                status[i] = 1;
            } else if (
                records[_name[i]].validUntil + 90 days > block.timestamp &&
                records[_name[i]].validUntil < block.timestamp
            ) {
                // If the validUntil is in the past, but less than 90 days ago, the Collective Portrait is in the grace period
                status[i] = 2;
            } else {
                // If the validUntil is more than 90 days ago, the Collective Portrait has expired
                status[i] = 0;
            }
        }

        return status;
    }

    /*
    A user can delegate the authority of updating the portraitHash for a Collective Portrait to another user, for a period of 50 blocks.
    We use the recover function to verify that the signature is from the owner of the Collective Portrait.
    */
    function setPortraitHashAsDelegate(
        string memory _name,
        uint256 _id,
        address _address,
        string memory _portraitHash,
        uint256 _blockHeight,
        bytes memory _signature
    ) public {
        // Require validUntil to be in the future, use block.timestamp
        require(
            records[_name].validUntil > block.timestamp,
            "This Portrait does not exist or has expired"
        );

        // Prefix is added according to EIP-191.
        bytes memory _messagePrefix = "\x19Ethereum Signed Message:\n32";

        // TO-DO: Test and remove if not needed
        // bytes32 _hashPrefix = keccak256(
        //     abi.encodePacked(_portraitHash, _blockHeight)
        // );

        // Prefix to explain what the message is about.
        bytes32 _proofPrefix = keccak256(
            abi.encodePacked(
                "Updating Portrait for ",
                _name,
                " with hash ",
                _portraitHash,
                " and block height ",
                _blockHeight
            )
        );

        // We concatenate the prefix and the hash.
        bytes32 _message = keccak256(
            abi.encodePacked(_messagePrefix, _proofPrefix)
        );

        // We use the recover function to verify the ownership of an Ethereum address.
        require(
            _address == recover(_message, _signature),
            "Signature does not match address"
        );

        // Require the block height to be within the epoch.
        require(_blockHeight <= block.number, "Block height is in the future");
        require(
            _blockHeight >= block.number - 50,
            "Block height is too far in the past"
        );

        // Require the user to have the minimumControlShares
        require(
            records[_name].minimumControlShares <= balanceOf(msg.sender, _id),
            "You do not have enough shares to set the portraitHash"
        );

        // Require the proposed hash to be different from the current hash
        bytes32 _proposedHash = keccak256(abi.encodePacked(_portraitHash));
        bytes32 _currentHash = keccak256(
            abi.encodePacked(records[_name].portraitHash)
        );
        require(
            _proposedHash != _currentHash,
            "The portraitHash is the same as the current portraitHash"
        );
        // Set the portraitHash
        records[_name].portraitHash = _portraitHash;
    }

    string baseUri = "https://collective-portrait-metadata.herokuapp.com/";

    /* Returns the URI for a given token ID */
    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, _id));
    }

    /*
    Function to update baseUri as the owner of the contract.
    */
    function updateBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /* Helper function for alphaNumeric check */
    function isAlphaNumeric(string memory _name) internal pure returns (bool) {
        bytes memory nameBytes = bytes(_name);
        for (uint256 i = 0; i < nameBytes.length; i++) {
            if (
                !(nameBytes[i] >= 0x30 && nameBytes[i] <= 0x39) &&
                !(nameBytes[i] >= 0x61 && nameBytes[i] <= 0x7a)
            ) {
                return false;
            }
        }
        return true;
    }

    /* Helper function for address check */
    function isAddress(string memory _name) internal pure returns (bool) {
        if (bytes(_name).length != 42) return false;
        if (bytes(_name)[0] != 0x30) return false;
        if (bytes(_name)[1] != 0x78) return false;
        bytes memory s = bytes(_name);
        for (uint256 i = 0; i < 40; i++) {
            bytes1 c = s[i + 2];
            if (
                !(c >= 0x30 && c <= 0x39) &&
                !(c >= 0x41 && c <= 0x46) &&
                !(c >= 0x61 && c <= 0x66)
            ) {
                return false;
            }
        }
        return true;
    }

    /*
    Helper function: the recover function is used to obtain the address from a signature.
    */
    function recover(bytes32 _message, bytes memory _signature)
        private
        pure
        returns (address)
    {
        bytes32 _r;
        bytes32 _s;
        uint8 _v;
        if (_signature.length != 65) {
            return (address(0));
        }
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := byte(0, mload(add(_signature, 96)))
        }
        if (_v < 27) {
            _v += 27;
        }
        if (_v != 27 && _v != 28) {
            return (address(0));
        } else {
            return ecrecover(_message, _v, _r, _s);
        }
    }

    // State variables for length of name and price
    uint256 public threeCharPrice = 640;
    uint256 public fourCharPrice = 160;
    uint256 public fiveCharOrMorePrice = 5;

    // Function to set the price of the state variables as the owner of the contract
    function setPrices(
        uint256 _threeCharPrice,
        uint256 _fourCharPrice,
        uint256 _fiveCharOrMorePrice
    ) public onlyOwner {
        threeCharPrice = _threeCharPrice;
        fourCharPrice = _fourCharPrice;
        fiveCharOrMorePrice = _fiveCharOrMorePrice;
    }

    /* Helper function to determine, for a given length of a string, what the price is in ETH
     */
    function calculatePrice(uint256 _length, uint256 _years)
        public
        view
        returns (uint256)
    {
        require(_years > 0, "You must pay for at least one year");
        require(
            _length > 2,
            "You must enter a name that is at least 3 characters long"
        );
        if (_length == 3) {
            return usdToWei(threeCharPrice) * _years;
        }
        if (_length == 4) {
            return usdToWei(fourCharPrice) * _years;
        }
        // if (_length >= 5)
        return usdToWei(fiveCharOrMorePrice) * _years;
    }

    /* Function to renew a Collective Portrait
    Anyone can pay for a Collective Portrait's renewal. Even non-shareholders.
    */
    function renewPortrait(string memory _name, uint256 _years) public payable {
        // Require the user to pay the correct amount of ETH
        require(
            msg.value == calculatePrice(bytes(_name).length, _years),
            "Insufficient ETH sent"
        );

        // Should exist, check with minimumControlShares >= 1
        require(
            records[_name].minimumControlShares >= 1,
            "This Collective Portrait does not exist"
        );

        // Set the new validUntil
        records[_name].validUntil = block.timestamp + _years * 365 days;
    }

    /* 
    The auction will be a Dutch auction, where the price starts at 1000000 * yearly renewal fee, and decreases by 1% every 30 minutes.
    If the auction price is lower than the yearly renewal fee, the name will be released.
    */
    function getAuctionPrice(string memory _name)
        public
        view
        returns (uint256)
    {
        // Require validUntil to be in the past + grace period, use block.timestamp
        require(
            records[_name].validUntil + 90 days < block.timestamp,
            "This Portrait is not in the auction period"
        );

        // validUntil + 90 days is when the auction starts
        uint256 _auctionStart = records[_name].validUntil + 90 days;

        // Get the time since the auction started
        uint256 _timeSinceAuctionStart = block.timestamp - _auctionStart;

        // 1000000*yearly renewal fee
        uint256 _startingPrice = calculatePrice(bytes(_name).length, 1) *
            1000000;

        // Get the auction price
        uint256 _auctionPrice = _startingPrice;
        while (_timeSinceAuctionStart >= 30 minutes) {
            _auctionPrice = _auctionPrice - (_auctionPrice / 100);
            _timeSinceAuctionStart = _timeSinceAuctionStart - 30 minutes;
        }

        return _auctionPrice;
    }

    /* Function to see if a name is still in the auction period
    This can be done by checking if validUntil + 90 days is in the past
    and if the auction price is higher than the yearly renewal fee */
    function isAuction(string memory _name) public view returns (bool) {
        // Require validUntil to be in the past + 90 days grace period, use block.timestamp
        require(
            records[_name].validUntil + 90 days < block.timestamp,
            "This Portrait is not in the auction period"
        );

        // Get the auction price
        uint256 _auctionPrice = getAuctionPrice(_name);

        // Get the yearly renewal fee
        uint256 _yearlyRenewalFee = calculatePrice(bytes(_name).length, 1);

        // Check if the auction price is higher than the yearly renewal fee
        if (_auctionPrice > _yearlyRenewalFee) {
            return true;
        } else {
            return false;
        }
    }
}