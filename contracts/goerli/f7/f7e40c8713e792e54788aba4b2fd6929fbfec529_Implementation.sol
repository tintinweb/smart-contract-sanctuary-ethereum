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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./hats/HatsAccessControl.sol";
import "./hats/IHats.sol";

contract Implementation is HatsAccessControl {
    // Access Control roles
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    // Hats protocol deployments
    address public constant goerli = 0xcf912a0193593f5cD55D81FF611c26c3ED63f924;
    address public constant polygn = 0x95647F88dcbC12986046fc4f49064Edd11a25d38;
    address public constant gnosis = 0x6B49b86D21aBc1D60611bD85c843a9766B5493DB;

    // Hats Implementation
    IHats public Hats;

    // Hats
    uint256 public topId;
    uint256 public adminId;
    uint256 public operatorId;

    // other vars
    address public deployer;
    address public admin;
    address public operator;
    uint256 public testVal;

    // mock vars
    address eligibilty = address(222);
    address toggle = address(333);

    // test var
    bool public pass;

    constructor(address _admin, address _operator) {
        deployer = msg.sender;
        admin = _admin;
        operator = _operator;

        // Hats protocol implementation
        Hats = IHats(goerli);
    }

    function initTopHat() external {
        // mint top hat to this contract
        topId = Hats.mintTopHat(address(this), "TopHat", "");
    }

    function checkTopHat() external view returns (bool) {
        // confirm top hat was minted
        return Hats.isTopHat(topId);
    }

    // function setHatsContract() external {
    //     // changes Hats protocol implementation pointer
    //     _changeHatsContract(goerli);
    // }

    function createAdminHat() external {
        // create admin hat (child of top hat)
        adminId = Hats.createHat(
            topId,
            "AdminHat",
            2,
            eligibilty,
            toggle,
            false,
            ""
        );
    }

    function mintAdminHat() external {
        // mint admin hat
        Hats.mintHat(adminId, admin);
        // set access control
        _grantRole(ADMIN, adminId);
    }

    function createOperatorHat() external {
        // create operator hat (child of admin)
        operatorId = Hats.createHat(
            adminId,
            "OperatorHat",
            3,
            eligibilty,
            toggle,
            true,
            ""
        );
    }

    function mintOperatorHat() external {
        // mint operator hat
        Hats.mintHat(operatorId, operator);
        // set access control
        _grantRole(OPERATOR, operatorId);
    }

    function transferTopHat() external {
        Hats.transferHat(topId, address(this), deployer);
    }

    function testTransfer() external {
        if (checkWearerOfTopHat() && checkHierarchy()) {
            pass = true;
        }
    }

    function checkWearerOfTopHat() internal view returns (bool) {
        return Hats.isWearerOfHat(operator, topId);
    }

    function checkHierarchy() internal view returns (bool) {
        return Hats.isAdminOfHat(admin, operatorId);
    }

    // TESTS:

    // only admin can call
    function adminTest(uint256 n) external onlyRole(ADMIN) returns (uint256) {
        testVal = n;
        return testVal;
    }

    // only operator can call (and admin?)
    function operatorTest(uint256 n)
        external
        onlyRole(OPERATOR)
        returns (uint256)
    {
        testVal = n;
        return testVal;
    }
}

// SPDX-License-Identifier: CC0
pragma solidity >=0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import "./IHats.sol";

