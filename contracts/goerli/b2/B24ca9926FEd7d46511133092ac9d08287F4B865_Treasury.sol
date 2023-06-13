// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import { ITwapOracle } from "./interfaces/ITwapOracle.sol";
import { IAssetStrategy } from "./interfaces/IAssetStrategy.sol";
import { IFractionalToken } from "./interfaces/IFractionalToken.sol";
import { ILeveragedToken } from "./interfaces/ILeveragedToken.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { ITreasury } from "./interfaces/ITreasury.sol";

import { StableCoinMath } from "./StableCoinMath.sol";

// solhint-disable no-empty-blocks
// solhint-disable not-rely-on-time

contract Treasury is OwnableUpgradeable, ITreasury {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;
  using SignedSafeMathUpgradeable for int256;
  using StableCoinMath for StableCoinMath.SwapState;

  /**********
   * Events *
   **********/

  /// @notice Emitted when the whitelist status for settle is updated.
  /// @param account The address of account to change.
  /// @param status The new whitelist status.
  event UpdateSettleWhitelist(address account, bool status);

  /// @notice Emitted when the price oracle contract is updated.
  /// @param priceOracle The address of new price oracle.
  event UpdatePriceOracle(address priceOracle);

  /// @notice Emitted when the strategy contract is updated.
  /// @param strategy The address of new strategy.
  event UpdateStrategy(address strategy);

  /// @notice Emitted when the beta for fToken is updated.
  /// @param beta The new value of beta.
  event UpdateBeta(uint256 beta);

  /*************
   * Constants *
   *************/

  /// @dev The precision used to compute nav.
  uint256 private constant PRECISION = 1e18;

  /// @dev The precision used to compute nav.
  int256 private constant PRECISION_I256 = 1e18;

  /// @dev The initial mint ratio for fToken.
  uint256 private immutable initialMintRatio;

  /***********
   * Structs *
   ***********/

  struct TwapCache {
    uint128 price;
    uint128 timestamp;
  }

  /*************
   * Variables *
   *************/

  /// @notice The address of market contract.
  address public market;

  /// @inheritdoc ITreasury
  address public override baseToken;

  /// @inheritdoc ITreasury
  address public override fToken;

  /// @inheritdoc ITreasury
  address public override xToken;

  /// @notice The address of price oracle contract.
  address public priceOracle;

  /// @notice The volitality multiple of fToken compare to base token.
  uint256 public beta;

  /// @inheritdoc ITreasury
  uint256 public override lastPermissionedPrice;

  /// @inheritdoc ITreasury
  uint256 public override totalBaseToken;

  /// @inheritdoc ITreasury
  address public override strategy;

  /// @inheritdoc ITreasury
  uint256 public override strategyUnderlying;

  TwapCache public twapCache;

  /// @notice Whether the sender is allowed to do settlement.
  mapping(address => bool) public settleWhitelist;

  /************
   * Modifier *
   ************/

  modifier onlyMarket() {
    require(msg.sender == market, "Only market");
    _;
  }

  modifier onlyStrategy() {
    require(msg.sender == strategy, "Only strategy");
    _;
  }

  /***************
   * Constructor *
   ***************/

  constructor(uint256 _initialMintRatio) {
    require(0 < _initialMintRatio && _initialMintRatio < PRECISION, "invalid initial mint ratio");
    initialMintRatio = _initialMintRatio;
  }

  function initialize(
    address _market,
    address _baseToken,
    address _fToken,
    address _xToken,
    address _priceOracle,
    uint256 _beta
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    market = _market;
    baseToken = _baseToken;
    fToken = _fToken;
    xToken = _xToken;
    priceOracle = _priceOracle;
    beta = _beta;
  }

  /*************************
   * Public View Functions *
   *************************/

  /// @inheritdoc ITreasury
  function collateralRatio() external view override returns (uint256) {
    StableCoinMath.SwapState memory _state = _loadSwapState();

    if (_state.baseSupply == 0) return PRECISION;
    if (_state.fSupply == 0 || _state.fNav == 0) return PRECISION * PRECISION;

    return _state.baseSupply.mul(_state.baseNav).mul(PRECISION).div(_state.fSupply.mul(_state.fNav));
  }

  /// @inheritdoc ITreasury
  function getCurrentNav()
    external
    view
    override
    returns (
      uint256 _baseNav,
      uint256 _fNav,
      uint256 _xNav
    )
  {
    StableCoinMath.SwapState memory _state = _loadSwapState();

    _baseNav = _state.baseNav;
    _fNav = _state.fNav;
    _xNav = _state.xNav;
  }

  /// @inheritdoc ITreasury
  /// @dev If the current collateral ratio <= new collateral ratio, we should return 0.
  function maxMintableFToken(uint256 _newCollateralRatio)
    external
    view
    override
    returns (uint256 _maxBaseIn, uint256 _maxFTokenMintable)
  {
    require(_newCollateralRatio > PRECISION, "collateral ratio too small");

    StableCoinMath.SwapState memory _state = _loadSwapState();
    (_maxBaseIn, _maxFTokenMintable) = _state.maxMintableFToken(_newCollateralRatio);
  }

  /// @inheritdoc ITreasury
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  function maxMintableXToken(uint256 _newCollateralRatio)
    external
    view
    override
    returns (uint256 _maxBaseIn, uint256 _maxXTokenMintable)
  {
    require(_newCollateralRatio > PRECISION, "collateral ratio too small");

    StableCoinMath.SwapState memory _state = _loadSwapState();
    (_maxBaseIn, _maxXTokenMintable) = _state.maxMintableXToken(_newCollateralRatio);
  }

  /// @inheritdoc ITreasury
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  function maxMintableXTokenWithIncentive(uint256 _newCollateralRatio, uint256 _incentiveRatio)
    external
    view
    override
    returns (uint256 _maxBaseIn, uint256 _maxXTokenMintable)
  {
    require(_newCollateralRatio > PRECISION, "collateral ratio too small");

    StableCoinMath.SwapState memory _state = _loadSwapState();
    (_maxBaseIn, _maxXTokenMintable) = _state.maxMintableXTokenWithIncentive(_newCollateralRatio, _incentiveRatio);
  }

  /// @inheritdoc ITreasury
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  function maxRedeemableFToken(uint256 _newCollateralRatio)
    external
    view
    override
    returns (uint256 _maxBaseOut, uint256 _maxFTokenRedeemable)
  {
    require(_newCollateralRatio > PRECISION, "collateral ratio too small");

    StableCoinMath.SwapState memory _state = _loadSwapState();
    (_maxBaseOut, _maxFTokenRedeemable) = _state.maxRedeemableFToken(_newCollateralRatio);
  }

  /// @inheritdoc ITreasury
  /// @dev If the current collateral ratio <= new collateral ratio, we should return 0.
  function maxRedeemableXToken(uint256 _newCollateralRatio)
    external
    view
    override
    returns (uint256 _maxBaseOut, uint256 _maxXTokenRedeemable)
  {
    require(_newCollateralRatio > PRECISION, "collateral ratio too small");

    StableCoinMath.SwapState memory _state = _loadSwapState();
    (_maxBaseOut, _maxXTokenRedeemable) = _state.maxRedeemableXToken(_newCollateralRatio);
  }

  /// @inheritdoc ITreasury
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  function maxLiquidatable(uint256 _newCollateralRatio, uint256 _incentiveRatio)
    external
    view
    override
    returns (uint256 _maxBaseOut, uint256 _maxFTokenLiquidatable)
  {
    require(_newCollateralRatio > PRECISION, "collateral ratio too small");

    StableCoinMath.SwapState memory _state = _loadSwapState();
    (_maxBaseOut, _maxFTokenLiquidatable) = _state.maxLiquidatable(_newCollateralRatio, _incentiveRatio);
  }

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @inheritdoc ITreasury
  function mint(
    uint256 _baseIn,
    address _recipient,
    MintOption _option
  ) external override onlyMarket returns (uint256 _fTokenOut, uint256 _xTokenOut) {
    StableCoinMath.SwapState memory _state = _loadSwapState();

    if (_option == MintOption.FToken) {
      _fTokenOut = _state.mintFToken(_baseIn);
    } else if (_option == MintOption.XToken) {
      _xTokenOut = _state.mintXToken(_baseIn);
    } else {
      if (_state.baseSupply == 0) {
        uint256 _totalVal = _baseIn.mul(_state.baseNav);
        _fTokenOut = _totalVal.mul(initialMintRatio).div(PRECISION).div(PRECISION);
        _xTokenOut = _totalVal.div(PRECISION).sub(_fTokenOut);
      } else {
        (_fTokenOut, _xTokenOut) = _state.mint(_baseIn);
      }
    }

    totalBaseToken = _state.baseSupply + _baseIn;

    if (_fTokenOut > 0) {
      IFractionalToken(fToken).mint(_recipient, _fTokenOut);
    }
    if (_xTokenOut > 0) {
      ILeveragedToken(xToken).mint(_recipient, _xTokenOut);
    }
  }

  /// @inheritdoc ITreasury
  function redeem(
    uint256 _fTokenIn,
    uint256 _xTokenIn,
    address _owner
  ) external override onlyMarket returns (uint256 _baseOut) {
    StableCoinMath.SwapState memory _state = _loadSwapState();

    _baseOut = _state.redeem(_fTokenIn, _xTokenIn);

    if (_fTokenIn > 0) {
      IFractionalToken(fToken).burn(_owner, _fTokenIn);
    }

    if (_xTokenIn > 0) {
      ILeveragedToken(xToken).burn(_owner, _xTokenIn);
    }

    totalBaseToken = _state.baseSupply.sub(_baseOut);

    _transferBaseToken(_baseOut, msg.sender);
  }

  /// @inheritdoc ITreasury
  function addBaseToken(
    uint256 _baseIn,
    uint256 _incentiveRatio,
    address _recipient
  ) external override onlyMarket returns (uint256 _xTokenOut) {
    StableCoinMath.SwapState memory _state = _loadSwapState();

    uint256 _fDeltaNav;
    (_xTokenOut, _fDeltaNav) = _state.mintXToken(_baseIn, _incentiveRatio);

    totalBaseToken = _state.baseSupply + _baseIn;
    IFractionalToken(fToken).setNav(
      _state.fNav.sub(_fDeltaNav).mul(PRECISION).div(uint256(PRECISION_I256.add(_state.fMultiple)))
    );

    if (_xTokenOut > 0) {
      ILeveragedToken(xToken).mint(_recipient, _xTokenOut);
    }
  }

  /// @inheritdoc ITreasury
  function liquidate(
    uint256 _fTokenIn,
    uint256 _incentiveRatio,
    address _owner
  ) external override onlyMarket returns (uint256 _baseOut) {
    StableCoinMath.SwapState memory _state = _loadSwapState();

    uint256 _fDeltaNav;
    (_baseOut, _fDeltaNav) = _state.liquidateWithIncentive(_fTokenIn, _incentiveRatio);

    totalBaseToken = _state.baseSupply.sub(_baseOut);

    address _fToken = fToken;
    IFractionalToken(_fToken).burn(_owner, _fTokenIn);
    IFractionalToken(_fToken).setNav(
      _state.fNav.sub(_fDeltaNav).mul(PRECISION).div(uint256(PRECISION_I256.add(_state.fMultiple)))
    );

    if (_baseOut > 0) {
      _transferBaseToken(_baseOut, msg.sender);
    }
  }

  /// @inheritdoc ITreasury
  function selfLiquidate(
    uint256 _baseAmt,
    uint256 _incentiveRatio,
    address _recipient,
    bytes calldata _data
  ) external override onlyMarket returns (uint256 _baseOut, uint256 _fAmt) {
    // The supply are locked, so it is safe to use this memory variable.
    StableCoinMath.SwapState memory _state = _loadSwapState();

    _transferBaseToken(_baseAmt, msg.sender);
    _fAmt = IMarket(msg.sender).onSelfLiquidate(_baseAmt, _data);

    uint256 _fDeltaNav;
    (_baseOut, _fDeltaNav) = _state.liquidateWithIncentive(_fAmt, _incentiveRatio);
    require(_baseOut >= _baseAmt, "self liquidate with loss");

    address _fToken = fToken;
    IFractionalToken(_fToken).burn(address(this), _fAmt);
    totalBaseToken = _state.baseSupply.sub(_baseOut);

    IFractionalToken(_fToken).setNav(
      _state.fNav.sub(_fDeltaNav).mul(PRECISION).div(uint256(PRECISION_I256.add(_state.fMultiple)))
    );

    if (_baseOut > _baseAmt) {
      _transferBaseToken(_baseOut - _baseAmt, _recipient);
    }
  }

  /// @inheritdoc ITreasury
  function cacheTwap() external override {
    TwapCache memory _cache = twapCache;
    if (_cache.timestamp != block.timestamp) {
      _cache.price = uint128(ITwapOracle(priceOracle).getTwap(block.timestamp));
      _cache.timestamp = uint128(block.timestamp);

      twapCache = _cache;
    }
  }

  /// @inheritdoc ITreasury
  function protocolSettle() external override {
    require(settleWhitelist[msg.sender], "only settle whitelist");
    if (totalBaseToken == 0) return;

    uint256 _newPrice = _fetchTwapPrice();
    int256 _fMultiple = _computeMultiple(_newPrice);
    uint256 _fNav = IFractionalToken(fToken).updateNav(_fMultiple);

    emit ProtocolSettle(_newPrice, _fNav);

    lastPermissionedPrice = _newPrice;
  }

  /// @inheritdoc ITreasury
  function transferToStrategy(uint256 _amount) external override onlyStrategy {
    IERC20Upgradeable(baseToken).safeTransfer(strategy, _amount);
    strategyUnderlying += _amount;
  }

  /// @inheritdoc ITreasury
  /// @dev For future use.
  function notifyStrategyProfit(uint256 _amount) external override onlyStrategy {}

  /*******************************
   * Public Restricted Functions *
   *******************************/

  function initializePrice() external onlyOwner {
    require(lastPermissionedPrice == 0, "only initialize price once");
    uint256 _price = _fetchTwapPrice();

    lastPermissionedPrice = _price;

    IFractionalToken(fToken).setNav(PRECISION);

    emit ProtocolSettle(_price, PRECISION);
  }

  /// @notice Change address of strategy contract.
  /// @param _strategy The new address of strategy contract.
  function updateStrategy(address _strategy) external onlyOwner {
    strategy = _strategy;

    emit UpdateStrategy(_strategy);
  }

  /// @notice Change the value of fToken beta.
  /// @param _beta The new value of beta.
  function updateBeta(uint256 _beta) external onlyOwner {
    beta = _beta;

    emit UpdateBeta(_beta);
  }

  /// @notice Change address of price oracle contract.
  /// @param _priceOracle The new address of price oracle contract.
  function updatePriceOracle(address _priceOracle) external onlyOwner {
    priceOracle = _priceOracle;

    emit UpdatePriceOracle(_priceOracle);
  }

  /// @notice Update the whitelist status for settle account.
  /// @param _account The address of account to update.
  /// @param _status The status of the account to update.
  function updateSettleWhitelist(address _account, bool _status) external onlyOwner {
    settleWhitelist[_account] = _status;

    emit UpdateSettleWhitelist(_account, _status);
  }

  /**********************
   * Internal Functions *
   **********************/

  /// @dev Internal function to transfer base token to receiver.
  /// @param _amount The amount of base token to transfer.
  /// @param _recipient The address of receiver.
  function _transferBaseToken(uint256 _amount, address _recipient) internal {
    address _baseToken = baseToken;
    uint256 _balance = IERC20Upgradeable(_baseToken).balanceOf(address(this));
    if (_balance < _amount) {
      uint256 _diff = _amount - _balance;
      IAssetStrategy(strategy).withdrawToTreasury(_diff);
      strategyUnderlying = strategyUnderlying.sub(_diff);

      // consider possible slippage here.
      _balance = IERC20Upgradeable(_baseToken).balanceOf(address(this));
      if (_amount > _balance) {
        _amount = _balance;
      }
    }

    IERC20Upgradeable(_baseToken).safeTransfer(_recipient, _amount);
  }

  /// @dev Internal function to load swap variable to memory
  function _loadSwapState() internal view returns (StableCoinMath.SwapState memory _state) {
    _state.baseSupply = totalBaseToken;
    _state.baseNav = _fetchTwapPrice();

    if (_state.baseSupply == 0) {
      _state.fNav = PRECISION;
      _state.xNav = PRECISION;
    } else {
      _state.fMultiple = _computeMultiple(_state.baseNav);
      address _fToken = fToken;
      _state.fSupply = IERC20Upgradeable(_fToken).totalSupply();
      _state.fNav = IFractionalToken(_fToken).getNav(_state.fMultiple);

      _state.xSupply = IERC20Upgradeable(xToken).totalSupply();
      if (_state.xSupply == 0) {
        // no xToken, treat the nav of xToken as 1.0
        _state.xNav = PRECISION;
      } else {
        _state.xNav = _state.baseSupply.mul(_state.baseNav).sub(_state.fSupply.mul(_state.fNav)).div(_state.xSupply);
      }
    }
  }

  /// @dev Internal function to compute latest nav multiple based on current price.
  ///
  /// Below are some important formula to do the update.
  ///                newPrice
  /// ratio = --------------------- - 1
  ///         lastPermissionedPrice
  ///
  /// lastIntermediateFTokenNav = (1 + beta * ratio) * lastFTokenNav
  ///
  /// @param _newPrice The current price of base token.
  /// @return _fMultiple The multiple for fToken.
  function _computeMultiple(uint256 _newPrice) internal view returns (int256 _fMultiple) {
    int256 _lastPermissionedPrice = int256(lastPermissionedPrice);

    int256 _ratio = int256(_newPrice).sub(_lastPermissionedPrice).mul(PRECISION_I256).div(_lastPermissionedPrice);

    _fMultiple = _ratio.mul(int256(beta)).div(PRECISION_I256);
  }

  /// @dev Internal function to fetch twap price.
  /// @return _price The twap price of the base token.
  function _fetchTwapPrice() internal view returns (uint256 _price) {
    TwapCache memory _cache = twapCache;
    if (_cache.timestamp != block.timestamp) {
      _price = ITwapOracle(priceOracle).getTwap(block.timestamp);
    } else {
      _price = _cache.price;
    }

    require(_price > 0, "invalid twap price");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library SafeMathUpgradeable {
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

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IAssetStrategy {
  /// @notice Withdraw assets from strategy to treasury.
  /// @param amount The amount of token to withdraw.
  function withdrawToTreasury(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IFractionalToken {
  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the net asset value for the token.
  function nav() external view returns (uint256);

  /// @notice Compute the new nav with multiple.
  /// @param multiple The multiplier used to update the nav, multiplied by 1e18.
  /// @return newNav The new net asset value of the token.
  function getNav(int256 multiple) external view returns (uint256 newNav);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Update the net asset value by times `(1 + multiple / 1e18)`.
  /// @param multiple The multiplier used to update the nav, multiplied by 1e18.
  /// @return newNav The new net asset value of the token.
  function updateNav(int256 multiple) external returns (uint256 newNav);

  /// @notice Update the net asset value by direct setting.
  /// @param newNav The new net asset value, multiplied by 1e18.
  function setNav(uint256 newNav) external;

  /// @notice Mint some token to someone.
  /// @param to The address of recipient.
  /// @param amount The amount of token to mint.
  function mint(address to, uint256 amount) external;

  /// @notice Burn some token from someone.
  /// @param from The address of owner to burn.
  /// @param amount The amount of token to burn.
  function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ILeveragedToken {
  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the net asset value for the token.
  function nav() external view returns (uint256);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint some token to someone.
  /// @param to The address of recipient.
  /// @param amount The amount of token to mint.
  function mint(address to, uint256 amount) external;

  /// @notice Burn some token from someone.
  /// @param from The address of owner to burn.
  /// @param amount The amount of token to burn.
  function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IMarket {
  /**********
   * Events *
   **********/

  /// @notice Emitted when fToken or xToken is minted.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param fTokenOut The amount of fToken minted.
  /// @param xTokenOut The amount of xToken minted.
  /// @param mintFee The amount of mint fee charged.
  event Mint(
    address indexed owner,
    address indexed recipient,
    uint256 baseTokenIn,
    uint256 fTokenOut,
    uint256 xTokenOut,
    uint256 mintFee
  );

  /// @notice Emitted when someone redeem base token with fToken or xToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param xTokenBurned The amount of xToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param redeemFee The amount of redeem fee charged.
  event Redeem(
    address indexed owner,
    address indexed recipient,
    uint256 fTokenBurned,
    uint256 xTokenBurned,
    uint256 baseTokenOut,
    uint256 redeemFee
  );

  /// @notice Emitted when someone add more base token.
  /// @param owner The address of base token owner.
  /// @param recipient The address of receiver for fToken or xToken.
  /// @param baseTokenIn The amount of base token deposited.
  /// @param xTokenMinted The amount of xToken minted.
  event AddCollateral(address indexed owner, address indexed recipient, uint256 baseTokenIn, uint256 xTokenMinted);

  /// @notice Emitted when someone liquidate with fToken.
  /// @param owner The address of fToken and xToken owner.
  /// @param recipient The address of receiver for base token.
  /// @param fTokenBurned The amount of fToken burned.
  /// @param baseTokenOut The amount of base token redeemed.
  event UserLiquidate(address indexed owner, address indexed recipient, uint256 fTokenBurned, uint256 baseTokenOut);

  /// @notice Emitted when self liquidate with fToken.
  /// @param caller The address of caller.
  /// @param baseSwapAmt The amount of base token used to swap.
  /// @param baseTokenOut The amount of base token redeemed.
  /// @param fTokenBurned The amount of fToken liquidated.
  event SelfLiquidate(address indexed caller, uint256 baseSwapAmt, uint256 baseTokenOut, uint256 fTokenBurned);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint both fToken and xToken with some base token.
  /// @param baseIn The amount of base token supplied.
  /// @param recipient The address of receiver for fToken and xToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mint(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted,
    uint256 minXTokenMinted
  ) external returns (uint256 fTokenMinted, uint256 xTokenMinted);

  /// @notice Mint some fToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for fToken.
  /// @param minFTokenMinted The minimum amount of fToken should be received.
  /// @return fTokenMinted The amount of fToken should be received.
  function mintFToken(
    uint256 baseIn,
    address recipient,
    uint256 minFTokenMinted
  ) external returns (uint256 fTokenMinted);

  /// @notice Mint some xToken with some base token.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function mintXToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Mint some xToken by add some base token as collateral.
  /// @param baseIn The amount of base token supplied, use `uint256(-1)` to supply all base token.
  /// @param recipient The address of receiver for xToken.
  /// @param minXTokenMinted The minimum amount of xToken should be received.
  /// @return xTokenMinted The amount of xToken should be received.
  function addBaseToken(
    uint256 baseIn,
    address recipient,
    uint256 minXTokenMinted
  ) external returns (uint256 xTokenMinted);

  /// @notice Redeem base token with fToken and xToken.
  /// @param fTokenIn the amount of fToken to redeem, use `uint256(-1)` to redeem all fToken.
  /// @param xTokenIn the amount of xToken to redeem, use `uint256(-1)` to redeem all xToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Permissionless liquidate some fToken to increase the collateral ratio.
  /// @param fTokenIn the amount of fToken to supply, use `uint256(-1)` to liquidate all fToken.
  /// @param recipient The address of receiver for base token.
  /// @param minBaseOut The minimum amount of base token should be received.
  /// @return baseOut The amount of base token should be received.
  function liquidate(
    uint256 fTokenIn,
    address recipient,
    uint256 minBaseOut
  ) external returns (uint256 baseOut);

  /// @notice Self liquidate some fToken to increase the collateral ratio.
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param minFTokenLiquidated The minimum amount of fToken should be liquidated.
  /// @param data The data used to swap base token to fToken.
  /// @return baseOut The amount of base token should be received.
  /// @return fTokenLiquidated the amount of fToken liquidated.
  function selfLiquidate(
    uint256 baseSwapAmt,
    uint256 minFTokenLiquidated,
    bytes calldata data
  ) external returns (uint256 baseOut, uint256 fTokenLiquidated);

  /// @notice Callback to swap base token to fToken
  /// @param baseSwapAmt The amount of base token to swap.
  /// @param data The data passed to market contract.
  /// @return fTokenAmt The amount of fToken received.
  function onSelfLiquidate(uint256 baseSwapAmt, bytes calldata data) external returns (uint256 fTokenAmt);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITreasury {
  /**********
   * Events *
   **********/

  /// @notice Emitted when the net asset value is updated.
  /// @param price The new price of base token.
  /// @param fNav The new net asset value of fToken.
  event ProtocolSettle(uint256 price, uint256 fNav);

  /*********
   * Enums *
   *********/

  enum MintOption {
    Both,
    FToken,
    XToken
  }

  /*************************
   * Public View Functions *
   *************************/

  /// @notice Return the address of base token.
  function baseToken() external view returns (address);

  /// @notice Return the address fractional base token.
  function fToken() external view returns (address);

  /// @notice Return the address leveraged base token.
  function xToken() external view returns (address);

  /// @notice Return the address of strategy contract.
  function strategy() external view returns (address);

  /// @notice The last updated permissioned base token price.
  function lastPermissionedPrice() external view returns (uint256);

  /// @notice Return the total amount of base token deposited.
  function totalBaseToken() external view returns (uint256);

  /// @notice Return the total amount of base token managed by strategy.
  function strategyUnderlying() external view returns (uint256);

  /// @notice Return the current collateral ratio of fToken, multipled by 1e18.
  function collateralRatio() external view returns (uint256);

  /// @notice Return current nav for base token, fToken and xToken.
  /// @return baseNav The nav for base token.
  /// @return fNav The nav for fToken.
  /// @return xNav The nav for xToken.
  function getCurrentNav()
    external
    view
    returns (
      uint256 baseNav,
      uint256 fNav,
      uint256 xNav
    );

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxFTokenMintable The amount of fToken can be minted.
  function maxMintableFToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxFTokenMintable);

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxXTokenMintable);

  /// @notice Compute the amount of base token needed to reach the new collateral ratio, with incentive.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return maxBaseIn The amount of base token needed.
  /// @return maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXTokenWithIncentive(uint256 newCollateralRatio, uint256 incentiveRatio)
    external
    view
    returns (uint256 maxBaseIn, uint256 maxXTokenMintable);

  /// @notice Compute the amount of fToken needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseOut The amount of base token redeemed.
  /// @return maxFTokenRedeemable The amount of fToken needed.
  function maxRedeemableFToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxFTokenRedeemable);

  /// @notice Compute the amount of xToken needed to reach the new collateral ratio.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return maxBaseOut The amount of base token redeemed.
  /// @return maxXTokenRedeemable The amount of xToken needed.
  function maxRedeemableXToken(uint256 newCollateralRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxXTokenRedeemable);

  /// @notice Compute the maximum amount of fToken can be liquidated.
  /// @param newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return maxBaseOut The maximum amount of base token can liquidate, without incentive.
  /// @return maxFTokenLiquidatable The maximum amount of fToken can be liquidated.
  function maxLiquidatable(uint256 newCollateralRatio, uint256 incentiveRatio)
    external
    view
    returns (uint256 maxBaseOut, uint256 maxFTokenLiquidatable);

  /****************************
   * Public Mutated Functions *
   ****************************/

  /// @notice Mint fToken and xToken with some base token.
  /// @param baseIn The amount of base token deposited.
  /// @param recipient The address of receiver.
  /// @param option The mint option, xToken or fToken or both.
  /// @return fTokenOut The amount of fToken minted.
  /// @return xTokenOut The amount of xToken minted.
  function mint(
    uint256 baseIn,
    address recipient,
    MintOption option
  ) external returns (uint256 fTokenOut, uint256 xTokenOut);

  /// @notice Redeem fToken and xToken to base tokne.
  /// @param fTokenIn The amount of fToken to redeem.
  /// @param xTokenIn The amount of xToken to redeem.
  /// @param owner The owner of the fToken or xToken.
  /// @param baseOut The amount of base token redeemed.
  function redeem(
    uint256 fTokenIn,
    uint256 xTokenIn,
    address owner
  ) external returns (uint256 baseOut);

  /// @notice Add some base token to mint xToken with incentive.
  /// @param baseIn The amount of base token deposited.
  /// @param incentiveRatio The incentive ratio.
  /// @param recipient The address of receiver.
  /// @return xTokenOut The amount of xToken minted.
  function addBaseToken(
    uint256 baseIn,
    uint256 incentiveRatio,
    address recipient
  ) external returns (uint256 xTokenOut);

  /// @notice Liquidate fToken to base token with incentive.
  /// @param fTokenIn The amount of fToken to liquidate.
  /// @param incentiveRatio The incentive ratio.
  /// @param owner The owner of the fToken.
  /// @param baseOut The amount of base token liquidated.
  function liquidate(
    uint256 fTokenIn,
    uint256 incentiveRatio,
    address owner
  ) external returns (uint256 baseOut);

  /// @notice Self liquidate fToken to base token with incentive.
  /// @param baseSwapAmt The amount of base token used to buy fToken.
  /// @param incentiveRatio The incentive ratio.
  /// @param recipient The address of receiver of profited base token.
  /// @param data The calldata passed to market contract.
  /// @return baseOut The expected base token received.
  /// @return fAmt The amount of fToken liquidated.
  function selfLiquidate(
    uint256 baseSwapAmt,
    uint256 incentiveRatio,
    address recipient,
    bytes calldata data
  ) external returns (uint256 baseOut, uint256 fAmt);

  /// @notice Cache the twap price.
  function cacheTwap() external;

  /// @notice Settle the nav of base token, fToken and xToken.
  function protocolSettle() external;

  /// @notice Transfer some base token to strategy contract.
  /// @param amount The amount of token to transfer.
  function transferToStrategy(uint256 amount) external;

  /// @notice Notify base token profit from strategy contract.
  /// @param amount The amount of base token.
  function notifyStrategyProfit(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITwapOracle {
  /// @notice Return TWAP with 18 decimal places in the epoch ending at the specified timestamp.
  ///         Zero is returned if TWAP in the epoch is not available.
  /// @param timestamp End Timestamp in seconds of the epoch
  /// @return TWAP (18 decimal places) in the epoch, or zero if not available
  function getTwap(uint256 timestamp) external view returns (uint256);

  /// @notice Return the latest price with 18 decimal places.
  function getLatest() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library StableCoinMath {
  using SafeMathUpgradeable for uint256;

  /*************
   * Constants *
   *************/

  /// @dev The precision used to compute nav.
  uint256 internal constant PRECISION = 1e18;

  /// @dev The precision used to compute nav.
  int256 internal constant PRECISION_I256 = 1e18;

  /***********
   * Structs *
   ***********/

  struct SwapState {
    // Current supply of base token
    uint256 baseSupply;
    // Current nav of base token
    uint256 baseNav;
    // The multiple used to compute current nav.
    int256 fMultiple;
    // Current supply of fractional token
    uint256 fSupply;
    // Current nav of fractional token
    uint256 fNav;
    // Current supply of leveraged token
    uint256 xSupply;
    // Current nav of leveraged token
    uint256 xNav;
  }

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  ///
  /// @dev If the current collateral ratio <= new collateral ratio, we should return 0.
  ///
  /// @param state The current state.
  /// @param _newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return _maxBaseIn The amount of base token needed.
  /// @return _maxFTokenMintable The amount of fToken can be minted.
  function maxMintableFToken(SwapState memory state, uint256 _newCollateralRatio)
    internal
    pure
    returns (uint256 _maxBaseIn, uint256 _maxFTokenMintable)
  {
    //  n * v = nf * vf + nx * vx
    //  (n + dn) * v = (nf + df) * vf + nx * vx
    //  (n + dn) * v / ((nf + df) * vf) = ncr
    // =>
    //  n * v - ncr * nf * vf = (ncr - 1) * dn * v
    //  n * v - ncr * nf * vf = (ncr - 1) * df * vf
    // =>
    //  dn = (n * v - ncr * nf * vf) / ((ncr - 1) * v)
    //  df = (n * v - ncr * nf * vf) / ((ncr - 1) * vf)

    uint256 _baseVal = state.baseSupply.mul(state.baseNav).mul(PRECISION);
    uint256 _fVal = _newCollateralRatio.mul(state.fSupply).mul(state.fNav);

    if (_baseVal > _fVal) {
      _newCollateralRatio = _newCollateralRatio.sub(PRECISION);
      uint256 _delta = _baseVal - _fVal;

      _maxBaseIn = _delta.div(state.baseNav.mul(_newCollateralRatio));
      _maxFTokenMintable = _delta.div(state.fNav.mul(_newCollateralRatio));
    }
  }

  /// @notice Compute the amount of base token needed to reach the new collateral ratio.
  ///
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  ///
  /// @param state The current state.
  /// @param _newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return _maxBaseIn The amount of base token needed.
  /// @return _maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXToken(SwapState memory state, uint256 _newCollateralRatio)
    internal
    pure
    returns (uint256 _maxBaseIn, uint256 _maxXTokenMintable)
  {
    //  n * v = nf * vf + nx * vx
    //  (n + dn) * v = nf * vf + (nx + dx) * vx
    //  (n + dn) * v / (nf * vf) = ncr
    // =>
    //  n * v + dn * v = ncr * nf * vf
    //  n * v + dx * vx = ncr * nf * vf
    // =>
    //  dn = (ncr * nf * vf - n * v) / v
    //  dx = (ncr * nf * vf - n * v) / vx

    uint256 _baseVal = state.baseNav.mul(state.baseSupply).mul(PRECISION);
    uint256 _fVal = _newCollateralRatio.mul(state.fSupply).mul(state.fNav);

    if (_fVal > _baseVal) {
      uint256 _delta = _fVal - _baseVal;

      _maxBaseIn = _delta.div(state.baseNav.mul(PRECISION));
      _maxXTokenMintable = _delta.div(state.xNav.mul(PRECISION));
    }
  }

  /// @notice Compute the amount of base token needed to reach the new collateral ratio, with incentive.
  ///
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  ///
  /// @param state The current state.
  /// @param _newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param _incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return _maxBaseIn The amount of base token needed.
  /// @return _maxXTokenMintable The amount of xToken can be minted.
  function maxMintableXTokenWithIncentive(
    SwapState memory state,
    uint256 _newCollateralRatio,
    uint256 _incentiveRatio
  ) internal pure returns (uint256 _maxBaseIn, uint256 _maxXTokenMintable) {
    //  n * v = nf * vf + nx * vx
    //  (n + dn) * v = nf * (vf - dvf) + (nx + dx) * vx
    //  (n + dn) * v / (nf * (vf - dvf)) = ncr
    //  nf * dvf = lambda * dn * v
    //  dx * vx = (1 + lambda) * dn * v
    // =>
    //  n * v + dn * v = ncr * nf * vf - lambda * nrc * dn * v
    // =>
    //  dn = (ncr * nf * vf - n * v) / (v * (1 + lambda * ncr))
    //  dx = ((1 + lambda) * dn * v) / vx

    uint256 _baseVal = state.baseNav.mul(state.baseSupply).mul(PRECISION);
    uint256 _fVal = _newCollateralRatio.mul(state.fSupply).mul(state.fNav);

    if (_fVal > _baseVal) {
      uint256 _delta = _fVal - _baseVal;

      _maxBaseIn = _delta.div(state.baseNav.mul(PRECISION + (_incentiveRatio * _newCollateralRatio) / PRECISION));
      _maxXTokenMintable = _maxBaseIn.mul(state.baseNav).mul(PRECISION + _incentiveRatio).div(
        state.xNav.mul(PRECISION)
      );
    }
  }

  /// @notice Compute the amount of fToken needed to reach the new collateral ratio.
  ///
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  ///
  /// @param state The current state.
  /// @param _newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return _maxBaseOut The amount of base token redeemed.
  /// @return _maxFTokenRedeemable The amount of fToken needed.
  function maxRedeemableFToken(SwapState memory state, uint256 _newCollateralRatio)
    internal
    pure
    returns (uint256 _maxBaseOut, uint256 _maxFTokenRedeemable)
  {
    //  n * v = nf * vf + nx * vx
    //  (n - dn) * v = (nf - df) * vf + nx * vx
    //  (n - dn) * v / ((nf - df) * vf) = ncr
    // =>
    //  n * v - dn * v = ncr * nf * vf - ncr * dn * v
    //  n * v - df * vf = ncr * nf * vf - ncr * df * vf
    // =>
    //  df = (ncr * nf * vf - n * v) / ((ncr - 1) * vf)
    //  dn = (ncr * nf * vf - n * v) / ((ncr - 1) * v)

    uint256 _baseVal = state.baseSupply.mul(state.baseNav).mul(PRECISION);
    uint256 _fVal = _newCollateralRatio.mul(state.fSupply).mul(state.fNav);

    if (_fVal > _baseVal) {
      uint256 _delta = _fVal - _baseVal;
      _newCollateralRatio = _newCollateralRatio.sub(PRECISION);

      _maxFTokenRedeemable = _delta.div(_newCollateralRatio.mul(state.fNav));
      _maxBaseOut = _delta.div(_newCollateralRatio.mul(state.baseNav));
    }
  }

  /// @notice Compute the amount of xToken needed to reach the new collateral ratio.
  ///
  /// @dev If the current collateral ratio <= new collateral ratio, we should return 0.
  ///
  /// @param state The current state.
  /// @param _newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @return _maxBaseOut The amount of base token redeemed.
  /// @return _maxXTokenRedeemable The amount of xToken needed.
  function maxRedeemableXToken(SwapState memory state, uint256 _newCollateralRatio)
    internal
    pure
    returns (uint256 _maxBaseOut, uint256 _maxXTokenRedeemable)
  {
    //  n * v = nf * vf + nx * vx
    //  (n - dn) * v = nf * vf + (nx - dx) * vx
    //  (n - dn) * v / (nf * vf) = ncr
    // =>
    //  n * v - dn * v = ncr * nf * vf
    //  n * v - dx * vx = ncr * nf * vf
    // =>
    //  dn = (n * v - ncr * nf * vf) / v
    //  dx = (n * v - ncr * nf * vf) / vx

    uint256 _baseVal = state.baseSupply.mul(state.baseNav).mul(PRECISION);
    uint256 _fVal = _newCollateralRatio.mul(state.fSupply).mul(state.fNav);

    if (_baseVal > _fVal) {
      uint256 _delta = _baseVal - _fVal;

      _maxXTokenRedeemable = _delta.div(state.xNav.mul(PRECISION));
      _maxBaseOut = _delta.div(state.baseNav.mul(PRECISION));
    }
  }

  /// @notice Compute the maximum amount of fToken can be liquidated.
  ///
  /// @dev If the current collateral ratio >= new collateral ratio, we should return 0.
  ///
  /// @param state The current state.
  /// @param _newCollateralRatio The target collateral ratio, multipled by 1e18.
  /// @param _incentiveRatio The extra incentive ratio, multipled by 1e18.
  /// @return _maxBaseOut The maximum amount of base token can liquidate, without incentive.
  /// @return _maxFTokenLiquidatable The maximum amount of fToken can be liquidated.
  function maxLiquidatable(
    SwapState memory state,
    uint256 _newCollateralRatio,
    uint256 _incentiveRatio
  ) internal pure returns (uint256 _maxBaseOut, uint256 _maxFTokenLiquidatable) {
    //  n * v = nf * vf + nx * vx
    //  (n - dn) * v = (nf - df) * (vf - dvf) + nx * vx
    //  (n - dn) * v / ((nf - df) * (vf - dvf)) = ncr
    //  dn * v = nf * dvf + df * (vf - dvf)
    //  dn * v = df * vf * (1 + lambda)
    // =>
    //  n * v - dn * v = ncf * nf * vf - ncr * dn * v
    // =>
    //  dn = (ncr * nf * vf - n * v) / ((ncr - 1) * v)
    //  df = (dn * v) / ((1 + lambda) * vf)

    uint256 _fVal = _newCollateralRatio.mul(state.fSupply).mul(state.fNav);
    uint256 _baseVal = state.baseSupply.mul(state.baseNav).mul(PRECISION);

    if (_fVal > _baseVal) {
      uint256 _delta = _fVal - _baseVal;
      _newCollateralRatio = _newCollateralRatio.sub(PRECISION);

      _maxBaseOut = _delta.div(state.baseNav.mul(_newCollateralRatio));
      _maxFTokenLiquidatable = _delta.div(_newCollateralRatio).mul(PRECISION).div(
        (PRECISION + _incentiveRatio).mul(state.fNav)
      );
    }
  }

  /// @notice Mint fToken and xToken according to current collateral ratio.
  /// @param state The current state.
  /// @param _baseIn The amount of base token supplied.
  /// @return _fTokenOut The amount of fToken expected.
  /// @return _xTokenOut The amount of xToken expected.
  function mint(SwapState memory state, uint256 _baseIn)
    internal
    pure
    returns (uint256 _fTokenOut, uint256 _xTokenOut)
  {
    //  n * v = nf * vf + nx * vx
    //  (n + dn) * v = (nf + df) * vf + (nx + dx) * vx
    //  ((nf + df) * vf) / ((n + dn) * v) = (nf * vf) / (n * v)
    //  ((nx + dx) * vx) / ((n + dn) * v) = (nx * vx) / (n * v)
    // =>
    //   df = nf * dn / n
    //   dx = nx * dn / n
    _fTokenOut = state.fSupply.mul(_baseIn).div(state.baseSupply);
    _xTokenOut = state.xSupply.mul(_baseIn).div(state.baseSupply);
  }

  /// @notice Mint fToken.
  /// @param state The current state.
  /// @param _baseIn The amount of base token supplied.
  /// @return _fTokenOut The amount of fToken expected.
  function mintFToken(SwapState memory state, uint256 _baseIn) internal pure returns (uint256 _fTokenOut) {
    //  n * v = nf * vf + nx * vx
    //  (n + dn) * v = (nf + df) * vf + nx * vx
    // =>
    //  df = dn * v / vf
    _fTokenOut = _baseIn.mul(state.baseNav).div(state.fNav);
  }

  /// @notice Mint xToken.
  /// @param state The current state.
  /// @param _baseIn The amount of base token supplied.
  /// @return _xTokenOut The amount of xToken expected.
  function mintXToken(SwapState memory state, uint256 _baseIn) internal pure returns (uint256 _xTokenOut) {
    //  n * v = nf * vf + nx * vx
    //  (n + dn) * v = nf * vf + (nx + dx) * vx
    // =>
    //  dx = (dn * v * nx) / (n * v - nf * vf)
    _xTokenOut = _baseIn.mul(state.baseNav).mul(state.xSupply);
    _xTokenOut = _xTokenOut.div(state.baseSupply.mul(state.baseNav).sub(state.fSupply.mul(state.fNav)));
  }

  /// @notice Mint xToken with given incentive.
  /// @param state The current state.
  /// @param _baseIn The amount of base token supplied.
  /// @param _incentiveRatio The extra incentive given, multiplied by 1e18.
  /// @return _xTokenOut The amount of xToken expected.
  /// @return _fDeltaNav The change for nav of fToken.
  function mintXToken(
    SwapState memory state,
    uint256 _baseIn,
    uint256 _incentiveRatio
  ) internal pure returns (uint256 _xTokenOut, uint256 _fDeltaNav) {
    //  n * v = nf * vf + nx * vx
    //  (n + dn) * v = nf * (vf - dvf) + (nx + dx) * vx
    // =>
    //  dn * v = dx * vx - nf * dvf
    //  nf * dvf = lambda * dn * v
    // =>
    //  dx * vx = (1 + lambda) * dn * v
    //  dvf = lambda * dn * v / nf

    uint256 _deltaVal = _baseIn.mul(state.baseNav);

    _xTokenOut = _deltaVal.mul(PRECISION + _incentiveRatio).div(PRECISION);
    _xTokenOut = _xTokenOut.div(state.xNav);

    _fDeltaNav = _deltaVal.mul(_incentiveRatio).div(PRECISION);
    _fDeltaNav = _fDeltaNav.div(state.fSupply);
  }

  /// @notice Redeem base token with fToken and xToken.
  /// @param state The current state.
  /// @param _fTokenIn The amount of fToken supplied.
  /// @param _xTokenIn The amount of xToken supplied.
  /// @return _baseOut The amount of base token expected.
  function redeem(
    SwapState memory state,
    uint256 _fTokenIn,
    uint256 _xTokenIn
  ) internal pure returns (uint256 _baseOut) {
    uint256 _xVal = state.baseSupply.mul(state.baseNav).sub(state.fSupply.mul(state.fNav));

    //  n * v = nf * vf + nx * vx
    //  (n - dn) * v = (nf - df) * vf + (nx - dx) * vx
    // =>
    //  dn = (df * vf + dx * (n * v - nf * vf) / nx) / v

    if (state.xSupply == 0) {
      _baseOut = _fTokenIn.mul(state.fNav).div(state.baseNav);
    } else {
      _baseOut = _fTokenIn.mul(state.fNav);
      _baseOut = _baseOut.add(_xTokenIn.mul(_xVal).div(state.xSupply));
      _baseOut = _baseOut.div(state.baseNav);
    }
  }

  /// @notice Redeem base token with fToken and given incentive.
  /// @param state The current state.
  /// @param _fTokenIn The amount of fToken supplied.
  /// @param _incentiveRatio The extra incentive given, multiplied by 1e18.
  /// @return _baseOut The amount of base token expected.
  /// @return _fDeltaNav The change for nav of fToken.
  function liquidateWithIncentive(
    SwapState memory state,
    uint256 _fTokenIn,
    uint256 _incentiveRatio
  ) internal pure returns (uint256 _baseOut, uint256 _fDeltaNav) {
    //  n * v = nf * vf + nx * vx
    //  (n - dn) * v = (nf - df) * (vf - dvf) + nx * vx
    // =>
    //  dn * v = nf * dvf + df * (vf - dvf)
    //  dn * v = df * vf * (1 + lambda)
    // =>
    //  dn = df * vf * (1 + lambda) / v
    //  dvf = lambda * (df * vf) / (nf - df)

    uint256 _fDeltaVal = _fTokenIn.mul(state.fNav);

    _baseOut = _fDeltaVal.mul(PRECISION + _incentiveRatio).div(PRECISION);
    _baseOut = _baseOut.div(state.baseNav);

    _fDeltaNav = _fDeltaVal.mul(_incentiveRatio).div(PRECISION);
    _fDeltaNav = _fDeltaNav.div(state.fSupply.sub(_fTokenIn));
  }
}