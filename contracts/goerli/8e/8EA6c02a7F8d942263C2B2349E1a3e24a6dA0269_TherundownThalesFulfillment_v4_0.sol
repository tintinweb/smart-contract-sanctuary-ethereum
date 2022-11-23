// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { ChainlinkExternalFulfillmentCompatible } from "../../../linkpool/v0.8/ChainlinkExternalFulfillmentCompatible.sol";

/**
 * Supported `sportId`
 * --------------------
 * NCAA Men's Football: 1
 * NFL: 2
 * MLB: 3
 * NBA: 4
 * NCAA Men's Basketball: 5
 * NHL: 6
 * MMA: 7
 * WNBA: 8
 * MLS: 10
 * EPL: 11
 * Ligue 1: 12
 * Bundesliga: 13
 * La Liga: 14
 * Serie A: 15
 * UEFA Champions League: 16
 * FIFA World Cup: 18
 */

/**
 * Supported `statusIds`
 * --------------------
 * 1 : STATUS_CANCELED
 * 2 : STATUS_DELAYED
 * 3 : STATUS_END_OF_FIGHT
 * 4 : STATUS_END_OF_ROUND
 * 5 : STATUS_END_PERIOD
 * 6 : STATUS_FIGHTERS_INTRODUCTION
 * 7 : STATUS_FIGHTERS_WALKING
 * 8 : STATUS_FINAL
 * 9 : STATUS_FINAL_PEN
 * 10 : STATUS_FIRST_HALF
 * 11 : STATUS_FULL_TIME
 * 12 : STATUS_HALFTIME
 * 13 : STATUS_IN_PROGRESS
 * 14 : STATUS_IN_PROGRESS_2
 * 15 : STATUS_POSTPONED
 * 16 : STATUS_PRE_FIGHT
 * 17 : STATUS_RAIN_DELAY
 * 18 : STATUS_SCHEDULED
 * 19 : STATUS_SECOND_HALF
 * 20 : STATUS_TBD
 * 21 : STATUS_UNCONTESTED
 * 22 : STATUS_ABANDONED
 * 23 : STATUS_END_OF_EXTRATIME
 * 24 : STATUS_END_OF_REGULATION
 * 25 : STATUS_FORFEIT
 * 26 : STATUS_HALFTIME_ET
 * 27 : STATUS_OVERTIME
 * 28 : STATUS_SHOOTOUT
 */

/**
 * @title A fulfillment contract for Therundown API.
 * @author LinkPool.
 * @dev Uses DRAFT Chainlink external request contracts.
 */
