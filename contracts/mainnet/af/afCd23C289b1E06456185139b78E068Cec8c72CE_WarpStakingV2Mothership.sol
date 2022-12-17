// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./WarpStakingV2.sol";
import "./WarpStakingV2ChildCreator.sol";

contract WarpStakingV2Mothership is AccessControl, Pausable {
    using SafeMath for uint256;

    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");
    bytes32 public constant CHILD_MANAGER_ROLE =
        keccak256("CHILD_MANAGER_ROLE");
    bytes32 public constant FUNDS_MANAGER_ROLE =
        keccak256("FUNDS_MANAGER_ROLE");
    bytes32 public constant CHILD_ROLE = keccak256("CHILD_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _fundsWithdrawReceiver;

    address private _feeReceiver;
    uint256 private _baseFee; // denom = 10000 ; eg. 0.25% = 25 / denom
    uint256 private _nativeFee; // BNB

    WarpStakingV2ChildCreator private _childCreator;

    WarpStakingV2[] private _stakingContracts;
    mapping(address => uint256) private _stakingContractIndexes;

    mapping(address => uint256) private _stakingContractDeposits;
    mapping(address => uint256) private _stakingContractHarvests;

    constructor(
        address admin_,
        address fundsWithdrawReceiver_,
        address feeReceiver_,
        uint256 baseFee_,
        uint256 nativeFee_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        _grantRole(SETTINGS_ROLE, admin_);
        _grantRole(RESCUER_ROLE, admin_);
        _grantRole(FUNDS_MANAGER_ROLE, admin_);
        _grantRole(CHILD_MANAGER_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);

        _childCreator = new WarpStakingV2ChildCreator(address(this));
        _fundsWithdrawReceiver = fundsWithdrawReceiver_;
        _feeReceiver = feeReceiver_;
        _baseFee = baseFee_;
        _nativeFee = nativeFee_;
    }

    /// @notice Return fee receiver
    function fundsWithdrawReceiver() public view returns (address) {
        return _fundsWithdrawReceiver;
    }

    /// @notice Return fee receiver
    function feeReceiver() public view returns (address) {
        return _feeReceiver;
    }

    /// @notice Return base fee
    function baseFee() public view returns (uint256) {
        return _baseFee;
    }

    /// @notice Return native fee
    function nativeFee() public view returns (uint256) {
        return _nativeFee;
    }

    /// @notice Return current child creator
    function childCreator() public view returns (WarpStakingV2ChildCreator) {
        return _childCreator;
    }

    /// @notice Return all WarpStaking contract managed by mothership
    function stakingContracts() public view returns (WarpStakingV2[] memory) {
        return _stakingContracts;
    }

    /// @notice Childs current deposit in child stake token
    function childsCurrentDeposit(address child_)
        public
        view
        returns (uint256 deposit)
    {
        return _stakingContractDeposits[child_];
    }

    /// @notice Childs total harvests in child reward token
    function childsTotalHarvest(address child_)
        public
        view
        returns (uint256 deposit)
    {
        return _stakingContractHarvests[child_];
    }

    function updateFundsWithdrawReceiver(address fundsWithdrawReceiver_)
        public
        onlyRole(SETTINGS_ROLE)
    {
        _fundsWithdrawReceiver = fundsWithdrawReceiver_;
    }

    function updateBaseFee(uint256 baseFee_) public onlyRole(SETTINGS_ROLE) {
        _baseFee = baseFee_;
    }

    function updateNativeFee(uint256 nativeFee_) public onlyRole(SETTINGS_ROLE) {
        _nativeFee = nativeFee_;
    }

    function updateFeeReceiver(address feeReceiver_)
        public
        onlyRole(SETTINGS_ROLE)
    {
        _feeReceiver = feeReceiver_;
    }

    /// @notice Create a new WarpStaking contract
    /// @dev New WarpStaking contract generated with the _childCreator
    function addWarpStaking(
        IERC20 token_,
        IERC20 rewardToken_,
        IPancakePair lp_,
        string memory name_,
        string memory symbol_,
        uint256 apr_,
        uint256 period_,
        bytes memory data
    ) public onlyRole(CHILD_MANAGER_ROLE) returns (WarpStakingV2) {
        require(
            address(_childCreator) != address(0),
            "WSM: Missing child creator"
        );
        WarpStakingV2 newContract = _childCreator.newWarpStaking(
            token_,
            rewardToken_,
            lp_,
            name_,
            symbol_,
            apr_,
            period_,
            data
        );
        address contractAddress = address(newContract);
        _stakingContractIndexes[contractAddress] = _stakingContracts.length;
        _stakingContracts.push(newContract);

        _grantRole(CHILD_ROLE, contractAddress);

        emit WarpStakingAdded(contractAddress);

        return newContract;
    }

    /// @notice Add an already existing WarpStaking contract
    /// @param warpStaking_ contract which already exists
    function addExistingWarpStaking(WarpStakingV2 warpStaking_)
        public
        onlyRole(CHILD_MANAGER_ROLE)
    {
        require(
            address(warpStaking_) != address(0),
            "WSM: Cant be null address"
        );

        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            require(
                address(_stakingContracts[i]) != address(warpStaking_),
                "WSM: Already added"
            );
        }
        _stakingContractIndexes[address(warpStaking_)] = _stakingContracts
            .length;
        _stakingContracts.push(warpStaking_);

        warpStaking_.setMother(this);

        _grantRole(CHILD_ROLE, address(warpStaking_));

        emit WarpStakingAdded(address(warpStaking_));
    }

    /// @notice Remove a WarpStaking contract from the mothership
    /// @param staking_ contract to remove from mothership
    function removeStakingContract(WarpStakingV2 staking_)
        public
        onlyRole(CHILD_MANAGER_ROLE)
    {
        uint256 index = _stakingContractIndexes[address(staking_)];
        require(
            index >= 0 && index < _stakingContracts.length,
            "WSM: Invalid staking contract"
        );
        require(
            address(_stakingContracts[index]) == address(staking_),
            "WSM: Address mismatch"
        );

        uint256 newIndex = _stakingContracts.length - 1;
        _stakingContractIndexes[address(_stakingContracts[newIndex])] = index;
        _stakingContracts[index] = _stakingContracts[newIndex];
        _stakingContracts.pop();

        _revokeRole(CHILD_ROLE, address(staking_));

        delete _stakingContractIndexes[address(staking_)];
        emit WarpStakingRemoved(address(staking_));
    }

    /// @notice Update the WarpStaking creator contract
    /// @param childCreator_ the new WarpStaking creator
    function updateChildCreator(WarpStakingV2ChildCreator childCreator_)
        public
        onlyRole(CHILD_MANAGER_ROLE)
    {
        _childCreator = childCreator_;
        emit ChildCreatorUpdated(address(_childCreator));
    }

    function childDeposit(uint256 amount_) public onlyRole(CHILD_ROLE) {
        WarpStakingV2 child = WarpStakingV2(msg.sender);
        IERC20 token = IERC20(child.token());

        token.transferFrom(msg.sender, address(this), amount_);

        uint256 newDepositAmount = _stakingContractDeposits[msg.sender].add(
            amount_
        );
        _stakingContractDeposits[msg.sender] = _stakingContractDeposits[
            msg.sender
        ].add(amount_);
        token.approve(msg.sender, newDepositAmount);
    }

    function childHarvest(uint256 amount_)
        public
        onlyRole(CHILD_ROLE)
        whenNotPaused
    {
        WarpStakingV2 child = WarpStakingV2(msg.sender);
        IERC20 rewardToken = IERC20(child.rewardToken());

        rewardToken.transfer(msg.sender, amount_);
        _stakingContractHarvests[msg.sender] = _stakingContractHarvests[
            msg.sender
        ].add(amount_);
    }

    function childWithdraw(uint256 amount_)
        public
        onlyRole(CHILD_ROLE)
        whenNotPaused
    {
        WarpStakingV2 child = WarpStakingV2(msg.sender);
        IERC20 token = IERC20(child.token());

        token.transfer(msg.sender, amount_);
        _stakingContractDeposits[msg.sender] = _stakingContractDeposits[
            msg.sender
        ].sub(amount_);
    }

    function stopChild(WarpStakingV2 child_, uint256 timestamp)
        external
        onlyRole(PAUSER_ROLE)
    {
        child_.stop(timestamp);
    }

    function stopChildNow(WarpStakingV2 child_)
        external
        onlyRole(PAUSER_ROLE)
    {
        child_.stop(block.timestamp);
    }

    function resumeChild(WarpStakingV2 child_) external onlyRole(PAUSER_ROLE) {
        child_.resume();
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Withdraw tokens out of the contract
    /// @param token_ to withdraw
    /// @param amount_ to rescue out of the contract
    function withdrawToken(IERC20 token_, uint256 amount_)
        external
        onlyRole(FUNDS_MANAGER_ROLE)
    {
        require(
            _fundsWithdrawReceiver != address(0),
            "WSM: Withdraw to null address"
        );
        token_.transfer(_fundsWithdrawReceiver, amount_);
    }

    /// @notice Withdraw all staked tokens out of the contract
    function withdrawAllChildTokens() external onlyRole(FUNDS_MANAGER_ROLE) {
        require(
            _fundsWithdrawReceiver != address(0),
            "WSM: Withdraw to null address"
        );
        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            IERC20 token = IERC20(_stakingContracts[i].token());
            token.transfer(
                _fundsWithdrawReceiver,
                token.balanceOf(address(this))
            );
        }
    }

    function forceChildUnstake(
        WarpStakingV2 child_,
        address account_,
        uint256 amount_,
        bool ignoreHarvest_
    ) external onlyRole(RESCUER_ROLE) {
        child_.forceUnstake(account_, amount_, ignoreHarvest_);
    }

    /// @notice Rescue tokens out of the contract
    /// @param token_ to rescue
    /// @param to_ receiver of the amount
    /// @param amount_ to rescue out of the contract
    function rescueToken(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external onlyRole(RESCUER_ROLE) {
        token_.transfer(to_, amount_);
    }

    /// @notice Rescue tokens out of a child contract
    /// @param child_ to rescue from
    /// @param token_ to rescue
    /// @param to_ receiver of the amount
    /// @param amount_ to rescue out of the contract
    function rescueTokenFromChild(
        WarpStakingV2 child_,
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external onlyRole(RESCUER_ROLE) {
        child_.rescueToken(token_, to_, amount_);
    }

    event ChildCreatorUpdated(address indexed childCreatorAddress);
    event WarpStakingAdded(address indexed warpStakingAddress);
    event WarpStakingRemoved(address indexed warpStakingAddress);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./WarpStakingV2Mothership.sol";
import "./utils/BalanceAccounting.sol";
import "./pancake/interfaces/IPancakePair.sol";

contract WarpStakingV2 is AccessControl, BalanceAccounting {
    using SafeMath for uint256;

    struct UserData {
        uint256 startTime; // Start time of first stake
        uint256 startBlock; // Start block of first stake
        uint256 lastStakeTime; // Last time staked
        uint256 lastStakeBlock; // Last block staked
        uint256 lastResetTime; // Last time harvested
        uint256 totalHarvested; // Total amount harvested in _rewardToken
        uint256 lastTimeHarvested; // Last time harvested
        uint256 lastBlockHarvested; // Last block harvested
        uint256 currentRewards; // Current rewards in _token (will be set when requesting with userData(_), don't use directly from _userDatas)
    }

    bytes32 public constant MOTHER_ROLE = keccak256("MOTHER_ROLE");

    WarpStakingV2Mothership private _mother;

    IERC20 private _token;
    IERC20 private _rewardToken;
    IPancakePair private _lp;
    uint256 private _tokenLpIndex;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _apr;
    uint256 private _rewardPerTokenPerSec; // Per ETH reward in WEI
    uint256 private _period;

    uint256 private _stoppedTimestamp;

    mapping(address => UserData) private _userDatas;

    constructor(
        WarpStakingV2Mothership mother_,
        IERC20 token_,
        IERC20 rewardToken_,
        IPancakePair lp_,
        string memory name_,
        string memory symbol_,
        uint256 apr_,
        uint256 period_
    ) {
        require(
            address(token_) == lp_.token0() || address(token_) == lp_.token1(),
            "WS: Missing token in lp"
        );
        require(
            address(rewardToken_) == lp_.token0() ||
                address(rewardToken_) == lp_.token1(),
            "WS: Missing reward token in lp"
        );

        _token = token_;
        _rewardToken = rewardToken_;
        _lp = lp_;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _apr = apr_;
        _period = period_;

        _tokenLpIndex = address(_token) != _lp.token0() ? 0 : 1;

        _rewardPerTokenPerSec = _apr
            .mul(10**_decimals)
            .div(100)
            .div(365)
            .div(24)
            .div(60)
            .div(60);

        _setMother(mother_);
    }

    function mother() public view returns (WarpStakingV2Mothership) {
        return _mother;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function rewardToken() public view returns (address) {
        return address(_rewardToken);
    }

    function lp() public view returns (address) {
        return address(_lp);
    }

    function apr() public view returns (uint256) {
        return _apr;
    }

    function period() public view returns (uint256) {
        return _period;
    }

    function fee() public view returns (uint256) {
        return _mother.baseFee();
    }

    function nativeFee() public view returns (uint256) {
        return _mother.nativeFee();
    }

    /// @notice Set new mother contract
    /// @param mother_ contract to replace current
    function setMother(WarpStakingV2Mothership mother_)
        public
        onlyRole(MOTHER_ROLE)
    {
        _setMother(mother_);
    }

    /**
     * @dev Returns the price of _token in _rewardToken
     */
    function tokenPriceInRewardToken() public view returns (uint256) {
        (uint256 lpReserve0, uint256 lpReserve1, uint256 lpTimestamp) = _lp
            .getReserves();

        return
            (_tokenLpIndex == 0 ? lpReserve1 : lpReserve0).mul(10**18).div(
                _tokenLpIndex == 0 ? lpReserve0 : lpReserve1
            );
    }

    /**
     * @dev Returns the price of _rewardToken in _token
     */
    function rewardTokenPriceInToken() public view returns (uint256) {
        (uint256 lpReserve0, uint256 lpReserve1, uint256 lpTimestamp) = _lp
            .getReserves();

        return
            (_tokenLpIndex == 0 ? lpReserve0 : lpReserve1).mul(10**18).div(
                _tokenLpIndex == 0 ? lpReserve1 : lpReserve0
            );
    }

    function rewardPerTokenPerSec() public view returns (uint256) {
        return _rewardPerTokenPerSec;
    }

    function isStopped() public view returns (bool) {
        return _stoppedTimestamp > 0 && _stoppedTimestamp <= block.timestamp;
    }

    /**
     * @dev Returns the userData of an address and also sets the currentRewards property
     */
    function userData(address account) public view returns (UserData memory) {
        UserData memory user = _userDatas[account];
        user.currentRewards = this.currentRewards(account);
        return user;
    }

    function totalHarvested(address account) public view returns (uint256) {
        return _userDatas[account].totalHarvested;
    }

    /**
     * @dev Returns pending rewards in _token
     * Rewards are always in _token and when harvested converted to the _rewardToken
     *
     * The reward is based on time since last time stake/harvest to now or if the
     * contract is stopped based on the stopped time
     */
    function currentRewards(address account) public view returns (uint256) {
        UserData memory user = _userDatas[account];

        if (user.lastResetTime == 0 && user.startTime == 0) {
            return 0;
        }

        uint256 lastReset = (
            user.lastResetTime != 0 ? user.lastResetTime : user.startTime
        );
        uint256 elapsedTime = (isStopped() && lastReset >= _stoppedTimestamp)
            ? 0
            : (
                (isStopped() ? _stoppedTimestamp : block.timestamp).sub(
                    lastReset,
                    "ghtrjhge"
                )
            );

        if (elapsedTime <= 0) {
            return 0;
        }

        return
            _rewardPerTokenPerSec.mul(elapsedTime).mul(balanceOf(account)).div(
                10**_decimals
            );
    }

    /**
     * @dev Returns pending rewards converted to the _rewardToken
     * Rewards are always in _token and when harvested converted to the _rewardToken
     */
    function currentRewardsInRewardToken(address account)
        public
        view
        returns (uint256)
    {
        uint256 reward = this.currentRewards(account);
        if (reward <= 0) {
            return 0;
        }

        return reward.mul(rewardTokenPriceInToken()).div(10**18);
    }

    /**
     * @dev Stops staking by setting the _stoppedTimestamp
     * Rewards will be only calculated up to the time of _stoppedTimestamp
     * Harvesting and unstaking is still possible.
     */
    function stop(uint256 timestamp) external onlyRole(MOTHER_ROLE) {
        require(timestamp > 0, "WS: Empty timestamp is not allowed");
        _stoppedTimestamp = timestamp;
        emit Stopped(timestamp);
    }

    /**
     * @dev Resumes the contract by setting _stoppedTimestamp to 0
     */
    function resume() external onlyRole(MOTHER_ROLE) {
        require(isStopped(), "WS: Staking is not stopped");
        _stoppedTimestamp = 0;
        emit Resumed();
    }

    /**
     * @dev Stakes amount of _token and also calls _harvest()
     * The userData will be updated to current block data
     */
    function stake(uint256 amount) public payable virtual {
        require(amount > 0, "WS: Empty stake is not allowed");
        require(!isStopped(), "WS: Staking is stopped");
        require(msg.value == nativeFee(), "WS: Fee incorrect");

        address feeReceiver = _mother.feeReceiver();
        if (msg.value != 0) {
            payable(feeReceiver).transfer(msg.value);
        }

        _harvest(msg.sender, msg.sender);

        _token.transferFrom(msg.sender, address(this), amount);

        uint256 feeAmount = amount.mul(fee()).div(10000);
        uint256 finalAmount = amount.sub(feeAmount);

        if (feeReceiver != address(0)) {
            _token.transfer(feeReceiver, feeAmount);
        }

        _mother.childDeposit(finalAmount);
        _mint(msg.sender, finalAmount);

        UserData storage user = _userDatas[msg.sender];
        if (user.startTime == 0) {
            user.startBlock = block.number;
            user.startTime = block.timestamp;
        }
        user.lastStakeTime = block.timestamp;
        user.lastStakeBlock = block.number;

        emit Transfer(address(0), msg.sender, finalAmount);
    }

    /**
     * @dev Unstakes amount of _token and also calls _harvest()
     * The userData will be updated to current block data
     */
    function unstake(uint256 amount) public payable {
        require(amount > 0, "WS: Empty unstake is not allowed");

        uint256 periodInSec = _period.mul(24).mul(60).mul(60);
        require(
            block.timestamp >
                _userDatas[msg.sender].lastStakeTime.add(periodInSec),
            "WS: Staking period is not over"
        );

        require(msg.value == nativeFee(), "WS: Fee incorrect");

        address feeReceiver = _mother.feeReceiver();
        if (msg.value != 0) {
            payable(feeReceiver).transfer(msg.value);
        }

        _harvest(msg.sender, msg.sender);

        _burn(msg.sender, amount);
        _mother.childWithdraw(amount);

        uint256 feeAmount = amount.mul(fee()).div(10000);
        uint256 finalAmount = amount.sub(feeAmount);

        if (feeReceiver != address(0)) {
            _token.transfer(feeReceiver, feeAmount);
        }

        _token.transfer(msg.sender, finalAmount);

        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev Forces a user to unstake
     * Harvesting rewards can be ignored
     */
    function forceUnstake(
        address account,
        uint256 amount,
        bool ignoreHarvest
    ) public onlyRole(MOTHER_ROLE) {
        require(amount > 0, "WS: Empty unstake is not allowed");

        if (!ignoreHarvest) {
            _harvest(account, account);
        }

        _burn(account, amount);
        _token.transfer(account, amount);
        emit Transfer(account, address(0), amount);
    }

    function harvest() external payable returns (uint256) {
        require(msg.value == nativeFee(), "WS: Fee incorrect");

        if (msg.value != 0) {
            payable(_mother.feeReceiver()).transfer(msg.value);
        }

        return _harvest(msg.sender, msg.sender);
    }

    /*function harvestAll(address[] memory stakers) public onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            _harvest(stakers[i], stakers[i]);
        }
    }*/

    /**
     * @dev Harvest rewards and update userData to current block
     */
    function _harvest(address account, address receiver)
        internal
        virtual
        returns (uint256)
    {
        UserData storage user = _userDatas[account];

        uint256 rewards = this.currentRewardsInRewardToken(account);
        user.lastResetTime = block.timestamp;

        if (rewards <= 0) {
            return 0;
        }

        _mother.childHarvest(rewards);
        _rewardToken.transfer(receiver, rewards);

        user.lastTimeHarvested = block.timestamp;
        user.lastBlockHarvested = block.number;
        user.totalHarvested = user.totalHarvested.add(rewards);

        emit Harvest(account, receiver, rewards);
        return rewards;
    }

    /// @notice Set new mother contract
    /// @param mother_ contract to replace current
    function _setMother(WarpStakingV2Mothership mother_) internal {
        require(address(mother_) != address(0), "WS: Cant be null address");

        if (address(_mother) != address(0x0)) {
            _revokeRole(MOTHER_ROLE, address(_mother));
            _token.approve(address(_mother), 0);
        }

        _mother = mother_;

        _grantRole(MOTHER_ROLE, address(_mother));
        _token.approve(address(_mother), 2**256 - 1);
    }

    /**
     * @dev Rescue tokens out of the contract
     */
    function rescueToken(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external onlyRole(MOTHER_ROLE) {
        token_.transfer(to_, amount_);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Harvest(
        address indexed from,
        address indexed receiver,
        uint256 value
    );
    event Stopped(uint256 timestamp);
    event Resumed();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WarpStakingV2.sol";
import "./WarpStakingV2Mothership.sol";
import "./pancake/interfaces/IPancakePair.sol";

contract WarpStakingV2ChildCreator is AccessControl {
    bytes32 public constant MOTHER_ROLE = keccak256("MOTHER_ROLE");

    constructor(address admin_) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
        _setupRole(MOTHER_ROLE, admin_);
    }

    function newWarpStaking(
        IERC20 token_,
        IERC20 rewardToken_,
        IPancakePair lp_,
        string memory name_,
        string memory symbol_,
        uint256 apr_,
        uint256 period_,
        bytes memory data
    ) public onlyRole(MOTHER_ROLE) returns (WarpStakingV2) {
        return
            new WarpStakingV2(
                WarpStakingV2Mothership(msg.sender),
                token_,
                rewardToken_,
                lp_,
                name_,
                symbol_,
                apr_,
                period_
            );
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract BalanceAccounting {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }

    function _set(address account, uint256 amount) internal virtual returns(uint256 oldAmount) {
        oldAmount = _balances[account];
        if (oldAmount != amount) {
            _balances[account] = amount;
            _totalSupply = _totalSupply.add(amount).sub(oldAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}