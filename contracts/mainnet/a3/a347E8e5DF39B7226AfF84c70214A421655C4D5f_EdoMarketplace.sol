/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract EdoMarketplaceManagementAdmin is Initializable, OwnableUpgradeable {
    address public depositAddress;
    address public agentAddress;
    address public edoVerseFoundationAddress;
    address public edoVerseIncAddress;

    uint256 public agentRefundFeeRate;
    uint256 public edoVerseFoundationFeeRate;
    uint256 public edoVerseIncFeeRate;

    mapping (address => bool) public isEdoNFTContractAddress;
    mapping (address => bool) public isEdoPaymentContractAddress;

    function setDepositAddress(
        address _depositAddress
    )
        external
        onlyOwner
    {
        require(_depositAddress != address(0), "EdoMarketplaceManagementAdmin: Invalid deposit address.");
        depositAddress = _depositAddress;
    }

    function setAgentAddress(address _agentAddress) external onlyOwner {
        require(_agentAddress != address(0));
        agentAddress = _agentAddress;
    }

    function setEdoVerseFoundationAddress(address _edoVerseFoundationAddress) external onlyOwner {
        require(_edoVerseFoundationAddress != address(0));
        edoVerseFoundationAddress = _edoVerseFoundationAddress;
    }

    function setEdoVerseIncAddress(address _edoVerseIncAddress) external onlyOwner {
        require(_edoVerseIncAddress != address(0));
        edoVerseIncAddress = _edoVerseIncAddress;
    }

    function includeNFTContractAddress(
        address _NFTContractAddress
    )
        external
        onlyOwner
    {
        isEdoNFTContractAddress[_NFTContractAddress] = true;
    }

    function excludeNFTContractAddress(address _NFTContractAddress) external onlyOwner {
        isEdoNFTContractAddress[_NFTContractAddress] = false;
    }

    function isApprovedNFTContractAddress(address _NFTContractAddress) external view onlyOwner returns(bool) {
        return isEdoNFTContractAddress[_NFTContractAddress];
    }

    function includePaymentContractAddress(address _edoPaymentContractAddress) external onlyOwner {
        isEdoPaymentContractAddress[_edoPaymentContractAddress] = true;
    }

    function excludePaymentContractAddress(address _edoPaymentContractAddress) external onlyOwner {
       isEdoPaymentContractAddress[_edoPaymentContractAddress] = false;
    }

    function isApprovedPaymentContractAddress(address _edoPaymentContractAddress) external view onlyOwner returns(bool) {
        return isEdoPaymentContractAddress[_edoPaymentContractAddress];
    }

    function setFeeRateDistribution(
        uint256 _agentRefundFeeRate,
        uint256 _edoVerseFoundationFeeRate,
        uint256 _edoVerseIncFeeRate
    )
        external
        onlyOwner
    {
        uint256 totalFeeRate = _agentRefundFeeRate + _edoVerseFoundationFeeRate + _edoVerseIncFeeRate;
        require(totalFeeRate == 100, "EdoMarketplaceManagement: Total value is invalid.");

        agentRefundFeeRate = _agentRefundFeeRate;
        edoVerseFoundationFeeRate = _edoVerseFoundationFeeRate;
        edoVerseIncFeeRate = _edoVerseIncFeeRate;
    }
}

contract EdoMarketplaceManagement is EdoMarketplaceManagementAdmin {
    using SafeMath for uint256;

    uint256 constant MIN_FEE_RATE = 1;
    uint256 constant MAX_FEE_RATE = 10;
    uint256 constant NON_AGENT_FEE = 5;
    uint256 constant DEMOMINATOR = 100;

    address public agentRefundAddress;

    uint256 public serviceFeeRate;

    modifier onlyAgent() {
        require(agentAddress == msg.sender, "EdoMarketplaceManagement: Caller is not the agent.");
        _;
    }

    modifier onlyAgentOrOwner() {
        require(agentAddress == msg.sender || super.owner() == msg.sender, "EdoMarketplaceManagement: Caller is not the agent.");
        _;
    }

    modifier feeLimit(uint256 feeRate) {
        require(feeRate <= MAX_FEE_RATE, "EdoMarketplaceManagement: Fee rates are too high.");
        require(feeRate >= MIN_FEE_RATE, "EdoMarketplaceManagement: Fee rates are too low.");
        _;
    }

    function setAgentRefundAddress(address _agentRefundAddress) external onlyAgent {
        require(_agentRefundAddress != address(0));
        agentRefundAddress = _agentRefundAddress;
    }

    function setServiceFeeRate(
        uint256 _serviceFeeRate
    )
        external
        onlyAgent
        feeLimit(_serviceFeeRate)
    {
        serviceFeeRate = _serviceFeeRate;
    }

    function getServiceFeeRate() public view returns(uint256) {
        return serviceFeeRate;
    }

    function depositFeeAmount(address paymentContractAddress) external view onlyAgentOrOwner returns(uint256) {
        return IERC20(paymentContractAddress).balanceOf(depositAddress);
    }

    function withdraw(address paymentContractAddress) external onlyAgentOrOwner {
        uint256 balance = IERC20(paymentContractAddress).balanceOf(depositAddress);

        uint256 edoVerseFoundationProfit = balance.mul(edoVerseFoundationFeeRate).div(DEMOMINATOR);
        uint256 edoVerseIncProfit = balance.mul(edoVerseIncFeeRate).div(DEMOMINATOR);
        uint256 agentRefundProfit = balance.sub(edoVerseFoundationProfit).sub(edoVerseIncProfit);

        IERC20(paymentContractAddress).transfer(edoVerseFoundationAddress, edoVerseFoundationProfit);
        IERC20(paymentContractAddress).transfer(edoVerseIncAddress, edoVerseIncProfit);
        IERC20(paymentContractAddress).transfer(agentRefundAddress, agentRefundProfit);
    }
}

