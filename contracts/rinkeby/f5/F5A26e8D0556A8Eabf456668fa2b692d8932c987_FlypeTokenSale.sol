// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
pragma solidity 0.8.10;

import "./IFlypeNFT.sol";
import "./IaFLYP.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FlypeTokenSale is AccessControl, ReentrancyGuard {
    /// @notice Contains parameters, necessary for the pool
    /// @dev to see this parameters use getPoolInfo, checkUsedAddress and checkUsedNFT functions
    struct PoolInfo {
        uint256 takenSeats;
        uint256 maxSeats;
        uint256 maxTicketsPerUser;
        uint256 ticketPrice;
        uint256 ticketReward;
        uint256 lockup;
        mapping(address => uint256) takenTickets;
    }

    /// @notice pool ID for Econom class
    uint256 public constant ECONOM_PID = 0;
    /// @notice pool ID for Buisness class
    uint256 public constant BUISNESS_PID = 1;
    /// @notice pool ID for First class
    uint256 public constant FIRST_CLASS_PID = 2;

    /// @notice address of Flype NFT
    IFlypeNFT public immutable Flype_NFT;

    /// @notice address of aFLYP
    IaFLYP public immutable aFLYP;

    /// @notice True if minting is paused
    bool public onPause;
    bool public allowedOnly;

    mapping(uint256 => PoolInfo) poolInfo;
    mapping(address => bool) public banlistAddress;

    /// @notice Restricts from calling function with non-existing pool id
    modifier poolExist(uint256 pid) {
        require(pid <= 2, "Wrong pool ID");
        _;
    }

    /// @notice Restricts from calling function when sale is on pause
    modifier OnPause() {
        require(!onPause, "Sale is on pause");
        _;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only owner can use this function"
        );
        _;
    }

    /// @notice event emmited on each token sale
    /// @dev all events whould be collected after token sale and then distributed
    /// @param user address of buyer
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event Sale(
        address indexed user,
        uint256 pid,
        uint256 takenSeat,
        uint256 reward,
        uint256 lockup,
        uint256 blockNumber,
        uint256 timestamp
    );

    /// @notice event emmited on each pool initialization
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param maxSeats maximum number of participants
    /// @param ticketPrice amount of usdc which must be approved to participate
    /// @param ticketReward reward, which must be sent
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event InitializePool(
        uint256 pid,
        uint256 takenSeat,
        uint256 maxSeats,
        uint256 maxTicketsPerUser,
        uint256 ticketPrice,
        uint256 ticketReward,
        uint256 lockup,
        uint256 blockNumber,
        uint256 timestamp
    );

    /// @notice Performs initial setup.
    /// @param _FlypeNFT address of Flype NFT
    constructor(IFlypeNFT _FlypeNFT, IaFLYP _aFLYP) ReentrancyGuard() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        Flype_NFT = _FlypeNFT;
        aFLYP = _aFLYP;
        allowedOnly = true;
    }

    /// @notice Function that allows contract owner to initialize and update update pool settings
    /// @param pid pool id
    /// @param _maxSeats maximum number of participants
    /// @param _ticketPrice amount of eth which must be sended to participate
    /// @param _ticketReward reward, which must be sent
    /// @param _lockup time before token can be collected
    function initializePool(
        uint256 pid,
        uint256 _takenSeats,
        uint256 _maxSeats,
        uint256 _maxTicketPerUser,
        uint256 _ticketPrice,
        uint256 _ticketReward,
        uint256 _lockup
    ) external onlyOwner poolExist(pid) {
        PoolInfo storage pool = poolInfo[pid];
        pool.takenSeats = _takenSeats;
        pool.maxSeats = _maxSeats;
        pool.ticketPrice = _ticketPrice;
        pool.ticketReward = _ticketReward;
        pool.lockup = _lockup;
        pool.maxTicketsPerUser = _maxTicketPerUser;
        emit InitializePool(
            pid,
            pool.takenSeats,
            pool.maxSeats,
            pool.maxTicketsPerUser,
            pool.ticketPrice,
            pool.ticketReward,
            pool.lockup,
            block.number,
            block.timestamp
        );
    }

    /// @notice Function that allows contract owner to ban address from sale
    /// @param user address which whould be banned or unbanned
    /// @param isBanned state of ban
    function banAddress(address user, bool isBanned) external onlyOwner {
        banlistAddress[user] = isBanned;
    }

    function setAllowedOnly(bool newState) external onlyOwner {
        allowedOnly = newState;
    }

    /// @notice Function that allows contract owner to pause sale
    /// @param _onPause state of pause
    function setOnPause(bool _onPause) external onlyOwner {
        onPause = _onPause;
    }

    /// @notice Function that allows contract owner to receive eth from sale
    /// @param receiver address which whould receive eth
    function takeEth(address receiver) external onlyOwner {
        safeTransferETH(receiver, address(this).balance);
    }

    /// @notice emit Sale event for chosen pool
    /// @dev to use it send enough eth
    /// @param pid Pool id
    function buyTokens(uint256 pid, uint256 amountOfTickets)
        external
        payable
        OnPause
        nonReentrant
        poolExist(pid)
    {
        require(!banlistAddress[_msgSender()], "This address is banned");
        require(amountOfTickets > 0, "Amount of tickets cannot be zero");
        if (allowedOnly)
            require(Flype_NFT.allowList(_msgSender()), "Not in WL");
        PoolInfo storage pool = poolInfo[pid];
        require(pool.takenSeats < pool.maxSeats, "No seats left");
        require(
            pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser,
            "User cannot buy more than maxTicketsPerUser"
        );
        uint256 TotalPayment;
        uint256 TotalRewards;
        for (
            uint256 i = 0;
            i < amountOfTickets &&
                pool.takenSeats < pool.maxSeats &&
                pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser;
            i++
        ) {
            TotalPayment += pool.ticketPrice;
            pool.takenSeats++;
            pool.takenTickets[_msgSender()]++;
            TotalRewards += pool.ticketReward;

            emit Sale(
                _msgSender(),
                pid,
                pool.takenSeats,
                pool.ticketReward,
                pool.lockup,
                block.number,
                block.timestamp
            );
        }
        require(msg.value >= TotalPayment, "Insufficient funds sent");
        aFLYP.mintFor(_msgSender(), TotalRewards);
        if (msg.value > TotalPayment)
            safeTransferETH(_msgSender(), msg.value - TotalPayment);
    }

    /// @notice get pool setting and parameters
    /// @param pid pool id
    /// @return takenSeats № of last taken seat
    /// @return maxSeats maximum number of participants
    /// @return maxTicketsPerUser maximum number of participations per user
    /// @return ticketPrice amount of eth which must be send to participate in pool
    function getPoolInfo(uint256 pid)
        external
        view
        poolExist(pid)
        returns (
            uint256 takenSeats,
            uint256 maxSeats,
            uint256 maxTicketsPerUser,
            uint256 ticketPrice,
            uint256 ticketReward,
            uint256 lockup
        )
    {
        return (
            poolInfo[pid].takenSeats,
            poolInfo[pid].maxSeats,
            poolInfo[pid].maxTicketsPerUser,
            poolInfo[pid].ticketPrice,
            poolInfo[pid].ticketReward,
            poolInfo[pid].lockup
        );
    }

    function getUserTicketsAmount(uint256 pid, address user)
        external
        view
        returns (uint256)
    {
        return (poolInfo[pid].takenTickets[user]);
    }

    /// @notice sends eth to given address
    /// @param to address of receiver
    /// @param value amount of eth to send
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IFlypeNFT{
    function allowList(address user) external view returns(bool); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IaFLYP{
    function mintFor(address _receiver, uint256 _amount) external;
}