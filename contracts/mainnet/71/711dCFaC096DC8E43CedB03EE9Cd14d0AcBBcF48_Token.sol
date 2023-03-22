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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

// import "hardhat/console.sol";

struct Owner {
    address owner;
    bool burned;
    uint256 amount;
}

abstract contract ERC1155Hybrid is
    Context,
    ERC165,
    IERC1155,
    IERC1155MetadataURI
{
    string internal _name;
    string internal _symbol;
    string internal _uri;
    string internal _contractURI;

    mapping(address => mapping(address => bool)) _operatorApprovals;
    mapping(uint256 => mapping(address => uint256)) _fungibleBalances;
    mapping(uint16 => mapping(uint256 => Owner)) _nftOwnership;
    mapping(uint16 => uint256) _nftMintCounter;
    mapping(uint16 => mapping(address => uint256)) _nftBalances;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) {
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;
        _uri = uri_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _setMetadata(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) internal {
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;
        _uri = uri_;
    }

    function ownerOf(uint256 id) public view returns (address) {
        require(!_isFungible(id), "Token ID is fungible");

        (uint16 tier, uint256 unpacked) = _unpackID(id);
        (, uint256 idx, ) = _findNearestOwnershipRecord(tier, unpacked);

        return _nftOwnership[tier][idx].owner;
    }

    function balanceOfTier(
        address account,
        uint16 tier
    ) public view returns (uint256) {
        return _nftBalances[tier][account];
    }

    function balanceOf(
        address account,
        uint256 id
    ) public view returns (uint256) {
        if (_isFungible(id)) {
            return _balanceOfFungible(account, id);
        }

        if (ownerOf(id) == account) {
            return 1;
        }

        return 0;
    }

    function _balanceOfFungible(
        address account,
        uint256 id
    ) private view returns (uint256) {
        return _fungibleBalances[id][account];
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] calldata) {
        require(accounts.length == ids.length, "Array mismatch");

        uint256[] memory res = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            res[i] = balanceOf(accounts[i], ids[i]);
        }

        return ids;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external virtual {
        _safeTransferFrom(from, to, id, amount, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        if (_isFungible(id)) {
            return _safeTransferFromFungible(from, to, id, amount, data);
        }

        return _safeTransferFromNFT(from, to, id, amount, data);
    }

    function _safeTransferFromFungible(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        require(
            from == operator || _operatorApprovals[from][operator],
            "ERC1155: not approved"
        );

        uint256 fromBalance = _fungibleBalances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _fungibleBalances[id][from] = fromBalance - amount;
        }
        _fungibleBalances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeTransferFromNFT(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        address operator = _msgSender();

        require(to != address(0), "ERC1155: transfer to the zero address");
        require(amount == 1, "ERC1155: transfer of NFT must have amount of 1");

        (uint16 tier, uint256 unpacked) = _unpackID(id);

        (
            address origOwner,
            uint256 origStart,
            uint256 origAmount
        ) = _findNearestOwnershipRecord(tier, unpacked);

        require(origOwner == from, "ERC1155: not the owner of this token");
        require(
            from == operator || _operatorApprovals[from][operator],
            "ERC1155: not approved"
        );

        uint256 rightAmount = origStart + origAmount - unpacked - 1;
        uint256 leftAmount = unpacked - origStart;

        // console.log("ownership array length", _nftOwnership[tier].length);
        // console.log("left", left.start, left.amount);
        // console.log("middle", middle.start, middle.amount);
        // console.log("right", right.start, right.amount);

        if (leftAmount > 0) {
            _nftOwnership[tier][origStart].amount = leftAmount;
        }

        _nftOwnership[tier][unpacked] = Owner({
            owner: to,
            burned: false,
            amount: 1
        });

        if (rightAmount > 0) {
            _nftOwnership[tier][unpacked + 1] = Owner({
                owner: from,
                burned: false,
                amount: rightAmount
            });
        }

        _nftBalances[tier][from] -= 1;
        _nftBalances[tier][to] += 1;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(ids.length == amounts.length, "Array mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            _safeTransferFrom(from, to, ids[i], amounts[i], data);
        }
    }

    function _findNearestOwnershipRecord(
        uint16 tier,
        uint256 unpacked
    ) private view returns (address, uint256, uint256) {
        // console.log(tier, unpacked);

        if (unpacked > _nftMintCounter[tier]) {
            revert("Token not minted");
        }

        for (uint256 i = unpacked; i >= 0; i--) {
            if (
                _nftOwnership[tier][i].owner != address(0) ||
                _nftOwnership[tier][i].burned
            ) {
                return (
                    _nftOwnership[tier][i].owner,
                    i,
                    _nftOwnership[tier][i].amount
                );
            }
        }

        revert("Ownership could not be determined");
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function uri(uint256) external view returns (string memory) {
        return _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _tierOf(uint256 id) internal view virtual returns (uint16);

    function _isFungible(uint256 id) internal view virtual returns (bool);

    function _isFungibleTier(uint16 tier) internal view virtual returns (bool);

    function _supplyLimit(uint256 id) internal view virtual returns (uint256);

    function _tierBounds(
        uint16 tier
    ) internal view virtual returns (uint256, uint256);

    function _getNextID(uint16 tier) internal view virtual returns (uint256);

    function _incrementNextID(
        uint16 tier,
        uint256 amount
    ) internal virtual returns (uint256);

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
    function _mintFungible(address to, uint256 id, uint256 amount) internal {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _fungibleBalances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            "0x"
        );
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
    function _burnFungible(address from, uint256 id, uint256 amount) internal {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        uint256 fromBalance = _fungibleBalances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _fungibleBalances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _mintNFT(address to, uint16 tier, uint256 amount) internal {
        require(to != address(0), "ERC1155: mint to the zero address");

        uint256 start = _incrementNextID(tier, amount);
        address from = address(0);

        _nftOwnership[tier][start] = Owner({
            owner: to,
            burned: false,
            amount: amount
        });
        _nftBalances[tier][to] += amount;
        _nftMintCounter[tier] = start + amount - 1;

        emit TransferBatch(
            _msgSender(),
            from,
            to,
            _rangeWithTier(start, amount, tier),
            _repeat(1, amount)
        );
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (_isContract(to)) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
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
        if (_isContract(to)) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _repeat(
        uint256 value,
        uint256 length
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = value;
        }

        return array;
    }

    function _range(
        uint256 start,
        uint256 length
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = start + i;
        }

        return array;
    }

    function _rangeWithTier(
        uint256 start,
        uint256 length,
        uint16 tier
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = _packID(tier, start + i);
        }

        return array;
    }

    function _isContract(address account) private view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function _unpackID(uint256 id) internal pure returns (uint16, uint256) {
        uint16 tier = uint16(id & (2 ** 16 - 1));
        return (tier, id >> 16);
    }

    function _packID(uint16 tier, uint256 id) internal pure returns (uint256) {
        require(id < 2 ** 240, "ID too big");
        return (id << 16) + tier;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC1155Hybrid.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

struct TokenConfig {
    bool added;
    bool canMint;
    bool canBurn;
    uint256 supplyLimit;
}

contract Token is ERC1155Hybrid, Pausable, Ownable {
    uint8 public constant ROLE_MINT_FT = 1 << 0;
    uint8 public constant ROLE_MINT_NFT = 1 << 1;
    uint8 public constant ROLE_BATCH_MINT_NFT = 1 << 2;
    uint8 public constant ROLE_BURN_FT = 1 << 3;

    uint256 public constant FUNGIBLE_TOKEN_UPPER_BOUND = 2 ** 16;

    uint256 _tokenUpperBound = 0;
    mapping(uint16 => uint256) _tierStarts;
    uint256[] _tiers;
    mapping(uint16 => uint256) private _nextID;

    mapping(address => uint8) _roles;

    error NotAuthorized(uint8 req, address sender);

    event TierAdded(string name, uint16 id, uint256 size);

    mapping(uint256 => uint256) private _minted;
    mapping(uint256 => TokenConfig) private _added;

    modifier requireRole(uint8 req) {
        if (!hasRole(_msgSender(), req)) {
            revert NotAuthorized(req, _msgSender());
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) ERC1155Hybrid(name_, symbol_, contractURI_, uri_) {
        // Add fungible tier on deployment.
        addTier("Fungible Tokens", FUNGIBLE_TOKEN_UPPER_BOUND);
    }

    function setMetadata(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) public onlyOwner {
        _setMetadata(name_, symbol_, contractURI_, uri_);
    }

    function setPaused(bool b) public onlyOwner {
        if (b) {
            require(b && !paused(), "Contract is already paused");
            _pause();
            return;
        }

        require(!b && paused(), "Contract is not paused");
        _unpause();
    }

    function setRole(address operator, uint8 mask) public onlyOwner {
        _roles[operator] = mask;
    }

    function hasRole(address operator, uint8 role) public view returns (bool) {
        return _roles[operator] & role == role;
    }

    function addTier(
        string memory name,
        uint256 size
    ) public onlyOwner returns (uint16) {
        uint newTier = _tiers.length;

        require(newTier < 2 ** 16, "Tier is too high.");
        require(
            _tokenUpperBound + size < 2 ** 240,
            "Token upper bound is too high."
        );

        _tiers.push(size);
        _tierStarts[uint16(newTier)] = _tokenUpperBound;
        _tokenUpperBound += size;

        emit TierAdded(name, uint16(newTier), size);

        return uint16(newTier);
    }

    function _tierOf(uint256 id) internal pure override returns (uint16) {
        (uint16 tier, ) = _unpackID(id);
        return tier;
    }

    function _tierBounds(
        uint16 tier
    ) internal view override returns (uint256, uint256) {
        require(tier < _tiers.length, "Tier not configured.");
        return (_tierStarts[tier], _tierStarts[tier] + _tiers[tier]);
    }

    function _getNextID(uint16 tier) internal view override returns (uint256) {
        require(tier < _tiers.length, "Tier not configured.");
        return _nextID[tier];
    }

    function _incrementNextID(
        uint16 tier,
        uint256 amount
    ) internal override returns (uint256) {
        (, uint256 end) = _tierBounds(tier);

        require(
            _nextID[tier] + amount < end,
            "Requested IDs exceed bounds of tier"
        );

        uint256 start = _nextID[tier];
        _nextID[tier] += amount;
        return start;
    }

    function _isFungible(uint256 id) internal pure override returns (bool) {
        return _isFungibleTier(_tierOf(id));
    }

    function _isFungibleTier(
        uint16 tier
    ) internal pure override returns (bool) {
        return tier == 0;
    }

    function _supplyLimit(uint256 id) internal view override returns (uint256) {
        if (!_isFungible(id)) {
            return 1;
        }

        return _added[id].supplyLimit;
    }

    function totalMinted(uint256 id) public view returns (uint256) {
        if (!_isFungible(id)) {
            if (ownerOf(id) != address(0)) {
                return 1;
            } else {
                return 0;
            }
        }

        return _minted[id];
    }

    function supplyLimit(uint256 id) public view returns (uint256) {
        return _supplyLimit(id);
    }

    function addFT(
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public onlyOwner returns (uint256) {
        uint256 packed = _packID(0, _incrementNextID(0, 1));
        _added[packed] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);
        return packed;
    }

    function modifyFT(
        uint256 id,
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public onlyOwner {
        _added[id] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);
    }

    function mintFT(
        address to,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_MINT_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canMint, "Token cannot be minted.");
        require(
            supplyLimit(tokenID) == 0 ||
                (totalMinted(tokenID) + quantity <= supplyLimit(tokenID)),
            "Mint would exceed supply limit."
        );

        _minted[tokenID] += quantity;
        _mintFungible(to, tokenID, quantity);
    }

    function adminMintFT(
        address to,
        uint256 tokenID,
        uint256 quantity
    ) public onlyOwner {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(
            supplyLimit(tokenID) == 0 ||
                (totalMinted(tokenID) + quantity <= supplyLimit(tokenID)),
            "Mint would exceed supply limit."
        );

        _minted[tokenID] += quantity;
        _mintFungible(to, tokenID, quantity);
    }

    function mintNFT(
        address to,
        uint16 tier,
        uint256 quantity
    ) public requireRole(ROLE_MINT_NFT) {
        require(!_isFungibleTier(tier), "Tier is fungible.");
        _mintNFT(to, tier, quantity);
    }

    function adminMintNFT(
        address to,
        uint16 tier,
        uint256 quantity
    ) public onlyOwner {
        require(!_isFungibleTier(tier), "Tier is fungible.");
        _mintNFT(to, tier, quantity);
    }

    function batchMintNFT(
        address to,
        uint16[] calldata tiers,
        uint256[] calldata quantities
    ) public requireRole(ROLE_BATCH_MINT_NFT) {
        require(tiers.length == quantities.length, "Array mismatch");

        for (uint256 i = 0; i < tiers.length; i++) {
            mintNFT(to, tiers[i], quantities[i]);
        }
    }

    function burnFT(
        address owner,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_BURN_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canBurn, "Token cannot be burned.");

        _burnFungible(owner, tokenID, quantity);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155Hybrid) {
        if (paused()) revert("Token is paused");

        return _safeTransferFrom(from, to, id, amount, data);
    }

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function updateMetadata(uint256 id) public onlyOwner {
        emit MetadataUpdate(id);
    }

    function updateAllMetadata() public onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function packID(uint16 tier, uint256 id) external pure returns (uint256) {
        return _packID(tier, id);
    }

    function unpackID(uint256 id) external pure returns (uint16, uint256) {
        return _unpackID(id);
    }
}