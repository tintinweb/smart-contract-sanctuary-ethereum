// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/external/IKeep3rV1Proxy.sol';
import './interfaces/external/IvKP3R.sol';
import './interfaces/external/IrKP3R.sol';
import './interfaces/external/IGauge.sol';
import './interfaces/IGaugeProxy.sol';

contract GaugeProxyV2 is IGaugeProxy {
  address constant _rkp3r = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;
  address constant _vkp3r = 0x2FC52C61fB0C03489649311989CE2689D93dC1a2;
  address constant _kp3rV1 = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
  address constant _kp3rV1Proxy = 0x976b01c02c636Dd5901444B941442FD70b86dcd5;
  address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

  /// @inheritdoc IGaugeProxy
  uint256 public totalWeight;

  /// @inheritdoc IGaugeProxy
  address public keeper;
  /// @inheritdoc IGaugeProxy
  address public gov;
  /// @inheritdoc IGaugeProxy
  address public nextgov;
  /// @inheritdoc IGaugeProxy
  uint256 public commitgov;
  /// @inheritdoc IGaugeProxy
  uint256 public constant delay = 1 days;

  address[] internal _tokens;
  /// @inheritdoc IGaugeProxy
  mapping(address => address) public gauges; // token => gauge
  /// @inheritdoc IGaugeProxy
  mapping(address => uint256) public weights; // token => weight
  /// @inheritdoc IGaugeProxy
  mapping(address => mapping(address => uint256)) public votes; // msg.sender => votes
  /// @inheritdoc IGaugeProxy
  mapping(address => address[]) public tokenVote; // msg.sender => token
  /// @inheritdoc IGaugeProxy
  mapping(address => uint256) public usedWeights; // msg.sender => total voting weight of user
  /// @inheritdoc IGaugeProxy
  mapping(address => bool) public enabled;

  /// @inheritdoc IGaugeProxy
  function tokens() external view returns (address[] memory) {
    return _tokens;
  }

  constructor(address _gov) {
    gov = _gov;
    _safeApprove(_kp3rV1, _rkp3r, type(uint256).max);
  }

  modifier g() {
    require(msg.sender == gov);
    _;
  }

  modifier k() {
    require(msg.sender == keeper);
    _;
  }

  /// @inheritdoc IGaugeProxy
  function setKeeper(address _keeper) external g {
    keeper = _keeper;
  }

  /// @inheritdoc IGaugeProxy
  function setGov(address _gov) external g {
    nextgov = _gov;
    commitgov = block.timestamp + delay;
  }

  /// @inheritdoc IGaugeProxy
  function acceptGov() external {
    require(msg.sender == nextgov && commitgov < block.timestamp);
    gov = nextgov;
  }

  /// @inheritdoc IGaugeProxy
  function reset() external {
    _reset(msg.sender);
  }

  function _reset(address _owner) internal {
    address[] storage _tokenVote = tokenVote[_owner];
    uint256 _tokenVoteCnt = _tokenVote.length;

    for (uint256 i = 0; i < _tokenVoteCnt; i++) {
      address _token = _tokenVote[i];
      uint256 _votes = votes[_owner][_token];

      if (_votes > 0) {
        totalWeight -= _votes;
        weights[_token] -= _votes;
        votes[_owner][_token] = 0;
      }
    }

    delete tokenVote[_owner];
  }

  /// @inheritdoc IGaugeProxy
  function poke(address _owner) public {
    address[] memory _tokenVote = tokenVote[_owner];
    uint256 _tokenCnt = _tokenVote.length;
    uint256[] memory _weights = new uint256[](_tokenCnt);

    uint256 _prevUsedWeight = usedWeights[_owner];
    uint256 _weight = IvKP3R(_vkp3r).get_adjusted_ve_balance(_owner, ZERO_ADDRESS);

    for (uint256 i = 0; i < _tokenCnt; i++) {
      uint256 _prevWeight = votes[_owner][_tokenVote[i]];
      _weights[i] = (_prevWeight * _weight) / _prevUsedWeight;
    }

    _vote(_owner, _tokenVote, _weights);
  }

  function _vote(
    address _owner,
    address[] memory _tokenVote,
    uint256[] memory _weights
  ) internal {
    // _weights[i] = percentage * 100
    _reset(_owner);
    uint256 _tokenCnt = _tokenVote.length;
    uint256 _weight = IvKP3R(_vkp3r).get_adjusted_ve_balance(_owner, ZERO_ADDRESS);
    uint256 _totalVoteWeight = 0;
    uint256 _usedWeight = 0;

    for (uint256 i = 0; i < _tokenCnt; i++) {
      _totalVoteWeight += _weights[i];
    }

    for (uint256 i = 0; i < _tokenCnt; i++) {
      address _token = _tokenVote[i];
      address _gauge = gauges[_token];
      uint256 _tokenWeight = (_weights[i] * _weight) / _totalVoteWeight;

      if (_gauge != address(0x0)) {
        _usedWeight += _tokenWeight;
        totalWeight += _tokenWeight;
        weights[_token] += _tokenWeight;
        tokenVote[_owner].push(_token);
        votes[_owner][_token] = _tokenWeight;
      }
    }

    usedWeights[_owner] = _usedWeight;
  }

  /// @inheritdoc IGaugeProxy
  function vote(address[] calldata _tokenVote, uint256[] calldata _weights) external {
    require(_tokenVote.length == _weights.length);
    _vote(msg.sender, _tokenVote, _weights);
  }

  /// @inheritdoc IGaugeProxy
  function addGauge(address _token, address _gauge) external g {
    require(gauges[_token] == address(0x0), 'exists');
    _safeApprove(_rkp3r, _gauge, type(uint256).max);
    gauges[_token] = _gauge;
    enabled[_token] = true;
    _tokens.push(_token);
  }

  /// @inheritdoc IGaugeProxy
  function disable(address _token) external g {
    enabled[_token] = false;
  }

  /// @inheritdoc IGaugeProxy
  function enable(address _token) external g {
    enabled[_token] = true;
  }

  /// @inheritdoc IGaugeProxy
  function length() external view returns (uint256) {
    return _tokens.length;
  }

  /// @inheritdoc IGaugeProxy
  function forceDistribute() external g {
    _distribute();
  }

  /// @inheritdoc IGaugeProxy
  function distribute() external k {
    _distribute();
  }

  function _distribute() internal {
    uint256 _balance = IKeep3rV1Proxy(_kp3rV1Proxy).draw();
    IrKP3R(_rkp3r).deposit(_balance);

    if (_balance > 0 && totalWeight > 0) {
      uint256 _totalWeight = totalWeight;
      for (uint256 i = 0; i < _tokens.length; i++) {
        if (!enabled[_tokens[i]]) {
          _totalWeight -= weights[_tokens[i]];
        }
      }
      for (uint256 x = 0; x < _tokens.length; x++) {
        if (enabled[_tokens[x]]) {
          uint256 _reward = (_balance * weights[_tokens[x]]) / _totalWeight;
          if (_reward > 0) {
            address _gauge = gauges[_tokens[x]];
            IGauge(_gauge).deposit_reward_token(_rkp3r, _reward);
          }
        }
      }
    }
  }

  function _safeApprove(
    address token,
    address spender,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))));
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
pragma solidity >=0.8.4 <0.9.0;

