// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {Types} from "./types/Types.sol";

import {IDrawing} from "./interfaces/IDrawing.sol";
import {IHedgehogToken} from "./interfaces/IHedgehogToken.sol";

contract Drawing is AccessControl, IDrawing {
    bytes32 internal immutable DRAWING_ID;
    string  internal DRAWING_NAME;
    uint256 internal immutable TICKET_PRICE;
    uint256 internal immutable PRIZE_PERCENTAGE;
    uint256 internal immutable DRAWING_DATE;
    uint256 internal immutable MINIMUM_PRIZE;

    address internal immutable COORDINATOR;

    IHedgehogToken public immutable HEDGEHOG_TOKEN;

    uint256 internal TICKET_COUNT = 0;

    bool internal ACTIVE;
    bool internal WINNER_CHOSEN;

    Types.DrawingTicket internal WINNING_TICKET;

    mapping(bytes32 => Types.DrawingTicket) internal TICKETS;
    bytes32[] internal TICKET_IDS;

    bytes32 public constant ADMIN_ROLE       = keccak256("ADMIN");
    bytes32 public constant COORDINATOR_ROLE = keccak256("COORDINATOR");

    constructor(
        bytes32 _drawingId,
        string memory _drawingName,
        uint256 _ticketPrice,
        uint256 _prizePercentage,
        uint256 _drawingDate,
        uint256 _minimumPrize,
        IHedgehogToken _hedgehogToken,
        address[] memory _admins,
        address _coordinator
    )
    {
        DRAWING_ID       = _drawingId;
        DRAWING_NAME     = _drawingName;
        PRIZE_PERCENTAGE = _prizePercentage;
        DRAWING_DATE     = _drawingDate;
        TICKET_PRICE     = _ticketPrice;
        MINIMUM_PRIZE    = _minimumPrize;
        HEDGEHOG_TOKEN   = _hedgehogToken;
        COORDINATOR      = _coordinator;

        for (uint i = 0; i < _admins.length; i++) {
            _setupRole(ADMIN_ROLE, _admins[i]);
        }

        _setupRole(COORDINATOR_ROLE, _coordinator);

        emit DrawingCreated(
            _drawingId,
            _drawingName,
            _drawingDate,
            _ticketPrice,
            _minimumPrize
        );
    }

    modifier onlyAdmin
    {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "must be an admin to call this function"
        );

        _;
    }

    modifier onlyCoordinator
    {
        require(
            hasRole(COORDINATOR_ROLE, msg.sender),
            "must be the Coordinator to call this function"
        );

        _;
    }

    modifier afterDrawingDate
    {
        require(
            block.timestamp >= DRAWING_DATE,
            "can only call this function at or after drawing date"
        );

        _;
    }

    function drawingId()
        external
        view
        returns (bytes32)
    {
        return DRAWING_ID;
    }

    function drawingName()
        external
        view
        returns (string memory)
    {
        return DRAWING_NAME;
    }

    function ticketPrice()
        external
        view
        returns (uint256)
    {
        return TICKET_PRICE;
    }

    function ticketCount()
        external
        view
        returns (uint256)
    {
        return TICKET_COUNT;
    }

    function minimumPrize()
        external
        view
        returns (uint256)
    {
        return MINIMUM_PRIZE;
    }

    function drawingDate()
        external
        view
        returns (uint256)
    {
        return DRAWING_DATE;
    }

    function grandPrize()
        external
        view
        returns (uint256)
    {
        return _grandPrize();
    }

    function active()
        external
        view
        returns (bool)
    {
        return ACTIVE;
    }

    function winnerChosen()
        external
        view
        returns (bool)
    {
        return WINNER_CHOSEN;
    }

    function winningTicket()
        external
        view
        returns (Types.DrawingTicket memory, bool)
    {
        return (WINNING_TICKET, WINNER_CHOSEN);
    }

    function drawingInfo()
        external
        view
        returns (Types.DrawingInfo memory)
    {
        return Types.DrawingInfo({
            drawingId:          DRAWING_ID,
            drawingName:        DRAWING_NAME,
            drawingDate:        DRAWING_DATE,
            ticketPrice:        TICKET_PRICE,
            prizePercentage:    PRIZE_PERCENTAGE,
            minimumPrize:       MINIMUM_PRIZE,
            currentGrandPrize:  _grandPrize(),
            ticketCount:        TICKET_COUNT,
            _address:           address(this),
            active:             ACTIVE,
            winnerChosen:       WINNER_CHOSEN
        });
    }

    function getTicket(bytes32 ticketId)
        external
        view
        returns (Types.DrawingTicket memory, bool)
    {
        Types.DrawingTicket storage _ticket = TICKETS[ticketId];
        if (_ticket.account == address(0)) {
            return (_ticket, false);
        }

        return (_ticket, true);
    }

    function buyTicket()
        external
        returns (Types.DrawingTicket memory)
    {
        address _buyer = msg.sender;

        _buyTicket(_buyer);

        ++TICKET_COUNT;
        uint256 ticketNumber = TICKET_COUNT;
        bytes32 ticketId = keccak256(abi.encodePacked(_buyer, DRAWING_ID, block.timestamp, ticketNumber));

        TICKETS[ticketId] = Types.DrawingTicket({
            account:      _buyer,
            ticketId:     ticketId,
            drawingId:    DRAWING_ID,
            ticketNumber: ticketNumber,
            ticketPrice:  TICKET_PRICE
        });

        TICKET_IDS.push(ticketId);

        emit TicketPurchase(
            _buyer,
            DRAWING_ID,
            ticketId,
            ticketNumber,
            TICKET_PRICE
        );

        return TICKETS[ticketId];
    }

    function _buyTicket(address _buyer)
        internal
    {
        address _thisAddr = address(this);
        IERC20 _hhog = IERC20(address(HEDGEHOG_TOKEN));

        require(
            _hhog.allowance(_buyer, _thisAddr) >= TICKET_PRICE,
            "insufficient HHOG allowance, call approve() or permit()"
        );

        require(
            _hhog.balanceOf(_buyer) >= TICKET_PRICE,
            "insufficient HHOG balance"
        );

        require(
            _hhog.transferFrom(_buyer, _thisAddr, TICKET_PRICE),
            "payment failed"
        );
    }

    function drawWinningTicket()
        external
        onlyAdmin
        afterDrawingDate
    {
        Types.DrawingTicket memory _winningTicket = _pickWinner();
        IERC20 _hhog = IERC20(address(HEDGEHOG_TOKEN));

        address _thisAddr = address(this);
        uint256 _gpAmt    = _grandPrize();
        uint256 _hogBal   = _hhog.balanceOf(_thisAddr);

        require(
             _hogBal >= _gpAmt,
            "insufficient HHOG balance for awarding grand prize"
        );

        emit WinnerPicked(
            DRAWING_ID,
            _winningTicket.account,
            _winningTicket.ticketId,
            _gpAmt
        );

        require(
            _hhog.transfer(_winningTicket.account, _gpAmt),
            "grand prize transfer failed"
        );

        uint256 _returnAmt = _hogBal-_gpAmt;

        require(
            _hhog.transferFrom(_thisAddr, COORDINATOR, _returnAmt),
            "transfer of remaining HHOG failed"
        );

        ACTIVE = false;
        WINNER_CHOSEN = true;
        WINNING_TICKET = _winningTicket;
    }

    function destroy()
        external
        onlyCoordinator
    {
        selfdestruct(payable(COORDINATOR));
    }

    function _grandPrize()
        internal
        view
        returns (uint256)
    {
        uint256 _gp = _calculateGrandPrize();
        if (MINIMUM_PRIZE > _gp) {
            return MINIMUM_PRIZE;
        }

        return _gp;
    }

    function _calculateGrandPrize()
        internal
        view
        returns (uint256)
    {
        return (TICKET_PRICE * TICKET_COUNT) * PRIZE_PERCENTAGE / 100;
    }

    function _pickWinner()
        internal
        view
        returns (Types.DrawingTicket storage)
    {
        bytes32 _randHash = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        uint32 _randIdx = uint32(uint256(_randHash) % TICKET_COUNT);

        return TICKETS[TICKET_IDS[_randIdx]];
    }
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
pragma solidity ^0.8.11;

