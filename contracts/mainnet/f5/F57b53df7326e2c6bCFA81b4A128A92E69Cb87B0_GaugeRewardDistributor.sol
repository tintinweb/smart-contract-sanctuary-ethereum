// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./PlatformFeeDistributor.sol";
import "./ICurveGaugeV4V5.sol";

contract GaugeRewardDistributor is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  enum GaugeType {
    // used for empty gauge
    None,
    // claim from reward contract
    CurveGaugeV1V2V3,
    // explicitly call deposit_reward_token
    CurveGaugeV4V5
  }

  event UpdateDistributor(address _oldDistributor, address _newDistributor);
  event UpdateGaugeType(address _gauge, GaugeType _type);
  event AddRewardToken(uint256 _index, address _token, address[] _gauges, uint32[] _percentages);
  event RemoveRewardToken(uint256 _index, address _token);
  event UpdateRewardToken(address _token, address[] _gauges, uint32[] _percentages);

  struct RewardDistribution {
    address gauge;
    uint32 percentage;
  }

  struct GaugeRewards {
    GaugeType gaugeType;
    EnumerableSet.AddressSet tokens;
    mapping(address => uint256) pendings;
  }

  struct GaugeInfo {
    GaugeType gaugeType;
    address[] tokens;
    uint256[] pendings;
  }

  /// @dev The fee denominator used for percentage calculation.
  uint256 private constant FEE_DENOMINATOR = 1e9;

  /// @notice The address of PlatformFeeDistributor contract.
  address public distributor;

  /// @notice Mapping from reward token address to distribution information.
  mapping(address => RewardDistribution[]) public distributions;

  /// @notice The list of reward tokens.
  address[] public rewardTokens;

  /// @dev Mapping from gauge address to gauge type and rewards.
  mapping(address => GaugeRewards) private gauges;

  /// @notice Return the gauge information given the gauge address.
  /// @param _gauge The address of the gauge.
  function getGaugeInfo(address _gauge) external view returns (GaugeInfo memory) {
    GaugeInfo memory _info;
    uint256 _length = gauges[_gauge].tokens.length();

    _info.gaugeType = gauges[_gauge].gaugeType;
    _info.tokens = new address[](_length);
    _info.pendings = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      _info.tokens[i] = gauges[_gauge].tokens.at(i);
      _info.pendings[i] = gauges[_gauge].pendings[_info.tokens[i]];
    }

    return _info;
  }

  /// @notice Return the reward distribution given the token address.
  /// @param _token The address of the token.
  function getDistributionInfo(address _token) external view returns (RewardDistribution[] memory) {
    return distributions[_token];
  }

  /// @notice Claim function called by Curve Gauge V1, V2 or V3.
  function claim() external {
    require(gauges[msg.sender].gaugeType == GaugeType.CurveGaugeV1V2V3, "sender not allowed");
    _claimFromDistributor(new address[](0), new uint256[](0));
    _transferToGauge(msg.sender);
  }

  /// @notice Donate rewards to this contract
  /// @dev You can call this function to force distribute rewards to gauges.
  /// @param _tokens The list of address of reward tokens to donate.
  /// @param _amounts The list of amount of reward tokens to donate.
  function donate(address[] memory _tokens, uint256[] memory _amounts) external nonReentrant {
    require(_tokens.length == _amounts.length, "length mismatch");
    for (uint256 i = 0; i < _tokens.length; i++) {
      require(distributions[_tokens[i]].length > 0, "not reward token");
      uint256 _before = IERC20(_tokens[i]).balanceOf(address(this));
      IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
      _amounts[i] = IERC20(_tokens[i]).balanceOf(address(this)).sub(_before);
    }

    _claimFromDistributor(_tokens, _amounts);
  }

  /// @notice Update the address of PlatformFeeDistributor.
  /// @param _newDistributor The new address of PlatformFeeDistributor.
  function updateDistributor(address _newDistributor) external onlyOwner {
    address _oldDistributor = distributor;
    require(_oldDistributor != _newDistributor, "update the same address");

    distributor = _newDistributor;

    emit UpdateDistributor(_oldDistributor, _newDistributor);
  }

  /// @notice Update gauge types
  /// @dev You can only update from `None` to others or others to `None.
  /// @param _gauges The list of gauge addresses to update.
  /// @param _types The corresponding list of guage types to update.
  function updateGaugeTypes(address[] calldata _gauges, GaugeType[] calldata _types) external onlyOwner {
    require(_gauges.length == _types.length, "length mismatch");
    for (uint256 i = 0; i < _gauges.length; i++) {
      GaugeType _oldType = gauges[_gauges[i]].gaugeType;
      if (_oldType == GaugeType.None) {
        require(_types[i] != GaugeType.None, "invalid type");
      } else {
        require(_types[i] == GaugeType.None, "invalid type");
      }
      gauges[_gauges[i]].gaugeType = _types[i];

      emit UpdateGaugeType(_gauges[i], _types[i]);
    }
  }

  /// @notice Add a new reward token to distribute.
  /// @param _token The address of reward token.
  /// @param _gauges The list of gauges.
  /// @param _percentages The percentage distributed to each gauge.
  function addRewardToken(
    address _token,
    address[] calldata _gauges,
    uint32[] calldata _percentages
  ) external onlyOwner {
    require(_gauges.length == _percentages.length, "length mismatch");
    uint256 _length = rewardTokens.length;
    uint256 _emptyIndex = _length;
    for (uint256 i = 0; i < _length; i++) {
      address _rewardToken = rewardTokens[i];
      require(_rewardToken != _token, "duplicated reward token");
      if (_rewardToken == address(0)) _emptyIndex = i;
    }
    if (_emptyIndex == _length) {
      rewardTokens.push(_token);
    } else {
      rewardTokens[_emptyIndex] = _token;
    }

    RewardDistribution[] storage _distributions = distributions[_token];
    uint256 _sum;
    for (uint256 i = 0; i < _gauges.length; i++) {
      for (uint256 j = 0; j < i; j++) {
        require(_gauges[i] != _gauges[j], "duplicated gauge");
      }
      _distributions.push(RewardDistribution(_gauges[i], _percentages[i]));
      _sum = _sum.add(_percentages[i]);
      gauges[_gauges[i]].tokens.add(_token);
    }
    require(_sum == FEE_DENOMINATOR, "sum mismatch");

    emit AddRewardToken(_emptyIndex, _token, _gauges, _percentages);
  }

  /// @notice Remove a reward token.
  /// @param _index The index of the reward token.
  function removeRewardToken(uint256 _index) external onlyOwner {
    _claimFromDistributor(new address[](0), new uint256[](0));

    address _token = rewardTokens[_index];
    {
      uint256 _length = distributions[_token].length;
      for (uint256 i = 0; i < _length; i++) {
        gauges[distributions[_token][i].gauge].tokens.remove(_token);
      }
    }
    delete distributions[_token];
    rewardTokens[_index] = address(0);

    emit RemoveRewardToken(_index, _token);
  }

  /// @notice Update reward distribution for reward token.
  /// @param _index The index of the reward token.
  /// @param _gauges The list of gauges.
  /// @param _percentages The percentage distributed to each gauge.
  function updateRewardDistribution(
    uint256 _index,
    address[] calldata _gauges,
    uint32[] calldata _percentages
  ) external onlyOwner {
    _claimFromDistributor(new address[](0), new uint256[](0));

    address _token = rewardTokens[_index];
    {
      uint256 _length = distributions[_token].length;
      for (uint256 i = 0; i < _length; i++) {
        gauges[distributions[_token][i].gauge].tokens.remove(_token);
      }
    }
    delete distributions[_token];

    RewardDistribution[] storage _distributions = distributions[_token];
    uint256 _sum;
    for (uint256 i = 0; i < _gauges.length; i++) {
      for (uint256 j = 0; j < i; j++) {
        require(_gauges[i] != _gauges[j], "duplicated gauge");
      }
      _distributions.push(RewardDistribution(_gauges[i], _percentages[i]));
      _sum = _sum.add(_percentages[i]);
      gauges[_gauges[i]].tokens.add(_token);
    }
    require(_sum == FEE_DENOMINATOR, "sum mismatch");

    emit UpdateRewardToken(_token, _gauges, _percentages);
  }

  /// @dev Internal function to tranfer rewards to gauge directly. Caller shoule make sure the
  /// `GaugeType` is `CurveGaugeV1V2V3`.
  /// @param _gauge The address of gauge.
  function _transferToGauge(address _gauge) internal {
    GaugeRewards storage _rewards = gauges[_gauge];
    uint256 _length = _rewards.tokens.length();
    for (uint256 i = 0; i < _length; i++) {
      address _token = _rewards.tokens.at(i);
      uint256 _pending = _rewards.pendings[_token];
      if (_pending > 0) {
        _rewards.pendings[_token] = 0;
        IERC20(_token).safeTransfer(_gauge, _pending);
      }
    }
  }

  /// @dev Internal function to claim rewards from PlatformFeeDistributor
  /// @param _tokens The list of extra reward tokens donated to this contract.
  /// @param _amounts The list of amount of extra reward tokens donated to this contract.
  function _claimFromDistributor(address[] memory _tokens, uint256[] memory _amounts) internal {
    // claim from distributor and distribute to gauges
    address _distributor = distributor;
    if (_distributor != address(0)) {
      uint256 _length = rewardTokens.length;
      uint256[] memory _before = new uint256[](_length);
      for (uint256 i = 0; i < _length; i++) {
        if (rewardTokens[i] == address(0)) continue;
        _before[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
      }
      PlatformFeeDistributor(_distributor).claim();
      for (uint256 i = 0; i < _length; i++) {
        address _token = rewardTokens[i];
        if (_token == address(0)) continue;
        uint256 _claimed = IERC20(_token).balanceOf(address(this)).sub(_before[i]);
        if (_claimed > 0) {
          _distributeReward(_token, _claimed);
        }
      }
    }
    // distribute donated rewards to gauges.
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_amounts[i] > 0) {
        _distributeReward(_tokens[i], _amounts[i]);
      }
    }
  }

  /// @dev Internal function to distribute reward to gauges.
  /// @param _token The address of reward token.
  /// @param _amount The amount of reward token.
  function _distributeReward(address _token, uint256 _amount) internal {
    RewardDistribution[] storage _distributions = distributions[_token];
    uint256 _length = _distributions.length;
    for (uint256 i = 0; i < _length; i++) {
      RewardDistribution memory _distribution = _distributions[i];
      if (_distribution.percentage > 0) {
        uint256 _part = _amount.mul(_distribution.percentage) / FEE_DENOMINATOR;
        GaugeRewards storage _gauge = gauges[_distribution.gauge];
        if (_gauge.gaugeType == GaugeType.CurveGaugeV1V2V3) {
          // @note Curve Gauge V1, V2 or V3 need explicit claim.
          _gauge.pendings[_token] = _part.add(_gauge.pendings[_token]);
        } else if (_gauge.gaugeType == GaugeType.CurveGaugeV4V5) {
          // @note rewards can be deposited to Curve Gauge V4 or V5 directly.
          IERC20(_token).safeApprove(_distribution.gauge, 0);
          IERC20(_token).safeApprove(_distribution.gauge, _part);
          ICurveGaugeV4V5(_distribution.gauge).deposit_reward_token(_token, _part);
        } else {
          // no gauge to distribute, just send to owner
          IERC20(_token).safeTransfer(owner(), _part);
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library EnumerableSet {
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract PlatformFeeDistributor is Ownable {
  using SafeERC20 for IERC20;

  /// @notice Emitted when the address of gauge contract is changed.
  /// @param _gauge The address of new guage contract.
  event UpdateGauge(address _gauge);

  /// @notice Emitted when the address of ve token fee distribution contract is changed.
  /// @param _veDistributor The address of new ve token fee distribution contract.
  event UpdateDistributor(address _veDistributor);

  /// @notice Emitted when the address of treasury contract is changed.
  /// @param _treasury The address of new treasury contract.
  event UpdateTreasury(address _treasury);

  /// @notice Emitted when a reward token is removed.
  /// @param _token The address of reward token.
  event RemoveRewardToken(address _token);

  /// @notice Emitted when a new reward token is added.
  /// @param _token The address of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  event AddRewardToken(address _token, uint256 _gaugePercentage, uint256 _treasuryPercentage);

  /// @notice Emitted when the percentage is updated for existing reward token.
  /// @param _token The address of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  event UpdateRewardPercentage(address _token, uint256 _gaugePercentage, uint256 _treasuryPercentage);

  /// @dev The fee denominator used for percentage calculation.
  uint256 private constant FEE_DENOMINATOR = 1e9;

  struct RewardInfo {
    // The address of reward token.
    address token;
    // The percentage of token distributed to gauge contract.
    uint32 gaugePercentage;
    // The percentage of token distributed to treasury contract.
    uint32 treasuryPercentage;
    // @note The rest token will be distributed to ve token fee distribution contract.
  }

  /// @notice The address of gauge contract, will trigger rewards distribution.
  address public gauge;

  /// @notice The address of treasury contract.
  address public treasury;

  /// @notice The address of ve token fee distribution contract.
  address public veDistributor;

  /// @notice The list of rewards token.
  RewardInfo[] public rewards;

  constructor(
    address _gauge,
    address _treasury,
    address _veDistributor,
    RewardInfo[] memory _rewards
  ) {
    require(_gauge != address(0), "zero gauge address");
    require(_treasury != address(0), "zero treasury address");
    require(_veDistributor != address(0), "zero ve distributor address");

    gauge = _gauge;
    treasury = _treasury;
    veDistributor = _veDistributor;

    for (uint256 i = 0; i < _rewards.length; i++) {
      rewards.push(_rewards[i]);
    }
  }

  /// @notice Return the number of reward tokens.
  function getRewardCount() external view returns (uint256) {
    return rewards.length;
  }

  /// @notice Claim and distribute pending rewards to gauge/treasury/distributor contract.
  /// @dev The function can only be called by gauge contract.
  function claim() external {
    address _gauge = gauge;
    require(msg.sender == _gauge, "not gauge");

    address _treasury = treasury;
    address _veDistributor = veDistributor;

    uint256 _length = rewards.length;
    for (uint256 i = 0; i < _length; i++) {
      RewardInfo memory _reward = rewards[i];
      uint256 _balance = IERC20(_reward.token).balanceOf(address(this));
      if (_balance > 0) {
        uint256 _gaugeAmount = (_reward.gaugePercentage * _balance) / FEE_DENOMINATOR;
        uint256 _treasuryAmount = (_reward.treasuryPercentage * _balance) / FEE_DENOMINATOR;
        uint256 _veAmount = _balance - _gaugeAmount - _treasuryAmount;

        if (_gaugeAmount > 0) {
          IERC20(_reward.token).safeTransfer(_gauge, _gaugeAmount);
        }
        if (_treasuryAmount > 0) {
          IERC20(_reward.token).safeTransfer(_treasury, _treasuryAmount);
        }
        if (_veAmount > 0) {
          IERC20(_reward.token).safeTransfer(_veDistributor, _veAmount);
        }
      }
    }
  }

  /// @notice Update the address of gauge contract.
  /// @param _gauge The address of new guage contract.
  function updateGauge(address _gauge) external onlyOwner {
    require(_gauge != address(0), "zero gauge address");

    gauge = _gauge;

    emit UpdateGauge(_gauge);
  }

  /// @notice Update the address of treasury contract.
  /// @param _treasury The address of new treasury contract.
  function updateTreasury(address _treasury) external onlyOwner {
    require(_treasury != address(0), "zero treasury address");

    treasury = _treasury;

    emit UpdateTreasury(_treasury);
  }

  /// @notice Update the address of distributor contract.
  /// @param _veDistributor The address of new distributor contract.
  function updateDistributor(address _veDistributor) external onlyOwner {
    require(_veDistributor != address(0), "zero distributor address");

    veDistributor = _veDistributor;

    emit UpdateDistributor(_veDistributor);
  }

  /// @notice Update reward percentage of existing reward token.
  /// @param _index The index of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  function updateRewardPercentage(
    uint256 _index,
    uint32 _gaugePercentage,
    uint32 _treasuryPercentage
  ) external onlyOwner {
    require(_gaugePercentage <= FEE_DENOMINATOR, "gauge percentage too large");
    require(_treasuryPercentage <= FEE_DENOMINATOR, "treasury percentage too large");
    require(_gaugePercentage + _treasuryPercentage <= FEE_DENOMINATOR, "distributor percentage too small");
    require(_index < rewards.length, "index out of range");

    RewardInfo memory _info = rewards[_index];
    _info.gaugePercentage = _gaugePercentage;
    _info.treasuryPercentage = _treasuryPercentage;

    rewards[_index] = _info;
    emit UpdateRewardPercentage(_info.token, _gaugePercentage, _treasuryPercentage);
  }

  /// @notice Add a new reward token.
  /// @param _token The address of reward token.
  /// @param _gaugePercentage The percentage of token distributed to gauge contract, multipled by 1e9.
  /// @param _treasuryPercentage The percentage of token distributed to treasury contract, multipled by 1e9.
  function addRewardToken(
    address _token,
    uint32 _gaugePercentage,
    uint32 _treasuryPercentage
  ) external onlyOwner {
    require(_gaugePercentage <= FEE_DENOMINATOR, "gauge percentage too large");
    require(_treasuryPercentage <= FEE_DENOMINATOR, "treasury percentage too large");
    require(_gaugePercentage + _treasuryPercentage <= FEE_DENOMINATOR, "distributor percentage too small");

    for (uint256 i = 0; i < rewards.length; i++) {
      require(_token != rewards[i].token, "duplicated reward token");
    }

    rewards.push(RewardInfo(_token, _gaugePercentage, _treasuryPercentage));

    emit AddRewardToken(_token, _gaugePercentage, _treasuryPercentage);
  }

  /// @notice Remove an existing reward token.
  /// @param _index The index of reward token.
  function removeRewardToken(uint256 _index) external onlyOwner {
    uint256 _length = rewards.length;
    require(_index < _length, "index out of range");

    address _token = rewards[_index].token;
    if (_index != _length - 1) {
      rewards[_index] = rewards[_length - 1];
    }
    rewards.pop();

    emit RemoveRewardToken(_token);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase, var-name-mixedcase

interface ICurveGaugeV4V5 {
  function reward_data(address _token)
    external
    view
    returns (
      address token,
      address distributor,
      uint256 period_finish,
      uint256 rate,
      uint256 last_update,
      uint256 integral
    );

  function deposit(uint256 _value) external;

  function deposit(uint256 _value, address _addr) external;

  function deposit(
    uint256 _value,
    address _addr,
    bool _claim_rewards
  ) external;

  function withdraw(uint256 _value) external;

  function withdraw(uint256 _value, bool _claim_rewards) external;

  function user_checkpoint(address addr) external returns (bool);

  function claim_rewards(address _reward_token) external;

  function claim_rewards(address _reward_token, address _receiver) external;

  function claimable_reward(address _user, address _reward_token) external view returns (uint256);

  function claimable_tokens(address _user) external view returns (uint256);

  function add_reward(address _reward_token, address _distributor) external;

  function set_reward_distributor(address _reward_token, address _distributor) external;

  function deposit_reward_token(address _reward_token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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