// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../governance/ControllableV2.sol";
import "../../../openzeppelin/SafeERC20.sol";
import "../../../third_party/IDelegation.sol";
import "../../../third_party/balancer/IFeeDistributor.sol";
import "./IBalLocker.sol";
import "../../../third_party/curve/IGauge.sol";
import "../../../third_party/curve/IGaugeController.sol";
import "../../../third_party/balancer/IBalancerMinter.sol";


/// @title Dedicated contract for staking and managing veBAL
/// @author belbix
contract BalLocker is ControllableV2, IBalLocker {
  using SafeERC20 for IERC20;

  address public constant override VE_BAL = 0xC128a9954e6c874eA3d62ce62B468bA073093F25;
  address public constant override VE_BAL_UNDERLYING = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address public constant override BALANCER_MINTER = 0x239e55F427D44C3cc793f49bFB507ebe76638a2b;
  address public constant override BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
  uint256 private constant _MAX_LOCK = 365 * 86400;
  uint256 private constant _WEEK = 7 * 86400;

  address public override gaugeController;
  address public override feeDistributor;
  address public override operator;
  address public override voter;
  mapping(address => address) public gaugesToDepositors;

  event ChangeOperator(address oldValue, address newValue);
  event ChangeGaugeController(address oldValue, address newValue);
  event ChangeFeeDistributor(address oldValue, address newValue);
  event ChangeVoter(address oldValue, address newValue);
  event LinkGaugeToDistributor(address gauge, address depositor);

  constructor(
    address controller_,
    address operator_,
    address gaugeController_,
    address feeDistributor_
  ) {
    require(controller_ != address(0), "Zero controller");
    require(operator_ != address(0), "Zero operator");
    require(gaugeController_ != address(0), "Zero gaugeController");
    require(feeDistributor_ != address(0), "Zero feeDistributor");

    ControllableV2.initializeControllable(controller_);
    operator = operator_;
    gaugeController = gaugeController_;
    feeDistributor = feeDistributor_;
    // governance by default
    voter = IController(_controller()).governance();

    IERC20(VE_BAL_UNDERLYING).safeApprove(VE_BAL, type(uint).max);
  }

  modifier onlyGovernance() {
    require(_isGovernance(msg.sender), "Not gov");
    _;
  }

  modifier onlyVoter() {
    require(msg.sender == voter, "Not voter");
    _;
  }

  modifier onlyAllowedDepositor(address gauge) {
    require(gaugesToDepositors[gauge] == msg.sender, "Not allowed");
    _;
  }

  //*****************************************************************
  //********************* SNAPSHOT **********************************
  //*****************************************************************

  /// @dev Snapshot voting delegation. ID assumed to be a snapshot space name ex. name.eth
  function delegateVotes(
    bytes32 _id,
    address _delegateContract,
    address _delegate
  ) external override onlyVoter {
    IDelegation(_delegateContract).setDelegate(_id, _delegate);
  }

  /// @dev Clear snapshot voting delegation. ID assumed to be a snapshot space name ex. name.eth
  function clearDelegatedVotes(
    bytes32 _id,
    address _delegateContract
  ) external override onlyVoter {
    IDelegation(_delegateContract).clearDelegate(_id);
  }

  //*****************************************************************
  //********************* veBAL ACTIONS *****************************
  //*****************************************************************

  /// @dev Stake BAL-ETH LP to the veBAL with max lock. Extend period if necessary.
  ///      Without permissions - anyone can deposit.
  ///      Requires transfer tokens and call in the same block via contract.
  function depositVe(uint256 amount) external override {
    require(amount != 0, "Zero amount");

    // lock on max period
    IVotingEscrow ve = IVotingEscrow(VE_BAL);

    (uint balanceLocked, uint unlockTime) = ve.locked(address(this));
    if (unlockTime == 0 && balanceLocked == 0) {
      ve.create_lock(amount, block.timestamp + _MAX_LOCK);
    } else {
      ve.increase_amount(amount);

      uint256 unlockAt = block.timestamp + _MAX_LOCK;
      uint256 unlockInWeeks = (unlockAt / _WEEK) * _WEEK;

      //increase time too if over 2 week buffer
      if (unlockInWeeks > unlockTime && unlockInWeeks - unlockTime > 2) {
        ve.increase_unlock_time(unlockAt);
      }
    }
    IFeeDistributor(feeDistributor).checkpointUser(address(this));
  }

  /// @dev Claim rewards and send to recipient.
  ///      Only operator can call it.
  ///      Assume that claimed rewards will be immediately transfer to Polygon.
  function claimVeRewards(IERC20[] memory tokens, address recipient) external override {
    require(msg.sender == operator, "Not operator");
    require(recipient != address(0), "Zero recipient");

    IFeeDistributor(feeDistributor).claimTokens(address(this), tokens);

    // transfer all rewards to operator
    for (uint i; i < tokens.length; ++i) {
      IERC20 token = tokens[i];
      uint balance = token.balanceOf(address(this));
      if (balance != 0) {
        token.safeTransfer(recipient, balance);
      }
    }
  }

  /// @notice Return underlying balance under control.
  function investedUnderlyingBalance() external override view returns (uint) {
    (uint amount,) = IVotingEscrow(VE_BAL).locked(address(this));
    return amount;
  }

  //*****************************************************************
  //********************* GAUGES ACTIONS ****************************
  //*****************************************************************

  /// @dev Deposit to given gauge LP token. Sender should be linked to the gauge.
  function depositToGauge(address gauge, uint amount) external override onlyAllowedDepositor(gauge) {
    require(amount != 0, "Zero amount");
    require(gauge != address(0), "Zero gauge");

    address underlying = IGauge(gauge).lp_token();
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(underlying).safeApprove(gauge, 0);
    IERC20(underlying).safeApprove(gauge, amount);
    IGauge(gauge).deposit(amount, address(this), false);
  }

  /// @dev Withdraw from given gauge LP tokens. Sender should be linked to the gauge.
  function withdrawFromGauge(
    address gauge,
    uint amount
  ) external override onlyAllowedDepositor(gauge) {
    require(amount != 0, "Zero amount");
    require(gauge != address(0), "Zero gauge");

    IGauge(gauge).withdraw(amount, false);
    address underlying = IGauge(gauge).lp_token();
    IERC20(underlying).safeTransfer(msg.sender, amount);
  }

  /// @dev Claim rewards from given gauge. Sender should be linked to the gauge.
  function claimRewardsFromGauge(
    address gauge,
    address receiver
  ) external override onlyAllowedDepositor(gauge) {
    require(gauge != address(0), "Zero gauge");
    require(receiver != address(0), "Zero receiver");

    IGauge(gauge).claim_rewards(address(this), receiver);
  }

  /// @dev Claim rewards from BalancerMinter for given gauge. Sender should be linked to the gauge.
  function claimRewardsFromMinter(
    address gauge,
    address receiver
  ) external override onlyAllowedDepositor(gauge) returns (uint) {
    require(gauge != address(0), "Zero gauge");
    require(receiver != address(0), "Zero receiver");

    uint balance = IERC20(BAL).balanceOf(address(this));
    IBalancerMinter(BALANCER_MINTER).mint(gauge);
    uint claimed = IERC20(BAL).balanceOf(address(this)) - balance;
    IERC20(BAL).safeTransfer(receiver, claimed);
    return claimed;
  }

  //*****************************************************************
  //********************* veBAL VOTING ******************************
  //*****************************************************************

  /// @notice Allocate voting power for changing pool weights
  /// @param _gauges Gauges which _users votes for
  /// @param _userWeights Weights for gauges in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
  function voteForManyGaugeWeights(
    address[] memory _gauges,
    uint[] memory _userWeights
  ) external onlyVoter {
    require(_gauges.length == _userWeights.length, "Wrong input");
    for (uint i; i < _gauges.length; i++) {
      IGaugeController(gaugeController).vote_for_gauge_weights(_gauges[i], _userWeights[i]);
    }
  }

  //*****************************************************************
  //********************* GOV ACTIONS *******************************
  //*****************************************************************

  /// @dev Set a new operator address.
  function setOperator(address operator_) external onlyGovernance {
    require(operator_ != address(0), "Zero operator");
    emit ChangeOperator(operator, operator_);
    operator = operator_;
  }

  /// @dev Set a new gauge controller address.
  function setGaugeController(address value) external onlyGovernance {
    require(value != address(0), "Zero value");
    emit ChangeGaugeController(gaugeController, value);
    gaugeController = value;
  }

  /// @dev Set a new operator address.
  function setFeeDistributor(address value) external onlyGovernance {
    require(value != address(0), "Zero value");
    emit ChangeFeeDistributor(feeDistributor, value);
    feeDistributor = value;
  }

  /// @dev Set a new voter address.
  function setVoter(address value) external onlyVoter {
    require(value != address(0), "Zero value");
    emit ChangeVoter(voter, value);
    voter = value;
  }

  /// @dev Link an address to a gauge.
  ///      Governance can link a depositor only for not linked gauges.
  function linkDepositorsToGauges(
    address[] memory depositors,
    address[] memory gauges
  ) external onlyGovernance {
    for (uint i; i < depositors.length; i++) {
      address depositor = depositors[i];
      address gauge = gauges[i];
      require(gaugesToDepositors[gauge] == address(0), "Gauge already linked");
      gaugesToDepositors[gauge] = depositor;
      emit LinkGaugeToDistributor(gauge, depositor);
    }
  }

  /// @dev Transfer control under a gauge to another address.
  ///      Should have strict control and time-lock in the implementation.
  function changeDepositorToGaugeLink(address gauge, address newDepositor) external {
    address depositor = gaugesToDepositors[gauge];
    require(depositor == msg.sender, "Not depositor");
    gaugesToDepositors[gauge] = newDepositor;
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../openzeppelin/Initializable.sol";
import "../interface/IControllable.sol";
import "../interface/IControllableExtended.sol";
import "../interface/IController.sol";

/// @title Implement basic functionality for any contract that require strict control
///        V2 is optimised version for less gas consumption
/// @dev Can be used with upgradeable pattern.
///      Require call initializeControllable() in any case.
/// @author belbix
abstract contract ControllableV2 is Initializable, IControllable, IControllableExtended {

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param __controller Controller address
  function initializeControllable(address __controller) public initializer {
    _setController(__controller);
    _setCreated(block.timestamp);
    _setCreatedBlock(block.number);
    emit ContractInitialized(__controller, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Set a controller address to contract slot
  function _setController(address _newController) private {
    require(_newController != address(0));
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  /// @notice Return creation timestamp
  /// @return ts Creation timestamp
  function created() external view override returns (uint256 ts) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.timestamp
  function _setCreated(uint256 _value) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

  /// @notice Return creation block number
  /// @return ts Creation block number
  function createdBlock() external view returns (uint256 ts) {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      ts := sload(slot)
    }
  }

  /// @dev Filled only once when contract initialized
  /// @param _value block.number
  function _setCreatedBlock(uint256 _value) private {
    bytes32 slot = _CREATED_BLOCK_SLOT;
    assembly {
      sstore(slot, _value)
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IDelegation {
  function clearDelegate(bytes32 _id) external;

  function setDelegate(bytes32 _id, address _delegate) external;

  function delegation(address _address, bytes32 _id) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.4;

import "../../openzeppelin/IERC20.sol";
import "../curve/IVotingEscrow.sol";

/**
 * @title Fee Distributor
 * @notice Distributes any tokens transferred to the contract (e.g. Protocol fees and any BAL emissions) among veBAL
 * holders proportionally based on a snapshot of the week at which the tokens are sent to the FeeDistributor contract.
 * @dev Supports distributing arbitrarily many different tokens. In order to start distributing a new token to veBAL
 * holders simply transfer the tokens to the `FeeDistributor` contract and then call `checkpointToken`.
 */
interface IFeeDistributor {
  event TokenCheckpointed(IERC20 token, uint256 amount, uint256 lastCheckpointTimestamp);
  event TokensClaimed(address user, IERC20 token, uint256 amount, uint256 userTokenTimeCursor);

  /**
   * @notice Returns the VotingEscrow (veBAL) token contract
     */
  function getVotingEscrow() external view returns (IVotingEscrow);

  /**
   * @notice Returns the global time cursor representing the most earliest uncheckpointed week.
     */
  function getTimeCursor() external view returns (uint256);

  /**
   * @notice Returns the user-level time cursor representing the most earliest uncheckpointed week.
     * @param user - The address of the user to query.
     */
  function getUserTimeCursor(address user) external view returns (uint256);

  /**
   * @notice Returns the token-level time cursor storing the timestamp at up to which tokens have been distributed.
     * @param token - The ERC20 token address to query.
     */
  function getTokenTimeCursor(IERC20 token) external view returns (uint256);

  /**
   * @notice Returns the user-level time cursor storing the timestamp of the latest token distribution claimed.
     * @param user - The address of the user to query.
     * @param token - The ERC20 token address to query.
     */
  function getUserTokenTimeCursor(address user, IERC20 token) external view returns (uint256);

  /**
   * @notice Returns the user's cached balance of veBAL as of the provided timestamp.
     * @dev Only timestamps which fall on Thursdays 00:00:00 UTC will return correct values.
     * This function requires `user` to have been checkpointed past `timestamp` so that their balance is cached.
     * @param user - The address of the user of which to read the cached balance of.
     * @param timestamp - The timestamp at which to read the `user`'s cached balance at.
     */
  function getUserBalanceAtTimestamp(address user, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the cached total supply of veBAL as of the provided timestamp.
     * @dev Only timestamps which fall on Thursdays 00:00:00 UTC will return correct values.
     * This function requires the contract to have been checkpointed past `timestamp` so that the supply is cached.
     * @param timestamp - The timestamp at which to read the cached total supply at.
     */
  function getTotalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the FeeDistributor's cached balance of `token`.
     */
  function getTokenLastBalance(IERC20 token) external view returns (uint256);

  /**
   * @notice Returns the amount of `token` which the FeeDistributor received in the week beginning at `timestamp`.
     * @param token - The ERC20 token address to query.
     * @param timestamp - The timestamp corresponding to the beginning of the week of interest.
     */
  function getTokensDistributedInWeek(IERC20 token, uint256 timestamp) external view returns (uint256);

  // Depositing

  /**
   * @notice Deposits tokens to be distributed in the current week.
     * @dev Sending tokens directly to the FeeDistributor instead of using `depositTokens` may result in tokens being
     * retroactively distributed to past weeks, or for the distribution to carry over to future weeks.
     *
     * If for some reason `depositTokens` cannot be called, in order to ensure that all tokens are correctly distributed
     * manually call `checkpointToken` before and after the token transfer.
     * @param token - The ERC20 token address to distribute.
     * @param amount - The amount of tokens to deposit.
     */
  function depositToken(IERC20 token, uint256 amount) external;

  /**
   * @notice Deposits tokens to be distributed in the current week.
     * @dev A version of `depositToken` which supports depositing multiple `tokens` at once.
     * See `depositToken` for more details.
     * @param tokens - An array of ERC20 token addresses to distribute.
     * @param amounts - An array of token amounts to deposit.
     */
  function depositTokens(IERC20[] calldata tokens, uint256[] calldata amounts) external;

  // Checkpointing

  /**
   * @notice Caches the total supply of veBAL at the beginning of each week.
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     */
  function checkpoint() external;

  /**
   * @notice Caches the user's balance of veBAL at the beginning of each week.
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     * @param user - The address of the user to be checkpointed.
     */
  function checkpointUser(address user) external;

  /**
   * @notice Assigns any newly-received tokens held by the FeeDistributor to weekly distributions.
     * @dev Any `token` balance held by the FeeDistributor above that which is returned by `getTokenLastBalance`
     * will be distributed evenly across the time period since `token` was last checkpointed.
     *
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     * @param token - The ERC20 token address to be checkpointed.
     */
  function checkpointToken(IERC20 token) external;

  /**
   * @notice Assigns any newly-received tokens held by the FeeDistributor to weekly distributions.
     * @dev A version of `checkpointToken` which supports checkpointing multiple tokens.
     * See `checkpointToken` for more details.
     * @param tokens - An array of ERC20 token addresses to be checkpointed.
     */
  function checkpointTokens(IERC20[] calldata tokens) external;

  // Claiming

  /**
   * @notice Claims all pending distributions of the provided token for a user.
     * @dev It's not necessary to explicitly checkpoint before calling this function, it will ensure the FeeDistributor
     * is up to date before calculating the amount of tokens to be claimed.
     * @param user - The user on behalf of which to claim.
     * @param token - The ERC20 token address to be claimed.
     * @return The amount of `token` sent to `user` as a result of claiming.
     */
  function claimToken(address user, IERC20 token) external returns (uint256);

  /**
   * @notice Claims a number of tokens on behalf of a user.
     * @dev A version of `claimToken` which supports claiming multiple `tokens` on behalf of `user`.
     * See `claimToken` for more details.
     * @param user - The user on behalf of which to claim.
     * @param tokens - An array of ERC20 token addresses to be claimed.
     * @return An array of the amounts of each token in `tokens` sent to `user` as a result of claiming.
     */
  function claimTokens(address user, IERC20[] calldata tokens) external returns (uint256[] memory);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../../../openzeppelin/IERC20.sol";

interface IBalLocker {

  function VE_BAL() external view returns (address);

  function VE_BAL_UNDERLYING() external view returns (address);

  function BALANCER_MINTER() external view returns (address);

  function BAL() external view returns (address);

  function gaugeController() external view returns (address);

  function feeDistributor() external view returns (address);

  function operator() external view returns (address);

  function voter() external view returns (address);

  function delegateVotes(bytes32 _id, address _delegateContract, address _delegate) external;

  function clearDelegatedVotes(bytes32 _id, address _delegateContract) external;

  function depositVe(uint256 amount) external;

  function claimVeRewards(IERC20[] memory tokens, address recipient) external;

  function investedUnderlyingBalance() external view returns (uint);

  function depositToGauge(address gauge, uint amount) external;

  function withdrawFromGauge(address gauge, uint amount) external;

  function claimRewardsFromGauge(address gauge, address receiver) external;

  function claimRewardsFromMinter(address gauge, address receiver) external returns (uint claimed);

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IGauge {

  struct Reward {
    address token;
    address distributor;
    uint256 period_finish;
    uint256 rate;
    uint256 last_update;
    uint256 integral;
  }

  /// @notice Deposit `_value` LP tokens
  /// @dev Depositting also claims pending reward tokens
  /// @param _value Number of tokens to deposit
  function deposit(uint _value) external;

  function deposit(uint _value, address receiver, bool claim) external;

  /// @notice Get the number of claimable reward tokens for a user
  /// @dev This call does not consider pending claimable amount in `reward_contract`.
  ///      Off-chain callers should instead use `claimable_rewards_write` as a
  ///      view method.
  /// @param _addr Account to get reward amount for
  /// @param _token Token to get reward amount for
  /// @return uint256 Claimable reward token amount
  function claimable_reward(address _addr, address _token) external view returns (uint256);

  /// @notice Get the number of already-claimed reward tokens for a user
  /// @param _addr Account to get reward amount for
  /// @param _token Token to get reward amount for
  /// @return uint256 Total amount of `_token` already claimed by `_addr`
  function claimed_reward(address _addr, address _token) external view returns (uint256);

  /// @notice Get the number of claimable reward tokens for a user
  /// @dev This function should be manually changed to "view" in the ABI
  ///     Calling it via a transaction will claim available reward tokens
  /// @param _addr Account to get reward amount for
  /// @param _token Token to get reward amount for
  /// @return uint256 Claimable reward token amount
  function claimable_reward_write(address _addr, address _token) external returns (uint256);

  /// @notice Withdraw `_value` LP tokens
  /// @dev Withdrawing also claims pending reward tokens
  /// @param _value Number of tokens to withdraw
  function withdraw(uint _value, bool) external;

  function claim_rewards(address _addr) external;

  function claim_rewards(address _addr, address receiver) external;

  function balanceOf(address) external view returns (uint);

  function lp_token() external view returns (address);

  function deposit_reward_token(address reward_token, uint256 amount) external;

  function add_reward(address reward_token, address distributor) external;

  function reward_tokens(uint id) external view returns (address);

  function reward_data(address token) external view returns (Reward memory);

  function reward_count() external view returns (uint);

  function initialize(address lp) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IGaugeController {

  function vote_for_many_gauge_weights(address[] memory _gauges, uint[] memory _userWeights) external;

  function vote_for_gauge_weights(address gauge, uint weight) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IBalancerMinter {
  event Minted(address indexed recipient, address gauge, uint256 minted);
  event MinterApprovalSet(
    address indexed user,
    address indexed minter,
    bool approval
  );

  function allowed_to_mint_for(address minter, address user)
  external
  view
  returns (bool);

  function getBalancerToken() external view returns (address);

  function getBalancerTokenAdmin() external view returns (address);

  function getDomainSeparator() external view returns (bytes32);

  function getGaugeController() external view returns (address);

  function getMinterApproval(address minter, address user)
  external
  view
  returns (bool);

  function getNextNonce(address user) external view returns (uint256);

  function mint(address gauge) external returns (uint256);

  function mintFor(address gauge, address user) external returns (uint256);

  function mintMany(address[] memory gauges) external returns (uint256);

  function mintManyFor(address[] memory gauges, address user)
  external
  returns (uint256);

  function mint_for(address gauge, address user) external;

  function mint_many(address[8] memory gauges) external;

  function minted(address user, address gauge)
  external
  view
  returns (uint256);

  function setMinterApproval(address minter, bool approval) external;

  function setMinterApprovalWithSignature(
    address minter,
    bool approval,
    address user,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function toggle_approve_mint(address minter) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

/// @dev This interface contains additional functions for Controllable class
///      Don't extend the exist Controllable for the reason of huge coherence
interface IControllableExtended {

  function created() external view returns (uint256 ts);

  function controller() external view returns (address adr);

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IController {

  function addVaultsAndStrategies(address[] memory _vaults, address[] memory _strategies) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function dao() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function fundToken() external view returns (address);

  function psVault() external view returns (address);

  function fund() external view returns (address);

  function distributor() external view returns (address);

  function announcer() external view returns (address);

  function vaultController() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function fundNumerator() external view returns (uint256);

  function fundDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isDao(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isPoorRewardConsumer(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);

  function isValidStrategy(address _strategy) external view returns (bool);

  function rebalance(address _strategy) external;

  // ************ DAO ACTIONS *************
  function setPSNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function setFundNumeratorDenominator(uint256 numerator, uint256 denominator) external;

  function changeWhiteListStatus(address[] calldata _targets, bool status) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

interface IVotingEscrow {

  struct Point {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts;
    uint256 blk; // block
  }

  function balanceOf(address addr) external view returns (uint);

  function balanceOfAt(address addr, uint block_) external view returns (uint);

  function totalSupply() external view returns (uint);

  function totalSupplyAt(uint block_) external view returns (uint);

  function locked(address user) external view returns (uint amount, uint end);

  function create_lock(uint value, uint unlock_time) external;

  function increase_amount(uint value) external;

  function increase_unlock_time(uint unlock_time) external;

  function withdraw() external;

  function commit_smart_wallet_checker(address addr) external;

  function apply_smart_wallet_checker() external;

  function user_point_history(address user, uint256 timestamp) external view returns (Point memory);

  function user_point_epoch(address user) external view returns (uint256);

}