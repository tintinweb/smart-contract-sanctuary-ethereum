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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts (last updated v4.8.1) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: When the vault is empty or nearly empty, deposits are at high risk of being stolen through frontrunning with
 * a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _decimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _decimals = success ? assetDecimals : super.decimals();
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are read from the underlying asset in the constructor and cached. If this fails (e.g., the asset
     * has not been created yet), the cached value is set to a default obtained by `super.decimals()` (which depends on
     * inheritance but is most likely 18). Override this function in order to set a guaranteed hardcoded value.
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @dev Checks if vault is "healthy" in the sense of having assets backing the circulating shares.
     */
    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
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
pragma solidity ^0.8.17;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Deposit, FCNVaultMetadata, OptionBarrierType, OptionBarrier, VaultStatus, Withdrawal } from "./Structs.sol";
import { Oracle } from "./Oracle.sol";
import { CegaState } from "./CegaState.sol";

library Calculations {
    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant SECONDS_TO_DAYS = 86400;
    uint256 public constant BPS_DECIMALS = 10 ** 4;
    uint256 public constant LARGE_CONSTANT = 10 ** 18;

    /**
     * @notice Calculates the current yield accumulated to the current day for a given vault
     */
    function calculateCurrentYield(FCNVaultMetadata storage self) public {
        require(self.vaultStatus == VaultStatus.Traded, "500:WS");
        uint256 currentTime = block.timestamp;

        if (currentTime > self.tradeExpiry) {
            self.vaultStatus = VaultStatus.TradeExpired;
            return;
        }

        uint256 numberOfDaysPassed = (currentTime - self.tradeDate) / SECONDS_TO_DAYS;

        self.totalCouponPayoff = calculateCouponPayment(self.underlyingAmount, self.aprBps, numberOfDaysPassed);
    }

    /**
     * @notice Permissionless method that reads price from oracle contracts and checks if barrier is triggered
     * @param cegaStateAddress is the address of the CegaState contract that stores the oracle addresses
     */
    function checkBarriers(FCNVaultMetadata storage self, address cegaStateAddress) public {
        if (self.isKnockedIn == true) {
            return;
        }

        require(self.vaultStatus == VaultStatus.Traded, "500:WS");

        for (uint256 i = 0; i < self.optionBarriersCount; i++) {
            OptionBarrier storage optionBarrier = self.optionBarriers[i];
            address oracle = getOracleAddress(optionBarrier, cegaStateAddress);
            (, int256 answer, , , ) = Oracle(oracle).latestRoundData();

            // Knock In: Check if current price is less than barrier
            if (optionBarrier.barrierType == OptionBarrierType.KnockIn) {
                if (uint256(answer) <= optionBarrier.barrierAbsoluteValue) {
                    self.isKnockedIn = true;
                }
            }
        }
    }

    /**
     * @notice Calculates the final payoff for a given vault
     * @param self is the FCNVaultMetadata
     * @param cegaStateAddress is address of cegaState
     */
    function calculateVaultFinalPayoff(
        FCNVaultMetadata storage self,
        address cegaStateAddress
    ) public returns (uint256) {
        uint256 totalPrincipal;
        uint256 totalCouponPayment;
        uint256 principalToReturnBps = BPS_DECIMALS;

        require(
            (self.vaultStatus == VaultStatus.TradeExpired || self.vaultStatus == VaultStatus.PayoffCalculated),
            "500:WS"
        );

        // Calculate coupon payment
        totalCouponPayment = calculateCouponPayment(self.underlyingAmount, self.aprBps, self.tenorInDays);

        // Calculate principal
        if (self.isKnockedIn) {
            principalToReturnBps = calculateKnockInRatio(self, cegaStateAddress);
        }

        totalPrincipal = (self.underlyingAmount * principalToReturnBps) / BPS_DECIMALS;
        uint256 vaultFinalPayoff = totalPrincipal + totalCouponPayment;
        self.totalCouponPayoff = totalCouponPayment;
        self.vaultFinalPayoff = vaultFinalPayoff;
        self.vaultStatus = VaultStatus.PayoffCalculated;
        return vaultFinalPayoff;
    }

    /**
     * @notice Calculates the percentage of principal to return to users if a knock in occurs.
     * Iterates through all knock-in barriers and checks the ratio of (spot/strike) for each asset
     * Returns the minimum of the knock-in ratios.
     * @param self is the FCNVaultMetadata
     * @param cegaStateAddress is address of cegaState
     */
    function calculateKnockInRatio(
        FCNVaultMetadata storage self,
        address cegaStateAddress
    ) public view returns (uint256) {
        OptionBarrier[] memory optionBarriers = self.optionBarriers;
        uint256 optionBarriersCount = self.optionBarriersCount;

        uint256 minRatioBps = LARGE_CONSTANT;
        for (uint256 i = 0; i < optionBarriersCount; i++) {
            OptionBarrier memory optionBarrier = optionBarriers[i];
            address oracle = getOracleAddress(optionBarrier, cegaStateAddress);
            (, int256 answer, , , ) = Oracle(oracle).latestRoundData();

            // Only calculate the ratio if it is a knock in barrier
            if (optionBarrier.barrierType == OptionBarrierType.KnockIn) {
                uint256 ratioBps = (uint256(answer) * LARGE_CONSTANT) / optionBarrier.strikeAbsoluteValue;
                minRatioBps = Math.min(ratioBps, minRatioBps);
            }
        }
        return ((minRatioBps * BPS_DECIMALS)) / LARGE_CONSTANT;
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * @param managementFeeBps is the management fee in bps
     * @param yieldFeeBps is the yield fee in bps
     */
    function calculateFees(
        FCNVaultMetadata storage self,
        uint256 managementFeeBps,
        uint256 yieldFeeBps
    ) public view returns (uint256, uint256, uint256) {
        uint256 totalFee = 0;
        uint256 managementFee = 0;
        uint256 yieldFee = 0;

        uint256 underlyingAmount = self.underlyingAmount;
        uint256 numberOfDaysPassed = (self.tradeExpiry - self.vaultStart) / SECONDS_TO_DAYS;

        managementFee =
            (underlyingAmount * numberOfDaysPassed * managementFeeBps * LARGE_CONSTANT) /
            DAYS_IN_YEAR /
            BPS_DECIMALS /
            LARGE_CONSTANT;

        if (self.vaultFinalPayoff > underlyingAmount) {
            uint256 profit = self.vaultFinalPayoff - underlyingAmount;
            yieldFee = (profit * yieldFeeBps) / BPS_DECIMALS;
        }

        totalFee = managementFee + yieldFee;
        return (totalFee, managementFee, yieldFee);
    }

    /**
     * @notice Calculates the coupon payment accumulated for a given number of daysPassed
     * @param underlyingAmount is the amount of assets
     * @param aprBps is the apr in bps
     * @param daysPassed is the number of days that coupon payments have been accured for
     */
    function calculateCouponPayment(
        uint256 underlyingAmount,
        uint256 aprBps,
        uint256 daysPassed
    ) private pure returns (uint256) {
        return (underlyingAmount * daysPassed * aprBps * LARGE_CONSTANT) / DAYS_IN_YEAR / BPS_DECIMALS / LARGE_CONSTANT;
    }

    /**
     * @notice Gets the oracle address for a given optionBarrier
     * @param optionBarrier is the option barrier
     * @param cegaStateAddress is the address of the Cega state contract
     */
    function getOracleAddress(
        OptionBarrier memory optionBarrier,
        address cegaStateAddress
    ) private view returns (address) {
        CegaState cegaState = CegaState(cegaStateAddress);
        address oracle = cegaState.oracleAddresses(optionBarrier.oracleName);
        require(oracle != address(0), "400:Unregistered");
        return oracle;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { FCNProduct } from "./FCNProduct.sol";

contract CegaState is AccessControl {
    // Create a new role identifier for the admin roles
    bytes32 public constant OPERATOR_ADMIN_ROLE = keccak256("OPERATOR_ADMIN_ROLE");
    bytes32 public constant TRADER_ADMIN_ROLE = keccak256("TRADER_ADMIN_ROLE");
    bytes32 public constant SERVICE_ADMIN_ROLE = keccak256("SERVICE_ADMIN_ROLE");

    mapping(address => bool) public marketMakerAllowList;
    mapping(string => address) public products;
    mapping(string => address) public oracleAddresses;

    string[] public oracleNames;
    string[] public productNames;
    address public feeRecipient;

    /**
     * @notice CegaState contructor that sets up the admin roles
     * @param _operatorAdmin is the address of the operator admin
     * @param _traderAdmin is the address of the trader admin
     * @param _serviceAdmin is the address of the service admin
     */
    constructor(address _operatorAdmin, address _traderAdmin, address _serviceAdmin) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ADMIN_ROLE, _operatorAdmin);
        _setupRole(TRADER_ADMIN_ROLE, _traderAdmin);
        _setupRole(SERVICE_ADMIN_ROLE, _serviceAdmin);
    }

    /**
     * @notice Asserts whether the sender has the DEFAULT_ADMIN_ROLE
     * @param sender is the address to be checked
     */
    function isDefaultAdmin(address sender) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, sender);
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     * @param sender is the address to be checked
     */
    function isTraderAdmin(address sender) public view returns (bool) {
        return hasRole(TRADER_ADMIN_ROLE, sender);
    }

    /**
     * @notice Asserts whether the sender has the OPERATOR_ADMIN_ROLE
     * @param sender is the address to be checked
     */
    function isOperatorAdmin(address sender) public view returns (bool) {
        return hasRole(OPERATOR_ADMIN_ROLE, sender);
    }

    /**
     * @notice Asserts whether the sender has the SERVICE_ADMIN_ROLE
     * @param sender is the address of callee
     */
    function isServiceAdmin(address sender) public view returns (bool) {
        return hasRole(SERVICE_ADMIN_ROLE, sender);
    }

    /**
     * @notice Returns all oracle names (ex: "BTC/USD,PYTH")
     */
    function getOracleNames() public view returns (string[] memory) {
        return oracleNames;
    }

    /**
     * @notice Operator admin has ability to add a new oracle
     * @param oracleName is the name of the new oracle (ex: "BTC/USD,PYTH")
     * @param oracleAddress is the address of the oracle
     */
    function addOracle(string memory oracleName, address oracleAddress) public onlyRole(OPERATOR_ADMIN_ROLE) {
        if (oracleAddresses[oracleName] == address(0)) {
            oracleNames.push(oracleName);
        }
        oracleAddresses[oracleName] = oracleAddress;
    }

    /**
     * @notice Operator admin has ability to remove oracle
     * @param oracleName is the name of the oracle to be removed
     */
    function removeOracle(string memory oracleName) public onlyRole(OPERATOR_ADMIN_ROLE) {
        bool found = false;
        uint256 index = 0;
        for (uint256 i = 0; i < oracleNames.length; i++) {
            if (keccak256(abi.encodePacked(oracleNames[i])) == keccak256(abi.encodePacked(oracleName))) {
                index = i;
                found = true;
                break;
            }
        }
        if (found) {
            // Swap last element with element at index, then pop to delete oracle
            oracleNames[index] = oracleNames[oracleNames.length - 1];
            oracleNames.pop();
            delete oracleAddresses[oracleName];
        }
    }

    /**
     * @notice Returns all product names
     */
    function getProductNames() public view returns (string[] memory) {
        return productNames;
    }

    /**
     * @notice Operator admin has the ability to create a new product
     * @param productName is the name of the new product
     * @param product is the address of the product
     */
    function addProduct(string memory productName, address product) public onlyRole(OPERATOR_ADMIN_ROLE) {
        if (products[productName] == address(0)) {
            productNames.push(productName);
        }
        products[productName] = product;
    }

    /**
     * @notice Operator admin has the ability to remove products
     * @param productName is the name of the product to be removed
     */
    function removeProduct(string memory productName) public onlyRole(OPERATOR_ADMIN_ROLE) {
        bool found = false;
        uint256 index = 0;
        for (uint256 i = 0; i < productNames.length; i++) {
            if (keccak256(abi.encodePacked(productNames[i])) == keccak256(abi.encodePacked(productName))) {
                index = i;
                found = true;
            }
        }
        if (found) {
            // Swap last element with element at index, then pop to delete product
            productNames[index] = productNames[productNames.length - 1];
            productNames.pop();
            delete products[productName];
        }
    }

    /**
     * @notice Operator admin can toggle whether trade with market maker
     * @param marketMaker is the address of the market maker
     * @param allow is whether funds can be sent to that market maker
     */
    function updateMarketMakerPermission(address marketMaker, bool allow) public onlyRole(OPERATOR_ADMIN_ROLE) {
        marketMakerAllowList[marketMaker] = allow;
    }

    /**
     * @notice Only default admin can set the fee recipient
     * @param _feeRecipient is the address of the fee recipient
     */
    function setFeeRecipient(address _feeRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Moves assets to corresponding product and vault account
     * @param productName is the name of the product
     * @param vaultAddress is the address of the vault
     */
    function moveAssetsToProduct(
        string memory productName,
        address vaultAddress,
        uint256 amount
    ) public onlyRole(TRADER_ADMIN_ROLE) {
        address productAddress = products[productName];
        require(productAddress != address(0), "400:PN");

        FCNProduct fcnProduct = FCNProduct(productAddress);
        IERC20(fcnProduct.asset()).approve(productAddress, amount);
        fcnProduct.receiveAssetsFromCegaState(vaultAddress, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { CegaState } from "./CegaState.sol";
import { Deposit, FCNVaultMetadata, OptionBarrierType, OptionBarrier, VaultStatus, Withdrawal } from "./Structs.sol";
import { FCNVault } from "./FCNVault.sol";
import { Oracle } from "./Oracle.sol";
import { Calculations } from "./Calculations.sol";

error FCNProductError();

contract FCNProduct {
    using SafeERC20 for IERC20;
    using Calculations for FCNVaultMetadata;

    event VaultCreated(address vaultAddress, uint256 index);
    event VaultRemoved(address vaultAddress);
    event DepositQueued(address receiver, uint256 amount);
    event DepositQueueProcessed(address vaultAddress, uint256 totalUnderlyingAmount, uint256 processCount);
    event CollectFees(address vaultAddress, uint256 managementFee, uint256 yieldFee, uint256 totalFee);
    event WithdrawalQueued(address vaultAddress, address receiver, uint256 amountShares);
    event WithdrawalQueueProcessed(address vaultAddress, uint256 totalWithdrawnAmount, uint256 processCount);
    event RolloverVault(address vaultAddress, uint256 vaultStart);
    event FundsTransferred(address receiverAddress, uint256 totalUnderlyingAmount);

    CegaState public cegaState;

    address public immutable asset;
    string public name;
    uint256 public managementFeeBps; // basis points
    uint256 public yieldFeeBps; // basis points
    bool public isDepositQueueOpen;
    uint256 public maxDepositAmountLimit;
    uint256 public sumVaultUnderlyingAmounts;
    uint256 public queuedDepositsTotalAmount;
    uint256 public queuedDepositsCount;

    mapping(address => FCNVaultMetadata) public vaults;
    address[] public vaultAddresses;

    Deposit[] private depositQueue;
    mapping(address => Withdrawal[]) private withdrawalQueues;

    /**
     * @notice Creates a new FCNProduct
     * @param _cegaState is the address of the CegaState contract
     * @param _asset is the underlying asset this product accepts
     * @param _name is the name of the product
     * @param _managementFeeBps is the management fee in bps
     * @param _yieldFeeBps is the yield fee in bps
     * @param _maxDepositAmountLimit is the deposit limit for the product
     */
    constructor(
        address _cegaState,
        address _asset,
        string memory _name,
        uint256 _managementFeeBps,
        uint256 _yieldFeeBps,
        uint256 _maxDepositAmountLimit
    ) {
        cegaState = CegaState(_cegaState);
        asset = _asset;
        name = _name;
        managementFeeBps = _managementFeeBps;
        yieldFeeBps = _yieldFeeBps;
        maxDepositAmountLimit = _maxDepositAmountLimit;
        isDepositQueueOpen = false;
    }

    /**
     * @notice Asserts whether the sender has the DEFAULT_ADMIN_ROLE
     */
    modifier onlyDefaultAdmin() {
        require(cegaState.isDefaultAdmin(msg.sender), "403:DA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     */
    modifier onlyTraderAdmin() {
        require(cegaState.isTraderAdmin(msg.sender), "403:TA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the OPERATOR_ADMIN_ROLE
     */
    modifier onlyOperatorAdmin() {
        require(cegaState.isOperatorAdmin(msg.sender), "403:OA");
        _;
    }

    /**
     * @notice Asserts that the vault has been initialized & is a Cega Vault
     * @param vaultAddress is the address of the vault
     */
    modifier validVault(address vaultAddress) {
        require(isValidVault(vaultAddress), "400:VA");
        _;
    }

    /**
     * @notice Checks whether a vault exists in the vaults mapping
     * Vault start date will never be zero if it exists
     * @param vaultAddress is the address of the vault
     */
    function isValidVault(address vaultAddress) public view returns (bool) {
        if (vaults[vaultAddress].vaultStart != 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice Returns array of vault addresses associated with the product
     */
    function getVaultAddresses() public view returns (address[] memory) {
        return vaultAddresses;
    }

    /**
     * @notice Sets the management fee for the product
     * @param _managementFeeBps is the management fee in bps (100% = 10000)
     */
    function setManagementFeeBps(uint256 _managementFeeBps) public onlyOperatorAdmin {
        managementFeeBps = _managementFeeBps;
    }

    /**
     * @notice Sets the yieldfee for the product
     * @param _yieldFeeBps is the management fee in bps (100% = 10000)
     */
    function setYieldFeeBps(uint256 _yieldFeeBps) public onlyOperatorAdmin {
        yieldFeeBps = _yieldFeeBps;
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param _isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function setIsDepositQueueOpen(bool _isDepositQueueOpen) public onlyOperatorAdmin {
        isDepositQueueOpen = _isDepositQueueOpen;
    }

    /**
     * @notice Sets the maximum deposit limit for the product
     * @param _maxDepositAmountLimit is the deposit limit for the product
     */
    function setMaxDepositAmountLimit(uint256 _maxDepositAmountLimit) public onlyTraderAdmin {
        maxDepositAmountLimit = _maxDepositAmountLimit;
    }

    /**
     * @notice Creates a new vault for the product & maps the new vault address to the vaultMetadata
     * @param _tokenName is the name of the token for the vault
     * @param _tokenSymbol is the symbol for the vault's token
     * @param _vaultStart is the timestamp of the vault's start
     */
    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart
    ) public onlyTraderAdmin returns (address vaultAddress) {
        require(_vaultStart != 0, "400:VS");
        FCNVault vault = new FCNVault(asset, _tokenName, _tokenSymbol);
        address newVaultAddress = address(vault);
        vaultAddresses.push(newVaultAddress);

        // vaultMetadata & all of its fields are automatically initialized if it doesn't already exist in the mapping
        FCNVaultMetadata storage vaultMetadata = vaults[newVaultAddress];
        vaultMetadata.vaultStart = _vaultStart;
        vaultMetadata.vaultAddress = newVaultAddress;

        // Leverage is always set to 1
        vaultMetadata.leverage = 1;

        emit VaultCreated(newVaultAddress, vaultAddresses.length - 1);
        return newVaultAddress;
    }

    /**
     * @notice defaultAdmin has the ability to override & change the vaultMetadata
     * If a value is not input, it will override to the default value
     * @param vaultAddress is the address of the vault
     * @param metadata is the vault's metadata that we want to change to
     */
    function setVaultMetadata(
        address vaultAddress,
        FCNVaultMetadata calldata metadata
    ) public onlyDefaultAdmin validVault(vaultAddress) {
        require(metadata.vaultStart > 0, "400:VS");
        require(metadata.leverage == 1, "400:L");
        vaults[vaultAddress] = metadata;
    }

    /**
     * @notice defaultAdmin has the ability to remove a Vault
     * @param vaultAddress is the address of the vault
     */
    function removeVault(address vaultAddress) public onlyDefaultAdmin {
        uint256 j;
        bool isIn;

        for (j; j < vaultAddresses.length; j++) {
            if (vaultAddresses[j] == vaultAddress) {
                isIn = true;
                break;
            }
        }

        require(isIn, "400:VA");

        vaultAddresses[j] = vaultAddresses[vaultAddresses.length - 1];
        vaultAddresses.pop();
        delete vaults[vaultAddress];

        emit VaultRemoved(vaultAddress);
    }

    /**
     * @notice Trader admin sets the trade data after the auction
     * @param vaultAddress is the address of the vault
     * @param _tradeDate is the official timestamp of when the options contracts begins
     * @param _tradeExpiry is the timestamp of when the trade will expire
     * @param _aprBps is the APR in bps
     * @param _tenorInDays is the length of the options contract
     */
    function setTradeData(
        address vaultAddress,
        uint256 _tradeDate,
        uint256 _tradeExpiry,
        uint256 _aprBps,
        uint256 _tenorInDays
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        require(metadata.vaultStatus == VaultStatus.NotTraded, "500:WS");
        require(_tradeExpiry > 0, "400:TE");
        metadata.tradeDate = _tradeDate;
        metadata.tradeExpiry = _tradeExpiry;
        metadata.aprBps = _aprBps;
        metadata.tenorInDays = _tenorInDays;
    }

    /**
     * @notice Trader admin can add an option with barriers to a given vault
     * @param vaultAddress is the address of the vault
     * @param optionBarrier is the data for the option with barriers
     */
    function addOptionBarrier(
        address vaultAddress,
        OptionBarrier calldata optionBarrier
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        metadata.optionBarriers.push(optionBarrier);
        metadata.optionBarriersCount++;
    }

    /**
     * @notice Get all option barriers for a given vault
     * @param vaultAddress is the address of the vault
     */
    function getOptionBarriers(address vaultAddress) external view returns (OptionBarrier[] memory) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.optionBarriers;
    }

    /**
     * @notice Get a single option barrier for a given vault
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier
     */
    function getOptionBarrier(address vaultAddress, uint256 index) public view returns (OptionBarrier memory) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        require(index < metadata.optionBarriersCount, "400:I");
        return metadata.optionBarriers[index];
    }

    /**
     * @notice Trader admin has ability to update price fixings & observation time.
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier we want to update
     * @param _asset is the ticker symbol of the asset we want to update
     * (included as a safety check since the asset name should match the option barrier at given index)
     * @param _strikeAbsoluteValue is the actual strike price of the asset
     * @param _barrierAbsoluteValue is the actual price that will cause the barrier to be triggered
     */
    function updateOptionBarrier(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        uint256 _strikeAbsoluteValue,
        uint256 _barrierAbsoluteValue
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(index < vaultMetadata.optionBarriersCount, "400:I");

        OptionBarrier storage optionBarrier = vaultMetadata.optionBarriers[index];
        require(keccak256(abi.encodePacked(optionBarrier.asset)) == keccak256(abi.encodePacked(_asset)), "400:AS");

        optionBarrier.strikeAbsoluteValue = _strikeAbsoluteValue;
        optionBarrier.barrierAbsoluteValue = _barrierAbsoluteValue;
    }

    /**
     * @notice Operator admin has ability to update the oracle for an option barrier.
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier we want to update
     * @param _asset is the ticker symbol of the asset we want to update
     * (included as a safety check since the asset name should match the option barrier at given index)
     * @param newOracleName is the name of the new oracle (must also register this name in CegaState)
     */
    function updateOptionBarrierOracle(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        string memory newOracleName
    ) public onlyOperatorAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(index < vaultMetadata.optionBarriersCount, "400:I");

        OptionBarrier storage optionBarrier = vaultMetadata.optionBarriers[index];
        require(keccak256(abi.encodePacked(optionBarrier.asset)) == keccak256(abi.encodePacked(_asset)), "400:AS");

        require(cegaState.oracleAddresses(newOracleName) != address(0), "400:OR");
        optionBarrier.oracleName = newOracleName;
    }

    /**
     * @notice Trader admin has ability to remove an option barrier.
     * The index for all option barriers to the right of the index are shifted by one to the left.
     * @param vaultAddress is the address of the vault
     * @param index is the index of the option barrier we want to remove
     * @param _asset is the ticker symbol of the asset we want to update
     * (included as a safety check since the asset should match the option barrier at given index)
     */
    function removeOptionBarrier(
        address vaultAddress,
        uint256 index,
        string calldata _asset
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(index < vaultMetadata.optionBarriersCount, "400:I");

        OptionBarrier[] storage optionBarriers = vaultMetadata.optionBarriers;
        require(
            keccak256(abi.encodePacked(optionBarriers[index].asset)) == keccak256(abi.encodePacked(_asset)),
            "400:AS"
        );

        // Shift all elements to the left.
        // Element at "index" becomes overwritten. Last element is now duplicated, so we can remove it.
        for (uint256 i = index; i < vaultMetadata.optionBarriersCount - 1; i++) {
            optionBarriers[i] = optionBarriers[i + 1];
        }
        optionBarriers.pop();
        vaultMetadata.optionBarriersCount -= 1;
    }

    /**
     * Operator admin has ability to override the vault's status
     * @param vaultAddress is the address of the vault
     * @param _vaultStatus is the new status for the vault
     */
    function setVaultStatus(
        address vaultAddress,
        VaultStatus _vaultStatus
    ) public onlyOperatorAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage metadata = vaults[vaultAddress];
        metadata.vaultStatus = _vaultStatus;
    }

    /**
     * Trader admin has ability to set the vault to "DepositsOpen" state
     * @param vaultAddress is the address of the vault
     */
    function openVaultDeposits(address vaultAddress) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.vaultStatus = VaultStatus.DepositsOpen;
    }

    /**
     * Trader admin has an override to set the knock in status for a vault
     * @param vaultAddress is the address of the vault
     * @param newState is the new state for isKnockedIn
     */
    function setKnockInStatus(address vaultAddress, bool newState) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.isKnockedIn = newState;
    }

    /**
     * Transfers assets from the user to the product
     * @param amount is the amount of assets being deposited
     * @param receiver is the address of the user depositing into the product
     */
    function addToDepositQueue(uint256 amount, address receiver) public {
        require(isDepositQueueOpen, "500:NotOpen");
        queuedDepositsCount += 1;
        queuedDepositsTotalAmount += amount;
        require(queuedDepositsTotalAmount + sumVaultUnderlyingAmounts <= maxDepositAmountLimit, "500:TooBig");

        IERC20(asset).safeTransferFrom(receiver, address(this), amount);
        depositQueue.push(Deposit({ amount: amount, receiver: receiver }));
        emit DepositQueued(receiver, amount);
    }

    /**
     * Processes the product's deposit queue into a specific vault
     * @param vaultAddress is the address of the vault
     * @param maxProcessCount is the number of elements in the deposit queue to be processed
     */
    function processDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.DepositsOpen, "500:WS");

        FCNVault vault = FCNVault(vaultAddress);
        require(!(vaultMetadata.underlyingAmount == 0 && vault.totalSupply() > 0), "500:Z");

        uint256 processCount = Math.min(queuedDepositsCount, maxProcessCount);
        uint256 i;
        Deposit storage deposit;
        for (i = 0; i < processCount; i++) {
            deposit = depositQueue[i];
            queuedDepositsTotalAmount -= deposit.amount;
            vault.deposit(deposit.amount, deposit.receiver);
            vaultMetadata.underlyingAmount += deposit.amount;
            sumVaultUnderlyingAmounts += deposit.amount;
            vaultMetadata.currentAssetAmount += deposit.amount;
        }

        if (processCount >= queuedDepositsCount) {
            delete depositQueue;
        } else {
            // If partially processed the deposit queue, shift all remaining elements to the beginning
            // because we can only pop from the end of the array
            for (i = processCount; i < queuedDepositsCount; i++) {
                deposit = depositQueue[i];
                depositQueue[i - processCount] = deposit;
            }

            for (i = 0; i < processCount; i++) {
                depositQueue.pop();
            }
        }
        queuedDepositsCount -= processCount;

        if (queuedDepositsCount == 0) {
            vaultMetadata.vaultStatus = VaultStatus.NotTraded;
        }

        emit DepositQueueProcessed(vaultAddress, vaultMetadata.underlyingAmount, processCount);
    }

    /**
     * @notice Queues a withdrawal for the token holder of a specific vault token
     * @param vaultAddress is the address of the vault
     * @param amountShares is the number of vault tokens to be redeemed
     * @param receiver is the destination user's address once funds are withdrawn
     */
    function addToWithdrawalQueue(
        address vaultAddress,
        uint256 amountShares,
        address receiver
    ) public validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];

        IERC20(vaultAddress).safeTransferFrom(receiver, address(this), amountShares);
        Withdrawal[] storage withdrawalQueue = withdrawalQueues[vaultAddress];
        withdrawalQueue.push(Withdrawal({ amountShares: amountShares, receiver: receiver }));
        vaultMetadata.queuedWithdrawalsCount += 1;
        vaultMetadata.queuedWithdrawalsSharesAmount += amountShares;

        emit WithdrawalQueued(vaultAddress, receiver, amountShares);
    }

    /**
     * @notice Permissionless method that reads price from oracle contracts and checks if barrier is triggered
     * @param vaultAddress is address of the vault
     */
    function checkBarriers(address vaultAddress) public validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.checkBarriers(address(cegaState));
    }

    /**
     * @notice Calculates the final payoff for a given vault
     * @param vaultAddress is address of the vault
     */
    function calculateVaultFinalPayoff(
        address vaultAddress
    ) public validVault(vaultAddress) returns (uint256 vaultFinalPayoff) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.calculateVaultFinalPayoff(address(cegaState));
    }

    /**
     * @notice Calculates the percentage of principal to return to users if a knock in occurs.
     * Iterates through all knock-in barriers and checks the ratio of (spot/strike) for each asset
     * Returns the minimum of the knock-in ratios.
     * @param vaultAddress is address of the vault
     */
    function calculateKnockInRatio(
        address vaultAddress
    ) public view validVault(vaultAddress) returns (uint256 knockInRatio) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.calculateKnockInRatio(address(cegaState));
    }

    /**
     * @notice receive assets and allocate the underlying asset to the specified vault's balance
     * @param vaultAddress is the address of the vault
     * @param amount is the amount to transfer
     */
    function receiveAssetsFromCegaState(address vaultAddress, uint256 amount) public validVault(vaultAddress) {
        require(msg.sender == address(cegaState), "403:CS");
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        // // a valid vaultAddress will never have vaultStart = 0
        // require(vaultMetadata.vaultStart != 0, "400:VA");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        vaultMetadata.currentAssetAmount += amount;
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * @param vaultAddress is the address of the vault
     */
    function calculateFees(
        address vaultAddress
    ) public view validVault(vaultAddress) returns (uint256 totalFee, uint256 managementFee, uint256 yieldFee) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        return vaultMetadata.calculateFees(managementFeeBps, yieldFeeBps);
    }

    /**
     * @notice Transfers the correct amount of fees to the fee recipient
     * @param vaultAddress is the address of the vault
     */
    function collectFees(address vaultAddress) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.PayoffCalculated, "500:WS");

        (uint256 totalFees, uint256 managementFee, uint256 yieldFee) = calculateFees(vaultAddress);
        totalFees = Math.min(totalFees, vaultMetadata.vaultFinalPayoff);
        IERC20(asset).safeTransfer(cegaState.feeRecipient(), totalFees);
        vaultMetadata.currentAssetAmount -= totalFees;

        vaultMetadata.vaultStatus = VaultStatus.FeesCollected;
        sumVaultUnderlyingAmounts -= vaultMetadata.underlyingAmount;
        vaultMetadata.underlyingAmount = vaultMetadata.vaultFinalPayoff - totalFees;
        sumVaultUnderlyingAmounts += vaultMetadata.underlyingAmount;

        emit CollectFees(vaultAddress, managementFee, yieldFee, totalFees);
    }

    /**
     * @notice Processes all the queued withdrawals in the withdrawal queue
     * @param vaultAddress is the address of the vault
     * @param maxProcessCount is the maximum number of withdrawals to process in the queue
     */
    function processWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        // Needs zombie state so that we can restore the vault
        require(
            vaultMetadata.vaultStatus == VaultStatus.FeesCollected || vaultMetadata.vaultStatus == VaultStatus.Zombie,
            "500:WS"
        );
        Withdrawal[] storage withdrawalQueue = withdrawalQueues[vaultAddress];

        FCNVault vault = FCNVault(vaultAddress);

        uint256 processCount = Math.min(vaultMetadata.queuedWithdrawalsCount, maxProcessCount);
        uint256 amountAssets;
        uint256 i;
        Withdrawal memory withdrawal;
        for (i = 0; i < processCount; i++) {
            withdrawal = withdrawalQueue[i];
            amountAssets = vault.redeem(withdrawal.amountShares, withdrawal.receiver);
            vaultMetadata.underlyingAmount -= amountAssets;
            sumVaultUnderlyingAmounts -= amountAssets;
            vaultMetadata.queuedWithdrawalsSharesAmount -= withdrawal.amountShares;
            IERC20(asset).safeTransfer(withdrawal.receiver, amountAssets);
            vaultMetadata.currentAssetAmount -= amountAssets;
        }

        for (i = processCount; i < vaultMetadata.queuedWithdrawalsCount; i++) {
            withdrawal = withdrawalQueue[i];
            withdrawalQueue[i - processCount] = withdrawal;
        }

        for (i = 0; i < processCount; i++) {
            withdrawalQueue.pop();
        }
        vaultMetadata.queuedWithdrawalsCount -= processCount;

        if (vaultMetadata.queuedWithdrawalsCount == 0) {
            if (vaultMetadata.underlyingAmount == 0 && vault.totalSupply() > 0) {
                vaultMetadata.vaultStatus = VaultStatus.Zombie;
            } else {
                vaultMetadata.vaultStatus = VaultStatus.WithdrawalQueueProcessed;
            }
        }

        emit WithdrawalQueueProcessed(vaultAddress, vaultMetadata.underlyingAmount, processCount);
    }

    /**
     * @notice Resets the vault to the default state after the trade is settled
     * @param vaultAddress is the address of the vault
     */
    function rolloverVault(address vaultAddress) public onlyTraderAdmin validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(vaultMetadata.vaultStatus == VaultStatus.WithdrawalQueueProcessed, "500:WS");
        require(vaultMetadata.tradeExpiry != 0, "400:TE");
        vaultMetadata.vaultStart = vaultMetadata.tradeExpiry;
        vaultMetadata.tradeDate = 0;
        vaultMetadata.tradeExpiry = 0;
        vaultMetadata.aprBps = 0;
        vaultMetadata.vaultStatus = VaultStatus.DepositsClosed;
        vaultMetadata.totalCouponPayoff = 0;
        vaultMetadata.vaultFinalPayoff = 0;
        vaultMetadata.isKnockedIn = false;
        emit RolloverVault(vaultAddress, vaultMetadata.vaultStart);
    }

    /**
     * @notice Trader sends assets from the product to a third party wallet address
     * @param vaultAddress is the address of the vault
     * @param receiver is the receiver of the assets
     * @param amount is the amount of the assets to be sent
     */
    function sendAssetsToTrade(
        address vaultAddress,
        address receiver,
        uint256 amount
    ) public onlyTraderAdmin validVault(vaultAddress) {
        require(cegaState.marketMakerAllowList(receiver), "400:NotAllowed");
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        require(amount <= vaultMetadata.currentAssetAmount, "400:TooBig");
        IERC20(asset).safeTransfer(receiver, amount);
        vaultMetadata.currentAssetAmount = vaultMetadata.currentAssetAmount - amount;
        vaultMetadata.vaultStatus = VaultStatus.Traded;
        emit FundsTransferred(receiver, amount);
    }

    /**
     * @notice Calculates the current yield accumulated to the current day for a given vault
     * @param vaultAddress is the address of the vault
     */
    function calculateCurrentYield(address vaultAddress) public validVault(vaultAddress) {
        FCNVaultMetadata storage vaultMetadata = vaults[vaultAddress];
        vaultMetadata.calculateCurrentYield();
    }

    function throwError() external pure {
        revert FCNProductError();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { FCNProduct } from "./FCNProduct.sol";
import { FCNVaultMetadata, VaultStatus } from "./Structs.sol";

contract FCNVault is IERC4626, ERC20, Ownable {
    using SafeERC20 for ERC20;

    address public asset;
    FCNProduct public fcnProduct;

    /**
     * @notice Creates a new FCNVault that is owned by the FCNProduct
     * @param _asset is the address of the underlying asset
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the name of the token symbol
     */
    constructor(address _asset, string memory _tokenName, string memory _tokenSymbol) ERC20(_tokenName, _tokenSymbol) {
        asset = _asset;
        fcnProduct = FCNProduct(owner());
    }

    /**
     * @notice Returns underlying amount associated for the vault
     */
    function totalAssets() public view returns (uint256) {
        (, , , , , uint256 underlyingAmount, , , , , , , , , , ) = fcnProduct.vaults(address(this));
        return underlyingAmount;
    }

    /**
     * @notice Converts units of shares to assets
     * @param shares is the number of vault tokens
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return 0;
        return (shares * totalAssets()) / _totalSupply;
    }

    /**
     * @notice Converts units assets to shares
     * @param assets is the amount of underlying assets
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _totalAssets = totalAssets();
        if (_totalAssets == 0 || _totalSupply == 0) return assets;
        return (assets * _totalSupply) / _totalAssets;
    }

    /**
     * @notice Maximum sum of deposits that a vault can accept
     */
    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Preview the amount of shares for a given deposit
     * @param assets is the amount of underlying assets
     */
    function previewDeposit(uint256 assets) external view returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * Product can deposit into the vault
     * @param assets is the number of underlying assets to be deposited
     * @param receiver is the address of the original depositor
     */
    function deposit(uint256 assets, address receiver) public onlyOwner returns (uint256) {
        uint256 shares = convertToShares(assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    /**
     * @notice Product can deposit into the vault
     * @param assets is the number of underlying assets to be deposited
     */
    function deposit(uint256 assets) external onlyOwner returns (uint256) {
        return deposit(assets, msg.sender);
    }

    /**
     * @notice Maximum amount of shares (vault tokens) that can be minted
     */
    function maxMint(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Preview the amount of assets to return for an amount of shares
     * @param shares is the number of vault tokens
     */
    function previewMint(uint256 shares) external view returns (uint256) {
        uint256 assets = convertToAssets(shares);
        if (assets == 0 && totalAssets() == 0) return shares;
        return assets;
    }

    /**
     * @notice Mint a given amount of shares & deduct the correct amount of assets to do so
     * @param shares is the number of shares (vault tokens)
     * @param receiver is the address of the receiver
     */
    function mint(uint256 shares, address receiver) public onlyOwner returns (uint256) {
        uint256 assets = convertToAssets(shares);

        if (totalAssets() == 0) assets = shares;

        ERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    /**
     * Mint a given amount of shares (vault tokens)
     * @param shares is the number of shares
     */
    function mint(uint256 shares) external onlyOwner returns (uint256) {
        return mint(shares, msg.sender);
    }

    /**
     * @notice Maximum amount that can be withdrawn
     */
    function maxWithdraw(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * Preview the amount of shares that would be withdrawn to return assets
     * @param assets is the number of assets
     */
    function previewWithdraw(uint256 assets) external view returns (uint256) {
        uint256 shares = convertToShares(assets);
        if (totalSupply() == 0) return 0;
        return shares;
    }

    /**
     * Withdraw for a given amount of assets and burn shares
     * @param assets is the amount of assets
     * @param receiver is the receiver of the assets
     * @param owner is the owner of the shares to be withdrawn
     */
    function withdraw(uint256 assets, address receiver, address owner) public onlyOwner returns (uint256) {
        uint256 shares = convertToShares(assets);

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    /**
     * Withdraw a given amount of assets and burn shares
     * @param assets is the amount of assets to withdraw
     * @param receiver is the address of the receiver of the assets
     */
    function withdraw(uint256 assets, address receiver) external onlyOwner returns (uint256) {
        return withdraw(assets, receiver, msg.sender);
    }

    /**
     * Withdraw a given amount of assets and burn shares
     * the owner of the shares and receiver of assets is the same address
     * @param assets is the number of underlying assets to be withdrawn
     */
    function withdraw(uint256 assets) external onlyOwner returns (uint256) {
        return withdraw(assets, msg.sender, msg.sender);
    }

    /**
     * Maximum amount that can be redeemed
     */
    function maxRedeem(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * Preview amount of assets that can be redeemed
     * @param shares is the amount of shares to be redeemed
     */
    function previewRedeem(uint256 shares) external view returns (uint256) {
        return convertToAssets(shares);
    }

    /**
     * Redeem a given amount of shares in return for assets
     * @param shares is the amount of shares (vault tokens) to be redeemed
     * @param receiver is the address to receive assets
     * @param owner is the owner of the shares
     */
    function redeem(uint256 shares, address receiver, address owner) public onlyOwner returns (uint256) {
        uint256 assets = convertToAssets(shares);

        if (owner != msg.sender) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    /**
     * Redeem a given amount of shares in return for assets
     * Shares are burned from the caller
     * @param shares is the amount of shares (vault tokens) to be redeemed
     * @param receiver is the address to receive assets
     */
    function redeem(uint256 shares, address receiver) external onlyOwner returns (uint256) {
        return redeem(shares, receiver, msg.sender);
    }

    /**
     * Redeem a given amount of shares in return for assets
     * Shares are burned from the caller & assets sent to the caller
     * @param shares is the amount of shares (vault tokens) to be redeemed
     */
    function redeem(uint256 shares) external onlyOwner returns (uint256) {
        return redeem(shares, msg.sender, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { AggregatorV3Interface } from "./AggregatorV3Interface.sol";
import { RoundData } from "./Structs.sol";
import { CegaState } from "./CegaState.sol";

contract Oracle is AggregatorV3Interface {
    uint8 public decimals;
    string public description;
    uint256 public version = 1;
    CegaState public cegaState;
    RoundData[] public oracleData;
    uint80 public nextRoundId;

    /**
     * @notice Creates a new oracle for a given asset / data source pair
     * @param _cegaState is the address of the CegaState contract
     * @param _decimals is the number of decimals for the asset
     * @param _description is the aset
     */
    constructor(address _cegaState, uint8 _decimals, string memory _description) {
        cegaState = CegaState(_cegaState);
        decimals = _decimals;
        description = _description;
    }

    /**
     * @notice Asserts whether the sender has the SERVICE_ADMIN_ROLE
     */
    modifier onlyServiceAdmin() {
        require(cegaState.isServiceAdmin(msg.sender), "403:SA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     */
    modifier onlyTraderAdmin() {
        require(cegaState.isTraderAdmin(msg.sender), "403:TA");
        _;
    }

    /**
     * @notice Adds the pricing data for the next round
     * @param _roundData is the data to be added
     */
    function addNextRoundData(RoundData calldata _roundData) public onlyServiceAdmin {
        oracleData.push(_roundData);
        nextRoundId++;
    }

    /**
     * @notice Updates the pricing data for a given round
     * @param _roundData is the data to be updated
     */
    function updateRoundData(uint80 roundId, RoundData calldata _roundData) public onlyTraderAdmin {
        oracleData[roundId] = _roundData;
    }

    /**
     * @notice Gets the pricing data for a given round Id
     * @param _roundId is the id of the round
     */
    function getRoundData(
        uint80 _roundId
    )
        public
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            _roundId,
            oracleData[_roundId].answer,
            oracleData[_roundId].startedAt,
            oracleData[_roundId].updatedAt,
            oracleData[_roundId].answeredInRound
        );
    }

    /**
     * @notice Gets the pricing data for the latest round
     */
    function latestRoundData()
        public
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint80 _roundId = nextRoundId - 1;
        return (
            _roundId,
            oracleData[_roundId].answer,
            oracleData[_roundId].startedAt,
            oracleData[_roundId].updatedAt,
            oracleData[_roundId].answeredInRound
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum OptionBarrierType {
    None,
    KnockIn
}

struct Deposit {
    uint256 amount;
    address receiver;
}

struct Withdrawal {
    uint256 amountShares;
    address receiver;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    PayoffCalculated,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct OptionBarrier {
    uint256 barrierBps;
    uint256 barrierAbsoluteValue;
    uint256 strikeBps;
    uint256 strikeAbsoluteValue;
    string asset;
    string oracleName;
    OptionBarrierType barrierType;
}

struct FCNVaultMetadata {
    uint256 vaultStart;
    uint256 tradeDate;
    uint256 tradeExpiry;
    uint256 aprBps;
    uint256 tenorInDays;
    uint256 underlyingAmount; // This is how many assets were ever deposited into the vault
    uint256 currentAssetAmount; // This is how many assets are currently allocated for the vault (not sent for trade)
    uint256 totalCouponPayoff;
    uint256 vaultFinalPayoff;
    uint256 queuedWithdrawalsSharesAmount;
    uint256 queuedWithdrawalsCount;
    uint256 optionBarriersCount;
    uint256 leverage;
    address vaultAddress;
    VaultStatus vaultStatus;
    bool isKnockedIn;
    OptionBarrier[] optionBarriers;
}

struct RoundData {
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}