// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAPermissionManager.sol';

/// @notice This contract will be used to migrate position from one DCAHub to the other
contract PositionMigrator {
  /// @notice Emitted when a position is migrated
  /// @param sourceHub The hub that contains the position to migrate
  /// @param sourcePositionId The id of the position that will be migrated
  /// @param targetHub The hub where the position will me migrated into
  /// @param targetPositionId The id of the new position
  event Migrated(IDCAHub sourceHub, uint256 sourcePositionId, IDCAHub targetHub, uint256 targetPositionId);

  struct Signature {
    IDCAPermissionManager.PermissionSet[] permissions;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /// @notice Migrates a position from one hub, into another one. Will terminate the position on the source hub,
  /// send the swapped tokens to the owner, and then create a new position in the new hub with the unswapped balance
  /// @dev If the source hub is the beta version, due to a bug, only `TERMINATE` should be given as permissions
  /// @param _sourceHub The hub that contains the position to migrate
  /// @param _positionId The id of the position to migrate
  /// @param _signature The signature to give permissions to this contract
  /// @param _targetHub The hub where the position will me migrated into
  function migrate(
    IDCAHub _sourceHub,
    uint256 _positionId,
    Signature calldata _signature,
    IDCAHub _targetHub
  ) external {
    IDCAPermissionManager _permissionManager = _sourceHub.permissionManager();
    address _owner = _permissionManager.ownerOf(_positionId);

    // Fetch position
    IDCAHub.UserPosition memory _position = _sourceHub.userPosition(_positionId);

    // Give myself permissions
    _permissionManager.permissionPermit(_signature.permissions, _positionId, _signature.deadline, _signature.v, _signature.r, _signature.s);

    // Terminate the position. Send swapped to owner and unswapped to myself
    (uint256 _unswapped, ) = _sourceHub.terminate(_positionId, address(this), _owner);

    // Approve Hub for deposit
    _position.from.approve(address(_targetHub), _unswapped);

    // Create position for owner
    uint256 _newPositionId = _targetHub.deposit(
      address(_position.from),
      address(_position.to),
      _unswapped,
      _position.swapsLeft,
      _position.swapInterval,
      _owner,
      new IDCAPermissionManager.PermissionSet[](0)
    );

    // Emit event
    emit Migrated(_sourceHub, _positionId, _targetHub, _newPositionId);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IDCAPermissionManager.sol';
import './oracles/IPriceOracle.sol';

/// @title The interface for all state related queries
/// @notice These methods allow users to read the hubs's current values
interface IDCAHubParameters {
  /// @notice Swap information about a specific pair
  struct SwapData {
    // How many swaps have been executed
    uint32 performedSwaps;
    // How much of token A will be swapped on the next swap
    uint224 nextAmountToSwapAToB;
    // Timestamp of the last swap
    uint32 lastSwappedAt;
    // How much of token B will be swapped on the next swap
    uint224 nextAmountToSwapBToA;
  }

  /// @notice The difference of tokens to swap between a swap, and the previous one
  struct SwapDelta {
    // How much less of token A will the following swap require
    uint128 swapDeltaAToB;
    // How much less of token B will the following swap require
    uint128 swapDeltaBToA;
  }

  /// @notice The sum of the ratios the oracle reported in all executed swaps
  struct AccumRatio {
    // The sum of all ratios from A to B
    uint256 accumRatioAToB;
    // The sum of all ratios from B to A
    uint256 accumRatioBToA;
  }

  /// @notice Returns how much will the amount to swap differ from the previous swap. f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @param _swapIntervalMask The byte representation of the swap interval to check
  /// @param _swapNumber The swap number to check
  /// @return How much will the amount to swap differ, when compared to the swap just before this one
  function swapAmountDelta(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask,
    uint32 _swapNumber
  ) external view returns (SwapDelta memory);

  /// @notice Returns the sum of the ratios reported in all swaps executed until the given swap number
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @param _swapIntervalMask The byte representation of the swap interval to check
  /// @param _swapNumber The swap number to check
  /// @return The sum of the ratios
  function accumRatio(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask,
    uint32 _swapNumber
  ) external view returns (AccumRatio memory);

  /// @notice Returns swapping information about a specific pair
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @param _swapIntervalMask The byte representation of the swap interval to check
  /// @return The swapping information
  function swapData(
    address _tokenA,
    address _tokenB,
    bytes1 _swapIntervalMask
  ) external view returns (SwapData memory);

  /// @notice Returns the byte representation of the set of actice swap intervals for the given pair
  /// @dev `_tokenA` must be smaller than `_tokenB` (_tokenA < _tokenB)
  /// @param _tokenA The smaller of the pair's token
  /// @param _tokenB The other of the pair's token
  /// @return The byte representation of the set of actice swap intervals
  function activeSwapIntervals(address _tokenA, address _tokenB) external view returns (bytes1);

  /// @notice Returns how much of the hub's token balance belongs to the platform
  /// @param _token The token to check
  /// @return The amount that belongs to the platform
  function platformBalance(address _token) external view returns (uint256);
}

/// @title The interface for all position related matters
/// @notice These methods allow users to create, modify and terminate their positions
interface IDCAHubPositionHandler {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint120 rate;
  }

  /// @notice A list of positions that all have the same `to` token
  struct PositionSet {
    // The `to` token
    address token;
    // The position ids
    uint256[] positionIds;
  }

  /// @notice Emitted when a position is terminated
  /// @param user The address of the user that terminated the position
  /// @param recipientUnswapped The address of the user that will receive the unswapped tokens
  /// @param recipientSwapped The address of the user that will receive the swapped tokens
  /// @param positionId The id of the position that was terminated
  /// @param returnedUnswapped How many "from" tokens were returned to the caller
  /// @param returnedSwapped How many "to" tokens were returned to the caller
  event Terminated(
    address indexed user,
    address indexed recipientUnswapped,
    address indexed recipientSwapped,
    uint256 positionId,
    uint256 returnedUnswapped,
    uint256 returnedSwapped
  );

  /// @notice Emitted when a position is created
  /// @param depositor The address of the user that creates the position
  /// @param owner The address of the user that will own the position
  /// @param positionId The id of the position that was created
  /// @param fromToken The address of the "from" token
  /// @param toToken The address of the "to" token
  /// @param swapInterval How frequently the position's swaps should be executed
  /// @param rate How many "from" tokens need to be traded in each swap
  /// @param startingSwap The number of the swap when the position will be executed for the first time
  /// @param lastSwap The number of the swap when the position will be executed for the last time
  /// @param permissions The permissions defined for the position
  event Deposited(
    address indexed depositor,
    address indexed owner,
    uint256 positionId,
    address fromToken,
    address toToken,
    uint32 swapInterval,
    uint120 rate,
    uint32 startingSwap,
    uint32 lastSwap,
    IDCAPermissionManager.PermissionSet[] permissions
  );

  /// @notice Emitted when a position is created and extra data is provided
  /// @param positionId The id of the position that was created
  /// @param data The extra data that was provided
  event Miscellaneous(uint256 positionId, bytes data);

  /// @notice Emitted when a user withdraws all swapped tokens from a position
  /// @param withdrawer The address of the user that executed the withdraw
  /// @param recipient The address of the user that will receive the withdrawn tokens
  /// @param positionId The id of the position that was affected
  /// @param token The address of the withdrawn tokens. It's the same as the position's "to" token
  /// @param amount The amount that was withdrawn
  event Withdrew(address indexed withdrawer, address indexed recipient, uint256 positionId, address token, uint256 amount);

  /// @notice Emitted when a user withdraws all swapped tokens from many positions
  /// @param withdrawer The address of the user that executed the withdraws
  /// @param recipient The address of the user that will receive the withdrawn tokens
  /// @param positions The positions to withdraw from
  /// @param withdrew The total amount that was withdrawn from each token
  event WithdrewMany(address indexed withdrawer, address indexed recipient, PositionSet[] positions, uint256[] withdrew);

  /// @notice Emitted when a position is modified
  /// @param user The address of the user that modified the position
  /// @param positionId The id of the position that was modified
  /// @param rate How many "from" tokens need to be traded in each swap
  /// @param startingSwap The number of the swap when the position will be executed for the first time
  /// @param lastSwap The number of the swap when the position will be executed for the last time
  event Modified(address indexed user, uint256 positionId, uint120 rate, uint32 startingSwap, uint32 lastSwap);

  /// @notice Thrown when a user tries to create a position with the same `from` & `to`
  error InvalidToken();

  /// @notice Thrown when a user tries to create a position with a swap interval that is not allowed
  error IntervalNotAllowed();

  /// @notice Thrown when a user tries operate on a position that doesn't exist (it might have been already terminated)
  error InvalidPosition();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /// @notice Thrown when a user tries to create a position with zero swaps
  error ZeroSwaps();

  /// @notice Thrown when a user tries to create a position with zero funds
  error ZeroAmount();

  /// @notice Thrown when a user tries to withdraw a position whose `to` token doesn't match the specified one
  error PositionDoesNotMatchToken();

  /// @notice Thrown when a user tries create or modify a position with an amount too big
  error AmountTooBig();

  /// @notice Returns the permission manager contract
  /// @return The contract itself
  function permissionManager() external view returns (IDCAPermissionManager);

  /// @notice Returns total created positions
  /// @return The total created positions
  function totalCreatedPositions() external view returns (uint256);

  /// @notice Returns a user position
  /// @param _positionId The id of the position
  /// @return _position The position itself
  function userPosition(uint256 _positionId) external view returns (UserPosition memory _position);

  /// @notice Creates a new position
  /// @dev Will revert:
  /// With ZeroAddress if _from, _to or _owner are zero
  /// With InvalidToken if _from == _to
  /// With ZeroAmount if _amount is zero
  /// With AmountTooBig if _amount is too big
  /// With ZeroSwaps if _amountOfSwaps is zero
  /// With IntervalNotAllowed if _swapInterval is not allowed
  /// @param _from The address of the "from" token
  /// @param _to The address of the "to" token
  /// @param _amount How many "from" tokens will be swapped in total
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _owner The address of the owner of the position being created
  /// @param _permissions Extra permissions to add to the position. Can be empty
  /// @return _positionId The id of the created position
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions
  ) external returns (uint256 _positionId);

  /// @notice Creates a new position
  /// @dev Will revert:
  /// With ZeroAddress if _from, _to or _owner are zero
  /// With InvalidToken if _from == _to
  /// With ZeroAmount if _amount is zero
  /// With AmountTooBig if _amount is too big
  /// With ZeroSwaps if _amountOfSwaps is zero
  /// With IntervalNotAllowed if _swapInterval is not allowed
  /// @param _from The address of the "from" token
  /// @param _to The address of the "to" token
  /// @param _amount How many "from" tokens will be swapped in total
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _owner The address of the owner of the position being created
  /// @param _permissions Extra permissions to add to the position. Can be empty
  /// @param _miscellaneous Bytes that will be emitted, and associated with the position
  /// @return _positionId The id of the created position
  function deposit(
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps,
    uint32 _swapInterval,
    address _owner,
    IDCAPermissionManager.PermissionSet[] calldata _permissions,
    bytes calldata _miscellaneous
  ) external returns (uint256 _positionId);

  /// @notice Withdraws all swapped tokens from a position to a recipient
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroAddress if recipient is zero
  /// @param _positionId The position's id
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _swapped How much was withdrawn
  function withdrawSwapped(uint256 _positionId, address _recipient) external returns (uint256 _swapped);

  /// @notice Withdraws all swapped tokens from multiple positions
  /// @dev Will revert:
  /// With InvalidPosition if any of the position ids are invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position to any of the given positions
  /// With ZeroAddress if recipient is zero
  /// With PositionDoesNotMatchToken if any of the positions do not match the token in their position set
  /// @param _positions A list positions, grouped by `to` token
  /// @param _recipient The address to withdraw swapped tokens to
  /// @return _withdrawn How much was withdrawn for each token
  function withdrawSwappedMany(PositionSet[] calldata _positions, address _recipient) external returns (uint256[] memory _withdrawn);

  /// @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With AmountTooBig if _amount is too big
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to add to the position
  /// @param _newSwaps The new amount of swaps
  function increasePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps
  ) external;

  /// @notice Withdraws the specified amount from the unswapped balance and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroSwaps if _newSwaps is zero and _amount is not the total unswapped balance
  /// @param _positionId The position's id
  /// @param _amount Amount of funds to withdraw from the position
  /// @param _newSwaps The new amount of swaps
  /// @param _recipient The address to send tokens to
  function reducePosition(
    uint256 _positionId,
    uint256 _amount,
    uint32 _newSwaps,
    address _recipient
  ) external;

  /// @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
  /// @dev Will revert:
  /// With InvalidPosition if _positionId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroAddress if _recipientUnswapped or _recipientSwapped is zero
  /// @param _positionId The position's id
  /// @param _recipientUnswapped The address to withdraw unswapped tokens to
  /// @param _recipientSwapped The address to withdraw swapped tokens to
  /// @return _unswapped The unswapped balance sent to `_recipientUnswapped`
  /// @return _swapped The swapped balance sent to `_recipientSwapped`
  function terminate(
    uint256 _positionId,
    address _recipientUnswapped,
    address _recipientSwapped
  ) external returns (uint256 _unswapped, uint256 _swapped);
}

