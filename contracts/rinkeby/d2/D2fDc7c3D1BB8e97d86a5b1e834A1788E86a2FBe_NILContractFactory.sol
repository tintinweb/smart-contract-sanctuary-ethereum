// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./interfaces/INILContractFactory.sol";
import "./libraries/NILErrorCodes.sol";
import "./NILContract.sol";

contract NILContractFactory is INILContractFactory {
  /// @inheritdoc INILContractFactory
  address public override owner;

  constructor() {
    owner = msg.sender;
  }

  /// @inheritdoc INILContractFactory
  function createNILContract(
    address pool,
    address chainlinkFeed,
    address baseToken,
    uint256 fundingRate,
    uint256 fundingPeriodDuration
  ) external override onlyOwner returns (address) {
    // Create the contract
    NILContract c = new NILContract(
      NILContract.NILContractParams({
        pool: pool,
        chainlinkFeed: chainlinkFeed,
        baseToken: baseToken,
        fundingRate: fundingRate,
        fundingPeriodDuration: fundingPeriodDuration
      })
    );

    emit NILContractCreated(address(c));
    return address(c);
  }

  /// @inheritdoc INILContractFactory
  function setOwner(address _owner) external override onlyOwner {
    address oldOwner = owner;
    owner = _owner;
    emit OwnerChanged(oldOwner, owner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, NILErrorCodes.ONLY_OWNER);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title The interface for the NIL Contract Factory
/// @notice The NIL Contract Factory facilitates the creation of NIL contracts
interface INILContractFactory {
  /// @notice Returns the current owner of the factory
  /// @dev Can be changed by the current owner via setOwner
  function owner() external view returns (address);

  /// @notice Creates a NIL contract
  /// @param pool The address of the Uniswap V2 liquidity pool for this contract
  /// @param chainlinkFeed The address of the Chainlink data feed for the token pair
  /// @param baseToken The address of Token B (the base token) for the Uniswap V2 liquidity pool
  /// @param fundingRate The funding rate as a percentage of the value of the LP position. Denominated in 1e18
  /// @param fundingPeriodDuration The duration of the funding period for this contract
  /// @return nilContract The address of the created NIL contract
  function createNILContract(
    address pool,
    address chainlinkFeed,
    address baseToken,
    uint256 fundingRate,
    uint256 fundingPeriodDuration
  ) external returns (address nilContract);

  /// @notice Updates the owner of the factory
  /// @dev Must be called by the current owner
  /// @param _owner The new owner of the factory
  function setOwner(address _owner) external;

  /// @notice Emitted when the owner of the factory is changed
  /// @param oldOwner The owner before the owner was changed
  /// @param newOwner The owner after the owner was changed
  event OwnerChanged(address indexed oldOwner, address indexed newOwner);

  /// @notice Emitted when a NIL contract is created
  /// @param nilContract The address of the created NIL contract
  event NILContractCreated(address nilContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

library NILErrorCodes {
  /* ========== ACCESS CONTROL ========== */

  /// @notice Only the contract Writer may perform this action
  string public constant ONLY_WRITER = "AC1";

  /// @notice Only the contract Buyer may perform this action
  string public constant ONLY_BUYER = "AC2";

  /// @notice Only the contract Owner may perform this action
  string public constant ONLY_OWNER = "AC3";

  /* ========== INVALID PARAMS ========== */
  /// @notice Invalid Chainlink round ID param
  string public constant INVALID_CHAINLINK_ROUND = "IP1";

  /* ========== INVALID STATE ========== */
  /// @notice This action can only be taken when the contract is in the "Created" state
  string public constant ONLY_CREATED = "IS1";

  /// @notice This action can only be taken when the contract is in the "Pending" state
  string public constant ONLY_PENDING = "IS2";

  /// @notice This action can only be taken when the contract is in the "Ended" state
  string public constant ONLY_ENDED = "IS3";

  /// @notice This action can only be taken when the contract has an end price set
  string public constant ONLY_END_PRICE_SET = "IS4";

  /// @notice The ILV has already been claimed
  /// @dev This happens when the Buyer attemps to claim twice
  string public constant CLAIMED = "IS5";

  /// @notice The collateral has already been withdrawn
  /// @dev This happens when the Writer attemps to withdraw twice
  string public constant WITHDRAWN = "IS6";

  /// @notice The end price already exists
  /// @dev This happens when the Owner attemps to calculate the end Chainlink round
  /// when the end price has already been set
  string public constant END_PRICE_EXISTS = "IS7";

  /// @notice The end price already exists
  /// @dev This happens when the Owner attemps to calculate the end Chainlink round
  /// when the end price has already been set
  string public constant CHAINLINK_ROUND_NOT_FOUND = "IS8";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./interfaces/INILContractFactory.sol";
import "./interfaces/INILContract.sol";
import "./interfaces/IERC20Minimal.sol";
import "./interfaces/external/IChainlinkDataFeed.sol";
import "./interfaces/external/IUniswapV2Pool.sol";
import "./libraries/NILErrorCodes.sol";
import "./libraries/ILMath.sol";
import "./auxiliaries/ChainlinkHistoricalDataFeed.sol";

contract NILContract is INILContract {
  using ChainlinkHistoricalDataFeed for IChainlinkDataFeed;

  uint256 private constant MULTIPLIER_FUNDING_RATE = 1e18;

  /// @inheritdoc INILContractImmutables
  address public immutable override factory;
  /// @inheritdoc INILContractImmutables
  address public immutable override pool;
  /// @inheritdoc INILContractImmutables
  address public immutable override chainlinkFeed;
  /// @inheritdoc INILContractImmutables
  address public immutable override baseToken;
  /// @inheritdoc INILContractImmutables
  uint256 public immutable override fundingRate;
  /// @inheritdoc INILContractImmutables
  uint256 public immutable override fundingPeriodDuration;

  /// @inheritdoc INILContractState
  address public override writer;
  /// @inheritdoc INILContractState
  address public override buyer;
  /// @inheritdoc INILContractState
  uint256 public override collateralAmount;
  /// @inheritdoc INILContractState
  uint256 public override startTimestamp;
  /// @inheritdoc INILContractState
  uint80 public override startChainlinkRound;
  /// @inheritdoc INILContractState
  uint256 public override startPrice;
  /// @inheritdoc INILContractState
  uint256 public override endPrice;
  /// @inheritdoc INILContractState
  bool public override claimed;
  /// @inheritdoc INILContractState
  bool public override withdrawn;

  struct NILContractParams {
    address pool;
    address chainlinkFeed;
    address baseToken;
    uint256 fundingRate;
    uint256 fundingPeriodDuration;
  }

  constructor(NILContractParams memory params) {
    factory = msg.sender;
    pool = params.pool;
    chainlinkFeed = params.chainlinkFeed;
    baseToken = params.baseToken;
    fundingRate = params.fundingRate;
    fundingPeriodDuration = params.fundingPeriodDuration;
  }

  //==============================================================
  // WRITER ACTIONS
  //==============================================================
  /// @inheritdoc INILContractWriterActions
  function deposit(address writerAddress, uint256 amount) external override onlyCreated {
    writer = writerAddress;
    collateralAmount = amount;
    IERC20Minimal(baseToken).transferFrom(msg.sender, address(this), amount);

    emit Deposit(writerAddress, amount);
  }

  /// @inheritdoc INILContractWriterActions
  function withdraw(address recipient) external override onlyWriter onlyEndPriceSet {
    require(!withdrawn, NILErrorCodes.WITHDRAWN);
    withdrawn = true;
    IERC20Minimal(baseToken).transferFrom(
      address(this),
      recipient,
      collateralAmount - ilvClaimable() + _fundingRateAmount()
    );
  }

  //==============================================================
  // BUYER ACTIONS
  //==============================================================

  /// @inheritdoc INILContractBuyerActions
  function purchase(address buyerAddress) external override onlyPending {
    buyer = buyerAddress;
    startTimestamp = block.timestamp;
    (uint80 chainlinkRoundId, , , , ) = IChainlinkDataFeed(chainlinkFeed).latestRoundData();
    startChainlinkRound = chainlinkRoundId;
    startPrice = _tokenPrice();

    IERC20Minimal(baseToken).transferFrom(msg.sender, address(this), _fundingRateAmount());

    emit Purchase(buyerAddress);
  }

  /// @inheritdoc INILContractBuyerActions
  function claim(address recipient) external override onlyBuyer onlyEndPriceSet {
    require(!claimed, NILErrorCodes.CLAIMED);
    claimed = true;
    IERC20Minimal(baseToken).transferFrom(address(this), recipient, ilvClaimable());
  }

  //==============================================================
  // OWNER ACTIONS
  //==============================================================

  /// @inheritdoc INILContractOwnerActions
  function getEndChainlinkRound() external view override onlyOwner onlyEnded returns (uint80) {
    // This is an expensive call, so revert immediately if the contract has not expired,
    // or if `endPrice` has already been set.
    uint256 endTime = startTimestamp + fundingPeriodDuration;
    require(endPrice < 1, NILErrorCodes.END_PRICE_EXISTS);

    return IChainlinkDataFeed(chainlinkFeed).getRoundIdForTimestamp(endTime, startChainlinkRound);
  }

  /// @inheritdoc INILContractOwnerActions
  function setEndPrice(uint80 chainlinkRound) external override onlyOwner onlyEnded {
    // Note: We don't need to check if the end price has already been set here. If the end price
    // has already been set, this transaction will cost gas but will be a no-op.

    uint256 endTime = startTimestamp + fundingPeriodDuration;

    IChainlinkDataFeed feed = IChainlinkDataFeed(chainlinkFeed);
    (, int256 answer, uint256 startedAt, , ) = feed.getRoundData(chainlinkRound);

    (, , uint256 nextStartedAt, , ) = feed.getNextRound(chainlinkRound);
    if (nextStartedAt == 0) {
      // If getNextRound() returned zero values, it means that we're at the latest round so we just need
      // to check that the endTime is after the startedAt timestamp.
      require(endTime > startedAt, NILErrorCodes.INVALID_CHAINLINK_ROUND);
    } else {
      // Check that the endTime is before the startedAt timestamp of the next Chainlink round.
      require(endTime > startedAt && endTime < nextStartedAt, NILErrorCodes.INVALID_CHAINLINK_ROUND);
    }

    endPrice = uint256(answer);
  }

  //==============================================================
  // DERIVED STATE
  //==============================================================

  //   ,----+----.                    ,----+----.
  //   |         |  Writer deposits   |         |
  //   | CREATED | -----------------> | PENDING |
  //   |         |                    |         |
  //   `----+----'                    `----+----'
  //                                       |
  //                                       |
  //                                       | Buyer purchases
  //                                       |
  //                                       |
  //                                       V
  //   ,----+----.                    ,----+----.
  //   |         |   Funding period   |         |
  //   |  ENDED  | <----------------- | STARTED |
  //   |         |        ends        |         |
  //   `----+----'                    `----+----'

  /// @inheritdoc INILContractDerivedState
  function status() public view override returns (Status) {
    if (writer == address(0) && collateralAmount == 0) {
      return Status.CREATED;
    }

    if (buyer == address(0) && startTimestamp < 1) {
      return Status.PENDING;
    }

    if (startTimestamp + fundingPeriodDuration > block.timestamp) {
      return Status.STARTED;
    }

    return Status.ENDED;
  }

  /// @inheritdoc INILContractDerivedState
  function ilv() public view override returns (uint256) {
    Status _status = status();
    if (_status == Status.CREATED || _status == Status.PENDING) {
      return 0;
    }

    uint256 _endPrice = endPrice < 1 ? _tokenPrice() : endPrice;
    uint256 ilp = ILMath.impermanentLoss(startPrice, _endPrice, uint8(18));
    return (collateralAmount * 2 * ilp) / MULTIPLIER_FUNDING_RATE;
  }

  /// @inheritdoc INILContractDerivedState
  function ilvClaimable() public view override returns (uint256) {
    uint256 _ilv = ilv();

    // If the ILV is greater than the collateral amount, the claimable ILV is capped
    // at the collateral amount
    if (_ilv >= collateralAmount) {
      return collateralAmount;
    }

    return _ilv;
  }

  //==============================================================
  // INTERNAL FUNCTIONS
  //==============================================================
  function _fundingRateAmount() internal view returns (uint256) {
    return (collateralAmount * 2 * fundingRate) / MULTIPLIER_FUNDING_RATE;
  }

  function _tokenPrice() internal view returns (uint256) {
    IChainlinkDataFeed chainlink = IChainlinkDataFeed(chainlinkFeed);
    uint256 originalMantissa = uint256(10)**chainlink.decimals();
    uint256 finalMantissa = uint256(10)**IERC20Minimal(IUniswapV2Pool(pool).token1()).decimals();
    return (uint256(chainlink.latestAnswer()) * finalMantissa) / originalMantissa;
  }

  //==============================================================
  // MODIFIERS
  //==============================================================
  function isOwner() internal view virtual returns (bool) {
    return msg.sender == INILContractFactory(factory).owner();
  }

  modifier onlyOwner() {
    require(isOwner(), NILErrorCodes.ONLY_OWNER);
    _;
  }

  modifier onlyWriter() {
    require(msg.sender == writer, NILErrorCodes.ONLY_WRITER);
    _;
  }

  modifier onlyBuyer() {
    require(msg.sender == buyer, NILErrorCodes.ONLY_BUYER);
    _;
  }

  modifier onlyCreated() {
    require(status() == Status.CREATED, NILErrorCodes.ONLY_CREATED);
    _;
  }

  modifier onlyPending() {
    require(status() == Status.PENDING, NILErrorCodes.ONLY_PENDING);
    _;
  }

  modifier onlyEnded() {
    require(status() == Status.ENDED, NILErrorCodes.ONLY_ENDED);
    _;
  }

  modifier onlyEndPriceSet() {
    require(endPrice > 1, NILErrorCodes.ONLY_END_PRICE_SET);
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./contract/INILContractImmutables.sol";
import "./contract/INILContractState.sol";
import "./contract/INILContractDerivedState.sol";
import "./contract/INILContractWriterActions.sol";
import "./contract/INILContractBuyerActions.sol";
import "./contract/INILContractOwnerActions.sol";
import "./contract/INILContractEvents.sol";

/// @title The interface for a NIL contract
// solhint-disable-next-line no-empty-blocks
interface INILContract is
  INILContractImmutables,
  INILContractState,
  INILContractDerivedState,
  INILContractWriterActions,
  INILContractBuyerActions,
  INILContractOwnerActions,
  INILContractEvents
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title Minimal ERC20 interface for NIL
/// @notice Contains a subset of the full ERC20 interface that is used in NIL
interface IERC20Minimal {
  /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
  /// @param sender The account from which the transfer will be initiated
  /// @param recipient The recipient of the transfer
  /// @param amount The amount of the transfer
  // @return Returns true for a successful transfer, false for unsuccessful
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /// @notice Returns the number of decimals used to get its user representation
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IChainlinkDataFeed {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IUniswapV2Pool {
  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import ".//Math.sol";

library ILMath {
  /// @notice Calculates the impermanent loss as a percentage w.r.t. the base token (Token B)
  /// @param startPrice The starting price of Token A w.r.t. Token B
  /// @param endPrice The ending price of Token A w.r.t. Token B
  /// @param decimals The number of decimals to return the percentage in
  function impermanentLoss(
    uint256 startPrice,
    uint256 endPrice,
    uint8 decimals
  ) internal pure returns (uint256) {
    uint256 mantissa = uint256(10)**decimals;
    uint256 priceRatio = (startPrice * mantissa) / endPrice;
    uint256 value = (2 * mantissa * Math.sqrt(priceRatio * mantissa)) / (mantissa + priceRatio);
    return value > mantissa ? value - mantissa : mantissa - value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../interfaces/external/IChainlinkDataFeed.sol";
import "../libraries/NILErrorCodes.sol";

library ChainlinkHistoricalDataFeed {
  using ChainlinkHistoricalDataFeed for IChainlinkDataFeed;

  struct ChainlinkPeriodInfo {
    uint80 startPhaseId;
    uint64 startAggregatorRoundId;
    uint80 latestPhaseId;
    uint64 latestAggregatorRoundId;
  }

  struct Round {
    uint80 phaseId;
    uint64 aggregatorRoundId;
  }

  /// @notice Returns the round data for the next round
  /// @dev If the provided round ID is the latest Chainlink round, this function will return zero values
  /// @param roundId The round ID
  function getNextRound(IChainlinkDataFeed feed, uint80 roundId)
    internal
    view
    returns (
      uint80 nextRoundId,
      int256 nextAnswer,
      uint256 nextStartedAt,
      uint256 nextUpdatedAt,
      uint80 nextAnsweredInRound
    )
  {
    // First check that the round ID passed in is valid
    (, , uint256 timestamp, , ) = safeGetRoundData(feed, roundId);
    require(timestamp > 0, NILErrorCodes.INVALID_CHAINLINK_ROUND);

    // Optimisically construct the next round ID
    uint80 phaseId = roundId >> 64;
    uint64 aggregatorRoundId = uint64(roundId);
    uint80 _nextRoundId = (phaseId << 64) | (aggregatorRoundId + 1);

    // Get the next round
    (nextRoundId, nextAnswer, nextStartedAt, nextUpdatedAt, nextAnsweredInRound) = safeGetRoundData(feed, _nextRoundId);

    // If it's a valid round, just return the data
    if (nextStartedAt > 0) {
      return (nextRoundId, nextAnswer, nextStartedAt, nextUpdatedAt, nextAnsweredInRound);
    }

    // If we got an invalid round, we need to go to the beginning of the next phase
    // to reconstruct the next round ID
    phaseId = phaseId + 1;
    aggregatorRoundId = uint64(1);
    _nextRoundId = (phaseId << 64) | aggregatorRoundId;

    // Get the next round
    return safeGetRoundData(feed, _nextRoundId);
  }

  /// @notice Returns the Chainlink round ID at a specific timestamp
  /// @dev This is an expensive function! Do NOT call this in a transaction
  ///      that updates state
  ///
  ///      This function will revert if a round ID is not found
  /// @param timestamp The timestamp
  /// @param startRoundId The starting round ID. This function will iterate through all
  ///                     rounds starting from this point
  function getRoundIdForTimestamp(
    IChainlinkDataFeed feed,
    uint256 timestamp,
    uint80 startRoundId
  ) internal view returns (uint80) {
    require(timestamp < block.timestamp, "You must provide a timestamp in the past.");

    (, , uint256 startTimestamp, , ) = feed.safeGetRoundData(startRoundId);
    require(timestamp >= startTimestamp, "You must provide a timestamp after the round has started.");

    // https://docs.chain.link/docs/historical-price-data/
    // Iterate forwards through all rounds from the start round ID
    // to the latest round ID to find the round that contains the price
    // for the timestamp.
    (uint80 latestRoundId, , uint256 latestRoundTimestamp, , ) = feed.latestRoundData();

    // Check if the timestamp is for the latest round
    if (timestamp > latestRoundTimestamp) {
      return latestRoundId;
    }

    bool found = false;
    Round memory startRound = Round({phaseId: startRoundId >> 64, aggregatorRoundId: uint64(startRoundId)});
    Round memory latestRound = Round({phaseId: latestRoundId >> 64, aggregatorRoundId: uint64(latestRoundId)});
    Round memory currentRound = Round({phaseId: startRound.phaseId, aggregatorRoundId: startRound.aggregatorRoundId});

    while (
      !found &&
      (currentRound.phaseId < latestRound.phaseId ||
        (currentRound.phaseId == latestRound.phaseId &&
          currentRound.aggregatorRoundId <= latestRound.aggregatorRoundId))
    ) {
      uint80 currentRoundId = (currentRound.phaseId << 64) | currentRound.aggregatorRoundId;
      (uint80 nextRoundId, , uint256 nextStartedAt, , ) = feed.getNextRound(currentRoundId);
      // Stop searching once we find a round where the next round has a startedAt value
      // greater than the timestamp
      if (timestamp < nextStartedAt) {
        found = true;
        break;
      } else {
        // Otherwise, set the cursor to the next round
        currentRound.phaseId = nextRoundId >> 64;
        currentRound.aggregatorRoundId = uint64(nextRoundId);
      }
    }

    require(found, NILErrorCodes.CHAINLINK_ROUND_NOT_FOUND);
    return (currentRound.phaseId << 64) | currentRound.aggregatorRoundId;
  }

  /// @notice Safely returns the round data for a specific round ID
  /// @dev This function will catch any errors that happen in the underlying getRoundData() call
  ///      and return zero values
  /// @param id The round ID
  function safeGetRoundData(IChainlinkDataFeed feed, uint80 id)
    internal
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    try feed.getRoundData(id) returns (
      uint80 _roundId,
      int256 _answer,
      uint256 _startedAt,
      uint256 _updatedAt,
      uint80 _answeredInRound
    ) {
      if (_updatedAt > 0) {
        return (_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
      }
      return (0, 0, 0, 0, 0);
    } catch {
      return (0, 0, 0, 0, 0);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title Contract state that never changes
/// @notice These parameters are fixed for a contract forever, i.e., the methods will always return the same values
interface INILContractImmutables {
  /// @notice The address of the factory that created this contract
  function factory() external view returns (address);

  /// @notice The address of the Uniswap V2 liquidity pool for this contract
  function pool() external view returns (address);

  /// @notice The address of the Chainlink data feed for the token pair
  function chainlinkFeed() external view returns (address);

  /// @notice The address of Token B (the base token) for the Uniswap V2 liquidity pool
  function baseToken() external view returns (address);

  /// @notice The funding rate as a percentage of the value of the LP position. Denominated in 1e18
  function fundingRate() external view returns (uint256);

  /// @notice The duration of the funding period for this contract
  function fundingPeriodDuration() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title Contract state that can change
/// @notice These methods compose a NIL contracts's state, and can change with any frequency
interface INILContractState {
  /// @notice The address of the Writer for this contract
  function writer() external view returns (address);

  /// @notice The address of the contract Buyer
  function buyer() external view returns (address);

  /// @notice The amount of collateral deposited for this contract
  function collateralAmount() external view returns (uint256);

  /// @notice The timestamp for when the funding period started
  function startTimestamp() external view returns (uint256);

  /// @notice The Chainlink round ID when the funding period started
  function startChainlinkRound() external view returns (uint80);

  /// @notice The price of the Token A, priced in Token B at the start of the funding period
  function startPrice() external view returns (uint256);

  /// @notice The price of the Token A, priced in Token B at the end of the funding period
  function endPrice() external view returns (uint256);

  /// @notice True if the Buyer has claimed their realized ILV, false otherwise
  function claimed() external view returns (bool);

  /// @notice True if the Writer has withdrawn their collateral + fees, false otherwise
  function withdrawn() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title Derived contract state that is not stored
/// @notice Contains view functions to provide information about the contract that is computed
/// rather than stored on-chain.
interface INILContractDerivedState {
  //   ,----+----.                    ,----+----.
  //   |         |  Writer deposits   |         |
  //   | CREATED | -----------------> | PENDING |
  //   |         |                    |         |
  //   `----+----'                    `----+----'
  //                                       |
  //                                       |
  //                                       | Buyer purchases
  //                                       |
  //                                       |
  //                                       V
  //   ,----+----.                    ,----+----.
  //   |         |   Funding period   |         |
  //   |  ENDED  | <----------------- | STARTED |
  //   |         |        ends        |         |
  //   `----+----'                    `----+----'
  enum Status {
    CREATED,
    PENDING,
    STARTED,
    ENDED
  }

  /// @notice The status of the NIL Contract
  function status() external view returns (Status);

  /// @notice The current ILV for the NIL Contract
  /// @dev If the contract is pending, the ILV will be 0
  ///      If the contract is in progress, the ILV will be the unrealized value
  ///      If the contract has been ended, the ILV will be the realized value
  function ilv() external view returns (uint256);

  /// @notice The claimable ILV for the NIL Contract. The claimable ILV is capped
  ///         by the collateral amount
  /// @dev If the contract is pending, the claimable ILV will be 0
  ///      If the contract is in progress, the claimable ILV will be the unrealized value
  ///      If the contract has been ended, the claimable ILV will be the realized value
  function ilvClaimable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title NIL contract Writer actions
/// @notice Contains methods that are called by a Writer
interface INILContractWriterActions {
  /// @notice Deposit collateral
  /// @dev This method will fail if the contract been started
  /// @param writer The address to be stored as the Writer
  /// @param amount The amount of collateral to deposit
  function deposit(address writer, uint256 amount) external;

  /// @notice Withdraw unused collateral, plus funding rate fees
  /// @dev This method will fail if the contract period has not ended
  /// @param recipient The address to receive the tokens
  function withdraw(address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title NIL contract Buyer actions
/// @notice Contains methods that are called by a Buyer
interface INILContractBuyerActions {
  /// @notice Purchase IL protection using this NIL contract
  /// @param buyer The address to be stored as the Buyer
  function purchase(address buyer) external;

  /// @notice Claims realized ILV
  /// @dev This method will fail if the contract period has not ended
  /// @param recipient The address to receive the realized ILV
  function claim(address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title NIL contract Owner actions
/// @notice Contains methods that are called by a Owner
interface INILContractOwnerActions {
  function getEndChainlinkRound() external view returns (uint80);

  function setEndPrice(uint80 chainlinkRound) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/// @title Events emitted by a contract
interface INILContractEvents {
  event Deposit(address writer, uint256 amount);

  event Purchase(address buyer);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

library Math {
  // https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol#L11
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}