interface IKeep3rV1Proxy {
  // Structs
  struct Recipient {
    address recipient;
    uint256 caps;
  }

  // Variables
  function keep3rV1() external view returns (address);

  function minter() external view returns (address);

  function next(address) external view returns (uint256);

  function caps(address) external view returns (uint256);

  function recipients() external view returns (address[] memory);

  function recipientsCaps() external view returns (Recipient[] memory);

  // Errors
  error Cooldown();
  error NoDrawableAmount();
  error ZeroAddress();
  error OnlyMinter();

  // Methods
  function addRecipient(address _recipient, uint256 _amount) external;

  function removeRecipient(address _recipient) external;

  function draw() external returns (uint256 _amount);

  function setKeep3rV1(address _keep3rV1) external;

  function setMinter(address _minter) external;

  function mint(uint256 _amount) external;

  function mint(address _account, uint256 _amount) external;

  function setKeep3rV1Governance(address _governance) external;

  function acceptKeep3rV1Governance() external;

  function dispute(address _keeper) external;

  function slash(
    address _bonded,
    address _keeper,
    uint256 _amount
  ) external;

  function revoke(address _keeper) external;

  function resolve(address _keeper) external;

  function addJob(address _job) external;

  function removeJob(address _job) external;

  function addKPRCredit(address _job, uint256 _amount) external;

  function approveLiquidity(address _liquidity) external;

  function revokeLiquidity(address _liquidity) external;