/// @title The interface for all swap related matters
/// @notice These methods allow users to get information about the next swap, and how to execute it
interface IDCAHubSwapHandler {
  /// @notice Information about a swap
  struct SwapInfo {
    // The tokens involved in the swap
    TokenInSwap[] tokens;
    // The pairs involved in the swap
    PairInSwap[] pairs;
  }

  /// @notice Information about a token's role in a swap
  struct TokenInSwap {
    // The token's address
    address token;
    // How much will be given of this token as a reward
    uint256 reward;
    // How much of this token needs to be provided by swapper
    uint256 toProvide;
    // How much of this token will be paid to the platform
    uint256 platformFee;
  }

  /// @notice Information about a pair in a swap
  struct PairInSwap {
    // The address of one of the tokens
    address tokenA;
    // The address of the other token
    address tokenB;
    // How much is 1 unit of token A when converted to B
    uint256 ratioAToB;
    // How much is 1 unit of token B when converted to A
    uint256 ratioBToA;
    // The swap intervals involved in the swap, represented as a byte
    bytes1 intervalsInSwap;
  }

  /// @notice A pair of tokens, represented by their indexes in an array
  struct PairIndexes {
    // The index of the token A
    uint8 indexTokenA;
    // The index of the token B
    uint8 indexTokenB;
  }

