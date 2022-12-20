// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import {MNTToken} from './MNTToken.sol';
import {VotingEscrow} from './VotingEscrow.sol';

/**
 * @title Gauge Controller
 * @author Monetaria
 * @notice Controls liquidity gauges and the issuance of coins through the gauges
 */
 
contract GaugeController {
  // 7 * 86400 seconds - all future times are rounded by week
  uint256 constant WEEK = 604800;

  // Cannot change weight votes more often than once in 10 days
  uint256 constant WEIGHT_VOTE_DELAY = 10 * 86400;

  struct Point {
    uint256 bias;
    uint256 slope;
  }

  struct VotedSlope {
    uint256 slope;
    uint256 power;
    uint256 end;
  }

  event CommitOwnership (
    address admin
  );

  event ApplyOwnership (
    address admin
  );

  event AddType (
    string name,
    int128 type_id
  );

  event NewTypeWeight (
    int128 type_id,
    uint256 time,
    uint256 weight,
    uint256 total_weight
  );

  event NewGaugeWeight (
    address gauge_address,
    uint256 time,
    uint256 weight,
    uint256 total_weight
  );

  event VoteForGauge (
    uint256 time,
    address user,
    address gauge_addr,
    uint256 weight
  );

  event NewGauge (
    address addr,
    int128 gauge_type,
    uint256 weight
  );


  uint256 constant MULTIPLIER = 10 ** 18;

  address public admin;  // Can and will be a smart contract
  address public future_admin;  // Can and will be a smart contract

  address public token;  // MNT token
  address public voting_escrow;  // Voting escrow

  // Gauge parameters
  // All numbers are "fixed point" on the basis of 1e18
  int128 public n_gauge_types;
  int128 public n_gauges;
  mapping(int128 => string) public gauge_type_names;

  // Needed for enumeration
  address[1000000000] public gauges;

  // we increment values by 1 prior to storing them here so we can rely on a value
  // of zero as meaning the gauge has not been set
  mapping(address => int128) gauge_types_;

  mapping(address => mapping(address => VotedSlope)) public vote_user_slopes; // user -> gauge_addr -> VotedSlope
  mapping(address => uint256) public vote_user_power; // Total vote power used by user
  mapping(address => mapping(address => uint256)) public last_user_vote; // Last user vote's timestamp for each gauge address

  // Past and scheduled points for gauge weight, sum of weights per type, total weight
  // Point is for bias+slope
  // changes_* are for changes in slope
  // time_* are for the last change timestamp
  // timestamps are rounded to whole weeks

  mapping(address => mapping(uint256 => Point)) public points_weight; // gauge_addr -> time -> Point
  mapping(address => mapping(uint256 => uint256)) changes_weight; // gauge_addr -> time -> slope
  mapping(address => uint256) public time_weight; // gauge_addr -> last scheduled time (next week)

  mapping(int128 => mapping(uint256 => Point)) public points_sum; // type_id -> time -> Point
  mapping(int128 => mapping(uint256 => uint256)) changes_sum; // type_id -> time -> slope
  uint256[1000000000] public time_sum; // type_id -> last scheduled time (next week)

  mapping(uint256 => uint256) public points_total; // time -> total weight
  uint256 public time_total; // last scheduled time

  mapping(int128 => mapping(uint256 => uint256)) public points_type_weight; // type_id -> time -> type weight
  uint256[1000000000] public time_type_weight;  // type_id -> last scheduled time (next week)

  /**
    @notice Contract constructor
    @param _token `MNTToken` contract address
    @param _voting_escrow `VotingEscrow` contract address
   */
  constructor(address _token, address _voting_escrow) {
    require(_token != address(0));
    require(_voting_escrow != address(0));

    admin = msg.sender;
    token = _token;
    voting_escrow = _voting_escrow;
    time_total = block.timestamp / WEEK * WEEK;
  }

  /**
    @notice Transfer ownership of GaugeController to `addr`
    @param addr Address to have ownership transferred to
   */
  function commit_transfer_ownership(address addr) external {
    require(msg.sender == admin);  // dev: admin only
    future_admin = addr;
    emit CommitOwnership(addr);
  }

  /**
    @notice Apply pending ownership transfer
   */
  function apply_transfer_ownership() external {
    require(msg.sender == admin);  // dev: admin only
    address _admin = future_admin;
    require(_admin != address(0));  // dev: admin not set
    admin = _admin;
    emit ApplyOwnership(_admin);
  }

  /**
    @notice Get gauge type for address
    @param _addr Gauge address
    @return Gauge type id
   */
  function gauge_types(address _addr) external view returns(int128){
    int128 gauge_type = gauge_types_[_addr];
    require(gauge_type != 0);

    return gauge_type - 1;
  }

  /**
    @notice Fill historic type weights week-over-week for missed checkins
            and return the type weight for the future week
    @param gauge_type Gauge type id
    @return Type weight
   */
  function _get_type_weight(int128 gauge_type) internal returns(uint256){
    uint256 t = time_type_weight[uint256(int256(gauge_type))];
    if (t > 0) {
      uint256 w = points_type_weight[gauge_type][t];
      for(int i = 0; i < 500; i++){
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        points_type_weight[gauge_type][t] = w;
        if (t > block.timestamp) {
          time_type_weight[uint256(int256(gauge_type))] = t;
        }
      }
      return w;
    }else{
      return 0;
    }
  }

  /**
    @notice Fill sum of gauge weights for the same type week-over-week for
            missed checkins and return the sum for the future week
    @param gauge_type Gauge type id
    @return Sum of weights
   */
  function _get_sum(int128 gauge_type) internal returns(uint256) {
    uint256 t = time_sum[uint256(int256(gauge_type))];
    if (t > 0) {
      Point memory pt = points_sum[gauge_type][t];
      for(int i = 0; i < 500; i ++){
        if (t > block.timestamp){
          break;
        }
        t += WEEK;
        uint256 d_bias = pt.slope * WEEK;
        if (pt.bias > d_bias) {
          pt.bias -= d_bias;
          uint256 d_slope = changes_sum[gauge_type][t];
          pt.slope -= d_slope;
        }else{
          pt.bias = 0;
          pt.slope = 0;
        }
        points_sum[gauge_type][t] = pt;
        if (t > block.timestamp){
          time_sum[uint256(int256(gauge_type))] = t;
        }
      }
      return pt.bias;
    }else{
      return 0;
    }
  }

  /**
    @notice Fill historic total weights week-over-week for missed checkins
            and return the total for the future week
    @return Total weight
   */
  function _get_total() internal returns(uint256) {
    uint256 t = time_total;
    int128 _n_gauge_types = n_gauge_types;
    if (t > block.timestamp){
      // If we have already checkpointed - still need to change the value
      t -= WEEK;
    }
    uint256 pt = points_total[t];

    for(int128 gauge_type = 0; gauge_type < 100; gauge_type ++){
      if (gauge_type == _n_gauge_types) {
        break;
      }
      _get_sum(gauge_type);
      _get_type_weight(gauge_type);
    }

    for(int i = 0; i < 500; i ++){
      if (t > block.timestamp){
        break;
      }
      t += WEEK;
      pt = 0;
      // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
      for(int128 gauge_type = 0; gauge_type < 100; gauge_type ++){
        if (gauge_type == _n_gauge_types){
          break;
        }
        uint256 type_sum = points_sum[gauge_type][t].bias;
        uint256 type_weight = points_type_weight[gauge_type][t];
        pt += type_sum * type_weight;
      }
      points_total[t] = pt;

      if (t > block.timestamp) {
        time_total = t;
      }
    }
    return pt;
  }

  /**
    @notice Fill historic gauge weights week-over-week for missed checkins
            and return the total for the future week
    @param gauge_addr Address of the gauge
    @return Gauge weight
   */
  function _get_weight(address gauge_addr) internal returns(uint256) {
    uint256 t = time_weight[gauge_addr];
    if (t > 0){
      Point memory pt = points_weight[gauge_addr][t];
      for(int i = 0; i < 500; i ++){
        if (t > block.timestamp) {
          break;
        }
        t += WEEK;
        uint256 d_bias = pt.slope * WEEK;
        if (pt.bias > d_bias) {
          pt.bias -= d_bias;
          uint256 d_slope = changes_weight[gauge_addr][t];
          pt.slope -= d_slope;
        }else{
          pt.bias = 0;
          pt.slope = 0;
        }
        points_weight[gauge_addr][t] = pt;
        if (t > block.timestamp) {
          time_weight[gauge_addr] = t;
        }
      }
      return pt.bias;
    }else{
      return 0;
    }
  }

  /**
    @notice Add gauge `addr` of type `gauge_type` with weight `weight`
    @param addr Gauge address
    @param gauge_type Gauge type
    @param weight Gauge weight
   */
  function _add_gauge(address addr, int128 gauge_type, int128 weight) internal {
    require(msg.sender == admin);
    require((gauge_type >= 0) && (gauge_type < n_gauge_types));
    require(gauge_types_[addr] == 0);  // dev: cannot add the same gauge twice

    int128 n = n_gauges;
    n_gauges = n + 1;
    gauges[uint256(int256(n))] = addr;

    gauge_types_[addr] = gauge_type + 1;
    uint256 next_time = (block.timestamp + WEEK) / WEEK * WEEK;

    if (weight > 0) {
      uint256 _type_weight = _get_type_weight(gauge_type);
      uint256 _old_sum = _get_sum(gauge_type);
      uint256 _old_total = _get_total();

      points_sum[gauge_type][next_time].bias = uint256(int256(weight)) + _old_sum;
      time_sum[uint256(int256(gauge_type))] = next_time;
      points_total[next_time] = _old_total + _type_weight * uint256(int256(weight));
      time_total = next_time;

      points_weight[addr][next_time].bias = uint256(int256(weight));
    }

    if (time_sum[uint256(int256(gauge_type))] == 0) {
      time_sum[uint256(int256(gauge_type))] = next_time;
    }
    time_weight[addr] = next_time;

    emit NewGauge(addr, gauge_type, uint256(int256(weight)));
  }

  function add_gauge(address addr, int128 gauge_type) external {
    _add_gauge(addr, gauge_type, 0);
  }

  function add_gauge(address addr, int128 gauge_type, int128 weight) external {
    _add_gauge(addr, gauge_type, weight);
  }

  /**
    @notice Checkpoint to fill data common for all gauges
   */
  function checkpoint() external {
    _get_total();
  }


  /**
    @notice Checkpoint to fill data for both a specific gauge and common for all gauges
    @param addr Gauge address
   */
  function checkpoint_gauge(address addr) external {
    _get_weight(addr);
    _get_total();
  }

  /**
    @notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
            (e.g. 1.0 == 1e18). Inflation which will be received by it is
            inflation_rate * relative_weight / 1e18
    @param addr Gauge address
    @param time Relative weight at the specified timestamp in the past or present
    @return Value of relative weight normalized to 1e18
   */
  function _gauge_relative_weight(address addr, uint256 time) internal view returns(uint256) {
    uint256 t = time / WEEK * WEEK;
    uint256 _total_weight = points_total[t];

    if (_total_weight > 0) {
      int128 gauge_type = gauge_types_[addr] - 1;
      uint256 _type_weight = points_type_weight[gauge_type][t];
      uint256 _gauge_weight = points_weight[addr][t].bias;
      return MULTIPLIER * _type_weight * _gauge_weight / _total_weight;
    }else{
      return 0;
    }
  }

  function gauge_relative_weight(address addr) external view returns(uint256){
    return _gauge_relative_weight(addr, block.timestamp);
  }

  function gauge_relative_weight(address addr, uint256 time) external view returns(uint256){
    return _gauge_relative_weight(addr, time);
  }

  /**
    @notice Get gauge weight normalized to 1e18 and also fill all the unfilled
            values for type and gauge records
    @dev Any address can call, however nothing is recorded if the values are filled already
    @param addr Gauge address
    @param time Relative weight at the specified timestamp in the past or present
    @return Value of relative weight normalized to 1e18
   */
  function _gauge_relative_weight_write(address addr, uint256 time) internal returns(uint256){
    _get_weight(addr);
    _get_total();  // Also calculates get_sum;
    return _gauge_relative_weight(addr, time);
  }

  function gauge_relative_weight_write(address addr) external returns(uint256){
    return _gauge_relative_weight_write(addr, block.timestamp);
  }

  function gauge_relative_weight_write(address addr, uint256 time) external returns(uint256){
    return _gauge_relative_weight_write(addr, time);
  }

  /**
    @notice Change type weight
    @param type_id Type id
    @param weight New type weight
   */
  function _change_type_weight(int128 type_id, uint256 weight) internal {
    uint256 old_weight = _get_type_weight(type_id);
    uint256 old_sum = _get_sum(type_id);
    uint256 _total_weight = _get_total();
    uint256 next_time = (block.timestamp + WEEK) / WEEK * WEEK;

    _total_weight = _total_weight + old_sum * weight - old_sum * old_weight;
    points_total[next_time] = _total_weight;
    points_type_weight[type_id][next_time] = weight;
    time_total = next_time;
    time_type_weight[uint256(int256(type_id))] = next_time;

    emit NewTypeWeight(type_id, next_time, weight, _total_weight);
  }

  /**
    @notice Add gauge type with name `_name` and weight `weight`
    @param _name Name of gauge type
    @param weight Weight of gauge type
   */
  function _add_type(string memory _name, uint256 weight) internal {
    require(msg.sender == admin);
    int128 type_id = n_gauge_types;
    gauge_type_names[type_id] = _name;
    n_gauge_types = type_id + 1;
    if (weight != 0) {
      _change_type_weight(type_id, weight);
      emit AddType(_name, type_id);
    }
  }

  function add_type(string memory _name) internal {
    _add_type(_name, 0);
  }

  function add_type(string memory _name, uint256 weight) internal {
    _add_type(_name, weight);
  }

  /**
    @notice Change gauge type `type_id` weight to `weight`
    @param type_id Gauge type id
    @param weight New Gauge weight
   */
  function change_type_weight(int128 type_id, uint256 weight) external {
    require(msg.sender == admin);
    _change_type_weight(type_id, weight);
  }


  function _change_gauge_weight(address addr, uint256 weight) internal {
    // Change gauge weight
    // Only needed when testing in reality
    int128 gauge_type = gauge_types_[addr] - 1;
    uint256 old_gauge_weight = _get_weight(addr);
    uint256 type_weight = _get_type_weight(gauge_type);
    uint256 old_sum = _get_sum(gauge_type);
    uint256 _total_weight = _get_total();
    uint256 next_time = (block.timestamp + WEEK) / WEEK * WEEK;

    points_weight[addr][next_time].bias = weight;
    time_weight[addr] = next_time;

    uint256 new_sum = old_sum + weight - old_gauge_weight;
    points_sum[gauge_type][next_time].bias = new_sum;
    time_sum[uint256(int256(gauge_type))] = next_time;

    _total_weight = _total_weight + new_sum * type_weight - old_sum * type_weight;
    points_total[next_time] = _total_weight;
    time_total = next_time;

    emit NewGaugeWeight(addr, block.timestamp, weight, _total_weight);
  }

  /**
    @notice Change weight of gauge `addr` to `weight`
    @param addr `GaugeController` contract address
    @param weight New Gauge weight
   */
  function change_gauge_weight(address addr, uint256 weight) external {
    require(msg.sender == admin);
    _change_gauge_weight(addr, weight);
  }

  /**
    @notice Allocate voting power for changing pool weights
    @param _gauge_addr Gauge which `msg.sender` votes for
    @param _user_weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
   */
  struct VoteForGaugeWeightsVars {
    address escrow;
    uint256 slope;
    uint256 lock_end;
    uint256 next_time;
    int128 gauge_type;
    uint256 old_dt;
    uint256 old_bias;
    uint256 new_dt;  // dev: raises when expired
    uint256 new_bias;
    uint256 power_used;
    uint256 old_weight_bias;
    uint256 old_weight_slope;
    uint256 old_sum_bias;
    uint256 old_sum_slope;
  }
  function vote_for_gauge_weights(address _gauge_addr, uint256 _user_weight) external {
    VoteForGaugeWeightsVars memory vars;
    vars.escrow = voting_escrow;
    vars.slope = uint256(int256(VotingEscrow(vars.escrow).get_last_user_slope(msg.sender)));
    vars.lock_end = VotingEscrow(vars.escrow).locked__end(msg.sender);
    // int128 _n_gauges = n_gauges;
    vars.next_time = (block.timestamp + WEEK) / WEEK * WEEK;
    require(vars.lock_end > vars.next_time, "Your token lock expires too soon");
    require((_user_weight >= 0) && (_user_weight <= 10000), "You used all your voting power");
    require(block.timestamp >= last_user_vote[msg.sender][_gauge_addr] + WEIGHT_VOTE_DELAY, "Cannot vote so often");

    int128 gauge_type = gauge_types_[_gauge_addr] - 1;
    require(gauge_type >= 0, "Gauge not added");
    // Prepare slopes and biases in memory
    VotedSlope storage old_slope = vote_user_slopes[msg.sender][_gauge_addr];
    vars.old_dt = 0;
    if (old_slope.end > vars.next_time) {
      vars.old_dt = old_slope.end - vars.next_time;
    }
    vars.old_bias = old_slope.slope * vars.old_dt;
    VotedSlope memory new_slope = VotedSlope({
      slope: vars.slope * _user_weight / 10000,
      end: vars.lock_end,
      power: _user_weight
    });
    vars.new_dt = vars.lock_end - vars.next_time;  // dev: raises when expired
    vars.new_bias = new_slope.slope * vars.new_dt;

    // Check and update powers (weights) used
    vars.power_used = vote_user_power[msg.sender];
    vars.power_used = vars.power_used + new_slope.power - old_slope.power;
    vote_user_power[msg.sender] = vars.power_used;
    require((vars.power_used >= 0) && (vars.power_used <= 10000), 'Used too much power');

    // Remove old and schedule new slope changes
    // Remove slope changes for old slopes
    // Schedule recording of initial slope for next_time
    vars.old_weight_bias = _get_weight(_gauge_addr);
    vars.old_weight_slope = points_weight[_gauge_addr][vars.next_time].slope;
    vars.old_sum_bias = _get_sum(gauge_type);
    vars.old_sum_slope = points_sum[gauge_type][vars.next_time].slope;

    points_weight[_gauge_addr][vars.next_time].bias = Math.max(vars.old_weight_bias + vars.new_bias, vars.old_bias) - vars.old_bias;
    points_sum[gauge_type][vars.next_time].bias = Math.max(vars.old_sum_bias + vars.new_bias, vars.old_bias) - vars.old_bias;
    if (old_slope.end > vars.next_time) {
      points_weight[_gauge_addr][vars.next_time].slope = Math.max(vars.old_weight_slope + new_slope.slope, old_slope.slope) - old_slope.slope;
      points_sum[gauge_type][vars.next_time].slope = Math.max(vars.old_sum_slope + new_slope.slope, old_slope.slope) - old_slope.slope;
    }else{
      points_weight[_gauge_addr][vars.next_time].slope += new_slope.slope;
      points_sum[gauge_type][vars.next_time].slope += new_slope.slope;      
    }
    if (old_slope.end > block.timestamp) {
      // Cancel old slope changes if they still didn't happen
      changes_weight[_gauge_addr][old_slope.end] -= old_slope.slope;
      changes_sum[gauge_type][old_slope.end] -= old_slope.slope;
    }
    // Add slope changes for new slopes
    changes_weight[_gauge_addr][new_slope.end] += new_slope.slope;
    changes_sum[gauge_type][new_slope.end] += new_slope.slope;

    _get_total();

    vote_user_slopes[msg.sender][_gauge_addr] = new_slope;

    // Record last action time
    last_user_vote[msg.sender][_gauge_addr] = block.timestamp;

    emit VoteForGauge(block.timestamp, msg.sender, _gauge_addr, _user_weight);
  }

  /**
    @notice Get current gauge weight
    @param addr Gauge address
    @return Gauge weight
   */
  function get_gauge_weight(address addr) external view returns(uint256){
    return points_weight[addr][time_weight[addr]].bias;
  }

  /**
    @notice Get current type weight
    @param type_id Type id
    @return Type weight
   */
  function get_type_weight(int128 type_id) external view returns(uint256){
    return points_type_weight[type_id][time_type_weight[uint256(int256(type_id))]];
  }

  /**
    @notice Get current total (type-weighted) weight
    @return Total weight
   */
  function get_total_weight() external view returns(uint256) {
    return points_total[time_total];
  }

  /**
    @notice Get sum of gauge weights per type
    @param type_id Type id
    @return Sum of gauge weights
   */
  function get_weights_sum_per_type(int128 type_id) external view returns(uint256){
    return points_sum[type_id][time_sum[uint256(int256(type_id))]].bias;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title Monetaria Token
 * @author Monetaria
 * @notice Implementation of the Monetaria token
 */
contract MNTToken is ERC20 {
  using SafeMath for uint256;

  string internal constant NAME = 'Monetaria Token';
  string internal constant SYMBOL = 'MNT';
  uint8 internal constant DECIMALS = 18;

  uint256 public constant REVISION = 1;

  // Allocation:
  // =========
  // * shareholders - 30%
  // * emplyees - 3%
  // * DAO-controlled reserve - 5%
  // * Early users - 5%
  // == 43% ==
  // left for inflation: 57%

  // Supply parameters
  uint256 internal constant YEAR = 86400 * 365;
  uint256 internal constant INITIAL_SUPPLY = 1_303_030_303;
  uint256 internal constant INITIAL_RATE = 274_815_283 * 10 ** 18 / YEAR;  // leading to 43% premine;
  uint256 internal constant RATE_REDUCTION_TIME = YEAR;
  uint256 internal constant RATE_REDUCTION_COEFFICIENT = 1189207115002721024;  // 2 ** (1/4) * 1e18;
  uint256 internal constant RATE_DENOMINATOR = 10 ** 18;
  uint256 internal constant INFLATION_DELAY = 86400;

  // Supply variables
  int128 public mining_epoch;
  uint256 public start_epoch_time;
  uint256 public rate;
  uint256 internal start_epoch_supply;

  address public minter;
  address public admin;

  constructor() ERC20(NAME, SYMBOL) {
    uint256 init_supply = INITIAL_SUPPLY * 10 ** DECIMALS;
    _mint(msg.sender, init_supply);

    admin = msg.sender;
    start_epoch_time = block.timestamp + INFLATION_DELAY - RATE_REDUCTION_TIME;
    mining_epoch = -1;
    rate = 0;
    start_epoch_supply = init_supply;
  }

  /**
   * @dev Update mining rate and supply at the start of the epoch 
          Any modifying mining call must also call this
   */
  function _update_mining_parameters() internal {
    uint256 _rate = rate;
    uint256 _start_epoch_supply = start_epoch_supply;

    start_epoch_time += RATE_REDUCTION_TIME;
    mining_epoch += 1;

    if (_rate == 0) {
      _rate = INITIAL_RATE;
    } else {
      _start_epoch_supply += _rate * RATE_REDUCTION_TIME;
      start_epoch_supply = _start_epoch_supply;
      _rate = _rate * RATE_DENOMINATOR / RATE_REDUCTION_COEFFICIENT;
    }
    rate = _rate;
  }

  /**
    @notice Update mining rate and supply at the start of the epoch
    @dev Callable by any address, but only once per epoch
         Total supply becomes slightly larger if this function is called late
   */
  function update_mining_parameters() external {
    require(block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME); // dev: too soon!
    _update_mining_parameters();
  }

  /**
    @notice Get timestamp of the current mining epoch start
            while simultaneously updating mining parameters
    @return Timestamp of the epoch
   */
  function start_epoch_time_write() external returns (uint256) {
    uint256 _start_epoch_time = start_epoch_time;
    if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME){
      _update_mining_parameters();
      return start_epoch_time;
    } else {
      return _start_epoch_time;
    }
  }
  /**
    @notice Get timestamp of the next mining epoch start
            while simultaneously updating mining parameters
    @return Timestamp of the next epoch  
   */
  function future_epoch_time_write() external returns (uint256){
    uint256 _start_epoch_time = start_epoch_time;
    if (block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME){
      _update_mining_parameters();
      return start_epoch_time + RATE_REDUCTION_TIME;
    } else {
      return _start_epoch_time + RATE_REDUCTION_TIME;
    }
  }

  function _available_supply() internal view returns (uint256){
    return start_epoch_supply + (block.timestamp - start_epoch_time) * rate;
  }

  /**
    @notice Current number of tokens in existence (claimed or unclaimed)
   */
  function available_supply() external view returns (uint256){
    return _available_supply();
  }

  /**
    @notice How much supply is mintable from start timestamp till end timestamp
    @param start Start of the time interval (timestamp)
    @param end End of the time interval (timestamp)
    @return Tokens mintable from `start` till `end`
   */
  function mintable_in_timeframe(uint256 start, uint256 end) external view returns (uint256){
    require(start <= end);  // dev: start > end

    uint256 to_mint = 0;
    uint256 current_epoch_time = start_epoch_time;
    uint256 current_rate = rate;

    // Special case if end is in future (not yet minted) epoch
    if (end > current_epoch_time + RATE_REDUCTION_TIME) {
      current_epoch_time += RATE_REDUCTION_TIME;
      current_rate = current_rate * RATE_DENOMINATOR / RATE_REDUCTION_COEFFICIENT;
    }
    require(end <= current_epoch_time + RATE_REDUCTION_TIME);  // dev: too far in future

    for (uint i = 0; i < 999; i++) { // Monetaria will not work in 1000 years. Darn!
      if ( end >= current_epoch_time ) {
        uint256 current_end = end;
        if (current_end > current_epoch_time + RATE_REDUCTION_TIME) {
          current_end = current_epoch_time + RATE_REDUCTION_TIME;
        }

        uint256 current_start = start;
        if (current_start >= current_epoch_time + RATE_REDUCTION_TIME){
          break; // We should never get here but what if...
        } else if (current_start < current_epoch_time) {
          current_start = current_epoch_time;
        }

        to_mint += current_rate * (current_end - current_start);

        if (start >= current_epoch_time) {
          break;
        }
      }

      current_epoch_time -= RATE_REDUCTION_TIME;
      current_rate = current_rate * RATE_REDUCTION_COEFFICIENT / RATE_DENOMINATOR; // double-division with rounding made rate a bit less => good
      require(current_rate <= INITIAL_RATE); // This should never happen
    }
    return to_mint;
  }

  /**
    @notice Set the minter address
    @dev Only callable once, when minter has not yet been set
    @param _minter Address of the minter
   */
  function set_minter(address _minter) external {
    require(msg.sender == admin);  // dev: admin only
    require(minter == address(0)); // dev: can set the minter only once, at creation
    minter = _minter;
  }

  /**
    @notice Set the new admin.
    @dev After all is set up, admin only can change the token name
    @param _admin New admin address
   */
  function set_admin(address _admin) external {
    require(msg.sender == admin); // dev: admin only
    admin = _admin;
  }

  /**
    @notice Mint `_value` tokens and assign them to `_to`
    @dev Emits a Transfer event originating from 0x00
    @param _to The account that will receive the created tokens
    @param _value The amount that will be created
    @return bool success
   */
  function mint(address _to, uint256 _value) external returns (bool) {
    require(msg.sender == minter); //dev: minter only
    require(_to == address(0)); //dev: zero address

    if (block.timestamp >= start_epoch_time + RATE_REDUCTION_TIME){
      _update_mining_parameters();
    }

    require(totalSupply() <= _available_supply()); //dev: exceeds allowable mint amount

    _mint(_to, _value);

    return true;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
  @title Voting Escrow
  @author Monetaria
  @notice Votes have a weight depending on time, so that users are
          committed to the future of (whatever they are voting for)
  @dev Vote weight decays linearly over time. Lock time cannot be
      more than `MAXTIME` (4 years).
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime:
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

// Interface for checking whether address belongs to a whitelisted
// type of a smart wallet.
// When new types are added - the whole contract is changed
// The check() method is modifying to be able to use caching
// for individual wallet addresses
interface SmartWalletChecker{
  function check(address addr) external view returns (bool);
}

contract VotingEscrow {
  struct Point {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts;
    uint256 blk; //block
  }
  // We cannot really do block numbers per se b/c slope is per time, not per block
  // and per block could be fairly bad b/c Ethereum changes blocktimes.
  // What we can do is to extrapolate ***At functions

  struct LockedBalance {
    int128 amount;
    uint256 end;
  }

  int128 constant DEPOSIT_FOR_TYPE = 0;
  int128 constant CREATE_LOCK_TYPE = 1;
  int128 constant INCREASE_LOCK_AMOUNT = 2;
  int128 constant INCREASE_UNLOCK_TIME = 3;

  event CommitOwnership(
    address admin
  );

  event ApplyOwnership(
    address admin
  );
  
  event Deposit(
    address indexed provider,
    uint256 value,
    uint256 indexed locktime,
    int128 _type,
    uint256 ts
  );

  event Withdraw (
    address indexed provider,
    uint256 value,
    uint256 ts
  );

  event Supply (
    uint256 prevSupply,
    uint256 supply
  );

  uint256 constant WEEK = 7 * 86400;  // all future times are rounded by week
  uint256 constant MAXTIME = 4 * 365 * 86400;  // 4 years
  uint256 constant MULTIPLIER = 10 ** 18;

  address public token;
  uint256 public supply;

  mapping(address => LockedBalance) public locked;

  uint256 public epoch;
  mapping(uint256 => Point) public point_history; // epoch -> unsigned point // Point[100000000000000000000000000000]
  mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
  mapping(address => uint256) public user_point_epoch;
  mapping(uint256 => int128) public slope_changes; // time -> signed slope change

  // Aragon's view methods for compatibility
  address public controller;
  bool public transfersEnabled;

  string public name; // name: public(String[64])
  string public symbol; // symbol: public(String[32])
  string public version; // version: public(String[32])
  uint256 public decimals; // decimals: public(uint256)

  // Checker for whitelisted (smart contract) wallets which are allowed to deposit
  // The goal is to prevent tokenizing the escrow
  address public future_smart_wallet_checker;
  address public smart_wallet_checker;

  address public admin; // Can and will be a smart contract
  address public future_admin;

  /**
    @notice Contract constructor
    @param token_addr `MNTToken` token address
    @param _name Token name
    @param _symbol Token symbol
    @param _version Contract version - required for Aragon compatibility
   */
  constructor(address token_addr, string memory _name, string memory _symbol, string memory _version) {
    admin = msg.sender;
    token = token_addr;
    point_history[0].blk = block.number;
    point_history[0].ts = block.timestamp;
    controller = msg.sender;
    transfersEnabled = true;

    uint256 _decimals = ERC20(token_addr).decimals();
    require(_decimals <= 255);
    decimals = _decimals;

    name = _name;
    symbol = _symbol;
    version = _version;
  }

  /**
    @notice Transfer ownership of VotingEscrow contract to `addr`
    @param addr Address to have ownership transferred to
   */
  function commit_transfer_ownership(address addr) external {
    require(msg.sender == admin); // dev: admin only
    future_admin = addr;
    emit CommitOwnership(addr);
  }

  /**
    @notice Apply ownership transfer
   */
  function apply_transfer_ownership() external {
    require(msg.sender == admin); // dev: admin only
    address _admin = future_admin;
    require(_admin != address(0)); // dev: admin not set
    admin = _admin;
    emit ApplyOwnership(_admin);
  }

  /**
    @notice Set an external contract to check for approved smart contract wallets
    @param addr Address of Smart contract checker
   */
  function commit_smart_wallet_checker(address addr) external {
    require(msg.sender == admin);
    future_smart_wallet_checker = addr;
  }
  
  /**
    @notice Apply setting external contract to check approved smart contract wallets
   */
  function apply_smart_wallet_checker() external {
    require(msg.sender == admin);
    smart_wallet_checker = future_smart_wallet_checker;
  }

  /**
    @notice Check if the call is from a whitelisted smart contract, revert if not
    @param addr Address to be checked
   */
  function assert_not_contract(address addr) internal view {
    if(addr != tx.origin){
      address checker = smart_wallet_checker;
      if(checker != address(0)){
        if (SmartWalletChecker(checker).check(addr)){
          return;
        }
      }
      revert("Smart contract depositors not allowed");
    }
  }

  /**
    @notice Get the most recently recorded rate of voting power decrease for `addr`
    @param addr Address of the user wallet
    @return Value of the slope
   */
  function get_last_user_slope(address addr) external view returns (int128){
    uint256 uepoch = user_point_epoch[addr];
    return user_point_history[addr][uepoch].slope;
  }

  /**
    @notice Get the timestamp for checkpoint `_idx` for `_addr`
    @param _addr User wallet address
    @param _idx User epoch number
    @return Epoch time of the checkpoint
   */
  function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256){
    return user_point_history[_addr][_idx].ts;
  }

  /**
    @notice Get timestamp when `_addr`'s lock finishes
    @param _addr User wallet
    @return Epoch time of the lock end
   */
  function locked__end(address _addr) external view returns (uint256){
    return locked[_addr].end;
  }

  /**
    @notice Record global and per-user data to checkpoint
    @param addr User's wallet address. No user checkpoint if 0x0
    @param old_locked Pevious locked amount / end lock time for the user
    @param new_locked New locked amount / end lock time for the user
   */
  struct CheckPointVars {
    Point u_old;
    Point u_new;
    int128 old_dslope;
    int128 new_dslope;
    uint256 _epoch;
    Point last_point;
    uint256 last_checkpoint;
    Point initial_last_point;
  }
  function _checkpoint(address addr, LockedBalance memory old_locked, LockedBalance memory new_locked) internal {
    CheckPointVars memory vars;
    vars._epoch = epoch;

    if(addr != address(0)){
      // Calculate slopes and biases
      // Kept at zero when they have to
      if (old_locked.end > block.timestamp && old_locked.amount > 0){
        vars.u_old.slope = old_locked.amount / int128(int256(MAXTIME)); // type casting MAXTIME
        vars.u_old.bias = vars.u_old.slope * int128(int256(old_locked.end - block.timestamp)); // type casting old_locked.end - block.timestamp
      }
      if (new_locked.end > block.timestamp && new_locked.amount > 0){
        vars.u_new.slope = new_locked.amount / int128(int256(MAXTIME));
        vars.u_new.bias = vars.u_new.slope * int128(int256(new_locked.end - block.timestamp));
      }
      // Read values of scheduled changes in the slope
      // old_locked.end can be in the past and in the future
      // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
      vars.old_dslope = slope_changes[old_locked.end];
      if(new_locked.end != 0){
        if(new_locked.end == old_locked.end){
          vars.new_dslope = vars.old_dslope;
        }else{
          vars.new_dslope = slope_changes[new_locked.end];
        }
      }
    }
    vars.last_point = Point(0, 0, block.timestamp, block.number);
    if(vars._epoch > 0){
      vars.last_point = point_history[vars._epoch];
    }
    vars.last_checkpoint = vars.last_point.ts;
    // initial_last_point is used for extrapolation to calculate block number
    // (approximately, for *At methods) and save them
    // as we cannot figure that out exactly from inside the contract
    vars.initial_last_point = vars.last_point;
    uint256 block_slope = 0;  // dblock/dt
    if(block.timestamp > vars.last_point.ts){
      block_slope = MULTIPLIER * (block.number - vars.last_point.blk) / (block.timestamp - vars.last_point.ts);
    }
    // If last point is already recorded in this block, slope=0
    // But that's ok b/c we know the block in such case

    // Go over weeks to fill history and calculate what the current point is
    uint256 t_i = (vars.last_checkpoint / WEEK) * WEEK;
    for(uint i = 0; i < 255; i++){
      // Hopefully it won't happen that this won't get used in 5 years!
      // If it does, users will be able to withdraw but vote weight will be broken
      t_i += WEEK;
      int128 d_slope = 0;
      if(t_i > block.timestamp){
        t_i = block.timestamp;
      }else{
        d_slope = slope_changes[t_i];
      }
      vars.last_point.bias -= vars.last_point.slope * int128(int256(t_i - vars.last_checkpoint));
      vars.last_point.slope += d_slope;
      if(vars.last_point.bias < 0){  // This can happen
        vars.last_point.bias = 0;
      }
      if(vars.last_point.slope < 0){  // This cannot happen - just in case
        vars.last_point.slope = 0;
      }
      vars.last_checkpoint = t_i;
      vars.last_point.ts = t_i;
      vars.last_point.blk = vars.initial_last_point.blk + block_slope * (t_i - vars.initial_last_point.ts) / MULTIPLIER;
      vars._epoch += 1;
      if(t_i == block.timestamp){
        vars.last_point.blk = block.number;
        break;
      }else{
        point_history[vars._epoch] = vars.last_point;
      }
    }
    epoch = vars._epoch;
    // Now point_history is filled until t=now

    if(addr != address(0)) {
      // If last point was in this block, the slope change has been applied already
      // But in such case we have 0 slope(s)
      vars.last_point.slope += (vars.u_new.slope - vars.u_old.slope);
      vars.last_point.bias += (vars.u_new.bias - vars.u_old.bias);
      if(vars.last_point.slope < 0){
        vars.last_point.slope = 0;
      }
      if(vars.last_point.bias < 0){
        vars.last_point.bias = 0;
      }
    }

    // Record the changed point into history
    point_history[vars._epoch] = vars.last_point;

    if(addr != address(0)){
      // Schedule the slope changes (slope is going down)
      // We subtract new_user_slope from [new_locked.end]
      // and add old_user_slope to [old_locked.end]
      if(old_locked.end > block.timestamp){
        // old_dslope was <something> - u_old.slope, so we cancel that
        vars.old_dslope += vars.u_old.slope;
        if(new_locked.end == old_locked.end){
          vars.old_dslope -= vars.u_new.slope;  // It was a new deposit, not extension
        }
        slope_changes[old_locked.end] = vars.old_dslope;
      }
      if(new_locked.end > block.timestamp){
        if(new_locked.end > old_locked.end){
          vars.new_dslope -= vars.u_new.slope;  // old slope disappeared at this point
          slope_changes[new_locked.end] = vars.new_dslope;
        }
        // else: we recorded it already in old_dslope
      }

      // Now handle user history
      uint256 user_epoch = user_point_epoch[addr] + 1;

      user_point_epoch[addr] = user_epoch;
      vars.u_new.ts = block.timestamp;
      vars.u_new.blk = block.number;
      user_point_history[addr][user_epoch] = vars.u_new;
    }
  }
  
  /**
    @notice Deposit and lock tokens for a user
    @param _addr User's wallet address
    @param _value Amount to deposit
    @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    @param locked_balance Previous locked amount / timestamp
   */
  function _deposit_for(address _addr, uint256 _value, uint256 unlock_time, LockedBalance memory locked_balance, int128 _type) internal {
    LockedBalance memory _locked = locked_balance;
    uint256 supply_before = supply;

    supply = supply_before + _value;
    LockedBalance memory old_locked = _locked;
    // Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += int128(int256(_value));
    if (unlock_time != 0) {
      _locked.end = unlock_time;
    }
    locked[_addr] = _locked;

    // Possibilities:
    // Both old_locked.end could be current or expired (>/< block.timestamp)
    // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    // _locked.end > block.timestamp (always)
    _checkpoint(_addr, old_locked, _locked);

    if (_value != 0) {
      require(ERC20(token).transferFrom(_addr, address(this), _value));
    }

    emit Deposit(_addr, _value, _locked.end, _type, block.timestamp);
    emit Supply(supply_before, supply_before + _value);
  }

  /**
    @notice Record global data to checkpoint
   */
  function checkpoint() external {
    LockedBalance memory _old;
    LockedBalance memory _new;
    _checkpoint(address(0), _old, _new);
  }

  /**
    @notice Deposit `_value` tokens for `_addr` and add to the lock
    @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their locktime and deposit for a brand new user
    @param _addr User's wallet address
    @param _value Amount to add to user's lock
   */
  // @nonreentrant('lock')
  function deposit_for(address _addr, uint256 _value) external {
    LockedBalance storage _locked = locked[_addr];

    require(_value > 0); // dev: need non-zero value
    require(_locked.amount > 0, "No existing lock found");
    require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

    _deposit_for(_addr, _value, 0, locked[_addr], DEPOSIT_FOR_TYPE);
  }

  /**
    @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    @param _value Amount to deposit
    @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
   */
  // @nonreentrant('lock')
  function create_lock(uint256 _value, uint256 _unlock_time) external {
    assert_not_contract(msg.sender);
    uint256 unlock_time = (_unlock_time / WEEK) * WEEK;  // Locktime is rounded down to weeks
    LockedBalance storage _locked = locked[msg.sender];

    require(_value > 0);  // dev: need non-zero value
    require(_locked.amount == 0, "Withdraw old tokens first");
    require(unlock_time > block.timestamp, "Can only lock until time in the future");
    require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

    _deposit_for(msg.sender, _value, unlock_time, _locked, CREATE_LOCK_TYPE);
  }

  /**
    @notice Deposit `_value` additional tokens for `msg.sender`
            without modifying the unlock time
    @param _value Amount of tokens to deposit and add to the lock
   */
  // @nonreentrant('lock')
  function increase_amount(uint256 _value) external {
    assert_not_contract(msg.sender);
    LockedBalance storage _locked = locked[msg.sender];

    require(_value > 0); // dev: need non-zero value
    require(_locked.amount > 0, "No existing lock found");
    require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

    _deposit_for(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
  }

  /**
    @notice Extend the unlock time for `msg.sender` to `_unlock_time`
    @param _unlock_time New epoch time for unlocking
   */
  // @nonreentrant('lock')
  function increase_unlock_time(uint256 _unlock_time) external {
    assert_not_contract(msg.sender);
    LockedBalance storage _locked = locked[msg.sender];
    uint256 unlock_time = (_unlock_time / WEEK) * WEEK;  // Locktime is rounded down to weeks

    require(_locked.end > block.timestamp, "Lock expired");
    require(_locked.amount > 0, "Nothing is locked");
    require(unlock_time > _locked.end, "Can only increase lock duration");
    require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

    _deposit_for(msg.sender, 0, unlock_time, _locked, INCREASE_UNLOCK_TIME);
  }

  /**
    @notice Withdraw all tokens for `msg.sender`
    @dev Only possible if the lock has expired
   */
  // @nonreentrant('lock')
  function withdraw() external {
    LockedBalance storage _locked = locked[msg.sender];
    require(block.timestamp >= _locked.end, "The lock didn't expire");
    uint256 value = uint256(int256(_locked.amount));

    LockedBalance memory old_locked = _locked;
    _locked.end = 0;
    _locked.amount = 0;
    locked[msg.sender] = _locked;
    uint256 supply_before = supply;
    supply = supply_before - value;

    // old_locked can have either expired <= timestamp or zero end
    // _locked has only 0 end
    // Both can have >= 0 amount
    _checkpoint(msg.sender, old_locked, _locked);

    require(ERC20(token).transfer(msg.sender, value));

    emit Withdraw(msg.sender, value, block.timestamp);
    emit Supply(supply_before, supply_before - value);
  }

  // The following ERC20/minime-compatible methods are not real balanceOf and supply!
  // They measure the weights for the purpose of voting, so they don't represent
  // real coins.

  /**
    @notice Binary search to estimate timestamp for block number
    @param _block Block to find
    @param max_epoch Don't go beyond this epoch
    @return Approximate timestamp for block
   */
  function find_block_epoch(uint256 _block, uint256 max_epoch) internal view returns (uint256){
    // Binary search
    uint256 _min = 0;
    uint256 _max = max_epoch;
    for(int i = 0; i < 128; i++){ // Will be always enough for 128-bit numbers
      if(_min >= _max){
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if(point_history[_mid].blk <= _block){
        _min = _mid;
      }else{
        _max = _mid - 1;
      }
    }
    return _min;
  }

  /**
    @notice Get the current voting power for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param addr User wallet address
    @param _t Epoch time to return voting power at
    @return User voting power
   */
  function _balanceOf(address addr, uint256 _t) internal view returns (uint256){
    uint256 _epoch = user_point_epoch[addr];
    if(_epoch == 0){
        return 0;
    }else{
      Point memory last_point = user_point_history[addr][_epoch];
      last_point.bias -= last_point.slope * int128(int256(_t - last_point.ts));
      if (last_point.bias < 0){
        last_point.bias = 0;
      }
      return uint256(int256(last_point.bias));
    }
  }

  /**
    @notice Get the current voting power for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param addr User wallet address
    @param _t Epoch time to return voting power at
    @return User voting power
   */
  function balanceOf(address addr, uint256 _t) external view returns (uint256){
    return _balanceOf(addr, _t);
  }

  /**
    @notice Get the current voting power for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param addr User wallet address
    @return User voting power
   */
  function balanceOf(address addr) external view returns (uint256){
    return _balanceOf(addr, block.timestamp);
  }

  /**
    @notice Measure voting power of `addr` at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param addr User's wallet address
    @param _block Block to calculate the voting power at
    @return Voting power
   */
  function balanceOfAt(address addr, uint256 _block) external view returns (uint256){
    // Copying and pasting totalSupply code because Vyper cannot pass by
    // reference yet
    require(_block <= block.number);

    // Binary search
    uint256 _min = 0;
    uint256 _max = user_point_epoch[addr];
    for(int i = 0; i < 128; i++){ // Will be always enough for 128-bit numbers
      if(_min >= _max){
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if(user_point_history[addr][_mid].blk <= _block){
        _min = _mid;
      }else{
        _max = _mid - 1;
      }
    }
    Point memory upoint = user_point_history[addr][_min];

    uint256 max_epoch = epoch;
    uint256 _epoch = find_block_epoch(_block, max_epoch);
    Point storage point_0 = point_history[_epoch];
    uint256 d_block = 0;
    uint256 d_t = 0;
    if(_epoch < max_epoch){
      Point storage point_1 = point_history[_epoch + 1];
      d_block = point_1.blk - point_0.blk;
      d_t = point_1.ts - point_0.ts;
    }else{
      d_block = block.number - point_0.blk;
      d_t = block.timestamp - point_0.ts;
    }
    uint256 block_time = point_0.ts;
    if(d_block != 0){
      block_time += d_t * (_block - point_0.blk) / d_block;
    }

    upoint.bias -= upoint.slope * int128(int256(block_time - upoint.ts));
    if(upoint.bias >= 0){
      return uint256(int256(upoint.bias));
    }else{
      return 0;
    }
  }

  /**
    @notice Calculate total voting power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total voting power at
    @return Total voting power at that time
   */
  function supply_at(Point memory point, uint256 t) internal view returns(uint256){
    Point memory last_point = point;
    uint256 t_i = (last_point.ts / WEEK) * WEEK;
    for(int i = 0; i < 255; i ++){
      t_i += WEEK;
      int128 d_slope = 0;
      if(t_i > t){
        t_i = t;
      }else{
        d_slope = slope_changes[t_i];
      }
      last_point.bias -= last_point.slope * int128(int256(t_i - last_point.ts));
      if(t_i == t){
        break;
      }
      last_point.slope += d_slope;
      last_point.ts = t_i;
    }

    if(last_point.bias < 0){
      last_point.bias = 0;
    }
    return uint256(int256(last_point.bias));
  }

  /**
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
   */
  function _totalSupply(uint256 t) internal view returns(uint256){
    uint256 _epoch = epoch;
    Point storage last_point = point_history[_epoch];
    return supply_at(last_point, t);
  }

  /**
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
   */
  function totalSupply(uint256 t) external view returns(uint256){
    return _totalSupply(t);
  }

  /**
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
   */
  function totalSupply() external view returns(uint256){
    return _totalSupply(block.timestamp);
  }

  /**
    @notice Calculate total voting power at some point in the past
    @param _block Block to calculate the total voting power at
    @return Total voting power at `_block`
   */
  function totalSupplyAt(uint256 _block) external view returns(uint256){
    require(_block <= block.number);
    uint256 _epoch = epoch;
    uint256 target_epoch = find_block_epoch(_block, _epoch);

    Point storage point = point_history[target_epoch];
    uint256 dt = 0;
    if(target_epoch < _epoch){
      Point storage point_next = point_history[target_epoch + 1];
      if(point.blk != point_next.blk){
        dt = (_block - point.blk) * (point_next.ts - point.ts) / (point_next.blk - point.blk);
      }
    }else{
      if(point.blk != block.number){
        dt = (_block - point.blk) * (block.timestamp - point.ts) / (block.number - point.blk);
      }
    }
    // Now dt contains info on how far are we beyond point

    return supply_at(point, point.ts + dt);
  }

  // Dummy methods for compatibility with Aragon
  /**
    @dev Dummy method required for Aragon compatibility
   */
  function changeController(address _newController) external {
    require(msg.sender == controller);
    controller = _newController;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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