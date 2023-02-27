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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Declares the interface for initializing a collection.
 * @author batu-inal & HardlyDifficult
 */
interface INFTCollectionInitializer {
  function initialize(address payable _creator, string memory _name, string memory _symbol) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Declares the interface for initializing a drop collection.
 * @author batu-inal & HardlyDifficult
 */
interface INFTDropCollectionInitializer {
  function initialize(
    address payable _creator,
    string calldata _name,
    string calldata _symbol,
    string calldata _baseURI,
    bool isRevealed,
    uint32 _maxTokenId,
    address _approvedMinter,
    address payable _paymentAddress
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Declares the interface for initializing a timed edition collection.
 * @author cori-grohman
 */
interface INFTTimedEditionCollectionInitializer {
  function initialize(
    address payable _creator,
    string calldata _name,
    string calldata _symbol,
    string calldata tokenURI_,
    uint256 _mintEndTime,
    address _approvedMinter,
    address payable _paymentAddress
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @notice Interface for a contract which implements admin roles.
 * @author batu-inal & HardlyDifficult
 */
interface IRoles {
  function isAdmin(address account) external view returns (bool);

  function isOperator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

import "../../../libraries/AddressLibrary.sol";

/**
 * @title Interface for routing calls to the NFT Collection Factory to create timed edition collections.
 * @author HardlyDifficult
 */
interface INFTCollectionFactoryTimedEditions {
  function createNFTTimedEditionCollection(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection);

  function createNFTTimedEditionCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

struct CallWithoutValue {
  address target;
  bytes callData;
}

error AddressLibrary_Proxy_Call_Did_Not_Return_A_Contract(address addressReturned);

/**
 * @title A library for address helpers not already covered by the OZ library.
 * @author batu-inal & HardlyDifficult
 */
library AddressLibrary {
  using AddressUpgradeable for address;
  using AddressUpgradeable for address payable;

  /**
   * @notice Calls an external contract with arbitrary data and parse the return value into an address.
   * @param externalContract The address of the contract to call.
   * @param callData The data to send to the contract.
   * @return contractAddress The address of the contract returned by the call.
   */
  function callAndReturnContractAddress(
    address externalContract,
    bytes calldata callData
  ) internal returns (address payable contractAddress) {
    bytes memory returnData = externalContract.functionCall(callData);
    contractAddress = abi.decode(returnData, (address));
    if (!contractAddress.isContract()) {
      revert AddressLibrary_Proxy_Call_Did_Not_Return_A_Contract(contractAddress);
    }
  }

  function callAndReturnContractAddress(
    CallWithoutValue calldata call
  ) internal returns (address payable contractAddress) {
    contractAddress = callAndReturnContractAddress(call.target, call.callData);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title Helpers for working with time.
 * @author batu-inal & HardlyDifficult
 */
library TimeLibrary {
  /**
   * @notice Checks if the given timestamp is in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different than `hasBeenReached` in that it will return false if the expiry is now.
   */
  function hasExpired(uint256 expiry) internal view returns (bool) {
    return expiry < block.timestamp;
  }

  /**
   * @notice Checks if the given timestamp is now or in the past.
   * @dev This helper ensures a consistent interpretation of expiry across the codebase.
   * This is different from `hasExpired` in that it will return true if the timestamp is now.
   */
  function hasBeenReached(uint256 timestamp) internal view returns (bool) {
    return timestamp <= block.timestamp;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../../interfaces/internal/roles/IRoles.sol";

error NFTCollectionFactoryACL_Caller_Must_Have_Admin_Role();
error NFTCollectionFactoryACL_Constructor_RolesContract_Is_Not_A_Contract();

/**
 * @title ACL definitions for the factory.
 */
abstract contract NFTCollectionFactoryACL is Context {
  using AddressUpgradeable for address;

  IRoles private immutable _rolesManager;

  modifier onlyAdmin() {
    if (!_rolesManager.isAdmin(_msgSender())) {
      revert NFTCollectionFactoryACL_Caller_Must_Have_Admin_Role();
    }
    _;
  }

  /**
   * @notice Defines requirements for the collection drop factory at deployment time.
   * @param rolesManager_ The address of the contract defining roles for collections to use.
   */
  constructor(address rolesManager_) {
    if (!rolesManager_.isContract()) {
      revert NFTCollectionFactoryACL_Constructor_RolesContract_Is_Not_A_Contract();
    }

    _rolesManager = IRoles(rolesManager_);
  }

  /**
   * @notice The contract address which manages common roles.
   * @dev Defines a centralized admin role definition for permissioned functions below.
   * @return managerContract The contract address with role definitions.
   */
  function rolesManager() external view returns (address managerContract) {
    managerContract = address(_rolesManager);
  }

  // This mixin consumes 0 slots.
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./NFTCollectionFactoryACL.sol";
import "./NFTCollectionFactoryTemplateInitializer.sol";
import "./NFTCollectionFactoryTypes.sol";

error NFTCollectionFactorySharedTemplates_Collection_Requires_Symbol();
error NFTCollectionFactorySharedTemplates_Invalid_Collection_Type();
error NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Already_Set();
error NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Not_A_Contract();
error NFTCollectionFactorySharedTemplates_Upgrade_Unsorted_Or_Dupe_Collection_Type();

/*
 * Struct for calldata
 * Stored outside the contract for use in forge tests.
 */
struct CollectionTemplateUpgrade {
  CollectionType collectionType;
  address implementation;
}

/**
 * @title Shared logic for managing templates and creating new collections.
 */
abstract contract NFTCollectionFactorySharedTemplates is
  Context,
  Initializable,
  NFTCollectionFactoryACL,
  NFTCollectionFactoryTemplateInitializer
{
  using AddressUpgradeable for address;
  using Clones for address;

  // Struct for storage
  struct CollectionTemplateDetails {
    address implementation;
    uint32 version;
    // This slot has 64-bits of free space remaining.
  }

  mapping(CollectionType => CollectionTemplateDetails) private collectionTypeToTemplateDetails;

  /**
   * @notice Emitted when the implementation of NFTCollection used by new collections is updated.
   * @param implementation The new implementation contract address.
   * @param version The version of the new implementation, auto-incremented.
   */
  event CollectionTemplateUpdated(
    CollectionType indexed collectionType,
    address indexed implementation,
    uint256 indexed version
  );

  /**
   * @notice Called at the time of deployment / upgrade to initialize the factory with existing templates.
   * @param nftCollectionImplementation The implementation contract address for NFTCollection.
   * @param nftDropCollectionImplementation The implementation contract address for NFTDropCollection.
   * @dev This can be used to ensure there is zero downtime during an upgrade and that version numbers resume from
   * where they had left off.
   * Initializer 1 was previously used on mainnet. 2 was used on Goerli only.
   */
  function initialize(
    address nftCollectionImplementation,
    address nftDropCollectionImplementation,
    address nftTimedEditionCollectionImplementation
  ) external reinitializer(3) {
    // The latest version on mainnet before this upgrade was 3, so we start with 4.
    _setCollectionTemplate(CollectionType.NFTCollection, nftCollectionImplementation, 4);
    // The latest version on mainnet before this upgrade was 1, so we start with 2.
    _setCollectionTemplate(CollectionType.NFTDropCollection, nftDropCollectionImplementation, 2);
    // Editions are a new template, starting at version 1.
    _setCollectionTemplate(CollectionType.NFTTimedEditionCollection, nftTimedEditionCollectionImplementation, 1);
  }

  /**
   * @notice Allows admins to update a multiple templates.
   * @param newTemplates The new templates to set, sorted by collection type.
   * @dev New templates will start with version 1, others will auto-increment from their current version.
   */
  function adminUpdateCollectionTemplates(CollectionTemplateUpgrade[] calldata newTemplates) external onlyAdmin {
    for (uint i = 0; i < newTemplates.length; ) {
      CollectionTemplateUpgrade calldata newTemplate = newTemplates[i];
      unchecked {
        // Checking i > 0 first ensures that i - 1 is safe.
        if (i > 0 && newTemplate.collectionType <= newTemplates[i - 1].collectionType) {
          revert NFTCollectionFactorySharedTemplates_Upgrade_Unsorted_Or_Dupe_Collection_Type();
        }
      }
      if (collectionTypeToTemplateDetails[newTemplate.collectionType].implementation == newTemplate.implementation) {
        revert NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Already_Set();
      }

      _setCollectionTemplate(
        newTemplate.collectionType,
        newTemplate.implementation,
        ++collectionTypeToTemplateDetails[newTemplate.collectionType].version
      );

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice A helper for creating collections of a given type.
   */
  function _createCollection(
    CollectionType collectionType,
    address creator,
    uint96 nonce,
    string memory symbol
  ) internal returns (address collection, uint256 version) {
    // All collections require a symbol.
    if (bytes(symbol).length == 0) {
      revert NFTCollectionFactorySharedTemplates_Collection_Requires_Symbol();
    }

    address implementation = collectionTypeToTemplateDetails[collectionType].implementation;
    if (implementation == address(0)) {
      // This will occur if the collectionType is NULL or has not yet been initialized.
      revert NFTCollectionFactorySharedTemplates_Invalid_Collection_Type();
    }

    // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
    collection = implementation.cloneDeterministic(_getSalt(creator, nonce));
    version = collectionTypeToTemplateDetails[collectionType].version;
  }

  function _setCollectionTemplate(CollectionType collectionType, address implementation, uint32 version) private {
    if (!implementation.isContract()) {
      revert NFTCollectionFactorySharedTemplates_Upgrade_Implementation_Not_A_Contract();
    }

    collectionTypeToTemplateDetails[collectionType] = CollectionTemplateDetails(implementation, version);

    // Initialize will revert if the collectionType is NULL
    _initializeTemplate(collectionType, implementation, version);

    emit CollectionTemplateUpdated(collectionType, implementation, version);
  }

  /**
   * @notice Gets the latest implementation and version to be used by new collections of the given type.
   * @param collectionType The type of collection to get the template details for.
   * @return implementation The address of the implementation contract.
   * @return version The version of the current template.
   */
  function getCollectionTemplateDetails(
    CollectionType collectionType
  ) external view returns (address implementation, uint version) {
    CollectionTemplateDetails memory templateDetails = collectionTypeToTemplateDetails[collectionType];
    implementation = templateDetails.implementation;
    version = templateDetails.version;
  }

  /**
   * @notice Returns the address of an NFTDropCollection collection given the current
   * implementation version, creator, and nonce.
   * @param collectionType The type of collection this creator has or will create.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the collection contract that would be created by this nonce.
   * @dev This will return the same address whether the collection has already been created or not.
   * Returns address(0) if the collection type is not supported.
   */
  function predictCollectionAddress(
    CollectionType collectionType,
    address creator,
    uint96 nonce
  ) public view returns (address collection) {
    address implementation = collectionTypeToTemplateDetails[collectionType].implementation;
    if (implementation == address(0)) {
      // This will occur if the collectionType is NULL or has not yet been initialized.
      revert NFTCollectionFactorySharedTemplates_Invalid_Collection_Type();
    }

    collection = implementation.predictDeterministicAddress(_getSalt(creator, nonce));
  }

  /**
   * @notice [DEPRECATED] use `predictCollectionAddress` instead.
   * Returns the address of a collection given the current implementation version, creator, and nonce.
   * @param creator The creator of the collection.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the collection contract that would be created by this nonce.
   * @dev This will return the same address whether the collection has already been created or not.
   */
  function predictNFTCollectionAddress(address creator, uint96 nonce) external view returns (address collection) {
    collection = predictCollectionAddress(CollectionType.NFTCollection, creator, nonce);
  }

  /**
   * @dev Salt is address + nonce packed.
   */
  function _getSalt(address creator, uint96 nonce) private pure returns (bytes32) {
    return bytes32((uint256(uint160(creator)) << 96) | uint256(nonce));
  }

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   * @dev This mixin is a total of 1,000 slots.
   */
  uint256[999] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../interfaces/internal/INFTCollectionInitializer.sol";
import "../../interfaces/internal/INFTDropCollectionInitializer.sol";
import "../../interfaces/internal/INFTTimedEditionCollectionInitializer.sol";

import "./NFTCollectionFactoryTypes.sol";

/**
 * @title Initializes factory templates.
 * @dev This provides a better explorer experience, including referencing the version number for the template used.
 */
abstract contract NFTCollectionFactoryTemplateInitializer is NFTCollectionFactoryTypes {
  using Strings for uint256;

  /**
   * @notice Initializes the template with the version number and default parameters.
   * @dev This is called when templates are upgraded and will revert if the template has already been initialized.
   * To downgrade a template, the original template must be redeployed first.
   */
  function _initializeTemplate(CollectionType collectionType, address implementation, uint256 version) internal {
    // Set the template creator to 0 so that it may never be self destructed.
    address payable creator = payable(0);
    string memory symbol = version.toString();
    string memory name = string.concat(getCollectionTypeName(collectionType), " Implementation v", symbol);
    // getCollectionTypeName reverts if the collection type is NULL.

    if (collectionType == CollectionType.NFTCollection) {
      symbol = string.concat("NFTv", symbol);
      INFTCollectionInitializer(implementation).initialize(creator, name, symbol);
    } else if (collectionType == CollectionType.NFTDropCollection) {
      symbol = string.concat("NFTDropV", symbol);
      INFTDropCollectionInitializer(implementation).initialize({
        _creator: creator,
        _name: name,
        _symbol: symbol,
        _baseURI: "ipfs://QmUtCsULTpfUYWBfcUS1y25rqBZ6E5CfKzZg6j9P3gFScK/",
        isRevealed: true,
        _maxTokenId: 1,
        _approvedMinter: address(0),
        _paymentAddress: payable(0)
      });
    } else {
      // if (collectionType == CollectionType.NFTTimedEditionCollection)
      symbol = string.concat("NFTTimedEditionV", symbol);
      INFTTimedEditionCollectionInitializer(implementation).initialize({
        _creator: creator,
        _name: name,
        _symbol: symbol,
        tokenURI_: "ipfs://QmUtCsULTpfUYWBfcUS1y25rqBZ6E5CfKzZg6j9P3gFScK/",
        _mintEndTime: block.timestamp + 1,
        _approvedMinter: address(0),
        _paymentAddress: payable(0)
      });
    }
  }

  // This mixin consumes 0 slots.
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../shared/Constants.sol";

enum CollectionType {
  // Reserve 0 to indicate undefined.
  NULL,
  NFTCollection,
  NFTDropCollection,
  NFTTimedEditionCollection
}

error NFTCollectionFactoryTypes_Collection_Type_Is_Null();

/**
 * @title A mixin to define the types of collections supported by this factory.
 */
abstract contract NFTCollectionFactoryTypes {
  /**
   * @notice Returns the maximum value of the CollectionType enum.
   * @return count The maximum value of the CollectionType enum.
   * @dev Templates are indexed from 1 to this value inclusive.
   */
  function getCollectionTypeCount() external pure returns (uint256 count) {
    count = uint256(type(CollectionType).max);
  }

  /**
   * @notice Returns the name of the collection type.
   * @param collectionType The enum index collection type to check.
   * @return typeName The name of the collection type.
   */
  function getCollectionTypeName(CollectionType collectionType) public pure returns (string memory typeName) {
    if (collectionType == CollectionType.NFTCollection) {
      typeName = NFT_COLLECTION_TYPE;
    } else if (collectionType == CollectionType.NFTDropCollection) {
      typeName = NFT_DROP_COLLECTION_TYPE;
    } else if (collectionType == CollectionType.NFTTimedEditionCollection) {
      typeName = NFT_TIMED_EDITION_COLLECTION_TYPE;
    } else {
      // if (collectionType == CollectionType.NULL)
      revert NFTCollectionFactoryTypes_Collection_Type_Is_Null();
    }
  }

  // This mixin consumes 0 slots.
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title A placeholder contract skipping slots previously consumed by the NFTCollectionFactory upgradeable contract.
 * @author batu-inal & HardlyDifficult
 */
abstract contract NFTCollectionFactoryV1Gap {
  // Previously stored in these slots:
  // uint256[10_000] private __gap;
  //
  // /****** Slot 0 (after inheritance) ******/
  // /**
  //  * @notice The address of the implementation all new NFTCollections will leverage.
  //  * @dev When this is changed, `versionNFTCollection` is incremented.
  //  * @return The implementation address for NFTCollection.
  //  */
  // address public implementationNFTCollection;

  // /**
  //  * @notice The implementation version of new NFTCollections.
  //  * @dev This is auto-incremented each time `implementationNFTCollection` is changed.
  //  * @return The current NFTCollection implementation version.
  //  */
  // uint32 public versionNFTCollection;

  // /****** Slot 1 ******/
  // /**
  //  * @notice The address of the implementation all new NFTDropCollections will leverage.
  //  * @dev When this is changed, `versionNFTDropCollection` is incremented.
  //  * @return The implementation address for NFTDropCollection.
  //  */
  // address public implementationNFTDropCollection;

  // /**
  //  * @notice The implementation version of new NFTDropCollections.
  //  * @dev This is auto-incremented each time `implementationNFTDropCollection` is changed.
  //  * @return The current NFTDropCollection implementation version.
  //  */
  // uint32 public versionNFTDropCollection;

  // /****** End of storage ******/

  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[10_002] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

import "../NFTCollectionFactorySharedTemplates.sol";

/**
 * @title A factory to create NFTCollection contracts.
 */
abstract contract NFTCollectionFactoryNFTCollections is Context, NFTCollectionFactorySharedTemplates {
  /**
   * @notice Emitted when a new NFTCollection is created from this factory.
   * @param collection The address of the new NFT collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param version The implementation version used by the new collection.
   * @param name The name of the collection contract created.
   * @param symbol The symbol of the collection contract created.
   * @param nonce The nonce used by the creator when creating the collection,
   * used to define the address of the collection.
   */
  event NFTCollectionCreated(
    address indexed collection,
    address indexed creator,
    uint256 indexed version,
    string name,
    string symbol,
    uint256 nonce
  );

  /**
   * @notice Create a new collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTCollection(
    string calldata name,
    string calldata symbol,
    uint96 nonce
  ) external returns (address collection) {
    uint256 version;
    address payable sender = payable(_msgSender());
    (collection, version) = _createCollection(CollectionType.NFTCollection, sender, nonce, symbol);
    emit NFTCollectionCreated(collection, sender, version, name, symbol, nonce);

    INFTCollectionInitializer(collection).initialize(sender, name, symbol);
  }

  // This mixin consumes 0 slots.
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

import "../../../libraries/AddressLibrary.sol";

import "../NFTCollectionFactorySharedTemplates.sol";

/**
 * @title A factory to create NFTDropCollection contracts.
 */
abstract contract NFTCollectionFactoryNFTDropCollections is Context, NFTCollectionFactorySharedTemplates {
  struct NFTDropCollectionCreationConfig {
    string name;
    string symbol;
    string baseURI;
    bool isRevealed;
    uint32 maxTokenId;
    address approvedMinter;
    address payable paymentAddress;
    uint96 nonce;
  }

  /**
   * @notice Emitted when a new NFTDropCollection is created from this factory.
   * @param collection The address of the new NFT drop collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max `tokenID` for this collection.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @param version The implementation version used by the new NFTDropCollection collection.
   * @param nonce The nonce used by the creator to create this collection.
   */
  event NFTDropCollectionCreated(
    address indexed collection,
    address indexed creator,
    address indexed approvedMinter,
    string name,
    string symbol,
    string baseURI,
    bool isRevealed,
    uint256 maxTokenId,
    address paymentAddress,
    uint256 version,
    uint256 nonce
  );

  /**
   * @notice Create a new drop collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollection(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      NFTDropCollectionCreationConfig(name, symbol, baseURI, isRevealed, maxTokenId, approvedMinter, payable(0), nonce)
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address.
   * @dev All params other than `paymentAddress` are the same as in `createNFTDropCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollectionWithPaymentAddress(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce,
    address payable paymentAddress
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      NFTDropCollectionCreationConfig(
        name,
        symbol,
        baseURI,
        isRevealed,
        maxTokenId,
        approvedMinter,
        paymentAddress != _msgSender() ? paymentAddress : payable(0),
        nonce
      )
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address derived from the factory.
   * @dev All params other than `paymentAddressFactoryCall` are the same as in `createNFTDropCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param baseURI The base URI for the collection.
   * @param isRevealed Whether the collection is revealed or not.
   * @param maxTokenId The max token id for this collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddressFactoryCall The contract call which will return the address to use for payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTDropCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata baseURI,
    bool isRevealed,
    uint32 maxTokenId,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection) {
    collection = _createNFTDropCollection(
      NFTDropCollectionCreationConfig(
        name,
        symbol,
        baseURI,
        isRevealed,
        maxTokenId,
        approvedMinter,
        AddressLibrary.callAndReturnContractAddress(paymentAddressFactoryCall),
        nonce
      )
    );
  }

  function _createNFTDropCollection(
    NFTDropCollectionCreationConfig memory creationConfig
  ) private returns (address collection) {
    address payable sender = payable(_msgSender());
    uint256 version;
    (collection, version) = _createCollection(
      CollectionType.NFTDropCollection,
      sender,
      creationConfig.nonce,
      creationConfig.symbol
    );

    emit NFTDropCollectionCreated(
      collection,
      sender,
      creationConfig.approvedMinter,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.baseURI,
      creationConfig.isRevealed,
      creationConfig.maxTokenId,
      creationConfig.paymentAddress,
      version,
      creationConfig.nonce
    );

    INFTDropCollectionInitializer(collection).initialize(
      sender,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.baseURI,
      creationConfig.isRevealed,
      creationConfig.maxTokenId,
      creationConfig.approvedMinter,
      creationConfig.paymentAddress
    );
  }

  // This mixin consumes 0 slots.
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

import "../../../libraries/AddressLibrary.sol";
import "../../../libraries/TimeLibrary.sol";

import "../../../interfaces/internal/routes/INFTCollectionFactoryTimedEditions.sol";

import "../NFTCollectionFactorySharedTemplates.sol";

/**
 * @title A factory to create NFTTimedEditionCollection contracts.
 */
abstract contract NFTCollectionFactoryNFTTimedEditionCollections is
  INFTCollectionFactoryTimedEditions,
  Context,
  NFTCollectionFactorySharedTemplates
{
  using TimeLibrary for uint256;

  struct NFTTimedEditionCollectionCreationConfig {
    string name;
    string symbol;
    string tokenURI;
    uint256 mintEndTime;
    address approvedMinter;
    address payable paymentAddress;
    uint96 nonce;
  }

  /**
   * @notice Emitted when a new NFTTimedEditionCollection is created from this factory.
   * @param collection The address of the new NFT drop collection contract.
   * @param creator The address of the creator which owns the new collection.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The token URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @param version The implementation version used by the new NFTTimedEditionCollection collection.
   * @param nonce The nonce used by the creator to create this collection.
   */
  event NFTTimedEditionCollectionCreated(
    address indexed collection,
    address indexed creator,
    address indexed approvedMinter,
    string name,
    string symbol,
    string tokenURI,
    uint256 mintEndTime,
    address paymentAddress,
    uint256 version,
    uint256 nonce
  );

  /**
   * @notice Create a new drop collection contract.
   * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The base URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTTimedEditionCollection(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce
  ) external returns (address collection) {
    collection = _createNFTTimedEditionCollection(
      NFTTimedEditionCollectionCreationConfig(name, symbol, tokenURI, mintEndTime, approvedMinter, payable(0), nonce)
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address.
   * @dev All params other than `paymentAddress` are the same as in `createNFTTimedEditionCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The base URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddress The address that will receive royalties and mint payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTTimedEditionCollectionWithPaymentAddress(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    address payable paymentAddress
  ) external returns (address collection) {
    collection = _createNFTTimedEditionCollection(
      NFTTimedEditionCollectionCreationConfig(
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        paymentAddress != _msgSender() ? paymentAddress : payable(0),
        nonce
      )
    );
  }

  /**
   * @notice Create a new drop collection contract with a custom payment address derived from the factory.
   * @dev All params other than `paymentAddressFactoryCall` are the same as in `createNFTTimedEditionCollection`.
   * The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
   * @param name The collection's `name`.
   * @param symbol The collection's `symbol`.
   * @param tokenURI The base URI for the collection.
   * @param mintEndTime The time at which minting will end.
   * @param approvedMinter An optional address to grant the MINTER_ROLE.
   * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
   * @param paymentAddressFactoryCall The contract call which will return the address to use for payments.
   * @return collection The address of the newly created collection contract.
   */
  function createNFTTimedEditionCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) external returns (address collection) {
    collection = _createNFTTimedEditionCollection(
      NFTTimedEditionCollectionCreationConfig(
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        AddressLibrary.callAndReturnContractAddress(paymentAddressFactoryCall),
        nonce
      )
    );
  }

  function _createNFTTimedEditionCollection(
    NFTTimedEditionCollectionCreationConfig memory creationConfig
  ) private returns (address collection) {
    address payable sender = payable(_msgSender());
    uint256 version;
    (collection, version) = _createCollection(
      CollectionType.NFTTimedEditionCollection,
      sender,
      creationConfig.nonce,
      creationConfig.symbol
    );

    emit NFTTimedEditionCollectionCreated(
      collection,
      sender,
      creationConfig.approvedMinter,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.tokenURI,
      creationConfig.mintEndTime,
      creationConfig.paymentAddress,
      version,
      creationConfig.nonce
    );

    INFTTimedEditionCollectionInitializer(collection).initialize(
      sender,
      creationConfig.name,
      creationConfig.symbol,
      creationConfig.tokenURI,
      creationConfig.mintEndTime,
      creationConfig.approvedMinter,
      creationConfig.paymentAddress
    );
  }

  // This mixin consumes 0 slots.
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/// Constant values shared across mixins.

/**
 * @dev 100% in basis points.
 */
uint256 constant BASIS_POINTS = 10_000;

/**
 * @dev The default admin role defined by OZ ACL modules.
 */
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

/**
 * @dev The max take rate an exhibition can have.
 */
uint256 constant MAX_EXHIBITION_TAKE_RATE = 5_000;

/**
 * @dev Cap the number of royalty recipients.
 * A cap is required to ensure gas costs are not too high when a sale is settled.
 */
uint256 constant MAX_ROYALTY_RECIPIENTS = 5;

/**
 * @dev The minimum increase of 10% required when making an offer or placing a bid.
 */
uint256 constant MIN_PERCENT_INCREMENT_DENOMINATOR = BASIS_POINTS / 1_000;

/**
 * @dev The gas limit used when making external read-only calls.
 * This helps to ensure that external calls does not prevent the market from executing.
 */
uint256 constant READ_ONLY_GAS_LIMIT = 40_000;

/**
 * @dev Default royalty cut paid out on secondary sales.
 * Set to 10% of the secondary sale.
 */
uint96 constant ROYALTY_IN_BASIS_POINTS = 1_000;

/**
 * @dev 10%, expressed as a denominator for more efficient calculations.
 */
uint256 constant ROYALTY_RATIO = BASIS_POINTS / ROYALTY_IN_BASIS_POINTS;

/**
 * @dev The gas limit to send ETH to multiple recipients, enough for a 5-way split.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_MULTIPLE_RECIPIENTS = 210_000;

/**
 * @dev The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
 */
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20_000;

/**
 * @dev The NFT collection type.
 */
string constant NFT_COLLECTION_TYPE = "NFT Collection";

/**
 * @dev The NFT edition collection type.
 */
string constant NFT_TIMED_EDITION_COLLECTION_TYPE = "NFT Timed Edition Collection";

/**
 * @dev The NFT drop collection type.
 */
string constant NFT_DROP_COLLECTION_TYPE = "NFT Drop Collection";

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @title A placeholder contract leaving room for new mixins to be added to the future.
 * @author HardlyDifficult
 */
abstract contract Gap10000 {
  /**
   * @notice This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[10_000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error RouterContext_Not_A_Contract();

/**
 * @title Enables a trusted router contract to override the usual msg.sender address.
 * @author HardlyDifficult
 */
abstract contract RouterContext is Context {
  using AddressUpgradeable for address;

  address private immutable approvedRouter;

  constructor(address router) {
    if (!router.isContract()) {
      revert RouterContext_Not_A_Contract();
    }
    approvedRouter = router;
  }

  /**
   * @notice Returns the router contract which is able to override the msg.sender address.
   * @return router The address of the trusted router.
   */
  function getApprovedRouterAddress() external view returns (address router) {
    router = approvedRouter;
  }

  /**
   * @notice Returns the sender of the transaction.
   * @dev If the msg.sender is the trusted router contract, then the last 20 bytes of the calldata is the authorized
   * sender.
   */
  function _msgSender() internal view virtual override returns (address sender) {
    sender = super._msgSender();
    if (sender == approvedRouter) {
      assembly {
        // The router appends the msg.sender to the end of the calldata
        // source: https://github.com/opengsn/gsn/blob/v3.0.0-beta.3/packages/contracts/src/ERC2771Recipient.sol#L48
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
  }
}

/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./mixins/shared/Gap10000.sol";
import "./mixins/shared/RouterContext.sol";

import "./mixins/nftCollectionFactory/NFTCollectionFactoryACL.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactorySharedTemplates.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactoryTemplateInitializer.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactoryTypes.sol";
import "./mixins/nftCollectionFactory/NFTCollectionFactoryV1Gap.sol";
import "./mixins/nftCollectionFactory/templates/NFTCollectionFactoryNFTCollections.sol";
import "./mixins/nftCollectionFactory/templates/NFTCollectionFactoryNFTDropCollections.sol";
import "./mixins/nftCollectionFactory/templates/NFTCollectionFactoryNFTTimedEditionCollections.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create NFT collections.
 * @dev This creates and initializes an ERC-1167 minimal proxy pointing to an NFT collection contract implementation.
 * @author batu-inal & HardlyDifficult & reggieag
 */
contract NFTCollectionFactory is
  Context,
  RouterContext,
  Initializable,
  NFTCollectionFactoryV1Gap,
  Gap10000,
  NFTCollectionFactoryACL,
  NFTCollectionFactoryTypes,
  NFTCollectionFactoryTemplateInitializer,
  NFTCollectionFactorySharedTemplates,
  NFTCollectionFactoryNFTCollections,
  NFTCollectionFactoryNFTDropCollections,
  NFTCollectionFactoryNFTTimedEditionCollections
{
  /**
   * @notice Defines requirements for the collection factory at deployment time.
   * @param _rolesManager The address of the contract defining roles for collections to use.
   * @param router The trusted router contract address.
   * @dev
   */
  constructor(address _rolesManager, address router) NFTCollectionFactoryACL(_rolesManager) RouterContext(router) {
    // Prevent the template from being initialized.
    _disableInitializers();
  }

  /**
   * @inheritdoc RouterContext
   */
  function _msgSender() internal view override(Context, RouterContext) returns (address sender) {
    sender = super._msgSender();
  }
}