  /// @notice Emitted when a swap is executed
  /// @param sender The address of the user that initiated the swap
  /// @param rewardRecipient The address that received the reward
  /// @param callbackHandler The address that executed the callback
  /// @param swapInformation All information related to the swap
  /// @param borrowed How much was borrowed
  /// @param fee The swap fee at the moment of the swap
  event Swapped(
    address indexed sender,
    address indexed rewardRecipient,
    address indexed callbackHandler,
    SwapInfo swapInformation,
    uint256[] borrowed,
    uint32 fee
  );

  /// @notice Thrown when pairs indexes are not sorted correctly
  error InvalidPairs();

  /// @notice Thrown when trying to execute a swap, but there is nothing to swap
  error NoSwapsToExecute();

  /// @notice Returns all information related to the next swap
  /// @dev Will revert with:
  /// With InvalidTokens if _tokens are not sorted, or if there are duplicates
  /// With InvalidPairs if _pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
  /// @param _tokens The tokens involved in the next swap
  /// @param _pairs The pairs that you want to swap. Each element of the list points to the index of the token in the _tokens array
  /// @return _swapInformation The information about the next swap
  function getNextSwapInfo(address[] calldata _tokens, PairIndexes[] calldata _pairs) external view returns (SwapInfo memory _swapInformation);

