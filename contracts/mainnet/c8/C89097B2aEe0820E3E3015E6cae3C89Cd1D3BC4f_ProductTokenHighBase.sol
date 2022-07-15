// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./ProductTokenCore.sol";

/**
 * @title ProductToken High Base
 *
 * @notice High base represent only trading in HIGH token, and bonding curve is based on HIGH to calculate price
 *
 * @notice Prdocut is pausable and owner have authority to make pause only. oterwise
 *         there is also a sunset(endTime) feature, after sunset there is no able to buy and sell product anymore
 *         only can redeem product.
 *
 * @dev See ProductTokenCore for more details
 *
 */
contract ProductTokenHighBase is ProductTokenCore {

  /// @dev Link to HIGH STREET ERC20 Token instance
  address public HIGH;

  /**
   * @dev initializer function.
   *
   * @param _name the name of this token
   * @param _symbol the symbol of this token
   * @param _bondingCurve bonding curve instance address
   * @param _productNft product nft instance address
   * @param _reserveRatio the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount the amount of token that will exist for this type.
   * @param _supplyOffset this amount is used to determine initial price.
   * @param _baseReserve the base amount of reserve tokens, in accordance to _supplyOffset.
   * @param _time time array compose of three setup times, index 0 is start time, index 1 is endtime, index 2 is cool time.
   *
  */

  function initialize(
    string memory _name,
    string memory _symbol,
    address _high,
    address _bondingCurve,
    address _productNft,
    uint32 _reserveRatio,
    uint32 _maxTokenCount,
    uint32 _supplyOffset,
    uint256 _baseReserve,
    uint256[3] memory _time,
    uint256 _brandTokenId
  ) public virtual initializer{
    require(_high != address(0), "invalid high address");
    HIGH = _high;
    ProductTokenCore.__initialize(
      _name,
      _symbol,
      _bondingCurve,
      _productNft,
      _reserveRatio,
      _maxTokenCount,
      _supplyOffset,
      _baseReserve,
      _time[0],
      _time[1],
      _time[2],
      _brandTokenId
    );
  }

  /**
  * @notice buy product with maximum acceptable price and can only buy one at a time
  *
  * @dev This function is implemented by using HIGH token as currency
  * @dev when endTime is arrived then can not buy product anymore
  *
  * @param maxPrice_ maximum acceptable price.
  *
  */
  function buy(uint256 maxPrice_) external virtual whenNotPaused nonReentrant {
    require(now256() >= startTime, "sale hasn't start");
    if(endTime[FEATURE_ENDTIME_BUY] != 0) {
      require(now256() < endTime[FEATURE_ENDTIME_BUY], "sale is expire");
    }
    require(maxPrice_ > 0, "invalid max price");

    transferFromHighToken(_msgSender(), address(this), maxPrice_);

    (uint256 change)  = _buy(maxPrice_);
    if(change > 0) {
      transferHighToken(_msgSender(), change);
    }
    if(coolDownTime > 0) {
      coolDownTimes[_msgSender()] = now256() + coolDownTime;
    }
  }

  /**
  * @notice sell products and return equivalent HIGH token
  *
  * @dev This function is implemented by using HIGH token as currency
  * @dev when endTime is arrived then can not buy product anymore
  *
  * @param amount_ amount of product want to sell
  */
  function sell(uint32 amount_) external virtual whenNotPaused nonReentrant {
    require(now256() >= startTime, "sale hasn't start");
    if(endTime[FEATURE_ENDTIME_SELL] != 0) {
      require(now256() < endTime[FEATURE_ENDTIME_SELL], "sale is expire");
    }

    require(now256() > coolDownTimes[_msgSender()], "wait to cool down");

    require(amount_ > 0, "Amount must be non-zero.");
    require(balanceOf(_msgSender()) >= amount_, "Insufficient tokens.");

    uint256 price = _sell(amount_);
    transferHighToken(_msgSender(), price);
  }

  /**
  * @notice When user wants to trade in their token for retail product
  *
  * @param amount_ amount of tokens that user wants to trade in.
  */
  function tradein(uint32 amount_) external virtual whenNotPaused nonReentrant{
    require(now256() >= startTime, "sale hasn't start");
    if(endTime[FEATURE_ENDTIME_TRADEIN] != 0) {
      require(now256() < endTime[FEATURE_ENDTIME_TRADEIN], "sale is expire");
    }
    require(amount_ > 0 && amount_ < 10, "Invalid amount");
    require(balanceOf(_msgSender()) >= amount_, "Insufficient tokens.");
    _tradein(amount_);
  }

  /**
  * @inheritdoc ProductTokenCore
  *
  * @dev Additionally to the parent smart contract, implementing transaction logic
  */
  function _claim(uint256 amount_) internal override virtual {
    transferHighToken(_msgSender(), amount_);
  }

  /**
  * @dev Executes SafeERC20.safeTransfer on a HIGH token
  *
  */
  function transferHighToken(address to_, uint256 value_) internal virtual{
    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(HIGH), to_, value_);
  }

  /**
  * @dev Executes SafeERC20.safeTransferFrom on a HIGH token
  *
  */
  function transferFromHighToken(address from_, address to_, uint256 value_) internal virtual{
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(HIGH), from_, to_, value_);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./utils/BancorBondingCurve.sol";
import "./HighstreetBrands.sol";

/**
  * @title ProductTokenCore
  *
  * @notice A contract containing common logic for a product token.
  *
  * @dev This contract lays the foundation for transaction computations, including
  *   bonding curve calculations and variable management. This contract does not
  *   implement any transaction logic.
  */
