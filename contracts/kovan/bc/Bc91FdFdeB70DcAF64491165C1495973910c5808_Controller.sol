// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

// ==================== Internal Imports ====================

import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../lib/AddressArrayUtil.sol";

import { IController } from "../interfaces/IController.sol";
import { IMatrixToken } from "../interfaces/IMatrixToken.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IMatrixValuer } from "../interfaces/IMatrixValuer.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title Controller
 *
 * @dev houses state for approvals and system contracts such as added matrix,
 * modules, factories, resources (like price oracles), and protocol fee configurations.
 */
contract Controller is AccessControl, IController {
    using AddressArrayUtil for address[];

    // ==================== Constants ====================

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 internal constant INTEGRATION_REGISTRY_RESOURCE_ID = 0;

    // PriceOracle will always be resource ID 1 in the system
    uint256 internal constant PRICE_ORACLE_RESOURCE_ID = 1;

    // MatrixValuer resource will always be resource ID 2 in the system
    uint256 internal constant MATRIX_VALUER_RESOURCE_ID = 2;

    // ==================== Variables ====================

    // Enabled matrixs
    address[] internal _matrixs;

    // Enabled factories of MatrixToken
    address[] internal _factories;

    // Enabled Modules; Modules extend the functionality of MatrixToken
    address[] internal _modules;

    // Enabled Resources; Resources provide data, functionality, or permissions that can be drawn upon from Module, MatrixToken or factories
    address[] internal _resources;

    // Mappings to check whether address is valid Matrix, Factory, Module or Resource
    mapping(address => bool) internal _isMatrix;
    mapping(address => bool) internal _isFactory;
    mapping(address => bool) internal _isModule;
    mapping(address => bool) internal _isResource;

    // Mapping of modules to fee types to fee percentage. A module can have multiple feeTypes. Fee is denominated in precise unit percentages (100% = 1e18, 1% = 1e16)
    mapping(address => mapping(uint256 => uint256)) internal _fees;

    // Resource ID => resource address, allows contracts to fetch the correct resource while providing an ID
    mapping(uint256 => address) internal _resourceIds;

    // Recipient of protocol fees
    address internal _feeRecipient;

    bool internal _isInitialized;

    // ==================== Constructor function ====================

    /**
     * @param feeRecipient    Address of the initial protocol fee recipient
     */
    constructor(address feeRecipient) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());

        _feeRecipient = feeRecipient;
    }

    // ==================== Modifier functions ====================

    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    modifier onlyInitialized() {
        _onlyInitialized();
        _;
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    // ==================== External functions ====================

    function isInitialized() external view returns (bool) {
        return _isInitialized;
    }

    function isMatrix(address addr) external view returns (bool) {
        return _isMatrix[addr];
    }

    function isFactory(address addr) external view returns (bool) {
        return _isFactory[addr];
    }

    function isModule(address addr) external view returns (bool) {
        return _isModule[addr];
    }

    function isResource(address addr) external view returns (bool) {
        return _isResource[addr];
    }

    /**
     * @dev Check if a contract address is a matrix, module, resource, factory or controller
     *
     * @param addr    The contract address to check
     */
    function isSystemContract(address addr) external view returns (bool) {
        return (_isMatrix[addr] || _isModule[addr] || _isResource[addr] || _isFactory[addr] || addr == address(this));
    }

    function getFeeRecipient() external view returns (address) {
        return _feeRecipient;
    }

    function getModuleFee(address moduleAddress, uint256 feeType) external view returns (uint256) {
        return _fees[moduleAddress][feeType];
    }

    function getFactories() external view returns (address[] memory) {
        return _factories;
    }

    function getModules() external view returns (address[] memory) {
        return _modules;
    }

    function getResources() external view returns (address[] memory) {
        return _resources;
    }

    function getResource(uint256 id) external view returns (address) {
        return _resourceIds[id];
    }

    function getMatrixs() external view returns (address[] memory) {
        return _matrixs;
    }

    /**
     * @dev Gets the instance of integration registry stored on Controller.
     * @notice IntegrationRegistry is stored as index 0 on the Controller.
     */
    function getIntegrationRegistry() external view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_resourceIds[INTEGRATION_REGISTRY_RESOURCE_ID]);
    }

    /**
     * @dev Gets instance of price oracle on Controller.
     * @notice PriceOracle is stored as index 1 on the Controller.
     */
    function getPriceOracle() external view returns (IPriceOracle) {
        return IPriceOracle(_resourceIds[PRICE_ORACLE_RESOURCE_ID]);
    }

    /**
     * @dev Gets the instance of matrix valuer on Controller.
     * @notice MatrixValuer is stored as index 2 on the Controller.
     */
    function getMatrixValuer() external view returns (IMatrixValuer) {
        return IMatrixValuer(_resourceIds[MATRIX_VALUER_RESOURCE_ID]);
    }

    /**
     * @dev Initializes any predeployed factories, modules, and resources post deployment.
     * @notice This function can only be called by the owner once to batch initialize the initial system contracts.
     *
     * @param factories      factories to add
     * @param modules        modules to add
     * @param resources      resources to add
     * @param resourceIds    resource IDs associated with the resources
     */
    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external onlyAdmin {
        require(!_isInitialized, "C0a");
        require(resources.length == resourceIds.length, "C0b");

        _factories = factories;
        _modules = modules;
        _resources = resources;

        // Loop through and initialize isModule, isFactory, and isResource mapping
        for (uint256 i = 0; i < factories.length; i++) {
            address factory = factories[i];
            require(factory != address(0), "C0c");

            _isFactory[factory] = true;
        }

        for (uint256 i = 0; i < modules.length; i++) {
            address module = modules[i];
            require(module != address(0), "C0d");

            _isModule[module] = true;
        }

        for (uint256 i = 0; i < resources.length; i++) {
            address resource = resources[i];
            require(resource != address(0), "C0e");

            uint256 resourceId = resourceIds[i];
            require(_resourceIds[resourceId] == address(0), "C0f");

            _isResource[resource] = true;
            _resourceIds[resourceId] = resource;
        }

        _isInitialized = true;
    }

    /**
     * @dev PRIVILEGED FACTORY FUNCTION. Adds a newly deployed MatrixToken as an enabled MatrixToken.
     *
     * @param matrixToken    Address of the MatrixToken contract to add
     */
    function addMatrix(address matrixToken) external onlyInitialized onlyFactory {
        require(!_isMatrix[matrixToken], "C1");

        _isMatrix[matrixToken] = true;
        _matrixs.push(matrixToken);

        emit AddMatrix(matrixToken, msg.sender);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a Set
     *
     * @param matrixToken    Address of the MatrixToken contract to remove
     */
    function removeMatrix(address matrixToken) external onlyInitialized onlyAdmin {
        require(_isMatrix[matrixToken], "C2");

        _matrixs.quickRemoveItem(matrixToken);
        _isMatrix[matrixToken] = false;

        emit RemoveMatrix(matrixToken);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a factory
     *
     * @param factory    Address of the factory contract to add
     */
    function addFactory(address factory) external onlyInitialized onlyAdmin {
        require(!_isFactory[factory], "C3");

        _isFactory[factory] = true;
        _factories.push(factory);

        emit AddFactory(factory);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a factory
     *
     * @param factory    Address of the factory contract to remove
     */
    function removeFactory(address factory) external onlyInitialized onlyAdmin {
        require(_isFactory[factory], "C4");

        _factories.quickRemoveItem(factory);
        _isFactory[factory] = false;

        emit RemoveFactory(factory);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a module
     *
     * @param module    Address of the module contract to add
     */
    function addModule(address module) external onlyInitialized onlyAdmin {
        require(!_isModule[module], "C5");

        _isModule[module] = true;
        _modules.push(module);

        emit AddModule(module);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a module
     *
     * @param module    Address of the module contract to remove
     */
    function removeModule(address module) external onlyInitialized onlyAdmin {
        require(_isModule[module], "C6");

        _modules.quickRemoveItem(module);
        _isModule[module] = false;

        emit RemoveModule(module);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a resource
     *
     * @param resource    Address of the resource contract to add
     * @param id          New ID of the resource contract
     */
    function addResource(address resource, uint256 id) external onlyInitialized onlyAdmin {
        require(!_isResource[resource], "C7a");
        require(_resourceIds[id] == address(0), "C7b");

        _isResource[resource] = true;
        _resourceIds[id] = resource;
        _resources.push(resource);

        emit AddResource(resource, id);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a resource
     *
     * @param id    ID of the resource contract to remove
     */
    function removeResource(uint256 id) external onlyInitialized onlyAdmin {
        address resourceToRemove = _resourceIds[id];
        require(resourceToRemove != address(0), "C8");

        _resources.quickRemoveItem(resourceToRemove);
        delete _resourceIds[id];
        _isResource[resourceToRemove] = false;

        emit RemoveResource(resourceToRemove, id);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a fee to a module
     *
     * @param module              Address of the module contract to add fee to
     * @param feeType             Type of the fee to add in the module
     * @param newFeePercentage    Percentage of fee to add in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external onlyInitialized onlyAdmin {
        require(_isModule[module], "C9a");
        require(_fees[module][feeType] == 0, "C9b");

        _fees[module][feeType] = newFeePercentage;

        emit AddFee(module, feeType, newFeePercentage);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit a fee in an existing module
     *
     * @param module              Address of the module contract to edit fee
     * @param feeType             Type of the fee to edit in the module
     * @param newFeePercentage    Percentage of fee to edit in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external onlyInitialized onlyAdmin {
        require(_isModule[module], "C10a");
        require(_fees[module][feeType] != 0, "C10b");

        _fees[module][feeType] = newFeePercentage;

        emit EditFee(module, feeType, newFeePercentage);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol fee recipient
     *
     * @param newFeeRecipient    Address of the new protocol fee recipient
     */
    function editFeeRecipient(address newFeeRecipient) external onlyInitialized onlyAdmin {
        require(newFeeRecipient != address(0), "C11");

        _feeRecipient = newFeeRecipient;

        emit EditFeeRecipient(newFeeRecipient);
    }

    // ==================== Private functions ====================

    function _onlyFactory() private view {
        require(_isFactory[msg.sender], "C12");
    }

    function _onlyInitialized() private view {
        require(_isInitialized, "C13");
    }

    function _onlyAdmin() private view {
        require(hasRole(ADMIN_ROLE, _msgSender()), "C14");
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title PreciseUnitMath
 *
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision.
 */
library PreciseUnitMath {
    // ==================== Constants ====================

    // The number One in precise units
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;

    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    // ==================== Internal functions ====================

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISE_UNIT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / PRECISE_UNIT_INT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        return (product == 0) ? 0 : ((product - 1) / PRECISE_UNIT + 1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM0");

        return (a * PRECISE_UNIT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "PM1");

        return (a * PRECISE_UNIT_INT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM2");

        return a > 0 ? ((a * PRECISE_UNIT - 1) / b + 1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     * return 0 when `a` is 0.reverts when `b` is 0.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM3");

        a *= PRECISE_UNIT_INT;
        result = a / b;

        if (a % b != 0) {
            (a ^ b >= 0) ? ++result : --result;
        }
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseMulFloor(int256 a, int256 b) internal pure returns (int256 result) {
        int256 product = a * b;
        result = product / PRECISE_UNIT_INT;

        if ((product < 0) && (product % PRECISE_UNIT_INT != 0)) {
            --result;
        }
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseDivFloor(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM4");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1

        if ((numerator ^ b < 0) && (numerator % b != 0)) {
            --result;
        }
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(
        uint256 a,
        uint256 b,
        uint256 range
    ) internal pure returns (bool) {
        if (a >= b) {
            return a - b <= range;
        } else {
            return b - a <= range;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title AddressArrayUtil
 *
 * @dev Utility functions to handle address arrays
 */
library AddressArrayUtil {
    // ==================== Internal functions ====================

    /**
     * @dev Returns true if there are 2 same elements in an array
     *
     * @param array The input array to search
     */
    function hasDuplicate(address[] memory array) internal pure returns (bool) {
        if (array.length > 1) {
            uint256 lastIndex = array.length - 1;
            for (uint256 i = 0; i < lastIndex; i++) {
                address value = array[i];
                for (uint256 j = i + 1; j < array.length; j++) {
                    if (value == array[j]) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * @dev Finds the index of the first occurrence of the given element.
     *
     * @param array     The input array to search
     * @param value     The value to find
     *
     * @return index    The first occurrence starting from 0
     * @return found    True if find
     */
    function indexOf(address[] memory array, address value) internal pure returns (uint256 index, bool found) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }

        return (type(uint256).max, false);
    }

    /**
     * @dev Check if the value is in the list.
     *
     * @param array    The input array to search
     * @param value    The value to find
     *
     * @return found   True if find
     */
    function contain(address[] memory array, address value) internal pure returns (bool found) {
        (, found) = indexOf(array, value);
    }

    /**
     * @param array    The input array to search
     * @param value    The address to remove
     *
     * @return result  the array with the object removed.
     */
    function removeValue(address[] memory array, address value) internal pure returns (address[] memory result) {
        (uint256 index, bool found) = indexOf(array, value);
        require(found, "A0");

        result = new address[](array.length - 1);

        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }

        for (uint256 i = index + 1; i < array.length; i++) {
            result[index] = array[i];
            index = i;
        }
    }

    /**
     * @param array    The input array to search
     * @param item     The address to remove
     */
    function removeItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A1");

        for (uint256 right = index + 1; right < array.length; right++) {
            array[index] = array[right];
            index = right;
        }

        array.pop();
    }

    /**
     * @param array    The input array to search
     * @param item     The address to remove
     */
    function quickRemoveItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A2");

        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @dev Returns the combination of the two arrays
     *
     * @param array1    The first array
     * @param array2    The second array
     *
     * @return result   A extended by B
     */
    function merge(address[] memory array1, address[] memory array2) internal pure returns (address[] memory result) {
        result = new address[](array1.length + array2.length);

        for (uint256 i = 0; i < array1.length; i++) {
            result[i] = array1[i];
        }

        uint256 index = array1.length;
        for (uint256 j = 0; j < array2.length; j++) {
            result[index++] = array2[j];
        }
    }

    /**
     * @dev Validate that address and uint array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of uint
     */
    function validateArrayPairs(address[] memory array1, uint256[] memory array2) internal pure {
        require(array1.length == array2.length, "A3");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bool array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bool
     */
    function validateArrayPairs(address[] memory array1, bool[] memory array2) internal pure {
        require(array1.length == array2.length, "A4");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and string array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of strings
     */
    function validateArrayPairs(address[] memory array1, string[] memory array2) internal pure {
        require(array1.length == array2.length, "A5");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address array lengths match, and calling address array are not empty and contain no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of addresses
     */
    function validateArrayPairs(address[] memory array1, address[] memory array2) internal pure {
        require(array1.length == array2.length, "A6");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bytes array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bytes
     */
    function validateArrayPairs(address[] memory array1, bytes[] memory array2) internal pure {
        require(array1.length == array2.length, "A7");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate address array is not empty and contains no duplicate elements.
     *
     * @param array    Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory array) internal pure {
        require(array.length > 0, "A8a");
        require(!hasDuplicate(array), "A8b");
    }

    /**
     * @dev assume both of array1 and array2 has no duplicate items
     */
    function equal(address[] memory array1, address[] memory array2) internal pure returns (bool) {
        if (array1.length != array2.length) {
            return false;
        }

        for (uint256 i = 0; i < array1.length; i++) {
            if (!contain(array2, array1[i])) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IMatrixValuer } from "../interfaces/IMatrixValuer.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title IController
 */
interface IController {
    // ==================== Events ====================

    event AddFactory(address indexed factory);
    event RemoveFactory(address indexed factory);
    event AddFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFeeRecipient(address newFeeRecipient);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event AddResource(address indexed resource, uint256 id);
    event RemoveResource(address indexed resource, uint256 id);
    event AddMatrix(address indexed matrixToken, address indexed factory);
    event RemoveMatrix(address indexed matrixToken);

    // ==================== External functions ====================

    function isMatrix(address matrixToken) external view returns (bool);

    function isFactory(address addr) external view returns (bool);

    function isModule(address addr) external view returns (bool);

    function isResource(address addr) external view returns (bool);

    function isSystemContract(address contractAddress) external view returns (bool);

    function getFeeRecipient() external view returns (address);

    function getModuleFee(address module, uint256 feeType) external view returns (uint256);

    function getFactories() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getResources() external view returns (address[] memory);

    function getResource(uint256 id) external view returns (address);

    function getMatrixs() external view returns (address[] memory);

    function getIntegrationRegistry() external view returns (IIntegrationRegistry);

    function getPriceOracle() external view returns (IPriceOracle);

    function getMatrixValuer() external view returns (IMatrixValuer);

    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external;

    function addMatrix(address matrixToken) external;

    function removeMatrix(address matrixToken) external;

    function addFactory(address factory) external;

    function removeFactory(address factory) external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function addResource(address resource, uint256 id) external;

    function removeResource(uint256 id) external;

    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFeeRecipient(address newFeeRecipient) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMatrixToken
 */
interface IMatrixToken is IERC20 {
    // ==================== Enums ====================

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    // ==================== Structs ====================

    /**
     * @dev The base definition of a MatrixToken Position
     *
     * @param unit             Each unit is the # of components per 10^18 of a MatrixToken
     * @param module           If not in default state, the address of associated module
     * @param component        Address of token in the Position
     * @param positionState    Position ENUM. Default is 0; External is 1
     * @param data             Arbitrary data
     */
    struct Position {
        int256 unit;
        address module;
        address component;
        uint8 positionState;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's external position details including virtual unit and any auxiliary data.
     *
     * @param virtualUnit    Virtual value of a component's EXTERNAL position.
     * @param data           Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and  virtual units.
     *
     * @param virtualUnit                Virtual value of a component's DEFAULT position. Stored as virtual for efficiency updating all units
     *                                   at once via the position multiplier. Virtual units are achieved by dividing a real value by the positionMultiplier
     * @param externalPositionModules    Eexternal modules attached to each external position. Each module maps to an external position
     * @param externalPositions          Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    // ==================== Events ====================

    event Invoke(address indexed target, uint256 indexed value, bytes data, bytes returnValue);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event InitializeModule(address indexed module);
    event EditManager(address newManager, address oldManager);
    event RemovePendingModule(address indexed module);
    event EditPositionMultiplier(int256 newMultiplier);
    event AddComponent(address indexed component);
    event RemoveComponent(address indexed component);
    event EditDefaultPositionUnit(address indexed component, int256 realUnit);
    event EditExternalPositionUnit(address indexed component, address indexed positionModule, int256 realUnit);
    event EditExternalPositionData(address indexed component, address indexed positionModule, bytes data);
    event AddPositionModule(address indexed component, address indexed positionModule);
    event RemovePositionModule(address indexed component, address indexed positionModule);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getManager() external view returns (address);

    function getLocker() external view returns (address);

    function getComponents() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getModuleState(address module) external view returns (ModuleState);

    function getPositionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(address component) external view returns (int256);

    function getDefaultPositionRealUnit(address component) external view returns (int256);

    function getExternalPositionRealUnit(address component, address positionModule) external view returns (int256);

    function getExternalPositionModules(address component) external view returns (address[] memory);

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory);

    function isExternalPositionModule(address component, address module) external view returns (bool);

    function isComponent(address component) external view returns (bool);

    function isInitializedModule(address module) external view returns (bool);

    function isPendingModule(address module) external view returns (bool);

    function isLocked() external view returns (bool);

    function setManager(address manager) external;

    function addComponent(address component) external;

    function removeComponent(address component) external;

    function editDefaultPositionUnit(address component, int256 realUnit) external;

    function addExternalPositionModule(address component, address positionModule) external;

    function removeExternalPositionModule(address component, address positionModule) external;

    function editExternalPositionUnit(
        address component,
        address positionModule,
        int256 realUnit
    ) external;

    function editExternalPositionData(
        address component,
        address positionModule,
        bytes calldata data
    ) external;

    function invoke(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);

    function invokeSafeApprove(
        address token,
        address spender,
        uint256 amount
    ) external;

    function invokeSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeExactSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeWrapWETH(address weth, uint256 amount) external;

    function invokeUnwrapWETH(address weth, uint256 amount) external;

    function editPositionMultiplier(int256 newMultiplier) external;

    function mint(address account, uint256 quantity) external;

    function burn(address account, uint256 quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function initializeModule() external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IPriceOracle
 */
interface IPriceOracle {
    // ==================== Events ====================

    event AddPair(address indexed asset1, address indexed asset2, address indexed oracle);
    event RemovePair(address indexed asset1, address indexed asset2, address indexed oracle);
    event EditPair(address indexed asset1, address indexed asset2, address indexed newOracle);
    event AddAdapter(address indexed adapter);
    event RemoveAdapter(address indexed adapter);
    event EditMasterQuoteAsset(address indexed newMasterQuote);
    event EditSecondQuoteAsset(address indexed newSecondQuote);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getOracle(address asset1, address asset2) external view returns (address);

    function getMasterQuoteAsset() external view returns (address);

    function getSecondQuoteAsset() external view returns (address);

    function getAdapters() external view returns (address[] memory);

    function getPrice(address asset1, address asset2) external view returns (uint256);

    function addPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function editPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function removePair(address asset1, address asset2) external;

    function addAdapter(address adapter) external;

    function removeAdapter(address adapter) external;

    function editMasterQuoteAsset(address newMasterQuoteAsset) external;

    function editSecondQuoteAsset(address newSecondQuoteAsset) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IMatrixToken } from "../interfaces/IMatrixToken.sol";

/**
 * @title IMatrixValuer
 */
interface IMatrixValuer {
    // ==================== External functions ====================

    function calculateMatrixTokenValuation(IMatrixToken matrixToken, address quoteAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/*
 * @title IIntegrationRegistry
 */
interface IIntegrationRegistry {
    // ==================== Events ====================

    event AddIntegration(address indexed module, address indexed adapter, string integrationName);
    event RemoveIntegration(address indexed module, address indexed adapter, string integrationName);
    event EditIntegration(address indexed module, address newAdapter, string integrationName);

    // ==================== External functions ====================

    function getIntegrationAdapter(address module, string memory id) external view returns (address);

    function getIntegrationAdapterWithHash(address module, bytes32 id) external view returns (address);

    function isValidIntegration(address module, string memory id) external view returns (bool);

    function addIntegration(address module, string memory id, address wrapper) external; // prettier-ignore

    function batchAddIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function editIntegration(address module, string memory name, address adapter) external; // prettier-ignore

    function batchEditIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function removeIntegration(address module, string memory name) external;
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