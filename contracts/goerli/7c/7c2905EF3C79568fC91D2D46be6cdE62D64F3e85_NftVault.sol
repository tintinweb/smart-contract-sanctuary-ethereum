// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IApeCoinStaking {
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }

    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }

    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }

    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    struct PoolWithoutTimeRange {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
    }

    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }

    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    struct PairingStatus {
        uint248 tokenId;
        bool isPaired;
    }

    function mainToBakc(uint256 poolId_, uint256 mainTokenId_) external view returns (PairingStatus memory);

    function bakcToMain(uint256 poolId_, uint256 bakcTokenId_) external view returns (PairingStatus memory);

    function nftContracts(uint256 poolId_) external view returns (address);

    function rewardsBy(uint256 poolId_, uint256 from_, uint256 to_) external view returns (uint256, uint256);

    function apeCoin() external view returns (address);

    function getCurrentTimeRangeIndex(Pool memory pool_) external view returns (uint256);

    function getTimeRangeBy(uint256 poolId_, uint256 index_) external view returns (TimeRange memory);

    function getPoolsUI() external view returns (PoolUI memory, PoolUI memory, PoolUI memory, PoolUI memory);

    function getSplitStakes(address address_) external view returns (DashboardStake[] memory);

    function stakedTotal(address addr_) external view returns (uint256);

    function pools(uint256 poolId_) external view returns (PoolWithoutTimeRange memory);

    function nftPosition(uint256 poolId_, uint256 tokenId_) external view returns (Position memory);

    function addressPosition(address addr_) external view returns (Position memory);

    function pendingRewards(uint256 poolId_, address address_, uint256 tokenId_) external view returns (uint256);

    function depositBAYC(SingleNft[] calldata nfts_) external;

    function depositMAYC(SingleNft[] calldata nfts_) external;

    function depositBAKC(
        PairNftDepositWithAmount[] calldata baycPairs_,
        PairNftDepositWithAmount[] calldata maycPairs_
    ) external;

    function depositSelfApeCoin(uint256 amount_) external;

    function claimSelfApeCoin() external;

    function claimBAYC(uint256[] calldata nfts_, address recipient_) external;

    function claimMAYC(uint256[] calldata nfts_, address recipient_) external;

    function claimBAKC(PairNft[] calldata baycPairs_, PairNft[] calldata maycPairs_, address recipient_) external;

    function withdrawBAYC(SingleNft[] calldata nfts_, address recipient_) external;

    function withdrawMAYC(SingleNft[] calldata nfts_, address recipient_) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] calldata baycPairs_,
        PairNftWithdrawWithAmount[] calldata maycPairs_
    ) external;

    function withdrawSelfApeCoin(uint256 amount_) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.18;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 *      from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault) external view returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import {IApeCoinStaking} from "./IApeCoinStaking.sol";
import {IDelegationRegistry} from "../interfaces/IDelegationRegistry.sol";

interface INftVault is IERC721ReceiverUpgradeable {
    event NftDeposited(address indexed nft, address indexed owner, address indexed staker, uint256[] tokenIds);
    event NftWithdrawn(address indexed nft, address indexed owner, address indexed staker, uint256[] tokenIds);

    event SingleNftStaked(address indexed nft, address indexed staker, IApeCoinStaking.SingleNft[] nfts);
    event PairedNftStaked(
        address indexed staker,
        IApeCoinStaking.PairNftDepositWithAmount[] baycPairs,
        IApeCoinStaking.PairNftDepositWithAmount[] maycPairs
    );
    event SingleNftUnstaked(address indexed nft, address indexed staker, IApeCoinStaking.SingleNft[] nfts);
    event PairedNftUnstaked(
        address indexed staker,
        IApeCoinStaking.PairNftWithdrawWithAmount[] baycPairs,
        IApeCoinStaking.PairNftWithdrawWithAmount[] maycPairs
    );

    event SingleNftClaimed(address indexed nft, address indexed staker, uint256[] tokenIds, uint256 rewards);
    event PairedNftClaimed(
        address indexed staker,
        IApeCoinStaking.PairNft[] baycPairs,
        IApeCoinStaking.PairNft[] maycPairs,
        uint256 rewards
    );

    struct NftStatus {
        address owner;
        address staker;
    }

    struct VaultStorage {
        // nft address =>  nft tokenId => nftStatus
        mapping(address => mapping(uint256 => NftStatus)) nfts;
        // nft address => staker address => refund
        mapping(address => mapping(address => Refund)) refunds;
        // nft address => staker address => position
        mapping(address => mapping(address => Position)) positions;
        // nft address => staker address => staking nft tokenId array
        mapping(address => mapping(address => EnumerableSetUpgradeable.UintSet)) stakingTokenIds;
        IApeCoinStaking apeCoinStaking;
        IERC20Upgradeable apeCoin;
        address bayc;
        address mayc;
        address bakc;
        IDelegationRegistry delegationRegistry;
        mapping(address => bool) authorized;
    }