contract ProductTokenCore is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
  using SafeMathUpgradeable for uint256;

  /// @dev Data structure representing supplier information
  struct Supplier {
    // @dev Amount of fee owned by supplier;
    // @dev Will increase when people buy(), sell(), tradin() and decrease when supplier claim the value.
    uint256 amount;
    // @dev The wallet address of supplier
    address wallet;
  }

  /// @dev Amount of liquidity in the pool, not including the platform and supplier fee
  uint256 public reserveBalance;

  /// @dev Amount of supplier liquidity in the pool
  uint256 public tradeinReserveBalance;

  /// @dev computed from the exponential factor in the
  uint32 public reserveRatio;

  /// @dev max token count, determined by the supply of our physical product
  uint32 public maxTokenCount;

  /// @dev number of tokens burned through redeeming procedure. This will drive price up permanently
  uint32 public tradeinCount;

  /// @dev an initial value used to set an initial price. This is not included in the total supply.
  uint32 public supplyOffset;

  /// @dev Link to the Bancor Bonding Curve instance
  BancorBondingCurve public bondingCurve;

  /// @dev Link to the product nft instance
  HighstreetBrands public nft;

  /// @dev supplier information.
  Supplier private supplier;

  /// @dev platform fee.
  /// @dev 75% of fee from buy, 50% of fee from sell
  uint256 private platformFee;

  /// @dev cool down time is a interval which user should wait when sell after buy
  /// @dev it is implied that user can not sell immidiately after buy a product
  uint256 public coolDownTime;

  /// @dev brand token id
  /// @dev fixed tokenId on highstreet brand.
  uint256 public brandTokenId;

  /// @dev start time of sale
  uint256 public startTime;

  /**
  * @dev End time is the last time when user can buy and sell;
  *      it is implied that product stops after that time
  */
  mapping(uint32 => uint256) public endTime;

  /**
  * @dev a list stored cool down time of every user
  */
  mapping(address => uint256) public coolDownTimes;

  /// @dev To avoid significant precision loss due to division by "fraction of fee".
  uint256 public constant FEE_MULTIPLIER = 1e24;

  /// @dev during buy, 8% of price will be charge as fee
  uint256 public constant FEE_RATE_IN_BUY = 8e24;

  /// @dev during sell, 4% of price will be charge as fee
  uint256 public constant FEE_RATE_IN_SELL = 4e24;

  /// @dev the rate of transaction fee that brand can share for each buy
  uint256 public constant FEE_RATE_IN_BUY_BRAND = 2e24;

  /// @dev To avoid significant precision loss due to division by "fraction of fee".
  /// @dev this is 100 * FEE_MULTIPLIER
  uint256 internal constant FEE_DIVIDER = 100 * FEE_MULTIPLIER;

  /// @dev base value of bit mask that represent the endTime
  uint32 public constant FEATURE_ENDTIME_MIN = 0x0000_0001;

  /// @dev bit mask that represent the endTime of buy
  uint32 public constant FEATURE_ENDTIME_BUY = FEATURE_ENDTIME_MIN;

  /// @dev bit mask that represent the endTime of sell
  uint32 public constant FEATURE_ENDTIME_SELL = FEATURE_ENDTIME_BUY << 1;

  /// @dev bit mask that represent the endTime of tradein
  uint32 public constant FEATURE_ENDTIME_TRADEIN = FEATURE_ENDTIME_SELL << 1;

  /// @dev max value of bit mask that represent the endTime
  uint32 public constant FEATURE_ENDTIME_MAX = 0x0000_1111;


  /**
    * @dev Fired in _buy()
    *
    * @param sender an address which performed an operation, usually token buyer
    * @param price  token prices spent to bought tokens
    * @param fee amount of price in charged with according to platform fee
    */
  event Buy(address indexed sender, uint256 price, uint256 fee);

  /**
    * @dev Fired in _sell()
    *
    * @param sender an address which performed an operation, usually token seller
    * @param amount amount of tokens sold
    * @param price  amount of token prices when tokens sold
    * @param fee amount of price in charged with according to platform fee
    */
  event Sell(address indexed sender, uint32 amount, uint256 price, uint256 fee);

  /**
    * @dev Fired in _tradin()
    *
    * @param sender an address which performed an operation, usually token owner
    * @param amount amount of tokens redeemed
    * @param value value of tokens paid for supplier when redeemed
    */
  event Tradein(address indexed sender, uint32 amount, uint256 value);

  /**
    * @dev Fired in updateSupplier()
    *
    * @param supplier a new address of supplier
    */
  event UpdateSupplier(address indexed supplier);

  /**
    * @dev Fired in claimSupplier()
    *
    * @param sender an address which performed an operation, usually token suppier
    * @param amount amount of fee to deposit
    */
  event ClaimSupplierFee(address indexed sender, uint256 amount);

  /**
    * @dev Fired in claimPlatformFee()
    *
    * @param sender an address which performed an operation, usually token suppier
    * @param amount amount of fee to deposit
    */
  event ClaimPlatformFee(address indexed sender, uint256 amount);

  /**
    * @dev Fired in updateEndTime()
    *
    * @param sender an address which performed an operation, usually owner
    * @param set a variable to decide which endTime we want to set (buy, sell, tradein)
    * @param endTime a timestamp which restrict user to buy and sell product
    */
  event UpdateEndTime(address indexed sender, uint32 set, uint256 endTime);

  event UpdateStartTime(address indexed sender, uint256 startTime);

  /**
    * @dev Fired in updateCoolDownTime()
    *
    * @param sender an address which performed an operation, usually owner
    * @param coolDownTime a timestamp which restrict user to wait when sell
    */
  event UpdateCoolDownTime(address indexed sender, uint256 coolDownTime);

  /**
   * @dev initializer function.
   *
   * @param _name the name of this token
   * @param _symbol the symbol of this token
   * @param _bondingCurve bonding curve instance address
   * @param _highstreetBrands product nft instance address
   * @param _reserveRatio the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount the amount of token that will exist for this type.
   * @param _supplyOffset this amount is used to determine initial price.
   * @param _baseReserve the base amount of reserve tokens, in accordance to _supplyOffset.
   * @param _startTime end time is the starting time when user can buy and sell;
   * @param _endTime end time is the last time when user can buy and sell;
   * @param _coolDownTime cool down time is a interval which user should wait when sell after buy.
   * @param _brandTokenId fixed brand tokenId that represent certain token in Highstreet brand
   *
  */
  function __initialize(
    string memory _name,
    string memory _symbol,
    address _bondingCurve,
    address _highstreetBrands,
    uint32 _reserveRatio,
    uint32 _maxTokenCount,
    uint32 _supplyOffset,
    uint256 _baseReserve,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _coolDownTime,
    uint256 _brandTokenId
  ) public virtual initializer{
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __ERC20_init(_name, _symbol);
    __UUPSUpgradeable_init();
    __ProductToken_init_unchained(_bondingCurve, _highstreetBrands, _reserveRatio, _maxTokenCount, _supplyOffset, _baseReserve);
    supplier.wallet = _msgSender();
    if(_endTime > 0) {
      updateEndTime(FEATURE_ENDTIME_MAX, _endTime);
    }
    if(_startTime > 0) {
      updateStartTime(_startTime);
    }
    updateCoolDownTime(_coolDownTime);
    brandTokenId = _brandTokenId;
  }

  /**
   * @dev unchained initializer function.
   *
   * @param _bondingCurve bonding curve instance address
   * @param _highstreetBrands product nft instance address
   * @param _reserveRatio the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount the amount of token that will exist for this type.
   * @param _supplyOffset this amount is used to determine initial price.
   * @param _baseReserve the base amount of reserve tokens, in accordance to _supplyOffset.
   *
  */
  function __ProductToken_init_unchained(
    address _bondingCurve,
    address _highstreetBrands,
    uint32 _reserveRatio,
    uint32 _maxTokenCount,
    uint32 _supplyOffset,
    uint256 _baseReserve
  ) internal initializer {
    require(_maxTokenCount > 0, "Invalid max token count.");
    require(_reserveRatio > 0, "Invalid reserve ratio");
    require(_bondingCurve != address(0), "invalid bc address");
    require(_highstreetBrands != address(0), "invalid nft address");

    bondingCurve = BancorBondingCurve(_bondingCurve);
    nft = HighstreetBrands(_highstreetBrands);
    reserveBalance = _baseReserve * 1e18;
    tradeinReserveBalance = _baseReserve * 1e18;
    supplyOffset = _supplyOffset;
    reserveRatio = _reserveRatio;
    maxTokenCount = _maxTokenCount;
  }

  /**
   * @dev token is inseparable and only can be integer number
   * so decimal is set to zero.
   *
  */
  function decimals() public view virtual override returns (uint8) {
      return 0;
  }


  /**
   * @dev Function to check how many tokens of this product are currently available for purchase,
   * by taking the difference between max cap count and current token in circulation or burned.
   *
   * @return available the number of tokens available
  */
  function getAvailability() public view virtual returns (uint32 available)
  {
    return maxTokenCount - uint32(totalSupply()) - tradeinCount;    // add safemath for uint32 later
  }

  /**
   * @dev Used internally, function that computes supply value for the bonding curve
   * based on current token in circulation, token offset initialized, and tokens already redeemed.
   *
   * @return supply upply value for bonding curve calculation.
  */
  function _getTotalSupply() internal view virtual returns (uint32 supply)
  {
    return uint32(totalSupply().add(uint256(tradeinCount)).add(uint256(supplyOffset)));
  }

  /**
   * @dev Function that computes current price for a token through bonding curve calculation
   * based on parameters such as total supply, reserve balance, and reserve ratio.
   *
   * @return price current price in reserve token (in our case, this is HIGH). (with 4% platform fee)
  */
  function getCurrentPrice() external view virtual returns (uint256 price)
  {
    return getPriceForN(1);
  }

  /**
   * @dev Function that computes price total for buying n token through bonding curve calculation
   * based on parameters such as total supply, reserve balance, and reserve ratio.
   *
   * @param  _amountProduct token amount in traded token
   * @return price total price in reserve token (in our case, this is HIGH). (with 4% platform fee)
  */
  function getPriceForN(uint32 _amountProduct) public view virtual returns(uint256 price)
  {
    (uint value, uint fee) = _getPriceForN(_amountProduct);
    return value.add(fee);
  }

  /**
   * @dev Used internally, mostly by getPriceForN() and _buy()
   *
   * @param _amountProduct the amount of product token
   *
   * @return price price for N product token
   * @return fee platform and supplier fee charge to the buyer
  */
  function _getPriceForN(uint32 _amountProduct) internal view virtual returns (uint256 price, uint256 fee) {
    price = bondingCurve.calculatePriceForNTokens(
                _getTotalSupply(),
                reserveBalance,
                reserveRatio,
                _amountProduct
              );
    //ppm of 96%. 4% is the platform transaction fee
    fee = price * FEE_RATE_IN_BUY / FEE_DIVIDER ;
    return (price, fee);
  }


  /**
   * @dev Used internally, mostly by calculateBuyReturn()
   *
   * @param _amountReserve the total value that the buyer would like to pay (pegged currency)
   *
   * @return amount total amount of product token that buyer can have based on _amountReserve
   * @return fee platform and supplier fee charge to the buyer
   */
  function _buyReturn(uint256 _amountReserve) internal view virtual returns (uint32 amount, uint fee)
  {
    // value should be dvided by 1.04, before purchase
    uint256 value = _amountReserve * FEE_DIVIDER / (FEE_DIVIDER + FEE_RATE_IN_BUY);
    //ppm of 96%. 4% is the platform transaction fee
    fee = value * FEE_RATE_IN_BUY / FEE_DIVIDER;

    amount = bondingCurve.calculatePurchaseReturn(
              _getTotalSupply(),
              reserveBalance,
              reserveRatio,
              value - fee
            );
    return (amount, fee);
  }

  /**
   * @dev Function that computes number of product tokens one can buy given an amount in reserve token.
   *
   * @param  _amountReserve purchaing amount in reserve token (HIGH)(with 4% platform fee)
   * @return mintAmount number of tokens in traded token that can be purchased by given amount.
  */
  function calculateBuyReturn(uint256 _amountReserve)
    external view virtual returns (uint32 mintAmount)
  {
    (uint32 amount,) = _buyReturn(_amountReserve);
    return amount;
  }

  /**
   * @dev Used internally, to computes selling price for given amount of product tokens
   *
   * @param _amountProduct amount of product token that seller would like to sell
   * @return amount of tokens(pegged currency) that seller can have
   * @return fee platform and supplier fee charge to the seller
   */
  function _sellReturn(uint32 _amountProduct)
    internal view virtual returns (uint256 amount, uint256 fee)
  {
    // ppm of 98%. 2% is the platform transaction fee
    amount = bondingCurve.calculateSaleReturn(
              _getTotalSupply(),
              reserveBalance,
              reserveRatio,
              _amountProduct
            );
    fee = amount * FEE_RATE_IN_SELL / FEE_DIVIDER;
    return (amount, fee);
  }

  /**
   * @dev Function that computes selling price in reserve tokens given an amount in traded token.
   *
   * @param  _amountProduct selling amount in product token
   * @return soldAmount total amount that will be transferred to the seller (with 2% platform fee).
  */
  function calculateSellReturn(uint32 _amountProduct) external view virtual returns (uint256 soldAmount)
  {
    (uint reimburseAmount, uint fee) = _sellReturn(_amountProduct);
    return (reimburseAmount - fee);
  }

  /**
   * @dev Used internally, for supplier to calculate the token amount they can withdraw.
   *      The value will increase when users redeem the product token
   *
   * @param _amount amount of product token wishes to be redeemed
   *
   * @return price price base on input amount
   */
  function _tradinReturn(uint32 _amount) internal view virtual returns (uint256 price)
  {
    uint32 supply = uint32(uint256(_amount).add(uint256(tradeinCount)).add(uint256(supplyOffset)));
    return bondingCurve.calculatePriceForNTokens(
            supply,
            tradeinReserveBalance,
            reserveRatio,
            _amount
          );
  }

  /**
   * @dev Used internally, calculates the return for a given conversion (in product token)
   * This function validate whether is enough to purchase token.
   * If enough, the function will deduct, and then mint one token for the user. Any extras are return as change.
   * If not enough, will return as change directly
   * then replace the _amount with the actual amount and proceed with the above logic.
   *
   * @param _deposit reserve token deposited
   *
   * @return change amount of change in reserve tokens.
  */
  function _buy(uint256 _deposit) internal virtual returns (uint256 change)
  {
    require(getAvailability() > 0, "Sorry, this token is sold out.");

    (uint price, uint fee ) = _getPriceForN(1);

    require(_deposit >= (price + fee), "Insufficient max price.");
    _mint(_msgSender(), 1);
    // 50% of fee, is for supplier
    _updateSupplierFee(fee * FEE_RATE_IN_BUY_BRAND / FEE_RATE_IN_BUY);
    // 50% of fee, is for platform
    _updatePlatformFee(fee * (FEE_RATE_IN_BUY - FEE_RATE_IN_BUY_BRAND) / FEE_RATE_IN_BUY);

    reserveBalance = reserveBalance + price;

    emit Buy(_msgSender(), price, fee);
    return (_deposit - price - fee);
  }

  /**
   * @dev Used internally, calculates the return for a given conversion (in the reserve token)
   * This function will try to compute the amount of liquidity one gets by selling _amount token,
   * then it will initiate a transfer.
   *
   * @param _amount amount of product token wishes to be sold
   *
   * @return price price returned after sold tokens
  */
  function _sell(uint32 _amount) internal virtual returns (uint256 price)
  {
    // calculate amount of liquidity to reimburse
    (uint256 reimburseAmount, uint256 fee) = _sellReturn(_amount);

    reserveBalance = reserveBalance - reimburseAmount;

    _burn(_msgSender(), _amount);

    // 50% of fee, is for supplier
    _updateSupplierFee(fee * FEE_MULTIPLIER / FEE_RATE_IN_SELL);
    // 50% of fee, is for platform
    _updatePlatformFee(fee * (FEE_RATE_IN_SELL - FEE_MULTIPLIER) / FEE_RATE_IN_SELL);

    emit Sell(_msgSender(), _amount, reimburseAmount, fee);

    return (reimburseAmount - fee);
  }

  /**
   * @dev Used internally, when user wants to trade in their token for retail product
   *
   * @param amount_ amount of product token wishes to be redeemed
   *
  */
  function _tradein(uint32 amount_) internal virtual {

    _burn(_msgSender(), amount_);
    // redeem value should give to supplier
    uint256 tradinReturn = _tradinReturn(amount_);

    //redeem value should give to supplier
    _updateSupplierFee(tradinReturn);

    nft.mint(_msgSender(), brandTokenId, amount_, "");

    tradeinCount = tradeinCount + amount_;
    tradeinReserveBalance = tradeinReserveBalance + tradinReturn;

    emit Tradein(_msgSender(), amount_, tradinReturn);
  }

  /**
   * @dev Used internally, to update the transaction fee for supplier. See _buy(), _sell, and _tradein()
   *
   * @param fee_ value to be accumulate
   */
  function _updateSupplierFee(uint256 fee_) internal virtual {
    supplier.amount = supplier.amount + fee_;
  }

  /**
   * @dev Used internally, to update the transaction fee for Highstreet. See _buy(), _sell, and _tradein()
   *
   * @param fee_ value to be accumulate
   */
  function _updatePlatformFee(uint256 fee_) internal virtual {
    platformFee = platformFee + fee_;
  }

  /**
   * @notice Update the address of supplier wallet
   *
   * @dev Only owner and supplier can call this function
   *
   * @param wallet_ supplier address
   */
  function transferSupplier( address wallet_) external virtual {
    require(_msgSender() == owner() || _msgSender() == supplier.wallet, "not allowed");
    require(wallet_!=address(0), "Address is invalid");
    supplier.wallet = wallet_;

    emit UpdateSupplier(wallet_);
  }

  /**
   * @notice Return the transaction fee for supplier
   * @dev The vlaue is included for both transaction fee and tradein value
   *
   * @return amount the token amount that supplier can withdraw
   */
  function getSupplierFee() external view virtual returns(uint256 amount){
    require(_msgSender() == owner() || _msgSender() == supplier.wallet, "not allowed");
    return supplier.amount;
  }

  /**
   * @notice For owner and supplier to check the supplier address
   * @dev Only owner and supplier can call this function
   *
   * @return the wallet address of the supplier
   */
  function getSupplierAddress() external view virtual returns(address){
    require(_msgSender() == owner() || _msgSender() == supplier.wallet, "not allowed");
    return supplier.wallet;
  }

  /**
   * @notice For the supplier to claim their transaction fee
   * @dev Only supplier can call this function
   *
   * @param amount_ the amount of token that supplier would like to withdraw
   */
  function claimSupplierFee(uint256 amount_) external virtual {
    require(_msgSender()  == supplier.wallet, "not allowed");
    require(amount_ <= supplier.amount, "amount is exceed");

    _claim(amount_);
    supplier.amount = supplier.amount - amount_;

    emit ClaimSupplierFee(_msgSender(), amount_);
  }

  /**
   * @notice Return the transaction fee for Highstreet
   * @dev Only owner can call this function
   *
   * @return amount the token amount that Highstreet can withdraw
   */
  function getPlatformFee() external view virtual returns(uint256 amount){
    require(_msgSender() == owner(), "not allowed");
    return platformFee;
  }

  /**
   * @notice For Highstreet to claim the transaction fee
   * @dev Only owner can call this function
   *
   * @param amount_ the amount of token that Highstreet would like to withdraw
   */
  function claimPlatformFee(uint256 amount_) external virtual {
    require(_msgSender() == owner(), "not allowed");
    require(amount_ <= platformFee, "amount is exceed");

    _claim(amount_);
    platformFee = platformFee - amount_;

    emit ClaimPlatformFee(_msgSender(), amount_);
  }

  /**
   * @notice Set token MaxSupply for fixed id in highstreet Brand
   *
   * @dev Only owner can call this function
   *
   * @param amount_ Max amount for tokenId
   */

  function setBrandIdMaxSupply(uint256 amount_) external onlyOwner {
    nft.setMaxSupply(brandTokenId, amount_);
  }

  /**
   * @dev Used internally, mostly by children implementations
   *
   * @param amount_ the token amount would like to claim
   */
  function _claim(uint256 amount_) internal virtual { }

  /**
  *@notice For Emergency operation like we will pause before upgrading contract
  *        thus user would not able to make trade(buy, sell, tradein)
  *@dev Only owner can call this function
  *
  */
  function pause() external onlyOwner{
    _pause();
  }

  /**
  *@notice For Emergency operation like we will pause before upgrading contract
  *        after that we will unpause, then make trade be normal
  *@dev Only owner can call this function
  *
  */
  function unpause() external onlyOwner{
    _unpause();
  }

  /**
    * @dev Testing time-dependent functionality is difficult and the best way of
    *      doing it is to override time in helper test smart contracts
    *
    * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
    */
  function now256() public view virtual returns (uint256) {
    // return current block timestamp
    return block.timestamp;
  }

  /**
  * @notice Service function to update product coolDownTime
  *
  * @dev This function can only be called by Owner 
  *
  * @param time_ an unix timestamp 
  */
  function updateCoolDownTime(uint256 time_) public virtual onlyOwner {
    coolDownTime = time_;
    emit UpdateCoolDownTime(_msgSender(), time_);
  }

  /**
  * @notice Service function to update product endtime
  *
  * @dev This function can only be called by Owner
  *
  * @param set_ a variable to decide which endTime we want to set (buy, sell, tradein
  * @param endTime_ an unix timestamp
  */
  function updateEndTime(uint32 set_, uint256 endTime_) public virtual onlyOwner {
    require(set_ <= FEATURE_ENDTIME_MAX, "invalid type");
    require(endTime_ > now256(), "invalid endTime");

    if(FEATURE_ENDTIME_BUY & set_ == FEATURE_ENDTIME_BUY) {
      endTime[FEATURE_ENDTIME_BUY] = endTime_;
    }
    if(FEATURE_ENDTIME_SELL & set_ == FEATURE_ENDTIME_SELL) {
      endTime[FEATURE_ENDTIME_SELL] = endTime_;
    }
    if(FEATURE_ENDTIME_TRADEIN & set_ == FEATURE_ENDTIME_TRADEIN) {
      endTime[FEATURE_ENDTIME_TRADEIN] = endTime_;
    }
    emit UpdateEndTime(_msgSender(), set_, endTime_);
  }

  /**
   * @notice Service function to update product endtime
   *
   * @dev This function can only be called by Owner
   *
   * @param startTime_ an unix timestamp
   */
  function updateStartTime(uint256 startTime_) public virtual onlyOwner {
    require(startTime_ > now256(), "invalid time");
    startTime = startTime_;
    emit UpdateStartTime(_msgSender(), startTime_);
  }

  /**
    * @inheritdoc ERC20Upgradeable
    *
    * @dev Additionally to the parent smart contract, add cool down time limitation
    * @dev user will not able to transfer within cool down time (for more see buy, sell, transferFrom)
    */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(now256() > coolDownTimes[_msgSender()], "wait to cool down");
    return super.transfer(recipient, amount);
  }

  /**
    * @inheritdoc ERC20Upgradeable
    *
    * @dev Additionally to the parent smart contract, add cool down time limitation
    * @dev user will not able to transferFrom within cool down time (for more see buy, sell, transfer)
    */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    require(now256() > coolDownTimes[sender], "wait to cool down");
    return super.transferFrom(sender, recipient, amount);
  }

  /**
    * @dev  See {UUPSUpgradeable-_authorizeUpgrade}.
    *
    */
  function _authorizeUpgrade(address) internal override onlyOwner {}

  fallback () external { }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./Power.sol"; // Efficient power function.

