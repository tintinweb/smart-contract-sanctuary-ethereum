// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../interface/IVe.sol";
import "../../interface/IVoter.sol";
import "../../interface/IERC20.sol";
import "../../interface/IERC721.sol";
import "../../interface/IGauge.sol";
import "../../interface/IFactory.sol";
import "../../interface/IPair.sol";
import "../../interface/IBribeFactory.sol";
import "../../interface/IGaugeFactory.sol";
import "../../interface/IMinter.sol";
import "../../interface/IBribe.sol";
import "../../interface/IMultiRewardsPool.sol";
import "../Reentrancy.sol";
import "../../lib/SafeERC20.sol";

contract DystVoter is IVoter, Reentrancy {
  using SafeERC20 for IERC20;

  /// @dev The ve token that governs these contracts
  address public immutable override ve;
  /// @dev DystFactory
  address public immutable factory;
  address public immutable token;
  address public immutable gaugeFactory;
  address public immutable bribeFactory;
  /// @dev Rewards are released over 7 days
  uint internal constant DURATION = 7 days;
  address public minter;

  /// @dev Total voting weight
  uint public totalWeight;

  /// @dev All pools viable for incentives
  address[] public pools;
  /// @dev pool => gauge
  mapping(address => address) public gauges;
  /// @dev gauge => pool
  mapping(address => address) public poolForGauge;
  /// @dev gauge => bribe
  mapping(address => address) public bribes;
  /// @dev pool => weight
  mapping(address => int256) public weights;
  /// @dev nft => pool => votes
  mapping(uint => mapping(address => int256)) public votes;
  /// @dev nft => pools
  mapping(uint => address[]) public poolVote;
  /// @dev nft => total voting weight of user
  mapping(uint => uint) public usedWeights;
  mapping(address => bool) public isGauge;
  mapping(address => bool) public isWhitelisted;

  uint public index;
  mapping(address => uint) public supplyIndex;
  mapping(address => uint) public claimable;

  event GaugeCreated(address indexed gauge, address creator, address indexed bribe, address indexed pool);
  event Voted(address indexed voter, uint tokenId, int256 weight);
  event Abstained(uint tokenId, int256 weight);
  event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
  event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
  event NotifyReward(address indexed sender, address indexed reward, uint amount);
  event DistributeReward(address indexed sender, address indexed gauge, uint amount);
  event Attach(address indexed owner, address indexed gauge, uint tokenId);
  event Detach(address indexed owner, address indexed gauge, uint tokenId);
  event Whitelisted(address indexed whitelister, address indexed token);

  constructor(address _ve, address _factory, address _gaugeFactory, address _bribeFactory) {
    ve = _ve;
    factory = _factory;
    token = IVe(_ve).token();
    gaugeFactory = _gaugeFactory;
    bribeFactory = _bribeFactory;
    minter = msg.sender;
  }

  function initialize(address[] memory _tokens, address _minter) external {
    require(msg.sender == minter, "!minter");
    for (uint i = 0; i < _tokens.length; i++) {
      _whitelist(_tokens[i]);
    }
    minter = _minter;
  }

  /// @dev Amount of tokens required to be hold for whitelisting.
  function listingFee() external view returns (uint) {
    return _listingFee();
  }

  /// @dev 20% of circulation supply.
  function _listingFee() internal view returns (uint) {
    return (IERC20(token).totalSupply() - IERC20(ve).totalSupply()) / 5;
  }

  /// @dev Remove all votes for given tokenId.
  function reset(uint _tokenId) external {
    require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    _reset(_tokenId);
    IVe(ve).abstain(_tokenId);
  }

  function _reset(uint _tokenId) internal {
    address[] storage _poolVote = poolVote[_tokenId];
    uint _poolVoteCnt = _poolVote.length;
    int256 _totalWeight = 0;

    for (uint i = 0; i < _poolVoteCnt; i ++) {
      address _pool = _poolVote[i];
      int256 _votes = votes[_tokenId][_pool];
      _updateFor(gauges[_pool]);
      weights[_pool] -= _votes;
      votes[_tokenId][_pool] -= _votes;
      if (_votes > 0) {
        IBribe(bribes[gauges[_pool]])._withdraw(uint(_votes), _tokenId);
        _totalWeight += _votes;
      } else {
        _totalWeight -= _votes;
      }
      emit Abstained(_tokenId, _votes);
    }
    totalWeight -= uint(_totalWeight);
    usedWeights[_tokenId] = 0;
    delete poolVote[_tokenId];
  }

  /// @dev Resubmit exist votes for given token. For internal purposes.
  function poke(uint _tokenId) external {
    address[] memory _poolVote = poolVote[_tokenId];
    uint _poolCnt = _poolVote.length;
    int256[] memory _weights = new int256[](_poolCnt);

    for (uint i = 0; i < _poolCnt; i ++) {
      _weights[i] = votes[_tokenId][_poolVote[i]];
    }

    _vote(_tokenId, _poolVote, _weights);
  }

  function _vote(uint _tokenId, address[] memory _poolVote, int256[] memory _weights) internal {
    _reset(_tokenId);
    uint _poolCnt = _poolVote.length;
    int256 _weight = int256(IVe(ve).balanceOfNFT(_tokenId));
    int256 _totalVoteWeight = 0;
    int256 _totalWeight = 0;
    int256 _usedWeight = 0;

    for (uint i = 0; i < _poolCnt; i++) {
      _totalVoteWeight += _weights[i] > 0 ? _weights[i] : - _weights[i];
    }

    for (uint i = 0; i < _poolCnt; i++) {
      address _pool = _poolVote[i];
      address _gauge = gauges[_pool];

      int256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
      require(votes[_tokenId][_pool] == 0, "duplicate pool");
      require(_poolWeight != 0, "zero power");
      _updateFor(_gauge);

      poolVote[_tokenId].push(_pool);

      weights[_pool] += _poolWeight;
      votes[_tokenId][_pool] += _poolWeight;
      if (_poolWeight > 0) {
        IBribe(bribes[_gauge])._deposit(uint(_poolWeight), _tokenId);
      } else {
        _poolWeight = - _poolWeight;
      }
      _usedWeight += _poolWeight;
      _totalWeight += _poolWeight;
      emit Voted(msg.sender, _tokenId, _poolWeight);
    }
    if (_usedWeight > 0) IVe(ve).voting(_tokenId);
    totalWeight += uint(_totalWeight);
    usedWeights[_tokenId] = uint(_usedWeight);
  }

  /// @dev Vote for given pools using a vote power of given tokenId. Reset previous votes.
  function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external {
    require(IVe(ve).isApprovedOrOwner(msg.sender, tokenId), "!owner");
    require(_poolVote.length == _weights.length, "!arrays");
    _vote(tokenId, _poolVote, _weights);
  }

  /// @dev Add token to whitelist. Only pools with whitelisted tokens can be added to gauge.
  function whitelist(address _token, uint _tokenId) external {
    require(_tokenId > 0, "!token");
    require(msg.sender == IERC721(ve).ownerOf(_tokenId), "!owner");
    require(IVe(ve).balanceOfNFT(_tokenId) > _listingFee(), "!power");
    _whitelist(_token);
  }

  function _whitelist(address _token) internal {
    require(!isWhitelisted[_token], "already whitelisted");
    isWhitelisted[_token] = true;
    emit Whitelisted(msg.sender, _token);
  }

  /// @dev Add a token to a gauge/bribe as possible reward.
  function registerRewardToken(address _token, address _gaugeOrBribe, uint _tokenId) external {
    require(_tokenId > 0, "!token");
    require(msg.sender == IERC721(ve).ownerOf(_tokenId), "!owner");
    require(IVe(ve).balanceOfNFT(_tokenId) > _listingFee(), "!power");
    IMultiRewardsPool(_gaugeOrBribe).registerRewardToken(_token);
  }

  /// @dev Remove a token from a gauge/bribe allowed rewards list.
  function removeRewardToken(address _token, address _gaugeOrBribe, uint _tokenId) external {
    require(_tokenId > 0, "!token");
    require(msg.sender == IERC721(ve).ownerOf(_tokenId), "!owner");
    require(IVe(ve).balanceOfNFT(_tokenId) > _listingFee(), "!power");
    IMultiRewardsPool(_gaugeOrBribe).removeRewardToken(_token);
  }

  /// @dev Create gauge for given pool. Only for a pool with whitelisted tokens.
  function createGauge(address _pool) external returns (address) {
    require(gauges[_pool] == address(0x0), "exists");
    require(IFactory(factory).isPair(_pool), "!pool");
    (address tokenA, address tokenB) = IPair(_pool).tokens();
    require(isWhitelisted[tokenA] && isWhitelisted[tokenB], "!whitelisted");

    address[] memory allowedRewards = new address[](3);
    allowedRewards[0] = tokenA;
    allowedRewards[1] = tokenB;
    if (token != tokenA && token != tokenB) {
      allowedRewards[2] = token;
    }

    address _bribe = IBribeFactory(bribeFactory).createBribe(allowedRewards);
    address _gauge = IGaugeFactory(gaugeFactory).createGauge(_pool, _bribe, ve, allowedRewards);
    IERC20(token).safeIncreaseAllowance(_gauge, type(uint).max);
    bribes[_gauge] = _bribe;
    gauges[_pool] = _gauge;
    poolForGauge[_gauge] = _pool;
    isGauge[_gauge] = true;
    _updateFor(_gauge);
    pools.push(_pool);
    emit GaugeCreated(_gauge, msg.sender, _bribe, _pool);
    return _gauge;
  }

  /// @dev A gauge should be able to attach a token for preventing transfers/withdraws.
  function attachTokenToGauge(uint tokenId, address account) external override {
    require(isGauge[msg.sender], "!gauge");
    if (tokenId > 0) {
      IVe(ve).attachToken(tokenId);
    }
    emit Attach(account, msg.sender, tokenId);
  }

  /// @dev Emit deposit event for easily handling external actions.
  function emitDeposit(uint tokenId, address account, uint amount) external override {
    require(isGauge[msg.sender], "!gauge");
    emit Deposit(account, msg.sender, tokenId, amount);
  }

  /// @dev Detach given token.
  function detachTokenFromGauge(uint tokenId, address account) external override {
    require(isGauge[msg.sender], "!gauge");
    if (tokenId > 0) {
      IVe(ve).detachToken(tokenId);
    }
    emit Detach(account, msg.sender, tokenId);
  }

  /// @dev Emit withdraw event for easily handling external actions.
  function emitWithdraw(uint tokenId, address account, uint amount) external override {
    require(isGauge[msg.sender], "!gauge");
    emit Withdraw(account, msg.sender, tokenId, amount);
  }

  /// @dev Length of pools
  function poolsLength() external view returns (uint) {
    return pools.length;
  }

  /// @dev Add rewards to this contract. Usually it is DystMinter.
  function notifyRewardAmount(uint amount) external override {
    require(amount != 0, "zero amount");
    uint _totalWeight = totalWeight;
    // without votes rewards can not be added
    require(_totalWeight != 0, "!weights");
    // transfer the distro in
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    // 1e18 adjustment is removed during claim
    uint _ratio = amount * 1e18 / _totalWeight;
    if (_ratio > 0) {
      index += _ratio;
    }
    emit NotifyReward(msg.sender, token, amount);
  }

  /// @dev Update given gauges.
  function updateFor(address[] memory _gauges) external {
    for (uint i = 0; i < _gauges.length; i++) {
      _updateFor(_gauges[i]);
    }
  }

  /// @dev Update gauges by indexes in a range.
  function updateForRange(uint start, uint end) public {
    for (uint i = start; i < end; i++) {
      _updateFor(gauges[pools[i]]);
    }
  }

  /// @dev Update all gauges.
  function updateAll() external {
    updateForRange(0, pools.length);
  }

  /// @dev Update reward info for given gauge.
  function updateGauge(address _gauge) external {
    _updateFor(_gauge);
  }

  function _updateFor(address _gauge) internal {
    address _pool = poolForGauge[_gauge];
    int256 _supplied = weights[_pool];
    if (_supplied > 0) {
      uint _supplyIndex = supplyIndex[_gauge];
      // get global index for accumulated distro
      uint _index = index;
      // update _gauge current position to global position
      supplyIndex[_gauge] = _index;
      // see if there is any difference that need to be accrued
      uint _delta = _index - _supplyIndex;
      if (_delta > 0) {
        // add accrued difference for each supplied token
        uint _share = uint(_supplied) * _delta / 1e18;
        claimable[_gauge] += _share;
      }
    } else {
      // new users are set to the default global state
      supplyIndex[_gauge] = index;
    }
  }

  /// @dev Batch claim rewards from given gauges.
  function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
    for (uint i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
    }
  }

  /// @dev Batch claim rewards from given bribe contracts for given tokenId.
  function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
    require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    for (uint i = 0; i < _bribes.length; i++) {
      IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
    }
  }

  /// @dev Claim fees from given bribes.
  function claimFees(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
    require(IVe(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owner");
    for (uint i = 0; i < _bribes.length; i++) {
      IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
    }
  }

  /// @dev Move fees from deposited pools to bribes for given gauges.
  function distributeFees(address[] memory _gauges) external {
    for (uint i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).claimFees();
    }
  }

  /// @dev Get emission from minter and notify rewards for given gauge.
  function distribute(address _gauge) external override {
    _distribute(_gauge);
  }

  function _distribute(address _gauge) internal lock {
    IMinter(minter).updatePeriod();
    _updateFor(_gauge);
    uint _claimable = claimable[_gauge];
    if (_claimable > IMultiRewardsPool(_gauge).left(token) && _claimable / DURATION > 0) {
      claimable[_gauge] = 0;
      IGauge(_gauge).notifyRewardAmount(token, _claimable);
      emit DistributeReward(msg.sender, _gauge, _claimable);
    }
  }

  /// @dev Distribute rewards for all pools.
  function distributeAll() external {
    uint length = pools.length;
    for (uint x; x < length; x++) {
      _distribute(gauges[pools[x]]);
    }
  }

  function distributeForPoolsInRange(uint start, uint finish) external {
    for (uint x = start; x < finish; x++) {
      _distribute(gauges[pools[x]]);
    }
  }

  function distributeForGauges(address[] memory _gauges) external {
    for (uint x = 0; x < _gauges.length; x++) {
      _distribute(_gauges[x]);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVe {

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  struct LockedBalance {
    int128 amount;
    uint end;
  }

  function token() external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(uint, uint, address) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function depositFor(uint tokenId, uint value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoter {

  function ve() external view returns (address);

  function attachTokenToGauge(uint _tokenId, address account) external;

  function detachTokenFromGauge(uint _tokenId, address account) external;

  function emitDeposit(uint _tokenId, address account, uint amount) external;

  function emitWithdraw(uint _tokenId, address account, uint amount) external;

  function distribute(address _gauge) external;

  function notifyRewardAmount(uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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

pragma solidity ^0.8.13;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGauge {

  function notifyRewardAmount(address token, uint amount) external;

  function getReward(address account, address[] memory tokens) external;

  function claimFees() external returns (uint claimed0, uint claimed1);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFactory {
  function treasury() external view returns (address);

  function isPair(address pair) external view returns (bool);

  function getInitializable() external view returns (address, address, bool);

  function isPaused() external view returns (bool);

  function pairCodeHash() external pure returns (bytes32);

  function getPair(address tokenA, address token, bool stable) external view returns (address);

  function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPair {

  // Structure to capture time period obervations every 30 minutes, used for local oracles
  struct Observation {
    uint timestamp;
    uint reserve0Cumulative;
    uint reserve1Cumulative;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function burn(address to) external returns (uint amount0, uint amount1);

  function mint(address to) external returns (uint liquidity);

  function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

  function getAmountOut(uint, address) external view returns (uint);

  function claimFees() external returns (uint, uint);

  function tokens() external view returns (address, address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function stable() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IBribeFactory {
  function createBribe(address[] memory _allowedRewardTokens) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGaugeFactory {
  function createGauge(
    address _pool,
    address _bribe,
    address _ve,
    address[] memory _allowedRewardTokens
  ) external returns (address);

  function createGaugeSingle(
    address _pool,
    address _bribe,
    address _ve,
    address _voter,
    address[] memory _allowedRewardTokens
  ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMinter {

  function updatePeriod() external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IBribe {

  function notifyRewardAmount(address token, uint amount) external;

  function _deposit(uint amount, uint tokenId) external;

  function _withdraw(uint amount, uint tokenId) external;

  function getRewardForOwner(uint tokenId, address[] memory tokens) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMultiRewardsPool {

  function underlying() external view returns (address);

  function derivedSupply() external view returns (uint);

  function derivedBalances(address account) external view returns (uint);

  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function rewardTokens(uint id) external view returns (address);

  function isRewardToken(address token) external view returns (bool);

  function rewardTokensLength() external view returns (uint);

  function derivedBalance(address account) external view returns (uint);

  function left(address token) external view returns (uint);

  function earned(address token, address account) external view returns (uint);

  function registerRewardToken(address token) external;

  function removeRewardToken(address token) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract Reentrancy {

  /// @dev simple re-entrancy check
  uint internal _unlocked = 1;

  modifier lock() {
    require(_unlocked == 1, "Reentrant call");
    _unlocked = 2;
    _;
    _unlocked = 1;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.13;

import "../interface/IERC20.sol";
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
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
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
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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

pragma solidity ^0.8.13;

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

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call(data);
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