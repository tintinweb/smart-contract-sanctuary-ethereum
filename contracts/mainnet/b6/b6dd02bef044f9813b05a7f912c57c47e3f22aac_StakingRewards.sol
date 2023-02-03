pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
 */
abstract contract AccessControlUpgradeSafe is Initializable, ContextUpgradeSafe {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity ^0.6.0;

import "../access/AccessControl.sol";
import "../GSN/Context.sol";
import "../token/ERC20/ERC20.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Pausable.sol";
import "../Initializable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC20PresetMinterPauserUpgradeSafe is Initializable, ContextUpgradeSafe, AccessControlUpgradeSafe, ERC20BurnableUpgradeSafe, ERC20PausableUpgradeSafe {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */

    function initialize(string memory name, string memory symbol) public {
        __ERC20PresetMinterPauser_init(name, symbol);
    }

    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
    }

    function __ERC20PresetMinterPauser_init_unchained(string memory name, string memory symbol) internal initializer {


        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

    }


    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20UpgradeSafe, ERC20PausableUpgradeSafe) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";
import "../../Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeSafe is Initializable, ContextUpgradeSafe, ERC20UpgradeSafe {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {


    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";
import "../../Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeSafe is Initializable, ERC20UpgradeSafe, PausableUpgradeSafe {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {


    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
     * @dev Returns the number of values on the set. O(1).
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
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "../token/ERC20/ERC20.sol";
import "./IERC20Permit.sol";
import "../cryptography/ECDSA.sol";
import "../utils/Counters.sol";
import "./EIP712.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) internal EIP712(name, "1") {
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 */
library EnumerableSet {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
     * @dev Returns the number of values on the set. O(1).
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
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
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly

/*
  Vendored from @opengsn/[email protected]
  Reason:
   * @opengsn/gsn is deprecated and does not compile for node 16. Replacement package
   * has incompatable changes.
  Alterations:
   * change solidity version from 0.6.2 -> 0.6.12 to match our contracts
*/

pragma solidity 0.6.12;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
  /*
   * Forwarder singleton we accept calls from
   */
  address public trustedForwarder;

  function isTrustedForwarder(address forwarder) public view override returns (bool) {
    return forwarder == trustedForwarder;
  }

  /**
   * return the sender of this call.
   * if the call came through our trusted forwarder, return the original sender.
   * otherwise, return `msg.sender`.
   * should be used in the contract anywhere instead of msg.sender
   */
  function _msgSender() internal view virtual override returns (address payable ret) {
    if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
      // At this point we know that the sender is a trusted forwarder,
      // so we trust that the last bytes of msg.data are the verified sender address.
      // extract sender address from the end of msg.data
      assembly {
        ret := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return msg.sender;
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
  function _msgData() internal view virtual override returns (bytes memory ret) {
    if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
      // At this point we know that the sender is a trusted forwarder,
      // we copy the msg.data , except the last 20 bytes (and update the total length)
      assembly {
        let ptr := mload(0x40)
        // copy only size-20 bytes
        let size := sub(calldatasize(), 20)
        // structure RLP data as <offset> <length> <bytes>
        mstore(ptr, 0x20)
        mstore(add(ptr, 32), size)
        calldatacopy(add(ptr, 64), 0, size)
        return(ptr, add(size, 64))
      }
    } else {
      return msg.data;
    }
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable
/*
  Vendored from @openzeppelin/[email protected]
  Alterations:
   * Make supportsInterface virtual so it can be overriden by inheriting contracts
*/
pragma solidity ^0.6.0;

import "../interfaces/openzeppelin/IERC165.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165UpgradeSafe is Initializable, IERC165 {
  /*
   * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
   */
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  /**
   * @dev Mapping of interface ids to whether or not it's supported.
   */
  mapping(bytes4 => bool) private _supportedInterfaces;

  function __ERC165_init() internal initializer {
    __ERC165_init_unchained();
  }

  function __ERC165_init_unchained() internal initializer {
    // Derived contracts need only register support for their own interfaces,
    // we register support for ERC165 itself here
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   *
   * Time complexity O(1), guaranteed to always use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev Registers the contract as an implementer of the interface defined by
   * `interfaceId`. Support of the actual ERC165 interface is automatic and
   * registering its interface id is not required.
   *
   * See {IERC165-supportsInterface}.
   *
   * Requirements:
   *
   * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
   */
  function _registerInterface(bytes4 interfaceId) internal virtual {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// solhint-disable
/*
  Vendored from @openzeppelin/[email protected]
  Alterations:
   * Use vendored ERC165 with virtual supportsInterface
*/

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "../interfaces/openzeppelin/IERC721.sol";
import "../interfaces/openzeppelin/IERC721Metadata.sol";
import "../interfaces/openzeppelin/IERC721Enumerable.sol";
import "../interfaces/openzeppelin/IERC721Receiver.sol";
import "./ERC165.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721UpgradeSafe is
  Initializable,
  ContextUpgradeSafe,
  ERC165UpgradeSafe,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using SafeMath for uint256;
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;
  using Strings for uint256;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from holder address to their (enumerable) set of owned tokens
  mapping(address => EnumerableSet.UintSet) private _holderTokens;

  // Enumerable mapping from token ids to their owners
  EnumerableMap.UintToAddressMap private _tokenOwners;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  // Base URI
  string private _baseURI;

  /*
   *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
   *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
   *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
   *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
   *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
   *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
   *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
   *
   *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
   *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
   */
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

  /*
   *     bytes4(keccak256('name()')) == 0x06fdde03
   *     bytes4(keccak256('symbol()')) == 0x95d89b41
   *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
   *
   *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
   */
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  /*
   *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
   *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
   *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
   *
   *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
   */
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

  function __ERC721_init(string memory name, string memory symbol) internal initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained(name, symbol);
  }

  function __ERC721_init_unchained(string memory name, string memory symbol) internal initializer {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");

    return _holderTokens[owner].length();
  }

  /**
   * @dev Gets the owner of the specified token ID.
   * @param tokenId uint256 ID of the token to query the owner of
   * @return address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
  }

  /**
   * @dev Gets the token name.
   * @return string representing the token name
   */
  function name() public view override returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the token symbol.
   * @return string representing the token symbol
   */
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the URI for a given token ID. May return an empty string.
   *
   * If a base URI is set (via {_setBaseURI}), it is added as a prefix to the
   * token's own URI (via {_setTokenURI}).
   *
   * If there is a base URI but no token URI, the token's ID will be used as
   * its URI when appending it to the base URI. This pattern for autogenerated
   * token URIs can lead to large gas savings.
   *
   * .Examples
   * |===
   * |`_setBaseURI()` |`_setTokenURI()` |`tokenURI()`
   * | ""
   * | ""
   * | ""
   * | ""
   * | "token.uri/123"
   * | "token.uri/123"
   * | "token.uri/"
   * | "123"
   * | "token.uri/123"
   * | "token.uri/"
   * | ""
   * | "token.uri/<tokenId>"
   * |===
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];

    // If there is no base URI, return the token URI.
    if (bytes(_baseURI).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(_baseURI, _tokenURI));
    }
    // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(_baseURI, tokenId.toString()));
  }

  /**
   * @dev Returns the base URI set via {_setBaseURI}. This will be
   * automatically added as a prefix in {tokenURI} to each token's URI, or
   * to the token ID if no specific URI is set for that token ID.
   */
  function baseURI() public view returns (string memory) {
    return _baseURI;
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner.
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) public view override returns (uint256) {
    return _holderTokens[owner].at(index);
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract.
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view override returns (uint256) {
    // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
    return _tokenOwners.length();
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens.
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    (uint256 tokenId, ) = _tokenOwners.at(index);
    return tokenId;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf.
   * @param operator operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner.
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address.
   * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   * Requires the msg.sender to be the owner, approved, or operator.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the _msgSender() to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether the specified token exists.
   * @param tokenId uint256 ID of the token to query the existence of
   * @return bool whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _tokenOwners.contains(tokenId);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID.
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   * is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Internal function to mint a new token.
   * Reverts if the given token ID already exists.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Internal function to burn a specific token.
   * Reverts if the token does not exist.
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }

    _holderTokens[owner].remove(tokenId);

    _tokenOwners.remove(tokenId);

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to transfer ownership of a given token ID to another address.
   * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _transfer(address from, address to, uint256 tokenId) internal virtual {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _holderTokens[from].remove(tokenId);
    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Internal function to set the token URI for a given token.
   *
   * Reverts if the token ID does not exist.
   *
   * TIP: If all token IDs share a prefix (for example, if your URIs look like
   * `https://api.myproject.com/token/<id>`), use {_setBaseURI} to store
   * it and save gas.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function _setBaseURI(string memory baseURI_) internal virtual {
    _baseURI = baseURI_;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (!to.isContract()) {
      return true;
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = to.call(
      abi.encodeWithSelector(
        IERC721Receiver(to).onERC721Received.selector,
        _msgSender(),
        from,
        tokenId,
        _data
      )
    );
    if (!success) {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert("ERC721: transfer to non ERC721Receiver implementer");
      }
    } else {
      bytes4 retval = abi.decode(returndata, (bytes4));
      return (retval == _ERC721_RECEIVED);
    }
  }

  function _approve(address to, uint256 tokenId) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - when `from` is zero, `tokenId` will be minted for `to`.
   * - when `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

  uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
// solhint-disable
/*
  Vendored from @openzeppelin/[email protected]
  Alterations:
   * Use vendored ERC721, which inherits from vendored ERC165 with virtual supportsInterface
*/

pragma solidity ^0.6.0;

import "./ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeSafe is
  Initializable,
  ERC721UpgradeSafe,
  PausableUpgradeSafe
{
  function __ERC721Pausable_init() internal initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();
  }

  function __ERC721Pausable_init_unchained() internal initializer {}

  /**
   * @dev See {ERC721-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    require(!paused(), "ERC721Pausable: token transfer while paused");
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// solhint-disable
/*
  This is copied from OZ preset: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.0.0/contracts/presets/ERC721PresetMinterPauserAutoId.sol
  Alterations:
   * Make the counter public, so that we can use it in our custom mint function
   * Removed ERC721Burnable parent contract, but added our own custom burn function.
   * Removed original "mint" function, because we have a custom one.
   * Removed default initialization functions, because they set msg.sender as the owner, which
     we do not want, because we use a deployer account, which is separate from the protocol owner.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Counters.sol";
import "./ERC721Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC721PresetMinterPauserAutoIdUpgradeSafe is
  Initializable,
  ContextUpgradeSafe,
  AccessControlUpgradeSafe,
  ERC721PausableUpgradeSafe
{
  using Counters for Counters.Counter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  Counters.Counter public _tokenIdTracker;

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC721PresetMinterPauserAutoId: must have pauser role to pause"
    );
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC721PresetMinterPauserAutoId: must have pauser role to unpause"
    );
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721PausableUpgradeSafe) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
// solhint-disable
// Imported from https://github.com/UMAprotocol/protocol/blob/4d1c8cc47a4df5e79f978cb05647a7432e111a3d/packages/core/contracts/common/implementation/FixedPoint.sol
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
  // For unsigned values:
  //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
  uint256 private constant FP_SCALING_FACTOR = 10 ** 18;

  // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
  struct Unsigned {
    uint256 rawValue;
  }

  /**
   * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5**18`.
   * @param a uint to convert into a FixedPoint.
   * @return the converted FixedPoint.
   */
  function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
    return Unsigned(a.mul(FP_SCALING_FACTOR));
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if equal, or False.
   */
  function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if equal, or False.
   */
  function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue == b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue > fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue >= fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue < fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a < b`, or False.
   */
  function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
    return a.rawValue <= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
    return a.rawValue <= fromUnscaledUint(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
    return fromUnscaledUint(a).rawValue <= b.rawValue;
  }

  /**
   * @notice The minimum of `a` and `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the minimum of `a` and `b`.
   */
  function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return a.rawValue < b.rawValue ? a : b;
  }

  /**
   * @notice The maximum of `a` and `b`.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the maximum of `a` and `b`.
   */
  function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return a.rawValue > b.rawValue ? a : b;
  }

  /**
   * @notice Adds two `Unsigned`s, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the sum of `a` and `b`.
   */
  function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.add(b.rawValue));
  }

  /**
   * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return the sum of `a` and `b`.
   */
  function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return add(a, fromUnscaledUint(b));
  }

  /**
   * @notice Subtracts two `Unsigned`s, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the difference of `a` and `b`.
   */
  function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.sub(b.rawValue));
  }

  /**
   * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return the difference of `a` and `b`.
   */
  function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return sub(a, fromUnscaledUint(b));
  }

  /**
   * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
   * @param a a uint256.
   * @param b a FixedPoint.
   * @return the difference of `a` and `b`.
   */
  function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return sub(fromUnscaledUint(a), b);
  }

  /**
   * @notice Multiplies two `Unsigned`s, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the product of `a` and `b`.
   */
  function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as a uint256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FP_SCALING_FACTOR != 0.
    return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
  }

  /**
   * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.
   * @param b a uint256.
   * @return the product of `a` and `b`.
   */
  function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.mul(b));
  }

  /**
   * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the product of `a` and `b`.
   */
  function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    uint256 mulRaw = a.rawValue.mul(b.rawValue);
    uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
    uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
    if (mod != 0) {
      return Unsigned(mulFloor.add(1));
    } else {
      return Unsigned(mulFloor);
    }
  }

  /**
   * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.
   * @param b a FixedPoint.
   * @return the product of `a` and `b`.
   */
  function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    // Since b is an int, there is no risk of truncation and we can just mul it normally
    return Unsigned(a.rawValue.mul(b));
  }

  /**
   * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as a uint256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
  }

  /**
   * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b a uint256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    return Unsigned(a.rawValue.div(b));
  }

  /**
   * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a uint256 numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
    return div(fromUnscaledUint(a), b);
  }

  /**
   * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
    uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
    uint256 divFloor = aScaled.div(b.rawValue);
    uint256 mod = aScaled.mod(b.rawValue);
    if (mod != 0) {
      return Unsigned(divFloor.add(1));
    } else {
      return Unsigned(divFloor);
    }
  }

  /**
   * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b a uint256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
    // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
    // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
    // This creates the possibility of overflow if b is very large.
    return divCeil(a, fromUnscaledUint(b));
  }

  /**
   * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
   * @dev This will "floor" the result.
   * @param a a FixedPoint numerator.
   * @param b a uint256 denominator.
   * @return output is `a` to the power of `b`.
   */
  function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
    output = fromUnscaledUint(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }

  // ------------------------------------------------- SIGNED -------------------------------------------------------------
  // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
  // For signed values:
  //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
  int256 private constant SFP_SCALING_FACTOR = 10 ** 18;

  struct Signed {
    int256 rawValue;
  }

  function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
    require(a.rawValue >= 0, "Negative value provided");
    return Unsigned(uint256(a.rawValue));
  }

  function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
    require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
    return Signed(int256(a.rawValue));
  }

  /**
   * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5**18`.
   * @param a int to convert into a FixedPoint.Signed.
   * @return the converted FixedPoint.Signed.
   */
  function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
    return Signed(a.mul(SFP_SCALING_FACTOR));
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a int256.
   * @return True if equal, or False.
   */
  function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue == fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if equal, or False.
   */
  function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue == b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue > fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a > b`, or False.
   */
  function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue > b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue >= fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is greater than or equal to `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a >= b`, or False.
   */
  function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue >= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a < b`, or False.
   */
  function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue < fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a < b`, or False.
   */
  function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue < b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
    return a.rawValue <= b.rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
    return a.rawValue <= fromUnscaledInt(b).rawValue;
  }

  /**
   * @notice Whether `a` is less than or equal to `b`.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return True if `a <= b`, or False.
   */
  function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
    return fromUnscaledInt(a).rawValue <= b.rawValue;
  }

  /**
   * @notice The minimum of `a` and `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the minimum of `a` and `b`.
   */
  function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return a.rawValue < b.rawValue ? a : b;
  }

  /**
   * @notice The maximum of `a` and `b`.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the maximum of `a` and `b`.
   */
  function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return a.rawValue > b.rawValue ? a : b;
  }

  /**
   * @notice Adds two `Signed`s, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the sum of `a` and `b`.
   */
  function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.add(b.rawValue));
  }

  /**
   * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return the sum of `a` and `b`.
   */
  function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return add(a, fromUnscaledInt(b));
  }

  /**
   * @notice Subtracts two `Signed`s, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the difference of `a` and `b`.
   */
  function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.sub(b.rawValue));
  }

  /**
   * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return the difference of `a` and `b`.
   */
  function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return sub(a, fromUnscaledInt(b));
  }

  /**
   * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
   * @param a an int256.
   * @param b a FixedPoint.Signed.
   * @return the difference of `a` and `b`.
   */
  function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
    return sub(fromUnscaledInt(a), b);
  }

  /**
   * @notice Multiplies two `Signed`s, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the product of `a` and `b`.
   */
  function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as an int256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
    return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
  }

  /**
   * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
   * @dev This will "floor" the product.
   * @param a a FixedPoint.Signed.
   * @param b an int256.
   * @return the product of `a` and `b`.
   */
  function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.mul(b));
  }

  /**
   * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the product of `a` and `b`.
   */
  function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    int256 mulRaw = a.rawValue.mul(b.rawValue);
    int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
    // Manual mod because SignedSafeMath doesn't support it.
    int256 mod = mulRaw % SFP_SCALING_FACTOR;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(mulTowardsZero.add(valueToAdd));
    } else {
      return Signed(mulTowardsZero);
    }
  }

  /**
   * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
   * @param a a FixedPoint.Signed.
   * @param b a FixedPoint.Signed.
   * @return the product of `a` and `b`.
   */
  function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
    // Since b is an int, there is no risk of truncation and we can just mul it normally
    return Signed(a.rawValue.mul(b));
  }

  /**
   * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as an int256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
  }

  /**
   * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a a FixedPoint numerator.
   * @param b an int256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
    return Signed(a.rawValue.div(b));
  }

  /**
   * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
   * @dev This will "floor" the quotient.
   * @param a an int256 numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
    return div(fromUnscaledInt(a), b);
  }

  /**
   * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b a FixedPoint denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
    int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
    int256 divTowardsZero = aScaled.div(b.rawValue);
    // Manual mod because SignedSafeMath doesn't support it.
    int256 mod = aScaled % b.rawValue;
    if (mod != 0) {
      bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
      int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
      return Signed(divTowardsZero.add(valueToAdd));
    } else {
      return Signed(divTowardsZero);
    }
  }

  /**
   * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
   * @param a a FixedPoint numerator.
   * @param b an int256 denominator.
   * @return the quotient of `a` divided by `b`.
   */
  function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
    // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
    // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
    // This creates the possibility of overflow if b is very large.
    return divAwayFromZero(a, fromUnscaledInt(b));
  }

  /**
   * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
   * @dev This will "floor" the result.
   * @param a a FixedPoint.Signed.
   * @param b a uint256 (negative exponents are not allowed).
   * @return output is `a` to the power of `b`.
   */
  function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
    output = fromUnscaledInt(1);
    for (uint256 i = 0; i < b; i = i.add(1)) {
      output = mul(output, a);
    }
  }
}

// SPDX-License-Identifier:MIT

/*
  Vendored from @opengsn/[email protected]
  Reason:
   * @opengsn/gsn is deprecated and does not compile for node 16. Replacement package
   * has incompatable changes.
  Alterations:
   * change solidity version from 0.6.2 -> 0.6.12 to match our contracts
*/

pragma solidity 0.6.12;

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
  function isTrustedForwarder(address forwarder) public view virtual returns (bool);

  /**
   * return the sender of this call.
   * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
   * of the msg.data.
   * otherwise, return `msg.sender`
   * should be used in the contract anywhere instead of msg.sender
   */
  function _msgSender() internal view virtual returns (address payable);

  /**
   * return the msg.data of this call.
   * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
   * of the msg.data - so this method will strip those 20 bytes off.
   * otherwise, return `msg.data`
   * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
   * signing or hashing the
   */
  function _msgData() internal view virtual returns (bytes memory);

  function versionRecipient() external view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {ITranchedPool} from "./ITranchedPool.sol";

interface IBackerRewards {
  struct BackerRewardsTokenInfo {
    uint256 rewardsClaimed; // gfi claimed
    uint256 accRewardsPerPrincipalDollarAtMint; // Pool's accRewardsPerPrincipalDollar at PoolToken mint()
  }

  struct BackerRewardsInfo {
    uint256 accRewardsPerPrincipalDollar; // accumulator gfi per interest dollar
  }

  /// @notice Staking rewards parameters relevant to a TranchedPool
  struct StakingRewardsPoolInfo {
    // @notice the value `StakingRewards.accumulatedRewardsPerToken()` at the last checkpoint
    uint256 accumulatedRewardsPerTokenAtLastCheckpoint;
    // @notice last time the rewards info was updated
    //
    // we need this in order to know how much to pro rate rewards after the term is over.
    uint256 lastUpdateTime;
    // @notice staking rewards parameters for each slice of the tranched pool
    StakingRewardsSliceInfo[] slicesInfo;
  }

  /// @notice Staking rewards paramters relevant to a TranchedPool slice
  struct StakingRewardsSliceInfo {
    // @notice fidu share price when the slice is first drawn down
    //
    // we need to save this to calculate what an equivalent position in
    // the senior pool would be at the time the slice is downdown
    uint256 fiduSharePriceAtDrawdown;
    // @notice the amount of principal deployed at the last checkpoint
    //
    // we use this to calculate the amount of principal that should
    // acctually accrue rewards during between the last checkpoint and
    // and subsequent updates
    uint256 principalDeployedAtLastCheckpoint;
    // @notice the value of StakingRewards.accumulatedRewardsPerToken() at time of drawdown
    //
    // we need to keep track of this to use this as a base value to accumulate rewards
    // for tokens. If the token has never claimed staking rewards, we use this value
    // and the current staking rewards accumulator
    uint256 accumulatedRewardsPerTokenAtDrawdown;
    // @notice amount of rewards per token accumulated over the lifetime of the slice that a backer
    //          can claim
    uint256 accumulatedRewardsPerTokenAtLastCheckpoint;
    // @notice the amount of rewards per token accumulated over the lifetime of the slice
    //
    // this value is "unrealized" because backers will be unable to claim against this value.
    // we keep this value so that we can always accumulate rewards for the amount of capital
    // deployed at any point in time, but not allow backers to withdraw them until a payment
    // is made. For example: we want to accumulate rewards when a backer does a drawdown. but
    // a backer shouldn't be allowed to claim rewards until a payment is made.
    //
    // this value is scaled depending on the current proportion of capital currently deployed
    // in the slice. For example, if the staking rewards contract accrued 10 rewards per token
    // between the current checkpoint and a new update, and only 20% of the capital was deployed
    // during that period, we would accumulate 2 (10 * 20%) rewards.
    uint256 unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint;
  }

  /// @notice Staking rewards parameters relevant to a PoolToken
  struct StakingRewardsTokenInfo {
    // @notice the amount of rewards accumulated the last time a token's rewards were withdrawn
    uint256 accumulatedRewardsPerTokenAtLastWithdraw;
  }

  /// @notice total amount of GFI rewards available, times 1e18
  function totalRewards() external view returns (uint256);

  /// @notice interest $ eligible for gfi rewards, times 1e18
  function maxInterestDollarsEligible() external view returns (uint256);

  /// @notice counter of total interest repayments, times 1e6
  function totalInterestReceived() external view returns (uint256);

  /// @notice totalRewards/totalGFISupply * 100, times 1e18
  function totalRewardPercentOfTotalGFI() external view returns (uint256);

  /// @notice Get backer rewards metadata for a pool token
  function getTokenInfo(uint256 poolTokenId) external view returns (BackerRewardsTokenInfo memory);

  /// @notice Get backer staking rewards metadata for a pool token
  function getStakingRewardsTokenInfo(
    uint256 poolTokenId
  ) external view returns (StakingRewardsTokenInfo memory);

  /// @notice Get backer staking rewards for a pool
  function getBackerStakingRewardsPoolInfo(
    ITranchedPool pool
  ) external view returns (StakingRewardsPoolInfo memory);

  /// @notice Calculates the accRewardsPerPrincipalDollar for a given pool,
  ///   when a interest payment is received by the protocol
  /// @param _interestPaymentAmount Atomic usdc amount of the interest payment
  function allocateRewards(uint256 _interestPaymentAmount) external;

  /// @notice callback for TranchedPools when they drawdown
  /// @param sliceIndex index of the tranched pool slice
  /// @dev initializes rewards info for the calling TranchedPool if it's the first
  ///  drawdown for the given slice
  function onTranchedPoolDrawdown(uint256 sliceIndex) external;

  /// @notice When a pool token is minted for multiple drawdowns,
  ///   set accRewardsPerPrincipalDollarAtMint to the current accRewardsPerPrincipalDollar price
  /// @param poolAddress Address of the pool associated with the pool token
  /// @param tokenId Pool token id
  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(
    address poolAddress,
    uint256 tokenId
  ) external;

  /// @notice PoolToken request to withdraw all allocated rewards
  /// @param tokenId Pool token id
  /// @return amount of rewards withdrawn
  function withdraw(uint256 tokenId) external returns (uint256);

  /**
   * @notice Set BackerRewards and BackerStakingRewards metadata for tokens created by a pool token split.
   * @param originalBackerRewardsTokenInfo backer rewards info for the pool token that was split
   * @param originalStakingRewardsTokenInfo backer staking rewards info for the pool token that was split
   * @param newTokenId id of one of the tokens in the split
   * @param newRewardsClaimed rewardsClaimed value for the new token.
   */
  function setBackerAndStakingRewardsTokenInfoOnSplit(
    BackerRewardsTokenInfo memory originalBackerRewardsTokenInfo,
    StakingRewardsTokenInfo memory originalStakingRewardsTokenInfo,
    uint256 newTokenId,
    uint256 newRewardsClaimed
  ) external;

  /**
   * @notice Calculate the gross available gfi rewards for a PoolToken
   * @param tokenId Pool token id
   * @return The amount of GFI claimable
   */
  function poolTokenClaimableRewards(uint256 tokenId) external view returns (uint256);

  /// @notice Clear all BackerRewards and StakingRewards associated data for `tokenId`
  function clearTokenInfo(uint256 tokenId) external;
}

// SPDX-Licence-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IBorrower {
  function initialize(address owner, address _config) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./openzeppelin/IERC721.sol";

import "../interfaces/IERC20withDec.sol";

interface ICommunityRewards is IERC721 {
  function rewardsToken() external view returns (IERC20withDec);

  function claimableRewards(uint256 tokenId) external view returns (uint256 rewards);

  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) external pure returns (uint256 rewards);

  function grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) external returns (uint256 tokenId);

  function loadRewards(uint256 rewards) external;

  function revokeGrant(uint256 tokenId) external;

  function getReward(uint256 tokenId) external;

  event RewardAdded(uint256 reward);
  event Granted(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  );
  event GrantRevoked(uint256 indexed tokenId, uint256 totalUnvested);
  event RewardPaid(address indexed user, uint256 indexed tokenId, uint256 reward);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ICreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ICurveLP {
  function coins(uint256) external view returns (address);

  function token() external view returns (address);

  function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);

  function lp_price() external view returns (uint256);

  function add_liquidity(
    uint256[2] calldata amounts,
    uint256 min_mint_amount,
    bool use_eth,
    address receiver
  ) external returns (uint256);

  function remove_liquidity(
    uint256 _amount,
    uint256[2] calldata min_amounts
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 token_amount,
    uint256 i,
    uint256 min_amount
  ) external returns (uint256);

  function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

  function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);

  function balances(uint256 arg0) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20withDec.sol";

interface ICUSDCContract is IERC20withDec {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external returns (uint256);

  function getAccountSnapshot(
    address account
  ) external view returns (uint256, uint256, uint256, uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// Copied from: https://eips.ethereum.org/EIPS/eip-173

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
  /// @dev This emits when ownership of a contract changes.
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @notice Get the address of the owner
  /// @return The address of the owner.
  function owner() external view returns (address);

  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/*
Only addition is the `decimals` function, which we need, and which both our Fidu and USDC use, along with most ERC20's.
*/

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20 {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IERC2981 {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

/// @notice Common events that can be emmitted by multiple contracts
interface IEvents {
  /// @notice Emitted when a safety check fails
  event SafetyCheckTriggered();
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20withDec.sol";

interface IFidu is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;

  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGFI is IERC20 {
  function mint(address account, uint256 amount) external;

  function setCap(uint256 _cap) external;

  function cap() external returns (uint256);

  event CapUpdated(address indexed who, uint256 cap);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

abstract contract IGo {
  uint256 public constant ID_TYPE_0 = 0;
  uint256 public constant ID_TYPE_1 = 1;
  uint256 public constant ID_TYPE_2 = 2;
  uint256 public constant ID_TYPE_3 = 3;
  uint256 public constant ID_TYPE_4 = 4;
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  /// @notice Returns the address of the UniqueIdentity contract.
  function uniqueIdentity() external virtual returns (address);

  function go(address account) public view virtual returns (bool);

  function goOnlyIdTypes(
    address account,
    uint256[] calldata onlyIdTypes
  ) public view virtual returns (bool);

  /**
   * @notice Returns whether the provided account is go-listed for use of the SeniorPool on the Goldfinch protocol.
   * @param account The account whose go status to obtain
   * @return true if `account` is go listed
   */
  function goSeniorPool(address account) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IGoldfinchConfig {
  function getNumber(uint256 index) external returns (uint256);

  function getAddress(uint256 index) external returns (address);

  function setAddress(uint256 index, address newAddress) external returns (address);

  function setNumber(uint256 index, uint256 newNumber) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IGoldfinchFactory {
  function createCreditLine() external returns (address);

  function createBorrower(address owner) external returns (address);

  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function createMigratedPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/interfaces/IMerkleDistributor.sol.
pragma solidity >=0.6.12;

/// @notice Enables the transfer of GFI rewards (referred to as a "grant"), if the grant details exist in this
/// contract's Merkle root.
interface IMerkleDirectDistributor {
  /// @notice Returns the address of the GFI contract that is the token distributed as rewards by
  ///   this contract.
  function gfi() external view returns (address);

  /// @notice Returns the merkle root of the merkle tree containing grant details available to accept.
  function merkleRoot() external view returns (bytes32);

  /// @notice Returns true if the index has been marked accepted.
  function isGrantAccepted(uint256 index) external view returns (bool);

  /// @notice Causes the sender to accept the grant consisting of the given details. Reverts if
  /// the inputs (which includes who the sender is) are invalid.
  function acceptGrant(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external;

  /// @notice This event is triggered whenever a call to #acceptGrant succeeds.
  event GrantAccepted(uint256 indexed index, address indexed account, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/interfaces/IMerkleDistributor.sol.
pragma solidity >=0.6.12;

/// @notice Enables the granting of a CommunityRewards grant, if the grant details exist in this
/// contract's Merkle root.
interface IMerkleDistributor {
  /// @notice Returns the address of the CommunityRewards contract whose grants are distributed by this contract.
  function communityRewards() external view returns (address);

  /// @notice Returns the merkle root of the merkle tree containing grant details available to accept.
  function merkleRoot() external view returns (bytes32);

  /// @notice Returns true if the index has been marked accepted.
  function isGrantAccepted(uint256 index) external view returns (bool);

  /// @notice Causes the sender to accept the grant consisting of the given details. Reverts if
  /// the inputs (which includes who the sender is) are invalid.
  function acceptGrant(
    uint256 index,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval,
    bytes32[] calldata merkleProof
  ) external;

  /// @notice This event is triggered whenever a call to #acceptGrant succeeds.
  event GrantAccepted(
    uint256 indexed tokenId,
    uint256 indexed index,
    address indexed account,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./openzeppelin/IERC721.sol";

interface IPoolTokens is IERC721 {
  struct TokenInfo {
    address pool;
    uint256 tranche;
    uint256 principalAmount;
    uint256 principalRedeemed;
    uint256 interestRedeemed;
  }

  struct MintParams {
    uint256 principalAmount;
    uint256 tranche;
  }

  struct PoolInfo {
    uint256 totalMinted;
    uint256 totalPrincipalRedeemed;
    bool created;
  }

  /**
   * @notice Called by pool to create a debt position in a particular tranche and amount
   * @param params Struct containing the tranche and the amount
   * @param to The address that should own the position
   * @return tokenId The token ID (auto-incrementing integer across all pools)
   */
  function mint(MintParams calldata params, address to) external returns (uint256);

  /**
   * @notice Redeem principal and interest on a pool token. Called by valid pools as part of their redemption
   *  flow
   * @param tokenId pool token id
   * @param principalRedeemed principal to redeem. This cannot exceed the token's principal amount, and
   *  the redemption cannot cause the pool's total principal redeemed to exceed the pool's total minted
   *  principal
   * @param interestRedeemed interest to redeem.
   */
  function redeem(uint256 tokenId, uint256 principalRedeemed, uint256 interestRedeemed) external;

  /**
   * @notice Withdraw a pool token's principal up to the token's principalAmount. Called by valid pools
   *  as part of their withdraw flow before the pool is locked (i.e. before the principal is committed)
   * @param tokenId pool token id
   * @param principalAmount principal to withdraw
   */
  function withdrawPrincipal(uint256 tokenId, uint256 principalAmount) external;

  /**
   * @notice Burns a specific ERC721 token and removes deletes the token metadata for PoolTokens, BackerReards,
   *  and BackerStakingRewards
   * @param tokenId uint256 id of the ERC721 token to be burned.
   */
  function burn(uint256 tokenId) external;

  /**
   * @notice Called by the GoldfinchFactory to register the pool as a valid pool. Only valid pools can mint/redeem
   * tokens
   * @param newPool The address of the newly created pool
   */
  function onPoolCreated(address newPool) external;

  function getTokenInfo(uint256 tokenId) external view returns (TokenInfo memory);

  function getPoolInfo(address pool) external view returns (PoolInfo memory);

  /// @notice Query if `pool` is a valid pool. A pool is valid if it was created by the Goldfinch Factory
  function validPool(address pool) external view returns (bool);

  function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

  /**
   * @notice Splits a pool token into two smaller positions. The original token is burned and all
   * its associated data is deleted.
   * @param tokenId id of the token to split.
   * @param newPrincipal1 principal amount for the first token in the split. The principal amount for the
   *  second token in the split is implicitly the original token's principal amount less newPrincipal1
   * @return tokenId1 id of the first token in the split
   * @return tokenId2 id of the second token in the split
   */
  function splitToken(
    uint256 tokenId,
    uint256 newPrincipal1
  ) external returns (uint256 tokenId1, uint256 tokenId2);

  /**
   * @notice Mint event emitted for a new TranchedPool deposit or when an existing pool token is
   *  split
   * @param owner address to which the token was minted
   * @param pool tranched pool that the deposit was in
   * @param tokenId ERC721 tokenId
   * @param amount the deposit amount
   * @param tranche id of the tranche of the deposit
   */
  event TokenMinted(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 tranche
  );

  /**
   * @notice Redeem event emitted when interest and/or principal is redeemed in the token's pool
   * @param owner owner of the pool token
   * @param pool tranched pool that the token belongs to
   * @param principalRedeemed amount of principal redeemed from the pool
   * @param interestRedeemed amount of interest redeemed from the pool
   * @param tranche id of the tranche the token belongs to
   */
  event TokenRedeemed(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    uint256 tranche
  );

  /**
   * @notice Burn event emitted when the token owner/operator manually burns the token or burns
   *  it implicitly by splitting it
   * @param owner owner of the pool token
   * @param pool tranched pool that the token belongs to
   */
  event TokenBurned(address indexed owner, address indexed pool, uint256 indexed tokenId);

  /**
   * @notice Split event emitted when the token owner/operator splits the token
   * @param pool tranched pool to which the orginal and split tokens belong
   * @param tokenId id of the original token that was split
   * @param newTokenId1 id of the first split token
   * @param newPrincipal1 principalAmount of the first split token
   * @param newTokenId2 id of the second split token
   * @param newPrincipal2 principalAmount of the second split token
   */
  event TokenSplit(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 newTokenId1,
    uint256 newPrincipal1,
    uint256 newTokenId2,
    uint256 newPrincipal2
  );

  /**
   * @notice Principal Withdrawn event emitted when a token's principal is withdrawn from the pool
   *  BEFORE the pool's drawdown period
   * @param pool tranched pool of the token
   * @param principalWithdrawn amount of principal withdrawn from the pool
   */
  event TokenPrincipalWithdrawn(
    address indexed owner,
    address indexed pool,
    uint256 indexed tokenId,
    uint256 principalWithdrawn,
    uint256 tranche
  );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IRequiresUID {
  function hasAllowedUID(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ITranchedPool} from "./ITranchedPool.sol";
import {ISeniorPoolEpochWithdrawals} from "./ISeniorPoolEpochWithdrawals.sol";

abstract contract ISeniorPool is ISeniorPoolEpochWithdrawals {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  /**
   * @notice Withdraw `usdcAmount` of USDC, bypassing the epoch withdrawal system. Callable
   * by Zapper only.
   */
  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  /**
   * @notice Withdraw `fiduAmount` of FIDU converted to USDC at the current share price,
   * bypassing the epoch withdrawal system. Callable by Zapper only
   */
  function withdrawInFidu(uint256 fiduAmount) external virtual returns (uint256 amount);

  function invest(ITranchedPool pool) external virtual returns (uint256);

  function estimateInvestment(ITranchedPool pool) external view virtual returns (uint256);

  function redeem(uint256 tokenId) external virtual;

  function writedown(uint256 tokenId) external virtual;

  function calculateWritedown(
    uint256 tokenId
  ) external view virtual returns (uint256 writedownAmount);

  function sharesOutstanding() external view virtual returns (uint256);

  function assets() external view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);

  event DepositMade(address indexed capitalProvider, uint256 amount, uint256 shares);
  event WithdrawalMade(address indexed capitalProvider, uint256 userAmount, uint256 reserveAmount);
  event InterestCollected(address indexed payer, uint256 amount);
  event PrincipalCollected(address indexed payer, uint256 amount);
  event ReserveFundsCollected(address indexed user, uint256 amount);
  event ReserveSharesCollected(address indexed user, address indexed reserve, uint256 amount);

  event PrincipalWrittenDown(address indexed tranchedPool, int256 amount);
  event InvestmentMadeInSenior(address indexed tranchedPool, uint256 amount);
  event InvestmentMadeInJunior(address indexed tranchedPool, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

interface ISeniorPoolEpochWithdrawals {
  /**
   * @notice A withdrawal epoch
   * @param endsAt timestamp the epoch ends
   * @param fiduRequested amount of fidu requested in the epoch, including fidu
   *                      carried over from previous epochs
   * @param fiduLiquidated Amount of fidu that was liquidated at the end of this epoch
   * @param usdcAllocated Amount of usdc that was allocated to liquidate fidu.
   *                      Does not consider withdrawal fees.
   */
  struct Epoch {
    uint256 endsAt;
    uint256 fiduRequested;
    uint256 fiduLiquidated;
    uint256 usdcAllocated;
  }

  /**
   * @notice A user's request for withdrawal
   * @param epochCursor id of next epoch the user can liquidate their request
   * @param fiduRequested amount of fidu left to liquidate since last checkpoint
   * @param usdcWithdrawable amount of usdc available for a user to withdraw
   */
  struct WithdrawalRequest {
    uint256 epochCursor;
    uint256 usdcWithdrawable;
    uint256 fiduRequested;
  }

  /**
   * @notice Returns the amount of unallocated usdc in the senior pool, taking into account
   *         usdc that _will_ be allocated to withdrawals when a checkpoint happens
   */
  function usdcAvailable() external view returns (uint256);

  /// @notice Current duration of withdrawal epochs, in seconds
  function epochDuration() external view returns (uint256);

  /// @notice Update epoch duration
  function setEpochDuration(uint256 newEpochDuration) external;

  /// @notice The current withdrawal epoch
  function currentEpoch() external view returns (Epoch memory);

  /// @notice Get request by tokenId. A request is considered active if epochCursor > 0.
  function withdrawalRequest(uint256 tokenId) external view returns (WithdrawalRequest memory);

  /**
   * @notice Submit a request to withdraw `fiduAmount` of FIDU. Request is rejected
   * if caller already owns a request token. A non-transferrable request token is
   * minted to the caller
   * @return tokenId token minted to caller
   */
  function requestWithdrawal(uint256 fiduAmount) external returns (uint256 tokenId);

  /**
   * @notice Add `fiduAmount` FIDU to a withdrawal request for `tokenId`. Caller
   * must own tokenId
   */
  function addToWithdrawalRequest(uint256 fiduAmount, uint256 tokenId) external;

  /**
   * @notice Cancel request for tokenId. The fiduRequested (minus a fee) is returned
   * to the caller. Caller must own tokenId.
   * @return fiduReceived the fidu amount returned to the caller
   */
  function cancelWithdrawalRequest(uint256 tokenId) external returns (uint256 fiduReceived);

  /**
   * @notice Transfer the usdcWithdrawable of request for tokenId to the caller.
   * Caller must own tokenId
   */
  function claimWithdrawalRequest(uint256 tokenId) external returns (uint256 usdcReceived);

  /// @notice Emitted when the epoch duration is changed
  event EpochDurationChanged(uint256 newDuration);

  /// @notice Emitted when a new withdraw request has been created
  event WithdrawalRequested(
    uint256 indexed epochId,
    uint256 indexed tokenId,
    address indexed operator,
    uint256 fiduRequested
  );

  /// @notice Emitted when a user adds to their existing withdraw request
  /// @param epochId epoch that the withdraw was added to
  /// @param tokenId id of token that represents the position being added to
  /// @param operator address that added to the request
  /// @param fiduRequested amount of additional fidu added to request
  event WithdrawalAddedTo(
    uint256 indexed epochId,
    uint256 indexed tokenId,
    address indexed operator,
    uint256 fiduRequested
  );

  /// @notice Emitted when a withdraw request has been canceled
  event WithdrawalCanceled(
    uint256 indexed epochId,
    uint256 indexed tokenId,
    address indexed operator,
    uint256 fiduCanceled,
    uint256 reserveFidu
  );

  /// @notice Emitted when an epoch has been checkpointed
  /// @param epochId id of epoch that ended
  /// @param endTime timestamp the epoch ended
  /// @param fiduRequested amount of FIDU oustanding when the epoch ended
  /// @param usdcAllocated amount of USDC allocated to liquidate FIDU
  /// @param fiduLiquidated amount of FIDU liquidated using `usdcAllocated`
  event EpochEnded(
    uint256 indexed epochId,
    uint256 endTime,
    uint256 fiduRequested,
    uint256 usdcAllocated,
    uint256 fiduLiquidated
  );

  /// @notice Emitted when an epoch could not be finalized and is extended instead
  /// @param epochId id of epoch that was extended
  /// @param newEndTime new epoch end time
  /// @param oldEndTime previous epoch end time
  event EpochExtended(uint256 indexed epochId, uint256 newEndTime, uint256 oldEndTime);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./ISeniorPool.sol";
import "./ITranchedPool.sol";

abstract contract ISeniorPoolStrategy {
  function getLeverageRatio(ITranchedPool pool) public view virtual returns (uint256);

  /**
   * @notice Determines how much money to invest in the senior tranche based on what is committed to the junior
   * tranche, what is committed to the senior tranche, and a leverage ratio to the junior tranche. Because
   * it takes into account what is already committed to the senior tranche, the value returned by this
   * function can be used "idempotently" to achieve the investment target amount without exceeding that target.
   * @param seniorPool The senior pool to invest from
   * @param pool The tranched pool to invest into (as the senior)
   * @return amount of money to invest into the tranched pool's senior tranche, from the senior pool
   */
  function invest(
    ISeniorPool seniorPool,
    ITranchedPool pool
  ) public view virtual returns (uint256 amount);

  /**
   * @notice A companion of `invest()`: determines how much would be returned by `invest()`, as the
   * value to invest into the senior tranche, if the junior tranche were locked and the senior tranche
   * were not locked.
   * @param seniorPool The senior pool to invest from
   * @param pool The tranched pool to invest into (as the senior)
   * @return The amount of money to invest into the tranched pool's senior tranche, from the senior pool
   */
  function estimateInvestment(
    ISeniorPool seniorPool,
    ITranchedPool pool
  ) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

pragma experimental ABIEncoderV2;

import {IERC721} from "./openzeppelin/IERC721.sol";
import {IERC721Metadata} from "./openzeppelin/IERC721Metadata.sol";
import {IERC721Enumerable} from "./openzeppelin/IERC721Enumerable.sol";

interface IStakingRewards is IERC721, IERC721Metadata, IERC721Enumerable {
  /// @notice Get the staking rewards position
  /// @param tokenId id of the position token
  /// @return position the position
  function getPosition(uint256 tokenId) external view returns (StakedPosition memory position);

  /// @notice Unstake an amount of `stakingToken()` (FIDU, FiduUSDCCurveLP, etc) associated with
  ///   a given position and transfer to msg.sender. Any remaining staked amount will continue to
  ///   accrue rewards.
  /// @dev This function checkpoints rewards
  /// @param tokenId A staking position token ID
  /// @param amount Amount of `stakingToken()` to be unstaked from the position
  function unstake(uint256 tokenId, uint256 amount) external;

  /// @notice Add `amount` to an existing FIDU position (`tokenId`)
  /// @param tokenId A staking position token ID
  /// @param amount Amount of `stakingToken()` to be added to tokenId's position
  function addToStake(uint256 tokenId, uint256 amount) external;

  /// @notice Returns the staked balance of a given position token.
  /// @dev The value returned is the bare amount, not the effective amount. The bare amount represents
  ///   the number of tokens the user has staked for a given position. The effective amount is the bare
  ///   amount multiplied by the token's underlying asset type multiplier. This multiplier is a crypto-
  ///   economic parameter determined by governance.
  /// @param tokenId A staking position token ID
  /// @return Amount of staked tokens denominated in `stakingToken().decimals()`
  function stakedBalanceOf(uint256 tokenId) external view returns (uint256);

  /// @notice Deposit to FIDU and USDC into the Curve LP, and stake your Curve LP tokens in the same transaction.
  /// @param fiduAmount The amount of FIDU to deposit
  /// @param usdcAmount The amount of USDC to deposit
  function depositToCurveAndStakeFrom(
    address nftRecipient,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) external;

  /// @notice "Kick" a user's reward multiplier. If they are past their lock-up period, their reward
  ///   multiplier will be reset to 1x.
  /// @dev This will also checkpoint their rewards up to the current time.
  function kick(uint256 tokenId) external;

  /// @notice Accumulated rewards per token at the last checkpoint
  function accumulatedRewardsPerToken() external view returns (uint256);

  /// @notice The block timestamp when rewards were last checkpointed
  function lastUpdateTime() external view returns (uint256);

  /// @notice Claim rewards for a given staked position
  /// @param tokenId A staking position token ID
  /// @return amount of rewards claimed
  function getReward(uint256 tokenId) external returns (uint256);

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    StakedPositionType positionType,
    uint256 baseTokenExchangeRate
  );
  event DepositedAndStaked(
    address indexed user,
    uint256 depositedAmount,
    uint256 indexed tokenId,
    uint256 amount
  );
  event DepositedToCurve(
    address indexed user,
    uint256 fiduAmount,
    uint256 usdcAmount,
    uint256 tokensReceived
  );
  event DepositedToCurveAndStaked(
    address indexed user,
    uint256 fiduAmount,
    uint256 usdcAmount,
    uint256 indexed tokenId,
    uint256 amount
  );
  event AddToStake(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    StakedPositionType positionType
  );
  event Unstaked(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amount,
    StakedPositionType positionType
  );
  event UnstakedMultiple(address indexed user, uint256[] tokenIds, uint256[] amounts);
  event RewardPaid(address indexed user, uint256 indexed tokenId, uint256 reward);
  event RewardsParametersUpdated(
    address indexed who,
    uint256 targetCapacity,
    uint256 minRate,
    uint256 maxRate,
    uint256 minRateAtPercent,
    uint256 maxRateAtPercent
  );
  event EffectiveMultiplierUpdated(
    address indexed who,
    StakedPositionType positionType,
    uint256 multiplier
  );
}

/// @notice Indicates which ERC20 is staked
enum StakedPositionType {
  Fidu,
  CurveLP
}

struct Rewards {
  uint256 totalUnvested;
  uint256 totalVested;
  // @dev DEPRECATED (definition kept for storage slot)
  //   For legacy vesting positions, this was used in the case of slashing.
  //   For non-vesting positions, this is unused.
  uint256 totalPreviouslyVested;
  uint256 totalClaimed;
  uint256 startTime;
  // @dev DEPRECATED (definition kept for storage slot)
  //   For legacy vesting positions, this is the endTime of the vesting.
  //   For non-vesting positions, this is 0.
  uint256 endTime;
}

struct StakedPosition {
  // @notice Staked amount denominated in `stakingToken().decimals()`
  uint256 amount;
  // @notice Struct describing rewards owed with vesting
  Rewards rewards;
  // @notice Multiplier applied to staked amount when locking up position
  uint256 leverageMultiplier;
  // @notice Time in seconds after which position can be unstaked
  uint256 lockedUntil;
  // @notice Type of the staked position
  StakedPositionType positionType;
  // @notice Multiplier applied to staked amount to denominate in `baseStakingToken().decimals()`
  // @dev This field should not be used directly; it may be 0 for staked positions created prior to GIP-1.
  //  If you need this field, use `safeEffectiveMultiplier()`, which correctly handles old staked positions.
  uint256 unsafeEffectiveMultiplier;
  // @notice Exchange rate applied to staked amount to denominate in `baseStakingToken().decimals()`
  // @dev This field should not be used directly; it may be 0 for staked positions created prior to GIP-1.
  //  If you need this field, use `safeBaseTokenExchangeRate()`, which correctly handles old staked positions.
  uint256 unsafeBaseTokenExchangeRate;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {IV2CreditLine} from "./IV2CreditLine.sol";

abstract contract ITranchedPool {
  IV2CreditLine public creditLine;
  uint256 public createdAt;
  enum Tranches {
    Reserved,
    Senior,
    Junior
  }

  struct TrancheInfo {
    uint256 id;
    uint256 principalDeposited;
    uint256 principalSharePrice;
    uint256 interestSharePrice;
    uint256 lockedUntil;
  }

  struct PoolSlice {
    TrancheInfo seniorTranche;
    TrancheInfo juniorTranche;
    uint256 totalInterestAccrued;
    uint256 principalDeployed;
  }

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public virtual;

  function getAllowedUIDTypes() external view virtual returns (uint256[] memory);

  function getTranche(uint256 tranche) external view virtual returns (TrancheInfo memory);

  function pay(uint256 amount) external virtual;

  function poolSlices(uint256 index) external view virtual returns (PoolSlice memory);

  function lockJuniorCapital() external virtual;

  function lockPool() external virtual;

  function initializeNextSlice(uint256 _fundableAt) external virtual;

  function totalJuniorDeposits() external view virtual returns (uint256);

  function drawdown(uint256 amount) external virtual;

  function setFundableAt(uint256 timestamp) external virtual;

  function deposit(uint256 tranche, uint256 amount) external virtual returns (uint256 tokenId);

  function assess() external virtual;

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 tokenId);

  function availableToWithdraw(
    uint256 tokenId
  ) external view virtual returns (uint256 interestRedeemable, uint256 principalRedeemable);

  function withdraw(
    uint256 tokenId,
    uint256 amount
  ) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMax(
    uint256 tokenId
  ) external virtual returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

  function withdrawMultiple(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external virtual;

  function numSlices() external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

/// @dev This interface provides a subset of the functionality of the IUniqueIdentity
/// interface -- namely, the subset of functionality needed by Goldfinch protocol contracts
/// compiled with Solidity version 0.6.12.
interface IUniqueIdentity0612 {
  function balanceOf(address account, uint256 id) external view returns (uint256);

  function isApprovedForAll(address account, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ICreditLine} from "./ICreditLine.sol";

abstract contract IV2CreditLine is ICreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess() external virtual returns (uint256, uint256, uint256);

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

/// @title interface for implementers that have an arbitrary associated tag
interface IVersioned {
  /// @notice Returns the version triplet `[major, minor, patch]`
  function getVersion() external pure returns (uint8[3] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC721Enumerable} from "./openzeppelin/IERC721Enumerable.sol";

interface IWithdrawalRequestToken is IERC721Enumerable {
  /// @notice Mint a withdrawal request token to `receiver`
  /// @dev succeeds if and only if called by senior pool
  function mint(address receiver) external returns (uint256 tokenId);

  /// @notice Burn token `tokenId`
  /// @dev suceeds if and only if called by senior pool
  function burn(uint256 tokenId) external;
}

pragma solidity >=0.6.0;

// This file copied from OZ, but with the version pragma updated to use >=.

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

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >= & reference other >= pragma interfaces.
// NOTE: Modified to reference our updated pragma version of IERC165
import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of NFTs in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   *
   *
   * Requirements:
   * - `from`, `to` cannot be zero.
   * - `tokenId` must be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this
   * NFT by either {approve} or {setApprovalForAll}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   * Requirements:
   * - If the caller is not `from`, it must be approved to move this NFT by
   * either {approve} or {setApprovalForAll}.
   */
  function transferFrom(address from, address to, uint256 tokenId) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >=.

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
  function totalSupply() external view returns (uint256);

  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) external view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity >=0.6.2;

// This file copied from OZ, but with the version pragma updated to use >=.

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity >=0.6.12;

// This file copied from OZ, but with the version pragma updated to use >= & reference other >= pragma interfaces.

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

library CommunityRewardsVesting {
  using SafeMath for uint256;
  using CommunityRewardsVesting for Rewards;

  /// @dev All time values in the Rewards struct (i.e. `startTime`, `endTime`,
  /// `cliffLength`, `vestingInterval`, `revokedAt`) use the same units: seconds. All timestamp
  /// values (i.e. `startTime`, `endTime`, `revokedAt`) are seconds since the unix epoch.
  /// @dev `cliffLength` is the duration from the start of the grant, before which has elapsed
  /// the vested amount remains 0.
  /// @dev `vestingInterval` is the interval at which vesting occurs. If `vestingInterval` is not a
  /// factor of `vestingLength`, rewards are fully vested at the time of the last whole `vestingInterval`.
  struct Rewards {
    uint256 totalGranted;
    uint256 totalClaimed;
    uint256 startTime;
    uint256 endTime;
    uint256 cliffLength;
    uint256 vestingInterval;
    uint256 revokedAt;
  }

  function claim(Rewards storage rewards, uint256 reward) internal {
    rewards.totalClaimed = rewards.totalClaimed.add(reward);
  }

  function claimable(Rewards storage rewards) internal view returns (uint256) {
    return claimable(rewards, block.timestamp);
  }

  function claimable(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return rewards.totalVestedAt(time).sub(rewards.totalClaimed);
  }

  function totalUnvestedAt(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return rewards.totalGranted.sub(rewards.totalVestedAt(time));
  }

  function totalVestedAt(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return
      getTotalVestedAt(
        rewards.startTime,
        rewards.endTime,
        rewards.totalGranted,
        rewards.cliffLength,
        rewards.vestingInterval,
        rewards.revokedAt,
        time
      );
  }

  function getTotalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) internal pure returns (uint256) {
    if (time < start.add(cliffLength)) {
      return 0;
    }

    if (end <= start) {
      return granted;
    }

    uint256 elapsedVestingTimestamp = revokedAt > 0 ? Math.min(revokedAt, time) : time;
    uint256 elapsedVestingUnits = (elapsedVestingTimestamp.sub(start)).div(vestingInterval);
    uint256 totalVestingUnits = (end.sub(start)).div(vestingInterval);
    return Math.min(granted.mul(elapsedVestingUnits).div(totalVestingUnits), granted);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @title Safe ERC20 Transfer
 * @notice Reverts when transfer is not successful
 * @author Goldfinch
 */
library SafeERC20Transfer {
  function safeERC20Transfer(
    IERC20 erc20,
    address to,
    uint256 amount,
    string memory message
  ) internal {
    /// @dev ZERO address
    require(to != address(0), "ZERO");
    bool success = erc20.transfer(to, amount);
    require(success, message);
  }

  function safeERC20Transfer(IERC20 erc20, address to, uint256 amount) internal {
    safeERC20Transfer(erc20, to, amount, "");
  }

  function safeERC20TransferFrom(
    IERC20 erc20,
    address from,
    address to,
    uint256 amount,
    string memory message
  ) internal {
    require(to != address(0), "ZERO");
    bool success = erc20.transferFrom(from, to, amount);
    require(success, message);
  }

  function safeERC20TransferFrom(IERC20 erc20, address from, address to, uint256 amount) internal {
    safeERC20TransferFrom(erc20, from, to, amount, "");
  }

  function safeERC20Approve(
    IERC20 erc20,
    address spender,
    uint256 allowance,
    string memory message
  ) internal {
    bool success = erc20.approve(spender, allowance);
    require(success, message);
  }

  function safeERC20Approve(IERC20 erc20, address spender, uint256 allowance) internal {
    safeERC20Approve(erc20, spender, allowance, "");
  }
}

pragma solidity >=0.6.12;

// NOTE: this file exists only to remove the extremely long error messages in safe math.

import {SafeMath as OzSafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return OzSafeMath.sub(a, b, "");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    return OzSafeMath.sub(a, b, errorMessage);
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return OzSafeMath.div(a, b, "");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    return OzSafeMath.div(a, b, errorMessage);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return OzSafeMath.mod(a, b, "");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    return OzSafeMath.mod(a, b, errorMessage);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {Rewards} from "../interfaces/IStakingRewards.sol";

import {Rewards} from "../interfaces/IStakingRewards.sol";

library StakingRewardsVesting {
  using StakingRewardsVesting for Rewards;
  using SafeMath for uint256;

  uint256 internal constant PERCENTAGE_DECIMALS = 1e18;

  function claim(Rewards storage rewards, uint256 reward) internal {
    rewards.totalClaimed = rewards.totalClaimed.add(reward);
  }

  function claimable(Rewards storage rewards) internal view returns (uint256) {
    return rewards.totalVested.add(rewards.totalPreviouslyVested).sub(rewards.totalClaimed);
  }

  function currentGrant(Rewards storage rewards) internal view returns (uint256) {
    return rewards.totalUnvested.add(rewards.totalVested);
  }

  function checkpoint(Rewards storage rewards) internal {
    uint256 newTotalVested = totalVestedAt(
      rewards.startTime,
      rewards.endTime,
      block.timestamp,
      rewards.currentGrant()
    );

    if (newTotalVested > rewards.totalVested) {
      uint256 difference = newTotalVested.sub(rewards.totalVested);
      rewards.totalUnvested = rewards.totalUnvested.sub(difference);
      rewards.totalVested = newTotalVested;
    }
  }

  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 time,
    uint256 grantedAmount
  ) internal pure returns (uint256) {
    if (end <= start) {
      return grantedAmount;
    }

    return Math.min(grantedAmount.mul(time.sub(start)).div(end.sub(start)), grantedAmount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ICreditLine} from "../../interfaces/ICreditLine.sol";
import {FixedPoint} from "../../external/FixedPoint.sol";
import {SafeMath} from "../../library/SafeMath.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

/**
 * @title The Accountant
 * @notice Library for handling key financial calculations, such as interest and principal accrual.
 * @author Goldfinch
 */

library Accountant {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Signed;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for int256;
  using FixedPoint for uint256;

  // Scaling factor used by FixedPoint.sol. We need this to convert the fixed point raw values back to unscaled
  uint256 private constant FP_SCALING_FACTOR = 10 ** 18;
  uint256 private constant INTEREST_DECIMALS = 1e18;
  uint256 private constant SECONDS_PER_DAY = 60 * 60 * 24;
  uint256 private constant SECONDS_PER_YEAR = (SECONDS_PER_DAY * 365);

  struct PaymentAllocation {
    uint256 interestPayment;
    uint256 principalPayment;
    uint256 additionalBalancePayment;
  }

  function calculateInterestAndPrincipalAccrued(
    ICreditLine cl,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 balance = cl.balance(); // gas optimization
    uint256 interestAccrued = calculateInterestAccrued(cl, balance, timestamp, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, timestamp);
    return (interestAccrued, principalAccrued);
  }

  function calculateInterestAndPrincipalAccruedOverPeriod(
    ICreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 interestAccrued = calculateInterestAccruedOverPeriod(
      cl,
      balance,
      startTime,
      endTime,
      lateFeeGracePeriod
    );
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, endTime);
    return (interestAccrued, principalAccrued);
  }

  function calculatePrincipalAccrued(
    ICreditLine cl,
    uint256 balance,
    uint256 timestamp
  ) public view returns (uint256) {
    // If we've already accrued principal as of the term end time, then don't accrue more principal
    uint256 termEndTime = cl.termEndTime();
    if (cl.interestAccruedAsOf() >= termEndTime) {
      return 0;
    }
    if (timestamp >= termEndTime) {
      return balance;
    } else {
      return 0;
    }
  }

  function calculateWritedownFor(
    ICreditLine cl,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    return
      calculateWritedownForPrincipal(cl, cl.balance(), timestamp, gracePeriodInDays, maxDaysLate);
  }

  function calculateWritedownForPrincipal(
    ICreditLine cl,
    uint256 principal,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    FixedPoint.Unsigned memory amountOwedPerDay = calculateAmountOwedForOneDay(cl);
    if (amountOwedPerDay.isEqual(0)) {
      return (0, 0);
    }
    FixedPoint.Unsigned memory fpGracePeriod = FixedPoint.fromUnscaledUint(gracePeriodInDays);
    FixedPoint.Unsigned memory daysLate;

    // Excel math: =min(1,max(0,periods_late_in_days-graceperiod_in_days)/MAX_ALLOWED_DAYS_LATE) grace_period = 30,
    // Before the term end date, we use the interestOwed to calculate the periods late. However, after the loan term
    // has ended, since the interest is a much smaller fraction of the principal, we cannot reliably use interest to
    // calculate the periods later.
    uint256 totalOwed = cl.interestOwed().add(cl.principalOwed());
    daysLate = FixedPoint.fromUnscaledUint(totalOwed).div(amountOwedPerDay);
    if (timestamp > cl.termEndTime()) {
      uint256 secondsLate = timestamp.sub(cl.termEndTime());
      daysLate = daysLate.add(FixedPoint.fromUnscaledUint(secondsLate).div(SECONDS_PER_DAY));
    }

    FixedPoint.Unsigned memory maxLate = FixedPoint.fromUnscaledUint(maxDaysLate);
    FixedPoint.Unsigned memory writedownPercent;
    if (daysLate.isLessThanOrEqual(fpGracePeriod)) {
      // Within the grace period, we don't have to write down, so assume 0%
      writedownPercent = FixedPoint.fromUnscaledUint(0);
    } else {
      writedownPercent = FixedPoint.min(
        FixedPoint.fromUnscaledUint(1),
        (daysLate.sub(fpGracePeriod)).div(maxLate)
      );
    }

    FixedPoint.Unsigned memory writedownAmount = writedownPercent.mul(principal).div(
      FP_SCALING_FACTOR
    );
    // This will return a number between 0-100 representing the write down percent with no decimals
    uint256 unscaledWritedownPercent = writedownPercent.mul(100).div(FP_SCALING_FACTOR).rawValue;
    return (unscaledWritedownPercent, writedownAmount.rawValue);
  }

  function calculateAmountOwedForOneDay(
    ICreditLine cl
  ) public view returns (FixedPoint.Unsigned memory) {
    // Determine theoretical interestOwed for one full day
    uint256 totalInterestPerYear = cl.balance().mul(cl.interestApr()).div(INTEREST_DECIMALS);
    FixedPoint.Unsigned memory interestOwedForOneDay = FixedPoint
      .fromUnscaledUint(totalInterestPerYear)
      .div(365);
    return interestOwedForOneDay.add(cl.principalOwed());
  }

  function calculateInterestAccrued(
    ICreditLine cl,
    uint256 balance,
    uint256 timestamp,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256) {
    // We use Math.min here to prevent integer overflow (ie. go negative) when calculating
    // numSecondsElapsed. Typically this shouldn't be possible, because
    // the interestAccruedAsOf couldn't be *after* the current timestamp. However, when assessing
    // we allow this function to be called with a past timestamp, which raises the possibility
    // of overflow.
    // This use of min should not generate incorrect interest calculations, since
    // this function's purpose is just to normalize balances, and handing in a past timestamp
    // will necessarily return zero interest accrued (because zero elapsed time), which is correct.
    uint256 startTime = Math.min(timestamp, cl.interestAccruedAsOf());
    return
      calculateInterestAccruedOverPeriod(
        cl,
        balance,
        startTime,
        timestamp,
        lateFeeGracePeriodInDays
      );
  }

  function calculateInterestAccruedOverPeriod(
    ICreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256 interestOwed) {
    uint256 secondsElapsed = endTime.sub(startTime);
    uint256 totalInterestPerYear = balance.mul(cl.interestApr()).div(INTEREST_DECIMALS);
    uint256 normalInterestOwed = totalInterestPerYear.mul(secondsElapsed).div(SECONDS_PER_YEAR);

    // Interest accrued in the current period isn't owed until nextDueTime. After that the borrower
    // has a grace period before late fee interest starts to accrue. This grace period applies for
    // every due time (termEndTime is not a special case).
    uint256 lateFeeInterestOwed = 0;
    uint256 lateFeeStartsAt = Math.max(
      startTime,
      cl.nextDueTime().add(lateFeeGracePeriodInDays.mul(SECONDS_PER_DAY))
    );
    if (lateFeeStartsAt < endTime) {
      uint256 lateSecondsElapsed = endTime.sub(lateFeeStartsAt);
      uint256 lateFeeInterestPerYear = balance.mul(cl.lateFeeApr()).div(INTEREST_DECIMALS);
      lateFeeInterestOwed = lateFeeInterestPerYear.mul(lateSecondsElapsed).div(SECONDS_PER_YEAR);
    }

    return normalInterestOwed.add(lateFeeInterestOwed);
  }

  function allocatePayment(
    uint256 paymentAmount,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) public pure returns (PaymentAllocation memory) {
    uint256 paymentRemaining = paymentAmount;
    uint256 interestPayment = Math.min(interestOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(interestPayment);

    uint256 principalPayment = Math.min(principalOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(principalPayment);

    uint256 balanceRemaining = balance.sub(principalPayment);
    uint256 additionalBalancePayment = Math.min(paymentRemaining, balanceRemaining);

    return
      PaymentAllocation({
        interestPayment: interestPayment,
        principalPayment: principalPayment,
        additionalBalancePayment: additionalBalancePayment
      });
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {AccessControlUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import {ReentrancyGuardUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import {SafeMath} from "../../library/SafeMath.sol";
import {PauserPausable} from "./PauserPausable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like upgradeability, pausability, access control, and re-entrancy guards.
 * @author Goldfinch
 */

contract BaseUpgradeablePausable is
  Initializable,
  AccessControlUpgradeSafe,
  PauserPausable,
  ReentrancyGuardUpgradeSafe
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  using SafeMath for uint256;
  // Pre-reserving a few slots in the base contract in case we need to add things in the future.
  // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
  // See OpenZeppelin's use of this pattern here:
  // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
  uint256[50] private __gap1;
  uint256[50] private __gap2;
  uint256[50] private __gap3;
  uint256[50] private __gap4;

  // solhint-disable-next-line func-name-mixedcase
  function __BaseUpgradeablePausable__init(address owner) public initializer {
    require(owner != address(0), "Owner cannot be the zero address");
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ImplementationRepository} from "./proxy/ImplementationRepository.sol";
import {ConfigOptions} from "./ConfigOptions.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {IFidu} from "../../interfaces/IFidu.sol";
import {IWithdrawalRequestToken} from "../../interfaces/IWithdrawalRequestToken.sol";
import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {ICUSDCContract} from "../../interfaces/ICUSDCContract.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {IBackerRewards} from "../../interfaces/IBackerRewards.sol";
import {IGoldfinchFactory} from "../../interfaces/IGoldfinchFactory.sol";
import {IGo} from "../../interfaces/IGo.sol";
import {IStakingRewards} from "../../interfaces/IStakingRewards.sol";
import {ICurveLP} from "../../interfaces/ICurveLP.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigHelper {
  function getSeniorPool(GoldfinchConfig config) internal view returns (ISeniorPool) {
    return ISeniorPool(seniorPoolAddress(config));
  }

  function getSeniorPoolStrategy(
    GoldfinchConfig config
  ) internal view returns (ISeniorPoolStrategy) {
    return ISeniorPoolStrategy(seniorPoolStrategyAddress(config));
  }

  function getUSDC(GoldfinchConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }

  function getFidu(GoldfinchConfig config) internal view returns (IFidu) {
    return IFidu(fiduAddress(config));
  }

  function getFiduUSDCCurveLP(GoldfinchConfig config) internal view returns (ICurveLP) {
    return ICurveLP(fiduUSDCCurveLPAddress(config));
  }

  function getCUSDCContract(GoldfinchConfig config) internal view returns (ICUSDCContract) {
    return ICUSDCContract(cusdcContractAddress(config));
  }

  function getPoolTokens(GoldfinchConfig config) internal view returns (IPoolTokens) {
    return IPoolTokens(poolTokensAddress(config));
  }

  function getBackerRewards(GoldfinchConfig config) internal view returns (IBackerRewards) {
    return IBackerRewards(backerRewardsAddress(config));
  }

  function getGoldfinchFactory(GoldfinchConfig config) internal view returns (IGoldfinchFactory) {
    return IGoldfinchFactory(goldfinchFactoryAddress(config));
  }

  function getGFI(GoldfinchConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(gfiAddress(config));
  }

  function getGo(GoldfinchConfig config) internal view returns (IGo) {
    return IGo(goAddress(config));
  }

  function getStakingRewards(GoldfinchConfig config) internal view returns (IStakingRewards) {
    return IStakingRewards(stakingRewardsAddress(config));
  }

  function getTranchedPoolImplementationRepository(
    GoldfinchConfig config
  ) internal view returns (ImplementationRepository) {
    return
      ImplementationRepository(
        config.getAddress(uint256(ConfigOptions.Addresses.TranchedPoolImplementationRepository))
      );
  }

  function getWithdrawalRequestToken(
    GoldfinchConfig config
  ) internal view returns (IWithdrawalRequestToken) {
    return
      IWithdrawalRequestToken(
        config.getAddress(uint256(ConfigOptions.Addresses.WithdrawalRequestToken))
      );
  }

  function oneInchAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.OneInch));
  }

  function creditLineImplementationAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CreditLineImplementation));
  }

  /// @dev deprecated because we no longer use GSN
  function trustedForwarderAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TrustedForwarder));
  }

  function configAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchConfig));
  }

  function poolTokensAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PoolTokens));
  }

  function backerRewardsAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BackerRewards));
  }

  function seniorPoolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SeniorPool));
  }

  function seniorPoolStrategyAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.SeniorPoolStrategy));
  }

  function goldfinchFactoryAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchFactory));
  }

  function gfiAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GFI));
  }

  function fiduAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Fidu));
  }

  function fiduUSDCCurveLPAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.FiduUSDCCurveLP));
  }

  function cusdcContractAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CUSDCContract));
  }

  function usdcAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.USDC));
  }

  function tranchedPoolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TranchedPoolImplementation));
  }

  function reserveAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ProtocolAdmin));
  }

  function borrowerImplementationAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.BorrowerImplementation));
  }

  function goAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Go));
  }

  function stakingRewardsAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.StakingRewards));
  }

  function getReserveDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessMaxDays));
  }

  function getDrawdownPeriodInSeconds(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.DrawdownPeriodInSeconds));
  }

  function getTransferRestrictionPeriodInDays(
    GoldfinchConfig config
  ) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.TransferRestrictionPeriodInDays));
  }

  function getLeverageRatio(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LeverageRatio));
  }

  function getSeniorPoolWithdrawalCancelationFeeInBps(
    GoldfinchConfig config
  ) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.SeniorPoolWithdrawalCancelationFeeInBps));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit,
    /// @dev: TotalFundsLimit used to represent a total cap on senior pool deposits
    /// but is now deprecated
    TotalFundsLimit,
    MaxUnderwriterLimit,
    ReserveDenominator,
    WithdrawFeeDenominator,
    LatenessGracePeriodInDays,
    LatenessMaxDays,
    DrawdownPeriodInSeconds,
    TransferRestrictionPeriodInDays,
    LeverageRatio,
    /// A number in the range [0, 10000] representing basis points of FIDU taken as a fee
    /// when a withdrawal request is canceled.
    SeniorPoolWithdrawalCancelationFeeInBps
  }
  /// @dev TrustedForwarder is deprecated because we no longer use GSN. CreditDesk
  ///   and Pool are deprecated because they are no longer used in the protocol.
  enum Addresses {
    Pool, // deprecated
    CreditLineImplementation,
    GoldfinchFactory,
    CreditDesk, // deprecated
    Fidu,
    USDC,
    TreasuryReserve,
    ProtocolAdmin,
    OneInch,
    TrustedForwarder, // deprecated
    CUSDCContract,
    GoldfinchConfig,
    PoolTokens,
    TranchedPoolImplementation, // deprecated
    SeniorPool,
    SeniorPoolStrategy,
    MigratedTranchedPoolImplementation,
    BorrowerImplementation,
    GFI,
    Go,
    BackerRewards,
    StakingRewards,
    FiduUSDCCurveLP,
    TranchedPoolImplementationRepository,
    WithdrawalRequestToken
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/// @notice Library to house logic around the ERC2981 royalty standard. Contracts
///   using this library should define a ConfigurableRoyaltyStandard.RoyaltyParams
///   state var and public functions that proxy to the logic here. Contracts should
///   take care to ensure that a public `setRoyaltyParams` method is only callable
///   by an admin.
library ConfigurableRoyaltyStandard {
  using SafeMath for uint256;

  /// @dev bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  uint256 internal constant _PERCENTAGE_DECIMALS = 1e18;

  struct RoyaltyParams {
    // The address that should receive royalties
    address receiver;
    // The percent of `salePrice` that should be taken for royalties.
    // Represented with `_PERCENTAGE_DECIMALS` where `_PERCENTAGE_DECIMALS` is 100%.
    uint256 royaltyPercent;
  }

  event RoyaltyParamsSet(address indexed sender, address newReceiver, uint256 newRoyaltyPercent);

  /// @notice Called with the sale price to determine how much royalty
  //    is owed and to whom.
  /// @param _tokenId The NFT asset queried for royalty information
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address that should receive royalties
  /// @return royaltyAmount The royalty payment amount for _salePrice
  function royaltyInfo(
    RoyaltyParams storage params,
    // solhint-disable-next-line no-unused-vars
    uint256 _tokenId,
    uint256 _salePrice
  ) internal view returns (address, uint256) {
    uint256 royaltyAmount = _salePrice.mul(params.royaltyPercent).div(_PERCENTAGE_DECIMALS);
    return (params.receiver, royaltyAmount);
  }

  /// @notice Set royalty params used in `royaltyInfo`. The calling contract should limit
  ///   public use of this function to owner or using some other access control scheme.
  /// @param newReceiver The new address which should receive royalties. See `receiver`.
  /// @param newRoyaltyPercent The new percent of `salePrice` that should be taken for royalties.
  ///   See `royaltyPercent`.
  /// @dev The receiver cannot be the null address
  function setRoyaltyParams(
    RoyaltyParams storage params,
    address newReceiver,
    uint256 newRoyaltyPercent
  ) internal {
    require(newReceiver != address(0), "Null receiver");
    params.receiver = newReceiver;
    params.royaltyPercent = newRoyaltyPercent;
    emit RoyaltyParamsSet(msg.sender, newReceiver, newRoyaltyPercent);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {Accountant} from "./Accountant.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {ICreditLine} from "../../interfaces/ICreditLine.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

/**
 * @title CreditLine
 * @notice A contract that represents the agreement between Backers and
 *  a Borrower. Includes the terms of the loan, as well as the current accounting state, such as interest owed.
 *  A CreditLine belongs to a TranchedPool, and is fully controlled by that TranchedPool. It does not
 *  operate in any standalone capacity. It should generally be considered internal to the TranchedPool.
 * @author Goldfinch
 */

// solhint-disable-next-line max-states-count
contract CreditLine is BaseUpgradeablePausable, ICreditLine {
  uint256 public constant SECONDS_PER_DAY = 60 * 60 * 24;

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  // Credit line terms
  address public override borrower;
  uint256 public currentLimit;
  uint256 public override maxLimit;
  uint256 public override interestApr;
  uint256 public override paymentPeriodInDays;
  uint256 public override termInDays;
  uint256 public override principalGracePeriodInDays;
  uint256 public override lateFeeApr;

  // Accounting variables
  uint256 public override balance;
  uint256 public override interestOwed;
  uint256 public override principalOwed;
  uint256 public override termEndTime;
  uint256 public override nextDueTime;
  uint256 public override interestAccruedAsOf;
  uint256 public override lastFullPaymentTime;
  uint256 public totalInterestAccrued;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public initializer {
    require(
      _config != address(0) && owner != address(0) && _borrower != address(0),
      "Zero address passed in"
    );
    __BaseUpgradeablePausable__init(owner);
    config = GoldfinchConfig(_config);
    borrower = _borrower;
    maxLimit = _maxLimit;
    interestApr = _interestApr;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lateFeeApr = _lateFeeApr;
    principalGracePeriodInDays = _principalGracePeriodInDays;
    interestAccruedAsOf = block.timestamp;

    // Unlock owner, which is a TranchedPool, for infinite amount
    bool success = config.getUSDC().approve(owner, uint256(-1));
    require(success, "Failed to approve USDC");
  }

  function limit() external view override returns (uint256) {
    return currentLimit;
  }

  /**
   * @notice Updates the internal accounting to track a drawdown as of current block timestamp.
   * Does not move any money
   * @param amount The amount in USDC that has been drawndown
   */
  function drawdown(uint256 amount) external onlyAdmin {
    uint256 timestamp = currentTime();
    require(termEndTime == 0 || (timestamp < termEndTime), "After termEndTime");
    require(amount.add(balance) <= currentLimit, "Cannot drawdown more than the limit");
    require(amount > 0, "Invalid drawdown amount");

    if (balance == 0) {
      setInterestAccruedAsOf(timestamp);
      setLastFullPaymentTime(timestamp);
      setTotalInterestAccrued(0);
      // Set termEndTime only once to prevent extending
      // the loan's end time on every 0 balance drawdown
      if (termEndTime == 0) {
        setTermEndTime(timestamp.add(SECONDS_PER_DAY.mul(termInDays)));
      }
    }

    (uint256 _interestOwed, uint256 _principalOwed) = _updateAndGetInterestAndPrincipalOwedAsOf(
      timestamp
    );
    balance = balance.add(amount);

    updateCreditLineAccounting(balance, _interestOwed, _principalOwed);
    require(!_isLate(timestamp), "Cannot drawdown when payments are past due");
  }

  function setLateFeeApr(uint256 newLateFeeApr) external onlyAdmin {
    lateFeeApr = newLateFeeApr;
  }

  function setLimit(uint256 newAmount) external onlyAdmin {
    require(newAmount <= maxLimit, "Cannot be more than the max limit");
    currentLimit = newAmount;
  }

  function setMaxLimit(uint256 newAmount) external onlyAdmin {
    maxLimit = newAmount;
  }

  function termStartTime() external view returns (uint256) {
    return _termStartTime();
  }

  function isLate() external view override returns (bool) {
    return _isLate(block.timestamp);
  }

  function withinPrincipalGracePeriod() external view override returns (bool) {
    if (termEndTime == 0) {
      // Loan hasn't started yet
      return true;
    }
    return block.timestamp < _termStartTime().add(principalGracePeriodInDays.mul(SECONDS_PER_DAY));
  }

  function setTermEndTime(uint256 newTermEndTime) public onlyAdmin {
    termEndTime = newTermEndTime;
  }

  function setNextDueTime(uint256 newNextDueTime) public onlyAdmin {
    nextDueTime = newNextDueTime;
  }

  function setBalance(uint256 newBalance) public onlyAdmin {
    balance = newBalance;
  }

  function setTotalInterestAccrued(uint256 _totalInterestAccrued) public onlyAdmin {
    totalInterestAccrued = _totalInterestAccrued;
  }

  function setInterestOwed(uint256 newInterestOwed) public onlyAdmin {
    interestOwed = newInterestOwed;
  }

  function setPrincipalOwed(uint256 newPrincipalOwed) public onlyAdmin {
    principalOwed = newPrincipalOwed;
  }

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) public onlyAdmin {
    interestAccruedAsOf = newInterestAccruedAsOf;
  }

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) public onlyAdmin {
    lastFullPaymentTime = newLastFullPaymentTime;
  }

  /**
   * @notice Triggers an assessment of the creditline. Any USDC balance available in the creditline is applied
   * towards the interest and principal.
   * @return Any amount remaining after applying payments towards the interest and principal
   * @return Amount applied towards interest
   * @return Amount applied towards principal
   */
  function assess() public onlyAdmin returns (uint256, uint256, uint256) {
    // Do not assess until a full period has elapsed or past due
    require(balance > 0, "Must have balance to assess credit line");

    // Don't assess credit lines early!
    if (currentTime() < nextDueTime && !_isLate(currentTime())) {
      return (0, 0, 0);
    }
    uint256 timeToAssess = calculateNextDueTime();
    setNextDueTime(timeToAssess);

    // We always want to assess for the most recently *past* nextDueTime.
    // So if the recalculation above sets the nextDueTime into the future,
    // then ensure we pass in the one just before this.
    if (timeToAssess > currentTime()) {
      uint256 secondsPerPeriod = paymentPeriodInDays.mul(SECONDS_PER_DAY);
      timeToAssess = timeToAssess.sub(secondsPerPeriod);
    }
    return handlePayment(_getUSDCBalance(address(this)), timeToAssess);
  }

  function calculateNextDueTime() internal view returns (uint256) {
    uint256 newNextDueTime = nextDueTime;
    uint256 secondsPerPeriod = paymentPeriodInDays.mul(SECONDS_PER_DAY);
    uint256 curTimestamp = currentTime();
    // You must have just done your first drawdown
    if (newNextDueTime == 0 && balance > 0) {
      return curTimestamp.add(secondsPerPeriod);
    }

    // Active loan that has entered a new period, so return the *next* newNextDueTime.
    // But never return something after the termEndTime
    if (balance > 0 && curTimestamp >= newNextDueTime) {
      uint256 secondsToAdvance = (curTimestamp.sub(newNextDueTime).div(secondsPerPeriod))
        .add(1)
        .mul(secondsPerPeriod);
      newNextDueTime = newNextDueTime.add(secondsToAdvance);
      return Math.min(newNextDueTime, termEndTime);
    }

    // You're paid off, or have not taken out a loan yet, so no next due time.
    if (balance == 0 && newNextDueTime != 0) {
      return 0;
    }
    // Active loan in current period, where we've already set the newNextDueTime correctly, so should not change.
    if (balance > 0 && curTimestamp < newNextDueTime) {
      return newNextDueTime;
    }
    revert("Error: could not calculate next due time.");
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _isLate(uint256 timestamp) internal view returns (bool) {
    uint256 secondsElapsedSinceFullPayment = timestamp.sub(lastFullPaymentTime);
    return balance > 0 && secondsElapsedSinceFullPayment > paymentPeriodInDays.mul(SECONDS_PER_DAY);
  }

  function _termStartTime() internal view returns (uint256) {
    return termEndTime.sub(SECONDS_PER_DAY.mul(termInDays));
  }

  /**
   * @notice Applies `amount` of payment for a given credit line. This moves already collected money into the Pool.
   *  It also updates all the accounting variables. Note that interest is always paid back first, then principal.
   *  Any extra after paying the minimum will go towards existing principal (reducing the
   *  effective interest rate). Any extra after the full loan has been paid off will remain in the
   *  USDC Balance of the creditLine, where it will be automatically used for the next drawdown.
   * @param paymentAmount The amount, in USDC atomic units, to be applied
   * @param timestamp The timestamp on which accrual calculations should be based. This allows us
   *  to be precise when we assess a Credit Line
   */
  function handlePayment(
    uint256 paymentAmount,
    uint256 timestamp
  ) internal returns (uint256, uint256, uint256) {
    (uint256 newInterestOwed, uint256 newPrincipalOwed) = _updateAndGetInterestAndPrincipalOwedAsOf(
      timestamp
    );
    Accountant.PaymentAllocation memory pa = Accountant.allocatePayment(
      paymentAmount,
      balance,
      newInterestOwed,
      newPrincipalOwed
    );

    uint256 newBalance = balance.sub(pa.principalPayment);
    // Apply any additional payment towards the balance
    newBalance = newBalance.sub(pa.additionalBalancePayment);
    uint256 totalPrincipalPayment = balance.sub(newBalance);
    uint256 paymentRemaining = paymentAmount.sub(pa.interestPayment).sub(totalPrincipalPayment);

    updateCreditLineAccounting(
      newBalance,
      newInterestOwed.sub(pa.interestPayment),
      newPrincipalOwed.sub(pa.principalPayment)
    );

    assert(paymentRemaining.add(pa.interestPayment).add(totalPrincipalPayment) == paymentAmount);

    return (paymentRemaining, pa.interestPayment, totalPrincipalPayment);
  }

  function _updateAndGetInterestAndPrincipalOwedAsOf(
    uint256 timestamp
  ) internal returns (uint256, uint256) {
    (uint256 interestAccrued, uint256 principalAccrued) = Accountant
      .calculateInterestAndPrincipalAccrued(this, timestamp, config.getLatenessGracePeriodInDays());
    if (interestAccrued > 0) {
      // If we've accrued any interest, update interestAccruedAsOf to the time that we've
      // calculated interest for. If we've not accrued any interest, then we keep the old value so the next
      // time the entire period is taken into account.
      setInterestAccruedAsOf(timestamp);
      totalInterestAccrued = totalInterestAccrued.add(interestAccrued);
    }
    return (interestOwed.add(interestAccrued), principalOwed.add(principalAccrued));
  }

  function updateCreditLineAccounting(
    uint256 newBalance,
    uint256 newInterestOwed,
    uint256 newPrincipalOwed
  ) internal nonReentrant {
    setBalance(newBalance);
    setInterestOwed(newInterestOwed);
    setPrincipalOwed(newPrincipalOwed);

    // This resets lastFullPaymentTime. These conditions assure that they have
    // indeed paid off all their interest and they have a real nextDueTime. (ie. creditline isn't pre-drawdown)
    uint256 _nextDueTime = nextDueTime;
    if (newInterestOwed == 0 && _nextDueTime != 0) {
      // If interest was fully paid off, then set the last full payment as the previous due time
      uint256 mostRecentLastDueTime;
      if (currentTime() < _nextDueTime) {
        uint256 secondsPerPeriod = paymentPeriodInDays.mul(SECONDS_PER_DAY);
        mostRecentLastDueTime = _nextDueTime.sub(secondsPerPeriod);
      } else {
        mostRecentLastDueTime = _nextDueTime;
      }
      setLastFullPaymentTime(mostRecentLastDueTime);
    }

    setNextDueTime(calculateNextDueTime());
  }

  function _getUSDCBalance(address _address) internal view returns (uint256) {
    return config.getUSDC().balanceOf(_address);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {LeverageRatioStrategy} from "./LeverageRatioStrategy.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";

contract DynamicLeverageRatioStrategy is LeverageRatioStrategy {
  bytes32 public constant LEVERAGE_RATIO_SETTER_ROLE = keccak256("LEVERAGE_RATIO_SETTER_ROLE");

  struct LeverageRatioInfo {
    uint256 leverageRatio;
    uint256 juniorTrancheLockedUntil;
  }

  // tranchedPoolAddress => leverageRatioInfo
  mapping(address => LeverageRatioInfo) public ratios;

  event LeverageRatioUpdated(
    address indexed pool,
    uint256 leverageRatio,
    uint256 juniorTrancheLockedUntil,
    bytes32 version
  );

  function initialize(address owner) public initializer {
    require(owner != address(0), "Owner address cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    _setupRole(LEVERAGE_RATIO_SETTER_ROLE, owner);

    _setRoleAdmin(LEVERAGE_RATIO_SETTER_ROLE, OWNER_ROLE);
  }

  function getLeverageRatio(ITranchedPool pool) public view override returns (uint256) {
    LeverageRatioInfo memory ratioInfo = ratios[address(pool)];
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(
      uint256(ITranchedPool.Tranches.Junior)
    );
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(
      uint256(ITranchedPool.Tranches.Senior)
    );

    require(ratioInfo.juniorTrancheLockedUntil > 0, "Leverage ratio has not been set yet.");
    if (seniorTranche.lockedUntil > 0) {
      // The senior tranche is locked. Coherence check: we expect locking the senior tranche to have
      // updated `juniorTranche.lockedUntil` (compared to its value when `setLeverageRatio()` was last
      // called successfully).
      require(
        ratioInfo.juniorTrancheLockedUntil < juniorTranche.lockedUntil,
        "Expected junior tranche `lockedUntil` to have been updated."
      );
    } else {
      require(
        ratioInfo.juniorTrancheLockedUntil == juniorTranche.lockedUntil,
        "Leverage ratio is obsolete. Wait for its recalculation."
      );
    }

    return ratioInfo.leverageRatio;
  }

  /**
   * @notice Updates the leverage ratio for the specified tranched pool. The combination of the
   * `juniorTranchedLockedUntil` param and the `version` param in the event emitted by this
   * function are intended to enable an outside observer to verify the computation of the leverage
   * ratio set by calls of this function.
   * @param pool The tranched pool whose leverage ratio to update.
   * @param leverageRatio The leverage ratio value to set for the tranched pool.
   * @param juniorTrancheLockedUntil The `lockedUntil` timestamp, of the tranched pool's
   * junior tranche, to which this calculation of `leverageRatio` corresponds, i.e. the
   * value of the `lockedUntil` timestamp of the JuniorCapitalLocked event which the caller
   * is calling this function in response to having observed. By providing this timestamp
   * (plus an assumption that we can trust the caller to report this value accurately),
   * the caller enables this function to enforce that a leverage ratio that is obsolete in
   * the sense of having been calculated for an obsolete `lockedUntil` timestamp cannot be set.
   * @param version An arbitrary identifier included in the LeverageRatioUpdated event emitted
   * by this function, enabling the caller to describe how it calculated `leverageRatio`. Using
   * the bytes32 type accommodates using git commit hashes (both the current SHA1 hashes, which
   * require 20 bytes; and the future SHA256 hashes, which require 32 bytes) for this value.
   */
  function setLeverageRatio(
    ITranchedPool pool,
    uint256 leverageRatio,
    uint256 juniorTrancheLockedUntil,
    bytes32 version
  ) public onlySetterRole {
    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(
      uint256(ITranchedPool.Tranches.Junior)
    );
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(
      uint256(ITranchedPool.Tranches.Senior)
    );

    // NOTE: We allow a `leverageRatio` of 0.
    require(
      leverageRatio <= 10 * LEVERAGE_RATIO_DECIMALS,
      "Leverage ratio must not exceed 10 (adjusted for decimals)."
    );

    require(
      juniorTranche.lockedUntil > 0,
      "Cannot set leverage ratio if junior tranche is not locked."
    );
    require(
      seniorTranche.lockedUntil == 0,
      "Cannot set leverage ratio if senior tranche is locked."
    );
    require(
      juniorTrancheLockedUntil == juniorTranche.lockedUntil,
      "Invalid `juniorTrancheLockedUntil` timestamp."
    );

    ratios[address(pool)] = LeverageRatioInfo({
      leverageRatio: leverageRatio,
      juniorTrancheLockedUntil: juniorTrancheLockedUntil
    });

    emit LeverageRatioUpdated(address(pool), leverageRatio, juniorTrancheLockedUntil, version);
  }

  modifier onlySetterRole() {
    require(
      hasRole(LEVERAGE_RATIO_SETTER_ROLE, _msgSender()),
      "Must have leverage-ratio setter role to perform this action"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable-next-line max-line-length
import {ERC20PresetMinterPauserUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/presets/ERC20PresetMinterPauser.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";

/**
 * @title Fidu
 * @notice Fidu (symbol: FIDU) is Goldfinch's liquidity token, representing shares
 *  in the Pool. When you deposit, we mint a corresponding amount of Fidu, and when you withdraw, we
 *  burn Fidu. The share price of the Pool implicitly represents the "exchange rate" between Fidu
 *  and USDC (or whatever currencies the Pool may allow withdraws in during the future)
 * @author Goldfinch
 */

contract Fidu is ERC20PresetMinterPauserUpgradeSafe {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  // $1 threshold to handle potential rounding errors, from differing decimals on Fidu and USDC;
  uint256 public constant ASSET_LIABILITY_MATCH_THRESHOLD = 1e6;
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  /*
    We are using our own initializer function so we can set the owner by passing it in.
    I would override the regular "initializer" function, but I can't because it's not marked
    as "virtual" in the parent contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(
    address owner,
    string calldata name,
    string calldata symbol,
    GoldfinchConfig _config
  ) external initializer {
    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC20_init_unchained(name, symbol);

    __ERC20Burnable_init_unchained();
    __Pausable_init_unchained();
    __ERC20Pausable_init_unchained();

    config = _config;

    _setupRole(MINTER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mintTo(address to, uint256 amount) public {
    require(canMint(amount), "Cannot mint: it would create an asset/liability mismatch");
    // This super call restricts to only the minter in its implementation, so we don't need to do it here.
    super.mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have the MINTER_ROLE
   */
  function burnFrom(address from, uint256 amount) public override {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      "ERC20PresetMinterPauser: Must have minter role to burn"
    );
    require(canBurn(amount), "Cannot burn: it would create an asset/liability mismatch");
    _burn(from, amount);
  }

  // Internal functions

  // canMint assumes that the USDC that backs the new shares has already been sent to the Pool
  function canMint(uint256 newAmount) internal view returns (bool) {
    ISeniorPool seniorPool = config.getSeniorPool();
    uint256 liabilities = totalSupply().add(newAmount).mul(seniorPool.sharePrice()).div(
      fiduMantissa()
    );
    uint256 liabilitiesInDollars = fiduToUSDC(liabilities);
    uint256 _assets = seniorPool.assets();
    if (_assets >= liabilitiesInDollars) {
      return true;
    } else {
      return liabilitiesInDollars.sub(_assets) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    }
  }

  // canBurn assumes that the USDC that backed these shares has already been moved out the Pool
  function canBurn(uint256 amountToBurn) internal view returns (bool) {
    ISeniorPool seniorPool = config.getSeniorPool();
    uint256 liabilities = totalSupply().sub(amountToBurn).mul(seniorPool.sharePrice()).div(
      fiduMantissa()
    );
    uint256 liabilitiesInDollars = fiduToUSDC(liabilities);
    uint256 _assets = seniorPool.assets();
    if (_assets >= liabilitiesInDollars) {
      return true;
    } else {
      return liabilitiesInDollars.sub(_assets) <= ASSET_LIABILITY_MATCH_THRESHOLD;
    }
  }

  function fiduToUSDC(uint256 amount) internal pure returns (uint256) {
    return amount.div(fiduMantissa().div(usdcMantissa()));
  }

  function fiduMantissa() internal pure returns (uint256) {
    return uint256(10) ** uint256(18);
  }

  function usdcMantissa() internal pure returns (uint256) {
    return uint256(10) ** uint256(6);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {LeverageRatioStrategy} from "./LeverageRatioStrategy.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";

contract FixedLeverageRatioStrategy is LeverageRatioStrategy {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  function getLeverageRatio(ITranchedPool) public view override returns (uint256) {
    return config.getLeverageRatio();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import {IGFI} from "../../interfaces/IGFI.sol";

/**
 * @title GFI
 * @notice GFI is Goldfinch's governance token.
 * @author Goldfinch
 */
contract GFI is Context, AccessControl, ERC20Burnable, ERC20Pausable, IGFI {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// The maximum number of tokens that can be minted
  uint256 public override cap;

  event CapUpdated(address indexed who, uint256 cap);

  constructor(
    address owner,
    string memory name,
    string memory symbol,
    uint256 initialCap
  ) public ERC20(name, symbol) {
    cap = initialCap;

    _setupRole(MINTER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice create and send tokens to a specified address
   * @dev this function will fail if the caller attempts to mint over the current cap
   */
  function mint(address account, uint256 amount) public override onlyMinter whenNotPaused {
    require(mintingAmountIsWithinCap(amount), "Cannot mint more than cap");
    _mint(account, amount);
  }

  /**
   * @notice sets the maximum number of tokens that can be minted
   * @dev the cap must be greater than the current total supply
   */
  function setCap(uint256 _cap) external override onlyOwner {
    require(_cap >= totalSupply(), "Cannot decrease the cap below existing supply");
    cap = _cap;
    emit CapUpdated(_msgSender(), cap);
  }

  function mintingAmountIsWithinCap(uint256 amount) internal view returns (bool) {
    return totalSupply().add(amount) <= cap;
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external onlyPauser {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external onlyPauser {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  modifier onlyOwner() {
    require(hasRole(OWNER_ROLE, _msgSender()), "Must be owner");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "Must be minter");
    _;
  }

  modifier onlyPauser() {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Must be pauser");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {IGo} from "../../interfaces/IGo.sol";
import {IUniqueIdentity0612} from "../../interfaces/IUniqueIdentity0612.sol";

contract Go is IGo, BaseUpgradeablePausable {
  bytes32 public constant ZAPPER_ROLE = keccak256("ZAPPER_ROLE");

  address public override uniqueIdentity;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  GoldfinchConfig public legacyGoList;
  uint256[11] public allIdTypes;
  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  function initialize(
    address owner,
    GoldfinchConfig _config,
    address _uniqueIdentity
  ) public initializer {
    require(
      owner != address(0) && address(_config) != address(0) && _uniqueIdentity != address(0),
      "Owner and config and UniqueIdentity addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    _performUpgrade();
    config = _config;
    uniqueIdentity = _uniqueIdentity;
  }

  function performUpgrade() external onlyAdmin {
    return _performUpgrade();
  }

  function _performUpgrade() internal {
    allIdTypes[0] = ID_TYPE_0;
    allIdTypes[1] = ID_TYPE_1;
    allIdTypes[2] = ID_TYPE_2;
    allIdTypes[3] = ID_TYPE_3;
    allIdTypes[4] = ID_TYPE_4;
    allIdTypes[5] = ID_TYPE_5;
    allIdTypes[6] = ID_TYPE_6;
    allIdTypes[7] = ID_TYPE_7;
    allIdTypes[8] = ID_TYPE_8;
    allIdTypes[9] = ID_TYPE_9;
    allIdTypes[10] = ID_TYPE_10;
  }

  /**
   * @notice sets the config that will be used as the source of truth for the go
   * list instead of the config currently associated. To use the associated config for to list, set the override
   * to the null address.
   */
  function setLegacyGoList(GoldfinchConfig _legacyGoList) external onlyAdmin {
    legacyGoList = _legacyGoList;
  }

  /**
   * @notice Returns whether the provided account is:
   * 1. go-listed for use of the Goldfinch protocol for any of the provided UID token types
   * 2. is allowed to act on behalf of the go-listed EOA initiating this transaction
   * Go-listed is defined as: whether `balanceOf(account, id)` on the UniqueIdentity
   * contract is non-zero (where `id` is a supported token id on UniqueIdentity), falling back to the
   * account's status on the legacy go-list maintained on GoldfinchConfig.
   * @dev If tx.origin is 0x0 (e.g. in blockchain explorers such as Etherscan) this function will
   *      throw an error if the account is not go listed.
   * @param account The account whose go status to obtain
   * @param onlyIdTypes Array of id types to check balances
   * @return The account's go status
   */
  function goOnlyIdTypes(
    address account,
    uint256[] memory onlyIdTypes
  ) public view override returns (bool) {
    require(account != address(0), "Zero address is not go-listed");

    if (hasRole(ZAPPER_ROLE, account)) {
      return true;
    }

    GoldfinchConfig legacyGoListConfig = _getLegacyGoList();
    for (uint256 i = 0; i < onlyIdTypes.length; ++i) {
      uint256 idType = onlyIdTypes[i];

      /// @dev Legacy logic. The old contract only holds the equivalent of ID_TYPE_0 accounts, so when checking
      ///   that type, look in the old contract first, then check UID nfts.
      if (idType == ID_TYPE_0 && legacyGoListConfig.goList(account)) {
        return true;
      }

      uint256 accountIdBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(account, idType);
      if (accountIdBalance > 0) {
        return true;
      }

      /* 
       * Check if tx.origin has the UID, and has delegated that to `account`
       * tx.origin should only ever be used for access control - it should never be used to determine
       * the target address for any economic actions
       * e.g. tx.origin should never be used as the source of truth for the target address to
       * credit/debit/mint/burn any tokens to/from
       * WARNING: If tx.origin is 0x0 (e.g. in blockchain explorers such as Etherscan) this function will
       * throw an error if the account is not go listed.
      /* solhint-disable avoid-tx-origin */
      uint256 txOriginIdBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(tx.origin, idType);
      if (txOriginIdBalance > 0) {
        return IUniqueIdentity0612(uniqueIdentity).isApprovedForAll(tx.origin, account);
      }
      /* solhint-enable avoid-tx-origin */
    }

    return false;
  }

  /**
   * @notice Returns a dynamic array of all UID types
   */
  function getAllIdTypes() public view returns (uint256[] memory) {
    // create a dynamic array and copy the fixed array over so we return a dynamic array
    uint256[] memory _allIdTypes = new uint256[](allIdTypes.length);
    for (uint256 i = 0; i < allIdTypes.length; i++) {
      _allIdTypes[i] = allIdTypes[i];
    }

    return _allIdTypes;
  }

  /**
   * @notice Returns a dynamic array of UID types accepted by the senior pool
   */
  function getSeniorPoolIdTypes() public pure returns (uint256[] memory) {
    // using a fixed size array because you can only define fixed size array literals.
    uint256[4] memory allowedSeniorPoolIdTypesStaging = [
      ID_TYPE_0,
      ID_TYPE_1,
      ID_TYPE_3,
      ID_TYPE_4
    ];

    // create a dynamic array and copy the fixed array over so we return a dynamic array
    uint256[] memory allowedSeniorPoolIdTypes = new uint256[](
      allowedSeniorPoolIdTypesStaging.length
    );
    for (uint256 i = 0; i < allowedSeniorPoolIdTypesStaging.length; i++) {
      allowedSeniorPoolIdTypes[i] = allowedSeniorPoolIdTypesStaging[i];
    }

    return allowedSeniorPoolIdTypes;
  }

  /**
   * @notice Returns whether the provided account is go-listed for any UID type
   * @param account The account whose go status to obtain
   * @return The account's go status
   */
  function go(address account) public view override returns (bool) {
    return goOnlyIdTypes(account, getAllIdTypes());
  }

  /**
   * @notice Returns whether the provided account is go-listed for use of the SeniorPool on the Goldfinch protocol.
   * @param account The account whose go status to obtain
   * @return The account's go status
   */
  function goSeniorPool(address account) public view override returns (bool) {
    if (account == config.stakingRewardsAddress()) {
      return true;
    }

    return goOnlyIdTypes(account, getSeniorPoolIdTypes());
  }

  function _getLegacyGoList() internal view returns (GoldfinchConfig) {
    return address(legacyGoList) == address(0) ? config : legacyGoList;
  }

  function initZapperRole() external onlyAdmin {
    _setRoleAdmin(ZAPPER_ROLE, OWNER_ROLE);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {IGoldfinchConfig} from "../../interfaces/IGoldfinchConfig.sol";
import {ConfigOptions} from "./ConfigOptions.sol";

/**
 * @title GoldfinchConfig
 * @notice This contract stores mappings of useful "protocol config state", giving a central place
 *  for all other contracts to access it. For example, the TransactionLimit, or the PoolAddress. These config vars
 *  are enumerated in the `ConfigOptions` library, and can only be changed by admins of the protocol.
 *  Note: While this inherits from BaseUpgradeablePausable, it is not deployed as an upgradeable contract (this
 *    is mostly to save gas costs of having each call go through a proxy)
 * @author Goldfinch
 */

contract GoldfinchConfig is BaseUpgradeablePausable {
  bytes32 public constant GO_LISTER_ROLE = keccak256("GO_LISTER_ROLE");

  mapping(uint256 => address) public addresses;
  mapping(uint256 => uint256) public numbers;
  mapping(address => bool) public goList;

  event AddressUpdated(address owner, uint256 index, address oldValue, address newValue);
  event NumberUpdated(address owner, uint256 index, uint256 oldValue, uint256 newValue);

  event GoListed(address indexed member);
  event NoListed(address indexed member);

  bool public valuesInitialized;

  function initialize(address owner) public initializer {
    require(owner != address(0), "Owner address cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    _setupRole(GO_LISTER_ROLE, owner);

    _setRoleAdmin(GO_LISTER_ROLE, OWNER_ROLE);
  }

  function setAddress(uint256 addressIndex, address newAddress) public onlyAdmin {
    require(addresses[addressIndex] == address(0), "Address has already been initialized");

    emit AddressUpdated(msg.sender, addressIndex, addresses[addressIndex], newAddress);
    addresses[addressIndex] = newAddress;
  }

  function setNumber(uint256 index, uint256 newNumber) public onlyAdmin {
    emit NumberUpdated(msg.sender, index, numbers[index], newNumber);
    numbers[index] = newNumber;
  }

  function setTreasuryReserve(address newTreasuryReserve) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.TreasuryReserve);
    emit AddressUpdated(msg.sender, key, addresses[key], newTreasuryReserve);
    addresses[key] = newTreasuryReserve;
  }

  function setSeniorPoolStrategy(address newStrategy) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.SeniorPoolStrategy);
    emit AddressUpdated(msg.sender, key, addresses[key], newStrategy);
    addresses[key] = newStrategy;
  }

  function setCreditLineImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.CreditLineImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setTranchedPoolImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.TranchedPoolImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setBorrowerImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.BorrowerImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setGoldfinchConfig(address newAddress) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.GoldfinchConfig);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function initializeFromOtherConfig(
    address _initialConfig,
    uint256 numbersLength,
    uint256 addressesLength
  ) public onlyAdmin {
    require(!valuesInitialized, "Already initialized values");
    IGoldfinchConfig initialConfig = IGoldfinchConfig(_initialConfig);
    for (uint256 i = 0; i < numbersLength; i++) {
      setNumber(i, initialConfig.getNumber(i));
    }

    for (uint256 i = 0; i < addressesLength; i++) {
      if (getAddress(i) == address(0)) {
        setAddress(i, initialConfig.getAddress(i));
      }
    }
    valuesInitialized = true;
  }

  /**
   * @dev Adds a user to go-list
   * @param _member address to add to go-list
   */
  function addToGoList(address _member) public onlyGoListerRole {
    goList[_member] = true;
    emit GoListed(_member);
  }

  /**
   * @dev removes a user from go-list
   * @param _member address to remove from go-list
   */
  function removeFromGoList(address _member) public onlyGoListerRole {
    goList[_member] = false;
    emit NoListed(_member);
  }

  /**
   * @dev adds many users to go-list at once
   * @param _members addresses to ad to go-list
   */
  function bulkAddToGoList(address[] calldata _members) external onlyGoListerRole {
    for (uint256 i = 0; i < _members.length; i++) {
      addToGoList(_members[i]);
    }
  }

  /**
   * @dev removes many users from go-list at once
   * @param _members addresses to remove from go-list
   */
  function bulkRemoveFromGoList(address[] calldata _members) external onlyGoListerRole {
    for (uint256 i = 0; i < _members.length; i++) {
      removeFromGoList(_members[i]);
    }
  }

  /*
    Using custom getters in case we want to change underlying implementation later,
    or add checks or validations later on.
  */
  function getAddress(uint256 index) public view returns (address) {
    return addresses[index];
  }

  function getNumber(uint256 index) public view returns (uint256) {
    return numbers[index];
  }

  modifier onlyGoListerRole() {
    require(
      hasRole(GO_LISTER_ROLE, _msgSender()),
      "Must have go-lister role to perform this action"
    );
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {IBorrower} from "../../interfaces/IBorrower.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IV2CreditLine} from "../../interfaces/IV2CreditLine.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {ImplementationRepository} from "./proxy/ImplementationRepository.sol";
import {UcuProxy} from "./proxy/UcuProxy.sol";

/**
 * @title GoldfinchFactory
 * @notice Contract that allows us to create other contracts, such as CreditLines and BorrowerContracts
 *  Note GoldfinchFactory is a legacy name. More properly this can be considered simply the GoldfinchFactory
 * @author Goldfinch
 */

contract GoldfinchFactory is BaseUpgradeablePausable {
  GoldfinchConfig public config;

  /// Role to allow for pool creation
  bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");

  using ConfigHelper for GoldfinchConfig;

  event BorrowerCreated(address indexed borrower, address indexed owner);
  event PoolCreated(ITranchedPool indexed pool, address indexed borrower);
  event CreditLineCreated(IV2CreditLine indexed creditLine);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = _config;
    _setRoleAdmin(BORROWER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice Allows anyone to create a CreditLine contract instance
   * @dev There is no value to calling this function directly. It is only meant to be called
   *  by a TranchedPool during it's creation process.
   */
  function createCreditLine() external returns (IV2CreditLine) {
    IV2CreditLine creditLine = IV2CreditLine(
      _deployMinimal(config.creditLineImplementationAddress())
    );
    emit CreditLineCreated(creditLine);
    return creditLine;
  }

  /**
   * @notice Allows anyone to create a Borrower contract instance
   * @param owner The address that will own the new Borrower instance
   */
  function createBorrower(address owner) external returns (address) {
    address _borrower = _deployMinimal(config.borrowerImplementationAddress());
    IBorrower borrower = IBorrower(_borrower);
    borrower.initialize(owner, address(config));
    emit BorrowerCreated(address(borrower), owner);
    return address(borrower);
  }

  /**
   * @notice Allows anyone to create a new TranchedPool for a single borrower
   * @param _borrower The borrower for whom the CreditLine will be created
   * @param _juniorFeePercent The percent of senior interest allocated to junior investors, expressed as
   *  integer percents. eg. 20% is simply 20
   * @param _limit The maximum amount a borrower can drawdown from this CreditLine
   * @param _interestApr The interest amount, on an annualized basis (APR, so non-compounding), expressed as an integer.
   *  We assume 18 digits of precision. For example, to submit 15.34%, you would pass up 153400000000000000,
   *  and 5.34% would be 53400000000000000
   * @param _paymentPeriodInDays How many days in each payment period.
   *  ie. the frequency with which they need to make payments.
   * @param _termInDays Number of days in the credit term. It is used to set the `termEndTime` upon first drawdown.
   *  ie. The credit line should be fully paid off {_termIndays} days after the first drawdown.
   * @param _lateFeeApr The additional interest you will pay if you are late. For example, if this is 3%, and your
   *  normal rate is 15%, then you will pay 18% while you are late. Also expressed as an 18 decimal precision integer
   *
   * Requirements:
   *  You are the admin
   */
  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) external onlyAdminOrBorrower returns (ITranchedPool) {
    ITranchedPool pool;
    // need to enclose in a scope to avoid overflowing stack
    {
      ImplementationRepository repo = config.getTranchedPoolImplementationRepository();
      UcuProxy poolProxy = new UcuProxy(repo, _borrower);
      pool = ITranchedPool(address(poolProxy));
    }

    pool.initialize(
      address(config),
      _borrower,
      _juniorFeePercent,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays,
      _fundableAt,
      _allowedUIDTypes
    );
    emit PoolCreated(pool, _borrower);
    config.getPoolTokens().onPoolCreated(address(pool));
    return pool;
  }

  // Stolen from:
  // https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/ProxyFactory.sol
  function _deployMinimal(address _logic) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(_logic);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }
    return proxy;
  }

  function isBorrower() public view returns (bool) {
    return hasRole(BORROWER_ROLE, _msgSender());
  }

  modifier onlyAdminOrBorrower() {
    require(isAdmin() || isBorrower(), "Must have admin or borrower role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

/// @notice Base contract that provides an OWNER_ROLE and convenience function/modifier for
///   checking sender against this role. Inherting contracts must set up this role using
///   `_setupRole` and `_setRoleAdmin`.
contract HasAdmin is AccessControlUpgradeSafe {
  /// @notice ID for OWNER_ROLE
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  /// @notice Determine whether msg.sender has OWNER_ROLE
  /// @return isAdmin True when msg.sender has OWNER_ROLE
  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    /// @dev AD: Must have admin role to perform this action
    require(isAdmin(), "AD");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";

abstract contract LeverageRatioStrategy is BaseUpgradeablePausable, ISeniorPoolStrategy {
  uint256 internal constant LEVERAGE_RATIO_DECIMALS = 1e18;

  /// @inheritdoc ISeniorPoolStrategy
  function invest(ISeniorPool, ITranchedPool pool) public view override returns (uint256) {
    uint256 nSlices = pool.numSlices();
    // If the pool has no slices, we cant invest
    if (nSlices == 0) {
      return 0;
    }
    uint256 sliceIndex = nSlices.sub(1);
    (
      ITranchedPool.TrancheInfo memory juniorTranche,
      ITranchedPool.TrancheInfo memory seniorTranche
    ) = _getTranchesInSlice(pool, sliceIndex);
    // If junior capital is not yet invested, or pool already locked, then don't invest anything.
    if (juniorTranche.lockedUntil == 0 || seniorTranche.lockedUntil > 0) {
      return 0;
    }

    return _invest(pool, juniorTranche, seniorTranche);
  }

  /// @inheritdoc ISeniorPoolStrategy
  function estimateInvestment(
    ISeniorPool,
    ITranchedPool pool
  ) public view override returns (uint256) {
    uint256 nSlices = pool.numSlices();
    // If the pool has no slices, we cant invest
    if (nSlices == 0) {
      return 0;
    }
    uint256 sliceIndex = nSlices.sub(1);
    (
      ITranchedPool.TrancheInfo memory juniorTranche,
      ITranchedPool.TrancheInfo memory seniorTranche
    ) = _getTranchesInSlice(pool, sliceIndex);

    return _invest(pool, juniorTranche, seniorTranche);
  }

  function _invest(
    ITranchedPool pool,
    ITranchedPool.TrancheInfo memory juniorTranche,
    ITranchedPool.TrancheInfo memory seniorTranche
  ) internal view returns (uint256) {
    uint256 juniorCapital = juniorTranche.principalDeposited;
    uint256 existingSeniorCapital = seniorTranche.principalDeposited;
    uint256 seniorTarget = juniorCapital.mul(getLeverageRatio(pool)).div(LEVERAGE_RATIO_DECIMALS);
    if (existingSeniorCapital >= seniorTarget) {
      return 0;
    }

    return seniorTarget.sub(existingSeniorCapital);
  }

  /// @notice Return the junior and senior tranches from a given pool in a specified slice
  /// @param pool pool to fetch tranches from
  /// @param sliceIndex slice index to fetch tranches from
  /// @return (juniorTranche, seniorTranche)
  function _getTranchesInSlice(
    ITranchedPool pool,
    uint256 sliceIndex
  )
    internal
    view
    returns (
      ITranchedPool.TrancheInfo memory, // junior tranche
      ITranchedPool.TrancheInfo memory // senior tranche
    )
  {
    uint256 juniorTrancheId = _sliceIndexToJuniorTrancheId(sliceIndex);
    uint256 seniorTrancheId = _sliceIndexToSeniorTrancheId(sliceIndex);

    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(juniorTrancheId);
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(seniorTrancheId);
    return (juniorTranche, seniorTranche);
  }

  /// @notice Returns the junior tranche id for the given slice index
  /// @param index slice index
  /// @return junior tranche id of given slice index
  function _sliceIndexToJuniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.mul(2).add(2);
  }

  /// @notice Returns the senion tranche id for the given slice index
  /// @param index slice index
  /// @return senior tranche id of given slice index
  function _sliceIndexToSeniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.mul(2).add(1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

/**
 * @title PauserPausable
 * @notice Inheriting from OpenZeppelin's Pausable contract, this does small
 *  augmentations to make it work with a PAUSER_ROLE, leveraging the AccessControl contract.
 *  It is meant to be inherited.
 * @author Goldfinch
 */

contract PauserPausable is AccessControlUpgradeSafe, PausableUpgradeSafe {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __PauserPausable__init() public initializer {
    __Pausable_init_unchained();
  }

  /**
   * @dev Pauses all functions guarded by Pause
   *
   * See {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the PAUSER_ROLE.
   */

  function pause() public onlyPauserRole {
    _pause();
  }

  /**
   * @dev Unpauses the contract
   *
   * See {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the Pauser role
   */
  function unpause() public onlyPauserRole {
    _unpause();
  }

  modifier onlyPauserRole() {
    /// @dev NA: not authorized
    require(hasRole(PAUSER_ROLE, _msgSender()), "NA");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ERC721PresetMinterPauserAutoIdUpgradeSafe} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {ERC165UpgradeSafe} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {IERC165} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {HasAdmin} from "./HasAdmin.sol";
import {ConfigurableRoyaltyStandard} from "./ConfigurableRoyaltyStandard.sol";
import {IERC2981} from "../../interfaces/IERC2981.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {IBackerRewards} from "../../interfaces/IBackerRewards.sol";

/**
 * @title PoolTokens
 * @notice PoolTokens is an ERC721 compliant contract, which can represent
 *  junior tranche or senior tranche shares of any of the borrower pools.
 * @author Goldfinch
 */
contract PoolTokens is IPoolTokens, ERC721PresetMinterPauserAutoIdUpgradeSafe, HasAdmin, IERC2981 {
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  // tokenId => tokenInfo
  mapping(uint256 => TokenInfo) public tokens;
  // poolAddress => poolInfo
  mapping(address => PoolInfo) public pools;

  ConfigurableRoyaltyStandard.RoyaltyParams public royaltyParams;
  using ConfigurableRoyaltyStandard for ConfigurableRoyaltyStandard.RoyaltyParams;

  /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );

    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC165_init_unchained();
    // This is setting name and symbol of the NFT's
    __ERC721_init_unchained("Goldfinch V2 Pool Tokens", "GFI-V2-PT");
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();

    config = _config;

    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /// @inheritdoc IPoolTokens
  function mint(
    MintParams calldata params,
    address to
  ) external virtual override onlyPool whenNotPaused returns (uint256 tokenId) {
    address poolAddress = _msgSender();

    PoolInfo storage pool = pools[poolAddress];
    pool.totalMinted = pool.totalMinted.add(params.principalAmount);

    tokenId = _createToken({
      principalAmount: params.principalAmount,
      tranche: params.tranche,
      principalRedeemed: 0,
      interestRedeemed: 0,
      poolAddress: poolAddress,
      mintTo: to
    });

    config.getBackerRewards().setPoolTokenAccRewardsPerPrincipalDollarAtMint(_msgSender(), tokenId);
  }

  /// @inheritdoc IPoolTokens
  function redeem(
    uint256 tokenId,
    uint256 principalRedeemed,
    uint256 interestRedeemed
  ) external virtual override onlyPool whenNotPaused {
    TokenInfo storage token = tokens[tokenId];
    address poolAddr = token.pool;
    require(token.pool != address(0), "Invalid tokenId");
    require(_msgSender() == poolAddr, "Only the token's pool can redeem");

    PoolInfo storage pool = pools[poolAddr];
    pool.totalPrincipalRedeemed = pool.totalPrincipalRedeemed.add(principalRedeemed);
    require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot redeem more than we minted");

    token.principalRedeemed = token.principalRedeemed.add(principalRedeemed);
    require(
      token.principalRedeemed <= token.principalAmount,
      "Cannot redeem more than principal-deposited amount for token"
    );
    token.interestRedeemed = token.interestRedeemed.add(interestRedeemed);

    emit TokenRedeemed(
      ownerOf(tokenId),
      poolAddr,
      tokenId,
      principalRedeemed,
      interestRedeemed,
      token.tranche
    );
  }

  /** @notice reduce a given pool token's principalAmount and principalRedeemed by a specified amount
   *  @dev uses safemath to prevent underflow
   *  @dev this function is only intended for use as part of the v2.6.0 upgrade
   *    to rectify a bug that allowed users to create a PoolToken that had a
   *    larger amount of principal than they actually made available to the
   *    borrower.  This bug is fixed in v2.6.0 but still requires past pool tokens
   *    to have their principal redeemed and deposited to be rectified.
   *  @param tokenId id of token to decrease
   *  @param amount amount to decrease by
   */
  function reducePrincipalAmount(uint256 tokenId, uint256 amount) external onlyAdmin {
    TokenInfo storage tokenInfo = tokens[tokenId];
    tokenInfo.principalAmount = tokenInfo.principalAmount.sub(amount);
    tokenInfo.principalRedeemed = tokenInfo.principalRedeemed.sub(amount);
  }

  /// @inheritdoc IPoolTokens
  function withdrawPrincipal(
    uint256 tokenId,
    uint256 principalAmount
  ) external virtual override onlyPool whenNotPaused {
    TokenInfo storage token = tokens[tokenId];
    address poolAddr = token.pool;
    require(_msgSender() == poolAddr, "Invalid sender");
    require(token.principalRedeemed == 0, "Token redeemed");
    require(token.principalAmount >= principalAmount, "Insufficient principal");

    PoolInfo storage pool = pools[poolAddr];
    pool.totalMinted = pool.totalMinted.sub(principalAmount);
    require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot withdraw more than redeemed");

    token.principalAmount = token.principalAmount.sub(principalAmount);

    emit TokenPrincipalWithdrawn(
      ownerOf(tokenId),
      poolAddr,
      tokenId,
      principalAmount,
      token.tranche
    );
  }

  /// @inheritdoc IPoolTokens
  function burn(uint256 tokenId) external virtual override whenNotPaused {
    TokenInfo memory token = _getTokenInfo(tokenId);
    bool canBurn = _isApprovedOrOwner(_msgSender(), tokenId);
    bool fromTokenPool = _validPool(_msgSender()) && token.pool == _msgSender();
    address owner = ownerOf(tokenId);
    require(canBurn || fromTokenPool, "ERC721Burnable: caller cannot burn this token");
    require(
      token.principalRedeemed == token.principalAmount,
      "Can only burn fully redeemed tokens"
    );
    // If we let you burn with claimable backer rewards then it would blackhole your rewards,
    // so you must claim all rewards before burning
    require(config.getBackerRewards().poolTokenClaimableRewards(tokenId) == 0, "rewards>0");
    _destroyAndBurn(owner, address(token.pool), tokenId);
  }

  function getTokenInfo(uint256 tokenId) external view virtual override returns (TokenInfo memory) {
    return _getTokenInfo(tokenId);
  }

  function getPoolInfo(address pool) external view override returns (PoolInfo memory) {
    return pools[pool];
  }

  /// @inheritdoc IPoolTokens
  function onPoolCreated(address newPool) external override onlyGoldfinchFactory {
    pools[newPool].created = true;
  }

  /**
   * @notice Returns a boolean representing whether the spender is the owner or the approved spender of the token
   * @param spender The address to check
   * @param tokenId The token id to check for
   * @return True if approved to redeem/transfer/burn the token, false if not
   */
  function isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) external view override returns (bool) {
    return _isApprovedOrOwner(spender, tokenId);
  }

  /**
   * @inheritdoc IPoolTokens
   * @dev NA: Not Authorized
   * @dev IA: Invalid Amount - newPrincipal1 not in range (0, principalAmount)
   */
  function splitToken(
    uint256 tokenId,
    uint256 newPrincipal1
  ) external override returns (uint256 tokenId1, uint256 tokenId2) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "NA");
    TokenInfo memory tokenInfo = _getTokenInfo(tokenId);
    require(0 < newPrincipal1 && newPrincipal1 < tokenInfo.principalAmount, "IA");

    IBackerRewards.BackerRewardsTokenInfo memory backerRewardsTokenInfo = config
      .getBackerRewards()
      .getTokenInfo(tokenId);

    IBackerRewards.StakingRewardsTokenInfo memory backerStakingRewardsTokenInfo = config
      .getBackerRewards()
      .getStakingRewardsTokenInfo(tokenId);

    // Burn the original token before calling out to other contracts to prevent possible reentrancy attacks.
    // A reentrancy guard on this function alone is insufficient because someone may be able to reenter the
    // protocol through a different contract that reads pool token metadata. Following checks-effects-interactions
    // here leads to a clunky implementation (fn's with many params) but guarding against potential reentrancy
    // is more important.
    address tokenOwner = ownerOf(tokenId);
    _destroyAndBurn(tokenOwner, address(tokenInfo.pool), tokenId);

    (tokenId1, tokenId2) = _createSplitTokens(tokenInfo, tokenOwner, newPrincipal1);
    _setBackerRewardsForSplitTokens(
      tokenInfo,
      backerRewardsTokenInfo,
      backerStakingRewardsTokenInfo,
      tokenId1,
      tokenId2,
      newPrincipal1
    );

    emit TokenSplit({
      owner: tokenOwner,
      pool: tokenInfo.pool,
      tokenId: tokenId,
      newTokenId1: tokenId1,
      newPrincipal1: newPrincipal1,
      newTokenId2: tokenId2,
      newPrincipal2: tokenInfo.principalAmount.sub(newPrincipal1)
    });
  }

  /// @notice Initialize the backer rewards metadata for split tokens
  function _setBackerRewardsForSplitTokens(
    TokenInfo memory tokenInfo,
    IBackerRewards.BackerRewardsTokenInfo memory backerRewardsTokenInfo,
    IBackerRewards.StakingRewardsTokenInfo memory stakingRewardsTokenInfo,
    uint256 newTokenId1,
    uint256 newTokenId2,
    uint256 newPrincipal1
  ) internal {
    uint256 rewardsClaimed1 = backerRewardsTokenInfo.rewardsClaimed.mul(newPrincipal1).div(
      tokenInfo.principalAmount
    );

    config.getBackerRewards().setBackerAndStakingRewardsTokenInfoOnSplit({
      originalBackerRewardsTokenInfo: backerRewardsTokenInfo,
      originalStakingRewardsTokenInfo: stakingRewardsTokenInfo,
      newTokenId: newTokenId1,
      newRewardsClaimed: rewardsClaimed1
    });

    config.getBackerRewards().setBackerAndStakingRewardsTokenInfoOnSplit({
      originalBackerRewardsTokenInfo: backerRewardsTokenInfo,
      originalStakingRewardsTokenInfo: stakingRewardsTokenInfo,
      newTokenId: newTokenId2,
      newRewardsClaimed: backerRewardsTokenInfo.rewardsClaimed.sub(rewardsClaimed1)
    });
  }

  /// @notice Split tokenId into two new tokens. Assumes that newPrincipal1 is valid for the token's principalAmount
  function _createSplitTokens(
    TokenInfo memory tokenInfo,
    address tokenOwner,
    uint256 newPrincipal1
  ) internal returns (uint256 newTokenId1, uint256 newTokenId2) {
    // All new vals are proportional to the new token's principal
    uint256 principalRedeemed1 = tokenInfo.principalRedeemed.mul(newPrincipal1).div(
      tokenInfo.principalAmount
    );
    uint256 interestRedeemed1 = tokenInfo.interestRedeemed.mul(newPrincipal1).div(
      tokenInfo.principalAmount
    );

    newTokenId1 = _createToken(
      newPrincipal1,
      tokenInfo.tranche,
      principalRedeemed1,
      interestRedeemed1,
      tokenInfo.pool,
      tokenOwner
    );

    newTokenId2 = _createToken(
      tokenInfo.principalAmount.sub(newPrincipal1),
      tokenInfo.tranche,
      tokenInfo.principalRedeemed.sub(principalRedeemed1),
      tokenInfo.interestRedeemed.sub(interestRedeemed1),
      tokenInfo.pool,
      tokenOwner
    );
  }

  /// @inheritdoc IPoolTokens
  function validPool(address sender) public view virtual override returns (bool) {
    return _validPool(sender);
  }

  /**
   * @notice Mint the token and save its metadata to storage
   * @param principalAmount token principal
   * @param tranche tranche of the pool to which the token belongs
   * @param principalRedeemed amount of principal already redeemed for the token. This is
   *  0 for tokens created from a deposit, and could be non-zero for tokens created from a split
   * @param interestRedeemed amount of interest already redeemed for the token. This is
   *  0 for tokens created from a deposit, and could be non-zero for tokens created from a split
   * @param poolAddress pool to which the token belongs
   * @param mintTo the token owner
   * @return tokenId id of the created token
   */
  function _createToken(
    uint256 principalAmount,
    uint256 tranche,
    uint256 principalRedeemed,
    uint256 interestRedeemed,
    address poolAddress,
    address mintTo
  ) internal returns (uint256 tokenId) {
    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    tokens[tokenId] = TokenInfo({
      pool: poolAddress,
      tranche: tranche,
      principalAmount: principalAmount,
      principalRedeemed: principalRedeemed,
      interestRedeemed: interestRedeemed
    });

    _mint(mintTo, tokenId);

    emit TokenMinted({
      owner: mintTo,
      pool: poolAddress,
      tokenId: tokenId,
      amount: principalAmount,
      tranche: tranche
    });
  }

  function _destroyAndBurn(address owner, address pool, uint256 tokenId) internal {
    delete tokens[tokenId];
    _burn(tokenId);
    config.getBackerRewards().clearTokenInfo(tokenId);
    emit TokenBurned(owner, pool, tokenId);
  }

  function _validPool(address poolAddress) internal view virtual returns (bool) {
    return pools[poolAddress].created;
  }

  function _getTokenInfo(uint256 tokenId) internal view returns (TokenInfo memory) {
    return tokens[tokenId];
  }

  /// @notice Called with the sale price to determine how much royalty
  //    is owed and to whom.
  /// @param _tokenId The NFT asset queried for royalty information
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address that should receive royalties
  /// @return royaltyAmount The royalty payment amount for _salePrice
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override returns (address, uint256) {
    return royaltyParams.royaltyInfo(_tokenId, _salePrice);
  }

  /// @notice Set royalty params used in `royaltyInfo`. This function is only callable by
  ///   an address with `OWNER_ROLE`.
  /// @param newReceiver The new address which should receive royalties. See `receiver`.
  /// @param newRoyaltyPercent The new percent of `salePrice` that should be taken for royalties.
  ///   See `royaltyPercent`.
  function setRoyaltyParams(address newReceiver, uint256 newRoyaltyPercent) external onlyAdmin {
    royaltyParams.setRoyaltyParams(newReceiver, newRoyaltyPercent);
  }

  function setBaseURI(string calldata baseURI_) external onlyAdmin {
    _setBaseURI(baseURI_);
  }

  function supportsInterface(
    bytes4 id
  ) public view override(ERC165UpgradeSafe, IERC165) returns (bool) {
    return (id == _INTERFACE_ID_ERC721 ||
      id == _INTERFACE_ID_ERC721_METADATA ||
      id == _INTERFACE_ID_ERC721_ENUMERABLE ||
      id == _INTERFACE_ID_ERC165 ||
      id == ConfigurableRoyaltyStandard._INTERFACE_ID_ERC2981);
  }

  modifier onlyGoldfinchFactory() {
    require(_msgSender() == config.goldfinchFactoryAddress(), "Only Goldfinch factory is allowed");
    _;
  }

  modifier onlyPool() {
    require(_validPool(_msgSender()), "Invalid pool!");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "../BaseUpgradeablePausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title User Controlled Upgrades (UCU) Proxy Repository
/// A repository maintaing a collection of "lineages" of implementation contracts
///
/// Lineages are a sequence of implementations each lineage can be thought of as
/// a "major" revision of implementations. Implementations between lineages are
/// considered incompatible.
contract ImplementationRepository is BaseUpgradeablePausable {
  address internal constant INVALID_IMPL = address(0);
  uint256 internal constant INVALID_LINEAGE_ID = 0;

  /// @notice returns data that will be delegatedCalled when the given implementation
  ///           is upgraded to
  mapping(address => bytes) public upgradeDataFor;

  /// @dev mapping from one implementation to the succeeding implementation
  mapping(address => address) internal _nextImplementationOf;

  /// @notice Returns the id of the lineage a given implementation belongs to
  mapping(address => uint256) public lineageIdOf;

  /// @dev internal because we expose this through the `currentImplementation(uint256)` api
  mapping(uint256 => address) internal _currentOfLineage;

  /// @notice Returns the id of the most recently created lineage
  uint256 public currentLineageId;

  // //////// External ////////////////////////////////////////////////////////////

  /// @notice initialize the repository's state
  /// @dev reverts if `_owner` is the null address
  /// @dev reverts if `implementation` is not a contract
  /// @param _owner owner of the repository
  /// @param implementation initial implementation in the repository
  function initialize(address _owner, address implementation) external initializer {
    __BaseUpgradeablePausable__init(_owner);
    _createLineage(implementation);
    require(currentLineageId != INVALID_LINEAGE_ID);
  }

  /// @notice set data that will be delegate called when a proxy upgrades to the given `implementation`
  /// @dev reverts when caller is not an admin
  /// @dev reverts when the contract is paused
  /// @dev reverts if the given implementation isn't registered
  function setUpgradeDataFor(
    address implementation,
    bytes calldata data
  ) external onlyAdmin whenNotPaused {
    _setUpgradeDataFor(implementation, data);
  }

  /// @notice Create a new lineage of implementations.
  ///
  /// This creates a new "root" of a new lineage
  /// @dev reverts if `implementation` is not a contract
  /// @param implementation implementation that will be the first implementation in the lineage
  /// @return newly created lineage's id
  function createLineage(
    address implementation
  ) external onlyAdmin whenNotPaused returns (uint256) {
    return _createLineage(implementation);
  }

  /// @notice add a new implementation and set it as the current implementation
  /// @dev reverts if the sender is not an owner
  /// @dev reverts if the contract is paused
  /// @dev reverts if `implementation` is not a contract
  /// @param implementation implementation to append
  function append(address implementation) external onlyAdmin whenNotPaused {
    _append(implementation, currentLineageId);
  }

  /// @notice Append an implementation to a specified lineage
  /// @dev reverts if the contract is paused
  /// @dev reverts if the sender is not an owner
  /// @dev reverts if `implementation` is not a contract
  /// @param implementation implementation to append
  /// @param lineageId id of lineage to append to
  function append(address implementation, uint256 lineageId) external onlyAdmin whenNotPaused {
    _append(implementation, lineageId);
  }

  /// @notice Remove an implementation from the chain and "stitch" together its neighbors
  /// @dev If you have a chain of `A -> B -> C` and I call `remove(B, C)` it will result in `A -> C`
  /// @dev reverts if `previos` is not the ancestor of `toRemove`
  /// @dev we need to provide the previous implementation here to be able to successfully "stitch"
  ///       the chain back together. Because this is an admin action, we can source what the previous
  ///       version is from events.
  /// @param toRemove Implementation to remove
  /// @param previous Implementation that currently has `toRemove` as its successor
  function remove(address toRemove, address previous) external onlyAdmin whenNotPaused {
    _remove(toRemove, previous);
  }

  // //////// External view ////////////////////////////////////////////////////////////

  /// @notice Returns `true` if an implementation has a next implementation set
  /// @param implementation implementation to check
  /// @return The implementation following the given implementation
  function hasNext(address implementation) external view returns (bool) {
    return _nextImplementationOf[implementation] != INVALID_IMPL;
  }

  /// @notice Returns `true` if an implementation has already been added
  /// @param implementation Implementation to check existence of
  /// @return `true` if the implementation has already been added
  function has(address implementation) external view returns (bool) {
    return _has(implementation);
  }

  /// @notice Get the next implementation for a given implementation or
  ///           `address(0)` if it doesn't exist
  /// @dev reverts when contract is paused
  /// @param implementation implementation to get the upgraded implementation for
  /// @return Next Implementation
  function nextImplementationOf(
    address implementation
  ) external view whenNotPaused returns (address) {
    return _nextImplementationOf[implementation];
  }

  /// @notice Returns `true` if a given lineageId exists
  function lineageExists(uint256 lineageId) external view returns (bool) {
    return _lineageExists(lineageId);
  }

  /// @notice Return the current implementation of a lineage with the given `lineageId`
  function currentImplementation(uint256 lineageId) external view whenNotPaused returns (address) {
    return _currentImplementation(lineageId);
  }

  /// @notice return current implementaton of the current lineage
  function currentImplementation() external view whenNotPaused returns (address) {
    return _currentImplementation(currentLineageId);
  }

  // //////// Internal ////////////////////////////////////////////////////////////

  function _setUpgradeDataFor(address implementation, bytes memory data) internal {
    require(_has(implementation), "unknown impl");
    upgradeDataFor[implementation] = data;
    emit UpgradeDataSet(implementation, data);
  }

  function _createLineage(address implementation) internal virtual returns (uint256) {
    require(Address.isContract(implementation), "not a contract");
    // NOTE: impractical to overflow
    currentLineageId += 1;

    _currentOfLineage[currentLineageId] = implementation;
    lineageIdOf[implementation] = currentLineageId;

    emit Added(currentLineageId, implementation, address(0));
    return currentLineageId;
  }

  function _currentImplementation(uint256 lineageId) internal view returns (address) {
    return _currentOfLineage[lineageId];
  }

  /// @notice Returns `true` if an implementation has already been added
  /// @param implementation implementation to check for
  /// @return `true` if the implementation has already been added
  function _has(address implementation) internal view virtual returns (bool) {
    return lineageIdOf[implementation] != INVALID_LINEAGE_ID;
  }

  /// @notice Set an implementation to the current implementation
  /// @param implementation implementation to set as current implementation
  /// @param lineageId id of lineage to append to
  function _append(address implementation, uint256 lineageId) internal virtual {
    require(Address.isContract(implementation), "not a contract");
    require(!_has(implementation), "exists");
    require(_lineageExists(lineageId), "invalid lineageId");
    require(_currentOfLineage[lineageId] != INVALID_IMPL, "empty lineage");

    address oldImplementation = _currentOfLineage[lineageId];
    _currentOfLineage[lineageId] = implementation;
    lineageIdOf[implementation] = lineageId;
    _nextImplementationOf[oldImplementation] = implementation;

    emit Added(lineageId, implementation, oldImplementation);
  }

  function _remove(address toRemove, address previous) internal virtual {
    require(toRemove != INVALID_IMPL && previous != INVALID_IMPL, "ZERO");
    require(_nextImplementationOf[previous] == toRemove, "Not prev");

    uint256 lineageId = lineageIdOf[toRemove];

    // need to reset the head pointer to the previous version if we remove the head
    if (toRemove == _currentOfLineage[lineageId]) {
      _currentOfLineage[lineageId] = previous;
    }

    _setUpgradeDataFor(toRemove, ""); // reset upgrade data
    _nextImplementationOf[previous] = _nextImplementationOf[toRemove];
    _nextImplementationOf[toRemove] = INVALID_IMPL;
    lineageIdOf[toRemove] = INVALID_LINEAGE_ID;
    emit Removed(lineageId, toRemove);
  }

  function _lineageExists(uint256 lineageId) internal view returns (bool) {
    return lineageId != INVALID_LINEAGE_ID && lineageId <= currentLineageId;
  }

  // //////// Events //////////////////////////////////////////////////////////////
  event Added(
    uint256 indexed lineageId,
    address indexed newImplementation,
    address indexed oldImplementation
  );
  event Removed(uint256 indexed lineageId, address indexed implementation);
  event UpgradeDataSet(address indexed implementation, bytes data);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ImplementationRepository as Repo} from "./ImplementationRepository.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC173} from "../../../interfaces/IERC173.sol";

/// @title User Controlled Upgrade (UCU) Proxy
///
/// The UCU Proxy contract allows the owner of the proxy to control _when_ they
/// upgrade their proxy, but not to what implementation.  The implementation is
/// determined by an externally controlled {ImplementationRepository} contract that
/// specifices the upgrade path. A user is able to upgrade their proxy as many
/// times as is available until they're reached the most up to date version
contract UcuProxy is IERC173, Proxy {
  /// @dev Storage slot with the address of the current implementation.
  /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
  bytes32 private constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  // defined here: https://eips.ethereum.org/EIPS/eip-1967
  // result of `bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)`
  bytes32 private constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  // result of `bytes32(uint256(keccak256('eipxxxx.proxy.repository')) - 1)`
  bytes32 private constant _REPOSITORY_SLOT =
    0x007037545499569801a5c0bd8dbf5fccb13988c7610367d129f45ee69b1624f8;

  // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

  /// @param _repository repository used for sourcing upgrades
  /// @param _owner owner of proxy
  /// @dev reverts if either `_repository` or `_owner` is null
  constructor(Repo _repository, address _owner) public {
    require(_owner != address(0), "bad owner");
    _setOwner(_owner);
    _setRepository(_repository);
    // this will validate that the passed in repo is a contract
    _upgradeToAndCall(_repository.currentImplementation(), "");
  }

  /// @notice upgrade the proxy implementation
  /// @dev reverts if the repository has not been initialized or if there is no following version
  function upgradeImplementation() external onlyOwner {
    _upgradeImplementation();
  }

  /// @inheritdoc IERC173
  function transferOwnership(address newOwner) external override onlyOwner {
    _setOwner(newOwner);
  }

  /// @inheritdoc IERC173
  function owner() external view override returns (address) {
    return _getOwner();
  }

  /// @notice Returns the associated {Repo}
  ///   contract used for fetching implementations to upgrade to
  function getRepository() external view returns (Repo) {
    return _getRepository();
  }

  // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

  function _upgradeImplementation() internal {
    Repo repo = _getRepository();
    address nextImpl = repo.nextImplementationOf(_implementation());
    bytes memory data = repo.upgradeDataFor(nextImpl);
    _upgradeToAndCall(nextImpl, data);
  }

  /// @dev Returns the current implementation address.
  function _implementation() internal view override returns (address impl) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(_IMPLEMENTATION_SLOT)
    }
  }

  /// @dev Upgrades the proxy to a new implementation.
  //
  /// Emits an {Upgraded} event.
  function _upgradeToAndCall(address newImplementation, bytes memory data) internal virtual {
    _setImplementationAndCall(newImplementation, data);
    emit Upgraded(newImplementation);
  }

  /// @dev Stores a new address in the EIP1967 implementation slot.
  function _setImplementationAndCall(address newImplementation, bytes memory data) internal {
    require(Address.isContract(newImplementation), "no upgrade");

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(_IMPLEMENTATION_SLOT, newImplementation)
    }

    if (data.length > 0) {
      (bool success, ) = newImplementation.delegatecall(data);
      if (!success) {
        assembly {
          // This assembly ensure the revert contains the exact string data
          let returnDataSize := returndatasize()
          returndatacopy(0, 0, returnDataSize)
          revert(0, returnDataSize)
        }
      }
    }
  }

  function _setRepository(Repo newRepository) internal {
    require(Address.isContract(address(newRepository)), "bad repo");
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      sstore(_REPOSITORY_SLOT, newRepository)
    }
  }

  function _getRepository() internal view returns (Repo repo) {
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      repo := sload(_REPOSITORY_SLOT)
    }
  }

  function _getOwner() internal view returns (address adminAddress) {
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      adminAddress := sload(_ADMIN_SLOT)
    }
  }

  function _setOwner(address newOwner) internal {
    address previousOwner = _getOwner();
    // solhint-disable-next-line security/no-inline-assembly
    assembly {
      sstore(_ADMIN_SLOT, newOwner)
    }
    emit OwnershipTransferred(previousOwner, newOwner);
  }

  // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////
  modifier onlyOwner() {
    /// @dev NA: not authorized. not owner
    require(msg.sender == _getOwner(), "NA");
    _;
  }

  // /////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////////

  /// @dev Emitted when the implementation is upgraded.
  event Upgraded(address indexed implementation);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import {IVersioned} from "../../../interfaces/IVersioned.sol";
import {ImplementationRepository as Repo} from "./ImplementationRepository.sol";

contract VersionedImplementationRepository is Repo {
  /// @dev abi encoded version -> implementation address
  /// @dev we use bytes here so only a single storage slot is used
  mapping(bytes => address) internal _byVersion;

  // // EXTERNAL //////////////////////////////////////////////////////////////////

  /// @notice get an implementation by a version tag
  /// @param version `[major, minor, patch]` version tag
  /// @return implementation associated with the given version tag
  function getByVersion(uint8[3] calldata version) external view returns (address) {
    return _byVersion[abi.encodePacked(version)];
  }

  /// @notice check if a version exists
  /// @param version `[major, minor, patch]` version tag
  /// @return true if the version is registered
  function hasVersion(uint8[3] calldata version) external view returns (bool) {
    return _hasVersion(version);
  }

  // // INTERNAL //////////////////////////////////////////////////////////////////

  function _append(address implementation, uint256 lineageId) internal override {
    uint8[3] memory version = IVersioned(implementation).getVersion();
    _insertVersion(version, implementation);
    return super._append(implementation, lineageId);
  }

  function _createLineage(address implementation) internal override returns (uint256) {
    uint8[3] memory version = IVersioned(implementation).getVersion();
    _insertVersion(version, implementation);
    uint256 lineageId = super._createLineage(implementation);
    return lineageId;
  }

  function _remove(address toRemove, address previous) internal override {
    uint8[3] memory version = IVersioned(toRemove).getVersion();
    _removeVersion(version);
    return super._remove(toRemove, previous);
  }

  function _insertVersion(uint8[3] memory version, address impl) internal {
    require(!_hasVersion(version), "exists");
    _byVersion[abi.encodePacked(version)] = impl;
    emit VersionAdded(version, impl);
  }

  function _removeVersion(uint8[3] memory version) internal {
    address toRemove = _byVersion[abi.encode(version)];
    _byVersion[abi.encodePacked(version)] = INVALID_IMPL;
    emit VersionRemoved(version, toRemove);
  }

  function _hasVersion(uint8[3] memory version) internal view returns (bool) {
    return _byVersion[abi.encodePacked(version)] != INVALID_IMPL;
  }

  event VersionAdded(uint8[3] indexed version, address indexed impl);
  event VersionRemoved(uint8[3] indexed version, address indexed impl);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {IFidu} from "../../interfaces/IFidu.sol";
import {ISeniorPoolEpochWithdrawals} from "../../interfaces/ISeniorPoolEpochWithdrawals.sol";
import {IWithdrawalRequestToken} from "../../interfaces/IWithdrawalRequestToken.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {ICUSDCContract} from "../../interfaces/ICUSDCContract.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {Accountant} from "./Accountant.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";

/**
 * @title Goldfinch's SeniorPool contract
 * @notice Main entry point for senior LPs (a.k.a. capital providers)
 *  Automatically invests across borrower pools using an adjustable strategy.
 * @author Goldfinch
 */
contract SeniorPool is BaseUpgradeablePausable, ISeniorPool {
  using SignedSafeMath for int256;
  using Math for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ConfigHelper for GoldfinchConfig;
  using SafeERC20 for IFidu;
  using SafeERC20 for IERC20withDec;

  uint256 internal constant USDC_MANTISSA = 1e6;
  uint256 internal constant FIDU_MANTISSA = 1e18;
  bytes32 public constant ZAPPER_ROLE = keccak256("ZAPPER_ROLE");

  /*================================================================================
    Storage
    ================================================================================*/

  GoldfinchConfig public config;

  /// @dev DEPRECATED!
  uint256 internal compoundBalance;

  /// @dev DEPRECATED, DO NOT USE.
  mapping(ITranchedPool => uint256) internal writedowns;

  /// @dev Writedowns by PoolToken id. This is used to ensure writedowns are incremental.
  ///   Example: At t1, a pool is late and should be written down by 10%. At t2, the pool
  ///   is even later, and should be written down by 25%. This variable helps ensure that
  ///   if writedowns occur at both t1 and t2, t2's writedown is only by the delta of 15%,
  ///   rather than double-counting the writedown percent from t1.
  mapping(uint256 => uint256) public writedownsByPoolToken;

  uint256 internal _checkpointedEpochId;
  mapping(uint256 => Epoch) internal _epochs;
  mapping(uint256 => WithdrawalRequest) internal _withdrawalRequests;
  /// @dev Tracks usdc available for investments, zaps, withdrawal allocations etc. Due to the time
  /// based nature of epochs, if the last epoch has ended but isn't checkpointed yet then this var
  /// doesn't reflect the true usdc available at the current timestamp. To query for the up to date
  /// usdc available without having to execute a tx, use the usdcAvailable() view fn
  uint256 internal _usdcAvailable;
  uint256 internal _epochDuration;

  /*================================================================================
    Initialization Functions
    ================================================================================*/

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );

    __BaseUpgradeablePausable__init(owner);
    _setRoleAdmin(ZAPPER_ROLE, OWNER_ROLE);

    config = _config;
    sharePrice = FIDU_MANTISSA;
    totalLoansOutstanding = 0;
    totalWritedowns = 0;
  }

  /*================================================================================
  Admin Functions
  ================================================================================*/

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev Triggers a checkpoint
   */
  function setEpochDuration(uint256 newEpochDuration) external override onlyAdmin {
    require(newEpochDuration > 0, "Zero duration");
    Epoch storage headEpoch = _applyEpochCheckpoints();
    // When we're updating the epoch duration we need to update the head epoch endsAt
    // time to be the new epoch duration
    if (headEpoch.endsAt > block.timestamp) {
      /*
      This codepath happens when we successfully finalize the previous epoch. This results
      in a timestamp in the future. In this case we need to account for no-op epochs that
      would be created by setting the duration to a value less than the previous epoch.
      */

      uint256 previousEpochEndsAt = headEpoch.endsAt.sub(_epochDuration);
      _epochDuration = newEpochDuration;
      headEpoch.endsAt = _mostRecentEndsAtAfter(previousEpochEndsAt).add(newEpochDuration);
      assert(headEpoch.endsAt > block.timestamp);
    } else {
      headEpoch.endsAt = _mostRecentEndsAtAfter(headEpoch.endsAt).add(newEpochDuration);
    }
    _epochDuration = newEpochDuration;
    emit EpochDurationChanged(newEpochDuration);
  }

  /**
   * @notice Initialize the epoch withdrawal system. This includes writing the
   *          initial epoch and snapshotting usdcAvailable at the current usdc balance of
   *          the senior pool.
   */
  function initializeEpochs() external onlyAdmin {
    require(_epochs[0].endsAt == 0);
    _epochDuration = 2 weeks;
    _usdcAvailable = config.getUSDC().balanceOf(address(this));
    _epochs[0].endsAt = block.timestamp;
    _applyInitializeNextEpochFrom(_epochs[0]);
  }

  /*================================================================================
    LP functions
    ================================================================================*/

  // External Functions
  //--------------------------------------------------------------------------------

  /**
   * @notice Deposits `amount` USDC from msg.sender into the SeniorPool, and grants you the
   *  equivalent value of FIDU tokens
   * @param amount The amount of USDC to deposit
   */
  function deposit(
    uint256 amount
  ) public override whenNotPaused nonReentrant returns (uint256 depositShares) {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(amount > 0, "Must deposit more than zero");
    _applyEpochCheckpoints();
    _usdcAvailable = _usdcAvailable.add(amount);
    // Check if the amount of new shares to be added is within limits
    depositShares = getNumShares(amount);
    emit DepositMade(msg.sender, amount, depositShares);
    require(
      config.getUSDC().transferFrom(msg.sender, address(this), amount),
      "Failed to transfer for deposit"
    );

    config.getFidu().mintTo(msg.sender, depositShares);
    return depositShares;
  }

  /**
   * @notice Identical to deposit, except it allows for a passed up signature to permit
   *  the Senior Pool to move funds on behalf of the user, all within one transaction.
   * @param amount The amount of USDC to deposit
   * @param v secp256k1 signature component
   * @param r secp256k1 signature component
   * @param s secp256k1 signature component
   */
  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override returns (uint256 depositShares) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(amount);
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev Reverts if a withdrawal with the given tokenId does not exist
   * @dev Reverts if the caller is not the owner of the given token
   * @dev Triggers a checkpoint
   */
  function addToWithdrawalRequest(
    uint256 fiduAmount,
    uint256 tokenId
  ) external override whenNotPaused nonReentrant {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    IWithdrawalRequestToken requestTokens = config.getWithdrawalRequestToken();
    require(msg.sender == requestTokens.ownerOf(tokenId), "NA");

    (Epoch storage thisEpoch, WithdrawalRequest storage request) = _applyEpochAndRequestCheckpoints(
      tokenId
    );

    request.fiduRequested = request.fiduRequested.add(fiduAmount);
    thisEpoch.fiduRequested = thisEpoch.fiduRequested.add(fiduAmount);

    emit WithdrawalAddedTo({
      epochId: _checkpointedEpochId,
      tokenId: tokenId,
      operator: msg.sender,
      fiduRequested: fiduAmount
    });

    config.getFidu().safeTransferFrom(msg.sender, address(this), fiduAmount);
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev triggers a checkpoint
   */
  function requestWithdrawal(
    uint256 fiduAmount
  ) external override whenNotPaused nonReentrant returns (uint256) {
    IWithdrawalRequestToken requestTokens = config.getWithdrawalRequestToken();
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(requestTokens.balanceOf(msg.sender) == 0, "Existing request");
    Epoch storage thisEpoch = _applyEpochCheckpoints();

    uint256 tokenId = requestTokens.mint(msg.sender);

    WithdrawalRequest storage request = _withdrawalRequests[tokenId];

    request.epochCursor = _checkpointedEpochId;
    request.fiduRequested = fiduAmount;

    thisEpoch.fiduRequested = thisEpoch.fiduRequested.add(fiduAmount);
    config.getFidu().safeTransferFrom(msg.sender, address(this), fiduAmount);

    emit WithdrawalRequested(_checkpointedEpochId, tokenId, msg.sender, fiduAmount);
    return tokenId;
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev triggers a checkpoint
   */
  function cancelWithdrawalRequest(
    uint256 tokenId
  ) external override whenNotPaused nonReentrant returns (uint256) {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(msg.sender == config.getWithdrawalRequestToken().ownerOf(tokenId), "NA");

    (Epoch storage thisEpoch, WithdrawalRequest storage request) = _applyEpochAndRequestCheckpoints(
      tokenId
    );
    require(request.fiduRequested != 0, "Cant cancel");

    uint256 reserveBps = config.getSeniorPoolWithdrawalCancelationFeeInBps();
    require(reserveBps <= 10_000, "Invalid Bps");
    uint256 reserveFidu = request.fiduRequested.mul(reserveBps).div(10_000);
    uint256 userFidu = request.fiduRequested.sub(reserveFidu);

    thisEpoch.fiduRequested = thisEpoch.fiduRequested.sub(request.fiduRequested);
    request.fiduRequested = 0;

    // only delete the withdraw request if there is no more possible value to be added
    if (request.usdcWithdrawable == 0) {
      _burnWithdrawRequest(tokenId);
    }
    config.getFidu().safeTransfer(msg.sender, userFidu);

    address reserve = config.protocolAdminAddress();
    config.getFidu().safeTransfer(reserve, reserveFidu);

    emit ReserveSharesCollected(msg.sender, reserve, reserveFidu);
    emit WithdrawalCanceled(_checkpointedEpochId, tokenId, msg.sender, userFidu, reserveFidu);
    return userFidu;
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev triggers a checkpoint
   */
  function claimWithdrawalRequest(
    uint256 tokenId
  ) external override whenNotPaused nonReentrant returns (uint256) {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(msg.sender == config.getWithdrawalRequestToken().ownerOf(tokenId), "NA");
    (, WithdrawalRequest storage request) = _applyEpochAndRequestCheckpoints(tokenId);

    uint256 totalUsdcAmount = request.usdcWithdrawable;
    request.usdcWithdrawable = 0;
    uint256 reserveAmount = totalUsdcAmount.div(config.getWithdrawFeeDenominator());
    uint256 userAmount = totalUsdcAmount.sub(reserveAmount);

    // if there is no outstanding FIDU, burn the token
    if (request.fiduRequested == 0) {
      _burnWithdrawRequest(tokenId);
    }

    _sendToReserve(reserveAmount, msg.sender);
    config.getUSDC().safeTransfer(msg.sender, userAmount);

    emit WithdrawalMade(msg.sender, userAmount, reserveAmount);

    return userAmount;
  }

  // view functions
  //--------------------------------------------------------------------------------

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function epochDuration() external view override returns (uint256) {
    return _epochDuration;
  }

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function withdrawalRequest(
    uint256 tokenId
  ) external view override returns (WithdrawalRequest memory) {
    // This call will revert if the tokenId does not exist
    config.getWithdrawalRequestToken().ownerOf(tokenId);
    WithdrawalRequest storage wr = _withdrawalRequests[tokenId];
    return _previewWithdrawRequestCheckpoint(wr);
  }

  // internal view functions
  //--------------------------------------------------------------------------------

  /**
   * @notice Preview the effects of attempting to checkpoint a given epoch. If
   *         the epoch doesn't need to be checkpointed then the same epoch will be return
   *          along with a bool indicated it didn't need to be checkpointed.
   * @param epoch epoch to checkpoint
   * @return maybeCheckpointedEpoch the checkpointed epoch if the epoch was
   *                                  able to be checkpointed, otherwise the same epoch
   * @return epochStatus If the epoch can't be finalized, returns `Unapplied`.
   *                      If the Epoch is after the end time of the epoch the epoch will be extended.
   *                      An extended epoch will have its endTime set to the next endtime but won't
   *                      have any usdc allocated to it. If the epoch can be finalized and its after
   *                      the end time, it will have usdc allocated to it.
   */
  function _previewEpochCheckpoint(
    Epoch memory epoch
  ) internal view returns (Epoch memory, EpochCheckpointStatus) {
    if (block.timestamp < epoch.endsAt) {
      return (epoch, EpochCheckpointStatus.Unapplied);
    }

    // After this point block.timestamp >= epoch.endsAt

    uint256 usdcNeededToFullyLiquidate = _getUSDCAmountFromShares(epoch.fiduRequested);
    epoch.endsAt = _mostRecentEndsAtAfter(epoch.endsAt);
    /*
    If usdc available is zero for an epoch, or the epoch's usdc equivalent
    of its fidu requested is zero, then the epoch is extended instead of finalized.
    Why? Because if usdc available is zero then we can't liquidate any fidu,
    and if the fidu requested is zero (in usdc terms) then there's no need to
    allocate usdc. 
    */
    if (_usdcAvailable == 0 || usdcNeededToFullyLiquidate == 0) {
      // When we extend the epoch, we need to add an additional epoch to the end so that
      // the next time a checkpoint happens it won't immediately finalize the epoch
      epoch.endsAt = epoch.endsAt.add(_epochDuration);
      return (epoch, EpochCheckpointStatus.Extended);
    }

    // finalize epoch
    uint256 usdcAllocated = _usdcAvailable.min(usdcNeededToFullyLiquidate);
    uint256 fiduLiquidated = getNumShares(usdcAllocated);
    epoch.fiduLiquidated = fiduLiquidated;
    epoch.usdcAllocated = usdcAllocated;
    return (epoch, EpochCheckpointStatus.Finalized);
  }

  /// @notice Returns the most recent, uncheckpointed epoch
  function _headEpoch() internal view returns (Epoch storage) {
    return _epochs[_checkpointedEpochId];
  }

  /// @notice Returns the state of a withdraw request after checkpointing
  function _previewWithdrawRequestCheckpoint(
    WithdrawalRequest memory wr
  ) internal view returns (WithdrawalRequest memory) {
    Epoch memory epoch;
    // Iterate through each epoch, calculating the amount of USDC that would be
    // allocated to the withdraw request by using the proportion of FIDU the
    // withdraw request had in that epoch and subtracting the allocation from
    // the withdraw request.
    for (uint256 i = wr.epochCursor; i <= _checkpointedEpochId && wr.fiduRequested > 0; ++i) {
      epoch = _epochs[i];

      // The withdraw request could have FIDU in the most recent, non-finalized-
      // epoch, and so we need to apply the checkpoint to get an accurate count
      if (i == _checkpointedEpochId) {
        (epoch, ) = _previewEpochCheckpoint(epoch);
      }
      uint256 proRataUsdc = epoch.usdcAllocated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      uint256 fiduLiquidated = epoch.fiduLiquidated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      wr.fiduRequested = wr.fiduRequested.sub(fiduLiquidated);
      wr.usdcWithdrawable = wr.usdcWithdrawable.add(proRataUsdc);

      if (epoch.fiduLiquidated != 0) {
        /*
        If the user's outstanding fiduAmount, when claimed, would result in them
        receiving no usdc amount because of loss of precision in conversion we
        just zero out the request so when they claim they don't need to
        unnecessarily iterate through many epochs where they receive nothing.

        The sum of the withdraw request that are "dust" (would result in 0 usdc)
        may result in a non zero usdc allocation at the epoch level. USDC will
        be allocated to these "dusty" requests, but the very small amount of
        usdc will not be claimable by anyone.
        */
        uint256 epochSharePrice = epoch.usdcAllocated.mul(FIDU_MANTISSA).mul(1e12).div(
          epoch.fiduLiquidated
        );
        bool noUsdcValueRemainingInRequest = _getUSDCAmountFromShares(
          wr.fiduRequested,
          epochSharePrice
        ) == 0;
        if (noUsdcValueRemainingInRequest) {
          wr.fiduRequested = 0;
        }
      }
    }
    wr.epochCursor = _checkpointedEpochId;

    return wr;
  }

  /**
   * @notice Returns the most recent time an epoch would end assuming the current epoch duration
   *          and the starting point of `endsAt`.
   * @param endsAt basis for calculating the most recent endsAt time
   * @return mostRecentEndsAt The most recent endsAt
   */
  function _mostRecentEndsAtAfter(uint256 endsAt) internal view returns (uint256) {
    // if multiple epochs have passed since checkpointing, update the endtime
    // and emit many events so that we don't need to write a bunch of useless epochs
    uint256 nopEpochsElapsed = block.timestamp.sub(endsAt).div(_epochDuration);
    // update the last epoch timestamp to the timestamp of the most recently ended epoch
    return endsAt.add(nopEpochsElapsed.mul(_epochDuration));
  }

  // internal functions
  //--------------------------------------------------------------------------------

  function _sendToReserve(uint256 amount, address userForEvent) internal {
    emit ReserveFundsCollected(userForEvent, amount);
    config.getUSDC().safeTransfer(config.reserveAddress(), amount);
  }

  /**
   * @notice Initialize the next epoch using a given epoch by carrying forward its oustanding fidu
   */
  function _applyInitializeNextEpochFrom(
    Epoch storage previousEpoch
  ) internal returns (Epoch storage) {
    _epochs[++_checkpointedEpochId] = _initializeNextEpochFrom(previousEpoch);
    return _epochs[_checkpointedEpochId];
  }

  function _initializeNextEpochFrom(
    Epoch memory previousEpoch
  ) internal view returns (Epoch memory) {
    Epoch memory nextEpoch;
    nextEpoch.endsAt = previousEpoch.endsAt.add(_epochDuration);
    uint256 fiduToCarryOverFromLastEpoch = previousEpoch.fiduRequested.sub(
      previousEpoch.fiduLiquidated
    );
    nextEpoch.fiduRequested = fiduToCarryOverFromLastEpoch;
    return nextEpoch;
  }

  /// @notice Increment _checkpointedEpochId cursor up to the current epoch
  function _applyEpochCheckpoints() private returns (Epoch storage) {
    return _applyEpochCheckpoint(_headEpoch());
  }

  function _applyWithdrawalRequestCheckpoint(
    uint256 tokenId
  ) internal returns (WithdrawalRequest storage) {
    WithdrawalRequest storage wr = _withdrawalRequests[tokenId];
    Epoch storage epoch;

    for (uint256 i = wr.epochCursor; i < _checkpointedEpochId && wr.fiduRequested > 0; i++) {
      epoch = _epochs[i];
      uint256 proRataUsdc = epoch.usdcAllocated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      uint256 fiduLiquidated = epoch.fiduLiquidated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      wr.fiduRequested = wr.fiduRequested.sub(fiduLiquidated);
      wr.usdcWithdrawable = wr.usdcWithdrawable.add(proRataUsdc);

      /*
      If the user's outstanding fiduAmount, when claimed, would result in them
      receiving no usdc amount because of loss of precision in conversion we
      just zero out the request so when they claim they don't need to
      unnecessarily iterate through many epochs where they receive nothing.

      At the epoch level, the sum of the withdraw request that are "dust" (would
      result in 0 usdc) may result in a non zero usdc allocation at the epoch
      level. USDC will be allocated to these "dusty" requests, but the very
      small amount of usdc will not be claimable by anyone.
      */
      uint256 epochSharePrice = epoch.usdcAllocated.mul(FIDU_MANTISSA).mul(1e12).div(
        epoch.fiduLiquidated
      );
      bool noUsdcValueRemainingInRequest = _getUSDCAmountFromShares(
        wr.fiduRequested,
        epochSharePrice
      ) == 0;
      if (noUsdcValueRemainingInRequest) {
        wr.fiduRequested = 0;
      }
    }

    // Update a fully liquidated request's cursor. Otherwise new fiduRequested would be applied to liquidated
    // epochs that the request was not part of.
    wr.epochCursor = _checkpointedEpochId;
    return wr;
  }

  function _applyEpochAndRequestCheckpoints(
    uint256 tokenId
  ) internal returns (Epoch storage, WithdrawalRequest storage) {
    Epoch storage headEpoch = _applyEpochCheckpoints();
    WithdrawalRequest storage wr = _applyWithdrawalRequestCheckpoint(tokenId);
    return (headEpoch, wr);
  }

  /**
   * @notice Checkpoint an epoch, returning the same epoch if it doesn't need
   * to be checkpointed or a newly initialized epoch if the given epoch was
   * successfully checkpointed. In other words, return the most current epoch
   * @dev To decrease storage writes we have introduced optimizations based on two observations
   *      1. If block.timestamp < endsAt, then the epoch is unchanged and we can return
   *       the unmodified epoch (checkpointStatus == Unappled).
   *      2. If the epoch has ended but its fiduRequested is 0 OR the senior pool's usdcAvailable
   *       is 0, then the next epoch will have the SAME fiduRequested, and the only variable we have to update
   *       is endsAt (chekpointStatus == Extended).
   * @param epoch epoch to checkpoint
   * @return currentEpoch current epoch
   */
  function _applyEpochCheckpoint(Epoch storage epoch) internal returns (Epoch storage) {
    (
      Epoch memory checkpointedEpoch,
      EpochCheckpointStatus checkpointStatus
    ) = _previewEpochCheckpoint(epoch);
    if (checkpointStatus == EpochCheckpointStatus.Unapplied) {
      return epoch;
    } else if (checkpointStatus == EpochCheckpointStatus.Extended) {
      uint256 oldEndsAt = epoch.endsAt;
      epoch.endsAt = checkpointedEpoch.endsAt;
      emit EpochExtended(_checkpointedEpochId, epoch.endsAt, oldEndsAt);
      return epoch;
    } else {
      // copy checkpointed data
      epoch.fiduLiquidated = checkpointedEpoch.fiduLiquidated;
      epoch.usdcAllocated = checkpointedEpoch.usdcAllocated;
      epoch.endsAt = checkpointedEpoch.endsAt;

      _usdcAvailable = _usdcAvailable.sub(epoch.usdcAllocated);
      uint256 endingEpochId = _checkpointedEpochId;
      Epoch storage newEpoch = _applyInitializeNextEpochFrom(epoch);
      config.getFidu().burnFrom(address(this), epoch.fiduLiquidated);

      emit EpochEnded(
        endingEpochId,
        epoch.endsAt,
        epoch.fiduRequested,
        epoch.usdcAllocated,
        epoch.fiduLiquidated
      );
      return newEpoch;
    }
  }

  function _burnWithdrawRequest(uint256 tokenId) internal {
    delete _withdrawalRequests[tokenId];
    config.getWithdrawalRequestToken().burn(tokenId);
  }

  /*================================================================================
    Zapper Withdraw
    ================================================================================*/
  /**
   * @notice Withdraws USDC from the SeniorPool to msg.sender, and burns the equivalent value of FIDU tokens
   * @param usdcAmount The amount of USDC to withdraw
   */
  function withdraw(
    uint256 usdcAmount
  ) external override whenNotPaused nonReentrant onlyZapper returns (uint256 amount) {
    require(usdcAmount > 0, "Must withdraw more than zero");
    uint256 withdrawShares = getNumShares(usdcAmount);
    return _withdraw(usdcAmount, withdrawShares);
  }

  /**
   * @notice Withdraws USDC (denominated in FIDU terms) from the SeniorPool to msg.sender
   * @param fiduAmount The amount of USDC to withdraw in terms of FIDU shares
   */
  function withdrawInFidu(
    uint256 fiduAmount
  ) external override whenNotPaused nonReentrant onlyZapper returns (uint256 amount) {
    require(fiduAmount > 0, "Must withdraw more than zero");
    uint256 usdcAmount = _getUSDCAmountFromShares(fiduAmount);
    uint256 withdrawShares = fiduAmount;
    return _withdraw(usdcAmount, withdrawShares);
  }

  // Zapper Withdraw: Internal functions
  //--------------------------------------------------------------------------------
  function _withdraw(
    uint256 usdcAmount,
    uint256 withdrawShares
  ) internal returns (uint256 userAmount) {
    _applyEpochCheckpoints();
    IFidu fidu = config.getFidu();
    // Determine current shares the address has and the shares requested to withdraw
    uint256 currentShares = fidu.balanceOf(msg.sender);
    // Ensure the address has enough value in the pool
    require(
      withdrawShares <= currentShares,
      "Amount requested is greater than what this address owns"
    );

    _usdcAvailable = _usdcAvailable.sub(usdcAmount, "IB");
    // Send to reserves
    userAmount = usdcAmount;

    // Send to user
    config.getUSDC().safeTransfer(msg.sender, usdcAmount);

    // Burn the shares
    fidu.burnFrom(msg.sender, withdrawShares);

    emit WithdrawalMade(msg.sender, userAmount, 0);

    return userAmount;
  }

  /*================================================================================
    Asset Management
    ----------------
    functions related to investing, writing off, and redeeming assets
    ================================================================================*/

  // External functions
  //--------------------------------------------------------------------------------

  /**
   * @notice Invest in an ITranchedPool's senior tranche using the senior pool's strategy
   * @param pool An ITranchedPool whose senior tranche should be considered for investment
   */
  function invest(
    ITranchedPool pool
  ) external override whenNotPaused nonReentrant returns (uint256) {
    require(_isValidPool(pool), "Pool must be valid");
    _applyEpochCheckpoints();

    ISeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    uint256 amount = strategy.invest(this, pool);

    require(amount > 0, "Investment amount must be positive");
    require(amount <= _usdcAvailable, "not enough usdc");

    _usdcAvailable = _usdcAvailable.sub(amount);

    _approvePool(pool, amount);
    uint256 nSlices = pool.numSlices();
    require(nSlices >= 1, "Pool has no slices");
    uint256 sliceIndex = nSlices.sub(1);
    uint256 seniorTrancheId = _sliceIndexToSeniorTrancheId(sliceIndex);
    totalLoansOutstanding = totalLoansOutstanding.add(amount);
    uint256 poolToken = pool.deposit(seniorTrancheId, amount);

    emit InvestmentMadeInSenior(address(pool), amount);

    return poolToken;
  }

  /**
   * @notice Redeem interest and/or principal from an ITranchedPool investment
   * @param tokenId the ID of an IPoolTokens token to be redeemed
   * @dev triggers a checkpoint
   */
  function redeem(uint256 tokenId) external override whenNotPaused nonReentrant {
    _applyEpochCheckpoints();
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    (uint256 interestRedeemed, uint256 principalRedeemed) = pool.withdrawMax(tokenId);

    _collectInterestAndPrincipal(address(pool), interestRedeemed, principalRedeemed);
  }

  /**
   * @notice Write down an ITranchedPool investment. This will adjust the senior pool's share price
   *  down if we're considering the investment a loss, or up if the borrower has subsequently
   *  made repayments that restore confidence that the full loan will be repaid.
   * @param tokenId the ID of an IPoolTokens token to be considered for writedown
   * @dev triggers a checkpoint
   */
  function writedown(uint256 tokenId) external override whenNotPaused nonReentrant {
    IPoolTokens poolTokens = config.getPoolTokens();
    require(
      address(this) == poolTokens.ownerOf(tokenId),
      "Only tokens owned by the senior pool can be written down"
    );

    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    require(_isValidPool(pool), "Pool must be valid");
    _applyEpochCheckpoints();

    // Assess the pool first in case it has unapplied USDC in its credit line
    pool.assess();

    uint256 principalRemaining = tokenInfo.principalAmount.sub(tokenInfo.principalRedeemed);

    (uint256 writedownPercent, uint256 writedownAmount) = _calculateWritedown(
      pool,
      principalRemaining
    );

    uint256 prevWritedownAmount = writedownsByPoolToken[tokenId];

    if (writedownPercent == 0 && prevWritedownAmount == 0) {
      return;
    }

    int256 writedownDelta = prevWritedownAmount.toInt256().sub(writedownAmount.toInt256());
    writedownsByPoolToken[tokenId] = writedownAmount;
    _distributeLosses(writedownDelta);
    if (writedownDelta > 0) {
      // If writedownDelta is positive, that means we got money back. So subtract from totalWritedowns.
      totalWritedowns = totalWritedowns.sub(writedownDelta.toUint256());
    } else {
      totalWritedowns = totalWritedowns.add((writedownDelta * -1).toUint256());
    }
    emit PrincipalWrittenDown(address(pool), writedownDelta);
  }

  // View Functions
  //--------------------------------------------------------------------------------

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function usdcAvailable() public view override returns (uint256) {
    (Epoch memory e, ) = _previewEpochCheckpoint(_headEpoch());
    uint256 usdcThatWillBeAllocatedToLatestEpoch = e.usdcAllocated;
    return _usdcAvailable.sub(usdcThatWillBeAllocatedToLatestEpoch);
  }

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function currentEpoch() external view override returns (Epoch memory) {
    (Epoch memory e, EpochCheckpointStatus checkpointStatus) = _previewEpochCheckpoint(
      _headEpoch()
    );
    if (checkpointStatus == EpochCheckpointStatus.Finalized) e = _initializeNextEpochFrom(e);
    return e;
  }

  /**
   * @notice Returns the net assests controlled by and owed to the pool
   */
  function assets() external view override returns (uint256) {
    return usdcAvailable().add(totalLoansOutstanding).sub(totalWritedowns);
  }

  /**
   * @notice Returns the number of shares outstanding, accounting for shares that will be burned
   *          when an epoch checkpoint happens
   */
  function sharesOutstanding() external view override returns (uint256) {
    (Epoch memory e, ) = _previewEpochCheckpoint(_headEpoch());
    uint256 fiduThatWillBeBurnedOnCheckpoint = e.fiduLiquidated;
    return config.getFidu().totalSupply().sub(fiduThatWillBeBurnedOnCheckpoint);
  }

  function getNumShares(uint256 usdcAmount) public view override returns (uint256) {
    return _getNumShares(usdcAmount, sharePrice);
  }

  function estimateInvestment(ITranchedPool pool) external view override returns (uint256) {
    require(_isValidPool(pool), "Pool must be valid");
    ISeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    return strategy.estimateInvestment(this, pool);
  }

  /**
   * @notice Calculates the writedown amount for a particular pool position
   * @param tokenId The token reprsenting the position
   * @return The amount in dollars the principal should be written down by
   */
  function calculateWritedown(uint256 tokenId) external view override returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    ITranchedPool pool = ITranchedPool(tokenInfo.pool);

    uint256 principalRemaining = tokenInfo.principalAmount.sub(tokenInfo.principalRedeemed);

    (, uint256 writedownAmount) = _calculateWritedown(pool, principalRemaining);
    return writedownAmount;
  }

  // Internal functions
  //--------------------------------------------------------------------------------

  function _getNumShares(uint256 _usdcAmount, uint256 _sharePrice) internal pure returns (uint256) {
    return _usdcToFidu(_usdcAmount).mul(FIDU_MANTISSA).div(_sharePrice);
  }

  function _calculateWritedown(
    ITranchedPool pool,
    uint256 principal
  ) internal view returns (uint256 writedownPercent, uint256 writedownAmount) {
    return
      Accountant.calculateWritedownForPrincipal(
        pool.creditLine(),
        principal,
        block.timestamp,
        config.getLatenessGracePeriodInDays(),
        config.getLatenessMaxDays()
      );
  }

  function _distributeLosses(int256 writedownDelta) internal {
    _applyEpochCheckpoints();
    if (writedownDelta > 0) {
      uint256 delta = _usdcToSharePrice(writedownDelta.toUint256());
      sharePrice = sharePrice.add(delta);
    } else {
      // If delta is negative, convert to positive uint, and sub from sharePrice
      uint256 delta = _usdcToSharePrice((writedownDelta * -1).toUint256());
      sharePrice = sharePrice.sub(delta);
    }
  }

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal {
    uint256 increment = _usdcToSharePrice(interest);
    sharePrice = sharePrice.add(increment);

    if (interest > 0) {
      emit InterestCollected(from, interest);
    }
    if (principal > 0) {
      emit PrincipalCollected(from, principal);
      totalLoansOutstanding = totalLoansOutstanding.sub(principal);
    }
    _usdcAvailable = _usdcAvailable.add(interest).add(principal);
  }

  function _isValidPool(ITranchedPool pool) internal view returns (bool) {
    return config.getPoolTokens().validPool(address(pool));
  }

  function _approvePool(ITranchedPool pool, uint256 allowance) internal {
    IERC20withDec usdc = config.getUSDC();
    require(usdc.approve(address(pool), allowance));
  }

  /*================================================================================
    General Internal Functions
    ================================================================================*/

  function _usdcToFidu(uint256 amount) internal pure returns (uint256) {
    return amount.mul(FIDU_MANTISSA).div(USDC_MANTISSA);
  }

  function _fiduToUsdc(uint256 amount) internal pure returns (uint256) {
    return amount.div(FIDU_MANTISSA.div(USDC_MANTISSA));
  }

  function _getUSDCAmountFromShares(uint256 fiduAmount) internal view returns (uint256) {
    return _getUSDCAmountFromShares(fiduAmount, sharePrice);
  }

  function _getUSDCAmountFromShares(
    uint256 _fiduAmount,
    uint256 _sharePrice
  ) internal pure returns (uint256) {
    return _fiduToUsdc(_fiduAmount.mul(_sharePrice)).div(FIDU_MANTISSA);
  }

  function _usdcToSharePrice(uint256 usdcAmount) internal view returns (uint256) {
    return _usdcToFidu(usdcAmount).mul(FIDU_MANTISSA).div(_totalShares());
  }

  function _totalShares() internal view returns (uint256) {
    return config.getFidu().totalSupply();
  }

  /// @notice Returns the senion tranche id for the given slice index
  /// @param index slice index
  /// @return senior tranche id of given slice index
  function _sliceIndexToSeniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.mul(2).add(1);
  }

  modifier onlyZapper() {
    require(hasRole(ZAPPER_ROLE, msg.sender), "Not Zapper");
    _;
  }

  enum EpochCheckpointStatus {
    Unapplied,
    Extended,
    Finalized
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IRequiresUID} from "../../interfaces/IRequiresUID.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {IV2CreditLine} from "../../interfaces/IV2CreditLine.sol";
import {IBackerRewards} from "../../interfaces/IBackerRewards.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {IVersioned} from "../../interfaces/IVersioned.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {SafeERC20Transfer} from "../../library/SafeERC20Transfer.sol";
import {TranchingLogic} from "./TranchingLogic.sol";

contract TranchedPool is BaseUpgradeablePausable, ITranchedPool, IRequiresUID, IVersioned {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using TranchingLogic for PoolSlice;
  using TranchingLogic for TrancheInfo;
  using SafeERC20Transfer for IERC20withDec;

  bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
  bytes32 public constant SENIOR_ROLE = keccak256("SENIOR_ROLE");
  uint8 internal constant MAJOR_VERSION = 0;
  uint8 internal constant MINOR_VERSION = 1;
  uint8 internal constant PATCH_VERSION = 0;
  uint256 public juniorFeePercent;
  bool public drawdownsPaused;
  uint256[] public allowedUIDTypes;
  uint256 public totalDeployed;
  uint256 public fundableAt;

  mapping(uint256 => PoolSlice) internal _poolSlices;
  uint256 public override numSlices;

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public override initializer {
    require(address(_config) != address(0) && address(_borrower) != address(0), "ZERO");

    config = GoldfinchConfig(_config);
    address owner = config.protocolAdminAddress();
    __BaseUpgradeablePausable__init(owner);
    _initializeNextSlice(_fundableAt);
    _createAndSetCreditLine(
      _borrower,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );

    createdAt = block.timestamp;
    juniorFeePercent = _juniorFeePercent;
    if (_allowedUIDTypes.length == 0) {
      uint256[1] memory defaultAllowedUIDTypes = [config.getGo().ID_TYPE_0()];
      allowedUIDTypes = defaultAllowedUIDTypes;
    } else {
      allowedUIDTypes = _allowedUIDTypes;
    }

    _setupRole(LOCKER_ROLE, _borrower);
    _setupRole(LOCKER_ROLE, owner);
    _setRoleAdmin(LOCKER_ROLE, OWNER_ROLE);
    _setRoleAdmin(SENIOR_ROLE, OWNER_ROLE);

    // Give the senior pool the ability to deposit into the senior pool
    _setupRole(SENIOR_ROLE, address(config.getSeniorPool()));

    // Unlock self for infinite amount
    require(config.getUSDC().approve(address(this), uint256(-1)));
  }

  function setAllowedUIDTypes(uint256[] calldata ids) external onlyLocker {
    require(
      _poolSlices[0].juniorTranche.principalDeposited == 0 &&
        _poolSlices[0].seniorTranche.principalDeposited == 0,
      "has balance"
    );
    allowedUIDTypes = ids;
  }

  function getAllowedUIDTypes() external view override returns (uint256[] memory) {
    return allowedUIDTypes;
  }

  /**
   * @notice Deposit a USDC amount into the pool for a tranche. Mints an NFT to the caller representing the position
   * @param tranche The number representing the tranche to deposit into
   * @param amount The USDC amount to tranfer from the caller to the pool
   * @return tokenId The tokenId of the NFT
   */
  function deposit(
    uint256 tranche,
    uint256 amount
  ) public override nonReentrant whenNotPaused returns (uint256) {
    TrancheInfo storage trancheInfo = _getTrancheInfo(tranche);
    /// @dev TL: tranche locked
    require(trancheInfo.lockedUntil == 0, "TL");
    /// @dev IA: invalid amount
    require(amount > 0, "IA");
    /// @dev NA: not authorized. Must have correct UID or be go listed
    require(hasAllowedUID(msg.sender), "NA");
    require(block.timestamp >= fundableAt, "Not open");
    // senior tranche ids are always odd numbered
    if (TranchingLogic.isSeniorTrancheId(trancheInfo.id)) {
      require(hasRole(SENIOR_ROLE, _msgSender()), "NA");
    }

    trancheInfo.principalDeposited = trancheInfo.principalDeposited.add(amount);
    uint256 tokenId = config.getPoolTokens().mint(
      IPoolTokens.MintParams({tranche: tranche, principalAmount: amount}),
      msg.sender
    );

    config.getUSDC().safeERC20TransferFrom(msg.sender, address(this), amount);
    emit DepositMade(msg.sender, tranche, tokenId, amount);
    return tokenId;
  }

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override returns (uint256 tokenId) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(tranche, amount);
  }

  /**
   * @notice Withdraw an already deposited amount if the funds are available
   * @param tokenId The NFT representing the position
   * @param amount The amount to withdraw (must be <= interest+principal currently available to withdraw)
   * @return interestWithdrawn The interest amount that was withdrawn
   * @return principalWithdrawn The principal amount that was withdrawn
   */
  function withdraw(
    uint256 tokenId,
    uint256 amount
  ) public override nonReentrant whenNotPaused returns (uint256, uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = _getTrancheInfo(tokenInfo.tranche);

    return _withdraw(trancheInfo, tokenInfo, tokenId, amount);
  }

  /**
   * @notice Withdraw from many tokens (that the sender owns) in a single transaction
   * @param tokenIds An array of tokens ids representing the position
   * @param amounts An array of amounts to withdraw from the corresponding tokenIds
   */
  function withdrawMultiple(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) public override {
    require(tokenIds.length == amounts.length, "LEN");

    for (uint256 i = 0; i < amounts.length; i++) {
      withdraw(tokenIds[i], amounts[i]);
    }
  }

  /**
   * @notice Similar to withdraw but will withdraw all available funds
   * @param tokenId The NFT representing the position
   * @return interestWithdrawn The interest amount that was withdrawn
   * @return principalWithdrawn The principal amount that was withdrawn
   */
  function withdrawMax(
    uint256 tokenId
  )
    external
    override
    nonReentrant
    whenNotPaused
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = _getTrancheInfo(tokenInfo.tranche);

    (uint256 interestRedeemable, uint256 principalRedeemable) = TranchingLogic
      .redeemableInterestAndPrincipal(trancheInfo, tokenInfo);

    uint256 amount = interestRedeemable.add(principalRedeemable);

    return _withdraw(trancheInfo, tokenInfo, tokenId, amount);
  }

  /**
   * @notice Draws down the funds (and locks the pool) to the borrower address. Can only be called by the borrower
   * @param amount The amount to drawdown from the creditline (must be < limit)
   */
  function drawdown(uint256 amount) external override onlyLocker whenNotPaused {
    /// @dev DP: drawdowns paused
    require(!drawdownsPaused, "DP");
    if (!_locked()) {
      // Assumes the senior pool has invested already (saves the borrower a separate transaction to lock the pool)
      _lockPool();
    }
    // Drawdown only draws down from the current slice for simplicity. It's harder to account for how much
    // money is available from previous slices since depositors can redeem after unlock.
    PoolSlice storage currentSlice = _poolSlices[numSlices - 1];
    uint256 amountAvailable = TranchingLogic.sharePriceToUsdc(
      currentSlice.juniorTranche.principalSharePrice,
      currentSlice.juniorTranche.principalDeposited
    );
    amountAvailable = amountAvailable.add(
      TranchingLogic.sharePriceToUsdc(
        currentSlice.seniorTranche.principalSharePrice,
        currentSlice.seniorTranche.principalDeposited
      )
    );

    /// @dev IF: insufficient funds
    require(amount <= amountAvailable, "IF");

    creditLine.drawdown(amount);

    // Update the share price to reflect the amount remaining in the pool
    uint256 amountRemaining = amountAvailable.sub(amount);
    uint256 oldJuniorPrincipalSharePrice = currentSlice.juniorTranche.principalSharePrice;
    uint256 oldSeniorPrincipalSharePrice = currentSlice.seniorTranche.principalSharePrice;
    currentSlice.juniorTranche.principalSharePrice = currentSlice
      .juniorTranche
      .calculateExpectedSharePrice(amountRemaining, currentSlice);
    currentSlice.seniorTranche.principalSharePrice = currentSlice
      .seniorTranche
      .calculateExpectedSharePrice(amountRemaining, currentSlice);
    currentSlice.principalDeployed = currentSlice.principalDeployed.add(amount);
    totalDeployed = totalDeployed.add(amount);

    address borrower = creditLine.borrower();
    IBackerRewards backerRewards = IBackerRewards(config.backerRewardsAddress());
    backerRewards.onTranchedPoolDrawdown(numSlices - 1);
    config.getUSDC().safeERC20TransferFrom(address(this), borrower, amount);
    emit DrawdownMade(borrower, amount);
    emit SharePriceUpdated(
      address(this),
      currentSlice.juniorTranche.id,
      currentSlice.juniorTranche.principalSharePrice,
      int256(oldJuniorPrincipalSharePrice.sub(currentSlice.juniorTranche.principalSharePrice)) * -1,
      currentSlice.juniorTranche.interestSharePrice,
      0
    );
    emit SharePriceUpdated(
      address(this),
      currentSlice.seniorTranche.id,
      currentSlice.seniorTranche.principalSharePrice,
      int256(oldSeniorPrincipalSharePrice.sub(currentSlice.seniorTranche.principalSharePrice)) * -1,
      currentSlice.seniorTranche.interestSharePrice,
      0
    );
  }

  function NUM_TRANCHES_PER_SLICE() external pure returns (uint256) {
    return TranchingLogic.NUM_TRANCHES_PER_SLICE;
  }

  /**
   * @notice Locks the junior tranche, preventing more junior deposits. Gives time for the senior to determine how
   * much to invest (ensure leverage ratio cannot change for the period)
   */
  function lockJuniorCapital() external override onlyLocker whenNotPaused {
    _lockJuniorCapital(numSlices.sub(1));
  }

  /**
   * @notice Locks the pool (locks both senior and junior tranches and starts the drawdown period). Beyond the drawdown
   * period, any unused capital is available to withdraw by all depositors
   */
  function lockPool() external override onlyLocker whenNotPaused {
    _lockPool();
  }

  function setFundableAt(uint256 newFundableAt) external override onlyLocker {
    fundableAt = newFundableAt;
  }

  function initializeNextSlice(uint256 _fundableAt) external override onlyLocker whenNotPaused {
    /// @dev NL: not locked
    require(_locked(), "NL");
    /// @dev LP: late payment
    require(!creditLine.isLate(), "LP");
    /// @dev GP: beyond principal grace period
    require(creditLine.withinPrincipalGracePeriod(), "GP");
    _initializeNextSlice(_fundableAt);
    emit SliceCreated(address(this), numSlices.sub(1));
  }

  /**
   * @notice Triggers an assessment of the creditline and the applies the payments according the tranche waterfall
   */
  function assess() external override whenNotPaused {
    _assess();
  }

  /**
   * @notice Allows repaying the creditline. Collects the USDC amount from the sender and triggers an assess
   * @param amount The amount to repay
   */
  function pay(uint256 amount) external override whenNotPaused {
    /// @dev  IA: cannot pay 0
    require(amount > 0, "IA");
    config.getUSDC().safeERC20TransferFrom(msg.sender, address(creditLine), amount);
    _assess();
  }

  /**
   * @notice Pauses the pool and sweeps any remaining funds to the treasury reserve.
   */
  function emergencyShutdown() public onlyAdmin {
    if (!paused()) {
      pause();
    }

    IERC20withDec usdc = config.getUSDC();
    address reserveAddress = config.reserveAddress();
    // Sweep any funds to community reserve
    uint256 poolBalance = usdc.balanceOf(address(this));
    if (poolBalance > 0) {
      config.getUSDC().safeERC20Transfer(reserveAddress, poolBalance);
    }

    uint256 clBalance = usdc.balanceOf(address(creditLine));
    if (clBalance > 0) {
      usdc.safeERC20TransferFrom(address(creditLine), reserveAddress, clBalance);
    }
    emit EmergencyShutdown(address(this));
  }

  /**
   * @notice Pauses all drawdowns (but not deposits/withdraws)
   */
  function pauseDrawdowns() public onlyAdmin {
    drawdownsPaused = true;
    emit DrawdownsPaused(address(this));
  }

  /**
   * @notice Unpause drawdowns
   */
  function unpauseDrawdowns() public onlyAdmin {
    drawdownsPaused = false;
    emit DrawdownsUnpaused(address(this));
  }

  /**
   * @notice Migrates the accounting variables from the current creditline to a brand new one
   * @param _borrower The borrower address
   * @param _maxLimit The new max limit
   * @param _interestApr The new interest APR
   * @param _paymentPeriodInDays The new payment period in days
   * @param _termInDays The new term in days
   * @param _lateFeeApr The new late fee APR
   */
  function migrateCreditLine(
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public onlyAdmin {
    require(_borrower != address(0) && _paymentPeriodInDays != 0 && _termInDays != 0, "ZERO");

    IV2CreditLine originalCl = creditLine;

    _createAndSetCreditLine(
      _borrower,
      _maxLimit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );

    TranchingLogic.migrateAccountingVariables(originalCl, creditLine);
    TranchingLogic.closeCreditLine(originalCl);
    address originalBorrower = originalCl.borrower();
    address newBorrower = creditLine.borrower();

    // Ensure Roles
    if (originalBorrower != newBorrower) {
      revokeRole(LOCKER_ROLE, originalBorrower);
      grantRole(LOCKER_ROLE, newBorrower);
    }
    // Transfer any funds to new CL
    uint256 clBalance = config.getUSDC().balanceOf(address(originalCl));
    if (clBalance > 0) {
      config.getUSDC().safeERC20TransferFrom(address(originalCl), address(creditLine), clBalance);
    }
    emit CreditLineMigrated(originalCl, creditLine);
  }

  // CreditLine proxy method
  function setLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setLimit(newAmount);
  }

  function setMaxLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setMaxLimit(newAmount);
  }

  function getTranche(uint256 tranche) public view override returns (TrancheInfo memory) {
    return _getTrancheInfo(tranche);
  }

  function poolSlices(uint256 index) external view override returns (PoolSlice memory) {
    return _poolSlices[index];
  }

  /**
   * @notice Returns the total junior capital deposited
   * @return The total USDC amount deposited into all junior tranches
   */
  function totalJuniorDeposits() external view override returns (uint256) {
    uint256 total;
    for (uint256 i = 0; i < numSlices; i++) {
      total = total.add(_poolSlices[i].juniorTranche.principalDeposited);
    }
    return total;
  }

  /**
   * @notice Determines the amount of interest and principal redeemable by a particular tokenId
   * @param tokenId The token representing the position
   * @return interestRedeemable The interest available to redeem
   * @return principalRedeemable The principal available to redeem
   */
  function availableToWithdraw(uint256 tokenId) public view override returns (uint256, uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = _getTrancheInfo(tokenInfo.tranche);

    if (block.timestamp > trancheInfo.lockedUntil) {
      return TranchingLogic.redeemableInterestAndPrincipal(trancheInfo, tokenInfo);
    } else {
      return (0, 0);
    }
  }

  function hasAllowedUID(address sender) public view override returns (bool) {
    return config.getGo().goOnlyIdTypes(sender, allowedUIDTypes);
  }

  /* Internal functions  */

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal returns (uint256) {
    uint256 totalReserveAmount = TranchingLogic.applyToAllSlices(
      _poolSlices,
      numSlices,
      interest,
      principal,
      uint256(100).div(config.getReserveDenominator()), // Convert the denonminator to percent
      totalDeployed,
      creditLine,
      juniorFeePercent
    );

    config.getUSDC().safeERC20TransferFrom(from, address(this), principal.add(interest));
    config.getUSDC().safeERC20TransferFrom(
      address(this),
      config.reserveAddress(),
      totalReserveAmount
    );

    emit ReserveFundsCollected(address(this), totalReserveAmount);

    return totalReserveAmount;
  }

  function _createAndSetCreditLine(
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) internal {
    creditLine = IV2CreditLine(config.getGoldfinchFactory().createCreditLine());
    creditLine.initialize(
      address(config),
      address(this), // Set self as the owner
      _borrower,
      _maxLimit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );
  }

  // // Internal //////////////////////////////////////////////////////////////////

  function _withdraw(
    TrancheInfo storage trancheInfo,
    IPoolTokens.TokenInfo memory tokenInfo,
    uint256 tokenId,
    uint256 amount
  ) internal returns (uint256, uint256) {
    /// @dev NA: not authorized
    require(
      config.getPoolTokens().isApprovedOrOwner(msg.sender, tokenId) && hasAllowedUID(msg.sender),
      "NA"
    );
    /// @dev IA: invalid amount. Cannot withdraw 0
    require(amount > 0, "IA");
    (uint256 interestRedeemable, uint256 principalRedeemable) = TranchingLogic
      .redeemableInterestAndPrincipal(trancheInfo, tokenInfo);
    uint256 netRedeemable = interestRedeemable.add(principalRedeemable);

    /// @dev IA: invalid amount. User does not have enough available to redeem
    require(amount <= netRedeemable, "IA");
    /// @dev TL: Tranched Locked
    require(block.timestamp > trancheInfo.lockedUntil, "TL");

    uint256 interestToRedeem = 0;
    uint256 principalToRedeem = 0;

    // If the tranche has not been locked, ensure the deposited amount is correct
    if (trancheInfo.lockedUntil == 0) {
      trancheInfo.principalDeposited = trancheInfo.principalDeposited.sub(amount);

      principalToRedeem = amount;

      config.getPoolTokens().withdrawPrincipal(tokenId, principalToRedeem);
    } else {
      interestToRedeem = Math.min(interestRedeemable, amount);
      principalToRedeem = Math.min(principalRedeemable, amount.sub(interestToRedeem));

      config.getPoolTokens().redeem(tokenId, principalToRedeem, interestToRedeem);
    }

    config.getUSDC().safeERC20TransferFrom(
      address(this),
      msg.sender,
      principalToRedeem.add(interestToRedeem)
    );

    emit WithdrawalMade(
      msg.sender,
      tokenInfo.tranche,
      tokenId,
      interestToRedeem,
      principalToRedeem
    );

    return (interestToRedeem, principalToRedeem);
  }

  function _lockJuniorCapital(uint256 sliceId) internal {
    /// @dev TL: tranch locked
    require(!_locked() && _poolSlices[sliceId].juniorTranche.lockedUntil == 0, "TL");

    TranchingLogic.lockTranche(_poolSlices[sliceId].juniorTranche, config);
  }

  function _lockPool() internal {
    PoolSlice storage slice = _poolSlices[numSlices.sub(1)];
    /// @dev NL: Not locked
    require(slice.juniorTranche.lockedUntil > 0, "NL");
    // Allow locking the pool only once; do not allow extending the lock of an
    // already-locked pool. Otherwise the locker could keep the pool locked
    // indefinitely, preventing withdrawals.
    /// @dev TL: tranche locked. The senior pool has already been locked.
    require(slice.seniorTranche.lockedUntil == 0, "TL");

    uint256 currentTotal = slice.juniorTranche.principalDeposited.add(
      slice.seniorTranche.principalDeposited
    );
    creditLine.setLimit(Math.min(creditLine.limit().add(currentTotal), creditLine.maxLimit()));

    // We start the drawdown period, so backers can withdraw unused capital after borrower draws down
    TranchingLogic.lockTranche(slice.juniorTranche, config);
    TranchingLogic.lockTranche(slice.seniorTranche, config);
  }

  function _initializeNextSlice(uint256 newFundableAt) internal {
    /// @dev SL: slice limit
    require(numSlices < 5, "SL");
    TranchingLogic.initializeNextSlice(_poolSlices, numSlices);
    numSlices = numSlices.add(1);
    fundableAt = newFundableAt;
  }

  // If the senior tranche of the current slice is locked, then the pool is not open to any more deposits
  // (could throw off leverage ratio)
  function _locked() internal view returns (bool) {
    return numSlices == 0 || _poolSlices[numSlices - 1].seniorTranche.lockedUntil > 0;
  }

  function _getTrancheInfo(uint256 trancheId) internal view returns (TrancheInfo storage) {
    require(
      trancheId > 0 && trancheId <= numSlices.mul(TranchingLogic.NUM_TRANCHES_PER_SLICE),
      "invalid tranche"
    );
    uint256 sliceId = TranchingLogic.trancheIdToSliceIndex(trancheId);
    PoolSlice storage slice = _poolSlices[sliceId];
    TrancheInfo storage trancheInfo = TranchingLogic.isSeniorTrancheId(trancheId)
      ? slice.seniorTranche
      : slice.juniorTranche;
    return trancheInfo;
  }

  function _assess() internal {
    // We need to make sure the pool is locked before we allocate rewards to ensure it's not
    // possible to game rewards by sandwiching an interest payment to an unlocked pool
    // It also causes issues trying to allocate payments to an empty slice (divide by zero)
    /// @dev NL: not locked
    require(_locked(), "NL");

    uint256 interestAccrued = creditLine.totalInterestAccrued();
    (uint256 paymentRemaining, uint256 interestPayment, uint256 principalPayment) = creditLine
      .assess();
    interestAccrued = creditLine.totalInterestAccrued().sub(interestAccrued);

    // Split the interest accrued proportionally across slices so we know how much interest goes to each slice
    // We need this because the slice start at different times, so we cannot retroactively allocate the interest
    // linearly
    uint256[] memory principalPaymentsPerSlice = new uint256[](numSlices);
    for (uint256 i = 0; i < numSlices; i++) {
      uint256 interestForSlice = TranchingLogic.scaleByFraction(
        interestAccrued,
        _poolSlices[i].principalDeployed,
        totalDeployed
      );
      principalPaymentsPerSlice[i] = TranchingLogic.scaleByFraction(
        principalPayment,
        _poolSlices[i].principalDeployed,
        totalDeployed
      );
      _poolSlices[i].totalInterestAccrued = _poolSlices[i].totalInterestAccrued.add(
        interestForSlice
      );
    }

    if (interestPayment > 0 || principalPayment > 0) {
      uint256 reserveAmount = _collectInterestAndPrincipal(
        address(creditLine),
        interestPayment,
        principalPayment.add(paymentRemaining)
      );

      for (uint256 i = 0; i < numSlices; i++) {
        _poolSlices[i].principalDeployed = _poolSlices[i].principalDeployed.sub(
          principalPaymentsPerSlice[i]
        );
        totalDeployed = totalDeployed.sub(principalPaymentsPerSlice[i]);
      }

      config.getBackerRewards().allocateRewards(interestPayment);

      emit PaymentApplied(
        creditLine.borrower(),
        address(this),
        interestPayment,
        principalPayment,
        paymentRemaining,
        reserveAmount
      );
    }
    emit TranchedPoolAssessed(address(this));
  }

  // // Events ////////////////////////////////////////////////////////////////////

  event DepositMade(
    address indexed owner,
    uint256 indexed tranche,
    uint256 indexed tokenId,
    uint256 amount
  );
  event WithdrawalMade(
    address indexed owner,
    uint256 indexed tranche,
    uint256 indexed tokenId,
    uint256 interestWithdrawn,
    uint256 principalWithdrawn
  );

  event TranchedPoolAssessed(address indexed pool);
  event PaymentApplied(
    address indexed payer,
    address indexed pool,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount,
    uint256 reserveAmount
  );
  // Note: This has to exactly match the even in the TranchingLogic library for events to be emitted
  // correctly
  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );
  event ReserveFundsCollected(address indexed from, uint256 amount);
  event CreditLineMigrated(
    IV2CreditLine indexed oldCreditLine,
    IV2CreditLine indexed newCreditLine
  );
  event DrawdownMade(address indexed borrower, uint256 amount);
  event DrawdownsPaused(address indexed pool);
  event DrawdownsUnpaused(address indexed pool);
  event EmergencyShutdown(address indexed pool);
  event TrancheLocked(address indexed pool, uint256 trancheId, uint256 lockedUntil);
  event SliceCreated(address indexed pool, uint256 sliceId);

  // // Modifiers /////////////////////////////////////////////////////////////////

  /// @inheritdoc IVersioned
  function getVersion() external pure override returns (uint8[3] memory version) {
    (version[0], version[1], version[2]) = (MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION);
  }

  modifier onlyLocker() {
    /// @dev NA: not authorized. not locker
    require(hasRole(LOCKER_ROLE, msg.sender), "NA");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable-next-line max-line-length
import {VersionedImplementationRepository} from "./proxy/VersionedImplementationRepository.sol";

contract TranchedPoolImplementationRepository is VersionedImplementationRepository {}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IV2CreditLine} from "../../interfaces/IV2CreditLine.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {FixedPoint} from "../../external/FixedPoint.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title TranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Goldfinch
 */

library TranchingLogic {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for uint256;
  using ConfigHelper for GoldfinchConfig;

  struct SliceInfo {
    uint256 reserveFeePercent;
    uint256 interestAccrued;
    uint256 principalAccrued;
  }

  struct ApplyResult {
    uint256 interestRemaining;
    uint256 principalRemaining;
    uint256 reserveDeduction;
    uint256 oldInterestSharePrice;
    uint256 oldPrincipalSharePrice;
  }

  uint256 internal constant FP_SCALING_FACTOR = 1e18;
  uint256 public constant NUM_TRANCHES_PER_SLICE = 2;

  function usdcToSharePrice(uint256 amount, uint256 totalShares) public pure returns (uint256) {
    return totalShares == 0 ? 0 : amount.mul(FP_SCALING_FACTOR).div(totalShares);
  }

  function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares) public pure returns (uint256) {
    return sharePrice.mul(totalShares).div(FP_SCALING_FACTOR);
  }

  function lockTranche(ITranchedPool.TrancheInfo storage tranche, GoldfinchConfig config) external {
    tranche.lockedUntil = block.timestamp.add(config.getDrawdownPeriodInSeconds());
    emit TrancheLocked(address(this), tranche.id, tranche.lockedUntil);
  }

  function redeemableInterestAndPrincipal(
    ITranchedPool.TrancheInfo storage trancheInfo,
    IPoolTokens.TokenInfo memory tokenInfo
  ) public view returns (uint256, uint256) {
    // This supports withdrawing before or after locking because principal share price starts at 1
    // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
    uint256 maxPrincipalRedeemable = sharePriceToUsdc(
      trancheInfo.principalSharePrice,
      tokenInfo.principalAmount
    );
    // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
    // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
    uint256 maxInterestRedeemable = sharePriceToUsdc(
      trancheInfo.interestSharePrice,
      tokenInfo.principalAmount
    );

    uint256 interestRedeemable = maxInterestRedeemable.sub(tokenInfo.interestRedeemed);
    uint256 principalRedeemable = maxPrincipalRedeemable.sub(tokenInfo.principalRedeemed);

    return (interestRedeemable, principalRedeemable);
  }

  function calculateExpectedSharePrice(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) public pure returns (uint256) {
    uint256 sharePrice = usdcToSharePrice(amount, tranche.principalDeposited);
    return _scaleByPercentOwnership(tranche, sharePrice, slice);
  }

  function scaleForSlice(
    ITranchedPool.PoolSlice memory slice,
    uint256 amount,
    uint256 totalDeployed
  ) public pure returns (uint256) {
    return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
  }

  // We need to create this struct so we don't run into a stack too deep error due to too many variables
  function getSliceInfo(
    ITranchedPool.PoolSlice memory slice,
    IV2CreditLine creditLine,
    uint256 totalDeployed,
    uint256 reserveFeePercent
  ) public view returns (SliceInfo memory) {
    (uint256 interestAccrued, uint256 principalAccrued) = getTotalInterestAndPrincipal(
      slice,
      creditLine,
      totalDeployed
    );
    return
      SliceInfo({
        reserveFeePercent: reserveFeePercent,
        interestAccrued: interestAccrued,
        principalAccrued: principalAccrued
      });
  }

  function getTotalInterestAndPrincipal(
    ITranchedPool.PoolSlice memory slice,
    IV2CreditLine creditLine,
    uint256 totalDeployed
  ) public view returns (uint256, uint256) {
    uint256 principalAccrued = creditLine.principalOwed();
    // In addition to principal actually owed, we need to account for early principal payments
    // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
    // 5K (balance- deployed) + 0 (principal owed)
    principalAccrued = totalDeployed.sub(creditLine.balance()).add(principalAccrued);
    // Now we need to scale that correctly for the slice we're interested in
    principalAccrued = scaleForSlice(slice, principalAccrued, totalDeployed);
    // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
    // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
    // share price starts at 1, and is decremented by what was drawn down.
    uint256 totalDeposited = slice.seniorTranche.principalDeposited.add(
      slice.juniorTranche.principalDeposited
    );
    principalAccrued = totalDeposited.sub(slice.principalDeployed).add(principalAccrued);
    return (slice.totalInterestAccrued, principalAccrued);
  }

  function scaleByFraction(
    uint256 amount,
    uint256 fraction,
    uint256 total
  ) public pure returns (uint256) {
    FixedPoint.Unsigned memory totalAsFixedPoint = FixedPoint.fromUnscaledUint(total);
    FixedPoint.Unsigned memory fractionAsFixedPoint = FixedPoint.fromUnscaledUint(fraction);
    return fractionAsFixedPoint.div(totalAsFixedPoint).mul(amount).div(FP_SCALING_FACTOR).rawValue;
  }

  /// @notice apply a payment to all slices
  /// @param poolSlices slices to apply to
  /// @param numSlices number of slices
  /// @param interest amount of interest to apply
  /// @param principal amount of principal to apply
  /// @param reserveFeePercent percentage that protocol will take for reserves
  /// @param totalDeployed total amount of principal deployed
  /// @param creditLine creditline to account for
  /// @param juniorFeePercent percentage the junior tranche will take
  /// @return total amount that will be sent to reserves
  function applyToAllSlices(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 numSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine,
    uint256 juniorFeePercent
  ) external returns (uint256) {
    ApplyResult memory result = TranchingLogic.applyToAllSeniorTranches(
      poolSlices,
      numSlices,
      interest,
      principal,
      reserveFeePercent,
      totalDeployed,
      creditLine,
      juniorFeePercent
    );

    return
      result.reserveDeduction.add(
        TranchingLogic.applyToAllJuniorTranches(
          poolSlices,
          numSlices,
          result.interestRemaining,
          result.principalRemaining,
          reserveFeePercent,
          totalDeployed,
          creditLine
        )
      );
  }

  function applyToAllSeniorTranches(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 numSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine,
    uint256 juniorFeePercent
  ) internal returns (ApplyResult memory) {
    ApplyResult memory seniorApplyResult;
    for (uint256 i = 0; i < numSlices; i++) {
      ITranchedPool.PoolSlice storage slice = poolSlices[i];

      SliceInfo memory sliceInfo = getSliceInfo(
        slice,
        creditLine,
        totalDeployed,
        reserveFeePercent
      );

      // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
      // pro-rata across the slices. So we scale the interest and principal to the slice
      ApplyResult memory applyResult = applyToSeniorTranche(
        slice,
        scaleForSlice(slice, interest, totalDeployed),
        scaleForSlice(slice, principal, totalDeployed),
        juniorFeePercent,
        sliceInfo
      );
      emitSharePriceUpdatedEvent(slice.seniorTranche, applyResult);
      seniorApplyResult.interestRemaining = seniorApplyResult.interestRemaining.add(
        applyResult.interestRemaining
      );
      seniorApplyResult.principalRemaining = seniorApplyResult.principalRemaining.add(
        applyResult.principalRemaining
      );
      seniorApplyResult.reserveDeduction = seniorApplyResult.reserveDeduction.add(
        applyResult.reserveDeduction
      );
    }
    return seniorApplyResult;
  }

  function applyToAllJuniorTranches(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 numSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine
  ) internal returns (uint256 totalReserveAmount) {
    for (uint256 i = 0; i < numSlices; i++) {
      SliceInfo memory sliceInfo = getSliceInfo(
        poolSlices[i],
        creditLine,
        totalDeployed,
        reserveFeePercent
      );
      // Any remaining interest and principal is then shared pro-rata with the junior slices
      ApplyResult memory applyResult = applyToJuniorTranche(
        poolSlices[i],
        scaleForSlice(poolSlices[i], interest, totalDeployed),
        scaleForSlice(poolSlices[i], principal, totalDeployed),
        sliceInfo
      );
      emitSharePriceUpdatedEvent(poolSlices[i].juniorTranche, applyResult);
      totalReserveAmount = totalReserveAmount.add(applyResult.reserveDeduction);
    }
    return totalReserveAmount;
  }

  function emitSharePriceUpdatedEvent(
    ITranchedPool.TrancheInfo memory tranche,
    ApplyResult memory applyResult
  ) internal {
    emit SharePriceUpdated(
      address(this),
      tranche.id,
      tranche.principalSharePrice,
      int256(tranche.principalSharePrice.sub(applyResult.oldPrincipalSharePrice)),
      tranche.interestSharePrice,
      int256(tranche.interestSharePrice.sub(applyResult.oldInterestSharePrice))
    );
  }

  function applyToSeniorTranche(
    ITranchedPool.PoolSlice storage slice,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 juniorFeePercent,
    SliceInfo memory sliceInfo
  ) internal returns (ApplyResult memory) {
    // First determine the expected share price for the senior tranche. This is the gross amount the senior
    // tranche should receive.
    uint256 expectedInterestSharePrice = calculateExpectedSharePrice(
      slice.seniorTranche,
      sliceInfo.interestAccrued,
      slice
    );
    uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
      slice.seniorTranche,
      sliceInfo.principalAccrued,
      slice
    );

    // Deduct the junior fee and the protocol reserve
    uint256 desiredNetInterestSharePrice = scaleByFraction(
      expectedInterestSharePrice,
      uint256(100).sub(juniorFeePercent.add(sliceInfo.reserveFeePercent)),
      uint256(100)
    );
    // Collect protocol fee interest received (we've subtracted this from the senior portion above)
    uint256 reserveDeduction = scaleByFraction(
      interestRemaining,
      sliceInfo.reserveFeePercent,
      uint256(100)
    );
    interestRemaining = interestRemaining.sub(reserveDeduction);
    uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice;
    uint256 oldPrincipalSharePrice = slice.seniorTranche.principalSharePrice;
    // Apply the interest remaining so we get up to the netInterestSharePrice
    (interestRemaining, principalRemaining) = _applyBySharePrice(
      slice.seniorTranche,
      interestRemaining,
      principalRemaining,
      desiredNetInterestSharePrice,
      expectedPrincipalSharePrice
    );
    return
      ApplyResult({
        interestRemaining: interestRemaining,
        principalRemaining: principalRemaining,
        reserveDeduction: reserveDeduction,
        oldInterestSharePrice: oldInterestSharePrice,
        oldPrincipalSharePrice: oldPrincipalSharePrice
      });
  }

  function applyToJuniorTranche(
    ITranchedPool.PoolSlice storage slice,
    uint256 interestRemaining,
    uint256 principalRemaining,
    SliceInfo memory sliceInfo
  ) public returns (ApplyResult memory) {
    // Then fill up the junior tranche with all the interest remaining, upto the principal share price
    uint256 expectedInterestSharePrice = slice.juniorTranche.interestSharePrice.add(
      usdcToSharePrice(interestRemaining, slice.juniorTranche.principalDeposited)
    );
    uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
      slice.juniorTranche,
      sliceInfo.principalAccrued,
      slice
    );
    uint256 oldInterestSharePrice = slice.juniorTranche.interestSharePrice;
    uint256 oldPrincipalSharePrice = slice.juniorTranche.principalSharePrice;
    (interestRemaining, principalRemaining) = _applyBySharePrice(
      slice.juniorTranche,
      interestRemaining,
      principalRemaining,
      expectedInterestSharePrice,
      expectedPrincipalSharePrice
    );

    // All remaining interest and principal is applied towards the junior tranche as interest
    interestRemaining = interestRemaining.add(principalRemaining);
    // Since any principal remaining is treated as interest (there is "extra" interest to be distributed)
    // we need to make sure to collect the protocol fee on the additional interest (we only deducted the
    // fee on the original interest portion)
    uint256 reserveDeduction = scaleByFraction(
      principalRemaining,
      sliceInfo.reserveFeePercent,
      uint256(100)
    );
    interestRemaining = interestRemaining.sub(reserveDeduction);
    principalRemaining = 0;

    (interestRemaining, principalRemaining) = _applyByAmount(
      slice.juniorTranche,
      interestRemaining.add(principalRemaining),
      0,
      interestRemaining.add(principalRemaining),
      0
    );
    return
      ApplyResult({
        interestRemaining: interestRemaining,
        principalRemaining: principalRemaining,
        reserveDeduction: reserveDeduction,
        oldInterestSharePrice: oldInterestSharePrice,
        oldPrincipalSharePrice: oldPrincipalSharePrice
      });
  }

  function migrateAccountingVariables(IV2CreditLine originalCl, IV2CreditLine newCl) external {
    // Copy over all accounting variables
    newCl.setBalance(originalCl.balance());
    newCl.setLimit(originalCl.limit());
    newCl.setInterestOwed(originalCl.interestOwed());
    newCl.setPrincipalOwed(originalCl.principalOwed());
    newCl.setTermEndTime(originalCl.termEndTime());
    newCl.setNextDueTime(originalCl.nextDueTime());
    newCl.setInterestAccruedAsOf(originalCl.interestAccruedAsOf());
    newCl.setLastFullPaymentTime(originalCl.lastFullPaymentTime());
    newCl.setTotalInterestAccrued(originalCl.totalInterestAccrued());
  }

  function closeCreditLine(IV2CreditLine cl) external {
    // Close out old CL
    cl.setBalance(0);
    cl.setLimit(0);
    cl.setMaxLimit(0);
  }

  function trancheIdToSliceIndex(uint256 trancheId) external pure returns (uint256) {
    return trancheId.sub(1).div(NUM_TRANCHES_PER_SLICE);
  }

  function initializeNextSlice(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 sliceIndex
  ) external {
    poolSlices[sliceIndex] = ITranchedPool.PoolSlice({
      seniorTranche: ITranchedPool.TrancheInfo({
        id: sliceIndexToSeniorTrancheId(sliceIndex),
        principalSharePrice: usdcToSharePrice(1, 1),
        interestSharePrice: 0,
        principalDeposited: 0,
        lockedUntil: 0
      }),
      juniorTranche: ITranchedPool.TrancheInfo({
        id: sliceIndexToJuniorTrancheId(sliceIndex),
        principalSharePrice: usdcToSharePrice(1, 1),
        interestSharePrice: 0,
        principalDeposited: 0,
        lockedUntil: 0
      }),
      totalInterestAccrued: 0,
      principalDeployed: 0
    });
  }

  function sliceIndexToJuniorTrancheId(uint256 sliceIndex) public pure returns (uint256) {
    // 0 -> 2
    // 1 -> 4
    return sliceIndex.mul(NUM_TRANCHES_PER_SLICE).add(2);
  }

  function sliceIndexToSeniorTrancheId(uint256 sliceIndex) public pure returns (uint256) {
    // 0 -> 1
    // 1 -> 3
    return sliceIndex.mul(NUM_TRANCHES_PER_SLICE).add(1);
  }

  function isSeniorTrancheId(uint256 trancheId) external pure returns (bool) {
    return trancheId.mod(TranchingLogic.NUM_TRANCHES_PER_SLICE) == 1;
  }

  function isJuniorTrancheId(uint256 trancheId) external pure returns (bool) {
    return trancheId != 0 && trancheId.mod(TranchingLogic.NUM_TRANCHES_PER_SLICE) == 0;
  }

  // // INTERNAL //////////////////////////////////////////////////////////////////

  function _applyToSharePrice(
    uint256 amountRemaining,
    uint256 currentSharePrice,
    uint256 desiredAmount,
    uint256 totalShares
  ) internal pure returns (uint256, uint256) {
    // If no money left to apply, or don't need any changes, return the original amounts
    if (amountRemaining == 0 || desiredAmount == 0) {
      return (amountRemaining, currentSharePrice);
    }
    if (amountRemaining < desiredAmount) {
      // We don't have enough money to adjust share price to the desired level. So just use whatever amount is left
      desiredAmount = amountRemaining;
    }
    uint256 sharePriceDifference = usdcToSharePrice(desiredAmount, totalShares);
    return (amountRemaining.sub(desiredAmount), currentSharePrice.add(sharePriceDifference));
  }

  function _scaleByPercentOwnership(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) internal pure returns (uint256) {
    uint256 totalDeposited = slice.juniorTranche.principalDeposited.add(
      slice.seniorTranche.principalDeposited
    );
    return scaleByFraction(amount, tranche.principalDeposited, totalDeposited);
  }

  function _desiredAmountFromSharePrice(
    uint256 desiredSharePrice,
    uint256 actualSharePrice,
    uint256 totalShares
  ) internal pure returns (uint256) {
    // If the desired share price is lower, then ignore it, and leave it unchanged
    if (desiredSharePrice < actualSharePrice) {
      desiredSharePrice = actualSharePrice;
    }
    uint256 sharePriceDifference = desiredSharePrice.sub(actualSharePrice);
    return sharePriceToUsdc(sharePriceDifference, totalShares);
  }

  function _applyByAmount(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestAmount,
    uint256 desiredPrincipalAmount
  ) internal returns (uint256, uint256) {
    uint256 totalShares = tranche.principalDeposited;
    uint256 newSharePrice;

    (interestRemaining, newSharePrice) = _applyToSharePrice(
      interestRemaining,
      tranche.interestSharePrice,
      desiredInterestAmount,
      totalShares
    );
    tranche.interestSharePrice = newSharePrice;

    (principalRemaining, newSharePrice) = _applyToSharePrice(
      principalRemaining,
      tranche.principalSharePrice,
      desiredPrincipalAmount,
      totalShares
    );
    tranche.principalSharePrice = newSharePrice;
    return (interestRemaining, principalRemaining);
  }

  function _applyBySharePrice(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestSharePrice,
    uint256 desiredPrincipalSharePrice
  ) internal returns (uint256, uint256) {
    uint256 desiredInterestAmount = _desiredAmountFromSharePrice(
      desiredInterestSharePrice,
      tranche.interestSharePrice,
      tranche.principalDeposited
    );
    uint256 desiredPrincipalAmount = _desiredAmountFromSharePrice(
      desiredPrincipalSharePrice,
      tranche.principalSharePrice,
      tranche.principalDeposited
    );
    return
      _applyByAmount(
        tranche,
        interestRemaining,
        principalRemaining,
        desiredInterestAmount,
        desiredPrincipalAmount
      );
  }

  // // Events /////////////////////////////////////////////////////////////////////

  // NOTE: this needs to match the event in TranchedPool
  event TrancheLocked(address indexed pool, uint256 trancheId, uint256 lockedUntil);

  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ERC721PresetMinterPauserAutoIdUpgradeSafe} from "../../external/ERC721PresetMinterPauserAutoId.sol";
import {ERC721UpgradeSafe} from "../../external/ERC721.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {IWithdrawalRequestToken} from "../../interfaces/IWithdrawalRequestToken.sol";
import {HasAdmin} from "./HasAdmin.sol";
import {IERC721} from "../../interfaces/openzeppelin/IERC721.sol";

// TODO - supportsInterface and setBaseURI functions
contract WithdrawalRequestToken is
  IWithdrawalRequestToken,
  ERC721PresetMinterPauserAutoIdUpgradeSafe,
  HasAdmin
{
  using ConfigHelper for GoldfinchConfig;

  GoldfinchConfig private config;

  /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );

    __Context_init_unchained();
    __AccessControl_init_unchained();
    __ERC165_init_unchained();
    // This is setting name and symbol of the NFT's
    __ERC721_init_unchained("Goldfinch SeniorPool Withdrawal Tokens", "GFI-SENIOR-WITHDRAWALS");
    __Pausable_init_unchained();
    __ERC721Pausable_init_unchained();

    config = _config;

    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /// @inheritdoc IWithdrawalRequestToken
  /// @notice Can only be called by senior pool or protocol admin
  function mint(address receiver) external override onlySeniorPool returns (uint256) {
    _tokenIdTracker.increment();
    _mint(receiver, _tokenIdTracker.current());
    return _tokenIdTracker.current();
  }

  /// @inheritdoc IWithdrawalRequestToken
  function burn(uint256 tokenId) external override onlySeniorPool {
    _burn(tokenId);
  }

  /// @notice Disabled
  function approve(address, uint256) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function setApprovalForAll(address, bool) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function transferFrom(address, address, uint256) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function safeTransferFrom(address, address, uint256) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  /// @notice Disabled
  function safeTransferFrom(
    address,
    address,
    uint256,
    bytes memory
  ) public override(IERC721, ERC721UpgradeSafe) {
    revert("Disabled");
  }

  modifier onlySeniorPool() {
    require(msg.sender == address(config.getSeniorPool()), "NA");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC721} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IRequiresUID} from "../../interfaces/IRequiresUID.sol";
import {IStakingRewards, StakedPositionType} from "../../interfaces/IStakingRewards.sol";
import {Accountant} from "./Accountant.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";

/// @title Zapper
/// @author Emily Hsia, Mark Hudnall, Will Johnston, Dalton Sweeney
/// @notice Moves capital from the SeniorPool to TranchedPools without taking fees
contract Zapper is BaseUpgradeablePausable {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  struct Zap {
    address owner;
    uint256 stakingPositionId;
  }

  /// @dev PoolToken.id => Zap
  mapping(uint256 => Zap) public tranchedPoolZaps;

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  /// @notice Zap multiple StakingRewards tokens to a tranched pool.
  /// @param stakingRewardsTokenIds ids of the StakingRewards ERC721 positions to zap. Token ids MUST be
  ///   sorted ascending.
  /// @param fiduAmounts FIDU amount to zap for each position such that `fiduAmounts[i]` FIDU
  ///   is zapped from position `tokenIds[i]`.
  /// @param tranchedPool address of the tranched pool to zap into.
  /// @param tranche id of the tranch to zap into.
  /// @return poolTokenIds PoolTokens ERC721 ids created by each zap action.
  function zapMultipleToTranchedPool(
    uint256[] calldata stakingRewardsTokenIds,
    uint256[] calldata fiduAmounts,
    ITranchedPool tranchedPool,
    uint256 tranche
  ) public whenNotPaused nonReentrant returns (uint256[] memory poolTokenIds) {
    require(stakingRewardsTokenIds.length == fiduAmounts.length, "Array size mismatch");

    poolTokenIds = new uint256[](stakingRewardsTokenIds.length);
    for (uint256 i = 0; i < stakingRewardsTokenIds.length; ++i) {
      if (i > 0 && stakingRewardsTokenIds[i] <= stakingRewardsTokenIds[i - 1]) {
        revert("Token ids not sorted");
      }
      poolTokenIds[i] = _zapFiduAmountToTranchedPool(
        stakingRewardsTokenIds[i],
        tranchedPool,
        tranche,
        fiduAmounts[i]
      );
    }

    return poolTokenIds;
  }

  /// @notice Unzap multiple pool tokens (not necessarily from the same tranched pools).
  ///   You may perform this action anytime before the respective tranche locks.
  /// @param poolTokenIds PoolTokens ERC721 ids to unzap. Token ids MUST be sorted ascending.
  ///   The caller MUST be the address that performed the initial zaps.
  function unzapMultipleFromTranchedPools(
    uint256[] calldata poolTokenIds
  ) public whenNotPaused nonReentrant {
    for (uint256 i = 0; i < poolTokenIds.length; ++i) {
      if (i > 0 && poolTokenIds[i] <= poolTokenIds[i - 1]) {
        revert("Token ids not sorted");
      }
      _unzapToStakingRewards(poolTokenIds[i]);
    }
  }

  /// @notice Claim multiple pool tokens (not necessarily from the same tranched pools). A claim
  ///   only succeeds if the tranched pool has locked.
  /// @param poolTokenIds PoolTokens ERC721 ids to claim. Token ids MUST be sorted ascending.
  ///   The caller MUST be the address that performed the initial zaps.
  function claimMultipleTranchedPoolZaps(
    uint256[] calldata poolTokenIds
  ) public whenNotPaused nonReentrant {
    for (uint256 i = 0; i < poolTokenIds.length; ++i) {
      if (i > 0 && poolTokenIds[i] <= poolTokenIds[i - 1]) {
        revert("Token ids not sorted");
      }
      _claimTranchedPoolZap(poolTokenIds[i]);
    }
  }

  /// @notice Zap staked FIDU into the junior tranche of a TranchedPool without losing
  ///   unvested rewards or paying a withdrawal fee. This function is preferred over
  ///   `zapStakeToTranchedPool` for zapping an entire position because the latter
  ///   accepts a USDC amount, which cannot precisely represent FIDU due to lack of decimals.
  /// @dev The minted pool token is held by this contract until either `claimZap` or
  ///   `unzap` is called.
  /// @param tokenId StakingRewards ERC721 token id to zap.
  /// @param tranchedPool TranchedPool to deposit into.
  /// @param tranche id of the tranche to deposit into.
  /// @param fiduAmount amount to deposit in FIDU.
  /// @return poolTokenId PoolTokens ERC721 id of the TranchedPool deposit.
  function zapFiduStakeToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 fiduAmount
  ) public whenNotPaused nonReentrant returns (uint256 poolTokenId) {
    return _zapFiduAmountToTranchedPool(tokenId, tranchedPool, tranche, fiduAmount);
  }

  /// @notice Zap staked FIDU into the junior tranche of a TranchedPool without losing
  ///   unvested rewards or paying a withdrawal fee
  /// @dev The minted pool token is held by this contract until either `claimZap` or
  ///   `unzap` is called
  /// @param tokenId A staking position token ID. The owner MUST perform an ERC721 approval
  /// @param tranchedPool TranchedPool to deposit into.
  /// @param tranche id of the tranche to deposit into.
  /// @param usdcAmount The USDC amount to deposit.
  /// @return poolTokenId PoolTokens ERC721 id of the TranchedPool deposit.
  ///   for the Zapper address before calling this function.
  function zapStakeToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 usdcAmount
  ) public whenNotPaused nonReentrant returns (uint256 poolTokenId) {
    return _zapUsdcAmountToTranchedPool(tokenId, tranchedPool, tranche, usdcAmount);
  }

  /// @notice Claim the underlying PoolToken for a zap initiated with `zapStakeToTranchePool`.
  ///  The pool token will be transferred to msg.sender if msg.sender initiated the zap and
  ///  we are past the tranche's lockedUntil time.
  /// @param poolTokenId The underyling PoolToken id created in a previously initiated zap
  function claimTranchedPoolZap(uint256 poolTokenId) public whenNotPaused nonReentrant {
    _claimTranchedPoolZap(poolTokenId);
  }

  /// @notice Unwind a zap initiated with `zapStakeToTranchePool`.
  ///  The funds will be withdrawn from the TranchedPool and added back to the original
  ///  staked position in StakingRewards. This method can only be called when the PoolToken's
  ///  tranche has never been locked.
  /// @param poolTokenId The underyling PoolToken id created in a previously initiated zap
  function unzapToStakingRewards(uint256 poolTokenId) public whenNotPaused nonReentrant {
    _unzapToStakingRewards(poolTokenId);
  }

  /// @notice Zap staked FIDU into staked Curve LP tokens without losing unvested rewards
  ///  or paying a withdrawal fee.
  /// @param tokenId A staking position token ID
  /// @param fiduAmount The amount in FIDU from the staked position to zap
  /// @param usdcAmount The amount of USDC to deposit into Curve
  function zapStakeToCurve(
    uint256 tokenId,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) public whenNotPaused nonReentrant {
    IStakingRewards stakingRewards = config.getStakingRewards();
    require(IERC721(address(stakingRewards)).ownerOf(tokenId) == msg.sender, "Not token owner");

    uint256 stakedBalance = stakingRewards.stakedBalanceOf(tokenId);
    require(fiduAmount > 0, "Cannot zap 0 FIDU");
    require(fiduAmount <= stakedBalance, "cannot unstake more than staked balance");

    stakingRewards.unstake(tokenId, fiduAmount);

    SafeERC20.safeApprove(config.getFidu(), address(stakingRewards), fiduAmount);

    if (usdcAmount > 0) {
      SafeERC20.safeTransferFrom(config.getUSDC(), msg.sender, address(this), usdcAmount);
      SafeERC20.safeApprove(config.getUSDC(), address(stakingRewards), usdcAmount);
    }

    stakingRewards.depositToCurveAndStakeFrom(msg.sender, fiduAmount, usdcAmount);

    // Require that the allowances for both FIDU and USDC are reset to zero after
    // at the end of the transaction. `safeApprove` will fail on subsequent invocations
    // if any "dust" is left behind.
    require(
      config.getFidu().allowance(address(this), address(stakingRewards)) == 0,
      "Entire allowance of FIDU has not been used."
    );
    require(
      config.getUSDC().allowance(address(this), address(stakingRewards)) == 0,
      "Entire allowance of USDC has not been used."
    );
  }

  /// @notice See `unzapToStakingRewards`
  function _unzapToStakingRewards(uint256 poolTokenId) internal {
    Zap storage zap = tranchedPoolZaps[poolTokenId];

    require(zap.owner == msg.sender, "Not zap owner");

    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(poolTokenId);
    ITranchedPool tranchedPool = ITranchedPool(tokenInfo.pool);
    ITranchedPool.TrancheInfo memory trancheInfo = tranchedPool.getTranche(tokenInfo.tranche);

    require(trancheInfo.lockedUntil == 0, "Tranche locked");

    (uint256 interestWithdrawn, uint256 principalWithdrawn) = tranchedPool.withdrawMax(poolTokenId);
    require(interestWithdrawn == 0, "Invalid state");
    require(principalWithdrawn > 0, "Invalid state");

    ISeniorPool seniorPool = config.getSeniorPool();
    SafeERC20.safeApprove(config.getUSDC(), address(seniorPool), principalWithdrawn);
    uint256 fiduAmount = seniorPool.deposit(principalWithdrawn);

    IStakingRewards stakingRewards = config.getStakingRewards();
    SafeERC20.safeApprove(config.getFidu(), address(stakingRewards), fiduAmount);
    stakingRewards.addToStake(zap.stakingPositionId, fiduAmount);

    // Require that the allowances for both FIDU and USDC are reset to zero
    // at the end of the transaction. `safeApprove` will fail on subsequent invocations
    // if any "dust" is left behind.
    require(
      config.getUSDC().allowance(address(this), address(seniorPool)) == 0,
      "Entire allowance of USDC has not been used."
    );
    require(
      config.getFidu().allowance(address(this), address(stakingRewards)) == 0,
      "Entire allowance of FIDU has not been used."
    );
  }

  /// @notice See `claimTranchedPoolZap`
  function _claimTranchedPoolZap(uint256 poolTokenId) internal {
    Zap storage zap = tranchedPoolZaps[poolTokenId];

    require(zap.owner == msg.sender, "Not zap owner");

    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(poolTokenId);
    ITranchedPool.TrancheInfo memory trancheInfo = ITranchedPool(tokenInfo.pool).getTranche(
      tokenInfo.tranche
    );

    require(
      trancheInfo.lockedUntil != 0 && block.timestamp > trancheInfo.lockedUntil,
      "Zap locked"
    );

    IERC721(address(poolTokens)).safeTransferFrom(address(this), msg.sender, poolTokenId);
  }

  /// @notice See zapStakeToTranchedPool
  function _zapUsdcAmountToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 usdcAmount
  ) internal returns (uint256 poolTokenId) {
    IStakingRewards stakingRewards = config.getStakingRewards();
    ISeniorPool seniorPool = config.getSeniorPool();

    require(_validPool(tranchedPool), "Invalid pool");
    require(IERC721(address(stakingRewards)).ownerOf(tokenId) == msg.sender, "Not token owner");
    require(_hasAllowedUID(tranchedPool), "Address not go-listed");
    require(
      stakingRewards.getPosition(tokenId).positionType == StakedPositionType.Fidu,
      "Bad positionType"
    );

    uint256 shares = seniorPool.getNumShares(usdcAmount);
    stakingRewards.unstake(tokenId, shares);

    uint256 withdrawnAmount = seniorPool.withdraw(usdcAmount);
    require(withdrawnAmount == usdcAmount, "Withdrawn amount != requested amount");

    SafeERC20.safeApprove(config.getUSDC(), address(tranchedPool), usdcAmount);
    poolTokenId = tranchedPool.deposit(tranche, usdcAmount);

    tranchedPoolZaps[poolTokenId] = Zap(msg.sender, tokenId);

    // Require that the tranched pool's allowance for USDC is reset to zero
    // at the end of the transaction. `safeApprove` will fail on subsequent invocations
    // if any "dust" is left behind.
    require(
      config.getUSDC().allowance(address(this), address(tranchedPool)) == 0,
      "Entire allowance of USDC has not been used."
    );
  }

  /// @notice See zapFiduStakeToTranchedPool
  function _zapFiduAmountToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 fiduAmount
  ) internal returns (uint256 poolTokenId) {
    IStakingRewards stakingRewards = config.getStakingRewards();
    ISeniorPool seniorPool = config.getSeniorPool();

    require(_validPool(tranchedPool), "Invalid pool");
    require(IERC721(address(stakingRewards)).ownerOf(tokenId) == msg.sender, "Not token owner");
    require(_hasAllowedUID(tranchedPool), "Address not go-listed");
    require(
      stakingRewards.getPosition(tokenId).positionType == StakedPositionType.Fidu,
      "Bad positionType"
    );

    stakingRewards.unstake(tokenId, fiduAmount);
    uint256 withdrawnAmount = seniorPool.withdrawInFidu(fiduAmount);

    SafeERC20.safeApprove(config.getUSDC(), address(tranchedPool), withdrawnAmount);
    poolTokenId = tranchedPool.deposit(tranche, withdrawnAmount);

    tranchedPoolZaps[poolTokenId] = Zap(msg.sender, tokenId);

    // Require that the allowance for USDC is reset to zero after at the end of the transaction.
    // `safeApprove` will fail on subsequent invocations if any "dust" is left behind.
    require(
      config.getUSDC().allowance(address(this), address(tranchedPool)) == 0,
      "Entire allowance of USDC has not been used."
    );
  }

  function _hasAllowedUID(ITranchedPool pool) internal view returns (bool) {
    return IRequiresUID(address(pool)).hasAllowedUID(msg.sender);
  }

  function _validPool(ITranchedPool pool) internal view returns (bool) {
    return config.getPoolTokens().validPool(address(pool));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IVersioned} from "../../interfaces/IVersioned.sol";
import {SafeERC20Transfer} from "../../library/SafeERC20Transfer.sol";
import {BaseUpgradeablePausable} from "../core/BaseUpgradeablePausable.sol";
import {ConfigHelper} from "../core/ConfigHelper.sol";
import {CreditLine} from "../core/CreditLine.sol";
import {GoldfinchConfig} from "../core/GoldfinchConfig.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IBorrower} from "../../interfaces/IBorrower.sol";
import {BaseRelayRecipient} from "../../external/BaseRelayRecipient.sol";
import {ContextUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

/**
 * @title Goldfinch's Borrower contract
 * @notice These contracts represent the a convenient way for a borrower to interact with Goldfinch
 *  They are 100% optional. However, they let us add many sophisticated and convient features for borrowers
 *  while still keeping our core protocol small and secure. We therefore expect most borrowers will use them.
 *  This contract is the "official" borrower contract that will be maintained by Goldfinch governance. However,
 *  in theory, anyone can fork or create their own version, or not use any contract at all. The core functionality
 *  is completely agnostic to whether it is interacting with a contract or an externally owned account (EOA).
 * @author Goldfinch
 */

contract Borrower is BaseUpgradeablePausable, BaseRelayRecipient, IBorrower {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  address private constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address private constant BUSD_ADDRESS = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
  address private constant GUSD_ADDRESS = address(0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
  address private constant DAI_ADDRESS = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  function initialize(address owner, address _config) external override initializer {
    require(
      owner != address(0) && _config != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = GoldfinchConfig(_config);

    trustedForwarder = config.trustedForwarderAddress();

    // Handle default approvals. Pool, and OneInch for maximum amounts
    address oneInch = config.oneInchAddress();
    IERC20withDec usdc = config.getUSDC();
    usdc.approve(oneInch, uint256(-1));
    bytes memory data = abi.encodeWithSignature("approve(address,uint256)", oneInch, uint256(-1));
    _invoke(USDT_ADDRESS, data);
    _invoke(BUSD_ADDRESS, data);
    _invoke(GUSD_ADDRESS, data);
    _invoke(DAI_ADDRESS, data);
  }

  function lockJuniorCapital(address poolAddress) external onlyAdmin {
    ITranchedPool(poolAddress).lockJuniorCapital();
  }

  function lockPool(address poolAddress) external onlyAdmin {
    ITranchedPool(poolAddress).lockPool();
  }

  /**
   * @notice Allows a borrower to drawdown on their credit line through a TranchedPool.
   * @param poolAddress The creditline from which they would like to drawdown
   * @param amount The amount, in USDC atomic units, that a borrower wishes to drawdown
   * @param addressToSendTo The address where they would like the funds sent. If the zero address is passed,
   *  it will be defaulted to the contracts address (msg.sender). This is a convenience feature for when they would
   *  like the funds sent to an exchange or alternate wallet, different from the authentication address
   */
  function drawdown(
    address poolAddress,
    uint256 amount,
    address addressToSendTo
  ) external onlyAdmin {
    ITranchedPool(poolAddress).drawdown(amount);

    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    transferERC20(config.usdcAddress(), addressToSendTo, amount);
  }

  function drawdownWithSwapOnOneInch(
    address poolAddress,
    uint256 amount,
    address addressToSendTo,
    address toToken,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) public onlyAdmin {
    // Drawdown to the Borrower contract
    ITranchedPool(poolAddress).drawdown(amount);

    // Do the swap
    swapOnOneInch(config.usdcAddress(), toToken, amount, minTargetAmount, exchangeDistribution);

    // Default to sending to the owner, and don't let funds stay in this contract
    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    // Fulfill the send to
    bytes memory _data = abi.encodeWithSignature("balanceOf(address)", address(this));
    uint256 receivedAmount = _toUint256(_invoke(toToken, _data));
    transferERC20(toToken, addressToSendTo, receivedAmount);
  }

  function transferERC20(address token, address to, uint256 amount) public onlyAdmin {
    bytes memory _data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
    _invoke(token, _data);
  }

  /**
   * @notice Allows a borrower to pay back loans by calling the `pay` function directly on a TranchedPool
   * @param poolAddress The credit line to be paid back
   * @param amount The amount, in USDC atomic units, that the borrower wishes to pay
   */
  function pay(address poolAddress, uint256 amount) external onlyAdmin {
    IERC20withDec usdc = config.getUSDC();
    bool success = usdc.transferFrom(_msgSender(), address(this), amount);
    require(success, "Failed to transfer USDC");
    _transferAndPay(usdc, poolAddress, amount);
  }

  function payMultiple(address[] calldata pools, uint256[] calldata amounts) external onlyAdmin {
    require(pools.length == amounts.length, "Pools and amounts must be the same length");

    uint256 totalAmount;
    for (uint256 i = 0; i < amounts.length; i++) {
      totalAmount = totalAmount.add(amounts[i]);
    }

    IERC20withDec usdc = config.getUSDC();
    // Do a single transfer, which is cheaper
    bool success = usdc.transferFrom(_msgSender(), address(this), totalAmount);
    require(success, "Failed to transfer USDC");

    for (uint256 i = 0; i < amounts.length; i++) {
      _transferAndPay(usdc, pools[i], amounts[i]);
    }
  }

  function payInFull(address poolAddress, uint256 amount) external onlyAdmin {
    IERC20withDec usdc = config.getUSDC();
    bool success = usdc.transferFrom(_msgSender(), address(this), amount);
    require(success, "Failed to transfer USDC");

    _transferAndPay(usdc, poolAddress, amount);
    require(
      ITranchedPool(poolAddress).creditLine().balance() == 0,
      "Failed to fully pay off creditline"
    );
  }

  function payWithSwapOnOneInch(
    address poolAddress,
    uint256 originAmount,
    address fromToken,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) external onlyAdmin {
    transferFrom(fromToken, _msgSender(), address(this), originAmount);
    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, minTargetAmount, exchangeDistribution);
    uint256 usdcBalance = usdc.balanceOf(address(this));
    _transferAndPay(usdc, poolAddress, usdcBalance);
  }

  function payMultipleWithSwapOnOneInch(
    address[] calldata pools,
    uint256[] calldata minAmounts,
    uint256 originAmount,
    address fromToken,
    uint256[] calldata exchangeDistribution
  ) external onlyAdmin {
    require(pools.length == minAmounts.length, "Pools and amounts must be the same length");

    uint256 totalMinAmount = 0;
    for (uint256 i = 0; i < minAmounts.length; i++) {
      totalMinAmount = totalMinAmount.add(minAmounts[i]);
    }

    transferFrom(fromToken, _msgSender(), address(this), originAmount);

    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, totalMinAmount, exchangeDistribution);

    for (uint256 i = 0; i < minAmounts.length; i++) {
      _transferAndPay(usdc, pools[i], minAmounts[i]);
    }

    uint256 remainingUSDC = usdc.balanceOf(address(this));
    if (remainingUSDC > 0) {
      _transferAndPay(usdc, pools[0], remainingUSDC);
    }
  }

  function _transferAndPay(IERC20withDec usdc, address poolAddress, uint256 amount) internal {
    ITranchedPool pool = ITranchedPool(poolAddress);
    // We don't use transferFrom since it would require a separate approval per creditline
    bool success = usdc.transfer(address(pool.creditLine()), amount);
    require(success, "USDC Transfer to creditline failed");
    pool.assess();
  }

  function transferFrom(address erc20, address sender, address recipient, uint256 amount) internal {
    bytes memory _data;
    // Do a low-level _invoke on this transfer, since Tether fails if we use the normal IERC20 interface
    _data = abi.encodeWithSignature(
      "transferFrom(address,address,uint256)",
      sender,
      recipient,
      amount
    );
    _invoke(address(erc20), _data);
  }

  function swapOnOneInch(
    address fromToken,
    address toToken,
    uint256 originAmount,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) internal {
    bytes memory _data = abi.encodeWithSignature(
      "swap(address,address,uint256,uint256,uint256[],uint256)",
      fromToken,
      toToken,
      originAmount,
      minTargetAmount,
      exchangeDistribution,
      0
    );
    _invoke(config.oneInchAddress(), _data);
  }

  /**
   * @notice Performs a generic transaction.
   * @param _target The address for the transaction.
   * @param _data The data of the transaction.
   * Mostly copied from Argent:
   * https://github.com/argentlabs/argent-contracts/blob/develop/contracts/wallet/BaseWallet.sol#L111
   */
  function _invoke(address _target, bytes memory _data) internal returns (bytes memory) {
    // External contracts can be compiled with different Solidity versions
    // which can cause "revert without reason" when called through,
    // for example, a standard IERC20 ABI compiled on the latest version.
    // This low-level call avoids that issue.

    bool success;
    bytes memory _res;
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = _target.call(_data);
    if (!success && _res.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    } else if (!success) {
      revert("VM: wallet _invoke reverted");
    }
    return _res;
  }

  function _toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }

  // OpenZeppelin contracts come with support for GSN _msgSender() (which just defaults to msg.sender)
  // Since there are two different versions of the function in the hierarchy, we need to instruct solidity to
  // use the relay recipient version which can actually pull the real sender from the parameters.
  // https://www.notion.so/My-contract-is-using-OpenZeppelin-How-do-I-add-GSN-support-2bee7e9d5f774a0cbb60d3a8de03e9fb
  function _msgSender()
    internal
    view
    override(ContextUpgradeSafe, BaseRelayRecipient)
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  function _msgData()
    internal
    view
    override(ContextUpgradeSafe, BaseRelayRecipient)
    returns (bytes memory ret)
  {
    return BaseRelayRecipient._msgData();
  }

  function versionRecipient() external view override returns (string memory) {
    return "2.0.0";
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "./MerkleDirectDistributor.sol";

// solhint-disable-next-line no-empty-blocks
contract BackerMerkleDirectDistributor is MerkleDirectDistributor {

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "./MerkleDistributor.sol";

contract BackerMerkleDistributor is MerkleDistributor {
  constructor(
    address communityRewards_,
    bytes32 merkleRoot_
  )
    public
    MerkleDistributor(communityRewards_, merkleRoot_) // solhint-disable-next-line no-empty-blocks
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {Babylonian} from "@uniswap/lib/contracts/libraries/Babylonian.sol";

import {SafeERC20Transfer} from "../library/SafeERC20Transfer.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";
import {BaseUpgradeablePausable} from "../protocol/core/BaseUpgradeablePausable.sol";
import {ICreditLine} from "../interfaces/ICreditLine.sol";
import {IPoolTokens} from "../interfaces/IPoolTokens.sol";
import {IStakingRewards} from "../interfaces/IStakingRewards.sol";
import {ITranchedPool} from "../interfaces/ITranchedPool.sol";
import {IBackerRewards} from "../interfaces/IBackerRewards.sol";
import {ISeniorPool} from "../interfaces/ISeniorPool.sol";
import {IEvents} from "../interfaces/IEvents.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";

// Basically, Every time a interest payment comes back
// we keep a running total of dollars (totalInterestReceived) until it reaches the maxInterestDollarsEligible limit
// Every dollar of interest received from 0->maxInterestDollarsEligible
// has a allocated amount of rewards based on a sqrt function.

// When a interest payment comes in for a given Pool or the pool balance increases
// we recalculate the pool's accRewardsPerPrincipalDollar

// equation ref `_calculateNewGrossGFIRewardsForInterestAmount()`:
// (sqrtNewTotalInterest - sqrtOrigTotalInterest) / sqrtMaxInterestDollarsEligible * (totalRewards / totalGFISupply)

// When a PoolToken is minted, we set the mint price to the pool's current accRewardsPerPrincipalDollar
// Every time a PoolToken withdraws rewards, we determine the allocated rewards,
// increase that PoolToken's rewardsClaimed, and transfer the owner the gfi

contract BackerRewards is IBackerRewards, BaseUpgradeablePausable, IEvents {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using SafeERC20Transfer for IERC20withDec;

  uint256 internal constant GFI_MANTISSA = 10 ** 18;
  uint256 internal constant FIDU_MANTISSA = 10 ** 18;
  uint256 internal constant USDC_MANTISSA = 10 ** 6;
  uint256 internal constant NUM_TRANCHES_PER_SLICE = 2;

  /// @inheritdoc IBackerRewards
  uint256 public override totalRewards;

  /// @inheritdoc IBackerRewards
  uint256 public override maxInterestDollarsEligible;

  /// @inheritdoc IBackerRewards
  uint256 public override totalInterestReceived;

  /// @inheritdoc IBackerRewards
  uint256 public override totalRewardPercentOfTotalGFI;

  mapping(uint256 => BackerRewardsTokenInfo) public tokens;
  mapping(address => BackerRewardsInfo) public pools;
  mapping(ITranchedPool => StakingRewardsPoolInfo) public poolStakingRewards;

  /// @notice Staking rewards info for each pool token
  mapping(uint256 => StakingRewardsTokenInfo) public tokenStakingRewards;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  /// @notice intialize the first slice of a StakingRewardsPoolInfo
  /// @dev this is _only_ meant to be called on pools that didnt qualify for the backer rewards airdrop
  ///       but were deployed before this contract.
  function forceInitializeStakingRewardsPoolInfo(
    ITranchedPool pool,
    uint256 fiduSharePriceAtDrawdown,
    uint256 principalDeployedAtDrawdown,
    uint256 rewardsAccumulatorAtDrawdown
  ) external onlyAdmin {
    require(config.getPoolTokens().validPool(address(pool)), "Invalid pool!");
    require(fiduSharePriceAtDrawdown != 0, "Invalid: 0");
    require(principalDeployedAtDrawdown != 0, "Invalid: 0");
    require(rewardsAccumulatorAtDrawdown != 0, "Invalid: 0");

    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];
    require(poolInfo.slicesInfo.length <= 1, "trying to overwrite multi slice rewards info!");

    // NOTE: making this overwrite behavior to make it so that we have
    //           an escape hatch in case the incorrect value is set for some reason
    bool firstSliceHasAlreadyBeenInitialized = poolInfo.slicesInfo.length != 0;

    poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint = rewardsAccumulatorAtDrawdown;
    StakingRewardsSliceInfo memory sliceInfo = _initializeStakingRewardsSliceInfo(
      fiduSharePriceAtDrawdown,
      principalDeployedAtDrawdown,
      rewardsAccumulatorAtDrawdown
    );

    if (firstSliceHasAlreadyBeenInitialized) {
      poolInfo.slicesInfo[0] = sliceInfo;
    } else {
      poolInfo.slicesInfo.push(sliceInfo);
    }
  }

  /// @inheritdoc IBackerRewards
  function allocateRewards(uint256 _interestPaymentAmount) external override onlyPool nonReentrant {
    // note: do not use a require statment because that will TranchedPool kill execution
    if (_interestPaymentAmount > 0) {
      _allocateRewards(_interestPaymentAmount);
    }

    _allocateStakingRewards();
  }

  /**
   * @notice Set the total gfi rewards and the % of total GFI
   * @param _totalRewards The amount of GFI rewards available, expects 10^18 value
   */
  function setTotalRewards(uint256 _totalRewards) public onlyAdmin {
    totalRewards = _totalRewards;
    uint256 totalGFISupply = config.getGFI().totalSupply();
    totalRewardPercentOfTotalGFI = _totalRewards.mul(GFI_MANTISSA).div(totalGFISupply).mul(100);
    emit BackerRewardsSetTotalRewards(_msgSender(), _totalRewards, totalRewardPercentOfTotalGFI);
  }

  /**
   * @notice Set the total interest received to date.
   * This should only be called once on contract deploy.
   * @param _totalInterestReceived The amount of interest the protocol has received to date, expects 10^6 value
   */
  function setTotalInterestReceived(uint256 _totalInterestReceived) public onlyAdmin {
    totalInterestReceived = _totalInterestReceived;
    emit BackerRewardsSetTotalInterestReceived(_msgSender(), _totalInterestReceived);
  }

  /**
   * @notice Set the max dollars across the entire protocol that are eligible for GFI rewards
   * @param _maxInterestDollarsEligible The amount of interest dollars eligible for GFI rewards, expects 10^18 value
   */
  function setMaxInterestDollarsEligible(uint256 _maxInterestDollarsEligible) public onlyAdmin {
    maxInterestDollarsEligible = _maxInterestDollarsEligible;
    emit BackerRewardsSetMaxInterestDollarsEligible(_msgSender(), _maxInterestDollarsEligible);
  }

  /// @inheritdoc IBackerRewards
  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(
    address poolAddress,
    uint256 tokenId
  ) external override {
    require(_msgSender() == config.poolTokensAddress(), "Invalid sender!");
    require(config.getPoolTokens().validPool(poolAddress), "Invalid pool!");
    if (tokens[tokenId].accRewardsPerPrincipalDollarAtMint != 0) {
      return;
    }
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    require(poolAddress == tokenInfo.pool, "PoolAddress must equal PoolToken pool address");

    tokens[tokenId].accRewardsPerPrincipalDollarAtMint = pools[tokenInfo.pool]
      .accRewardsPerPrincipalDollar;
  }

  /// @inheritdoc IBackerRewards
  function onTranchedPoolDrawdown(uint256 sliceIndex) external override onlyPool nonReentrant {
    ITranchedPool pool = ITranchedPool(_msgSender());
    IStakingRewards stakingRewards = _getUpdatedStakingRewards();
    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];
    ITranchedPool.TrancheInfo memory juniorTranche = _getJuniorTrancheForTranchedPoolSlice(
      pool,
      sliceIndex
    );
    uint256 newRewardsAccumulator = stakingRewards.accumulatedRewardsPerToken();

    // On the first drawdown in the lifetime of the pool, we need to initialize
    // the pool local accumulator
    bool poolRewardsHaventBeenInitialized = !_poolStakingRewardsInfoHaveBeenInitialized(poolInfo);
    if (poolRewardsHaventBeenInitialized) {
      _updateStakingRewardsPoolInfoAccumulator(poolInfo, newRewardsAccumulator);
    }

    bool isNewSlice = !_sliceRewardsHaveBeenInitialized(pool, sliceIndex);
    if (isNewSlice) {
      ISeniorPool seniorPool = ISeniorPool(config.seniorPoolAddress());
      uint256 principalDeployedAtDrawdown = _getPrincipalDeployedForTranche(juniorTranche);
      uint256 fiduSharePriceAtDrawdown = seniorPool.sharePrice();

      // initialize new slice params
      StakingRewardsSliceInfo memory sliceInfo = _initializeStakingRewardsSliceInfo(
        fiduSharePriceAtDrawdown,
        principalDeployedAtDrawdown,
        newRewardsAccumulator
      );

      poolStakingRewards[pool].slicesInfo.push(sliceInfo);
    } else {
      // otherwise, its nth drawdown of the slice
      // we need to checkpoint the values here to account for the amount of principal
      // that was at risk between the last checkpoint and now, but we don't publish
      // because backer's shouldn't be able to claim rewards for a drawdown.
      _checkpointSliceStakingRewards(pool, sliceIndex, false);
    }

    _updateStakingRewardsPoolInfoAccumulator(poolInfo, newRewardsAccumulator);
  }

  /**
   * @inheritdoc IBackerRewards
   * @dev The sum of newRewardsClaimed across the split tokens MUST be equal to (or be very slightly smaller
   * than, in the case of rounding due to integer division) the original token's rewardsClaimed. Furthermore,
   * they must be split proportional to the original and new token's principalAmounts. This impl validates
   * neither of those things because only the pool tokens contract can call it, and it trusts that the PoolTokens
   * contract doesn't call maliciously.
   */
  function setBackerAndStakingRewardsTokenInfoOnSplit(
    BackerRewardsTokenInfo memory originalBackerRewardsTokenInfo,
    StakingRewardsTokenInfo memory originalStakingRewardsTokenInfo,
    uint256 newTokenId,
    uint256 newRewardsClaimed
  ) external override onlyPoolTokens {
    tokens[newTokenId] = BackerRewardsTokenInfo({
      rewardsClaimed: newRewardsClaimed,
      accRewardsPerPrincipalDollarAtMint: originalBackerRewardsTokenInfo
        .accRewardsPerPrincipalDollarAtMint
    });
    tokenStakingRewards[newTokenId] = originalStakingRewardsTokenInfo;
  }

  /// @inheritdoc IBackerRewards
  function clearTokenInfo(uint256 tokenId) external override onlyPoolTokens {
    delete tokens[tokenId];
    delete tokenStakingRewards[tokenId];
  }

  /// @inheritdoc IBackerRewards
  function getTokenInfo(
    uint256 poolTokenId
  ) external view override returns (BackerRewardsTokenInfo memory) {
    return tokens[poolTokenId];
  }

  /// @inheritdoc IBackerRewards
  function getStakingRewardsTokenInfo(
    uint256 poolTokenId
  ) external view override returns (StakingRewardsTokenInfo memory) {
    return tokenStakingRewards[poolTokenId];
  }

  /// @inheritdoc IBackerRewards
  function getBackerStakingRewardsPoolInfo(
    ITranchedPool pool
  ) external view override returns (StakingRewardsPoolInfo memory) {
    return poolStakingRewards[pool];
  }

  /**
   * @notice Calculate the gross available gfi rewards for a PoolToken
   * @param tokenId Pool token id
   * @return The amount of GFI claimable
   */
  function poolTokenClaimableRewards(uint256 tokenId) public view override returns (uint256) {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    if (_isSeniorTrancheToken(tokenInfo)) {
      return 0;
    }

    // Note: If a TranchedPool is oversubscribed, reward allocations scale down proportionately.

    uint256 diffOfAccRewardsPerPrincipalDollar = pools[tokenInfo.pool]
      .accRewardsPerPrincipalDollar
      .sub(tokens[tokenId].accRewardsPerPrincipalDollarAtMint);
    uint256 rewardsClaimed = tokens[tokenId].rewardsClaimed.mul(GFI_MANTISSA);

    /*
      equation for token claimable rewards:
        token.principalAmount
        * (pool.accRewardsPerPrincipalDollar - token.accRewardsPerPrincipalDollarAtMint)
        - token.rewardsClaimed
    */

    return
      _usdcToAtomic(tokenInfo.principalAmount)
        .mul(diffOfAccRewardsPerPrincipalDollar)
        .sub(rewardsClaimed)
        .div(GFI_MANTISSA);
  }

  /**
   * @notice Calculates the amount of staking rewards already claimed for a PoolToken.
   * This function is provided for the sake of external (e.g. frontend client) consumption;
   * it is not necessary as an input to the mutative calculations in this contract.
   * @param tokenId Pool token id
   * @return The amount of GFI claimed
   */
  function stakingRewardsClaimed(uint256 tokenId) external view returns (uint256) {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory poolTokenInfo = poolTokens.getTokenInfo(tokenId);

    if (_isSeniorTrancheToken(poolTokenInfo)) {
      return 0;
    }

    ITranchedPool pool = ITranchedPool(poolTokenInfo.pool);
    uint256 sliceIndex = _juniorTrancheIdToSliceIndex(poolTokenInfo.tranche);

    if (
      !_poolRewardsHaveBeenInitialized(pool) || !_sliceRewardsHaveBeenInitialized(pool, sliceIndex)
    ) {
      return 0;
    }

    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    StakingRewardsSliceInfo memory sliceInfo = poolInfo.slicesInfo[sliceIndex];
    StakingRewardsTokenInfo memory tokenInfo = tokenStakingRewards[tokenId];

    uint256 sliceAccumulator = sliceInfo.accumulatedRewardsPerTokenAtDrawdown;
    uint256 tokenAccumulator = _getTokenAccumulatorAtLastWithdraw(tokenInfo, sliceInfo);
    uint256 rewardsPerFidu = tokenAccumulator.sub(sliceAccumulator);
    uint256 principalAsFidu = _fiduToUsdc(
      poolTokenInfo.principalAmount,
      sliceInfo.fiduSharePriceAtDrawdown
    );
    uint256 rewards = principalAsFidu.mul(rewardsPerFidu).div(FIDU_MANTISSA);
    return rewards;
  }

  /**
   * @notice PoolToken request to withdraw multiple PoolTokens allocated rewards
   * @param tokenIds Array of pool token id
   */
  function withdrawMultiple(uint256[] calldata tokenIds) public {
    require(tokenIds.length > 0, "TokensIds length must not be 0");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      withdraw(tokenIds[i]);
    }
  }

  /// @inheritdoc IBackerRewards
  function withdraw(uint256 tokenId) public override whenNotPaused nonReentrant returns (uint256) {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    address poolAddr = tokenInfo.pool;
    require(config.getPoolTokens().validPool(poolAddr), "Invalid pool!");
    require(msg.sender == poolTokens.ownerOf(tokenId), "Must be owner of PoolToken");

    BaseUpgradeablePausable pool = BaseUpgradeablePausable(poolAddr);
    require(!pool.paused(), "Pool withdraw paused");

    ITranchedPool tranchedPool = ITranchedPool(poolAddr);
    require(!tranchedPool.creditLine().isLate(), "Pool is late on payments");

    require(!_isSeniorTrancheToken(tokenInfo), "Ineligible senior tranche token");

    uint256 claimableBackerRewards = poolTokenClaimableRewards(tokenId);
    uint256 claimableStakingRewards = stakingRewardsEarnedSinceLastWithdraw(tokenId);
    uint256 totalClaimableRewards = claimableBackerRewards.add(claimableStakingRewards);
    uint256 poolTokenRewardsClaimed = tokens[tokenId].rewardsClaimed;

    // Only account for claimed backer rewards, the staking rewards should not impact the
    // distribution of backer rewards
    tokens[tokenId].rewardsClaimed = poolTokenRewardsClaimed.add(claimableBackerRewards);

    if (claimableStakingRewards != 0) {
      _checkpointTokenStakingRewards(tokenId);
    }

    config.getGFI().safeERC20Transfer(poolTokens.ownerOf(tokenId), totalClaimableRewards);
    emit BackerRewardsClaimed(
      _msgSender(),
      tokenId,
      claimableBackerRewards,
      claimableStakingRewards
    );

    return totalClaimableRewards;
  }

  /**
   * @notice Returns the amount of staking rewards earned by a given token since the last
   * time its staking rewards were withdrawn.
   * @param tokenId token id to get rewards
   * @return amount of rewards
   */
  function stakingRewardsEarnedSinceLastWithdraw(uint256 tokenId) public view returns (uint256) {
    IPoolTokens.TokenInfo memory poolTokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    if (_isSeniorTrancheToken(poolTokenInfo)) {
      return 0;
    }

    ITranchedPool pool = ITranchedPool(poolTokenInfo.pool);
    uint256 sliceIndex = _juniorTrancheIdToSliceIndex(poolTokenInfo.tranche);

    if (
      !_poolRewardsHaveBeenInitialized(pool) || !_sliceRewardsHaveBeenInitialized(pool, sliceIndex)
    ) {
      return 0;
    }

    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    StakingRewardsSliceInfo memory sliceInfo = poolInfo.slicesInfo[sliceIndex];
    StakingRewardsTokenInfo memory tokenInfo = tokenStakingRewards[tokenId];

    uint256 sliceAccumulator = _getSliceAccumulatorAtLastCheckpoint(sliceInfo, poolInfo);
    uint256 tokenAccumulator = _getTokenAccumulatorAtLastWithdraw(tokenInfo, sliceInfo);
    uint256 rewardsPerFidu = sliceAccumulator.sub(tokenAccumulator);
    uint256 principalAsFidu = _fiduToUsdc(
      poolTokenInfo.principalAmount,
      sliceInfo.fiduSharePriceAtDrawdown
    );
    uint256 rewards = principalAsFidu.mul(rewardsPerFidu).div(FIDU_MANTISSA);
    return rewards;
  }

  /* Internal functions  */
  function _allocateRewards(uint256 _interestPaymentAmount) internal {
    uint256 _totalInterestReceived = totalInterestReceived;
    if (_usdcToAtomic(_totalInterestReceived) >= maxInterestDollarsEligible) {
      return;
    }

    address _poolAddress = _msgSender();

    // Gross GFI Rewards earned for incoming interest dollars
    uint256 newGrossRewards = _calculateNewGrossGFIRewardsForInterestAmount(_interestPaymentAmount);

    ITranchedPool pool = ITranchedPool(_poolAddress);
    BackerRewardsInfo storage _poolInfo = pools[_poolAddress];

    uint256 totalJuniorDepositsAtomic = _usdcToAtomic(pool.totalJuniorDeposits());
    // If total junior deposits are 0, or less than 1, allocate no rewards. The latter condition
    // is necessary to prevent a perverse, "infinite mint" scenario in which we'd allocate
    // an even greater amount of rewards than `newGrossRewards`, due to dividing by less than 1.
    // This scenario and its mitigation are analogous to that of
    // `StakingRewards.additionalRewardsPerTokenSinceLastUpdate()`.

    if (totalJuniorDepositsAtomic < GFI_MANTISSA) {
      emit SafetyCheckTriggered();
      return;
    }

    // example: (6708203932437400000000 * 10^18) / (100000*10^18)
    _poolInfo.accRewardsPerPrincipalDollar = _poolInfo.accRewardsPerPrincipalDollar.add(
      newGrossRewards.mul(GFI_MANTISSA).div(totalJuniorDepositsAtomic)
    );

    totalInterestReceived = _totalInterestReceived.add(_interestPaymentAmount);
  }

  function _allocateStakingRewards() internal {
    ITranchedPool pool = ITranchedPool(_msgSender());

    // only accrue rewards on a full repayment
    ICreditLine cl = pool.creditLine();
    bool wasFullRepayment = cl.lastFullPaymentTime() > 0 &&
      cl.lastFullPaymentTime() <= block.timestamp &&
      cl.principalOwed() == 0 &&
      cl.interestOwed() == 0;
    if (wasFullRepayment) {
      // in the case of a full repayment, we want to checkpoint rewards and make them claimable
      // to backers by publishing
      _checkpointPoolStakingRewards(pool, true);
    }
  }

  /**
   * @notice Checkpoints staking reward accounting for a given pool.
   * @param pool pool to checkpoint
   * @param publish if true, the updated rewards values will be immediately available for
   *                 backers to withdraw. otherwise, the accounting will be updated but backers
   *                 will not be able to withdraw
   */
  function _checkpointPoolStakingRewards(ITranchedPool pool, bool publish) internal {
    IStakingRewards stakingRewards = _getUpdatedStakingRewards();
    uint256 newStakingRewardsAccumulator = stakingRewards.accumulatedRewardsPerToken();
    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];

    // If for any reason the new accumulator is less than our last one, abort for safety.
    if (newStakingRewardsAccumulator < poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint) {
      emit SafetyCheckTriggered();
      return;
    }

    // iterate through all of the slices and checkpoint
    for (uint256 sliceIndex = 0; sliceIndex < poolInfo.slicesInfo.length; sliceIndex++) {
      _checkpointSliceStakingRewards(pool, sliceIndex, publish);
    }

    _updateStakingRewardsPoolInfoAccumulator(poolInfo, newStakingRewardsAccumulator);
  }

  /**
   * @notice checkpoint the staking rewards accounting for a single tranched pool slice
   * @param pool pool that the slice belongs to
   * @param sliceIndex index of slice to checkpoint rewards accounting for
   * @param publish if true, the updated rewards values will be immediately available for
   *                 backers to withdraw. otherwise, the accounting will be updated but backers
   *                 will not be able to withdraw
   */
  function _checkpointSliceStakingRewards(
    ITranchedPool pool,
    uint256 sliceIndex,
    bool publish
  ) internal {
    StakingRewardsPoolInfo storage poolInfo = poolStakingRewards[pool];
    StakingRewardsSliceInfo storage sliceInfo = poolInfo.slicesInfo[sliceIndex];
    IStakingRewards stakingRewards = _getUpdatedStakingRewards();
    ITranchedPool.TrancheInfo memory juniorTranche = _getJuniorTrancheForTranchedPoolSlice(
      pool,
      sliceIndex
    );
    uint256 newStakingRewardsAccumulator = stakingRewards.accumulatedRewardsPerToken();

    // If for any reason the new accumulator is less than our last one, abort for safety.
    if (newStakingRewardsAccumulator < poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint) {
      emit SafetyCheckTriggered();
      return;
    }
    uint256 rewardsAccruedSinceLastCheckpoint = newStakingRewardsAccumulator.sub(
      poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint
    );

    // We pro rate rewards if we're beyond the term date by approximating
    // taking the current reward rate and multiplying it by the time
    // that we left in the term divided by the time since we last updated
    bool shouldProRate = block.timestamp > pool.creditLine().termEndTime();
    if (shouldProRate) {
      rewardsAccruedSinceLastCheckpoint = _calculateProRatedRewardsForPeriod(
        rewardsAccruedSinceLastCheckpoint,
        poolInfo.lastUpdateTime,
        block.timestamp,
        pool.creditLine().termEndTime()
      );
    }

    uint256 newPrincipalDeployed = _getPrincipalDeployedForTranche(juniorTranche);

    // the percentage we need to scale the rewards accumualated by
    uint256 deployedScalingFactor = _usdcToAtomic(
      sliceInfo.principalDeployedAtLastCheckpoint.mul(USDC_MANTISSA).div(
        juniorTranche.principalDeposited
      )
    );

    uint256 scaledRewardsForPeriod = rewardsAccruedSinceLastCheckpoint
      .mul(deployedScalingFactor)
      .div(FIDU_MANTISSA);

    sliceInfo.unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint = sliceInfo
      .unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint
      .add(scaledRewardsForPeriod);

    sliceInfo.principalDeployedAtLastCheckpoint = newPrincipalDeployed;
    if (publish) {
      sliceInfo.accumulatedRewardsPerTokenAtLastCheckpoint = sliceInfo
        .unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint;
    }
  }

  /**
   * @notice Updates the staking rewards accounting for for a given tokenId
   * @param tokenId token id to checkpoint
   */
  function _checkpointTokenStakingRewards(uint256 tokenId) internal {
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    require(!_isSeniorTrancheToken(tokenInfo), "Ineligible senior tranche token");

    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    uint256 sliceIndex = _juniorTrancheIdToSliceIndex(tokenInfo.tranche);
    StakingRewardsSliceInfo memory sliceInfo = poolInfo.slicesInfo[sliceIndex];

    uint256 newAccumulatedRewardsPerTokenAtLastWithdraw = _getSliceAccumulatorAtLastCheckpoint(
      sliceInfo,
      poolInfo
    );

    // If for any reason the new accumulator is less than our last one, abort for safety.
    if (
      newAccumulatedRewardsPerTokenAtLastWithdraw <
      tokenStakingRewards[tokenId].accumulatedRewardsPerTokenAtLastWithdraw
    ) {
      emit SafetyCheckTriggered();
      return;
    }

    tokenStakingRewards[tokenId]
      .accumulatedRewardsPerTokenAtLastWithdraw = newAccumulatedRewardsPerTokenAtLastWithdraw;
  }

  /**
   * @notice Calculate the rewards earned for a given interest payment
   * @param _interestPaymentAmount interest payment amount times 1e6
   */
  function _calculateNewGrossGFIRewardsForInterestAmount(
    uint256 _interestPaymentAmount
  ) internal view returns (uint256) {
    uint256 totalGFISupply = config.getGFI().totalSupply();

    // incoming interest payment, times * 1e18 divided by 1e6
    uint256 interestPaymentAmount = _usdcToAtomic(_interestPaymentAmount);

    // all-time interest payments prior to the incoming amount, times 1e18
    uint256 _previousTotalInterestReceived = _usdcToAtomic(totalInterestReceived);
    uint256 sqrtOrigTotalInterest = Babylonian.sqrt(_previousTotalInterestReceived);

    // sum of new interest payment + previous total interest payments, times 1e18
    uint256 newTotalInterest = _usdcToAtomic(
      _atomicToUsdc(_previousTotalInterestReceived).add(_atomicToUsdc(interestPaymentAmount))
    );

    // interest payment passed the maxInterestDollarsEligible cap, should only partially be rewarded
    if (newTotalInterest > maxInterestDollarsEligible) {
      newTotalInterest = maxInterestDollarsEligible;
    }

    /*
      equation:
        (sqrtNewTotalInterest-sqrtOrigTotalInterest)
        * totalRewardPercentOfTotalGFI
        / sqrtMaxInterestDollarsEligible
        / 100
        * totalGFISupply
        / 10^18

      example scenario:
      - new payment = 5000*10^18
      - original interest received = 0*10^18
      - total reward percent = 3 * 10^18
      - max interest dollars = 1 * 10^27 ($1 billion)
      - totalGfiSupply = 100_000_000 * 10^18

      example math:
        (70710678118 - 0)
        * 3000000000000000000
        / 31622776601683
        / 100
        * 100000000000000000000000000
        / 10^18
        = 6708203932437400000000 (6,708.2039 GFI)
    */
    uint256 sqrtDiff = Babylonian.sqrt(newTotalInterest).sub(sqrtOrigTotalInterest);
    uint256 sqrtMaxInterestDollarsEligible = Babylonian.sqrt(maxInterestDollarsEligible);

    require(sqrtMaxInterestDollarsEligible > 0, "maxInterestDollarsEligible must not be zero");

    uint256 newGrossRewards = sqrtDiff
      .mul(totalRewardPercentOfTotalGFI)
      .div(sqrtMaxInterestDollarsEligible)
      .div(100)
      .mul(totalGFISupply)
      .div(GFI_MANTISSA);

    // Extra safety check to make sure the logic is capped at a ceiling of potential rewards
    // Calculating the gfi/$ for first dollar of interest to the protocol, and multiplying by new interest amount
    uint256 absoluteMaxGfiCheckPerDollar = Babylonian
      .sqrt((uint256)(1).mul(GFI_MANTISSA))
      .mul(totalRewardPercentOfTotalGFI)
      .div(sqrtMaxInterestDollarsEligible)
      .div(100)
      .mul(totalGFISupply)
      .div(GFI_MANTISSA);
    require(
      newGrossRewards < absoluteMaxGfiCheckPerDollar.mul(newTotalInterest),
      "newGrossRewards cannot be greater then the max gfi per dollar"
    );

    return newGrossRewards;
  }

  /**
   * @return Whether the provided `tokenInfo` is a token corresponding to a senior tranche.
   */
  function _isSeniorTrancheToken(
    IPoolTokens.TokenInfo memory tokenInfo
  ) internal pure returns (bool) {
    return tokenInfo.tranche.mod(NUM_TRANCHES_PER_SLICE) == 1;
  }

  /// @notice Returns an amount with the base of usdc (1e6) as an 1e18 number
  function _usdcToAtomic(uint256 amount) internal pure returns (uint256) {
    return amount.mul(GFI_MANTISSA).div(USDC_MANTISSA);
  }

  /// @notice Returns an amount with the base 1e18 as a usdc amount (1e6)
  function _atomicToUsdc(uint256 amount) internal pure returns (uint256) {
    return amount.div(GFI_MANTISSA.div(USDC_MANTISSA));
  }

  /// @notice Returns the equivalent amount of USDC given an amount of fidu and a share price
  /// @param amount amount of FIDU
  /// @param sharePrice share price of FIDU
  /// @return equivalent amount of USDC
  function _fiduToUsdc(uint256 amount, uint256 sharePrice) internal pure returns (uint256) {
    return _usdcToAtomic(amount).mul(FIDU_MANTISSA).div(sharePrice);
  }

  /// @notice Returns the junior tranche id for the given slice index
  /// @param index slice index
  /// @return junior tranche id of given slice index
  function _sliceIndexToJuniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.add(1).mul(2);
  }

  /// @notice Returns the slice index for the given junior tranche id
  /// @param trancheId tranche id
  /// @return slice index that the given tranche id belongs to
  function _juniorTrancheIdToSliceIndex(uint256 trancheId) internal pure returns (uint256) {
    return trancheId.sub(1).div(2);
  }

  /// @notice get the StakingRewards contract after checkpoint the rewards values
  /// @return StakingRewards with updated rewards values
  function _getUpdatedStakingRewards() internal returns (IStakingRewards) {
    IStakingRewards stakingRewards = IStakingRewards(config.stakingRewardsAddress());
    if (stakingRewards.lastUpdateTime() != block.timestamp) {
      // This triggers rewards to update
      stakingRewards.kick(0);
    }
    return stakingRewards;
  }

  /// @notice Returns true if a TranchedPool's rewards parameters have been initialized, otherwise false
  /// @param pool pool to check rewards info
  function _poolRewardsHaveBeenInitialized(ITranchedPool pool) internal view returns (bool) {
    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    return _poolStakingRewardsInfoHaveBeenInitialized(poolInfo);
  }

  /// @notice Returns true if a given pool's staking rewards parameters have been initialized
  function _poolStakingRewardsInfoHaveBeenInitialized(
    StakingRewardsPoolInfo memory poolInfo
  ) internal pure returns (bool) {
    return poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint != 0;
  }

  /// @notice Returns true if a TranchedPool's slice's rewards parameters have been initialized, otherwise false
  function _sliceRewardsHaveBeenInitialized(
    ITranchedPool pool,
    uint256 sliceIndex
  ) internal view returns (bool) {
    StakingRewardsPoolInfo memory poolInfo = poolStakingRewards[pool];
    return
      poolInfo.slicesInfo.length > sliceIndex &&
      poolInfo.slicesInfo[sliceIndex].unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint != 0;
  }

  /// @notice Return a slice's rewards accumulator if it has been intialized,
  ///           otherwise return the TranchedPool's accumulator
  function _getSliceAccumulatorAtLastCheckpoint(
    StakingRewardsSliceInfo memory sliceInfo,
    StakingRewardsPoolInfo memory poolInfo
  ) internal pure returns (uint256) {
    require(
      poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint != 0,
      "unsafe: pool accumulator hasn't been initialized"
    );
    bool sliceHasNotReceivedAPayment = sliceInfo.accumulatedRewardsPerTokenAtLastCheckpoint == 0;
    return
      sliceHasNotReceivedAPayment
        ? poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint
        : sliceInfo.accumulatedRewardsPerTokenAtLastCheckpoint;
  }

  /// @notice Return a tokenss rewards accumulator if its been initialized, otherwise return the slice's accumulator
  function _getTokenAccumulatorAtLastWithdraw(
    StakingRewardsTokenInfo memory tokenInfo,
    StakingRewardsSliceInfo memory sliceInfo
  ) internal pure returns (uint256) {
    require(
      sliceInfo.accumulatedRewardsPerTokenAtDrawdown != 0,
      "unsafe: slice accumulator hasn't been initialized"
    );
    bool hasNotWithdrawn = tokenInfo.accumulatedRewardsPerTokenAtLastWithdraw == 0;
    if (hasNotWithdrawn) {
      return sliceInfo.accumulatedRewardsPerTokenAtDrawdown;
    } else {
      require(
        tokenInfo.accumulatedRewardsPerTokenAtLastWithdraw >=
          sliceInfo.accumulatedRewardsPerTokenAtDrawdown,
        "Unexpected token accumulator"
      );
      return tokenInfo.accumulatedRewardsPerTokenAtLastWithdraw;
    }
  }

  /// @notice Returns the junior tranche of a pool given a slice index
  /// @param pool pool to retreive tranche from
  /// @param sliceIndex slice index
  /// @return tranche in specified slice and pool
  function _getJuniorTrancheForTranchedPoolSlice(
    ITranchedPool pool,
    uint256 sliceIndex
  ) internal view returns (ITranchedPool.TrancheInfo memory) {
    uint256 trancheId = _sliceIndexToJuniorTrancheId(sliceIndex);
    return pool.getTranche(trancheId);
  }

  /// @notice Return the amount of principal currently deployed in a given slice
  /// @param tranche tranche to get principal outstanding of
  function _getPrincipalDeployedForTranche(
    ITranchedPool.TrancheInfo memory tranche
  ) internal pure returns (uint256) {
    return
      tranche.principalDeposited.sub(
        _atomicToUsdc(
          tranche.principalSharePrice.mul(_usdcToAtomic(tranche.principalDeposited)).div(
            FIDU_MANTISSA
          )
        )
      );
  }

  /// @notice Return an initialized StakingRewardsSliceInfo with the given parameters
  function _initializeStakingRewardsSliceInfo(
    uint256 fiduSharePriceAtDrawdown,
    uint256 principalDeployedAtDrawdown,
    uint256 rewardsAccumulatorAtDrawdown
  ) internal pure returns (StakingRewardsSliceInfo memory) {
    return
      StakingRewardsSliceInfo({
        fiduSharePriceAtDrawdown: fiduSharePriceAtDrawdown,
        principalDeployedAtLastCheckpoint: principalDeployedAtDrawdown,
        accumulatedRewardsPerTokenAtDrawdown: rewardsAccumulatorAtDrawdown,
        accumulatedRewardsPerTokenAtLastCheckpoint: rewardsAccumulatorAtDrawdown,
        unrealizedAccumulatedRewardsPerTokenAtLastCheckpoint: rewardsAccumulatorAtDrawdown
      });
  }

  /// @notice Returns the amount of rewards accrued from `lastUpdatedTime` to `endTime`
  ///           We assume the reward rate was linear during this time
  /// @param rewardsAccruedSinceLastCheckpoint rewards accumulated between `lastUpdatedTime` and `currentTime`
  /// @param lastUpdatedTime the last timestamp the rewards accumulator was updated
  /// @param currentTime the current timestamp
  /// @param endTime the end time of the period that is elligible to accrue rewards
  /// @return approximate rewards accrued from `lastUpdateTime` to `endTime`
  function _calculateProRatedRewardsForPeriod(
    uint256 rewardsAccruedSinceLastCheckpoint,
    uint256 lastUpdatedTime,
    uint256 currentTime,
    uint256 endTime
  ) internal pure returns (uint256) {
    uint256 slopeNumerator = rewardsAccruedSinceLastCheckpoint.mul(FIDU_MANTISSA);
    uint256 slopeDivisor = currentTime.sub(lastUpdatedTime);

    uint256 slope = slopeNumerator.div(slopeDivisor);
    uint256 span = endTime.sub(lastUpdatedTime);
    uint256 rewards = slope.mul(span).div(FIDU_MANTISSA);
    return rewards;
  }

  /// @notice update a Pool's staking rewards accumulator
  function _updateStakingRewardsPoolInfoAccumulator(
    StakingRewardsPoolInfo storage poolInfo,
    uint256 newAccumulatorValue
  ) internal {
    poolInfo.accumulatedRewardsPerTokenAtLastCheckpoint = newAccumulatorValue;
    poolInfo.lastUpdateTime = block.timestamp;
  }

  /* ======== MODIFIERS  ======== */

  modifier onlyPoolTokens() {
    require(msg.sender == address(config.getPoolTokens()), "Not PoolTokens");
    _;
  }

  modifier onlyPool() {
    require(config.getPoolTokens().validPool(_msgSender()), "Invalid pool!");
    _;
  }

  /* ======== EVENTS ======== */
  event BackerRewardsClaimed(
    address indexed owner,
    uint256 indexed tokenId,
    uint256 amountOfTranchedPoolRewards,
    uint256 amountOfSeniorPoolRewards
  );
  event BackerRewardsSetTotalRewards(
    address indexed owner,
    uint256 totalRewards,
    uint256 totalRewardPercentOfTotalGFI
  );
  event BackerRewardsSetTotalInterestReceived(address indexed owner, uint256 totalInterestReceived);
  event BackerRewardsSetMaxInterestDollarsEligible(
    address indexed owner,
    uint256 maxInterestDollarsEligible
  );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuardUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

import {ERC721PresetMinterPauserAutoIdUpgradeSafe} from "../external/ERC721PresetMinterPauserAutoId.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {ICommunityRewards} from "../interfaces/ICommunityRewards.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";

import {CommunityRewardsVesting} from "../library/CommunityRewardsVesting.sol";

contract CommunityRewards is
  ICommunityRewards,
  ERC721PresetMinterPauserAutoIdUpgradeSafe,
  ReentrancyGuardUpgradeSafe
{
  using SafeERC20 for IERC20withDec;
  using ConfigHelper for GoldfinchConfig;

  using CommunityRewardsVesting for CommunityRewardsVesting.Rewards;

  /* ==========     EVENTS      ========== */

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  /* ========== STATE VARIABLES ========== */

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

  GoldfinchConfig public config;

  /// @notice Total rewards available for granting, denominated in `rewardsToken()`
  uint256 public rewardsAvailable;

  /// @notice Token launch time in seconds. This is used in vesting.
  uint256 public tokenLaunchTimeInSeconds;

  /// @dev NFT tokenId => rewards grant
  mapping(uint256 => CommunityRewardsVesting.Rewards) public grants;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(
    address owner,
    GoldfinchConfig _config,
    uint256 _tokenLaunchTimeInSeconds
  ) external initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );

    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained("Goldfinch V2 Community Rewards Tokens", "GFI-V2-CR");
    __ERC721Pausable_init_unchained();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(DISTRIBUTOR_ROLE, owner);

    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(DISTRIBUTOR_ROLE, OWNER_ROLE);

    tokenLaunchTimeInSeconds = _tokenLaunchTimeInSeconds;

    config = _config;
  }

  /* ========== VIEWS ========== */

  /// @notice The token being disbursed as rewards
  function rewardsToken() public view override returns (IERC20withDec) {
    return config.getGFI();
  }

  /// @notice Returns the rewards claimable by a given grant token, taking into
  ///   account vesting schedule.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function claimableRewards(uint256 tokenId) public view override returns (uint256 rewards) {
    return grants[tokenId].claimable();
  }

  /// @notice Returns the rewards that will have vested for some grant with the given params.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) external pure override returns (uint256 rewards) {
    return
      CommunityRewardsVesting.getTotalVestedAt(
        start,
        end,
        granted,
        cliffLength,
        vestingInterval,
        revokedAt,
        time
      );
  }

  /* ========== MUTATIVE, ADMIN-ONLY FUNCTIONS ========== */

  /// @notice Transfer rewards from msg.sender, to be used for reward distribution
  function loadRewards(uint256 rewards) external override onlyAdmin {
    require(rewards > 0, "Cannot load 0 rewards");

    rewardsAvailable = rewardsAvailable.add(rewards);

    rewardsToken().safeTransferFrom(msg.sender, address(this), rewards);

    emit RewardAdded(rewards);
  }

  /// @notice Revokes rewards that have not yet vested, for a grant. The unvested rewards are
  /// now considered available for allocation in another grant.
  /// @param tokenId The tokenId corresponding to the grant whose unvested rewards to revoke.
  function revokeGrant(uint256 tokenId) external override whenNotPaused onlyAdmin {
    CommunityRewardsVesting.Rewards storage grant = grants[tokenId];

    require(grant.totalGranted > 0, "Grant not defined for token id");
    require(grant.revokedAt == 0, "Grant has already been revoked");

    uint256 totalUnvested = grant.totalUnvestedAt(block.timestamp);
    require(totalUnvested > 0, "Grant has fully vested");

    rewardsAvailable = rewardsAvailable.add(totalUnvested);

    grant.revokedAt = block.timestamp;

    emit GrantRevoked(tokenId, totalUnvested);
  }

  function setTokenLaunchTimeInSeconds(uint256 _tokenLaunchTimeInSeconds) external onlyAdmin {
    tokenLaunchTimeInSeconds = _tokenLaunchTimeInSeconds;
  }

  /* ========== MUTATIVE, NON-ADMIN-ONLY FUNCTIONS ========== */

  /// @notice Grant rewards to a recipient. The recipient address receives an
  ///   an NFT representing their rewards grant. They can present the NFT to `getReward()`
  ///   to claim their rewards. Rewards vest over a schedule. If the given `vestingInterval`
  ///   is 0, then `vestingInterval` will be equal to `vestingLength`.
  /// @param recipient The recipient of the grant.
  /// @param amount The amount of `rewardsToken()` to grant.
  /// @param vestingLength The duration (in seconds) over which the grant vests.
  /// @param cliffLength The duration (in seconds) from the start of the grant, before which has elapsed
  /// the vested amount remains 0.
  /// @param vestingInterval The interval (in seconds) at which vesting occurs.
  function grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) external override nonReentrant whenNotPaused onlyDistributor returns (uint256 tokenId) {
    return _grant(recipient, amount, vestingLength, cliffLength, vestingInterval);
  }

  function _grant(
    address recipient,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval
  ) internal returns (uint256 tokenId) {
    require(amount > 0, "Cannot grant 0 amount");
    require(cliffLength <= vestingLength, "Cliff length cannot exceed vesting length");
    require(amount <= rewardsAvailable, "Cannot grant amount due to insufficient funds");
    require(vestingInterval <= vestingLength, "Invalid vestingInterval");

    if (vestingInterval == 0) {
      vestingInterval = vestingLength;
    }

    rewardsAvailable = rewardsAvailable.sub(amount);

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    grants[tokenId] = CommunityRewardsVesting.Rewards({
      totalGranted: amount,
      totalClaimed: 0,
      startTime: tokenLaunchTimeInSeconds,
      endTime: tokenLaunchTimeInSeconds.add(vestingLength),
      cliffLength: cliffLength,
      vestingInterval: vestingInterval,
      revokedAt: 0
    });

    _mint(recipient, tokenId);

    emit Granted(recipient, tokenId, amount, vestingLength, cliffLength, vestingInterval);

    return tokenId;
  }

  /// @notice Claim rewards for a given grant
  /// @param tokenId A grant token ID
  function getReward(uint256 tokenId) external override nonReentrant whenNotPaused {
    require(ownerOf(tokenId) == msg.sender, "access denied");
    uint256 reward = claimableRewards(tokenId);
    if (reward > 0) {
      grants[tokenId].claim(reward);
      rewardsToken().safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, tokenId, reward);
    }
  }

  function totalUnclaimed(address owner) external view returns (uint256) {
    uint256 result = 0;
    for (uint256 i = 0; i < balanceOf(owner); i++) {
      uint256 tokenId = tokenOfOwnerByIndex(owner, i);
      result = result.add(_unclaimed(tokenId));
    }
    return result;
  }

  function unclaimed(uint256 tokenId) external view returns (uint256) {
    return _unclaimed(tokenId);
  }

  function _unclaimed(uint256 tokenId) internal view returns (uint256) {
    return grants[tokenId].totalGranted - grants[tokenId].totalClaimed;
  }

  /* ========== MODIFIERS ========== */

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }

  function isDistributor() public view returns (bool) {
    return hasRole(DISTRIBUTOR_ROLE, _msgSender());
  }

  modifier onlyDistributor() {
    require(isDistributor(), "Must have distributor role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/MerkleDistributor.sol.
pragma solidity 0.6.12;

import {MerkleProof} from "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {IMerkleDirectDistributor} from "../interfaces/IMerkleDirectDistributor.sol";
import {BaseUpgradeablePausable} from "../protocol/core/BaseUpgradeablePausable.sol";

contract MerkleDirectDistributor is IMerkleDirectDistributor, BaseUpgradeablePausable {
  using SafeERC20 for IERC20withDec;

  address public override gfi;
  bytes32 public override merkleRoot;

  // @dev This is a packed array of booleans.
  mapping(uint256 => uint256) private acceptedBitMap;

  function initialize(address owner, address _gfi, bytes32 _merkleRoot) public initializer {
    require(owner != address(0), "Owner address cannot be empty");
    require(_gfi != address(0), "GFI address cannot be empty");
    require(_merkleRoot != 0, "Invalid Merkle root");

    __BaseUpgradeablePausable__init(owner);

    gfi = _gfi;
    merkleRoot = _merkleRoot;
  }

  function isGrantAccepted(uint256 index) public view override returns (bool) {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    uint256 acceptedWord = acceptedBitMap[acceptedWordIndex];
    uint256 mask = (1 << acceptedBitIndex);
    return acceptedWord & mask == mask;
  }

  function _setGrantAccepted(uint256 index) private {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    acceptedBitMap[acceptedWordIndex] = acceptedBitMap[acceptedWordIndex] | (1 << acceptedBitIndex);
  }

  function acceptGrant(
    uint256 index,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override whenNotPaused {
    require(!isGrantAccepted(index), "Grant already accepted");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it accepted and perform the granting.
    _setGrantAccepted(index);
    IERC20withDec(gfi).safeTransfer(msg.sender, amount);

    emit GrantAccepted(index, msg.sender, amount);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/MerkleDistributor.sol.
pragma solidity 0.6.12;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import "../interfaces/ICommunityRewards.sol";
import "../interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
  address public immutable override communityRewards;
  bytes32 public immutable override merkleRoot;

  // @dev This is a packed array of booleans.
  mapping(uint256 => uint256) private acceptedBitMap;

  constructor(address communityRewards_, bytes32 merkleRoot_) public {
    require(communityRewards_ != address(0), "Cannot use the null address");
    require(merkleRoot_ != 0, "Invalid merkle root provided");
    communityRewards = communityRewards_;
    merkleRoot = merkleRoot_;
  }

  function isGrantAccepted(uint256 index) public view override returns (bool) {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    uint256 acceptedWord = acceptedBitMap[acceptedWordIndex];
    uint256 mask = (1 << acceptedBitIndex);
    return acceptedWord & mask == mask;
  }

  function _setGrantAccepted(uint256 index) private {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    acceptedBitMap[acceptedWordIndex] = acceptedBitMap[acceptedWordIndex] | (1 << acceptedBitIndex);
  }

  function acceptGrant(
    uint256 index,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isGrantAccepted(index), "Grant already accepted");

    /*
     *
     * Verify the merkle proof.
     *
     * Per the Warning in
     * https://github.com/ethereum/solidity/blob/v0.6.12/docs/abi-spec.rst#non-standard-packed-mode,
     * it is important that no more than one of the arguments to `abi.encodePacked()` here be a
     * dynamic type (see definition in
     * https://github.com/ethereum/solidity/blob/v0.6.12/docs/abi-spec.rst#formal-specification-of-the-encoding).
     */
    bytes32 node = keccak256(
      abi.encodePacked(index, msg.sender, amount, vestingLength, cliffLength, vestingInterval)
    );
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it accepted and perform the granting.
    _setGrantAccepted(index);
    uint256 tokenId = ICommunityRewards(communityRewards).grant(
      msg.sender,
      amount,
      vestingLength,
      cliffLength,
      vestingInterval
    );

    emit GrantAccepted(
      tokenId,
      index,
      msg.sender,
      amount,
      vestingLength,
      cliffLength,
      vestingInterval
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuardUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";

import {ERC721PresetMinterPauserAutoIdUpgradeSafe} from "../external/ERC721PresetMinterPauserAutoId.sol";
import {IERC20withDec, IERC20} from "../interfaces/IERC20withDec.sol";
import {ISeniorPool} from "../interfaces/ISeniorPool.sol";
import {ICurveLP} from "../interfaces/ICurveLP.sol";
import {IFidu} from "../interfaces/IFidu.sol";
import {IStakingRewards, StakedPosition, StakedPositionType} from "../interfaces/IStakingRewards.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";
import {StakingRewardsVesting} from "../library/StakingRewardsVesting.sol";

import {StakingRewardsVesting, Rewards} from "../library/StakingRewardsVesting.sol";

// solhint-disable-next-line max-states-count
contract StakingRewards is
  ERC721PresetMinterPauserAutoIdUpgradeSafe,
  ReentrancyGuardUpgradeSafe,
  IStakingRewards
{
  using SafeERC20 for IERC20withDec;
  using SafeERC20 for IERC20;
  using ConfigHelper for GoldfinchConfig;

  using StakingRewardsVesting for Rewards;

  enum LockupPeriod {
    SixMonths,
    TwelveMonths,
    TwentyFourMonths
  }

  /* ========== STATE VARIABLES ========== */

  uint256 private constant MULTIPLIER_DECIMALS = 1e18;
  uint256 private constant USDC_MANTISSA = 1e6;

  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  GoldfinchConfig public config;

  /// @notice The block timestamp when rewards were last checkpointed
  uint256 public override lastUpdateTime;

  /// @notice Accumulated rewards per token at the last checkpoint
  uint256 public override accumulatedRewardsPerToken;

  /// @notice Total rewards available for disbursement at the last checkpoint, denominated in `rewardsToken()`
  uint256 public rewardsAvailable;

  /// @notice StakedPosition tokenId => accumulatedRewardsPerToken at the position's last checkpoint
  mapping(uint256 => uint256) public positionToAccumulatedRewardsPerToken;

  /// @notice Desired supply of staked tokens. The reward rate adjusts in a range
  ///   around this value to incentivize staking or unstaking to maintain it.
  uint256 public targetCapacity;

  /// @notice The minimum total disbursed rewards per second, denominated in `rewardsToken()`
  uint256 public minRate;

  /// @notice The maximum total disbursed rewards per second, denominated in `rewardsToken()`
  uint256 public maxRate;

  /// @notice The percent of `targetCapacity` at which the reward rate reaches `maxRate`.
  ///  Represented with `MULTIPLIER_DECIMALS`.
  uint256 public maxRateAtPercent;

  /// @notice The percent of `targetCapacity` at which the reward rate reaches `minRate`.
  ///  Represented with `MULTIPLIER_DECIMALS`.
  uint256 public minRateAtPercent;

  /// @notice The duration in seconds over which legacy rewards vest. New positions have no vesting
  ///  and earn rewards immediately.
  /// @dev UNUSED (definition kept for storage slot)
  uint256 public vestingLength;

  /// @dev Supply of staked tokens, denominated in `stakingToken().decimals()`
  /// @dev Note that due to the use of `unsafeBaseTokenExchangeRate` and `unsafeEffectiveMultiplier` on
  /// a StakedPosition, the sum of `amount` across all staked positions will not necessarily
  /// equal this `totalStakedSupply` value; the purpose of the base token exchange rate and
  /// the effective multiplier is to enable calculation of an "effective amount" -- which is
  /// what this `totalStakedSupply` represents the sum of.
  uint256 public totalStakedSupply;

  /// @dev UNUSED (definition kept for storage slot)
  uint256 private totalLeveragedStakedSupply;

  /// @dev UNUSED (definition kept for storage slot)
  mapping(LockupPeriod => uint256) private leverageMultipliers;

  /// @dev NFT tokenId => staked position
  mapping(uint256 => StakedPosition) public positions;

  /// @dev A mapping of staked position types to multipliers used to denominate positions
  ///   in `baseStakingToken()`. Represented with `MULTIPLIER_DECIMALS`.
  mapping(StakedPositionType => uint256) private effectiveMultipliers;

  // solhint-disable-next-line func-name-mixedcase
  function __initialize__(address owner, GoldfinchConfig _config) external initializer {
    __Context_init_unchained();
    __ERC165_init_unchained();
    __ERC721_init_unchained("Goldfinch V2 LP Staking Tokens", "GFI-V2-LPS");
    __ERC721Pausable_init_unchained();
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);

    config = _config;

    vestingLength = 365 days;
  }

  /* ========== VIEWS ========== */

  /// @inheritdoc IStakingRewards
  function getPosition(
    uint256 tokenId
  ) external view override returns (StakedPosition memory position) {
    return positions[tokenId];
  }

  /// @inheritdoc IStakingRewards
  function stakedBalanceOf(uint256 tokenId) external view override returns (uint256) {
    return positions[tokenId].amount;
  }

  /// @notice The address of the token being disbursed as rewards
  function rewardsToken() internal view returns (IERC20withDec) {
    return config.getGFI();
  }

  /// @notice The address of the token that is staked for a given position type
  function stakingToken(StakedPositionType positionType) internal view returns (IERC20) {
    if (positionType == StakedPositionType.CurveLP) {
      return IERC20(config.getFiduUSDCCurveLP().token());
    }

    return config.getFidu();
  }

  /// @notice The additional rewards earned per token, between the provided time and the last
  ///   time rewards were checkpointed, given the prevailing `rewardRate()`. This amount is limited
  ///   by the amount of rewards that are available for distribution; if there aren't enough
  ///   rewards in the balance of this contract, then we shouldn't be giving them out.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function _additionalRewardsPerTokenSinceLastUpdate(uint256 time) internal view returns (uint256) {
    /// @dev IT: Invalid end time for range
    require(time >= lastUpdateTime, "IT");

    if (totalStakedSupply == 0) {
      return 0;
    }
    uint256 rewardsSinceLastUpdate = Math.min(
      time.sub(lastUpdateTime).mul(rewardRate()),
      rewardsAvailable
    );
    uint256 additionalRewardsPerToken = rewardsSinceLastUpdate
      .mul(stakingAndRewardsTokenMantissa())
      .div(totalStakedSupply);
    // Prevent perverse, infinite-mint scenario where totalStakedSupply is a fraction of a token.
    // Since it's used as the denominator, this could make additionalRewardPerToken larger than the total number
    // of tokens that should have been disbursed in the elapsed time. The attacker would need to find
    // a way to reduce totalStakedSupply while maintaining a staked position of >= 1.
    // See: https://twitter.com/Mudit__Gupta/status/1409463917290557440
    if (additionalRewardsPerToken > rewardsSinceLastUpdate) {
      return 0;
    }
    return additionalRewardsPerToken;
  }

  /// @notice Returns accumulated rewards per token up to the current block timestamp
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`
  function rewardPerToken() public view returns (uint256) {
    return
      accumulatedRewardsPerToken.add(_additionalRewardsPerTokenSinceLastUpdate(block.timestamp));
  }

  /// @notice Returns rewards earned by a given position token from its last checkpoint up to the
  ///   current block timestamp.
  /// @param tokenId A staking position token ID
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`
  function earnedSinceLastCheckpoint(uint256 tokenId) public view returns (uint256) {
    return
      _positionToEffectiveAmount(positions[tokenId])
        .mul(rewardPerToken().sub(positionToAccumulatedRewardsPerToken[tokenId]))
        .div(stakingAndRewardsTokenMantissa());
  }

  function totalOptimisticClaimable(address owner) external view returns (uint256) {
    uint256 result = 0;
    for (uint256 i = 0; i < balanceOf(owner); i++) {
      uint256 tokenId = tokenOfOwnerByIndex(owner, i);
      result = result.add(optimisticClaimable(tokenId));
    }
    return result;
  }

  function optimisticClaimable(uint256 tokenId) public view returns (uint256) {
    return earnedSinceLastCheckpoint(tokenId).add(claimableRewards(tokenId));
  }

  /// @notice Returns the rewards claimable by a given position token at the most recent checkpoint, taking into
  ///   account vesting schedule for legacy positions.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function claimableRewards(uint256 tokenId) public view returns (uint256 rewards) {
    return positions[tokenId].rewards.claimable();
  }

  /// @notice Returns the rewards that will have vested for some position with the given params.
  /// @return rewards Amount of rewards denominated in `rewardsToken()`
  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 time,
    uint256 grantedAmount
  ) external pure returns (uint256 rewards) {
    return StakingRewardsVesting.totalVestedAt(start, end, time, grantedAmount);
  }

  /// @notice Number of rewards, in `rewardsToken().decimals()`, to disburse each second
  function rewardRate() internal view returns (uint256) {
    // The reward rate can be thought of as a piece-wise function:
    //
    //   let intervalStart = (maxRateAtPercent * targetCapacity),
    //       intervalEnd = (minRateAtPercent * targetCapacity),
    //       x = totalStakedSupply
    //   in
    //     if x < intervalStart
    //       y = maxRate
    //     if x > intervalEnd
    //       y = minRate
    //     else
    //       y = maxRate - (maxRate - minRate) * (x - intervalStart) / (intervalEnd - intervalStart)
    //
    // See an example here:
    // solhint-disable-next-line max-line-length
    // https://www.wolframalpha.com/input/?i=Piecewise%5B%7B%7B1000%2C+x+%3C+50%7D%2C+%7B100%2C+x+%3E+300%7D%2C+%7B1000+-+%281000+-+100%29+*+%28x+-+50%29+%2F+%28300+-+50%29+%2C+50+%3C+x+%3C+300%7D%7D%5D
    //
    // In that example:
    //   maxRateAtPercent = 0.5, minRateAtPercent = 3, targetCapacity = 100, maxRate = 1000, minRate = 100
    uint256 intervalStart = targetCapacity.mul(maxRateAtPercent).div(MULTIPLIER_DECIMALS);
    uint256 intervalEnd = targetCapacity.mul(minRateAtPercent).div(MULTIPLIER_DECIMALS);
    uint256 x = totalStakedSupply;

    // Subsequent computation would overflow
    if (intervalEnd <= intervalStart) {
      return 0;
    }

    if (x < intervalStart) {
      return maxRate;
    }

    if (x > intervalEnd) {
      return minRate;
    }

    return
      maxRate.sub(
        maxRate.sub(minRate).mul(x.sub(intervalStart)).div(intervalEnd.sub(intervalStart))
      );
  }

  function _positionToEffectiveAmount(
    StakedPosition storage position
  ) internal view returns (uint256) {
    return
      toEffectiveAmount(
        position.amount,
        safeBaseTokenExchangeRate(position),
        safeEffectiveMultiplier(position)
      );
  }

  /// @notice Calculates the effective amount given the amount, (safe) base token exchange rate,
  ///   and (safe) effective multiplier for a position
  /// @param amount The amount of staked tokens
  /// @param safeBaseTokenExchangeRate The (safe) base token exchange rate. See @dev comment below.
  /// @param safeEffectiveMultiplier The (safe) effective multiplier. See @dev comment below.
  /// @dev Do NOT pass in the unsafeBaseTokenExchangeRate or unsafeEffectiveMultiplier in storage.
  ///   Convert it to safe values using `safeBaseTokenExchangeRate()` and `safeEffectiveMultiplier()`
  //    before calling this function.
  function toEffectiveAmount(
    uint256 amount,
    uint256 safeBaseTokenExchangeRate,
    uint256 safeEffectiveMultiplier
  ) internal pure returns (uint256) {
    // Both the exchange rate and the effective multiplier are denominated in MULTIPLIER_DECIMALS
    return
      amount
        .mul(safeBaseTokenExchangeRate)
        .mul(safeEffectiveMultiplier)
        .div(MULTIPLIER_DECIMALS)
        .div(MULTIPLIER_DECIMALS);
  }

  /// @dev We overload the responsibility of this function -- i.e. returning a value that can be
  /// used for both the `stakingToken()` mantissa and the `rewardsToken()` mantissa --, rather than have
  /// multiple distinct functions for that purpose, in order to reduce contract size. We rely on a unit
  /// test to ensure that the tokens' mantissas are indeed 1e18 and therefore that this approach works.
  function stakingAndRewardsTokenMantissa() internal pure returns (uint256) {
    return 1e18;
  }

  /// @notice The amount of rewards currently being earned per token per second. This amount takes into
  ///   account how many rewards are actually available for disbursal -- unlike `rewardRate()` which does not.
  ///   This function is intended for public consumption, to know the rate at which rewards are being
  ///   earned, and not as an input to the mutative calculations in this contract.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function currentEarnRatePerToken() public view returns (uint256) {
    uint256 time = block.timestamp == lastUpdateTime ? block.timestamp + 1 : block.timestamp;
    uint256 elapsed = time.sub(lastUpdateTime);
    return _additionalRewardsPerTokenSinceLastUpdate(time).div(elapsed);
  }

  /// @notice The amount of rewards currently being earned per second, for a given position. This function
  ///   is intended for public consumption, to know the rate at which rewards are being earned
  ///   for a given position, and not as an input to the mutative calculations in this contract.
  /// @return Amount of rewards denominated in `rewardsToken().decimals()`.
  function positionCurrentEarnRate(uint256 tokenId) external view returns (uint256) {
    return
      currentEarnRatePerToken().mul(_positionToEffectiveAmount(positions[tokenId])).div(
        stakingAndRewardsTokenMantissa()
      );
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function setBaseURI(string calldata baseURI_) external onlyAdmin {
    _setBaseURI(baseURI_);
  }

  /// @notice Stake `stakingToken()` to earn rewards. When you call this function, you'll receive an
  ///   an NFT representing your staked position. You can present your NFT to `getReward` or `unstake`
  ///   to claim rewards or unstake your tokens respectively.
  /// @dev This function checkpoints rewards.
  /// @param amount The amount of `stakingToken()` to stake
  /// @param positionType The type of the staked position
  /// @return Id of the NFT representing the staked position
  function stake(
    uint256 amount,
    StakedPositionType positionType
  ) external nonReentrant whenNotPaused updateReward(0) returns (uint256) {
    return _stake(msg.sender, msg.sender, amount, positionType);
  }

  /// @notice Deposit to SeniorPool and stake your shares in the same transaction.
  /// @param usdcAmount The amount of USDC to deposit into the senior pool. All shares from deposit
  ///   will be staked.
  function depositAndStake(
    uint256 usdcAmount
  ) public nonReentrant whenNotPaused updateReward(0) returns (uint256) {
    /// @dev GL: This address has not been go-listed
    require(isGoListed(), "GL");
    IERC20withDec usdc = config.getUSDC();
    usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

    ISeniorPool seniorPool = config.getSeniorPool();
    usdc.safeIncreaseAllowance(address(seniorPool), usdcAmount);
    uint256 fiduAmount = seniorPool.deposit(usdcAmount);

    uint256 tokenId = _stake(address(this), msg.sender, fiduAmount, StakedPositionType.Fidu);
    emit DepositedAndStaked(msg.sender, usdcAmount, tokenId, fiduAmount);

    return tokenId;
  }

  /// @notice Identical to `depositAndStake`, except it allows for a signature to be passed that permits
  ///   this contract to move funds on behalf of the user.
  /// @param usdcAmount The amount of USDC to deposit
  /// @param v secp256k1 signature component
  /// @param r secp256k1 signature component
  /// @param s secp256k1 signature component
  function depositWithPermitAndStake(
    uint256 usdcAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256) {
    IERC20Permit(config.usdcAddress()).permit(
      msg.sender,
      address(this),
      usdcAmount,
      deadline,
      v,
      r,
      s
    );
    return depositAndStake(usdcAmount);
  }

  /// @notice Deposits FIDU and USDC to Curve on behalf of the user. The Curve LP tokens will be minted
  ///   directly to the user's address
  /// @param fiduAmount The amount of FIDU to deposit
  /// @param usdcAmount The amount of USDC to deposit
  function depositToCurve(
    uint256 fiduAmount,
    uint256 usdcAmount
  ) external nonReentrant whenNotPaused {
    uint256 curveLPTokens = _depositToCurve(msg.sender, msg.sender, fiduAmount, usdcAmount);

    emit DepositedToCurve(msg.sender, fiduAmount, usdcAmount, curveLPTokens);
  }

  function depositToCurveAndStake(uint256 fiduAmount, uint256 usdcAmount) external {
    depositToCurveAndStakeFrom(msg.sender, fiduAmount, usdcAmount);
  }

  /// @inheritdoc IStakingRewards
  function depositToCurveAndStakeFrom(
    address nftRecipient,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) public override nonReentrant whenNotPaused updateReward(0) {
    // Add liquidity to Curve. The Curve LP tokens will be minted under StakingRewards
    uint256 curveLPTokens = _depositToCurve(msg.sender, address(this), fiduAmount, usdcAmount);

    // Stake the Curve LP tokens on behalf of the user
    uint256 tokenId = _stake(
      address(this),
      nftRecipient,
      curveLPTokens,
      StakedPositionType.CurveLP
    );

    emit DepositedToCurveAndStaked(msg.sender, fiduAmount, usdcAmount, tokenId, curveLPTokens);
  }

  /// @notice Deposit to FIDU and USDC into the Curve LP. Returns the amount of Curve LP tokens minted,
  ///   which is denominated in 1e18.
  /// @param depositor The address of the depositor (i.e. the current owner of the FIDU and USDC to deposit)
  /// @param lpTokensRecipient The receipient of the resulting LP tokens
  /// @param fiduAmount The amount of FIDU to deposit
  /// @param usdcAmount The amount of USDC to deposit
  function _depositToCurve(
    address depositor,
    address lpTokensRecipient,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) internal returns (uint256) {
    /// @dev ZERO: Cannot stake 0
    require(fiduAmount > 0 || usdcAmount > 0, "ZERO");

    IERC20withDec usdc = config.getUSDC();
    IERC20withDec fidu = config.getFidu();
    ICurveLP curveLP = config.getFiduUSDCCurveLP();

    // Transfer FIDU and USDC from depositor to StakingRewards, and allow the Curve LP contract to spend
    // this contract's FIDU and USDC
    if (fiduAmount > 0) {
      fidu.safeTransferFrom(depositor, address(this), fiduAmount);
      fidu.safeIncreaseAllowance(address(curveLP), fiduAmount);
    }
    if (usdcAmount > 0) {
      usdc.safeTransferFrom(depositor, address(this), usdcAmount);
      usdc.safeIncreaseAllowance(address(curveLP), usdcAmount);
    }

    // We will allow up to 10% slippage, so minMintAmount should be at least 90%
    uint256 minMintAmount = curveLP.calc_token_amount([fiduAmount, usdcAmount]).mul(9).div(10);

    // Add liquidity to Curve. The Curve LP tokens will be minted under the `lpTokensRecipient`.
    // The `add_liquidity()` function returns the number of LP tokens minted, denominated in 1e18.
    //
    // solhint-disable-next-line max-line-length
    // https://github.com/curvefi/curve-factory/blob/ab5e7f6934c0dcc3ad06ccda4d6b35ffbbc99d42/contracts/implementations/plain-4/Plain4Basic.vy#L76
    // https://curve.readthedocs.io/factory-pools.html#StableSwap.decimals
    //
    // It would perhaps be ideal to do our own enforcement of `minMintAmount`, but given the Curve
    // contract is non-upgradeable and we are satisfied with its implementation, we do not.
    return curveLP.add_liquidity([fiduAmount, usdcAmount], minMintAmount, false, lpTokensRecipient);
  }

  /// @notice Returns the effective multiplier for a given position. Defaults to 1 for all staked
  ///   positions created prior to GIP-1 (before the `unsafeEffectiveMultiplier` field was added).
  /// @dev Always use this method to get the effective multiplier to ensure proper handling of
  ///   old staked positions.
  function safeEffectiveMultiplier(
    StakedPosition storage position
  ) internal view returns (uint256) {
    if (position.unsafeEffectiveMultiplier > 0) {
      return position.unsafeEffectiveMultiplier;
    }

    return MULTIPLIER_DECIMALS; // 1x
  }

  /// @notice Returns the base token exchange rate for a given position. Defaults to 1 for all staked
  ///   positions created prior to GIP-1 (before the `unsafeBaseTokenExchangeRate` field was added).
  /// @dev Always use this method to get the base token exchange rate to ensure proper handling of
  ///   old staked positions.
  function safeBaseTokenExchangeRate(
    StakedPosition storage position
  ) internal view returns (uint256) {
    if (position.unsafeBaseTokenExchangeRate > 0) {
      return position.unsafeBaseTokenExchangeRate;
    }
    return MULTIPLIER_DECIMALS;
  }

  /// @notice The effective multiplier to use with new staked positions of the provided `positionType`,
  ///   for denominating them in terms of `baseStakingToken()`. This value is denominated in `MULTIPLIER_DECIMALS`.
  function getEffectiveMultiplierForPositionType(
    StakedPositionType positionType
  ) public view returns (uint256) {
    if (effectiveMultipliers[positionType] > 0) {
      return effectiveMultipliers[positionType];
    }

    return MULTIPLIER_DECIMALS; // 1x
  }

  /// @notice Calculate the exchange rate that will be used to convert the original staked token amount to the
  ///   `baseStakingToken()` amount. The exchange rate is denominated in `MULTIPLIER_DECIMALS`.
  /// @param positionType Type of the staked postion
  function getBaseTokenExchangeRate(
    StakedPositionType positionType
  ) public view virtual returns (uint256) {
    if (positionType == StakedPositionType.CurveLP) {
      ICurveLP curvePool = config.getFiduUSDCCurveLP();
      // To calculate the amount of FIDU underlying each Curve LP token, we take the total amount of FIDU in
      // the Curve pool, and divide that by the total number of Curve LP tokens in circulation.
      return
        curvePool.balances(0).mul(MULTIPLIER_DECIMALS).div(IERC20(curvePool.token()).totalSupply());
    }

    return MULTIPLIER_DECIMALS; // 1x
  }

  function _stake(
    address staker,
    address nftRecipient,
    uint256 amount,
    StakedPositionType positionType
  ) internal returns (uint256 tokenId) {
    /// @dev ZERO: Cannot stake 0
    require(amount > 0, "ZERO");

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    // Ensure we snapshot accumulatedRewardsPerToken for tokenId after it is available
    // We do this before setting the position, because we don't want `earned` to (incorrectly) account for
    // position.amount yet. This is equivalent to using the updateReward(msg.sender) modifier in the original
    // synthetix contract, where the modifier is called before any staking balance for that address is recorded
    _updateReward(tokenId);

    uint256 baseTokenExchangeRate = getBaseTokenExchangeRate(positionType);
    uint256 effectiveMultiplier = getEffectiveMultiplierForPositionType(positionType);

    if (positionType == StakedPositionType.CurveLP) {
      ICurveLP curvePool = config.getFiduUSDCCurveLP();

      // Do not allow the user to create a new Curve LP staked position if the Curve pool is significantly
      // imbalanced. This prevents attackers from exploiting an artificially unbalanced Curve pool to
      // receive a higher staking reward rate.
      //
      // We consider the Curve pool to be reasonably balanced if the ratio of USDC to FIDU is within +/- 25%
      // of the current FIDU price in the Senior Pool. When the Curve pool is balanced, we expect this
      // the ratio to be close to the Senior Pool FIDU price.
      //
      // We put these bounds in place to protect against flash loan attacks, where an attacker can temporarily
      // force the Curve pool to become imbalanced, and stake the Curve LP tokens to get a higher staking
      // reward rate.
      uint256 usdcToFiduOnCurve = curvePool
        .balances(1)
        .mul(MULTIPLIER_DECIMALS)
        .div(curvePool.balances(0))
        .mul(MULTIPLIER_DECIMALS)
        .div(USDC_MANTISSA);

      /// @dev IM: Curve pool is too imbalanced
      require(
        usdcToFiduOnCurve > config.getSeniorPool().sharePrice().mul(75).div(100) &&
          usdcToFiduOnCurve < config.getSeniorPool().sharePrice().mul(125).div(100),
        "IM"
      );
    }

    positions[tokenId] = StakedPosition({
      positionType: positionType,
      amount: amount,
      rewards: Rewards({
        totalUnvested: 0,
        totalVested: 0,
        totalPreviouslyVested: 0,
        totalClaimed: 0,
        startTime: block.timestamp,
        endTime: 0
      }),
      unsafeBaseTokenExchangeRate: baseTokenExchangeRate,
      unsafeEffectiveMultiplier: effectiveMultiplier,
      leverageMultiplier: 0,
      lockedUntil: 0
    });
    _mint(nftRecipient, tokenId);

    totalStakedSupply = totalStakedSupply.add(_positionToEffectiveAmount(positions[tokenId]));

    // Staker is address(this) when using depositAndStake or other convenience functions
    if (staker != address(this)) {
      stakingToken(positionType).safeTransferFrom(staker, address(this), amount);
    }

    emit Staked(nftRecipient, tokenId, amount, positionType, baseTokenExchangeRate);

    return tokenId;
  }

  //==============================================================
  // START: UNSTAKING FUNCTIONS
  //
  // Note: All unstake functions need to checkpoint rewards by
  // calling `_updateReward(tokenId)` before unstaking to ensure
  // that latest rewards earned since the last checkpoint are
  // accounted for.
  //==============================================================

  /// @inheritdoc IStakingRewards
  function unstake(uint256 tokenId, uint256 amount) public override nonReentrant whenNotPaused {
    // Checkpoint rewards
    _updateReward(tokenId);
    // Unstake
    _unstake(tokenId, amount);
    // Transfer staked tokens back to msg.sender
    stakingToken(positions[tokenId].positionType).safeTransfer(msg.sender, amount);
  }

  /// @notice Unstake multiple positions and transfer to msg.sender.
  ///
  /// @dev This function checkpoints rewards
  /// @param tokenIds A list of position token IDs
  /// @param amounts A list of amounts of `stakingToken()` to be unstaked from the position
  function unstakeMultiple(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external nonReentrant whenNotPaused {
    /// @dev LEN: Params must have the same length
    require(tokenIds.length == amounts.length, "LEN");

    uint256 fiduAmountToUnstake = 0;
    uint256 curveAmountToUnstake = 0;

    for (uint256 i = 0; i < amounts.length; i++) {
      // Checkpoint rewards
      _updateReward(tokenIds[i]);
      // Unstake
      _unstake(tokenIds[i], amounts[i]);
      if (positions[tokenIds[i]].positionType == StakedPositionType.CurveLP) {
        curveAmountToUnstake = curveAmountToUnstake.add(amounts[i]);
      } else {
        fiduAmountToUnstake = fiduAmountToUnstake.add(amounts[i]);
      }
    }

    // Transfer all staked tokens back to msg.sender
    if (fiduAmountToUnstake > 0) {
      stakingToken(StakedPositionType.Fidu).safeTransfer(msg.sender, fiduAmountToUnstake);
    }
    if (curveAmountToUnstake > 0) {
      stakingToken(StakedPositionType.CurveLP).safeTransfer(msg.sender, curveAmountToUnstake);
    }

    emit UnstakedMultiple(msg.sender, tokenIds, amounts);
  }

  /// @notice Unstake an amount from a single position
  ///
  /// @dev This function does NOT checkpoint rewards; the caller of this function is responsible
  ///   for ensuring that rewards are properly checkpointed before invocation.
  /// @dev This function does NOT transfer staked tokens back to the user; the caller of this
  ///   function is responsible for ensuring that tokens are transferred back to the
  ///   owner if necessary.
  /// @param tokenId The token ID
  /// @param amount The amount of of `stakingToken()` to be unstaked from the position
  function _unstake(uint256 tokenId, uint256 amount) internal {
    /// @dev AD: Access denied
    require(_isApprovedOrOwner(msg.sender, tokenId), "AD");

    StakedPosition storage position = positions[tokenId];
    uint256 prevAmount = position.amount;
    /// @dev IA: Invalid amount. Cannot unstake zero, and cannot unstake more than staked balance.
    require(amount > 0 && amount <= prevAmount, "IA");

    totalStakedSupply = totalStakedSupply.sub(
      toEffectiveAmount(
        amount,
        safeBaseTokenExchangeRate(position),
        safeEffectiveMultiplier(position)
      )
    );
    position.amount = prevAmount.sub(amount);

    emit Unstaked(msg.sender, tokenId, amount, position.positionType);
  }

  //==============================================================
  // END: UNSTAKING FUNCTIONS
  //==============================================================

  /// @inheritdoc IStakingRewards
  function kick(
    uint256 tokenId
  ) external override nonReentrant whenNotPaused updateReward(tokenId) {} // solhint-disable-line no-empty-blocks

  /// @notice Updates a user's effective multiplier to the prevailing multiplier. This function gives
  ///   users an option to get on a higher multiplier without needing to unstake.
  /// @dev This will also checkpoint their rewards up to the current time.
  function updatePositionEffectiveMultiplier(
    uint256 tokenId
  ) external nonReentrant whenNotPaused updateReward(tokenId) {
    /// @dev AD: Access denied
    require(ownerOf(tokenId) == msg.sender, "AD");

    StakedPosition storage position = positions[tokenId];

    uint256 newEffectiveMultiplier = getEffectiveMultiplierForPositionType(position.positionType);

    /// We want to honor the original multiplier for the user's sake, so we don't want to
    /// allow the effective multiplier for a given position to decrease.
    /// @dev LOW: Cannot update position to a lower effective multiplier
    require(newEffectiveMultiplier >= safeEffectiveMultiplier(position), "LOW");

    uint256 prevEffectiveAmount = _positionToEffectiveAmount(position);

    position.unsafeEffectiveMultiplier = newEffectiveMultiplier;

    uint256 newEffectiveAmount = _positionToEffectiveAmount(position);

    totalStakedSupply = totalStakedSupply.sub(prevEffectiveAmount).add(newEffectiveAmount);
  }

  /// @inheritdoc IStakingRewards
  function getReward(
    uint256 tokenId
  ) external override nonReentrant whenNotPaused updateReward(tokenId) returns (uint256) {
    /// @dev AD: Access denied
    require(ownerOf(tokenId) == msg.sender, "AD");
    uint256 reward = claimableRewards(tokenId);
    if (reward > 0) {
      positions[tokenId].rewards.claim(reward);
      rewardsToken().safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, tokenId, reward);
    }

    return reward;
  }

  /// @inheritdoc IStakingRewards
  function addToStake(
    uint256 tokenId,
    uint256 amount
  ) external override nonReentrant whenNotPaused updateReward(tokenId) {
    /// @dev AD: Access denied
    require(_isApprovedOrOwner(msg.sender, tokenId), "AD");

    StakedPosition storage position = positions[tokenId];

    /// @dev PT: Position type is incorrect for this action
    require(position.positionType == StakedPositionType.Fidu, "PT");

    position.amount = position.amount.add(amount);

    totalStakedSupply = totalStakedSupply.add(
      toEffectiveAmount(
        amount,
        safeBaseTokenExchangeRate(position),
        safeEffectiveMultiplier(position)
      )
    );

    stakingToken(position.positionType).safeTransferFrom(msg.sender, address(this), amount);
    emit AddToStake(msg.sender, tokenId, amount, position.positionType);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /// @notice Transfer rewards from msg.sender, to be used for reward distribution
  function loadRewards(uint256 rewards) external onlyAdmin updateReward(0) {
    rewardsToken().safeTransferFrom(msg.sender, address(this), rewards);
    rewardsAvailable = rewardsAvailable.add(rewards);
    emit RewardAdded(rewards);
  }

  function setRewardsParameters(
    uint256 _targetCapacity,
    uint256 _minRate,
    uint256 _maxRate,
    uint256 _minRateAtPercent,
    uint256 _maxRateAtPercent
  ) external onlyAdmin updateReward(0) {
    /// @dev IP: Invalid parameters. maxRate must be >= then minRate. maxRateAtPercent must be <= minRateAtPercent.
    require(_maxRate >= _minRate && _maxRateAtPercent <= _minRateAtPercent, "IP");

    targetCapacity = _targetCapacity;
    minRate = _minRate;
    maxRate = _maxRate;
    minRateAtPercent = _minRateAtPercent;
    maxRateAtPercent = _maxRateAtPercent;

    emit RewardsParametersUpdated(
      msg.sender,
      targetCapacity,
      minRate,
      maxRate,
      minRateAtPercent,
      maxRateAtPercent
    );
  }

  /// @notice Set the effective multiplier for a given staked position type. The effective multipler
  ///  is used to denominate a staked position to `baseStakingToken()`. The multiplier is represented in
  ///  `MULTIPLIER_DECIMALS`
  /// @param multiplier the new multiplier, denominated in `MULTIPLIER_DECIMALS`
  /// @param positionType the type of the position
  function setEffectiveMultiplier(
    uint256 multiplier,
    StakedPositionType positionType
  ) external onlyAdmin updateReward(0) {
    // @dev ZERO: Multiplier cannot be zero
    require(multiplier > 0, "ZERO");

    effectiveMultipliers[positionType] = multiplier;
    emit EffectiveMultiplierUpdated(_msgSender(), positionType, multiplier);
  }

  /* ========== MODIFIERS ========== */

  modifier updateReward(uint256 tokenId) {
    _updateReward(tokenId);
    _;
  }

  function _updateReward(uint256 tokenId) internal {
    uint256 prevAccumulatedRewardsPerToken = accumulatedRewardsPerToken;

    accumulatedRewardsPerToken = rewardPerToken();
    uint256 rewardsJustDistributed = totalStakedSupply
      .mul(accumulatedRewardsPerToken.sub(prevAccumulatedRewardsPerToken))
      .div(stakingAndRewardsTokenMantissa());
    rewardsAvailable = rewardsAvailable.sub(rewardsJustDistributed);
    lastUpdateTime = block.timestamp;

    if (tokenId != 0) {
      uint256 additionalRewards = earnedSinceLastCheckpoint(tokenId);

      Rewards storage rewards = positions[tokenId].rewards;
      rewards.totalUnvested = rewards.totalUnvested.add(additionalRewards);
      rewards.checkpoint();

      positionToAccumulatedRewardsPerToken[tokenId] = accumulatedRewardsPerToken;
    }
  }

  function isAdmin() internal view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    /// @dev AD: Must have admin role to perform this action
    require(isAdmin(), "AD");
    _;
  }

  function isGoListed() internal view returns (bool) {
    return config.getGo().goSeniorPool(msg.sender);
  }

  function canWithdraw(uint256 tokenId) internal view returns (bool) {
    return positions[tokenId].positionType == StakedPositionType.Fidu;
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

// contract IOneSplitConsts {
//     // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
//     uint256 internal constant FLAG_DISABLE_UNISWAP = 0x01;
//     uint256 internal constant DEPRECATED_FLAG_DISABLE_KYBER = 0x02; // Deprecated
//     uint256 internal constant FLAG_DISABLE_BANCOR = 0x04;
//     uint256 internal constant FLAG_DISABLE_OASIS = 0x08;
//     uint256 internal constant FLAG_DISABLE_COMPOUND = 0x10;
//     uint256 internal constant FLAG_DISABLE_FULCRUM = 0x20;
//     uint256 internal constant FLAG_DISABLE_CHAI = 0x40;
//     uint256 internal constant FLAG_DISABLE_AAVE = 0x80;
//     uint256 internal constant FLAG_DISABLE_SMART_TOKEN = 0x100;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_BDAI = 0x400;
//     uint256 internal constant FLAG_DISABLE_IEARN = 0x800;
//     uint256 internal constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
//     uint256 internal constant FLAG_DISABLE_CURVE_USDT = 0x2000;
//     uint256 internal constant FLAG_DISABLE_CURVE_Y = 0x4000;
//     uint256 internal constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
//     uint256 internal constant FLAG_DISABLE_WETH = 0x80000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_IDLE = 0x800000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
//     uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
//     uint256 internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDT = 0x400000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_WBTC = 0x800000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_TBTC = 0x1000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_RENBTC = 0x2000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
//     uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
//     uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
//     uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_SBTC = 0x40000000000;
//     uint256 internal constant FLAG_DISABLE_DMM = 0x80000000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_ALL = 0x100000000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400000000000;
//     uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_1 = 0x2000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_2 = 0x4000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_3 = 0x8000000000000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x10000000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x20000000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x40000000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP = 0x80000000000000; // Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_COMP = 0x100000000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_1 = 0x400000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_2 = 0x800000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_3 = 0x1000000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_4 = 0x2000000000000000;
//     uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN = 0x4000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_ALL = 0x8000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_ETH = 0x10000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_DAI = 0x20000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_USDC = 0x40000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_POOL_TOKEN = 0x80000000000000000;
// }

interface IOneSplit {
  function getExpectedReturn(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags // See constants in IOneSplit.sol
  ) external view returns (uint256 returnAmount, uint256[] memory distribution);

  function getExpectedReturnWithGas(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags, // See constants in IOneSplit.sol
    uint256 destTokenEthPriceTimesGasPrice
  )
    external
    view
    returns (uint256 returnAmount, uint256 estimateGasAmount, uint256[] memory distribution);

  function swap(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory distribution,
    uint256 flags
  ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/Accountant.sol";
import "../protocol/core/CreditLine.sol";

contract TestAccountant {
  function calculateInterestAndPrincipalAccrued(
    address creditLineAddress,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    CreditLine cl = CreditLine(creditLineAddress);
    return Accountant.calculateInterestAndPrincipalAccrued(cl, timestamp, lateFeeGracePeriod);
  }

  function calculateWritedownFor(
    address creditLineAddress,
    uint256 blockNumber,
    uint256 gracePeriod,
    uint256 maxLatePeriods
  ) public view returns (uint256, uint256) {
    CreditLine cl = CreditLine(creditLineAddress);
    return Accountant.calculateWritedownFor(cl, blockNumber, gracePeriod, maxLatePeriods);
  }

  function calculateAmountOwedForOneDay(
    address creditLineAddress
  ) public view returns (FixedPoint.Unsigned memory) {
    CreditLine cl = CreditLine(creditLineAddress);
    return Accountant.calculateAmountOwedForOneDay(cl);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../rewards/BackerRewards.sol";

contract TestBackerRewards is BackerRewards {
  address payable public sender;

  // solhint-disable-next-line modifiers/ensure-modifiers
  function _setSender(address payable _sender) public {
    sender = _sender;
  }

  function _msgSender() internal view override returns (address payable) {
    if (sender != address(0)) {
      return sender;
    } else {
      return super._msgSender();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/ConfigurableRoyaltyStandard.sol";
import "../protocol/core/HasAdmin.sol";
import "../interfaces/IERC2981.sol";

contract TestConfigurableRoyaltyStandard is HasAdmin, IERC2981 {
  using ConfigurableRoyaltyStandard for ConfigurableRoyaltyStandard.RoyaltyParams;

  ConfigurableRoyaltyStandard.RoyaltyParams public royaltyParams;

  // The library event must be copied to the base contract so that decoding clients
  // don't get confused. See https://medium.com/aragondec/library-driven-development-in-solidity-2bebcaf88736#7ed4
  event RoyaltyParamsSet(address indexed sender, address newReceiver, uint256 newRoyaltyPercent);

  constructor(address owner) public {
    __AccessControl_init_unchained();
    _setupRole(OWNER_ROLE, owner);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /// @notice Called with the sale price to determine how much royalty
  //    is owed and to whom.
  /// @param _tokenId The NFT asset queried for royalty information
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address that should receive royalties
  /// @return royaltyAmount The royalty payment amount for _salePrice
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override returns (address, uint256) {
    return royaltyParams.royaltyInfo(_tokenId, _salePrice);
  }

  /// @notice Set royalty params used in `royaltyInfo`. This function is only callable by
  ///   an address with `OWNER_ROLE`.
  /// @param newReceiver The new address which should receive royalties. See `receiver`.
  /// @param newRoyaltyPercent The new percent of `salePrice` that should be taken for royalties.
  ///   See `royaltyPercent`.
  function setRoyaltyParams(address newReceiver, uint256 newRoyaltyPercent) external onlyAdmin {
    royaltyParams.setRoyaltyParams(newReceiver, newRoyaltyPercent);
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == ConfigurableRoyaltyStandard._INTERFACE_ID_ERC2981;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/BaseUpgradeablePausable.sol";
import "../protocol/core/CreditLine.sol";

contract TestCreditLine is CreditLine {
  function setPaymentPeriodInDays(uint256 _paymentPeriodInDays) public onlyAdmin {
    paymentPeriodInDays = _paymentPeriodInDays;
  }

  function setInterestApr(uint256 _interestApr) public onlyAdmin {
    interestApr = _interestApr;
  }
}

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/drafts/ERC20Permit.sol";

contract TestERC20 is ERC20("USD Coin", "USDC"), ERC20Permit("USD Coin") {
  constructor(uint256 initialSupply, uint8 decimals) public {
    _setupDecimals(decimals);
    _mint(msg.sender, initialSupply);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/drafts/ERC20Permit.sol";

import "../interfaces/ICurveLP.sol";
import "../protocol/core/ConfigOptions.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";

contract TestFiduUSDCCurveLP is
  ERC20("LP FIDU-USDC Curve", "FIDUUSDCCURVE"),
  ERC20Permit("LP FIDU-USDC Curve"),
  ICurveLP
{
  using ConfigHelper for GoldfinchConfig;
  uint256 private constant MULTIPLIER_DECIMALS = 1e18;
  uint256 private constant USDC_DECIMALS = 1e6;

  GoldfinchConfig public config;

  uint256 private slippage = MULTIPLIER_DECIMALS;
  uint256[2] private _balances = [1e18, 1e18];
  uint256 private _totalSupply = 1e18;

  constructor(uint256 initialSupply, uint8 decimals, GoldfinchConfig _config) public {
    _setupDecimals(decimals);
    _mint(msg.sender, initialSupply);
    config = _config;
  }

  function coins(uint256 index) external view override returns (address) {
    // note: defining as an array so we get the same out of bounds behavior
    //        but can't define it at compile time because the addresses
    //        are sourced from goldfinch config
    return [address(getFidu()), address(getUSDC())][index];
  }

  function token() public view override returns (address) {
    return address(this);
  }

  /// @notice Mock calc_token_amount function that returns the sum of both token amounts
  function calc_token_amount(uint256[2] memory amounts) public view override returns (uint256) {
    return amounts[0].add(amounts[1].mul(MULTIPLIER_DECIMALS).div(USDC_DECIMALS));
  }

  /// @notice Mock add_liquidity function that mints Curve LP tokens
  function add_liquidity(
    uint256[2] memory amounts,
    uint256 min_mint_amount,
    bool,
    address receiver
  ) public override returns (uint256) {
    // Transfer FIDU and USDC from caller to this contract
    getFidu().transferFrom(msg.sender, address(this), amounts[0]);
    getUSDC().transferFrom(msg.sender, address(this), amounts[1]);

    uint256 amount = calc_token_amount(amounts).mul(slippage).div(MULTIPLIER_DECIMALS);

    require(amount >= min_mint_amount, "Slippage too high");

    _mint(receiver, amount);
    return amount;
  }

  function lp_price() external view override returns (uint256) {
    return MULTIPLIER_DECIMALS.mul(2);
  }

  /// @notice Used to mock slippage in unit tests
  function _setSlippage(uint256 newSlippage) external {
    slippage = newSlippage;
  }

  /// @notice Used to return the mocked balances in unit tests
  function balances(uint256 index) public view override returns (uint256) {
    return _balances[index];
  }

  /// @notice Used to mock balances in unit tests
  function _setBalance(uint256 index, uint256 balance) public {
    _balances[index] = balance;
  }

  /// @notice Used to return the mocked total supply in unit tests
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Used to mock the total supply in unit tests
  function _setTotalSupply(uint256 newTotalSupply) public {
    _totalSupply = newTotalSupply;
  }

  /// @notice Mock remove_liquidity function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function remove_liquidity(uint256, uint256[2] memory) public override returns (uint256) {
    return 0;
  }

  /// @notice Mock remove_liquidity_one_coin function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function remove_liquidity_one_coin(uint256, uint256, uint256) public override returns (uint256) {
    return 0;
  }

  /// @notice Mock get_dy function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function get_dy(uint256, uint256, uint256) external view override returns (uint256) {
    return 0;
  }

  /// @notice Mock exchange function
  /// @dev Left unimplemented because we're only using this in mainnet forking tests
  function exchange(uint256, uint256, uint256, uint256) public override returns (uint256) {
    return 0;
  }

  function getUSDC() internal view returns (ERC20) {
    return ERC20(address(config.getUSDC()));
  }

  function getFidu() internal view returns (ERC20) {
    return ERC20(address(config.getFidu()));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/GoldfinchConfig.sol";

contract TestGoldfinchConfig is GoldfinchConfig {
  function setAddressForTest(uint256 addressKey, address newAddress) public {
    addresses[addressKey] = newAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/HasAdmin.sol";

contract TestHasAdmin is HasAdmin {
  event TestEvent();

  constructor(address owner) public {
    __AccessControl_init_unchained();
    _setupRole(OWNER_ROLE, owner);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function adminFunction() public onlyAdmin {
    emit TestEvent();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/PoolTokens.sol";

contract TestPoolTokens is PoolTokens {
  bool public disablePoolValidation;
  address payable public sender;

  // solhint-disable-next-line modifiers/ensure-modifiers
  function _disablePoolValidation(bool shouldDisable) public {
    disablePoolValidation = shouldDisable;
  }

  // solhint-disable-next-line modifiers/ensure-modifiers
  function _setSender(address payable _sender) public {
    sender = _sender;
  }

  function _validPool(address _sender) internal view override returns (bool) {
    if (disablePoolValidation) {
      return true;
    } else {
      return super._validPool(_sender);
    }
  }

  function _msgSender() internal view override returns (address payable) {
    if (sender != address(0)) {
      return sender;
    } else {
      return super._msgSender();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import {SeniorPool} from "../protocol/core/SeniorPool.sol";

contract TestSeniorPool is SeniorPool {
  function getUsdcAmountFromShares(uint256 shares) public view returns (uint256) {
    return _getUSDCAmountFromShares(shares);
  }

  function _getNumShares(uint256 amount) public view returns (uint256) {
    return getNumShares(amount);
  }

  function getUSDCAmountFromShares(uint256 fiduAmount) public view returns (uint256) {
    return _getUSDCAmountFromShares(fiduAmount);
  }

  function __getNumShares(uint256 usdcAmount, uint256 sharePrice) public pure returns (uint256) {
    return _getNumShares(usdcAmount, sharePrice);
  }

  function usdcMantissa() public pure returns (uint256) {
    return USDC_MANTISSA;
  }

  function fiduMantissa() public pure returns (uint256) {
    return FIDU_MANTISSA;
  }

  function usdcToFidu(uint256 amount) public pure returns (uint256) {
    return _usdcToFidu(amount);
  }

  function fiduToUsdc(uint256 amount) public pure returns (uint256) {
    return _fiduToUsdc(amount);
  }

  function _setSharePrice(uint256 newSharePrice) public returns (uint256) {
    sharePrice = newSharePrice;
  }

  function epochAt(uint256 id) external view returns (Epoch memory) {
    return _epochs[id];
  }

  function _usdcAvailableRaw() external view returns (uint256) {
    return _usdcAvailable;
  }

  function setUsdcAvailable(uint256 newUsdcAvailable) external {
    _usdcAvailable = newUsdcAvailable;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {TestSeniorPool} from "./TestSeniorPool.sol";
import {IERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Contract that can be used as a middle man between an EOA and SeniorPool. Useful for
 * testing different authorization combos, e.g. EOA has a UID and has ERC1155-approved this
 * contract.
 */
contract TestSeniorPoolCaller {
  TestSeniorPool private immutable seniorPool;

  constructor(TestSeniorPool _seniorPool, address usdc, address fidu) public {
    seniorPool = _seniorPool;
    IERC20(usdc).approve(address(_seniorPool), type(uint256).max);
    IERC20(fidu).approve(address(_seniorPool), type(uint256).max);
  }

  function deposit(uint256 usdcAmount) public returns (uint256) {
    return seniorPool.deposit(usdcAmount);
  }

  function requestWithdrawal(uint256 fiduAmount) public returns (uint256) {
    return seniorPool.requestWithdrawal(fiduAmount);
  }

  function addToWithdrawalRequest(uint256 fiduAmount, uint256 tokenId) public {
    seniorPool.addToWithdrawalRequest(fiduAmount, tokenId);
  }

  function cancelWithdrawalRequest(uint256 tokenId) public {
    seniorPool.cancelWithdrawalRequest(tokenId);
  }

  function claimWithdrawalRequest(uint256 tokenId) public returns (uint256) {
    return seniorPool.claimWithdrawalRequest(tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../rewards/StakingRewards.sol";

contract TestStakingRewards is StakingRewards {
  uint256 private constant MULTIPLIER_DECIMALS = 1e18;

  mapping(StakedPositionType => uint256) private exchangeRates;

  /// @dev Used in unit tests to mock the `unsafeEffectiveMultiplier` for a given position
  function _setPositionUnsafeEffectiveMultiplier(uint256 tokenId, uint256 newMultiplier) external {
    StakedPosition storage position = positions[tokenId];

    position.unsafeEffectiveMultiplier = newMultiplier;
  }

  /// @dev Copy of _stake, but with a valid vesting endtime
  function stakeWithVesting(
    address staker,
    address nftRecipient,
    uint256 amount,
    StakedPositionType positionType
  ) external nonReentrant whenNotPaused updateReward(0) returns (uint256 tokenId) {
    /// @dev ZERO: Cannot stake 0
    require(amount > 0, "ZERO");

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    // Ensure we snapshot accumulatedRewardsPerToken for tokenId after it is available
    // We do this before setting the position, because we don't want `earned` to (incorrectly) account for
    // position.amount yet. This is equivalent to using the updateReward(msg.sender) modifier in the original
    // synthetix contract, where the modifier is called before any staking balance for that address is recorded
    _updateReward(tokenId);

    uint256 baseTokenExchangeRate = getBaseTokenExchangeRate(positionType);
    uint256 effectiveMultiplier = getEffectiveMultiplierForPositionType(positionType);

    positions[tokenId] = StakedPosition({
      positionType: positionType,
      amount: amount,
      rewards: Rewards({
        totalUnvested: 0,
        totalVested: 0,
        totalPreviouslyVested: 0,
        totalClaimed: 0,
        startTime: block.timestamp,
        endTime: block.timestamp.add(100)
      }),
      unsafeBaseTokenExchangeRate: baseTokenExchangeRate,
      unsafeEffectiveMultiplier: effectiveMultiplier,
      leverageMultiplier: 0,
      lockedUntil: 0
    });
    _mint(nftRecipient, tokenId);

    uint256 effectiveAmount = _positionToEffectiveAmount(positions[tokenId]);
    totalStakedSupply = totalStakedSupply.add(effectiveAmount);

    // Staker is address(this) when using depositAndStake or other convenience functions
    if (staker != address(this)) {
      stakingToken(positionType).safeTransferFrom(staker, address(this), amount);
    }

    emit Staked(nftRecipient, tokenId, amount, positionType, baseTokenExchangeRate);

    return tokenId;
  }

  function _getStakingAndRewardsTokenMantissa() public pure returns (uint256) {
    return stakingAndRewardsTokenMantissa();
  }

  function _getFiduStakingTokenMantissa() public view returns (uint256) {
    return uint256(10) ** IERC20withDec(address(stakingToken(StakedPositionType.Fidu))).decimals();
  }

  function _getCurveLPStakingTokenMantissa() public view returns (uint256) {
    return
      uint256(10) ** IERC20withDec(address(stakingToken(StakedPositionType.CurveLP))).decimals();
  }

  function _getRewardsTokenMantissa() public view returns (uint256) {
    return uint256(10) ** rewardsToken().decimals();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {GoldfinchConfig} from "../protocol/core/GoldfinchConfig.sol";
import {ConfigHelper} from "../protocol/core/ConfigHelper.sol";
import {TranchedPool} from "../protocol/core/TranchedPool.sol";
import {TranchingLogic} from "../protocol/core/TranchingLogic.sol";

contract TestTranchedPool is TranchedPool {
  function collectInterestAndPrincipal(address from, uint256 interest, uint256 principal) public {
    _collectInterestAndPrincipal(from, interest, principal);
  }

  function _setSeniorTranchePrincipalDeposited(uint256 principalDeposited) public {
    _poolSlices[numSlices - 1].seniorTranche.principalDeposited = principalDeposited;
  }

  /**
   * @notice Converts USDC amounts to share price
   * @param amount The USDC amount to convert
   * @param totalShares The total shares outstanding
   * @return The share price of the input amount
   */
  function usdcToSharePrice(uint256 amount, uint256 totalShares) public pure returns (uint256) {
    return TranchingLogic.usdcToSharePrice(amount, totalShares);
  }

  /**
   * @notice Converts share price to USDC amounts
   * @param sharePrice The share price to convert
   * @param totalShares The total shares outstanding
   * @return The USDC amount of the input share price
   */
  function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares) public pure returns (uint256) {
    return TranchingLogic.sharePriceToUsdc(sharePrice, totalShares);
  }

  function _setLimit(uint256 limit) public {
    creditLine.setLimit(limit);
  }

  function _modifyJuniorTrancheLockedUntil(uint256 lockedUntil) public {
    _poolSlices[numSlices - 1].juniorTranche.lockedUntil = lockedUntil;
  }
}