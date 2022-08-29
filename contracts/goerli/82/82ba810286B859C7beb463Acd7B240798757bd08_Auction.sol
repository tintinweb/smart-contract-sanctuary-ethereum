pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./Permissions.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IBurnMintableERC20.sol";
import "./interfaces/IMaltDataLab.sol";
import "./interfaces/IDexHandler.sol";
import "./interfaces/ILiquidityExtension.sol";
import "./interfaces/IImpliedCollateralService.sol";
import "./interfaces/IAuctionBurnReserveSkew.sol";
import "./interfaces/IAuctionStartController.sol";


struct AccountCommitment {
  uint256 commitment;
  uint256 redeemed;
  uint256 maltPurchased;
}

struct AuctionData {
  // The full amount of commitments required to return to peg
  uint256 fullRequirement;
  // total maximum desired commitments to this auction
  uint256 maxCommitments;
  // Quantity of sale currency committed to this auction
  uint256 commitments;
  // Malt purchased and burned using current commitments
  uint256 maltPurchased;
  // Desired starting price for the auction
  uint256 startingPrice;
  // Desired lowest price for the arbitrage token
  uint256 endingPrice;
  // Price of arbitrage tokens at conclusion of auction. This is either
  // when the duration elapses or the maxCommitments is reached
  uint256 finalPrice;
  // The peg price for the liquidity pool
  uint256 pegPrice;
  // Time when auction started
  uint256 startingTime;
  uint256 endingTime;
  // Is the auction currently accepting commitments?
  bool active;
  // The reserve ratio at the start of the auction
  uint256 preAuctionReserveRatio;
  // Has this auction been finalized? Meaning any additional stabilizing
  // has been done
  bool finalized;
  // The amount of arb tokens that have been executed and are now claimable
  uint256 claimableTokens;
  // The finally calculated realBurnBudget
  uint256 finalBurnBudget;
  // The amount of Malt purchased with realBurnBudget
  uint256 finalPurchased;
  // A map of all commitments to this auction by specific accounts
  mapping(address => AccountCommitment) accountCommitments;
}