    struct Refund {
        uint256 principal;
        uint256 reward;
    }
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }

    function authorise(address addr_, bool authorized_) external;

    function stakerOf(address nft_, uint256 tokenId_) external view returns (address);

    function ownerOf(address nft_, uint256 tokenId_) external view returns (address);

    function refundOf(address nft_, address staker_) external view returns (Refund memory);

    function positionOf(address nft_, address staker_) external view returns (Position memory);

    function pendingRewards(address nft_, address staker_) external view returns (uint256);

    function totalStakingNft(address nft_, address staker_) external view returns (uint256);

    function stakingNftIdByIndex(address nft_, address staker_, uint256 index_) external view returns (uint256);

    function isStaking(address nft_, address staker_, uint256 tokenId_) external view returns (bool);

    // delegate.cash

    function setDelegateCash(address delegate_, address nft_, uint256[] calldata tokenIds, bool value) external;

    // deposit nft
    function depositNft(address nft_, uint256[] calldata tokenIds_, address staker_) external;

    // withdraw nft
    function withdrawNft(address nft_, uint256[] calldata tokenIds_) external;

    // staker withdraw ape coin
    function withdrawRefunds(address nft_) external;

    // stake
    function stakeBaycPool(IApeCoinStaking.SingleNft[] calldata nfts_) external;

    function stakeMaycPool(IApeCoinStaking.SingleNft[] calldata nfts_) external;

    function stakeBakcPool(
        IApeCoinStaking.PairNftDepositWithAmount[] calldata baycPairs_,
        IApeCoinStaking.PairNftDepositWithAmount[] calldata maycPairs_
    ) external;

    // unstake
    function unstakeBaycPool(
        IApeCoinStaking.SingleNft[] calldata nfts_,
        address recipient_
    ) external returns (uint256 principal, uint256 rewards);

    function unstakeMaycPool(
        IApeCoinStaking.SingleNft[] calldata nfts_,
        address recipient_
    ) external returns (uint256 principal, uint256 rewards);

    function unstakeBakcPool(
        IApeCoinStaking.PairNftWithdrawWithAmount[] calldata baycPairs_,
        IApeCoinStaking.PairNftWithdrawWithAmount[] calldata maycPairs_,
        address recipient_
    ) external returns (uint256 principal, uint256 rewards);

    // claim rewards
    function claimBaycPool(uint256[] calldata tokenIds_, address recipient_) external returns (uint256 rewards);

    function claimMaycPool(uint256[] calldata tokenIds_, address recipient_) external returns (uint256 rewards);

    function claimBakcPool(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_,
        address recipient_
    ) external returns (uint256 rewards);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import {IApeCoinStaking} from "../interfaces/IApeCoinStaking.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ApeStakingLib {
    uint256 internal constant APE_COIN_PRECISION = 1e18;
    uint256 internal constant SECONDS_PER_HOUR = 3600;
    uint256 internal constant SECONDS_PER_MINUTE = 60;

    uint256 internal constant APE_COIN_POOL_ID = 0;
    uint256 internal constant BAYC_POOL_ID = 1;
    uint256 internal constant MAYC_POOL_ID = 2;
    uint256 internal constant BAKC_POOL_ID = 3;

    function getCurrentTimeRange(
        IApeCoinStaking apeCoinStaking_,
        uint256 poolId
    ) internal view returns (IApeCoinStaking.TimeRange memory) {
        (
            IApeCoinStaking.PoolUI memory apeCoinPoolUI,
            IApeCoinStaking.PoolUI memory baycPoolUI,
            IApeCoinStaking.PoolUI memory maycPoolUI,
            IApeCoinStaking.PoolUI memory bakcPoolUI
        ) = apeCoinStaking_.getPoolsUI();

        if (poolId == apeCoinPoolUI.poolId) {
            return apeCoinPoolUI.currentTimeRange;
        }

        if (poolId == baycPoolUI.poolId) {
            return baycPoolUI.currentTimeRange;
        }

        if (poolId == maycPoolUI.poolId) {
            return maycPoolUI.currentTimeRange;
        }
        if (poolId == bakcPoolUI.poolId) {
            return bakcPoolUI.currentTimeRange;
        }

        revert("invalid pool id");
    }

    function getNftPoolId(IApeCoinStaking apeCoinStaking_, address nft_) internal view returns (uint256) {
        if (nft_ == apeCoinStaking_.nftContracts(BAYC_POOL_ID)) {
            return BAYC_POOL_ID;
        }

        if (nft_ == apeCoinStaking_.nftContracts(MAYC_POOL_ID)) {
            return MAYC_POOL_ID;
        }
        if (nft_ == apeCoinStaking_.nftContracts(BAKC_POOL_ID)) {
            return BAKC_POOL_ID;
        }
        revert("invalid nft");
    }

    function getNftPosition(
        IApeCoinStaking apeCoinStaking_,
        address nft_,
        uint256 tokenId_
    ) internal view returns (IApeCoinStaking.Position memory) {
        return apeCoinStaking_.nftPosition(getNftPoolId(apeCoinStaking_, nft_), tokenId_);
    }

    function getNftPool(
        IApeCoinStaking apeCoinStaking_,
        address nft_
    ) internal view returns (IApeCoinStaking.PoolWithoutTimeRange memory) {
        return apeCoinStaking_.pools(getNftPoolId(apeCoinStaking_, nft_));
    }

    function getNftRewardsBy(
        IApeCoinStaking apeCoinStaking_,
        address nft_,
        uint256 from_,
        uint256 to_
    ) internal view returns (uint256, uint256) {
        return apeCoinStaking_.rewardsBy(getNftPoolId(apeCoinStaking_, nft_), from_, to_);
    }

    function bayc(IApeCoinStaking apeCoinStaking_) internal view returns (IERC721) {
        return IERC721(apeCoinStaking_.nftContracts(BAYC_POOL_ID));
    }

    function mayc(IApeCoinStaking apeCoinStaking_) internal view returns (IERC721) {
        return IERC721(apeCoinStaking_.nftContracts(MAYC_POOL_ID));
    }

    function bakc(IApeCoinStaking apeCoinStaking_) internal view returns (IERC721) {
        return IERC721(apeCoinStaking_.nftContracts(BAKC_POOL_ID));
    }

    function getPreviousTimestampHour() internal view returns (uint256) {
        return block.timestamp - (getMinute(block.timestamp) * 60 + getSecond(block.timestamp));
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    /// @notice the seconds (0 to 59) of a timestamp
    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {INftVault, IApeCoinStaking, IERC721ReceiverUpgradeable} from "../interfaces/INftVault.sol";
import {IDelegationRegistry} from "../interfaces/IDelegationRegistry.sol";

import {ApeStakingLib} from "../libraries/ApeStakingLib.sol";
import {VaultLogic} from "./VaultLogic.sol";

contract NftVault is INftVault, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using ApeStakingLib for IApeCoinStaking;

    VaultStorage internal _vaultStorage;

    modifier onlyApe(address nft_) {
        require(
            nft_ == _vaultStorage.bayc || nft_ == _vaultStorage.mayc || nft_ == _vaultStorage.bakc,
            "NftVault: not ape"
        );
        _;
    }

    modifier onlyApeCaller() {
        require(
            msg.sender == _vaultStorage.bayc || msg.sender == _vaultStorage.mayc || msg.sender == _vaultStorage.bakc,
            "NftVault: caller not ape"
        );
        _;
    }

    modifier onlyAuthorized() {
        require(_vaultStorage.authorized[msg.sender], "StNft: caller is not authorized");
        _;
    }

    function initialize(IApeCoinStaking apeCoinStaking_, IDelegationRegistry delegationRegistry_) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        _vaultStorage.apeCoinStaking = apeCoinStaking_;
        _vaultStorage.delegationRegistry = delegationRegistry_;
        _vaultStorage.apeCoin = IERC20Upgradeable(_vaultStorage.apeCoinStaking.apeCoin());
        _vaultStorage.bayc = address(_vaultStorage.apeCoinStaking.bayc());
        _vaultStorage.mayc = address(_vaultStorage.apeCoinStaking.mayc());
        _vaultStorage.bakc = address(_vaultStorage.apeCoinStaking.bakc());
        _vaultStorage.apeCoin.approve(address(_vaultStorage.apeCoinStaking), type(uint256).max);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override onlyApeCaller returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function stakerOf(address nft_, uint256 tokenId_) external view onlyApe(nft_) returns (address) {
        return VaultLogic._stakerOf(_vaultStorage, nft_, tokenId_);
    }

    function ownerOf(address nft_, uint256 tokenId_) external view onlyApe(nft_) returns (address) {
        return VaultLogic._ownerOf(_vaultStorage, nft_, tokenId_);
    }

    function refundOf(address nft_, address staker_) external view onlyApe(nft_) returns (Refund memory) {
        return _vaultStorage.refunds[nft_][staker_];
    }

    function positionOf(address nft_, address staker_) external view onlyApe(nft_) returns (Position memory) {
        return _vaultStorage.positions[nft_][staker_];
    }

    function pendingRewards(address nft_, address staker_) external view onlyApe(nft_) returns (uint256) {
        IApeCoinStaking.PoolWithoutTimeRange memory pool = _vaultStorage.apeCoinStaking.getNftPool(nft_);
        Position memory position = _vaultStorage.positions[nft_][staker_];

        (uint256 rewardsSinceLastCalculated, ) = _vaultStorage.apeCoinStaking.getNftRewardsBy(
            nft_,
            pool.lastRewardedTimestampHour,
            ApeStakingLib.getPreviousTimestampHour()
        );
        uint256 accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare;

        if (
            block.timestamp > pool.lastRewardedTimestampHour + ApeStakingLib.SECONDS_PER_HOUR && pool.stakedAmount != 0
        ) {
            accumulatedRewardsPerShare =
                accumulatedRewardsPerShare +
                (rewardsSinceLastCalculated * ApeStakingLib.APE_COIN_PRECISION) /
                pool.stakedAmount;
        }
        return
            uint256(int256(position.stakedAmount * accumulatedRewardsPerShare) - position.rewardsDebt) /
            ApeStakingLib.APE_COIN_PRECISION;
    }

    function totalStakingNft(address nft_, address staker_) external view returns (uint256) {
        return _vaultStorage.stakingTokenIds[nft_][staker_].length();
    }

    function stakingNftIdByIndex(address nft_, address staker_, uint256 index_) external view returns (uint256) {
        return _vaultStorage.stakingTokenIds[nft_][staker_].at(index_);
    }

    function isStaking(address nft_, address staker_, uint256 tokenId_) external view returns (bool) {
        return _vaultStorage.stakingTokenIds[nft_][staker_].contains(tokenId_);
    }

    function authorise(address addr_, bool authorized_) external override onlyOwner {
        _vaultStorage.authorized[addr_] = authorized_;
    }

    function setDelegateCash(
        address delegate_,
        address nft_,
        uint256[] calldata tokenIds_,
        bool value_
    ) external override onlyAuthorized onlyApe(nft_) {
        require(delegate_ != address(0), "nftVault: invalid delegate");
        uint256 tokenId_;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            tokenId_ = tokenIds_[i];
            require(
                msg.sender == VaultLogic._ownerOf(_vaultStorage, nft_, tokenId_),
                "nftVault: only owner can delegate"
            );
            _vaultStorage.delegationRegistry.delegateForToken(delegate_, nft_, tokenId_, value_);
        }
    }

    function depositNft(
        address nft_,
        uint256[] calldata tokenIds_,
        address staker_
    ) external override onlyApe(nft_) onlyAuthorized nonReentrant {
        IApeCoinStaking.Position memory position_;

        // transfer nft and set permission
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // block partially stake from official contract
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, tokenIds_[i]);
            require(position_.stakedAmount == 0, "nftVault: nft already staked");
            IERC721Upgradeable(nft_).safeTransferFrom(msg.sender, address(this), tokenIds_[i]);
            _vaultStorage.nfts[nft_][tokenIds_[i]] = NftStatus(msg.sender, staker_);
        }
        emit NftDeposited(nft_, msg.sender, staker_, tokenIds_);
    }

    function withdrawNft(
        address nft_,
        uint256[] calldata tokenIds_
    ) external override onlyApe(nft_) onlyAuthorized nonReentrant {
        require(tokenIds_.length > 0, "nftVault: invalid tokenIds");
        address staker_ = VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[0]);
        if (nft_ == _vaultStorage.bayc || nft_ == _vaultStorage.mayc) {
            VaultLogic._refundSinglePool(_vaultStorage, nft_, tokenIds_);
        } else if (nft_ == _vaultStorage.bakc) {
            VaultLogic._refundPairingPool(_vaultStorage, tokenIds_);
        }
        // transfer nft to sender
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(
                msg.sender == VaultLogic._ownerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: caller must be nft owner"
            );
            require(
                staker_ == VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: staker must be same"
            );
            delete _vaultStorage.nfts[nft_][tokenIds_[i]];
            // transfer nft
            IERC721Upgradeable(nft_).safeTransferFrom(address(this), msg.sender, tokenIds_[i]);
        }
        emit NftWithdrawn(nft_, msg.sender, staker_, tokenIds_);
    }

    function withdrawRefunds(address nft_) external override onlyApe(nft_) onlyAuthorized nonReentrant {
        Refund memory _refund = _vaultStorage.refunds[nft_][msg.sender];
        uint256 amount = _refund.principal + _refund.reward;
        delete _vaultStorage.refunds[nft_][msg.sender];
        _vaultStorage.apeCoin.transfer(msg.sender, amount);
    }

    function stakeBaycPool(IApeCoinStaking.SingleNft[] calldata nfts_) external override onlyAuthorized nonReentrant {
        address nft_ = _vaultStorage.bayc;
        uint256 totalStakedAmount = 0;
        IApeCoinStaking.SingleNft memory singleNft_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be bayc staker"
            );
            totalStakedAmount += singleNft_.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(singleNft_.tokenId);
        }
        _vaultStorage.apeCoin.transferFrom(msg.sender, address(this), totalStakedAmount);
        _vaultStorage.apeCoinStaking.depositBAYC(nfts_);

        VaultLogic._increasePosition(_vaultStorage, nft_, msg.sender, totalStakedAmount);

        emit SingleNftStaked(nft_, msg.sender, nfts_);
    }

    function unstakeBaycPool(
        IApeCoinStaking.SingleNft[] calldata nfts_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 principal, uint256 rewards) {
        address nft_ = _vaultStorage.bayc;
        IApeCoinStaking.SingleNft memory singleNft_;
        IApeCoinStaking.Position memory position_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be nft staker"
            );
            principal += singleNft_.amount;
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, singleNft_.tokenId);
            if (position_.stakedAmount == singleNft_.amount) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(singleNft_.tokenId);
            }
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);
        _vaultStorage.apeCoinStaking.withdrawBAYC(nfts_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards - principal;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }

        VaultLogic._decreasePosition(_vaultStorage, nft_, msg.sender, principal);

        emit SingleNftUnstaked(nft_, msg.sender, nfts_);
    }

    function claimBaycPool(
        uint256[] calldata tokenIds_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 rewards) {
        address nft_ = _vaultStorage.bayc;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: caller must be nft staker"
            );
        }
        rewards = _vaultStorage.apeCoin.balanceOf(address(recipient_));
        _vaultStorage.apeCoinStaking.claimBAYC(tokenIds_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }
        emit SingleNftClaimed(nft_, msg.sender, tokenIds_, rewards);
    }

    function stakeMaycPool(IApeCoinStaking.SingleNft[] calldata nfts_) external override onlyAuthorized nonReentrant {
        address nft_ = _vaultStorage.mayc;
        uint256 totalApeCoinAmount = 0;
        IApeCoinStaking.SingleNft memory singleNft_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be mayc staker"
            );
            totalApeCoinAmount += singleNft_.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(singleNft_.tokenId);
        }
        _vaultStorage.apeCoin.transferFrom(msg.sender, address(this), totalApeCoinAmount);
        _vaultStorage.apeCoinStaking.depositMAYC(nfts_);
        VaultLogic._increasePosition(_vaultStorage, nft_, msg.sender, totalApeCoinAmount);

        emit SingleNftStaked(nft_, msg.sender, nfts_);
    }

    function unstakeMaycPool(
        IApeCoinStaking.SingleNft[] calldata nfts_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 principal, uint256 rewards) {
        address nft_ = _vaultStorage.mayc;
        IApeCoinStaking.SingleNft memory singleNft_;
        IApeCoinStaking.Position memory position_;
        for (uint256 i = 0; i < nfts_.length; i++) {
            singleNft_ = nfts_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, singleNft_.tokenId),
                "nftVault: caller must be nft staker"
            );
            principal += singleNft_.amount;
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, singleNft_.tokenId);
            if (position_.stakedAmount == singleNft_.amount) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(singleNft_.tokenId);
            }
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);

        _vaultStorage.apeCoinStaking.withdrawMAYC(nfts_, recipient_);

        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards - principal;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }

        VaultLogic._decreasePosition(_vaultStorage, nft_, msg.sender, principal);

        emit SingleNftUnstaked(nft_, msg.sender, nfts_);
    }

    function claimMaycPool(
        uint256[] calldata tokenIds_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 rewards) {
        address nft_ = _vaultStorage.mayc;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, tokenIds_[i]),
                "nftVault: caller must be nft staker"
            );
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);
        _vaultStorage.apeCoinStaking.claimMAYC(tokenIds_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }
        emit SingleNftClaimed(nft_, msg.sender, tokenIds_, rewards);
    }

    function stakeBakcPool(
        IApeCoinStaking.PairNftDepositWithAmount[] calldata baycPairs_,
        IApeCoinStaking.PairNftDepositWithAmount[] calldata maycPairs_
    ) external override onlyAuthorized nonReentrant {
        uint256 totalStakedAmount = 0;
        IApeCoinStaking.PairNftDepositWithAmount memory pair;
        address nft_ = _vaultStorage.bakc;
        for (uint256 i = 0; i < baycPairs_.length; i++) {
            pair = baycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            totalStakedAmount += pair.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(pair.bakcTokenId);
        }

        for (uint256 i = 0; i < maycPairs_.length; i++) {
            pair = maycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.mayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            totalStakedAmount += pair.amount;
            _vaultStorage.stakingTokenIds[nft_][msg.sender].add(pair.bakcTokenId);
        }
        _vaultStorage.apeCoin.transferFrom(msg.sender, address(this), totalStakedAmount);
        _vaultStorage.apeCoinStaking.depositBAKC(baycPairs_, maycPairs_);

        VaultLogic._increasePosition(_vaultStorage, nft_, msg.sender, totalStakedAmount);

        emit PairedNftStaked(msg.sender, baycPairs_, maycPairs_);
    }

    function unstakeBakcPool(
        IApeCoinStaking.PairNftWithdrawWithAmount[] calldata baycPairs_,
        IApeCoinStaking.PairNftWithdrawWithAmount[] calldata maycPairs_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 principal, uint256 rewards) {
        address nft_ = _vaultStorage.bakc;
        IApeCoinStaking.Position memory position_;
        IApeCoinStaking.PairNftWithdrawWithAmount memory pair;
        for (uint256 i = 0; i < baycPairs_.length; i++) {
            pair = baycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, pair.bakcTokenId);
            principal += (pair.isUncommit ? position_.stakedAmount : pair.amount);
            if (pair.isUncommit) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(pair.bakcTokenId);
            }
        }

        for (uint256 i = 0; i < maycPairs_.length; i++) {
            pair = maycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.mayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
            position_ = _vaultStorage.apeCoinStaking.getNftPosition(nft_, pair.bakcTokenId);
            principal += (pair.isUncommit ? position_.stakedAmount : pair.amount);
            if (pair.isUncommit) {
                _vaultStorage.stakingTokenIds[nft_][msg.sender].remove(pair.bakcTokenId);
            }
        }
        rewards = _vaultStorage.apeCoin.balanceOf(address(this));
        _vaultStorage.apeCoinStaking.withdrawBAKC(baycPairs_, maycPairs_);
        rewards = _vaultStorage.apeCoin.balanceOf(address(this)) - rewards - principal;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }
        VaultLogic._decreasePosition(_vaultStorage, nft_, msg.sender, principal);

        _vaultStorage.apeCoin.transfer(recipient_, principal + rewards);

        emit PairedNftUnstaked(msg.sender, baycPairs_, maycPairs_);
    }

    function claimBakcPool(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_,
        address recipient_
    ) external override onlyAuthorized nonReentrant returns (uint256 rewards) {
        address nft_ = _vaultStorage.bakc;
        IApeCoinStaking.PairNft memory pair;
        for (uint256 i = 0; i < baycPairs_.length; i++) {
            pair = baycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, nft_, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
        }

        for (uint256 i = 0; i < maycPairs_.length; i++) {
            pair = maycPairs_[i];
            require(
                msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.mayc, pair.mainTokenId) &&
                    msg.sender == VaultLogic._stakerOf(_vaultStorage, _vaultStorage.bakc, pair.bakcTokenId),
                "nftVault: caller must be nft staker"
            );
        }
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_);
        _vaultStorage.apeCoinStaking.claimBAKC(baycPairs_, maycPairs_, recipient_);
        rewards = _vaultStorage.apeCoin.balanceOf(recipient_) - rewards;
        if (rewards > 0) {
            VaultLogic._updateRewardsDebt(_vaultStorage, nft_, msg.sender, rewards);
        }

        emit PairedNftClaimed(msg.sender, baycPairs_, maycPairs_, rewards);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import {IApeCoinStaking} from "../interfaces/IApeCoinStaking.sol";
