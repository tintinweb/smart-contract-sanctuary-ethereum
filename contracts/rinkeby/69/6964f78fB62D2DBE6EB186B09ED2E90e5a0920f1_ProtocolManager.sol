// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Fluent Protocol Manager
/// @author Fluent Group - Development team
/// @dev This contract has management functions over the Fluent USD+ and the Redeemer

import "./Redeemer.sol";
import "./IUSDPlusMinter.sol";
import "./IUSDPlusBurner.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ProtocolManager is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct FedMemberRedeemers {
        bool added;
        address[] redeemers;
    }

    mapping(address => FedMemberRedeemers) fedMembersRedeemers;
    address fluentUSDPlusAddress;
    address public USDPlusMinterAddr;
    address public USDlusBurnerAddr;

    constructor(
        address _fluentUSDPlusAddress,
        address _USDPlusMinterAddr,
        address _USDlusBurnerAddr
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        fluentUSDPlusAddress = _fluentUSDPlusAddress;
        USDPlusMinterAddr = _USDPlusMinterAddr;
        USDlusBurnerAddr = _USDlusBurnerAddr;
    }

    function pause() 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setUSDPlusMinterAddress(address _USDPlusMinterAddr)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        USDPlusMinterAddr = _USDPlusMinterAddr;
    }

    function setUSDlusBurnerAddress(address _USDlusBurnerAddr)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        USDlusBurnerAddr = _USDlusBurnerAddr;
    }

    /// @notice Add a new Federation Member to this solution
    /// @dev this deploy a new instance of Redeemer Contract
    /// @param fedMemberId The address that represents this member
    function addNewFedMember(address fedMemberId)
        external
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address)
    {
        require(
            !fedMembersRedeemers[fedMemberId].added,
            "FEDMEMBER ALREADY ADDED"
        );

        Redeemer newRedeemer = new Redeemer(
            fluentUSDPlusAddress,
            USDlusBurnerAddr,
            fedMemberId
        );

        fedMembersRedeemers[fedMemberId].added = true;
        fedMembersRedeemers[fedMemberId].redeemers.push(address(newRedeemer));

        IUSDPlusMinter(USDPlusMinterAddr).toGrantRole(fedMemberId);
        IUSDPlusBurner(USDlusBurnerAddr).toGrantRole(address(newRedeemer));
        return address(newRedeemer);
    }

    /// @notice Add a new Redeemer contract to an existing Federation Member
    /// @dev this deploy a new instance of Redeemer Contract and links it to a Fed Member
    /// @param fedMemberId The address that represents this member
    /// Discussion: This function could be called from the FedMembers Account, once we set a role for it
    function addNewRedeemer(address fedMemberId)
        external 
        whenNotPaused 
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address)
    {
        require(fedMembersRedeemers[fedMemberId].added, "FEDMEMBER NOT ADDED");

        Redeemer newRedeemer = new Redeemer(
            fluentUSDPlusAddress,
            USDlusBurnerAddr,
            fedMemberId
        );
        fedMembersRedeemers[fedMemberId].redeemers.push(address(newRedeemer));

        IUSDPlusBurner(USDlusBurnerAddr).toGrantRole(address(newRedeemer));

        return address(newRedeemer);
    }

    /// @notice Return a list of redeemers based in a given Fed Member address
    ///         i.e. all redeemers that are linked to it
    /// @dev
    /// @param fedMemberId The address that represents this member
    function getRedeemers(address fedMemberId)
        external
        view
        returns (address[] memory)
    {
        return fedMembersRedeemers[fedMemberId].redeemers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IUSDPlusBurner.sol";
import "./IFluentUSDPlus.sol";

/// @title Federation member´s Contract for redeem balance
/// @author Fluent Group - Development team
/// @notice Use this contract for request US dollars back
/// @dev
contract Redeemer is Pausable, AccessControl {
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");

    address public fedMemberId;
    address public USDlusBurnerAddr;
    address public fluentUSDPlusAddress;
    
    struct BurnTicket {
        bytes32 refId;
        address from;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool status;
        bool approved;
        bool burned;
    }

    /// @dev _refId => ticket
    mapping(bytes32 => BurnTicket) burnTickets;

    /// @dev _refId => bool
    mapping(bytes32 => bool) public rejectedAmount;

    /// @dev Array of _refId
    bytes32[] public _refIds;

    constructor(address _fluentUSDPlusAddress, address _USDlusBurnerAddr, address _fedMemberId) {
        require(_USDlusBurnerAddr != address(0x0), 'ZERO Addr is not allowed');
        require(_fedMemberId != address(0x0), 'ZERO Addr is not allowed');

        _grantRole(DEFAULT_ADMIN_ROLE, _fedMemberId);
        _grantRole(APPROVER_ROLE, _fedMemberId);
        _grantRole(PAUSER_ROLE, _fedMemberId);

        fluentUSDPlusAddress = _fluentUSDPlusAddress;
        USDlusBurnerAddr = _USDlusBurnerAddr;
        fedMemberId = _fedMemberId;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Entry point to a user request redeem their USD+ back to FIAT
    /// @dev
    /// @param amount The requested amount
    /// @param refId The Ticket Id generated in Core Banking System
    function requestRedeem(uint256 amount, bytes32 refId)
        external
        onlyRole(USER_ROLE)
        whenNotPaused
        returns (bool isRequestPlaced)
    {
        require(
            IERC20(fluentUSDPlusAddress).balanceOf(msg.sender) >= amount,
            "NOT_ENOUGH_BALANCE"
        );
        require(
            IERC20(fluentUSDPlusAddress).allowance(msg.sender, address(this)) >=
                amount,
            "NOT_ENOUGH_ALLOWANCE"
        );
        
        require(!burnTickets[refId].status, "ALREADY_USED_REFID");

        BurnTicket memory ticket = BurnTicket({
            refId: refId,
            from: msg.sender,
            amount: amount,
            placedBlock: block.number,
            confirmedBlock: 0,
            status: true,
            approved: false,
            burned: false });

        _refIds.push(refId);
        burnTickets[refId] = ticket;

        require(
            IERC20(fluentUSDPlusAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ), "FAIL_TRANSFER"
        );

        return true;
    }

    /// @notice Set a Ticket to approved or not approved
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    /// @param isApproved boolean condition for this Ticket
    function approveTickets(bytes32 refId, bool isApproved)
        external
        onlyRole(APPROVER_ROLE)
    {

        BurnTicket memory ticket = burnTickets[refId];
        require(ticket.status, "INVALID_TICKED_ID");
        require(!ticket.approved, "TICKED_ALREADY_APPROVED");

        if (isApproved) {
            _approvedTicket(refId);
        } else {
            rejectedAmount[refId] = true;
        }
    }

    /// @notice Set a Ticket to approved and send it to USD+
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    function _approvedTicket(bytes32 refId)
        internal
        onlyRole(APPROVER_ROLE)
        whenNotPaused
        returns (bool isTicketApproved)
    {
        BurnTicket storage ticket = burnTickets[refId];

        ticket.approved = true;

        
            IUSDPlusBurner(USDlusBurnerAddr).requestBurnUSDPlus(
                ticket.refId,
                address(this),
                ticket.from,
                fedMemberId,
                ticket.amount
            );
        

        require(
            IFluentUSDPlus(fluentUSDPlusAddress).increaseAllowance(USDlusBurnerAddr, ticket.amount),
            "INCREASE_ALLOWANCE_FAIL");
        
        return true;
    }

    /// @notice Allows the FedMember give a destination for a seized value
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    /// @param recipient The target address where the values will be addressed
    function transferRejectedAmounts(bytes32 refId, address recipient)
        external
        onlyRole(APPROVER_ROLE)
        whenNotPaused
    {
        require(rejectedAmount[refId], "Not a rejected refId");

        BurnTicket memory ticket = burnTickets[refId];

        rejectedAmount[refId] = false;
        require(
            IERC20(fluentUSDPlusAddress).transfer(recipient, ticket.amount), "FAIL_TRANSFER"
        );
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    function getBurnReceiptById(bytes32 refId)
        external
        view
        returns (BurnTicket memory)
    {
        return burnTickets[refId];
    }

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    function getBurnStatusById(bytes32 refId)
        external
        view
        returns (
            bool,
            bool,
            bool,
            uint256
        )
    {
        if (burnTickets[refId].status) {
            return (
                burnTickets[refId].status,
                burnTickets[refId].approved,
                burnTickets[refId].burned,
                burnTickets[refId].confirmedBlock
            );
        } else {
            return (false, false, false, 0);
        }
    }

    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUSDPlusMinter {
    struct MintTicket {
        bytes32 ID;
        address from;
        address to;
        uint256 amount;
        uint256 placedBlock;
        bool status;
        bool executed;
    }

    /// @notice Creates a ticket to request a amount of USD+ to mint
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    /// @param amount The amount of USD+ to be minted
    /// @param to The destination address
    function requestMint(
        bytes32 id,
        uint256 amount,
        address to
    ) external returns (bool retRequestMint);

    /// @notice Mints the amount of USD+ defined in the ticket
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function mint(bytes32 id) external returns (bool retMint, address retTo, uint256 retAmount);

    /// @notice Returns a ticket structure
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getMintReceiptById(bytes32 id)
        external
        view
        returns (MintTicket memory);

    /// @notice Returns Status, Execution Status and the Block Number when the mint occurs
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getMintStatusById(bytes32 id) external view returns (bool, bool);

    function toGrantRole(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUSDPlusBurner {
    struct BurnTicket {
        bytes32 refId;
        address redeemerContractAddress;
        address redeemerPerson;
        address fedMemberID;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool status;
        bool executed;
    }

    ///@dev arrays of refIds
    struct BurnTicketId {
        bytes32 refId;
        address fedMemberId;
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnReceiptById(bytes32 id)
        external
        view
        returns (BurnTicket memory);

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnStatusById(bytes32 id)
        external
        view
        returns (
            bool,
            bool,
            uint256
        );

    /// @notice Execute transferFrom Executer Acc to this contract, and open a burn Ticket
    /// @dev to match the id the fields should be (burnCounter, _refNo, amount, msg.sender)
    /// @param refId Ref Code provided by customer to identify this request
    /// @param redeemerContractAddress The Federation Member´s REDEEMER contract
    /// @param redeemerPerson The person who is requesting USD Redeem
    /// @param fedMemberID Identification for Federation Member
    /// @param amount The amount to be burned
    /// @return isRequestPlaced confirmation if Function gets to the end without revert
    function requestBurnUSDPlus(
        bytes32 refId,
        address redeemerContractAddress,
        address redeemerPerson,
        address fedMemberID,
        uint256 amount
    ) external returns (bool isRequestPlaced);

    /// @notice Burn the amount of USD+ defined in the ticket
    /// @dev Be aware that burnID is formed by a hash of (mapping.burnCounter, mapping._refNo, amount, _redeemBy), see requestBurnUSDPlus method
    /// @param refId Burn TicketID
    /// @param redeemerContractAddress address from the amount get out
    /// @param fedMemberId Federation Member ID
    /// @param amount Burn amount requested
    /// @return isAmountBurned confirmation if Function gets to the end without revert
    function executeBurn(
        bytes32 refId,
        address redeemerContractAddress,
        address fedMemberId,
        uint256 amount,
        address vault
    ) external returns (bool isAmountBurned);

    /// @notice gives Redeemer permission to request burn
    /// @dev
    /// @param redeemerAddr The address where the USDPlus was deployed
    function setRedeemerAccess(address redeemerAddr) external;

    function toGrantRole(address _to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
pragma solidity ^0.8.10;

interface IFluentUSDPlus {
    function burn(uint256 amount) external;
    function mint(address to, uint amount) external returns(bool);
    function increaseAllowance(address spender, uint addedValue) external returns(bool);
    function burnFrom(address account, uint amount) external;
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