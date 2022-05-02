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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMnAGame.sol";
import "./interfaces/IMnAv2.sol";
import "./interfaces/IKLAYE.sol";
import "./interfaces/ILevelMath.sol";
import "./interfaces/IORES.sol";

contract StakingPoolv2 is
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  IERC721Receiver,
  PausableUpgradeable
{
  // maximum rank for a Marine/Alien
  uint8 public constant MAX_RANK = 4;

  // struct to store a stake information
  struct Stake {
    uint256 tokenId;
    address owner;
    uint256 value;
    uint256 lastClaimTime;
    uint256 startTime;
    uint256 stakedDuration;
    uint256 tokenLevel;
  }

  uint256 private totalRankStaked;

  event TokenStaked(
    uint256 indexed tokenId,
    address indexed owner,
    bool isMarine,
    uint256 stakedDuration,
    uint256 value
  );

  event MarineClaimed(
    uint256 indexed tokenId,
    bool indexed unstaked,
    uint256 earned
  );
  event AlienClaimed(
    uint256 indexed tokenId,
    bool indexed unstaked,
    uint256 earned
  );

  // reference to the MnAv2 NFT contract
  IMnAv2 public mnaNFT;
  // reference to the $KLAYE contract for minting $KLAYE earnings
  IKLAYE public klayeToken;
  // reference to LevelMath
  ILevelMath public levelMath;
  // reference to oresToken
  IORES public oresToken;

  // maps tokenId to stake
  mapping(uint256 => Stake) public marinePool;
  // maps rank to all Alien staked with that rank
  mapping(uint256 => Stake[]) public alienPool;
  // tracks location of each Alien in AlienPool
  mapping(uint256 => uint256) private alienPoolIndices;
  // any rewards distributed when no aliens are staked
  uint256 private unaccountedRewards;
  // amount of $KLAYE due for each rank point staked
  uint256 private klayePerRank;

  // marines must have 2 days worth of $KLAYE to unstake or else they're still guarding the marine pool
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // aliens take a 20% tax on all $KLAYE claimed
  uint256 public constant KLAYE_CLAIM_TAX_PERCENTAGE = 20;
  // penalty fee for unstaking
  uint256 public UNSTAKE_KLAYE_AMOUNT = 3 ether;

  // amount of $KLAYE earned so far
  uint256 public totalKLAYEEarned;
  // the last time $KLAYE was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $KLAYE
  bool public rescueEnabled;

  function initialize() public initializer {
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();
    __Ownable_init_unchained();
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
    require(
      address(mnaNFT) != address(0) &&
        address(klayeToken) != address(0) &&
        address(oresToken) != address(0) &&
        address(levelMath) != address(0),
      "Contracts not set"
    );
    _;
  }

  function setContracts(
    address _mnaNFT,
    address _klaye,
    address _ores,
    address _levelMath
  ) external onlyOwner {
    mnaNFT = IMnAv2(_mnaNFT);
    klayeToken = IKLAYE(_klaye);
    oresToken = IORES(_ores);
    levelMath = ILevelMath(_levelMath);
  }

  /** STAKING */

  /**
   * adds Marines and Aliens to the MarinePool and AlienPool
   * @param account the address of the staker
   * @param tokenIds the IDs of the Marines and Aliens to stake
   */
  function addManyToMarinePoolAndAlienPool(
    address account,
    uint256[] calldata tokenIds
  ) external nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    uint256 tokenId;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      require(
        mnaNFT.ownerOf(tokenId) == _msgSender(),
        "You don't own this token"
      );
      uint256 tokenLevel = mnaNFT.getTokenLevel(tokenId);
      require(
        canStake(tokenId, tokenLevel),
        "can't stake. upgrade level first"
      );
      mnaNFT.transferFrom(_msgSender(), address(this), tokenId);

      if (mnaNFT.isMarine(tokenId))
        _addMarineToMarinePool(account, tokenId, tokenLevel);
      else _addAlienToAlienPool(account, tokenId, tokenLevel);
    }
  }

  /**
   * adds a single Marine to the MarinePool
   * @param account the address of the staker
   * @param tokenId the ID of the Marine to add to the MarinePool
   */
  function _addMarineToMarinePool(
    address account,
    uint256 tokenId,
    uint256 level
  ) internal whenNotPaused {
    Stake storage stake = marinePool[tokenId];
    stake.tokenId = tokenId;
    stake.owner = account;
    stake.startTime = block.timestamp;
    stake.lastClaimTime = block.timestamp;
    if (level == stake.tokenLevel) {
      stake.stakedDuration = stake.stakedDuration;
    } else {
      stake.stakedDuration = 0;
    }

    stake.value = 0;
    stake.tokenLevel = level;
    emit TokenStaked(tokenId, account, true, stake.stakedDuration, 0);
  }

  /**
   * adds a single Alien to the AlienPool
   * @param account the address of the staker
   * @param tokenId the ID of the Alien to add to the AlienPool
   */
  function _addAlienToAlienPool(
    address account,
    uint256 tokenId,
    uint256 level
  ) internal {
    uint8 rank = _rankForAlien(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 4 to 1
    alienPoolIndices[tokenId] = alienPool[rank].length; // Store the location of the alien in the AlienPool
    alienPool[rank].push(
      Stake({
        tokenId: tokenId,
        owner: account,
        value: klayePerRank,
        startTime: block.timestamp,
        lastClaimTime: block.timestamp,
        stakedDuration: 0,
        tokenLevel: level
      })
    ); // Add the alien to the AlienPool
    emit TokenStaked(tokenId, account, false, 0, klayePerRank);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $KLAYE earnings and optionally unstake tokens from the MarinePool / AlienPool
   * to unstake a Marine it will require it has 2 days worth of $KLAYE unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromMarinePoolAndAlienPool(
    uint256[] calldata tokenIds,
    bool unstake
  ) public whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    uint256 owed = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (mnaNFT.isMarine(tokenIds[i])) {
        owed += _claimMarineFromMarinePool(tokenIds[i], unstake);
      } else {
        owed += _claimAlienFromAlienPool(tokenIds[i], unstake);
      }
    }
    klayeToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    klayeToken.mint(_msgSender(), owed);
  }

  /**
   * realize $KLAYE earnings for a single Marine and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Aliens
   * if unstaking, there is a 50% chance all $KLAYE is stolen
   * @param tokenId the ID of the Marines to claim earnings from
   * @param unstake whether or not to unstake the Marines
   * @return owed - the amount of $KLAYE earned
   */
  function _claimMarineFromMarinePool(uint256 tokenId, bool unstake)
    internal
    returns (uint256 owed)
  {
    Stake storage stake = marinePool[tokenId];
    require(stake.owner == _msgSender(), "Don't own the given token");
    owed = calculateRewards(tokenId);

    _payAlienTax((owed * KLAYE_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked aliens
    owed = (owed * (100 - KLAYE_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Marine owner
    stake.lastClaimTime = block.timestamp;

    if (unstake) {
      // TODO Should take unstake amount in $KLAYE
      require(
        owed >= UNSTAKE_KLAYE_AMOUNT,
        "Unstake amount is smaller than the penalty amount"
      );
      owed = owed - UNSTAKE_KLAYE_AMOUNT;

      uint256 tokenLevel = mnaNFT.getTokenLevel(tokenId);
      if (tokenLevel >= 69) tokenLevel = 69;
      ILevelMath.LevelEpoch memory levelEpoch = levelMath.getLevelEpoch(
        tokenLevel
      );

      uint256 passedDuration = block.timestamp -
        stake.startTime +
        stake.stakedDuration;
      stake.stakedDuration = passedDuration > levelEpoch.maxRewardDuration
        ? levelEpoch.maxRewardDuration
        : passedDuration;
      stake.owner = address(0);
      stake.tokenLevel = tokenLevel;

      klayeToken.mint(address(this), UNSTAKE_KLAYE_AMOUNT);
      klayeToken.burn(address(this), UNSTAKE_KLAYE_AMOUNT);

      // Always transfer last to guard against reentrance
      mnaNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Marine
    }

    emit MarineClaimed(tokenId, unstake, owed);
  }

  /**
   * realize $KLAYE earnings for a single Alien and optionally unstake it
   * Aliens earn $KLAYE proportional to their rank
   * @param tokenId the ID of the Alien to claim earnings from
   * @param unstake whether or not to unstake the Alien
   * @return owed - the amount of $KLAYE earned
   */
  function _claimAlienFromAlienPool(uint256 tokenId, bool unstake)
    internal
    returns (uint256 owed)
  {
    require(mnaNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    uint8 rank = _rankForAlien(tokenId);
    Stake memory stake = alienPool[rank][alienPoolIndices[tokenId]];
    require(stake.owner == _msgSender(), "Doesn't own token");
    owed = calculateRewards(tokenId);
    if (unstake) {
      // TODO Should take unstake amount in $KLAYE
      require(
        owed >= UNSTAKE_KLAYE_AMOUNT,
        "Unstake amount is smaller than the penalty amount"
      );
      owed = owed - UNSTAKE_KLAYE_AMOUNT;

      totalRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = alienPool[rank][alienPool[rank].length - 1];
      alienPool[rank][alienPoolIndices[tokenId]] = lastStake; // Shuffle last Alien to current position
      alienPoolIndices[lastStake.tokenId] = alienPoolIndices[tokenId];
      alienPool[rank].pop(); // Remove duplicate
      klayeToken.mint(address(this), UNSTAKE_KLAYE_AMOUNT);
      klayeToken.burn(address(this), UNSTAKE_KLAYE_AMOUNT);
      delete alienPoolIndices[tokenId]; // Delete old mapping
      // Always remove last to guard against reentrance
      mnaNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Alien
    } else {
      alienPool[rank][alienPoolIndices[tokenId]] = Stake({
        tokenId: tokenId,
        owner: _msgSender(),
        startTime: stake.startTime,
        value: klayePerRank,
        lastClaimTime: block.timestamp,
        stakedDuration: 0,
        tokenLevel: stake.tokenLevel
      }); // reset stake
    }
    emit AlienClaimed(tokenId, unstake, owed);
  }

  /**
   * Upgrades levels of tokens to get rewards continuosly
   */
  function upgradeLevel(uint256[] calldata tokenIds) external whenNotPaused {
    claimManyFromMarinePoolAndAlienPool(tokenIds, false);

    uint256 totalOresToken = 0;
    for (uint256 index = 0; index < tokenIds.length; index++) {
      uint256 tokenId = tokenIds[index];
      uint256 tokenLevel = mnaNFT.getTokenLevel(tokenId);
      ILevelMath.LevelEpoch memory levelEpoch = levelMath.getLevelEpoch(
        tokenLevel
      );
      totalOresToken += levelEpoch.oresToken;
    }
    if (totalOresToken > 0) {
      oresToken.transferFrom(_msgSender(), address(this), totalOresToken);
    }

    IERC20(address(oresToken)).approve(address(mnaNFT), totalOresToken);
    mnaNFT.upgradeLevel(tokenIds);

    for (uint256 index = 0; index < tokenIds.length; index++) {
      uint256 tokenId = tokenIds[index];
      Stake storage stake = marinePool[tokenId];
      stake.startTime = block.timestamp;
      stake.lastClaimTime = block.timestamp;
      stake.stakedDuration = 0;
      stake.tokenLevel++;
    }
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint8 rank;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (mnaNFT.isMarine(tokenId)) {
        stake = marinePool[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        stake.stakedDuration =
          stake.stakedDuration -
          stake.lastClaimTime +
          stake.startTime;
        mnaNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Marines
        emit MarineClaimed(tokenId, true, 0);
      } else {
        rank = _rankForAlien(tokenId);
        stake = alienPool[rank][alienPoolIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalRankStaked -= rank; // Remove Rank from total staked
        lastStake = alienPool[rank][alienPool[rank].length - 1];
        alienPool[rank][alienPoolIndices[tokenId]] = lastStake; // Shuffle last Alien to current position
        alienPoolIndices[lastStake.tokenId] = alienPoolIndices[tokenId];
        alienPool[rank].pop(); // Remove duplicate
        delete alienPoolIndices[tokenId]; // Delete old mapping
        mnaNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Alien
        emit AlienClaimed(tokenId, true, 0);
      }
    }
  }

  /** ACCOUNTING */

  /**
   * add $KLAYE to claimable pot for the AlienPool
   * @param amount $KLAYE to add to the pot
   */
  function _payAlienTax(uint256 amount) internal {
    if (totalRankStaked == 0) {
      // if there's no staked aliens
      unaccountedRewards += amount; // keep track of $KLAYE due to aliens
      return;
    }
    // makes sure to include any unaccounted $KLAYE
    klayePerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setUnStakeKlayeAmount(uint256 amount) external onlyOwner {
    require(amount <= 3 ether, "Exceeds maximum value");
    UNSTAKE_KLAYE_AMOUNT = amount;
  }

  /** READ ONLY */

  /**
   * gets the rank score for a Alien
   * @param tokenId the ID of the Alien to get the rank score for
   * @return the rank score of the Alien (1-4)
   */
  function _rankForAlien(uint256 tokenId) internal view returns (uint8) {
    IMnA.MarineAlien memory s = mnaNFT.getTokenTraits(tokenId);
    return s.rankIndex + 1; // rank index is 0-3, (0->4, 1->3, 2->2, 3->1)
  }

  /**
   * Determines whether `tokenId` can be staked or not.
   * Token needs to have remaining accure duration for each level to stake
   */
  function canStake(uint256 tokenId, uint256 tokenLevel)
    public
    view
    returns (bool)
  {
    if (mnaNFT.isMarine(tokenId)) {
      if (tokenLevel > 69) tokenLevel = 69;
      ILevelMath.LevelEpoch memory levelEpoch = levelMath.getLevelEpoch(
        tokenLevel
      );
      Stake memory stake = marinePool[tokenId];
      if (tokenLevel > stake.tokenLevel || stake.startTime == 0) return true;
      uint256 passedDuration = block.timestamp -
        stake.startTime +
        stake.stakedDuration;
      uint256 stakedDuration = passedDuration > levelEpoch.maxRewardDuration
        ? levelEpoch.maxRewardDuration
        : passedDuration;
      return levelEpoch.maxRewardDuration > stakedDuration;
    } else {
      return true;
    }
  }

  /**
   * Calculates how much distributes for `tokenId`
   * @param tokenId - The token id you're gonna calculate for
   */
  function calculateRewards(uint256 tokenId)
    public
    view
    returns (uint256 owed)
  {
    if (mnaNFT.isMarine(tokenId)) {
      Stake memory stake = marinePool[tokenId];
      uint256 tokenLevel = mnaNFT.getTokenLevel(tokenId);
      if (tokenLevel > 69) tokenLevel = 69;
      ILevelMath.LevelEpoch memory levelEpoch = levelMath.getLevelEpoch(
        tokenLevel
      );

      uint256 claimedDuration = stake.stakedDuration +
        stake.lastClaimTime -
        stake.startTime;

      if (levelEpoch.maxRewardDuration <= claimedDuration) {
        owed = 0;
      } else {
        uint256 passedDuration = block.timestamp -
          stake.startTime +
          stake.stakedDuration;
        uint256 leftDuration = passedDuration > levelEpoch.maxRewardDuration
          ? passedDuration
          : levelEpoch.maxRewardDuration - passedDuration;
        if (leftDuration > levelEpoch.maxRewardDuration)
          leftDuration = levelEpoch.maxRewardDuration;
        uint256 passedTime = block.timestamp - stake.lastClaimTime;
        uint256 rewardDuration = leftDuration > passedTime
          ? passedTime
          : leftDuration;
        owed = (rewardDuration * levelEpoch.klayePerDay) / 1 days;
      }
    } else {
      uint8 rank = _rankForAlien(tokenId);
      Stake memory stake = alienPool[rank][alienPoolIndices[tokenId]];
      owed = rank * (klayePerRank - stake.value); // Calculate portion of tokens based on Rank
    }
  }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0x0), "Cannot send to MarinePool directly");
    return IERC721Receiver.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IKLAYE {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function updateOriginAccess() external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ILevelMath {
  struct LevelEpoch {
    uint256 oresToken;
    uint256 coolDownTime;
    uint256 klayeToSkip;
    uint256 klayePerDay;
    uint256 maxRewardDuration;
  }

  function getLevelEpoch(uint256 level)
    external
    view
    returns (LevelEpoch memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMnA is IERC721Enumerable {
    // game data storage
    struct MarineAlien {
        bool isMarine;
        uint8 M_Weapon;
        uint8 M_Back;
        uint8 M_Headgear;
        uint8 M_Eyes;
        uint8 M_Emblem;
        uint8 M_Body;
        uint8 A_Headgear;
        uint8 A_Eye;
        uint8 A_Back;
        uint8 A_Mouth;
        uint8 A_Body;
        uint8 rankIndex;
    }

    function minted() external returns (uint16);

    function updateOriginAccess(uint16[] memory tokenIds) external;

    function mint(address recipient, uint256 seed) external;

    function burn(uint256 tokenId) external;

    function getMaxTokens() external view returns (uint256);

    function getPaidTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (MarineAlien memory);

    function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

    function isMarine(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IMnAGame {}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IMnA.sol";

interface IMnAv2 is IERC721Enumerable {
  function minted() external returns (uint16);

  function updateOriginAccess(uint16[] memory tokenIds) external;

  function getTokenTraits(uint256 tokenId)
    external
    view
    returns (IMnA.MarineAlien memory);

  function getTokenLevel(uint256 tokenId) external view returns (uint256);

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function isMarine(uint256 tokenId) external view returns (bool);

  function upgradeLevel(uint256[] calldata tokenIds) external;

  function resetCoolDown(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IORES {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function updateOriginAccess() external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}