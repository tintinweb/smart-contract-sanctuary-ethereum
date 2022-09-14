/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol

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

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol

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

// File: @openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol

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

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol

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
interface IERC20PermitUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol

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

    function safePermit(
        IERC20PermitUpgradeable token,
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

// File: contracts/interfaces/IUniverse.sol


// IUniverse.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @title Universal Controller interface
 * @dev ...
 */
interface IUniverse {
    event ChargedParticlesSet(address indexed chargedParticles);
    event PhotonSet(address indexed photonToken, uint256 maxSupply);
    event ProtonTokenSet(address indexed protonToken);
    event LeptonTokenSet(address indexed leptonToken);
    event QuarkTokenSet(address indexed quarkToken);
    event BosonTokenSet(address indexed bosonToken);
    event EsaMultiplierSet(address indexed assetToken, uint256 multiplier);
    event ElectrostaticAttraction(
        address indexed account,
        address photonSource,
        uint256 energy,
        uint256 multiplier
    );
    event ElectrostaticDischarge(
        address indexed account,
        address photonSource,
        uint256 energy
    );

    function onEnergize(
        address sender,
        address referrer,
        address contractAddress,
        uint256 tokenId,
        string calldata managerId,
        address assetToken,
        uint256 assetEnergy
    ) external;

    function onDischarge(
        address contractAddress,
        uint256 tokenId,
        string calldata managerId,
        address assetToken,
        uint256 creatorEnergy,
        uint256 receiverEnergy
    ) external;

    function onDischargeForCreator(
        address contractAddress,
        uint256 tokenId,
        string calldata managerId,
        address creator,
        address assetToken,
        uint256 receiverEnergy
    ) external;

    function onRelease(
        address contractAddress,
        uint256 tokenId,
        string calldata managerId,
        address assetToken,
        uint256 principalEnergy,
        uint256 creatorEnergy,
        uint256 receiverEnergy
    ) external;

    function onCovalentBond(
        address contractAddress,
        uint256 tokenId,
        string calldata managerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external;

    function onCovalentBreak(
        address contractAddress,
        uint256 tokenId,
        string calldata managerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external;

    function onProtonSale(
        address contractAddress,
        uint256 tokenId,
        address oldOwner,
        address newOwner,
        uint256 salePrice,
        address creator,
        uint256 creatorRoyalties
    ) external;
}

// File: contracts/interfaces/IWalletManager.sol


// IWalletManager.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @title Particle Wallet Manager interface
 * @dev The wallet-manager for underlying assets attached to Charged Particles
 * @dev Manages the link between NFTs and their respective Smart-Wallets
 */
interface IWalletManager {
    event ControllerSet(address indexed controller);
    event ExecutorSet(address indexed executor);
    event PausedStateSet(bool isPaused);
    event NewSmartWallet(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed smartWallet,
        address creator,
        uint256 annuityPct
    );
    event WalletEnergized(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed assetToken,
        uint256 assetAmount,
        uint256 yieldTokensAmount
    );
    event WalletDischarged(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed assetToken,
        uint256 creatorAmount,
        uint256 receiverAmount
    );
    event WalletDischargedForCreator(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed assetToken,
        address creator,
        uint256 receiverAmount
    );
    event WalletReleased(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed receiver,
        address assetToken,
        uint256 principalAmount,
        uint256 creatorAmount,
        uint256 receiverAmount
    );
    event WalletRewarded(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed receiver,
        address rewardsToken,
        uint256 rewardsAmount
    );

    function isPaused() external view returns (bool);

    function isReserveActive(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external view returns (bool);

    function getReserveInterestToken(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external view returns (address);

    function getTotal(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external returns (uint256);

    function getPrincipal(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external returns (uint256);

    function getInterest(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external returns (uint256 creatorInterest, uint256 ownerInterest);

    function getRewards(
        address contractAddress,
        uint256 tokenId,
        address rewardToken
    ) external returns (uint256);

    function energize(
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 yieldTokensAmount);

    function discharge(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        address creatorRedirect
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        uint256 assetAmount,
        address creatorRedirect
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeAmountForCreator(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address creator,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 receiverAmount);

    function release(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        address creatorRedirect
    )
        external
        returns (
            uint256 principalAmount,
            uint256 creatorAmount,
            uint256 receiverAmount
        );

    function releaseAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address assetToken,
        uint256 assetAmount,
        address creatorRedirect
    )
        external
        returns (
            uint256 principalAmount,
            uint256 creatorAmount,
            uint256 receiverAmount
        );

    function withdrawRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address rewardsToken,
        uint256 rewardsAmount
    ) external returns (uint256 amount);

    function executeForAccount(
        address contractAddress,
        uint256 tokenId,
        address externalAddress,
        uint256 ethValue,
        bytes memory encodedParams
    ) external returns (bytes memory);

    function refreshPrincipal(
        address contractAddress,
        uint256 tokenId,
        address assetToken
    ) external;

    function getWalletAddressById(
        address contractAddress,
        uint256 tokenId,
        address creator,
        uint256 annuityPct
    ) external returns (address);

    function withdrawEther(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        uint256 amount
    ) external;

    function withdrawERC20(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external;

    function withdrawERC721(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address nftTokenAddress,
        uint256 nftTokenId
    ) external;
}

// File: contracts/interfaces/IBasketManager.sol


// IBasketManager.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @title Particle Basket Manager interface
 * @dev The basket-manager for underlying assets attached to Charged Particles
 * @dev Manages the link between NFTs and their respective Smart-Baskets
 */
interface IBasketManager {
    event ControllerSet(address indexed controller);
    event ExecutorSet(address indexed executor);
    event PausedStateSet(bool isPaused);
    event NewSmartBasket(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed smartBasket
    );
    event BasketAdd(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address basketTokenAddress,
        uint256 basketTokenId,
        uint256 basketTokenAmount
    );
    event BasketRemove(
        address indexed receiver,
        address indexed contractAddress,
        uint256 indexed tokenId,
        address basketTokenAddress,
        uint256 basketTokenId,
        uint256 basketTokenAmount
    );
    event BasketRewarded(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed receiver,
        address rewardsToken,
        uint256 rewardsAmount
    );

    function isPaused() external view returns (bool);

    function getTokenTotalCount(address contractAddress, uint256 tokenId)
        external
        view
        returns (uint256);

    function getTokenCountByType(
        address contractAddress,
        uint256 tokenId,
        address basketTokenAddress,
        uint256 basketTokenId
    ) external returns (uint256);

    function prepareTransferAmount(uint256 nftTokenAmount) external;

    function addToBasket(
        address contractAddress,
        uint256 tokenId,
        address basketTokenAddress,
        uint256 basketTokenId
    ) external returns (bool);

    function removeFromBasket(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address basketTokenAddress,
        uint256 basketTokenId
    ) external returns (bool);

    function withdrawRewards(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        address rewardsToken,
        uint256 rewardsAmount
    ) external returns (uint256 amount);

    function executeForAccount(
        address contractAddress,
        uint256 tokenId,
        address externalAddress,
        uint256 ethValue,
        bytes memory encodedParams
    ) external returns (bytes memory);

    function getBasketAddressById(address contractAddress, uint256 tokenId)
        external
        returns (address);

    function withdrawEther(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        uint256 amount
    ) external;

    function withdrawERC20(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external;

    function withdrawERC721(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address nftTokenAddress,
        uint256 nftTokenId
    ) external;

    function withdrawERC1155(
        address contractAddress,
        uint256 tokenId,
        address payable receiver,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 amount
    ) external;
}

// File: contracts/interfaces/IChargedSettings.sol


// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;


/**
 * @notice Interface for Charged Settings
 */
interface IChargedSettings {
    /***********************************|
  |             Public API            |
  |__________________________________*/

    // function isContractOwner(address contractAddress, address account) external view returns (bool);
    function getCreatorAnnuities(address contractAddress, uint256 tokenId)
        external
        returns (address creator, uint256 annuityPct);

    function getCreatorAnnuitiesRedirect(
        address contractAddress,
        uint256 tokenId
    ) external view returns (address);

    function getTempLockExpiryBlocks() external view returns (uint256);

    function getTimelockApprovals(address operator)
        external
        view
        returns (bool timelockAny, bool timelockOwn);

    function getAssetRequirements(address contractAddress, address assetToken)
        external
        view
        returns (
            string memory requiredWalletManager,
            bool energizeEnabled,
            bool restrictedAssets,
            bool validAsset,
            uint256 depositCap,
            uint256 depositMin,
            uint256 depositMax,
            bool invalidAsset
        );

    function getNftAssetRequirements(
        address contractAddress,
        address nftTokenAddress
    )
        external
        view
        returns (
            string memory requiredBasketManager,
            bool basketEnabled,
            uint256 maxNfts
        );

    /***********************************|
  |         Only NFT Creator          |
  |__________________________________*/

    function setCreatorAnnuities(
        address contractAddress,
        uint256 tokenId,
        address creator,
        uint256 annuityPercent
    ) external;

    function setCreatorAnnuitiesRedirect(
        address contractAddress,
        uint256 tokenId,
        address receiver
    ) external;

    /***********************************|
  |      Only NFT Contract Owner      |
  |__________________________________*/

    function setRequiredWalletManager(
        address contractAddress,
        string calldata walletManager
    ) external;

    function setRequiredBasketManager(
        address contractAddress,
        string calldata basketManager
    ) external;

    function setAssetTokenRestrictions(
        address contractAddress,
        bool restrictionsEnabled
    ) external;

    function setAllowedAssetToken(
        address contractAddress,
        address assetToken,
        bool isAllowed
    ) external;

    function setAssetTokenLimits(
        address contractAddress,
        address assetToken,
        uint256 depositMin,
        uint256 depositMax
    ) external;

    function setMaxNfts(
        address contractAddress,
        address nftTokenAddress,
        uint256 maxNfts
    ) external;

    /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

    function setAssetInvalidity(address assetToken, bool invalidity) external;

    function enableNftContracts(address[] calldata contracts) external;

    function setPermsForCharge(address contractAddress, bool state) external;

    function setPermsForBasket(address contractAddress, bool state) external;

    function setPermsForTimelockAny(address contractAddress, bool state)
        external;

    function setPermsForTimelockSelf(address contractAddress, bool state)
        external;

    /***********************************|
  |          Particle Events          |
  |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);
    event DepositCapSet(address assetToken, uint256 depositCap);
    event TempLockExpirySet(uint256 expiryBlocks);

    event RequiredWalletManagerSet(
        address indexed contractAddress,
        string walletManager
    );
    event RequiredBasketManagerSet(
        address indexed contractAddress,
        string basketManager
    );
    event AssetTokenRestrictionsSet(
        address indexed contractAddress,
        bool restrictionsEnabled
    );
    event AllowedAssetTokenSet(
        address indexed contractAddress,
        address assetToken,
        bool isAllowed
    );
    event AssetTokenLimitsSet(
        address indexed contractAddress,
        address assetToken,
        uint256 assetDepositMin,
        uint256 assetDepositMax
    );
    event MaxNftsSet(
        address indexed contractAddress,
        address indexed nftTokenAddress,
        uint256 maxNfts
    );
    event AssetInvaliditySet(address indexed assetToken, bool invalidity);

    event TokenCreatorConfigsSet(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed creatorAddress,
        uint256 annuityPercent
    );
    event TokenCreatorAnnuitiesRedirected(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed redirectAddress
    );

    event PermsSetForCharge(address indexed contractAddress, bool state);
    event PermsSetForBasket(address indexed contractAddress, bool state);
    event PermsSetForTimelockAny(address indexed contractAddress, bool state);
    event PermsSetForTimelockSelf(address indexed contractAddress, bool state);
}

// File: contracts/interfaces/IChargedState.sol


// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @notice Interface for Charged State
 */
interface IChargedState {
    /***********************************|
  |             Public API            |
  |__________________________________*/

    function getDischargeTimelockExpiry(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256 lockExpiry);

    function getReleaseTimelockExpiry(address contractAddress, uint256 tokenId)
        external
        view
        returns (uint256 lockExpiry);

    function getBreakBondTimelockExpiry(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256 lockExpiry);

    function isApprovedForDischarge(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isApprovedForRelease(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isApprovedForBreakBond(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isApprovedForTimelock(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external returns (bool);

    function isEnergizeRestricted(address contractAddress, uint256 tokenId)
        external
        view
        returns (bool);

    function isCovalentBondRestricted(address contractAddress, uint256 tokenId)
        external
        view
        returns (bool);

    function getDischargeState(
        address contractAddress,
        uint256 tokenId,
        address sender
    )
        external
        returns (
            bool allowFromAll,
            bool isApproved,
            uint256 timelock,
            uint256 tempLockExpiry
        );

    function getReleaseState(
        address contractAddress,
        uint256 tokenId,
        address sender
    )
        external
        returns (
            bool allowFromAll,
            bool isApproved,
            uint256 timelock,
            uint256 tempLockExpiry
        );

    function getBreakBondState(
        address contractAddress,
        uint256 tokenId,
        address sender
    )
        external
        returns (
            bool allowFromAll,
            bool isApproved,
            uint256 timelock,
            uint256 tempLockExpiry
        );

    /***********************************|
  |      Only NFT Owner/Operator      |
  |__________________________________*/

    function setDischargeApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setReleaseApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setBreakBondApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setTimelockApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setApprovalForAll(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setPermsForRestrictCharge(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowDischarge(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowRelease(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForRestrictBond(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowBreakBond(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setDischargeTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    function setReleaseTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    function setBreakBondTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    /***********************************|
  |         Only NFT Contract         |
  |__________________________________*/

    function setTemporaryLock(
        address contractAddress,
        uint256 tokenId,
        bool isLocked
    ) external;

    /***********************************|
  |          Particle Events          |
  |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);

    event DischargeApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );
    event ReleaseApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );
    event BreakBondApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );
    event TimelockApproval(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address operator
    );

    event TokenDischargeTimelock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed operator,
        uint256 unlockBlock
    );
    event TokenReleaseTimelock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed operator,
        uint256 unlockBlock
    );
    event TokenBreakBondTimelock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address indexed operator,
        uint256 unlockBlock
    );
    event TokenTempLock(
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 unlockBlock
    );

    event PermsSetForRestrictCharge(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForAllowDischarge(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForAllowRelease(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForRestrictBond(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
    event PermsSetForAllowBreakBond(
        address indexed contractAddress,
        uint256 indexed tokenId,
        bool state
    );
}

// File: contracts/interfaces/IChargedManagers.sol


// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;


/**
 * @notice Interface for Charged Wallet-Managers
 */
interface IChargedManagers {
    /***********************************|
  |             Public API            |
  |__________________________________*/

    function isContractOwner(address contractAddress, address account)
        external
        view
        returns (bool);

    // ERC20
    function isWalletManagerEnabled(string calldata walletManagerId)
        external
        view
        returns (bool);

    function getWalletManager(string calldata walletManagerId)
        external
        view
        returns (IWalletManager);

    // ERC721
    function isNftBasketEnabled(string calldata basketId)
        external
        view
        returns (bool);

    function getBasketManager(string calldata basketId)
        external
        view
        returns (IBasketManager);

    // Validation
    function validateDeposit(
        address sender,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external;

    function validateNftDeposit(
        address sender,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external;

    function validateDischarge(
        address sender,
        address contractAddress,
        uint256 tokenId
    ) external;

    function validateRelease(
        address sender,
        address contractAddress,
        uint256 tokenId
    ) external;

    function validateBreakBond(
        address sender,
        address contractAddress,
        uint256 tokenId
    ) external;

    /***********************************|
  |          Particle Events          |
  |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);
    event WalletManagerRegistered(
        string indexed walletManagerId,
        address indexed walletManager
    );
    event BasketManagerRegistered(
        string indexed basketId,
        address indexed basketManager
    );
}

// File: contracts/interfaces/IChargedParticles.sol


// IChargedParticles.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

/**
 * @notice Interface for Charged Particles
 */
interface IChargedParticles {
    /***********************************|
  |             Public API            |
  |__________________________________*/

    function getStateAddress() external view returns (address stateAddress);

    function getSettingsAddress()
        external
        view
        returns (address settingsAddress);

    function getManagersAddress()
        external
        view
        returns (address managersAddress);

    function getFeesForDeposit(uint256 assetAmount)
        external
        view
        returns (uint256 protocolFee);

    function baseParticleMass(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleCharge(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleKinetics(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleCovalentBonds(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId
    ) external view returns (uint256);

    /***********************************|
  |        Particle Mechanics         |
  |__________________________________*/

    function energizeParticle(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount,
        address referrer
    ) external returns (uint256 yieldTokensAmount);

    function dischargeParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeParticleForCreator(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 receiverAmount);

    function releaseParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function releaseParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function covalentBond(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external returns (bool success);

    function breakCovalentBond(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) external returns (bool success);

    /***********************************|
  |          Particle Events          |
  |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);
    event DepositFeeSet(uint256 depositFee);
    event ProtocolFeesCollected(
        address indexed assetToken,
        uint256 depositAmount,
        uint256 feesCollected
    );
}

// File: contracts/interfaces/ITokenInfoProxy.sol


// TokenInfoProxy.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

interface ITokenInfoProxy {
    event ContractFunctionSignatureSet(
        address indexed contractAddress,
        string fnName,
        bytes4 fnSig
    );

    struct FnSignatures {
        bytes4 ownerOf;
        bytes4 creatorOf;
    }

    function setContractFnOwnerOf(address contractAddress, bytes4 fnSig)
        external;

    function setContractFnCreatorOf(address contractAddress, bytes4 fnSig)
        external;

    function getTokenUUID(address contractAddress, uint256 tokenId)
        external
        pure
        returns (uint256);

    function isNFTOwnerOrOperator(
        address contractAddress,
        uint256 tokenId,
        address sender
    ) external returns (bool);

    function isNFTContractOrCreator(
        address contractAddress,
        uint256 tokenId,
        address sender
    ) external returns (bool);

    function getTokenOwner(address contractAddress, uint256 tokenId)
        external
        returns (address);

    function getTokenCreator(address contractAddress, uint256 tokenId)
        external
        returns (address);
}

// File: contracts/lib/Bitwise.sol


// Bitwise.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

library Bitwise {
    function negate(uint32 a) internal pure returns (uint32) {
        return a ^ maxInt();
    }

    function shiftLeft(uint32 a, uint32 n) internal pure returns (uint32) {
        return a * uint32(2)**n;
    }

    function shiftRight(uint32 a, uint32 n) internal pure returns (uint32) {
        return a / uint32(2)**n;
    }

    function maxInt() internal pure returns (uint32) {
        return type(uint32).max;
    }

    // Get bit value at position
    function hasBit(uint32 a, uint32 n) internal pure returns (bool) {
        return a & shiftLeft(0x01, n) != 0;
    }

    // Set bit value at position
    function setBit(uint32 a, uint32 n) internal pure returns (uint32) {
        return a | shiftLeft(0x01, n);
    }

    // Set the bit into state "false"
    function clearBit(uint32 a, uint32 n) internal pure returns (uint32) {
        uint32 mask = negate(shiftLeft(0x01, n));
        return a & mask;
    }
}

// File: @opengsn/gsn/contracts/interfaces/IRelayRecipient.sol

pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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

// File: contracts/lib/RelayRecipient.sol


pragma solidity ^0.8.4;

contract RelayRecipient is BaseRelayRecipient {
    function versionRecipient() external view override returns (string memory) {
        return "1.0.0-beta.1/charged-particles.relay.recipient";
    }
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

// File: contracts/lib/BlackholePrevention.sol


// BlackholePrevention.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;





/**
 * @notice Prevents ETH or Tokens from getting stuck in a contract by allowing
 *  the Owner/DAO to pull them out on behalf of a user
 * This is only meant to contracts that are not expected to hold tokens, but do handle transferring them.
 */
contract BlackholePrevention {
    using Address for address payable;
    using SafeERC20 for IERC20;

    event WithdrawStuckEther(address indexed receiver, uint256 amount);
    event WithdrawStuckERC20(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 amount
    );
    event WithdrawStuckERC721(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event WithdrawStuckERC1155(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    function _withdrawEther(address payable receiver, uint256 amount)
        internal
        virtual
    {
        require(receiver != address(0x0), "BHP:E-403");
        if (address(this).balance >= amount) {
            receiver.sendValue(amount);
            emit WithdrawStuckEther(receiver, amount);
        }
    }

    function _withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (IERC20(tokenAddress).balanceOf(address(this)) >= amount) {
            IERC20(tokenAddress).safeTransfer(receiver, amount);
            emit WithdrawStuckERC20(receiver, tokenAddress, amount);
        }
    }

    function _withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (IERC721(tokenAddress).ownerOf(tokenId) == address(this)) {
            IERC721(tokenAddress).transferFrom(
                address(this),
                receiver,
                tokenId
            );
            emit WithdrawStuckERC721(receiver, tokenAddress, tokenId);
        }
    }

    function _withdrawERC1155(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (
            IERC1155(tokenAddress).balanceOf(address(this), tokenId) >= amount
        ) {
            IERC1155(tokenAddress).safeTransferFrom(
                address(this),
                receiver,
                tokenId,
                amount,
                ""
            );
            emit WithdrawStuckERC1155(receiver, tokenAddress, tokenId, amount);
        }
    }
}

// File: contracts/ChargedParticles.sol


// ChargedParticles.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


// import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
















/**
 * @notice Charged Particles V2 Contract
 * @dev Upgradeable Contract
 */
contract ChargedParticles is
    IChargedParticles,
    // Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    RelayRecipient,
    IERC721ReceiverUpgradeable,
    BlackholePrevention,
    IERC1155ReceiverUpgradeable
{
    // using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Bitwise for uint32;
    using AddressUpgradeable for address;

    uint256 internal constant PERCENTAGE_SCALE = 1e4; // 10000  (100%)

    //
    // Particle Terminology
    //
    //   Particle               - Non-fungible Token (NFT)
    //   Mass                   - Underlying Asset of a Token (ex; DAI)
    //   Charge                 - Accrued Interest on the Underlying Asset of a Token
    //   Charged Particle       - Any NFT that has a Mass and a Positive Charge
    //   Neutral Particle       - Any NFT that has a Mass and No Charge
    //   Energize / Recharge    - Deposit of an Underlying Asset into an NFT
    //   Discharge              - Withdraw the Accrued Interest of an NFT leaving the Particle with its initial Mass
    //   Release                - Withdraw the Underlying Asset & Accrued Interest of an NFT leaving the Particle with No Mass or Charge
    //
    //   Proton                 - NFTs minted from the Charged Particle Accelerator
    //                            - A proton is a subatomic particle, symbol p or p⁺, with a positive electric charge of +1e elementary
    //                              charge and a mass slightly less than that of a neutron.
    //   Ion                    - Platform Governance Token
    //                            - A charged subatomic particle. An atom or group of atoms that carries a positive or negative electric charge
    //                              as a result of having lost or gained one or more electrons.
    //

    // Linked Contracts
    IUniverse internal _universe;
    IChargedState internal _chargedState;
    IChargedSettings internal _chargedSettings;
    address internal _lepton;
    uint256 internal depositFee;
    ITokenInfoProxy internal _tokenInfoProxy;
    IChargedManagers internal _chargedManagers;

    /***********************************|
  |          Initialization           |
  |__________________________________*/

    function initialize(address initiator) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        emit Initialized(initiator);
    }

    /***********************************|
  |         Public Functions          |
  |__________________________________*/

    function getStateAddress()
        external
        view
        virtual
        override
        returns (address stateAddress)
    {
        return address(_chargedState);
    }

    function getSettingsAddress()
        external
        view
        virtual
        override
        returns (address settingsAddress)
    {
        return address(_chargedSettings);
    }

    function getManagersAddress()
        external
        view
        virtual
        override
        returns (address managersAddress)
    {
        return address(_chargedManagers);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

    // Unimplemented
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ""; // IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector;
    }

    function supportsInterface(
        bytes4 /* interfaceId */
    ) external view virtual override returns (bool) {
        return false;
    }

    /// @notice Calculates the amount of Fees to be paid for a specific deposit amount
    /// @param assetAmount The Amount of Assets to calculate Fees on
    /// @return protocolFee The amount of deposit fees for the protocol
    function getFeesForDeposit(uint256 assetAmount)
        external
        view
        override
        returns (uint256 protocolFee)
    {
        protocolFee = _getFeesForDeposit(assetAmount);
    }

    /// @notice Gets the Amount of Asset Tokens that have been Deposited into the Particle
    /// representing the Mass of the Particle.
    /// @param contractAddress      The Address to the Contract of the Token
    /// @param tokenId              The ID of the Token
    /// @param walletManagerId  The Liquidity-Provider ID to check the Asset balance of
    /// @param assetToken           The Address of the Asset Token to check
    /// @return The Amount of underlying Assets held within the Token
    function baseParticleMass(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        returns (uint256)
    {
        return
            _baseParticleMass(
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken
            );
    }

    /// @notice Gets the amount of Interest that the Particle has generated representing
    /// the Charge of the Particle
    /// @param contractAddress      The Address to the Contract of the Token
    /// @param tokenId              The ID of the Token
    /// @param walletManagerId  The Liquidity-Provider ID to check the Interest balance of
    /// @param assetToken           The Address of the Asset Token to check
    /// @return The amount of interest the Token has generated (in Asset Token)
    function currentParticleCharge(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        returns (uint256)
    {
        return
            _currentParticleCharge(
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken
            );
    }

    /// @notice Gets the amount of LP Tokens that the Particle has generated representing
    /// the Kinetics of the Particle
    /// @param contractAddress      The Address to the Contract of the Token
    /// @param tokenId              The ID of the Token
    /// @param walletManagerId  The Liquidity-Provider ID to check the Kinetics balance of
    /// @param assetToken           The Address of the Asset Token to check
    /// @return The amount of LP tokens that have been generated
    function currentParticleKinetics(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        returns (uint256)
    {
        return
            _currentParticleKinetics(
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken
            );
    }

    /// @notice Gets the total amount of ERC721 Tokens that the Particle holds
    /// @param contractAddress  The Address to the Contract of the Token
    /// @param tokenId          The ID of the Token
    /// @param basketManagerId  The ID of the BasketManager to check the token balance of
    /// @return The total amount of ERC721 tokens that are held  within the Particle
    function currentParticleCovalentBonds(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId
    )
        external
        view
        virtual
        override
        basketEnabled(basketManagerId)
        returns (uint256)
    {
        return
            _currentParticleCovalentBonds(
                contractAddress,
                tokenId,
                basketManagerId
            );
    }

    /***********************************|
  |        Energize Particles         |
  |__________________________________*/

    /// @notice Fund Particle with Asset Token
    ///    Must be called by the account providing the Asset
    ///    Account must Approve THIS contract as Operator of Asset
    ///
    /// NOTE: DO NOT Energize an ERC20 Token, as anyone who holds any amount
    ///       of the same ERC20 token could discharge or release the funds.
    ///       All holders of the ERC20 token would essentially be owners of the Charged Particle.
    ///
    /// @param contractAddress      The Address to the Contract of the Token to Energize
    /// @param tokenId              The ID of the Token to Energize
    /// @param walletManagerId  The Asset-Pair to Energize the Token with
    /// @param assetToken           The Address of the Asset Token being used
    /// @param assetAmount          The Amount of Asset Token to Energize the Token with
    /// @return yieldTokensAmount The amount of Yield-bearing Tokens added to the escrow for the Token
    function energizeParticle(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount,
        address referrer
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        nonReentrant
        returns (uint256 yieldTokensAmount)
    {
        _validateDeposit(
            contractAddress,
            tokenId,
            walletManagerId,
            assetToken,
            assetAmount
        );

        // Transfer ERC20 Token from Caller to Contract (reverts on fail)
        uint256 feeAmount = _collectAssetToken(
            _msgSender(),
            assetToken,
            assetAmount
        );

        // Deposit Asset Token directly into Smart Wallet (reverts on fail) and Update WalletManager
        yieldTokensAmount = _depositIntoWalletManager(
            contractAddress,
            tokenId,
            walletManagerId,
            assetToken,
            assetAmount,
            feeAmount
        );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onEnergize(
                _msgSender(),
                referrer,
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken,
                assetAmount
            );
        }
    }

    /***********************************|
  |        Discharge Particles        |
  |__________________________________*/

    /// @notice Allows the owner or operator of the Token to collect or transfer the interest generated
    ///         from the token without removing the underlying Asset that is held within the token.
    /// @param receiver             The Address to Receive the Discharged Asset Tokens
    /// @param contractAddress      The Address to the Contract of the Token to Discharge
    /// @param tokenId              The ID of the Token to Discharge
    /// @param walletManagerId      The Wallet Manager of the Assets to Discharge from the Token
    /// @param assetToken           The Address of the Asset Token being discharged
    /// @return creatorAmount Amount of Asset Token discharged to the Creator
    /// @return receiverAmount Amount of Asset Token discharged to the Receiver
    function dischargeParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        nonReentrant
        returns (uint256 creatorAmount, uint256 receiverAmount)
    {
        _validateDischarge(contractAddress, tokenId);

        address creatorRedirect = _chargedSettings.getCreatorAnnuitiesRedirect(
            contractAddress,
            tokenId
        );
        (creatorAmount, receiverAmount) = _chargedManagers
            .getWalletManager(walletManagerId)
            .discharge(
                receiver,
                contractAddress,
                tokenId,
                assetToken,
                creatorRedirect
            );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onDischarge(
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken,
                creatorAmount,
                receiverAmount
            );
        }
    }

    /// @notice Allows the owner or operator of the Token to collect or transfer a specific amount of the interest
    ///         generated from the token without removing the underlying Asset that is held within the token.
    /// @param receiver             The Address to Receive the Discharged Asset Tokens
    /// @param contractAddress      The Address to the Contract of the Token to Discharge
    /// @param tokenId              The ID of the Token to Discharge
    /// @param walletManagerId  The Wallet Manager of the Assets to Discharge from the Token
    /// @param assetToken           The Address of the Asset Token being discharged
    /// @param assetAmount          The specific amount of Asset Token to Discharge from the Token
    /// @return creatorAmount Amount of Asset Token discharged to the Creator
    /// @return receiverAmount Amount of Asset Token discharged to the Receiver
    function dischargeParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        nonReentrant
        returns (uint256 creatorAmount, uint256 receiverAmount)
    {
        _validateDischarge(contractAddress, tokenId);

        address creatorRedirect = _chargedSettings.getCreatorAnnuitiesRedirect(
            contractAddress,
            tokenId
        );
        (creatorAmount, receiverAmount) = _chargedManagers
            .getWalletManager(walletManagerId)
            .dischargeAmount(
                receiver,
                contractAddress,
                tokenId,
                assetToken,
                assetAmount,
                creatorRedirect
            );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onDischarge(
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken,
                creatorAmount,
                receiverAmount
            );
        }
    }

    /// @notice Allows the Creator of the Token to collect or transfer a their portion of the interest (if any)
    ///         generated from the token without removing the underlying Asset that is held within the token.
    /// @param receiver             The Address to Receive the Discharged Asset Tokens
    /// @param contractAddress      The Address to the Contract of the Token to Discharge
    /// @param tokenId              The ID of the Token to Discharge
    /// @param walletManagerId  The Wallet Manager of the Assets to Discharge from the Token
    /// @param assetToken           The Address of the Asset Token being discharged
    /// @param assetAmount          The specific amount of Asset Token to Discharge from the Particle
    /// @return receiverAmount      Amount of Asset Token discharged to the Receiver
    function dischargeParticleForCreator(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        nonReentrant
        returns (uint256 receiverAmount)
    {
        address sender = _msgSender();
        address tokenCreator = _tokenInfoProxy.getTokenCreator(
            contractAddress,
            tokenId
        );
        require(sender == tokenCreator, "CP:E-104");

        receiverAmount = _chargedManagers
            .getWalletManager(walletManagerId)
            .dischargeAmountForCreator(
                receiver,
                contractAddress,
                tokenId,
                sender,
                assetToken,
                assetAmount
            );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onDischargeForCreator(
                contractAddress,
                tokenId,
                walletManagerId,
                sender,
                assetToken,
                receiverAmount
            );
        }
    }

    /***********************************|
  |         Release Particles         |
  |__________________________________*/

    /// @notice Releases the Full amount of Asset + Interest held within the Particle by LP of the Assets
    /// @param receiver             The Address to Receive the Released Asset Tokens
    /// @param contractAddress      The Address to the Contract of the Token to Release
    /// @param tokenId              The ID of the Token to Release
    /// @param walletManagerId  The Wallet Manager of the Assets to Release from the Token
    /// @param assetToken           The Address of the Asset Token being released
    /// @return creatorAmount Amount of Asset Token released to the Creator
    /// @return receiverAmount Amount of Asset Token released to the Receiver (includes principalAmount)
    function releaseParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        nonReentrant
        returns (uint256 creatorAmount, uint256 receiverAmount)
    {
        _validateRelease(contractAddress, tokenId);

        // Release Particle to Receiver
        uint256 principalAmount;
        address creatorRedirect = _chargedSettings.getCreatorAnnuitiesRedirect(
            contractAddress,
            tokenId
        );
        (principalAmount, creatorAmount, receiverAmount) = _chargedManagers
            .getWalletManager(walletManagerId)
            .release(
                receiver,
                contractAddress,
                tokenId,
                assetToken,
                creatorRedirect
            );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onRelease(
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken,
                principalAmount,
                creatorAmount,
                receiverAmount
            );
        }
    }

    /// @notice Releases a partial amount of Asset + Interest held within the Particle by LP of the Assets
    /// @param receiver             The Address to Receive the Released Asset Tokens
    /// @param contractAddress      The Address to the Contract of the Token to Release
    /// @param tokenId              The ID of the Token to Release
    /// @param walletManagerId      The Wallet Manager of the Assets to Release from the Token
    /// @param assetToken           The Address of the Asset Token being released
    /// @param assetAmount          The specific amount of Asset Token to Release from the Particle
    /// @return creatorAmount Amount of Asset Token released to the Creator
    /// @return receiverAmount Amount of Asset Token released to the Receiver (includes principalAmount)
    function releaseParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    )
        external
        virtual
        override
        managerEnabled(walletManagerId)
        nonReentrant
        returns (uint256 creatorAmount, uint256 receiverAmount)
    {
        _validateRelease(contractAddress, tokenId);

        // Release Particle to Receiver
        uint256 principalAmount;
        address creatorRedirect = _chargedSettings.getCreatorAnnuitiesRedirect(
            contractAddress,
            tokenId
        );
        (principalAmount, creatorAmount, receiverAmount) = _chargedManagers
            .getWalletManager(walletManagerId)
            .releaseAmount(
                receiver,
                contractAddress,
                tokenId,
                assetToken,
                assetAmount,
                creatorRedirect
            );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onRelease(
                contractAddress,
                tokenId,
                walletManagerId,
                assetToken,
                principalAmount,
                creatorAmount,
                receiverAmount
            );
        }
    }

    /***********************************|
  |         Covalent Bonding          |
  |__________________________________*/

    /// @notice Deposit other NFT Assets into the Particle
    ///    Must be called by the account providing the Asset
    ///    Account must Approve THIS contract as Operator of Asset
    ///
    /// @param contractAddress      The Address to the Contract of the Token to Energize
    /// @param tokenId              The ID of the Token to Energize
    /// @param basketManagerId      The Basket to Deposit the NFT into
    /// @param nftTokenAddress      The Address of the NFT Token being deposited
    /// @param nftTokenId           The ID of the NFT Token being deposited
    /// @param nftTokenAmount       The amount of Tokens to Deposit (ERC1155-specific)
    function covalentBond(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    )
        external
        virtual
        override
        basketEnabled(basketManagerId)
        nonReentrant
        returns (bool success)
    {
        _validateNftDeposit(
            contractAddress,
            tokenId,
            basketManagerId,
            nftTokenAddress,
            nftTokenId,
            nftTokenAmount
        );

        // Transfer ERC721 Token from Caller to Contract (reverts on fail)
        _collectNftToken(
            _msgSender(),
            nftTokenAddress,
            nftTokenId,
            nftTokenAmount
        );

        // Deposit Asset Token directly into Smart Wallet (reverts on fail) and Update WalletManager
        success = _depositIntoBasketManager(
            contractAddress,
            tokenId,
            basketManagerId,
            nftTokenAddress,
            nftTokenId,
            nftTokenAmount
        );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onCovalentBond(
                contractAddress,
                tokenId,
                basketManagerId,
                nftTokenAddress,
                nftTokenId,
                nftTokenAmount
            );
        }
    }

    /// @notice Release NFT Assets from the Particle
    /// @param receiver             The Address to Receive the Released Asset Tokens
    /// @param contractAddress      The Address to the Contract of the Token to Energize
    /// @param tokenId              The ID of the Token to Energize
    /// @param basketManagerId      The Basket to Deposit the NFT into
    /// @param nftTokenAddress      The Address of the NFT Token being deposited
    /// @param nftTokenId           The ID of the NFT Token being deposited
    /// @param nftTokenAmount       The amount of Tokens to Withdraw (ERC1155-specific)
    function breakCovalentBond(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    )
        external
        virtual
        override
        basketEnabled(basketManagerId)
        nonReentrant
        returns (bool success)
    {
        _validateBreakBond(contractAddress, tokenId);

        IBasketManager basketMgr = _chargedManagers.getBasketManager(
            basketManagerId
        );
        if (
            keccak256(abi.encodePacked(basketManagerId)) !=
            keccak256(abi.encodePacked("generic"))
        ) {
            basketMgr.prepareTransferAmount(nftTokenAmount);
        }

        // Release Particle to Receiver
        success = basketMgr.removeFromBasket(
            receiver,
            contractAddress,
            tokenId,
            nftTokenAddress,
            nftTokenId
        );

        // Signal to Universe Controller
        if (address(_universe) != address(0)) {
            _universe.onCovalentBreak(
                contractAddress,
                tokenId,
                basketManagerId,
                nftTokenAddress,
                nftTokenId,
                nftTokenAmount
            );
        }
    }

    /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

    /// @dev Setup the various Charged-Controllers
    function setController(address controller, string calldata controllerId)
        external
        virtual
        onlyOwner
    {
        bytes32 controllerIdStr = keccak256(abi.encodePacked(controllerId));

        if (controllerIdStr == keccak256(abi.encodePacked("universe"))) {
            _universe = IUniverse(controller);
        } else if (controllerIdStr == keccak256(abi.encodePacked("settings"))) {
            _chargedSettings = IChargedSettings(controller);
        } else if (controllerIdStr == keccak256(abi.encodePacked("state"))) {
            _chargedState = IChargedState(controller);
        } else if (controllerIdStr == keccak256(abi.encodePacked("managers"))) {
            _chargedManagers = IChargedManagers(controller);
        } else if (controllerIdStr == keccak256(abi.encodePacked("leptons"))) {
            _lepton = controller;
        } else if (
            controllerIdStr == keccak256(abi.encodePacked("forwarder"))
        ) {
            trustedForwarder = controller;
        } else if (
            controllerIdStr == keccak256(abi.encodePacked("tokeninfo"))
        ) {
            _tokenInfoProxy = ITokenInfoProxy(controller);
        }

        emit ControllerSet(controller, controllerId);
    }

    /***********************************|
  |          Protocol Fees            |
  |__________________________________*/

    /// @dev Setup the Base Deposit Fee for the Protocol
    function setDepositFee(uint256 fee) external onlyOwner {
        require(fee < PERCENTAGE_SCALE, "CP:E-421");
        depositFee = fee;
        emit DepositFeeSet(fee);
    }

    /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

    function withdrawEther(address payable receiver, uint256 amount)
        external
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawErc20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) external onlyOwner {
        _withdrawERC721(receiver, tokenAddress, tokenId);
    }

    function withdrawERC1155(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
    }

    /***********************************|
  |         Private Functions         |
  |__________________________________*/

    /// @dev Validates a Deposit according to the rules set by the Token Contract
    /// @param contractAddress      The Address to the Contract of the External NFT to check
    /// @param tokenId              The Token ID of the External NFT to check
    /// @param walletManagerId  The Wallet Manager of the Assets to Deposit
    /// @param assetToken           The Address of the Asset Token to Deposit
    /// @param assetAmount          The specific amount of Asset Token to Deposit
    function _validateDeposit(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) internal virtual {
        _chargedManagers.validateDeposit(
            _msgSender(),
            contractAddress,
            tokenId,
            walletManagerId,
            assetToken,
            assetAmount
        );
    }

    /// @dev Validates an NFT Deposit according to the rules set by the Token Contract
    /// @param contractAddress      The Address to the Contract of the External NFT to check
    /// @param tokenId              The Token ID of the External NFT to check
    /// @param basketManagerId      The Basket to Deposit the NFT into
    /// @param nftTokenAddress      The Address of the NFT Token being deposited
    /// @param nftTokenId           The ID of the NFT Token being deposited
    /// @param nftTokenAmount       The amount of Tokens to Deposit (ERC1155-specific)
    function _validateNftDeposit(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) internal virtual {
        _chargedManagers.validateNftDeposit(
            _msgSender(),
            contractAddress,
            tokenId,
            basketManagerId,
            nftTokenAddress,
            nftTokenId,
            nftTokenAmount
        );
    }

    function _validateDischarge(address contractAddress, uint256 tokenId)
        internal
        virtual
    {
        _chargedManagers.validateDischarge(
            _msgSender(),
            contractAddress,
            tokenId
        );
    }

    function _validateRelease(address contractAddress, uint256 tokenId)
        internal
        virtual
    {
        _chargedManagers.validateRelease(
            _msgSender(),
            contractAddress,
            tokenId
        );
    }

    function _validateBreakBond(address contractAddress, uint256 tokenId)
        internal
        virtual
    {
        _chargedManagers.validateBreakBond(
            _msgSender(),
            contractAddress,
            tokenId
        );
    }

    /// @dev Deposit Asset Tokens into an NFT via the Wallet Manager
    /// @param contractAddress      The Address to the Contract of the NFT
    /// @param tokenId              The Token ID of the NFT
    /// @param walletManagerId  The Wallet Manager of the Assets to Deposit
    /// @param assetToken           The Address of the Asset Token to Deposit
    /// @param assetAmount          The specific amount of Asset Token to Deposit
    /// @param feeAmount            The Amount of Protocol Fees charged
    function _depositIntoWalletManager(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount,
        uint256 feeAmount
    ) internal virtual returns (uint256) {
        // Get Wallet-Manager for LP
        IWalletManager lpWalletMgr = _chargedManagers.getWalletManager(
            walletManagerId
        );

        (address creator, uint256 annuityPct) = _chargedSettings
            .getCreatorAnnuities(contractAddress, tokenId);

        // Deposit Asset Token directly into Smart Wallet (reverts on fail) and Update WalletManager
        address wallet = lpWalletMgr.getWalletAddressById(
            contractAddress,
            tokenId,
            creator,
            annuityPct
        );
        IERC20Upgradeable(assetToken).transfer(wallet, assetAmount);

        emit ProtocolFeesCollected(assetToken, assetAmount, feeAmount);

        return
            lpWalletMgr.energize(
                contractAddress,
                tokenId,
                assetToken,
                assetAmount
            );
    }

    /// @dev Deposit NFT Tokens into the Basket Manager
    /// @param contractAddress      The Address to the Contract of the NFT
    /// @param tokenId              The Token ID of the NFT
    /// @param basketManagerId      The Wallet Manager of the Assets to Deposit
    /// @param nftTokenAddress      The Address of the Asset Token to Deposit
    /// @param nftTokenId           The specific amount of Asset Token to Deposit
    /// @param nftTokenAmount       The amount of Tokens to Deposit (ERC1155-specific)
    function _depositIntoBasketManager(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) internal virtual returns (bool) {
        // Deposit NFT Token directly into Smart Wallet (reverts on fail) and Update BasketManager
        IBasketManager basketMgr = _chargedManagers.getBasketManager(
            basketManagerId
        );
        address wallet = basketMgr.getBasketAddressById(
            contractAddress,
            tokenId
        );

        if (
            keccak256(abi.encodePacked(basketManagerId)) !=
            keccak256(abi.encodePacked("generic"))
        ) {
            basketMgr.prepareTransferAmount(nftTokenAmount);
        }

        if (_isERC1155(nftTokenAddress)) {
            if (nftTokenAmount == 0) {
                nftTokenAmount = 1;
            }
            IERC1155Upgradeable(nftTokenAddress).safeTransferFrom(
                address(this),
                wallet,
                nftTokenId,
                nftTokenAmount,
                ""
            );
        } else {
            IERC721Upgradeable(nftTokenAddress).transferFrom(
                address(this),
                wallet,
                nftTokenId
            );
        }
        return
            basketMgr.addToBasket(
                contractAddress,
                tokenId,
                nftTokenAddress,
                nftTokenId
            );
    }

    /**
     * @dev Calculates the amount of Fees to be paid for a specific deposit amount
     *   Fees are calculated in Interest-Token as they are the type collected for Fees
     * @param assetAmount The Amount of Assets to calculate Fees on
     * @return protocolFee The amount of fees reserved for the protocol
     */
    function _getFeesForDeposit(uint256 assetAmount)
        internal
        view
        returns (uint256 protocolFee)
    {
        if (depositFee > 0) {
            protocolFee = (assetAmount * (depositFee)) / (PERCENTAGE_SCALE);
        }
    }

    /// @dev Collects the Required ERC20 Token(s) from the users wallet
    ///   Be sure to Approve this Contract to transfer your Token(s)
    /// @param from         The owner address to collect the tokens from
    /// @param tokenAddress  The addres of the token to transfer
    /// @param tokenAmount  The amount of tokens to collect
    function _collectAssetToken(
        address from,
        address tokenAddress,
        uint256 tokenAmount
    ) internal virtual returns (uint256 protocolFee) {
        protocolFee = _getFeesForDeposit(tokenAmount);
        IERC20Upgradeable(tokenAddress).safeTransferFrom(
            from,
            address(this),
            tokenAmount + (protocolFee)
        );
    }

    /// @dev Collects the Required ERC721 Token(s) from the users wallet
    ///   Be sure to Approve this Contract to transfer your Token(s)
    /// @param from             The owner address to collect the tokens from
    /// @param nftTokenAddress  The address of the NFT token to transfer
    /// @param nftTokenId       The ID of the NFT token to transfer
    /// @param nftTokenAmount   The amount of Tokens to Transfer (ERC1155-specific)
    function _collectNftToken(
        address from,
        address nftTokenAddress,
        uint256 nftTokenId,
        uint256 nftTokenAmount
    ) internal virtual {
        if (_isERC1155(nftTokenAddress)) {
            IERC1155Upgradeable(nftTokenAddress).safeTransferFrom(
                from,
                address(this),
                nftTokenId,
                nftTokenAmount,
                ""
            );
        } else {
            IERC721Upgradeable(nftTokenAddress).safeTransferFrom(
                from,
                address(this),
                nftTokenId
            );
        }
    }

    /// @dev Checks if an NFT token contract supports the ERC1155 standard interface
    function _isERC1155(address nftTokenAddress)
        internal
        view
        virtual
        returns (bool)
    {
        bytes4 _INTERFACE_ID_ERC1155 = 0xd9b67a26;
        return
            IERC165Upgradeable(nftTokenAddress).supportsInterface(
                _INTERFACE_ID_ERC1155
            );
    }

    /// @dev See {ChargedParticles-baseParticleMass}.
    function _baseParticleMass(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) internal virtual returns (uint256) {
        return
            _chargedManagers.getWalletManager(walletManagerId).getPrincipal(
                contractAddress,
                tokenId,
                assetToken
            );
    }

    /// @dev See {ChargedParticles-currentParticleCharge}.
    function _currentParticleCharge(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) internal virtual returns (uint256) {
        (, uint256 ownerInterest) = _chargedManagers
            .getWalletManager(walletManagerId)
            .getInterest(contractAddress, tokenId, assetToken);
        return ownerInterest;
    }

    /// @dev See {ChargedParticles-currentParticleKinetics}.
    function _currentParticleKinetics(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) internal virtual returns (uint256) {
        return
            _chargedManagers.getWalletManager(walletManagerId).getRewards(
                contractAddress,
                tokenId,
                assetToken
            );
    }

    /// @dev See {ChargedParticles-currentParticleCovalentBonds}.
    function _currentParticleCovalentBonds(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId
    ) internal view virtual returns (uint256) {
        return
            _chargedManagers
                .getBasketManager(basketManagerId)
                .getTokenTotalCount(contractAddress, tokenId);
    }

    /***********************************|
  |          GSN/MetaTx Relay         |
  |__________________________________*/

    // @dev See {BaseRelayRecipient-_msgSender}.
    function _msgSender()
        internal
        view
        virtual
        override(BaseRelayRecipient, ContextUpgradeable)
        returns (address payable)
    {
        return super._msgSender();
        // return payable(BaseRelayRecipient._msgSender());
    }

    // @dev See {BaseRelayRecipient-_msgData}.
    function _msgData()
        internal
        view
        virtual
        override(BaseRelayRecipient, ContextUpgradeable)
        returns (bytes memory)
    {
        return super._msgData();
        // return BaseRelayRecipient._msgData();
    }

    /***********************************|
  |             Modifiers             |
  |__________________________________*/

    modifier managerEnabled(string calldata walletManagerId) {
        require(
            _chargedManagers.isWalletManagerEnabled(walletManagerId),
            "CP:E-419"
        );
        _;
    }

    modifier basketEnabled(string calldata basketManagerId) {
        require(
            _chargedManagers.isNftBasketEnabled(basketManagerId),
            "CP:E-419"
        );
        _;
    }
}