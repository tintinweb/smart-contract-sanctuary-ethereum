// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IIncreAccessControl is IAccessControl {
    /* ****************** */
    /*     Events         */
    /* ****************** */

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function isGovernor(address account) external view returns (bool);

    function isManager(address account) external view returns (bool);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

interface IVBase is IVirtualToken {
    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when oracle heart beat is updated
    /// @param newHeartBeat New heart beat value
    event HeartBeatUpdated(uint256 newHeartBeat);

    /// @notice Emitted when sequencer uptime feed is updated
    /// @param newSequencerUptimeFeed New sequencer uptime feed
    event SequencerUptimeFeedUpdated(AggregatorV3Interface newSequencerUptimeFeed);

    /// @notice Emitted when grace period is updated
    /// @param newGracePeriod New grace period
    event GracePeriodUpdated(uint256 newGracePeriod);

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the proposed aggregators decimals are less than PRECISION
    error VBase_InsufficientPrecision();

    /// @notice Emitted when the latest round is incomplete
    error VBase_InvalidRoundTimestamp();

    /// @notice Emitted when the latest round's price is invalid
    error VBase_InvalidRoundPrice();

    /// @notice Emitted when the latest round's data is older than the oracle's max refresh time
    error VBase_DataNotFresh();

    /// @notice Emitted when proposed sequencer uptime feed address is equal to the zero address
    error VBase_SequencerUptimeFeedZeroAddress();

    /// @notice Emitted when proposed grace period is outside of the bounds
    error VBase_IncorrectGracePeriod();

    /// @notice Emitted when Zksync sequencer is down
    error VBase_SequencerDown();

    /// @notice Emitted when Zksync sequencer hasn't been back up for long enough
    error VBase_GracePeriodNotOver();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function getIndexPrice() external view returns (int256);

    function heartBeat() external view returns (uint256);

    function sequencerUptimeFeed() external view returns (AggregatorV3Interface);

