// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface Rain_Interface {
    function isAccountFrozen(address account) external view returns (bool);
}

contract Quest is Pausable, AccessControl {
    struct Feedback {
        bytes32 feedback_hash;
        bool GM_occurred;
        bool request_dispute;
    }

    struct Time_Keeper {
        uint256 respondTime;
        uint256 feedbackTime;
        uint256 requestDisputeTime;
        uint256 disputeExectueTime;
    }

    struct GM_DATA {
        address rm_lead;
        address su_address;
        bool rm_lead_proposed_this_gm;
        bytes32 gm_statement_hash;
        uint256 rm_lead_stake_required;
        uint256 su_stake_required;
        bool rm_lead_staked;
        bool su_staked;
        uint256 dispute_cost;
        bool rm_staked_dispute;
        bool su_staked_dispute;
        address[] participants;
        uint16[] gm_cap_table;
        uint256 feedback_deadline;
        Time_Keeper gm_times;
        bool agreed;
        Feedback rm_feedback;
        Feedback su_feedback;
        bool frozen_user;
        bool paused_contract;
    }

    modifier valid_index(uint8 gm_index) {
        require(gm_index < next_gm_index, "Not valid GM index");
        _;
    }

    modifier valid_user(address user, address rain_address) {
        Rain_Interface rain_interface = Rain_Interface(rain_address);
        require(
            rain_interface.isAccountFrozen(user) == false,
            "Address is frozen, please contact Admin to unfreeze"
        );
        _;
    }

    uint256 constant TIME_INTERVAL_ONE = 100000;
    uint256 constant TIME_INTERVAL_THREE = 300000;
    uint256 constant TIME_INTERVAL_FOUR = 300000;
    address constant ADMIN_ADDRESS = 0x99dbB9D1A7FFd38467F94443a9dEe088c6AB34B9;

    address public rain_token_address;
    address public rm_lead;
    address[] public su_multisigs;
    address[] public all_RMs;
    address public dispute_multisig;
    uint8 public next_gm_index;
    mapping(uint8 => GM_DATA) gm_list;
    mapping(address => bool) is_rm;

    event New_GM_Proposed(GM_DATA new_GM, address proposer);
    event GM_Agreed(
        uint256 indexed gm_index,
        GM_DATA updated_GM,
        address updater
    );
    event GM_Disagreed(
        uint256 indexed gm_index,
        GM_DATA updated_GM,
        address updater
    );
    event RM_Lead_Updated(address new_rm_lead);
    event Feedback_Submitted(
        uint256 indexed gm_index,
        Feedback submitted_feedback,
        address submitor,
        bool is_su,
        bool is_disputed
    );
    event GM_Withdrawed(
        uint256 indexed gm_index,
        address withdrawed_address,
        uint256 withdrawed_value
    );

    constructor(
        address _rm_lead,
        address[] memory _su_multisigs,
        address[] memory _all_RMs,
        address _rain_token_address,
        address _dispute_multisig
    ) {
        rm_lead = _rm_lead;
        su_multisigs = _su_multisigs;
        all_RMs = _all_RMs;
        next_gm_index = 0;
        rain_token_address = _rain_token_address;
        dispute_multisig = _dispute_multisig;

        for (uint256 i = 0; i < _all_RMs.length; i++) {
            is_rm[all_RMs[i]] = true;
        }

        _grantRole(DEFAULT_ADMIN_ROLE, ADMIN_ADDRESS);
    }

    function propose_new_GM(
        address _su_address,
        bytes32 _gm_statement_hash,
        uint256 _rm_lead_stake_required,
        uint256 _su_stake_required,
        uint256 _dispute_cost,
        address[] calldata _participants,
        uint16[] calldata _gm_cap_table,
        uint256 _feedback_deadline
    ) external {
        bool sender_is_su = false;

        for (uint256 i = 0; i < su_multisigs.length; i++) {
            if (msg.sender == su_multisigs[i]) {
                sender_is_su = true;
                break;
            }
        }

        require(
            msg.sender == rm_lead || sender_is_su == true,
            "Address is not allowed proposing new GM"
        );
        require(
            _participants.length == _gm_cap_table.length,
            "Length of participants and cap_table is not the same"
        );

        for (uint256 i = 0; i < _participants.length; i++) {
            require(is_rm[_participants[i]] == true, "participant is not RM");
        }

        Time_Keeper memory _gm_times = Time_Keeper(
            block.timestamp + TIME_INTERVAL_ONE,
            0,
            0,
            0
        );

        Feedback memory _default_feedback = Feedback(bytes32(0), false, false);

        GM_DATA memory new_GM;
        new_GM.rm_lead_stake_required = _rm_lead_stake_required;
        new_GM.su_stake_required = _su_stake_required;

        IERC20 rain_token = IERC20(rain_token_address);

        if (sender_is_su) {
            new_GM.rm_lead_proposed_this_gm = false;
            require(
                rain_token.balanceOf(msg.sender) >= _su_stake_required,
                "Address doesn't have enough rain token"
            );
            if (new_GM.su_stake_required > 0) {
                rain_token.transferFrom(
                    msg.sender,
                    address(this),
                    new_GM.su_stake_required
                );
            }
            new_GM.rm_lead_staked = false;
            new_GM.su_staked = true;
        } else {
            new_GM.rm_lead_proposed_this_gm = true;
            require(
                rain_token.balanceOf(msg.sender) >= _rm_lead_stake_required,
                "Address doesn't have enough rain token"
            );
            if (new_GM.rm_lead_stake_required > 0) {
                rain_token.transferFrom(
                    msg.sender,
                    address(this),
                    new_GM.rm_lead_stake_required
                );
            }
            new_GM.rm_lead_staked = true;
            new_GM.su_staked = false;
        }

        new_GM.rm_lead = rm_lead;
        new_GM.su_address = _su_address;
        new_GM.gm_statement_hash = _gm_statement_hash;
        new_GM.dispute_cost = _dispute_cost;
        new_GM.rm_staked_dispute = false;
        new_GM.su_staked_dispute = false;
        new_GM.participants = _participants;
        new_GM.gm_cap_table = _gm_cap_table;
        new_GM.gm_times = _gm_times;
        new_GM.agreed = false;
        new_GM.rm_feedback = _default_feedback;
        new_GM.su_feedback = _default_feedback;
        new_GM.frozen_user = false;
        new_GM.paused_contract = false;
        new_GM.feedback_deadline = _feedback_deadline;

        gm_list[next_gm_index] = new_GM;
        next_gm_index += 1;

        emit New_GM_Proposed(new_GM, msg.sender);
    }

    function submit_feedback(
        uint8 gm_index,
        bytes32 _feedback_hash,
        bool _GM_occurred,
        bool _request_dispute,
        bool is_su
    ) external valid_index(gm_index) {
        GM_DATA memory selected_GM = gm_list[gm_index];

        require(
            selected_GM.rm_lead_staked && selected_GM.su_staked,
            "The GM have not been accepted"
        );
        require(
            block.timestamp < selected_GM.gm_times.feedbackTime,
            "This GM is Lock"
        );
        if (
            selected_GM.rm_feedback.feedback_hash == bytes32(0) &&
            selected_GM.su_feedback.feedback_hash == bytes32(0)
        ) {
            if (
                selected_GM.gm_times.feedbackTime <
                block.timestamp + TIME_INTERVAL_THREE
            ) {
                selected_GM.gm_times.feedbackTime =
                    block.timestamp +
                    TIME_INTERVAL_THREE;
            }
        }

        if (is_su) {
            require(
                msg.sender == selected_GM.su_address,
                "Address is not allowed to submit feedback to GM"
            );
        } else {
            require(
                msg.sender == selected_GM.rm_lead,
                "Address is not allowed to submit feedback to GM"
            );
        }
        if (_request_dispute == true) {
            selected_GM.gm_times.requestDisputeTime =
                block.timestamp +
                TIME_INTERVAL_FOUR;
        }

        Feedback memory feedback = Feedback(
            _feedback_hash,
            _GM_occurred,
            _request_dispute
        );

        if (is_su) {
            selected_GM.rm_feedback = feedback;
        } else {
            selected_GM.su_feedback = feedback;
        }

        emit Feedback_Submitted(
            gm_index,
            feedback,
            msg.sender,
            is_su,
            _request_dispute
        );
    }

    function withdraw_rain(uint8 gm_index)
        external
        payable
        valid_index(gm_index)
    {
        GM_DATA memory selected_GM = gm_list[gm_index];
        require(
            msg.sender == selected_GM.su_address ||
                msg.sender == selected_GM.rm_lead,
            "Address is not allowed to withdraw rain token to GM"
        );
        IERC20 rain_token = IERC20(rain_token_address);
        if (msg.sender == selected_GM.su_address) {
            require(
                selected_GM.su_staked == true,
                "Can not withdraw rain token: Address has not staked before"
            );
            require(
                rain_token.balanceOf(address(this)) >
                    selected_GM.su_stake_required,
                "Can not withdraw: Contract doesn't have enough rain token"
            );
            rain_token.transfer(msg.sender, selected_GM.su_stake_required);
            selected_GM.su_staked = false;
            emit GM_Withdrawed(
                gm_index,
                msg.sender,
                selected_GM.su_stake_required
            );
        } else {
            require(
                selected_GM.rm_lead_staked == true,
                "Can not withdraw rain token: Address has not staked before"
            );
            require(
                rain_token.balanceOf(address(this)) >
                    selected_GM.rm_lead_stake_required,
                "Can not withdraw: Contract doesn't have enough rain token"
            );
            rain_token.transfer(msg.sender, selected_GM.rm_lead_stake_required);
            selected_GM.rm_lead_staked = false;
            emit GM_Withdrawed(
                gm_index,
                msg.sender,
                selected_GM.rm_lead_stake_required
            );
        }
    }

    function agree_GM(uint8 gm_index) external valid_index(gm_index) {
        GM_DATA memory selected_GM = gm_list[gm_index];
        IERC20 rain_token = IERC20(rain_token_address);

        require(
            block.timestamp < selected_GM.gm_times.respondTime,
            "This GM is Locked"
        );
        require(
            msg.sender == rm_lead || msg.sender == selected_GM.su_address,
            "Address is not allowed to agree the GM"
        );
        if (selected_GM.rm_lead_proposed_this_gm) {
            require(
                msg.sender != selected_GM.rm_lead,
                "Address is the proposer of the GM"
            );
            require(
                rain_token.balanceOf(msg.sender) >
                    selected_GM.rm_lead_stake_required,
                "Address doesn't have enough rain token"
            );
            rain_token.transferFrom(
                msg.sender,
                address(this),
                selected_GM.rm_lead_stake_required
            );
        } else {
            require(
                msg.sender != selected_GM.su_address,
                "Address is the proposer of the GM"
            );
            require(
                rain_token.balanceOf(msg.sender) >
                    selected_GM.su_stake_required,
                "Address doesn't have enough rain token"
            );
            rain_token.transferFrom(
                msg.sender,
                address(this),
                selected_GM.su_stake_required
            );
        }

        selected_GM.agreed = true;
        selected_GM.gm_times.feedbackTime =
            block.timestamp +
            selected_GM.feedback_deadline;
        gm_list[gm_index] = selected_GM;

        emit GM_Agreed(gm_index, selected_GM, msg.sender);
    }

    function disagree_GM(uint8 gm_index) external valid_index(gm_index) {
        GM_DATA memory selected_GM = gm_list[gm_index];
        require(
            msg.sender == selected_GM.rm_lead ||
                msg.sender == selected_GM.su_address,
            "Address is not allowed to disagree the GM"
        );
        selected_GM.agreed = false;
        gm_list[gm_index] = selected_GM;
        emit GM_Disagreed(gm_index, selected_GM, msg.sender);
    }

    function transfer_rm_lead(address _new_rm_lead) external {
        require(
            msg.sender == rm_lead || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Can not transfer rm_lead, you are not current rm lead or Admin"
        );
        rm_lead = _new_rm_lead;
        emit RM_Lead_Updated(_new_rm_lead);
    }

    // function get_gm_time(uint8 gm_index) external valid_index(gm_index) return (respond_time, feedback_time, dispute_time){

    // }

    function pause() external whenNotPaused {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Can not pause: address are not ADMIN"
        );
        _pause();
    }

    function unpause() external whenPaused {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Can not pause: address are not ADMIN"
        );
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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