/// @title Malt Arbitrage Auction
/// @author 0xScotch <[email protected]>
/// @notice The under peg Malt mechanism of dutch arbitrage auctions is implemented here
contract Auction is Initializable, Permissions {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  bytes32 public constant AUCTION_AMENDER_ROLE = keccak256("AUCTION_AMENDER_ROLE");

  address public stabilizerNode;
  address public amender;
  IMaltDataLab public maltDataLab;
  ERC20 public collateralToken;
  IBurnMintableERC20 public malt;
  IDexHandler public dexHandler;
  ILiquidityExtension public liquidityExtension;
  IImpliedCollateralService public impliedCollateralService;
  IAuctionBurnReserveSkew public auctionBurnReserveSkew;

  uint256 public unclaimedArbTokens;
  uint256 public replenishingAuctionId;
  uint256 public currentAuctionId;
  uint256 public claimableArbitrageRewards;
  uint256 public nextCommitmentId;
  uint256 public auctionLength = 600; // 10 minutes
  uint256 public arbTokenReplenishSplit = 7000; // 70%
  uint256 public maxAuctionEnd = 900; // 90% of target price
  uint256 public auctionEndReserveBps = 900; // 90% of collateral
  uint256 public priceLookback = 2 minutes;
  uint256 public reserveRatioLookback = 30; // 30 seconds
  uint256 public dustThreshold = 1e4;

  address public auctionStartController;

  mapping (uint256 => AuctionData) internal idToAuction;
  mapping(address => uint256[]) internal accountCommitmentEpochs;

  event AuctionCommitment(
    uint256 commitmentId,
    uint256 auctionId,
    address account,
    uint256 commitment,
    uint256 purchased
  );

  event ClaimArbTokens(
    uint256 auctionId,
    address account,
    uint256 amountTokens
  );

  event AuctionEnded(
    uint256 id,
    uint256 commitments,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 maltPurchased
  );

  event AuctionStarted(
    uint256 id,
    uint256 maxCommitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 startingTime,
    uint256 endingTime
  );

  event ArbTokenAllocation(
    uint256 replenishingAuctionId,
    uint256 maxArbAllocation
  );

  event SetAuctionLength(uint256 length);
  event SetStabilizerNode(address stabilizerNode);
  event SetMaltDataLab(address dataLab);

  function initialize(
    address _timelock,
    address initialAdmin,
    address _collateralToken,
    address _malt,
    uint256 _auctionLength,
    address _stabilizerNode,
    address _maltDataLab,
    address _dexHandler,
    address _liquidityExtension,
    address _impliedCollateralService,
    address _auctionBurnReserveSkew,
    address _amender
  ) external initializer {
    _adminSetup(_timelock);

    _setupRole(ADMIN_ROLE, initialAdmin);
    _setupRole(STABILIZER_NODE_ROLE, _stabilizerNode);
    _roleSetup(AUCTION_AMENDER_ROLE, _amender);

    collateralToken = ERC20(_collateralToken);
    malt = IBurnMintableERC20(_malt);
    auctionLength = _auctionLength;
    stabilizerNode = _stabilizerNode;
    maltDataLab = IMaltDataLab(_maltDataLab);
    dexHandler = IDexHandler(_dexHandler);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_auctionBurnReserveSkew);
    amender = _amender;
  }

  /*
   * PUBLIC METHODS
   */
  function purchaseArbitrageTokens(uint256 amount) external notSameBlock {
    require(auctionActive(currentAuctionId), "No auction running");

    uint256 realCommitment = _capCommitment(currentAuctionId, amount);

    collateralToken.safeTransferFrom(msg.sender, address(liquidityExtension), realCommitment);

    uint256 purchased = liquidityExtension.purchaseAndBurn(realCommitment);
    
    AuctionData storage auction = idToAuction[currentAuctionId];

    require(auction.startingTime <= now, "Auction hasn't started yet");
    require(auction.endingTime >= now, "Auction is already over");
    require(auction.active == true, "Auction is not active");

    auction.commitments = auction.commitments.add(realCommitment);

    if (auction.accountCommitments[msg.sender].commitment == 0) {
      accountCommitmentEpochs[msg.sender].push(currentAuctionId);
    }
    auction.accountCommitments[msg.sender].commitment = auction.accountCommitments[msg.sender].commitment.add(realCommitment);
    auction.accountCommitments[msg.sender].maltPurchased = auction.accountCommitments[msg.sender].maltPurchased.add(purchased);
    auction.maltPurchased = auction.maltPurchased.add(purchased);

    emit AuctionCommitment(
      nextCommitmentId,
      currentAuctionId,
      msg.sender,
      realCommitment,
      purchased
    );

    nextCommitmentId = nextCommitmentId + 1;

    if (auction.commitments >= auction.maxCommitments) {
      _endAuction(currentAuctionId) ;
    }
  }

  function claimArbitrage(uint256 _auctionId) external notSameBlock {
    uint256 amountTokens = userClaimableArbTokens(msg.sender, _auctionId);

    require(amountTokens > 0, "No claimable Arb tokens");

    AuctionData storage auction = idToAuction[_auctionId];

    require(!auction.active, "Cannot claim tokens on an active auction");

    AccountCommitment storage commitment = auction.accountCommitments[msg.sender];

    uint256 redemption = amountTokens.mul(auction.finalPrice).div(auction.pegPrice);
    uint256 remaining = commitment.commitment.sub(commitment.redeemed);

    require(redemption <= remaining.add(1), "Cannot claim more tokens than available");

    commitment.redeemed = commitment.redeemed.add(redemption);

    // Unclaimed represents total outstanding, but not necessarily
    // claimable yet.
    // claimableArbitrageRewards represents total amount that is now
    // available to be claimed
    if (amountTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens.sub(amountTokens);
    }

    if (amountTokens > claimableArbitrageRewards) {
      claimableArbitrageRewards = 0;
    } else {
      claimableArbitrageRewards = claimableArbitrageRewards.sub(amountTokens);
    }

    collateralToken.safeTransfer(msg.sender, amountTokens);

    emit ClaimArbTokens(
      _auctionId,
      msg.sender,
      amountTokens
    );
  }

  /*
   * PUBLIC VIEW FUNCTIONS
   */
  function isAuctionFinished(uint256 _id) public view returns(bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.endingTime > 0 && (now >= auction.endingTime || auction.finalPrice > 0 || auction.commitments >= auction.maxCommitments);
  }

  function auctionActive(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];
    
    return auction.active && now >= auction.startingTime;
  }

  function isAuctionFinalized(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];
    return auction.finalized;
  }

  function userClaimableArbTokens(
    address account,
    uint256 auctionId
  ) public view returns (uint256) {
    AuctionData storage auction = idToAuction[auctionId];

    if (auction.claimableTokens == 0 || auction.finalPrice == 0 || auction.commitments == 0) {
      return 0;
    }

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 totalTokens = auction.commitments.mul(auction.pegPrice).div(auction.finalPrice);


    uint256 claimablePerc = auction.claimableTokens.mul(auction.pegPrice).div(totalTokens);

    uint256 price = auction.finalPrice;

    if (auction.finalPrice == 0) {
      price = currentPrice(auctionId);
    }

    uint256 amountTokens = commitment.commitment.mul(auction.pegPrice).div(price);
    uint256 redeemedTokens = commitment.redeemed.mul(auction.pegPrice).div(price);

    uint256 amountOut = amountTokens.mul(claimablePerc).div(auction.pegPrice).sub(redeemedTokens);

    // Avoid leaving dust behind
    if (amountOut < dustThreshold) {
      return 0;
    }

    return amountOut;
  }

  function balanceOfArbTokens(
    uint256 _auctionId,
    address account
  ) public view returns (uint256) {
    AuctionData storage auction = idToAuction[_auctionId];

    AccountCommitment storage commitment = auction.accountCommitments[account];

    uint256 remaining = commitment.commitment.sub(commitment.redeemed);

    uint256 price = auction.finalPrice;

    if (auction.finalPrice == 0) {
      price = currentPrice(_auctionId);
    }

    return remaining.mul(auction.pegPrice).div(price);
  }

  function averageMaltPrice(uint256 _id) external view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.maltPurchased == 0) {
      return 0;
    }

    return auction.commitments.mul(auction.pegPrice).div(auction.maltPurchased);
  }

  function currentPrice(uint256 _id) public view returns (uint256) {
    AuctionData storage auction = idToAuction[_id];

    if (auction.startingTime == 0) {
      return maltDataLab.priceTarget();
    }

    uint256 secondsSinceStart = 0;

    if (now > auction.startingTime) {
      secondsSinceStart = now - auction.startingTime;
    }

    uint256 auctionDuration = auction.endingTime - auction.startingTime;

    if (secondsSinceStart >= auctionDuration) {
      return auction.endingPrice;
    }

    uint256 totalPriceDelta = auction.startingPrice.sub(auction.endingPrice);

    uint256 currentPriceDelta = totalPriceDelta.mul(secondsSinceStart).div(auctionDuration);

    return auction.startingPrice.sub(currentPriceDelta);
  }

  function getAuctionCommitments(uint256 _id) public view returns (uint256 commitments, uint256 maxCommitments) {
    AuctionData storage auction = idToAuction[_id];

    return (auction.commitments, auction.maxCommitments);
  }

  function getAuctionPrices(uint256 _id) public view returns (uint256 startingPrice, uint256 endingPrice, uint256 finalPrice) {
    AuctionData storage auction = idToAuction[_id];

    return (auction.startingPrice, auction.endingPrice, auction.finalPrice);
  }

  function auctionExists(uint256 _id) public view returns (bool) {
    AuctionData storage auction = idToAuction[_id];

    return auction.startingTime > 0;
  }

  function getAccountCommitments(address account) external view returns (
    uint256[] memory auctions,
    uint256[] memory commitments,
    uint256[] memory awardedTokens,
    uint256[] memory redeemedTokens,
    uint256[] memory finalPrice,
    uint256[] memory claimable,
    bool[] memory finished
  ) {
    uint256[] memory epochCommitments = accountCommitmentEpochs[account];

    auctions = new uint256[](epochCommitments.length);
    commitments = new uint256[](epochCommitments.length);
    awardedTokens = new uint256[](epochCommitments.length);
    redeemedTokens = new uint256[](epochCommitments.length);
    finalPrice = new uint256[](epochCommitments.length);
    claimable = new uint256[](epochCommitments.length);
    finished = new bool[](epochCommitments.length);

    for (uint i = 0; i < epochCommitments.length; ++i) {
      AuctionData storage auction = idToAuction[epochCommitments[i]];

      AccountCommitment storage commitment = auction.accountCommitments[account];

      uint256 price = auction.finalPrice;

      if (auction.finalPrice == 0) {
        price = currentPrice(epochCommitments[i]);
      }

      auctions[i] = epochCommitments[i];
      commitments[i] = commitment.commitment;
      awardedTokens[i] = commitment.commitment.mul(auction.pegPrice).div(price);
      redeemedTokens[i] = commitment.redeemed.mul(auction.pegPrice).div(price);
      finalPrice[i] = price;
      claimable[i] = userClaimableArbTokens(account, epochCommitments[i]);
      finished[i] = isAuctionFinished(epochCommitments[i]);
    }
  }

  function getAccountCommitmentAuctions(address account) external view returns (uint[] memory) {
    return accountCommitmentEpochs[account];
  }

  function getAuctionParticipationForAccount(address account, uint256 auctionId) external view returns (
    uint256 commitment,
    uint256 redeemed,
    uint256 maltPurchased
  ) {
    AccountCommitment storage commitment = idToAuction[auctionId].accountCommitments[account];

    return (commitment.commitment, commitment.redeemed, commitment.maltPurchased);
  }

  function getActiveAuction() external view returns (
    uint256 auctionId,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased
  ) {
    AuctionData storage auction = idToAuction[currentAuctionId];

    return (
      currentAuctionId,
      auction.maxCommitments,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget,
      auction.finalPurchased
    );
  }

  function getAuction(uint256 _id) public view returns (
    uint256 fullRequirement,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased
  ) {
    AuctionData storage auction = idToAuction[_id];

    return (
      auction.fullRequirement,
      auction.maxCommitments,
      auction.commitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.finalBurnBudget,
      auction.finalPurchased
    );
  }

  function getAuctionCore(uint256 _id) public view returns (
    uint256 auctionId,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 preAuctionReserveRatio,
    bool active
  ) {
    AuctionData storage auction = idToAuction[_id];

    return (
      _id,
      auction.commitments,
      auction.maltPurchased,
      auction.startingPrice,
      auction.finalPrice,
      auction.pegPrice,
      auction.startingTime,
      auction.endingTime,
      auction.preAuctionReserveRatio,
      auction.active
    );
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _triggerAuction(
    uint256 pegPrice,
    uint256 rRatio,
    uint256 purchaseAmount
  ) internal {
    if (auctionStartController != address(0)) {
      bool success = IAuctionStartController(auctionStartController).checkForStart();
      if (!success) {
        return;
      }
    }
    (uint256 startingPrice, uint256 endingPrice) = _calculateAuctionPricing(rRatio);

    AuctionData memory auction = AuctionData(
      purchaseAmount, // fullRequirement
      purchaseAmount, // maxCommitments
      0, // commitments
      0, // maltPurchased
      startingPrice,
      endingPrice,
      0, // finalPrice
      pegPrice,
      now, // startingTime
      now.add(auctionLength), // endingTime
      true, // active
      rRatio, // preAuctionReserveRatio
      false, // finalized
      0, // claimableTokens
      0, // finalBurnBudget
      0 // finalPurchased
    );

    _createAuction(
      currentAuctionId,
      auction
    );
  }

  function _capCommitment(uint256 _id, uint256 _commitment) internal view returns (uint256 realCommitment) {
    AuctionData storage auction = idToAuction[_id];

    realCommitment = _commitment;

    if (auction.commitments.add(_commitment) >= auction.maxCommitments) {
      realCommitment = auction.maxCommitments.sub(auction.commitments);
    }
  }

  function _endAuction(uint256 _id) internal {
    AuctionData storage auction = idToAuction[_id];

    require(auction.active == true, "Auction is already over");

    auction.active = false;
    auction.finalPrice = currentPrice(_id);

    uint256 amountArbTokens = auction.commitments.mul(auction.pegPrice).div(auction.finalPrice);
    unclaimedArbTokens = unclaimedArbTokens.add(amountArbTokens);

    emit AuctionEnded(
      _id,
      auction.commitments,
      auction.startingPrice,
      auction.finalPrice,
      auction.maltPurchased
    );
  }

  function _finalizeAuction(uint256 auctionId) internal {
    (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    ) = _setupAuctionFinalization(auctionId);

    if (commitments >= fullRequirement) {
      return;
    }

    uint256 priceTarget = maltDataLab.priceTarget();

    // priceTarget.sub(preAuctionReserveRatio) represents maximum deficit per token
    // priceTarget divided by the max deficit is equivalent to 1 over the max deficit given we are in uint decimal
    // (commitments * 1/maxDeficit) - commitments
    uint256 maxBurnSpend = (commitments.mul(priceTarget).div(priceTarget.sub(preAuctionReserveRatio))).sub(commitments);

    uint256 totalTokens = commitments.mul(priceTarget).div(finalPrice);

    uint256 premiumExcess = 0;

    // The assumption here is that each token will be worth 1 Malt when redeemed.
    // Therefore if totalTokens is greater than the malt purchased then there is a net supply growth
    // After the tokens are repaid. We want this process to be neutral to supply at the very worst.
    if (totalTokens >= maltPurchased) {
      // This also assumes current purchase price of Malt is $1, which is higher than it will be in practice.
      // So the premium excess will actually ensure slight net negative supply growth.
      premiumExcess = totalTokens - maltPurchased;
    }

    uint256 realBurnBudget = auctionBurnReserveSkew.getRealBurnBudget(maxBurnSpend, premiumExcess);

    if (realBurnBudget > 0) {
      AuctionData storage auction = idToAuction[auctionId];

      auction.finalBurnBudget = realBurnBudget;
      auction.finalPurchased = liquidityExtension.purchaseAndBurn(realBurnBudget);
    }
  }

  function _setupAuctionFinalization(uint256 auctionId)
    internal
    returns (
      uint256 avgMaltPrice,
      uint256 commitments,
      uint256 fullRequirement,
      uint256 maltPurchased,
      uint256 finalPrice,
      uint256 preAuctionReserveRatio
    )
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(auction.startingTime > 0, "No auction available for the given id");

    auction.finalized = true;

    if (auction.maltPurchased > 0) {
      avgMaltPrice = auction.commitments.mul(auction.pegPrice).div(auction.maltPurchased);
    }
    
    return (
      avgMaltPrice,
      auction.commitments,
      auction.fullRequirement,
      auction.maltPurchased,
      auction.finalPrice,
      auction.preAuctionReserveRatio
    );
  }

  function _createAuction(
    uint256 _id,
    AuctionData memory auction
  ) internal {
    require(auction.endingTime == uint256(uint64(auction.endingTime)));

    idToAuction[_id] = auction;

    emit AuctionStarted(
      _id,
      auction.maxCommitments,
      auction.startingPrice,
      auction.endingPrice,
      auction.startingTime,
      auction.endingTime
    );
  }

  function _calcRealMaxRaise(uint256 purchaseAmount, uint256 rRatio, uint256 decimals) internal pure returns (uint256) {
    uint256 realBurn = purchaseAmount.mul(
      Math.min(
        rRatio,
        10**decimals
      )
    ).div(10**decimals);

    return purchaseAmount.sub(realBurn);
  }

  function _calculateAuctionPricing(uint256 rRatio) internal view returns (
    uint256 startingPrice,
    uint256 endingPrice
  ) {
    startingPrice = maltDataLab.maltPriceAverage(priceLookback);

    if (startingPrice < rRatio) {
      startingPrice = rRatio;
    }

    // TODO use global intrinsic value instead of rRatio Fri 12 Nov 2021 11:51:28 GMT

    // rRatio should never be large enough for this to overflow
    uint256 absoluteBottom = rRatio * auctionEndReserveBps / 1000;

    uint256 priceTarget = maltDataLab.priceTarget();
    uint256 idealBottom = 1; // 1wei just to avoid any issues with it being 0

    // This should always be true
    if (priceTarget > rRatio) {
      idealBottom = priceTarget - rRatio;
    }

    assert(priceTarget >= startingPrice);
    assert(startingPrice > endingPrice);

    if (idealBottom < startingPrice) {
      endingPrice = idealBottom;
    } else {
      endingPrice = absoluteBottom;
    } 

    // priceTarget should never be large enough to overflow here
    uint256 maxPrice = priceTarget * maxAuctionEnd / 1000;

    if (endingPrice > maxPrice) {
      endingPrice = maxPrice;
    }
  }

  function _checkAuctionFinalization(bool isInternal) internal {
    if (isInternal && !isAuctionFinished(currentAuctionId)) {
      // Auction is still in progress after internal auction purchasing.
      _resetAuctionMaxCommitments();
    }

    if (isAuctionFinished(currentAuctionId)) {
      if (auctionActive(currentAuctionId)) {
        _endAuction(currentAuctionId);
      }

      if (!isAuctionFinalized(currentAuctionId)) {
        _finalizeAuction(currentAuctionId);
      }
      currentAuctionId = currentAuctionId + 1;
    }
  }

  function _resetAuctionMaxCommitments() internal {
    AuctionData storage auction = idToAuction[currentAuctionId];

    uint256 decimals = collateralToken.decimals();

    uint256 realMaxRaise = _calcRealMaxRaise(auction.fullRequirement, auction.preAuctionReserveRatio, decimals);

    if (auction.commitments <= realMaxRaise) {
      auction.maxCommitments = realMaxRaise;
    }
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function checkAuctionFinalization()
    external
    onlyRole(STABILIZER_NODE_ROLE, "Must be stabilizer node")
  {
    _checkAuctionFinalization(false);
  }

  function amendAccountParticipation(address account, uint256 auctionId, uint256 amount, uint256 maltPurchase)
    external
    onlyRole(AUCTION_AMENDER_ROLE, "Only auction amender")
  {
    AuctionData storage auction = idToAuction[auctionId];
    require(auction.accountCommitments[account].commitment >= amount, "amend: amount underflows");
    require(auction.accountCommitments[account].maltPurchased >= maltPurchase, "amend: maltPurchase underflows");

    auction.commitments = auction.commitments - amount;
    auction.maltPurchased = auction.maltPurchased - maltPurchase;

    auction.accountCommitments[account].commitment = auction.accountCommitments[account].commitment - amount; 
    auction.accountCommitments[account].maltPurchased = auction.accountCommitments[account].maltPurchased - maltPurchase;

    uint256 amountArbTokens = amount.mul(auction.pegPrice).div(auction.finalPrice);

    if (amountArbTokens > unclaimedArbTokens) {
      unclaimedArbTokens = 0;
    } else {
      unclaimedArbTokens = unclaimedArbTokens.sub(amountArbTokens);
    }
  }

  function allocateArbRewards(uint256 rewarded)
    external
    onlyRole(STABILIZER_NODE_ROLE, "Must be stabilizer node")
    returns (uint256)
  {
    AuctionData storage auction = idToAuction[replenishingAuctionId];

    if (auction.finalPrice == 0 || auction.startingTime == 0) {
      return rewarded;
    }

    if (auction.commitments == 0) {
      replenishingAuctionId = replenishingAuctionId + 1;
      return rewarded;
    }

    uint256 totalTokens = auction.commitments.mul(auction.pegPrice).div(auction.finalPrice);

    if (auction.claimableTokens < totalTokens) {
      uint256 requirement = totalTokens.sub(auction.claimableTokens);
      uint256 maxArbAllocation = rewarded.mul(arbTokenReplenishSplit).div(10000);

      if (requirement >= maxArbAllocation) {
        auction.claimableTokens = auction.claimableTokens.add(maxArbAllocation);
        rewarded = rewarded.sub(maxArbAllocation);
        claimableArbitrageRewards = claimableArbitrageRewards.add(maxArbAllocation);

        collateralToken.safeTransferFrom(stabilizerNode, address(this), maxArbAllocation);

        emit ArbTokenAllocation(
          replenishingAuctionId,
          maxArbAllocation
        );
      } else {
        auction.claimableTokens = auction.claimableTokens.add(requirement);
        rewarded = rewarded.sub(requirement);
        claimableArbitrageRewards = claimableArbitrageRewards.add(requirement);

        collateralToken.safeTransferFrom(stabilizerNode, address(this), requirement);

        emit ArbTokenAllocation(
          replenishingAuctionId,
          requirement
        );
      }

      if (auction.claimableTokens == totalTokens) {
        uint256 count = 1;

        while (true) {
          auction = idToAuction[replenishingAuctionId + count];

          if (auction.commitments > 0 || !auction.finalized) {
            replenishingAuctionId = replenishingAuctionId + count;
            break;
          }
          count += 1;
        }
      }
    }

    return rewarded;
  }

  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount)
    external
    onlyRole(STABILIZER_NODE_ROLE, "Must be stabilizer node")
  {
    if (purchaseAmount == 0 || auctionExists(currentAuctionId)) {
      return;
    }

    uint256 rRatio = maltDataLab.reserveRatioAverage(reserveRatioLookback);

    _triggerAuction(pegPrice, rRatio, purchaseAmount);

    impliedCollateralService.handleDeficit(purchaseAmount);

    _checkAuctionFinalization(true);
  }

  function setAuctionLength(uint256 _length)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_length > 0, "Length must be larger than 0");
    auctionLength = _length;
    emit SetAuctionLength(_length);
  }

  function setStabilizerNode(address _stabilizerNode)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    _swapRole(_stabilizerNode, stabilizerNode, STABILIZER_NODE_ROLE);
    stabilizerNode = _stabilizerNode;
    emit SetStabilizerNode(_stabilizerNode);
  }

  function setMaltDataLab(address _dataLab)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    maltDataLab = IMaltDataLab(_dataLab);
    emit SetMaltDataLab(_dataLab);
  }

  function setAuctionReplenishId(uint256 _id)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    replenishingAuctionId = _id;
  }

  function setDexHandler(address _handler)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    dexHandler = IDexHandler(_handler);
  }

  function setLiquidityExtension(address _liquidityExtension)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
  }

  function setImpliedCollateralService(address _impliedCollateralService)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
  }

  function setAuctionBurnReserveSkew(address _reserveSkew)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_reserveSkew);
  }

  function setAuctionAmender(address _amender)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_amender != address(0), "Cannot set 0 address");
    _swapRole(_amender, amender, AUCTION_AMENDER_ROLE);
    amender = _amender;
  }

  function setAuctionStartController(address _controller)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    auctionStartController = _controller;
  }

  function setTokenReplenishSplit(uint256 _split)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_split > 0 && _split <= 10000, "Must be between 0-100%");
    arbTokenReplenishSplit = _split;
  }

  function setMaxAuctionEnd(uint256 _maxEnd)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_maxEnd > 0 && _maxEnd <= 1000, "Must be between 0-100%");
    maxAuctionEnd = _maxEnd;
  }

  function setPriceLookback(uint256 _lookback)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    priceLookback = _lookback;
  }

  function setReserveRatioLookback(uint256 _lookback)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_lookback > 0, "Must be above 0");
    reserveRatioLookback = _lookback;
  }

  function setAuctionEndReserveBps(uint256 _bps)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_bps > 0 && _bps < 1000, "Must be between 0-100%");
    auctionEndReserveBps = _bps;
  }

  function setDustThreshold(uint256 _threshold)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    require(_threshold > 0, "Must be between greater than 0");
    dustThreshold = _threshold;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/// @title Permissions