    function gracePeriod() external view returns (uint256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setHeartBeat(uint256 newHeartBeat) external;

    function setSequencerUptimeFeed(AggregatorV3Interface newSequencerUptimeFeed) external;

    function setGracePeriod(uint256 newGracePeriod) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVirtualToken is IERC20Metadata {
    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function mint(uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract BaseERC20 is IERC20, IERC20Metadata {
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public override name;

    string public override symbol;

    uint8 public constant override decimals = 18;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// contracts
import {VirtualToken} from "./VirtualToken.sol";
import {IncreAccessControl} from "../utils/IncreAccessControl.sol";

// interfaces
import {IVBase} from "../interfaces/IVBase.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice ERC20 token traded on the CryptoSwap pool
contract VBase is IVBase, IncreAccessControl, VirtualToken {
    uint8 internal constant PRECISION = 18;
    uint256 public override heartBeat;

    AggregatorV3Interface public immutable aggregator;
    AggregatorV3Interface public override sequencerUptimeFeed;
    uint256 public override gracePeriod;

    constructor(
        string memory _name,
        string memory _symbol,
        AggregatorV3Interface _aggregator,
        uint256 _heartBeat,
        AggregatorV3Interface _sequencerUptimeFeed,
        uint256 _gracePeriod
    ) VirtualToken(_name, _symbol) {
        if (_aggregator.decimals() > PRECISION) revert VBase_InsufficientPrecision();
        aggregator = _aggregator;
        setHeartBeat(_heartBeat);
        setSequencerUptimeFeed(_sequencerUptimeFeed);
        setGracePeriod(_gracePeriod);
    }

    /* *************** */
    /*   Governance    */
    /* *************** */

    function setHeartBeat(uint256 newHeartBeat) public override onlyRole(GOVERNANCE) {
        heartBeat = newHeartBeat;

        emit HeartBeatUpdated(newHeartBeat);
    }

    function setSequencerUptimeFeed(AggregatorV3Interface newSequencerUptimeFeed) public override onlyRole(GOVERNANCE) {
        if (address(newSequencerUptimeFeed) == address(0)) revert VBase_SequencerUptimeFeedZeroAddress();

        sequencerUptimeFeed = newSequencerUptimeFeed;
        emit SequencerUptimeFeedUpdated(newSequencerUptimeFeed);
    }

    function setGracePeriod(uint256 newGracePeriod) public override onlyRole(GOVERNANCE) {
        if (newGracePeriod < 60) revert VBase_IncorrectGracePeriod();
        if (newGracePeriod > 3600) revert VBase_IncorrectGracePeriod();

        gracePeriod = newGracePeriod;
        emit GracePeriodUpdated(newGracePeriod);
    }

    /* ****************** */
    /*   Global getter    */
    /* ****************** */

    function getIndexPrice() external view override returns (int256) {
        // Check if L2 sequencer up when transaction was received
        {
            (, int256 sequencerStatus, uint256 sequencerStatusLastUpdatedAt, , ) = sequencerUptimeFeed
                .latestRoundData();

            // 0 means sequencer is up & 1 sequencer is down
            bool isSequencerUp = sequencerStatus == 0;
            if (!isSequencerUp) revert VBase_SequencerDown();

            // make sure the grace period has passed after the sequencer is back up
            uint256 timeSinceUp = block.timestamp - sequencerStatusLastUpdatedAt;

            if (timeSinceUp <= gracePeriod) revert VBase_GracePeriodNotOver();
        }

        return _chainlinkPrice(aggregator);
    }

    function _chainlinkPrice(AggregatorV3Interface chainlinkInterface) internal view returns (int256) {
        uint8 chainlinkDecimals = chainlinkInterface.decimals();
        (, int256 roundPrice, , uint256 roundTimestamp, ) = chainlinkInterface.latestRoundData();

        // If the round is not complete yet, roundTimestamp is 0
        if (roundTimestamp <= 0) revert VBase_InvalidRoundTimestamp();
        if (roundPrice <= 0) revert VBase_InvalidRoundPrice();
        if (roundTimestamp + heartBeat < block.timestamp) revert VBase_DataNotFresh();

        int256 scaledPrice = (roundPrice * int256(10**(PRECISION - chainlinkDecimals)));
        return scaledPrice;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// contracts
import {BaseERC20} from "./BaseERC20.sol";
import {PerpOwnable} from "../utils/PerpOwnable.sol";

// interfaces
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

contract VirtualToken is IVirtualToken, BaseERC20, PerpOwnable {
    constructor(string memory _name, string memory _symbol) BaseERC20(_name, _symbol) {}

    function mint(uint256 amount) external override onlyPerp {
        _mint(perp, amount);
    }

    function burn(uint256 amount) external override onlyPerp {
        _burn(perp, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// interfaces
import {IIncreAccessControl} from "../interfaces/IIncreAccessControl.sol";

/// @notice Increment access control contract.
contract IncreAccessControl is AccessControl {
    bytes32 public constant GOVERNANCE = keccak256("GOVERNANCE");
    bytes32 public constant MANAGER = keccak256("MANAGER");

    constructor() {
        _setupRole(GOVERNANCE, msg.sender);
        _setRoleAdmin(GOVERNANCE, GOVERNANCE);

        _setupRole(MANAGER, msg.sender);
        _setRoleAdmin(MANAGER, GOVERNANCE);
    }

    // utils
    function isGovernor(address account) external view returns (bool) {
        return hasRole(GOVERNANCE, account);
    }

    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER, account);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

/// @notice Emitted when the sender is not perp
error PerpOwnable_NotOwner();

/// @notice Emitted when the proposed address is equal to the zero address
error PerpOwnable_TransferZeroAddress();

/// @notice Emitted when the ownership of the contract has already been claimed
error PerpOwnable_OwnershipAlreadyClaimed();

/// @notice Perp access control contract, simplied version of IncreOwnable
contract PerpOwnable {
    address public perp;

    event PerpOwnerTransferred(address indexed sender, address indexed recipient);

    /// @notice Access control modifier that requires modified function to be called by the perp contract
    modifier onlyPerp() {
        if (msg.sender != perp) revert PerpOwnable_NotOwner();
        _;
    }

    /// @notice Transfer `perp` account
    /// @notice Meant to be used only once at deployment as Perpetual can't transfer ownership afterwards
    /// @param recipient Account granted `perp` access control.
    function transferPerpOwner(address recipient) external {
        if (recipient == address(0)) revert PerpOwnable_TransferZeroAddress();
        if (perp != address(0)) revert PerpOwnable_OwnershipAlreadyClaimed();

        perp = recipient;
        emit PerpOwnerTransferred(msg.sender, recipient);
    }
}