// SPDX-License-Identifier: MIT

/*

  by             .__________                 ___ ___
  __  _  __ ____ |__\_____  \  ___________  /   |   \_____    ______ ____
  \ \/ \/ // __ \|  | _(__  <_/ __ \_  __ \/    ~    \__  \  /  ___// __ \
   \     /\  ___/|  |/       \  ___/|  | \/\    Y    // __ \_\___ \\  ___/
    \/\_/  \___  >__/______  /\___  >__|    \___|_  /(____  /____  >\___  >
               \/          \/     \/              \/      \/     \/     \/

*/

pragma solidity >=0.8.4 <0.9.0;

import './utils/Governable.sol';
import './utils/Keep3rJob.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

interface IChess {
  function board() external returns (uint256 _board);

  function mintMove(uint256 _move, uint256 _depth) external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external;
}

contract Kasparov is Governable, Keep3rJob, IERC721Receiver {
  address constant internal fiveOutOfNine = 0xB543F9043b387cE5B3d1F0d916E42D8eA2eBA2E0;
  
  uint256 internal board;
  uint256[] internal moves;
  uint256 internal nextMove;
  uint256 internal depth = 3;

  error UnknownBoard();
  error NoMoves();
  error UnknownNFT();

  constructor() Governable(msg.sender) {}

  function work() external upkeep {
    if (nextMove == moves.length) revert NoMoves();
    _checkBoard();
    _playNextMove();
  }

  function workMany(uint256 j) external upkeep {
    _checkBoard();
    if (j == 0) revert NoMoves();
    for (uint256 i = 0; i < j; i++) {
      _playNextMove();
    }
  }

  // Governable

  function addMoves(uint256[] memory _moves, bool _append) external onlyGovernor {
    if (!_append) {
      delete moves;
      delete nextMove;
    }
    for (uint256 i = 0; i < _moves.length; i++) {
      moves.push(_moves[i]);
    }
    board = IChess(fiveOutOfNine).board();
  }

  function setDepth(uint256 _depth) external onlyGovernor {
    depth = _depth;
  }

  // Internal

  function _playNextMove() internal {
    IChess(fiveOutOfNine).mintMove(moves[nextMove++], depth);
    board = IChess(fiveOutOfNine).board();
  }

  function _checkBoard() internal {
    uint256 _actualBoard = IChess(fiveOutOfNine).board();
    if (board != _actualBoard) revert UnknownBoard();
  }

  // @dev Transfers ERC721 to owner on reception
  function onERC721Received(
    address,
    address,
    uint256 _tokenId,
    bytes memory
  ) external override returns (bytes4) {
    if (msg.sender != fiveOutOfNine) revert UnknownNFT();
    IChess(fiveOutOfNine).transferFrom(address(this), governor, _tokenId);
    return 0x150b7a02;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../../interfaces/utils/IGovernable.sol';

abstract contract Governable is IGovernable {
  address public override governor;
  address public override pendingGovernor;

  constructor(address _governor) {
    if (_governor == address(0)) revert ZeroAddress();
    governor = _governor;
  }

  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    if (_pendingGovernor == address(0)) revert ZeroAddress();
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(governor, pendingGovernor);
  }

  function acceptPendingGovernor() external override onlyPendingGovernor {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit PendingGovernorAccepted(governor);
  }

  modifier onlyGovernor() {
    if (msg.sender != governor) revert OnlyGovernor();
    _;
  }

  modifier onlyPendingGovernor() {
    if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Governable.sol';
import '../../interfaces/utils/IKeep3rJob.sol';
import '../../interfaces/external/IKeep3rV2.sol';

abstract contract Keep3rJob is IKeep3rJob, Governable {
  address public override keep3r = 0x4A6cFf9E1456eAa3b6f37572395C6fa0c959edAB;

  function setKeep3r(address _keep3r) public override onlyGovernor {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function _isValidKeeper(address _keeper) internal virtual {
    if (!IKeep3rV2(keep3r).isKeeper(_keeper)) revert KeeperNotValid();
  }

  modifier upkeep() {
    _isValidKeeper(msg.sender);
    _;
    IKeep3rV2(keep3r).worked(msg.sender);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

interface IGovernable is IBaseErrors {
  // events
  event PendingGovernorSet(address _governor, address _pendingGovernor);
  event PendingGovernorAccepted(address _newGovernor);

  // errors
  error OnlyGovernor();
  error OnlyPendingGovernor();

  // variables
  function governor() external view returns (address _governor);

  function pendingGovernor() external view returns (address _pendingGovernor);

  // methods
  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

interface IBaseErrors {
  /// @notice Throws if a variable is assigned to the zero address
  error ZeroAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IKeep3rJob is IGovernable {
  // events
  event Keep3rSet(address _keep3r);

  // errors
  error KeeperNotValid();

  // variables
  function keep3r() external view returns (address _keep3r);

  // methods
  function setKeep3r(address _keep3r) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IKeep3rV2 {
  /// @notice Stores the tick information of the different liquidity pairs
  struct TickCache {
    int56 current; // Tracks the current tick
    int56 difference; // Stores the difference between the current tick and the last tick
    uint256 period; // Stores the period at which the last observation was made
  }

  // Events

  /// @notice Emitted when the Keep3rHelper address is changed
  /// @param _keep3rHelper The address of Keep3rHelper's contract
  event Keep3rHelperChange(address _keep3rHelper);

  /// @notice Emitted when the Keep3rV1 address is changed
  /// @param _keep3rV1 The address of Keep3rV1's contract
  event Keep3rV1Change(address _keep3rV1);

  /// @notice Emitted when the Keep3rV1Proxy address is changed
  /// @param _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  event Keep3rV1ProxyChange(address _keep3rV1Proxy);

  /// @notice Emitted when the KP3R-WETH pool address is changed
  /// @param _kp3rWethPool The address of the KP3R-WETH pool
  event Kp3rWethPoolChange(address _kp3rWethPool);

  /// @notice Emitted when bondTime is changed
  /// @param _bondTime The new bondTime
  event BondTimeChange(uint256 _bondTime);

  /// @notice Emitted when _liquidityMinimum is changed
  /// @param _liquidityMinimum The new _liquidityMinimum
  event LiquidityMinimumChange(uint256 _liquidityMinimum);

  /// @notice Emitted when _unbondTime is changed
  /// @param _unbondTime The new _unbondTime
  event UnbondTimeChange(uint256 _unbondTime);

  /// @notice Emitted when _rewardPeriodTime is changed
  /// @param _rewardPeriodTime The new _rewardPeriodTime
  event RewardPeriodTimeChange(uint256 _rewardPeriodTime);

  /// @notice Emitted when the inflationPeriod is changed
  /// @param _inflationPeriod The new inflationPeriod
  event InflationPeriodChange(uint256 _inflationPeriod);

  /// @notice Emitted when the fee is changed
  /// @param _fee The new token credits fee
  event FeeChange(uint256 _fee);

  /// @notice Emitted when a slasher is added
  /// @param _slasher Address of the added slasher
  event SlasherAdded(address _slasher);

  /// @notice Emitted when a slasher is removed
  /// @param _slasher Address of the removed slasher
  event SlasherRemoved(address _slasher);

  /// @notice Emitted when a disputer is added
  /// @param _disputer Address of the added disputer
  event DisputerAdded(address _disputer);

  /// @notice Emitted when a disputer is removed
  /// @param _disputer Address of the removed disputer
  event DisputerRemoved(address _disputer);

  /// @notice Emitted when the bonding process of a new keeper begins
  /// @param _keeper The caller of Keep3rKeeperFundable#bond function
  /// @param _bonding The asset the keeper has bonded
  /// @param _amount The amount the keeper has bonded
  event Bonding(address indexed _keeper, address indexed _bonding, uint256 _amount);

  /// @notice Emitted when a keeper or job begins the unbonding process to withdraw the funds
  /// @param _keeperOrJob The keeper or job that began the unbonding process
  /// @param _unbonding The liquidity pair or asset being unbonded
  /// @param _amount The amount being unbonded
  event Unbonding(address indexed _keeperOrJob, address indexed _unbonding, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#activate is called
  /// @param _keeper The keeper that has been activated
  /// @param _bond The asset the keeper has bonded
  /// @param _amount The amount of the asset the keeper has bonded
  event Activation(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperFundable#withdraw is called
  /// @param _keeper The caller of Keep3rKeeperFundable#withdraw function
  /// @param _bond The asset to withdraw from the bonding pool
  /// @param _amount The amount of funds withdrawn
  event Withdrawal(address indexed _keeper, address indexed _bond, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#slash is called
  /// @param _keeper The slashed keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#slash
  /// @param _amount The amount of credits slashed from the keeper
  event KeeperSlash(address indexed _keeper, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rKeeperDisputable#revoke is called
  /// @param _keeper The revoked keeper
  /// @param _slasher The user that called Keep3rKeeperDisputable#revoke
  event KeeperRevoke(address indexed _keeper, address indexed _slasher);

  /// @notice Emitted when Keep3rJobFundableCredits#addTokenCreditsToJob is called
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being provided
  /// @param _provider The user that calls the function
  /// @param _amount The amount of credit being added to the job
  event TokenCreditAddition(address indexed _job, address indexed _token, address indexed _provider, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableCredits#withdrawTokenCreditsFromJob is called
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The credit being withdrawn from the job
  /// @param _receiver The user that receives the tokens
  /// @param _amount The amount of credit withdrawn
  event TokenCreditWithdrawal(address indexed _job, address indexed _token, address indexed _receiver, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableLiquidity#approveLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being approved
  event LiquidityApproval(address _liquidity);

  /// @notice Emitted when Keep3rJobFundableLiquidity#revokeLiquidity function is called
  /// @param _liquidity The address of the liquidity pair being revoked
  event LiquidityRevocation(address _liquidity);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job to which liquidity will be added
  /// @param _liquidity The address of the liquidity being added
  /// @param _provider The user that calls the function
  /// @param _amount The amount of liquidity being added
  event LiquidityAddition(address indexed _job, address indexed _liquidity, address indexed _provider, uint256 _amount);

  /// @notice Emitted when IKeep3rJobFundableLiquidity#withdrawLiquidityFromJob function is called
  /// @param _job The address of the job of which liquidity will be withdrawn from
  /// @param _liquidity The address of the liquidity being withdrawn
  /// @param _receiver The receiver of the liquidity tokens
  /// @param _amount The amount of liquidity being withdrawn from the job
  event LiquidityWithdrawal(address indexed _job, address indexed _liquidity, address indexed _receiver, uint256 _amount);

  /// @notice Emitted when Keep3rJobFundableLiquidity#addLiquidityToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  /// @param _periodCredits The credits of the job for the current period
  event LiquidityCreditsReward(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits, uint256 _periodCredits);

  /// @notice Emitted when Keep3rJobFundableLiquidity#forceLiquidityCreditsToJob function is called
  /// @param _job The address of the job whose credits will be updated
  /// @param _rewardedAt The time at which the job was last rewarded
  /// @param _currentCredits The current credits of the job
  event LiquidityCreditsForced(address indexed _job, uint256 _rewardedAt, uint256 _currentCredits);

  /// @notice Emitted when Keep3rJobManager#addJob is called
  /// @param _job The address of the job to add
  /// @param _jobOwner The job's owner
  event JobAddition(address indexed _job, address indexed _jobOwner);

  /// @notice Emitted when a keeper is validated before a job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of keeper validation
  event KeeperValidation(uint256 _gasLeft);

  /// @notice Emitted when a keeper works a job
  /// @param _credit The address of the asset in which the keeper is paid
  /// @param _job The address of the job the keeper has worked
  /// @param _keeper The address of the keeper that has worked the job
  /// @param _amount The amount that has been paid out to the keeper in exchange for working the job
  /// @param _gasLeft The amount of gas that the transaction has left at the moment of payment
  event KeeperWork(address indexed _credit, address indexed _job, address indexed _keeper, uint256 _amount, uint256 _gasLeft);

  /// @notice Emitted when Keep3rJobOwnership#changeJobOwnership is called
  /// @param _job The address of the job proposed to have a change of owner
  /// @param _owner The current owner of the job
  /// @param _pendingOwner The new address proposed to be the owner of the job
  event JobOwnershipChange(address indexed _job, address indexed _owner, address indexed _pendingOwner);

  /// @notice Emitted when Keep3rJobOwnership#JobOwnershipAssent is called
  /// @param _job The address of the job which the proposed owner will now own
  /// @param _previousOwner The previous owner of the job
  /// @param _newOwner The newowner of the job
  event JobOwnershipAssent(address indexed _job, address indexed _previousOwner, address indexed _newOwner);

  /// @notice Emitted when Keep3rJobMigration#migrateJob function is called
  /// @param _fromJob The address of the job that requests to migrate
  /// @param _toJob The address at which the job requests to migrate
  event JobMigrationRequested(address indexed _fromJob, address _toJob);

  /// @notice Emitted when Keep3rJobMigration#acceptJobMigration function is called
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address at which the job had requested to migrate
  event JobMigrationSuccessful(address _fromJob, address indexed _toJob);

  /// @notice Emitted when Keep3rJobDisputable#slashTokenFromJob is called
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token being slashed
  /// @param _slasher The user that slashes the token
  /// @param _amount The amount of the token being slashed
  event JobSlashToken(address indexed _job, address _token, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when Keep3rJobDisputable#slashLiquidityFromJob is called
  /// @param _job The address of the job from which the liquidity will be slashed
  /// @param _liquidity The address of the liquidity being slashed
  /// @param _slasher The user that slashes the liquidity
  /// @param _amount The amount of the liquidity being slashed
  event JobSlashLiquidity(address indexed _job, address _liquidity, address indexed _slasher, uint256 _amount);

  /// @notice Emitted when a keeper or a job is disputed
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _disputer The user that called the function and disputed the keeper
  event Dispute(address indexed _jobOrKeeper, address indexed _disputer);

  /// @notice Emitted when a dispute is resolved
  /// @param _jobOrKeeper The address of the disputed keeper/job
  /// @param _resolver The user that called the function and resolved the dispute
  event Resolve(address indexed _jobOrKeeper, address indexed _resolver);

  // Errors

  /// @notice Throws if the reward period is less than the minimum reward period time
  error MinRewardPeriod();

  /// @notice Throws if either a job or a keeper is disputed
  error Disputed();

  /// @notice Throws if there are no bonded assets
  error BondsUnexistent();

  /// @notice Throws if the time required to bond an asset has not passed yet
  error BondsLocked();

  /// @notice Throws if there are no bonds to withdraw
  error UnbondsUnexistent();

  /// @notice Throws if the time required to withdraw the bonds has not passed yet
  error UnbondsLocked();

  /// @notice Throws if the address is already a registered slasher
  error SlasherExistent();

  /// @notice Throws if caller is not a registered slasher
  error SlasherUnexistent();

  /// @notice Throws if the address is already a registered disputer
  error DisputerExistent();

  /// @notice Throws if caller is not a registered disputer
  error DisputerUnexistent();

  /// @notice Throws if the msg.sender is not a slasher or is not a part of governance
  error OnlySlasher();

  /// @notice Throws if the msg.sender is not a disputer or is not a part of governance
  error OnlyDisputer();

  /// @notice Throws when an address is passed as a job, but that address is not a job
  error JobUnavailable();

  /// @notice Throws when an action that requires an undisputed job is applied on a disputed job
  error JobDisputed();

  /// @notice Throws when the address that is trying to register as a job is already a job
  error AlreadyAJob();

  /// @notice Throws when the token is KP3R, as it should not be used for direct token payments
  error TokenUnallowed();

  /// @notice Throws when the token withdraw cooldown has not yet passed
  error JobTokenCreditsLocked();

  /// @notice Throws when the user tries to withdraw more tokens than it has
  error InsufficientJobTokenCredits();

  /// @notice Throws when trying to add a job that has already been added
  error JobAlreadyAdded();

  /// @notice Throws when the address that is trying to register as a keeper is already a keeper
  error AlreadyAKeeper();

  /// @notice Throws when the liquidity being approved has already been approved
  error LiquidityPairApproved();

  /// @notice Throws when the liquidity being removed has not been approved
  error LiquidityPairUnexistent();

  /// @notice Throws when trying to add liquidity to an unapproved pool
  error LiquidityPairUnapproved();

  /// @notice Throws when the job doesn't have the requested liquidity
  error JobLiquidityUnexistent();

  /// @notice Throws when trying to remove more liquidity than the job has
  error JobLiquidityInsufficient();

  /// @notice Throws when trying to add less liquidity than the minimum liquidity required
  error JobLiquidityLessThanMin();

  /// @notice Throws if a variable is assigned to the zero address
  error ZeroAddress();

  /// @notice Throws if the address claiming to be a job is not in the list of approved jobs
  error JobUnapproved();

  /// @notice Throws if the amount of funds in the job is less than the payment that must be paid to the keeper that works that job
  error InsufficientFunds();

  /// @notice Throws when the caller of the function is not the job owner
  error OnlyJobOwner();

  /// @notice Throws when the caller of the function is not the pending job owner
  error OnlyPendingJobOwner();

  /// @notice Throws when the address of the job that requests to migrate wants to migrate to its same address
  error JobMigrationImpossible();

  /// @notice Throws when the _toJob address differs from the address being tracked in the pendingJobMigrations mapping
  error JobMigrationUnavailable();

  /// @notice Throws when cooldown between migrations has not yet passed
  error JobMigrationLocked();

  /// @notice Throws when the token trying to be slashed doesn't exist
  error JobTokenUnexistent();

  /// @notice Throws when someone tries to slash more tokens than the job has
  error JobTokenInsufficient();

  /// @notice Throws when a job or keeper is already disputed
  error AlreadyDisputed();

  /// @notice Throws when a job or keeper is not disputed and someone tries to resolve the dispute
  error NotDisputed();

  // Variables

  /// @notice Address of Keep3rHelper's contract
  /// @return _keep3rHelper The address of Keep3rHelper's contract
  function keep3rHelper() external view returns (address _keep3rHelper);

  /// @notice Address of Keep3rV1's contract
  /// @return _keep3rV1 The address of Keep3rV1's contract
  function keep3rV1() external view returns (address _keep3rV1);

  /// @notice Address of Keep3rV1Proxy's contract
  /// @return _keep3rV1Proxy The address of Keep3rV1Proxy's contract
  function keep3rV1Proxy() external view returns (address _keep3rV1Proxy);

  /// @notice Address of the KP3R-WETH pool
  /// @return _kp3rWethPool The address of KP3R-WETH pool
  function kp3rWethPool() external view returns (address _kp3rWethPool);

  /// @notice The amount of time required to pass after a keeper has bonded assets for it to be able to activate
  /// @return _days The required bondTime in days
  function bondTime() external view returns (uint256 _days);

  /// @notice The amount of time required to pass before a keeper can unbond what he has bonded
  /// @return _days The required unbondTime in days
  function unbondTime() external view returns (uint256 _days);

  /// @notice The minimum amount of liquidity required to fund a job per liquidity
  /// @return _amount The minimum amount of liquidity in KP3R
  function liquidityMinimum() external view returns (uint256 _amount);

  /// @notice The amount of time between each scheduled credits reward given to a job
  /// @return _days The reward period in days
  function rewardPeriodTime() external view returns (uint256 _days);

  /// @notice The inflation period is the denominator used to regulate the emission of KP3R
  /// @return _period The denominator used to regulate the emission of KP3R
  function inflationPeriod() external view returns (uint256 _period);

  /// @notice The fee to be sent to governance when a user adds liquidity to a job
  /// @return _amount The fee amount to be sent to governance when a user adds liquidity to a job
  function fee() external view returns (uint256 _amount);

  // solhint-disable func-name-mixedcase
  /// @notice The base that will be used to calculate the fee
  /// @return _base The base that will be used to calculate the fee
  function BASE() external view returns (uint256 _base);

  /// @notice The minimum rewardPeriodTime value to be set
  /// @return _minPeriod The minimum reward period in seconds
  function MIN_REWARD_PERIOD_TIME() external view returns (uint256 _minPeriod);

  /// @notice Maps an address to a boolean to determine whether the address is a slasher or not.
  /// @return _isSlasher Whether the address is a slasher or not
  function slashers(address _slasher) external view returns (bool _isSlasher);

  /// @notice Maps an address to a boolean to determine whether the address is a disputer or not.
  /// @return _isDisputer Whether the address is a disputer or not
  function disputers(address _disputer) external view returns (bool _isDisputer);

  /// @notice Tracks the total KP3R earnings of a keeper since it started working
  /// @return _workCompleted Total KP3R earnings of a keeper since it started working
  function workCompleted(address _keeper) external view returns (uint256 _workCompleted);

  /// @notice Tracks when a keeper was first registered
  /// @return timestamp The time at which the keeper was first registered
  function firstSeen(address _keeper) external view returns (uint256 timestamp);

  /// @notice Tracks if a keeper or job has a pending dispute
  /// @return _disputed Whether a keeper or job has a pending dispute
  function disputes(address _keeperOrJob) external view returns (bool _disputed);

  /// @notice Allows governance to create a dispute for a given keeper/job
  /// @param _jobOrKeeper The address in dispute
  function dispute(address _jobOrKeeper) external;

  /// @notice Allows governance to resolve a dispute on a keeper/job
  /// @param _jobOrKeeper The address cleared
  function resolve(address _jobOrKeeper) external;

  /// @notice Tracks how much a keeper has bonded of a certain token
  /// @return _bonds Amount of a certain token that a keeper has bonded
  function bonds(address _keeper, address _bond) external view returns (uint256 _bonds);

  /// @notice The current token credits available for a job
  /// @return _amount The amount of token credits available for a job
  function jobTokenCredits(address _job, address _token) external view returns (uint256 _amount);

  /// @notice Tracks the amount of assets deposited in pending bonds
  /// @return _pendingBonds Amount of a certain asset a keeper has unbonding
  function pendingBonds(address _keeper, address _bonding) external view returns (uint256 _pendingBonds);

  /// @notice Tracks when a bonding for a keeper can be activated
  /// @return _timestamp Time at which the bonding for a keeper can be activated
  function canActivateAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks when keeper bonds are ready to be withdrawn
  /// @return _timestamp Time at which the keeper bonds are ready to be withdrawn
  function canWithdrawAfter(address _keeper, address _bonding) external view returns (uint256 _timestamp);

  /// @notice Tracks how much keeper bonds are to be withdrawn
  /// @return _pendingUnbonds The amount of keeper bonds that are to be withdrawn
  function pendingUnbonds(address _keeper, address _bonding) external view returns (uint256 _pendingUnbonds);

  /// @notice Checks whether the address has ever bonded an asset
  /// @return _hasBonded Whether the address has ever bonded an asset
  function hasBonded(address _keeper) external view returns (bool _hasBonded);

  /// @notice Last block where tokens were added to the job [job => token => timestamp]
  /// @return _timestamp The last block where tokens were added to the job
  function jobTokenCreditsAddedAt(address _job, address _token) external view returns (uint256 _timestamp);

  // Methods

  /// @notice Add credit to a job to be paid out for work
  /// @param _job The address of the job being credited
  /// @param _token The address of the token being credited
  /// @param _amount The amount of credit being added
  function addTokenCreditsToJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Withdraw credit from a job
  /// @param _job The address of the job from which the credits are withdrawn
  /// @param _token The address of the token being withdrawn
  /// @param _amount The amount of token to be withdrawn
  /// @param _receiver The user that will receive tokens
  function withdrawTokenCreditsFromJob(
    address _job,
    address _token,
    uint256 _amount,
    address _receiver
  ) external;

  /// @notice Lists liquidity pairs
  /// @return _list An array of addresses with all the approved liquidity pairs
  function approvedLiquidities() external view returns (address[] memory _list);

  /// @notice Amount of liquidity in a specified job
  /// @param _job The address of the job being checked
  /// @param _liquidity The address of the liquidity we are checking
  /// @return _amount Amount of liquidity in the specified job
  function liquidityAmount(address _job, address _liquidity) external view returns (uint256 _amount);

  /// @notice Last time the job was rewarded liquidity credits
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was rewarded liquidity credits
  function rewardedAt(address _job) external view returns (uint256 _timestamp);

  /// @notice Last time the job was worked
  /// @param _job The address of the job being checked
  /// @return _timestamp Timestamp of the last time the job was worked
  function workedAt(address _job) external view returns (uint256 _timestamp);

  /// @notice Maps the job to the owner of the job (job => user)
  /// @return _owner The addres of the owner of the job
  function jobOwner(address _job) external view returns (address _owner);

  /// @notice Maps the owner of the job to its pending owner (job => user)
  /// @return _pendingOwner The address of the pending owner of the job
  function jobPendingOwner(address _job) external view returns (address _pendingOwner);

  /// @notice Maps the jobs that have requested a migration to the address they have requested to migrate to
  /// @return _toJob The address to which the job has requested to migrate to
  function pendingJobMigrations(address _fromJob) external view returns (address _toJob);

  // Methods

  /// @notice Sets the Keep3rHelper address
  /// @param _keep3rHelper The Keep3rHelper address
  function setKeep3rHelper(address _keep3rHelper) external;

  /// @notice Sets the Keep3rV1 address
  /// @param _keep3rV1 The Keep3rV1 address
  function setKeep3rV1(address _keep3rV1) external;

  /// @notice Sets the Keep3rV1Proxy address
  /// @param _keep3rV1Proxy The Keep3rV1Proxy address
  function setKeep3rV1Proxy(address _keep3rV1Proxy) external;

  /// @notice Sets the KP3R-WETH pool address
  /// @param _kp3rWethPool The KP3R-WETH pool address
  function setKp3rWethPool(address _kp3rWethPool) external;

  /// @notice Sets the bond time required to activate as a keeper
  /// @param _bond The new bond time
  function setBondTime(uint256 _bond) external;

  /// @notice Sets the unbond time required unbond what has been bonded
  /// @param _unbond The new unbond time
  function setUnbondTime(uint256 _unbond) external;

  /// @notice Sets the minimum amount of liquidity required to fund a job
  /// @param _liquidityMinimum The new minimum amount of liquidity
  function setLiquidityMinimum(uint256 _liquidityMinimum) external;

  /// @notice Sets the time required to pass between rewards for jobs
  /// @param _rewardPeriodTime The new amount of time required to pass between rewards
  function setRewardPeriodTime(uint256 _rewardPeriodTime) external;

  /// @notice Sets the new inflation period
  /// @param _inflationPeriod The new inflation period
  function setInflationPeriod(uint256 _inflationPeriod) external;

  /// @notice Sets the new fee
  /// @param _fee The new fee
  function setFee(uint256 _fee) external;

  /// @notice Registers a slasher by updating the slashers mapping
  function addSlasher(address _slasher) external;

  /// @notice Removes a slasher by updating the slashers mapping
  function removeSlasher(address _slasher) external;

  /// @notice Registers a disputer by updating the disputers mapping
  function addDisputer(address _disputer) external;

  /// @notice Removes a disputer by updating the disputers mapping
  function removeDisputer(address _disputer) external;

  /// @notice Lists all jobs
  /// @return _jobList Array with all the jobs in _jobs
  function jobs() external view returns (address[] memory _jobList);

  /// @notice Lists all keepers
  /// @return _keeperList Array with all the jobs in keepers
  function keepers() external view returns (address[] memory _keeperList);

  /// @notice Beginning of the bonding process
  /// @param _bonding The asset being bound
  /// @param _amount The amount of bonding asset being bound
  function bond(address _bonding, uint256 _amount) external;

  /// @notice Beginning of the unbonding process
  /// @param _bonding The asset being unbound
  /// @param _amount Allows for partial unbonding
  function unbond(address _bonding, uint256 _amount) external;

  /// @notice End of the bonding process after bonding time has passed
  /// @param _bonding The asset being activated as bond collateral
  function activate(address _bonding) external;

  /// @notice Withdraw funds after unbonding has finished
  /// @param _bonding The asset to withdraw from the bonding pool
  function withdraw(address _bonding) external;

  /// @notice Allows governance to slash a keeper based on a dispute
  /// @param _keeper The address being slashed
  /// @param _bonded The asset being slashed
  /// @param _amount The amount being slashed
  function slash(
    address _keeper,
    address _bonded,
    uint256 _amount
  ) external;

  /// @notice Blacklists a keeper from participating in the network
  /// @param _keeper The address being slashed
  function revoke(address _keeper) external;

  /// @notice Allows any caller to add a new job
  /// @param _job Address of the contract for which work should be performed
  function addJob(address _job) external;

  /// @notice Returns the liquidity credits of a given job
  /// @param _job The address of the job of which we want to know the liquidity credits
  /// @return _amount The liquidity credits of a given job
  function jobLiquidityCredits(address _job) external view returns (uint256 _amount);

  /// @notice Returns the credits of a given job for the current period
  /// @param _job The address of the job of which we want to know the period credits
  /// @return _amount The credits the given job has at the current period
  function jobPeriodCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates the total credits of a given job
  /// @param _job The address of the job of which we want to know the total credits
  /// @return _amount The total credits of the given job
  function totalJobCredits(address _job) external view returns (uint256 _amount);

  /// @notice Calculates how many credits should be rewarded periodically for a given liquidity amount
  /// @dev _periodCredits = underlying KP3Rs for given liquidity amount * rewardPeriod / inflationPeriod
  /// @param _liquidity The liquidity to provide
  /// @param _amount The amount of liquidity to provide
  /// @return _periodCredits The amount of KP3R periodically minted for the given liquidity
  function quoteLiquidity(address _liquidity, uint256 _amount) external view returns (uint256 _periodCredits);

  /// @notice Observes the current state of the liquidity pair being observed and updates TickCache with the information
  /// @param _liquidity The liquidity pair being observed
  /// @return _tickCache The updated TickCache
  function observeLiquidity(address _liquidity) external view returns (TickCache memory _tickCache);

  /// @notice Gifts liquidity credits to the specified job
  /// @param _job The address of the job being credited
  /// @param _amount The amount of liquidity credits to gift
  function forceLiquidityCreditsToJob(address _job, uint256 _amount) external;

  /// @notice Approve a liquidity pair for being accepted in future
  /// @param _liquidity The address of the liquidity accepted
  function approveLiquidity(address _liquidity) external;

  /// @notice Revoke a liquidity pair from being accepted in future
  /// @param _liquidity The liquidity no longer accepted
  function revokeLiquidity(address _liquidity) external;

  /// @notice Allows anyone to fund a job with liquidity
  /// @param _job The address of the job to assign liquidity to
  /// @param _liquidity The liquidity being added
  /// @param _amount The amount of liquidity tokens to add
  function addLiquidityToJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Unbond liquidity for a job
  /// @dev Can only be called by the job's owner
  /// @param _job The address of the job being unbound from
  /// @param _liquidity The liquidity being unbound
  /// @param _amount The amount of liquidity being removed
  function unbondLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;

  /// @notice Withdraw liquidity from a job
  /// @param _job The address of the job being withdrawn from
  /// @param _liquidity The liquidity being withdrawn
  /// @param _receiver The address that will receive the withdrawn liquidity
  function withdrawLiquidityFromJob(
    address _job,
    address _liquidity,
    address _receiver
  ) external;

  /// @notice Confirms if the current keeper is registered, can be used for general (non critical) functions
  /// @param _keeper The keeper being investigated
  /// @return _isKeeper Whether the address passed as a parameter is a keeper or not
  function isKeeper(address _keeper) external returns (bool _isKeeper);

  /// @notice Confirms if the current keeper is registered and has a minimum bond of any asset. Should be used for protected functions
  /// @param _keeper The keeper to check
  /// @param _bond The bond token being evaluated
  /// @param _minBond The minimum amount of bonded tokens
  /// @param _earned The minimum funds earned in the keepers lifetime
  /// @param _age The minimum keeper age required
  /// @return _isBondedKeeper Whether the `_keeper` meets the given requirements
  function isBondedKeeper(
    address _keeper,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external returns (bool _isBondedKeeper);

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Automatically calculates the payment for the keeper
  /// @param _keeper Address of the keeper that performed the work
  function worked(address _keeper) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with KP3R
  /// @param _keeper Address of the keeper that performed the work
  /// @param _payment The reward that should be allocated for the job
  function bondedPayment(address _keeper, uint256 _payment) external;

  /// @notice Implemented by jobs to show that a keeper performed work
  /// @dev Pays the keeper that performs the work with a specific token
  /// @param _token The asset being awarded to the keeper
  /// @param _keeper Address of the keeper that performed the work
  /// @param _amount The reward that should be allocated
  function directTokenPayment(
    address _token,
    address _keeper,
    uint256 _amount
  ) external;

  /// @notice Proposes a new address to be the owner of the job
  function changeJobOwnership(address _job, address _newOwner) external;

  /// @notice The proposed address accepts to be the owner of the job
  function acceptJobOwnership(address _job) external;

  /// @notice Initializes the migration process for a job by adding the request to the pendingJobMigrations mapping
  /// @param _fromJob The address of the job that is requesting to migrate
  /// @param _toJob The address at which the job is requesting to migrate
  function migrateJob(address _fromJob, address _toJob) external;

  /// @notice Completes the migration process for a job
  /// @dev Unbond/withdraw process doesn't get migrated
  /// @param _fromJob The address of the job that requested to migrate
  /// @param _toJob The address to which the job wants to migrate to
  function acceptJobMigration(address _fromJob, address _toJob) external;

  /// @notice Allows governance or slasher to slash a job specific token
  /// @param _job The address of the job from which the token will be slashed
  /// @param _token The address of the token that will be slashed
  /// @param _amount The amount of the token that will be slashed
  function slashTokenFromJob(
    address _job,
    address _token,
    uint256 _amount
  ) external;

  /// @notice Allows governance or a slasher to slash liquidity from a job
  /// @param _job The address being slashed
  /// @param _liquidity The address of the liquidity that will be slashed
  /// @param _amount The amount of liquidity that will be slashed
  function slashLiquidityFromJob(
    address _job,
    address _liquidity,
    uint256 _amount
  ) external;
}