contract TherundownThalesFulfillment_v4_0 is ConfirmedOwner, ChainlinkExternalFulfillmentCompatible {
    /* ========== CONSUMER STATE VARIABLES ========== */

    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        bytes32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        uint8 statusId;
        uint40 updatedAt;
    }

    struct GameResolveWithScoreByPeriod {
        bytes32 gameId;
        uint8[] homeScoreByPeriod;
        uint8[] awayScoreByPeriod;
        uint8 statusId;
        uint40 updatedAt;
    }

    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        int16 spreadHome;
        int24 spreadHomeOdds;
        int16 spreadAway;
        int24 spreadAwayOdds;
        uint24 totalover;
        int24 totalOverOdds;
        uint24 totalUnder;
        int24 totalUnderOdds;
    }

    address private s_genericConsumer;
    mapping(bytes32 => bytes[]) private s_requestIdOdds;
    mapping(bytes32 => uint256) private s_requestIdRemainder;
    mapping(bytes32 => bytes[]) private s_requestIdSchedules;
    mapping(uint256 => uint256[]) private s_sportIdToBookmakerIds;

    error CallerIsNotGenericConsumer();

    /* ========== CONSTRUCTOR ========== */

    constructor(address _genericConsumer) ConfirmedOwner(msg.sender) {
        s_genericConsumer = _genericConsumer;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGenericConsumer(address _genericConsumer) {
        if (_genericConsumer != s_genericConsumer) {
            revert CallerIsNotGenericConsumer();
        }
        _;
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function fulfillOdds(
        bytes32 _requestId,
        uint256 _remainder,
        bytes[] memory _odds
    ) external recordFulfillment(_requestId) {
        s_requestIdOdds[_requestId] = _odds;
        s_requestIdRemainder[_requestId] = _remainder;
    }

    function fulfillSchedules(
        bytes32 _requestId,
        uint256 _remainder,
        bytes[] memory _games
    ) external recordFulfillment(_requestId) {
        s_requestIdSchedules[_requestId] = _games;
        s_requestIdRemainder[_requestId] = _remainder;
    }

    function setBookmakerIdsBySportId(uint256 _sportId, uint256[] memory _bookmakerIds) external onlyOwner {
        s_sportIdToBookmakerIds[_sportId] = _bookmakerIds;
    }

    function setExternalPendingRequest(address _msgSender, bytes32 _requestId)
        external
        onlyGenericConsumer(msg.sender)
    {
        _addPendingRequest(_msgSender, _requestId);
    }

    function setGenericConsumer(address _genericConsumer) external onlyOwner {
        s_genericConsumer = _genericConsumer;
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function getBookmakerIdsBySportId(uint256 _sportId) external view returns (uint256[] memory) {
        return s_sportIdToBookmakerIds[_sportId];
    }

    function getGamesCreated(bytes32 _requestId, uint256 _idx) external view returns (GameCreate memory) {
        GameCreate memory game = abi.decode(s_requestIdSchedules[_requestId][_idx], (GameCreate));
        return game;
    }

    function getGamesResolved(bytes32 _requestId, uint256 _idx) external view returns (GameResolve memory) {
        GameResolve memory game = abi.decode(s_requestIdSchedules[_requestId][_idx], (GameResolve));
        return game;
    }

    function getGameResolvedWithScoreByPeriod(bytes32 _requestId, uint256 _idx)
        external
        view
        returns (GameResolveWithScoreByPeriod memory)
    {
        GameResolveWithScoreByPeriod memory game = abi.decode(
            s_requestIdSchedules[_requestId][_idx],
            (GameResolveWithScoreByPeriod)
        );
        return game;
    }

    function getGenericConsumer() external view returns (address) {
        return s_genericConsumer;
    }

    function getOdds(bytes32 _requestId, uint256 _idx) external view returns (GameOdds memory) {
        GameOdds memory odds = abi.decode(s_requestIdOdds[_requestId][_idx], (GameOdds));
        return odds;
    }

    function getRemainder(bytes32 _requestId) external view returns (uint256) {
        return s_requestIdRemainder[_requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IChainlinkExternalFulfillment } from "./interfaces/IChainlinkExternalFulfillment.sol";
import { ChainlinkFulfillment } from "./ChainlinkFulfillment.sol";

/**
 * @title The ChainlinkExternalFulfillmentCompatible contract.
 * @author LinkPool.
 * @notice Contract writers that build and/or send a Chainlink request from contract A and require to track & fulfill
 * it on contract B, should make contract B inherit from this contract, and make contract A call
 * B.setExternalPendingRequest().
 * @dev Uses @chainlink/contracts 0.5.1.
 * @dev Inheriting from this abstract contract requires to implement 'setExternalPendingRequest'. Make sure the access
 * controls (e.g. onlyOwner, onlyRole) are right.
 */
// solhint-disable-next-line no-empty-blocks
abstract contract ChainlinkExternalFulfillmentCompatible is ChainlinkFulfillment, IChainlinkExternalFulfillment {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title The ChainlinkFulfillment contract.
 * @author LinkPool.
 * @notice Contract writers can inherit this contract to fulfill Chainlink requests.
 * @dev Uses @chainlink/contracts 0.5.1.
 */
contract ChainlinkFulfillment {
    mapping(bytes32 => address) internal s_pendingRequests;

    error ChainlinkFulfillment__CallerIsNotRequester(address msgSender);
    error ChainlinkFulfillment__RequestIsPending(bytes32 requestId);

    event ChainlinkFulfilled(bytes32 indexed id);

    /* ========== MODIFIERS ========== */

    /**
     * @dev Reverts if the request is already pending (value is a contract address).
     * @param _requestId The request ID for fulfillment.
     */
    modifier notPendingRequest(bytes32 _requestId) {
        _requireRequestIsNotPending(_requestId);
        _;
    }

    /**
     * @dev Reverts if the sender is not the expected one (e.g. DRCoordinator, GenericConsumer).
     * @dev Emits the ChainlinkFulfilled event.
     * @param _requestId The request ID for fulfillment.
     */
    modifier recordFulfillment(bytes32 _requestId) {
        _recordFulfillment(_requestId);
        _;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Allows for a Chainlink request to be fulfilled on this contract.
     * @dev Maps the request ID with the contract address in charge of fulfilling the request.
     * @param _msgSender The address of the contract that will fulfill the request.
     * @param _requestId The request ID used for the response.
     */
    function _addPendingRequest(address _msgSender, bytes32 _requestId) internal notPendingRequest(_requestId) {
        s_pendingRequests[_requestId] = _msgSender;
    }

    /**
     * @notice Validates the request fulfillment data (requestId and sender), protecting Chainlink client callbacks from
     * being called by malicious callers.
     * @dev Reverts if the caller is not the original request sender.
     * @dev Emits the ChainlinkFulfilled event.
     * @param _requestId The request ID for fulfillment.
     */
    function _recordFulfillment(bytes32 _requestId) internal {
        address msgSender = s_pendingRequests[_requestId];
        if (msg.sender != msgSender) {
            revert ChainlinkFulfillment__CallerIsNotRequester(msgSender);
        }
        delete s_pendingRequests[_requestId];
        emit ChainlinkFulfilled(_requestId);
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Validates the request is not pending (it hasn't been fulfilled yet, or it just does not exist).
     * @dev Reverts if the request is pending (value is a non-zero contract address).
     * @param _requestId The request ID for fulfillment.
     */
    function _requireRequestIsNotPending(bytes32 _requestId) internal view {
        if (s_pendingRequests[_requestId] != address(0)) {
            revert ChainlinkFulfillment__RequestIsPending(_requestId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlinkExternalFulfillment {
    function setExternalPendingRequest(address _msgSender, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}