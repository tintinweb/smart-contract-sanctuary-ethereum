// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IArbitrable.sol";
import "./interfaces/IArbitrator.sol";
import "./interfaces/IEscrow.sol";

// solhint-disable not-rely-on-time
contract Escrow is Context, IArbitrable, IEscrow {
  using SafeMath for uint256;

  struct Bid {
    // who bid
    address participant;
    // how much
    uint256 amount;
  }

  struct Auction {
    /// all bids from participants
    Bid[] bids;
    /// ninimum for bid allowance
    uint256 minBid;
    /// timestamp of start auction
    uint256 startedAt;
    /// timestamp of end auction
    uint256 endAt;
  }

  // Arbitration
  enum RulingOption {
    /// split and send project fund equally to both parties (NOTES: bid deposit send to freelancer)
    RefusedToArbitrate, 
    /// settle all project fund + bid deposit to client
    Client, 
    /// settle all project fund + bid deposit to freelancer
    Freelancer 
  }

  enum Resolution {
    Executed,
    TimeoutByClient,
    TimeoutByFreelancer,
    RulingEnforced,
    SettlementReached
  }

  struct Dispute {
    uint256 disputeID;
    uint256 clientFee; // Total fees paid by the client.
    uint256 freelancerFee; // Total fees paid by the freelancer.
    RulingOption ruling;
    uint256 firstDepositFeeAt;
  }

  /// maximum verification period from client before fund can be release to freelancer
  uint256 public constant MAX_VERIFY_PERIOD = 2 days;
  /// maximum verification period from client before fund can be release to freelancer
  uint256 public constant MAX_AUCTION_DURATION = 30 days;
  /// title of freelance project
  string public title;
  /// some description goes here
  string public description;
  /// client address or project owner
  address payable public client = payable(_msgSender());
  /// freelancer address
  address payable public freelancer;
  /// deposited fund from client as project budget.
  uint256 public fund;
  /// state of payment
  State public state = State.Initialized;
  /// timestamp of start working on project
  uint256 public startedAt;
  /// timestamp of comfirm delivered project
  uint256 public deliveredAt;
  /// timestamp of project deadline (startedAt + duration), can extend a delay with penaty
  uint256 public deadline;
  /// project duration in seconds
  uint256 public immutable durationInSeconds;
  /// highest bid of last bid
  uint256 public highestBid;
  /// state of auction
  Auction public auction;

  // Arbitration
  uint8 public constant NUM_OF_CHOICES = 2;
  uint256 public immutable arbitrationFeeDepositPeriod;
  IArbitrator public immutable arbitrator;
  bytes public arbitratorExtraData;
  Dispute public dispute;

  constructor(
    string memory _title,
    string memory _description,
    uint256 _durationInSeconds,
    IArbitrator _arbitrator,
    bytes memory _arbitratorExtraData,
    uint256 _arbitrationFeeDepositPeriod
  ) checkDuration(_durationInSeconds) {
    title = _title;
    description = _description;
    durationInSeconds = _durationInSeconds;
    arbitrator = _arbitrator;
    arbitratorExtraData = _arbitratorExtraData;
    arbitrationFeeDepositPeriod = _arbitrationFeeDepositPeriod;
  }

  receive() external payable {
    deposit();
  }

  // Mutation function

  function deposit()
    public
    payable
    onlyClient
    inState(State.Initialized)
  {
    fund = fund.add(msg.value);
    state = State.PaymentInHold;
    // if(auctionDuration != 0){
    //   startAuction(_minBid, auctionDuration);
    // }
  }

  function startAuction(uint256 _minBid, uint256 _auctionDuration)
    external
    onlyClient
    inState(State.PaymentInHold)
    checkDuration(_auctionDuration)
  {
    if (_auctionDuration > MAX_AUCTION_DURATION) {
      revert OverMaximum(_auctionDuration, MAX_AUCTION_DURATION);
    }
    if (_minBid >= fund) {
      revert OverMaximum(_minBid, fund);
    }
    auction.minBid = _minBid;
    auction.startedAt = block.timestamp;
    auction.endAt = block.timestamp.add(_auctionDuration);
    state = State.AuctionStarted;
  }

  function placeBid() external payable inState(State.AuctionStarted) {
    if (_msgSender() == client) {
      revert AccessDenied(freelancer, _msgSender());
    }
    if (block.timestamp > auction.endAt) {
      revert PassDeadline(block.timestamp, auction.endAt);
    }
    uint256 bidAmount = msg.value;

    if (auction.bids.length == 0) {
      if (bidAmount < auction.minBid) {
        revert BelowMinimum(bidAmount, auction.minBid);
      }
    } else {
      Bid memory lastBid = auction.bids[auction.bids.length.sub(1)];
      if (bidAmount < lastBid.amount) {
        revert BelowMinimum(bidAmount, lastBid.amount);
      }
      payable(lastBid.participant).transfer(lastBid.amount);
    }
    auction.bids.push(Bid({participant: _msgSender(), amount: bidAmount}));
  }

  function endAuction(uint256 _startedAt)
    external
    isClientOrFreelancer
    inState(State.AuctionStarted)
  {
    if (block.timestamp < auction.endAt) {
      revert TooEarly(block.timestamp, auction.endAt);
    }
    if (auction.bids.length == 0) {
      state = State.PaymentInHold;
    } else {
      require(
        _startedAt == 0 || _startedAt >= block.timestamp,
        "start project can not before current timestamp"
      );
      if (_startedAt == 0) _startedAt = block.timestamp;
      startedAt = _startedAt;
      deadline = _startedAt.add(durationInSeconds);
      (address winner, uint256 amount) = getLastBid();
      freelancer = payable(winner);
      highestBid = amount;
      state = State.AuctionCompleted;
    }
  }

  function confirmDelivered() external onlyFreelancer inState(State.AuctionCompleted) {
    // check if current timestamp is before deadline of the project
    if(block.timestamp >= deadline){
      revert PassDeadline(block.timestamp, deadline);
    }
    // freelancer delivered the work and confirmed the project has been done.
    deliveredAt = block.timestamp; // halt payment window countdown
    // then mark as WorkDelivered state
    state = State.WorkDelivered;
  }

  function verifyDelivered() external onlyClient inState(State.WorkDelivered) inVerifyPeriod {
    // client verified the project done and satisfied the work,
    // then settle project fund + deposit bid to freelancer,
    _settlePayment();
  }

  function rejectDelivered() external onlyClient inState(State.WorkDelivered) inVerifyPeriod {
    state = State.WorkRejected;
  }

  function releaseFunds() external onlyClient inState(State.WorkRejected) {
    // after project has been fully delivered, then client can process the payment to freelancer.
    _settlePayment();
  }

  function claimPayment() external inState(State.WorkDelivered) {
    if(block.timestamp - deliveredAt < MAX_VERIFY_PERIOD)
    {
      revert DurationNotOver();
    }
    _settlePayment();
  }

  function reclaimFunds() external inState(State.AuctionCompleted) {
    if(block.timestamp < deadline){
      revert DurationNotOver();
    }
    _reclaimFunds();
  }

  function closeProject() public onlyClient inState(State.PaymentInHold) {
    _reclaimFunds();
  }

  // Dispute procedure

  function depositArbitrationFee() external payable isClientOrFreelancer {
    require(
      state == State.WorkRejected || state == State.FeeDeposited, 
      "unexpected status!"
    );
    uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
    if (state == State.FeeDeposited) {
      if(block.timestamp - dispute.firstDepositFeeAt >= arbitrationFeeDepositPeriod){
        revert PassDeadline(block.timestamp - dispute.firstDepositFeeAt, arbitrationFeeDepositPeriod);
      }
    }
    if(msg.value != arbitrationCost){
        revert InvalidAmount();
      }
    if (_msgSender() == client) {
      dispute.clientFee += msg.value;
    } else {
      dispute.freelancerFee += msg.value;
    }

    if (dispute.clientFee >= arbitrationCost && dispute.freelancerFee >= arbitrationCost) {
      raiseDispute(arbitrationCost);
    } else {
      dispute.firstDepositFeeAt = block.timestamp;
      state = State.FeeDeposited;
    }
  }

  function timeOut() external inState(State.FeeDeposited) {
    if (block.timestamp.sub(dispute.firstDepositFeeAt) < arbitrationFeeDepositPeriod) {
      revert TooEarly(block.timestamp, (dispute.firstDepositFeeAt.add(arbitrationFeeDepositPeriod)));
    }

    uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
    uint256 clientSettlementAmount = 0;
    uint256 freelancerSettlementAmount = 0;

    if (dispute.clientFee >= arbitrationCost) {
      clientSettlementAmount = fund.add(dispute.clientFee).add(highestBid);
    } else if (dispute.clientFee != 0) {
      clientSettlementAmount = dispute.clientFee;
    }

    if (dispute.freelancerFee >= arbitrationCost) {
      freelancerSettlementAmount = fund.add(dispute.freelancerFee).add(highestBid);
    } else if (dispute.freelancerFee != 0) {
      freelancerSettlementAmount = dispute.freelancerFee;
    }

    _resolvePayment(clientSettlementAmount, freelancerSettlementAmount);
  }

  function rule(uint256 _disputeID, uint256 _ruling) external override(IArbitrable,IEscrow) onlyArbitrator inState(State.DisputeCreated) {
    if (_ruling > uint256(NUM_OF_CHOICES)) {
      revert OverMaximum(_ruling, uint256(NUM_OF_CHOICES));
    }
    if (_disputeID != dispute.disputeID) {
      revert InvalidIndex();
    }
    dispute.ruling = RulingOption(_ruling);

    uint256 clientSettlementAmount = 0;
    uint256 freelancerSettlementAmount = 0;
    if (dispute.ruling == RulingOption.Client) {
      clientSettlementAmount = fund.add(dispute.clientFee).add(highestBid);
    } else if (dispute.ruling == RulingOption.Freelancer) {
      freelancerSettlementAmount = fund.add(dispute.freelancerFee).add(highestBid);
    } else {
      uint256 splitAmount = uint256(fund.add(dispute.clientFee).add(dispute.freelancerFee).add(highestBid)).div(2);
      clientSettlementAmount = splitAmount;
      freelancerSettlementAmount = splitAmount;
    }

    _resolvePayment(clientSettlementAmount, freelancerSettlementAmount);
    emit Ruling(arbitrator, _disputeID, _ruling);
  }
 
  // View function

  function getLastBid() public view returns (address participant, uint256 amount) {
    if (auction.bids.length == 0) {
      return (address(0), 0);
    }
    Bid memory lastBid = auction.bids[auction.bids.length.sub(1)];
    return (lastBid.participant, lastBid.amount);
  }

  function getBidsCount() public view returns (uint256 count) {
    return auction.bids.length;
  }

  function getBid(uint256 idx) public view returns (address participant, uint256 amount) {
    if (idx >= auction.bids.length) {
      revert InvalidIndex();
    }
    Bid memory bid = auction.bids[idx];
    return (bid.participant, bid.amount);
  }

  function remainingAuctionPeriod() public view inState(State.AuctionStarted) returns (uint256) {
    return block.timestamp > auction.endAt
      ? 0
      : (auction.endAt - block.timestamp);
  }

  function remainingVerifyPeriod() public view inState(State.WorkDelivered) returns (uint256) {
    return (block.timestamp - deliveredAt) > MAX_VERIFY_PERIOD
      ? 0
      : (deliveredAt + MAX_VERIFY_PERIOD - block.timestamp);
  }

  function remainingDepositFeePeriod() public view returns (uint256) {
    if(dispute.firstDepositFeeAt <=0 ){
      revert InvalidDuration();
    }
    return (block.timestamp - dispute.firstDepositFeeAt) > arbitrationFeeDepositPeriod
      ? 0
      : (dispute.firstDepositFeeAt + arbitrationFeeDepositPeriod - block.timestamp);
  }

  // Private & Internal function

  function raiseDispute(uint256 _arbitrationCost) internal {
    dispute.disputeID = arbitrator.createDispute{ value: _arbitrationCost }(
      NUM_OF_CHOICES,
      arbitratorExtraData
    );

    // Refund client if it overpaid
    uint256 extraClientFee = 0;
    if (dispute.clientFee > _arbitrationCost) {
      extraClientFee = dispute.clientFee - _arbitrationCost;
      dispute.clientFee = _arbitrationCost;
    } 

    // Refund freelancer if it overpaid
    uint256 extraFreelancerFee = 0;
    if (dispute.freelancerFee > _arbitrationCost) {
      extraFreelancerFee = dispute.freelancerFee - _arbitrationCost;
      dispute.freelancerFee = _arbitrationCost;
    } 

    state = State.DisputeCreated;
    if (extraClientFee > 0) client.transfer(extraClientFee);
    if (extraFreelancerFee > 0) freelancer.transfer(extraFreelancerFee);
  }

  function _settlePayment() private {
    // settle project fund + highestBid to freelancer,
    uint256 totalFunds = fund.add(highestBid);
    fund = 0;
    highestBid = 0;
    // then mark as VerifiedAndPaymentSettled state
    state = State.VerifiedAndPaymentSettled;
    freelancer.transfer(totalFunds);
  }

  function _reclaimFunds() private {
    fund = 0;
    highestBid = 0;
    // then mark as Reclaimed and Closed state
    state = State.ReclaimNClosed;
    client.transfer(address(this).balance);
  }

  function _resolvePayment(uint256 clientSettlementAmount, uint256 freelancerSettlementAmount) private {
    dispute.clientFee = 0;
    dispute.freelancerFee = 0;
    fund = 0;
    highestBid = 0;
    state = State.Resolved;

    if (clientSettlementAmount != 0) client.transfer(clientSettlementAmount);
    if (freelancerSettlementAmount != 0) freelancer.transfer(freelancerSettlementAmount);
  }

  // Modifiers (middleware)

  modifier onlyClient() {
    if (_msgSender() != client) {
      revert AccessDenied(client, _msgSender());
    }
    _;
  }

  modifier onlyFreelancer() {
    if (_msgSender() != freelancer) {
      revert AccessDenied(freelancer, _msgSender());
    }
    _;
  }

  modifier onlyArbitrator() {
    if (_msgSender() != address(arbitrator)) {
      revert AccessDenied(address(arbitrator), _msgSender());
    }
    _;
  }

  modifier isClientOrFreelancer() {
    if (auction.bids.length == 0) {
      if (_msgSender() != client) {
        revert AccessDenied(client, _msgSender());
      }
    } else {
      address lastParticipant = auction.bids[auction.bids.length.sub(1)].participant;
      require(_msgSender() == client || _msgSender() == lastParticipant, "access denied!");
    }
    _;
  }

  modifier inState(State expected) {
    if (state != expected) {
      revert UnexpectedStatus(expected, state);
    }
    _;
  }

  modifier checkDuration(uint256 duration) {
    if (duration == 0) {
      revert InvalidDuration();
    }
    _;
  }

  modifier checkAddress(address who) {
    if (who == address(0)) {
      revert InvalidAddress();
    }
    _;
  }

  modifier inVerifyPeriod() {
    if (block.timestamp - deliveredAt > MAX_VERIFY_PERIOD) {
      revert PassDeadline(block.timestamp, deliveredAt.add(MAX_VERIFY_PERIOD));
    }
    _;
  }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IArbitrator.sol";

/** @title IArbitrable
 *  @author Enrique Piqueras - <[email protected]>
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emmited when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    //event Dispute(IArbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(IArbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface IEscrow {
  enum State {
    /// Escrow has been initialized. waiting for PO deposit fund.
    Initialized,
    /// Fund has been deposited into contract. waiting for client to start auction project.
    PaymentInHold,
    /// Auction has been started. waiting for bid from freelancers.
    AuctionStarted,
    /// Auction has been completed, also Freelancer has been found. start working on the project.
    AuctionCompleted,
    /// Work has been delivered. waiting for verify from client.
    WorkDelivered,
    /// Work has been rejected, maybe freelancer missing something to deliver.
    WorkRejected,
    /// Client has been verified the work, Payment has been settled from contract to freelancer.
    VerifiedAndPaymentSettled,
    /// Arbitration fee deposited by either party.
    FeeDeposited,
    /// Dispute has been created.
    DisputeCreated,
    /// Dispute has been resolved.
    Resolved,
    /// Project has been closed and funds has been reclaimed by client,
    /// in case no bidding after auction or no work delivered after deadline.
    ReclaimNClosed
  }
  
  /// access denied! Expected `expected`, but found `found`.
  /// @param expected address expected can perform the operation.
  /// @param found address attemp to perform the operation.
  error AccessDenied(address expected, address found);
  /// unexpected status! Expected `expected`, but current state `current`.
  /// @param expected expected status on this state.
  /// @param current current status on this state.
  error UnexpectedStatus(State expected, State current);
  /// Insufficient balance for transfer. Needed `required` but only
  /// `available` available.
  /// @param available balance available.
  /// @param required requested amount to transfer.
  error InsufficientBalance(uint256 available, uint256 required);
  /// invalid given address!
  error InvalidAddress();
  /// duration is invalid!
  error InvalidDuration();
  /// amount is not valid
  error InvalidAmount();
  /// duration has not over
  error DurationNotOver();
  /// current timestamp `current` has been pass deadline `deadline`!
  /// @param current current timestamp.
  /// @param deadline expected deadline.
  error PassDeadline(uint256 current, uint256 deadline);
  /// current timestamp `current` has not been pass expected timestamp `deadline`!
  /// @param current current timestamp.
  /// @param expected expected timestamp.
  error TooEarly(uint256 current, uint256 expected);
  /// given input `given` is over maximum: `max`!
  /// @param given given input.
  /// @param max expected maximum.
  error OverMaximum(uint256 given, uint256 max);
  /// given input `given` is below minimum: `min`!
  /// @param given given input.
  /// @param min expected minimum.
  error BelowMinimum(uint256 given, uint256 min);
  /// given index is invalid!
  error InvalidIndex();

  /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
   */
  function rule(uint _disputeID, uint _ruling) external;
}