/// @author 0xScotch <[email protected]>
/// @notice Inherited by almost all Malt contracts to provide access control
contract Permissions is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // Timelock has absolute power across the system
  bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

  // Can mint/burn Malt
  bytes32 public constant MONETARY_BURNER_ROLE = keccak256("MONETARY_BURNER_ROLE");
  bytes32 public constant MONETARY_MINTER_ROLE = keccak256("MONETARY_MINTER_ROLE");

  // Contract types
  bytes32 public constant STABILIZER_NODE_ROLE = keccak256("STABILIZER_NODE_ROLE");
  bytes32 public constant LIQUIDITY_MINE_ROLE = keccak256("LIQUIDITY_MINE_ROLE");
  bytes32 public constant AUCTION_ROLE = keccak256("AUCTION_ROLE");
  bytes32 public constant REWARD_THROTTLE_ROLE = keccak256("REWARD_THROTTLE_ROLE");

  address internal globalAdmin;

  mapping(address => uint256) public lastBlock; // protect against reentrancy

  function _adminSetup(address _timelock) internal {
    _roleSetup(TIMELOCK_ROLE, _timelock);
    _roleSetup(ADMIN_ROLE, _timelock);
    _roleSetup(GOVERNOR_ROLE, _timelock);
    _roleSetup(MONETARY_BURNER_ROLE, _timelock);
    _roleSetup(MONETARY_MINTER_ROLE, _timelock);
    _roleSetup(STABILIZER_NODE_ROLE, _timelock);
    _roleSetup(LIQUIDITY_MINE_ROLE, _timelock);
    _roleSetup(AUCTION_ROLE, _timelock);
    _roleSetup(REWARD_THROTTLE_ROLE, _timelock);

    globalAdmin = _timelock;
  }

  function assignRole(bytes32 role, address _assignee)
    external
    onlyRole(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    _setupRole(role, _assignee);
  }

  function removeRole(bytes32 role, address _entity)
    external
    onlyRole(TIMELOCK_ROLE, "Only timelock can revoke roles")
  {
    revokeRole(role, _entity);
  }

  function reassignGlobalAdmin(address _admin)
    external
    onlyRole(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    _swapRole(_admin, globalAdmin, TIMELOCK_ROLE);
    _swapRole(_admin, globalAdmin, ADMIN_ROLE);
    _swapRole(_admin, globalAdmin, GOVERNOR_ROLE);
    _swapRole(_admin, globalAdmin, MONETARY_BURNER_ROLE);
    _swapRole(_admin, globalAdmin, MONETARY_MINTER_ROLE);
    _swapRole(_admin, globalAdmin, STABILIZER_NODE_ROLE);
    _swapRole(_admin, globalAdmin, LIQUIDITY_MINE_ROLE);
    _swapRole(_admin, globalAdmin, AUCTION_ROLE);
    _swapRole(_admin, globalAdmin, REWARD_THROTTLE_ROLE);

    globalAdmin = _admin;
  }

  function emergencyWithdrawGAS(address payable destination)
    external 
    onlyRole(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    // Transfers the entire balance of the Gas token to destination
    destination.call{value: address(this).balance}('');
  }

  function emergencyWithdraw(address _token, address destination)
    external 
    onlyRole(TIMELOCK_ROLE, "Must have timelock role")
  {
    // Transfers the entire balance of an ERC20 token at _token to destination
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, token.balanceOf(address(this)));
  }

  function partialWithdrawGAS(address payable destination, uint256 amount)
    external 
    onlyRole(TIMELOCK_ROLE, "Must have timelock role")
  {
    destination.call{value: amount}('');
  }

  function partialWithdraw(address _token, address destination, uint256 amount)
    external 
    onlyRole(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, amount);
  }

  /*
   * INTERNAL METHODS
   */
  function _swapRole(address newAccount, address oldAccount, bytes32 role) internal {
    revokeRole(role, oldAccount);
    _setupRole(role, newAccount);
  }

  function _roleSetup(bytes32 role, address account) internal {
    _setupRole(role, account);
    _setRoleAdmin(role, ADMIN_ROLE);
  }

  function _onlyRole(bytes32 role, string memory reason) internal view {
    require(
      hasRole(
        role,
        _msgSender()
      ),
      reason
    );
  }

  function _notSameBlock() internal {
    require(
      block.number > lastBlock[_msgSender()],
      "Can't carry out actions in the same block"
    );
    lastBlock[_msgSender()] = block.number;
  }

  // Using internal function calls here reduces compiled bytecode size
  modifier onlyRole(bytes32 role, string memory reason) {
    _onlyRole(role, reason);
    _;
  }

  modifier notSameBlock() {
    _notSameBlock();
    _;
  }
}

