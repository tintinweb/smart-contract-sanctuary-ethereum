// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 *
 * @dev Auction.sol - Metadrop auction implementation for Webaverse.
 *      Price non-discriminating auction with the following features:
 *      - Time based random end
 *      - Capped end (floor price)
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Auction is Ownable, Pausable, VRFConsumerBaseV2 {
  using SafeERC20 for IERC20;

  /**
   * @dev Chainlink config.
   */
  VRFCoordinatorV2Interface public vrfCoordinator;
  uint64 public vrfSubscriptionId;
  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 public vrfKeyHash;
  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 public vrfCallbackGasLimit = 150000;
  // The default is 3, but you can set this higher.
  uint16 public vrfRequestConfirmations = 3;
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public vrfNumWords = 1;

  /**
   * @dev Contract constants.
   */
  // Total auction length - including the last X hours inside which it can randomly end
  uint256 public constant AUCTION_LENGTH_IN_HOURS = 24;
  // Auction randomly ends within last AUCTION_END_THRESHOLD_HRS
  uint256 public constant AUCTION_END_THRESHOLD_HRS = 2;
  // Fixed minimum and maximum quantity
  uint256 public constant MINIMUM_QUANTITY = 1;
  uint256 public constant MAXIMUM_QUANTITY = 50;

  // Width of the window for which 1 random number will be requested
  uint256 public constant WINDOW_WIDTH_SECONDS = 60;
  // Probability of the random number ending the time based auction segment, out of 10,000
  uint256 public constant TIME_ENDING_P = 200; // 200 / 10,000 = 2%
  // The last time we called chainlink vrf for randomness to end the auction
  uint256 public lastRequestedRandomness;

  /**
   * @dev Contract immutable vars set in constructor.
   */
  uint256 public immutable minimumUnitPrice;
  uint256 public immutable maximumUnitPrice;
  uint256 public immutable minimumBidIncrement;
  uint256 public immutable unitPriceStepSize;

  uint256 public immutable numberOfAuctions;
  uint256 public immutable itemsPerAuction;
  address payable public immutable beneficiaryAddress;

  // block timestamp of when auction starts
  uint256 public auctionStart;
  // Merkle root of those addresses owed a refund
  bytes32 public refundMerkleRoot;

  AuctionStatus private _auctionStatus;
  uint256 private _bidIndex;

  uint256 public quantityAtMaxPrice;

  event AuctionStarted();
  event AuctionEnded();
  event BidPlaced(
    bytes32 indexed bidHash,
    uint256 indexed auctionIndex,
    address indexed bidder,
    uint256 bidIndex,
    uint256 unitPrice,
    uint256 quantity,
    uint256 balance
  );
  event RefundIssued(address indexed refundRecipient, uint256 refundAmount);

  event RandomEnd(
    string endType,
    uint256 endingProbability,
    uint256 randomNumber,
    string result
  );

  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);

  struct Bid {
    uint128 unitPrice;
    uint128 quantity;
  }

  struct AuctionStatus {
    bool started;
    bool ended;
  }

  // keccak256(auctionIndex, bidder address) => current bid
  mapping(bytes32 => Bid) private _bids;
  //Refunds address => excessRefunded
  mapping(address => bool) private _excessRefunded;

  /**
   *
   * @dev Constructor: The constructor must be passed the configuration items as
   * detailed below.
   *
   *   - floorEndTriggerPrice: The floor price that will trigger the floor based immediate end
   *   - vrfCoordinator: The VRF coordinator contract.
   *   - vrfKeyHash: The VRF key hash.
   */
  constructor(
    // Beneficiary address cannot be changed after deployment.
    address payable beneficiaryAddress_,
    uint256 minimumUnitPrice_,
    uint256 minimumBidIncrement_,
    uint256 unitPriceStepSize_,
    uint256 numberOfAuctions_,
    uint256 itemsPerAuction_,
    uint256 maximumUnitPrice_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_
  ) VRFConsumerBaseV2(vrfCoordinator_) {
    beneficiaryAddress = beneficiaryAddress_;
    minimumUnitPrice = minimumUnitPrice_;
    maximumUnitPrice = maximumUnitPrice_;
    minimumBidIncrement = minimumBidIncrement_;
    unitPriceStepSize = unitPriceStepSize_;
    numberOfAuctions = numberOfAuctions_;
    itemsPerAuction = itemsPerAuction_;
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    pause();
  }

  modifier whenRefundsActive() {
    require(refundMerkleRoot != 0, "Refund merkle root not set");
    _;
  }

  modifier whenAuctionActive() {
    require(!_auctionStatus.ended, "Auction has already ended");
    require(_auctionStatus.started, "Auction hasn't started yet");
    _;
  }

  modifier whenPreAuction() {
    require(!_auctionStatus.ended, "Auction has already ended");
    require(!_auctionStatus.started, "Auction has already started");
    _;
  }

  modifier whenAuctionEnded() {
    require(_auctionStatus.ended, "Auction hasn't ended yet");
    require(_auctionStatus.started, "Auction hasn't started yet");
    _;
  }

  /**
   *
   * @dev auctionStatus: Return the current status of the auction.
   *      bool started
   *      bool ended
   *
   */
  function auctionStatus() public view returns (AuctionStatus memory) {
    return _auctionStatus;
  }

  /**
   *
   * @dev chainlink configuration setters:
   *
   */

  /**
   *
   * @dev setVRFCoordinator: Set the chainlink subscription vrf coordinator.
   *
   */
  function setVRFCoordinator(address vrfCoordinator_) external onlyOwner {
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
  }

  /**
   *
   * @dev setVRFSubscriptionId: Set the chainlink subscription id.
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external onlyOwner {
    vrfSubscriptionId = vrfSubscriptionId_;
  }

  /**
   *
   * @dev setVRFKeyHash: Set the chainlink keyhash (gas lane).
   *
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external onlyOwner {
    vrfKeyHash = vrfKeyHash_;
  }

  /**
   *
   * @dev setVRFCallbackGasLimit: Set the chainlink callback gas limit.
   *
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_)
    external
    onlyOwner
  {
    vrfCallbackGasLimit = vrfCallbackGasLimit_;
  }

  /**
   *
   * @dev set: Set the chainlink number of confirmations.
   *
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_)
    external
    onlyOwner
  {
    vrfRequestConfirmations = vrfRequestConfirmations_;
  }

  /**
   *
   * @dev setVRFNumWords: Set the chainlink number of words.
   *
   */
  function setVRFNumWords(uint32 vrfNumWords_) external onlyOwner {
    vrfNumWords = vrfNumWords_;
  }

  /**
   *
   * @dev pause: Pause the contract.
   *
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   *
   * @dev pause: Unpause the contract.
   *
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   *
   * @dev startAuction: set the auction to started and unpause functionality.
   *
   */
  function startAuction() external onlyOwner whenPreAuction {
    _auctionStatus.started = true;
    auctionStart = block.timestamp;

    if (paused()) {
      unpause();
    }
    emit AuctionStarted();
  }

  /**
   *
   * @dev getAuctionEnd: get the time at which the auction will end, being the
   * start time plus the configured auction length in hours.
   *
   */
  function getAuctionEnd() internal view returns (uint256) {
    return auctionStart + (AUCTION_LENGTH_IN_HOURS * 1 hours);
  }

  /**
   *
   * @dev endAuction: external function that can be called to execute _endAuction
   * when the block.timestamp exceeds the auction end time (i.e. the auction is over).
   *
   */
  function endAuction() external whenAuctionActive {
    require(
      block.timestamp >= getAuctionEnd(),
      "Auction can't be stopped until due"
    );
    _endAuction();
  }

  /**
   *
   * @dev _endAuction: internal function that sets _auctionStatus.ended to be true
   * and pauses the contract.
   *
   */
  function _endAuction() internal whenAuctionActive {
    _auctionStatus.ended = true;
    if (!paused()) {
      _pause();
    }
    emit AuctionEnded();
  }

  /**
   *
   * @dev numberOfBidsPlaced: returns the _bidIndex which is the total
   * number of bids made to the auction(s) being run by this contract.
   *
   */
  function numberOfBidsPlaced() external view returns (uint256) {
    return _bidIndex;
  }

  /**
   *
   * @dev getBid: returns the _bidIndex which is the total
   * number of bids made to the auction(s) being run by this contract.
   *
   */
  function getBid(uint256 auctionIndex_, address bidder_)
    external
    view
    returns (Bid memory)
  {
    return _bids[_bidHash(auctionIndex_, bidder_)];
  }

  /**
   *
   * @dev _bidHash: creates a hash of the auctionIndex and bidder address
   * in order to return the bid for a specific auction ID for the passed address.
   *
   */
  function _bidHash(uint256 auctionIndex_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(auctionIndex_, bidder_));
  }

  /**
   *
   * @dev _refundHash: creates a hash of the refundAmount and bidder address
   *
   */
  function _refundHash(uint256 refundAmount_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(refundAmount_, bidder_));
  }

  /**
   *
   * @dev placeBid:
   *
   * When a bidder places a bid or updates their existing bid, they will use this function.
   * - total value can never be lowered
   * - unit price can never be lowered
   * - quantity can be raised or lowered, but only if unit price is raised to meet or exceed previous total price
   *
   */
  function placeBid(
    uint256 auctionIndex_,
    uint256 quantity_,
    uint256 unitPrice_
  ) external payable whenAuctionActive whenNotPaused {
    // If the bidder is increasing their bid, the amount being added must be greater than or equal to the minimum bid increment.
    if (msg.value > 0 && msg.value < minimumBidIncrement) {
      revert("Bid lower than minimum bid increment.");
    }
    // Ensure auctionIndex is within valid range.
    require(auctionIndex_ < numberOfAuctions, "Invalid auctionIndex");

    // Cache initial bid values.
    bytes32 bidHash = _bidHash(auctionIndex_, msg.sender);
    uint256 initialUnitPrice = _bids[bidHash].unitPrice;
    uint256 initialQuantity = _bids[bidHash].quantity;
    uint256 initialBalance = initialUnitPrice * initialQuantity;

    // Cache final bid values.
    uint256 finalUnitPrice = unitPrice_;
    uint256 finalQuantity = quantity_;
    uint256 finalBalance = initialBalance + msg.value;

    // Don't allow bids with a unit price scale smaller than unitPriceStepSize.
    // For example, allow 1.01 or 111.01 but don't allow 1.011.
    require(
      finalUnitPrice % unitPriceStepSize == 0,
      "Unit price step too small"
    );

    // Reject bids that don't have a quantity within the valid range.
    require(finalQuantity >= MINIMUM_QUANTITY, "Quantity too low");
    require(finalQuantity <= MAXIMUM_QUANTITY, "Quantity too high");

    // Balance can never be lowered.
    require(finalBalance >= initialBalance, "Balance can't be lowered");

    // Unit price can never be lowered.
    // Quantity can be raised or lowered, but it can only be lowered if the unit price is raised to meet or exceed the initial total value. Ensuring the the unit price is never lowered takes care of this.
    require(finalUnitPrice >= initialUnitPrice, "Unit price can't be lowered");

    // Ensure the new finalBalance equals quantity * the unit price that was given in this txn exactly. This is important to prevent rounding errors later when returning ether.
    require(
      finalQuantity * finalUnitPrice == finalBalance,
      "Quantity * Unit Price != Total Value"
    );

    // Unit price must be greater than or equal to the minimumUnitPrice.
    require(finalUnitPrice >= minimumUnitPrice, "Bid unit price too low");

    // Unit price must be less than or equal to the maximumUnitPrice.
    require(finalUnitPrice <= maximumUnitPrice, "Bid unit price too high");

    // Something must be changing from the initial bid for this new bid to be valid.
    if (
      initialUnitPrice == finalUnitPrice && initialQuantity == finalQuantity
    ) {
      revert("This bid doesn't change anything");
    }

    // If the bid is the max then increment the counter of max bids by the quantity on the bid:
    if (finalUnitPrice == maximumUnitPrice) {
      quantityAtMaxPrice += finalQuantity;
    }

    // Update the bidder's bid.
    _bids[bidHash].unitPrice = uint128(finalUnitPrice);
    _bids[bidHash].quantity = uint128(finalQuantity);

    emit BidPlaced(
      bidHash,
      auctionIndex_,
      msg.sender,
      _bidIndex,
      finalUnitPrice,
      finalQuantity,
      finalBalance
    );
    // Increment after emitting the BidPlaced event because counter is 0-indexed.
    _bidIndex += 1;

    // After the bid has been placed, check to see whether the auction is ended
    _checkAuctionEnd();
  }

  /**
   *
   * @dev withdrawContractBalance: onlyOwner withdrawal to the beneficiary address
   *
   */
  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev withdrawETH: onlyOwner withdrawal to the beneficiary address, sending
   * the amount to withdraw as an argument
   *
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev transferERC20Token:   A withdraw function to avoid locking ERC20 tokens
   * in the contract forever. Tokens can only be withdrawn by the owner, to the owner.
   *
   */
  function transferERC20Token(IERC20 token, uint256 amount) public onlyOwner {
    token.safeTransfer(owner(), amount);
  }

  /**
   *
   * @dev receive: Handles receiving ether to the contract.
   * Reject all direct payments to the contract except from beneficiary and owner.
   * Bids must be placed using the placeBid function.
   *
   */
  receive() external payable {
    require(msg.value > 0, "No ether was sent");
    require(
      msg.sender == beneficiaryAddress || msg.sender == owner(),
      "Only owner or beneficiary can fund contract"
    );
  }

  /**
   *
   * @dev setRefundMerkleRoot: onlyOwner call to set the refund merkleroot.
   *
   */
  function setRefundMerkleRoot(bytes32 refundMerkleRoot_)
    external
    onlyOwner
    whenAuctionEnded
  {
    refundMerkleRoot = refundMerkleRoot_;
  }

  /**
   *
   * @dev claimRefund: external function call to allow bidders to claim refunds.
   *
   */
  function claimRefund(uint256 refundAmount_, bytes32[] calldata proof_)
    external
    whenNotPaused
    whenAuctionEnded
    whenRefundsActive
  {
    // Can only refund if we haven't already refunded this address:
    require(!_excessRefunded[msg.sender], "Refund already issued");

    bytes32 leaf = _refundHash(refundAmount_, msg.sender);
    require(
      MerkleProof.verify(proof_, refundMerkleRoot, leaf),
      "Refund proof invalid"
    );

    // Safety check - we shouldn't be refunding more than this address has bid across all auctions. This will also
    // catch data collision exploits using other address and refund amount combinations, if
    // such are possible:
    uint256 totalBalance;
    for (
      uint256 auctionIndex = 0;
      auctionIndex < numberOfAuctions;
      auctionIndex++
    ) {
      bytes32 bidHash = _bidHash(auctionIndex, msg.sender);
      totalBalance += _bids[bidHash].unitPrice * _bids[bidHash].quantity;
    }

    require(refundAmount_ <= totalBalance, "Refund request exceeds balance");

    // Set state - we are issuing a refund to this address now, therefore
    // this logic path cannot be entered again for this address:
    _excessRefunded[msg.sender] = true;

    // State has been set, we can now send the refund:
    (bool success, ) = msg.sender.call{value: refundAmount_}("");
    require(success, "Refund failed");

    emit RefundIssued(msg.sender, refundAmount_);
  }

  /**
   *
   * @dev randomEndStarted: Has a random end commenced?
   * This doesn't check for auction end as it is covered by thresholdReached
   *
   */
  function randomEndStarted() external view returns (bool randomEndStarted_) {
    return _thresholdReached();
  }

  /**
   *
   * @dev _blindPriceReached: Has the floor price end trigger been reached?
   *
   */
  function _blindPriceReached() internal view returns (bool) {
    return quantityAtMaxPrice >= itemsPerAuction;
  }

  /**
   *
   * @dev _thresholdReached: Has the auction time based random end period been reached?
   *
   */
  function _thresholdReached() internal view returns (bool) {
    return
      block.timestamp >=
      (getAuctionEnd() - (AUCTION_END_THRESHOLD_HRS * 1 hours));
  }

  /**
   *
   * @dev _checkAuctionEnd: Check if the auction should end based on:
   *  - The time being up (block timestamp is past the end of the auction time)
   *  - The floor price trigger has been reached
   *  - We are in the random end period at the end of the contract and need to call a
   *    random end check
   *
   */
  function _checkAuctionEnd() internal {
    // (1) If we are at or past the end time it's the end of the action:
    if (block.timestamp >= getAuctionEnd())
      _endAuction();
      // (2) See if we have hit the floor trigger price, if so we end the auction
    else if (_blindPriceReached()) {
      _endAuction();
    }
    // (3) See if we have entered the random end period based on time:
    // Also make sure we haven't already requested randomness within WINDOW_WIDTH_SECONDS from now
    else if (
      _thresholdReached() &&
      (block.timestamp - lastRequestedRandomness) >= WINDOW_WIDTH_SECONDS
    ) {
      lastRequestedRandomness = block.timestamp;
      _requestRandomWords();
    }
  }

  /**
   *
   * @dev _requestRandomWords: Request randomness from chainlinkv2
   * Assumes the subscription is funded sufficiently.
   */
  function _requestRandomWords() private returns (uint256) {
    // Will revert if subscription is not set and funded.
    return
      vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        vrfRequestConfirmations,
        vrfCallbackGasLimit,
        vrfNumWords
      );
  }

  /**
   *
   * @dev fulfillRandomWords: Callback from the chainlinkv2 oracle with randomness.
   * Checks to end the auction if it's in the random end period of price or time.
   */
  function fulfillRandomWords(uint256 requestId_, uint256[] memory randomWords_)
    internal
    override
  {
    uint256 randomness = randomWords_[0] % 10000;
    emit RandomNumberReceived(requestId_, randomWords_[0]);

    if (_thresholdReached()) {
      if (randomness < TIME_ENDING_P) {
        emit RandomEnd(
          "Time",
          TIME_ENDING_P,
          randomness,
          "Random End: ending now"
        );
        _endAuction();
      } else {
        emit RandomEnd(
          "Time",
          TIME_ENDING_P,
          randomness,
          "Random End: continuing"
        );
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
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
        uint256 value
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
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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