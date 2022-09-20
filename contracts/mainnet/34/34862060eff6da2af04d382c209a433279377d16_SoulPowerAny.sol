/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
// Enchanted by: @0xBuns

// File: @openzeppelin/contracts/access/IAccessControl.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/access/AccessControl.sol

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/tokens/SoulPowerAny.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract SoulPowerAny is IERC20, AccessControl {
    using SafeERC20 for IERC20;
    string public name;
    string public symbol;
    uint8 public immutable override decimals;

    // used for crosschain pureposes
    address public underlying;
    bool public constant underlyingIsMinted = false;
    bool public isUnderlyingImmutable;

    /// @dev records amount of SOUL owned by account.
    mapping(address => uint) public override balanceOf;
    uint private _totalSupply;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool private _init;

    // primary controller of the token contract (trivial)
    address public vault;

    // toggles swapout vs vault.burn so multiple events are triggered
    bool private _vaultOnly;

    // checks for revocation of init.
    bool private _initRevoked;

    // restricts ability to deposit and withdraq
    bool private _depositEnabled;
    bool private _withdrawEnabled;

    // mapping used to verify minters & vaults
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isVault;

    // arrays composed of minter & vaults
    address[] public minters;
    address[] public vaults;

    // supreme & roles
    address public supreme; // supreme divine
    bytes32 public anunnaki; // admin role
    bytes32 public thoth; // minter role
    bytes32 public sophia; // burner role

    // events
    event NewSupreme(address supreme);
    event Rethroned(bytes32 role, address oldAccount, address newAccount);
    event LogSwapin(
        bytes32 indexed txhash,
        address indexed account,
        uint amount
    );
    event LogSwapout(
        address indexed account,
        address indexed bindaddr,
        uint amount
    );

    // modifiers
    modifier onlySupreme() {
        require(msg.sender == supreme, 'sender must be supreme');
        _;
    }

    // restricted to the house of the role passed as an object to obey
    modifier obey(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function owner() external view returns (address) {
        return supreme;
    }

    function mpc() external view returns (address) {
        return supreme;
    }

    // toggles permissions for _vaultOnly
    function setVaultOnly(bool enabled) external onlySupreme {
        _vaultOnly = enabled;
    }

    // initializes (when not revoked) [ onlySupreme ]
    function initVault(address _vault) external onlySupreme {
        require(!_initRevoked, 'initialization revoked');
        vault = _vault;
        isMinter[_vault] = true;
    }

    // toggles ability to init [ onlySupreme ]
    function toggleInit(bool enabled) external onlySupreme {
        require(!_initRevoked, 'initialization revoked');
        _init = enabled;
    }

    // revokes ability to re-initialize [ onlySupreme ]
    function revokeInit() external onlySupreme {
        require(!_initRevoked, 'initialization already revoked');
        _initRevoked = true;
    }

    // checks whether sender has divine `role` (public view)
    function hasDivineRole(bytes32 role) public view returns (bool) {
        return hasRole(role, msg.sender);
    }

    // sets minter address [ onlySupreme ]
    function setMinter(address _minter) external onlySupreme {
        _setMinter(_minter);
    }

    // adds the minter to the array of minters[]
    function _setMinter(address _minter) internal {
        require(_minter != address(0), "SoulPower: cannot set minter to address(0)");
        minters.push(_minter);
    }

    // sets vault address
    function setVault(address _vault) external onlySupreme {
        _setVault(_vault);
    }

    function _setVault(address _vault) internal {
        require(_vault != address(0), "SoulPower: cannot set vault to address(0)");
        vaults.push(_vault);
    }

    // no time delay revoke minter (emergency function)
    function revokeMinter(address _minter) external onlySupreme {
        isMinter[_minter] = false;
    }

    // no time delay revoke vault (emergency function)
    function revokeVault(address _vault) external onlySupreme {
        isVault[_vault] = false;
    }

    // restrict: underlying to `_immutableUnderlying`
    function setImmutableUnderlying(address _immutableUnderlying) external onlySupreme {
        require(!isUnderlyingImmutable, 'underlying is already immutable');
        
        // sets: underlying address (permanent)
        underlying = _immutableUnderlying;
        
        // sets: underlying to immutable
        isUnderlyingImmutable = true;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function getAllVaults() external view returns (address[] memory) {
        return vaults;
    }

    // mint: restricted to the role of Thoth.
    function mint(address to, uint amount) external obey(thoth) returns (bool) {
        _mint(to, amount);
        return true;
    }

    // burn: restricted to the role of Sophia.
    function burn(address from, uint amount) external obey(sophia) returns (bool) {
        _burn(from, amount);
        return true;
    }

    // thoth authorizes mint // transfer for `amount` of swapped in value to `account`
    function Swapin(bytes32 txhash, address account, uint amount) external obey(thoth) returns (bool) {
        if ( // [A] if the contract has enough (non-native) underlying (ERC20) to cover `amount`,
            underlying != address(0) &&
            IERC20(underlying).balanceOf(address(this)) >= amount
        ) { // then transfer requested `amount` of underlying (ERC20) to `account`.
            IERC20(underlying).safeTransfer(account, amount);
        } else { // [B] mint requested `amount` of SOUL to `account`.
            _mint(account, amount);
        }
        // logs Swapin event
        emit LogSwapin(txhash, account, amount);

        return true;
    }

    // authorizes user to swap out and burns swapped out tokens
    function Swapout(uint amount, address bindaddr) external returns (bool) {
        // checks for swapout restriction
        require(!_vaultOnly, "only the vault may swapout");
        require(bindaddr != address(0), "bindaddr cannot be address(0)");
    
        // if the underlying is non-native and the balance of the sender < `amount`
        if (underlying != address(0) && balanceOf[msg.sender] < amount) {
            // then transfer `amount` of underlying from the `msg.sender` to this contract.
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            _burn(msg.sender, amount);
        }
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    /// @dev records # of SOUL that `account` (2nd) will be allowed to spend on behalf of another `account` (1st) via { transferFrom }.
    mapping(address => mapping(address => uint)) public override allowance;

    constructor() {
        name = 'SoulPower';
        symbol = 'SOUL';
        decimals = 18;
        underlying = address(0);

        supreme = msg.sender; // head supreme
        anunnaki = keccak256("anunnaki"); // alpha supreme
        thoth = keccak256("thoth"); // god of wisdom and magic
        sophia = keccak256("sophia"); // goddess of wisdom and magic

        // use init to allow for CREATE2 accross all chains
        _init = true;

        // toggles: swapout vs mint/burn
        _vaultOnly = false;
        _setVault(msg.sender);

        _divinationRitual(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE, supreme); // supreme as root admin
        _divinationRitual(anunnaki, anunnaki, supreme); // anunnaki as admin of anunnaki
        _divinationRitual(thoth, anunnaki, supreme); // anunnaki as admin of thoth
        _divinationRitual(sophia, anunnaki, supreme); // anunnaki as admin of sophia

        _mint(supreme, 21_000 * 1e18); // mints initial supply of 21_000 SOUL
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function newUnderlying(address _underlying) public obey(anunnaki) {
        require(!isUnderlyingImmutable, 'underlying is now immutable');
        underlying = _underlying;
    }

    // deposits: sender balance [receiver: sender]
    function deposit() external returns (uint) {
        uint _amount = IERC20(underlying).balanceOf(msg.sender);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        return _deposit(_amount, msg.sender);
    }

    // deposits: `amount` from sender [receiver: sender]
    function deposit(uint amount) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        // deposits `amount`, then credits msg.sender as receiver.
        return _deposit(amount, msg.sender);
    }

    // deposits: `amount` from sender [receiver: `to`]
    function deposit(uint amount, address to) external returns (uint) {
        // sender transfers `amount` of underlying to this contract.
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        // deposits `amount`, then credits `to` as receiver of SOUL.
        return _deposit(amount, to);
    }

    // supreme-restricted withdrawal to enable toAddress-specification
    function depositVault(uint amount, address to) external onlySupreme returns (uint) {
        return _deposit(amount, to);
    }

    // mint `to` the requested `amount` of SOUL.
    function _deposit(uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(_depositEnabled, 'deposits are disabled');

        require(underlying != address(0), 'cannot deposit native');
        require(underlying != address(this), 'cannot deposit SOUL');

        // mints `to` the requested `amount` of SOUL.
        _mint(to, amount);
        return amount;
    }

    // withdraws: balance from sender [receiver: sender]
    function withdraw() external returns (uint) {
        return _withdraw(msg.sender, balanceOf[msg.sender], msg.sender);
    }

    // withdraws: `amount` from sender [receiver: sender]
    function withdraw(uint amount) external returns (uint) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    // withdraws: `amount` from sender [receiver: `to`]
    function withdraw(uint amount, address to) external returns (uint) {
        return _withdraw(msg.sender, amount, to);
    }

    // supreme-restricted withdrawal to enable fromAddress-specification [receiver: `to`]
    function withdrawVault(address from, uint amount, address to) external onlySupreme returns (uint) {
        return _withdraw(from, amount, to);
    }

    // burns `amount` of SOUL `from` user, then transfers `to` the `amount` of underlying.
    function _withdraw(address from, uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(_withdrawEnabled, 'withdrawals are disabled');

        // cannot withdraw when underlying is native.
        require(underlying != address(0), 'underlying cannot be native');
        // cannot withdraw when underlying is SOUL.
        require(underlying != address(this), 'underlying cannot be SOUL');

        // burns: SOUL belonging to `from` in the specified `amount`.
        _burn(from, amount);

        // transfers: `to` the underlying (ERC20) in the specified `amount`.
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
    }

    // enables deposits and withdrawals
    function enableDeposits(bool enabled) external onlySupreme {
        _depositEnabled = enabled;
    }

    function enableWithdrawals(bool enabled) external onlySupreme {
        _withdrawEnabled = enabled;
    }

    // mints `amount` of SOUL to `account`
    function _mint(address account, uint amount) internal {
        require(account != address(0), "cannot mint to the zero address");

        // increases: totalSupply by `amount`
        _totalSupply += amount;

        // increases: user balance by `amount`
        balanceOf[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "cannot burn from the zero address");

        // checks: `account` balance to ensure coverage for burn `amount` [C].
        uint balance = balanceOf[account];
        require(balance >= amount, "burn amount exceeds balance");

        // reduces: `account` by `amount` [E1].
        balanceOf[account] = balance - amount;

        // reduces: totalSupply by `amount` [E2].
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function approve(address spender, uint value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        require(to != address(0) && to != address(this));
        uint balance = balanceOf[msg.sender];
        require(balance >= value, "SoulPower: transfer amount exceeds balance");

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        require(to != address(0) && to != address(this));
        if (from != msg.sender) {
            uint allowed = allowance[from][msg.sender];
            if (allowed != type(uint).max) {
                require(
                    allowed >= value,
                    "SoulPower: request exceeds allowance"
                );
                uint reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }

        uint balance = balanceOf[from];
        require(balance >= value, "SoulPower: transfer amount exceeds balance");

        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);

        return true;
    }

    // grants `role` to `newAccount` && renounces `role` from `oldAccount` [ obey(role) ]
    function rethroneRitual(bytes32 role, address oldAccount, address newAccount) public obey(role) {
        require(oldAccount != newAccount, "must be a new address");
        grantRole(role, newAccount); // grants new account
        renounceRole(role, oldAccount); //  removes old account of role

        emit Rethroned(role, oldAccount, newAccount);
    }

    // solidifies roles (internal)
    function _divinationRitual(bytes32 _role, bytes32 _adminRole, address _account) internal {
        _setupRole(_role, _account);
        _setRoleAdmin(_role, _adminRole);
    }

    // updates supreme address (public anunnaki)
    function newSupreme(address _supreme) public obey(anunnaki) {
        require(supreme != _supreme, "make a change, be the change"); //  prevents self-destruct
        rethroneRitual(DEFAULT_ADMIN_ROLE, supreme, _supreme); //   empowers new supreme
        supreme = _supreme;

        emit NewSupreme(supreme);
    }

    // acquires chainID
    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}