  /// @notice Executes a flash swap
  /// @dev Will revert with:
  /// With InvalidTokens if _tokens are not sorted, or if there are duplicates
  /// With InvalidPairs if _pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
  /// Paused if swaps are paused by protocol
  /// NoSwapsToExecute if there are no swaps to execute for the given pairs
  /// LiquidityNotReturned if the required tokens were not back during the callback
  /// @param _tokens The tokens involved in the next swap
  /// @param _pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the _tokens array
  /// @param _rewardRecipient The address to send the reward to
  /// @param _callbackHandler Address to call for callback (and send the borrowed tokens to)
  /// @param _borrow How much to borrow of each of the tokens in _tokens. The amount must match the position of the token in the _tokens array
  /// @param _data Bytes to send to the caller during the callback
  /// @return Information about the executed swap
  function swap(
    address[] calldata _tokens,
    PairIndexes[] calldata _pairsToSwap,
    address _rewardRecipient,
    address _callbackHandler,
    uint256[] calldata _borrow,
    bytes calldata _data
  ) external returns (SwapInfo memory);
}

/// @title The interface for handling all configuration
/// @notice This contract will manage configuration that affects all pairs, swappers, etc
interface IDCAHubConfigHandler {
  /// @notice Emitted when a new oracle is set
  /// @param _oracle The new oracle contract
  event OracleSet(IPriceOracle _oracle);

