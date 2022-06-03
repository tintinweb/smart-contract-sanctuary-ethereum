/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// File: contracts/interfaces/IStrategy.sol


pragma solidity ^0.8.4;

interface IStrategy {
    function deposit() external;

    function withdraw(address _to, address _asset) external;

    function withdraw(address _to, uint256 _amount) external;

    function withdrawAll() external;

    function totalAssets() external view returns (uint256);
}

// File: contracts/interfaces/IFungibleAssetVaultForDAO.sol


pragma solidity ^0.8.4;

interface IFungibleAssetVaultForDAO {
    function deposit(uint256 amount) external payable;

    function borrow(uint256 amount) external;

    function getCreditLimit(uint256 amount) external view returns (uint256);
}

// File: contracts/interfaces/IBaseRewardPool.sol


pragma solidity ^0.8.4;

interface IBaseRewardPool {
    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    function donate(uint256 _amount) external returns(bool);

    function balanceOf(address) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}

// File: contracts/interfaces/IBooster.sol


pragma solidity ^0.8.4;

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);
    function earmarkRewards(uint256 _pid) external returns(bool);
}
// File: contracts/interfaces/I3CRVZap.sol


pragma solidity ^0.8.4;

interface I3CRVZap {
    function add_liquidity(address _pool, uint256[4] calldata _deposit_amounts, uint256 _min_mint_amount) external returns (uint256);
}
// File: contracts/interfaces/ISwapRouter.sol


pragma solidity ^0.8.4;

interface ISwapRouter {
  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  function exactInput(ExactInputParams calldata params)
    external
    returns (uint256 amountOut);

