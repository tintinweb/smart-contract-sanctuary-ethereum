// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721ReceiverUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Upgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IAccessControl.sol";

/// @title Cake access control
/// @author landakram
/// @notice This contact centralizes contract-to-contract access control using a simple
/// access-control list. There are two types of actors: operators and admins. Operators
/// are callers involved in a regular end-user tx. This would likely be another Goldfinch
/// contract for which the current contract is a dependency. Admins are callers allowed
/// for specific admin actions (like changing parameters, topping up funds, etc.).
contract AccessControl is Initializable, IAccessControl {
  /// @dev Mapping from contract address to contract admin;
  mapping(address => address) public admins;

  function initialize(address admin) public initializer {
    admins[address(this)] = admin;
    emit AdminSet(address(this), admin);
  }

  /// @inheritdoc IAccessControl
  function setAdmin(address resource, address admin) external {
    requireSuperAdmin(msg.sender);
    admins[resource] = admin;
    emit AdminSet(resource, admin);
  }

  /// @inheritdoc IAccessControl
  function requireAdmin(address resource, address accessor) public view {
    if (accessor == address(0)) revert ZeroAddress();
    bool isAdmin = admins[resource] == accessor;
    if (!isAdmin) revert RequiresAdmin(resource, accessor);
  }

  /// @inheritdoc IAccessControl
  function requireSuperAdmin(address accessor) public view {
    // The super admin is the admin of this AccessControl contract
    requireAdmin({resource: address(this), accessor: accessor});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Context} from "./Context.sol";
import "./Routing.sol" as Routing;

using Routing.Context for Context;

/// @title Base contract for application-layer
/// @author landakram
/// @notice This base contract is what all application-layer contracts should inherit from.
///  It provides `Context`, as well as some convenience functions for working with it and
///  using access control. All public methods on the inheriting contract should likely
///  use one of the modifiers to assert valid callers.
abstract contract Base {
  error RequiresOperator(address resource, address accessor);
  error ZeroAddress();

  /// @dev this is safe for proxies as immutable causes the context to be written to
  ///  bytecode on deployment. The proxy then treats this as a constant.
  Context immutable context;

  constructor(Context _context) {
    context = _context;
  }

  modifier onlyOperator(bytes4 operatorId) {
    requireOperator(operatorId, msg.sender);
    _;
  }

  modifier onlyOperators(bytes4[2] memory operatorIds) {
    requireAnyOperator(operatorIds, msg.sender);
    _;
  }

  modifier onlyAdmin() {
    context.accessControl().requireAdmin(address(this), msg.sender);
    _;
  }

  function requireAnyOperator(bytes4[2] memory operatorIds, address accessor) private view {
    if (accessor == address(0)) revert ZeroAddress();

    bool validOperator = isOperator(operatorIds[0], accessor) ||
      isOperator(operatorIds[1], accessor);

    if (!validOperator) revert RequiresOperator(address(this), accessor);
  }

  function requireOperator(bytes4 operatorId, address accessor) private view {
    if (accessor == address(0)) revert ZeroAddress();
    if (!isOperator(operatorId, accessor)) revert RequiresOperator(address(this), accessor);
  }

  function isOperator(bytes4 operatorId, address accessor) private view returns (bool) {
    return context.router().contracts(operatorId) == accessor;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccessControl} from "./AccessControl.sol";
import {Router} from "./Router.sol";
import "./Routing.sol" as Routing;

using Routing.Context for Context;

/// @title Entry-point for all application-layer contracts.
/// @author landakram
/// @notice This contract provides an interface for retrieving other contract addresses and doing access
///  control.
contract Context {
  /// @notice Used for retrieving other contract addresses.
  /// @dev This variable is immutable. This is done to save gas, as it is expected to be referenced
  /// in every end-user call with a call-chain length > 0. Note that it is written into the contract
  /// bytecode at contract creation time, so if the contract is deployed as the implementation for proxies,
  /// every proxy will share the same Router address.
  Router public immutable router;

  constructor(Router _router) {
    router = _router;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// solhint-disable-next-line max-line-length
import {PausableUpgradeable as OZPausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {Base} from "./Base.sol";
import "./Routing.sol" as Routing;

abstract contract PausableUpgradeable is Base, OZPausableUpgradeable {
  function pause() external onlyOperators([Routing.Keys.PauserAdmin, Routing.Keys.ProtocolAdmin]) {
    _pause();
  }

  function unpause()
    external
    onlyOperators([Routing.Keys.PauserAdmin, Routing.Keys.ProtocolAdmin])
  {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControl} from "./AccessControl.sol";
import {IRouter} from "../interfaces/IRouter.sol";

import "./Routing.sol" as Routing;

/// @title Router
/// @author landakram
/// @notice This contract provides service discovery for contracts using the cake framework.
///   It can be used in conjunction with the convenience methods defined in the `Routing.Context`
///   and `Routing.Keys` libraries.
contract Router is Initializable, IRouter {
  /// @notice Mapping of keys to contract addresses. Keys are the first 4 bytes of the keccak of
  ///   the contract's name. See Routing.sol for all options.
  mapping(bytes4 => address) public contracts;

  function initialize(AccessControl accessControl) public initializer {
    contracts[Routing.Keys.AccessControl] = address(accessControl);
  }

  /// @notice Associate a routing key to a contract address
  /// @dev This function is only callable by the Router admin
  /// @param key A routing key (defined in the `Routing.Keys` libary)
  /// @param addr A contract address
  function setContract(bytes4 key, address addr) public {
    AccessControl accessControl = AccessControl(contracts[Routing.Keys.AccessControl]);
    accessControl.requireAdmin(address(this), msg.sender);
    contracts[key] = addr;
    emit SetContract(key, addr);
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable const-name-snakecase

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

import {IMembershipVault} from "../interfaces/IMembershipVault.sol";
import {IGFILedger} from "../interfaces/IGFILedger.sol";
import {ICapitalLedger} from "../interfaces/ICapitalLedger.sol";
import {IMembershipDirector} from "../interfaces/IMembershipDirector.sol";
import {IMembershipOrchestrator} from "../interfaces/IMembershipOrchestrator.sol";
import {IMembershipLedger} from "../interfaces/IMembershipLedger.sol";
import {IMembershipCollector} from "../interfaces/IMembershipCollector.sol";
import {IBackerRewards} from "../interfaces/IBackerRewards.sol";

import {ISeniorPool} from "../interfaces/ISeniorPool.sol";
import {IPoolTokens} from "../interfaces/IPoolTokens.sol";
import {IStakingRewards} from "../interfaces/IStakingRewards.sol";
import {IGo} from "../interfaces/IGo.sol";

import {IERC20Splitter} from "../interfaces/IERC20Splitter.sol";
import {Context as ContextContract} from "./Context.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";

/// @title Routing.Keys
/// @notice This library is used to define routing keys used by `Router`.
/// @dev We use uints instead of enums for several reasons. First, keys can be re-ordered
///   or removed. This is useful when routing keys are deprecated; they can be moved to a
///   different section of the file. Second, other libraries or contracts can define their
///   own routing keys independent of this global mapping. This is useful for test contracts.
library Keys {
  // Membership
  bytes4 internal constant MembershipOrchestrator = bytes4(keccak256("MembershipOrchestrator"));
  bytes4 internal constant MembershipDirector = bytes4(keccak256("MembershipDirector"));
  bytes4 internal constant GFILedger = bytes4(keccak256("GFILedger"));
  bytes4 internal constant CapitalLedger = bytes4(keccak256("CapitalLedger"));
  bytes4 internal constant MembershipCollector = bytes4(keccak256("MembershipCollector"));
  bytes4 internal constant MembershipLedger = bytes4(keccak256("MembershipLedger"));
  bytes4 internal constant MembershipVault = bytes4(keccak256("MembershipVault"));

  // Tokens
  bytes4 internal constant GFI = bytes4(keccak256("GFI"));
  bytes4 internal constant FIDU = bytes4(keccak256("FIDU"));
  bytes4 internal constant USDC = bytes4(keccak256("USDC"));

  // Cake
  bytes4 internal constant AccessControl = bytes4(keccak256("AccessControl"));
  bytes4 internal constant Router = bytes4(keccak256("Router"));

  // Core
  bytes4 internal constant ReserveSplitter = bytes4(keccak256("ReserveSplitter"));
  bytes4 internal constant PoolTokens = bytes4(keccak256("PoolTokens"));
  bytes4 internal constant SeniorPool = bytes4(keccak256("SeniorPool"));
  bytes4 internal constant StakingRewards = bytes4(keccak256("StakingRewards"));
  bytes4 internal constant ProtocolAdmin = bytes4(keccak256("ProtocolAdmin"));
  bytes4 internal constant PauserAdmin = bytes4(keccak256("PauserAdmin"));
  bytes4 internal constant BackerRewards = bytes4(keccak256("BackerRewards"));
  bytes4 internal constant Go = bytes4(keccak256("Go"));
}

/// @title Routing.Context
/// @notice This library provides convenience functions for getting contracts from `Router`.
library Context {
  function accessControl(ContextContract context) internal view returns (IAccessControl) {
    return IAccessControl(context.router().contracts(Keys.AccessControl));
  }

  function membershipVault(ContextContract context) internal view returns (IMembershipVault) {
    return IMembershipVault(context.router().contracts(Keys.MembershipVault));
  }

  function capitalLedger(ContextContract context) internal view returns (ICapitalLedger) {
    return ICapitalLedger(context.router().contracts(Keys.CapitalLedger));
  }

  function gfiLedger(ContextContract context) internal view returns (IGFILedger) {
    return IGFILedger(context.router().contracts(Keys.GFILedger));
  }

  function gfi(ContextContract context) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(context.router().contracts(Keys.GFI));
  }

  function membershipDirector(ContextContract context) internal view returns (IMembershipDirector) {
    return IMembershipDirector(context.router().contracts(Keys.MembershipDirector));
  }

  function membershipOrchestrator(
    ContextContract context
  ) internal view returns (IMembershipOrchestrator) {
    return IMembershipOrchestrator(context.router().contracts(Keys.MembershipOrchestrator));
  }

  function stakingRewards(ContextContract context) internal view returns (IStakingRewards) {
    return IStakingRewards(context.router().contracts(Keys.StakingRewards));
  }

  function poolTokens(ContextContract context) internal view returns (IPoolTokens) {
    return IPoolTokens(context.router().contracts(Keys.PoolTokens));
  }

  function seniorPool(ContextContract context) internal view returns (ISeniorPool) {
    return ISeniorPool(context.router().contracts(Keys.SeniorPool));
  }

  function fidu(ContextContract context) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(context.router().contracts(Keys.FIDU));
  }

  function usdc(ContextContract context) internal view returns (IERC20Upgradeable) {
    return IERC20Upgradeable(context.router().contracts(Keys.USDC));
  }

  function reserveSplitter(ContextContract context) internal view returns (IERC20Splitter) {
    return IERC20Splitter(context.router().contracts(Keys.ReserveSplitter));
  }

  function membershipLedger(ContextContract context) internal view returns (IMembershipLedger) {
    return IMembershipLedger(context.router().contracts(Keys.MembershipLedger));
  }

  function membershipCollector(
    ContextContract context
  ) internal view returns (IMembershipCollector) {
    return IMembershipCollector(context.router().contracts(Keys.MembershipCollector));
  }

  function protocolAdmin(ContextContract context) internal view returns (address) {
    return context.router().contracts(Keys.ProtocolAdmin);
  }

  function pauserAdmin(ContextContract context) internal view returns (address) {
    return context.router().contracts(Keys.PauserAdmin);
  }

  function backerRewards(ContextContract context) internal view returns (IBackerRewards) {
    return IBackerRewards(context.router().contracts(Keys.BackerRewards));
  }

  function go(ContextContract context) internal view returns (IGo) {
    return IGo(context.router().contracts(Keys.Go));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title Cake access control
/// @author landakram
/// @notice This contact centralizes contract-to-contract access control using a simple
/// access-control list. There are two types of actors: operators and admins. Operators
/// are callers involved in a regular end-user tx. This would likely be another Goldfinch
/// contract for which the current contract is a dependency. Admins are callers allowed
/// for specific admin actions (like changing parameters, topping up funds, etc.).
interface IAccessControl {
  error RequiresAdmin(address resource, address accessor);
  error ZeroAddress();

  event AdminSet(address indexed resource, address indexed admin);

  /// @notice Set an admin for a given resource
  /// @param resource An address which with `admin` should be allowed to administer
  /// @param admin An address which should be allowed to administer `resource`
  /// @dev This method is only callable by the super-admin (the admin of this AccessControl
  ///   contract)
  function setAdmin(address resource, address admin) external;

  /// @notice Require a valid admin for a given resource
  /// @param resource An address that `accessor` is attempting to access
  /// @param accessor An address on which to assert access control checks
  /// @dev This method reverts when `accessor` is not a valid admin
  function requireAdmin(address resource, address accessor) external view;

  /// @notice Require a super-admin. A super-admin is an admin of this AccessControl contract.
  /// @param accessor An address on which to assert access control checks
  /// @dev This method reverts when `accessor` is not a valid super-admin
  function requireSuperAdmin(address accessor) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {ITranchedPool} from "./ITranchedPool.sol";

interface IBackerRewards {
  struct BackerRewardsTokenInfo {
    uint256 rewardsClaimed; // gfi claimed
    uint256 accRewardsPerPrincipalDollarAtMint; // Pool's accRewardsPerPrincipalDollar at PoolToken mint()
  }

  struct BackerRewardsInfo {
    uint256 accRewardsPerPrincipalDollar; // accumulator gfi per interest dollar
  }

  /// @notice Staking rewards parameters relevant to a TranchedPool
  struct StakingRewardsPoolInfo {
    // @notice the value `StakingRewards.accumulatedRewardsPerToken()` at the last checkpoint
    uint256 accumulatedRewardsPerTokenAtLastCheckpoint;
    // @notice last time the rewards info was updated
    //
    // we need this in order to know how much to pro rate rewards after the term is over.
    uint256 lastUpdateTime;
    // @notice staking rewards parameters for each slice of the tranched pool
    StakingRewardsSliceInfo[] slicesInfo;
  }

  /// @notice Staking rewards paramters relevant to a TranchedPool slice
  struct StakingRewardsSliceInfo {
    // @notice fidu share price when the slice is first drawn down
    //
    // we need to save this to calculate what an equivalent position in
    // the senior pool would be at the time the slice is downdown
    uint256 fiduSharePriceAtDrawdown;
    // @notice the amount of principal deployed at the last checkpoint
    //
    // we use this to calculate the amount of principal that should
    // acctually accrue rewards during between the last checkpoint and
    // and subsequent updates
    uint256 principalDeployedAtLastCheckpoint;
    // @notice the value of StakingRewards.accumulatedRewardsPerToken() at time of drawdown
    //
    // we need to keep track of this to use this as a base value to accumulate rewards
    // for tokens. If the token has never claimed staking rewards, we use this value
    // and the current staking rewards accumulator
    uint256 accumulatedRewardsPerTokenAtDrawdown;
    // @notice amount of rewards per token accumulated over the lifetime of the slice that a backer
    //          can claim
    uint256 accumulatedRewardsPerTokenAtLastCheckpoint;
    // @notice the amount of rewards per token accumulated over the lifetime of the slice
    //
    // this value is "unrealized" because backers will be unable to claim against this value.
    // we keep this value so that we can always accumulate rewards for the amount of capital
    // deployed at any point in time, but not allow backers to withdraw them until a payment
    // is made. For example: we want to accumulate rewards when a backer does a drawdown. but
    // a backer shouldn't be allowed to claim rewards until a payment is made.
    //
    // this value is scaled depending on the current proportion of capital currently deployed
    // in the slice. For example, if the staking rewards contract accrued 10 rewards per token
    // between the current checkpoint and a new update, and only 20% of the capital was deployed
    // during that period, we would accumulate 2 (10 * 20%) rewards.
    uint256 unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint;
  }

  /// @notice Staking rewards parameters relevant to a PoolToken
  struct StakingRewardsTokenInfo {
    // @notice the amount of rewards accumulated the last time a token's rewards were withdrawn
    uint256 accumulatedRewardsPerTokenAtLastWithdraw;
  }

  /// @notice total amount of GFI rewards available, times 1e18
  function totalRewards() external view returns (uint256);

  /// @notice interest $ eligible for gfi rewards, times 1e18
  function maxInterestDollarsEligible() external view returns (uint256);

  /// @notice counter of total interest repayments, times 1e6
  function totalInterestReceived() external view returns (uint256);

  /// @notice totalRewards/totalGFISupply * 100, times 1e18
  function totalRewardPercentOfTotalGFI() external view returns (uint256);

  /// @notice Get backer rewards metadata for a pool token
  function getTokenInfo(uint256 poolTokenId) external view returns (BackerRewardsTokenInfo memory);

  /// @notice Get backer staking rewards metadata for a pool token
  function getStakingRewardsTokenInfo(
    uint256 poolTokenId
  ) external view returns (StakingRewardsTokenInfo memory);

  /// @notice Get backer staking rewards for a pool
  function getBackerStakingRewardsPoolInfo(
    ITranchedPool pool
  ) external view returns (StakingRewardsPoolInfo memory);

  /// @notice Calculates the accRewardsPerPrincipalDollar for a given pool,
  ///   when a interest payment is received by the protocol
  /// @param _interestPaymentAmount Atomic usdc amount of the interest payment
  function allocateRewards(uint256 _interestPaymentAmount) external;

  /// @notice callback for TranchedPools when they drawdown
  /// @param sliceIndex index of the tranched pool slice
  /// @dev initializes rewards info for the calling TranchedPool if it's the first
  ///  drawdown for the given slice
  function onTranchedPoolDrawdown(uint256 sliceIndex) external;

  /// @notice When a pool token is minted for multiple drawdowns,
  ///   set accRewardsPerPrincipalDollarAtMint to the current accRewardsPerPrincipalDollar price
  /// @param poolAddress Address of the pool associated with the pool token
  /// @param tokenId Pool token id
  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(
    address poolAddress,
    uint256 tokenId
  ) external;

  /// @notice PoolToken request to withdraw all allocated rewards
  /// @param tokenId Pool token id
  /// @return amount of rewards withdrawn
  function withdraw(uint256 tokenId) external returns (uint256);

  /**
   * @notice Set BackerRewards and BackerStakingRewards metadata for tokens created by a pool token split.
   * @param originalBackerRewardsTokenInfo backer rewards info for the pool token that was split
   * @param originalStakingRewardsTokenInfo backer staking rewards info for the pool token that was split
   * @param newTokenId id of one of the tokens in the split
   * @param newRewardsClaimed rewardsClaimed value for the new token.
   */
  function setBackerAndStakingRewardsTokenInfoOnSplit(
    BackerRewardsTokenInfo memory originalBackerRewardsTokenInfo,
    StakingRewardsTokenInfo memory originalStakingRewardsTokenInfo,
    uint256 newTokenId,
    uint256 newRewardsClaimed
  ) external;

  /**
   * @notice Calculate the gross available gfi rewards for a PoolToken
   * @param tokenId Pool token id
   * @return The amount of GFI claimable
   */
  function poolTokenClaimableRewards(uint256 tokenId) external view returns (uint256);

  /// @notice Clear all BackerRewards and StakingRewards associated data for `tokenId`
  function clearTokenInfo(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

enum CapitalAssetType {
  INVALID,
  ERC721
}

interface ICapitalLedger {
  /**
   * @notice Emitted when a new capital erc721 deposit has been made
   * @param owner address owning the deposit
   * @param assetAddress address of the deposited ERC721
   * @param positionId id for the deposit
   * @param assetTokenId id of the token from the ERC721 `assetAddress`
   * @param usdcEquivalent usdc equivalent value at the time of deposit
   */
  event CapitalERC721Deposit(
    address indexed owner,
    address indexed assetAddress,
    uint256 positionId,
    uint256 assetTokenId,
    uint256 usdcEquivalent
  );

  /**
   * @notice Emitted when a new ERC721 capital withdrawal has been made
   * @param owner address owning the deposit
   * @param positionId id for the capital position
   * @param assetAddress address of the underlying ERC721
   * @param depositTimestamp block.timestamp of the original deposit
   */
  event CapitalERC721Withdrawal(
    address indexed owner,
    uint256 positionId,
    address assetAddress,
    uint256 depositTimestamp
  );

  /**
   * @notice Emitted when an ERC721 capital asset has been harvested
   * @param positionId id for the capital position
   * @param assetAddress address of the underlying ERC721
   */
  event CapitalERC721Harvest(uint256 indexed positionId, address assetAddress);

  /**
   * @notice Emitted when an ERC721 capital asset has been "kicked", which may cause the underlying
   *  usdc equivalent value to change.
   * @param positionId id for the capital position
   * @param assetAddress address of the underlying ERC721
   * @param usdcEquivalent new usdc equivalent value of the position
   */
  event CapitalPositionAdjustment(
    uint256 indexed positionId,
    address assetAddress,
    uint256 usdcEquivalent
  );

  /// Thrown when called with an invalid asset type for the function. Valid
  /// types are defined under CapitalAssetType
  error InvalidAssetType(CapitalAssetType);

  /**
   * @notice Account for a deposit of `id` for the ERC721 asset at `assetAddress`.
   * @dev reverts with InvalidAssetType if `assetAddress` is not an ERC721
   * @param owner address that owns the position
   * @param assetAddress address of the ERC20 address
   * @param assetTokenId id of the ERC721 asset to add
   * @return id of the newly created position
   */
  function depositERC721(
    address owner,
    address assetAddress,
    uint256 assetTokenId
  ) external returns (uint256);

  /**
   * @notice Get the id of the ERC721 asset held by position `id`. Pair this with
   *  `assetAddressOf` to get the address & id of the nft.
   * @dev reverts with InvalidAssetType if `assetAddress` is not an ERC721
   * @param positionId id of the position
   * @return id of the underlying ERC721 asset
   */
  function erc721IdOf(uint256 positionId) external view returns (uint256);

  /**
   * @notice Completely withdraw a position
   * @param positionId id of the position
   */
  function withdraw(uint256 positionId) external;

  /**
   * @notice Harvests the associated rewards, interest, and other accrued assets
   *  associated with the asset token. For example, if given a PoolToken asset,
   *  this will collect the GFI rewards (if available), redeemable interest, and
   *  redeemable principal, and send that to the `owner`.
   * @param positionId id of the position
   */
  function harvest(uint256 positionId) external;

  /**
   * @notice Get the asset address of the position. Example: For an ERC721 position, this
   *  returns the address of that ERC721 contract.
   * @param positionId id of the position
   * @return asset address of the position
   */
  function assetAddressOf(uint256 positionId) external view returns (address);

  /**
   * @notice Get the owner of a given position.
   * @param positionId id of the position
   * @return owner of the position
   */
  function ownerOf(uint256 positionId) external view returns (address);

  /**
   * @notice Total number of positions in the ledger
   * @return number of positions in the ledger
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Get the number of capital positions held by an address
   * @param addr address
   * @return positions held by address
   */
  function balanceOf(address addr) external view returns (uint256);

  /**
   * @notice Returns a position ID owned by `owner` at a given `index` of its position list
   * @param owner owner of the positions
   * @param index index of the owner's balance to get the position ID of
   * @return position id
   *
   * @dev use with {balanceOf} to enumerate all of `owner`'s positions
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /**
   * @dev Returns a position ID at a given `index` of all the positions stored by the contract.
   * @param index index to get the position ID at
   * @return position id
   *
   * @dev use with {totalSupply} to enumerate all positions
   */
  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
   * @notice Get the USDC value of `owner`s positions, reporting what is currently
   *  eligible and the total amount.
   * @param owner address owning the positions
   * @return eligibleAmount USDC value of positions eligible for rewards
   * @return totalAmount total USDC value of positions
   *
   * @dev this is used by Membership to determine how much is eligible in
   *  the current epoch vs the next epoch.
   */
  function totalsOf(
    address owner
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ICreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IERC20Splitter {
  function lastDistributionAt() external view returns (uint256);

  function distribute() external;

  function replacePayees(address[] calldata _payees, uint256[] calldata _shares) external;

  function pendingDistributionFor(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IGFILedger {
  struct Position {
    // Owner of the position
    address owner;
    // Index of the position in the ownership array
    uint256 ownedIndex;
    // Amount of GFI held in the position
    uint256 amount;
    // When the position was deposited
    uint256 depositTimestamp;
  }

  /**
   * @notice Emitted when a new GFI deposit has been made
   * @param owner address owning the deposit
   * @param positionId id for the deposit
   * @param amount how much GFI was deposited
   */
  event GFIDeposit(address indexed owner, uint256 indexed positionId, uint256 amount);

  /**
   * @notice Emitted when a new GFI withdrawal has been made. If the remaining amount is 0, the position has bee removed
   * @param owner address owning the withdrawn position
   * @param positionId id for the position
   * @param remainingAmount how much GFI is remaining in the position
   * @param depositTimestamp block.timestamp of the original deposit
   */
  event GFIWithdrawal(
    address indexed owner,
    uint256 indexed positionId,
    uint256 withdrawnAmount,
    uint256 remainingAmount,
    uint256 depositTimestamp
  );

  /**
   * @notice Account for a new deposit by the owner.
   * @param owner address to account for the deposit
   * @param amount how much was deposited
   * @return how much was deposited
   */
  function deposit(address owner, uint256 amount) external returns (uint256);

  /**
   * @notice Account for a new withdraw by the owner.
   * @param positionId id of the position
   * @return how much was withdrawn
   */
  function withdraw(uint256 positionId) external returns (uint256);

  /**
   * @notice Account for a new withdraw by the owner.
   * @param positionId id of the position
   * @param amount how much to withdraw
   * @return how much was withdrawn
   */
  function withdraw(uint256 positionId, uint256 amount) external returns (uint256);

  /**
   * @notice Get the number of GFI positions held by an address
   * @param addr address
   * @return positions held by address
   */
  function balanceOf(address addr) external view returns (uint256);

  /**
   * @notice Get the owner of a given position.
   * @param positionId id of the position
   * @return owner of the position
   */
  function ownerOf(uint256 positionId) external view returns (address);

  /**
   * @notice Total number of positions in the ledger
   * @return number of positions in the ledger
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Returns a position ID owned by `owner` at a given `index` of its position list
   * @param owner owner of the positions
   * @param index index of the owner's balance to get the position ID of
   * @return position id
   *
   * @dev use with {balanceOf} to enumerate all of `owner`'s positions
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /**
   * @dev Returns a position ID at a given `index` of all the positions stored by the contract.
   * @param index index to get the position ID at
   * @return token id
   *
   * @dev use with {totalSupply} to enumerate all positions
   */
  function tokenByIndex(uint256 index) external view returns (uint256);

  /**
   * @notice Get amount of GFI of `owner`s positions, reporting what is currently
   *  eligible and the total amount.
   * @return eligibleAmount GFI amount of positions eligible for rewards
   * @return totalAmount total GFI amount of positions
   *
   * @dev this is used by Membership to determine how much is eligible in
   *  the current epoch vs the next epoch.
   */
  function totalsOf(
    address owner
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

abstract contract IGo {
  uint256 public constant ID_TYPE_0 = 0;
  uint256 public constant ID_TYPE_1 = 1;
  uint256 public constant ID_TYPE_2 = 2;
  uint256 public constant ID_TYPE_3 = 3;
  uint256 public constant ID_TYPE_4 = 4;
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  /// @notice Returns the address of the UniqueIdentity contract.
  function uniqueIdentity() external virtual returns (address);

  function go(address account) public view virtual returns (bool);

  function goOnlyIdTypes(
    address account,
    uint256[] calldata onlyIdTypes
  ) public view virtual returns (bool);

  /**
   * @notice Returns whether the provided account is go-listed for use of the SeniorPool on the Goldfinch protocol.
   * @param account The account whose go status to obtain
   * @return true if `account` is go listed
   */
  function goSeniorPool(address account) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IMembershipCollector {
  /// @notice Have the collector distribute `amount` of Fidu to `addr`
  /// @param addr address to distribute to
  /// @param amount amount to distribute
  function distributeFiduTo(address addr, uint256 amount) external;

  /// @notice Get the last epoch finalized by the collector. This means the
  ///  collector will no longer add rewards to the epoch.
  /// @return the last finalized epoch
  function lastFinalizedEpoch() external view returns (uint256);

  /// @notice Get the rewards associated with `epoch`. This amount may change
  ///  until `epoch` has been finalized (is less than or equal to getLastFinalizedEpoch)
  /// @return rewards associated with `epoch`
  function rewardsForEpoch(uint256 epoch) external view returns (uint256);

  /// @notice Estimate rewards for a given epoch. For epochs at or before lastFinalizedEpoch
  ///  this will be the fixed, accurate reward for the epoch. For the current and other
  ///  non-finalized epochs, this will be the value as if the epoch were finalized in that
  ///  moment.
  /// @param epoch epoch to estimate the rewards of
  /// @return rewards associated with `epoch`
  function estimateRewardsFor(uint256 epoch) external view returns (uint256);

  /// @notice Finalize all unfinalized epochs. Causes the reserve splitter to distribute
  ///  if there are unfinalized epochs so all possible rewards are distributed.
  function finalizeEpochs() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IMembershipDirector {
  /**
   * @notice Adjust an `owner`s membership score and position due to the change
   *  in their GFI and Capital holdings
   * @param owner address who's holdings changed
   * @return id of membership position
   */
  function consumeHoldingsAdjustment(address owner) external returns (uint256);

  /**
   * @notice Collect all membership yield enhancements for the owner.
   * @param owner address to claim rewards for
   * @return amount of yield enhancements collected
   */
  function collectRewards(address owner) external returns (uint256);

  /**
   * @notice Check how many rewards are claimable for the owner. The return
   *  value here is how much would be retrieved by calling `collectRewards`.
   * @param owner address to calculate claimable rewards for
   * @return the amount of rewards that could be claimed by the owner
   */
  function claimableRewards(address owner) external view returns (uint256);

  /**
   * @notice Calculate the membership score
   * @param gfi Amount of gfi
   * @param capital Amount of capital in USDC
   * @return membership score
   */
  function calculateMembershipScore(uint256 gfi, uint256 capital) external view returns (uint256);

  /**
   * @notice Get the current score of `owner`
   * @param owner address to check the score of
   * @return eligibleScore score that is currently eligible for rewards
   * @return totalScore score that will be elgible for rewards next epoch
   */
  function currentScore(
    address owner
  ) external view returns (uint256 eligibleScore, uint256 totalScore);

  /**
   * @notice Get the sum of all member scores that are currently eligible and that will be eligible next epoch
   * @return eligibleTotal sum of all member scores that are currently eligible
   * @return nextEpochTotal sum of all member scores that will be eligible next epoch
   */
  function totalMemberScores()
    external
    view
    returns (uint256 eligibleTotal, uint256 nextEpochTotal);

  /**
   * @notice Estimate the score for an existing member, given some changes in GFI and capital
   * @param memberAddress the member's address
   * @param gfi the change in gfi holdings, denominated in GFI
   * @param capital the change in gfi holdings, denominated in USDC
   * @return score resulting score for the member given the GFI and capital changes
   */
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score);

  /// @notice Finalize all unfinalized epochs. Causes the reserve splitter to distribute
  ///  if there are unfinalized epochs so all possible rewards are distributed.
  function finalizeEpochs() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IMembershipLedger {
  /**
   * @notice Set `addr`s allocated rewards back to 0
   * @param addr address to reset rewards on
   */
  function resetRewards(address addr) external;

  /**
   * @notice Allocate `amount` rewards for `addr` but do not send them
   * @param addr address to distribute rewards to
   * @param amount amount of rewards to allocate for `addr`
   * @return rewards total allocated to `addr`
   */
  function allocateRewardsTo(address addr, uint256 amount) external returns (uint256 rewards);

  /**
   * @notice Get the rewards allocated to a certain `addr`
   * @param addr the address to check pending rewards for
   * @return rewards pending rewards for `addr`
   */
  function getPendingRewardsFor(address addr) external view returns (uint256 rewards);

  /**
   * @notice Get the alpha parameter for the cobb douglas function. Will always be in (0,1).
   * @return numerator numerator for the alpha param
   * @return denominator denominator for the alpha param
   */
  function alpha() external view returns (uint128 numerator, uint128 denominator);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import {Context} from "../cake/Context.sol";

struct CapitalDeposit {
  /// Address of the asset being deposited
  /// @dev must be supported in CapitalAssets.sol
  address assetAddress;
  /// Id of the nft
  uint256 id;
}

struct Deposit {
  /// Amount of gfi to deposit
  uint256 gfi;
  /// List of capital deposits
  CapitalDeposit[] capitalDeposits;
}

struct DepositResult {
  uint256 membershipId;
  uint256 gfiPositionId;
  uint256[] capitalPositionIds;
}

struct ERC20Withdrawal {
  uint256 id;
  uint256 amount;
}

struct Withdrawal {
  /// List of gfi token ids to withdraw
  ERC20Withdrawal[] gfiPositions;
  /// List of capital token ids to withdraw
  uint256[] capitalPositions;
}

/**
 * @title MembershipOrchestrator
 * @notice Externally facing gateway to all Goldfinch membership functionality.
 * @author Goldfinch
 */
interface IMembershipOrchestrator {
  /**
   * @notice Deposit multiple assets defined in `multiDeposit`. Assets can include GFI, Staked Fidu,
   *  and others.
   * @param deposit struct describing all the assets to deposit
   * @return ids all of the ids of the created depoits, in the same order as deposit. If GFI is
   *  present, it will be the first id.
   */
  function deposit(Deposit calldata deposit) external returns (DepositResult memory);

  /**
   * @notice Withdraw multiple assets defined in `multiWithdraw`. Assets can be GFI or capital
   *  positions ids. Caller must have been permitted to act upon all of the positions.
   * @param withdrawal all of the GFI and Capital ids to withdraw
   */
  function withdraw(Withdrawal calldata withdrawal) external;

  /**
   * @notice Collect all membership rewards for the caller.
   * @return how many rewards were collected and sent to caller
   */
  function collectRewards() external returns (uint256);

  /**
   * @notice Harvest the rewards, interest, redeemable principal, or other assets
   *  associated with the underlying capital asset. For example, if given a PoolToken,
   *  this will collect the GFI rewards (if available), redeemable interest, and
   *  redeemable principal, and send that to the owner of the capital position.
   * @param capitalPositionIds id of the capital position to harvest the underlying asset of
   */
  function harvest(uint256[] calldata capitalPositionIds) external;

  /**
   * @notice Check how many rewards are claimable at this moment in time for caller.
   * @param addr the address to check claimable rewards for
   * @return how many rewards could be claimed by a call to `collectRewards`
   */
  function claimableRewards(address addr) external view returns (uint256);

  /**
   * @notice Check the voting power of a given address
   * @param addr the address to check the voting power of
   * @return the voting power
   */
  function votingPower(address addr) external view returns (uint256);

  /**
   * @notice Get all GFI in Membership held by `addr`. This returns the current eligible amount and the
   *  total amount of GFI.
   * @param addr the owner
   * @return eligibleAmount how much GFI is currently eligible for rewards
   * @return totalAmount how much GFI is currently eligible for rewards
   */
  function totalGFIHeldBy(
    address addr
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount);

  /**
   * @notice Get all capital, denominated in USDC, in Membership held by `addr`. This returns the current
   *  eligible amount and the total USDC value of capital.
   * @param addr the owner
   * @return eligibleAmount how much USDC of capital is currently eligible for rewards
   * @return totalAmount how much  USDC of capital is currently eligible for rewards
   */
  function totalCapitalHeldBy(
    address addr
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount);

  /**
   * @notice Get the member score of `addr`
   * @param addr the owner
   * @return eligibleScore the currently eligible score
   * @return totalScore the total score that will be eligible next epoch
   *
   * @dev if eligibleScore == totalScore then there are no changes between now and the next epoch
   */
  function memberScoreOf(
    address addr
  ) external view returns (uint256 eligibleScore, uint256 totalScore);

  /**
   * @notice Estimate rewards for a given epoch. For epochs at or before lastFinalizedEpoch
   *  this will be the fixed, accurate reward for the epoch. For the current and other
   *  non-finalized epochs, this will be the value as if the epoch were finalized in that
   *  moment.
   * @param epoch epoch to estimate the rewards of
   * @return rewards associated with `epoch`
   */
  function estimateRewardsFor(uint256 epoch) external view returns (uint256);

  /**
   * @notice Calculate what the Membership Score would be if a `gfi` amount of GFI and `capital` amount
   *  of Capital denominated in USDC were deposited.
   * @param gfi amount of GFI to estimate with
   * @param capital amount of capital to estimate with, denominated in USDC
   * @return score the resulting score
   */
  function calculateMemberScore(uint256 gfi, uint256 capital) external view returns (uint256 score);

  /**
   * @notice Get the sum of all member scores that are currently eligible and that will be eligible next epoch
   * @return eligibleTotal sum of all member scores that are currently eligible
   * @return nextEpochTotal sum of all member scores that will be eligible next epoch
   */
  function totalMemberScores()
    external
    view
    returns (uint256 eligibleTotal, uint256 nextEpochTotal);

  /**
   * @notice Estimate the score for an existing member, given some changes in GFI and capital
   * @param memberAddress the member's address
   * @param gfi the change in gfi holdings, denominated in GFI
   * @param capital the change in gfi holdings, denominated in USDC
   * @return score resulting score for the member given the GFI and capital changes
   */
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score);

  /// @notice Finalize all unfinalized epochs. Causes the reserve splitter to distribute
  ///  if there are unfinalized epochs so all possible rewards are distributed.
  function finalizeEpochs() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

struct Position {
  // address owning the position
  address owner;
  // how much of the position is eligible as of checkpointEpoch
  uint256 eligibleAmount;
  // how much of the postion is eligible the epoch after checkpointEpoch
  uint256 nextEpochAmount;
  // when the position was first created
  uint256 createdTimestamp;
  // epoch of the last checkpoint
  uint256 checkpointEpoch;
}

/**
 * @title IMembershipVault
 * @notice Track assets held by owners in a vault, as well as the total held in the vault. Assets
 *  are not accounted for until the next epoch for MEV protection.
 * @author Goldfinch
 */
interface IMembershipVault is IERC721Upgradeable {
  /**
   * @notice Emitted when an owner has adjusted their holdings in a vault
   * @param owner the owner increasing their holdings
   * @param eligibleAmount the new eligible amount
   * @param nextEpochAmount the new next epoch amount
   */
  event AdjustedHoldings(address indexed owner, uint256 eligibleAmount, uint256 nextEpochAmount);

  /**
   * @notice Emitted when the total within the vault has changed
   * @param eligibleAmount new current amount
   * @param nextEpochAmount new next epoch amount
   */
  event VaultTotalUpdate(uint256 eligibleAmount, uint256 nextEpochAmount);

  /**
   * @notice Get the current value of `owner`. This changes depending on the current
   *  block.timestamp as increased holdings are not accounted for until the subsequent epoch.
   * @param owner address owning the positions
   * @return sum of all positions held by an address
   */
  function currentValueOwnedBy(address owner) external view returns (uint256);

  /**
   * @notice Get the total value in the vault as of block.timestamp
   * @return total value in the vault as of block.timestamp
   */
  function currentTotal() external view returns (uint256);

  /**
   * @notice Get the total value in the vault as of epoch
   * @return total value in the vault as of epoch
   */
  function totalAtEpoch(uint256 epoch) external view returns (uint256);

  /**
   * @notice Get the position owned by `owner`
   * @return position owned by `owner`
   */
  function positionOwnedBy(address owner) external view returns (Position memory);

  /**
   * @notice Record an adjustment in holdings. Eligible assets will update this epoch and
   *  total assets will become eligible the subsequent epoch.
   * @param owner the owner to checkpoint
   * @param eligibleAmount amount of points to apply to the current epoch
   * @param nextEpochAmount amount of points to apply to the next epoch
   * @return id of the position
   */
  function adjustHoldings(
    address owner,
    uint256 eligibleAmount,
    uint256 nextEpochAmount
  ) external returns (uint256);

  /**
   * @notice Checkpoint a specific owner & the vault total
   * @param owner the owner to checkpoint
   *
   * @dev to collect rewards, this must be called before `increaseHoldings` or
   *  `decreaseHoldings`. Those functions must call checkpoint internally
   *  so the historical data will be lost otherwise.
   */
  function checkpoint(address owner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./openzeppelin/IERC721.sol";

interface IPoolTokens is IERC721 {
  struct TokenInfo {
    address pool;
    uint256 tranche;
    uint256 principalAmount;
    uint256 principalRedeemed;
    uint256 interestRedeemed;
  }

  struct MintParams {
    uint256 principalAmount;
    uint256 tranche;
  }

  struct PoolInfo {
    uint256 totalMinted;
    uint256 totalPrincipalRedeemed;
    bool created;
  }

  /**
   * @notice Called by pool to create a debt position in a particular tranche and amount
   * @param params Struct containing the tranche and the amount
   * @param to The address that should own the position
   * @return tokenId The token ID (auto-incrementing integer across all pools)
   */
  function mint(MintParams calldata params, address to) external returns (uint256);

  /**
   * @notice Redeem principal and interest on a pool token. Called by valid pools as part of their redemption
   *  flow
   * @param tokenId pool token id
   * @param principalRedeemed principal to redeem. This cannot exceed the token's principal amount, and
   *  the redemption cannot cause the pool's total principal redeemed to exceed the pool's total minted
   *  principal
   * @param interestRedeemed interest to redeem.
   */
  function redeem(uint256 tokenId, uint256 principalRedeemed, uint256 interestRedeemed) external;

  /**
   * @notice Withdraw a pool token's principal up to the token's principalAmount. Called by valid pools
   *  as part of their withdraw flow before the pool is locked (i.e. before the principal is committed)
   * @param tokenId pool token id
   * @param principalAmount principal to withdraw
   */
  function withdrawPrincipal(uint256 tokenId, uint256 principalAmount) external;

  /**
   * @notice Burns a specific ERC721 token and removes deletes the token metadata for PoolTokens, BackerReards,
   *  and BackerStakingRewards
   * @param tokenId uint256 id of the ERC721 token to be burned.
   */
  function burn(uint256 tokenId) external;

  /**
   * @notice Called by the GoldfinchFactory to register the pool as a valid pool. Only valid pools can mint/redeem
   * tokens
   * @param newPool The address of the newly created pool
   */
  function onPoolCreated(address newPool) external;

  function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory);

  function getPoolInfo(address pool) external view returns (PoolInfo memory);

  /// @notice Query if `pool` is a valid pool. A pool is valid if it was created by the Goldfinch Factory
  function validPool(address pool) external view returns (bool);

  function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

  /**
   * @notice Splits a pool token into two smaller positions. The original token is burned and all
   * its associated data is deleted.
   * @param tokenId id of the token to split.
   * @param newPrincipal1 principal amount for the first token in the split. The principal amount for the
   *  second token in the split is implicitly the original token's principal amount less newPrincipal1
   * @return tokenId1 id of the first token in the split
   * @return tokenId2 id of the second token in the split
   */
  function splitToken(
    uint256 tokenId,
    uint256 newPrincipal1
  ) external returns (uint256 tokenId1, uint256 tokenId2);

  /**
   * @notice Mint event emitted for a new TranchedPool deposit or when an existing pool token is
   *  split
   * @param owner address to which the token was minted
   * @param pool tranched pool that the deposit was in
   * @param tokenId ERC721 tokenId
   * @param amount the deposit amount
   * @param tranche id of the tranche of the deposit
   */
  event TokenMinted(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 tranche
  );

  /**
   * @notice Redeem event emitted when interest and/or principal is redeemed in the token's pool
   * @param owner owner of the pool token
   * @param pool tranched pool that the token belongs to
   * @param principalRedeemed amount of principal redeemed from the pool
   * @param interestRedeemed amount of interest redeemed from the pool
   * @param tranche id of the tranche the token belongs to
   */
  event TokenRedeemed(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    uint256 tranche
  );

  /**
   * @notice Burn event emitted when the token owner/operator manually burns the token or burns
   *  it implicitly by splitting it
   * @param owner owner of the pool token
   * @param pool tranched pool that the token belongs to
   */
  event TokenBurned(address indexed owner, address indexed pool, uint256 indexed tokenId);

  /**
   * @notice Split event emitted when the token owner/operator splits the token
   * @param pool tranched pool to which the orginal and split tokens belong
   * @param tokenId id of the original token that was split
   * @param newTokenId1 id of the first split token
   * @param newPrincipal1 principalAmount of the first split token
   * @param newTokenId2 id of the second split token
   * @param newPrincipal2 principalAmount of the second split token
   */
  event TokenSplit(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 newTokenId1,
    uint256 newPrincipal1,
    uint256 newTokenId2,
    uint256 newPrincipal2
  );

  /**
   * @notice Principal Withdrawn event emitted when a token's principal is withdrawn from the pool
   *  BEFORE the pool's drawdown period
   * @param pool tranched pool of the token
   * @param principalWithdrawn amount of principal withdrawn from the pool
   */
  event TokenPrincipalWithdrawn(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalWithdrawn,
    uint256 tranche
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title IRouter
/// @author landakram
/// @notice This contract provides service discovery for contracts using the cake framework.
///   It can be used in conjunction with the convenience methods defined in the `Routing.Context`
///   and `Routing.Keys` libraries.
interface IRouter {
  event SetContract(bytes4 indexed key, address indexed addr);

  /// @notice Associate a routing key to a contract address
  /// @dev This function is only callable by the Router admin
  /// @param key A routing key (defined in the `Routing.Keys` libary)
  /// @param addr A contract address
  function setContract(bytes4 key, address addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ITranchedPool} from "./ITranchedPool.sol";
import {ISeniorPoolEpochWithdrawals} from "./ISeniorPoolEpochWithdrawals.sol";

abstract contract ISeniorPool is ISeniorPoolEpochWithdrawals {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  /**
   * @notice Withdraw `usdcAmount` of USDC, bypassing the epoch withdrawal system. Callable
   * by Zapper only.
   */
  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  /**
   * @notice Withdraw `fiduAmount` of FIDU converted to USDC at the current share price,
   * bypassing the epoch withdrawal system. Callable by Zapper only
   */
  function withdrawInFidu(uint256 fiduAmount) external virtual returns (uint256 amount);

  function invest(ITranchedPool pool) external virtual returns (uint256);

  function estimateInvestment(ITranchedPool pool) external view virtual returns (uint256);

  function redeem(uint256 tokenId) external virtual;

  function writedown(uint256 tokenId) external virtual;

  function calculateWritedown(
    uint256 tokenId
  ) external view virtual returns (uint256 writedownAmount);

  function sharesOutstanding() external view virtual returns (uint256);

  function assets() external view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);

  event DepositMade(address indexed capitalProvider, uint256 amount, uint256 shares);
  event WithdrawalMade(address indexed capitalProvider, uint256 userAmount, uint256 reserveAmount);
  event InterestCollected(address indexed payer, uint256 amount);
  event PrincipalCollected(address indexed payer, uint256 amount);
  event ReserveFundsCollected(address indexed user, uint256 amount);
  event ReserveSharesCollected(address indexed user, address indexed reserve, uint256 amount);

  event PrincipalWrittenDown(address indexed tranchedPool, int256 amount);
  event InvestmentMadeInSenior(address indexed tranchedPool, uint256 amount);
  event InvestmentMadeInJunior(address indexed tranchedPool, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

interface ISeniorPoolEpochWithdrawals {
  /**
   * @notice A withdrawal epoch
   * @param endsAt timestamp the epoch ends
   * @param fiduRequested amount of fidu requested in the epoch, including fidu
   *                      carried over from previous epochs
   * @param fiduLiquidated Amount of fidu that was liquidated at the end of this epoch
   * @param usdcAllocated Amount of usdc that was allocated to liquidate fidu.
   *                      Does not consider withdrawal fees.
   */
  struct Epoch {
    uint256 endsAt;
    uint256 fiduRequested;
    uint256 fiduLiquidated;
    uint256 usdcAllocated;
  }

  /**
   * @notice A user's request for withdrawal
   * @param epochCursor id of next epoch the user can liquidate their request
   * @param fiduRequested amount of fidu left to liquidate since last checkpoint
   * @param usdcWithdrawable amount of usdc available for a user to withdraw
   */
  struct WithdrawalRequest {
    uint256 epochCursor;
    uint256 usdcWithdrawable;
    uint256 fiduRequested;
  }

  /**
   * @notice Returns the amount of unallocated usdc in the senior pool, taking into account
   *         usdc that _will_ be allocated to withdrawals when a checkpoint happens
   */
  function usdcAvailable() external view returns (uint256);

  /// @notice Current duration of withdrawal epochs, in seconds
  function epochDuration() external view returns (uint256);

  /// @notice Update epoch duration
  function setEpochDuration(uint256 newEpochDuration) external;

  /// @notice The current withdrawal epoch
  function currentEpoch() external view returns (Epoch memory);

  /// @notice Get request by tokenId. A request is considered active if epochCursor > 0.
  function withdrawalRequest(uint256 tokenId) external view returns (WithdrawalRequest memory);

  /**
   * @notice Submit a request to withdraw `fiduAmount` of FIDU. Request is rejected
   * if caller already owns a request token. A non-transferrable request token is
   * minted to the caller
   * @return tokenId token minted to caller
   */
  function requestWithdrawal(uint256 fiduAmount) external returns (uint256 tokenId);

  /**
   * @notice Add `fiduAmount` FIDU to a withdrawal request for `tokenId`. Caller
   * must own tokenId
   */
  function addToWithdrawalRequest(uint256 fiduAmount, uint256 tokenId) external;

  /**
   * @notice Cancel request for tokenId. The fiduRequested (minus a fee) is returned
   * to the caller. Caller must own tokenId.
   * @return fiduReceived the fidu amount returned to the caller
   */
  function cancelWithdrawalRequest(uint256 tokenId) external returns (uint256 fiduReceived);

  /**
   * @notice Transfer the usdcWithdrawable of request for tokenId to the caller.
   * Caller must own tokenId
   */
  function claimWithdrawalRequest(uint256 tokenId) external returns (uint256 usdcReceived);

  /// @notice Emitted when the epoch duration is changed
  event EpochDurationChanged(uint256 newDuration);

  /// @notice Emitted when a new withdraw request has been created
  event WithdrawalRequested(
    uint256 indexed epochId,
    uint256 indexed tokenId,
    address indexed operator,
    uint256 fiduRequested
  );

  /// @notice Emitted when a user adds to their existing withdraw request
  /// @param epochId epoch that the withdraw was added to
  /// @param tokenId id of token that represents the position being added to
  /// @param operator address that added to the request
  /// @param fiduRequested amount of additional fidu added to request
  event WithdrawalAddedTo(
    uint256 indexed epochId,
    uint256 indexed tokenId,
    address indexed operator,
    uint256 fiduRequested
  );

  /// @notice Emitted when a withdraw request has been canceled
  event WithdrawalCanceled(
    uint256 indexed epochId,
    uint256 indexed tokenId,
    address indexed operator,
    uint256 fiduCanceled,
    uint256 reserveFidu
  );

  /// @notice Emitted when an epoch has been checkpointed
  /// @param epochId id of epoch that ended
  /// @param endTime timestamp the epoch ended
  /// @param fiduRequested amount of FIDU oustanding when the epoch ended
  /// @param usdcAllocated amount of USDC allocated to liquidate FIDU
  /// @param fiduLiquidated amount of FIDU liquidated using `usdcAllocated`
  event EpochEnded(
    uint256 indexed epochId,
    uint256 endTime,
    uint256 fiduRequested,
    uint256 usdcAllocated,
    uint256 fiduLiquidated
  );

  /// @notice Emitted when an epoch could not be finalized and is extended instead
  /// @param epochId id of epoch that was extended
  /// @param newEndTime new epoch end time
  /// @param oldEndTime previous epoch end time
  event EpochExtended(uint256 indexed epochId, uint256 newEndTime, uint256 oldEndTime);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {IERC721} from "./openzeppelin/IERC721.sol";
import {IERC721Metadata} from "./openzeppelin/IERC721Metadata.sol";
import {IERC721Enumerable} from "./openzeppelin/IERC721Enumerable.sol";

interface IStakingRewards is IERC721, IERC721Metadata, IERC721Enumerable {
  /// @notice Get the staking rewards position
  /// @param tokenId id of the position token
  /// @return position the position
  function getPosition(uint256 tokenId) external view returns (StakedPosition memory position);

  /// @notice Unstake an amount of `stakingToken()` (FIDU, FiduUSDCCurveLP, etc) associated with
  ///   a given position and transfer to msg.sender. Any remaining staked amount will continue to
  ///   accrue rewards.
  /// @dev This function checkpoints rewards
  /// @param tokenId A staking position token ID
  /// @param amount Amount of `stakingToken()` to be unstaked from the position
  function unstake(uint256 tokenId, uint256 amount) external;

  /// @notice Add `amount` to an existing FIDU position (`tokenId`)
  /// @param tokenId A staking position token ID
  /// @param amount Amount of `stakingToken()` to be added to tokenId's position
  function addToStake(uint256 tokenId, uint256 amount) external;

  /// @notice Returns the staked balance of a given position token.
  /// @dev The value returned is the bare amount, not the effective amount. The bare amount represents
  ///   the number of tokens the user has staked for a given position. The effective amount is the bare
  ///   amount multiplied by the token's underlying asset type multiplier. This multiplier is a crypto-
  ///   economic parameter determined by governance.
  /// @param tokenId A staking position token ID
  /// @return Amount of staked tokens denominated in `stakingToken().decimals()`
  function stakedBalanceOf(uint256 tokenId) external view returns (uint256);

  /// @notice Deposit to FIDU and USDC into the Curve LP, and stake your Curve LP tokens in the same transaction.
  /// @param fiduAmount The amount of FIDU to deposit
  /// @param usdcAmount The amount of USDC to deposit
  function depositToCurveAndStakeFrom(
    address nftRecipient,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) external;

  /// @notice "Kick" a user's reward multiplier. If they are past their lock-up period, their reward
  ///   multiplier will be reset to 1x.
  /// @dev This will also checkpoint their rewards up to the current time.
  function kick(uint256 tokenId) external;

  /// @notice Accumulated rewards per token at the last checkpoint
  function accumulatedRewardsPerToken() external view returns (uint256);

  /// @notice The block timestamp when rewards were last checkpointed
  function lastUpdateTime() external view returns (uint256);

  /// @notice Claim rewards for a given staked position
  /// @param tokenId A staking position token ID
  /// @return amount of rewards claimed
  function getReward(uint256 tokenId) external returns (uint256);

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    StakedPositionType positionType,
    uint256 baseTokenExchangeRate
  );
  event DepositedAndStaked(
    address indexed user,
    uint256 depositedAmount,
    uint256 indexed tokenId,
    uint256 amount
  );
  event DepositedToCurve(
    address indexed user,
    uint256 fiduAmount,
    uint256 usdcAmount,
    uint256 tokensReceived
  );
  event DepositedToCurveAndStaked(
    address indexed user,
    uint256 fiduAmount,
    uint256 usdcAmount,
    uint256 indexed tokenId,
    uint256 amount
  );
  event AddToStake(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    StakedPositionType positionType
  );
  event Unstaked(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    StakedPositionType positionType
  );
  event UnstakedMultiple(address indexed user, uint256[] tokenIds, uint256[] amounts);
  event RewardPaid(address indexed user, uint256 indexed tokenId, uint256 reward);
  event RewardsParametersUpdated(
    address indexed who,
    uint256 targetCapacity,
    uint256 minRate,
    uint256 maxRate,
    uint256 minRateAtPercent,
    uint256 maxRateAtPercent
  );
  event EffectiveMultiplierUpdated(
    address indexed who,
    StakedPositionType positionType,
    uint256 multiplier
  );
}

/// @notice Indicates which ERC20 is staked
enum StakedPositionType {
  Fidu,
  CurveLP
}

struct Rewards {
  uint256 totalUnvested;
  uint256 totalVested;
  // @dev DEPRECATED (definition kept for storage slot)
  //   For legacy vesting positions, this was used in the case of slashing.
  //   For non-vesting positions, this is unused.
  uint256 totalPreviouslyVested;
  uint256 totalClaimed;
  uint256 startTime;
  // @dev DEPRECATED (definition kept for storage slot)
  //   For legacy vesting positions, this is the endTime of the vesting.
  //   For non-vesting positions, this is 0.
  uint256 endTime;
}

struct StakedPosition {
  // @notice Staked amount denominated in `stakingToken().decimals()`
  uint256 amount;
  // @notice Struct describing rewards owed with vesting
  Rewards rewards;
  // @notice Multiplier applied to staked amount when locking up position
  uint256 leverageMultiplier;
  // @notice Time in seconds after which position can be unstaked
  uint256 lockedUntil;
  // @notice Type of the staked position
  StakedPositionType positionType;
  // @notice Multiplier applied to staked amount to denominate in `baseStakingToken().decimals()`
  // @dev This field should not be used directly; it may be 0 for staked positions created prior to GIP-1.
  //  If you need this field, use `safeEffectiveMultiplier()`, which correctly handles old staked positions.
  uint256 unsafeEffectiveMultiplier;
  // @notice Exchange rate applied to staked amount to denominate in `baseStakingToken().decimals()`
  // @dev This field should not be used directly; it may be 0 for staked positions created prior to GIP-1.
  //  If you need this field, use `safeBaseTokenExchangeRate()`, which correctly handles old staked positions.
  uint256 unsafeBaseTokenExchangeRate;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {IV2CreditLine} from "./IV2CreditLine.sol";

abstract contract ITranchedPool {
  IV2CreditLine public creditLine;
  uint256 public createdAt;
  enum Tranches {
    Reserved,
    Senior,
    Junior
  }

  struct TrancheInfo {
    uint256 id;
    uint256 principalDeposited;
    uint256 principalSharePrice;
    uint256 interestSharePrice;
    uint256 lockedUntil;
  }

  struct PoolSlice {
    TrancheInfo seniorTranche;
    TrancheInfo juniorTranche;
    uint256 totalInterestAccrued;
    uint256 principalDeployed;
  }

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public virtual;

  function getAllowedUIDTypes() external view virtual returns (uint256[] memory);

  function getTranche(uint256 tranche) external view virtual returns (TrancheInfo memory);

  function pay(uint256 amount) external virtual;

  function poolSlices(uint256 index) external view virtual returns (PoolSlice memory);

  function lockJuniorCapital() external virtual;

  function lockPool() external virtual;

  function initializeNextSlice(uint256 _fundableAt) external virtual;

  function totalJuniorDeposits() external view virtual returns (uint256);

  function drawdown(uint256 amount) external virtual;

  function setFundableAt(uint256 timestamp) external virtual;

  function deposit(uint256 tranche, uint256 amount) external virtual returns (uint256 tokenId);

  function assess() external virtual;

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 tokenId);

  function availableToWithdraw(
    uint256 tokenId
  ) external view virtual returns (uint256 interestRedeemable, uint256 principalRedeemable);

  function withdraw(
    uint256 tokenId,
    uint256 amount
  ) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMax(
    uint256 tokenId
  ) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMultiple(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external virtual;

  function numSlices() external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ICreditLine} from "./ICreditLine.sol";

abstract contract IV2CreditLine is ICreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess() external virtual returns (uint256, uint256, uint256);

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;
}

pragma solidity >=0.6.0;

// This file copied from OZ, but with the version pragma updated to use >=.

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

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >= & reference other >= pragma interfaces.
// NOTE: Modified to reference our updated pragma version of IERC165
import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of NFTs in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   *
   *
   * Requirements:
   * - `from`, `to` cannot be zero.
   * - `tokenId` must be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this
   * NFT by either {approve} or {setApprovalForAll}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   * Requirements:
   * - If the caller is not `from`, it must be approved to move this NFT by
   * either {approve} or {setApprovalForAll}.
   */
  function transferFrom(address from, address to, uint256 tokenId) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >=.

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
  function totalSupply() external view returns (uint256);

  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) external view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >=.

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library FiduConversions {
  uint256 internal constant FIDU_MANTISSA = 1e18;
  uint256 internal constant USDC_MANTISSA = 1e6;
  uint256 internal constant USDC_TO_FIDU_MANTISSA = FIDU_MANTISSA / USDC_MANTISSA;
  uint256 internal constant FIDU_USDC_CONVERSION_DECIMALS = USDC_TO_FIDU_MANTISSA * FIDU_MANTISSA;

  /**
   * @notice Convert Usdc to Fidu using a given share price
   * @param usdcAmount amount of usdc to convert
   * @param sharePrice share price to use to convert
   * @return fiduAmount converted fidu amount
   */
  function usdcToFidu(uint256 usdcAmount, uint256 sharePrice) internal pure returns (uint256) {
    return sharePrice > 0 ? (usdcAmount * FIDU_USDC_CONVERSION_DECIMALS) / sharePrice : 0;
  }

  /**
   * @notice Convert fidu to USDC using a given share price
   * @param fiduAmount fidu amount to convert
   * @param sharePrice share price to do the conversion with
   * @return usdcReceived usdc that will be received after converting
   */
  function fiduToUsdc(uint256 fiduAmount, uint256 sharePrice) internal pure returns (uint256) {
    return (fiduAmount * sharePrice) / FIDU_USDC_CONVERSION_DECIMALS;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721ReceiverUpgradeable.sol";

import {Base} from "../../cake/Base.sol";
import {PausableUpgradeable} from "../../cake/Pausable.sol";
import {Context} from "../../cake/Context.sol";
import "../../cake/Routing.sol" as Routing;

import {IMembershipDirector} from "../../interfaces/IMembershipDirector.sol";
import "../../interfaces/IMembershipOrchestrator.sol";
import {CapitalAssetType} from "../../interfaces/ICapitalLedger.sol";

import {Epochs} from "./membership/Epochs.sol";
import {MembershipScores} from "./membership/MembershipScores.sol";
import {CapitalAssets} from "./membership/assets/CapitalAssets.sol";

using Routing.Context for Context;
using SafeERC20 for IERC20Upgradeable;

/**
 * @title MembershipOrchestrator
 * @notice Externally facing gateway to all Goldfinch membership functionality.
 * @author Goldfinch
 */
contract MembershipOrchestrator is
  IMembershipOrchestrator,
  Base,
  Initializable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  IERC721ReceiverUpgradeable
{
  /// Thrown when anything is called with an unsupported asset
  error UnsupportedAssetAddress(address addr);
  /// Thrown when calling a method with invalid input
  error RequiresValidInput();
  /// Thrown when operating on an unowned asset
  error CannotOperateOnUnownedAsset(address nonOwner);

  constructor(Context _context) Base(_context) {}

  /// @notice Initialize the contract
  function initialize() external initializer {
    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
  }

  /// @inheritdoc IMembershipOrchestrator
  function deposit(
    Deposit calldata depositData
  ) external nonReentrant whenNotPaused returns (DepositResult memory result) {
    if (depositData.gfi > 0) {
      result.gfiPositionId = _depositGFI(depositData.gfi);
    }

    uint256 numCapitalDeposits = depositData.capitalDeposits.length;

    result.capitalPositionIds = new uint256[](numCapitalDeposits);
    for (uint256 i = 0; i < numCapitalDeposits; i++) {
      CapitalDeposit memory capitalDeposit = depositData.capitalDeposits[i];
      result.capitalPositionIds[i] = _depositCapitalERC721(
        capitalDeposit.assetAddress,
        capitalDeposit.id
      );
    }

    result.membershipId = context.membershipDirector().consumeHoldingsAdjustment(msg.sender);
  }

  /// @inheritdoc IMembershipOrchestrator
  function withdraw(Withdrawal calldata withdrawal) external nonReentrant whenNotPaused {
    // Find the owner that is being withdrawn for. The owner must be the same across all of the
    // positions so the membership vault can be updated.
    address owner = address(0);
    if (withdrawal.gfiPositions.length > 0) {
      owner = context.gfiLedger().ownerOf(withdrawal.gfiPositions[0].id);
    } else if (withdrawal.capitalPositions.length > 0) {
      owner = context.capitalLedger().ownerOf(withdrawal.capitalPositions[0]);
    }

    if (owner == address(0)) revert RequiresValidInput();

    for (uint256 i = 0; i < withdrawal.gfiPositions.length; i++) {
      uint256 positionId = withdrawal.gfiPositions[i].id;
      address positionOwner = context.gfiLedger().ownerOf(positionId);

      if (positionOwner == address(0)) revert CannotOperateOnUnownedAsset(address(0));
      if (positionOwner != owner) revert CannotOperateOnUnownedAsset(positionOwner);

      _withdrawGFI(positionId, withdrawal.gfiPositions[i].amount);
    }

    for (uint256 i = 0; i < withdrawal.capitalPositions.length; i++) {
      uint256 positionId = withdrawal.capitalPositions[i];
      address positionOwner = context.capitalLedger().ownerOf(positionId);

      if (positionOwner == address(0)) revert CannotOperateOnUnownedAsset(address(0));
      if (positionOwner != owner) revert CannotOperateOnUnownedAsset(positionOwner);

      _withdrawCapital(positionId);
    }

    context.membershipDirector().consumeHoldingsAdjustment(owner);
  }

  /// @inheritdoc IMembershipOrchestrator
  function collectRewards() external nonReentrant whenNotPaused returns (uint256) {
    return context.membershipDirector().collectRewards(msg.sender);
  }

  /// @inheritdoc IMembershipOrchestrator
  function harvest(uint256[] calldata capitalPositionIds) external nonReentrant whenNotPaused {
    if (capitalPositionIds.length == 0) revert RequiresValidInput();

    for (uint256 i = 0; i < capitalPositionIds.length; i++) {
      uint256 capitalPositionId = capitalPositionIds[i];

      address owner = context.capitalLedger().ownerOf(capitalPositionId);
      if (owner != msg.sender) revert CannotOperateOnUnownedAsset(msg.sender);

      context.capitalLedger().harvest(capitalPositionId);
    }

    // Consume adjustment to account for possible token principal changes
    // Checkpoints the user's rewards as they may get a new score from the changes
    address owner = context.capitalLedger().ownerOf(capitalPositionIds[0]);
    context.membershipDirector().consumeHoldingsAdjustment(owner);
  }

  /// @inheritdoc IMembershipOrchestrator
  function claimableRewards(address addr) external view returns (uint256) {
    return context.membershipDirector().claimableRewards(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function votingPower(address addr) external view returns (uint256) {
    (, uint256 total) = context.gfiLedger().totalsOf(addr);
    return total;
  }

  /// @inheritdoc IMembershipOrchestrator
  function totalGFIHeldBy(
    address addr
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount) {
    return context.gfiLedger().totalsOf(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function totalCapitalHeldBy(
    address addr
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount) {
    return context.capitalLedger().totalsOf(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function memberScoreOf(
    address addr
  ) external view returns (uint256 eligibleScore, uint256 totalScore) {
    return context.membershipDirector().currentScore(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function estimateRewardsFor(uint256 epoch) external view returns (uint256) {
    return context.membershipCollector().estimateRewardsFor(epoch);
  }

  /// @inheritdoc IMembershipOrchestrator
  function calculateMemberScore(uint256 gfi, uint256 capital) external view returns (uint256) {
    return context.membershipDirector().calculateMembershipScore(gfi, capital);
  }

  function finalizeEpochs() external nonReentrant whenNotPaused {
    return context.membershipDirector().finalizeEpochs();
  }

  /// @inheritdoc IMembershipOrchestrator
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score) {
    return context.membershipDirector().estimateMemberScore(memberAddress, gfi, capital);
  }

  /// @inheritdoc IMembershipOrchestrator
  function totalMemberScores()
    external
    view
    returns (uint256 eligibleTotal, uint256 nextEpochTotal)
  {
    return context.membershipDirector().totalMemberScores();
  }

  /// @inheritdoc IERC721ReceiverUpgradeable
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  //////////////////////////////////////////////////////////////////
  // Private

  function _depositGFI(uint256 amount) private returns (uint256) {
    uint256 balanceBefore = context.gfi().balanceOf(address(this));

    context.gfi().safeTransferFrom(msg.sender, address(this), amount);

    context.gfi().approve(address(context.gfiLedger()), amount);
    uint256 positionId = context.gfiLedger().deposit(msg.sender, amount);

    assert(context.gfi().balanceOf(address(this)) == balanceBefore);

    return positionId;
  }

  function _depositCapitalERC721(address assetAddress, uint256 id) private returns (uint256) {
    if (CapitalAssets.getSupportedType(context, assetAddress) == CapitalAssetType.INVALID) {
      revert UnsupportedAssetAddress(assetAddress);
    }

    IERC721Upgradeable asset = IERC721Upgradeable(assetAddress);

    asset.safeTransferFrom(msg.sender, address(this), id);

    asset.approve(address(context.capitalLedger()), id);
    uint256 positionId = context.capitalLedger().depositERC721(msg.sender, assetAddress, id);

    assert(asset.ownerOf(id) != address(this));

    return positionId;
  }

  function _withdrawGFI(uint256 positionId) private returns (uint256) {
    if (context.gfiLedger().ownerOf(positionId) != msg.sender) {
      revert CannotOperateOnUnownedAsset(msg.sender);
    }

    return context.gfiLedger().withdraw(positionId);
  }

  function _withdrawGFI(uint256 positionId, uint256 amount) private returns (uint256) {
    if (context.gfiLedger().ownerOf(positionId) != msg.sender) {
      revert CannotOperateOnUnownedAsset(msg.sender);
    }

    return context.gfiLedger().withdraw(positionId, amount);
  }

  function _withdrawCapital(uint256 positionId) private {
    if (context.capitalLedger().ownerOf(positionId) != msg.sender) {
      revert CannotOperateOnUnownedAsset(msg.sender);
    }

    context.capitalLedger().withdraw(positionId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library Epochs {
  uint256 internal constant EPOCH_SECONDS = 7 days;

  /**
   * @notice Get the epoch containing the timestamp `s`
   * @param s the timestamp
   * @return corresponding epoch
   */
  function fromSeconds(uint256 s) internal pure returns (uint256) {
    return s / EPOCH_SECONDS;
  }

  /**
   * @notice Get the current epoch for the block.timestamp
   * @return current epoch
   */
  function current() internal view returns (uint256) {
    return fromSeconds(block.timestamp);
  }

  /**
   * @notice Get the start timestamp for the current epoch
   * @return current epoch start timestamp
   */
  function currentEpochStartTimestamp() internal view returns (uint256) {
    return startOf(current());
  }

  /**
   * @notice Get the previous epoch given block.timestamp
   * @return previous epoch
   */
  function previous() internal view returns (uint256) {
    return current() - 1;
  }

  /**
   * @notice Get the next epoch given block.timestamp
   * @return next epoch
   */
  function next() internal view returns (uint256) {
    return current() + 1;
  }

  /**
   * @notice Get the Unix timestamp of the start of `epoch`
   * @param epoch the epoch
   * @return unix timestamp
   */
  function startOf(uint256 epoch) internal pure returns (uint256) {
    return epoch * EPOCH_SECONDS;
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable max-line-length

pragma solidity ^0.8.16;

// Below is code from 0x's LibFixedMath.sol. Changes:
// - addition of 0.8-style errors
// - removal of unused functions
// - added comments for clarity
// https://github.com/0xProject/exchange-v3/blob/aae46bef841bfd1cc31028f41793db4fe7197084/contracts/staking/contracts/src/libs/LibFixedMath.sol

/*

  Copyright 2017 Bprotocol Foundation, 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

library FixedMath0x {
  /// Thrown when the natural log function is given too large of an argument
  error LnTooLarge(int256 x);
  /// Thrown when the natural log would have returned a number outside of ℝ
  error LnNonRealResult(int256 x);
  /// Thrown when exp is given too large of an argument
  error ExpTooLarge(int256 x);
  /// Thrown when an unsigned value is too large to be converted to a signed value
  error UnsignedValueTooLarge(uint256 x);

  // Base for the fixed point numbers (this is our 1)
  int256 internal constant FIXED_1 =
    int256(0x0000000000000000000000000000000080000000000000000000000000000000);
  // Maximum ln argument (1)
  int256 private constant LN_MAX_VAL = FIXED_1;
  // Minimum ln argument. Notice this is related to EXP_MIN_VAL (e ^ -63.875)
  int256 private constant LN_MIN_VAL =
    int256(0x0000000000000000000000000000000000000000000000000000000733048c5a);
  // Maximum exp argument (0)
  int256 private constant EXP_MAX_VAL = 0;
  // Minimum exp argument. Notice this is related to LN_MIN_VAL (-63.875)
  int256 private constant EXP_MIN_VAL =
    -int256(0x0000000000000000000000000000001ff0000000000000000000000000000000);

  /// @dev Get the natural logarithm of a fixed-point number 0 < `x` <= LN_MAX_VAL
  function ln(int256 x) internal pure returns (int256 r) {
    if (x > LN_MAX_VAL) {
      revert LnTooLarge(x);
    }
    if (x <= 0) {
      revert LnNonRealResult(x);
    }
    if (x == FIXED_1) {
      return 0;
    }
    if (x <= LN_MIN_VAL) {
      return EXP_MIN_VAL;
    }

    int256 y;
    int256 z;
    int256 w;

    // Rewrite the input as a quotient of negative natural exponents and a single residual q, such that 1 < q < 2
    // For example: log(0.3) = log(e^-1 * e^-0.25 * 1.0471028872385522)
    //              = 1 - 0.25 - log(1 + 0.0471028872385522)
    // e ^ -32
    if (x <= int256(0x00000000000000000000000000000000000000000001c8464f76164760000000)) {
      r -= int256(0x0000000000000000000000000000001000000000000000000000000000000000); // - 32
      x =
        (x * FIXED_1) /
        int256(0x00000000000000000000000000000000000000000001c8464f76164760000000); // / e ^ -32
    }
    // e ^ -16
    if (x <= int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000)) {
      r -= int256(0x0000000000000000000000000000000800000000000000000000000000000000); // - 16
      x =
        (x * FIXED_1) /
        int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000); // / e ^ -16
    }
    // e ^ -8
    if (x <= int256(0x00000000000000000000000000000000000afe10820813d78000000000000000)) {
      r -= int256(0x0000000000000000000000000000000400000000000000000000000000000000); // - 8
      x =
        (x * FIXED_1) /
        int256(0x00000000000000000000000000000000000afe10820813d78000000000000000); // / e ^ -8
    }
    // e ^ -4
    if (x <= int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000)) {
      r -= int256(0x0000000000000000000000000000000200000000000000000000000000000000); // - 4
      x =
        (x * FIXED_1) /
        int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000); // / e ^ -4
    }
    // e ^ -2
    if (x <= int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000)) {
      r -= int256(0x0000000000000000000000000000000100000000000000000000000000000000); // - 2
      x =
        (x * FIXED_1) /
        int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000); // / e ^ -2
    }
    // e ^ -1
    if (x <= int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000)) {
      r -= int256(0x0000000000000000000000000000000080000000000000000000000000000000); // - 1
      x =
        (x * FIXED_1) /
        int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000); // / e ^ -1
    }
    // e ^ -0.5
    if (x <= int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000)) {
      r -= int256(0x0000000000000000000000000000000040000000000000000000000000000000); // - 0.5
      x =
        (x * FIXED_1) /
        int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000); // / e ^ -0.5
    }
    // e ^ -0.25
    if (x <= int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000)) {
      r -= int256(0x0000000000000000000000000000000020000000000000000000000000000000); // - 0.25
      x =
        (x * FIXED_1) /
        int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000); // / e ^ -0.25
    }
    // e ^ -0.125
    if (x <= int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) {
      r -= int256(0x0000000000000000000000000000000010000000000000000000000000000000); // - 0.125
      x =
        (x * FIXED_1) /
        int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d); // / e ^ -0.125
    }
    // `x` is now our residual in the range of 1 <= x <= 2 (or close enough).

    // Add the taylor series for log(1 + z), where z = x - 1
    z = y = x - FIXED_1;
    w = (y * y) / FIXED_1;
    r += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
    z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
    r += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
    z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
    r += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
    z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
    r += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
    z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
    r += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
    z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
    r += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
    z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
    r += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
    z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
    r += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16
  }

  /// @dev Compute the natural exponent for a fixed-point number EXP_MIN_VAL <= `x` <= 1
  function exp(int256 x) internal pure returns (int256 r) {
    if (x < EXP_MIN_VAL) {
      // Saturate to zero below EXP_MIN_VAL.
      return 0;
    }
    if (x == 0) {
      return FIXED_1;
    }
    if (x > EXP_MAX_VAL) {
      revert ExpTooLarge(x);
    }

    // Rewrite the input as a product of natural exponents and a
    // single residual q, where q is a number of small magnitude.
    // For example: e^-34.419 = e^(-32 - 2 - 0.25 - 0.125 - 0.044)
    //              = e^-32 * e^-2 * e^-0.25 * e^-0.125 * e^-0.044
    //              -> q = -0.044

    // Multiply with the taylor series for e^q
    int256 y;
    int256 z;
    // q = x % 0.125 (the residual)
    z = y = x % 0x0000000000000000000000000000000010000000000000000000000000000000;
    z = (z * y) / FIXED_1;
    r += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
    z = (z * y) / FIXED_1;
    r += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
    z = (z * y) / FIXED_1;
    r += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
    z = (z * y) / FIXED_1;
    r += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
    z = (z * y) / FIXED_1;
    r += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
    z = (z * y) / FIXED_1;
    r += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
    z = (z * y) / FIXED_1;
    r += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
    z = (z * y) / FIXED_1;
    r += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
    z = (z * y) / FIXED_1;
    r += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
    z = (z * y) / FIXED_1;
    r += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
    z = (z * y) / FIXED_1;
    r += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
    z = (z * y) / FIXED_1;
    r += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
    z = (z * y) / FIXED_1;
    r += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
    z = (z * y) / FIXED_1;
    r += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
    z = (z * y) / FIXED_1;
    r += z * 0x000000000001c638; // add y^16 * (20! / 16!)
    z = (z * y) / FIXED_1;
    r += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
    z = (z * y) / FIXED_1;
    r += z * 0x000000000000017c; // add y^18 * (20! / 18!)
    z = (z * y) / FIXED_1;
    r += z * 0x0000000000000014; // add y^19 * (20! / 19!)
    z = (z * y) / FIXED_1;
    r += z * 0x0000000000000001; // add y^20 * (20! / 20!)
    r = r / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

    // Multiply with the non-residual terms.
    x = -x;
    // e ^ -32
    if ((x & int256(0x0000000000000000000000000000001000000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x00000000000000000000000000000000000000f1aaddd7742e56d32fb9f99744)) /
        int256(0x0000000000000000000000000043cbaf42a000812488fc5c220ad7b97bf6e99e); // * e ^ -32
    }
    // e ^ -16
    if ((x & int256(0x0000000000000000000000000000000800000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x00000000000000000000000000000000000afe10820813d65dfe6a33c07f738f)) /
        int256(0x000000000000000000000000000005d27a9f51c31b7c2f8038212a0574779991); // * e ^ -16
    }
    // e ^ -8
    if ((x & int256(0x0000000000000000000000000000000400000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x0000000000000000000000000000000002582ab704279e8efd15e0265855c47a)) /
        int256(0x0000000000000000000000000000001b4c902e273a58678d6d3bfdb93db96d02); // * e ^ -8
    }
    // e ^ -4
    if ((x & int256(0x0000000000000000000000000000000200000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x000000000000000000000000000000001152aaa3bf81cb9fdb76eae12d029571)) /
        int256(0x00000000000000000000000000000003b1cc971a9bb5b9867477440d6d157750); // * e ^ -4
    }
    // e ^ -2
    if ((x & int256(0x0000000000000000000000000000000100000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x000000000000000000000000000000002f16ac6c59de6f8d5d6f63c1482a7c86)) /
        int256(0x000000000000000000000000000000015bf0a8b1457695355fb8ac404e7a79e3); // * e ^ -2
    }
    // e ^ -1
    if ((x & int256(0x0000000000000000000000000000000080000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x000000000000000000000000000000004da2cbf1be5827f9eb3ad1aa9866ebb3)) /
        int256(0x00000000000000000000000000000000d3094c70f034de4b96ff7d5b6f99fcd8); // * e ^ -1
    }
    // e ^ -0.5
    if ((x & int256(0x0000000000000000000000000000000040000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x0000000000000000000000000000000063afbe7ab2082ba1a0ae5e4eb1b479dc)) /
        int256(0x00000000000000000000000000000000a45af1e1f40c333b3de1db4dd55f29a7); // * e ^ -0.5
    }
    // e ^ -0.25
    if ((x & int256(0x0000000000000000000000000000000020000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) /
        int256(0x00000000000000000000000000000000910b022db7ae67ce76b441c27035c6a1); // * e ^ -0.25
    }
    // e ^ -0.125
    if ((x & int256(0x0000000000000000000000000000000010000000000000000000000000000000)) != 0) {
      r =
        (r * int256(0x00000000000000000000000000000000783eafef1c0a8f3978c7f81824d62ebf)) /
        int256(0x0000000000000000000000000000000088415abbe9a76bead8d00cf112e4d4a8); // * e ^ -0.125
    }
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase

pragma solidity ^0.8.16;

import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import {FixedMath0x} from "./FixedMath0x.sol";

using SafeCast for uint256;

library MembershipFixedMath {
  error InvalidFraction(uint256 n, uint256 d);

  /**
   * @notice Convert some uint256 fraction `n` numerator / `d` denominator to a fixed-point number `f`.
   * @param n numerator
   * @param d denominator
   * @return fixed-point number
   */
  function toFixed(uint256 n, uint256 d) internal pure returns (int256) {
    if (d.toInt256() < n.toInt256()) revert InvalidFraction(n, d);

    return (n.toInt256() * FixedMath0x.FIXED_1) / int256(d.toInt256());
  }

  /**
   * @notice Divide some unsigned int `u` by a fixed point number `f`
   * @param u unsigned dividend
   * @param f fixed point divisor, in FIXED_1 units
   * @return unsigned int quotient
   */
  function uintDiv(uint256 u, int256 f) internal pure returns (uint256) {
    // multiply `u` by FIXED_1 to cancel out the built-in FIXED_1 in f
    return uint256((u.toInt256() * FixedMath0x.FIXED_1) / f);
  }

  /**
   * @notice Multiply some unsigned int `u` by a fixed point number `f`
   * @param u unsigned multiplicand
   * @param f fixed point multiplier, in FIXED_1 units
   * @return unsigned int product
   */
  function uintMul(uint256 u, int256 f) internal pure returns (uint256) {
    // divide the product by FIXED_1 to cancel out the built-in FIXED_1 in f
    return uint256((u.toInt256() * f) / FixedMath0x.FIXED_1);
  }

  /// @notice see FixedMath0x
  function ln(int256 x) internal pure returns (int256 r) {
    return FixedMath0x.ln(x);
  }

  /// @notice see FixedMath0x
  function exp(int256 x) internal pure returns (int256 r) {
    return FixedMath0x.exp(x);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./MembershipFixedMath.sol";

using SafeCast for uint256;

library MembershipScores {
  uint256 internal constant GFI_MANTISSA = 1e18;
  uint256 internal constant USDC_MANTISSA = 1e6;
  uint256 internal constant USDC_TO_GFI_MANTISSA = GFI_MANTISSA / USDC_MANTISSA;

  /**
   * @notice Calculate a membership score given some amount of `gfi` and `capital`, along
   *  with some 𝝰 = `alphaNumerator` / `alphaDenominator`.
   * @param gfi amount of gfi (GFI, 1e18 decimal places)
   * @param capital amount of capital (USDC, 1e6 decimal places)
   * @param alphaNumerator alpha param numerator
   * @param alphaDenominator alpha param denominator
   * @return membership score with 1e18 decimal places
   *
   * @dev 𝝰 must be in the range [0, 1]
   */
  function calculateScore(
    uint256 gfi,
    uint256 capital,
    uint256 alphaNumerator,
    uint256 alphaDenominator
  ) internal pure returns (uint256) {
    // Convert capital to the same base units as GFI
    capital = capital * USDC_TO_GFI_MANTISSA;

    // Score function is:
    // gfi^𝝰 * capital^(1-𝝰)
    //    = capital * capital^(-𝝰) * gfi^𝝰
    //    = capital * (gfi / capital)^𝝰
    //    = capital * (e ^ (ln(gfi / capital))) ^ 𝝰
    //    = capital * e ^ (𝝰 * ln(gfi / capital))     (1)
    // or
    //    = capital / ( 1 / e ^ (𝝰 * ln(gfi / capital)))
    //    = capital / (e ^ (𝝰 * ln(gfi / capital)) ^ -1)
    //    = capital / e ^ (𝝰 * -1 * ln(gfi / capital))
    //    = capital / e ^ (𝝰 * ln(capital / gfi))     (2)
    //
    // To avoid overflows, use (1) when gfi < capital and
    // use (2) when capital < gfi

    assert(alphaNumerator <= alphaDenominator);

    // If any side is 0, exit early
    if (gfi == 0 || capital == 0) return 0;

    // If both sides are equal, we have:
    // gfi^𝝰 * capital^(1-𝝰)
    //    = gfi^𝝰 * gfi^(1-𝝰)
    //    = gfi^(𝝰 + 1 - 𝝰)     = gfi
    if (gfi == capital) return gfi;

    bool lessGFIThanCapital = gfi < capital;

    // (gfi / capital) or (capital / gfi), always in range (0, 1)
    int256 ratio = lessGFIThanCapital
      ? MembershipFixedMath.toFixed(gfi, capital)
      : MembershipFixedMath.toFixed(capital, gfi);

    // e ^ ( ln(ratio) * 𝝰 )
    int256 exponentiation = MembershipFixedMath.exp(
      (MembershipFixedMath.ln(ratio) * alphaNumerator.toInt256()) / alphaDenominator.toInt256()
    );

    if (lessGFIThanCapital) {
      // capital * e ^ (𝝰 * ln(gfi / capital))
      return MembershipFixedMath.uintMul(capital, exponentiation);
    }

    // capital / e ^ (𝝰 * ln(capital / gfi))
    return MembershipFixedMath.uintDiv(capital, exponentiation);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

import {Context} from "../../../../cake/Context.sol";
import {CapitalAssetType} from "../../../../interfaces/ICapitalLedger.sol";
import "../../../../cake/Routing.sol" as Routing;

/// @dev Adding a New Asset Type
/// 1. Create a new library in this directory of the name <AssetType>Asset.sol
/// 2. The library must implement the same functions as the other assets:
///   2.1 AssetType
///   2.2 isType
///   2.3 isValid - if the asset is an ERC721
///   2.4 getUsdcEquivalent
/// 3. Import the library below in "Supported assets"
/// 4. Add the new library to the corresponding `getSupportedType` function in this file
/// 5. Add the new library to the corresponding `getUsdcEquivalent` function in this file
/// 6. If the new library is an ERC721, add it to the `isValid` function in this file

// Supported assets
import {PoolTokensAsset} from "./PoolTokensAsset.sol";
import {StakedFiduAsset} from "./StakedFiduAsset.sol";

using Routing.Context for Context;

library CapitalAssets {
  /// Thrown when an asset has been requested that does not exist
  error InvalidAsset(address assetAddress);
  /// Thrown when an asset has been requested that does not exist
  error InvalidAssetWithId(address assetAddress, uint256 assetTokenId);

  /**
   * @notice Check if a specific `assetAddress` has a corresponding capital asset
   *  implementation and returns the asset type. Returns INVALID if no
   *  such asset exists.
   * @param context goldfinch context for routing
   * @param assetAddress the address of the asset's contract
   * @return type of the asset
   */
  function getSupportedType(
    Context context,
    address assetAddress
  ) internal view returns (CapitalAssetType) {
    if (StakedFiduAsset.isType(context, assetAddress)) return StakedFiduAsset.AssetType;
    if (PoolTokensAsset.isType(context, assetAddress)) return PoolTokensAsset.AssetType;

    return CapitalAssetType.INVALID;
  }

  //////////////////////////////////////////////////////////////////
  // ERC721

  /**
   * @notice Check if a specific token for a supported asset is valid or not. Returns false
   *  if the asset is not supported or the token is invalid
   * @param context goldfinch context for routing
   * @param assetAddress the address of the asset's contract
   * @param assetTokenId the token id
   * @return whether or not a specific token id of asset address is supported
   */
  function isValid(
    Context context,
    address assetAddress,
    uint256 assetTokenId
  ) internal view returns (bool) {
    if (StakedFiduAsset.isType(context, assetAddress))
      return StakedFiduAsset.isValid(context, assetTokenId);
    if (PoolTokensAsset.isType(context, assetAddress))
      return PoolTokensAsset.isValid(context, assetTokenId);

    return false;
  }

  /**
   * @notice Get the point-in-time USDC equivalent value of the ERC721 asset. This
   *  specifically attempts to return the "principle" or "at-risk" USDC value of
   *  the asset and does not include rewards, interest, or other benefits.
   * @param context goldfinch context for routing
   * @param asset ERC721 to evaluate
   * @param assetTokenId id of the token to evaluate
   * @return USDC equivalent value
   */
  function getUsdcEquivalent(
    Context context,
    IERC721Upgradeable asset,
    uint256 assetTokenId
  ) internal view returns (uint256) {
    if (PoolTokensAsset.isType(context, address(asset))) {
      return PoolTokensAsset.getUsdcEquivalent(context, assetTokenId);
    }

    if (StakedFiduAsset.isType(context, address(asset))) {
      return StakedFiduAsset.getUsdcEquivalent(context, assetTokenId);
    }

    revert InvalidAsset(address(asset));
  }

  /**
   * @notice Harvests the associated rewards, interest, and other accrued assets
   *  associated with the asset token. For example, if given a PoolToken asset,
   *  this will collect the GFI rewards (if available), redeemable interest, and
   *  redeemable principal, and send that to the `owner`.
   * @param context goldfinch context for routing
   * @param owner address to send the harvested assets to
   * @param asset ERC721 to harvest
   * @param assetTokenId id of the token to harvest
   */
  function harvest(
    Context context,
    address owner,
    IERC721Upgradeable asset,
    uint256 assetTokenId
  ) internal {
    if (PoolTokensAsset.isType(context, address(asset))) {
      return PoolTokensAsset.harvest(context, owner, assetTokenId);
    }

    if (StakedFiduAsset.isType(context, address(asset))) {
      return StakedFiduAsset.harvest(context, owner, assetTokenId);
    }

    revert InvalidAsset(address(asset));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {Context} from "../../../../cake/Context.sol";
import "../../../../cake/Routing.sol" as Routing;

import {CapitalAssetType} from "../../../../interfaces/ICapitalLedger.sol";
import {IPoolTokens} from "../../../../interfaces/IPoolTokens.sol";

import {ITranchedPool} from "../../../../interfaces/ITranchedPool.sol";

using Routing.Context for Context;
using SafeERC20 for IERC20Upgradeable;

library PoolTokensAsset {
  /// Thrown when trying to harvest a pool token when not go-listed
  error NotGoListed(address owner);

  CapitalAssetType public constant AssetType = CapitalAssetType.ERC721;

  /**
   * @notice Get the type of asset that this contract adapts.
   * @return the asset type
   */
  function isType(Context context, address assetAddress) internal view returns (bool) {
    return assetAddress == address(context.poolTokens());
  }

  /**
   * @notice Get whether or not the given asset is valid
   * @return true if the represented tranche is or may be drawn down (so true if assets are doing work)
   */
  function isValid(Context context, uint256 assetTokenId) internal view returns (bool) {
    IPoolTokens.TokenInfo memory tokenInfo = context.poolTokens().getTokenInfo(assetTokenId);
    ITranchedPool tranchedPool = ITranchedPool(tokenInfo.pool);

    return tranchedPool.getTranche(tokenInfo.tranche).lockedUntil != 0;
  }

  /**
   * @notice Get the point-in-time USDC equivalent value of the Pool Token asset. This
   *  specifically attempts to return the "principle" or "at-risk" USDC value of
   *  the asset and does not include rewards, interest, or other benefits.
   * @param context goldfinch context for routing
   * @param assetTokenId tokenId of the Pool Token to evaluate
   * @return USDC equivalent value
   */
  function getUsdcEquivalent(
    Context context,
    uint256 assetTokenId
  ) internal view returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = context.poolTokens().getTokenInfo(assetTokenId);
    return tokenInfo.principalAmount - tokenInfo.principalRedeemed;
  }

  /**
   * @notice Harvest GFI rewards and redeemable interest and principal on PoolToken with id
   *  `assetTokenId` and send the harvested assets to `owner`.
   * @param context goldfinch context for routing
   * @param owner address to send the harvested assets to
   * @param assetTokenId id of the position to harvest
   * @dev this may revert if the credit line is late on payments, which results in the backerRewards
   *  withdraw call to revert. We purposefully do not attempt to handle this case, instead expecting
   *  the caller to decide what the best course of action is (eg: wait for the payment to be updated
   *  or handle it manually).
   */
  function harvest(Context context, address owner, uint256 assetTokenId) internal {
    IPoolTokens.TokenInfo memory tokenInfo = context.poolTokens().getTokenInfo(assetTokenId);
    ITranchedPool tranchedPool = ITranchedPool(tokenInfo.pool);

    if (!context.go().goOnlyIdTypes(owner, tranchedPool.getAllowedUIDTypes())) {
      revert NotGoListed(owner);
    }

    (uint256 interestWithdrawn, uint256 principalWithdrawn) = tranchedPool.withdrawMax(
      assetTokenId
    );
    uint256 totalWithdrawn = interestWithdrawn + principalWithdrawn;
    if (totalWithdrawn > 0) {
      context.usdc().safeTransfer(owner, totalWithdrawn);
    }

    // Sends reward to owner (this contract)
    uint256 rewards = context.backerRewards().withdraw(assetTokenId);
    if (rewards > 0) {
      context.gfi().safeTransfer(owner, rewards);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../../library/FiduConversions.sol";
import {Context} from "../../../../cake/Context.sol";
import "../../../../cake/Routing.sol" as Routing;

import {CapitalAssetType} from "../../../../interfaces/ICapitalLedger.sol";
import {IStakingRewards, StakedPositionType} from "../../../../interfaces/IStakingRewards.sol";
import {ISeniorPool} from "../../../../interfaces/ISeniorPool.sol";

using Routing.Context for Context;
using SafeERC20 for IERC20Upgradeable;

library StakedFiduAsset {
  CapitalAssetType public constant AssetType = CapitalAssetType.ERC721;

  /**
   * @notice Get the type of asset that this contract adapts.
   * @return the asset type
   */
  function isType(Context context, address assetAddress) internal view returns (bool) {
    return assetAddress == address(context.stakingRewards());
  }

  /**
   * @notice Get whether or not the given asset is valid
   * @return true if the asset is Fidu type (not CurveLP)
   */
  function isValid(Context context, uint256 assetTokenId) internal view returns (bool) {
    return
      context.stakingRewards().getPosition(assetTokenId).positionType == StakedPositionType.Fidu;
  }

  /**
   * @notice Get the point-in-time USDC equivalent value of the ERC721 asset. This
   *  specifically attempts to return the "principle" or "at-risk" USDC value of
   *  the asset and does not include rewards, interest, or other benefits.
   * @param context goldfinch context for routing
   * @param assetTokenId id of the position to evaluate
   * @return USDC equivalent value
   */
  function getUsdcEquivalent(
    Context context,
    uint256 assetTokenId
  ) internal view returns (uint256) {
    uint256 stakedFiduBalance = context.stakingRewards().stakedBalanceOf(assetTokenId);
    return FiduConversions.fiduToUsdc(stakedFiduBalance, context.seniorPool().sharePrice());
  }

  /**
   * @notice Harvest GFI rewards on a staked fidu token and send them to `owner`.
   * @param context goldfinch context for routing
   * @param owner address to send the GFI to
   * @param assetTokenId id of the position to harvest
   */
  function harvest(Context context, address owner, uint256 assetTokenId) internal {
    // Sends reward to owner (this contract)
    uint256 reward = context.stakingRewards().getReward(assetTokenId);

    if (reward > 0) {
      context.gfi().safeTransfer(owner, reward);
    }
  }
}