/**
* @title BancorBondingCurve
* @notice General rule of computation we will use here:
* token amount will be passed in as uint32, since tokens we have are indivisible
* they will be converted to uint256 in function for safemath computation
* if a uint32 variable needs to be returned, it will be computed as uint256 value, then casted explicitly 
* @dev This is an implementation of the Bancor formula with slight modifications.
*/
contract BancorBondingCurve is Power {
  using SafeMathUpgradeable for uint256;
  uint32 private constant MAX_RESERVE_RATIO = 1000000;

  constructor() {
    __Power_init();
  }

  /**
   * @dev Try to compute the price to purchage n token. This is the modified component in addition 
   * to the two original functions below.
   *
   * Formula:
   * Return = _reserveBalance * (((_amount / _supply + 1) ^ (MAX_RESERVE_RATIO / _reserveRatio)) - 1)
   *
   * @param _supply              continuous token total supply
   * @param _reserveBalance     total reserve token balance
   * @param _reserveRatio       the reserve ratio in the bancor curve.
   * @param _amount             number to tokens one wishes to purchase
   *
   *  @return price for N tokens
  */
  function calculatePriceForNTokens(
    uint32 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint32 _amount) external view returns (uint256)
  {
    require(_supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO);
    // special case for 0 tokens
    if (_amount == 0) {
      return 0;
    }
    uint256 supply = uint256(_supply);
    uint256 amount = uint256(_amount);    // amount declared here as an uint256 equivalent of _amount
    // special case if this is a linear function
    if (_reserveRatio == MAX_RESERVE_RATIO) {
      return amount.mul(_reserveBalance).div(supply);
    }

    uint256 result;
    uint8 precision;
    uint256 baseN = amount.add(supply);
    (result, precision) = power(
      baseN, supply, MAX_RESERVE_RATIO, _reserveRatio
    );
    uint256 temp =  _reserveBalance.mul(result) >> precision;
    return temp - _reserveBalance;
  }

  /**
   * @dev given a continuous token supply, reserve token balance, reserve ratio, and a deposit amount (in the reserve token),
   * calculates the return for a given conversion (in the continuous token)
   *
   * Formula:
   * Return = _supply * ((1 + _depositAmount / _reserveBalance) ^ (_reserveRatio / MAX_RESERVE_RATIO) - 1)
   *
   * @param _supply              continuous token total supply
   * @param _reserveBalance    total reserve token balance
   * @param _reserveRatio     reserve ratio, represented in ppm, 1-1000000
   * @param _depositAmount       deposit amount, in reserve token
   *
   *  @return purchase return amount
  */
  // Remember this is a view function. Removed view modifier for testing only
  function calculatePurchaseReturn(
    uint32 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint256 _depositAmount) external view returns (uint32)
  {
    // validate input
    require(_supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO);
     // special case for 0 deposit amount
    if (_depositAmount == 0) {
      return 0;
    }

    uint256 supply = uint256(_supply);

    // special case if the ratio = 100%
    if (_reserveRatio == MAX_RESERVE_RATIO) {
      return uint32(supply.mul(_depositAmount).div(_reserveBalance));
    }

    uint256 result;
    uint8 precision;
    uint256 baseN = _depositAmount.add(_reserveBalance);
    (result, precision) = power(
      baseN, _reserveBalance, _reserveRatio, MAX_RESERVE_RATIO
    );
    uint256 temp = supply.mul(result) >> precision;
    return uint32(temp - supply);
  }

   /**
   * @dev given a continuous token supply, reserve token balance, reserve ratio and a sell amount (in the continuous token),
   * calculates the return for a given conversion (in the reserve token)
   *
   * Formula:
   * Return = _reserveBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_reserveRatio / MAX_RESERVE_RATIO)))
   *
   * @param _supply              continuous token total supply
   * @param _reserveBalance    total reserve token balance
   * @param _reserveRatio     constant reserve ratio, represented in ppm, 1-1000000
   * @param _sellAmount          sell amount, in the continuous token itself
   *
   * @return sale return amount
  */
  function calculateSaleReturn(
    uint32 _supply,
    uint256 _reserveBalance,
    uint32 _reserveRatio,
    uint32 _sellAmount) external view virtual returns (uint256)
  {
    // validate input
    require(_supply > 0 && _reserveBalance > 0 && _reserveRatio > 0 && _reserveRatio <= MAX_RESERVE_RATIO && _sellAmount <= _supply);
     // special case for 0 sell amount
    if (_sellAmount == 0) {
      return 0;
    }

     // special case for selling the entire supply
    if (_sellAmount == _supply) {
      return _reserveBalance;
    }

    uint256 supply = uint256(_supply);
    uint256 sellAmount = uint256(_sellAmount);

     // special case if the ratio = 100%
    if (_reserveRatio == MAX_RESERVE_RATIO) {
      return _reserveBalance.mul(sellAmount).div(supply);
    }
    uint256 result;
    uint8 precision;
    uint256 baseD = supply.sub(sellAmount);
    (result, precision) = power(
      supply, baseD, MAX_RESERVE_RATIO, _reserveRatio
    );
    uint256 oldBalance = _reserveBalance.mul(result);
    uint256 newBalance = _reserveBalance << precision;
    return oldBalance.sub(newBalance).div(result);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/MinterAccessControl.sol";
/**
 * @title Product NFT
 *
 * @notice Each prodcut has its own NFT, will be minted to user when trade in product
 *
 * @notice The tokenId of the NFT is determined according to the order of the tradein
 */
contract HighstreetBrands is Context, ERC1155Burnable, ERC1155Supply, Ownable, MinterAccessControl {

  using Strings for uint256;

  /// @dev a list of maxSupply of corresponding tokenId
  mapping(uint256 => uint256) private _maxSupply;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  event SetMaxSupply(uint256 indexed id, uint256 amount);

  /**
    * @dev Fired in mintBatch()
    *
    * @param to an address which received nfts
    * @param start a first number of this batch
    * @param count a number of of this batch
    */
  event MintBatch(address indexed to, uint256[] start, uint256[] count);

  /**
    * @dev Fired in updateBaseURI()
    *
    * @param sender an address which performed an operation, usually token owner
    * @param uri a stringof base uri for this nft
    */
  event UpdateBaseUri(address indexed sender, string uri);

  /**
    * @dev Creates/deploys an instance of the NFT
    *
    * @param name_ the name of this nft
    * @param symbol_ the symbol of this nft
    * @param uri_ a string of base uri for this nft
    */
  constructor(
    string memory name_,
    string memory symbol_,
    string memory uri_
  ) ERC1155(uri_) {
    _name = name_;
    _symbol = symbol_;
  }

  function name() public view virtual returns (string memory) {
    return _name; 
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return 0;
  }

  function uri(uint256 id_) public view override returns (string memory) {
    require(exists(id_), "URI query for nonexistent token");
    return bytes(super.uri(id_)).length > 0 ? string(abi.encodePacked(super.uri(id_), id_.toString())) : "";
  }

  /**
    * @notice Service function to grant minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is granted minter role
    */
  function grantMinterRole(address addr_) public onlyOwner {
    _grantMinterRole(addr_);
  }

  /**
    * @notice Service function to revoke minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is revorked minter role
    */
  function revokeMinterRole(address addr_) external onlyOwner {
    _revokeMinterRole(addr_);
  }

  /**
    * @notice Service function to update base uri
    *
    * @dev this function can only be called by owner
    *
    * @param uri_ a string for updating base uri
    */
  function updateBaseUri(string memory uri_) external onlyOwner {
    _setURI(uri_);
    emit UpdateBaseUri(_msgSender(), uri_);
  }

  /**
    * @notice Service function to mint nft
    *
    * @dev this function can only be called by minters
    *
    * @param to_ an address which received nft
    * @param id_ a number of id to be minted
    * @param amount_ a number of how much token would be minted
    * @param data_ extra data
    */
  function mint(
    address to_,
    uint256 id_,
    uint256 amount_,
    bytes memory data_
  ) external
    onlyMinter
  {
    _mint(to_, id_, amount_, data_);
  }

  /**
    * @notice Service function to mint nfts at same time
    *
    * @dev this function can only be called by minters
    *
    * @param to_ an address which received nft
    * @param ids_ a first number of this batch
    * @param amounts_ a number of of this batch
    * @param data_ extra data
    */
  function mintBatch(
    address to_,
    uint256[] memory ids_,
    uint256[] memory amounts_,
    bytes memory data_
  ) external
    onlyMinter
  {
    _mintBatch(to_, ids_, amounts_, data_);
  }

  function setMaxSupply(uint256 id_, uint256 amount_) external virtual onlyMinter {
    require(amount_ >= totalSupply(id_), "invalid amount");
    _maxSupply[id_] = amount_;
    emit SetMaxSupply(id_, amount_);
  }

  function maxSupply(uint256 id_) public view returns (uint256) {
    return _maxSupply[id_];
  }

  /**
  *
  * @dev Additionally to the parent smart contract, return string of base uri
  */
  function _baseURI() internal view returns (string memory) {
    return uri(0);
  }

  function _beforeTokenTransfer(
    address operator_, 
    address from_,
    address to_,
    uint256[] memory ids_,
    uint256[] memory amounts_,
    bytes memory data_
  ) internal
    virtual
    override(ERC1155, ERC1155Supply)
  {
    if (from_ == address(0)) {
      for (uint256 i = 0; i < ids_.length; i++) {
        require(
          totalSupply(ids_[i]) + amounts_[i] <= _maxSupply[ids_[i]],
          "cap exceeded"
        );
      }
    }
    super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data_);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * bancor formula by bancor
 * https://github.com/bancorprotocol/contracts
 * Modified from the original by Slava Balasanov
 * Split Power.sol out from BancorFormula.sol
 * Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements;
 * and to You under the Apache License, Version 2.0. "
 */
contract Power is Initializable {
  string public version;

  uint256 private constant ONE = 1;
  uint32 private constant MAX_WEIGHT = 1000000;
  uint8 private constant MIN_PRECISION = 32;
  uint8 private constant MAX_PRECISION = 127;

  /***
  * The values below depend on MAX_PRECISION. If you choose to change it:
  * Apply the same change in file 'PrintIntScalingFactors.py', run it and paste the results below.
  */
  uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
  uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
  uint256 private constant MAX_NUM = 0x1ffffffffffffffffffffffffffffffff;

  /***
  * The values below depend on MAX_PRECISION. If you choose to change it:
  * Apply the same change in file 'PrintLn2ScalingFactors.py', run it and paste the results below.
  */
  uint256 private constant LN2_MANTISSA = 0x2c5c85fdf473de6af278ece600fcbda;
  uint8   private constant LN2_EXPONENT = 122;

  /***
  * The values below depend on MIN_PRECISION and MAX_PRECISION. If you choose to change either one of them:
  * Apply the same change in file 'PrintFunctionBancorFormula.py', run it and paste the results below.
  */
  uint256[128] private maxExpArray;
  function __Power_init() public initializer {
    version = "0.3";
  // constructor () public {
//  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
//  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
//  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
//  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
//  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
//  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
//  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
//  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
//  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
//  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
//  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
//  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
//  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
//  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
//  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
//  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
//  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
//  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
//  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
//  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
//  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
//  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
//  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
//  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
//  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
//  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
//  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
//  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
//  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
//  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
//  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
//  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
    maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
    maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
    maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
    maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
    maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
    maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
    maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
    maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
    maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
    maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
    maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
    maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
    maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
    maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
    maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
    maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
    maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
    maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
    maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
    maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
    maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
    maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
    maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
    maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
    maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
    maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
    maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
    maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
    maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
    maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
    maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
    maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
    maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
    maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
    maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
    maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
    maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
    maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
    maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
    maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
    maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
    maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
    maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
    maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
    maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
    maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
    maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
    maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
    maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
    maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
    maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
    maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
    maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
    maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
    maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
    maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
    maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
    maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
    maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
    maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
    maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
    maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
    maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
    maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
    maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
    maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
    maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
    maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
    maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
    maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
    maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
    maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
    maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
    maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
    maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
    maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
    maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
    maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
    maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
    maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
    maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
    maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
    maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
    maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
    maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
    maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
    maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
    maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
    maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
    maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
    maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
    maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
    maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
    maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
    maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
    maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
  }


  /***
    General Description:
        Determine a value of precision.
        Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
        Return the result along with the precision used.
    Detailed Description:
        Instead of calculating "base ^ exp", we calculate "e ^ (ln(base) * exp)".
        The value of "ln(base)" is represented with an integer slightly smaller than "ln(base) * 2 ^ precision".
        The larger "precision" is, the more accurately this value represents the real value.
        However, the larger "precision" is, the more bits are required in order to store this value.
        And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
        This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
        Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
        This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
  */
  function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
    uint256 lnBaseTimesExp = ln(_baseN, _baseD) * _expN / _expD;
    uint8 precision = findPositionInMaxExpArray(lnBaseTimesExp);
    return (fixedExp(lnBaseTimesExp >> (MAX_PRECISION - precision), precision), precision);
  }

  /***
    Return floor(ln(numerator / denominator) * 2 ^ MAX_PRECISION), where:
    - The numerator   is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
    - The denominator is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
    - The output      is a value between 0 and floor(ln(2 ^ (256 - MAX_PRECISION) - 1) * 2 ^ MAX_PRECISION)
    This functions assumes that the numerator is larger than or equal to the denominator, because the output would be negative otherwise.
  */
  function ln(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
    assert(_numerator <= MAX_NUM);

    uint256 res = 0;
    uint256 x = _numerator * FIXED_1 / _denominator;

    // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
    if (x >= FIXED_2) {
      uint8 count = floorLog2(x / FIXED_1);
      x >>= count; // now x < 2
      res = count * FIXED_1;
    }

    // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
    if (x > FIXED_1) {
      for (uint8 i = MAX_PRECISION; i > 0; --i) {
        x = (x * x) / FIXED_1; // now 1 < x < 4
        if (x >= FIXED_2) {
          x >>= 1; // now 1 < x < 2
          res += ONE << (i - 1);
        }
      }
    }

    return (res * LN2_MANTISSA) >> LN2_EXPONENT;
  }

  /**
  * Compute the largest integer smaller than or equal to the binary logarithm of the input.
  */
  function floorLog2(uint256 _n) internal pure returns (uint8) {
    uint8 res = 0;
    uint256 n = _n;

    if (n < 256) {
      // At most 8 iterations
      while (n > 1) {
        n >>= 1;
        res += 1;
      }
    } else {
      // Exactly 8 iterations
      for (uint8 s = 128; s > 0; s >>= 1) {
        if (n >= (ONE << s)) {
          n >>= s;
          res |= s;
        }
      }
    }

    return res;
  }

  /***
      The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
      - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
      - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
  */
  function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
    uint8 lo = MIN_PRECISION;
    uint8 hi = MAX_PRECISION;

    while (lo + 1 < hi) {
      uint8 mid = (lo + hi) / 2;
      if (maxExpArray[mid] >= _x)
        lo = mid;
      else
        hi = mid;
    }

    if (maxExpArray[hi] >= _x)
        return hi;
    if (maxExpArray[lo] >= _x)
        return lo;

    assert(false);
    return 0;
  }

  /***
      This function can be auto-generated by the script 'PrintFunctionFixedExp.py'.
      It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
      It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
      The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
      The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
  */
  function fixedExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
    uint256 xi = _x;
    uint256 res = 0;

    xi = (xi * _x) >> _precision;
    res += xi * 0x03442c4e6074a82f1797f72ac0000000; // add x^2 * (33! / 2!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0116b96f757c380fb287fd0e40000000; // add x^3 * (33! / 3!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0045ae5bdd5f0e03eca1ff4390000000; // add x^4 * (33! / 4!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000defabf91302cd95b9ffda50000000; // add x^5 * (33! / 5!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0002529ca9832b22439efff9b8000000; // add x^6 * (33! / 6!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000054f1cf12bd04e516b6da88000000; // add x^7 * (33! / 7!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000a9e39e257a09ca2d6db51000000; // add x^8 * (33! / 8!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000012e066e7b839fa050c309000000; // add x^9 * (33! / 9!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000052b6b54569976310000; // add x^17 * (33! / 17!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000004985f67696bf748000; // add x^18 * (33! / 18!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000001317c70077000; // add x^23 * (33! / 23!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000082573a0a00; // add x^25 * (33! / 25!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000005035ad900; // add x^26 * (33! / 26!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x0000000000000000000000002f881b00; // add x^27 * (33! / 27!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000001b29340; // add x^28 * (33! / 28!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x000000000000000000000000000efc40; // add x^29 * (33! / 29!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000007fe0; // add x^30 * (33! / 30!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000420; // add x^31 * (33! / 31!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000021; // add x^32 * (33! / 32!)
    xi = (xi * _x) >> _precision;
    res += xi * 0x00000000000000000000000000000001; // add x^33 * (33! / 33!)

    return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract MinterAccessControl {

  /// @dev a list of minter role, and only minter can mint nft
  mapping(address => bool) public minters;

  /**
    * @dev Fired in grantMinterRole()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param account an address which is granted minter role
    */
  event MinterRoleGranted(address indexed sender, address indexed account);

  /**
    * @dev Fired in revokeMinterRole()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param account an address which is revoked minter role
    */
  event MinterRoleRevoked(address indexed sender, address indexed account);

  /**
    * @notice Service function to grant minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is granted minter role
    */
  function _grantMinterRole(address addr_) internal virtual {
    require(addr_ != address(0), "invalid address");
    minters[addr_] = true;
    emit MinterRoleGranted(msg.sender, addr_);
  }

  /**
    * @notice Service function to revoke minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is revorked minter role
    */
  function _revokeMinterRole(address addr_) internal virtual {
    require(addr_ != address(0), "invalid address");
    minters[addr_] = false;
    emit MinterRoleRevoked(msg.sender, addr_);
  }

  /**
    * @dev Modifier that checks that an account has a minter role.
    *
    */
  modifier onlyMinter() {
      require(minters[msg.sender] == true, "permission denied");
      _;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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