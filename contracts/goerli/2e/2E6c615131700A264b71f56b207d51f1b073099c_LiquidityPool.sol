//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./interfaces/ILiquidityPool.sol";
import "./interfaces/ILockBox.sol";
import "./interfaces/ILPToken.sol";
import "./interfaces/utils/ITokenTransferProxy.sol";
import "./utils/AccessHandler.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title Liquidity Pool
 * @author Michael Larsen
 * @notice This is the liquidity provider contract that owns tokens.
 * @notice Tokens are deposited by stakers, that will receive LP tokens
 *         as proof-of-deposit.
 * @notice The staked and the LP tokens can be unstaked by swapping back.
 * @notice Accesshandler is Initializable.
 */
contract LiquidityPool is AccessHandler, ILiquidityPool {
    ILockBox private lockBox;
    ITokenTransferProxy private tokenTransferProxy;
    ILPToken private lpToken;

    /**
     * @notice Event fires when withdraw for 0 tokens is attempted
     * @param owner is the owner of the tokens
     * @param token is the token contract address
     */
    event WithdrawZero(address indexed owner, address indexed token);

    /**
     * Error for Insufficient liquidity balancefor withdrawel.
     * Needed `required` but only `available` available.
     * @param available balance available.
     * @param required requested amount to transfer.
     */
    error InsufficientBalance(uint256 available, uint256 required);

    /**
     * Error for Insufficient LP Token balance for withdrawel.
     * Needed `required` but only `available` available.
     * @param available balance available.
     * @param required requested amount to transfer.
     */
    error InsufficientLPTokenBalance(uint256 available, uint256 required);

    /**
     * Error for Insufficient allowance for withdrawel.
     * Needed `required` but only `available` available.
     * @param available allowance available.
     * @param required requested amount to transfer.
     */
    error InsufficientAllowance(uint256 available, uint256 required);

    /**
     * Error for token transfer failure, prob due to lack of tokens.
     * @param user is the address that tried to deposit.
     * @param token is the token contract address
     * @param amount is the requested amount to transfer.
     */
    error TokenTransferFailed(address user, address token, uint256 amount);

    constructor() AccessHandler() {}

    /**
     * @notice Initializes this contract with reference to other contracts.
     * @param _lockBox The LockBox contract address.
     * @param _tokenTransferProxy The TokenTransferProxy contract  address.
     * @param _lpToken The Token used to keep the liquidity balance.
     */
    function init(
        ILockBox _lockBox,
        ITokenTransferProxy _tokenTransferProxy,
        ILPToken _lpToken
    )
        external
        notInitialized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockBox = _lockBox;
        tokenTransferProxy = _tokenTransferProxy;
        lpToken = _lpToken;
        AccessHandler.initialize();
    }

    /**
     * @notice Deposits tokens and updates the users locked amount.
     * @param token The token type to deposit.
     * @param amount The amount to add.
     */
    function depositToken(address token, uint256 amount)
        external
        override
        isInitialized
    {
        address owner = msg.sender;
        bool success = transferViaProxy(token, owner, address(lockBox), amount);
        if (!success) {
            revert TokenTransferFailed({
                user: owner,
                token: token,
                amount: amount
            });
        }
        lpToken.mint(owner, amount);
        lockBox.lockAmount(owner, token, amount);
    }

    /**
     * @notice Let the owner of deposited tokens withdraw them all again.
     * @param token The token type to withdraw.
     */
    function withDrawAllTokens(address token) external override {
        address owner = msg.sender;
        uint256 lockedAmount = lockBox.getLockedAmount(owner, token);
        if (lockedAmount == 0) {
            emit WithdrawZero(owner, token);
            return;
        }
        returnTokensForOwner(owner, token, lockedAmount);
    }

    /**
     * @notice Let the owner of deposited tokens withdraw them again.
     * @param token The token type to withdraw.
     * @param amount The amount to return.
     */
    function withDrawTokens(address token, uint256 amount) external override {
        address owner = msg.sender;
        if (amount == 0) {
            emit WithdrawZero(owner, token);
            return;
        }
        returnTokensForOwner(owner, token, amount);
    }

    /**
     * @notice Let the owner of this contract return all tokens to a user.
     * @param owner The user to update.
     * @param token The token type.
     */
    function returnAllTokensAsAdmin(address owner, address token)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {   // TODO: Determine if this is sufficient admin override to support our needs.
        //       It will not allow to return unbalanced CLT / LPT balances
        uint256 lockedAmount = lockBox.getLockedAmount(owner, token);
        uint256 lpBalance = lpToken.balanceOf(owner);
        uint256 tokenBalance = IERC20(token).balanceOf(address(lockBox));
        uint256 allowance = lpToken.allowance(owner, address(this));
        uint256 available = lockedAmount;
        if (lpBalance < available) available = lpBalance;
        if (tokenBalance < available) available = tokenBalance;
        if (allowance < available) available = allowance;
        if (available == 0) {
            emit WithdrawZero(owner, token);
            return;
        }
        lpToken.burnFrom(owner, available);
        lockBox.unlockAmountAndTransfer(owner, token, available);
    }

    /**
     * @notice Return deposited tokens to them and burn the lp tokens.
     * @param owner The user to update.
     * @param token The token type to withdraw.
     * @param amount The amount to return.
     */
    function returnTokensForOwner(
        address owner,
        address token,
        uint256 amount
    ) private {
        if (amount == 0) {
            emit WithdrawZero(owner, token);
            return;
        }
        uint256 lockedAmount = lockBox.getLockedAmount(owner, token);
        if (amount > lockedAmount) {
            revert InsufficientBalance({
                available: lockedAmount,
                required: amount
            });
        }
        uint256 lpBalance = lpToken.balanceOf(owner);
        if (amount > lpBalance) {
            revert InsufficientLPTokenBalance({
                available: lpBalance,
                required: amount
            });
        }
        uint256 allowance = lpToken.allowance(owner, address(this));
        if (amount > allowance) {
            revert InsufficientAllowance({
                available: allowance,
                required: amount
            });
        }
        lpToken.burnFrom(owner, amount);
        lockBox.unlockAmountAndTransfer(owner, token, amount);
    }

    /**
     * @notice Burn an amount of LP tokens.
     * @param owner Address of token owner.
     * @param value Amount of token to burn.
     */
    function burnLPTokens(address owner, uint256 value) private {
        lpToken.burnFrom(owner, value);
    }

    /**
     * @notice Transfers tokens using TokenTransferProxy.
     * @param token Address of token type to transfer.
     * @param from Address transfering tokens from.
     * @param to Address receiving tokens.
     * @param value Amount of tokens to transfer.
     * @return bool Success of tokens transfer.
     */
    function transferViaProxy(
        address token,
        address from,
        address to,
        uint256 value
    ) private returns (bool) {
        return tokenTransferProxy.transferFrom(token, from, to, value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

interface ILiquidityPool {
    function depositToken(address, uint256) external;
    function withDrawAllTokens(address) external;
    function withDrawTokens(address, uint256) external;
    function returnAllTokensAsAdmin(address, address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

interface ILockBox {
    function lockAmount(address, address, uint256) external;
    function unlockAmount(address, address, uint256)
        external
        returns (bool);
    function unlockAmountAndTransfer(address, address, uint256)
        external
        returns (bool);
    function unlockAmountTo(address, address, address, uint256)
        external
        returns (bool);
    function transferAmountTo(address, address, uint256)
        external
        returns (bool);
    function getLockedAmount(address, address)
        external
        view
        returns (uint256);
    function hasLockedAmount(address, address, uint256)
        external
        view
        returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILPToken is IERC20 {
    function addHandler(address) external;
    function removeHandler(address) external;
    function mint(address, uint256) external;
    function burn(uint256) external;
    function burnFrom(address, uint256) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

interface ITokenTransferProxy {
    function transferFrom(address, address, address, uint256)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../interfaces/utils/IAccessHandler.sol";
import "./Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Access Handler
 * @author Michael Larsen
 * @notice An access control contract. It restricts access to otherwise public
 *         methods, by checking for assigned roles. its meant to be extended
 *         and holds all the predefined role type for the derrived contracts.
 * @notice This is a util contract for the BookieMain app.
 */
abstract contract AccessHandler is IAccessHandler, Initializable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant BETTER_ROLE = keccak256("BETTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant LOCKBOX_ROLE = keccak256("LOCKBOX_ROLE");
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /**
     * @notice Simple constructor, just sets the admin.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Initialize and remeber the this state to avoid repeating.
     */
    function initialize()
        public
        virtual
        notInitialized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        initialized = true;
    }

    /**
     * @notice Changes the admin and revokes the roles of the current admin.
     * @param newAdmin is the addresse of the new admin.
     */
    function changeAdmin(address newAdmin)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        // We only want 1 admin
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

interface IAccessHandler {
    function changeAdmin(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

abstract contract Initializable {
    bool public initialized;

    /**
     * @notice Throws if this contract has not been initialized.
     */
    modifier isInitialized() {
        require(initialized, "NOT_INITIALIZED");
        _;
    }

    /**
     * @notice Throws if this contract has already been initialized.
     */
    modifier notInitialized() {
        require(!initialized, "ALREADY_INITIALIZED");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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