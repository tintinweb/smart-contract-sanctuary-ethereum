// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Permissions.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IYsdDataLab.sol";
import "./interfaces/IDAO.sol";
import "./interfaces/IRewardThrottle.sol";
import "./interfaces/IAuctionBurnReserveSkew.sol";
import "./interfaces/ILiquidityExtension.sol";
import "./interfaces/IImpliedCollateralService.sol";
import "./interfaces/IDexHandler.sol";
import "./interfaces/ISwingTrader.sol";
import "./interfaces/IBurnMintableERC20.sol";
import "./interfaces/ISupplyDistributionController.sol";
import "./interfaces/IAuctionStartController.sol";




/// @title Stabilizer Node
/// @author 0xBrains <0xbrains.eth>
/// @notice The backbone of the Ysd stability system. In charge of triggering actions to stabilize price
contract StabilizerNode is Permissions {
  using SafeERC20 for ERC20;

  uint256 internal stabilizeWindowEnd;
  uint256 public stabilizeBackoffPeriod = 5 * 60; // 5 minutes
  uint256 public upperStabilityThresholdBps = 100; // 1%
  uint256 public lowerStabilityThresholdBps = 100;
  uint256 public maxContributionBps = 7000;
  uint256 public priceAveragePeriod = 5 minutes;
  uint256 public fastAveragePeriod = 30; // 30 seconds
  uint256 public emergencyMintLookback = 5 minutes;
  uint256 public emergencyMintThresholdBps = 200; // 2%
  uint256 public overrideDistanceBps = 200; // 2%

  uint256 public expansionDampingFactor = 1;

  uint256 public defaultIncentive = 100; // in Ysd
  uint256 public trackingIncentive = 20; // in 100ths of a Ysd

  uint256 public daoRewardCutBps;
  uint256 public lpRewardCutBps = 4170;
  uint256 public auctionPoolRewardCutBps = 1130;
  uint256 public swingTraderRewardCutBps = 4170;
  uint256 public treasuryRewardCutBps = 500;
  uint256 public callerRewardCutBps = 30;
  uint256 public buyBurnCutBps = 500;  // 5%

  uint256 public upperBandLimitBps = 100000; // 1000%
  uint256 public lowerBandLimitBps = 1000; // 10%
  uint256 public sampleSlippageBps = 2000; // 20%
  uint256 public skipAuctionThreshold;

  uint256 public lastStabilize;
  uint256 public lastTracking;
  uint256 public trackingBackoff = 30; // 30 seconds
  

  bool internal trackAfterStabilize = true;

  ERC20 public rewardToken;
  IBurnMintableERC20 public ysd;
  IAuction public auction;
  IDexHandler public dexHandler;
  IDAO public dao;
  ILiquidityExtension public liquidityExtension;
  IYsdDataLab public ysdDataLab;
  IAuctionBurnReserveSkew public auctionBurnReserveSkew;
  IRewardThrottle public rewardThrottle;
  ERC20 public buyBurnToken;
  // MyToken public myToken;
  ISwingTrader public swingTrader;
  IImpliedCollateralService public impliedCollateralService;

  address payable public treasuryMultisig;
  address public auctionPool;
  address public supplyDistributionController;
  address public auctionStartController;

  event MintYsd(uint256 amount);
  event Stabilize(uint256 timestamp, uint256 exchangeRate);
  event RewardDistribution(uint256 rewarded);
  event SetStabilizeBackoff(uint256 period);
  event SetAuctionBurnSkew(address auctionBurnReserveSkew);
  event SetRewardCut(uint256 daoCut, uint256 lpCut, uint256 callerCut, uint256 treasuryCut, uint256 auctionPoolCut, uint256 swingTraderCut, uint256 buyBurn);
  event SetTreasury(address newTreasury);
  event SetDefaultIncentive(uint256 incentive);
  event SetTrackingIncentive(uint256 incentive);
  event SetExpansionDamping(uint256 amount);
  event SetNewYsdDataLab(address dataLab);
  event SetAuctionContract(address auction);
  event SetDexHandler(address dexHandler);
  event SetDao(address dao);
  event SetLiquidityExtension(address liquidityExtension);
  event SetRewardThrottle(address rewardThrottle);
  event setBuyBurnToken(address buyBurnToken);
  event setRewardContract(address rewardToken);
  event SetSwingTrader(address swingTrader);
  event SetPriceAveragePeriod(uint256 period);
  event SetOverrideDistance(uint256 distance);
  event SetFastAveragePeriod(uint256 period);
  event SetStabilityThresholds(uint256 upper, uint256 lower);
  event SetAuctionPool(address auctionPool);
  event SetMaxContribution(uint256 maxContribution);
  event SetImpliedCollateralService(address impliedCollateralService);
  event SetSupplyDistributionController(address _controller);
  event SetAuctionStartController(address _controller);
  event SetBandLimits(uint256 _upper, uint256 _lower);
  event SetSlippageBps(uint256 _slippageBps);
  event SetSkipAuctionThreshold(uint256 _skipAuctionThreshold);
  event SetEmergencyMintThresholdBps(uint256 thresholdBps);
  event SetEmergencyMintLookback(uint256 lookback);
  event Tracking();
  event SetTrackingBackoff(uint256 backoff);

  constructor(
    address _timelock,
    address initialAdmin,
    address _ysd,
    address _rewardToken,
    address payable _treasuryMultisig,
    uint256 _skipAuctionThreshold,
    address _burnProfit
  ) {
    require(_timelock != address(0), "StabilizerNode: Timelock addr(0)");
    require(initialAdmin != address(0), "StabilizerNode: Admin addr(0)");
    require(_treasuryMultisig != address(0), "StabilizerNode: Treasury addr(0)");
    require(_burnProfit != address(0), "StabilizerNode: buyBurnToken addr(0)");

    _adminSetup(_timelock);

    _setupRole(ADMIN_ROLE, initialAdmin);

    treasuryMultisig = _treasuryMultisig;
    rewardToken = ERC20(_rewardToken);
    ysd = IBurnMintableERC20(_ysd);
    skipAuctionThreshold = _skipAuctionThreshold;

    lastStabilize = block.timestamp;

    buyBurnToken = ERC20(_burnProfit);
  }

  function setupContracts(
    address _dexHandler,
    address _ysdDataLab,
    address _auctionBurnReserveSkew,
    address _rewardThrottle,
    address _dao,
    address _swingTrader,
    address _liquidityExtension,
    address _impliedCollateralService,
    address _auction,
    address _auctionPool
  ) external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(auctionPool == address(0), "StabilizerNode: Already setup");
    require(_dexHandler != address(0), "StabilizerNode: DexHandler addr(0)");
    require(_ysdDataLab != address(0), "StabilizerNode: DataLab addr(0)");
    require(_auctionBurnReserveSkew != address(0), "StabilizerNode: BurnSkew addr(0)");
    require(_rewardThrottle != address(0), "StabilizerNode: Throttle addr(0)");
    require(_dao != address(0), "StabilizerNode: DAO addr(0)");
    require(_swingTrader != address(0), "StabilizerNode: Swing addr(0)");
    require(_liquidityExtension != address(0), "StabilizerNode: LE addr(0)");
    require(_impliedCollateralService != address(0), "StabilizerNode: ImpCol addr(0)");
    require(_auction != address(0), "StabilizerNode: Auction addr(0)");
    require(_auctionPool != address(0), "StabilizerNode: AuctionPool addr(0)");
    //  require(_burnProfit != address(0), "StabilizerNode: buyBurnContract addr(0)");

    _setupRole(AUCTION_ROLE, _auction);

    dexHandler = IDexHandler(_dexHandler);
    ysdDataLab = IYsdDataLab(_ysdDataLab);
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_auctionBurnReserveSkew);
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    dao = IDAO(_dao);
    swingTrader = ISwingTrader(_swingTrader);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
    auction = IAuction(_auction);
    auctionPool = _auctionPool;
    //  buyBurnToken = ERC20(_burnProfit);
  }

  function stabilize() external nonReentrant {
    // Ensure data consistency
    ysdDataLab.trackPool();

    // Finalize auction if possible before potentially starting a new one
    auction.checkAuctionFinalization();

    require(
      block.timestamp >= stabilizeWindowEnd || _stabilityWindowOverride(),
      "Can't call stabilize"
    );
    stabilizeWindowEnd = block.timestamp + stabilizeBackoffPeriod;

    rewardThrottle.checkRewardUnderflow();

    // used in 3 location.
    uint256 exchangeRate = ysdDataLab.ysdPriceAverage(priceAveragePeriod);

    if (!_shouldAdjustSupply(exchangeRate)) {
      lastStabilize = block.timestamp;
      return;
    }

    emit Stabilize(block.timestamp, exchangeRate);

    (uint256 livePrice,) = dexHandler.ysdMarketPrice();

    uint256 priceTarget = ysdDataLab.priceTarget();
    // The upper and lower bands here avoid any issues with price
    // descrepency between the TWAP and live market price.
    // This avoids starting auctions too quickly into a big selloff
    // and also reduces risk of flashloan vectors
    if (exchangeRate > priceTarget) {
      uint256 upperBand = exchangeRate + (exchangeRate * upperBandLimitBps / 10000);
      uint256 latestSample = ysdDataLab.ysdPriceAverage(0);
      uint256 minThreshold = latestSample - ((latestSample - priceTarget) * sampleSlippageBps / 10000);

      if (!hasRole(ADMIN_ROLE, _msgSender())) {
        require(livePrice < upperBand, "Stabilize: Beyond upper bound");
        require(livePrice > minThreshold, "Stabilize: Slippage threshold");
      }

      _distributeSupply();
    } else {
      uint256 lowerBand = exchangeRate - (exchangeRate * lowerBandLimitBps / 10000);
      require(livePrice > lowerBand, "Stabilize: Beyond lower bound");

      _startAuction();
    }

    if (trackAfterStabilize) {
      ysdDataLab.trackPool();
    }
    lastStabilize = block.timestamp;
  }

  function endAuctionEarly() external {
    // This call reverts if the auction isn't ended
    auction.endAuctionEarly();

    // It hasn't reverted so the auction was ended. Pay the incentive
    ysd.mint(msg.sender, defaultIncentive * (10**ysd.decimals()));
    emit MintYsd(defaultIncentive * (10**ysd.decimals()) );
  }

  function trackPool() external {
    require(block.timestamp >= lastTracking + trackingBackoff, "Too early");
    ysdDataLab.trackPool();
    ysd.mint(msg.sender, (trackingIncentive * (10**ysd.decimals())) / 100); // div 100 because units are cents
    lastTracking = block.timestamp;
    emit Tracking();
  }

  /*
   * INTERNAL VIEW FUNCTIONS
   */
  function _stabilityWindowOverride() internal view returns (bool) {
    if (hasRole(ADMIN_ROLE, _msgSender())) {
      // Admin can always stabilize
      return true;
    }
    // Must have elapsed at least one period of the moving average before we stabilize again
    if (block.timestamp < lastStabilize + fastAveragePeriod) {
      return false;
    }

    uint256 priceTarget = ysdDataLab.priceTarget();
    uint256 exchangeRate = ysdDataLab.ysdPriceAverage(fastAveragePeriod);

    uint256 upperThreshold = priceTarget * (10000 + overrideDistanceBps) / 10000;

    return exchangeRate >= upperThreshold;
  }

  function _shouldAdjustSupply(uint256 exchangeRate) internal view returns (bool) {
    uint256 decimals = rewardToken.decimals();
    uint256 priceTarget = ysdDataLab.priceTarget();

    uint256 upperThreshold = priceTarget * upperStabilityThresholdBps / 10000;
    uint256 lowerThreshold = priceTarget * lowerStabilityThresholdBps / 10000;

    return (exchangeRate <= (priceTarget - lowerThreshold) && !auction.auctionExists(auction.currentAuctionId())) || exchangeRate >= (priceTarget + upperThreshold);
  }

  /*
   * INTERNAL FUNCTIONS
   */
  function _distributeSupply() internal {
    if (supplyDistributionController != address(0)) {
      bool success = ISupplyDistributionController(supplyDistributionController).check();
      if (!success) {
        return;
      }
    }

    uint256 priceTarget = ysdDataLab.priceTarget();
    uint256 tradeSize = dexHandler.calculateMintingTradeSize(priceTarget) / expansionDampingFactor;

    if (tradeSize == 0) {
      return;
    }

    uint256 swingAmount = swingTrader.sellYsd(tradeSize);

    if (swingAmount >= tradeSize) {
      return;
    }

    tradeSize = tradeSize - swingAmount;

    ysd.mint(address(dexHandler), tradeSize);
    emit MintYsd(tradeSize);
    // safeTransfer verification ensure any attempt to
    // sandwhich will trigger stabilize first
    uint256 rewards = dexHandler.sellYsd(tradeSize, 10000);

    auctionBurnReserveSkew.addAbovePegObservation(tradeSize);

    uint256 remaining = _replenishLiquidityExtension(rewards);

    _distributeRewards(remaining);

    impliedCollateralService.claim();
  }

  function _distributeRewards(uint256 rewarded) internal {
    if (rewarded == 0) {
      return;
    }
    // Ensure starting at 0
    rewardToken.safeApprove(address(auction), 0);
    rewardToken.safeApprove(address(auction), rewarded);
    rewarded = auction.allocateArbRewards(rewarded);
    // Reset approval
    rewardToken.safeApprove(address(auction), 0);

    if (rewarded == 0) {
      return;
    }

    uint256 callerCut = rewarded * callerRewardCutBps / 10000;
    uint256 lpCut = rewarded * lpRewardCutBps / 10000;
    uint256 daoCut = rewarded * daoRewardCutBps / 10000;
    uint256 auctionPoolCut = rewarded * auctionPoolRewardCutBps / 10000;
    uint256 swingTraderCut = rewarded * swingTraderRewardCutBps / 10000;
    uint256 buyBurn = rewarded * buyBurnCutBps / 10000;

    // Treasury gets paid after everyone else
    uint256 treasuryCut = rewarded - daoCut - lpCut - callerCut - auctionPoolCut - swingTraderCut - buyBurn;

    assert(treasuryCut <= rewarded);

    if (callerCut > 0) {
      rewardToken.safeTransfer(msg.sender, callerCut);
    }

    if (auctionPoolCut > 0) {
      rewardToken.safeTransfer(auctionPool, auctionPoolCut);
    }

    if (swingTraderCut > 0) {
      rewardToken.safeTransfer(address(swingTrader), swingTraderCut);
    }

    if (treasuryCut > 0) {
      rewardToken.safeTransfer(treasuryMultisig, treasuryCut);
    }

    if (daoCut > 0) {
      rewardToken.safeTransfer(address(dao), daoCut);
    }

    if (lpCut > 0) {
      rewardToken.safeTransfer(address(rewardThrottle), lpCut);
      rewardThrottle.handleReward();
    }

    if (buyBurn > 0) {
      rewardToken.safeTransfer(address(buyBurnToken), buyBurn);
    }
    emit RewardDistribution(rewarded);
  }

  function _replenishLiquidityExtension(uint256 rewards) internal returns (uint256 remaining) {
    if (rewards == 0) {
      return rewards;
    }

    (uint256 deficit,) = liquidityExtension.collateralDeficit();

    if (deficit == 0) {
      return rewards;
    }

    uint256 maxContrib = rewards * maxContributionBps / 10000;

    if (deficit >= maxContrib) {
      rewardToken.safeTransfer(address(liquidityExtension), maxContrib);
      return rewards - maxContrib;
    }

    rewardToken.safeTransfer(address(liquidityExtension), deficit);

    return rewards - deficit;
  }

  function _startAuction() internal {
    if (auctionStartController != address(0)) {
      bool success = IAuctionStartController(auctionStartController).checkForStart();
      if (!success) {
        return;
      }
    }

    uint256 priceTarget = ysdDataLab.priceTarget();
    uint256 purchaseAmount = dexHandler.calculateBurningTradeSize(priceTarget);

    if (purchaseAmount < skipAuctionThreshold) {
      return;
    }

    purchaseAmount = purchaseAmount - (swingTrader.buyYsd(purchaseAmount));

    if (purchaseAmount < 10**rewardToken.decimals()) {
      return;
    }

    auction.triggerAuction(priceTarget, purchaseAmount);

    ysd.mint(msg.sender, defaultIncentive * (10**ysd.decimals()) );
    emit MintYsd(defaultIncentive * (10**ysd.decimals()) );

    auctionBurnReserveSkew.addBelowPegObservation(purchaseAmount);
  }

  // @notice Allows minting of Ysd for $1 in recovery mode
  // @param amount: Amount of rewardToken to use to mint Ysd
  function emergencyMintYsd(uint256 amount) external {
    uint256 priceTarget = ysdDataLab.priceTarget();

    // Setting emergency mint BPS to 0 always allows minting for $1
    // This should not be allowed generally but can be useful in edge case failures.
    if (emergencyMintThresholdBps != 0) {
      uint256 twap = ysdDataLab.ysdPriceAverage(emergencyMintLookback);
      uint256 target = priceTarget * (10000 - emergencyMintThresholdBps) / 10000;
      require(twap <= target, "Can only emergency mint below threshold");
    }

    rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    uint256 unity = 10**rewardToken.decimals();

    rewardToken.safeTransfer(address(swingTrader), amount);
    ysd.mint(msg.sender, amount * unity / priceTarget);
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */

  function setStabilizeBackoff(uint256 _period)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Must be greater than 0");
    stabilizeBackoffPeriod = _period;
    emit SetStabilizeBackoff(_period);
  }

  function setAuctionBurnSkew(address _auctionBurnReserveSkew)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_auctionBurnReserveSkew);
    emit SetAuctionBurnSkew(_auctionBurnReserveSkew);
  }

  function setRewardCut(
    uint256 _daoCut,
    uint256 _lpCut,
    uint256 _callerCut,
    uint256 _auctionPoolCut,
    uint256 _swingTraderCut,
    uint256 _buyBurnProfit
  )
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    uint256 sum = _daoCut + _lpCut + _callerCut + _auctionPoolCut + _swingTraderCut + _buyBurnProfit;
    require(sum <= 10000, "Reward cut must be <= 100%");
    daoRewardCutBps = _daoCut;
    lpRewardCutBps = _lpCut;
    callerRewardCutBps = _callerCut;
    auctionPoolRewardCutBps = _auctionPoolCut;
    swingTraderRewardCutBps = _swingTraderCut;
    buyBurnCutBps = _buyBurnProfit;
    uint256 treasuryCut = 10000 - sum;
    treasuryRewardCutBps = treasuryCut;


    emit SetRewardCut(_daoCut, _lpCut, _callerCut, treasuryCut, _auctionPoolCut, _swingTraderCut, _buyBurnProfit);
  }

  function setTreasury(address payable _newTreasury)
    external
    onlyRoleYsd(TIMELOCK_ROLE, "Must have timelock role")
  {
    treasuryMultisig = _newTreasury;
    emit SetTreasury(_newTreasury);
  }

  function setDefaultIncentive(uint256 _incentive)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_incentive != 0 && _incentive <= 1000, "Incentive out of range");

    defaultIncentive = _incentive;

    emit SetDefaultIncentive(_incentive);
  }

  function setTrackingIncentive(uint256 _incentive)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    // Priced in cents. Must be less than 1000 Ysd
    require(_incentive != 0 && _incentive <= 100000, "Incentive out of range");

    trackingIncentive = _incentive;

    emit SetTrackingIncentive(_incentive);
  }

  /// @notice Only callable by Admin address.
  /// @dev Sets the Expansion Damping units.
  /// @param amount: Amount to set Expansion Damping units to.
  function setExpansionDamping(uint256 amount)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(amount > 0, "No negative damping");

    expansionDampingFactor = amount;
    emit SetExpansionDamping(amount);
  }

  function setNewDataLab(address _dataLab)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    ysdDataLab = IYsdDataLab(_dataLab);
    emit SetNewYsdDataLab(_dataLab);
  }

  function setAuctionContract(address _auction)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {

    if (address(auction) != address(0)) {
      revokeRole(AUCTION_ROLE, address(auction));
    }

    auction = IAuction(_auction);
    _setupRole(AUCTION_ROLE, _auction);
    emit SetAuctionContract(_auction);
  }

  function setStabilityThresholds(uint256 _upper, uint256 _lower)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_upper != 0 && _lower != 0, "Must be above 0");
    require(_lower < 10000, "Lower to large");

    upperStabilityThresholdBps = _upper;
    lowerStabilityThresholdBps = _lower;
    emit SetStabilityThresholds(_upper, _lower);
  }

  function setAuctionPool(address _auctionPool)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_auctionPool != address(0), "Not address 0");

    auctionPool = _auctionPool;
    emit SetAuctionPool(_auctionPool);
  }

  function setSupplyDistributionController(address _controller)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    supplyDistributionController = _controller;
    emit SetSupplyDistributionController(_controller);
  }

  function setAuctionStartController(address _controller)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin privilege")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    auctionStartController = _controller;
    emit SetAuctionStartController(_controller);
  }

  function setMaxContribution(uint256 _maxContribution)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_maxContribution != 0 && _maxContribution <= 10000, "Must be between 0 and 100");

    maxContributionBps = _maxContribution;
    emit SetMaxContribution(_maxContribution);
  }

  function setDexHandler(address _dexHandler)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_dexHandler != address(0), "Not address 0");
    dexHandler = IDexHandler(_dexHandler);
    emit SetDexHandler(_dexHandler);
  }

  function setDao(address _dao)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_dao != address(0), "Not address 0");
    dao = IDAO(_dao);
    emit SetDao(_dao);
  }

    function setBuyBurnTokens(address _buyToken)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_buyToken != address(0), "Not address 0");
     buyBurnToken = ERC20(_buyToken);
    emit setBuyBurnToken(_buyToken);
  }

      function setRewardContracts(address _rewardContract)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_rewardContract != address(0), "Not address 0");
     rewardToken = ERC20(_rewardContract);
    emit setRewardContract(_rewardContract);
  }

  function setLiquidityExtension(address _liquidityExtension)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_liquidityExtension != address(0), "Not address 0");
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    emit SetLiquidityExtension(_liquidityExtension);
  }

  function setRewardThrottle(address _rewardThrottle)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_rewardThrottle != address(0), "Not address 0");
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    emit SetRewardThrottle(_rewardThrottle);
  }

  function setSwingTrader(address _swingTrader)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_swingTrader != address(0), "Not address 0");
    swingTrader = ISwingTrader(_swingTrader);
    emit SetSwingTrader(_swingTrader);
  }

  function setImpliedCollateralService(address _impliedCollateralService)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_impliedCollateralService != address(0), "Not address 0");
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
    emit SetImpliedCollateralService(_impliedCollateralService);
  }

  function setPriceAveragePeriod(uint256 _period)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Cannot have 0 period");
    priceAveragePeriod = _period;
    emit SetPriceAveragePeriod(_period);
  }

  function setOverrideDistance(uint256 _distance)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_distance != 0 && _distance < 10000, "Override must be between 0-100%");
    overrideDistanceBps = _distance;
    emit SetOverrideDistance(_distance);
  }

  function setFastAveragePeriod(uint256 _period)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Cannot have 0 period");
    fastAveragePeriod = _period;
    emit SetFastAveragePeriod(_period);
  }

  function setBandLimits(uint256 _upper, uint256 _lower)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_upper != 0 && _lower != 0, "Cannot have 0 band limit");
    upperBandLimitBps = _upper;
    lowerBandLimitBps = _lower;
    emit SetBandLimits(_upper, _lower);
  }

  function setSlippageBps(uint256 _slippageBps)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_slippageBps <= 10000, "slippage: Must be <= 100%");
    sampleSlippageBps = _slippageBps;
    emit SetSlippageBps(_slippageBps);
  }

  function setSkipAuctionThreshold(uint256 _skipAuctionThreshold)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    skipAuctionThreshold = _skipAuctionThreshold;
    emit SetSkipAuctionThreshold(_skipAuctionThreshold);
  }

  function setEmergencyMintLookback(uint256 _lookback)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_lookback != 0, "Lookback cannot be 0");
    emergencyMintLookback = _lookback;
    emit SetEmergencyMintLookback(_lookback);
  }

  function setEmergencyMintThresholdBps(uint256 _thresholdBps)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_thresholdBps < 10000, "Cannot be above 100%");
    emergencyMintThresholdBps = _thresholdBps;
    emit SetEmergencyMintThresholdBps(_thresholdBps);
  }

  function setTrackingBackoff(uint256 _backoff)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    require(_backoff != 0, "Cannot be 0");
    trackingBackoff = _backoff;
    emit SetTrackingBackoff(_backoff);
  }

  function setTrackAfterStabilize(bool _track)
    external
    onlyRoleYsd(ADMIN_ROLE, "Must have admin role")
  {
    trackAfterStabilize = _track;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @title Permissions
/// @author 0xBrains <0xbrains.eth>
/// @notice Inherited by almost all Ysd contracts to provide access control
contract Permissions is AccessControl, ReentrancyGuard {
  using SafeERC20 for ERC20;

  // Timelock has absolute power across the system
  bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

  // Contract types
  bytes32 public constant STABILIZER_NODE_ROLE = keccak256("STABILIZER_NODE_ROLE");
  bytes32 public constant LIQUIDITY_MINE_ROLE = keccak256("LIQUIDITY_MINE_ROLE");
  bytes32 public constant AUCTION_ROLE = keccak256("AUCTION_ROLE");
  bytes32 public constant REWARD_THROTTLE_ROLE = keccak256("REWARD_THROTTLE_ROLE");
  bytes32 public constant INTERNAL_WHITELIST_ROLE = keccak256("INTERNAL_WHITELIST_ROLE");

  address public proposedAdmin;
  address internal globalAdmin;

  event reassignGlobalAdminProposed(address newAdmin, address sender);
  event reassignGlobalAdminAccepted(address newAdmin);

  function _adminSetup(address _timelock) internal {
    require(_timelock != address(0), "Perm: Admin setup 0x0");
    _roleSetup(TIMELOCK_ROLE, _timelock);
    _roleSetup(ADMIN_ROLE, _timelock);
    _roleSetup(GOVERNOR_ROLE, _timelock);
    _roleSetup(STABILIZER_NODE_ROLE, _timelock);
    _roleSetup(LIQUIDITY_MINE_ROLE, _timelock);
    _roleSetup(AUCTION_ROLE, _timelock);
    _roleSetup(REWARD_THROTTLE_ROLE, _timelock);
    _roleSetup(INTERNAL_WHITELIST_ROLE, _timelock);

    globalAdmin = _timelock;
  }

  function assignRole(bytes32 role, address _assignee)
    external
    onlyRoleYsd(getRoleAdmin(role), "Only role admin")
  {
    _grantRole(role, _assignee);
  }

  function removeRole(bytes32 role, address _entity)
    external
    onlyRoleYsd(getRoleAdmin(role), "Only role admin")
  {
    revokeRole(role, _entity);
  }

  function grantRoleMultiple(bytes32 role, address[] calldata addresses)
    external
    onlyRoleYsd(getRoleAdmin(role), "Only role admin")
  {
    uint256 length = addresses.length;
    for (uint i; i < length; ++i) {
      address account = addresses[i];
      require(account != address(0), "0x0");
      _grantRole(role, account);
    }
  }

  function reassignGlobalAdmin(address _admin)
    external
    onlyRoleYsd(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(_admin != address(0), "Perm: Reassign to 0x0");
    proposedAdmin = _admin;
    _grantRole(ADMIN_ROLE, proposedAdmin);
    emit reassignGlobalAdminProposed(_admin, msg.sender);
  }

  function acceptGlobalAdmin() external {
    require(proposedAdmin == msg.sender, "Perm: Not allowed to reassign");
    // give admin role to new admin so he can transfer roles from old admin
    _transferRole(proposedAdmin, globalAdmin, TIMELOCK_ROLE);
    _transferRole(proposedAdmin, globalAdmin, ADMIN_ROLE);
    _transferRole(proposedAdmin, globalAdmin, GOVERNOR_ROLE);
    _transferRole(proposedAdmin, globalAdmin, STABILIZER_NODE_ROLE);
    _transferRole(proposedAdmin, globalAdmin, LIQUIDITY_MINE_ROLE);
    _transferRole(proposedAdmin, globalAdmin, AUCTION_ROLE);
    _transferRole(proposedAdmin, globalAdmin, REWARD_THROTTLE_ROLE);

    globalAdmin = proposedAdmin;
    proposedAdmin = address(0x0);
    emit reassignGlobalAdminAccepted(globalAdmin);
  }

  function emergencyWithdrawGAS(address payable destination)
    external
    onlyRoleYsd(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of the Gas token to destination
    (bool success, ) = destination.call{value: address(this).balance}('');
    require(success, "emergencyWithdrawGAS error");
  }

  function emergencyWithdraw(address _token, address destination)
    external
    onlyRoleYsd(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    // Transfers the entire balance of an ERC20 token at _token to destination
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, token.balanceOf(address(this)));
  }

  function partialWithdrawGAS(address payable destination, uint256 amount)
    external
    onlyRoleYsd(TIMELOCK_ROLE, "Must have timelock role")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    (bool success, ) = destination.call{value: amount}('');
    require(success, "partialWithdrawGAS error");
  }

  function partialWithdraw(address _token, address destination, uint256 amount)
    external
    onlyRoleYsd(TIMELOCK_ROLE, "Only timelock can assign roles")
  {
    require(destination != address(0), "Withdraw: addr(0)");
    ERC20 token = ERC20(_token);
    token.safeTransfer(destination, amount);
  }

  /*
   * INTERNAL METHODS
   */
  function _transferRole(address newAccount, address oldAccount, bytes32 role) internal {
    revokeRole(role, oldAccount);
    _grantRole(role, newAccount);
  }

  function _roleSetup(bytes32 role, address account) internal {
    _grantRole(role, account);
    _setRoleAdmin(role, ADMIN_ROLE);
  }

  function _onlyRoleYsd(bytes32 role, string memory reason) internal view {
    require(
      hasRole(
        role,
        _msgSender()
      ),
      reason
    );
  }

  // Using internal function calls here reduces compiled bytecode size
  modifier onlyRoleYsd(bytes32 role, string memory reason) {
    _onlyRoleYsd(role, reason);
    _;
  }

  // verifies that the caller is not a contract.
  modifier onlyEOA() {
    require(hasRole(INTERNAL_WHITELIST_ROLE, _msgSender()) || msg.sender == tx.origin, "Perm: Only EOA");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


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
  function averageYsdPrice(uint256 _id) external view returns (uint256);
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
    uint256[] memory exitedTokens,
    bool[] memory finished
  );
  function getAccountCommitmentAuctions(address account) external view returns (uint[] memory);
  function hasOngoingAuction() external view returns (bool);
  function getActiveAuction() external view returns (
    uint256 auctionId,
    uint256 maxCommitments,
    uint256 commitments,
    uint256 ysdPurchased,
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
    uint256 ysdPurchased,
    uint256 startingPrice,
    uint256 finalPrice,
    uint256 pegPrice,
    uint256 startingTime,
    uint256 endingTime,
    uint256 preAuctionReserveRatio,
    bool active
  );
  function checkAuctionFinalization() external;
  function allocateArbRewards(uint256 rewarded) external returns (uint256);
  function triggerAuction(uint256 pegPrice, uint256 purchaseAmount) external;
  function getAuctionParticipationForAccount(address account, uint256 auctionId) external view returns(uint256, uint256, uint256, uint256);
  function accountExit(address account, uint256 auctionId, uint256 amount) external;
  function endAuctionEarly() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IYsdDataLab {
  function priceTarget() external view returns (uint256);
  function smoothedYsdPrice() external view returns (uint256);
  function smoothedK() external view returns (uint256);
  function smoothedReserves() external view returns (uint256);
  function ysdPriceAverage(uint256 _lookback) external view returns (uint256);
  function kAverage(uint256 _lookback) external view returns (uint256);
  function poolReservesAverage(uint256 _lookback) external view returns (uint256, uint256);
  function lastYsdPrice() external view returns (uint256, uint64);
  function lastPoolReserves() external view returns (uint256, uint256, uint64);
  function lastK() external view returns (uint256, uint64);
  function realValueOfLPToken(uint256 amount) external view returns (uint256);
  function trackPool() external;
  function trustedTrackPool(uint256, uint256, uint256) external;
  function rewardToken() external view returns(address);
  function ysd() external view returns(address);
  function stakeToken() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IDAO {
  function epoch() external view returns (uint256);
  function epochLength() external view returns (uint256);
  function genesisTime() external view returns (uint256);
  function getEpochStartTime(uint256 _epoch) external view returns (uint256);
  function getLockedYsd(address account) external view returns (uint256);
  function epochsPerYear() external view returns (uint256);
  function advance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IRewardThrottle {
  function handleReward() external;
  function epochAPR(uint256 epoch) external view returns (uint256);
  function targetAPR() external view returns (uint256);
  function epochData(uint256 epoch) external view returns (
    uint256 profit,
    uint256 rewarded,
    uint256 bondedValue,
    uint256 throttle
  );
  function checkRewardUnderflow() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface ILiquidityExtension {
  function hasMinimumReserves() external view returns (bool);
  function collateralDeficit() external view returns (uint256, uint256);
  function reserveRatio() external view returns (uint256, uint256);
  function reserveRatioAverage(uint256) external view returns (uint256, uint256);
  function purchaseAndBurn(uint256 amount) external returns (uint256 purchased);
  function buyBack(uint256 ysdAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IImpliedCollateralService {
  function handleDeficit(uint256 maxAmount) external;
  function claim() external;
  function getCollateralValueInYsd() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IDexHandler {
  function buyYsd(uint256, uint256) external returns (uint256 purchased);
  function sellYsd(uint256, uint256) external returns (uint256 rewards);
  function addLiquidity(uint256, uint256, uint256) external returns (
    uint256 ysdUsed,
    uint256 rewardUsed,
    uint256 liquidityCreated
  );
  function removeLiquidity(uint256, uint256) external returns (uint256 amountYsd, uint256 amountReward);
  function calculateMintingTradeSize(uint256 priceTarget) external view returns (uint256);
  function calculateBurningTradeSize(uint256 priceTarget) external view returns (uint256);
  function reserves() external view returns (uint256 ysdSupply, uint256 rewardSupply);
  function ysdMarketPrice() external view returns (uint256 price, uint256 decimals);
  function getOptimalLiquidity(address tokenA, address tokenB, uint256 liquidityB)
    external view returns (uint256 liquidityA);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface ISwingTrader {
  function buyYsd(uint256 maxCapital) external returns (uint256 capitalUsed);
  function sellYsd(uint256 maxAmount) external returns (uint256 amountSold);
  function costBasis() external view returns (uint256 cost, uint256 decimals);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface ISupplyDistributionController {
  function check() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;


interface IAuctionStartController {
  function checkForStart() external view returns(bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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