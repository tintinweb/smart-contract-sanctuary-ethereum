/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

// pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

// pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

// pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

// pragma solidity ^0.8.0;

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

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
}


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

// pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}


// Dependency file: contracts\interfaces\IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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

// Dependency file: contracts\interfaces\IUniswapV2Factory.sol

// Uniswap V2
// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// Dependency file: contracts\interfaces\IUniswapV2Router02.sol

// Uniswap V2
// pragma solidity 0.8.4;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

// pragma solidity ^0.8.1;

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// pragma solidity ^0.8.0;

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


// Root file: contracts\DGENICO.sol

pragma solidity 0.8.4;

// import "contracts\interfaces\IUniswapV2Factory.sol";
// import "contracts\interfaces\IUniswapV2Router02.sol";
contract DGENICO is Ownable, AccessControl, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct User {
    address account;
    address sponsor;
    uint256 tokensOfUser;
    bool exemptFromFees;
  }
  struct DGENAllocationEntity {
    uint256 icoRound;
    uint256 tokenQuantity;
    uint256 creationTime;
    bool isSponsored; // True when tokens are obtained from an affiliate's purchase
  }
  mapping(address => User) private _users;
  mapping(address => DGENAllocationEntity[]) private _dgenAllocationsOfUser;
  mapping(address => uint256) private _whitelistQuantitiesOfUser;
  mapping(address => uint256) private _affiliateCountOfUser;

  uint256 public totalUsers = 0;
  uint256 public totalTokenAllocations = 0;
  uint256 public totalTokensMinted = 0;

  IERC20 public supportedToken;

  // The safe that stores the tokens sent by users for the mint
  address payable public safeWallet;

  // Related to the mint
  uint256 public icoRound = 0; // 0 = Private sale - then rounds 1, 2, 3, etc.
  uint256 public mintPrice; // (/1000) - Price per DGEN token (in USD)
  // uint256 public balanceForSafeWallet = 0;
  // uint256 public minimumBalanceForSafeWalletToSwap = 0;
  uint256 public minimumUsdQuantityToMint; // Minimum token quantity required to mint
  uint256 public totalTokensToMint = 10_000_000e18; // All tokens available in the presale - 10M with 18 decimals = USD 200k for presale
  bool public isMintPaused = false; // If set to true, no tokens can be minted

  // Related to the referral system
  bool public isSponsorBonusPaused = true; // If set to true, sponsors will not receive bonus tokens - activated after presale
  bool public isAffiliateBonusPaused = true; // If set to true, affiliates will not receive bonus tokens
  uint256 public sponsorBonus = 20; // /1000 - Percentage of commission tokens for sponsors - 2% by default
  uint256 public affiliateBonus = 0; // /1000 - Percentage of bonus tokens for affiliates - 0% by default
  uint256 public minimumTokensOfUserToBecomeSponsor = 0; // Amount of tokens one must mint before becoming a sponsor

  // Events
  event HasMintedTokens(address account, uint256 tokenQuantity, bool isSponsored, uint256 mintTime); // `isSponsored`: token allocation comes from an affiliate of `account`'s purchase
  event SponsorGotNewAffiliate(address affiliateAccount, address sponsorAccount);
  event SentSupportedTokenBalance(uint256 quantity);

  constructor(
    address payable _safeWallet,
    address _supportedTokenAddress,
    uint256 _presaleMintPrice,
    uint256 _minimumUsdQuantityToMint
  ) {
    safeWallet = _safeWallet;
    supportedToken = IERC20(_supportedTokenAddress);
    
    _users[msg.sender].exemptFromFees = true;
    mintPrice = _presaleMintPrice;
    minimumUsdQuantityToMint = _minimumUsdQuantityToMint;

    // // Add supported tokens: BNB, BUSD for BSC; ETH, USDT and USDC for Ethereum...
    // // BNB
    // _addSupportedToken(
    //   _supportedTokenOne,
    //   2e22,
    //   0 // Each tx = send to safeWallet
    // );
    // // BUSD
    // _addSupportedToken(_supportedTokenTwo, 5e19, 50);

    // Add supported tokens from constructor
    // for (uint256 i = 0; i < _supportedTokenAddresses.length; i++) {
    //   _addSupportedToken(
    //     _supportedTokenAddresses[i],
    //     _supportedTokenPresaleMintPrices[i],
    //     _supportedTokenMinimumBalancesForSafeWalletToSwap[i]
    //   );
    // }
  }

  receive() external payable {}

  // Standard function for minting tokens - requires the sender to pay a certain amount of supported tokens
  function mintTokensSupportingSponsor(
    address _sponsorAddress,
    uint256 _supportedTokenAmount
  ) external nonReentrant {
    // Checks
    require(!isMintPaused, "Mint is paused until further notice");
    // Each token requires a minimum quantity per tx, in order to cover gas fees
    require(_supportedTokenAmount >= minimumUsdQuantityToMint, "Cannot mint tokens: quantity is too low");
    // Price in supported token for each DGEN token minted
    uint256 mintedDGENTokens = _supportedTokenAmount * mintPrice / 1000;
    require(totalTokensMinted + mintedDGENTokens < totalTokensToMint, "Cannot mint tokens: quantity is too high");

    // Presale: verify whitelist
    if (icoRound == 0) {
      require(
        _whitelistQuantitiesOfUser[msg.sender] >= mintedDGENTokens + _users[msg.sender].tokensOfUser,
        "Cannot mint tokens: whitelist quantity is too low"
      );
    }

    // Handle affiliates and sponsors
    _setSponsor(msg.sender, _sponsorAddress);

    // Update sponsorAddress and use it for next steps
    address sponsorAddress_ = _users[msg.sender].sponsor;

    if (sponsorAddress_ == address(0)) {
      // No sponsor - Normal quantity of tokens minted by user
      _mintTokens(msg.sender, icoRound, mintedDGENTokens, false);
    } else {
      require(
        getSponsorEligibility(sponsorAddress_),
        "Cannot mint tokens: sponsor has not minted enough tokens"
      );

      // Handle sponsor fee
      if (!isSponsorBonusPaused) {
        uint256 _sponsorTokens = (mintedDGENTokens * sponsorBonus) / 1000;
        _mintTokens(sponsorAddress_, icoRound, _sponsorTokens, true);
      }

      // Add bonus tokens for affiliate
      uint256 _affiliateTokens;

      if (!isAffiliateBonusPaused) {
        _affiliateTokens = (mintedDGENTokens * (1000 + affiliateBonus)) / 1000;
      } else {
        _affiliateTokens = mintedDGENTokens;
      }

      _mintTokens(msg.sender, icoRound, _affiliateTokens, false);
    }

    // Transfer supported tokens (skip step if msg.sender is exempt from fees)
    if (!_users[msg.sender].exemptFromFees) {
      _processPaymentForMint(msg.sender, _supportedTokenAmount);
    }
  }

  /* DGEN Internal functions */

  /* Related to the mint */

  function _processPaymentForMint(
    address _account,
    uint256 _supportedTokenAmount
  ) internal {
    require(
      supportedToken.balanceOf(_account) >= _supportedTokenAmount,
      "Cannot process payment for mint: user's supported token balance is too low"
    );

    // Send tokens directly to safeWallet
    supportedToken.safeTransferFrom(_account, safeWallet, _supportedTokenAmount);
    // balanceForSafeWallet += _supportedTokenAmount;
    // // When the balance reaches a threshold, swap for wrapped governance token and send to safeWallet
    // if (balanceForSafeWallet > minimumBalanceForSafeWalletToSwap) {
    //   _sendToSafeWallet(false);
    // }
  }

  // function _sendToSafeWallet(bool _forceSwapAndTransfer) internal {
  //   uint256 tokenQuantity = supportedToken.balanceOf(address(this));

  //   require(
  //     (tokenQuantity > minimumBalanceForSafeWalletToSwap) ||
  //     _forceSwapAndTransfer,
  //     "Not enough supported tokens to send to safeWallet"
  //   );

  //   // Reset balance of supported token
  //   balanceForSafeWallet = 0;

  //   // Send to safeWallet
  //   supportedToken.transfer(safeWallet, tokenQuantity);

  //   emit SentSupportedTokenBalance(tokenQuantity);
  // }

  /* Related to supported tokens for the mint */

  // function _addSupportedToken(
  //   address _tokenAddress,
  //   uint256 _mintPrice,
  //   uint256 _minimumBalanceForSafeWalletToSwap
  // ) internal {
  //   _supportedTokens[totalSupportedTokens] = SupportedToken(
  //     _tokenAddress,
  //     totalSupportedTokens,
  //     _mintPrice,
  //     _minimumBalanceForSafeWalletToSwap,
  //     0
  //   );
  //   totalSupportedTokens++;
  // }

  /* Related to the referral system */

  function _setSponsor(address _account, address _sponsorAddress) internal {
    // If _account does not have a sponsor yet but uses a referral link
    if (_sponsorAddress != address(0) && _sponsorAddress != _account && _users[_account].sponsor == address(0)) {
      _setAffiliate(_sponsorAddress, _account);
      _users[_account].sponsor = _sponsorAddress;
    }
  }

  function _setAffiliate(address _account, address _affiliateAddress) internal {
    _affiliateCountOfUser[_account]++;
    emit SponsorGotNewAffiliate(_account, _affiliateAddress);
  }

  // Important safety checks must be made when using this function
  function _mintTokens(
    address _account,
    uint256 _icoRound,
    uint256 _tokenQuantity,
    bool _isSponsored
  ) internal {
    _dgenAllocationsOfUser[_account].push(
      DGENAllocationEntity({
        icoRound: _icoRound,
        tokenQuantity: _tokenQuantity,
        creationTime: block.timestamp,
        isSponsored: _isSponsored
      })
    );

    // Increment token allocation count
    totalTokenAllocations++;

    // Increment token count of user
    _users[_account].tokensOfUser += _tokenQuantity;

    // Increment total tokens minted
    totalTokensMinted += _tokenQuantity;

    emit HasMintedTokens(_account, _tokenQuantity, _isSponsored, block.timestamp);
  }

  /*
    DGEN View functions
  */

  function getTotalUsers() external view returns (uint256) {
    return totalUsers;
  }

  function getTotalTokensMinted() external view returns (uint256) {
    return totalTokensMinted;
  }

  function getTotalTokensToMint() external view returns (uint256) {
    return totalTokensToMint;
  }

  function getTokensOfUser(address _account) external view returns (uint256) {
    return _users[_account].tokensOfUser;
  }

  function getTokenAllocationCountOfUser(address _account) external view returns (uint256) {
    return _dgenAllocationsOfUser[_account].length;
  }

  // Returns the amount of tokens obtained from affiliates
  function getAffiliatedTokensOfUser(address _account) external view returns (uint256) {
    DGENAllocationEntity[] memory allocations = _dgenAllocationsOfUser[_account];

    uint256 affiliatedTokensOfUser = 0;
    for (uint256 i = 0; i < allocations.length; i++) {
      if (allocations[i].isSponsored) {
        affiliatedTokensOfUser += allocations[i].tokenQuantity;
      }
    }

    return affiliatedTokensOfUser;
  }

  // Checks whether user already has a sponsor
  function getUserAffiliationStatus(address _account) public view returns (bool) {
    return !(_users[_account].sponsor == address(0));
  }

  // Returns number of affiliates of an address
  function getAffiliateCountOfUser(address _account) external view returns (uint256) {
    return _affiliateCountOfUser[_account];
  }

  function getTokenAllocationDgenValues(address _account) external view returns (uint256[] memory) {
    DGENAllocationEntity[] memory allocations = _dgenAllocationsOfUser[_account];
    uint256 numberOfAllocations = allocations.length;
    uint256[] memory dgenValues = new uint256[](numberOfAllocations);

    for (uint256 i = 0; i < numberOfAllocations; i++) {
      dgenValues[i] = allocations[i].tokenQuantity;
    }

    return dgenValues;
  }

  // "True" values = allocations earned as a sponsor; "False" values = allocations bought by user
  function getTokenAllocationSponsorStates(address _account) external view returns (bool[] memory) {
    DGENAllocationEntity[] memory allocations = _dgenAllocationsOfUser[_account];
    uint256 numberOfAllocations = allocations.length;
    bool[] memory sponsorStates = new bool[](numberOfAllocations);

    for (uint256 i = 0; i < numberOfAllocations; i++) {
      sponsorStates[i] = allocations[i].isSponsored;
    }

    return sponsorStates;
  }

  function getTokenAllocationCreationTimes(address _account) external view returns (uint256[] memory) {
    DGENAllocationEntity[] memory allocations = _dgenAllocationsOfUser[_account];
    uint256 numberOfAllocations = allocations.length;
    uint256[] memory creationTimes = new uint256[](numberOfAllocations);

    for (uint256 i = 0; i < numberOfAllocations; i++) {
      creationTimes[i] = allocations[i].creationTime;
    }

    return creationTimes;
  }

  function getTokenAllocationCreationTime(address _account, uint256 _allocationIndex)
    external
    view
    returns (uint256)
  {
    return _dgenAllocationsOfUser[_account][_allocationIndex].creationTime;
  }

  // Useful on the frontend to warn user in case his sponsor is not eligible
  function getSponsorEligibility(address _account) public view returns (bool) {
    return _users[_account].tokensOfUser >= minimumTokensOfUserToBecomeSponsor;
  }

  function getWhitelistStatus(address _account) public view returns (bool) {
    return _whitelistQuantitiesOfUser[_account] != 0;
  }

  function getWhitelistQuantity(address _account) public view returns (uint256) {
    return _whitelistQuantitiesOfUser[_account];
  }

  /*
    DGEN DAO functions
  */

  function exemptAddressFromFees(address _account) external onlyOwner {
    _users[_account].exemptFromFees = true;
  }

  function includeAddressInFees(address _account) external onlyOwner {
    _users[_account].exemptFromFees = false;
  }

  function whitelistAddress(address _account, uint256 _amount) external onlyOwner {
    _whitelistQuantitiesOfUser[_account] = _amount;
  }

  function whitelistAddresses(address[] memory _accounts, uint256 _amount) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      _whitelistQuantitiesOfUser[_accounts[i]] = _amount;
    }
  }

  // Directly mint DGEN tokens in batch for "_accounts", all with the same amounts
  // Does not process to any payment
  function airdropTokens(
    address[] memory _accounts,
    uint256 _icoRound,
    uint256 _tokenQuantity
  ) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      _mintTokens(_accounts[i], _icoRound, _tokenQuantity, false);
    }
  }

  /* Related to payments */

  function withdraw(uint256 _amount) external onlyOwner {
    payable(msg.sender).transfer(_amount);
  }

  function withdrawERC20(address _erc20, uint256 _amount) external onlyOwner {
    IERC20(_erc20).transfer(msg.sender, _amount);
  }

  function setSafeWallet(address payable _safeWallet) external onlyOwner {
    safeWallet = _safeWallet;
  }

  function setSupportedToken(address _supportedTokenAddress) external onlyOwner {
    supportedToken = IERC20(_supportedTokenAddress);
  }

  /* Related to swap */

  // function setDEXRouter(address _dexRouter) external onlyOwner {
  //   dexRouter = IUniswapV2Router02(_dexRouter);
  // }

  // function sendToSafeWallet() external onlyOwner {
  //   _sendToSafeWallet(true);
  // }

  /* Related to the mint */

  function setIcoRound(uint256 _icoRound) external onlyOwner {
    icoRound = _icoRound;
  }

  function pauseMint(bool _bool) external onlyOwner {
    isMintPaused = _bool;
  }


  function setMinimumUsdQuantityToMint(uint256 _minimumUsdQuantityToMint) external onlyOwner {
    minimumUsdQuantityToMint = _minimumUsdQuantityToMint;
  }

  function setTotalTokensToMint(uint256 _totalTokensToMint) external onlyOwner {
    totalTokensToMint = _totalTokensToMint;
  }

  /* Related to supported tokens for the mint */

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  // function setMinimumSupportedTokenForSafeWalletBalanceToSwap(uint256 _minimumBalanceForSafeWalletToSwap) external onlyOwner {
  //   minimumBalanceForSafeWalletToSwap = _minimumBalanceForSafeWalletToSwap;
  // }

  /* Related to the referral system */

  function setSponsor(address _account, address _sponsorAddress) external onlyOwner {
    _setSponsor(_account, _sponsorAddress);
  }

  function setAffiliate(address _account, address _affiliateAddress) external onlyOwner {
    _setAffiliate(_account, _affiliateAddress);
  }

  function setMinimumTokensOfUserToBecomeSponsor(uint256 _minimumTokensOfUserToBecomeSponsor)
    external
    onlyOwner
  {
    minimumTokensOfUserToBecomeSponsor = _minimumTokensOfUserToBecomeSponsor;
  }

  // Affiliate bonus = percentage of bonus DGEN tokens for affiliates
  function pauseAffiliateBonus(bool _bool) external onlyOwner {
    isAffiliateBonusPaused = _bool;
  }

  function setAffiliateBonus(uint256 _affiliateBonus) external onlyOwner {
    affiliateBonus = _affiliateBonus;
  }

  // Sponsor bonus = commission for sponsor
  function pauseSponsorBonus(bool _bool) external onlyOwner {
    isSponsorBonusPaused = _bool;
  }

  function setSponsorBonus(uint256 _sponsorBonus) external onlyOwner {
    sponsorBonus = _sponsorBonus;
  }
}