  /// @notice Emitted when a new swap fee is set
  /// @param _feeSet The new swap fee
  event SwapFeeSet(uint32 _feeSet);

  /// @notice Emitted when new swap intervals are allowed
  /// @param _swapIntervals The new swap intervals
  event SwapIntervalsAllowed(uint32[] _swapIntervals);

  /// @notice Emitted when some swap intervals are no longer allowed
  /// @param _swapIntervals The swap intervals that are no longer allowed
  event SwapIntervalsForbidden(uint32[] _swapIntervals);

  /// @notice Emitted when a new platform fee ratio is set
  /// @param _platformFeeRatio The new platform fee ratio
  event PlatformFeeRatioSet(uint16 _platformFeeRatio);

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to set a fee that is not multiple of 100
  error InvalidFee();

  /// @notice Thrown when trying to set a fee ratio that is higher that the maximum allowed
  error HighPlatformFeeRatio();

  /// @notice Returns the max fee ratio that can be set
  /// @dev Cannot be modified
  /// @return The maximum possible value
  // solhint-disable-next-line func-name-mixedcase
  function MAX_PLATFORM_FEE_RATIO() external view returns (uint16);

  /// @notice Returns the fee charged on swaps
  /// @return _swapFee The fee itself
  function swapFee() external view returns (uint32 _swapFee);

  /// @notice Returns the price oracle contract
  /// @return _oracle The contract itself
  function oracle() external view returns (IPriceOracle _oracle);

  /// @notice Returns how much will the platform take from the fees collected in swaps
  /// @return The current ratio
  function platformFeeRatio() external view returns (uint16);

  /// @notice Returns the max fee that can be set for swaps
  /// @dev Cannot be modified
  /// @return _maxFee The maximum possible fee
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 _maxFee);

  /// @notice Returns a byte that represents allowed swap intervals
  /// @return _allowedSwapIntervals The allowed swap intervals
  function allowedSwapIntervals() external view returns (bytes1 _allowedSwapIntervals);

  /// @notice Returns whether swaps and deposits are currently paused
  /// @return _isPaused Whether swaps and deposits are currently paused
  function paused() external view returns (bool _isPaused);

  /// @notice Sets a new swap fee
  /// @dev Will revert with HighFee if the fee is higher than the maximum
  /// @dev Will revert with InvalidFee if the fee is not multiple of 100
  /// @param _fee The new swap fee
  function setSwapFee(uint32 _fee) external;

  /// @notice Sets a new price oracle
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _oracle The new oracle contract
  function setOracle(IPriceOracle _oracle) external;

  /// @notice Sets a new platform fee ratio
  /// @dev Will revert with HighPlatformFeeRatio if given ratio is too high
  /// @param _platformFeeRatio The new ratio
  function setPlatformFeeRatio(uint16 _platformFeeRatio) external;

  /// @notice Adds new swap intervals to the allowed list
  /// @param _swapIntervals The new swap intervals
  function addSwapIntervalsToAllowedList(uint32[] calldata _swapIntervals) external;

  /// @notice Removes some swap intervals from the allowed list
  /// @param _swapIntervals The swap intervals to remove
  function removeSwapIntervalsFromAllowedList(uint32[] calldata _swapIntervals) external;

  /// @notice Pauses all swaps and deposits
  function pause() external;

  /// @notice Unpauses all swaps and deposits
  function unpause() external;
}

