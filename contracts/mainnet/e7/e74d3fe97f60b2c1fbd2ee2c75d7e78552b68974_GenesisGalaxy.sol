// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC165.sol";

interface IERC1363 is IERC165, IERC20 {
    /*
     * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */

    /*
     * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool);

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

/// @dev Will not work with negative bases, only use when x is positive.
function wadPow(int256 x, int256 y) pure returns (int256) {
    // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
    return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./utils/EntityUtils.sol";
import "./utils/Sample.sol";
import "./systems/SpatialSystem.sol";
import "./systems/MiningSystem.sol";
import "./IERC20Resource.sol";
import "./IMiaocraft.sol";
import "./constants.sol";

struct EmissionInfo {
    uint128 seed;
    uint128 amount;
}

struct AsteroidInfo {
    address resource;
    uint256 initialSupply;
    uint256 rewardPerSecond;
    int256 x;
    int256 y;
}

struct AsteroidInfoExtended {
    uint256 id;
    uint128 emissionId;
    uint32 index;
    bool identified;
    AsteroidInfo asteroidInfo;
    MineInfo mineInfo;
}

contract GenesisGalaxy is
    SpatialSystem,
    MiningSystem,
    Initializable,
    Ownable,
    Multicall
{
    uint256 public immutable ASTEROIDS_PER_EMISSION;
    uint256 public immutable MAX_DEPLETION_INTERVAL;
    uint256 public immutable MAX_RADIUS;
    uint256 public immutable SPEED; // per second

    IERC20Resource public butter;
    IMiaocraft public miaocraft;
    address public sbh;

    EmissionInfo[] public _emissionInfos;
    mapping(uint256 => uint256) public identifiedBitmaps;

    constructor(
        uint256 asteroidsPerEmission,
        uint256 maxDepletionInterval,
        uint256 maxRadius,
        uint256 speed
    ) {
        ASTEROIDS_PER_EMISSION = asteroidsPerEmission;
        MAX_DEPLETION_INTERVAL = maxDepletionInterval;
        MAX_RADIUS = maxRadius;
        SPEED = speed;
    }

    function initialize(
        address butter_,
        address miaocraft_,
        address sbh_
    ) public initializer {
        butter = IERC20Resource(butter_);
        miaocraft = IMiaocraft(miaocraft_);
        sbh = sbh_;

        // initialize the origin
        _add(getOrigin());

        _transferOwnership(msg.sender);
    }

    function getEmission(uint256 emissionId)
        public
        view
        returns (EmissionInfo memory emissionInfo)
    {
        emissionInfo = _emissionInfos[emissionId];
    }

    function getEmissionCount() public view returns (uint256) {
        return _emissionInfos.length;
    }

    function getAsteroids(uint256 emissionId)
        public
        view
        returns (AsteroidInfo[] memory asteroidInfos)
    {
        asteroidInfos = new AsteroidInfo[](ASTEROIDS_PER_EMISSION);
        for (uint256 i = 0; i < ASTEROIDS_PER_EMISSION; i++) {
            asteroidInfos[i] = getAsteroid(emissionId, i);
        }
    }

    function getAsteroid(uint256 emissionId, uint256 index)
        public
        view
        returns (AsteroidInfo memory asteroidInfo)
    {
        uint256 seed = uint256(
            keccak256(abi.encodePacked(_emissionInfos[emissionId].seed, index))
        );

        // Although sqrt(1/(1e-18 + x)) is bounded, a manipulated vrf can force
        // the multiplier to go to 1e9, which destroys the econmomy in an
        // instant. So use sqrt(1/(1e-15 + x)) to cap the multiplier at 31.6
        uint256 initialSupply = (sampleInvSqrt(seed++, 1e15) *
            _emissionInfos[emissionId].amount) /
            1e18 /
            ASTEROIDS_PER_EMISSION;

        // min reward rate is 1/2 the supply / depletion interval. Multiply b 2
        // so that the min reward rate is supply / depletion interval.
        uint256 rewardPerSecond = (2 *
            (sampleInvSqrt(seed++, 1e15) * initialSupply)) /
            1e18 /
            MAX_DEPLETION_INTERVAL;

        (int256 x, int256 y) = sampleCircle(
            seed,
            MAX_RADIUS / ASTEROID_COORD_PRECISION
        );

        asteroidInfo = AsteroidInfo({
            resource: address(butter),
            initialSupply: initialSupply,
            rewardPerSecond: rewardPerSecond,
            x: x * int256(ASTEROID_COORD_PRECISION),
            y: y * int256(ASTEROID_COORD_PRECISION)
        });
    }

    function getAsteroidExtended(uint256 emissionId, uint256 index)
        public
        view
        returns (AsteroidInfoExtended memory)
    {
        return
            _getAsteroidExtended(
                emissionId,
                index,
                identifiedBitmaps[emissionId]
            );
    }

    function getOrigin() public view returns (AsteroidInfo memory) {
        uint256 genesisCost = GENESIS_SUPPLY *
            miaocraft.buildCost(SPINS_PRECISION);
        return
            AsteroidInfo({
                resource: address(butter),
                initialSupply: 100 * genesisCost,
                rewardPerSecond: genesisCost / MAX_DEPLETION_INTERVAL,
                x: 0,
                y: 0
            });
    }

    function getOriginExtended()
        public
        view
        returns (AsteroidInfoExtended memory)
    {
        return
            AsteroidInfoExtended({
                id: 0,
                emissionId: 0,
                index: uint32(ASTEROIDS_PER_EMISSION),
                identified: true,
                asteroidInfo: getOrigin(),
                mineInfo: getMineInfo(tokenToEntity(address(this), 0))
            });
    }

    function coordinateToAsteroidId(int256 x, int256 y)
        public
        pure
        returns (uint256)
    {
        x /= int256(ASTEROID_COORD_PRECISION);
        y /= int256(ASTEROID_COORD_PRECISION);
        return
            (uint256(x < 0 ? -x + ASTEROID_COORD_NEG_FLAG : x) *
                uint256(ASTEROID_COORD_NEG_FLAG * 10)) +
            (uint256(y < 0 ? -y + ASTEROID_COORD_NEG_FLAG : y));
    }

    function asteroidIdToCoordinate(uint256 asteroidId)
        public
        pure
        returns (int256 x, int256 y)
    {
        x = int256(asteroidId) / ASTEROID_COORD_NEG_FLAG / 10;
        y = int256(asteroidId) - x * ASTEROID_COORD_NEG_FLAG * 10;
        x =
            (
                x / ASTEROID_COORD_NEG_FLAG == 0
                    ? x
                    : -(x - ASTEROID_COORD_NEG_FLAG)
            ) *
            int256(ASTEROID_COORD_PRECISION);
        y =
            (
                y / ASTEROID_COORD_NEG_FLAG == 0
                    ? y
                    : -(y - ASTEROID_COORD_NEG_FLAG)
            ) *
            int256(ASTEROID_COORD_PRECISION);
    }

    function identified(uint256 emissionId, uint256 index)
        public
        view
        returns (bool)
    {
        return _mapped(identifiedBitmaps[emissionId], index);
    }

    function _getAsteroidExtended(
        uint256 emissionId,
        uint256 index,
        uint256 identifiedBitmap
    ) internal view returns (AsteroidInfoExtended memory info) {
        AsteroidInfo memory asteroidInfo = getAsteroid(emissionId, index);
        uint256 asteroidId = coordinateToAsteroidId(
            asteroidInfo.x,
            asteroidInfo.y
        );
        return
            AsteroidInfoExtended({
                id: asteroidId,
                emissionId: uint128(emissionId),
                index: uint32(index),
                identified: _mapped(identifiedBitmap, index),
                asteroidInfo: asteroidInfo,
                mineInfo: getMineInfo(tokenToEntity(address(this), asteroidId))
            });
    }

    function _getAsteroidId(uint256 emissionId, uint256 index)
        internal
        view
        returns (uint256)
    {
        AsteroidInfo memory info = getAsteroid(emissionId, index);
        return coordinateToAsteroidId(info.x, info.y);
    }

    function _mapped(uint256 bitmap, uint256 index)
        private
        pure
        returns (bool)
    {
        return bitmap & (1 << index) != 0;
    }

    function _requireDocked(uint256 shipEntityId, uint256 asteroidEntityId)
        internal
        view
    {
        require(locked(shipEntityId), "Not docked");
        require(collocated(asteroidEntityId, shipEntityId), "Not docked here");
    }

    function addEmission(uint256 seed, uint256 amount) public {
        require(msg.sender == sbh, "Only sbh");
        _emissionInfos.push(
            EmissionInfo({seed: uint128(seed), amount: uint128(amount)})
        );
    }

    function identifyMultiple(uint256 emissionId, uint256[] memory indices)
        public
    {
        for (uint256 i = 0; i < indices.length; i++) {
            identify(emissionId, indices[i]);
        }
    }

    function identifyAll(uint256 emissionId) public {
        uint256 bitmap = identifiedBitmaps[emissionId];
        for (uint256 i = 0; i < ASTEROIDS_PER_EMISSION; i++) {
            if (!_mapped(bitmap, i)) identify(emissionId, i);
        }
    }

    function identify(uint256 emissionId, uint256 index)
        public
        returns (uint256 asteroidId)
    {
        require(emissionId < _emissionInfos.length, "Invalid emissionId");
        require(index < ASTEROIDS_PER_EMISSION, "Invalid index");
        require(!identified(emissionId, index), "Already identified");
        identifiedBitmaps[emissionId] |= 1 << index;

        asteroidId = _add(getAsteroid(emissionId, index));
    }

    function dock(uint256 shipId, uint256 asteroidId)
        public
        onlyApprovedOrShipOwner(shipId)
    {
        uint256 shipEntityId = tokenToEntity(address(miaocraft), shipId);
        uint256 asteroidEntityId = tokenToEntity(address(this), asteroidId);

        require(!locked(shipEntityId), "Already docked");

        _updateLocation(shipEntityId);

        require(collocated(asteroidEntityId, shipEntityId), "Out of orbit");

        _lock(shipEntityId);
        _dock(shipEntityId, asteroidEntityId, miaocraft.spinsOf(shipId));
    }

    function redock(uint256 shipId, uint256 asteroidId) public {
        uint256 shipEntityId = tokenToEntity(address(miaocraft), shipId);
        uint256 asteroidEntityId = tokenToEntity(address(this), asteroidId);

        _requireDocked(shipEntityId, asteroidEntityId);

        uint256 sharesBefore = getExtractorInfo(asteroidEntityId, shipEntityId)
            .shares;
        uint256 sharesAfter = miaocraft.spinsOf(shipId);
        if (sharesBefore > sharesAfter) {
            _undock(shipEntityId, asteroidEntityId, sharesBefore - sharesAfter);
        } else {
            _dock(shipEntityId, asteroidEntityId, sharesAfter - sharesBefore);
        }
    }

    function extract(uint256 shipId, uint256 asteroidId) public {
        _extract(
            tokenToEntity(address(miaocraft), shipId),
            tokenToEntity(address(this), asteroidId)
        );
    }

    function identifyAndDock(
        uint256 emissionId,
        uint256 index,
        uint256 shipId
    ) public {
        uint256 asteroidId;
        if (!identified(emissionId, index)) {
            asteroidId = identify(emissionId, index);
        } else {
            asteroidId = _getAsteroidId(emissionId, index);
        }
        dock(shipId, asteroidId);
    }

    function undockAndExtract(uint256 shipId, uint256 asteroidId)
        public
        onlyApprovedOrShipOwner(shipId)
    {
        uint256 shipEntityId = tokenToEntity(address(miaocraft), shipId);
        uint256 asteroidEntityId = tokenToEntity(address(this), asteroidId);

        _requireDocked(shipEntityId, asteroidEntityId);

        _undockAndExtract(
            shipEntityId,
            asteroidEntityId,
            getExtractorInfo(asteroidEntityId, shipEntityId).shares
        );
        _unlock(shipEntityId);
    }

    function emergencyUndock(uint256 shipId, uint256 asteroidId)
        public
        onlyApprovedOrShipOwner(shipId)
    {
        uint256 shipEntityId = tokenToEntity(address(miaocraft), shipId);
        _emergencyUndock(
            shipEntityId,
            tokenToEntity(address(this), asteroidId)
        );
        _unlock(shipEntityId);
    }

    function undockExtractAndMove(
        uint256 shipId,
        uint256 fromAsteroidId,
        uint256 toAsteroidId
    ) public {
        (int256 x, int256 y) = coordinate(
            tokenToEntity(address(this), toAsteroidId)
        );
        undockExtractAndMove(shipId, fromAsteroidId, x, y);
    }

    function undockExtractAndMove(
        uint256 shipId,
        uint256 asteroidId,
        int256 xDest,
        int256 yDest
    ) public onlyApprovedOrShipOwner(shipId) {
        uint256 shipEntityId = tokenToEntity(address(miaocraft), shipId);
        uint256 asteroidEntityId = tokenToEntity(address(this), asteroidId);

        _requireDocked(shipEntityId, asteroidEntityId);

        _undockAndExtract(
            shipEntityId,
            asteroidEntityId,
            getExtractorInfo(asteroidEntityId, shipEntityId).shares
        );
        _unlock(shipEntityId);
        _move(shipEntityId, xDest, yDest, SPEED);
    }

    function move(uint256 shipId, uint256 asteroidId) public {
        (int256 x, int256 y) = coordinate(
            tokenToEntity(address(this), asteroidId)
        );
        move(shipId, x, y);
    }

    function move(
        uint256 shipId,
        int256 xDest,
        int256 yDest
    ) public onlyApprovedOrShipOwner(shipId) {
        _move(tokenToEntity(address(miaocraft), shipId), xDest, yDest, SPEED);
    }

    function remove(uint256 shipId, uint256 asteroidId) public {
        try miaocraft.ownerOf(shipId) {
            revert("Ship exists");
        } catch Error(string memory reason) {
            require(
                keccak256(abi.encodePacked(reason)) ==
                    keccak256("ERC721: invalid token ID"),
                "Invalid reason"
            );
            _destroyExtractor(
                tokenToEntity(address(this), asteroidId),
                tokenToEntity(address(miaocraft), shipId)
            );
        }
    }

    function _add(AsteroidInfo memory asteroidInfo)
        internal
        returns (uint256 asteroidId)
    {
        asteroidId = coordinateToAsteroidId(asteroidInfo.x, asteroidInfo.y);
        uint256 asteroidEntityId = tokenToEntity(address(this), asteroidId);

        IERC20Resource(asteroidInfo.resource).mint(
            asteroidEntityId,
            asteroidInfo.initialSupply
        );

        _setCoordinate(asteroidEntityId, asteroidInfo.x, asteroidInfo.y);

        _add(
            asteroidEntityId,
            asteroidInfo.resource,
            asteroidInfo.rewardPerSecond
        );
    }

    modifier onlyApprovedOrShipOwner(uint256 shipId) {
        require(
            miaocraft.isApprovedOrOwner(msg.sender, shipId),
            "Only approved or owner"
        );
        _;
    }

    /*
    DATA QUERY FUNCTIONS
    */

