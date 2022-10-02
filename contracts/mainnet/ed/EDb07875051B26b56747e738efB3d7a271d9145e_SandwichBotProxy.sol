// SPDX-License-Identifier: GNU-GPL
pragma solidity >=0.8.0;

import "./interfaces/IResonateHelper.sol";
import "./interfaces/ISandwichBotProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


/** @title Sandwich Bot Proxy. */
contract SandwichBotProxy is ISandwichBotProxy, AccessControl {

    /// Resonate Helper address
    address public RESONATE_HELPER;

    /// Declares CALLER, VOTER, ADMIN
    bytes32 public constant CALLER = 'CALLER';
    bytes32 public constant VOTER = 'VOTER';
    bytes32 public constant ADMIN = 'ADMIN';

    /**
     * @notice Sets up the sandwich bot proxy and its roles
     * @dev 
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _setupRole(CALLER, msg.sender);
        _setupRole(VOTER, msg.sender);
        _setRoleAdmin(CALLER, ADMIN);
        _setRoleAdmin(VOTER, ADMIN);
    }

    /**
     * @notice Initiates a meta-governance proxy call for a specific poolId with a list of operations to perform
     * @param poolId the pool to use the SmartWallet.sol deployment of for the meta-governance calls
     * @param targets a list of addresses to make calls against
     * @param values a list of Ether values to include in the calls
     * @param calldatas encoded calldata for the calls to-be-made
     */
    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external override onlyRole(VOTER) {
        IResonateHelper(RESONATE_HELPER).proxyCall(poolId, targets, values, calldatas);
    }

    /**
     * @notice sets up the ResonateHelper.sol contract during deployment
     * @param _resonateHelper the address of ResonateHelper.sol for this deployment
     */
    function setResonateHelper(address _resonateHelper) external onlyRole(ADMIN) {
        RESONATE_HELPER = _resonateHelper;
    }

    /**
     * @notice initiates a withdrawal/deposit of assets from a passed-in vaultAdapter for a given poolId
     * @param poolId the pool to target
     * @param amount the amount of tokens to withdraw/deposit
     * @param isWithdrawal whether to withdraw or deposit
     */
    function sandwichSnapshot(
        bytes32 poolId, 
        uint amount, 
        bool isWithdrawal
    ) external override onlyRole(CALLER) {
        IResonateHelper(RESONATE_HELPER).sandwichSnapshot(poolId, amount, isWithdrawal);
    }

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./IResonate.sol";

/// @author RobAnon

interface IResonateHelper {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address owner);

    function POOL_TEMPLATE() external view returns (address template);

    function FNFT_TEMPLATE() external view returns (address template);

    function SANDWICH_BOT_ADDRESS() external view returns (address bot);

    function getAddressForPool(bytes32 poolId) external view returns (address smartWallet);

    function getAddressForFNFT(bytes32 fnftId) external view returns (address smartWallet);

    function getWalletForPool(bytes32 poolId) external returns (address smartWallet);

    function getWalletForFNFT(bytes32 fnftId) external returns (address wallet);


    function setResonate(address resonate) external;

    function blackListFunction(uint32 selector) external;
    function whiteListFunction(uint32 selector, bool isWhitelisted) external;

    /// To be used by the sandwich bot for bribe system. Can only withdraw assets back to vault not externally
    function sandwichSnapshot(bytes32 poolId, uint amount, bool isWithdrawal) external;
    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external;
    ///
    /// VIEW METHODS
    ///

    function getPoolId(
        address asset, 
        address vault,
        address adapter, 
        uint128 rate,
        uint128 _additional_rate,
        uint32 lockupPeriod, 
        uint packetSize
    ) external pure returns (bytes32 poolId);

    function nextInQueue(bytes32 poolId, bool isProvider) external view returns (IResonate.Order memory order);

    function isQueueEmpty(bytes32 poolId, bool isProvider) external view returns (bool isEmpty);

    function calculateInterest(uint fnftId) external view returns (uint256 interest, uint256 interestAfterFee);

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface ISandwichBotProxy {
// SPDX-License-Identifier: GNU-GPL


    function proxyCall(bytes32 poolId, address[] memory targets, uint[] memory values, bytes[] memory calldatas) external;

    function setResonateHelper(address _resonateHelper) external;

    function sandwichSnapshot(
        bytes32 poolId, 
        uint amount, 
        bool isWithdrawal
    ) external;

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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

library Bytes32Conversion {
    function toAddress(bytes32 b32) internal pure returns (address) {
        return address(uint160(bytes20(b32)));
    }
}

interface IResonate {

        // Uses 3 storage slots
    struct PoolConfig {
        address asset; // 20
        address vault; // 20 
        address adapter; // 20
        uint32  lockupPeriod; // 4
        uint128  rate; // 16
        uint128  addInterestRate; //Amount additional (10% on top of the 30%) - If not a bond then just zero // 16
        uint256 packetSize; // 32
    }

    // Uses 1 storage slot
    struct PoolQueue {
        uint64 providerHead;
        uint64 providerTail;
        uint64 consumerHead;
        uint64 consumerTail;
    }

    // Uses 3 storage slot
    struct Order {
        uint256 packetsRemaining;
        uint256 depositedShares;
        bytes32 owner;
    }

    struct ParamPacker {
        Order consumerOrder;
        Order producerOrder;
        bool isProducerNew;
        bool isCrossAsset;
        uint quantityPackets; 
        uint currentExchangeRate;
        PoolConfig pool;
        address adapter;
        bytes32 poolId;
    }

    /// Uses 4 storage slots
    /// Stores information on activated positions
    struct Active {
        // The ID of the associated Principal FNFT
        // Interest FNFT will be this +1
        uint256 principalId; 
        // Set at the time you last claim interest
        // Current state of interest - current shares per asset
        uint256 sharesPerPacket; 
        // Zero measurement point at pool creation
        // Left as zero if Type0
        uint256 startingSharesPerPacket; 
        bytes32 poolId;
    }

    ///
    /// Events
    ///

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event PoolCreated(bytes32 indexed poolId, address indexed asset, address indexed vault, address payoutAsset, uint128 rate, uint128 addInterestRate, uint32 lockupPeriod, uint256 packetSize, bool isFixedTerm, string poolName, address creator);

    event EnqueueProvider(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);
    event EnqueueConsumer(bytes32 indexed poolId, address indexed addr, uint64 indexed position, bool shouldFarm, Order order);

    event DequeueProvider(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);
    event DequeueConsumer(bytes32 indexed poolId, address indexed dequeuer, address indexed owner, uint64 position, Order order);

    event OracleRegistered(address indexed vaultAsset, address indexed paymentAsset, address indexed oracleDispatch);

    event VaultAdapterRegistered(address indexed underlyingVault, address indexed vaultAdapter, address indexed vaultAsset);

    event CapitalActivated(bytes32 indexed poolId, uint numPackets, uint indexed principalFNFT);
    
    event OrderWithdrawal(bytes32 indexed poolId, uint amountPackets, bool fullyWithdrawn, address owner);

    event FNFTCreation(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);
    event FNFTRedeemed(bytes32 indexed poolId, bool indexed isPrincipal, uint indexed fnftId, uint quantityFNFTs);

    event FeeCollection(bytes32 indexed poolId, uint amountTokens);

    event InterestClaimed(bytes32 indexed poolId, uint indexed fnftId, address indexed claimer, uint amount);
    event BatchInterestClaimed(bytes32 indexed poolId, uint[] fnftIds, address indexed claimer, uint amountInterest);
    
    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);
    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    function residuals(uint fnftId) external view returns (uint residual);
    function RESONATE_HELPER() external view returns (address resonateHelper);

    function queueMarkers(bytes32 poolId) external view returns (uint64 a, uint64 b, uint64 c, uint64 d);
    function providerQueue(bytes32 poolId, uint256 providerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function consumerQueue(bytes32 poolId, uint256 consumerHead) external view returns (uint packetsRemaining, uint depositedShares, bytes32 owner);
    function activated(uint fnftId) external view returns (uint principalId, uint sharesPerPacket, uint startingSharesPerPacket, bytes32 poolId);
    function pools(bytes32 poolId) external view returns (address asset, address vault, address adapter, uint32 lockupPeriod, uint128 rate, uint128 addInterestRate, uint256 packetSize);
    function vaultAdapters(address vault) external view returns (address vaultAdapter);
    function fnftIdToIndex(uint fnftId) external view returns (uint index);
    function REGISTRY_ADDRESS() external view returns (address registry);

    function receiveRevestOutput(
        uint fnftId,
        address,
        address payable owner,
        uint quantity
    ) external;

    function claimInterest(uint fnftId, address recipient) external;
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