/// @title The interface for handling platform related actions
/// @notice This contract will handle all actions that affect the platform in some way
interface IDCAHubPlatformHandler {
  /// @notice Emitted when someone withdraws from the paltform balance
  /// @param sender The address of the user that initiated the withdraw
  /// @param recipient The address that received the withdraw
  /// @param amounts The tokens (and the amount) that were withdrawn
  event WithdrewFromPlatform(address indexed sender, address indexed recipient, IDCAHub.AmountOfToken[] amounts);

  /// @notice Withdraws tokens from the platform balance
  /// @param _amounts The amounts to withdraw
  /// @param _recipient The address that will receive the tokens
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata _amounts, address _recipient) external;
}

interface IDCAHub is IDCAHubParameters, IDCAHubConfigHandler, IDCAHubSwapHandler, IDCAHubPositionHandler, IDCAHubPlatformHandler {
  /// @notice Specifies an amount of a token. For example to determine how much to borrow from certain tokens
  struct AmountOfToken {
    // The tokens' address
    address token;
    // How much to borrow or withdraw of the specified token
    uint256 amount;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the expected liquidity is not returned in flash swaps
  error LiquidityNotReturned();

  /// @notice Thrown when a list of token pairs is not sorted, or if there are duplicates
  error InvalidTokens();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './IDCATokenDescriptor.sol';

interface IERC721BasicEnumerable {
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  /// them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256);
}

/// @title The interface for all permission related matters
/// @notice These methods allow users to set and remove permissions to their positions
interface IDCAPermissionManager is IERC721, IERC721BasicEnumerable {
  /// @notice Set of possible permissions
  enum Permission {
    INCREASE,
    REDUCE,
    WITHDRAW,
    TERMINATE
  }

  /// @notice A set of permissions for a specific operator
  struct PermissionSet {
    // The address of the operator
    address operator;
    // The permissions given to the overator
    Permission[] permissions;
  }

  /// @notice Emitted when permissions for a token are modified
  /// @param tokenId The id of the token
  /// @param permissions The set of permissions that were updated
  event Modified(uint256 tokenId, PermissionSet[] permissions);

  /// @notice Emitted when the address for a new descritor is set
  /// @param descriptor The new descriptor contract
  event NFTDescriptorSet(IDCATokenDescriptor descriptor);

  /// @notice Thrown when a user tries to set the hub, once it was already set
  error HubAlreadySet();

  /// @notice Thrown when a user provides a zero address when they shouldn't
  error ZeroAddress();

  /// @notice Thrown when a user calls a method that can only be executed by the hub
  error OnlyHubCanExecute();

  /// @notice Thrown when a user tries to modify permissions for a token they do not own
  error NotOwner();

  /// @notice Thrown when a user tries to execute a permit with an expired deadline
  error ExpiredDeadline();

  /// @notice Thrown when a user tries to execute a permit with an invalid signature
  error InvalidSignature();

  /// @notice The permit typehash used in the permit signature
  /// @return The typehash for the permit
  // solhint-disable-next-line func-name-mixedcase
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  /// @notice The permit typehash used in the permission permit signature
  /// @return The typehash for the permission permit
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /// @notice The permit typehash used in the permission permit signature
  /// @return The typehash for the permission set
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_SET_TYPEHASH() external pure returns (bytes32);

  /// @notice The domain separator used in the permit signature
  /// @return The domain seperator used in encoding of permit signature
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /// @notice Returns the NFT descriptor contract
  /// @return The contract for the NFT descriptor
  function nftDescriptor() external returns (IDCATokenDescriptor);

  /// @notice Returns the address of the DCA Hub
  /// @return The address of the DCA Hub
  function hub() external returns (address);

  /// @notice Returns the next nonce to use for a given user
  /// @param _user The address of the user
  /// @return _nonce The next nonce to use
  function nonces(address _user) external returns (uint256 _nonce);

  /// @notice Returns whether the given address has the permission for the given token
  /// @param _id The id of the token to check
  /// @param _address The address of the user to check
  /// @param _permission The permission to check
  /// @return Whether the user has the permission or not
  function hasPermission(
    uint256 _id,
    address _address,
    Permission _permission
  ) external view returns (bool);

  /// @notice Returns whether the given address has the permissions for the given token
  /// @param _id The id of the token to check
  /// @param _address The address of the user to check
  /// @param _permissions The permissions to check
  /// @return _hasPermissions Whether the user has each permission or not
  function hasPermissions(
    uint256 _id,
    address _address,
    Permission[] calldata _permissions
  ) external view returns (bool[] memory _hasPermissions);