  function setKeep3rHelper(address _keep3rHelper) external;

  function addVotes(address _voter, uint256 _amount) external;

  function removeVotes(address _voter, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IvKP3R {
  // solhint-disable-next-line func-name-mixedcase
  function get_adjusted_ve_balance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IrKP3R {
  function deposit(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IGauge {
  // solhint-disable-next-line func-name-mixedcase
  function deposit_reward_token(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title GaugeProxy contract
/// @notice Handles Curve gauges reward voting and distribution
interface IGaugeProxy {
  /// @dev Vote weight used on disabled pools is computed in totalWeight but not reflected in the actual distribution
  /// @return _totalWeight Sum of total weight used on all the pools
  function totalWeight() external returns (uint256 _totalWeight);

  /// @return _keeper Address with access permission to call distribute function
  function keeper() external returns (address _keeper);

  /// @notice Governance has permission to manage gauges, and force the distribution
  /// @return _gov Address of Governance
  function gov() external returns (address _gov);

  /// @return _nextGov Address of the proposed next governance
  function nextgov() external returns (address _nextGov);

  /// @return _commitGov Datetime when next governance can execute transition
  function commitgov() external returns (uint256 _commitGov);

  /// @return _delay Time in seconds to pass between a next governance proposal and it's execution
  function delay() external returns (uint256 _delay);

  /// @param _pool Address of the pool being checked
  /// @return _gauge Address of the gauge related to the input pool
  function gauges(address _pool) external view returns (address _gauge);

  /// @param _pool Address of the pool being checked
  /// @return _weight Amount of weight vote on the pool
  function weights(address _pool) external view returns (uint256 _weight);

  /// @dev The vote weight decays with time and this function does not reflect that
  /// @param _voter Address of the voter being checked
  /// @param _pool Address of the pool being checked
  /// @return _votes Amount of vote weight from the voter, on the pool
  function votes(address _voter, address _pool) external view returns (uint256 _votes);

  /// @param _voter Address of the voter being checked
  /// @param _i Index of the pool being checked
  /// @return _pool Addresses of the voted pools of a voter
  function tokenVote(address _voter, uint256 _i) external view returns (address _pool);

  /// @param _voter Address of the voter being checked
  /// @return _usedWeights Total amount of used weight of a voter
  function usedWeights(address _voter) external view returns (uint256 _usedWeights);

  /// @param _pool Address of the pool being checked
  /// @return _enabled Whether the pool is enabled
  function enabled(address _pool) external view returns (bool _enabled);

  /// @return _pools Array of pools added to the contract
  function tokens() external view returns (address[] memory _pools);

  /// @notice Allows governance to modify the keeper address
  /// @param _keeper Address of the new keeper being set
  function setKeeper(address _keeper) external;

  /// @notice Allows governance to propose a new governance
  function setGov(address _gov) external;

  /// @notice Allows new governance to execute the transition
  /// @dev Requires a delay time between the proposal and the execution
  function acceptGov() external;

  /// @notice Resets function caller vote distribution
  function reset() external;

  /// @notice Refresh a voter weight distributio to current state
  /// @dev Vote weight decays with time and this function allows to refresh it
  /// @param _voter Address of the voter veing poked
  function poke(address _voter) external;

  /// @notice Allows a voter to submit a vote distribution
  /// @dev Voter is always using its full weight, inputed weights get ponderated
  /// @param _poolVote Array of addresses being voted
  /// @param _weights Distribution of vote weight to use on addresses
  function vote(address[] calldata _poolVote, uint256[] calldata _weights) external;

  /// @notice Allows governance to register a new gauge
  /// @param _pool Address of the pool to reward
  /// @param _gauge Address of the gauge to reward the pool
  function addGauge(address _pool, address _gauge) external;

  /// @notice Allows governance to disable a pool reward
  /// @dev Vote weight deposited on disabled tokens is taken out of the total weight
  /// @param _pool Address of the pool being disabled
  function disable(address _pool) external;

  /// @notice Allows governance to reenable a pool reward
  /// @param _pool Address of the pool being enabled
  function enable(address _pool) external;

  /// returns _lenght Total amount of rewarded pools
  function length() external view returns (uint256 _lenght);

  /// @notice Allows governance to execute a reward distribution
  function forceDistribute() external;

  /// @notice Function to be upkeep responsible for executing rKP3Rs reward distribution
  function distribute() external;
}