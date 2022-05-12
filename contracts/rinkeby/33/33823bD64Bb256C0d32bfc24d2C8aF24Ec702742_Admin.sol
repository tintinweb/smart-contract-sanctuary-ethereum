// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Admin is AccessControl, Initializable{
    address public BUSDProtocol;
    address public POL;
    address public Treasury;
    address public BShareBUSDVault;
    address public bYSLVault;
    address public USDyBUSDVault;
    address public USDyVault;
    address public xYSLBUSDVault;
    address public xYSLVault;
    address public YSLBUSDVault;
    address public YSLVault;
    address public BShare;
    address public bYSL;
    address public USDs;
    address public USDy;
    address public xYSL;
    address public YSL;
    address public YSLS;
    address public xYSLS;
    address public swapPage;
    address public PhoenixNFT;
    address public Opt1155;
    address public EarlyAccess;
    address public LPSwap;
    address public optVaultFactory;
    address public ReceiptSwap;
    address public swap;
    address public temporaryHolding;
    address public tokenSwap;
    address public vaultSwap;
    address public whitelist;
    address public BUSD;
    address public WBNB;
    address public BShareVault;
    address public masterNTT;
    address public biswapRouter;
    address public ApeswapRouter;
    address public pancakeRouter;
    address public TeamAddress;
    address public MasterChef;
    address public Refferal;
    address public liquidityProvider;
    address public Blacklist;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR"); //byte for minter role
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE"); //role byte for setter functions


    function initialize(address owner, address operator) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, owner); 
        _setupRole(OPERATOR_ROLE, operator);  
    }

    function setRefferal(address _refferal) external onlyRole(DEFAULT_ADMIN_ROLE){
        Refferal = _refferal;
    }
    /**
        @dev this function used to set WBNB address
        @param _WBNB address
     */
    function setWBNB(address _WBNB) external onlyRole(DEFAULT_ADMIN_ROLE){
        WBNB = _WBNB;
    }
    /**
        @dev this function used to set BShareVault address
        @param _BShareVault address
     */
    function setBShareVault(address _BShareVault) external onlyRole(DEFAULT_ADMIN_ROLE){
       BShareVault= _BShareVault;
    }
    /**
        @dev this function used to set BUSD address
        @param _BUSD address
     */
    function setBUSD(address _BUSD) external onlyRole(DEFAULT_ADMIN_ROLE){
        BUSD = _BUSD;
    }
    /**
        @dev this function used to set Whitelist address
        @param _whitelist address
     */
    function setWhitelist(address _whitelist) external onlyRole(DEFAULT_ADMIN_ROLE){
        whitelist = _whitelist;
    }
    /**
        @dev this function used to set VaultSwap address
        @param _vaultSwap address
     */
    function setVaultSwap(address _vaultSwap) external onlyRole(DEFAULT_ADMIN_ROLE){
        vaultSwap = _vaultSwap;
    }
    /**
        @dev this function used to set TokenSwap address
        @param _tokenSwap address
     */
    function setTokenSwap(address _tokenSwap) external onlyRole(DEFAULT_ADMIN_ROLE){
        tokenSwap = _tokenSwap;
    }
    /**
        @dev this function used to set TemporaryHolding address
        @param _temporaryHolding address
     */
    function setTemporaryHolding(address _temporaryHolding) external onlyRole(DEFAULT_ADMIN_ROLE){
        temporaryHolding = _temporaryHolding;
    }
    /**
        @dev this function used to set Swap address
        @param _swap address
     */
    function setSwap(address _swap) external onlyRole(DEFAULT_ADMIN_ROLE){
        swap = _swap;
    }
    /**
        @dev this function used to set ReceiptSwap address
        @param _ReceiptSwap address
     */
    function setReceiptSwap(address _ReceiptSwap) external onlyRole(DEFAULT_ADMIN_ROLE){
        ReceiptSwap = _ReceiptSwap;
    }
    /**
        @dev this function used to set OptVaultFactory address
        @param _optVaultFactory address
     */
    function setOptVaultFactory(address _optVaultFactory) external onlyRole(DEFAULT_ADMIN_ROLE){
        optVaultFactory = _optVaultFactory;
    }
    /**
        @dev this function used to set LPSwap address
        @param _LPSwap address
     */
    function setLPSwap(address _LPSwap) external onlyRole(DEFAULT_ADMIN_ROLE){
        LPSwap = _LPSwap;
    }
    /**
        @dev this function used to set EarlyAccess address
        @param _EarlyAccess address
     */
    function setEarlyAccess(address _EarlyAccess) external onlyRole(DEFAULT_ADMIN_ROLE){
        EarlyAccess = _EarlyAccess;
    }
    /**
        @dev this function used to set Opt1155 address
        @param _Opt1155 address
     */
    function setOpt1155(address _Opt1155) external onlyRole(DEFAULT_ADMIN_ROLE){
        Opt1155 = _Opt1155;
    }
    /**
        @dev this function used to set PhoenixNFT address
        @param _PhoenixNFT address
     */
    function setPhoenixNFT(address _PhoenixNFT) external onlyRole(DEFAULT_ADMIN_ROLE){
        PhoenixNFT = _PhoenixNFT;
    }
    /**
        @dev this function used to set SwapPage address
        @param _swapPage address
     */
    function setSwapPage(address _swapPage) external onlyRole(DEFAULT_ADMIN_ROLE){
        swapPage = _swapPage;
    }
    /**
        @dev this function used to set YSLS address
        @param _YSLS address
     */
    function setYSLS(address _YSLS) external onlyRole(DEFAULT_ADMIN_ROLE){
        YSLS = _YSLS;
    }
    /**
        @dev this function used to set YSL address
        @param _YSL address
     */
    function setYSL(address _YSL) external onlyRole(DEFAULT_ADMIN_ROLE){
        YSL = _YSL;
    }
    /**
        @dev this function used to set xYSLs address
        @param _xYSLS address
     */
    function setxYSLs(address _xYSLS) external onlyRole(DEFAULT_ADMIN_ROLE){
        xYSLS = _xYSLS;
    }
    /**
        @dev this function used to set xYSL address
        @param _xYSL address
     */
    function setxYSL(address _xYSL) external onlyRole(DEFAULT_ADMIN_ROLE){
        xYSL = _xYSL;
    }
    /**
        @dev this function used to set USDy address
        @param _USDy address
     */
    function setUSDy(address _USDy) external onlyRole(DEFAULT_ADMIN_ROLE){
        USDy = _USDy;
    }
    /**
        @dev this function used to set USDs address
        @param _USDs address
     */
    function setUSDs(address _USDs) external onlyRole(DEFAULT_ADMIN_ROLE){
        USDs = _USDs;
    }
    /**
        @dev this function used to set bysl address
        @param _bYSL address
     */
    function setbYSL(address _bYSL) external onlyRole(DEFAULT_ADMIN_ROLE){
        bYSL = _bYSL;
    }
    /**
        @dev this function used to set BShare address
        @param _BShare address
     */
    function setBShare(address _BShare) external onlyRole(DEFAULT_ADMIN_ROLE){
        BShare = _BShare;
    }
    /**
        @dev this function used to set YSLVault address
        @param _YSLVault address
     */
    function setYSLVault(address _YSLVault) external onlyRole(DEFAULT_ADMIN_ROLE){
        YSLVault = _YSLVault;
    }
    /**
        @dev this function used to set YSLBUSDVault address
        @param _YSLBUSDVault address
     */
    function setYSLBUSDVault(address _YSLBUSDVault) external onlyRole(DEFAULT_ADMIN_ROLE){
        YSLBUSDVault = _YSLBUSDVault;
    }
    /**
        @dev this function used to set xYSLVault address
        @param _xYSLVault address
     */
    function setxYSLVault(address _xYSLVault) external onlyRole(DEFAULT_ADMIN_ROLE){
        xYSLVault = _xYSLVault;
    }
    /**
        @dev this function used to set xYSLBUSDVault address
        @param _xYSLBUSDVault address
     */
    function setxYSLBUSDVault(address _xYSLBUSDVault) external onlyRole(DEFAULT_ADMIN_ROLE){
        xYSLBUSDVault = _xYSLBUSDVault;
    }
    /**
        @dev this function used to set USDyVault address
        @param _USDyVault address
     */
    function setUSDyVault(address _USDyVault) external onlyRole(DEFAULT_ADMIN_ROLE){
        USDyVault = _USDyVault;
    }
    /**
        @dev this function used to set USDyBUSDVault address
        @param _USDyBUSDVault address
     */
    function setUSDyBUSDVault(address _USDyBUSDVault) external onlyRole(DEFAULT_ADMIN_ROLE){
        USDyBUSDVault = _USDyBUSDVault;
    }
    /**
        @dev this function used to set bYSLVault address
        @param _bYSLVault address
     */
    function setbYSLVault(address _bYSLVault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bYSLVault = _bYSLVault;
    }
    /**
        @dev this function used to set BShareBUSD address
        @param _BShareBUSD address
     */
    function setBShareBUSD(address _BShareBUSD) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BShareBUSDVault = _BShareBUSD;
    }
    /**
        @dev this function used to set Treasury address
        @param _Treasury address
     */
    function setTreasury(address _Treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Treasury = _Treasury;
    }
    /**
        @dev this function used to set BUSDPROTOCOL address
        @param _BUSDProtocol address
     */
    function setBUSDProtocol(address _BUSDProtocol) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BUSDProtocol = _BUSDProtocol;
    }
    /**
        @dev this function used to set POL address
        @param _POL address
     */
    function setPOL(address _POL) external onlyRole(DEFAULT_ADMIN_ROLE){
        POL = _POL;
    }
    /**
        @dev this function used to set MasterNTT address
        @param _masterNTT address
     */
    function setmasterNTT(address _masterNTT)external onlyRole(DEFAULT_ADMIN_ROLE){
        masterNTT=_masterNTT;
    }
    /**
        @dev this function used to set biswapRouter address
        @param _biswapRouter address
     */
    function setbiswapRouter(address _biswapRouter)external onlyRole(DEFAULT_ADMIN_ROLE){
        biswapRouter =_biswapRouter;
    }
    /**
        @dev this function used to set ApeswapRouter address
        @param _ApeswapRouter address
     */
    function setApeswapRouter(address _ApeswapRouter)external onlyRole(DEFAULT_ADMIN_ROLE){
        ApeswapRouter = _ApeswapRouter;
    }
    /**
        @dev this function used to set pancakeRouter address
        @param _pancakeRouter address
     */
    function setpancakeRouter(address _pancakeRouter)external onlyRole(DEFAULT_ADMIN_ROLE){
        pancakeRouter = _pancakeRouter;
    }
    /**
        @dev this function used to set TeamAddress address
        @param _TeamAddress address
     */
    function setTeamAddress(address _TeamAddress)external onlyRole(DEFAULT_ADMIN_ROLE){
        TeamAddress = _TeamAddress;
    }
    /**
        @dev this function used to set MasterChef address
        @param _MasterChef address
     */
    function setMasterChef(address _MasterChef)external onlyRole(DEFAULT_ADMIN_ROLE){
        MasterChef = _MasterChef;
    }
    /**
        @dev this function used to set MasterChef address
        @param _blacklist address
     */
    function setBlacklist(address _blacklist) external onlyRole(DEFAULT_ADMIN_ROLE){
        Blacklist = _blacklist;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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