  /// @notice Sets the address for the hub
  /// @dev Can only be successfully executed once. Once it's set, it can be modified again
  /// Will revert:
  /// With ZeroAddress if address is zero
  /// With HubAlreadySet if the hub has already been set
  /// @param _hub The address to set for the hub
  function setHub(address _hub) external;

  /// @notice Mints a new NFT with the given id, and sets the permissions for it
  /// @dev Will revert with OnlyHubCanExecute if the caller is not the hub
  /// @param _id The id of the new NFT
  /// @param _owner The owner of the new NFT
  /// @param _permissions Permissions to set for the new NFT
  function mint(
    uint256 _id,
    address _owner,
    PermissionSet[] calldata _permissions
  ) external;

  /// @notice Burns the NFT with the given id, and clears all permissions
  /// @dev Will revert with OnlyHubCanExecute if the caller is not the hub
  /// @param _id The token's id
  function burn(uint256 _id) external;

  /// @notice Sets new permissions for the given tokens
  /// @dev Will revert with NotOwner if the caller is not the token's owner.
  /// Operators that are not part of the given permission sets do not see their permissions modified.
  /// In order to remove permissions to an operator, provide an empty list of permissions for them
  /// @param _id The token's id
  /// @param _permissions A list of permission sets
  function modify(uint256 _id, PermissionSet[] calldata _permissions) external;

  /// @notice Approves spending of a specific token ID by spender via signature
  /// @param _spender The account that is being approved
  /// @param _tokenId The ID of the token that is being approved for spending
  /// @param _deadline The deadline timestamp by which the call must be mined for the approve to work
  /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permit(
    address _spender,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  /// @notice Sets permissions via signature
  /// @dev This method works similarly to `modify`, but instead of being executed by the owner, it can be set my signature
  /// @param _permissions The permissions to set
  /// @param _tokenId The token's id
  /// @param _deadline The deadline timestamp by which the call must be mined for the approve to work
  /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
  /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
  /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
  function permissionPermit(
    PermissionSet[] calldata _permissions,
    uint256 _tokenId,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  /// @notice Sets a new NFT descriptor
  /// @dev Will revert with ZeroAddress if address is zero
  /// @param _descriptor The new NFT descriptor contract
  function setNFTDescriptor(IDCATokenDescriptor _descriptor) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for an oracle that provides price quotes
/// @notice These methods allow users to add support for pairs, and then ask for quotes
interface IPriceOracle {
  /// @notice Returns whether this oracle can support this pair of tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  /// @return Whether the given pair of tokens can be supported by the oracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool);

  /// @notice Returns a quote, based on the given tokens and amount
  /// @param _tokenIn The token that will be provided
  /// @param _amountIn The amount that will be provided
  /// @param _tokenOut The token we would like to quote
  /// @return _amountOut How much _tokenOut will be returned in exchange for _amountIn amount of _tokenIn
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut);

  /// @notice Reconfigures support for a given pair. This function will let the oracle take some actions to configure the pair, in
  /// preparation for future quotes. Can be called many times in order to let the oracle re-configure for a new context.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function reconfigureSupportForPair(address _tokenA, address _tokenB) external;

  /// @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
  /// then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation for future quotes.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function addSupportForPairIfNeeded(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/// @title The interface for generating a token's description
/// @notice Contracts that implement this interface must return a base64 JSON with the entire description
interface IDCATokenDescriptor {
  /// @notice Thrown when a user tries get the description of an unsupported interval
  error InvalidInterval();

  /// @notice Generates a token's description, both the JSON and the image inside
  /// @param _hub The address of the DCA Hub
  /// @param _tokenId The token/position id
  /// @return _description The position's description
  function tokenURI(address _hub, uint256 _tokenId) external view returns (string memory _description);

  /// @notice Returns a text description for the given swap interval. For example for 3600, returns 'Hourly'
  /// @dev Will revert with InvalidInterval if the function receives a unsupported interval
  /// @param _swapInterval The swap interval
  /// @return _description The description
  function intervalToDescription(uint32 _swapInterval) external pure returns (string memory _description);
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