pragma solidity >=0.6.6;

interface IAuction {
  function replenishingAuctionId() external view returns(uint256);
  function currentAuctionId() external view returns(uint256);
  function purchaseArbitrageTokens(uint256 amount) external;
  function claimArbitrage(uint256 _auctionId) external;
  function isAuctionFinished(uint256 _id) external view returns(bool);
  function auctionActive(uint256 _id) external view returns (bool);
  function isAuctionFinalized(uint256 _id) external view returns (bool);
  function userClaimableArbTokens(
    address account,
    uint256 auctionId
  ) external view returns (uint256);
  function balanceOfArbTokens(
    uint256 _auctionId,
    address account
  ) external view returns (uint256);
  function averageMaltPrice(uint256 _id) external view returns (uint256);
  function currentPrice(uint256 _id) external view returns (uint256);
  function getAuctionCommitments(uint256 _id) external view returns (uint256 commitments, uint256 maxCommitments);
  function getAuctionPrices(uint256 _id) external view returns (uint256 startingPrice, uint256 endingPrice, uint256 finalPrice);
  function auctionExists(uint256 _id) external view returns (bool);
  function getAccountCommitments(address account) external view returns (
    uint256[] memory auctions,
    uint256[] memory commitments,
    uint256[] memory awardedTokens,
    uint256[] memory redeemedTokens,
    uint256[] memory finalPrice,
    uint256[] memory claimable,
    bool[] memory finished
  );
  function getAccountCommitmentAuctions(address account) external view returns (uint[] memory);
  function getActiveAuction() external view returns (
    uint256 auctionId,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased
  );
  function getAuction(uint256 _id) external view returns (
    uint256 maxCommitments,
    uint256 commitments,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 finalBurnBudget,
    uint256 finalPurchased
  );
  function getAuctionCore(uint256 _id) external view returns (
    uint256 auctionId,
    uint256 commitments,
    uint256 maltPurchased,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    bool active
  );
  function checkAuctionFinalization() external;
  function allocateArbRewards(uint256 rewarded) external returns (uint256);
  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount) external;
  function getAuctionParticipationForAccount(address account, uint256 auctionId) external view returns(uint256, uint256, uint256);
  function amendAccountParticipation(address account, uint256 auctionId, uint256 amount, uint256 maltQuantity) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBurnMintableERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;

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

