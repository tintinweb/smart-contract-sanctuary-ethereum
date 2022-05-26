/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// File: @openzeppelin\contracts\access\IAccessControl.sol

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

// File: @openzeppelin\contracts\utils\Context.sol


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

// File: @openzeppelin\contracts\utils\Strings.sol


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

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol


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

// File: @openzeppelin\contracts\utils\introspection\ERC165.sol


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

// File: @openzeppelin\contracts\access\AccessControl.sol


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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin\contracts\utils\math\SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: contracts\Oracle.sol


pragma solidity ^0.8.0;

contract Oracle {
  address owner;
  uint public rand;

  constructor() {
    owner = msg.sender;
    rand = uint(
      keccak256(
        abi.encodePacked(
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    );
  }

  function feedRandomness(uint _rand) external {
    require(
      msg.sender == owner,
      "Owner only"
    );
    
    rand = uint(
      keccak256(
        abi.encodePacked(
          _rand,
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    );
  }
}

// File: contracts\LottoGame.sol


pragma solidity ^0.8.0;



contract LottoGame is AccessControl {
  using SafeMath for uint256;

  /**
   * @dev Game record struct
   */
  struct Game {

    /**
     * @dev Is game running?
     */
    bool status;

    /**
     * @dev Number assigned to the game (sequental, based on total games)
     */
    uint256 number;

    /**
     * @dev Total value of token pot
     */
    uint256 pot;

    /**
     * @dev Number of players in the current game
     */
    uint256 playerCount;

    /**
     * @dev Number of all player tickets in the current game
     */
    uint256 ticketCount;

    /**
     * @dev Maximum number of players allowed in the game
     */
    uint256 maxPlayers;

    /**
     * @dev Maximum number of tickets per player
     */
    uint256 maxTicketsPlayer;

    /**
     * @dev Single ticket price
     */
    uint256 ticketPrice;

    /**
     * @dev Percentage (hundredth) of the pot will go to `gameFeeAddress`.
     * Zero value disables feature
     */
    uint256 feePercent;

    /**
     * @dev Owner address of the game
     * @todo Allow people to run their own games? Risky?, sure.
     */
    // address ownerAddress;

    /**
     * @dev Destination for the game fee tokens
     */
    address feeAddress;

    /**
     * @dev Game address for underlying functionality (raffle, lotto, ...)
     */
    address gameAddress;

    /**
     * @dev ERC-20 token address for game tickets
     */
    address tokenAddress;

    /**
     * @dev Address of the game winner
     */
    address winnerAddress;

    /**
     * @dev List of individual player tickets
     */
    address[] tickets;

    /**
     * @dev Cross reference for `Game` struct `players` mapping
     */
    address[] playersIndex;

    /**
     * @dev Winner result (i.e. single ticket index for raffle, or multiple numbers for lotto)
     */
    uint256[] winnerResult;

    /**
     * @dev List of unique game players
     */
    mapping (address => uint256) players;

    /**
     * @dev The game token that players will play for.
     */
    IERC20Metadata token;

    /**
     * @dev The game interface.
     * @todo Modular game interface (lotto, raffle, ...)
     */
    // IGB game;
  }

  /**
   * @dev Storage for all games (Game structs)
   */
  mapping (uint256 => Game) games;

  /**
   * @dev Increments with each `_randModulus()` call, for randomness
   */
  uint256 nonce;

  /**
   * @dev Total number of games (increments in `startGame`)
   */
  uint256 public totalGames;

  /**
   * @dev Total number of games ended (increments in `endGame`)
   */
  uint256 public totalGamesEnded;

  /**
   * @dev Randomness oracle, for selecting a winner on `endGame()`
   */
  Oracle oracle;

  /**
   * @dev Role for `startGame()`, `endGame()`
   */
  bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

  /**
   * @dev Role for `setGameToken()`, `setTicketPrice()`, `setMaxPlayers()`,
   * `setMaxTicketsPerPlayer()`, `setGameFeePercent()`, `setGameFeeAddress()`
   */
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /**
   * @dev Emitted when a game is started
   */
  event GameStarted(
    address indexed tokenAddress,
    address indexed feeAddress,
    uint256 indexed gameNumber,
    uint256 feePercent,
    uint256 ticketPrice,
    uint256 maxPlayers,
    uint256 maxTicketsPlayer
  );

  /**
   * @dev Emitted when a player buys ticket(s)
   */
  event TicketBought(
    address indexed playerAddress,
    uint256 indexed gameNumber,
    uint256 playerCount,
    uint256 ticketCount
  );

  /**
   * @dev Emitted when a game ends, and a player has won
   */
  event GameEnded(
    address indexed tokenAddress,
    address indexed winnerAddress,
    uint256 indexed gameNumber,
    uint256[] winnerResult,
    uint256 pot
  );

  /**
   * @dev Setup contract
   */
  constructor(
    address _oracleAddress
  ) {

    // Oracle of randomness
    oracle = Oracle(_oracleAddress);

    // Grant the contract deployer the default admin role: it will be able
    // to grant and revoke any roles
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
    _setupRole(CALLER_ROLE, msg.sender);
  }

  /**
   * @dev Used by `buyTicket()`
   */
  function _safeTransferFrom(
    IERC20Metadata token,
    address sender,
    address recipient,
    uint256 amount
  ) private {
    bool sent = token.transferFrom(sender, recipient, amount);
    require(sent, "Token transfer failed");
  }

  /**
   * @dev Reset all game storage states
   */
  function _resetGame(
    uint256 _gameNumber
  ) private {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );

    g.tickets = new address[](0);
    address j;
    for (uint256 i = 0; i < g.playerCount; i++) {
      j = g.playersIndex[i];
      delete g.players[j];
    }
    g.playersIndex = new address[](0);
    g.playerCount = 0;
    g.ticketCount = 0;
  }

  /**
   * @dev Game reset call for managers
   */
  function resetGame(
    uint256 _gameNumber
  ) external onlyRole(MANAGER_ROLE) {
    _resetGame(_gameNumber);
  }

  /**
   * @dev Start a new game (if none running) with given parameters
   */
  function startGame(
    address _gameTokenAddress,
    address _gameFeeAddress,
    uint256 _gameFeePercent,
    uint256 _ticketPrice,
    uint256 _maxPlayers,
    uint256 _maxTicketsPlayer
  ) external onlyRole(CALLER_ROLE) {
    require(
      _ticketPrice > 0,
      "Price greater than 0"
    );
    require(
      _maxPlayers > 1,
      "Max players greater than 1"
    );
    require(
      _maxTicketsPlayer > 0,
      "Max tickets greater than 0"
    );

    // Get game number
    uint256 _gameNumber = totalGames++;

    // Create new game record
    Game storage g = games[_gameNumber];
    g.status = true;
    g.number = _gameNumber;
    g.playerCount = 0;
    g.ticketCount = 0;
    g.maxPlayers = _maxPlayers;
    g.maxTicketsPlayer = _maxTicketsPlayer;
    g.ticketPrice = _ticketPrice;
    g.feePercent = _gameFeePercent;
    g.feeAddress = _gameFeeAddress;
    g.tokenAddress = _gameTokenAddress;
    g.token = IERC20Metadata(_gameTokenAddress);

    // Fire `GameStarted` event
    emit GameStarted(
      g.tokenAddress,
      g.feeAddress,
      g.number,
      g.feePercent,
      g.ticketPrice,
      g.maxPlayers,
      g.maxTicketsPlayer
    );
  }

  /**
   * @dev Allow a player to buy Nth tickets in `_gameNumber`, at predefined `g.ticketPrice` of `g.token`
   */
  function buyTicket(
    uint256 _gameNumber,
    uint256 _numberOfTickets
  ) external {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers >= 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );
    require(
      _numberOfTickets > 0,
      "Buy at least 1 ticket"
    );

    // Ensure player has enough tokens to play
    uint256 _totalCost = g.ticketPrice.mul(_numberOfTickets);
    require(
      g.token.allowance(msg.sender, address(this)) >= _totalCost,
      "Insufficent game token allowance"
    );

    // Marker for new player logic
    bool _isNewPlayer = false;

    // Current number of tickets that this player has
    uint256 _playerTicketCount = g.players[msg.sender];

    // First time player has entered the game
    if (_playerTicketCount == 0) {
      if (g.playerCount == g.maxPlayers) {
        revert("Too many players in game");
      }
      _isNewPlayer = true;
    }
    
    // Check the new player ticket count
    uint256 _playerTicketNextCount = _playerTicketCount + _numberOfTickets;
    require(
      _playerTicketNextCount <= g.maxTicketsPlayer,
      "Exceeds max player tickets, try lower value"
    );

    // Transfer `_totalCost` of `gameToken` from player, this this contract
    // g.token.transferFrom(msg.sender, address(this), _totalCost);
    _safeTransferFrom(
      g.token,
      msg.sender,
      address(this),
      _totalCost
    );

    // Add total ticket cost to pot
    g.pot += _totalCost;

    // If a new player (currently has no tickets)
    if (_isNewPlayer) {

      // Increase game total player count
      g.playerCount++;

      // Used for iteration on game player mapping, when resetting game
      g.playersIndex.push(msg.sender);
    }

    // Update number of tickets purchased by player
    g.players[msg.sender] = _playerTicketNextCount;

    // Add each of the tickets to an array, a random index of this array 
    // will be selected as winner.
    uint256 _i;
    while (_i != _numberOfTickets) {
      g.tickets.push(msg.sender);
      _i++;
    }

    // Increase total number of game player tickets
    g.ticketCount += _numberOfTickets;

    // Fire `TicketBought` event
    emit TicketBought(
      msg.sender,
      g.number,
      g.playerCount,
      g.ticketCount
    );
  }

  /**
   * @dev Ends the current game, and picks a winner
   */
  function endGame(
    uint256 _gameNumber
  ) external onlyRole(CALLER_ROLE) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );

    uint256 _pot = g.pot;
    uint256 _balance = g.token.balanceOf(address(this));
    require(
      g.pot <= _balance,
      "Not enough of game token in reserve"
    );

    // Close game
    g.status = false;

    // Pick winner
    uint256 _rand = _randModulus(100);
    uint256 _total = g.ticketCount - 1;
    uint256 _index = (_total == 0) ? 0 : (_rand % _total);

    // Store winner result index
    g.winnerResult.push(_index);

    // Store winner address index
    g.winnerAddress = g.tickets[_index];

    // Send fees (if applicable)
    if (g.feePercent > 0) {
      uint256 _feeTotal = _pot.div(100).mul(g.feePercent);

      // Transfer game fee from pot
      if (_feeTotal > 0) {
        g.token.transfer(g.feeAddress, _feeTotal);

        // Deduct fee from pot value
        _pot -= _feeTotal;
      }
    }

    // Send pot to winner
    g.token.transfer(g.winnerAddress, _pot);

    // @todo Trim superfluous game data for gas saving
    totalGamesEnded++;

    // Fire `GameEnded` event
    emit GameEnded(
      g.tokenAddress,
      g.winnerAddress,
      g.number,
      g.winnerResult,
      _pot
    );
  }

  /**
   * @dev Return an array of useful game states
   */
  function getGameState(
    uint256 _gameNumber
  ) external view
  returns (
    bool status,
    uint256 pot,
    uint256 playerCount,
    uint256 ticketCount,
    uint256 maxPlayers,
    uint256 maxTicketsPlayer,
    uint256 ticketPrice,
    uint256 feePercent,
    address feeAddress,
    address tokenAddress,
    address winnerAddress,
    uint256[] memory winnerResult
  ) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );

    return (
      g.status,
      g.pot,
      g.playerCount,
      g.ticketCount,
      g.maxPlayers,
      g.maxTicketsPlayer,
      g.ticketPrice,
      g.feePercent,
      g.feeAddress,
      g.tokenAddress,
      g.winnerAddress,
      g.winnerResult
    );
  }

  /**
   * @dev Return `totalGamesEnded`, the total number of completed games
   */
  // function getTotalGameCount() external view returns(uint256) {
  //   return totalGamesEnded;
  // }

  /**
   * @dev Define new ERC20 `gameToken` with provided `_token`
   */
  function setGameToken(
    uint256 _gameNumber,
    address _token
  ) external onlyRole(MANAGER_ROLE) returns(bool sufficient) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );

    g.tokenAddress = _token;
    g.token = IERC20Metadata(_token);

    return true;
  }

  /**
   * @dev Define new game ticket price
   */
  function setTicketPrice(
    uint256 _gameNumber,
    uint256 _price
  ) external onlyRole(MANAGER_ROLE) returns(bool sufficient) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );
    require(
      _price > 0,
      "Price greater than 0"
    );

    g.ticketPrice = _price;

    return true;
  }

  /**
   * @dev Defines maximum number of unique game players
   */
  function setMaxPlayers(
    uint256 _gameNumber,
    uint256 _max
  ) external onlyRole(MANAGER_ROLE) returns(bool sufficient) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );
    require(
      _max > 1,
      "Max players greater than 1"
    );

    g.maxPlayers = _max;

    return true;
  }

  /**
   * @dev Defines maximum number of tickets, per unique game player
   */
  function setMaxTicketsPerPlayer(
    uint256 _gameNumber,
    uint256 _max
  ) external onlyRole(MANAGER_ROLE) returns(bool sufficient) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );
    require(
      _max > 0,
      "Max tickets greater than 0"
    );

    g.maxTicketsPlayer = _max;

    return true;
  }

  /**
   * @dev Defines the game fee percentage (can only be lower than original value)
   */
  function setGameFeePercent(
    uint256 _gameNumber,
    uint256 _percent
  ) external onlyRole(MANAGER_ROLE) returns(bool sufficient) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );
    require(
      _percent >= 0,
      "Zero or higher"
    );
    require(
      _percent < g.feePercent,
      "Can only be decreased after game start"
    );

    g.feePercent = _percent;

    return true;
  }

  /**
   * @dev Defines an address for the game fee
   */
  function setGameFeeAddress(
    uint256 _gameNumber,
    address _address
  ) external onlyRole(MANAGER_ROLE) returns(bool sufficient) {
    Game storage g = games[_gameNumber];

    require(
      g.maxPlayers > 0,
      "Invalid game"
    );
    require(
      g.status == true,
      "Game already ended"
    );

    g.feeAddress = _address;

    return true;
  }

  /**
   * @dev Returns a random seed
   */
  function _randModulus(
    uint256 mod
  ) internal returns(uint256) {
    uint256 _rand = uint256(
      keccak256(
        abi.encodePacked(
          nonce,
          oracle.rand(),
          block.timestamp,
          block.difficulty,
          msg.sender
        )
      )
    ) % mod;
    nonce++;

    return _rand;
  }
}