    function paginateEmissions(uint256 offset, uint256 limit)
        public
        view
        returns (EmissionInfo[] memory emissionInfos_)
    {
        limit = Math.min(limit, _emissionInfos.length - offset);
        emissionInfos_ = new EmissionInfo[](limit);
        uint256 start = _emissionInfos.length - offset - 1;
        for (uint256 i = 0; i < limit; i++) {
            emissionInfos_[i] = _emissionInfos[start - i];
        }
    }

    function paginateAsteroids(uint256 offset, uint256 limit)
        public
        view
        returns (AsteroidInfoExtended[] memory asteroidInfos)
    {
        limit = Math.min(limit, _emissionInfos.length - offset);
        asteroidInfos = new AsteroidInfoExtended[](
            limit * ASTEROIDS_PER_EMISSION
        );
        uint256 start = _emissionInfos.length - offset - 1;
        for (uint256 i = 0; i < limit; i++) {
            uint256 emissionId = start - i;
            uint256 bitmap = identifiedBitmaps[i];
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 0
            ] = _getAsteroidExtended(emissionId, 0, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 1
            ] = _getAsteroidExtended(emissionId, 1, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 2
            ] = _getAsteroidExtended(emissionId, 2, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 3
            ] = _getAsteroidExtended(emissionId, 3, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 4
            ] = _getAsteroidExtended(emissionId, 4, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 5
            ] = _getAsteroidExtended(emissionId, 5, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 6
            ] = _getAsteroidExtended(emissionId, 6, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 7
            ] = _getAsteroidExtended(emissionId, 7, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 8
            ] = _getAsteroidExtended(emissionId, 8, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 9
            ] = _getAsteroidExtended(emissionId, 9, bitmap);
            asteroidInfos[
                emissionId * ASTEROIDS_PER_EMISSION + 10
            ] = _getAsteroidExtended(emissionId, 10, bitmap);
        }
    }

    /*
    OWNER FUNCTIONS
    */

    function setButter(IERC20Resource butter_) public onlyOwner {
        butter = butter_;
    }

    function setMiaocraft(IMiaocraft miaocraft_) public onlyOwner {
        miaocraft = miaocraft_;
    }

    function setSbh(address sbh_) public onlyOwner {
        sbh = sbh_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./extensions/IERC20EntityBurnable.sol";

interface IERC20Resource is IERC20EntityBurnable {
    function mint(address to, uint256 amount) external;

    function mint(uint256 to, uint256 amount) external;

    function mintAndCall(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct ShipInfo {
    uint96 spins;
    uint96 spinsBurned;
    uint40 lastServiceTime;
    string name;
}

interface IMiaocraft is IERC721 {
    event Build(
        address indexed owner,
        uint256 indexed id,
        uint256 spins,
        string name
    );

    event Upgrade(address indexed owner, uint256 indexed id, uint256 spins);

    event Merge(
        address indexed owner,
        uint256 indexed id1,
        uint256 indexed id2,
        uint256 spins
    );

    event Scrap(
        address indexed scavengerOwner,
        uint256 indexed scavengerId,
        uint256 indexed targetId
    );

    event Service(
        address indexed owner,
        uint256 indexed id,
        uint256 spins,
        uint256 cost
    );

    event Rename(address indexed owner, uint256 indexed id, string name);

    function spinsOf(uint256 id) external view returns (uint256);

    function spinsDecayOf(uint256 id) external view returns (uint256);

    function buildCost(uint256 spins_) external view returns (uint256);

    function serviceCostOf(uint256 id) external view returns (uint256);

    function getShipInfo(uint256 id) external view returns (ShipInfo memory);

    function build(uint256 spins_, string calldata name_) external;

    function upgrade(uint256 id, uint256 spins_) external;

    function merge(uint256 id1, uint256 id2) external;

    function scrap(uint256 scavengerId, uint256 targetId) external;

    function service(uint256 id) external;

    function rename(uint256 id, string calldata name_) external;

    function isApprovedOrOwner(address spender, uint256 id)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

uint16 constant VRF_MIN_BLOCKS = 3;
uint32 constant VRF_GAS_LIMIT = 300000;

uint256 constant SPINS_PRECISION = 1e18;
uint256 constant GENESIS_SUPPLY = 2000;

uint256 constant ASTEROID_COORD_PRECISION = 1e3;
int256 constant ASTEROID_COORD_NEG_FLAG = 1e3;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/Interfaces/IERC1363.sol";

/// @title ERC20 with entity-based ownership and allowances.
/// @author boffee
/// @author Modified from openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)
interface IERC20Entity is IERC1363 {
    /**
     * @dev Emitted when `value` tokens are moved from one entity (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event EntityTransfer(
        uint256 indexed from,
        uint256 indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event EntityApproval(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens owned by `entity`.
     */
    function balanceOf(uint256 entity) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's entity to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {EntityTransfer} event.
     */
    function transfer(uint256 to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(uint256 owner, uint256 spender)
        external
        view
        returns (uint256);

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
    function approve(uint256 spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {EntityTransfer} event.
     */
    function transferFrom(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20Entity.sol";

interface IERC20EntityBurnable is IERC20Entity {
    function burn(uint256 amount) external;

    function burnFrom(uint256 entity, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct LocationInfo {
    int40 xOrigin;
    int40 yOrigin;
    int40 xDest;
    int40 yDest;
    uint40 speed;
    uint40 departureTime;
    bool locked;
}

interface ISpatialSystem {
    event UpdateLocation(
        uint256 indexed entityId,
        int256 xOrigin,
        int256 yOrigin,
        int256 xDest,
        int256 yDest,
        uint256 speed,
        uint256 departureTime
    );

    event Move(
        uint256 indexed entityId,
        int256 xOrigin,
        int256 yOrigin,
        int256 xDest,
        int256 yDest,
        uint256 speed,
        uint256 departureTime
    );

    event SetLocation(
        uint256 indexed entityId,
        int256 xOrigin,
        int256 yOrigin,
        int256 xDest,
        int256 yDest,
        uint256 speed,
        uint256 departureTime
    );

    event SetCoordinate(uint256 indexed entityId, int256 x, int256 y);

    event Locked(uint256 indexed entityId);

    event Unlocked(uint256 indexed entityId);

    function coordinate(uint256 entityId)
        external
        view
        returns (int256 x, int256 y);

    function collocated(uint256 entityId1, uint256 entityId2)
        external
        view
        returns (bool);

    function collocated(
        uint256 entityId1,
        uint256 entityId2,
        uint256 radius
    ) external view returns (bool);

    function getLocationInfo(uint256 entityId)
        external
        view
        returns (LocationInfo memory);

    function locked(uint256 entityId) external view returns (bool);

    function updateLocation(uint256 entityId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../extensions/IERC20Entity.sol";

struct ExtractorInfo {
    uint128 shares;
    int128 rewardDebt;
}

struct MineInfo {
    uint128 rewardPerShare;
    uint64 lastRewardTimestamp;
    uint64 rewardPerSecond;
    uint128 totalShares;
    uint128 totalReward;
}

/// @title Mining System
/// @author boffee
/// @author Modified fro MasterChef V2 (https://github.com/sushiswap/sushiswap/blob/master/protocols/masterchef/contracts/MasterChefV2.sol)
/// @notice This contract is used to manage mining.
contract MiningSystem {
    event Dock(
        uint256 indexed extractorId,
        uint256 indexed mineId,
        uint256 shares
    );
    event Undock(
        uint256 indexed extractorId,
        uint256 indexed mineId,
        uint256 shares
    );
    event EmergencyUndock(
        uint256 indexed extractorId,
        uint256 indexed mineId,
        uint256 shares
    );
    event Extract(
        uint256 indexed extractorId,
        uint256 indexed mineId,
        uint256 reward
    );
    event AddMine(
        uint256 indexed mineId,
        address indexed rewardToken,
        uint256 rewardPerSecond,
        uint256 rewardPool
    );
    event SetMine(
        uint256 indexed mineId,
        address indexed rewardToken,
        uint256 rewardPerSecond,
        uint256 rewardPool
    );
    event UpdateMine(
        uint256 indexed mineId,
        uint64 lastRewardTimestamp,
        uint256 totalShares,
        uint256 rewardPerShare
    );
    event DestroyMine(uint256 indexed mineId);

    uint256 public constant REWARD_PER_SHARE_PRECISION = 1e12;

    /// @notice Info of each mine.
    mapping(uint256 => MineInfo) private _mineInfos;

    /// @notice Info of each extractor at each mine.
    mapping(uint256 => mapping(uint256 => ExtractorInfo))
        private _extractorInfos;

    /// @notice Mine reward token address.
    mapping(uint256 => IERC20Entity) public rewardTokens;

    function exists(uint256 mineId) public view returns (bool) {
        return address(rewardTokens[mineId]) != address(0);
    }

    /// @notice View function to see pending reward on frontend.
    /// @param extractorId Address of extractor.
    /// @param mineId id of the mine. See `_mineInfos`.
    /// @return pending reward for a given extractor.
    function pendingReward(uint256 extractorId, uint256 mineId)
        external
        view
        returns (uint256 pending)
    {
        MineInfo memory mineInfo = _mineInfos[mineId];
        ExtractorInfo storage extractorInfo = _extractorInfos[mineId][
            extractorId
        ];
        uint256 rewardPerShare = mineInfo.rewardPerShare;
        if (
            block.timestamp > mineInfo.lastRewardTimestamp &&
            mineInfo.totalShares != 0
        ) {
            uint256 duration = block.timestamp - mineInfo.lastRewardTimestamp;
            uint256 reward = Math.min(
                duration * mineInfo.rewardPerSecond,
                rewardTokens[mineId].balanceOf(mineId) - mineInfo.totalReward
            );
            // total reward cannot excceed mine balance
            rewardPerShare +=
                (reward * REWARD_PER_SHARE_PRECISION) /
                mineInfo.totalShares;
        }
        pending = uint256(
            int256(
                (extractorInfo.shares * rewardPerShare) /
                    REWARD_PER_SHARE_PRECISION
            ) - extractorInfo.rewardDebt
        );
    }

    /// @notice get mine info
    /// @param mineId id of the mine. See `_mineInfos`.
    /// @return mineInfo
    function getMineInfo(uint256 mineId) public view returns (MineInfo memory) {
        return _mineInfos[mineId];
    }

    /// @notice get extractor info
    /// @param mineId id of the mine. See `_mineInfos`.
    /// @param extractorId id of the extractor. See `_extractorInfos`.
    /// @return extractorInfo
    function getExtractorInfo(uint256 mineId, uint256 extractorId)
        public
        view
        returns (ExtractorInfo memory)
    {
        return _extractorInfos[mineId][extractorId];
    }

    /// @notice Update reward variables for all mines.
    /// @param mineIds Mine IDs of all to be updated.
    function massUpdateMines(uint256[] calldata mineIds) external {
        uint256 len = mineIds.length;
        for (uint256 i = 0; i < len; ++i) {
            updateMine(mineIds[i]);
        }
    }

    /// @notice Update reward variables of the given mine.
    /// @param mineId id of the mine. See `_mineInfos`.
    /// @return mineInfo Returns the mine that was updated.
    function updateMine(uint256 mineId)
        public
        returns (MineInfo memory mineInfo)
    {
        mineInfo = _mineInfos[mineId];
        if (block.timestamp > mineInfo.lastRewardTimestamp) {
            if (mineInfo.totalShares > 0) {
                uint256 duration = block.timestamp -
                    mineInfo.lastRewardTimestamp;
                uint256 reward = Math.min(
                    duration * mineInfo.rewardPerSecond,
                    rewardTokens[mineId].balanceOf(mineId) -
                        mineInfo.totalReward
                );
                mineInfo.totalReward += uint128(reward);
                // total reward cannot excceed mine balance
                mineInfo.rewardPerShare += uint128(
                    (reward * REWARD_PER_SHARE_PRECISION) / mineInfo.totalShares
                );
            }
            mineInfo.lastRewardTimestamp = uint64(block.timestamp);
            _mineInfos[mineId] = mineInfo;
            emit UpdateMine(
                mineId,
                mineInfo.lastRewardTimestamp,
                mineInfo.totalShares,
                mineInfo.rewardPerShare
            );
        }
    }

    /// @notice Dock extractor to mine for BUTTER allocation.
    /// @param extractorId The receiver of `shares` dock benefit.
    /// @param mineId id of the mine. See `_mineInfos`.
    /// @param shares The amount of shares to be docked.
    function _dock(
        uint256 extractorId,
        uint256 mineId,
        uint256 shares
    ) internal {
        MineInfo memory mineInfo = updateMine(mineId);

        require(
            (mineInfo.totalShares * uint256(mineInfo.rewardPerShare)) /
                REWARD_PER_SHARE_PRECISION <
                rewardTokens[mineId].balanceOf(mineId),
            "Mine depleted"
        );

        ExtractorInfo storage extractorInfo = _extractorInfos[mineId][
            extractorId
        ];

        // Effects
        extractorInfo.shares += uint128(shares);
        extractorInfo.rewardDebt += int128(
            uint128(
                (shares * mineInfo.rewardPerShare) / REWARD_PER_SHARE_PRECISION
            )
        );
        _mineInfos[mineId].totalShares += uint128(shares);

        emit Dock(extractorId, mineId, shares);
    }

    /// @notice Undock extractor from mine.
    /// @param extractorId Receiver of the reward.
    /// @param mineId id of the mine. See `_mineInfos`.
    /// @param shares Extractor shares to undock.
    function _undock(
        uint256 extractorId,
        uint256 mineId,
        uint256 shares
    ) internal {
        MineInfo memory mineInfo = updateMine(mineId);
        ExtractorInfo storage extractorInfo = _extractorInfos[mineId][
            extractorId
        ];

        // Effects
        extractorInfo.rewardDebt -= int128(
            uint128(
                (shares * mineInfo.rewardPerShare) / REWARD_PER_SHARE_PRECISION
            )
        );
        extractorInfo.shares -= uint128(shares);
        _mineInfos[mineId].totalShares -= uint128(shares);

        _tryDestroy(mineId);

        emit Undock(extractorId, mineId, shares);
    }

    /// @notice Extract proceeds for extractor.
    /// @param extractorId Receiver of rewards.
    /// @param mineId id of the mine. See `_mineInfos`.
    function _extract(uint256 extractorId, uint256 mineId) internal {
        MineInfo memory mineInfo = updateMine(mineId);
        ExtractorInfo storage extractorInfo = _extractorInfos[mineId][
            extractorId
        ];
        int256 accumulatedReward = int256(
            (extractorInfo.shares * uint256(mineInfo.rewardPerShare)) /
                REWARD_PER_SHARE_PRECISION
        );
        uint256 _pendingReward = uint256(
            accumulatedReward - extractorInfo.rewardDebt
        );

        // Effects
        extractorInfo.rewardDebt = int128(accumulatedReward);
        _mineInfos[mineId].totalReward -= uint128(_pendingReward);

        rewardTokens[mineId].transferFrom(mineId, extractorId, _pendingReward);

        _tryDestroy(mineId);

        emit Extract(extractorId, mineId, _pendingReward);
    }

    /// @notice Undock extractor from mine and extract proceeds.
    /// @param extractorId Receiver of the rewards.
    /// @param mineId id of the mine. See `_mineInfos`.
    /// @param shares Extractor shares to undock.
    function _undockAndExtract(
        uint256 extractorId,
        uint256 mineId,
        uint256 shares
    ) internal {
        MineInfo memory mineInfo = updateMine(mineId);
        ExtractorInfo storage extractorInfo = _extractorInfos[mineId][
            extractorId
        ];
        int256 accumulatedReward = int256(
            (extractorInfo.shares * uint256(mineInfo.rewardPerShare)) /
                REWARD_PER_SHARE_PRECISION
        );
        uint256 _pendingReward = uint256(
            accumulatedReward - extractorInfo.rewardDebt
        );

        // Effects
        extractorInfo.rewardDebt = int128(
            accumulatedReward -
                int256(
                    (shares * mineInfo.rewardPerShare) /
                        REWARD_PER_SHARE_PRECISION
                )
        );
        extractorInfo.shares -= uint128(shares);
        _mineInfos[mineId].totalShares -= uint128(shares);
        _mineInfos[mineId].totalReward -= uint128(_pendingReward);

        rewardTokens[mineId].transferFrom(mineId, extractorId, _pendingReward);

        _tryDestroy(mineId);

        emit Undock(extractorId, mineId, shares);
        emit Extract(extractorId, mineId, _pendingReward);
    }

    /// @notice Undock without caring about rewards. EMERGENCY ONLY.
    /// @param extractorId Receiver of the reward.
    /// @param mineId id of the mine. See `_mineInfos`.
    function _emergencyUndock(uint256 extractorId, uint256 mineId) internal {
        ExtractorInfo storage extractorInfo = _extractorInfos[mineId][
            extractorId
        ];
        uint256 shares = extractorInfo.shares;
        if (_mineInfos[mineId].totalShares >= shares) {
            _mineInfos[mineId].totalShares -= uint128(shares);
        }

        delete _extractorInfos[mineId][extractorId];

        emit EmergencyUndock(extractorId, mineId, shares);
    }

    /// @notice Add a new mine.
    /// @param mineId The id of the mine.
    /// @param rewardToken The address of the reward token.
    /// @param rewardPerSecond reward rate of the new mine.
    function _add(
        uint256 mineId,
        address rewardToken,
        uint256 rewardPerSecond
    ) internal {
        require(
            _mineInfos[mineId].lastRewardTimestamp == 0,
            "Mine already exists"
        );

        _mineInfos[mineId] = MineInfo({
            rewardPerSecond: uint64(rewardPerSecond),
            lastRewardTimestamp: uint64(block.timestamp),
            rewardPerShare: 0,
            totalShares: 0,
            totalReward: 0
        });
        rewardTokens[mineId] = IERC20Entity(rewardToken);

        emit AddMine(
            mineId,
            rewardToken,
            rewardPerSecond,
            IERC20Entity(rewardToken).balanceOf(mineId)
        );
    }

    /// @notice Update the given mine's reward rate.
    /// @param mineId The entity id of the mine.
    /// @param rewardPerSecond New reward rate of the mine.
    function _set(uint256 mineId, uint256 rewardPerSecond) internal {
        _mineInfos[mineId].rewardPerSecond = uint64(rewardPerSecond);
        IERC20Entity rewardToken = rewardTokens[mineId];

        emit SetMine(
            mineId,
            address(rewardToken),
            rewardPerSecond,
            rewardToken.balanceOf(mineId)
        );
    }

    /// @notice Destroy the given mine if its depleted and has no shares.
    /// @param mineId The entity id of the mine.
    function _tryDestroy(uint256 mineId) internal {
        if (
            rewardTokens[mineId].balanceOf(mineId) < 1e15 &&
            _mineInfos[mineId].totalShares < 1e15
        ) {
            _destroy(mineId);
        }
    }

    /// @notice Destroy the given mine.
    /// @param mineId The entity id of the mine.
    function _destroy(uint256 mineId) internal {
        delete _mineInfos[mineId];
        delete rewardTokens[mineId];
        emit DestroyMine(mineId);
    }

    function _destroyExtractor(uint256 mineId, uint256 extractorId) internal {
        ExtractorInfo memory extractorInfo = _extractorInfos[mineId][
            extractorId
        ];
        _mineInfos[mineId].totalShares -= uint128(extractorInfo.shares);
        _mineInfos[mineId].totalReward -= uint128(
            uint256(
                int256(
                    (extractorInfo.shares *
                        uint256(_mineInfos[mineId].rewardPerShare)) /
                        REWARD_PER_SHARE_PRECISION
                ) - extractorInfo.rewardDebt
            )
        );
        delete _extractorInfos[mineId][extractorId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../utils/VectorWadMath.sol";
import "../utils/EntityUtils.sol";
import "./ISpatialSystem.sol";

contract SpatialSystem is ISpatialSystem {
    mapping(uint256 => LocationInfo) private _locationInfos;

    function coordinate(uint256 entityId)
        public
        view
        virtual
        override
        returns (int256 x, int256 y)
    {
        return _coordinate(entityId);
    }

    function coordinate(address token, uint256 id)
        public
        view 
        virtual
        returns (int256 x, int256 y)
    {
        return _coordinate(tokenToEntity(token, id));
    }

    function locked(uint256 entityId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _locationInfos[entityId].locked;
    }

    function collocated(uint256 entityId1, uint256 entityId2)
        public
        view 
        virtual
        override
        returns (bool)
    {
        (int256 x1, int256 y1) = _coordinate(entityId1);
        (int256 x2, int256 y2) = _coordinate(entityId2);
        return x1 == x2 && y1 == y2;
    }

    function collocated(
        uint256 entityId1,
        uint256 entityId2,
        uint256 radius
    ) public view virtual override returns (bool) {
        (int256 x1, int256 y1) = _coordinate(entityId1);
        (int256 x2, int256 y2) = _coordinate(entityId2);
        return
            VectorWadMath.distance(x1 * 1e18, y1 * 1e18, x2 * 1e18, y2 * 1e18) <=
            radius * 1e18;
    }

    function getLocationInfo(uint256 entityId)
        public
        view
        virtual
        override
        returns (LocationInfo memory)
    {
        return _locationInfos[entityId];
    }

    function _coordinate(uint256 entityId)
        internal
        view 
        virtual
        returns (int256 x, int256 y)
    {
        LocationInfo memory info = _locationInfos[entityId];
        // ship is only not moving if it's at its destination
        if (info.speed == 0) {
            return (info.xOrigin, info.yOrigin);
        }

        uint256 distance =
            VectorWadMath.distance(
                info.xOrigin,
                info.yOrigin,
                info.xDest,
                info.yDest
            );
        uint256 distanceTraveled = (block.timestamp - info.departureTime) *
            info.speed;

        // reached destination already
        if (distanceTraveled >= distance) {
            return (info.xDest, info.yDest);
        }

        (x, y) = VectorWadMath.scaleVector(
            info.xOrigin,
            info.yOrigin,
            info.xDest,
            info.yDest,
            int256((distanceTraveled * 1e18) / distance)
        );
    }

    function updateLocation(uint256 entityId) public virtual override {
        _updateLocation(entityId);
    }

    function updateLocation(address token, uint256 id) public virtual {
        _updateLocation(tokenToEntity(token, id));
    }

    function _move(
        uint256 entityId,
        int256 xDest,
        int256 yDest,
        uint256 speed
    ) internal virtual {
        require(!_locationInfos[entityId].locked, "Locked");
        (int256 x, int256 y) = _coordinate(entityId);
        _locationInfos[entityId] = LocationInfo({
            // update origin to current coordinate
            xOrigin: int40(x),
            yOrigin: int40(y),
            // set destination
            xDest: int40(xDest),
            yDest: int40(yDest),
            speed: uint40(speed),
            departureTime: uint40(block.timestamp),
            locked: false
        });

        emit Move(
            entityId,
            x,
            y,
            xDest,
            yDest,
            speed,
            block.timestamp
        );
    }

    function _updateLocation(uint256 entityId) internal virtual {
        (int256 x, int256 y) = _coordinate(entityId);
        
        LocationInfo memory info = _locationInfos[entityId];
        // arrived, so set speed to 0
        if (
            x == info.xDest &&
            y == info.yDest
        ) {
            info.speed = 0;
        }

        // update origin to current coordinate
        info.xOrigin = int40(x);
        info.yOrigin = int40(y);
        info.departureTime = uint40(block.timestamp);

        _locationInfos[entityId] = info;
        
        emit UpdateLocation(
            entityId,
            x,
            y,
            info.xDest,
            info.yDest,
            info.speed,
            block.timestamp
        );
    }

    function _setLocation(
        uint256 entityId, 
        LocationInfo memory info
    ) internal virtual {
        _locationInfos[entityId] = info;

        emit SetLocation(
            entityId,
            info.xOrigin,
            info.yOrigin,
            info.xDest,
            info.yDest,
            info.speed,
            info.departureTime
        );
    }

    function _setCoordinate(
        uint256 entityId,
        int256 x,
        int256 y
    ) internal virtual {
        _locationInfos[entityId] = LocationInfo({
            xOrigin: int40(x),
            yOrigin: int40(y),
            xDest: int40(x),
            yDest: int40(y),
            speed: 0,
            departureTime: uint40(block.timestamp),
            locked: false
        });

        emit SetCoordinate(entityId, x, y);
    }

    function _lock(
        uint256 entityId
    ) internal virtual {
        require(_locationInfos[entityId].speed == 0, "Moving");
        _locationInfos[entityId].locked = true;

        emit Locked(entityId);
    }

    function _unlock(
        uint256 entityId
    ) internal virtual {
        _locationInfos[entityId].locked = false;

        emit Unlocked(entityId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

function tokenToEntity(address token, uint256 id) pure returns (uint256) {
    return (uint256(uint160(token)) << 96) | id;
}

function entityToToken(uint256 entity)
    pure
    returns (address token, uint256 id)
{
    token = address(uint160(entity >> 96));
    id = entity & 0xffffffffffffffffffffffff;
}

function accountToEntity(address account) pure returns (uint256) {
    return (uint256(uint160(account)));
}

function entityToAccount(uint256 entity) pure returns (address account) {
    account = address(uint160(entity));
}

function entityIsAccount(uint256 entity) pure returns (bool) {
    return entity >> 160 == 0;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "solmate/utils/SignedWadMath.sol";

function wadSigmoid(int256 x) pure returns (uint256) {
    return uint256(unsafeWadDiv(1e18, 1e18 + wadExp(-x)));
}

function random(uint256 seed, uint256 max) pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed))) % max;
}

function sampleCircle(uint256 seed, uint256 radius)
    pure
    returns (int256 x, int256 y)
{
    unchecked {
        seed = uint256(keccak256(abi.encodePacked(seed)));
        int256 r = int256(random(seed++, radius)) + 1;
        int256 xUnit = int256(random(seed++, 2e18)) - 1e18;
        int256 yUnit = int256(Math.sqrt(1e36 - uint256(xUnit * xUnit)));
        x = int256((xUnit * r) / 1e18);
        y = int256((yUnit * r) / 1e18);
        if (random(seed, 2) == 0) {
            y = -y;
        }
    }
}

function sampleInvSqrt(uint256 seed, uint256 e) pure returns (uint256) {
    return wadInvSqrt(random(seed, 1e18), e) / 2;
}

function wadInvSqrt(uint256 x, uint256 e) pure returns (uint256) {
    return Math.sqrt(1e54 / (e + x));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library VectorWadMath {
    using Math for uint256;
    using SignedMath for int256;

    int256 constant PRECISION = 1e18;
    int256 constant PRECISION_UINT = 1e18;

    function distance(
        int256 x1,
        int256 y1,
        int256 x2,
        int256 y2
    ) internal pure returns (uint256) {
        return ((x2 - x1).abs()**2 + (y2 - y1).abs()**2).sqrt();
    }

    function unitVector(
        int256 x1,
        int256 y1,
        int256 x2,
        int256 y2
    ) internal pure returns (int256, int256) {
        int256 dist = int256(distance(x1, y1, x2, y2));
        return (((x2 - x1) * PRECISION) / dist, ((y2 - y1) * PRECISION) / dist);
    }

    function scaleVector(
        int256 x1,
        int256 y1,
        int256 x2,
        int256 y2,
        int256 scale
    ) internal pure returns (int256, int256) {
        return (
            x1 + ((x2 - x1) * scale) / PRECISION,
            y1 + ((y2 - y1) * scale) / PRECISION
        );
    }
}