pragma solidity >=0.6.6;

interface IMaltDataLab {
  function priceTarget() external view returns (uint256);
  function smoothedReserveRatio() external view returns (uint256);
  function smoothedMaltPrice() external view returns (uint256);
  function smoothedMaltInPool() external view returns (uint256);
  function reserveRatioAverage(uint256 _lookback) external view returns (uint256);
  function maltPriceAverage(uint256 _lookback) external view returns (uint256);
  function maltInPoolAverage(uint256 _lookback) external view returns (uint256);
  function realValueOfLPToken(uint256 amount) external view returns (uint256);
  function trackReserveRatio() external;
  function trackPool() external;
}

pragma solidity >=0.6.6;

interface IDexHandler {
  function buyMalt() external returns (uint256 purchased);
  function sellMalt() external returns (uint256 rewards);
  function addLiquidity() external returns (
    uint256 maltUsed,
    uint256 rewardUsed,
    uint256 liquidityCreated
  );
  function removeLiquidity() external returns (uint256 amountMalt, uint256 amountReward);
  function calculateMintingTradeSize(uint256 priceTarget) external view returns (uint256);
  function calculateBurningTradeSize(uint256 priceTarget) external view returns (uint256);
  function reserves() external view returns (uint256 maltSupply, uint256 rewardSupply);
  function maltMarketPrice() external view returns (uint256 price, uint256 decimals);
  function getOptimalLiquidity(address tokenA, address tokenB, uint256 liquidityB)
    external view returns (uint256 liquidityA);
}

pragma solidity >=0.6.6;

interface ILiquidityExtension {
  function hasMinimumReserves() external view returns (bool);
  function collateralDeficit() external view returns (uint256, uint256);
  function reserveRatio() external view returns (uint256, uint256);
  function purchaseAndBurn(uint256 amount) external returns (uint256 purchased);
  function buyBack(uint256 maltAmount) external;
}

pragma solidity >=0.6.6;

interface IImpliedCollateralService {
  function handleDeficit(uint256 maxAmount) external;
  function claim() external;
  function getCollateralValueInMalt() external view returns(uint256);
}

pragma solidity >=0.6.6;

interface IAuctionBurnReserveSkew {
  function consult(uint256 excess) external view returns (uint256);
  function getAverageParticipation() external view;
  function getPegDeltaFrequency() external view;
  function addAbovePegObservation(uint256 amount) external;
  function addBelowPegObservation(uint256 amount) external;
  function setNewStabilizerNode() external;
  function removeStabilizerNode() external;
  function getRealBurnBudget(
    uint256 maxBurnSpend,
    uint256 premiumExcess
  ) external view returns(uint256);
}

pragma solidity >=0.6.6;

interface IAuctionStartController {
  function checkForStart() external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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