import {INftVault} from "../interfaces/INftVault.sol";

import {ApeStakingLib} from "../libraries/ApeStakingLib.sol";

library VaultLogic {
    event SingleNftUnstaked(address indexed nft, address indexed staker, IApeCoinStaking.SingleNft[] nfts);
    event PairedNftUnstaked(
        address indexed staker,
        IApeCoinStaking.PairNftWithdrawWithAmount[] baycPairs,
        IApeCoinStaking.PairNftWithdrawWithAmount[] maycPairs
    );
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for uint248;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using ApeStakingLib for IApeCoinStaking;

    function _stakerOf(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        uint256 tokenId_
    ) internal view returns (address) {
        return _vaultStorage.nfts[nft_][tokenId_].staker;
    }

    function _ownerOf(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        uint256 tokenId_
    ) internal view returns (address) {
        return _vaultStorage.nfts[nft_][tokenId_].owner;
    }

    function _increasePosition(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        address staker_,
        uint256 stakedAmount_
    ) internal {
        INftVault.Position storage position_ = _vaultStorage.positions[nft_][staker_];
        position_.stakedAmount += stakedAmount_;
        position_.rewardsDebt += int256(
            stakedAmount_ * _vaultStorage.apeCoinStaking.getNftPool(nft_).accumulatedRewardsPerShare
        );
    }

    function _decreasePosition(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        address staker_,
        uint256 stakedAmount_
    ) internal {
        INftVault.Position storage position_ = _vaultStorage.positions[nft_][staker_];
        position_.stakedAmount -= stakedAmount_;
        position_.rewardsDebt -= int256(
            stakedAmount_ * _vaultStorage.apeCoinStaking.getNftPool(nft_).accumulatedRewardsPerShare
        );
    }

    function _updateRewardsDebt(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        address staker_,
        uint256 claimedRewardsAmount_
    ) internal {
        INftVault.Position storage position_ = _vaultStorage.positions[nft_][staker_];
        position_.rewardsDebt += int256(claimedRewardsAmount_ * ApeStakingLib.APE_COIN_PRECISION);
    }

    struct RefundSinglePoolVars {
        uint256 poolId;
        uint256 cachedBalance;
        uint256 tokenId;
        uint256 bakcTokenId;
        uint256 stakedAmount;
        // refunds
        address staker;
        uint256 totalPrincipal;
        uint256 totalReward;
        uint256 totalPairingPrincipal;
        uint256 totalPairingReward;
        // array
        uint256 singleNftIndex;
        uint256 singleNftSize;
        uint256 pairingNftIndex;
        uint256 pairingNftSize;
    }

    function _refundSinglePool(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        uint256[] calldata tokenIds_
    ) external {
        require(nft_ == _vaultStorage.bayc || nft_ == _vaultStorage.mayc, "nftVault: not bayc or mayc");
        require(tokenIds_.length > 0, "nftVault: invalid tokenIds");

        RefundSinglePoolVars memory vars;
        IApeCoinStaking.PairingStatus memory pairingStatus;
        INftVault.Refund storage refund;

        vars.poolId = ApeStakingLib.BAYC_POOL_ID;
        if (nft_ == _vaultStorage.mayc) {
            vars.poolId = ApeStakingLib.MAYC_POOL_ID;
        }
        vars.cachedBalance = _vaultStorage.apeCoin.balanceOf(address(this));
        vars.staker = _stakerOf(_vaultStorage, nft_, tokenIds_[0]);
        require(vars.staker != address(0), "nftVault: invalid staker");

        // Calculate the nft array size
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            vars.tokenId = tokenIds_[i];
            require(msg.sender == _ownerOf(_vaultStorage, nft_, vars.tokenId), "nftVault: caller must be nft owner");
            // make sure the bayc/mayc locked in valult
            require(address(this) == IERC721Upgradeable(nft_).ownerOf(vars.tokenId), "nftVault: invalid token id");
            require(vars.staker == _stakerOf(_vaultStorage, nft_, vars.tokenId), "nftVault: staker must be same");
            vars.stakedAmount = _vaultStorage.apeCoinStaking.nftPosition(vars.poolId, vars.tokenId).stakedAmount;

            // Still have ape coin staking in single pool
            if (vars.stakedAmount > 0) {
                vars.singleNftSize += 1;
            }

            pairingStatus = _vaultStorage.apeCoinStaking.mainToBakc(vars.poolId, vars.tokenId);
            vars.bakcTokenId = pairingStatus.tokenId;
            vars.stakedAmount = _vaultStorage
                .apeCoinStaking
                .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.bakcTokenId)
                .stakedAmount;

            //  Still have ape coin staking in pairing pool
            if (
                pairingStatus.isPaired &&
                // make sure the bakc locked in valult
                IERC721Upgradeable(_vaultStorage.bakc).ownerOf(vars.bakcTokenId) == address(this) &&
                vars.stakedAmount > 0
            ) {
                vars.pairingNftSize += 1;
            }
        }

        if (vars.singleNftSize > 0) {
            IApeCoinStaking.SingleNft[] memory singleNfts_ = new IApeCoinStaking.SingleNft[](vars.singleNftSize);
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                vars.tokenId = tokenIds_[i];
                vars.stakedAmount = _vaultStorage.apeCoinStaking.nftPosition(vars.poolId, vars.tokenId).stakedAmount;
                if (vars.stakedAmount > 0) {
                    vars.totalPrincipal += vars.stakedAmount;
                    singleNfts_[vars.singleNftIndex] = IApeCoinStaking.SingleNft({
                        tokenId: vars.tokenId.toUint32(),
                        amount: vars.stakedAmount.toUint224()
                    });
                    vars.singleNftIndex += 1;
                    _vaultStorage.stakingTokenIds[nft_][vars.staker].remove(vars.tokenId);
                }
            }
            if (nft_ == _vaultStorage.bayc) {
                _vaultStorage.apeCoinStaking.withdrawBAYC(singleNfts_, address(this));
            } else {
                _vaultStorage.apeCoinStaking.withdrawMAYC(singleNfts_, address(this));
            }
            vars.totalReward =
                _vaultStorage.apeCoin.balanceOf(address(this)) -
                vars.cachedBalance -
                vars.totalPrincipal;
            // refund ape coin for single nft
            refund = _vaultStorage.refunds[nft_][vars.staker];
            refund.principal += vars.totalPrincipal;
            refund.reward += vars.totalReward;

            // update bayc&mayc position and debt
            if (vars.totalReward > 0) {
                _updateRewardsDebt(_vaultStorage, nft_, vars.staker, vars.totalReward);
            }
            _decreasePosition(_vaultStorage, nft_, vars.staker, vars.totalPrincipal);
            emit SingleNftUnstaked(nft_, vars.staker, singleNfts_);
        }

        if (vars.pairingNftSize > 0) {
            IApeCoinStaking.PairNftWithdrawWithAmount[]
                memory pairingNfts = new IApeCoinStaking.PairNftWithdrawWithAmount[](vars.pairingNftSize);
            IApeCoinStaking.PairNftWithdrawWithAmount[] memory emptyNfts;

            for (uint256 i = 0; i < tokenIds_.length; i++) {
                vars.tokenId = tokenIds_[i];

                pairingStatus = _vaultStorage.apeCoinStaking.mainToBakc(vars.poolId, vars.tokenId);
                vars.bakcTokenId = pairingStatus.tokenId;
                vars.stakedAmount = _vaultStorage
                    .apeCoinStaking
                    .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.bakcTokenId)
                    .stakedAmount;
                if (
                    pairingStatus.isPaired &&
                    // make sure the bakc locked in valult
                    IERC721Upgradeable(_vaultStorage.bakc).ownerOf(vars.bakcTokenId) == address(this) &&
                    vars.stakedAmount > 0
                ) {
                    vars.totalPairingPrincipal += vars.stakedAmount;
                    pairingNfts[vars.pairingNftIndex] = IApeCoinStaking.PairNftWithdrawWithAmount({
                        mainTokenId: vars.tokenId.toUint32(),
                        bakcTokenId: vars.bakcTokenId.toUint32(),
                        amount: vars.stakedAmount.toUint184(),
                        isUncommit: true
                    });
                    vars.pairingNftIndex += 1;
                    _vaultStorage.stakingTokenIds[_vaultStorage.bakc][vars.staker].remove(vars.bakcTokenId);
                }
            }
            vars.cachedBalance = _vaultStorage.apeCoin.balanceOf(address(this));

            if (nft_ == _vaultStorage.bayc) {
                _vaultStorage.apeCoinStaking.withdrawBAKC(pairingNfts, emptyNfts);
                emit PairedNftUnstaked(vars.staker, pairingNfts, emptyNfts);
            } else {
                _vaultStorage.apeCoinStaking.withdrawBAKC(emptyNfts, pairingNfts);
                emit PairedNftUnstaked(vars.staker, emptyNfts, pairingNfts);
            }
            vars.totalPairingReward =
                _vaultStorage.apeCoin.balanceOf(address(this)) -
                vars.cachedBalance -
                vars.totalPairingPrincipal;

            // refund ape coin for paring nft
            refund = _vaultStorage.refunds[_vaultStorage.bakc][vars.staker];
            refund.principal += vars.totalPairingPrincipal;
            refund.reward += vars.totalPairingReward;

            // update bakc position and debt
            if (vars.totalPairingReward > 0) {
                _updateRewardsDebt(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalPairingReward);
            }
            _decreasePosition(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalPairingPrincipal);
        }
    }

    struct RefundPairingPoolVars {
        uint256 cachedBalance;
        uint256 tokenId;
        uint256 stakedAmount;
        // refund
        address staker;
        uint256 totalPrincipal;
        uint256 totalReward;
        // array
        uint256 baycIndex;
        uint256 baycSize;
        uint256 maycIndex;
        uint256 maycSize;
    }

    function _refundPairingPool(INftVault.VaultStorage storage _vaultStorage, uint256[] calldata tokenIds_) external {
        require(tokenIds_.length > 0, "nftVault: invalid tokenIds");
        RefundPairingPoolVars memory vars;
        IApeCoinStaking.PairingStatus memory pairingStatus;

        vars.staker = _stakerOf(_vaultStorage, _vaultStorage.bakc, tokenIds_[0]);
        require(vars.staker != address(0), "nftVault: invalid staker");
        vars.cachedBalance = _vaultStorage.apeCoin.balanceOf(address(this));

        // Calculate the nft array size
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            vars.tokenId = tokenIds_[i];
            require(
                msg.sender == _ownerOf(_vaultStorage, _vaultStorage.bakc, vars.tokenId),
                "nftVault: caller must be nft owner"
            );
            // make sure the bakc locked in valult
            require(
                address(this) == IERC721Upgradeable(_vaultStorage.bakc).ownerOf(vars.tokenId),
                "nftVault: invalid token id"
            );
            require(
                vars.staker == _stakerOf(_vaultStorage, _vaultStorage.bakc, vars.tokenId),
                "nftVault: staker must be same"
            );

            vars.stakedAmount = _vaultStorage
                .apeCoinStaking
                .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.tokenId)
                .stakedAmount;
            if (vars.stakedAmount > 0) {
                pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(vars.tokenId, ApeStakingLib.BAYC_POOL_ID);

                // make sure the bayc locked in valult
                if (
                    pairingStatus.isPaired &&
                    IERC721Upgradeable(_vaultStorage.bayc).ownerOf(pairingStatus.tokenId) == address(this)
                ) {
                    vars.baycSize += 1;
                } else {
                    pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(vars.tokenId, ApeStakingLib.MAYC_POOL_ID);
                    // make sure the mayc locked in valult
                    if (
                        pairingStatus.isPaired &&
                        IERC721Upgradeable(_vaultStorage.mayc).ownerOf(pairingStatus.tokenId) == address(this)
                    ) {
                        vars.maycSize += 1;
                    }
                }
            }
        }

        if (vars.baycSize > 0 || vars.maycSize > 0) {
            IApeCoinStaking.PairNftWithdrawWithAmount[]
                memory baycNfts_ = new IApeCoinStaking.PairNftWithdrawWithAmount[](vars.baycSize);
            IApeCoinStaking.PairNftWithdrawWithAmount[]
                memory maycNfts_ = new IApeCoinStaking.PairNftWithdrawWithAmount[](vars.maycSize);
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                vars.tokenId = tokenIds_[i];
                vars.stakedAmount = _vaultStorage
                    .apeCoinStaking
                    .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.tokenId)
                    .stakedAmount;
                if (vars.stakedAmount > 0) {
                    vars.totalPrincipal += vars.stakedAmount;
                    pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(vars.tokenId, ApeStakingLib.BAYC_POOL_ID);
                    // make sure the bayc locked in valult
                    if (
                        pairingStatus.isPaired &&
                        IERC721Upgradeable(_vaultStorage.bayc).ownerOf(pairingStatus.tokenId) == address(this)
                    ) {
                        baycNfts_[vars.baycIndex] = IApeCoinStaking.PairNftWithdrawWithAmount({
                            mainTokenId: pairingStatus.tokenId.toUint32(),
                            bakcTokenId: vars.tokenId.toUint32(),
                            amount: vars.stakedAmount.toUint184(),
                            isUncommit: true
                        });
                        vars.baycIndex += 1;
                        _vaultStorage.stakingTokenIds[_vaultStorage.bakc][vars.staker].remove(vars.tokenId);
                    } else {
                        pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(
                            vars.tokenId,
                            ApeStakingLib.MAYC_POOL_ID
                        );
                        // make sure the mayc locked in valult
                        if (
                            pairingStatus.isPaired &&
                            IERC721Upgradeable(_vaultStorage.mayc).ownerOf(pairingStatus.tokenId) == address(this)
                        ) {
                            maycNfts_[vars.maycIndex] = IApeCoinStaking.PairNftWithdrawWithAmount({
                                mainTokenId: pairingStatus.tokenId.toUint32(),
                                bakcTokenId: vars.tokenId.toUint32(),
                                amount: vars.stakedAmount.toUint184(),
                                isUncommit: true
                            });
                            vars.maycIndex += 1;
                            _vaultStorage.stakingTokenIds[_vaultStorage.bakc][vars.staker].remove(vars.tokenId);
                        }
                    }
                }
            }

            _vaultStorage.apeCoinStaking.withdrawBAKC(baycNfts_, maycNfts_);
            vars.totalReward =
                _vaultStorage.apeCoin.balanceOf(address(this)) -
                vars.cachedBalance -
                vars.totalPrincipal;
            // refund ape coin for bakc
            INftVault.Refund storage _refund = _vaultStorage.refunds[_vaultStorage.bakc][vars.staker];
            _refund.principal += vars.totalPrincipal;
            _refund.reward += vars.totalReward;

            // update bakc position and debt
            if (vars.totalReward > 0) {
                _updateRewardsDebt(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalReward);
            }
            _decreasePosition(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalPrincipal);
            emit PairedNftUnstaked(vars.staker, baycNfts_, maycNfts_);
        }
    }
}