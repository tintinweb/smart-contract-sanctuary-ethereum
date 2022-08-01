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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers whenNotPaused and whenPaused, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by account.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by account.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
 * onlyOwner, which can be applied to your functions to restrict their use to
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
     * onlyOwner functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (newOwner).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if account is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, isContract will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's transfer: sends amount wei to
     * recipient, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by transfer, making them unable to receive funds via
     * transfer. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to recipient, care must be
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
     * @dev Performs a Solidity function call using a low level call. A
     * plain call is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If target reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[abi.decode].
     *
     * Requirements:
     *
     * - target must be a contract.
     * - calling target with data must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall], but with
     * errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but also transferring value wei to target.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least value.
     * - the called Solidity function must be payable.
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
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[functionCallWithValue], but
     * with errorMessage as a fallback revert reason when target reverts.
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[functionCall],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[functionCall],
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
     * interfaceId. See the corresponding
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
 * solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * 
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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a safeTransferFrom after the balance has been updated.
        To accept the transfer, this must return
        bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a safeBatchTransferFrom after the balances have
        been updated. To accept the transfer(s), this must return
        bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")) if transfer is allowed
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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when value tokens of token type id are transferred from from to to by operator.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where operator, from and to are the same for all
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
     * @dev Emitted when account grants or revokes permission to operator to transfer their tokens, according to
     * approved.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type id changes to value, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for id, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that value will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type id owned by account.
     *
     * Requirements:
     *
     * - account cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - accounts and ids must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to operator to transfer the caller's tokens, according to approved,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - operator cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if operator is approved to transfer account's tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers amount tokens of token type id from from to to.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - to cannot be the zero address.
     * - If the caller is not from, it must be have been approved to spend from's tokens via {setApprovalForAll}.
     * - from must have a balance of tokens of type id of at least amount.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
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
     * - ids and amounts must have the same length.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
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
     * @dev Returns the URI for token type id.
     *
     * If the {id} substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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
    
    // Mapping for token ID that are not able to traded
    // For reasons mapping to uint8 instead of boolean
    // so 1 = false and 255 = true
    mapping (uint256 => uint8) tokenTradingStatus;

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
     * Clients calling this function must replace the {id} substring with the
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
     * - account cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - accounts and ids must have the same length.
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
        require(tokenTradingStatus[id] == 255, "Token is not tradeable!");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
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
        for (uint256 i = 0; i < ids.length; ++i) {
            require(tokenTradingStatus[ids[i]] == 255, "Token is not tradeable!");
        }

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers amount tokens of token type id from from to to.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - to cannot be the zero address.
     * - from must have a balance of tokens of type id of at least amount.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
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

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the {id} substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the https://token-cdn-domain/{id}.json URI would be
     * interpreted by clients as
     * https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json
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
     * @dev Creates amount tokens of token type id, and assigns them to to.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - to cannot be the zero address.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - ids and amounts must have the same length.
     * - If to refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys amount tokens of token type id from from
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - from must have at least amount tokens of token type id.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - ids and amounts must have the same length.
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
    }

    /**
     * @dev Approve operator to operate on all of owner tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * transfers, the length of the id and amount arrays will be 1.
     *
     * Calling conditions (for each id and amount pair):
     *
     * - When from and to are both non-zero, amount of from's tokens
     * of token type id will be  transferred to to.
     * - When from is zero, amount tokens of token type id will be minted
     * for to.
     * - when to is zero, amount of from's tokens of token type id
     * will be burned.
     * - from and to are never both zero.
     * - ids and amounts have the same, non-zero length.
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155, Ownable {
    mapping (uint256 => uint256) private _totalSupply;
    mapping (uint256 => uint256) private tokenSupplyCap;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 _id) public view virtual returns (uint256) {
        return _totalSupply[_id];
    }

    function getTokenSupplyCap(uint256 _id) public view virtual returns (uint256) {
        require(exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return tokenSupplyCap[_id];
    }

    function setTokenSupplyCap(uint256 _id, uint256 _newSupplyCap) public onlyOwner {
        require(exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        require(_newSupplyCap > tokenSupplyCap[_id], "New Supply Cap can only be greater than previous supply cap.");
        tokenSupplyCap[_id] = _newSupplyCap;
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
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}
//-------------END DEPENDENCIES------------------------//


// File: isFeeable.sol
abstract contract isPriceable is Ownable {
    mapping (uint256 => uint256) tokenPrice;

    function getPriceForToken(uint256 _id) public view returns(uint256) {
        return tokenPrice[_id];
    }

    function setPriceForToken(uint256 _id, uint256 _feeInWei) public onlyOwner {
        tokenPrice[_id] = _feeInWei;
    }
}


  
// File: hasTransactionCap.sol
abstract contract hasTransactionCap is Ownable {
    mapping (uint256 => uint256) transactionCap;

    function getTransactionCapForToken(uint256 _id) public view returns(uint256) {
        return transactionCap[_id];
    }

    function setTransactionCapForToken(uint256 _id, uint256 _transactionCap) public onlyOwner {
        require(_transactionCap > 0, "Quantity must be more than zero");
        transactionCap[_id] = _transactionCap;
    }

    function canMintQtyForTransaction(uint256 _id, uint256 _qty) internal view returns(bool) {
        return _qty <= transactionCap[_id];
    }
}


  
// File: hasWalletCap.sol
abstract contract hasWalletCap is Ownable {
    mapping (uint256 => bool) private walletCapEnabled;
    mapping (uint256 => uint256) private walletMaxes;
    mapping (address => mapping(uint256 => uint256)) private walletMints;

    /**
    * @dev establish the inital settings of the wallet cap upon creation
    * @param _id token id
    * @param _initWalletCapStatus initial state of wallet cap
    * @param _initWalletMax initial state of wallet cap limit
    */
    function setWalletCap(uint256 _id, bool _initWalletCapStatus, uint256 _initWalletMax) internal {
      walletCapEnabled[_id] = _initWalletCapStatus;
      walletMaxes[_id] = _initWalletMax;
    }

    function enableWalletCap(uint256 _id) public onlyOwner {
      walletCapEnabled[_id] = true;
    }

    function disableWalletCap(uint256 _id) public onlyOwner {
      walletCapEnabled[_id] = false;
    }

    function addTokenMints(uint256 _id, address _address, uint256 _amount) internal {
      walletMints[_address][_id] = (walletMints[_address][_id] +  _amount);
    }

    /**
    * @dev Allow contract owner to reset the amount of tokens claimed to be minted per address
    * @param _id token id
    * @param _address address to reset counter of
    */
    function resetMints(uint256 _id, address _address) public onlyOwner {
      walletMints[_address][_id] = 0;
    }

    /**
    * @dev update the wallet max per wallet per token
    * @param _id token id
    * @param _newMax the new wallet max per wallet
    */
    function setTokenWalletMax(uint256 _id, uint256 _newMax) public onlyOwner {
      require(_newMax >= 1, "Token wallet max must be greater than or equal to one.");
      walletMaxes[_id] = _newMax;
    }

    /**
    * @dev Check if wallet over maximum mint
    * @param _id token id to query against
    * @param _address address in question to check if minted count exceeds max
    */
    function canMintAmount(uint256 _id, address _address, uint256 _amount) public view returns(bool) {
        if(isWalletCapEnabled(_id) == false) {
          return true;
        }
  
        require(_amount >= 1, "Amount must be greater than or equal to 1");
        return (currentMintCount(_id, _address) + _amount) <= tokenWalletCap(_id);
    }

    /**
    * @dev Get current wallet cap for token
    * @param _id token id to query against
    */
    function tokenWalletCap(uint256 _id) public view returns(uint256) {
      return walletMaxes[_id];
    }

    /**
    * @dev Check if token is enforcing wallet caps
    * @param _id token id to query against
    */
    function isWalletCapEnabled(uint256 _id) public view returns(bool) {
      return walletCapEnabled[_id] == true;
    }

    /**
    * @dev Check current mint count for token and address
    * @param _id token id to query against
    * @param _address address to check mint count of
    */
    function currentMintCount(uint256 _id, address _address) public view returns(uint256) {
      return walletMints[_address][_id];
    }
}


  
// File: Closeable.sol
abstract contract Closeable is Ownable {
    mapping (uint256 => bool) mintingOpen;

    function openMinting(uint256 _id) public onlyOwner {
        mintingOpen[_id] = true;
    }

    function closeMinting(uint256 _id) public onlyOwner {
        mintingOpen[_id] = false;
    }

    function isMintingOpen(uint256 _id) public view returns(bool) {
        return mintingOpen[_id] == true;
    }

    function setInitialMintingStatus(uint256 _id, bool _initStatus) internal {
        mintingOpen[_id] = _initStatus;
    }
}
  

  
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


