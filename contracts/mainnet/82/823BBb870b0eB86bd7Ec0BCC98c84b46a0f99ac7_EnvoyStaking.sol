// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EnvoyStaking is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant EMBARGOES_ROLE = keccak256("EMBARGOES_ROLE");
    bytes32 public constant LOCKINGS_ROLE = keccak256("LOCKINGS_ROLE");
    bytes32 public constant RATES_ROLE = keccak256("RATES_ROLE");

    event NewStake(address indexed user, uint256 totalStaked, uint256 lockupPeriod, bool isEmbargo);
    event StakeFinished(address indexed user, uint256 totalRewards);
    event LockingIncreased(address indexed user, uint256 total);
    event LockingReleased(address indexed user, uint256 total);
    event APYSet(uint256 indexed _lockupPeriod, uint256 _from, uint256 _to, uint256 _apy);
    event APYRemoved(uint256 indexed _lockupPeriod, uint256 _from, uint256 _to);
    
    IERC20 token = IERC20(0x2Ac8172D8Ce1C5Ad3D869556FD708801a42c1c0E);

    uint256 public constant APY_1 = 500; //5%
    uint256 public constant APY_3 = 800; //8%
    uint256 public constant APY_6 = 1100; //11%
    uint256 public constant APY_9 = 1300; //13%
    uint256 public constant APY_12 = 1500; //15%
    
    uint256 public totalStakes;
    uint256 public totalActiveStakes;
    uint256 public totalActiveStaked;
    uint256 public totalStaked;
    uint256 public totalStakeClaimed;
    uint256 public totalRewardsClaimed;
    uint256 public minimumStake = 1e18;

    struct APY {
        uint256 from;
        uint256 to;
        uint256 apy;
        bool enabled;
    }
    
    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 initialAmount;
        uint256 lockupPeriod;
        uint256 apy;
        bool isEmbargo;
    }
    
    mapping(address => Stake) stakes;
    mapping(address => uint256) public lockings;
    mapping(uint256 => APY[]) public apys;

    function _getTotalAPYs(uint256 lockup) public view returns(uint256) {
        return apys[lockup].length;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(EMBARGOES_ROLE, msg.sender);
        _grantRole(LOCKINGS_ROLE, msg.sender);
        _grantRole(RATES_ROLE, msg.sender);
    }

    function createStake(uint256 _totalStake, uint256 _lockupPeriod, uint256 _forceAPY) public {
        require(_totalStake >= minimumStake, "Total stake below minimum");

        _addStake(msg.sender, _totalStake, _lockupPeriod, false, _forceAPY);
    }

    function calculateAPY(uint256 _lockupPeriod) public view returns(uint256) {
        uint256 currentAPY = APY_1;
        if (_lockupPeriod == 3) {
            currentAPY = APY_3;
        }
        else if (_lockupPeriod == 6) {
            currentAPY = APY_6;
        }
        else if (_lockupPeriod == 9) {
            currentAPY = APY_9;
        }
        else if (_lockupPeriod == 12) {
            currentAPY = APY_12;
        }
        else if (_lockupPeriod != 1) {
            revert();
        }

        for (uint i = 0; i < apys[_lockupPeriod].length; i++) {
            if (apys[_lockupPeriod][i].from <= totalActiveStaked && totalActiveStaked <= apys[_lockupPeriod][i].to && currentAPY < apys[_lockupPeriod][i].apy) {
                currentAPY = apys[_lockupPeriod][i].apy;
            } 
        }

        return currentAPY;
    }
    
    function _addStake(address _beneficiary, uint256 _totalStake, uint256 _lockupPeriod, bool _isEmbargo, uint256 _forceAPY) internal whenNotPaused {
        require(!stakes[_beneficiary].exists, "Stake already created");
        require(_lockupPeriod == 1 || _lockupPeriod == 3 || _lockupPeriod == 6 || _lockupPeriod == 9 || _lockupPeriod == 12, "Invalid lockup period");
        require(IERC20(token).transferFrom(msg.sender, address(this), _totalStake), "Couldn't take the tokens");

        uint256 apy = calculateAPY(_lockupPeriod);
        if (_forceAPY > 0) {
            require(apy == _forceAPY, "APY changed");
        }
        
        Stake memory stake = Stake({exists:true,
                                    createdOn: block.timestamp, 
                                    initialAmount:_totalStake, 
                                    lockupPeriod:_lockupPeriod, 
                                    apy: apy,
                                    isEmbargo:_isEmbargo
        });
        
        stakes[_beneficiary] = stake;
                                    
        totalActiveStakes++;
        totalStakes++;
        totalStaked += _totalStake;
        totalActiveStaked += _totalStake;
        
        emit NewStake(_beneficiary, _totalStake, _lockupPeriod, _isEmbargo);
    }
    
    function finishStake() public {
        require(!stakes[msg.sender].isEmbargo, "This is an embargo");
        totalStakes--;
        _finishStake(msg.sender);
    }
    
    function _finishStake(address _account) internal {
        require(stakes[_account].exists, "Invalid stake");

        Stake storage stake = stakes[_account];
        
        uint256 finishesOn = _calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        require(block.timestamp > finishesOn, "Can't be finished yet");
        
        stake.exists = false;
        
        uint256 totalRewards = calculateRewards(stake.initialAmount, stake.lockupPeriod, stake.apy);

        totalActiveStakes -= 1;
        totalActiveStaked -= stake.initialAmount;
        totalStakeClaimed += stake.initialAmount;
        totalRewardsClaimed += totalRewards;
        
        require(token.transfer(msg.sender, totalRewards), "Couldn't transfer the tokens");
        
        emit StakeFinished(msg.sender, totalRewards);
    }
    
    function calculateRewards(uint256 initialAmount, uint256 lockupPeriod, uint256 apy) public pure returns (uint256) {
        return initialAmount * apy * lockupPeriod / 120000;
    }
    
    function calculateFinishTimestamp(address _account) public view returns (uint256) {
        return _calculateFinishTimestamp(stakes[_account].createdOn, stakes[_account].lockupPeriod);
    }
    
    function _calculateFinishTimestamp(uint256 _timestamp, uint256 _lockupPeriod) internal pure returns (uint256) {
        return _timestamp + _lockupPeriod * 30 days;
    }

    //If minimum stake is set to zero, no minimum stake will be required
    function setMinimumStake(uint256 _minimumStake) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not allowed");
        require(_minimumStake >= 1e18, "Minimum stake is 1 VOY");

        minimumStake = _minimumStake;
    }
    
    function increaseLocking(address _beneficiary, uint256 _total) public {
        require(hasRole(LOCKINGS_ROLE, msg.sender), "Not allowed");
        require(_beneficiary != address(0), "Invalid address");
        require(_total > 0, "Invalid value");

        require(IERC20(token).transferFrom(msg.sender, address(this), _total), "Couldn't take the tokens");
        
        lockings[_beneficiary] += _total;
        
        emit LockingIncreased(_beneficiary, _total);
    }
    
    function releaseFromLocking(address _beneficiary, uint256 _total) public {
        require(hasRole(LOCKINGS_ROLE, msg.sender), "Not allowed");
        require(_total > 0, "Invalid value");
        require(lockings[_beneficiary] >= _total, "Not enough locked tokens");

        lockings[_beneficiary] -= _total;

        require(IERC20(token).transfer(_beneficiary, _total), "Couldn't send the tokens");
        
        emit LockingReleased(_beneficiary, _total);
    }

    function createEmbargo(address _account, uint256 _totalStake, uint256 _lockupPeriod, uint256 _forceAPY) public {
        require(hasRole(EMBARGOES_ROLE, msg.sender), "Not allowed");
        require(_account != address(0), "Invalid address");
        require(_totalStake > 1e18, "Invalid value");
        _addStake(_account, _totalStake, _lockupPeriod, true, _forceAPY);
    }

    function _setAPY(uint256 _lockupPeriod, uint256 _from, uint256 _to, uint256 _apy) public {
        require(hasRole(RATES_ROLE, msg.sender), "Not allowed");
        for (uint i = 0; i < apys[_lockupPeriod].length; i++) {
            if (apys[_lockupPeriod][i].from == _from && apys[_lockupPeriod][i].to == _to) {
                apys[_lockupPeriod][i].apy = _apy;
                apys[_lockupPeriod][i].enabled = true;
                return;
            }
        }

        APY memory apy = APY({from:_from, to:_to, apy:_apy, enabled:true});
        apys[_lockupPeriod].push(apy);
        emit APYSet(_lockupPeriod, _from, _to, _apy);
    }

    function _removeAPY(uint256 _lockupPeriod, uint256 _from, uint256 _to) public {
        require(hasRole(RATES_ROLE, msg.sender), "Not allowed");

        for (uint i = 0; i < apys[_lockupPeriod].length; i++) {
            if (apys[_lockupPeriod][i].from == _from && apys[_lockupPeriod][i].to == _to) {
                apys[_lockupPeriod][i].enabled = false;
                emit APYRemoved(_lockupPeriod, _from, _to);
                return;
            }
        }

        return revert();
    }
    
    function finishEmbargo(address _account) public {
        require(hasRole(EMBARGOES_ROLE, msg.sender), "Not allowed");
        require(stakes[_account].isEmbargo, "Not an embargo");

        _finishStake(_account);
    }

    function _setupInitialAPYs() public {
        _setAPY(1, 0, 500000 * 1e18, 1000);
        _setAPY(1, 500000 * 1e18, 1000000 * 1e18, 900);
        _setAPY(1, 1000000 * 1e18, 5000000 * 1e18, 800);
        _setAPY(1, 5000000 * 1e18, 10000000 * 1e18, 700);
        _setAPY(1, 10000000 * 1e18, 50000000 * 1e18, 625);
        _setAPY(1, 50000000 * 1e18, 100000000 * 1e18, 575);
        _setAPY(1, 100000000 * 1e18, 10000000000 * 1e18, 500);

        _setAPY(3, 0, 500000 * 1e18 * 1e18, 1600);
        _setAPY(3, 500000 * 1e18, 1000000 * 1e18, 1440);
        _setAPY(3, 1000000 * 1e18, 5000000 * 1e18, 1280);
        _setAPY(3, 5000000 * 1e18, 10000000 * 1e18, 1120);
        _setAPY(3, 10000000 * 1e18, 50000000 * 1e18, 1000);
        _setAPY(3, 50000000 * 1e18, 100000000 * 1e18, 920);
        _setAPY(3, 100000000 * 1e18, 10000000000 * 1e18, 800);

        _setAPY(6, 0, 500000 * 1e18, 2200);
        _setAPY(6, 500000 * 1e18, 1000000 * 1e18, 1980);
        _setAPY(6, 1000000 * 1e18, 5000000 * 1e18, 1760);
        _setAPY(6, 5000000 * 1e18, 10000000 * 1e18, 1540);
        _setAPY(6, 10000000 * 1e18, 50000000 * 1e18, 1375);
        _setAPY(6, 50000000 * 1e18, 100000000 * 1e18, 1265);
        _setAPY(6, 100000000 * 1e18, 10000000000 * 1e18, 1100);

        _setAPY(9, 0, 500000 * 1e18 * 1e18, 2600);
        _setAPY(9, 500000 * 1e18, 1000000 * 1e18, 2340);
        _setAPY(9, 1000000 * 1e18, 5000000 * 1e18, 2080);
        _setAPY(9, 5000000 * 1e18, 10000000 * 1e18, 1820);
        _setAPY(9, 10000000 * 1e18, 50000000 * 1e18, 1625);
        _setAPY(9, 50000000 * 1e18, 100000000 * 1e18, 1495);
        _setAPY(9, 100000000 * 1e18, 10000000000 * 1e18, 1300);

        _setAPY(12, 0, 500000 * 1e18, 3000);
        _setAPY(12, 500000 * 1e18, 1000000 * 1e18, 2700);
        _setAPY(12, 1000000 * 1e18, 5000000 * 1e18, 2400);
        _setAPY(12, 5000000 * 1e18, 10000000 * 1e18, 2100);
        _setAPY(12, 10000000 * 1e18, 50000000 * 1e18, 1875);
        _setAPY(12, 50000000 * 1e18, 100000000 * 1e18, 1725);
        _setAPY(12, 100000000 * 1e18, 10000000000 * 1e18, 1500);
    }
    
    function _extract(uint256 amount, address _sendTo) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not allowed");
        require(token.transfer(_sendTo, amount));
    }
    
    function getStake(address _account) external view returns (bool _exists, uint256 _createdOn, uint256 _initialAmount, uint256 _lockupPeriod, uint256 _apy, bool _isEmbargo, uint256 _finishesOn, uint256 _totalRewards) {
        Stake memory stake = stakes[_account];
        if (!stake.exists) {
            return (false, 0, 0, 0, 0, false, 0, 0);
        }
        uint256 finishesOn = calculateFinishTimestamp(_account);
        uint256 totalRewards = calculateRewards(stake.initialAmount, stake.lockupPeriod, stake.apy);
        return (stake.exists, stake.createdOn, stake.initialAmount, stake.lockupPeriod, stake.apy, stake.isEmbargo, finishesOn, totalRewards);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
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