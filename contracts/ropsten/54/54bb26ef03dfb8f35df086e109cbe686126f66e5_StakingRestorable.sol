// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "@openzeppelin/contracts-upgradeable/contracts/proxy/Initializable.sol";
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
/** Local Interfaces */
import '../Staking.sol';

contract StakingRestorable is Staking {
    function init(
        address _mainTokenAddress,
        address _auctionAddress,
        address _subBalancesAddress,
        address _foreignSwapAddress,
        address _stakingV1Address,
        uint256 _stepTimestamp,
        uint256 _lastSessionIdV1
    ) external onlyMigrator {
        require(!init_, 'Staking: init is active');
        init_ = true;
        /** Setup */
        _setupRole(EXTERNAL_STAKER_ROLE, _foreignSwapAddress);
        _setupRole(EXTERNAL_STAKER_ROLE, _auctionAddress);

        addresses = Addresses({
            mainToken: _mainTokenAddress,
            auction: _auctionAddress,
            subBalances: _subBalancesAddress
        });

        stakingV1 = IStakingV1(_stakingV1Address);
        stepTimestamp = _stepTimestamp;

        if (startContract == 0) {
            startContract = now;
            nextPayoutCall = startContract.add(_stepTimestamp);
        }
        if (_lastSessionIdV1 != 0) {
            lastSessionIdV1 = _lastSessionIdV1;
        }
        if (shareRate == 0) {
            shareRate = 1e18;
        }
    }

    function addStakedAmount(uint256 _staked) external onlyMigrator {
        totalStakedAmount = totalStakedAmount.add(_staked);
    }

    function addShareTotalSupply(uint256 _shares) external onlyMigrator {
        sharesTotalSupply = sharesTotalSupply.add(_shares);
    }

    // migration functions
    function setOtherVars(
        uint256 _startTime,
        uint256 _shareRate,
        uint256 _sharesTotalSupply,
        uint256 _nextPayoutCall,
        uint256 _globalPayin,
        uint256 _globalPayout,
        uint256[] calldata _payouts,
        uint256[] calldata _sharesTotalSupplyVec,
        uint256 _lastSessionId
    ) external onlyMigrator {
        startContract = _startTime;
        shareRate = _shareRate;
        sharesTotalSupply = _sharesTotalSupply;
        nextPayoutCall = _nextPayoutCall;
        globalPayin = _globalPayin;
        globalPayout = _globalPayout;
        lastSessionId = _lastSessionId;
        lastSessionIdV1 = _lastSessionId;

        for (uint256 i = 0; i < _payouts.length; i++) {
            payouts.push(
                Payout({
                    payout: _payouts[i],
                    sharesTotalSupply: _sharesTotalSupplyVec[i]
                })
            );
        }
    }

    function setSessionsOf(
        address[] calldata _wallets,
        uint256[] calldata _sessionIds
    ) external onlyMigrator {
        for (uint256 idx = 0; idx < _wallets.length; idx = idx.add(1)) {
            sessionsOf[_wallets[idx]].push(_sessionIds[idx]);
        }
    }

    function setBasePeriod(uint256 _basePeriod) external onlyMigrator {
        basePeriod = _basePeriod;
    }

    function setLastSessionId(uint256 _lastSessionId) external onlyMigrator {
        lastSessionId = _lastSessionId;
    }

    function setSharesTotalSupply(uint256 _sharesTotalSupply)
        external
        onlyMigrator
    {
        sharesTotalSupply = _sharesTotalSupply;
    }

    function setTotalStakedAmount(uint256 _totalStakedAmount)
        external
        onlyMigrator
    {
        totalStakedAmount = _totalStakedAmount;
    }

    /**
     * Fix stake
     * */
    function fixShareRateOnStake(address _staker, uint256 _stakeId)
        external
        onlyMigrator
    {
        Session storage session = sessionDataOf[_staker][_stakeId]; // Get Session
        require(
            session.withdrawn == false && session.shares != 0,
            'STAKING: Session has already been withdrawn'
        );
        sharesTotalSupply = sharesTotalSupply.sub(session.shares); // Subtract shares total share supply
        session.shares = _getStakersSharesAmount(
            session.amount,
            session.start,
            session.end
        ); // update shares
        sharesTotalSupply = sharesTotalSupply.add(session.shares); // Add to total share suuply
    }

    /**
     * Fix v1 unstakers
     * Unfortunately due to people not understanding that we were updating to v2, we need to fix some of our users stakes
     * This code will be removed as soon as we fix stakes
     * In order to run this code it will take at minimum 4 devs / core team to accept any stake
     * This function can not be ran by just anyone.
     */
    function fixV1Stake(address _staker, uint256 _sessionId)
        external
        onlyMigrator
    {
        require(_sessionId <= lastSessionIdV1, 'Staking: Invalid sessionId'); // Require that the sessionId we are looking for is > v1Id

        // Ensure that the session does not exist
        Session storage session = sessionDataOf[_staker][_sessionId];
        require(
            session.shares == 0 && session.withdrawn == false,
            'Staking: Stake already fixed and or withdrawn'
        );

        // Find the v1 stake && ensure the stake has not been withdrawn
        (
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 shares,
            uint256 firstPayout
        ) = stakingV1.sessionDataOf(_staker, _sessionId);

        require(shares == 0, 'Staking: Stake has not been withdrawn');

        // Get # of staking days
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);

        stakeInternalCommon(
            _sessionId,
            amount,
            start,
            end < now ? now : end,
            stakingDays,
            firstPayout,
            _staker
        );
    }

    // Used for tests only
    function resetTotalSharesOfAccount() external {
        totalSharesOf[msg.sender] = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.4.25 <0.7.0;

import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol';

import './interfaces/IToken.sol';
import './interfaces/IAuction.sol';
import './interfaces/IStaking.sol';
import './interfaces/ISubBalances.sol';
import './interfaces/IStakingV1.sol';

contract Staking is IStaking, Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /** Events */
    event Stake(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 shares
    );

    event MaxShareUpgrade(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 newAmount,
        uint256 shares,
        uint256 newShares,
        uint256 start,
        uint256 end
    );

    event Unstake(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 shares
    );

    event MakePayout(
        uint256 indexed value,
        uint256 indexed sharesTotalSupply,
        uint256 indexed time
    );

    event WithdrawLiquidDiv(
        address indexed accountAddress,
        address indexed tokenAddress,
        uint256 indexed interest
    );

    /** Structs */
    struct Payout {
        uint256 payout;
        uint256 sharesTotalSupply;
    }

    struct Session {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 shares;
        uint256 firstPayout;
        uint256 lastPayout;
        bool withdrawn;
        uint256 payout;
    }

    struct Addresses {
        address mainToken;
        address auction;
        address subBalances;
    }

    Addresses public addresses;
    IStakingV1 public stakingV1;

    /** Roles */
    bytes32 public constant MIGRATOR_ROLE = keccak256('MIGRATOR_ROLE');
    bytes32 public constant EXTERNAL_STAKER_ROLE =
        keccak256('EXTERNAL_STAKER_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    /** Public Variables */
    uint256 public shareRate;
    uint256 public sharesTotalSupply;
    uint256 public nextPayoutCall;
    uint256 public stepTimestamp;
    uint256 public startContract;
    uint256 public globalPayout;
    uint256 public globalPayin;
    uint256 public lastSessionId;
    uint256 public lastSessionIdV1;

    /** Mappings / Arrays */
    mapping(address => mapping(uint256 => Session)) public sessionDataOf;
    mapping(address => uint256[]) public sessionsOf;
    Payout[] public payouts;

    /** Booleans */
    bool public init_;

    uint256 public basePeriod;
    uint256 public totalStakedAmount;

    bool private maxShareEventActive;

    uint16 private maxShareMaxDays;
    uint256 private shareRateScalingFactor;

    uint256 public totalVcaRegisteredShares;

    mapping(address => uint256) public tokenPricePerShare;
    EnumerableSetUpgradeable.AddressSet internal divTokens;

    mapping(address => uint256) internal totalSharesOf;
    mapping(address => mapping(address => uint256)) public deductBalances;

    /* New variables must go below here. */

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), 'Caller is not a manager');
        _;
    }

    modifier onlyMigrator() {
        require(
            hasRole(MIGRATOR_ROLE, _msgSender()),
            'Caller is not a migrator'
        );
        _;
    }

    modifier onlyExternalStaker() {
        require(
            hasRole(EXTERNAL_STAKER_ROLE, _msgSender()),
            'Caller is not a external staker'
        );
        _;
    }

    modifier onlyAuction() {
        require(msg.sender == addresses.auction, 'Caller is not the auction');
        _;
    }

    function initialize(address _manager, address _migrator)
        public
        initializer
    {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }

    function sessionsOf_(address account)
        external
        view
        returns (uint256[] memory)
    {
        return sessionsOf[account];
    }

    function stake(uint256 amount, uint256 stakingDays) external {
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        stakeInternal(amount, stakingDays, msg.sender);
        IToken(addresses.mainToken).burn(msg.sender, amount);
    }

    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external override onlyExternalStaker {
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        stakeInternal(amount, stakingDays, staker);
    }

    function stakeInternal(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) internal {
        if (now >= nextPayoutCall) makePayout();

        uint256 start = now;
        uint256 end = now.add(stakingDays.mul(stepTimestamp));

        lastSessionId = lastSessionId.add(1);

        stakeInternalCommon(
            lastSessionId,
            amount,
            start,
            end,
            stakingDays,
            payouts.length,
            staker
        );
    }

    function _initPayout(address to, uint256 amount) internal {
        IToken(addresses.mainToken).mint(to, amount);
        globalPayout = globalPayout.add(amount);
    }

    function calculateStakingInterest(
        uint256 firstPayout,
        uint256 lastPayout,
        uint256 shares
    ) public view returns (uint256) {
        uint256 stakingInterest;
        uint256 lastIndex = MathUpgradeable.min(payouts.length, lastPayout);

        for (uint256 i = firstPayout; i < lastIndex; i++) {
            uint256 payout =
                payouts[i].payout.mul(shares).div(payouts[i].sharesTotalSupply);

            stakingInterest = stakingInterest.add(payout);
        }

        return stakingInterest;
    }

    function unstake(uint256 sessionId) external {
        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares != 0 && session.withdrawn == false,
            'Staking: Stake withdrawn or not set'
        );

        uint256 actualEnd = now;

        uint256 amountOut = unstakeInternal(session, sessionId, actualEnd);

        // To account
        _initPayout(msg.sender, amountOut);
    }

    function unstakeV1(uint256 sessionId) external {
        require(sessionId <= lastSessionIdV1, 'Staking: Invalid sessionId');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        // Unstaked already
        require(
            session.shares == 0 && session.withdrawn == false,
            'Staking: Stake withdrawn'
        );

        (
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 shares,
            uint256 firstPayout
        ) = stakingV1.sessionDataOf(msg.sender, sessionId);

        // Unstaked in v1 / doesn't exist
        require(shares != 0, 'Staking: Stake withdrawn or not set');

        uint256 stakingDays = (end - start) / stepTimestamp;
        uint256 lastPayout = stakingDays + firstPayout;

        uint256 actualEnd = now;

        uint256 amountOut =
            unstakeV1Internal(
                sessionId,
                amount,
                start,
                end,
                actualEnd,
                shares,
                firstPayout,
                lastPayout,
                stakingDays
            );

        // To account
        _initPayout(msg.sender, amountOut);
    }

    function getAmountOutAndPenalty(
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 stakingInterest
    ) public view returns (uint256, uint256) {
        uint256 stakingSeconds = end.sub(start);
        uint256 stakingDays = stakingSeconds.div(stepTimestamp);
        uint256 secondsStaked = now.sub(start);
        uint256 daysStaked = secondsStaked.div(stepTimestamp);
        uint256 amountAndInterest = amount.add(stakingInterest);

        // Early
        if (stakingDays > daysStaked) {
            uint256 payOutAmount =
                amountAndInterest.mul(secondsStaked).div(stakingSeconds);

            uint256 earlyUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, earlyUnstakePenalty);
            // In time
        } else if (daysStaked < stakingDays.add(14)) {
            return (amountAndInterest, 0);
            // Late
        } else if (daysStaked < stakingDays.add(714)) {
            uint256 daysAfterStaking = daysStaked - stakingDays;

            uint256 payOutAmount =
                amountAndInterest.mul(uint256(714).sub(daysAfterStaking)).div(
                    700
                );

            uint256 lateUnstakePenalty = amountAndInterest.sub(payOutAmount);

            return (payOutAmount, lateUnstakePenalty);
            // Nothing
        } else {
            return (0, amountAndInterest);
        }
    }

    function makePayout() public {
        require(now >= nextPayoutCall, 'Staking: Wrong payout time');

        uint256 payout = _getPayout();

        payouts.push(
            Payout({payout: payout, sharesTotalSupply: sharesTotalSupply})
        );

        nextPayoutCall = nextPayoutCall.add(stepTimestamp);

        updateShareRate(payout);

        emit MakePayout(payout, sharesTotalSupply, now);
    }

    function readPayout() external view returns (uint256) {
        uint256 amountTokenInDay =
            IERC20Upgradeable(addresses.mainToken).balanceOf(address(this));

        uint256 currentTokenTotalSupply =
            (IERC20Upgradeable(addresses.mainToken).totalSupply()).add(
                globalPayin
            );

        uint256 inflation =
            uint256(8).mul(currentTokenTotalSupply.add(totalStakedAmount)).div(
                36500
            );

        return amountTokenInDay.add(inflation);
    }

    function _getPayout() internal returns (uint256) {
        uint256 amountTokenInDay =
            IERC20Upgradeable(addresses.mainToken).balanceOf(address(this));

        globalPayin = globalPayin.add(amountTokenInDay);

        if (globalPayin > globalPayout) {
            globalPayin = globalPayin.sub(globalPayout);
            globalPayout = 0;
        } else {
            globalPayin = 0;
            globalPayout = 0;
        }

        uint256 currentTokenTotalSupply =
            (IERC20Upgradeable(addresses.mainToken).totalSupply()).add(
                globalPayin
            );

        IToken(addresses.mainToken).burn(address(this), amountTokenInDay);

        uint256 inflation =
            uint256(8).mul(currentTokenTotalSupply.add(totalStakedAmount)).div(
                36500
            );

        globalPayin = globalPayin.add(inflation);

        return amountTokenInDay.add(inflation);
    }

    function _getStakersSharesAmount(
        uint256 amount,
        uint256 start,
        uint256 end
    ) internal view returns (uint256) {
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);
        uint256 numerator = amount.mul(uint256(1819).add(stakingDays));
        uint256 denominator = uint256(1820).mul(shareRate);

        return (numerator).mul(1e18).div(denominator);
    }

    function _getShareRate(
        uint256 amount,
        uint256 shares,
        uint256 start,
        uint256 end,
        uint256 stakingInterest
    ) internal view returns (uint256) {
        uint256 stakingDays = (end.sub(start)).div(stepTimestamp);

        uint256 numerator =
            (amount.add(stakingInterest)).mul(uint256(1819).add(stakingDays));

        uint256 denominator = uint256(1820).mul(shares);

        return (numerator).mul(1e18).div(denominator);
    }

    function restake(
        uint256 sessionId,
        uint256 stakingDays,
        uint256 topup
    ) external {
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares != 0 && session.withdrawn == false,
            'Staking: Stake withdrawn/invalid'
        );

        uint256 actualEnd = now;

        require(session.end <= actualEnd, 'Staking: Stake not mature');

        uint256 amountOut = unstakeInternal(session, sessionId, actualEnd);

        if (topup != 0) {
            IToken(addresses.mainToken).burn(msg.sender, topup);
            amountOut = amountOut.add(topup);
        }

        stakeInternal(amountOut, stakingDays, msg.sender);
    }

    function restakeV1(
        uint256 sessionId,
        uint256 stakingDays,
        uint256 topup
    ) external {
        require(sessionId <= lastSessionIdV1, 'Staking: Invalid sessionId');
        require(stakingDays != 0, 'Staking: Staking days < 1');
        require(stakingDays <= 5555, 'Staking: Staking days > 5555');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares == 0 && session.withdrawn == false,
            'Staking: Stake withdrawn'
        );

        (
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 shares,
            uint256 firstPayout
        ) = stakingV1.sessionDataOf(msg.sender, sessionId);

        // Unstaked in v1 / doesn't exist
        require(shares != 0, 'Staking: Stake withdrawn');

        uint256 actualEnd = now;

        require(end <= actualEnd, 'Staking: Stake not mature');

        uint256 sessionStakingDays = (end - start) / stepTimestamp;
        uint256 lastPayout = sessionStakingDays + firstPayout;

        uint256 amountOut =
            unstakeV1Internal(
                sessionId,
                amount,
                start,
                end,
                actualEnd,
                shares,
                firstPayout,
                lastPayout,
                sessionStakingDays
            );

        if (topup != 0) {
            IToken(addresses.mainToken).burn(msg.sender, topup);
            amountOut = amountOut.add(topup);
        }

        stakeInternal(amountOut, stakingDays, msg.sender);
    }

    function unstakeInternal(
        Session storage session,
        uint256 sessionId,
        uint256 actualEnd
    ) internal returns (uint256) {
        uint256 amountOut =
            unstakeInternalCommon(
                sessionId,
                session.amount,
                session.start,
                session.end,
                actualEnd,
                session.shares,
                session.firstPayout,
                session.lastPayout
            );

        uint256 stakingDays = (session.end - session.start) / stepTimestamp;

        if (stakingDays >= basePeriod) {
            ISubBalances(addresses.subBalances).callOutcomeStakerTrigger(
                sessionId,
                session.start,
                session.end,
                actualEnd,
                session.shares
            );
        }

        session.end = actualEnd;
        session.withdrawn = true;
        session.payout = amountOut;

        return amountOut;
    }

    function unstakeV1Internal(
        uint256 sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares,
        uint256 firstPayout,
        uint256 lastPayout,
        uint256 stakingDays
    ) internal returns (uint256) {
        uint256 amountOut =
            unstakeInternalCommon(
                sessionId,
                amount,
                start,
                end,
                actualEnd,
                shares,
                firstPayout,
                lastPayout
            );

        if (stakingDays >= basePeriod) {
            ISubBalances(addresses.subBalances).callOutcomeStakerTriggerV1(
                msg.sender,
                sessionId,
                start,
                end,
                actualEnd,
                shares
            );
        }

        sessionDataOf[msg.sender][sessionId] = Session({
            amount: amount,
            start: start,
            end: actualEnd,
            shares: shares,
            firstPayout: firstPayout,
            lastPayout: lastPayout,
            withdrawn: true,
            payout: amountOut
        });

        sessionsOf[msg.sender].push(sessionId);

        return amountOut;
    }

    function unstakeInternalCommon(
        uint256 sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares,
        uint256 firstPayout,
        uint256 lastPayout
    ) internal returns (uint256) {
        if (now >= nextPayoutCall) makePayout();

        uint256 stakingInterest =
            calculateStakingInterest(firstPayout, lastPayout, shares);

        sharesTotalSupply = sharesTotalSupply.sub(shares);
        totalStakedAmount = totalStakedAmount.sub(amount);
        totalVcaRegisteredShares = totalVcaRegisteredShares.sub(shares);

        uint256 oldTotalSharesOf = totalSharesOf[msg.sender];
        totalSharesOf[msg.sender] = totalSharesOf[msg.sender].sub(shares);

        rebalance(msg.sender, oldTotalSharesOf);

        (uint256 amountOut, uint256 penalty) =
            getAmountOutAndPenalty(amount, start, end, stakingInterest);

        // To auction
        if (penalty != 0) {
            _initPayout(addresses.auction, penalty);
            IAuction(addresses.auction).callIncomeDailyTokensTrigger(penalty);
        }

        emit Unstake(
            msg.sender,
            sessionId,
            amountOut,
            start,
            actualEnd,
            shares
        );

        return amountOut;
    }

    function stakeInternalCommon(
        uint256 sessionId,
        uint256 amount,
        uint256 start,
        uint256 end,
        uint256 stakingDays,
        uint256 firstPayout,
        address staker
    ) internal {
        uint256 shares = _getStakersSharesAmount(amount, start, end);

        sharesTotalSupply = sharesTotalSupply.add(shares);
        totalStakedAmount = totalStakedAmount.add(amount);
        totalVcaRegisteredShares = totalVcaRegisteredShares.add(shares);

        uint256 oldTotalSharesOf = totalSharesOf[staker];
        totalSharesOf[staker] = totalSharesOf[staker].add(shares);

        rebalance(staker, oldTotalSharesOf);

        sessionDataOf[staker][sessionId] = Session({
            amount: amount,
            start: start,
            end: end,
            shares: shares,
            firstPayout: firstPayout,
            lastPayout: firstPayout + stakingDays,
            withdrawn: false,
            payout: 0
        });

        sessionsOf[staker].push(sessionId);

        if (stakingDays >= basePeriod) {
            ISubBalances(addresses.subBalances).callIncomeStakerTrigger(
                staker,
                sessionId,
                start,
                end,
                shares
            );
        }

        emit Stake(staker, sessionId, amount, start, end, shares);
    }

    function withdrawDivToken(address tokenAddress) external {
        uint256 tokenInterestEarned =
            getTokenInterestEarnedInternal(msg.sender, tokenAddress);

        if (
            tokenAddress != address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
        ) {
            IERC20Upgradeable(tokenAddress).transfer(
                msg.sender,
                tokenInterestEarned
            );
        } else {
            msg.sender.transfer(tokenInterestEarned);
        }

        deductBalances[msg.sender][tokenAddress] = totalSharesOf[msg.sender]
            .mul(tokenPricePerShare[tokenAddress]);

        emit WithdrawLiquidDiv(msg.sender, tokenAddress, tokenInterestEarned);
    }

    function getTokenInterestEarned(
        address accountAddress,
        address tokenAddress
    ) external view returns (uint256) {
        return getTokenInterestEarnedInternal(accountAddress, tokenAddress);
    }

    function getTokenInterestEarnedInternal(
        address accountAddress,
        address tokenAddress
    ) internal view returns (uint256) {
        return
            totalSharesOf[accountAddress]
                .mul(tokenPricePerShare[tokenAddress])
                .sub(deductBalances[accountAddress][tokenAddress])
                .div(1e18);
    }

    function rebalance(address staker, uint256 oldTotalSharesOf) internal {
        for (uint8 i = 0; i < divTokens.length(); i++) {
            uint256 tokenInterestEarned =
                oldTotalSharesOf.mul(tokenPricePerShare[divTokens.at(i)]).sub(
                    deductBalances[staker][divTokens.at(i)]
                );

            deductBalances[staker][divTokens.at(i)] = totalSharesOf[staker]
                .mul(tokenPricePerShare[divTokens.at(i)])
                .sub(tokenInterestEarned);
        }
    }

    function setTotalSharesOfAccount() external {
        // TO DISCUSS - This would negate all liq divs if account not registered and there was a new stake created
        uint256 totalShares;
        uint256[] storage sessionsOfAccount = sessionsOf[msg.sender];

        for (uint256 i = 0; i < sessionsOfAccount.length; i++) {
            totalShares = totalShares.add(
                sessionDataOf[msg.sender][sessionsOfAccount[i]].shares
            );
        }

        uint256[] memory v1SessionsOfAccount =
            stakingV1.sessionsOf_(msg.sender);

        for (uint256 i = 0; i < v1SessionsOfAccount.length; i++) {
            if (v1SessionsOfAccount[i] > lastSessionIdV1) {
                continue;
            }

            (
                uint256 amount,
                uint256 start,
                uint256 end,
                uint256 shares,
                uint256 firstPayout
            ) = stakingV1.sessionDataOf(msg.sender, v1SessionsOfAccount[i]);

            (amount);
            (start);
            (end);
            (firstPayout);

            if (shares == 0) {
                continue;
            }

            totalShares = totalShares.add(shares);
        }

        require(
            totalSharesOf[msg.sender] != totalShares,
            'STAKING: totalSharesOf already set.'
        );

        if (totalSharesOf[msg.sender] != 0) {
            totalVcaRegisteredShares = totalVcaRegisteredShares.sub(
                totalSharesOf[msg.sender]
            );
        }

        totalVcaRegisteredShares = totalVcaRegisteredShares.add(totalShares);

        for (uint256 i = 0; i < divTokens.length(); i++) {
            deductBalances[msg.sender][divTokens.at(i)] = totalShares.mul(
                tokenPricePerShare[divTokens.at(i)]
            );
        }

        totalSharesOf[msg.sender] = totalShares;
    }

    function updateTokenPricePerShare(
        address payable bidderAddress,
        address tokenAddress,
        uint256 amountBought
    ) external payable override onlyAuction {
        uint256 amountForBidder = amountBought.mul(10526).div(100000);

        if (
            tokenAddress != address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
        ) {
            IERC20Upgradeable(tokenAddress).transfer(
                bidderAddress,
                amountForBidder
            );
        } else {
            bidderAddress.transfer(amountForBidder);
        }

        tokenPricePerShare[tokenAddress] = tokenPricePerShare[tokenAddress].add(
            amountBought.sub(amountForBidder).mul(1e18).div(
                totalVcaRegisteredShares
            )
        );
    }

    function addDivToken(address tokenAddress) external override onlyAuction {
        if (!divTokens.contains(tokenAddress)) {
            divTokens.add(tokenAddress);
        }
    }

    function updateShareRate(uint256 _payout) internal {
        uint256 currentTokenTotalSupply =
            IERC20Upgradeable(addresses.mainToken).totalSupply();

        uint256 growthFactor =
            _payout.mul(1e18).div(
                currentTokenTotalSupply + totalStakedAmount + 1
            );

        if (shareRateScalingFactor == 0) {
            shareRateScalingFactor = 1;
        }

        shareRate = shareRate
            .mul(1e18 + shareRateScalingFactor.mul(growthFactor))
            .div(1e18);
    }

    function setShareRateScalingFactor(uint256 _scalingFactor)
        external
        onlyManager
    {
        shareRateScalingFactor = _scalingFactor;
    }

    function maxShare(uint256 sessionId) external {
        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares != 0 && session.withdrawn == false,
            'STAKING: Stake withdrawn or not set'
        );

        (
            uint256 newStart,
            uint256 newEnd,
            uint256 newAmount,
            uint256 newShares
        ) =
            maxShareUpgrade(
                session.firstPayout,
                session.lastPayout,
                session.shares,
                session.amount
            );

        uint256 stakingDays = (session.end - session.start) / stepTimestamp;
        if (stakingDays >= basePeriod) {
            ISubBalances(addresses.subBalances).createMaxShareSession(
                sessionId,
                newStart,
                newEnd,
                newShares,
                session.shares
            );
        } else {
            ISubBalances(addresses.subBalances).callIncomeStakerTrigger(
                msg.sender,
                sessionId,
                newStart,
                newEnd,
                newShares
            );
        }

        maxShareInternal(
            sessionId,
            session.shares,
            newShares,
            session.amount,
            newAmount,
            newStart,
            newEnd
        );

        sessionDataOf[msg.sender][sessionId].amount = newAmount;
        sessionDataOf[msg.sender][sessionId].end = newEnd;
        sessionDataOf[msg.sender][sessionId].start = newStart;
        sessionDataOf[msg.sender][sessionId].shares = newShares;
        sessionDataOf[msg.sender][sessionId].firstPayout = payouts.length;
        sessionDataOf[msg.sender][sessionId].lastPayout = payouts.length + 5555;
    }

    function maxShareV1(uint256 sessionId) external {
        require(sessionId <= lastSessionIdV1, 'STAKING: Invalid sessionId');

        Session storage session = sessionDataOf[msg.sender][sessionId];

        require(
            session.shares == 0 && session.withdrawn == false,
            'STAKING: Stake withdrawn'
        );

        (
            uint256 amount,
            uint256 start,
            uint256 end,
            uint256 shares,
            uint256 firstPayout
        ) = stakingV1.sessionDataOf(msg.sender, sessionId);
        uint256 stakingDays = (end - start) / stepTimestamp;
        uint256 lastPayout = stakingDays + firstPayout;

        (
            uint256 newStart,
            uint256 newEnd,
            uint256 newAmount,
            uint256 newShares
        ) = maxShareUpgrade(firstPayout, lastPayout, shares, amount);

        if (stakingDays >= basePeriod) {
            ISubBalances(addresses.subBalances).createMaxShareSessionV1(
                msg.sender,
                sessionId,
                newStart,
                newEnd,
                newShares, // new shares
                shares // old shares
            );
        } else {
            ISubBalances(addresses.subBalances).callIncomeStakerTrigger(
                msg.sender,
                sessionId,
                newStart,
                newEnd,
                newShares
            );
        }

        sessionDataOf[msg.sender][sessionId] = Session({
            amount: newAmount,
            start: newStart,
            end: newEnd,
            shares: newShares,
            firstPayout: payouts.length,
            lastPayout: payouts.length + 5555,
            withdrawn: false,
            payout: 0
        });

        sessionsOf[msg.sender].push(sessionId);

        maxShareInternal(
            sessionId,
            shares,
            newShares,
            amount,
            newAmount,
            newStart,
            newEnd
        );
    }

    function maxShareUpgrade(
        uint256 firstPayout,
        uint256 lastPayout,
        uint256 shares,
        uint256 amount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            maxShareEventActive == true,
            'STAKING: Max Share event is not active'
        );
        require(
            lastPayout - firstPayout <= maxShareMaxDays,
            'STAKING: Max Share Upgrade - Stake must be less then max share max days'
        );

        uint256 stakingInterest =
            calculateStakingInterest(firstPayout, lastPayout, shares);

        uint256 newStart = now;
        uint256 newEnd = newStart + (stepTimestamp * 5555);
        uint256 newAmount = stakingInterest + amount;
        uint256 newShares =
            _getStakersSharesAmount(newAmount, newStart, newEnd);

        require(
            newShares > shares,
            'STAKING: New shares are not greater then previous shares'
        );

        return (newStart, newEnd, newAmount, newShares);
    }

    function maxShareInternal(
        uint256 sessionId,
        uint256 oldShares,
        uint256 newShares,
        uint256 oldAmount,
        uint256 newAmount,
        uint256 newStart,
        uint256 newEnd
    ) internal {
        sharesTotalSupply = sharesTotalSupply.add(newShares - oldShares);
        totalStakedAmount = totalStakedAmount.add(newAmount - oldAmount);
        totalVcaRegisteredShares = totalVcaRegisteredShares.add(newShares - oldShares);

        uint256 oldTotalSharesOf = totalSharesOf[msg.sender];
        totalSharesOf[msg.sender] = totalSharesOf[msg.sender].add(
            newShares - oldShares
        );

        rebalance(msg.sender, oldTotalSharesOf);

        emit MaxShareUpgrade(
            msg.sender,
            sessionId,
            oldAmount,
            newAmount,
            oldShares,
            newShares,
            newStart,
            newEnd
        );
    }

    // stepTimestamp
    // startContract
    function calculateStepsFromStart() public view returns (uint256) {
        return now.sub(startContract).div(stepTimestamp);
    }

    /** Set Max Shares */
    function setMaxShareEventActive(bool _active) external onlyManager {
        maxShareEventActive = _active;
    }

    function getMaxShareEventActive() external view returns (bool) {
        return maxShareEventActive;
    }

    function setMaxShareMaxDays(uint16 _maxShareMaxDays) external onlyManager {
        maxShareMaxDays = _maxShareMaxDays;
    }

    function getMaxShareMaxDays() external view returns (uint16) {
        return maxShareMaxDays;
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    /** Temporary */
    function setShareRate(uint256 _shareRate) external onlyManager {
        shareRate = _shareRate;
    }

    function getDivTokens() external view returns (address[] memory) {
        address[] memory divTokenAddresses = new address[](divTokens.length());

        for (uint8 i = 0; i < divTokens.length(); i++) {
            divTokenAddresses[i] = divTokens.at(i);
        }

        return divTokenAddresses;
    }

    function getTotalSharesOf(address account) external view returns (uint256) {
        return totalSharesOf[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IAuction {
    function callIncomeDailyTokensTrigger(uint256 amount) external;

    function callIncomeWeeklyTokensTrigger(uint256 amount) external;

    function addReservesToAuction(uint256 daysInFuture, uint256 amount) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStaking {
    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external;

    function updateTokenPricePerShare(
        address payable bidderAddress,
        address tokenAddress,
        uint256 amountBought
    ) external payable;

    function addDivToken(address tokenAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ISubBalances {
    function callIncomeStakerTrigger(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 shares
    ) external;

    function callOutcomeStakerTrigger(
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares
    ) external;

    function callOutcomeStakerTriggerV1(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 actualEnd,
        uint256 shares
    ) external;

    function createMaxShareSession(
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 newShares,
        uint256 oldShares
    ) external;

    function createMaxShareSessionV1(
        address staker,
        uint256 sessionId,
        uint256 start,
        uint256 end,
        uint256 newShares,
        uint256 oldShares
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStakingV1 {
    function sessionDataOf(address, uint256)
        external view returns (uint256, uint256, uint256, uint256, uint256);

    function sessionsOf_(address)
        external view returns (uint256[] memory);
}