library Types {
    /**
     * @dev DrawingTicket contains data about a ticket for a
     * drawing purchased by a given user.
     */
    struct DrawingTicket {
        // @dev account is the address of the user who purchased the ticket.
        address account;
        // @dev ticketId is the ID of this ticket,
        // and is the result of keccak256(abi.encodePacked(account, drawingId, block.timestamp, ticketNumber)).
        bytes32 ticketId;
        // @dev drawingId is the ID of the drawing this ticket is for.
        bytes32 drawingId;
        // @dev ticketNumber is the sequential number of this ticket.
        uint256 ticketNumber;
        // @dev ticketPrice is the price paid for this ticket.
        uint256 ticketPrice;
    }

    struct DrawingInfo {
        bytes32 drawingId;
        string  drawingName;
        uint256 drawingDate;
        uint256 ticketPrice;
        uint256 prizePercentage;
        uint256 minimumPrize;
        uint256 currentGrandPrize;
        uint256 ticketCount;
        address _address;
        bool    active;
        bool    winnerChosen;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IHedgehogToken} from "./IHedgehogToken.sol";

import {Types} from "../types/Types.sol";

interface IDrawing {
    /**
     * Emitted when a Drawing contract is successfully created.
     */
    event DrawingCreated(
        bytes32 indexed drawingId,
        string  indexed drawingName,
        uint256 indexed drawingDate,
        uint256 ticketPrice,
        uint256 minimumPrize
    );

    /**
     * Emitted when a user purchases a ticket for a Drawing.
     */
    event TicketPurchase(
        address indexed account,
        bytes32 indexed drawingId,
        bytes32 ticketId,
        uint256 ticketNumber,
        uint256 ticketPrice
    );

    /**
     * Emitted when drawWinningTicket() is called and a winner is chosen
     * from the pool of purchased tickets.
     */
    event WinnerPicked(
        bytes32 indexed drawingId,
        address indexed account,
        bytes32 indexed ticketId,
        uint256 prizeAmount
    );

    /**
     * Returns the configured address of the HedgehogToken contract.
     * @dev when called from solidity, returns an IHedgehogToken. When
     * called from code (eg. JS, Go), returns an address.
     */
    function HEDGEHOG_TOKEN() external view returns (IHedgehogToken);

    /**
     * Returns the ID of a Drawing.
     * @dev a Drawing's ID is calculated before contract creation using
     * keccak256(abi.encodePacked(drawingName)).
     */
    function drawingId() external view returns (bytes32);

    /**
     * Returns the name of a Drawing.
     * A Drawing's name is entirely meaningless except for representation
     * purposes.
     */
    function drawingName() external view returns (string memory);

    /**
     * Returns the configured price of a ticket.
     */
    function ticketPrice() external view returns (uint256);

    /**
     * Returns the current number of tickets purchased for a Drawing.
     */
    function ticketCount() external view returns (uint256);

    /**
     * Returns the minimum prize amount a Drawing winner will receive,
     * if such a value was set at the creation of a Drawing.
     */
    function minimumPrize() external view returns (uint256);

    /**
     * Returns the date (as a unix timestamp) at which a Drawing can have drawWinningTicket() called.
     */
    function drawingDate() external view returns (uint256);

    /**
     * Returns the current grand prize amount for a Drawing,
     * which is a function of MAX(((TICKET_PRICE * TICKET_COUNT) * PRIZE_PERCENTAGE), MINIMUM_PRIZE).
     */
    function grandPrize() external view returns (uint256);

    /**
     * Returns the active state of a Drawing.
     * Will always return true until drawWinningTicket() is called
     * and successfully "draws" a winning ticket.
     */
    function active() external view returns (bool);

    /**
     * Returns whether a winning ticket has been chosen.
     */
    function winnerChosen() external view returns (bool);

    /**
     * winningTicket returns the winning ticket drawn, if one has been drawn.
     * The returned boolean indicates whether a winning ticket has been drawn.
     */
    function winningTicket() external view returns (Types.DrawingTicket memory, bool);

    /**
     * Returns information about a Drawing.
     */
    function drawingInfo() external view returns (Types.DrawingInfo memory);

    /**
     * Returns information about a purchased ticket with the passed ID.
     * The returned boolean indicates whether a ticket with the passed ID was found.
     * @param ticketId ID of the purchased ticket.
     */
    function getTicket(bytes32 ticketId) external view returns (Types.DrawingTicket memory, bool);

    /**
     * Allows a user to purchase a ticket for this drawing.
     */
    function buyTicket() external returns (Types.DrawingTicket memory);

    /**
     * Draws a ticket from the pool of purchased tickets, and transfers
     * the grand prize amount to the address associated with that ticket.
     * @notice Any remaining token amount leftover after transfer of the grand
     * prize amount to the winner is returned to the Drawing's Coordinator contract.
     * @notice Upon successful drawing and transfers, the Drawing is set as "inactive",
     * and all calls to active() will return false.
     */
    function drawWinningTicket() external;

    /**
     * Destroys this drawing on-chain via selfdestruct().
     * @dev This function can only be called by the Drawing's Coordinator contract.
     */
    function destroy() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHedgehogToken is IERC20 {
    function mint(address to, uint256 amount) external;
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