contract Seven22HDNFIGRZ is 
    ERC1155,
    Ownable, 
    Pausable, 
    ERC1155Supply, 
    Closeable,
    isPriceable,
    hasTransactionCap,
    hasWalletCap{

    constructor() ERC1155('') {}

    uint8 public CONTRACT_VERSION = 1;
    bytes private emptyBytes;
    uint256 public currentTokenID = 0;
    string public name = "Seven22";
    string public symbol = "HDN-FIGRZ";

    mapping (uint256 => string) baseTokenURI;

    /**
    * @dev returns the URI for a specific token to show metadata on marketplaces
    * @param _id the maximum supply of tokens for this token
    */
    function uri(uint256 _id) public override view returns (string memory) {
        require(exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return baseTokenURI[_id];
    }

    
  /////////////// Admin Mint Functions
  function mintToAdmin(address _address, uint256 _id, uint256 _qty) public onlyOwner {
      require(exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
      require(_qty > 0, "Minting quantity must be over 0");
      require((totalSupply(_id)+ _qty) <= getTokenSupplyCap(_id), "Cannot mint over supply cap of token!");
      
      _mint(_address, _id, _qty, emptyBytes);
  }

  function mintManyAdmin(address[] memory addresses, uint256 _id, uint256 _qtyToEach) public onlyOwner {
      for(uint256 i=0; i < addresses.length; i++) {
          _mint(addresses[i], _id, _qtyToEach, emptyBytes);
      }
  }

    
    function createToken(
            uint256 _tokenSupplyCap, 
            uint256 _tokenTransactionCap,
            uint256 _tokenFeeInWei, 
            bool _isOpenDefaultStatus,
            bool _allowTradingDefaultStatus,
            bool _enableWalletCap,
            uint256 _walletCap,
            string memory _tokenURI
        ) public onlyOwner {
        require(_tokenSupplyCap > 0, "Token Supply Cap must be greater than zero.");
        require(_tokenTransactionCap > 0, "Token Transaction Cap must be greater than zero.");
        require(bytes(_tokenURI).length > 0, "Token URI cannot be an empty value");

        uint256 tokenId = _getNextTokenID();

        _mint(msg.sender, tokenId, 1, emptyBytes);
        baseTokenURI[tokenId] = _tokenURI;

        setTokenSupplyCap(tokenId, _tokenSupplyCap);
        setPriceForToken(tokenId, _tokenFeeInWei);
        setTransactionCapForToken(tokenId, _tokenTransactionCap);
        setInitialMintingStatus(tokenId, _isOpenDefaultStatus);
        setWalletCap(tokenId, _enableWalletCap, _walletCap);
        tokenTradingStatus[tokenId] = _allowTradingDefaultStatus ? 255 : 1;

        _incrementTokenTypeId();
    }

    /**
    * @dev pauses minting for all tokens in the contract
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * @dev unpauses minting for all tokens in the contract
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * @dev set the URI for a specific token on the contract
    * @param _id token id
    * @param _newTokenURI string for new metadata url (ex: ipfs://something)
    */
    function setTokenURI(uint256 _id, string memory _newTokenURI) public onlyOwner {
        require(exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        baseTokenURI[_id] = _newTokenURI;
    }

    /**
    * @dev calculates price for a token based on qty
    * @param _id token id
    * @param _qty desired amount to mint
    */
    function getPrice(uint256 _id, uint256 _qty) public view returns (uint256) {
        require(_qty > 0, "Quantity must be more than zero");
        return getPriceForToken(_id) * _qty;
    }

    /**
    * @dev prevent token from being transferred (aka soulbound)
    * @param tokenId token id
    */
    function setTokenUntradeable(uint256 tokenId) public onlyOwner {
        require(tokenTradingStatus[tokenId] != 1, "Token ID is already untradeable!");
        require(exists(tokenId), "Token ID does not exist!");
        tokenTradingStatus[tokenId] = 1;
    }

    /**
    * @dev allow token from being transferred - the default mode
    * @param tokenId token id
    */
    function setTokenTradeable(uint256 tokenId) public onlyOwner {
        require(tokenTradingStatus[tokenId] != 255, "Token ID is already tradeable!");
        require(exists(tokenId), "Token ID does not exist!");
        tokenTradingStatus[tokenId] = 255;
    }

    /**
    * @dev check if token id is tradeable
    * @param tokenId token id
    */
    function isTokenTradeable(uint256 tokenId) public view returns (bool) {
        require(exists(tokenId), "Token ID does not exist!");
        return tokenTradingStatus[tokenId] == 255;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _getNextTokenID() public view returns (uint256) {
        return currentTokenID + 1;
    }

    /**
    * @dev increments the value of currentTokenID
    */
    function _incrementTokenTypeId() public  {
        currentTokenID++;
    }
}