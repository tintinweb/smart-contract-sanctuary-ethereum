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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./PriceCalculator.sol";
import "../interfaces/shared/ISale.sol";
import "../interfaces/shared/IEarlySaleReceiver.sol";
import "./library/IterableMapping.sol";

/// @title Contract which allows early investors to deposit ETH to reserve STK for the upcoming private sale
/// @notice Sends buy orders to StaakeSale contract
contract EarlySale is ISale, PriceCalculator, AccessControl {
    using IterableMapping for IterableMapping.Map;

    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR");

    uint256 public availableTokens;
    IterableMapping.Map private investorToBalance;

    IEarlySaleReceiver public receiver;

    bool public isPublic = true;
    bool public isClosed = false;

    uint256 public immutable MIN_INVESTMENT;
    uint256 public immutable MAX_INVESTMENT;

    event TokenReserved(address indexed investor, uint256 eth, uint256 stk);

    constructor(
        address _priceFeed,
        uint256 _remainingTokens,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        address[] memory _earlyInvestors
    ) PriceCalculator(_priceFeed) {
        availableTokens = _remainingTokens;
        MIN_INVESTMENT = _minInvestment;
        MAX_INVESTMENT = _maxInvestment;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice view the price of STK tokens in USD
     */
    function STK_USD_VALUE()
        public
        pure
        override(ISale, PriceCalculator)
        returns (uint256)
    {
        // 1 STK = 1/10 USD => 1 STK = 0.10 USD
        return (10**STK_USD_DECIMALS() * 1) / 10;
    }

    /**
     * @notice view the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS()
        public
        pure
        override(ISale, PriceCalculator)
        returns (uint8)
    {
        return 8;
    }

    /**
     * @notice Reserves STK tokens at the current ETH/USD exchange rate
     */
    function buy() external payable {
        require(!isClosed, "early sale is closed");
        require(
            isPublic || hasRole(INVESTOR_ROLE, msg.sender),
            "early sale is private"
        );

        require(msg.value >= MIN_INVESTMENT, "amount should be at least 5 ETH");

        (uint256 eth, ) = investorToBalance.get(msg.sender);
        require(eth + msg.value <= MAX_INVESTMENT, "max investment is 500 ETH");

        uint256 stk = getPriceConversion(msg.value);
        require(stk <= availableTokens, "not enough tokens available");

        investorToBalance.increment(msg.sender, msg.value, stk);
        availableTokens -= stk;

        emit TokenReserved(msg.sender, msg.value, stk);
    }

    /**
     * @notice Initializes the receiver of the STK buy orders
     * @notice Makes `withdrawAll()` available
     * @notice Contract must implement ERC165 and IEarlySaleReceiver
     * @param _address, contract address
     */
    function setReceiver(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(receiver) == address(0), "address already set");
        require(
            ERC165Checker.supportsInterface(
                _address,
                type(IEarlySaleReceiver).interfaceId
            ),
            "address is not a compatible receiver"
        );

        receiver = IEarlySaleReceiver(_address);
    }

    /**
     * @notice Withdraws the ETH to the caller's address
     * @notice Ends the sale and locks the `buy` function
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!isClosed, "sale is already over");
        isClosed = true;
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Transfers a batch of buy orders to the receiver contract
     * @notice Withdraws the ETH to the caller's wallet and self-destructs if there are no buy orders left
     * @notice Ends the sale and locks the `buy` function
     * @notice Can only be called if the receiver address has been set
     */
    function sendBuyOrders(uint256 _count)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(isClosed, "sale should be over");
        require(address(receiver) != address(0), "receiver not set yet");
        require(
            _count <= investorToBalance.size(),
            "count above investor count"
        );

        for (uint256 i = 0; i < _count; i++) {
            address investor = investorToBalance.getKeyAtIndex(0);
            (uint256 eth, uint256 stk) = investorToBalance.get(investor);
            investorToBalance.remove(investor);

            receiver.earlyDeposit(investor, eth, stk);
        }

        if (investorToBalance.size() == 0) selfdestruct(payable(msg.sender));
    }

    /**
     * @notice Allows new addresses to invest (i.e. to call the `buy` function)
     * @param _earlyInvestors, array of addresses of the investors
     */
    function addToWhitelist(address[] calldata _earlyInvestors)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Revoke access to the `buy` function from investors
     * @param _earlyInvestors, array of addresses of the investors
     */
    function removeFromWhitelist(address[] calldata _earlyInvestors)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < _earlyInvestors.length; i++)
            _revokeRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Set whether the sale is public or whitelist-only
     */
    function setIsPublic(bool _isPublic) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPublic = _isPublic;
    }

    /**
     * @notice View the number of distinct investors
     */
    function investorCount() external view returns (uint256) {
        return investorToBalance.size();
    }

    /**
     * @notice View the amount of STK a user currently has reserved
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256) {
        (, uint256 stk) = investorToBalance.get(_user);
        return stk;
    }

    /**
     * @notice View the amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint256) {
        (uint256 eth, ) = investorToBalance.get(_user);
        return eth;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library IterableMapping {
    // Iterable mapping from address to balances;
    struct Map {
        address[] keys;
        mapping(address => Value) values;
        mapping(address => uint256) indexOf;
    }

    struct Value {
        uint256 stk;
        uint256 eth;
    }

    function get(
        Map storage self,
        address _key
    ) public view returns (uint256 eth, uint256 stk) {
        return (self.values[_key].eth, self.values[_key].stk);
    }

    function getKeyAtIndex(
        Map storage self,
        uint256 index
    ) public view returns (address) {
        return self.keys[index];
    }

    function size(Map storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function increment(
        Map storage self,
        address _key,
        uint256 _eth,
        uint256 _stk
    ) public {
        if (self.values[_key].stk == 0 && self.values[_key].stk == 0) {
            self.indexOf[_key] = self.keys.length;
            self.keys.push(_key);
        }

        self.values[_key].eth += _eth;
        self.values[_key].stk += _stk;
    }

    function remove(Map storage self, address _key) public {
        if (self.values[_key].stk == 0 && self.values[_key].stk == 0) {
            return;
        }

        delete self.values[_key];

        uint256 index = self.indexOf[_key];
        uint256 lastIndex = self.keys.length - 1;
        address lastKey = self.keys[lastIndex];

        self.indexOf[lastKey] = index;
        delete self.indexOf[_key];

        self.keys[index] = lastKey;
        self.keys.pop();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract PriceCalculator {
    AggregatorV3Interface internal priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice view the price of STK tokens in USD
     */
    function STK_USD_VALUE() public view virtual returns (uint256);

    /**
     * @notice view the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS() public view virtual returns (uint8);

    /**
     * @notice convert WEI => STK
     * @param _eth, the value to convert
     */
    function getPriceConversion(uint256 _eth) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            (uint256(price) * _eth * 10**STK_USD_DECIMALS()) /
            STK_USD_VALUE() /
            10**priceFeed.decimals();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Interface Staake Sale
abstract contract IEarlySaleReceiver is ERC165 {
    /**
     * @notice deposit previous purchases of STK
     */
    function earlyDeposit(
        address _investor,
        uint256 _eth,
        uint256 _stk
    ) external virtual;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IEarlySaleReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Shared interface for EarlySale + StaakeSale
interface ISale {
    /**
     * @notice view the price of STK tokens in USD
     */
    function STK_USD_VALUE() external view returns (uint256);

    /**
     * @notice view the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS() external view returns (uint8);

    /**
     * @notice view the minimum amount of ETH per call
     */
    function MIN_INVESTMENT() external view returns (uint256);

    /**
     * @notice view the maximum total amount of ETH per investor
     */
    function MAX_INVESTMENT() external view returns (uint256);

    /**
     * @notice view the amount of STK still available for sale
     */
    function availableTokens() external view returns (uint256);

    /**
     * @notice Buy STK token
     */
    function buy() external payable;

    /**
     * @notice view the amount of STK token for a user
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256);

    /**
     * @notice view the amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint256);
}