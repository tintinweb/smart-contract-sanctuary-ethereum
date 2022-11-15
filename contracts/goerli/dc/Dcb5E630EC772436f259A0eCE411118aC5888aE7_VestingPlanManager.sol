// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

struct VestingPlan {
  address receiver;
  address sponsor;
  IERC20 token;
  uint256 amount;
  uint256 cliff;
  uint256 periodDuration;
  uint256 eventCount;
}

interface IVestingPlanManager {
  event CreatePlan(
    address _receiver,
    address _sponsor,
    IERC20 _token,
    uint256 _amount,
    uint256 _cliff,
    uint256 _period,
    uint256 _duration,
    string _memo,
    uint256 _planId
  );

  event TerminatePlan(uint256 _planId, address _receiver, IERC20 _token, uint256 _amount);

  event DistributeAward(
    uint256 _planId,
    address _receiver,
    IERC20 _token,
    uint256 _amount,
    uint256 _total,
    uint256 _remaining
  );
}

/**
 * @notice A trustless contract to manage ERC20 token vesting plans. There is no administration functionality. Plan creators can create plans and terminate them. Plan termination will first distribute any already-vested tokens. Vested tokens can be distributed trustlessly by any account. Vesting plans are immutable, but can be terminated early.
 */
contract VestingPlanManager is IVestingPlanManager {
  //*********************************************************************//
  // ------------------------- Custom Errors --------------------------- //
  //*********************************************************************//

  /**
   * @notice Plan with this configuration already exists.
   */
  error DUPLICATE_CONFIGURATION();

  /**
   * @notice Plan configuration has a 0 amount.
   */
  error INVALID_CONFIGURATION();

  /**
   * @notice Could not take custody of ERC20 tokens for the plan being created.
   */
  error FUNDING_FAILED();

  /**
   * @notice Plan does not exist.
   */
  error INVALID_PLAN();

  error CLIFF_NOT_REACHED();
  error INCOMPLETE_PERIOD();
  error DISTRIBUTION_FAILED();

  /**
   * @notice Attempt to call a function that only plan originator can execute.
   */
  error UNAUTHORIZED();

  mapping(address => uint256[]) public receiverIdMap;
  mapping(uint256 => address) public idReceiverMap;
  mapping(address => uint256[]) public sponsorIdMap;
  mapping(uint256 => address) public idSponsorMap;
  mapping(uint256 => VestingPlan) public plans;
  mapping(uint256 => uint256) public distributions;

  //*********************************************************************//
  // ---------------------- Public Transactions ------------------------ //
  //*********************************************************************//

  /**
   * @notice Creates a vesting plan. Emits a `CreatePlan` event.
   *
   * @dev Plan id is generated from incoming parameters and is published in the `CreatePlan` event.
   *
   * @param _receiver Receiver of the tokens.
   * @param _token ERC20 token to distribute.
   * @param _amount Token amount to distribute each vesting period.
   * @param _cliff Vesting cliff for the first distribution.
   * @param _periodDuration Vesting period duration in seconds.
   * @param _eventCount Number of periods to schedule.
   * @param _memo String to include in the emitted CreatePlan event.
   */
  function create(
    address _receiver,
    IERC20 _token,
    uint256 _amount,
    uint256 _cliff,
    uint256 _periodDuration,
    uint256 _eventCount,
    string calldata _memo
  ) public returns (uint256 planId) {
    planId = uint256(
      keccak256(
        abi.encodePacked(
          _receiver,
          msg.sender,
          address(_token),
          _amount,
          _cliff,
          _periodDuration,
          _eventCount // TODO: consider adding _memo for entropy?
        )
      )
    );

    if (idSponsorMap[planId] != address(0) || idReceiverMap[planId] != address(0)) {
      revert DUPLICATE_CONFIGURATION();
    }

    if (_amount == 0) {
      revert INVALID_CONFIGURATION();
    }

    if (!_token.transferFrom(msg.sender, address(this), _amount * _eventCount)) {
      revert FUNDING_FAILED();
    }

    receiverIdMap[_receiver].push(planId);
    idReceiverMap[planId] = _receiver;
    sponsorIdMap[msg.sender].push(planId);
    idSponsorMap[planId] = msg.sender;
    plans[planId] = VestingPlan(
      _receiver,
      msg.sender,
      _token,
      _amount,
      _cliff,
      _periodDuration,
      _eventCount
    );

    emit CreatePlan(
      _receiver,
      msg.sender,
      _token,
      _amount,
      _cliff,
      _periodDuration,
      _eventCount,
      _memo,
      planId
    );
  }

  /**
   * @notice Terminates a vesting plan in progress. This method is only available to the account that set up the plan originally. Before the plan record is removed any vested, but not distributed balance is sent out to the receiver.
   *
   * @param _id Vesting plan id.
   */
  function terminate(uint256 _id) public {
    if (plans[_id].amount == 0) {
      revert INVALID_PLAN();
    }

    VestingPlan memory plan = plans[_id];

    if (plan.sponsor != msg.sender) {
      revert UNAUTHORIZED();
    }

    if (
      block.timestamp >= plan.cliff && distributions[_id] + plan.periodDuration < block.timestamp
    ) {
      _distribute(_id, plan);
    }

    (uint256 remainingBalance, ) = unvestedBalance(_id);
    if (!plan.token.transfer(plan.sponsor, remainingBalance)) {
      revert DISTRIBUTION_FAILED();
    }

    delete plans[_id];

    emit TerminatePlan(_id, plan.receiver, plan.token, plan.amount);
  }

  /**
   * @notice A trustless function to distribute tokens, if available, from a given plan.
   *
   * @param _id Vesting plan id.
   */
  function distribute(uint256 _id) public {
    if (plans[_id].amount == 0) {
      revert INVALID_PLAN();
    }

    VestingPlan memory plan = plans[_id];

    if (block.timestamp < plan.cliff) {
      revert CLIFF_NOT_REACHED();
    }

    if (distributions[_id] + plan.periodDuration > block.timestamp) {
      revert INCOMPLETE_PERIOD();
    }

    _distribute(_id, plan);
  }

  //*********************************************************************//
  // ----------------------------- Views ------------------------------- //
  //*********************************************************************//

  /**
   * @notice Returns a `VestingPlan` struct and the end of the most-recently claimed distribution period.
   *
   * @param _id Vesting plan id.
   */
  function planDetails(uint256 _id) public view returns (VestingPlan memory, uint256) {
    if (plans[_id].amount == 0) {
      revert INVALID_PLAN();
    }

    return (plans[_id], distributions[_id]);
  }

  /**
   * @notice Returns the unvested amount and token for a given plan.
   *
   * @param _id Vesting plan id.
   */
  function unvestedBalance(uint256 _id)
    public
    view
    returns (uint256 remainingBalance, IERC20 token)
  {
    if (plans[_id].amount == 0) {
      revert INVALID_PLAN();
    }

    VestingPlan memory plan = plans[_id];

    uint256 elapsedPeriods = ((block.timestamp - plan.cliff) / plan.periodDuration) + 1;
    uint256 remainingPeriods = plan.eventCount - elapsedPeriods;
    remainingBalance = remainingPeriods * plan.amount;
    token = plan.token;
  }

  //*********************************************************************//
  // ----------------------- Private Transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Internal method to calculate current distribution amount.
   */
  function _distributionAmount(uint256 _id, VestingPlan memory plan)
    private
    view
    returns (uint256 distribution, uint256 elapsedPeriodsBoundary)
  {
    uint256 elapsedPeriods = ((block.timestamp - plan.cliff) / plan.periodDuration) + 1;
    elapsedPeriodsBoundary = elapsedPeriods * plan.periodDuration + plan.cliff;
    uint256 pendingPeriods = elapsedPeriods;
    if (distributions[_id] != 0) {
      pendingPeriods = (elapsedPeriodsBoundary - distributions[_id]) / plan.periodDuration;
    }
    distribution = plan.amount * pendingPeriods;
  }

  /**
   * @notice Internal operation to send current distribution to the plan receiver. Generates a `DistributeAward` event.
   */
  function _distribute(uint256 _id, VestingPlan memory _plan) private {
    (uint256 distribution, uint256 elapsedPeriodsBoundary) = _distributionAmount(_id, _plan);

    distributions[_id] = elapsedPeriodsBoundary;

    if (!_plan.token.transfer(_plan.receiver, distribution)) {
      revert DISTRIBUTION_FAILED();
    }

    (uint256 remainingBalance, ) = unvestedBalance(_id);

    emit DistributeAward(
      _id,
      _plan.receiver,
      _plan.token,
      _plan.amount,
      distribution,
      remainingBalance
    ); // TODO: consider addding remaining duration
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