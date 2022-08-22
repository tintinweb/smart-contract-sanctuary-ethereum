// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";




/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev minimal ERC2771 handler to keep bytecode-size down
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/metatx/ERC2771Context.sol
/// with an initializer for proxies and a mutable forwarder

contract ERC2771Handler {
    address internal _trustedForwarder;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
/* solhint-disable func-order, code-complexity */
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./WithSuperOperatorsV2.sol";
import "../interfaces/IERC721MandatoryTokenReceiver.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract ERC721BaseTokenV2 is ContextUpgradeable, IERC721Upgradeable, WithSuperOperatorsV2 {
    using AddressUpgradeable for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_BATCH_RECEIVED = 0x4b808c46;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC721_MANDATORY_RECEIVER = 0x5e8bf644;

    uint256 internal constant NOT_ADDRESS = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000;
    uint256 internal constant OPERATOR_FLAG = (2**255);
    uint256 internal constant NOT_OPERATOR_FLAG = OPERATOR_FLAG - 1;
    uint256 internal constant BURNED_FLAG = (2**160);

    mapping(address => uint256) internal _numNFTPerAddress;
    mapping(uint256 => uint256) internal _owners;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;

    /// @notice Approve an operator to spend tokens on the senders behalf.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approve(address operator, uint256 id) external override {
        uint256 ownerData = _owners[_storageId(id)];
        address owner = _ownerOf(id);
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(
            owner == msgSender || _operatorsForAll[owner][msgSender] || _superOperators[msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        _approveFor(ownerData, operator, id);
    }

    /// @notice Approve an operator to spend tokens on the sender behalf.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external {
        uint256 ownerData = _owners[_storageId(id)];
        address owner = _ownerOf(id);
        address msgSender = _msgSender();
        require(sender != address(0), "ZERO_ADDRESS_SENDER");
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(
            msgSender == sender || _operatorsForAll[sender][msgSender] || _superOperators[msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        require(address(uint160(ownerData)) == sender, "OWNER_NOT_SENDER");
        _approveFor(ownerData, operator, id);
    }

    /// @notice Transfer a token between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, ""), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Transfer a token between 2 addresses letting the receiver know of the transfer.
    /// @param from The send of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Transfer many tokens between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) public virtual {
        _batchTransferFrom(from, to, ids, data, false);
    }

    /// @notice Transfer many tokens between 2 addresses, while
    /// ensuring the receiving contract has a receiver method.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, true);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender != address(0), "Invalid sender address");
        address msgSender = _msgSender();
        require(msgSender == sender || _superOperators[msgSender], "UNAUTHORIZED_APPROVE_FOR_ALL");

        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Burns token `id`.
    /// @param id The token which will be burnt.
    function burn(uint256 id) external virtual {
        _burn(_msgSender(), _ownerOf(id), id);
    }

    /// @notice Burn token`id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id The token which will be burnt.
    function burnFrom(address from, uint256 id) external virtual {
        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(
            msgSender == from ||
                (operatorEnabled && _operators[id] == msgSender) ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender],
            "UNAUTHORIZED_BURN"
        );
        _burn(from, owner, id);
    }

    /// @notice Get the number of tokens owned by an address.
    /// @param owner The address to look for.
    /// @return The number of tokens owned by the address.
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS_OWNER");
        return _numNFTPerAddress[owner];
    }

    /// @notice Get the owner of a token.
    /// @param id The id of the token.
    /// @return owner The address of the token owner.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NONEXISTANT_TOKEN");
    }

    /// @notice Get the approved operator for a specific token.
    /// @param id The id of the token.
    /// @return The address of the operator.
    function getApproved(uint256 id) external view override returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    /// @notice Check if the sender approved the operator.
    /// @param owner The address of the owner.
    /// @param operator The address of the operator.
    /// @return isOperator The status of the approval.
    function isApprovedForAll(address owner, address operator) external view override returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice Transfer a token between 2 addresses letting the receiver knows of the transfer.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    /// @param data Additional data.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, data), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC-165.
    /// 0x80ac58cd is ERC-721
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    /// @dev By overriding this function in an implementation which inherits this contract,
    /// you can enable versioned tokenIds without the extra overhead of writing to a new storage slot in _owners each time a version is incremented.
    /// See GameToken._storageId() for an example, where the storageId is the tokenId minus the version number.
    /// !!! Caution !!! Overriding this function without taking appropriate care could lead to
    /// ownerOf() returning an owner for non-existent tokens. Tests should be written to
    /// guard against introducing this bug.
    /// @param id The id of a token.
    /// @return The id used for storage mappings.
    function _storageId(uint256 id) internal view virtual returns (uint256) {
        return id;
    }

    function _updateOwnerData(
        uint256 id,
        uint256 oldData,
        address newOwner,
        bool hasOperator
    ) internal virtual {
        if (hasOperator) {
            _owners[_storageId(id)] = (oldData & NOT_ADDRESS) | OPERATOR_FLAG | uint256(uint160(newOwner));
        } else {
            _owners[_storageId(id)] = ((oldData & NOT_ADDRESS) & NOT_OPERATOR_FLAG) | uint256(uint160(newOwner));
        }
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _updateOwnerData(id, _owners[_storageId(id)], to, false);
        emit Transfer(from, to, id);
    }

    /// @dev See approveFor.
    function _approveFor(
        uint256 ownerData,
        address operator,
        uint256 id
    ) internal {
        address owner = _ownerOf(id);
        if (operator == address(0)) {
            _updateOwnerData(id, ownerData, owner, false);
        } else {
            _updateOwnerData(id, ownerData, owner, true);
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /// @dev See batchTransferFrom.
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool safe
    ) internal {
        address msgSender = _msgSender();
        bool authorized = msgSender == from || _operatorsForAll[from][msgSender] || _superOperators[msgSender];

        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        require(to != address(0), "NOT_TO_ZEROADDRESS");

        uint256 numTokens = ids.length;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = ids[i];
            (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
            require(owner == from, "BATCHTRANSFERFROM_NOT_OWNER");
            require(authorized || (operatorEnabled && _operators[id] == msgSender), "NOT_AUTHORIZED");
            _updateOwnerData(id, _owners[_storageId(id)], to, false);
            emit Transfer(from, to, id);
        }
        if (from != to) {
            _numNFTPerAddress[from] -= numTokens;
            _numNFTPerAddress[to] += numTokens;
        }

        if (to.isContract()) {
            if (_checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
                require(_checkOnERC721BatchReceived(msgSender, from, to, ids, data), "ERC721_BATCH_RECEIVED_REJECTED");
            } else if (safe) {
                for (uint256 i = 0; i < numTokens; i++) {
                    require(_checkOnERC721Received(msgSender, from, to, ids[i], data), "ERC721_RECEIVED_REJECTED");
                }
            }
        }
    }

    /// @dev See setApprovalForAll.
    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "INVALID_APPROVAL_CHANGE");
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev See burn.
    function _burn(
        address from,
        address owner,
        uint256 id
    ) internal {
        require(from == owner, "NOT_OWNER");
        uint256 storageId = _storageId(id);
        _owners[storageId] = (_owners[storageId] & NOT_OPERATOR_FLAG) | BURNED_FLAG; // record as non owner but keep track of last owner
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
    }

    /// @dev Check if receiving contract accepts erc721 transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param tokenId The id of the token we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x150b7a02 is returned.
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721ReceiverUpgradeable(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /// @dev Check if receiving contract accepts erc721 batch transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param ids The ids of the tokens we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x4b808c46 is returned.
    function _checkOnERC721BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721MandatoryTokenReceiver(to).onERC721BatchReceived(operator, from, ids, _data);
        return (retval == _ERC721_BATCH_RECEIVED);
    }

    /// @dev See ownerOf
    function _ownerOf(uint256 id) internal view virtual returns (address) {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            return address(0);
        }
        return address(uint160(data));
    }

    /// @dev Get the owner and operatorEnabled status of a token.
    /// @param id The token to query.
    /// @return owner The owner of the token.
    /// @return operatorEnabled Whether or not operators are enabled for this token.
    function _ownerAndOperatorEnabledOf(uint256 id)
        internal
        view
        virtual
        returns (address owner, bool operatorEnabled)
    {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            owner = address(0);
        } else {
            owner = address(uint160(data));
        }
        operatorEnabled = (data & OPERATOR_FLAG) == OPERATOR_FLAG;
    }

    /// @dev Check whether a transfer is a meta Transaction or not.
    /// @param from The address who initiated the transfer (may differ from msg.sender).
    /// @param to The address recieving the token.
    /// @param id The token being transferred.
    /// @return isMetaTx Whether or not the transaction is a MetaTx.
    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view returns (bool isMetaTx) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(owner == from, "CHECKTRANSFER_NOT_OWNER");
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(
            msgSender == owner ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender] ||
                (operatorEnabled && _operators[id] == msgSender),
            "UNAUTHORIZED_TRANSFER"
        );
        return true;
    }

    /// @dev Check if there was enough gas.
    /// @param _contract The address of the contract to check.
    /// @param interfaceId The id of the interface we want to test.
    /// @return Whether or not this check succeeded.
    function _checkInterfaceWith10000Gas(address _contract, bytes4 interfaceId) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(ERC165ID, interfaceId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract WithAdminV2 is ContextUpgradeable {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(_msgSender() == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        address admin = _admin;
        require(_msgSender() == admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(admin, newAdmin);
        _admin = newAdmin;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdminV2.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract WithSuperOperatorsV2 is ContextUpgradeable, WithAdminV2 {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address indexed superOperator, bool indexed enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(_msgSender() == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

abstract contract FxBaseChildTunnelUpgradeable is FxBaseChildTunnel {
    constructor() FxBaseChildTunnel(address(0)) {}

    function __FxBaseChildTunnelUpgradeable_initialize(address _fxChild) internal {
        fxChild = _fxChild;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev Note: The ERC-165 identifier for this interface is 0x5e8bf644.
interface IERC721MandatoryTokenReceiver {
    function onERC721BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x4b808c46

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x150b7a02
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ILandToken {
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external;

    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ILandToken.sol";

interface IPolygonLand is ILandToken {
    function mintQuad(
        address user,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external;

    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// solhint-disable code-complexity

pragma solidity 0.8.2;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../../../common/BaseWithStorage/ERC721BaseTokenV2.sol";
import "../../../common/interfaces/IPolygonLand.sol";

abstract contract PolygonLandBaseToken is IPolygonLand, Initializable, ERC721BaseTokenV2 {
    using AddressUpgradeable for address;

    uint256 internal constant GRID_SIZE = 408;

    uint256 internal constant LAYER = 0xFF00000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_1x1 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_3x3 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_6x6 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_12x12 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_24x24 = 0x0400000000000000000000000000000000000000000000000000000000000000;

    mapping(address => bool) internal _minters;

    event Minter(address minter, bool enabled);

    modifier validQuad(
        uint256 size,
        uint256 x,
        uint256 y
    ) {
        require(size == 1 || size == 3 || size == 6 || size == 12 || size == 24, "Invalid size");
        require(x % size == 0 && y % size == 0, "Invalid coordinates");
        require(x <= GRID_SIZE - size && y <= GRID_SIZE - size, "Out of bounds");

        _;
    }

    /**
     * @notice Return the name of the token contract
     * @return The name of the token contract
     */
    function name() public pure returns (string memory) {
        return "Sandbox's LANDs";
    }

    /**
     * @notice Return the symbol of the token contract
     * @return The symbol of the token contract
     */
    function symbol() public pure returns (string memory) {
        return "LAND";
    }

    /// @notice total width of the map
    /// @return width
    function width() public pure returns (uint256) {
        return GRID_SIZE;
    }

    /// @notice total height of the map
    /// @return height
    function height() public pure returns (uint256) {
        return GRID_SIZE;
    }

    /// @notice x coordinate of Land token
    /// @param id tokenId
    /// @return the x coordinates
    function getX(uint256 id) external view returns (uint256) {
        require(_ownerOf(id) != address(0), "token does not exist");
        return id % GRID_SIZE;
    }

    /// @notice y coordinate of Land token
    /// @param id tokenId
    /// @return the y coordinates
    function getY(uint256 id) external view returns (uint256) {
        require(_ownerOf(id) != address(0), "token does not exist");
        return id / GRID_SIZE;
    }

    /**
     * @notice Return the URI of a specific token
     * @param id The id of the token
     * @return The URI of the token
     */
    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf(id) != address(0), "Id does not exist");
        return
            string(
                abi.encodePacked("https://api.sandbox.game/lands/", StringsUpgradeable.toString(id), "/metadata.json")
            );
    }

    /**
     * @notice Check if the contract supports an interface
     * 0x01ffc9a7 is ERC-165
     * 0x80ac58cd is ERC-721
     * 0x5b5e139f is ERC-721 metadata
     * @param id The id of the interface
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 id) public pure override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }

    /**
     * @notice Mint a new quad (aligned to a quad tree with size 1, 3, 6, 12 or 24 only)
     * @param user The recipient of the new quad
     * @param size The size of the new quad
     * @param x The top left x coordinate of the new quad
     * @param y The top left y coordinate of the new quad
     * @param data extra data to pass to the transfer
     */
    function mintQuad(
        address user,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external virtual override {
        require(isMinter(_msgSender()), "!AUTHORIZED");
        _mintQuad(user, size, x, y, data);
    }

    function _mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        require(to != address(0), "to is zero address");
        require(!exists(size, x, y), "Already minted");

        uint256 quadId;
        uint256 id = x + y * GRID_SIZE;

        if (size == 1) {
            quadId = id;
        } else if (size == 3) {
            quadId = LAYER_3x3 + id;
        } else if (size == 6) {
            quadId = LAYER_6x6 + id;
        } else if (size == 12) {
            quadId = LAYER_12x12 + id;
        } else if (size == 24) {
            quadId = LAYER_24x24 + id;
        }

        for (uint256 i = 0; i < size * size; i++) {
            emit Transfer(address(0), to, _idInPath(i, size, x, y));
        }

        _owners[quadId] = uint256(uint160(address(to)));
        _numNFTPerAddress[to] += size * size;

        _checkBatchReceiverAcceptQuad(_msgSender(), address(0), to, size, x, y, data);
    }

    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external override {
        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");
        require(sizes.length == xs.length && xs.length == ys.length, "invalid data");
        if (_msgSender() != from) {
            require(
                _operatorsForAll[from][_msgSender()] || _superOperators[_msgSender()],
                "not authorized to transferMultiQuads"
            );
        }
        uint256 numTokensTransfered = 0;
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 size = sizes[i];
            _transferQuad(from, to, size, xs[i], ys[i]);
            numTokensTransfered += size * size;
        }
        _numNFTPerAddress[from] -= numTokensTransfered;
        _numNFTPerAddress[to] += numTokensTransfered;

        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            uint256[] memory ids = new uint256[](numTokensTransfered);
            uint256 counter = 0;
            for (uint256 j = 0; j < sizes.length; j++) {
                uint256 size = sizes[j];
                for (uint256 i = 0; i < size * size; i++) {
                    ids[counter] = _idInPath(i, size, xs[j], ys[j]);
                    counter++;
                }
            }
            require(
                _checkOnERC721BatchReceived(_msgSender(), from, to, ids, data),
                "erc721 batch transfer rejected by to"
            );
        }
    }

    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external override {
        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");
        if (_msgSender() != from) {
            require(
                _operatorsForAll[from][_msgSender()] || _superOperators[_msgSender()],
                "not authorized to transferQuad"
            );
        }
        _transferQuad(from, to, size, x, y);
        _numNFTPerAddress[from] -= size * size;
        _numNFTPerAddress[to] += size * size;

        _checkBatchReceiverAcceptQuad(_msgSender(), from, to, size, x, y, data);
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) public override(ILandToken, ERC721BaseTokenV2) {
        super.batchTransferFrom(from, to, ids, data);
    }

    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) public view override validQuad(size, x, y) returns (bool) {
        if (_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE] != 0) return true;
        uint256 toX = x + size;
        uint256 toY = y + size;
        if (size <= 12) {
            if (_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE] != 0) return true;
        } else {
            for (uint256 x12i = x; x12i < toX; x12i += 12) {
                for (uint256 y12i = y; y12i < toY; y12i += 12) {
                    uint256 id12x12 = LAYER_12x12 + x12i + y12i * GRID_SIZE;
                    if (_owners[id12x12] != 0) return true;
                }
            }
        }

        if (size <= 6) {
            if (_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE] != 0) return true;
        } else {
            for (uint256 x6i = x; x6i < toX; x6i += 6) {
                for (uint256 y6i = y; y6i < toY; y6i += 6) {
                    uint256 id6x6 = LAYER_6x6 + x6i + y6i * GRID_SIZE;
                    if (_owners[id6x6] != 0) return true;
                }
            }
        }

        if (size <= 3) {
            if (_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE] != 0) return true;
        } else {
            for (uint256 x3i = x; x3i < toX; x3i += 3) {
                for (uint256 y3i = y; y3i < toY; y3i += 3) {
                    uint256 id3x3 = LAYER_3x3 + x3i + y3i * GRID_SIZE;
                    if (_owners[id3x3] != 0) return true;
                }
            }
        }

        for (uint256 i = 0; i < size * size; i++) {
            if (_owners[_idInPath(i, size, x, y)] != 0) return true;
        }

        return false;
    }

    /// @notice Enable or disable the ability of `minter` to transfer tokens of all (minter rights).
    /// @param minter address that will be given/removed minter right.
    /// @param enabled set whether the minter is enabled or disabled.
    function setMinter(address minter, bool enabled) external {
        require(_msgSender() == _admin, "only admin is allowed to add minters");
        require(minter != address(0), "PolygonLand: Invalid address");
        _minters[minter] = enabled;
        emit Minter(minter, enabled);
    }

    /// @notice check whether address `who` is given minter rights.
    /// @param who The address to query.
    /// @return whether the address has minter rights.
    function isMinter(address who) public view returns (bool) {
        return _minters[who];
    }

    function _transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal validQuad(size, x, y) {
        if (size == 1) {
            uint256 id1x1 = x + y * GRID_SIZE;
            address owner = _ownerOf(id1x1);
            require(owner != address(0), "token does not exist");
            require(owner == from, "not owner in _transferQuad");
            _owners[id1x1] = uint256(uint160(address(to)));
        } else {
            _regroup(from, to, size, x, y);
        }
        for (uint256 i = 0; i < size * size; i++) {
            emit Transfer(from, to, _idInPath(i, size, x, y));
        }
    }

    function _idInPath(
        uint256 i,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        uint256 row = i / size;
        if (row % 2 == 0) {
            // allow ids to follow a path in a quad
            return (x + (i % size)) + ((y + row) * GRID_SIZE);
        } else {
            return ((x + size) - (1 + (i % size))) + ((y + row) * GRID_SIZE);
        }
    }

    function _regroup(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal {
        if (size == 3) {
            _regroup3x3(from, to, x, y, true);
        } else if (size == 6) {
            _regroup6x6(from, to, x, y, true);
        } else if (size == 12) {
            _regroup12x12(from, to, x, y, true);
        } else if (size == 24) {
            _regroup24x24(from, to, x, y, true);
        }
    }

    function _regroup3x3(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_3x3 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 3; xi++) {
            for (uint256 yi = y; yi < y + 3; yi++) {
                ownerOfAll = _checkAndClear(from, xi + yi * GRID_SIZE) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(_ownerOfQuad(3, x, y) == from, "not owner of all sub quads nor parent quads");
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll;
    }

    function _regroup6x6(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_6x6 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 6; xi += 3) {
            for (uint256 yi = y; yi < y + 6; yi += 3) {
                bool ownAllIndividual = _regroup3x3(from, to, xi, yi, false);
                uint256 id3x3 = LAYER_3x3 + xi + yi * GRID_SIZE;
                uint256 owner3x3 = _owners[id3x3];
                if (owner3x3 != 0) {
                    if (!ownAllIndividual) {
                        require(owner3x3 == uint256(uint160(address(from))), "not owner of 3x3 quad");
                    }
                    _owners[id3x3] = 0;
                }
                ownerOfAll = (ownAllIndividual || owner3x3 != 0) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(_ownerOfQuad(6, x, y) == from, "not owner of all sub quads nor parent quads");
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll;
    }

    function _regroup12x12(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_12x12 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 12; xi += 6) {
            for (uint256 yi = y; yi < y + 12; yi += 6) {
                bool ownAllIndividual = _regroup6x6(from, to, xi, yi, false);
                uint256 id6x6 = LAYER_6x6 + xi + yi * GRID_SIZE;
                uint256 owner6x6 = _owners[id6x6];
                if (owner6x6 != 0) {
                    if (!ownAllIndividual) {
                        require(owner6x6 == uint256(uint160(address(from))), "not owner of 6x6 quad");
                    }
                    _owners[id6x6] = 0;
                }
                ownerOfAll = (ownAllIndividual || owner6x6 != 0) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(_ownerOfQuad(12, x, y) == from, "not owner of all sub quads nor parent quads");
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll;
    }

    function _regroup24x24(
        address from,
        address to,
        uint256 x,
        uint256 y,
        bool set
    ) internal returns (bool) {
        uint256 id = x + y * GRID_SIZE;
        uint256 quadId = LAYER_24x24 + id;
        bool ownerOfAll = true;
        for (uint256 xi = x; xi < x + 24; xi += 12) {
            for (uint256 yi = y; yi < y + 24; yi += 12) {
                bool ownAllIndividual = _regroup12x12(from, to, xi, yi, false);
                uint256 id12x12 = LAYER_12x12 + xi + yi * GRID_SIZE;
                uint256 owner12x12 = _owners[id12x12];
                if (owner12x12 != 0) {
                    if (!ownAllIndividual) {
                        require(owner12x12 == uint256(uint160(address(from))), "not owner of 12x12 quad");
                    }
                    _owners[id12x12] = 0;
                }
                ownerOfAll = (ownAllIndividual || owner12x12 != 0) && ownerOfAll;
            }
        }
        if (set) {
            if (!ownerOfAll) {
                require(
                    _owners[quadId] == uint256(uint160(address(from))),
                    "not owner of all sub quads not parent quad"
                );
            }
            _owners[quadId] = uint256(uint160(address(to)));
            return true;
        }
        return ownerOfAll || _owners[quadId] == uint256(uint160(address(from)));
    }

    function _ownerOfQuad(
        uint256 size,
        uint256 x,
        uint256 y
    ) internal returns (address) {
        uint256 layer;
        uint256 parentSize = size * 2;
        if (size == 3) {
            layer = LAYER_3x3;
        } else if (size == 6) {
            layer = LAYER_6x6;
        } else if (size == 12) {
            layer = LAYER_12x12;
        } else if (size == 24) {
            layer = LAYER_24x24;
        } else {
            require(false, "Invalid size");
        }

        address owner = address(uint160(_owners[layer + (x / size) * size + ((y / size) * size) * GRID_SIZE]));
        if (owner != address(0)) {
            return owner;
        } else if (size < 24) {
            return _ownerOfQuad(parentSize, x, y);
        }
        return address(0);
    }

    function _ownerOf(uint256 id) internal view override returns (address) {
        require(id & LAYER == 0, "Invalid token id");
        uint256 x = id % GRID_SIZE;
        uint256 y = id / GRID_SIZE;
        uint256 owner1x1 = _owners[id];

        if ((owner1x1 & BURNED_FLAG) == BURNED_FLAG) {
            return address(0);
        }

        if (owner1x1 != 0) {
            return address(uint160(owner1x1)); //we check if the quad exists as an 1x1 quad, then 3x3, and so on..
        } else {
            address owner3x3 = address(uint160(_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE]));
            if (owner3x3 != address(0)) {
                return owner3x3;
            } else {
                address owner6x6 = address(uint160(_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE]));
                if (owner6x6 != address(0)) {
                    return owner6x6;
                } else {
                    address owner12x12 =
                        address(uint160(_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE]));
                    if (owner12x12 != address(0)) {
                        return owner12x12;
                    } else {
                        return address(uint160(_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE]));
                    }
                }
            }
        }
    }

    function _checkAndClear(address from, uint256 id) internal returns (bool) {
        uint256 owner = _owners[id];
        if (owner != 0) {
            require((owner & BURNED_FLAG) != BURNED_FLAG, "not owner");
            require(address(uint160(owner)) == from, "not owner");
            _owners[id] = 0;
            return true;
        }
        return false;
    }

    function _checkBatchReceiverAcceptQuad(
        address operator,
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            uint256[] memory ids = new uint256[](size * size);
            for (uint256 i = 0; i < size * size; i++) {
                ids[i] = _idInPath(i, size, x, y);
            }
            require(_checkOnERC721BatchReceived(operator, from, to, ids, data), "erc721 batch transfer rejected by to");
        }
    }

    function _ownerAndOperatorEnabledOf(uint256 id)
        internal
        view
        override
        returns (address owner, bool operatorEnabled)
    {
        require(id & LAYER == 0, "Invalid token id");
        uint256 x = id % GRID_SIZE;
        uint256 y = id / GRID_SIZE;
        uint256 owner1x1 = _owners[id];

        if ((owner1x1 & BURNED_FLAG) == BURNED_FLAG) {
            owner = address(0);
            operatorEnabled = (owner1x1 & OPERATOR_FLAG) == OPERATOR_FLAG;
            return (owner, operatorEnabled);
        }

        if (owner1x1 != 0) {
            owner = address(uint160(owner1x1));
            operatorEnabled = (owner1x1 & OPERATOR_FLAG) == OPERATOR_FLAG;
        } else {
            address owner3x3 = address(uint160(_owners[LAYER_3x3 + (x / 3) * 3 + ((y / 3) * 3) * GRID_SIZE]));
            if (owner3x3 != address(uint160(0))) {
                owner = owner3x3;
                operatorEnabled = false;
            } else {
                address owner6x6 = address(uint160(_owners[LAYER_6x6 + (x / 6) * 6 + ((y / 6) * 6) * GRID_SIZE]));
                if (owner6x6 != address(uint160(0))) {
                    owner = owner6x6;
                    operatorEnabled = false;
                } else {
                    address owner12x12 =
                        address(uint160(_owners[LAYER_12x12 + (x / 12) * 12 + ((y / 12) * 12) * GRID_SIZE]));
                    if (owner12x12 != address(uint160(0))) {
                        owner = owner12x12;
                        operatorEnabled = false;
                    } else {
                        owner = address(uint160(_owners[LAYER_24x24 + (x / 24) * 24 + ((y / 24) * 24) * GRID_SIZE]));
                        operatorEnabled = false;
                    }
                }
            }
        }
    }

    // Empty storage space in contracts for future enhancements
    // ref: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/issues/13)
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../../common/FX-Portal/FxBaseChildTunnelUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../../common/interfaces/IPolygonLand.sol";
import "../../../common/interfaces/IERC721MandatoryTokenReceiver.sol";
import "../../../common/BaseWithStorage/ERC2771Handler.sol";
import "./PolygonLandBaseToken.sol";

/// @title LAND bridge on L2
contract PolygonLandTunnel is
    FxBaseChildTunnelUpgradeable,
    IERC721MandatoryTokenReceiver,
    ERC2771Handler,
    OwnableUpgradeable,
    PausableUpgradeable
{
    IPolygonLand public childToken;
    uint32 public maxGasLimitOnL1;
    uint256 public maxAllowedQuads;
    bool internal transferringToL1;

    mapping(uint8 => uint32) public gasLimits;

    event SetGasLimit(uint8 size, uint32 limit);
    event SetMaxGasLimit(uint32 maxGasLimit);
    event SetMaxAllowedQuads(uint256 maxQuads);
    event Deposit(address indexed user, uint256 size, uint256 x, uint256 y, bytes data);
    event Withdraw(address indexed user, uint256 size, uint256 x, uint256 y, bytes data);

    function setMaxLimitOnL1(uint32 _maxGasLimit) external onlyOwner {
        maxGasLimitOnL1 = _maxGasLimit;
        emit SetMaxGasLimit(_maxGasLimit);
    }

    function setMaxAllowedQuads(uint256 _maxAllowedQuads) external onlyOwner {
        require(_maxAllowedQuads > 0, "PolygonLandTunnel: max allowed value cannot be zero");
        maxAllowedQuads = _maxAllowedQuads;
        emit SetMaxAllowedQuads(_maxAllowedQuads);
    }

    function _setLimit(uint8 size, uint32 limit) internal {
        gasLimits[size] = limit;
        emit SetGasLimit(size, limit);
    }

    function setLimit(uint8 size, uint32 limit) external onlyOwner {
        _setLimit(size, limit);
    }

    // setupLimits([5, 10, 20, 90, 340]);
    function setupLimits(uint32[5] memory limits) public onlyOwner {
        _setLimit(1, limits[0]);
        _setLimit(3, limits[1]);
        _setLimit(6, limits[2]);
        _setLimit(12, limits[3]);
        _setLimit(24, limits[4]);
    }

    function _PolygonLandTunnel_init(
        address _fxChild,
        IPolygonLand _childToken,
        address _trustedForwarder,
        uint32 _maxGasLimit,
        uint256 _maxAllowedQuads,
        uint32[5] memory limits
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        childToken = _childToken;
        maxGasLimitOnL1 = _maxGasLimit;
        maxAllowedQuads = _maxAllowedQuads;
        setupLimits(limits);
        __FxBaseChildTunnelUpgradeable_initialize(_fxChild);
        __ERC2771Handler_initialize(_trustedForwarder);
    }

    function batchTransferQuadToL1(
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes memory data
    ) external whenNotPaused {
        require(sizes.length == xs.length && sizes.length == ys.length, "sizes, xs, ys must be same length");

        uint32 gasLimit = 0;
        uint256 quads = 0;
        for (uint256 i = 0; i < sizes.length; i++) {
            gasLimit += gasLimits[uint8(sizes[i])];
            quads += sizes[i] * sizes[i];
        }

        require(quads <= maxAllowedQuads, "Exceeds max allowed quads.");
        require(gasLimit < maxGasLimitOnL1, "Exceeds gas limit on L1.");
        transferringToL1 = true;
        for (uint256 i = 0; i < sizes.length; i++) {
            childToken.transferQuad(_msgSender(), address(this), sizes[i], xs[i], ys[i], data);
            emit Withdraw(to, sizes[i], xs[i], ys[i], data);
        }
        _sendMessageToRoot(abi.encode(to, sizes, xs, ys, data));
        transferringToL1 = false;
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    /// @dev Pauses all token transfers across bridge
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses all token transfers across bridge
    function unpause() external onlyOwner {
        _unpause();
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        _syncDeposit(data);
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address to, uint256 size, uint256 x, uint256 y, bytes memory data) = abi.decode(
            syncData,
            (address, uint256, uint256, uint256, bytes)
        );
        if (!childToken.exists(size, x, y)) childToken.mintQuad(to, size, x, y, data);
        else childToken.transferQuad(address(this), to, size, x, y, data);
        emit Deposit(to, size, x, y, data);
    }

    function _msgSender() internal view override(ContextUpgradeable, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external view override returns (bytes4) {
        require(transferringToL1, "PolygonLandTunnel: !BRIDGING");
        return this.onERC721Received.selector;
    }

    function onERC721BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        bytes calldata /* data */
    ) external view override returns (bytes4) {
        require(transferringToL1, "PolygonLandTunnel: !BRIDGING");
        return this.onERC721BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x5e8bf644 || interfaceId == 0x01ffc9a7;
    }
}