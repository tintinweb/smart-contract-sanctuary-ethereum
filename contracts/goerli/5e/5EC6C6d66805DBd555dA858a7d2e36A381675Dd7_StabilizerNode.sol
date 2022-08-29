pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "./Permissions.sol";
import "./interfaces/IAuction.sol";
import "./interfaces/IMaltDataLab.sol";
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
/// @author 0xScotch <[email protected]>
/// @notice The backbone of the Malt stability system. In charge of triggering actions to stabilize price
contract StabilizerNode is Initializable, Permissions {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  uint256 internal stabilizeWindowEnd;
  uint256 public stabilizeBackoffPeriod = 5 * 60; // 5 minutes
  uint256 public upperStabilityThreshold = (10**18) / 100; // 1%
  uint256 public lowerStabilityThreshold = (10**18) / 100;
  uint256 public maxContributionBps = 70;
  uint256 public priceAveragePeriod = 5 minutes;
  uint256 public fastAveragePeriod = 30; // 30 seconds
  uint256 public overrideDistance = 20; // 2%

  uint256 public expansionDampingFactor = 1;

  uint256 public defaultIncentive = 100;

  uint256 public daoRewardCut;
  uint256 public lpRewardCut = 417;
  uint256 public auctionPoolRewardCut = 113;
  uint256 public swingTraderRewardCut = 417;
  uint256 public treasuryRewardCut = 50;
  uint256 public callerRewardCut = 3;

  uint256 public lastStabilize;

  ERC20 public rewardToken;
  IBurnMintableERC20 public malt;
  IAuction public auction;
  IDexHandler public dexHandler;
  IDAO public dao;
  address public uniswapV2Factory;
  ILiquidityExtension public liquidityExtension;
  IMaltDataLab public maltDataLab;
  IAuctionBurnReserveSkew public auctionBurnReserveSkew;
  IRewardThrottle public rewardThrottle;
  ISwingTrader public swingTrader;
  IImpliedCollateralService public impliedCollateralService;

  address payable public treasuryMultisig;
  address public auctionPool;
  address public supplyDistributionController;
  address public auctionStartController;

  event MintMalt(uint256 amount);
  event Stabilize(uint256 timestamp, uint256 exchangeRate);
  event RewardDistribution(uint256 rewarded);
  event SetAnnualYield(uint256 yield);
  event SetStabilizeBackoff(uint256 period);
  event SetAuctionBurnSkew(address auctionBurnReserveSkew);
  event SetRewardCut(uint256 daoCut, uint256 lpCut, uint256 callerCut, uint256 treasuryCut, uint256 auctionPoolCut, uint256 swingTraderCut);
  event SetTreasury(address newTreasury);
  event SetDefaultIncentive(uint256 incentive);
  event SetExpansionDamping(uint256 amount);
  event SetNewMaltDataLab(address dataLab);
  event SetAuctionContract(address auction);
  event SetDexHandler(address dexHandler);
  event SetDao(address dao);
  event SetLiquidityExtension(address liquidityExtension);
  event SetRewardThrottle(address rewardThrottle);
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

  function initialize(
    address _timelock,
    address initialAdmin,
    address _rewardToken,
    address _malt,
    address _auction,
    address _uniswapV2Factory,
    address payable _treasuryMultisig,
    address _auctionPool
  ) external initializer {
    _adminSetup(_timelock);

    _setupRole(ADMIN_ROLE, initialAdmin);
    _setupRole(AUCTION_ROLE, _auction);

    rewardToken = ERC20(_rewardToken);
    malt = IBurnMintableERC20(_malt);
    auction = IAuction(_auction);

    uniswapV2Factory = _uniswapV2Factory;
    treasuryMultisig = _treasuryMultisig;
    auctionPool = _auctionPool;

    lastStabilize = block.timestamp;
  }

  function setupContracts(
    address _dexHandler,
    address _maltDataLab,
    address _auctionBurnReserveSkew,
    address _rewardThrottle,
    address _dao,
    address _swingTrader,
    address _liquidityExtension,
    address _impliedCollateralService
  ) external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    dexHandler = IDexHandler(_dexHandler);
    maltDataLab = IMaltDataLab(_maltDataLab);
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_auctionBurnReserveSkew);
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    dao = IDAO(_dao);
    swingTrader = ISwingTrader(_swingTrader);
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
  }

  function stabilize() external notSameBlock {
    auction.checkAuctionFinalization();

    require(
      block.timestamp >= stabilizeWindowEnd || _stabilityWindowOverride(),
      "Can't call stabilize"
    );
    stabilizeWindowEnd = block.timestamp + stabilizeBackoffPeriod;

    rewardThrottle.checkRewardUnderflow();

    uint256 exchangeRate = maltDataLab.maltPriceAverage(priceAveragePeriod);

    if (!_shouldAdjustSupply(exchangeRate)) {
      maltDataLab.trackReserveRatio();

      lastStabilize = block.timestamp;
      return;
    }

    emit Stabilize(block.timestamp, exchangeRate);

    if (exchangeRate > maltDataLab.priceTarget()) {
      _distributeSupply();
    } else {
      _startAuction();
    }

    lastStabilize = block.timestamp;
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

    uint256 priceTarget = maltDataLab.priceTarget();
    uint256 exchangeRate = maltDataLab.maltPriceAverage(fastAveragePeriod);

    uint256 upperThreshold = priceTarget.mul(1000 + overrideDistance).div(1000);
    uint256 lowerThreshold = priceTarget.mul(1000 - overrideDistance).div(1000);

    return exchangeRate <= lowerThreshold || exchangeRate >= upperThreshold;
  }

  function _shouldAdjustSupply(uint256 exchangeRate) internal view returns (bool) {
    uint256 decimals = rewardToken.decimals();
    uint256 priceTarget = maltDataLab.priceTarget();

    uint256 upperThreshold = priceTarget.mul(upperStabilityThreshold).div(10**decimals);
    uint256 lowerThreshold = priceTarget.mul(lowerStabilityThreshold).div(10**decimals);

    return (exchangeRate <= priceTarget.sub(lowerThreshold) && !auction.auctionActive(auction.currentAuctionId())) || exchangeRate >= priceTarget.add(upperThreshold);
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

    uint256 priceTarget = maltDataLab.priceTarget();
    uint256 tradeSize = dexHandler.calculateMintingTradeSize(priceTarget).div(expansionDampingFactor);

    if (tradeSize == 0) {
      return;
    }

    uint256 swingAmount = swingTrader.sellMalt(tradeSize);

    if (swingAmount >= tradeSize) {
      return;
    }

    tradeSize = tradeSize - swingAmount;

    malt.mint(address(dexHandler), tradeSize);
    emit MintMalt(tradeSize);
    uint256 rewards = dexHandler.sellMalt();

    auctionBurnReserveSkew.addAbovePegObservation(tradeSize);

    uint256 remaining = _replenishLiquidityExtension(rewards);

    _distributeRewards(remaining);

    maltDataLab.trackReserveRatio();
    impliedCollateralService.claim();
  }

  function _distributeRewards(uint256 rewarded) internal {
    if (rewarded == 0) {
      return;
    }
    rewardToken.approve(address(auction), rewarded);
    rewarded = auction.allocateArbRewards(rewarded);

    if (rewarded == 0) {
      return;
    }

    uint256 callerCut = rewarded.mul(callerRewardCut).div(1000);
    uint256 lpCut = rewarded.mul(lpRewardCut).div(1000);
    uint256 daoCut = rewarded.mul(daoRewardCut).div(1000);
    uint256 auctionPoolCut = rewarded.mul(auctionPoolRewardCut).div(1000);
    uint256 swingTraderCut = rewarded.mul(swingTraderRewardCut).div(1000);

    // Treasury gets paid after everyone else
    uint256 treasuryCut = rewarded - daoCut - lpCut - callerCut - auctionPoolCut - swingTraderCut;

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

    emit RewardDistribution(rewarded);
  }

  function _replenishLiquidityExtension(uint256 rewards) internal returns (uint256 remaining) {
    if (liquidityExtension.hasMinimumReserves() || rewards == 0) {
      return rewards;
    }

    (uint256 deficit,) = liquidityExtension.collateralDeficit();

    uint256 maxContrib = rewards.mul(maxContributionBps).div(100);

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

    uint256 priceTarget = maltDataLab.priceTarget();
    uint256 purchaseAmount = dexHandler.calculateBurningTradeSize(priceTarget);

    if (purchaseAmount == 0) {
      return;
    }

    uint256 decimals = rewardToken.decimals();

    uint256 amountUsed = swingTrader.buyMalt(purchaseAmount);

    purchaseAmount = purchaseAmount - amountUsed;

    if (purchaseAmount < 10**decimals) {
      return;
    }

    auction.triggerAuction(priceTarget, purchaseAmount);

    malt.mint(msg.sender, defaultIncentive*10**18);
    emit MintMalt(defaultIncentive*10**18);

    auctionBurnReserveSkew.addBelowPegObservation(purchaseAmount);

    maltDataLab.trackReserveRatio();
  }

  /*
   * PRIVILEDGED FUNCTIONS
   */
  function setStabilizeBackoff(uint256 _period)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Must be greater than 0");
    stabilizeBackoffPeriod = _period;
    emit SetStabilizeBackoff(_period);
  }

  function setAuctionBurnSkew(address _auctionBurnReserveSkew)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    auctionBurnReserveSkew = IAuctionBurnReserveSkew(_auctionBurnReserveSkew);
    emit SetAuctionBurnSkew(_auctionBurnReserveSkew);
  }

  function setRewardCut(
    uint256 _daoCut,
    uint256 _lpCut,
    uint256 _callerCut,
    uint256 _auctionPoolCut,
    uint256 _swingTraderCut
  )
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    uint256 sum = _daoCut.add(_lpCut).add(_callerCut).add(_auctionPoolCut).add(_swingTraderCut);
    require(sum <= 1000, "Reward cut must be <= 100%");
    daoRewardCut = _daoCut;
    lpRewardCut = _lpCut;
    callerRewardCut = _callerCut;
    auctionPoolRewardCut = _auctionPoolCut;
    swingTraderRewardCut = _swingTraderCut;
    treasuryRewardCut = 1000 - sum;

    emit SetRewardCut(_daoCut, _lpCut, _callerCut, treasuryRewardCut, _auctionPoolCut, _swingTraderCut);
  }

  function setTreasury(address payable _newTreasury)
    external
    onlyRole(TIMELOCK_ROLE, "Must have timelock role")
  {
    treasuryMultisig = _newTreasury;
    emit SetTreasury(_newTreasury);
  }

  function setDefaultIncentive(uint256 _incentive)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_incentive > 0, "No negative incentive");

    defaultIncentive = _incentive;

    emit SetDefaultIncentive(_incentive);
  }

  function setExpansionDamping(uint256 amount)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(amount > 0, "No negative damping");

    expansionDampingFactor = amount;
    emit SetExpansionDamping(amount);
  }

  function setNewDataLab(address _dataLab)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    maltDataLab = IMaltDataLab(_dataLab);
    emit SetNewMaltDataLab(_dataLab);
  }

  function setAuctionContract(address _auction)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
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
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_upper > 0 && _lower > 0, "Must be above 0");

    upperStabilityThreshold = _upper;
    lowerStabilityThreshold = _lower;
    emit SetStabilityThresholds(_upper, _lower);
  }

  function setAuctionPool(address _auctionPool)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_auctionPool != address(0), "Not address 0");

    auctionPool = _auctionPool;
    emit SetAuctionPool(_auctionPool);
  }

  function setSupplyDistributionController(address _controller)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    supplyDistributionController = _controller;
    emit SetSupplyDistributionController(_controller);
  }

  function setAuctionStartController(address _controller)
    external
    onlyRole(ADMIN_ROLE, "Must have admin privilege")
  {
    // This is allowed to be set to address(0) as its checked before calling methods on it
    auctionStartController = _controller;
    emit SetAuctionStartController(_controller);
  }

  function setMaxContribution(uint256 _maxContribution)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_maxContribution > 0 && _maxContribution <= 100, "Must be between 0 and 100");

    maxContributionBps = _maxContribution;
    emit SetMaxContribution(_maxContribution);
  }

  function setDexHandler(address _dexHandler)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_dexHandler != address(0), "Not address 0");
    dexHandler = IDexHandler(_dexHandler);
    emit SetDexHandler(_dexHandler);
  }

  function setDao(address _dao)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_dao != address(0), "Not address 0");
    dao = IDAO(_dao);
    emit SetDao(_dao);
  }

  function setLiquidityExtension(address _liquidityExtension)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_liquidityExtension != address(0), "Not address 0");
    liquidityExtension = ILiquidityExtension(_liquidityExtension);
    emit SetLiquidityExtension(_liquidityExtension);
  }

  function setRewardThrottle(address _rewardThrottle)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_rewardThrottle != address(0), "Not address 0");
    rewardThrottle = IRewardThrottle(_rewardThrottle);
    emit SetRewardThrottle(_rewardThrottle);
  }

  function setSwingTrader(address _swingTrader)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_swingTrader != address(0), "Not address 0");
    swingTrader = ISwingTrader(_swingTrader);
    emit SetSwingTrader(_swingTrader);
  }

  function setImpliedCollateralService(address _impliedCollateralService)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_impliedCollateralService != address(0), "Not address 0");
    impliedCollateralService = IImpliedCollateralService(_impliedCollateralService);
    emit SetImpliedCollateralService(_impliedCollateralService);
  }

  function setPriceAveragePeriod(uint256 _period)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Cannot have 0 period");
    priceAveragePeriod = _period;
    emit SetPriceAveragePeriod(_period);
  }

  function setOverrideDistance(uint256 _distance)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_distance > 0 && _distance < 1000, "Override must be between 0-100%");
    overrideDistance = _distance;
    emit SetOverrideDistance(_distance);
  }

  function setFastAveragePeriod(uint256 _period)
    external
    onlyRole(ADMIN_ROLE, "Must have admin role")
  {
    require(_period > 0, "Cannot have 0 period");
    fastAveragePeriod = _period;
    emit SetFastAveragePeriod(_period);
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

interface IDAO {
  function epoch() external view returns (uint256);
  function epochLength() external view returns (uint256);
  function genesisTime() external view returns (uint256);
  function getEpochStartTime(uint256 _epoch) external view returns (uint256);
  function getLockedMalt(address account) external view returns (uint256);
  function epochsPerYear() external view returns (uint256);
}

pragma solidity >=0.6.6;

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

interface ISwingTrader {
  function buyMalt(uint256 maxCapital) external returns (uint256 capitalUsed);
  function sellMalt(uint256 maxAmount) external returns (uint256 amountSold);
  function costBasis() external view returns (uint256 cost, uint256 decimals);
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

interface ISupplyDistributionController {
  function check() external view returns (bool);
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