  function quoteExactInput(bytes calldata path, uint256 amountIn)
    external
    returns (uint256 amountOut);
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: contracts/interfaces/ICurve.sol


pragma solidity ^0.8.4;


interface ICurve is IERC20 {
    function balances(uint256 index) external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 _dx, uint256 _min_dy) external payable returns (uint256);
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/vaults/erc20/strategies/StrategyPUSDConvex.sol


pragma solidity ^0.8.4;











/// @title JPEG'd PUSD Convex autocompounding strategy
/// @notice This strategy autocompounds Convex rewards from the PUSD/USDC/USDT/DAI Curve pool.
/// @dev The strategy deposits either USDC or PUSD in the Curve pool depending on which one has lower liquidity.
/// The strategy sells reward tokens for USDC. If the pool has less PUSD than USDC, this contract uses the
/// USDC {FungibleAssetVaultForDAO} to mint PUSD using USDC as collateral
contract StrategyPUSDConvex is AccessControl, IStrategy {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICurve;

    event Harvested(uint256 wantEarned);

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    /// @param booster Convex Booster's address
    /// @param baseRewardPool Convex BaseRewardPool's address
    /// @param pid The Convex pool id for PUSD/3CRV LP tokens
    struct ConvexConfig {
        IBooster booster;
        IBaseRewardPool baseRewardPool;
        uint256 pid;
    }

    /// @param zap The 3CRV zap address
    /// @param crv3Index The USDC token index in curve's pool
    /// @param usdcIndex The USDC token index in curve's pool
    /// @param pusdIndex The PUSD token index in curve's pool
    struct ZapConfig {
        I3CRVZap zap;
        uint256 crv3Index;
        uint256 usdcIndex;
        uint256 pusdIndex;
    }

    /// @param lp The curve LP token
    /// @param ethIndex The eth index in the curve LP pool
    struct CurveSwapConfig {
        ICurve lp;
        uint256 ethIndex;
    }

    /// @param vault The strategy's vault
    /// @param usdcVault The JPEG'd USDC {FungibleAssetVaultForDAO} address
    struct StrategyConfig {
        address vault;
        IFungibleAssetVaultForDAO usdcVault;
    }

    struct StrategyTokens {
        ICurve want;
        IERC20 pusd;
        IERC20 weth;
        IERC20 usdc;
        IERC20 cvx;
        IERC20 crv;
    }

    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    /// @notice The PUSD/USDC/USDT/DAI Curve LP token
    StrategyTokens public strategyTokens;

    ISwapRouter public immutable v3Router;

    address public feeRecipient;

    CurveSwapConfig public cvxEth;
    CurveSwapConfig public crvEth;

    ZapConfig public zapConfig;
    ConvexConfig public convexConfig;
    StrategyConfig public strategyConfig;

    /// @notice The performance fee to be sent to the DAO/strategists
    Rate public performanceFee;

    /// @notice lifetime strategy earnings denominated in `want` token
    uint256 public earned;

    /// @param _strategyTokens tokens relevant to this strategy
    /// @param _v3Router The Uniswap V3 router
    /// @param _feeAddress The fee recipient address
    /// @param _cvxEth See {CurveSwapConfig}
    /// @param _crvEth See {CurveSwapConfig}
    /// @param _zapConfig See {ZapConfig} struct
    /// @param _convexConfig See {ConvexConfig} struct
    /// @param _strategyConfig See {StrategyConfig} struct
    /// @param _performanceFee The rate of USDC to be sent to the DAO/strategists
    constructor(
        StrategyTokens memory _strategyTokens,
        address _v3Router,
        address _feeAddress,
        CurveSwapConfig memory _cvxEth,
        CurveSwapConfig memory _crvEth,
        ZapConfig memory _zapConfig,
        ConvexConfig memory _convexConfig,
        StrategyConfig memory _strategyConfig,
        Rate memory _performanceFee
    ) {
        require(address(_strategyTokens.want) != address(0), "INVALID_WANT");
        require(address(_strategyTokens.pusd) != address(0), "INVALID_PUSD");
        require(address(_strategyTokens.weth) != address(0), "INVALID_WETH");
        require(address(_strategyTokens.usdc) != address(0), "INVALID_USDC");

        require(address(_strategyTokens.cvx) != address(0), "INVALID_CVX");
        require(address(_strategyTokens.crv) != address(0), "INVALID_CRV");

        require(_v3Router != address(0), "INVALID_UNISWAP_V3");

        require(address(_cvxEth.lp) != address(0), "INVALID_CVXETH_LP");
        require(address(_crvEth.lp) != address(0), "INVALID_CRVETH_LP");
        require(_cvxEth.ethIndex < 2, "INVALID_ETH_INDEX");
        require(_crvEth.ethIndex < 2, "INVALID_ETH_INDEX");

        require(address(_zapConfig.zap) != address(0), "INVALID_3CRV_ZAP");
        require(
            _zapConfig.pusdIndex != _zapConfig.crv3Index,
            "INVALID_CURVE_INDEXES"
        );
        require(_zapConfig.pusdIndex < 2, "INVALID_PUSD_CURVE_INDEX");
        require(_zapConfig.crv3Index < 2, "INVALID_3CRV_CURVE_INDEX");
        require(_zapConfig.usdcIndex < 4, "INVALID_USDC_CURVE_INDEX");

        require(
            address(_convexConfig.booster) != address(0),
            "INVALID_CONVEX_BOOSTER"
        );
        require(
            address(_convexConfig.baseRewardPool) != address(0),
            "INVALID_CONVEX_BASE_REWARD_POOL"
        );
        require(address(_strategyConfig.vault) != address(0), "INVALID_VAULT");
        require(
            address(_strategyConfig.usdcVault) != address(0),
            "INVALID_USDC_VAULT"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setFeeRecipient(_feeAddress);
        setPerformanceFee(_performanceFee);

        strategyTokens = _strategyTokens;

        feeRecipient = _feeAddress;

        cvxEth = _cvxEth;
        crvEth = _crvEth;

        v3Router = ISwapRouter(_v3Router);

        zapConfig = _zapConfig;
        convexConfig = _convexConfig;
        strategyConfig = _strategyConfig;

        _strategyTokens.want.safeApprove(
            address(_convexConfig.booster),
            type(uint256).max
        );
        _strategyTokens.cvx.safeApprove(address(_cvxEth.lp), type(uint256).max);
        _strategyTokens.crv.safeApprove(address(_crvEth.lp), type(uint256).max);
        _strategyTokens.weth.safeApprove(address(_v3Router), type(uint256).max);
        _strategyTokens.usdc.safeApprove(
            address(_strategyConfig.usdcVault),
            type(uint256).max
        );
        _strategyTokens.usdc.safeApprove(
            address(_zapConfig.zap),
            type(uint256).max
        );
        _strategyTokens.pusd.safeApprove(
            address(_zapConfig.zap),
            type(uint256).max
        );
    }

    modifier onlyVault() {
        require(msg.sender == address(strategyConfig.vault), "NOT_VAULT");
        _;
    }

    /// @notice Allows the DAO to set the performance fee
    /// @param _performanceFee The new performance fee
    function setPerformanceFee(Rate memory _performanceFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _performanceFee.denominator != 0 &&
                _performanceFee.denominator >= _performanceFee.numerator,
            "INVALID_RATE"
        );
        performanceFee = _performanceFee;
    }

    /// @notice Allows the DAO to set the USDC vault
    /// @param _vault The new USDC vault
    function setUSDCVault(address _vault)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_vault != address(0), "INVALID_USDC_VAULT");
        strategyConfig.usdcVault = IFungibleAssetVaultForDAO(_vault);
    }

    function setFeeRecipient(address _newRecipient)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newRecipient != address(0), "INVALID_FEE_RECIPIENT");

        feeRecipient = _newRecipient;
    }

    /// @return The amount of `want` tokens held by this contract
    function heldAssets() public view returns (uint256) {
        return strategyTokens.want.balanceOf(address(this));
    }

    /// @return The amount of `want` tokens deposited in the Convex pool by this contract
    function depositedAssets() public view returns (uint256) {
        return convexConfig.baseRewardPool.balanceOf(address(this));
    }

    /// @return The total amount of `want` tokens this contract manages (held + deposited)
    function totalAssets() external view override returns (uint256) {
        return heldAssets() + depositedAssets();
    }

    /// @notice Allows anyone to deposit the total amount of `want` tokens in this contract into Convex
    function deposit() public override {
        ConvexConfig memory convex = convexConfig;
        convex.booster.depositAll(convex.pid, true);
    }

    /// @notice Controller only function that allows to withdraw non-strategy tokens (e.g tokens sent accidentally).
    /// CVX and CRV can be withdrawn with this function.
    function withdraw(address _to, address _asset)
        external
        override
        onlyRole(STRATEGIST_ROLE)
    {
        require(_to != address(0), "INVALID_ADDRESS");
        require(address(strategyTokens.want) != _asset, "want");
        require(address(strategyTokens.pusd) != _asset, "pusd");
        require(address(strategyTokens.usdc) != _asset, "usdc");
        require(address(strategyTokens.weth) != _asset, "weth");

        uint256 balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(_to, balance);
    }

    /// @notice Allows the controller to withdraw `want` tokens. Normally used with a vault withdrawal
    /// @param _to The address to send the tokens to
    /// @param _amount The amount of `want` tokens to withdraw
    function withdraw(address _to, uint256 _amount)
        external
        override
        onlyVault
    {
        ICurve _want = strategyTokens.want;

        uint256 balance = _want.balanceOf(address(this));
        //if the contract doesn't have enough want, withdraw from Convex
        if (balance < _amount) {
            unchecked {
                convexConfig.baseRewardPool.withdrawAndUnwrap(
                    _amount - balance,
                    false
                );
            }
        }

        _want.safeTransfer(_to, _amount);
    }

    /// @notice Allows the controller to withdraw all `want` tokens. Normally used when migrating strategies
    function withdrawAll() external override onlyVault {
        ICurve _want = strategyTokens.want;

        convexConfig.baseRewardPool.withdrawAllAndUnwrap(true);

        uint256 balance = _want.balanceOf(address(this));
        _want.safeTransfer(msg.sender, balance);
    }

    /// @notice Allows members of the `STRATEGIST_ROLE` to compound Convex rewards into Curve
    /// @param minOutCurve The minimum amount of `want` tokens to receive
    function harvest(uint256 minOutCurve) external onlyRole(STRATEGIST_ROLE) {
        convexConfig.baseRewardPool.getReward(address(this), true);

        IERC20 _usdc = strategyTokens.usdc;
        //Prevent `Stack too deep` errors
        {
            uint256 cvxBalance = strategyTokens.cvx.balanceOf(address(this));
            if (cvxBalance > 0) {
                CurveSwapConfig memory _cvxEth = cvxEth;
                //minOut is not needed here, we already have it on the Curve deposit
                _cvxEth.lp.exchange(
                    1 - _cvxEth.ethIndex,
                    _cvxEth.ethIndex,
                    cvxBalance,
                    0
                );
            }

            uint256 crvBalance = strategyTokens.crv.balanceOf(address(this));
            if (crvBalance > 0) {
                CurveSwapConfig memory _crvEth = crvEth;
                //minOut is not needed here, we already have it on the Curve deposit
                _crvEth.lp.exchange(
                    1 - _crvEth.ethIndex,
                    _crvEth.ethIndex,
                    crvBalance,
                    0
                );
            }

            IERC20 _weth = strategyTokens.weth;
            uint256 wethBalance = _weth.balanceOf(address(this));
            require(wethBalance != 0, "NOOP");

            //minOut is not needed here, we already have it on the Curve deposit
            ISwapRouter.ExactInputParams memory params = ISwapRouter
                .ExactInputParams(
                    abi.encodePacked(_weth, uint24(500), _usdc),
                    address(this),
                    block.timestamp,
                    wethBalance,
                    0
                );

            v3Router.exactInput(params);
        }

        StrategyConfig memory strategy = strategyConfig;
        ZapConfig memory zap = zapConfig;

        uint256 usdcBalance = _usdc.balanceOf(address(this));

        //take the performance fee
        uint256 fee = (usdcBalance * performanceFee.numerator) /
            performanceFee.denominator;
        _usdc.safeTransfer(feeRecipient, fee);
        unchecked {
            usdcBalance -= fee;
        }

        ICurve _want = strategyTokens.want;

        uint256 pusdCurveBalance = _want.balances(zap.pusdIndex);
        uint256 crv3Balance = _want.balances(zap.crv3Index);

        //The curve pool has 4 tokens, we are doing a single asset deposit with either USDC or PUSD
        uint256[4] memory liquidityAmounts = [uint256(0), 0, 0, 0];
        if (crv3Balance > pusdCurveBalance) {
            //if there's more USDC than PUSD in the pool, use USDC as collateral to mint PUSD
            //and deposit it into the Curve pool
            strategy.usdcVault.deposit(usdcBalance);

            //check the vault's credit limit, it should be 1:1 for USDC
            uint256 toBorrow = strategy.usdcVault.getCreditLimit(usdcBalance);

            strategy.usdcVault.borrow(toBorrow);
            liquidityAmounts[zap.pusdIndex] = toBorrow;
        } else {
            //if there's more PUSD than USDC in the pool, deposit USDC
            liquidityAmounts[zap.usdcIndex] = usdcBalance;
        }

        zap.zap.add_liquidity(address(_want), liquidityAmounts, minOutCurve);

        uint256 wantBalance = heldAssets();

        deposit();

        earned += wantBalance;
        emit Harvested(wantBalance);
    }
}