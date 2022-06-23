// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IMasonry.sol";

// solhint-disable max-states-count, not-rely-on-time, no-empty-blocks, reason-string
contract Treasury is ContractGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========= CONSTANT VARIABLES ======== */

  // TODO: Update PERIOD (default is 6h)
  uint256 public constant PERIOD = 10 minutes;

  /* ========== STATE VARIABLES ========== */

  // governance
  address public operator;

  // flags
  bool public initialized = false;

  // epoch
  uint256 public startTime;
  uint256 public epoch = 0;
  uint256 public epochSupplyContractionLeft = 0;

  // exclusions from total supply
  // Add PawGenesisPool, PawRewardPool
  address[] public excludedFromTotalSupply;

  // core components
  address public paw;
  address public bone;
  address public pod;

  address public masonry;
  address public pawOracle;

  // price
  uint256 public pawPriceOne;
  uint256 public pawPriceCeiling;

  uint256 public seigniorageSaved;

  uint256[] public supplyTiers;
  uint256[] public maxExpansionTiers;

  uint256 public maxSupplyExpansionPercent;
  uint256 public boneDepletionFloorPercent;
  uint256 public seigniorageExpansionFloorPercent;
  uint256 public maxSupplyContractionPercent;
  uint256 public maxDebtRatioPercent;

  // 28 first epochs (1 week) with 4.5% expansion regardless of Paw price
  uint256 public bootstrapEpochs;
  uint256 public bootstrapSupplyExpansionPercent;

  /* =================== Added variables =================== */
  uint256 public previousEpochPawPrice;
  uint256 public maxDiscountRate; // when purchasing bone
  uint256 public maxPremiumRate; // when redeeming bone
  uint256 public discountPercent;
  uint256 public premiumThreshold;
  uint256 public premiumPercent;
  uint256 public mintingFactorForPayingDebt; // print extra Paw during debt phase

  address public daoFund;
  uint256 public daoFundSharedPercent;

  address public devFund;
  uint256 public devFundSharedPercent;

  /* =================== Events =================== */

  event Initialized(address indexed executor, uint256 at);
  event BurnedBones(address indexed from, uint256 boneAmount);
  event RedeemedBones(address indexed from, uint256 pawAmount, uint256 boneAmount);
  event BoughtBones(address indexed from, uint256 pawAmount, uint256 boneAmount);
  event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
  event MasonryFunded(uint256 timestamp, uint256 seigniorage);
  event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
  event DevFundFunded(uint256 timestamp, uint256 seigniorage);

  /* =================== Modifier =================== */

  modifier onlyOperator() {
    require(operator == msg.sender, "Treasury: caller is not the operator");
    _;
  }

  modifier checkCondition() {
    require(block.timestamp >= startTime, "Treasury: not started yet");

    _;
  }

  modifier checkEpoch() {
    require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

    _;

    epoch = epoch.add(1);
    epochSupplyContractionLeft = (getPawPrice() > pawPriceCeiling)
      ? 0
      : getPawCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
  }

  modifier checkOperator() {
    require(
      IBasisAsset(paw).operator() == address(this) &&
        IBasisAsset(bone).operator() == address(this) &&
        IBasisAsset(pod).operator() == address(this) &&
        Operator(masonry).operator() == address(this),
      "Treasury: need more permission"
    );

    _;
  }

  modifier notInitialized() {
    require(!initialized, "Treasury: already initialized");

    _;
  }

  /* ========== VIEW FUNCTIONS ========== */

  function isInitialized() public view returns (bool) {
    return initialized;
  }

  // epoch
  function nextEpochPoint() public view returns (uint256) {
    return startTime.add(epoch.mul(PERIOD));
  }

  // oracle
  function getPawPrice() public view returns (uint256 pawPrice) {
    try IOracle(pawOracle).consult(paw, 1e18) returns (uint144 price) {
      return uint256(price);
    } catch {
      revert("Treasury: failed to consult Paw price from the oracle");
    }
  }

  function getPawUpdatedPrice() public view returns (uint256 _pawPrice) {
    try IOracle(pawOracle).twap(paw, 1e18) returns (uint144 price) {
      return uint256(price);
    } catch {
      revert("Treasury: failed to consult Paw price from the oracle");
    }
  }

  // budget
  function getReserve() public view returns (uint256) {
    return seigniorageSaved;
  }

  function getBurnablePawLeft() public view returns (uint256 _burnablePawLeft) {
    uint256 _pawPrice = getPawPrice();
    if (_pawPrice <= pawPriceOne) {
      uint256 _pawSupply = getPawCirculatingSupply();
      uint256 _boneMaxSupply = _pawSupply.mul(maxDebtRatioPercent).div(10000);
      uint256 _boneSupply = IERC20(bone).totalSupply();
      if (_boneMaxSupply > _boneSupply) {
        uint256 _maxMintableBone = _boneMaxSupply.sub(_boneSupply);
        uint256 _maxBurnablePaw = _maxMintableBone.mul(_pawPrice).div(1e18);
        _burnablePawLeft = Math.min(epochSupplyContractionLeft, _maxBurnablePaw);
      }
    }
  }

  function getRedeemableBones() public view returns (uint256 _redeemableBones) {
    uint256 _pawPrice = getPawPrice();
    if (_pawPrice > pawPriceCeiling) {
      uint256 _totalPaw = IERC20(paw).balanceOf(address(this));
      uint256 _rate = getBonePremiumRate();
      if (_rate > 0) {
        _redeemableBones = _totalPaw.mul(1e18).div(_rate);
      }
    }
  }

  function getBoneDiscountRate() public view returns (uint256 _rate) {
    uint256 _pawPrice = getPawPrice();
    if (_pawPrice <= pawPriceOne) {
      if (discountPercent == 0) {
        // no discount
        _rate = pawPriceOne;
      } else {
        uint256 _boneAmount = pawPriceOne.mul(1e18).div(_pawPrice); // to burn 1 Paw
        uint256 _discountAmount = _boneAmount.sub(pawPriceOne).mul(discountPercent).div(10000);
        _rate = pawPriceOne.add(_discountAmount);
        if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
          _rate = maxDiscountRate;
        }
      }
    }
  }

  function getBonePremiumRate() public view returns (uint256 _rate) {
    uint256 _pawPrice = getPawPrice();
    if (_pawPrice > pawPriceCeiling) {
      uint256 _pawPricePremiumThreshold = pawPriceOne.mul(premiumThreshold).div(100);
      if (_pawPrice >= _pawPricePremiumThreshold) {
        //Price > 1.10
        uint256 _premiumAmount = _pawPrice.sub(pawPriceOne).mul(premiumPercent).div(10000);
        _rate = pawPriceOne.add(_premiumAmount);
        if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
          _rate = maxPremiumRate;
        }
      } else {
        // no premium bonus
        _rate = pawPriceOne;
      }
    }
  }

  /* ========== GOVERNANCE ========== */

  function initialize(
    address _paw,
    address _bone,
    address _pod,
    address _pawOracle,
    address _masonry,
    uint256 _startTime,
    address[] memory _excludedFromTotalSupply
  ) public notInitialized {
    paw = _paw;
    bone = _bone;
    pod = _pod;
    pawOracle = _pawOracle;
    masonry = _masonry;
    startTime = _startTime;

    excludedFromTotalSupply = _excludedFromTotalSupply;
    pawPriceOne = 10**18;
    pawPriceCeiling = pawPriceOne.mul(101).div(100);

    // Dynamic max expansion percent
    supplyTiers = [
      0 ether,
      500000 ether,
      1000000 ether,
      1500000 ether,
      2000000 ether,
      5000000 ether,
      10000000 ether,
      20000000 ether,
      50000000 ether
    ];
    maxExpansionTiers = [450, 400, 350, 300, 250, 200, 150, 125, 100];

    maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

    boneDepletionFloorPercent = 10000; // 100% of Bone supply for depletion floor
    seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for masonry
    maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn Paw and mint tBONE)
    maxDebtRatioPercent = 3500; // Upto 35% supply of tBONE to purchase

    premiumThreshold = 110;
    premiumPercent = 7000;

    // First 28 epochs with 4.5% expansion
    // TODO: Update bootstrapEpochs, paw default is 28
    bootstrapEpochs = 0;
    bootstrapSupplyExpansionPercent = 450;

    // set seigniorageSaved to it's balance
    seigniorageSaved = IERC20(paw).balanceOf(address(this));

    initialized = true;
    operator = msg.sender;
    emit Initialized(msg.sender, block.number);
  }

  function setOperator(address _operator) external onlyOperator {
    operator = _operator;
  }

  function setMasonry(address _masonry) external onlyOperator {
    masonry = _masonry;
  }

  function setPawOracle(address _pawOracle) external onlyOperator {
    pawOracle = _pawOracle;
  }

  function setPawPriceCeiling(uint256 _pawPriceCeiling) external onlyOperator {
    require(
      _pawPriceCeiling >= pawPriceOne && _pawPriceCeiling <= pawPriceOne.mul(120).div(100),
      "out of range"
    ); // [$1.0, $1.2]
    pawPriceCeiling = _pawPriceCeiling;
  }

  function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
    require(
      _maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000,
      "_maxSupplyExpansionPercent: out of range"
    ); // [0.1%, 10%]
    maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
  }

  function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
    require(_index >= 0, "Index has to be higher than 0");
    require(_index < 9, "Index has to be lower than count of tiers");
    if (_index > 0) {
      require(_value > supplyTiers[_index - 1]);
    }
    if (_index < 8) {
      require(_value < supplyTiers[_index + 1]);
    }
    supplyTiers[_index] = _value;
    return true;
  }

  function setMaxExpansionTiersEntry(uint8 _index, uint256 _value)
    external
    onlyOperator
    returns (bool)
  {
    require(_index >= 0, "Index has to be higher than 0");
    require(_index < 9, "Index has to be lower than count of tiers");
    require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
    maxExpansionTiers[_index] = _value;
    return true;
  }

  function setBoneDepletionFloorPercent(uint256 _boneDepletionFloorPercent) external onlyOperator {
    require(
      _boneDepletionFloorPercent >= 500 && _boneDepletionFloorPercent <= 10000,
      "out of range"
    ); // [5%, 100%]
    boneDepletionFloorPercent = _boneDepletionFloorPercent;
  }

  function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent)
    external
    onlyOperator
  {
    require(
      _maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500,
      "out of range"
    ); // [0.1%, 15%]
    maxSupplyContractionPercent = _maxSupplyContractionPercent;
  }

  function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
    require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
    maxDebtRatioPercent = _maxDebtRatioPercent;
  }

  function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent)
    external
    onlyOperator
  {
    require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
    require(
      _bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000,
      "_bootstrapSupplyExpansionPercent: out of range"
    ); // [1%, 10%]
    bootstrapEpochs = _bootstrapEpochs;
    bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
  }

  function setExtraFunds(
    address _daoFund,
    uint256 _daoFundSharedPercent,
    address _devFund,
    uint256 _devFundSharedPercent
  ) external onlyOperator {
    require(_daoFund != address(0), "zero");
    require(_daoFundSharedPercent <= 3000, "out of range"); // <= 30%
    require(_devFund != address(0), "zero");
    require(_devFundSharedPercent <= 1000, "out of range"); // <= 10%
    daoFund = _daoFund;
    daoFundSharedPercent = _daoFundSharedPercent;
    devFund = _devFund;
    devFundSharedPercent = _devFundSharedPercent;
  }

  function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
    maxDiscountRate = _maxDiscountRate;
  }

  function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
    maxPremiumRate = _maxPremiumRate;
  }

  function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
    require(_discountPercent <= 20000, "_discountPercent is over 200%");
    discountPercent = _discountPercent;
  }

  function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
    require(_premiumThreshold >= pawPriceCeiling, "_premiumThreshold exceeds pawPriceCeiling");
    require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
    premiumThreshold = _premiumThreshold;
  }

  function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
    require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
    premiumPercent = _premiumPercent;
  }

  function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt)
    external
    onlyOperator
  {
    require(
      _mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000,
      "_mintingFactorForPayingDebt: out of range"
    ); // [100%, 200%]
    mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
  }

  /* ========== MUTABLE FUNCTIONS ========== */

  function _updatePawPrice() internal {
    try IOracle(pawOracle).update() {} catch {}
  }

  function getPawCirculatingSupply() public view returns (uint256) {
    IERC20 pawErc20 = IERC20(paw);
    uint256 totalSupply = pawErc20.totalSupply();
    uint256 balanceExcluded = 0;
    for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
      balanceExcluded = balanceExcluded.add(pawErc20.balanceOf(excludedFromTotalSupply[entryId]));
    }
    return totalSupply.sub(balanceExcluded);
  }

  function buyBones(uint256 _pawAmount, uint256 targetPrice)
    external
    onlyOneBlock
    checkCondition
    checkOperator
  {
    require(_pawAmount > 0, "Treasury: cannot purchase bones with zero amount");

    uint256 pawPrice = getPawPrice();
    require(pawPrice == targetPrice, "Treasury: Paw price moved");
    require(
      pawPrice < pawPriceOne, // price < $1
      "Treasury: pawPrice not eligible for bone purchase"
    );

    require(_pawAmount <= epochSupplyContractionLeft, "Treasury: not enough bone left to purchase");

    uint256 _rate = getBoneDiscountRate();
    require(_rate > 0, "Treasury: invalid bone rate");

    uint256 _boneAmount = _pawAmount.mul(_rate).div(1e18);
    uint256 pawSupply = getPawCirculatingSupply();
    uint256 newBoneSupply = IERC20(bone).totalSupply().add(_boneAmount);
    require(newBoneSupply <= pawSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

    IBasisAsset(paw).burnFrom(msg.sender, _pawAmount);
    IBasisAsset(bone).mint(msg.sender, _boneAmount);

    epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_pawAmount);
    _updatePawPrice();

    emit BoughtBones(msg.sender, _pawAmount, _boneAmount);
  }

  function redeemBones(uint256 _boneAmount, uint256 targetPrice)
    external
    onlyOneBlock
    checkCondition
    checkOperator
  {
    require(_boneAmount > 0, "Treasury: cannot redeem bones with zero amount");

    uint256 pawPrice = getPawPrice();
    require(pawPrice == targetPrice, "Treasury: Paw price moved");
    require(
      pawPrice > pawPriceCeiling, // price > $1.01
      "Treasury: pawPrice not eligible for bone purchase"
    );

    uint256 _rate = getBonePremiumRate();
    require(_rate > 0, "Treasury: invalid bone rate");

    uint256 _pawAmount = _boneAmount.mul(_rate).div(1e18);
    require(
      IERC20(paw).balanceOf(address(this)) >= _pawAmount,
      "Treasury: treasury has no more budget"
    );

    seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _pawAmount));

    IBasisAsset(bone).burnFrom(msg.sender, _boneAmount);
    IERC20(paw).safeTransfer(msg.sender, _pawAmount);

    _updatePawPrice();

    emit RedeemedBones(msg.sender, _pawAmount, _boneAmount);
  }

  function _sendToMasonry(uint256 _amount) internal {
    IBasisAsset(paw).mint(address(this), _amount);

    uint256 _daoFundSharedAmount = 0;
    if (daoFundSharedPercent > 0) {
      _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
      IERC20(paw).transfer(daoFund, _daoFundSharedAmount);
      emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
    }

    uint256 _devFundSharedAmount = 0;
    if (devFundSharedPercent > 0) {
      // solhint-disable-next-line reentrancy
      _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
      IERC20(paw).transfer(devFund, _devFundSharedAmount);
      emit DevFundFunded(block.timestamp, _devFundSharedAmount);
    }

    _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);

    IERC20(paw).safeApprove(masonry, 0);
    IERC20(paw).safeApprove(masonry, _amount);
    IMasonry(masonry).allocateSeigniorage(_amount);
    emit MasonryFunded(block.timestamp, _amount);
  }

  function _calculateMaxSupplyExpansionPercent(uint256 _pawSupply) internal returns (uint256) {
    for (uint8 tierId = 8; tierId >= 0; --tierId) {
      if (_pawSupply >= supplyTiers[tierId]) {
        maxSupplyExpansionPercent = maxExpansionTiers[tierId];
        break;
      }
    }
    return maxSupplyExpansionPercent;
  }

  function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
    _updatePawPrice();
    previousEpochPawPrice = getPawPrice();
    uint256 pawSupply = getPawCirculatingSupply().sub(seigniorageSaved);
    if (epoch < bootstrapEpochs) {
      // 28 first epochs with 4.5% expansion
      _sendToMasonry(pawSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
    } else {
      if (previousEpochPawPrice > pawPriceCeiling) {
        // Expansion ($Paw Price > 1 $FTM): there is some seigniorage to be allocated
        uint256 boneSupply = IERC20(bone).totalSupply();
        uint256 _percentage = previousEpochPawPrice.sub(pawPriceOne);
        uint256 _savedForBone;
        uint256 _savedForMasonry;
        uint256 _mse = _calculateMaxSupplyExpansionPercent(pawSupply).mul(1e14);
        if (_percentage > _mse) {
          _percentage = _mse;
        }
        if (seigniorageSaved >= boneSupply.mul(boneDepletionFloorPercent).div(10000)) {
          // saved enough to pay debt, mint as usual rate
          _savedForMasonry = pawSupply.mul(_percentage).div(1e18);
        } else {
          // have not saved enough to pay debt, mint more
          uint256 _seigniorage = pawSupply.mul(_percentage).div(1e18);
          _savedForMasonry = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
          _savedForBone = _seigniorage.sub(_savedForMasonry);
          if (mintingFactorForPayingDebt > 0) {
            _savedForBone = _savedForBone.mul(mintingFactorForPayingDebt).div(10000);
          }
        }
        if (_savedForMasonry > 0) {
          _sendToMasonry(_savedForMasonry);
        }
        if (_savedForBone > 0) {
          seigniorageSaved = seigniorageSaved.add(_savedForBone);
          IBasisAsset(paw).mint(address(this), _savedForBone);
          emit TreasuryFunded(block.timestamp, _savedForBone);
        }
      }
    }
  }

  function governanceRecoverUnsupported(
    IERC20 _token,
    uint256 _amount,
    address _to
  ) external onlyOperator {
    // do not allow to drain core tokens
    require(address(_token) != address(paw), "paw");
    require(address(_token) != address(bone), "bone");
    require(address(_token) != address(pod), "pod");
    _token.safeTransfer(_to, _amount);
  }

  function masonrySetOperator(address _operator) external onlyOperator {
    IMasonry(masonry).setOperator(_operator);
  }

  function masonrySetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs)
    external
    onlyOperator
  {
    IMasonry(masonry).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
  }

  function masonryAllocateSeigniorage(uint256 amount) external onlyOperator {
    IMasonry(masonry).allocateSeigniorage(amount);
  }

  function masonryGovernanceRecoverUnsupported(
    address _token,
    uint256 _amount,
    address _to
  ) external onlyOperator {
    IMasonry(masonry).governanceRecoverUnsupported(_token, _amount, _to);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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

pragma solidity 0.8.9;

library Babylonian {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            "operator: zero address given for new operator"
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        // solhint-disable-next-line avoid-tx-origin
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            "ContractGuard: one block, one function"
        );
        require(
            !checkSameSenderReentranted(),
            "ContractGuard: one block, one function"
        );

        _;

        // solhint-disable-next-line avoid-tx-origin
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn)
        external
        view
        returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn)
        external
        view
        returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasonry {
  function balanceOf(address _mason) external view returns (uint256);

  function earned(address _mason) external view returns (uint256);

  function canWithdraw(address _mason) external view returns (bool);

  function canClaimReward(address _mason) external view returns (bool);

  function epoch() external view returns (uint256);

  function nextEpochPoint() external view returns (uint256);

  function getPawPrice() external view returns (uint256);

  function setOperator(address _operator) external;

  function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

  function stake(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function exit() external;

  function claimReward() external;

  function allocateSeigniorage(uint256 _amount) external;

  function governanceRecoverUnsupported(
    address _token,
    uint256 _amount,
    address _to
  ) external;
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