// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IVoter.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IVeTetu.sol";
import "../interfaces/IGauge.sol";
import "../proxy/ControllableV3.sol";
import "./StakelessMultiPoolBase.sol";

/// @title Stakeless pool for vaults
/// @author belbix
contract MultiGauge is StakelessMultiPoolBase, ControllableV3, IGauge {

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant MULTI_GAUGE_VERSION = "1.0.0";

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev The ve token used for gauges
  address public ve;
  /// @dev staking token => ve owner => veId
  mapping(address => mapping(address => uint)) public override veIds;
  /// @dev Staking token => whitelist status
  mapping(address => bool) stakingTokens;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event AddStakingToken(address token);
  event Deposit(address indexed stakingToken, address indexed account, uint amount);
  event Withdraw(address indexed stakingToken, address indexed account, uint amount, bool full, uint veId);
  event VeTokenLocked(address indexed stakingToken, address indexed account, uint tokenId);
  event VeTokenUnlocked(address indexed stakingToken, address indexed account, uint tokenId);

  // *************************************************************
  //                        INIT
  // *************************************************************

  function init(
    address controller_,
    address _operator,
    address _ve,
    address _defaultRewardToken
  ) external initializer {
    __Controllable_init(controller_);
    __MultiPool_init(_operator, _defaultRewardToken);
    ve = _ve;
  }

  function voter() public view returns (IVoter) {
    return IVoter(IController(controller()).voter());
  }

  // *************************************************************
  //                    OPERATOR ACTIONS
  // *************************************************************

  /// @dev Operator can whitelist token. Removing is forbidden.
  function addStakingToken(address token) external onlyOperator {
    stakingTokens[token] = true;
    emit AddStakingToken(token);
  }

  // *************************************************************
  //                        CLAIMS
  // *************************************************************

  function getReward(
    address stakingToken,
    address account,
    address[] memory tokens
  ) external override {
    _getReward(stakingToken, account, tokens);
  }

  function getAllRewards(
    address stakingToken,
    address account
  ) external override {
    _getAllRewards(stakingToken, account);
  }

  function _getAllRewards(
    address stakingToken,
    address account
  ) internal {
    address[] storage rts = rewardTokens[stakingToken];
    uint length = rts.length;
    address[] memory tokens = new address[](length + 1);
    for (uint i; i < length; ++i) {
      tokens[i] = rts[i];
    }
    tokens[length] = defaultRewardToken;
    _getReward(stakingToken, account, tokens);
  }

  function getAllRewardsForTokens(
    address[] memory _stakingTokens,
    address account
  ) external override {
    for (uint i; i < _stakingTokens.length; i++) {
      _getAllRewards(_stakingTokens[i], account);
    }
  }

  function _getReward(address stakingToken, address account, address[] memory tokens) internal {
    voter().distribute(stakingToken);
    _getReward(stakingToken, account, tokens, account);
  }

  // *************************************************************
  //                   VIRTUAL DEPOSIT/WITHDRAW
  // *************************************************************

  function attachVe(address stakingToken, address account, uint veId) external override {
    require(IERC721(ve).ownerOf(veId) == account, "Not ve token owner");
    require(isStakeToken(stakingToken), "Wrong staking token");

    _updateRewardForAllTokens(stakingToken);

    if (veIds[stakingToken][account] == 0) {
      veIds[stakingToken][account] = veId;
      voter().attachTokenToGauge(stakingToken, veId, account);
    }
    require(veIds[stakingToken][account] == veId, "Wrong ve");

    _updateDerivedBalanceAndWriteCheckpoints(stakingToken, account);

    emit VeTokenLocked(stakingToken, account, veId);
  }

  function detachVe(address stakingToken, address account, uint veId) external override {
    require(IERC721(ve).ownerOf(veId) == account
      || msg.sender == address(voter()), "Not ve token owner or voter");
    require(isStakeToken(stakingToken), "Wrong staking token");

    _updateRewardForAllTokens(stakingToken);
    _unlockVeToken(stakingToken, account, veId);
    _updateDerivedBalanceAndWriteCheckpoints(stakingToken, account);
  }

  /// @dev Must be called from stakingToken when user balance changed.
  function handleBalanceChange(address account) external override {
    address stakingToken = msg.sender;
    require(isStakeToken(stakingToken), "Wrong staking token");

    uint stakedBalance = balanceOf[stakingToken][account];
    uint actualBalance = IERC20(stakingToken).balanceOf(account);
    if (stakedBalance < actualBalance) {
      _deposit(stakingToken, account, actualBalance - stakedBalance);
    } else if (stakedBalance > actualBalance) {
      _withdraw(stakingToken, account, stakedBalance - actualBalance, actualBalance == 0);
    }
  }

  function _deposit(
    address stakingToken,
    address account,
    uint amount
  ) internal {
    _registerBalanceIncreasing(stakingToken, account, amount);
    emit Deposit(stakingToken, account, amount);
  }

  function _withdraw(
    address stakingToken,
    address account,
    uint amount,
    bool fullWithdraw
  ) internal {
    uint veId = 0;
    if (fullWithdraw) {
      veId = veIds[stakingToken][account];
    }
    if (veId > 0) {
      _unlockVeToken(stakingToken, account, veId);
    }
    _registerBalanceDecreasing(stakingToken, account, amount);
    emit Withdraw(
      stakingToken,
      account,
      amount,
      fullWithdraw,
      veId
    );
  }

  /// @dev Balance should be recalculated after the unlock
  function _unlockVeToken(address stakingToken, address account, uint veId) internal {
    require(veId == veIds[stakingToken][account], "Wrong ve");
    veIds[stakingToken][account] = 0;
    voter().detachTokenFromGauge(stakingToken, veId, account);
    emit VeTokenUnlocked(stakingToken, account, veId);
  }

  // *************************************************************
  //                   LOGIC OVERRIDES
  // *************************************************************

  /// @dev Similar to Curve https://resources.curve.fi/reward-gauges/boosting-your-crv-rewards#formula
  function _derivedBalance(
    address stakingToken,
    address account
  ) internal override view returns (uint) {
    uint _tokenId = veIds[stakingToken][account];
    uint _balance = balanceOf[stakingToken][account];
    uint _derived = _balance * 40 / 100;
    uint _adjusted = 0;
    uint _supply = IERC20(ve).totalSupply();
    if (account == IERC721(ve).ownerOf(_tokenId) && _supply > 0) {
      _adjusted = (totalSupply[stakingToken] * IVeTetu(ve).balanceOfNFT(_tokenId) / _supply) * 60 / 100;
    }
    return Math.min((_derived + _adjusted), _balance);
  }

  function isStakeToken(address token) public view override returns (bool) {
    return stakingTokens[token];
  }

  // *************************************************************
  //                   REWARDS DISTRIBUTION
  // *************************************************************

  function notifyRewardAmount(address stakingToken, address token, uint amount) external override {
    _notifyRewardAmount(stakingToken, token, amount);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVoter {

  function ve() external view returns (address);

  function attachTokenToGauge(address stakingToken, uint _tokenId, address account) external;

  function detachTokenFromGauge(address stakingToken, uint _tokenId, address account) external;

  function distribute(address stakingToken) external;

  function notifyRewardAmount(uint amount) external;

  function detachTokenFromAll(uint tokenId, address account) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

pragma solidity 0.8.4;

interface IVeTetu {

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

  function attachments(uint tokenId) external view returns (uint);

  function lockedAmounts(uint veId, address stakingToken) external view returns (uint);

  function lockedDerivedAmount(uint veId) external view returns (uint);

  function lockedEnd(uint veId) external view returns (uint);

  function voted(uint tokenId) external view returns (uint);

  function tokens(uint idx) external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(address _token, uint _value, uint _lockDuration, address _to) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function increaseAmount(address _token, uint _tokenId, uint _value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;

  function totalSupplyAt(uint _block) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IGauge {

  function veIds(address stakingToken, address account) external view returns (uint);

  function getReward(
    address stakingToken,
    address account,
    address[] memory tokens
  ) external;

  function getAllRewards(
    address stakingToken,
    address account
  ) external;

  function getAllRewardsForTokens(
    address[] memory stakingTokens,
    address account
  ) external;

  function attachVe(address stakingToken, address account, uint veId) external;

  function detachVe(address stakingToken, address account, uint veId) external;

  function handleBalanceChange(address account) external;

  function notifyRewardAmount(address stakingToken, address token, uint amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/Initializable.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../openzeppelin/Math.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../openzeppelin/Initializable.sol";
import "../interfaces/IMultiPool.sol";
import "../interfaces/IERC20.sol";
import "../lib/CheckpointLib.sol";

/// @title Abstract stakeless pool
/// @author belbix
abstract contract StakelessMultiPoolBase is ReentrancyGuard, IMultiPool, Initializable {
  using SafeERC20 for IERC20;
  using CheckpointLib for mapping(uint => CheckpointLib.Checkpoint);

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant MULTI_POOL_VERSION = "1.0.0";
  /// @dev Rewards are released over 7 days
  uint internal constant _DURATION = 7 days;
  /// @dev Precision for internal calculations
  uint internal constant _PRECISION = 10 ** 18;
  /// @dev Max reward tokens per 1 staking token
  uint internal constant _MAX_REWARD_TOKENS = 10;

  // *************************************************************
  //                        VARIABLES
  //              Keep names and ordering!
  //     Add only in the bottom and adjust __gap variable
  // *************************************************************

  /// @dev Operator can add/remove reward tokens
  address public operator;
  /// @dev This token will be always allowed as reward
  address public defaultRewardToken;

  /// @dev Staking token => Supply adjusted on derived balance logic. Use for rewards boost.
  mapping(address => uint) public override derivedSupply;
  /// @dev Staking token => Account => Staking token virtual balance. Can be adjusted regarding rewards boost logic.
  mapping(address => mapping(address => uint)) public override derivedBalances;
  /// @dev Staking token => Account => User virtual balance of staking token.
  mapping(address => mapping(address => uint)) public override balanceOf;
  /// @dev Staking token => Total amount of attached staking tokens
  mapping(address => uint) public override totalSupply;

  /// @dev Staking token => Reward token => Reward rate with precision 1e18
  mapping(address => mapping(address => uint)) public rewardRate;
  /// @dev Staking token => Reward token => Reward finish period in timestamp.
  mapping(address => mapping(address => uint)) public periodFinish;
  /// @dev Staking token => Reward token => Last updated time for reward token for internal calculations.
  mapping(address => mapping(address => uint)) public lastUpdateTime;
  /// @dev Staking token => Reward token => Part of SNX pool logic. Internal snapshot of reward per token value.
  mapping(address => mapping(address => uint)) public rewardPerTokenStored;

  /// @dev Timestamp of the last claim action.
  mapping(address => mapping(address => mapping(address => uint))) public lastEarn;
  /// @dev Snapshot of user's reward per token for internal calculations.
  mapping(address => mapping(address => mapping(address => uint))) public userRewardPerTokenStored;

  /// @dev Allowed reward tokens for staking token
  mapping(address => address[]) public override rewardTokens;
  /// @dev Allowed reward tokens for staking token stored in map for fast check.
  mapping(address => mapping(address => bool)) public override isRewardToken;

  /// @notice A record of balance checkpoints for each account, by index
  mapping(address => mapping(address => mapping(uint => CheckpointLib.Checkpoint))) public checkpoints;
  /// @notice The number of checkpoints for each account
  mapping(address => mapping(address => uint)) public numCheckpoints;
  /// @notice A record of balance checkpoints for each token, by index
  mapping(address => mapping(uint => CheckpointLib.Checkpoint)) public supplyCheckpoints;
  /// @notice The number of checkpoints
  mapping(address => uint) public supplyNumCheckpoints;
  /// @notice A record of balance checkpoints for each token, by index
  mapping(address => mapping(address => mapping(uint => CheckpointLib.Checkpoint))) public rewardPerTokenCheckpoints;
  /// @notice The number of checkpoints for each token
  mapping(address => mapping(address => uint)) public rewardPerTokenNumCheckpoints;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event BalanceIncreased(address indexed token, address indexed account, uint amount);
  event BalanceDecreased(address indexed token, address indexed account, uint amount);
  event NotifyReward(address indexed from, address token, address indexed reward, uint amount);
  event ClaimRewards(address indexed account, address token, address indexed reward, uint amount, address recepient);

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Operator will able to add/remove reward tokens
  function __MultiPool_init(address _operator, address _defaultRewardToken) internal onlyInitializing {
    operator = _operator;
    defaultRewardToken = _defaultRewardToken;
  }

  // *************************************************************
  //                        RESTRICTIONS
  // *************************************************************

  modifier onlyOperator() {
    require(msg.sender == operator, "Not operator");
    _;
  }

  // *************************************************************
  //                            VIEWS
  // *************************************************************

  /// @dev Should return true for whitelisted for rewards tokens
  function isStakeToken(address token) public view override virtual returns (bool);

  /// @dev Length of rewards tokens array for given token
  function rewardTokensLength(address token) external view override returns (uint) {
    return rewardTokens[token].length;
  }

  /// @dev Reward paid for token for the current period.
  function rewardPerToken(address stakeToken, address rewardToken) public view returns (uint) {
    uint _derivedSupply = derivedSupply[stakeToken];
    if (_derivedSupply == 0) {
      return rewardPerTokenStored[stakeToken][rewardToken];
    }
    return rewardPerTokenStored[stakeToken][rewardToken]
    + (
    (_lastTimeRewardApplicable(stakeToken, rewardToken)
    - Math.min(lastUpdateTime[stakeToken][rewardToken], periodFinish[stakeToken][rewardToken]))
    * rewardRate[stakeToken][rewardToken]
    / _derivedSupply
    );
  }

  /// @dev Balance of holder adjusted with specific rules for boost calculation.
  function derivedBalance(address token, address account) external view override returns (uint) {
    return _derivedBalance(token, account);
  }

  /// @dev Amount of reward tokens left for the current period
  function left(address stakeToken, address rewardToken) external view override returns (uint) {
    uint _periodFinish = periodFinish[stakeToken][rewardToken];
    if (block.timestamp >= _periodFinish) return 0;
    uint _remaining = _periodFinish - block.timestamp;
    return _remaining * rewardRate[stakeToken][rewardToken] / _PRECISION;
  }

  /// @dev Approximate of earned rewards ready to claim
  function earned(address stakeToken, address rewardToken, address account) external view override returns (uint) {
    return _earned(stakeToken, rewardToken, account);
  }

  // *************************************************************
  //                  OPERATOR ACTIONS
  // *************************************************************

  /// @dev Whitelist reward token for staking token. Only operator can do it.
  function registerRewardToken(address stakeToken, address rewardToken) external override onlyOperator {
    require(rewardTokens[stakeToken].length < _MAX_REWARD_TOKENS, "Too many reward tokens");
    require(!isRewardToken[stakeToken][rewardToken], "Already registered");
    isRewardToken[stakeToken][rewardToken] = true;
    rewardTokens[stakeToken].push(rewardToken);
  }

  /// @dev Remove from whitelist reward token for staking token. Only operator can do it.
  ///      We assume that the first token can not be removed.
  function removeRewardToken(address stakeToken, address rewardToken) external override onlyOperator {
    require(periodFinish[stakeToken][rewardToken] < block.timestamp, "Rewards not ended");
    require(isRewardToken[stakeToken][rewardToken], "Not reward token");

    isRewardToken[stakeToken][rewardToken] = false;
    uint length = rewardTokens[stakeToken].length;
    uint i = 0;
    bool found = false;
    for (; i < length; i++) {
      address t = rewardTokens[stakeToken][i];
      if (t == rewardToken) {
        found = true;
        break;
      }
    }
    // if isRewardToken map and rewardTokens array changed accordingly the token always exist
    rewardTokens[stakeToken][i] = rewardTokens[stakeToken][length - 1];
    rewardTokens[stakeToken].pop();
  }

  // *************************************************************
  //                      USER ACTIONS
  // *************************************************************

  /// @dev Assume to be called when linked token balance changes.
  function _registerBalanceIncreasing(
    address stakingToken,
    address account,
    uint amount
  ) internal virtual nonReentrant {
    require(isStakeToken(stakingToken), "Staking token not allowed");
    require(amount > 0, "Zero amount");

    _increaseBalance(stakingToken, account, amount);
    emit BalanceIncreased(stakingToken, account, amount);
  }

  function _increaseBalance(
    address stakingToken,
    address account,
    uint amount
  ) internal virtual {
    _updateRewardForAllTokens(stakingToken);
    totalSupply[stakingToken] += amount;
    balanceOf[stakingToken][account] += amount;
    _updateDerivedBalanceAndWriteCheckpoints(stakingToken, account);
  }

  /// @dev Assume to be called when linked token balance changes.
  function _registerBalanceDecreasing(
    address stakingToken,
    address account,
    uint amount
  ) internal nonReentrant virtual {
    require(isStakeToken(stakingToken), "Staking token not allowed");
    _decreaseBalance(stakingToken, account, amount);
    emit BalanceDecreased(stakingToken, account, amount);
  }

  function _decreaseBalance(
    address stakingToken,
    address account,
    uint amount
  ) internal virtual {
    _updateRewardForAllTokens(stakingToken);
    totalSupply[stakingToken] -= amount;
    balanceOf[stakingToken][account] -= amount;
    _updateDerivedBalanceAndWriteCheckpoints(stakingToken, account);
  }

  /// @dev Caller should implement restriction checks
  function _getReward(
    address stakingToken,
    address account,
    address[] memory rewardTokens_,
    address recipient
  ) internal nonReentrant virtual {
    for (uint i = 0; i < rewardTokens_.length; i++) {
      (rewardPerTokenStored[stakingToken][rewardTokens_[i]], lastUpdateTime[stakingToken][rewardTokens_[i]])
      = _updateRewardPerToken(stakingToken, rewardTokens_[i], type(uint).max, true);

      uint _reward = _earned(stakingToken, rewardTokens_[i], account);
      lastEarn[stakingToken][rewardTokens_[i]][account] = block.timestamp;
      userRewardPerTokenStored[stakingToken][rewardTokens_[i]][account] = rewardPerTokenStored[stakingToken][rewardTokens_[i]];
      if (_reward > 0) {
        IERC20(rewardTokens_[i]).safeTransfer(recipient, _reward);
      }

      emit ClaimRewards(account, stakingToken, rewardTokens_[i], _reward, recipient);
    }

    _updateDerivedBalanceAndWriteCheckpoints(stakingToken, account);
  }

  function _updateDerivedBalanceAndWriteCheckpoints(address stakingToken, address account) internal {
    uint __derivedBalance = derivedBalances[stakingToken][account];
    derivedSupply[stakingToken] -= __derivedBalance;
    __derivedBalance = _derivedBalance(stakingToken, account);
    derivedBalances[stakingToken][account] = __derivedBalance;
    derivedSupply[stakingToken] += __derivedBalance;

    _writeCheckpoint(stakingToken, account, __derivedBalance);
    _writeSupplyCheckpoint(stakingToken);
  }

  // *************************************************************
  //                    REWARDS CALCULATIONS
  // *************************************************************

  /// @dev Earned is an estimation, it won't be exact till the supply > rewardPerToken calculations have run
  function _earned(
    address stakingToken,
    address rewardToken,
    address account
  ) internal view returns (uint) {
    // zero checkpoints means zero deposits
    if (numCheckpoints[stakingToken][account] == 0) {
      return 0;
    }
    // last claim rewards time
    uint _startTimestamp = Math.max(
      lastEarn[stakingToken][rewardToken][account],
      rewardPerTokenCheckpoints[stakingToken][rewardToken][0].timestamp
    );

    // find an index of the balance that the user had on the last claim
    uint _startIndex = getPriorBalanceIndex(stakingToken, account, _startTimestamp);
    uint _endIndex = numCheckpoints[stakingToken][account] - 1;

    uint reward = 0;

    // calculate previous snapshots if exist
    if (_endIndex > 0) {
      for (uint i = _startIndex; i <= _endIndex - 1; i++) {
        CheckpointLib.Checkpoint memory cp0 = checkpoints[stakingToken][account][i];
        CheckpointLib.Checkpoint memory cp1 = checkpoints[stakingToken][account][i + 1];
        (uint _rewardPerTokenStored0,) = getPriorRewardPerToken(stakingToken, rewardToken, cp0.timestamp);
        (uint _rewardPerTokenStored1,) = getPriorRewardPerToken(stakingToken, rewardToken, cp1.timestamp);
        reward += cp0.value * (_rewardPerTokenStored1 - _rewardPerTokenStored0) / _PRECISION;
      }
    }

    CheckpointLib.Checkpoint memory cp = checkpoints[stakingToken][account][_endIndex];
    (uint _rewardPerTokenStored,) = getPriorRewardPerToken(stakingToken, rewardToken, cp.timestamp);
    reward += cp.value * (
    rewardPerToken(stakingToken, rewardToken) - Math.max(
      _rewardPerTokenStored,
      userRewardPerTokenStored[stakingToken][rewardToken][account]
    )
    ) / _PRECISION;
    return reward;
  }

  /// @dev Supposed to be implemented in a parent contract
  ///      Adjust user balance with some logic, like boost logic.
  function _derivedBalance(
    address stakingToken,
    address account
  ) internal virtual view returns (uint) {
    return balanceOf[stakingToken][account];
  }

  /// @dev Update stored rewardPerToken values without the last one snapshot
  ///      If the contract will get "out of gas" error on users actions this will be helpful
  function batchUpdateRewardPerToken(
    address stakingToken,
    address rewardToken,
    uint maxRuns
  ) external {
    (rewardPerTokenStored[stakingToken][rewardToken], lastUpdateTime[stakingToken][rewardToken])
    = _updateRewardPerToken(stakingToken, rewardToken, maxRuns, false);
  }

  function _updateRewardForAllTokens(address stakingToken) internal {
    uint length = rewardTokens[stakingToken].length;
    for (uint i; i < length; i++) {
      address rewardToken = rewardTokens[stakingToken][i];
      (rewardPerTokenStored[stakingToken][rewardToken], lastUpdateTime[stakingToken][rewardToken])
      = _updateRewardPerToken(stakingToken, rewardToken, type(uint).max, true);
    }
    // update for default token
    address _defaultRewardToken = defaultRewardToken;
    (rewardPerTokenStored[stakingToken][_defaultRewardToken], lastUpdateTime[stakingToken][_defaultRewardToken])
    = _updateRewardPerToken(stakingToken, _defaultRewardToken, type(uint).max, true);
  }

  /// @dev Should be called only with properly updated snapshots, or with actualLast=false
  function _updateRewardPerToken(
    address stakingToken,
    address rewardToken,
    uint maxRuns,
    bool actualLast
  ) internal returns (uint, uint) {
    uint _startTimestamp = lastUpdateTime[stakingToken][rewardToken];
    uint reward = rewardPerTokenStored[stakingToken][rewardToken];

    if (supplyNumCheckpoints[stakingToken] == 0) {
      return (reward, _startTimestamp);
    }

    if (rewardRate[stakingToken][rewardToken] == 0) {
      return (reward, block.timestamp);
    }
    uint _startIndex = getPriorSupplyIndex(stakingToken, _startTimestamp);
    uint _endIndex = Math.min(supplyNumCheckpoints[stakingToken] - 1, maxRuns);

    if (_endIndex > 0) {
      for (uint i = _startIndex; i <= _endIndex - 1; i++) {
        CheckpointLib.Checkpoint memory sp0 = supplyCheckpoints[stakingToken][i];
        if (sp0.value > 0) {
          CheckpointLib.Checkpoint memory sp1 = supplyCheckpoints[stakingToken][i + 1];
          (uint _reward, uint _endTime) = _calcRewardPerToken(
            stakingToken,
            rewardToken,
            sp1.timestamp,
            sp0.timestamp,
            sp0.value,
            _startTimestamp
          );
          reward += _reward;
          _writeRewardPerTokenCheckpoint(stakingToken, rewardToken, reward, _endTime);
          _startTimestamp = _endTime;
        }
      }
    }

    // need to override the last value with actual numbers only on deposit/withdraw/claim/notify actions
    if (actualLast) {
      CheckpointLib.Checkpoint memory sp = supplyCheckpoints[stakingToken][_endIndex];
      if (sp.value > 0) {
        (uint _reward,) = _calcRewardPerToken(
          stakingToken,
          rewardToken,
          _lastTimeRewardApplicable(stakingToken, rewardToken),
          Math.max(sp.timestamp, _startTimestamp),
          sp.value,
          _startTimestamp
        );
        reward += _reward;
        _writeRewardPerTokenCheckpoint(stakingToken, rewardToken, reward, block.timestamp);
        _startTimestamp = block.timestamp;
      }
    }

    return (reward, _startTimestamp);
  }

  function _calcRewardPerToken(
    address stakingToken,
    address token,
    uint lastSupplyTs1,
    uint lastSupplyTs0,
    uint supply,
    uint startTimestamp
  ) internal view returns (uint, uint) {
    uint endTime = Math.max(lastSupplyTs1, startTimestamp);
    uint _periodFinish = periodFinish[stakingToken][token];
    return (
    (Math.min(endTime, _periodFinish) - Math.min(Math.max(lastSupplyTs0, startTimestamp), _periodFinish))
    * rewardRate[stakingToken][token] / supply
    , endTime);
  }

  /// @dev Returns the last time the reward was modified or periodFinish if the reward has ended
  function _lastTimeRewardApplicable(address stakeToken, address rewardToken) internal view returns (uint) {
    return Math.min(block.timestamp, periodFinish[stakeToken][rewardToken]);
  }

  // *************************************************************
  //                         NOTIFY
  // *************************************************************

  function _notifyRewardAmount(
    address stakingToken,
    address rewardToken,
    uint amount
  ) internal nonReentrant virtual {
    require(amount > 0, "Zero amount");
    require(defaultRewardToken == rewardToken
      || isRewardToken[stakingToken][rewardToken], "Token not allowed");
    if (rewardRate[stakingToken][rewardToken] == 0) {
      _writeRewardPerTokenCheckpoint(stakingToken, rewardToken, 0, block.timestamp);
    }
    (rewardPerTokenStored[stakingToken][rewardToken], lastUpdateTime[stakingToken][rewardToken])
    = _updateRewardPerToken(stakingToken, rewardToken, type(uint).max, true);

    IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amount);

    if (block.timestamp >= periodFinish[stakingToken][rewardToken]) {
      rewardRate[stakingToken][rewardToken] = amount * _PRECISION / _DURATION;
    } else {
      uint _remaining = periodFinish[stakingToken][rewardToken] - block.timestamp;
      uint _left = _remaining * rewardRate[stakingToken][rewardToken];
      // rewards should not extend period infinity, only higher amount allowed
      require(amount > _left / _PRECISION, "Amount should be higher than remaining rewards");
      rewardRate[stakingToken][rewardToken] = (amount * _PRECISION + _left) / _DURATION;
    }

    periodFinish[stakingToken][rewardToken] = block.timestamp + _DURATION;
    emit NotifyReward(msg.sender, stakingToken, rewardToken, amount);
  }

  // *************************************************************
  //                          CHECKPOINTS
  // *************************************************************

  /// @notice Determine the prior balance for an account as of a block number
  /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
  /// @param stakingToken The address of the staking token to check
  /// @param account The address of the account to check
  /// @param timestamp The timestamp to get the balance at
  /// @return The balance the account had as of the given block
  function getPriorBalanceIndex(
    address stakingToken,
    address account,
    uint timestamp
  ) public view returns (uint) {
    uint nCheckpoints = numCheckpoints[stakingToken][account];
    if (nCheckpoints == 0) {
      return 0;
    }
    return checkpoints[stakingToken][account].findLowerIndex(nCheckpoints, timestamp);
  }

  function getPriorSupplyIndex(address stakingToken, uint timestamp) public view returns (uint) {
    uint nCheckpoints = supplyNumCheckpoints[stakingToken];
    if (nCheckpoints == 0) {
      return 0;
    }
    return supplyCheckpoints[stakingToken].findLowerIndex(nCheckpoints, timestamp);
  }

  function getPriorRewardPerToken(
    address stakingToken,
    address rewardToken,
    uint timestamp
  ) public view returns (uint, uint) {
    uint nCheckpoints = rewardPerTokenNumCheckpoints[stakingToken][rewardToken];
    if (nCheckpoints == 0) {
      return (0, 0);
    }
    mapping(uint => CheckpointLib.Checkpoint) storage cps =
    rewardPerTokenCheckpoints[stakingToken][rewardToken];
    uint lower = cps.findLowerIndex(nCheckpoints, timestamp);
    CheckpointLib.Checkpoint memory cp = cps[lower];
    return (cp.value, cp.timestamp);
  }

  function _writeCheckpoint(
    address stakingToken,
    address account,
    uint balance
  ) internal {
    uint _timestamp = block.timestamp;
    uint _nCheckPoints = numCheckpoints[stakingToken][account];

    if (_nCheckPoints > 0 && checkpoints[stakingToken][account][_nCheckPoints - 1].timestamp == _timestamp) {
      checkpoints[stakingToken][account][_nCheckPoints - 1].value = balance;
    } else {
      checkpoints[stakingToken][account][_nCheckPoints] = CheckpointLib.Checkpoint(_timestamp, balance);
      numCheckpoints[stakingToken][account] = _nCheckPoints + 1;
    }
  }

  function _writeRewardPerTokenCheckpoint(
    address stakingToken,
    address rewardToken,
    uint reward,
    uint timestamp
  ) internal {
    uint _nCheckPoints = rewardPerTokenNumCheckpoints[stakingToken][rewardToken];
    if (_nCheckPoints > 0 && rewardPerTokenCheckpoints[stakingToken][rewardToken][_nCheckPoints - 1].timestamp == timestamp) {
      rewardPerTokenCheckpoints[stakingToken][rewardToken][_nCheckPoints - 1].value = reward;
    } else {
      rewardPerTokenCheckpoints[stakingToken][rewardToken][_nCheckPoints] = CheckpointLib.Checkpoint(timestamp, reward);
      rewardPerTokenNumCheckpoints[stakingToken][rewardToken] = _nCheckPoints + 1;
    }
  }

  function _writeSupplyCheckpoint(address stakingToken) internal {
    uint _nCheckPoints = supplyNumCheckpoints[stakingToken];
    uint _timestamp = block.timestamp;

    if (_nCheckPoints > 0 && supplyCheckpoints[stakingToken][_nCheckPoints - 1].timestamp == _timestamp) {
      supplyCheckpoints[stakingToken][_nCheckPoints - 1].value = derivedSupply[stakingToken];
    } else {
      supplyCheckpoints[stakingToken][_nCheckPoints] = CheckpointLib.Checkpoint(_timestamp, derivedSupply[stakingToken]);
      supplyNumCheckpoints[stakingToken] = _nCheckPoints + 1;
    }
  }

  /**
* @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
  uint[38] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
     */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
     */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
  modifier initializer() {
    bool isTopLevelCall = _setInitializedVersion(1);
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
  modifier reinitializer(uint8 version) {
    bool isTopLevelCall = _setInitializedVersion(version);
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(version);
    }
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
  function _disableInitializers() internal virtual {
    _setInitializedVersion(type(uint8).max);
  }

  function _setInitializedVersion(uint8 version) private returns (bool) {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
    // of initializers, because in other contexts the contract may have been reentered.
    if (_initializing) {
      require(
        version == 1 && !Address.isContract(address(this)),
        "Initializable: contract is already initialized"
      );
      return false;
    } else {
      require(_initialized < version, "Initializable: contract is already initialized");
      _initialized = version;
      return true;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/utils/AddressUpgradeable.sol
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
  function sendValue(address payable recipient, uint amount) internal {
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
    uint value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint value,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/token/ERC20/utils/SafeERC20.sol
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
    uint value
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
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
  unchecked {
    uint oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint newAllowance = oldAllowance - value;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

  constructor() {
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

pragma solidity 0.8.4;

interface IMultiPool {

  function totalSupply(address stakingToken) external view returns (uint);

  function derivedSupply(address stakingToken) external view returns (uint);

  function derivedBalances(address stakingToken, address account) external view returns (uint);

  function balanceOf(address stakingToken, address account) external view returns (uint);

  function rewardTokens(address stakingToken, uint id) external view returns (address);

  function isRewardToken(address stakingToken, address token) external view returns (bool);

  function rewardTokensLength(address stakingToken) external view returns (uint);

  function derivedBalance(address stakingToken, address account) external view returns (uint);

  function left(address stakingToken, address token) external view returns (uint);

  function earned(address stakingToken, address token, address account) external view returns (uint);

  function registerRewardToken(address stakingToken, address token) external;

  function removeRewardToken(address stakingToken, address token) external;

  function isStakeToken(address token) external view returns (bool);

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
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

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
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Library for find lower index in checkpoints. Uses with MultiPool
/// @author belbix
library CheckpointLib {

  /// @notice A checkpoint for uint value
  struct Checkpoint {
    uint timestamp;
    uint value;
  }

  function findLowerIndex(mapping(uint => Checkpoint) storage checkpoints, uint size, uint timestamp) internal view returns (uint) {
    require(size != 0, "Empty checkpoints");

    // First check most recent value
    if (checkpoints[size - 1].timestamp <= timestamp) {
      return (size - 1);
    }

    // Next check implicit zero value
    if (checkpoints[0].timestamp > timestamp) {
      return 0;
    }

    uint lower = 0;
    uint upper = size - 1;
    while (upper > lower) {
      // ceil, avoiding overflow
      uint center = upper - (upper - lower) / 2;
      Checkpoint memory cp = checkpoints[center];
      if (cp.timestamp == timestamp) {
        return center;
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return lower;
  }

}