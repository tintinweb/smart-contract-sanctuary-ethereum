// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * The Purpose of this contract is to handle the booking of areas to display specific images at coordinates for a determined time.
 * The booking process is two steps, as validation from the contract operators is required.
 * Users can create and cancel submissions, identified by a unique ID.
 * The operator can accept and reject user submissions. Rejected submissions are refunded.
*/
contract XiSpace is AccessControl {

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant PRICE_ROLE = keccak256("PRICE_ROLE");

    uint256 public constant BETA_RHO_SUPPLY = 6790 * 10**18;
    uint256 public constant MAX_X = 1200;
    uint256 public constant MAX_Y = 1080;
    uint256 public PIXEL_X_PRICE = BETA_RHO_SUPPLY / MAX_X / 100;
    uint256 public PIXEL_Y_PRICE = BETA_RHO_SUPPLY / MAX_Y / 100;
    uint256 public SECOND_PRICE = 10**17;

    address public treasury = 0x1f7c453a4cccbF826A97F213706Ee72b79dba466;

    IERC20 public betaToken = IERC20(0x35F67c1D929E106FDfF8D1A55226AFe15c34dbE2);
    IERC20 public rhoToken = IERC20(0x3F3Cd642E81d030D7b514a2aB5e3a5536bEb90Ec);
    IERC20 public kappaToken = IERC20(0x5D2C6545d16e3f927a25b4567E39e2cf5076BeF4);
    IERC20 public gammaToken = IERC20(0x1E1EEd62F8D82ecFd8230B8d283D5b5c1bA81B55);
    IERC20 public xiToken = IERC20(0x295B42684F90c77DA7ea46336001010F2791Ec8c);

    event SUBMISSION(uint256 id, address indexed addr);
    event CANCELLED(uint256 id);
    event BOOKED(uint256 id);
    event REJECTED(uint256 id, bool fundsReturned);

    struct Booking {
        uint16 x;
        uint16 y;
        uint16 width;
        uint16 height;
        bool validated;
        uint256 time;
        uint256 duration;
        bytes32 sha;
        address owner;
    }

    struct Receipt {
        uint256 betaAmount;
        uint256 rhoAmount;
        uint256 kappaAmount;
        uint256 gammaAmount;
        uint256 xiAmount;
    }

    uint256 public bookingsCount = 0;

    // Store the booking submissions
    mapping(uint256 => Booking) public bookings;

    // Store the amounts of Kappa and Gamma provided by the user for an area
    mapping(uint256 => Receipt) public receipts;

    constructor(address beta, address rho, address kappa, address gamma, address xi) {
        // in case we want to override the addresses (for testnet)
        if(beta != address(0)) {
            betaToken = IERC20(beta);
            rhoToken = IERC20(rho);
            kappaToken = IERC20(kappa);
            gammaToken = IERC20(gamma);
            xiToken = IERC20(xi);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VALIDATOR_ROLE, msg.sender);
        _setRoleAdmin(VALIDATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(TREASURER_ROLE, msg.sender);
        _setRoleAdmin(TREASURER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(PRICE_ROLE, msg.sender);
        _setRoleAdmin(PRICE_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setTreasury(address _treasury) external onlyRole(TREASURER_ROLE) {
        treasury = _treasury;
    }

    function setXiDivisor(uint256 divisor) external onlyRole(PRICE_ROLE) {
        SECOND_PRICE = 10**18 / divisor;
    }

    function setBetaAndRhoDivisor(uint256 divisor) external onlyRole(PRICE_ROLE) {
        PIXEL_X_PRICE = BETA_RHO_SUPPLY / MAX_X / divisor;
        PIXEL_Y_PRICE = BETA_RHO_SUPPLY / MAX_Y / divisor;
    }

    /**
     * @dev Called by the interface to submit a booking of an area to display an image. The user must have created 5 allowances for all tokens
     * At the time of submission, no collisions with previous bookings must be found or validation process will fail
     * User tokens are temporary stored in the contract and will be non refundable after validation
     * @param x X Coordinate of the upper left corner of the area, must be within screen boundaries: 0-MAX_X-1
     * @param y Y Coordinate of the upper left corner of the area, must be within screen boundaries: 0-MAX_Y-1
     * @param width Width of the area
     * @param height Height of the area
     * @param time Start timestamp for the display
     * @param duration Duration in seconds of the display
     * @param sha Must be the sha256 of the image as it is computed during IPFS storage
     * @param computedKappaAmount Amount of Kappa required to pay for the image pixels, this must be correct or the validation process will reject the submission
     * @param computedGammaAmount Amount of Gamma required to pay for the image pixels, this must be correct or the validation process will reject the submission
    */
    function submit(uint16 x, uint16 y, uint16 width, uint16 height, uint256 time, uint256 duration, bytes32 sha, uint256 computedKappaAmount, uint256 computedGammaAmount) external {
        require(width > 0
                && height > 0
                && time > 0
                && duration > 0
                && computedKappaAmount > 0
                && computedGammaAmount > 0
        , "XiSpace: Invalid arguments");
        require(x + width - 1 <= MAX_X, "XiSpace: Invalid area");
        require(y + height - 1 <= MAX_Y, "XiSpace: Invalid area");

        bookings[bookingsCount] = Booking(x, y, width, height, false, time, duration, sha, msg.sender);
        receipts[bookingsCount] = Receipt(PIXEL_X_PRICE * width, PIXEL_Y_PRICE * height, computedKappaAmount, computedGammaAmount, SECOND_PRICE * duration);
        emit SUBMISSION(bookingsCount, msg.sender);

        // Transfer the tokens from the user
        betaToken.transferFrom(msg.sender, address(this), receipts[bookingsCount].betaAmount);
        rhoToken.transferFrom(msg.sender, address(this), receipts[bookingsCount].rhoAmount);
        kappaToken.transferFrom(msg.sender, address(this), computedKappaAmount);
        gammaToken.transferFrom(msg.sender, address(this), computedGammaAmount);
        xiToken.transferFrom(msg.sender, address(this), receipts[bookingsCount].xiAmount);
        
        bookingsCount++;
    }

    /**
     * @dev Called by the user to cancel a submission before validation has been made
     * Tokens are then returned to the user
     * @param id ID of the booking to cancel. The address canceling must be the same as the one which created the submission
    */
    function cancelSubmission(uint256 id) external {
        require(bookings[id].owner == msg.sender, "XiSpace: Access denied");
        require(bookings[id].validated == false, "XiSpace: Already validated");
        require(receipts[id].xiAmount > 0, "XiSpace: Booking not found");
        // Transfer the tokens back to the user
        _moveTokens(id, msg.sender);
        delete bookings[id];
        delete receipts[id];
        emit CANCELLED(id);
    }

    /**
     * @dev Called by the validator: Accept or reject a booking submission
     * In case of rejection, tokens could be refunded, in case of acceptance the tokens are sent to treasury
     * @param id ID of the submission to validate
     * @param accept True to accept the submission, false to reject it
     * @param returnFunds True if the validator choses to return user funds
    */
    function validate(uint256 id, bool accept, bool returnFunds) external onlyRole(VALIDATOR_ROLE) {
        require(bookings[id].validated == false, "XiSpace: Already validated");
        if(accept) {
            // Transfer the tokens to the treasury
            _moveTokens(id, treasury);
            bookings[id].validated = true;
            emit BOOKED(id);
        } else {
            if(returnFunds) {
                // Transfer the tokens back to the user
                _moveTokens(id, bookings[id].owner);
            } else {
                // Transfer the tokens to the treasury
                _moveTokens(id, treasury);
            }
            
            delete bookings[id];
            delete receipts[id];
            emit REJECTED(id, returnFunds);
        }

    }

    /**
     * @dev Moves all 5 tokens from this contract to any destination
     * @param id ID of the submission to move the tokens of
     * @param destination Address to send the tokens to
    */
    function _moveTokens(uint256 id, address destination) internal {
        Receipt memory receipt = receipts[id];
        betaToken.transfer(destination, receipt.betaAmount);
        rhoToken.transfer(destination, receipt.rhoAmount);
        kappaToken.transfer(destination, receipt.kappaAmount);
        gammaToken.transfer(destination, receipt.gammaAmount);
        xiToken.transfer(destination, receipt.xiAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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