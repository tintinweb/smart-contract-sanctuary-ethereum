// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address usr) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library UserUtility {
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    error NotYourAsset();

    struct UserDetails {
        address[] _erc20Assets;
        address[] _erc721Assets;
        uint256[][] _tokenIds;
        address[] _erc1155Assets;
        uint256[][] _ids;
        address _beneficiary;
        uint256 _timelapse;
    }

    // Check if msg.sender is owner of NFT
    function checkOwner(address asset, uint256[] memory ids) internal view {
        for (uint256 j = 0; j < ids.length; j++) {
            if (IERC721(asset).ownerOf(ids[j]) != msg.sender) {
                revert NotYourAsset();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interface/IWETH.sol";
import "./library/UserUtility.sol";

contract Protection is Ownable, ReentrancyGuardUpgradeable {
    struct NFTAsset {
        address asset;
        uint256[] ids;
    }

    address public user;
    address public beneficiary;
    uint256 public timelapse;
    bool public assetsTransferred;
    bool public hasStaked;
    address private factory;

    // Arrays to store assets
    address[] private erc20Assets;
    NFTAsset[] private erc721Assets;
    NFTAsset[] private erc1155Assets;

    // Mapping to store if asset is protected or not
    mapping(address => bool) public isAssetProtected;
    // Mappings for asset address to assets index in the array
    mapping(address => uint256) private erc20ToIndex;
    mapping(address => uint256) private erc721ToIndex;
    mapping(address => uint256) private erc1155ToIndex;

    error ZeroAddress();
    error AssetNotProtected();
    error AssetAlreadyProtected();
    error AssetAndIdsLengthMismatch();
    error NoAssetProvided();
    error NotFactory();
    error AssetsAlreadyTransferred();
    error NotStakedNFT();

    event AssetsAdded(
        bool eth,
        address[] erc20Assets,
        address[] erc721Assets,
        address[] erc1155Assets
    );
    event AssetsRemoved(
        address[] erc20Assets,
        address[] erc721Assets,
        address[] erc1155Assets
    );
    event IdsUpdated(address[] assets, uint256[][] ids);
    event TimelapseUpdated(uint256 oldTimelapse, uint256 newTimelapse);

    constructor(
        address _user,
        UserUtility.UserDetails memory _userDetails,
        bool _protectETH
    ) {
        user = _user;
        beneficiary = _userDetails._beneficiary;
        timelapse = _userDetails._timelapse;
        assetsTransferred = false;
        hasStaked = true;
        factory = msg.sender;

        _addERC20Assets(_userDetails._erc20Assets, _protectETH);

        _addNFTAsset(1, _userDetails._erc721Assets, _userDetails._tokenIds);

        _addNFTAsset(2, _userDetails._erc1155Assets, _userDetails._ids);
    }

    modifier hasStakedAndAssetsNotTransferred() {
        if (!hasStaked) revert NotStakedNFT();
        if (assetsTransferred) revert AssetsAlreadyTransferred();
        _;
    }

    function setHasStaked(bool _hasStaked) public {
        if (msg.sender != factory) revert NotFactory();
        if (assetsTransferred) revert AssetsAlreadyTransferred();
        hasStaked = _hasStaked;
    }

    // Add ERC20 assets to the array- check if ethProtected then add WETH address
    function _addERC20Assets(address[] memory _assets, bool _protectETH)
        internal
    {
        if (_protectETH) {
            if (isAssetProtected[UserUtility.WETH])
                revert AssetAlreadyProtected();

            erc20ToIndex[UserUtility.WETH] = erc20Assets.length;
            erc20Assets.push(UserUtility.WETH);
            isAssetProtected[UserUtility.WETH] = true;
        }
        for (uint256 i = 0; i < _assets.length; i++) {
            erc20ToIndex[_assets[i]] = erc20Assets.length;
            erc20Assets.push(_assets[i]);
            isAssetProtected[_assets[i]] = true;
        }
    }

    // Add ERC721 and ERC1155 assets to array
    function _addNFTAsset(
        uint256 flag,
        address[] memory _assets,
        uint256[][] memory _ids
    ) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            address _asset = _assets[i];
            if (flag == 1) {
                erc721ToIndex[_asset] = erc721Assets.length;
                erc721Assets.push(NFTAsset(_asset, _ids[i]));
            } else if (flag == 2) {
                erc1155ToIndex[_asset] = erc1155Assets.length;
                erc1155Assets.push(NFTAsset(_asset, _ids[i]));
            }
            isAssetProtected[_asset] = true;
        }
    }

    // Add new ERC20 assets provided by user
    function _addNewERC20Assets(address[] memory _assets, bool _protectETH)
        internal
    {
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] == address(0)) revert ZeroAddress();
            if (isAssetProtected[_assets[i]]) revert AssetAlreadyProtected();
        }
        _addERC20Assets(_assets, _protectETH);
    }

    // Add new ERC721 and ERC1155 assets provided by user
    function _addNewNFTAssets(
        uint256 flag,
        address[] memory _assets,
        uint256[][] memory _ids
    ) internal {
        if (_assets.length != _ids.length) revert AssetAndIdsLengthMismatch();
        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            if (asset == address(0)) revert ZeroAddress();
            if (isAssetProtected[asset]) revert AssetAlreadyProtected();

            if (flag == 1) UserUtility.checkOwner(asset, _ids[i]);
        }
        _addNFTAsset(flag, _assets, _ids);
    }

    // Add all new assets provided by the user
    function addNewAssets(
        address[] memory _erc20Assets,
        address[] memory _erc721Assets,
        uint256[][] memory _tokenIds,
        address[] memory _erc1155Assets,
        uint256[][] memory _ids
    ) public payable onlyOwner hasStakedAndAssetsNotTransferred {
        bool protectETH = false;

        if (msg.value > 0) {
            protectETH = true;
            swapEthToWeth(msg.sender);
        } else {
            if (
                (_erc20Assets.length +
                    _erc721Assets.length +
                    _erc1155Assets.length) == 0
            ) revert NoAssetProvided();
        }

        if (
            (_erc721Assets.length != _tokenIds.length) ||
            (_erc1155Assets.length != _ids.length)
        ) revert AssetAndIdsLengthMismatch();

        _addNewERC20Assets(_erc20Assets, protectETH);
        _addNewNFTAssets(1, _erc721Assets, _tokenIds);
        _addNewNFTAssets(2, _erc1155Assets, _ids);

        emit AssetsAdded(
            protectETH,
            _erc20Assets,
            _erc721Assets,
            _erc1155Assets
        );
    }

    // Remove ERC20 assets
    function _removeERC20Assets(address[] memory _assets) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            if (asset == address(0)) revert ZeroAddress();
            if (!isAssetProtected[asset]) revert AssetNotProtected();

            uint256 index = erc20ToIndex[asset];
            if (index == erc20Assets.length - 1) {
                erc20Assets.pop();
            } else {
                erc20Assets[index] = erc20Assets[(erc20Assets.length - 1)];
                erc20Assets.pop();
                erc20ToIndex[erc20Assets[index]] = index;
            }
        }
    }

    // Remove ERC721 and ERC1155 assets
    function _removeNFTAsset(uint256 flag, address[] memory _assets) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            if (asset == address(0)) revert ZeroAddress();
            if (!isAssetProtected[asset]) revert AssetNotProtected();

            if (flag == 1) {
                uint256 index = erc721ToIndex[asset];
                if (index == (erc721Assets.length - 1)) {
                    erc721Assets.pop();
                } else {
                    erc721Assets[index] = erc721Assets[
                        (erc721Assets.length - 1)
                    ];
                    erc721Assets.pop();
                    erc721ToIndex[erc721Assets[index].asset] = index;
                }
            } else if (flag == 2) {
                uint256 index = erc1155ToIndex[asset];
                if (index == (erc1155Assets.length - 1)) {
                    erc1155Assets.pop();
                } else {
                    erc1155Assets[index] = erc1155Assets[
                        (erc1155Assets.length - 1)
                    ];
                    erc1155Assets.pop();
                    erc1155ToIndex[erc1155Assets[index].asset] = index;
                }
            }
        }
    }

    // Remove all the assets provided by user
    function removeProtectedAssets(
        address[] memory _erc20Assets,
        address[] memory _erc721Assets,
        address[] memory _erc1155Assets
    ) public onlyOwner hasStakedAndAssetsNotTransferred {
        if (
            (_erc20Assets.length +
                _erc721Assets.length +
                _erc1155Assets.length) == 0
        ) revert NoAssetProvided();
        _removeERC20Assets(_erc20Assets);
        _removeNFTAsset(1, _erc721Assets);
        _removeNFTAsset(2, _erc1155Assets);

        emit AssetsRemoved(_erc20Assets, _erc721Assets, _erc1155Assets);
    }

    // Update the ids of already added ERC721 and ERC21155 assets
    function _updateAssets(
        uint256 flag,
        address[] memory _assets,
        uint256[][] memory _ids
    ) internal {
        if (_assets.length != _ids.length) revert AssetAndIdsLengthMismatch();

        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];
            uint256[] memory ids = _ids[i];
            if (asset == address(0)) revert ZeroAddress();
            if (!isAssetProtected[asset]) revert AssetNotProtected();

            if (flag == 1) {
                UserUtility.checkOwner(asset, ids);
                uint256 index = erc721ToIndex[asset];
                erc721Assets[index] = NFTAsset(asset, ids);
            } else if (flag == 2) {
                uint256 index = erc1155ToIndex[asset];
                erc1155Assets[index] = NFTAsset(asset, ids);
            }
        }
        emit IdsUpdated(_assets, _ids);
    }

    // Update tokenIds of ERC721 assets
    function updateERC721TokenIds(
        address[] memory _assets,
        uint256[][] memory _tokenIds
    ) public onlyOwner hasStakedAndAssetsNotTransferred {
        _updateAssets(1, _assets, _tokenIds);
    }

    // Update ids of ERC1155 assets
    function updateERC1155Ids(address[] memory _assets, uint256[][] memory _ids)
        public
        onlyOwner
        hasStakedAndAssetsNotTransferred
    {
        _updateAssets(2, _assets, _ids);
    }

    // Get addresses of all the protected assets
    function getAllProtectedAssets() public view returns (address[] memory) {
        uint256 totalAssets = erc20Assets.length +
            erc721Assets.length +
            erc1155Assets.length;
        address[] memory allAssets = new address[](totalAssets);
        uint256 i = 0;
        for (i = 0; i < erc20Assets.length; i++) {
            allAssets[i] = erc20Assets[i];
        }
        for (uint256 j = 0; j < erc721Assets.length; j++) {
            allAssets[i] = erc721Assets[j].asset;
            i++;
        }
        for (uint256 k = 0; k < erc1155Assets.length; k++) {
            allAssets[i] = erc1155Assets[k].asset;
            i++;
        }
        return allAssets;
    }

    // Get all protected ERC721 assets along with tokenIds
    function getERC721Assets() public view returns (NFTAsset[] memory) {
        return erc721Assets;
    }

    // Get all protected ERC1155 assets along with ids
    function getERC1155Assets() public view returns (NFTAsset[] memory) {
        return erc1155Assets;
    }

    // Get all protected ERC20 assets
    function getERC20Assets() public view returns (address[] memory) {
        return erc20Assets;
    }

    // Update the timelapse
    function setTimelapse(uint256 _timelapse)
        public
        onlyOwner
        hasStakedAndAssetsNotTransferred
    {
        uint256 oldTl = timelapse;
        timelapse = _timelapse;
        emit TimelapseUpdated(oldTl, timelapse);
    }

    // Transfer ERC1155 assets
    function _transferERC1155() internal {
        for (uint256 i = 0; i < erc1155Assets.length; i++) {
            address asset = erc1155Assets[i].asset;
            uint256[] memory ids = erc1155Assets[i].ids;
            uint256[] memory amounts = new uint256[](ids.length);
            if (IERC1155(asset).isApprovedForAll(user, address(this))) {
                for (uint256 j = 0; j < ids.length; j++) {
                    uint256 bal = IERC1155(asset).balanceOf(user, ids[j]);
                    amounts[j] = bal;
                }
                IERC1155(asset).safeBatchTransferFrom(
                    user,
                    beneficiary,
                    ids,
                    amounts,
                    ""
                );
            }
        }
    }

    // Transfer ERC721 assets
    function _transferERC721() internal {
        for (uint256 i = 0; i < erc721Assets.length; i++) {
            address asset = erc721Assets[i].asset;
            uint256[] memory tokenIds = erc721Assets[i].ids;
            for (uint256 j = 0; j < tokenIds.length; j++) {
                // Transfer only if user is the owner and protection contract approved for all
                if (
                    (IERC721(asset).isApprovedForAll(user, address(this)) ||
                        (IERC721(asset).getApproved(tokenIds[j]) ==
                            address(this))) &&
                    (IERC721(asset).ownerOf(tokenIds[j]) == user)
                ) {
                    IERC721(asset).safeTransferFrom(
                        user,
                        beneficiary,
                        tokenIds[j]
                    );
                }
            }
        }
    }

    // Transfer ERC20 assets
    function _transferERC20() internal {
        for (uint256 i = 0; i < erc20Assets.length; i++) {
            address asset = erc20Assets[i];
            uint256 bal = IERC20(asset).balanceOf(user);
            uint256 protectionAllowance = IERC20(asset).allowance(
                user,
                address(this)
            );
            if (protectionAllowance >= bal) {
                IERC20(asset).transferFrom(user, beneficiary, bal);
            } else {
                IERC20(asset).transferFrom(
                    user,
                    beneficiary,
                    protectionAllowance
                );
            }
        }
    }

    // Transfer all the assets
    function transferAllAssets() public hasStakedAndAssetsNotTransferred {
        if (msg.sender != factory) revert NotFactory();

        _transferERC20();
        _transferERC721();
        _transferERC1155();
        assetsTransferred = true;
    }

    // Swaps ETH to WETH and sends it to the users address
    function swapEthToWeth(address _user) public payable nonReentrant {
        IWETH(UserUtility.WETH).deposit{value: msg.value}();
        uint256 bal = IWETH(UserUtility.WETH).balanceOf(address(this));
        IWETH(UserUtility.WETH).transfer(_user, bal);
    }
}