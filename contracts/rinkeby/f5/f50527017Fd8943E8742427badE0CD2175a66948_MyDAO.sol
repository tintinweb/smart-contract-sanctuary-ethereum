//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './IMyStaking.sol';
import './IMyDAO.sol';

contract MyDAO is AccessControl, IMyDAO {
  using SafeERC20 for IERC20;

  // Accessing role to propose votings
  bytes32 public constant CHAIR_ROLE = keccak256("CHAIR_ROLE");

  // Accessing role to call approveUnstake func
  bytes32 public constant UNSTAKER_ROLE = keccak256("UNSTAKER_ROLE");

  // Minimum quorum
  uint256 public override minimumQuorum;

  // Period of votings in hours that assigned in constructor once
  uint256 public immutable override debatingPeriodDuration;

  // Address of voting tokens contract
  address public override voteTokenAddr;

  // Votind Id counter "can increment only"
  uint256 public override votingCount;

  // Charman counter
  uint256 public override chairManCount;

  IERC20 voteToken;
  IMyStaking staking;

  /**
   * @dev Structure oh one voting
   * @param actual is this voting actual
   * @param startTime
   * @param description description of proposal
   * @param callData data for contract call
   * @param recipient: address of calling contract
   * @param totalVotes: total amoumt of votes
   * @param agreeVotes: amount of agree votes
   * @param voters: mapping from voter's address to flag is he already voted
   * @param delegations: mapping from voter's address to address to whom delegated
   * @param delegatedTotalBalance: mapping from voter's address to all amount
   *        that was delegeted to him
   */
  struct Voting {
    bool actual;
    uint startTime;
    string description;
    bytes callData;
    address recipient;
    uint256 totalVotes;
    uint256 agreeVotes;
    mapping(address => bool) voters;
    mapping(address => address) delegations;
    mapping(address => uint256) delegatedTotalBalance;
  }

  // Unordered array of actual votings
  uint256[] private actualVotingsIds;

  // Mapping from id to votings
  mapping(uint256 => Voting) public override votings;


  /**
   * @dev constructor
   * @param _chairPerson first chairMan of the contract
   * @param _staking staking contract
   * @param _minimumQuorum initial quorum
   * @param _debatingPeriodDuration debating period. Can't be changed in futher
   *        time
   */
  constructor(address _chairPerson, IMyStaking _staking,
      uint256 _minimumQuorum, uint _debatingPeriodDuration) {

    require(_chairPerson != address(0), "Address of chair person can not be zero");
    require(_debatingPeriodDuration != 0, "Debating period can not be zero");

    _setupRole(DEFAULT_ADMIN_ROLE, address(this));
    _grantRole(CHAIR_ROLE, _chairPerson);
    _grantRole(UNSTAKER_ROLE, address(_staking));
    chairManCount = 1;

    staking = _staking;
    minimumQuorum = _minimumQuorum;
    debatingPeriodDuration = _debatingPeriodDuration;
  }

  // See IMyDAO-approveUnstake
  function approveUnstake(address _sender, uint256 _amount, uint256 _balance)
      public virtual override{
    require(hasRole(UNSTAKER_ROLE, msg.sender), "Caller is not an unstaker");
    for (uint i = 0; i < actualVotingsIds.length; i++) {
      uint256 id = actualVotingsIds[i];
      Voting storage vt = votings[id];
      require(!vt.voters[_sender],
        "Unstake operation reverted due to participating in actual voting");
      address delegator = vt.delegations[_sender];
      require(!vt.voters[delegator],
        "Unstake operation reverted due to delegating in actual voting");
      if (vt.delegations[_sender] != address(0)) {
        vt.delegations[_sender] = address(0);
        vt.delegatedTotalBalance[delegator] -= _balance;
      }
    }
  }

  // See IMyDAO-addProposal
  function addProposal(bytes memory _callData, address _recipient,
      string memory _description) public virtual override {
    require(hasRole(CHAIR_ROLE, msg.sender), "Caller is not a chairman");
    uint256 votingId = votingCount;
    votingCount += 1;
    Voting storage vt = votings[votingId];
    vt.actual = true;
    vt.startTime = block.timestamp;
    vt.description = _description;
    vt.callData = _callData;
    vt.recipient = _recipient;
    vt.totalVotes = 0;
    vt.agreeVotes = 0;
    actualVotingsIds.push(votingId);
    emit NewVotingAdded(votingId, _description);
  }

  // See IMyDAO-delegate
  function delegate(uint256 _votingId, address _to) public virtual override {
    (uint256 balance,,,)= staking.stakes(msg.sender);
    require(balance != 0, "No tokens to vote");
    (uint256 balanceTo,,,)= staking.stakes(_to);
    require(balanceTo != 0, "This account cannot vote");
    require(msg.sender != _to, "Voter cannot delegate himself");
    Voting storage vt = votings[_votingId];
    require(vt.actual, "This voting is not actual");
    require(!vt.voters[_to], "The voter already voted");
    address sideDelegated = vt.delegations[_to];
    require(!vt.voters[sideDelegated],
      "This voter delegate his votes to some voter and that voter already voted");
    require(vt.delegations[msg.sender] == address(0),
      "The votes are already delegated. Undelegate them to redelegate");
    vt.delegatedTotalBalance[_to] += balance;
    vt.delegations[msg.sender] = _to;
  }

  // See IMyDAO-unDelegate
  function unDelegate(uint256 _votingId) public virtual override {
    (uint256 balance,,,)= staking.stakes(msg.sender);
    require(balance != 0, "No tokens to vote");
    Voting storage vt = votings[_votingId];
    require(vt.actual, "This voting is not actual");
    address delegated = vt.delegations[msg.sender];
    require(delegated != address(0), "Nothing to undelegate");
    require(!vt.voters[delegated], "The voter already voted");
    vt.delegations[msg.sender] = address(0);
    vt.delegatedTotalBalance[delegated] -= balance;
  }

  // See IMyDAO-vote
  function vote(uint256 _votingId, bool _agree) public virtual override {
    (uint256 balance,,,)= staking.stakes(msg.sender);
    require(balance != 0, "No tokens to vote");
    Voting storage vt = votings[_votingId];
    require(vt.actual, "This voting is not actual");
    require(block.timestamp < vt.startTime + debatingPeriodDuration * 1 hours,
      "The time of voting is elapsed");
    require(!vt.voters[msg.sender], "The voter already voted");
    address delegator = vt.delegations[msg.sender];
    require(!vt.voters[delegator],
      "The voter delegate his votes and delegator already voted");
    vt.voters[msg.sender] = true;
    if (delegator != address(0)) {
      vt.delegatedTotalBalance[delegator] -= balance;
    }
    vt.delegations[msg.sender] = address(0);
    uint256 amount = balance;
    amount += vt.delegatedTotalBalance[msg.sender];
    if (_agree) {
      vt.totalVotes += amount;
      vt.agreeVotes += amount;
    } else {
      vt.totalVotes += amount;
    }
    emit Vote(_votingId, msg.sender, _agree, amount);
  }

  // See IMyDAO-finishProposal
  function finishProposal(uint256 _votingId) public virtual override{
    Voting storage vt = votings[_votingId];
    require(vt.actual, "This voting is not actual");
    require(block.timestamp > vt.startTime + debatingPeriodDuration * 1 hours,
      "The time of voting is not elapsed");
    vt.actual = false;
    if (vt.totalVotes >= minimumQuorum) {
      if (vt.totalVotes - vt.agreeVotes >= vt.agreeVotes) {
        emit VotingOver(_votingId, false);
      } else {
        (bool sucsess, ) = vt.recipient.call(vt.callData);
        require(sucsess, "ERROR call func");
        emit VotingOver(_votingId, true);
      }
    }
    for (uint i = 0; i < actualVotingsIds.length; i++) {
      if (actualVotingsIds[i] == _votingId) {
        actualVotingsIds[i] = actualVotingsIds[actualVotingsIds.length - 1];
        actualVotingsIds.pop();
        break;
      }
    }
  }

  /**
   * @dev Function for adding new chairman of votings. The function can be called
   * only from the contract by finishing appropriate voting.
   * In case of reentrancy by group of voters (and some chairman) the maximum
   * demadge is that the dublicated votings will remain aqtual forever.
   * @param newChairman address.
   * return true if success.
   */
  function addChairMan(address newChairman) public returns(bool) {
    require(msg.sender == address(this), "This function can be called only from voting");
    require(!hasRole(CHAIR_ROLE, newChairman));
    chairManCount += 1;
    _grantRole(CHAIR_ROLE, newChairman);
    return true;
  }

  /**
   * @dev Function for removing chairman of votings. There must be more than one
   * chairman in contract to call the function. The function can be called
   * only from the contract by finishing appropriate voting.
   * @param chairMan address for remove.
   * return true if success.
   */
  function removeChairMan(address chairMan) public returns(bool) {
    require(msg.sender == address(this), "This function can be called only from voting");
    require(chairManCount > 1, "Can not leave contract without chairman");
    chairManCount -= 1;
    _revokeRole(CHAIR_ROLE, chairMan);
    return true;
  }

  /**
   * @dev Function for reset minimum quorum. The function can be called
   * only from the contract by finishing appropriate voting.
   * @param newQuorum.
   * return true if success.
   */
  function resetMinimumQuorum(uint256 newQuorum) public returns(bool) {
    require(msg.sender == address(this), "This function can be called only from voting");
    minimumQuorum = newQuorum;
    return true;
  }

  // See IMyDAO-getActualVotingsIdsLength
  function getActualVotingsIdsLength() public view virtual override returns(uint256) {
    return actualVotingsIds.length;
  }

  // See IMyDAO-getIsVoted
  function getIsVoted(uint256 _votingId, address _voter) public view
      virtual override returns(bool) {
    return votings[_votingId].voters[_voter];
  }

  // See IMyDAO-getDelegated
  function getDelegated(uint256 _votingId, address _delegetor) public
      view virtual override returns(address) {
    return votings[_votingId].delegations[_delegetor];
  }

  // See IMyDAO-getDelegatedTotalBalance
  function getDelegatedTotalBalance(uint256 _votingId, address _delegeted)
      public view virtual override returns(uint256) {
    return votings[_votingId].delegatedTotalBalance[_delegeted];
  }

  // See IMyDAO-getActualVotingsIds
  function getActualVotingsIds() public view virtual override
      returns(uint256[] memory) {
    return actualVotingsIds;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IMyStaking {

  /**
   * @dev Emitted when stake done.
   *
   * `_from` is the account that made this stake.
   * '__value' is amount of lp tokens staked.
   */
  event StakeDone(address indexed _from, uint _value);

  /**
   * @dev Emitted when claim done.
   *
   * `_to` is the account that made this claim reward.
   * '__value' is amount of reward tokens transfered.
   */
  event Claim(address indexed _to, uint _value);

  /**
   * @dev Emitted when unstake done.
   *
   * `_to` is the account that made this unstake.
   * '__value' is amount of lp tokens to return.
   */
  event Unstake(address indexed _to, uint _value);

  /**
   * @dev Return the period of reward in seconds.
   */
  function rewardPeriod() external view returns (uint);

  /**
   * @dev Return the period of lock of lp tokens in seconds.
   */
  function lockPeriod() external view returns (uint);

  /**
   * @dev Return the reward procents.
   */
  function rewardProcents() external view returns (uint256);

  /**
   * @dev Return address of DAO contract that deployed by this contract.
   */
  function daoContractAddress() external view returns (address);

  /**
   * @dev Mapping from staker to record about user's staking.
   */
  function stakes(address staker) external view returns (uint256, uint256, uint, uint);

  /**
   * @dev Moves `_amount` lp tokens from the caller's account to this contract.
   *
   * Emits a {StakeDone} event.
   */
  function stake(uint256 _amount) external;

  /**
   * @dev Calculate rewards of each user's stake and transfer resulted amount
   * of tokens to user. In each stake's timestamp for reward estimation is updated.
   *
   * Emits a {StakeDone} event.
   */
  function claim() external;

  /**
   * @dev Unstake lp tokens. Function become available after lock period expire.
   *
   * Emits a {Unstake} event.
   */
  function unstake(uint256 _amount) external;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IMyDAO  {
  /* *
   * @dev Emitted when voting with 'votingId' finished with some 'result'.
   */
  event NewVotingAdded(
    uint256 votingId,
    string description
  );

  /* *
   * @dev Emitted when anybody voted in voting 'votingId' for 'result' with
   * 'amount' of votes.
   */
  event Vote(
    uint256 votingId,
    address voter,
    bool result,
    uint256 amount
  );

  /* *
   * @dev Emitted when voting with 'votingId' finished with some 'result'.
   */
  event VotingOver(
    uint256 votingId,
    bool result
  );


  /**
   * @dev Function for approving unstaking of staking contract.
   * @param _sender: address of unstaking user.
   * @param _amount: unstaked amount.
   * @param _balance staked balance of user.
   */
  function approveUnstake(address _sender, uint256 _amount, uint256 _balance) external;

  /**
   * @dev Only chairmans can propose votings.
   * @param _callData: data for call an external contract.
   * @param _recipient: address of an external contract.
   * @param _description of call.
   * emit NewVotingAdded.
   */
  function addProposal(bytes memory _callData, address _recipient,
      string memory _description) external;

  /**
   * @dev Delegate votes to some person. That person should have voting tokens.
   * @param _votingId of voting for votes delegated.
   * @param _to: address to whom delegated.
   */
  function delegate(uint256 _votingId, address _to) external;

  /**
   * @dev Undelegate votes.
   * @param _votingId of voting for votes undelegated.
   */
  function unDelegate(uint256 _votingId) external;

  /**
   * @dev Vote for proposal.
   * @param _votingId of voting.
   * @param _agree: agreement or disagreement for a proposal.
   */
  function vote(uint256 _votingId, bool _agree) external;

  /**
   * @dev Finish voting for proposal. Anybody can call this function.
   * @param _votingId of voting.
   * emit Vote
   */
  function finishProposal(uint256 _votingId) external;

  //Getters

  // Minimum quorum
  /**
   * @dev Getter for actual votings array length.
   */
  function minimumQuorum() external view returns(uint256);

  // Period of votings in hours that assigned in constructor once
  /**
   * @dev Getter for actual votings array length.
   */
  function debatingPeriodDuration() external view returns(uint256);

  // Address of voting tokens contract
  /**
   * @dev Getter for actual votings array length.
   */
  function voteTokenAddr() external view returns(address);

  // Votind Id number
  /**
   * @dev Getter for actual votings array length.
   */
  function votingCount() external view returns(uint256);

  // Charman number
  /**
   * @dev Getter for actual votings array length
   */
  function chairManCount() external view returns(uint256);

  // Unordered array of actual votings
  /**
   * @dev Getter for actual votings array length
   */
  function getActualVotingsIds() external view returns(uint256[] memory);

  // Get votings common parametrs by id
  /**
   * @dev Getter for actual votings array length
   */
  function votings(uint256 votingId) external view
    returns(bool actual,
            uint startTime,
            string memory description,
            bytes memory callData,
            address recipient,
            uint256 totalVotes,
            uint256 agreeVotes);

  /**
   * @dev Getter for actual votings array length
   */
  function getIsVoted(uint256 _votingId, address _voter) external view
    returns(bool);

  /**
   * @dev Getter for actual votings array length
   */
  function getDelegated(uint256 _votingId, address _delegetor) external
    view returns(address);

  /**
   * @dev Getter for actual votings array length
   */
  function getDelegatedTotalBalance(uint256 _votingId, address _delegeted)
      external view returns(uint256);

  /**
   * @dev Getter for actual votings array length
   */
  function getActualVotingsIdsLength() external view returns(uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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