contract EdoMarketplace is EdoMarketplaceManagement {
    using SafeMath for uint256;

    struct NftMeta {
        bytes32 nftId;
        address owner;
        address nftContractAddress;
        uint256 tokenId;
        address paymentContractAddress;
        uint256 price;
        bool isListing;
    }

    mapping (bytes32 => NftMeta) public tokenMeta;
    mapping (uint256 => bytes32) public tokenMetaIndex;
    uint256 public tokenMetaIndexCount;
    uint256 public listingNftCount;

    modifier onlyEdoNft(address contractAddress) {
        require(isEdoNFTContractAddress[contractAddress], "EdoMarketplace: Invalid nft contract address.");
        _;
    }

    modifier onlyNftOwner(address nftContractAddress, uint256 tokenId) {
        NftMeta memory nftMeta = tokenMeta[getHash(nftContractAddress, tokenId)];
        require(nftMeta.owner == msg.sender, "EdoMarketplace: Caller is not the owner.");
        _;
    }

    function initialize(
        uint256 _serviceFeeRate,
        uint256 _agentRefundFeeRate,
        uint256 _edoVerseFoundationFeeRate,
        uint256 _edoVerseIncFeeRate,
        address _agentAddress,
        address _agentRefundAddress,
        address _edoVerseFoundationAddress,
        address _edoVerseIncAddress,
        address _edoNFTContractAddress,
        address _edoPaymentContractAddress
    )
        public
        initializer
        feeLimit(_serviceFeeRate)
    {
        uint256 totalFeeRate = _agentRefundFeeRate + _edoVerseFoundationFeeRate + _edoVerseIncFeeRate;
        require(totalFeeRate == 100, "initialize: Total value is invalid.");

        __Ownable_init();

        tokenMetaIndexCount = 0;

        serviceFeeRate = _serviceFeeRate;
        agentRefundFeeRate = _agentRefundFeeRate;
        edoVerseFoundationFeeRate = _edoVerseFoundationFeeRate;
        edoVerseIncFeeRate = _edoVerseIncFeeRate;

        agentAddress = _agentAddress;
        agentRefundAddress = _agentRefundAddress;
        edoVerseFoundationAddress = _edoVerseFoundationAddress;
        edoVerseIncAddress = _edoVerseIncAddress;

        isEdoNFTContractAddress[_edoNFTContractAddress] = true;
        isEdoPaymentContractAddress[_edoPaymentContractAddress] = true;
    }

    function approveErc721(address nftContractAddress, address to, uint256 tokenId) external {
        IERC721(nftContractAddress).approve(to, tokenId);
    }

    function setListingNFT(
        address nftContractAddress,
        uint256 tokenId,
        address paymentContractAddress,
        uint256 price
    )
        public
        onlyEdoNft(nftContractAddress)
    {
        require(depositAddress != address(0), "EdoMarketplace: Invalid deposit address.");
        require(isEdoPaymentContractAddress[paymentContractAddress], "EdoMarketplace: Invalid payment contract address.");

        IERC721(nftContractAddress).transferFrom(msg.sender, depositAddress, tokenId);

        _setNftMeta(
            getHash(nftContractAddress, tokenId),
            msg.sender,
            nftContractAddress,
            tokenId,
            paymentContractAddress,
            price,
            true
        );

        listingNftCount++;
    }

    function buyEdoNFT(
        address nftContractAddress,
        uint256 tokenId
    )
        public
        onlyEdoNft(nftContractAddress)
    {
        bytes32 nftId = getHash(nftContractAddress, tokenId);

        NftMeta memory nftMeta = tokenMeta[nftId];

        require(nftMeta.owner != msg.sender, "EdoMarketplace: You cannot purchase your own NFTs.");
        require(nftMeta.owner != address(0), "EdoMarketplace: Not list.");

        uint256 balance = IERC20(nftMeta.paymentContractAddress).balanceOf(msg.sender);
        require(nftMeta.price < balance, "EdoMarketplace: Insufficient balance.");

        uint256 serviceFeeRate = getServiceFeeRate();

        uint256 serviceProfit = nftMeta.price.mul(serviceFeeRate).div(DEMOMINATOR);
        uint256 sellerProfit = nftMeta.price.sub(serviceProfit);

        IERC20(nftMeta.paymentContractAddress).transferFrom(msg.sender, depositAddress, serviceProfit);
        IERC20(nftMeta.paymentContractAddress).transferFrom(msg.sender, nftMeta.owner, sellerProfit);

        IERC721(nftContractAddress).transferFrom(depositAddress, msg.sender, tokenId);

        tokenMeta[nftId].owner = msg.sender;
        tokenMeta[nftId].isListing = false;
        listingNftCount--;
    }

    function cancelTrade(
        address nftContractAddress,
        uint256 tokenId
    )
        public
        onlyEdoNft(nftContractAddress)
        onlyNftOwner(nftContractAddress, tokenId)
    {
        IERC721(nftContractAddress).transferFrom(depositAddress, msg.sender, tokenId);
        tokenMeta[getHash(nftContractAddress, tokenId)].isListing = false;
        listingNftCount--;
    }

    function getEdoNFTInfo(
        address nftContractAddress,
        uint256 tokenId
    )
        public
        view
        onlyEdoNft(nftContractAddress)
        returns (
            address owner,
            address paymentContractAddress,
            uint256 price,
            bool isListing
        )
    {
        bytes32 nftId = getHash(nftContractAddress, tokenId);

        NftMeta memory nftMeta = tokenMeta[nftId];

        owner = nftMeta.owner;
        paymentContractAddress = nftMeta.paymentContractAddress;
        price = nftMeta.price;
        isListing = nftMeta.isListing;
    }

    function getListingEdoNfts() public view returns(NftMeta[] memory) {
        NftMeta[] memory metadata = new NftMeta[](listingNftCount);

        uint256 index = 0;
        for (uint256 i = 0; i < tokenMetaIndexCount; i++) {
            if (tokenMeta[tokenMetaIndex[i]].isListing) {
                metadata[index] = NftMeta(
                    tokenMeta[tokenMetaIndex[i]].nftId,
                    tokenMeta[tokenMetaIndex[i]].owner,
                    tokenMeta[tokenMetaIndex[i]].nftContractAddress,
                    tokenMeta[tokenMetaIndex[i]].tokenId,
                    tokenMeta[tokenMetaIndex[i]].paymentContractAddress,
                    tokenMeta[tokenMetaIndex[i]].price,
                    tokenMeta[tokenMetaIndex[i]].isListing
                );
                index++;
            }
        }

        return metadata;
    }

    function getEdoNfts() public view returns(NftMeta[] memory) {
        NftMeta[] memory metadata = new NftMeta[](tokenMetaIndexCount);

        uint256 index = 0;
        for (uint256 i = 0; i < tokenMetaIndexCount; i++) {
            metadata[index] = NftMeta(
                tokenMeta[tokenMetaIndex[i]].nftId,
                tokenMeta[tokenMetaIndex[i]].owner,
                tokenMeta[tokenMetaIndex[i]].nftContractAddress,
                tokenMeta[tokenMetaIndex[i]].tokenId,
                tokenMeta[tokenMetaIndex[i]].paymentContractAddress,
                tokenMeta[tokenMetaIndex[i]].price,
                tokenMeta[tokenMetaIndex[i]].isListing
            );
            index++;
        }

        return metadata;
    }

    function getHash(address nftContractAddress, uint256 tokenId) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(nftContractAddress, tokenId));
    }

    function _setNftMeta(
        bytes32 nftId,
        address owner,
        address nftContractAddress,
        uint256 tokenId,
        address paymentContractAddress,
        uint256 price,
        bool isListing
    )
        internal
    {
        NftMeta memory newNftMeta = NftMeta(
            nftId,
            owner,
            nftContractAddress,
            tokenId,
            paymentContractAddress,
            price,
            isListing
        );

        if (tokenMeta[nftId].owner == address(0)) {
            tokenMetaIndex[tokenMetaIndexCount] = nftId;
            tokenMetaIndexCount++;
        }

        tokenMeta[nftId] = newNftMeta;
    }
}