// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SignedWadMath.sol";

/** @title EthCurve Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract EthCurve is Ownable {
  bool public _initialized;
  uint256 public _count;
  uint256 public _decimals = 18;

  int256 public _posFeePercent18;
  int256 public _b18; //Min price, 18 decimals
  int256 public _L18; //Max price, 18 decimals
  int256 public _k18; //Slope, 18 decimals
  int256 public _m18; //Phase, 18 decimals

  uint256 public _lastReset;//block height of last reset
  uint256 public _resetInterval = 1;//100800;//number of 12second blocks in 2 weeks
  //int256 public _resetPriceMulitple;
  //int256 public _resetPriceThreshold;

  address public _BondingCurveAddress;


  modifier onlyBondingCurve() {
    require(msg.sender == _BondingCurveAddress, "only BC");
    _;
  }

  constructor() Ownable() {
    _lastReset = block.number;
  }

  function initialize(int256 L_, int256 k_, uint256 m_, int256 b_, int256 posPercent_) external onlyOwner() {
    require(!_initialized, "already");
    //Set default params
    _L18 = SignedWadMath.wadDiv(L_, 100);//1
    _k18 = SignedWadMath.wadDiv(k_, 10000);//0
    _m18 = SignedWadMath.toWadUnsafe(m_);//8888
    _b18 = SignedWadMath.wadDiv(b_, 1000);//0.065
    _posFeePercent18 = SignedWadMath.wadDiv(posPercent_, 100);//0.95

    //_resetPriceMulitple = SignedWadMath.wadDiv(resetPriceMultiple_, 100);//0.99
    //_resetPriceThreshold = SignedWadMath.wadMul(_resetPriceMulitple, _b18);

    /*TODO:un-uncomment*/
    //_initialized = true;
  }

  function setBondingCurve(address BondingCurveAddress_) external onlyOwner() {
    _BondingCurveAddress = BondingCurveAddress_;
  }


  function getPosFeePercent18() external view returns(int256){
    return _posFeePercent18;
  }

  function getCount() external view returns(uint256) {
    return _count;
  }


  function getNewReserve(int256 b18_, int256 posFeePercent18_) public view returns(uint256 newReserve) {
    //require reserveBalance >= newReserve == (b x supply) x (1 - pos)
    int256 oneMinusPos18 = SignedWadMath.toWadUnsafe(1) - posFeePercent18_;
    int256 bTimesSupply = SignedWadMath.wadMul(b18_, SignedWadMath.toWadUnsafe(_count));
    newReserve = uint256(SignedWadMath.wadMul(bTimesSupply, oneMinusPos18));
  }

  /**
   * Resets curve, updates params, and returns minimum reserve value.
   */
  function resetCurve(int256 k18_, int256 L18_, int256 b18_, int256 posFeePercent18_, uint256 _reserveBalance) external onlyBondingCurve returns(uint256 newReserve) {
    //require price is above threshold == resetPriceMulitple_ x _b18
    //_resetPriceThreshold = SignedWadMath.wadMul(_resetPriceMulitple, _b18);
    //require(getMintPrice(_count) >= uint256(_resetPriceThreshold), "insufficient price");

    //require time interval for reset
    uint256 blockInterval = block.number - _lastReset;
    require(blockInterval >= _resetInterval, "not yet");
    _lastReset = block.number;

    //require reserveBalance >= newReserve == (b x supply) x (1 - pos)
    //int256 oneMinusPos18 = SignedWadMath.toWadUnsafe(1) - _posFeePercent18;
    //int256 bTimesSupply = SignedWadMath.wadMul(b18_, SignedWadMath.toWadUnsafe(_count));
    //newReserve = uint256(SignedWadMath.wadMul(bTimesSupply, oneMinusPos18));
    newReserve = getNewReserve(b18_, posFeePercent18_);
    require(_reserveBalance >= newReserve, "Insuff reserve");

    //Reset can now proceed, all validations passed

    //calculate new m value
    //m = (ln[(L / b) - 1 ] + k * x) / k
    int256 kx18 = SignedWadMath.wadMul(k18_, SignedWadMath.toWadUnsafe(_count));
    int256 LOverB18 = SignedWadMath.wadDiv(L18_, b18_);
    int256 lnVar18 = LOverB18 - SignedWadMath.toWadUnsafe(1);
    int256 ln18 = SignedWadMath.wadLn(lnVar18);
    int256 numerator18 = ln18 + kx18;
    _m18 = SignedWadMath.wadDiv(numerator18, k18_);

    //update curve params
    _k18 = k18_;
    _L18 = L18_;
    _b18 = b18_;

    //_resetPriceMulitple = resetPriceMulitple_;
    //_resetPriceThreshold = SignedWadMath.wadMul(_resetPriceMulitple, _b18);
    _posFeePercent18 = posFeePercent18_;
  }

  function incrementCount(uint256 _amount) external onlyBondingCurve() {
    _count += _amount;
  }

  function decrementCount() external onlyBondingCurve() {
    _count--;
  }

  function getNextBurnReward() public view returns(uint256 reward) {
    return getBurnReward(_count);
  }

  //Must divide price by decimals to get value in ETH
  function getBurnReward(uint256 _x) public view returns(uint256 price) {
    uint256 mintPrice18 = getMintPrice(_x);

    int256 burnPercent18 = SignedWadMath.toWadUnsafe(1) - int256(_posFeePercent18);
    int256 burnPrice18 = SignedWadMath.wadMul(burnPercent18, int256(mintPrice18));

    return uint256(burnPrice18);
  }

  function getNextMintPrice() public view returns(uint256 price) {
    return getMintPrice(_count + 1);
  }

  //Must divide price by decimals to get value in ETH
  function getMintPrice(uint256 _x) public view returns(uint256 price) {
    // Formula: L / [1 + (1/e^(k * [x - m])) ]
    int256 x18 = SignedWadMath.toWadUnsafe(_x);
    int256 diff;
    int256 pow;
    int256 expo;

    if(x18 > _m18){//1/e
      diff = x18 - _m18;
      pow = SignedWadMath.wadMul(_k18, diff);
      expo = SignedWadMath.wadExp(pow);
      expo = SignedWadMath.wadDiv(SignedWadMath.toWadUnsafe(1), expo);
    }else{//e
      diff = _m18 - x18;
      pow = SignedWadMath.wadMul(_k18, diff);
      expo = SignedWadMath.wadExp(pow);
    }

    int256 denom = SignedWadMath.toWadUnsafe(1) + expo;
    int256 a = SignedWadMath.wadDiv(_L18, denom);

    price = uint256(_max(a, _b18));
  }

  function _max(int256 a, int256 b) internal pure returns (int256) {
    return a >= b ? a : b;
  }

}//end

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)
library SignedWadMath{
  /// @dev Will not revert on overflow, only use where overflow is not possible.
  function toWadUnsafe(uint256 x) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 1e18.
          r := mul(x, 1000000000000000000)
      }
  }

  /// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
  /// @dev Will not revert on overflow, only use where overflow is not possible.
  /// @dev Not meant for negative second amounts, it assumes x is positive.
  function toDaysWadUnsafe(uint256 x) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 1e18 and then divide it by 86400.
          r := div(mul(x, 1000000000000000000), 86400)
      }
  }

  /// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
  /// @dev Will not revert on overflow, only use where overflow is not possible.
  /// @dev Not meant for negative day amounts, it assumes x is positive.
  function fromDaysWadUnsafe(int256 x) public pure returns (uint256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 86400 and then divide it by 1e18.
          r := div(mul(x, 86400), 1000000000000000000)
      }
  }

  /// @dev Will not revert on overflow, only use where overflow is not possible.
  function unsafeWadMul(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by y and divide by 1e18.
          r := sdiv(mul(x, y), 1000000000000000000)
      }
  }

  /// @dev Will return 0 instead of reverting if y is zero and will
  /// not revert on overflow, only use where overflow is not possible.
  function unsafeWadDiv(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Multiply x by 1e18 and divide it by y.
          r := sdiv(mul(x, 1000000000000000000), y)
      }
  }

  function wadMul(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Store x * y in r for now.
          r := mul(x, y)

          // Equivalent to require(x == 0 || (x * y) / x == y)
          if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
              revert(0, 0)
          }

          // Scale the result down by 1e18.
          r := sdiv(r, 1000000000000000000)
      }
  }

  function wadDiv(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Store x * 1e18 in r for now.
          r := mul(x, 1000000000000000000)

          // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
          if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
              revert(0, 0)
          }

          // Divide r by y.
          r := sdiv(r, y)
      }
  }

  /// @dev Will not work with negative bases, only use when x is positive.
  function wadPow(int256 x, int256 y) public pure returns (int256) {
      // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
      return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
  }

  function wadExp(int256 x) public pure returns (int256 r) {
      unchecked {
          // When the result is < 0.5 we return zero. This happens when
          // x <= floor(log(0.5e18) * 1e18) ~ -42e18
          if (x <= -42139678854452767551) return 0;

          // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
          // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
          if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

          // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
          // for more intermediate precision and a binary basis. This base conversion
          // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
          x = (x << 78) / 5**18;

          // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
          // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
          // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
          int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
          x = x - k * 54916777467707473351141471128;

          // k is in the range [-61, 195].

          // Evaluate using a (6, 7)-term rational approximation.
          // p is made monic, we'll multiply by a scale factor later.
          int256 y = x + 1346386616545796478920950773328;
          y = ((y * x) >> 96) + 57155421227552351082224309758442;
          int256 p = y + x - 94201549194550492254356042504812;
          p = ((p * y) >> 96) + 28719021644029726153956944680412240;
          p = p * x + (4385272521454847904659076985693276 << 96);

          // We leave p in 2**192 basis so we don't need to scale it back up for the division.
          int256 q = x - 2855989394907223263936484059900;
          q = ((q * x) >> 96) + 50020603652535783019961831881945;
          q = ((q * x) >> 96) - 533845033583426703283633433725380;
          q = ((q * x) >> 96) + 3604857256930695427073651918091429;
          q = ((q * x) >> 96) - 14423608567350463180887372962807573;
          q = ((q * x) >> 96) + 26449188498355588339934803723976023;

          /// @solidity memory-safe-assembly
          assembly {
              // Div in assembly because solidity adds a zero check despite the unchecked.
              // The q polynomial won't have zeros in the domain as all its roots are complex.
              // No scaling is necessary because p is already 2**96 too large.
              r := sdiv(p, q)
          }

          // r should be in the range (0.09, 0.25) * 2**96.

          // We now need to multiply r by:
          // * the scale factor s = ~6.031367120.
          // * the 2**k factor from the range reduction.
          // * the 1e18 / 2**96 factor for base conversion.
          // We do this all at once, with an intermediate result in 2**213
          // basis, so the final right shift is always by a positive amount.
          r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
      }
  }

  function wadLn(int256 x) public pure returns (int256 r) {
      unchecked {
          require(x > 0, "UNDEFINED");

          // We want to convert x from 10**18 fixed point to 2**96 fixed point.
          // We do this by multiplying by 2**96 / 10**18. But since
          // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
          // and add ln(2**96 / 10**18) at the end.

          /// @solidity memory-safe-assembly
          assembly {
              r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
              r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
              r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
              r := or(r, shl(4, lt(0xffff, shr(r, x))))
              r := or(r, shl(3, lt(0xff, shr(r, x))))
              r := or(r, shl(2, lt(0xf, shr(r, x))))
              r := or(r, shl(1, lt(0x3, shr(r, x))))
              r := or(r, lt(0x1, shr(r, x)))
          }

          // Reduce range of x to (1, 2) * 2**96
          // ln(2^k * x) = k * ln(2) + ln(x)
          int256 k = r - 96;
          x <<= uint256(159 - k);
          x = int256(uint256(x) >> 159);

          // Evaluate using a (8, 8)-term rational approximation.
          // p is made monic, we will multiply by a scale factor later.
          int256 p = x + 3273285459638523848632254066296;
          p = ((p * x) >> 96) + 24828157081833163892658089445524;
          p = ((p * x) >> 96) + 43456485725739037958740375743393;
          p = ((p * x) >> 96) - 11111509109440967052023855526967;
          p = ((p * x) >> 96) - 45023709667254063763336534515857;
          p = ((p * x) >> 96) - 14706773417378608786704636184526;
          p = p * x - (795164235651350426258249787498 << 96);

          // We leave p in 2**192 basis so we don't need to scale it back up for the division.
          // q is monic by convention.
          int256 q = x + 5573035233440673466300451813936;
          q = ((q * x) >> 96) + 71694874799317883764090561454958;
          q = ((q * x) >> 96) + 283447036172924575727196451306956;
          q = ((q * x) >> 96) + 401686690394027663651624208769553;
          q = ((q * x) >> 96) + 204048457590392012362485061816622;
          q = ((q * x) >> 96) + 31853899698501571402653359427138;
          q = ((q * x) >> 96) + 909429971244387300277376558375;
          /// @solidity memory-safe-assembly
          assembly {
              // Div in assembly because solidity adds a zero check despite the unchecked.
              // The q polynomial is known not to have zeros in the domain.
              // No scaling required because p is already 2**96 too large.
              r := sdiv(p, q)
          }

          // r is in the range (0, 0.125) * 2**96

          // Finalization, we need to:
          // * multiply by the scale factor s = 5.549…
          // * add ln(2**96 / 10**18)
          // * add k * ln(2)
          // * multiply by 10**18 / 2**96 = 5**18 >> 78

          // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
          r *= 1677202110996718588342820967067443963516166;
          // add ln(2) * k * 5e18 * 2**192
          r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
          // add ln(2**96 / 10**18) * 5e18 * 2**192
          r += 600920179829731861736702779321621459595472258049074101567377883020018308;
          // base conversion: mul 2**18 / 2**192
          r >>= 174;
      }
  }

  /// @dev Will return 0 instead of reverting if y is zero.
  function unsafeDiv(int256 x, int256 y) public pure returns (int256 r) {
      /// @solidity memory-safe-assembly
      assembly {
          // Divide x by y.
          r := sdiv(x, y)
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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