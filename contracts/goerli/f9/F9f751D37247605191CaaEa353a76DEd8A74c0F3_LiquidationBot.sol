// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity ^0.8.17;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Constants } from "../Libs/Constants.sol";
import { Controller } from "./Controller.sol";

error notGovernance();
error notKeeper();
error notMultisig();
error notLiquidator();

// Contains logic to fetch access control info from the Controller.
contract Controllable {
    address public immutable controller;

    constructor(address _controller) {
        controller = _controller;
    }

    // Revert if msg.sender is not the Controller's Governor
    modifier onlyGovernor() {
        if (!AccessControl(controller).hasRole(Constants.DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert notGovernance();
        }
        _;
    }

    // Revert if msg.sender is not registered as a keeper in the Controller
    modifier onlyKeeper() {
        if (!AccessControl(controller).hasRole(Constants.KEEPER_ROLE, msg.sender)) {
            revert notKeeper();
        }
        _;
    }

    modifier onlyMultisig() {
        if (!AccessControl(controller).hasRole(Constants.MULTISIG_ROLE, msg.sender)) {
            revert notMultisig();
        }
        _;
    }

    modifier onlyLiquidator() {
        if (!AccessControl(controller).hasRole(Constants.LIQUIDATOR_ROLE, msg.sender)) {
            revert notLiquidator();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Constants } from "../Libs/Constants.sol";
import { SwapAdapterRegistry } from "./SwapAdapterRegistry.sol";
import { VaultRegistry } from "./VaultRegistry.sol";

error notOwner();
error notContract();

contract Controller is AccessControl, VaultRegistry, SwapAdapterRegistry {
    using Address for address;

    // Addresses of Taurus contracts

    address public immutable tau;
    address public immutable tgt;

    mapping(bytes32 => address) public addressMapper;

    // Functions

    /**
     * @param _tau address of the TAU token
     * @param _tgt address of the TGT token
     * @param _governance address of the Governor
     * @param _multisig address of the team multisig
     */
    constructor(address _tau, address _tgt, address _governance, address _multisig) {
        tau = _tau;
        tgt = _tgt;

        // Set up access control
        _setupRole(DEFAULT_ADMIN_ROLE, _governance);
        _setupRole(Constants.MULTISIG_ROLE, _multisig);
        _setRoleAdmin(Constants.KEEPER_ROLE, Constants.MULTISIG_ROLE); // Set multisig as keeper manager
    }

    function setAddress(bytes32 _name, address _addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressMapper[_name] = _addr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Constants } from "../Libs/Constants.sol";

contract SwapAdapterRegistry is AccessControl {
    // Mapping (hash of SwapAdapter name => SwapAdapter address).
    // Note that if the result is address(0) then there is no swap adapter registered with that hash.
    // The purpose of this is to force keepers to work only with endorsed swap modules, which helps minimize necessary trust in keepers.
    mapping(bytes32 => address) public swapAdapters;

    /**
     * @dev function to allow governance to add new swap adapters.
     * Note that this function is also capable of editing existing swap adapter addresses.
     * @param _swapAdapterHash is the hash of the swap adapter name, i.e. keccak256("UniswapSwapAdapter")
     * @param _swapAdapterAddress is the address of the swap adapter contract.
     */
    function registerSwapAdapter(
        bytes32 _swapAdapterHash,
        address _swapAdapterAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapAdapters[_swapAdapterHash] = _swapAdapterAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract VaultRegistry is AccessControl {
    /**
     * @dev struct containing vault data for a registered vault
     * vaultAddress is the address of the vault
     * yieldSource is the address of the smart contract from which the vault earns yield
     */
    struct VaultData {
        address collateralToken;
        address yieldSource;
    }

    /// @dev mapping (vault smart contract address => data) for all vaults
    mapping(address => VaultData) public vaults;

    event VaultRegistered(address indexed vault, address indexed collateralToken, address indexed yieldSource);

    /**
     * @dev register a new vault, with associated data, to the Controller. For now, this is mainly to simply endorse the vault.
     * @param _vault is the address of the vault which will be registered
     * @param _vaultData is all applicable data for the vault:
     *   collateralToken is the address of the token which will be used as collateral for this vault
     *   yieldSource is the address of the yield source which will be used to generate yield for this vault
     */
    function registerVault(address _vault, VaultData calldata _vaultData) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vaults[_vault] = _vaultData;
        emit VaultRegistered(_vault, _vaultData.collateralToken, _vaultData.yieldSource);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Basic contract to hold some constants used throughout the Taurus system
library Constants {
    // Roles
    // Role for keepers, trusted accounts which manage system operations.
    bytes32 internal constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    // Role for the team multisig, which adds/removes keepers and may perform other administrative functions in the future.
    bytes32 internal constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

    // Governance has DEFAULT_ADMIN_ROLE i.e. bytes32(0). This puts it in charge of the multisig as well. It's exposed here for convenience.
    bytes32 internal constant DEFAULT_ADMIN_ROLE = bytes32(0);

    // SwapAdapter names
    bytes32 internal constant UNISWAP_SWAP_ADAPTER = keccak256("UNISWAP_SWAP_ADAPTER");
    bytes32 internal constant CURVE_SWAP_ADAPTER = keccak256("CURVE_SWAP_ADAPTER");

    // Role for accounts that can liquidate the underwater accounts in the system
    bytes32 internal constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    uint256 internal constant PRECISION = 1e18;

    // Fees

    uint256 internal constant MAX_PERC = 2e17; // Just high enough to account for protocol fees
    uint256 internal constant PERCENT_PRECISION = 1e18; // i.e. 1% will be represented as 1e16.

    // Fee names
    // Fraction of yield from GLP vault which will be sent to the feeSplitter, i.e. the protocol. Precision is PERCENT_PRECISION.
    bytes32 internal constant GLP_VAULT_PROTOCOL_FEE = keccak256("GLP_VAULT_PROTOCOL_FEE");

    bytes32 internal constant LIQUIDATOR_FEE = keccak256("LIQUIDATOR_FEE");

    bytes32 internal constant TAURUS_LIQUIDATION_FEE = keccak256("TAURUS_LIQUIDATION_FEE");

    bytes32 internal constant PRICE_ORACLE_MANAGER = keccak256("PRICE_ORACLE_MANAGER");

    bytes32 internal constant FEE_SPLITTER = keccak256("FEE_SPLITTER");
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Constants } from "./Constants.sol";

library TauMath {
    /**
     * @dev function to calculate the collateral ratio of an account.
     * Note that _price must have the correct number of deceimals to connect _coll and _debt if the latter two differ in their decimals.
     */
    function _computeCR(uint256 _coll, uint256 _debt, uint256 _price) internal pure returns (uint256) {
        if (_debt > 0) {
            uint256 newCollRatio = (_coll * _price * Constants.PERCENT_PRECISION) / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the account has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseVault } from "../Vault/BaseVault.sol";
import { Controllable } from "../Controller/Controllable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidationBot is Controllable {
    using SafeERC20 for IERC20;

    // errors
    error wrongOffset(uint256);
    error oracleCorrupt();
    error insufficientFunds();

    // events
    event CollateralWithdrawn(address indexed userAddress, uint256 amount);

    struct LiqParams {
        address vaultAddress;
        address accountAddr;
        uint256 amount;
        bool offset;
    }
    // The offset is needed, because some portion of the debt will be recovered by updateRewards().
    // Hence, the value that we provide as an input will be slightly higher than the actual debt
    uint256 public percOffset = 1e2; // this is 1%

    // The precision for the offset
    uint256 public constant OFFSET_PRECISION = 1e4;

    uint256 public constant OFFSET_LIMIT = 1e3; // This signifies not more than 10%

    uint256 public offset;

    IERC20 public tau;

    constructor(address _tau, address _controller, uint256 _offset) Controllable(_controller) {
        offset = _offset;
        tau = IERC20(_tau);
    }

    function setParams(uint256 _offset) external onlyMultisig {
        offset = _offset;
    }

    /// @dev Function to set the offset percentage
    function setOffsetPercentage(uint256 _percOff) external onlyMultisig {
        if (_percOff > (OFFSET_LIMIT)) revert wrongOffset(_percOff);

        percOffset = _percOff;
    }

    /**
     * @dev approve any token to the swapRouter.
     * note this is calleable by anyone.
     */
    function approveTokens(address _tokenIn, address _vault) external onlyMultisig {
        IERC20(_tokenIn).approve(address(_vault), type(uint256).max);
    }

    /// @dev fetch the unhealthy accounts for the given vault
    function fetchUnhealthyAccounts(
        uint256 _startIndex,
        address _vaultAddress
    ) external view returns (address[] memory unhealthyAccounts) {
        BaseVault vault = BaseVault(_vaultAddress);
        address[] memory accounts = vault.getUsers(_startIndex, _startIndex + offset);
        uint256 j;

        for (uint256 i; i < accounts.length; ++i) {
            if (!vault.getAccountHealth(accounts[i])) j++;
        }

        unhealthyAccounts = new address[](j);
        j = 0;

        for (uint256 i; i < accounts.length; i++) {
            if (!vault.getAccountHealth(accounts[i])) unhealthyAccounts[j++] = accounts[i];
        }

        return unhealthyAccounts;
    }

    /// @dev This function can be invoked by any one to liquidate the account and returns true if succeeds, false otherwise
    /// note This function takes liquidation params as input in which the amount can be
    ///      provided either inclusive/exclusive of offset
    function liquidate(LiqParams memory _liqParams) external onlyLiquidator returns (bool) {
        BaseVault vault = BaseVault(_liqParams.vaultAddress);
        uint256 newCalcAmt = _liqParams.amount;

        if (_liqParams.offset) {
            // Calculate the new amount by deducting the offset
            newCalcAmt -= ((newCalcAmt * percOffset) / OFFSET_PRECISION);
        }

        if (newCalcAmt > tau.balanceOf(address(this))) revert insufficientFunds();

        try vault.liquidate(_liqParams.accountAddr, newCalcAmt) {
            return true;
        } catch Error(string memory) {
            // providing safe exit
            return false;
        }
    }

    function withdrawLiqRewards(address _token, uint256 _amount) external onlyMultisig {
        IERC20 collToken = IERC20(_token);
        if (_amount > collToken.balanceOf(address(this))) revert insufficientFunds();
        collToken.transfer(msg.sender, _amount);

        emit CollateralWithdrawn(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracleWrapper {
    struct OracleResponse {
        uint8 decimals;
        uint256 currentPrice;
        uint256 lastPrice;
        uint256 lastUpdateTimestamp;
        bool success;
    }

    error TokenIsNotRegistered(address _underlying, address _strike);
    error ResponseFromOracleIsInvalid(address _token, address _oracle);
    error ZeroAddress();
    error NotContract(address _address);
    error InvalidDecimals();

    event NewOracle(address indexed _aggregatorAddress, address _underlying, address _strike);

    function fetchPrice(address _underlying, address _strike) external;

    function getSavedResponse(address _underlying, address _strike) external returns (OracleResponse memory response);

    function getLastPrice(address _underlying, address _strike) external view returns (uint256 lastPrice);

    function getCurrentPrice(address _underlying, address _strike) external view returns (uint256 currentPrice);

    function getExternalPrice(
        address _underlying,
        address _strike
    ) external view returns (uint256 price, uint8 decimals, bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPriceOracleManager {
    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    event NewWrapperRegistered(address indexed _underlying, address indexed _strike, address indexed _wrapperAddress);

    event WrapperUpdated(address indexed _underlying, address indexed _strike, address indexed _wrapperAddress);

    function setWrapper(address _underlying, address _strike, address _wrapperAddress) external;

    function updateWrapper(address _underlying, address _strike, address _wrapperAddress) external;

    function getPrice(address _underlying, address _strike) external returns (uint256 price, uint8 decimals);

    function getExternalPrice(
        address _underlying,
        address _strike
    ) external returns (uint256 price, uint8 decimals, bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IPriceOracleManager } from "./Interface/IPriceOracleManager.sol";
import { IOracleWrapper } from "./Interface/IOracleWrapper.sol";

error notContract();
error duplicateWrapper(address);
error wrapperNotRegistered(address);
error priceNotUpdated(address);
error oracleCorrupted(address);

contract PriceOracleManager is IPriceOracleManager, Ownable {
    using Address for address;

    // This is a mapping of wrapper addresses for a particular target asset
    // maps address(underlying) => address(strike) => address(wrapper)
    // Wherein, the underlying is the target asset and strike is the measure of the underlying
    // Eg: If we consider ETH/USD pair, ETH will be underlying and USD will be strike
    mapping(address => mapping(address => address)) public wrapperAddressMap;

    uint256 public constant TIME_OFFSET = 4 hours;

    function setWrapper(address _underlying, address _strike, address _wrapperAddress) external override onlyOwner {
        if (!_wrapperAddress.isContract()) revert notContract();
        if (wrapperAddressMap[_underlying][_strike] != address(0)) revert duplicateWrapper(_wrapperAddress);

        wrapperAddressMap[_underlying][_strike] = _wrapperAddress;

        emit NewWrapperRegistered(_underlying, _strike, _wrapperAddress);
    }

    function updateWrapper(address _underlying, address _strike, address _wrapperAddress) external override onlyOwner {
        if (!_wrapperAddress.isContract()) revert notContract();
        if (wrapperAddressMap[_underlying][_strike] == address(0)) revert wrapperNotRegistered(_wrapperAddress);

        wrapperAddressMap[_underlying][_strike] = _wrapperAddress;

        emit WrapperUpdated(_underlying, _strike, _wrapperAddress);
    }

    function getPrice(address _underlying, address _strike) external override returns (uint256 price, uint8 decimals) {
        // First fetch the current price and then fetch the previous updated price.
        // If the time diff is greater than offset, then the oracle is stale.
        IOracleWrapper wrapper = IOracleWrapper(wrapperAddressMap[_underlying][_strike]);

        if (address(wrapper) == address(0)) revert wrapperNotRegistered(address(wrapper));

        IOracleWrapper.OracleResponse memory resp = wrapper.getSavedResponse(_underlying, _strike);

        if (!resp.success) revert oracleCorrupted(address(wrapper));
        if ((block.timestamp - resp.lastUpdateTimestamp) >= TIME_OFFSET) revert priceNotUpdated(address(wrapper));

        price = resp.currentPrice;
        decimals = resp.decimals;
    }

    function getExternalPrice(
        address _underlying,
        address _strike
    ) external view override returns (uint256 price, uint8 decimals, bool success) {
        IOracleWrapper wrapper = IOracleWrapper(wrapperAddressMap[_underlying][_strike]);

        if (address(wrapper) == address(0)) revert wrapperNotRegistered(address(wrapper));

        return wrapper.getExternalPrice(_underlying, _strike);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev abstract contract meant solely to force all SwapAdapters to implement the same swap() function.
 */
abstract contract BaseSwapAdapter {
    function swap(address _outputToken, bytes calldata _swapData) external virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

error notGovernance();
error mintLimitExceeded(uint256 newAmount, uint256 maxMintAmount);

contract TAU is ERC20, ERC20Burnable {
    address public governance;

    // Max amount of tokens which a given vault can mint. Since this is set to zero by default, there is no need to register vaults.
    mapping(address => uint256) public mintLimit;
    mapping(address => uint256) public currentMinted;

    constructor(address _governance) ERC20("TAU", "TAU") {
        governance = _governance;
    }

    /**
     * @dev Set new mint limit for a given vault. Only governance can call this function.
     * note if the new limit is lower than the vault's current amount minted, this will disable future mints for that vault,
        but will do nothing to its existing minted amount.
     * @param vault The address of the vault whose mintLimit will be updated
     * @param newLimit The new mint limit for the target vault
     */
    function setMintLimit(address vault, uint256 newLimit) external {
        if (msg.sender != governance) {
            revert notGovernance();
        }
        mintLimit[vault] = newLimit;
    }

    function mint(address recipient, uint256 amount) external {
        // Check whether mint amount exceeds mintLimit for msg.sender
        uint256 newMinted = currentMinted[msg.sender] + amount;
        if (newMinted > mintLimit[msg.sender]) {
            revert mintLimitExceeded(newMinted, mintLimit[msg.sender]);
        }

        // Update vault currentMinted
        currentMinted[msg.sender] = newMinted;

        // Mint TAU to recipient
        _mint(recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual override {
        address account = _msgSender();
        _burn(account, amount);
        _decreaseCurrentMinted(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance. Also decreases the burner's currentMinted amount if the burner is a vault.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual override {
        super.burnFrom(account, amount);
        _decreaseCurrentMinted(account, amount);
    }

    function _decreaseCurrentMinted(address account, uint256 amount) internal virtual {
        // If the burner is a vault, subtract burnt TAU from its currentMinted.
        // This has a few highly unimportant edge cases which can generally be rectified by increasing the relevant vault's mintLimit.
        uint256 accountMinted = currentMinted[account];
        if (accountMinted >= amount) {
            currentMinted[msg.sender] = accountMinted - amount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Contracts
import { Controllable } from "../Controller/Controllable.sol";
import { Controller } from "../Controller/Controller.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { PriceOracleManager } from "../Oracle/PriceOracleManager.sol";
import { TauDripFeed } from "./TauDripFeed.sol";

import { SwapHandler } from "./SwapHandler.sol";

import { TAU } from "../TAU.sol";

// Libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Constants } from "../Libs/Constants.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { TauMath } from "../Libs/TauMath.sol";

// Note that this contract is not compatible with ERC777 tokens due to potential reentrancy concerns.
abstract contract BaseVault is SwapHandler {
    using SafeERC20 for IERC20;
    using Address for address;

    /// Define the errors
    error insufficientCollateral();
    error userNotFound();
    error wrongLiquidationAmount();
    error incorrectDebtRepayAmount();
    error cannotLiquidateHealthyAccount();

    // Events
    event AccountLiquidated(address _liquidator, address _account, uint256 _amount, uint256 _liqFees);

    struct UserDetails {
        uint256 collateral; // Collateral amount deposited by user
        uint256 debt; // Debt amount borrowed by user
        uint256 lastUpdatedRewardPerCollateral; // Last updated reward per collateral for the user
        uint256 startTimestamp; // Time when the first deposit was made by the user
    }

    /// @dev mapping of user and UserDetails
    mapping(address => UserDetails) public userDetails;

    /// @dev keep track of user addresses to index the userDetails for liquidation
    address[] public userAddresses;

    /// @dev placeholder address used to ask oracle for the price of USD
    address public immutable usdOracle;

    // Minimum collateral ratio (change this to non-constant variable later)
    uint256 public constant MIN_COL_RATIO = (120 * Constants.PERCENT_PRECISION) / 100; // 120 %

    // Maximum collateral ratio an account can have after being liquidated (limits liquidation size to only what is necessary)
    uint256 internal constant MAX_LIQ_COLL_RATIO = (130 * Constants.PERCENT_PRECISION) / 100; // 130 %

    constructor(
        address _controller,
        address _tau,
        address _collateralToken,
        uint256 _maxSlippageFraction,
        address _usdOracle
    ) Controllable(_controller) TauDripFeed(_tau, _collateralToken) SwapHandler(_maxSlippageFraction) {
        usdOracle = _usdOracle;
    }

    /**
     * @dev modifier to update user's reward per collateral and pay off some of their debt. This is
        executed before any function that modifies a user's collateral or debt.
     * note if there is surplus TAU after the debt is paid off, it is added back to the drip feed.
     */
    modifier updateReward(address _account) {
        // Disburse available yield from the drip feed
        _disburseTau();

        // If user has collateral, pay down their debt and recycle surplus rewards back into the tauDripFeed.
        uint256 _userCollateral = userDetails[_account].collateral;
        if (_userCollateral > 0) {
            // Get diff between global rewardPerCollateral and user lastUpdatedRewardPerCollateral
            uint256 _rewardDiff = cumulativeTauRewardPerCollateral -
                userDetails[_account].lastUpdatedRewardPerCollateral;

            // Calculate user's TAU earned since the last update, use it to pay off debt
            uint256 _tauEarned = (_rewardDiff * _userCollateral) / Constants.PRECISION;

            uint256 _userDebt = userDetails[_account].debt;
            if (_tauEarned > _userDebt) {
                // If user has earned more than enough TAU to pay off their debt, pay off debt and add surplus to drip feed
                userDetails[_account].debt = 0;

                _tauEarned -= _userDebt;
                _withholdTau(_tauEarned);
            } else {
                // Pay off as much debt as possible
                userDetails[_account].debt = _userDebt - _tauEarned;
            }
        } else {
            // Keep track of new users
            if (userDetails[_account].startTimestamp == 0) {
                userAddresses.push(_account);
                userDetails[_account].startTimestamp = block.timestamp;
            }
        }

        // Update user lastUpdatedRewardPerCollateral
        userDetails[_account].lastUpdatedRewardPerCollateral = cumulativeTauRewardPerCollateral;
        _;
    }

    //------------------------------------------------------------View functions------------------------------------------------------------

    function _checkAccountHealth(address _account) internal view {
        if (!getAccountHealth(_account)) {
            revert insufficientCollateral();
        }
    }

    /// @dev In this function, we calculate the collateral ratio
    function getCollRatio(address _account) internal view returns (uint256 ratio) {
        // Fetch the price from oracle manager
        (uint256 price, uint8 decimals) = getOraclePrice(collateralToken, usdOracle);

        // Check that user's collateral ratio is above minimum healthy ratio
        ratio =
            TauMath._computeCR(userDetails[_account].collateral, userDetails[_account].debt, price) /
            (10 ** decimals);
    }

    /// @dev In this function, we assume that TAU is worth $1 exactly. This allows users to arbitrage the difference, if any.
    function getAccountHealth(address _account) public view returns (bool) {
        uint256 ratio = getCollRatio(_account);

        return (ratio > MIN_COL_RATIO);
    }

    /// @dev Get the number of users
    function getUsersCount() public view returns (uint256) {
        return userAddresses.length;
    }

    /** @dev Get the user details in the range given start and end index.
     * note the start and end index are inclusive
     */
    function getUsersDetailsInRange(uint256 _start, uint256 _end) public view returns (UserDetails[] memory users) {
        if (_end > getUsersCount() || _start > _end) revert indexOutOfBound();

        users = new UserDetails[](_end - _start + 1);

        for (uint i = _start; i < _end; ++i) {
            users[i - _start] = userDetails[userAddresses[i]];
        }
    }

    /** @dev Get the user addresses in the range given start and end index
     * note the start and end index are inclusive
     */
    function getUsers(uint256 _start, uint256 _end) public view returns (address[] memory users) {
        if (_end > getUsersCount() || _start > _end) revert indexOutOfBound();

        users = new address[](_end - _start + 1);

        for (uint256 i = _start; i < _end; ++i) {
            users[i - _start] = userAddresses[i];
        }
    }

    //------------------------------------------------------------User functions------------------------------------------------------------

    function modifyPosition(
        uint256 _collateralDelta,
        uint256 _debtDelta,
        bool _increaseCollateral,
        bool _increaseDebt
    ) external whenNotPaused updateReward(msg.sender) {
        _modifyPosition(msg.sender, _collateralDelta, _debtDelta, _increaseCollateral, _increaseDebt);
    }

    /**
     * @dev Function allowing a user to automatically close their position.
     * Note that this function is available even when the contract is paused.
     * Note that since this function does not call updateReward, it should only be used when the contract is paused.
     *
     */
    function emergencyClosePosition() external {
        _modifyPosition(msg.sender, userDetails[msg.sender].collateral, userDetails[msg.sender].debt, false, false);
    }

    /**
     * @dev Find the correct liquidation value for a user.
     * @param _account is the account which may be liquidated.
     * @return amount is the amount of debt which will be repaid as part of the liquidation process, 0 if the user's account is healthy.
     */
    function checkLiquidity(address _account) public view returns (uint256 amount) {
        // If the user is part of the system, check the health
        if (getAccountHealth(_account)) return 0;

        uint256 liquidationFeeMultiplier = Constants.PERCENT_PRECISION + (feeMapping[Constants.TAURUS_LIQUIDATION_FEE]);
        (uint256 price, uint8 decimals) = getOraclePrice(collateralToken, usdOracle);

        // Formula to find the liquidation amount is as follows
        // [(collateral * price) - (F * X)] / (debt - X) = Min Liq Ratio
        // Here,
        // collateral -> collateral amount user has put in
        // price      -> price of the collateral asset
        // F          -> current coll ratio - total fee%
        // X          -> liquidation amount
        // debt       -> debt taken by the user on the collateral
        amount =
            ((MAX_LIQ_COLL_RATIO * userDetails[_account].debt) -
                (((userDetails[_account].collateral * price) / (10 ** decimals)) * (Constants.PERCENT_PRECISION))) /
            (MAX_LIQ_COLL_RATIO - liquidationFeeMultiplier);
    }

    //------------------------------------------------------------BaseVault internal functions------------------------------------------------------------

    /**
     * @dev function to modify user collateral and debt in any way. If debt is increased or collateral reduced, the account must be healthy at the end of the tx.
     * note that generally this function is called after updateReward, meaning that user details are up to date.
     * @param _account is the account to be modified
     * @param _collateralDelta is the absolute value of the change in collateral.
     *  note that withdrawals cannot attempt to withdraw more than the user collateral balance, or the transaction will revert.
     * @param _debtDelta is the absolute value of the change in debt
     *  note that repayments can attempt to repay more than their debt balance. Only their debt balance will be pulled, and used to cancel out their debt.
     * @param _increaseCollateral is true if collateral is being deposited, false if collateralDelta is 0 or collateral is being withdrawn
     * @param _increaseDebt is true if debt is being borrowed, false if debtDelta is 0 or debt is being repaid
     */
    function _modifyPosition(
        address _account,
        uint256 _collateralDelta,
        uint256 _debtDelta,
        bool _increaseCollateral,
        bool _increaseDebt
    ) internal virtual {
        bool mustCheckHealth; // False until an action is taken which can reduce account health

        // Handle debt first, since TAU has no reentrancy concerns.
        if (_debtDelta != 0) {
            if (_increaseDebt) {
                // Borrow TAU from the vault
                userDetails[_account].debt += _debtDelta;
                mustCheckHealth = true;
                TAU(tau).mint(_account, _debtDelta);
            } else {
                // Repay TAU debt
                uint256 currentDebt = userDetails[_account].debt;
                if (_debtDelta > currentDebt) _debtDelta = currentDebt;
                userDetails[_account].debt -= _debtDelta;
                // Burn Tau used to repay debt
                TAU(tau).burnFrom(_account, _debtDelta);
            }
        }

        if (_collateralDelta != 0) {
            if (_increaseCollateral) {
                // Deposit collateral
                userDetails[_account].collateral += _collateralDelta;
                IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), _collateralDelta);
            } else {
                // Withdraw collateral
                uint256 currentCollateral = userDetails[_account].collateral;
                if (_collateralDelta > currentCollateral) revert insufficientCollateral();
                userDetails[_account].collateral = currentCollateral - _collateralDelta;
                mustCheckHealth = true;
                IERC20(collateralToken).safeTransfer(msg.sender, _collateralDelta);
            }
        }

        if (mustCheckHealth) {
            _checkAccountHealth(_account);
        }
    }

    //------------------------------------------------------------Liquidator/governance functions------------------------------------------------------------

    /**
     * @param _account is the account to be liquidated. It must be unhealthy.
     * @param _amount is the amount of debt to be repaid. It must be greater than 0 and less than or equal to the liquidateable amount.
     * @return true if the liquidation was successful
     */
    function liquidate(
        address _account,
        uint256 _amount
    ) external onlyLiquidator whenNotPaused updateReward(_account) returns (bool) {
        // Check if the liquidation amount is > 0 and not more than the liquidateable amount
        if (!(_amount > 0) || _amount > checkLiquidity(_account)) revert wrongLiquidationAmount();

        UserDetails memory accDetails = userDetails[_account];

        // Get total fee charged to the user for this liquidation. Collateral equal to (liquidated taurus debt value * feeMultiplier) will be deducted from the user's account.
        uint256 liquidationFeeMultiplier = Constants.PERCENT_PRECISION + feeMapping[Constants.TAURUS_LIQUIDATION_FEE];

        (uint256 price, uint8 decimals) = getOraclePrice(collateralToken, usdOracle);

        // Calculate the new collateral and debt amount post-liquidation
        // newColl = oldColl - (curCollRatio * _amount / precision * price)
        // newDebt = oldDebt - _amount
        uint256 collateralToLiquidate = ((liquidationFeeMultiplier * _amount * 10 ** decimals) /
            (Constants.PERCENT_PRECISION * price));
        uint256 newCollAmt;
        // Failsafe conditions
        if (collateralToLiquidate > accDetails.collateral) {
            collateralToLiquidate = accDetails.collateral;
            // newCollAmt is zero, since all of the user's collateral will be liquidated
        } else {
            newCollAmt = accDetails.collateral - collateralToLiquidate;
        }
        uint256 newDebtAmt = _amount > accDetails.debt ? 0 : accDetails.debt - _amount;

        // Now, calculate the post-liquidation collateral ratio
        uint256 newRatio = TauMath._computeCR(newCollAmt, newDebtAmt, price) / (10 ** decimals);

        if (newRatio < MIN_COL_RATIO) {
            revert wrongLiquidationAmount();
        }

        // Update the collateral and debt of the user
        userDetails[_account].collateral = newCollAmt;
        userDetails[_account].debt = newDebtAmt;

        // Burn liquidator's Tau
        TAU(tau).burnFrom(msg.sender, _amount);

        // Transfer part of _amount to liquidator and Taurus as fees for liquidation
        // liquidationFee = collateralToLiquidate * liquidationFee / feePrecision;
        uint256 tauLiqFee = (collateralToLiquidate * feeMapping[Constants.TAURUS_LIQUIDATION_FEE]) /
            Constants.PERCENT_PRECISION;

        IERC20(collateralToken).safeTransfer(msg.sender, collateralToLiquidate - tauLiqFee);
        IERC20(collateralToken).safeTransfer(Controller(controller).addressMapper(Constants.FEE_SPLITTER), tauLiqFee);

        emit AccountLiquidated(msg.sender, _account, collateralToLiquidate, tauLiqFee);

        return true;
    }

    /**
     * @dev Updates a user's rewards. Callable by anyone, but really only useful for keepers
     *  to update inactive accounts (thus redistributing their excess rewards to the vault).
     * @param _account is the account whose rewards will be updated
     */
    function updateRewards(address _account) external whenNotPaused updateReward(_account) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseVault } from "./BaseVault.sol";
import { Controllable } from "../Controller/Controllable.sol";
import { Controller } from "../Controller/Controller.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseSwapAdapter } from "../SwapAdapters/BaseSwapAdapter.sol";
import { Constants } from "../Libs/Constants.sol";
import { PriceOracleManager } from "../Oracle/PriceOracleManager.sol";
import { TauDripFeed } from "./TauDripFeed.sol";
import { SwapAdapterRegistry } from "../Controller/SwapAdapterRegistry.sol";

abstract contract FeeMapping is Controllable {
    error feePercTooLarge();
    error indexOutOfBound();

    /// @dev keep track of fee types being used by the vault
    mapping(bytes32 => uint256) internal feeMapping;

    /// @dev add the fee types being used by the vault
    /// note if we want to delete the mapping, pass _feeType with empty array
    function addFeePerc(bytes32[] memory _feeType, uint256[] memory _perc) public onlyMultisig {
        uint256 _feeTypeLength = _feeType.length;
        if (_feeTypeLength != _perc.length) revert indexOutOfBound();

        for (uint256 i; i < _feeTypeLength; ++i) {
            if (_perc[i] > Constants.MAX_PERC) revert feePercTooLarge();
            feeMapping[_feeType[i]] = _perc[i];
        }
    }

    function getFeePerc(bytes32 _feeType) public view returns (uint256 perc) {
        return (feeMapping[_feeType]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseVault } from "./BaseVault.sol";
import { Controllable } from "../Controller/Controllable.sol";
import { Controller } from "../Controller/Controller.sol";
import { BaseSwapAdapter } from "../SwapAdapters/BaseSwapAdapter.sol";
import { FeeMapping } from "./FeeMapping.sol";
import { PriceOracleManager } from "../Oracle/PriceOracleManager.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SwapAdapterRegistry } from "../Controller/SwapAdapterRegistry.sol";
import { TauDripFeed } from "./TauDripFeed.sol";

import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Libraries
import { Constants } from "../Libs/Constants.sol";

abstract contract SwapHandler is FeeMapping, TauDripFeed {
    using SafeERC20 for IERC20;

    // Errors
    error notContract();
    error oracleCorrupt();
    error tokenCannotBeSwapped();
    error tooMuchSlippage(uint256 actual, uint256 maxAllowed);
    error unregisteredSwapAdapter();
    error zeroAmount();

    /// @dev the minimum vault value post-swap, as a fraction of the vault value pre-swap * 1e18.
    uint256 public immutable maxSlippageFraction;

    event Swap(address indexed fromToken, uint256 feesToProtocol, uint256 fromAmount, uint256 tauReturned);

    constructor(uint256 _maxSlippageFraction) {
        maxSlippageFraction = _maxSlippageFraction;
    }

    /**
     * @dev function called as part of the yield pull process. This will fetch swap modules from the Controller, use them 
        to handle a swap from vault yield to tau, then validate that the swap did not encounter too much slippage.
     * @param _yieldTokenAddress is the address of the token to be swapped. Must be a yield token, so cannot be the vault's collateral token or tau.
     * @param _yieldTokenAmount is the amount of yield token. Some will be transferred to the FeeSplitter for use by the protocol. The rest will be swapped for tau.
     * note that slippage parameters must be built based on the amount to be swapped, not based on _yieldTokenAmount above (some of which will not be swapped).
     * @param _swapAdapterHash is the hash of the swap adapter to be used, i.e. keccak256("UniswapSwapAdapter") for the UniswapSwapAdapter.
     * @param _swapParams is the params to be passed to the SwapAdapter.
     * note that this function may only be called by a registered keeper.
     * note that this function can only be called when the contract is unpaused. whenNotPaused is checked within disburseTau().
     */
    function swapForTau(
        address _yieldTokenAddress,
        uint256 _yieldTokenAmount,
        bytes32 _swapAdapterHash,
        bytes calldata _swapParams
    ) external onlyKeeper whenNotPaused {
        // Ensure keeper is allowed to swap this token
        if (_yieldTokenAddress == collateralToken) {
            revert tokenCannotBeSwapped();
        }

        if (_yieldTokenAmount == 0) {
            revert zeroAmount();
        }

        // Get and validate swap adapter address
        address swapAdapterAddress = SwapAdapterRegistry(controller).swapAdapters(_swapAdapterHash);
        if (swapAdapterAddress == address(0)) {
            // The given hash has not yet been approved as a swap adapter.
            revert unregisteredSwapAdapter();
        }

        // Calculate portion of tokens which will be swapped for TAU and disbursed to the vault, and portion which will be sent to the protocol.
        uint256 protocolFees = (feeMapping[Constants.GLP_VAULT_PROTOCOL_FEE] * _yieldTokenAmount) /
            Constants.PERCENT_PRECISION;
        uint256 swapAmount = _yieldTokenAmount - protocolFees;

        // Get total token value of tokens to be swapped. This will be used later to check that there hasn't been too much slippage.
        uint256 inputTokenValueinTau = _getInputTokenValueinTau(_yieldTokenAddress, swapAmount);

        // Transfer tokens to swap adapter
        IERC20(_yieldTokenAddress).safeTransfer(swapAdapterAddress, swapAmount);

        // Call swap function, get return amount from them. Specify tau as the output token.
        uint256 tauReturned = BaseSwapAdapter(swapAdapterAddress).swap(tau, _swapParams);

        // Validate that swap did not encounter too much slippage by checking new token value
        if (tauReturned < inputTokenValueinTau) {
            // No need to check slippage if there was none
            uint256 totalSlippage = (Constants.PRECISION * (inputTokenValueinTau - tauReturned)) / inputTokenValueinTau;
            if (totalSlippage > maxSlippageFraction) {
                revert tooMuchSlippage(totalSlippage, maxSlippageFraction);
            }
        }

        // Burn received Tau
        ERC20Burnable(tau).burn(tauReturned);

        // Add Tau rewards to withheldTAU to avert sandwich attacks
        _disburseTau();
        _withholdTau(tauReturned);

        // Send protocol fees to FeeSplitter
        IERC20(_yieldTokenAddress).safeTransfer(
            Controller(controller).addressMapper(Constants.FEE_SPLITTER),
            protocolFees
        );

        // Emit event
        emit Swap(_yieldTokenAddress, protocolFees, swapAmount, tauReturned);
    }

    function getOraclePrice(
        address _collateralToken,
        address _baseToken
    ) internal view returns (uint256 price, uint8 decimals) {
        bool success;
        // Fetch the price from oracle manager
        (price, decimals, success) = PriceOracleManager(
            Controller(controller).addressMapper(Constants.PRICE_ORACLE_MANAGER)
        ).getExternalPrice(_collateralToken, _baseToken);
        if (!success) {
            revert oracleCorrupt();
        }
    }

    /**
     * @dev internal function to call the oracle module for whichever token is being swapped and get its price.
     * @dev note that we do get its price in terms of TAU here rather than USD. This function is to be used only for keeper-instigated swaps.
     * @return tau * PRECISION / collateral
     */
    function _getInputTokenValueinTau(address _tokenAddress, uint256 _tokenAmount) internal view returns (uint256) {
        (uint256 price, uint8 decimals) = getOraclePrice(_tokenAddress, tau);

        // Result will always be normalized to 18 decimals.
        return (_tokenAmount * price) / (10 ** decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { Controllable } from "../Controller/Controllable.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Constants } from "../Libs/Constants.sol";

// @dev contains logic for accepting TAU yield and distributing it to users over time to protect against sandwich attacks.
abstract contract TauDripFeed is Pausable, Controllable {
    // @dev total amount of tau tokens that have ever been rewarded to the contract, divided by the total collateral present at the time of each deposit.
    // This number can only increase.
    uint256 public cumulativeTauRewardPerCollateral;

    /// @dev Tau tokens yet to be doled out to the vault. Tokens yet to be doled out are not counted towards cumulativeTauRewardPerCollateral.
    uint256 public tauWithheld;

    /// @dev timestamp at which tokens were most recently disbursed. Updated only when tauWithheld > 0. Used in conjunction with DRIP_DURATION to
    /// calculate next token disbursal amount.
    uint256 public tokensLastDisbursedTimestamp;

    /// @dev duration of the drip feed. Deposited TAU is steadily distributed to the contract over this amount of time.
    uint256 public constant DRIP_DURATION = 1 days;

    /// @dev address of TAU
    address public immutable tau;

    /// @dev address of token used as collateral by this vault.
    address public collateralToken;

    constructor(address _tau, address _collateralToken) {
        tau = _tau;
        collateralToken = _collateralToken;
    }

    function pause() external onlyMultisig {
        _pause();
    }

    function unpause() external onlyMultisig {
        _unpause();
    }

    /**
     * @dev function to deposit TAU into the contract while averting sandwich attacks.
     * @param amount is the amount of TAU to be burned and used to cancel out debt.
     * note the main source of TAU is the SwapHandler. This function is just a safeguard in case some other source of TAU arises.
     */
    function distributeTauRewards(uint256 amount) external whenNotPaused {
        // Burn depositor's Tau
        ERC20Burnable(tau).burnFrom(msg.sender, amount);

        // Disburse available tau
        _disburseTau();

        // Set new tau aside to protect against sandwich attacks
        _withholdTau(amount);
    }

    function disburseTau() external whenNotPaused {
        _disburseTau();
    }

    /**
     * @dev disburse TAU to the contract by updating cumulativeTauRewardPerCollateral.
     * Note that since rewards are distributed based on timeElapsed / DRIP_DURATION, this function will technically only distribute 100% of rewards if it is not called
        until the DRIP_DURATION has elapsed. This isn't too much of an issue--at worst, about 2/3 of the rewards will be distributed per DRIP_DURATION, the rest carrying over
        to the next DRIP_DURATION.
     * Note that if collateral == 0, tokens will not be disbursed. This prevents undefined behavior when rewards are deposited before collateral is.
     */
    function _disburseTau() internal {
        if (tauWithheld > 0) {
            uint256 _currentCollateral = IERC20(collateralToken).balanceOf(address(this));

            if (_currentCollateral > 0) {
                // Get time elapsed
                uint256 _timeElapsed = block.timestamp - tokensLastDisbursedTimestamp;

                // Get tokens to disburse
                uint256 _tokensToDisburse;
                if (_timeElapsed >= DRIP_DURATION) {
                    _tokensToDisburse = tauWithheld;
                    tauWithheld = 0;
                } else {
                    _tokensToDisburse = (_timeElapsed * tauWithheld) / DRIP_DURATION;
                    tauWithheld -= _tokensToDisburse;
                }

                // Divide by current collateral to get the additional tokensPerCollateral which we'll be adding to the cumulative sum
                uint256 _extraRewardPerCollateral = (_tokensToDisburse * Constants.PRECISION) / _currentCollateral;

                // Add to cumulative reward
                cumulativeTauRewardPerCollateral += _extraRewardPerCollateral;

                // Update block.timestamp
                tokensLastDisbursedTimestamp = block.timestamp;
            }
        }
    }

    /**
     * @dev internal function to deposit TAU into the contract while averting sandwich attacks.
     * This is primarily meant to be called by the SwapHandler, which is the smart contract's source of TAU.
     * It is also called by the BaseVault when an account earns TAU rewards in excess of their debt.
     * Note that this function should generally only be called after disburseTau has been called.
     */
    function _withholdTau(uint256 amount) internal {
        // Update block.timestamp in case it hasn't been updated yet this transaction.
        tokensLastDisbursedTimestamp = block.timestamp;
        tauWithheld += amount;
    }
}