/**
 * @notice forked from OpeZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol)
 * @author Hats Protocol
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
 * accounts that wear a role's admin hat {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts wearing this hat's role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract HatsAccessControl is Context {
    error NotWearingRoleHat(bytes32 role, uint256 hat, address account);

    error RoleAlreadyAssigned(bytes32 role, uint256 roleHat);

    event RoleGranted(bytes32 indexed role, uint256 indexed hat, address indexed sender);

    event RoleRevoked(bytes32 indexed role, uint256 indexed hat, address indexed sender);

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event HatsContractChanged(address indexed previousHatsContract, address indexed newHatsContract);

    event RoleHatChanged(bytes32 indexed role, uint256 indexed previousRoleHat, uint256 indexed newRoleHat);

    struct RoleData {
        uint256 hat;
        bytes32 adminRole;
    }

    IHats private HATS;

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`,
     * based on the account wearing the correct hat.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return HATS.isWearerOfHat(account, _roles[role].hat);
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     * Format of the revert message is described in {_checkRole}.
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert NotWearingRoleHat(role, _roles[role].hat, account);
        }
    }

    function hatsContract() public view virtual returns (address) {
        return address(HATS);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `hat`.
     * If `hat` had not been already granted `role`, emits a {RoleGranted} event.
     * Requirements:
     * - the caller must wear ``role``'s hat's admin hat.
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, uint256 hat) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, hat);
    }

    function changeRoleHat(bytes32 role, uint256 newRoleHat) public virtual onlyRole(getRoleAdmin(role)) {
        _changeRoleHat(role, newRoleHat);
    }

    /**
     * @dev Revokes `role` from `hat`.
     * If `hat` had been granted `role`, emits a {RoleRevoked} event.
     * Requirements:
     * - the caller must wear ``role``'s hat's admin hat.
     */
    function revokeRole(bytes32 role, uint256 hat) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, hat);
    }

    /**
     * @dev Points to a new Hats Protocol implementation
     * Emits a {RoleAdminChanged} event.
     */

    /**
     * @dev Points to a new Hats Protocol implementation
     * Only callable by the wearer of the default admin role's hat
     * Emits a {RoleAdminChanged} event.
     */
    function changeHatsContract(address newHatsContract) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _changeHatsContract(newHatsContract);
    }

    function _changeHatsContract(address newHatsContract) internal virtual {
        address previousHatsContract = address(HATS);
        HATS = IHats(newHatsContract);

        emit HatsContractChanged(previousHatsContract, newHatsContract);
    }

    function _changeRoleHat(bytes32 role, uint256 newRoleHat) internal virtual {
        uint256 roleHat = _roles[role].hat;
        if (roleHat == 0) {
            _grantRole(role, newRoleHat);
        }
        if (roleHat != newRoleHat) {
            _roles[role].hat = newRoleHat;
            emit RoleHatChanged(role, roleHat, newRoleHat);
        }
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `hat`.
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, uint256 hat) internal virtual {
        uint256 roleHat = _roles[role].hat;
        if (roleHat > 0) {
            revert RoleAlreadyAssigned(role, roleHat);
        }
        if (roleHat != hat) {
            _roles[role].hat = hat;
            emit RoleGranted(role, hat, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, uint256 hat) internal virtual {
        if (_roles[role].hat == hat) {
            _roles[role].hat = 0;
            emit RoleRevoked(role, hat, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// Interfaces (3)
interface HatsErrors {
    error NotAdmin(address _user, uint256 _hatId);
    error AllHatsWorn(uint256 _hatId);
    error AlreadyWearingHat(address _wearer, uint256 _hatId);
    error HatDoesNotExist(uint256 _hatId);
    error NotEligible(address _wearer, uint256 _hatId);
    error NotHatWearer();
    error NotHatsToggle();
    error NotHatsEligibility();
    error BatchArrayLengthMismatch();
    error MaxLevelsReached();
    error Immutable();
    error NewMaxSupplyTooLow();
}

interface HatsEvents {
    event HatCreated(
        uint256 id,
        string details,
        uint32 maxSupply,
        address eligibility,
        address toggle,
        bool mutable_,
        string imageURI
    );
    event HatStatusChanged(uint256 hatId, bool newStatus);
    event HatDetailsChanged(uint256 hatId, string newDetails);
    event HatEligibilityChanged(uint256 hatId, address newEligibility);
    event HatToggleChanged(uint256 hatId, address newToggle);
    event HatMutabilityChanged(uint256 hatId);
    event HatMaxSupplyChanged(uint256 hatId, uint32 newMaxSupply);
    event HatImageURIChanged(uint256 hatId, string newImageURI);
}

interface IHatsIdUtilities {
    function buildHatId(uint256 _admin, uint8 _newHat)
        external
        pure
        returns (uint256 id);

    function getHatLevel(uint256 _hatId) external pure returns (uint8);

    function isTopHat(uint256 _hatId) external pure returns (bool);

    function getAdminAtLevel(uint256 _hatId, uint8 _level)
        external
        pure
        returns (uint256);

    function getTophatDomain(uint256 _hatId) external pure returns (uint256);
}

/// IHat Contract
interface IHats is IHatsIdUtilities, HatsErrors, HatsEvents {
    function mintTopHat(
        address _target,
        string memory _details,
        string memory _imageURI
    ) external returns (uint256 topHatId);

    function createHat(
        uint256 _admin,
        string memory _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string memory _imageURI
    ) external returns (uint256 newHatId);

    function batchCreateHats(
        uint256[] memory _admins,
        string[] memory _details,
        uint32[] memory _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] memory _mutables,
        string[] memory _imageURIs
    ) external returns (bool);

    function getNextId(uint256 _admin) external view returns (uint256);

    function mintHat(uint256 _hatId, address _wearer) external returns (bool);

    function batchMintHats(uint256[] memory _hatIds, address[] memory _wearers)
        external
        returns (bool);

    function setHatStatus(uint256 _hatId, bool _newStatus)
        external
        returns (bool);

    function checkHatStatus(uint256 _hatId) external returns (bool);

    function setHatWearerStatus(
        uint256 _hatId,
        address _wearer,
        bool _eligible,
        bool _standing
    ) external returns (bool);

    function checkHatWearerStatus(uint256 _hatId, address _wearer)
        external
        returns (bool);

    function renounceHat(uint256 _hatId) external;

    function transferHat(
        uint256 _hatId,
        address _from,
        address _to
    ) external;

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeHatImmutable(uint256 _hatId) external;

    function changeHatDetails(uint256 _hatId, string memory _newDetails)
        external;

    function changeHatEligibility(uint256 _hatId, address _newEligibility)
        external;

    function changeHatToggle(uint256 _hatId, address _newToggle) external;

    function changeHatImageURI(uint256 _hatId, string memory _newImageURI)
        external;

    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external;

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function viewHat(uint256 _hatId)
        external
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint8 lastHatId,
            bool mutable_,
            bool active
        );

    function isWearerOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    function isAdminOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    function isInGoodStanding(address _wearer, uint256 _hatId)
        external
        view
        returns (bool);

    function isEligible(address _wearer, uint256 _hatId)
        external
        view
        returns (bool);

    function getImageURIForHat(uint256 _hatId)
        external
        view
        returns (string memory);

    function balanceOf(address wearer, uint256 hatId)
        external
        view
        returns (uint256 balance);

    function uri(uint256 id) external view returns (string memory);
}