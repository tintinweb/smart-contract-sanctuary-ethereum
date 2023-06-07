/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;

  function pushManagement(address newOwner_) external;

  function pullManagement() external;
}

contract Ownable is IOwnable {
  address internal _owner;
  address internal _newOwner;

  event OwnershipPushed(
    address indexed previousOwner,
    address indexed newOwner
  );
  event OwnershipPulled(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
    emit OwnershipPushed(address(0), _owner);
  }

  function policy() public view override returns (address) {
    return _owner;
  }

  modifier onlyPolicy() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceManagement() public virtual override onlyPolicy {
    emit OwnershipPushed(_owner, address(0));
    _owner = address(0);
  }

  function pushManagement(
    address newOwner_
  ) public virtual override onlyPolicy {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipPushed(_owner, newOwner_);
    _newOwner = newOwner_;
  }

  function pullManagement() public virtual override {
    require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
    emit OwnershipPulled(_owner, _newOwner);
    _owner = _newOwner;
  }
}

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
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  function sqrrt(uint256 a) internal pure returns (uint c) {
    if (a > 3) {
      c = a;
      uint b = add(div(a, 2), 1);
      while (b < c) {
        c = b;
        b = div(add(div(a, b), b), 2);
      }
    } else if (a != 0) {
      c = 1;
    }
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
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

  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function addressToString(
    address _address
  ) internal pure returns (string memory) {
    bytes32 _bytes = bytes32(uint256(_address));
    bytes memory HEX = "0123456789abcdef";
    bytes memory _addr = new bytes(42);

    _addr[0] = "0";
    _addr[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
      _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
      _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }

    return string(_addr);
  }
}

interface IERC20 {
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

library FullMath {
  function fullMul(
    uint256 x,
    uint256 y
  ) private pure returns (uint256 l, uint256 h) {
    uint256 mm = mulmod(x, y, uint256(-1));
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
    uint256 pow2 = d & -d;
    d /= pow2;
    l /= pow2;
    l += h * ((-pow2) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);
    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;
    require(h < d, "FullMath::mulDiv: overflow");
    return fullDiv(l, h, d);
  }
}

library FixedPoint {
  struct uq112x112 {
    uint224 _x;
  }

  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode112with18(
    uq112x112 memory self
  ) internal pure returns (uint256) {
    return uint256(self._x) / 5192296858534827;
  }

  function fraction(
    uint256 numerator,
    uint256 denominator
  ) internal pure returns (uq112x112 memory) {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= uint144(-1)) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= uint224(-1), "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= uint224(-1), "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

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

  constructor() internal {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
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

interface IBurnable {
  function burnFrom(address sender, uint256 amount) external;
}

contract FHMToBLNCBondDepository is Ownable, ReentrancyGuard {
  using FixedPoint for *;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /* ======== EVENTS ======== */

  event BondCreated(
    uint256 deposit,
    uint256 indexed payout,
    uint256 indexed expires,
    uint256 indexed priceInBLNC
  );
  event BondRedeemed(
    address indexed recipient,
    uint256 payout,
    uint256 remaining
  );
  event BondPriceChanged(
    uint256 indexed priceInBLNC,
    uint256 indexed internalPrice,
    uint256 indexed debtRatio
  );

  /* ======== STATE VARIABLES ======== */

  address public immutable FHM;
  address public immutable BLNC;
  address public immutable DAO;

  Terms public terms; // stores terms for new bonds

  mapping(address => Bond) public bondInfo; // stores bond information for depositors

  uint256 public totalDebt; // total value of outstanding bonds; used for pricing
  uint256 public lastDecay; // reference block for debt decay

  SoldBonds[] public soldBondsInHour;
  uint256 public totalSold;

  /* ======== STRUCTS ======== */

  // Info for creating new bonds
  struct Terms {
    uint256 rfvExpireAt; // in timestamp
    uint256 expireAt; // in timestamp
    uint256 vestingTerm; // in blocks
    uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
    uint256 fee; // as % of bond payout, in hundreds. ( 500 = 5% = 0.05 for every 1 paid)
    uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    uint256 soldBondsLimitUsd; //
  }

  // Info for bond holder
  struct Bond {
    uint256 payout; // BLNC to be paid
    uint256 vesting; // Blocks left to vest
    uint256 lastBlock; // Last interaction
    uint256 pricePaid; // In BLNC, for front end viewing
  }

  struct SoldBonds {
    uint256 timestampFrom;
    uint256 timestampTo;
    uint256 payoutInUsd;
  }

  /* ======== INITIALIZATION ======== */

  constructor(
    address _FHM,
    address _BLNC,
    address _DAO
  ) {
    require(_FHM != address(0));
    FHM = _FHM;
    require(_BLNC != address(0));
    BLNC = _BLNC;
    require(_DAO != address(0));
    DAO = _DAO;
  }

  /**
   *  @notice initializes bond parameters
   *  @param _vestingTerm uint256
   *  @param _maxPayout uint256
   *  @param _fee uint256
   *  @param _maxDebt uint256
   *  @param _initialDebt uint256
   *  @param _soldBondsLimitUsd uint256
   */
  function initializeBondTerms(
    uint256 _rfvExpireAt,
    uint256 _expireAt,
    uint256 _vestingTerm,
    uint256 _maxPayout,
    uint256 _fee,
    uint256 _maxDebt,
    uint256 _initialDebt,
    uint256 _soldBondsLimitUsd
  ) external onlyPolicy {
    terms = Terms({
      rfvExpireAt: _rfvExpireAt,
      expireAt: _expireAt,
      vestingTerm: _vestingTerm,
      maxPayout: _maxPayout,
      fee: _fee,
      maxDebt: _maxDebt,
      soldBondsLimitUsd: _soldBondsLimitUsd
    });
    totalDebt = _initialDebt;
    lastDecay = block.number;
  }

  /* ======== POLICY FUNCTIONS ======== */

  enum PARAMETER {
    VESTING,
    PAYOUT,
    FEE,
    DEBT,
    EXPIRATION,
    RFVEXPIRATION
  }

  /**
   *  @notice set parameters for new bonds
   *  @param _parameter PARAMETER
   *  @param _input uint256
   */
  function setBondTerms(
    PARAMETER _parameter,
    uint256 _input
  ) external onlyPolicy {
    if (_parameter == PARAMETER.VESTING) {
      // 0
      require(_input >= 10000, "Vesting must be longer than 10000 blocks");
      terms.vestingTerm = _input;
    } else if (_parameter == PARAMETER.PAYOUT) {
      // 1
      require(_input <= 1000, "Payout cannot be above 1 percent");
      terms.maxPayout = _input;
    } else if (_parameter == PARAMETER.FEE) {
      // 2
      require(_input <= 10000, "DAO fee cannot exceed payout");
      terms.fee = _input;
    } else if (_parameter == PARAMETER.DEBT) {
      // 3
      terms.maxDebt = _input;
    } else if (_parameter == PARAMETER.EXPIRATION) {
      // 4
      terms.expireAt = _input;
    } else if (_parameter == PARAMETER.RFVEXPIRATION) {
      // 5
      terms.rfvExpireAt = _input;
    }
  }

  /* ======== USER FUNCTIONS ======== */

  /**
   *  @notice deposit and redeem bond
   *  @param _amount uint256
   *  @param _maxPrice uint256
   *  @param _depositor address
   *  @return uint256
   */
  function depositAndRedeem(
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor
  ) external nonReentrant returns (uint256) {
    _deposit(_amount, _maxPrice, _depositor);
    return _redeem(_depositor, false);
  }

  /**
   *  @notice deposit bond
   *  @param _amount uint256
   *  @param _maxPrice uint256
   *  @param _depositor address
   *  @return uint256
   */
  function deposit(
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor
  ) external nonReentrant returns (uint256) {
    return _deposit(_amount, _maxPrice, _depositor);
  }

  function _deposit(
    uint256 _amount,
    uint256 _maxPrice,
    address _depositor
  ) private returns (uint256) {
    require(block.timestamp < terms.expireAt, "Bond Expired");
    require(_depositor != address(0), "Invalid address");

    decayDebt();
    require(totalDebt <= terms.maxDebt, "Max capacity reached");

    uint256 priceInUSD = bondPriceInBLNC(); // Stored in bond info
    uint256 nativePrice = _bondPrice();

    require(_maxPrice >= nativePrice, "Slippage limit: more than max price"); // slippage protection

    uint256 payout = payoutFor(_amount); // payout to bonder is computed

    require(payout >= 0.01 ether, "Bond too small"); // must be > 0.01 usd ( underflow protection )
    require(payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage
    require(!circuitBreakerActivated(payout), "CIRCUIT_BREAKER_ACTIVE"); //

    uint256 payoutInFhm = _amount;

    IERC20(BLNC).safeTransferFrom(DAO, address(this), payout);

    // live long and prosper!
    IBurnable(FHM).burnFrom(msg.sender, payoutInFhm);

    // total debt is increased
    totalDebt = totalDebt.add(payout);
    // total sold is increased
    totalSold = totalSold.add(payout);

    // update sold bonds
    updateSoldBonds(payout);

    // depositor info is stored
    bondInfo[_depositor] = Bond({
      payout: bondInfo[_depositor].payout.add(payout),
      vesting: terms.vestingTerm,
      lastBlock: block.number,
      pricePaid: priceInUSD
    });

    // indexed events are emitted
    emit BondCreated(
      _amount,
      payout,
      block.number.add(terms.vestingTerm),
      priceInUSD
    );
    emit BondPriceChanged(bondPriceInBLNC(), _bondPrice(), debtRatio());

    return payout;
  }

  /**
  *  @notice redeem bond for user
   *  @param _recipient address
   *  @param _stake bool
   *  @return uint256
   */
  function redeem(address _recipient, bool _stake) external returns (uint256) {
    return _redeem(_recipient, _stake);
  }

  function _redeem(address _recipient, bool _stake) private returns (uint256) {
    _stake; // no code
    Bond memory info = bondInfo[_recipient];
    uint256 percentVested = percentVestedFor(_recipient); // (blocks since last interaction / vesting term remaining)

    require(percentVested >= 10000, "Wait for end of bond");

    delete bondInfo[_recipient]; // delete user info
    emit BondRedeemed(_recipient, info.payout, 0); // emit bond data

    IERC20(BLNC).transfer(_recipient, info.payout); // pay user everything due

    return info.payout;
  }

  /* ======== INTERNAL HELPER FUNCTIONS ======== */

  function updateSoldBonds(uint256 _payout) internal {
    uint256 length = soldBondsInHour.length;
    if (length == 0) {
      soldBondsInHour.push(
        SoldBonds({
          timestampFrom: block.timestamp,
          timestampTo: block.timestamp.add(1 hours),
          payoutInUsd: _payout
        })
      );
      return;
    }

    SoldBonds storage soldBonds = soldBondsInHour[length.sub(1)];
    // update in existing interval
    if (
      soldBonds.timestampFrom < block.timestamp &&
      soldBonds.timestampTo >= block.timestamp
    ) {
      soldBonds.payoutInUsd = soldBonds.payoutInUsd.add(_payout);
    } else {
      // create next interval if its continuous
      uint256 nextTo = soldBonds.timestampTo.add(1 hours);
      if (block.timestamp <= nextTo) {
        soldBondsInHour.push(
          SoldBonds({
            timestampFrom: soldBonds.timestampTo,
            timestampTo: nextTo,
            payoutInUsd: _payout
          })
        );
      } else {
        soldBondsInHour.push(
          SoldBonds({
            timestampFrom: block.timestamp,
            timestampTo: block.timestamp.add(1 hours),
            payoutInUsd: _payout
          })
        );
      }
    }
  }

  function circuitBreakerCurrentPayout() public view returns (uint256 _amount) {
    if (soldBondsInHour.length == 0) return 0;

    uint256 max = 0;
    if (soldBondsInHour.length >= 24) max = soldBondsInHour.length.sub(24);

    uint256 to = block.timestamp;
    uint256 from = to.sub(24 hours);
    for (uint256 i = max; i < soldBondsInHour.length; i++) {
      SoldBonds memory soldBonds = soldBondsInHour[i];
      if (soldBonds.timestampFrom >= from && soldBonds.timestampFrom <= to) {
        _amount = _amount.add(soldBonds.payoutInUsd);
      }
    }

    return _amount;
  }

  function circuitBreakerActivated(uint256 payout) public view returns (bool) {
    payout = payout.add(circuitBreakerCurrentPayout());
    return payout > terms.soldBondsLimitUsd;
  }

  function getBLNCPrice() public view returns (uint256 _marketPrice) {
    if (block.timestamp < terms.rfvExpireAt) {
      return 105; // 1.05 BLNC
    } else {
      return 100; // 1 BLNC
    }
  }

  /**
   *  @notice reduce total debt
   */
  function decayDebt() internal {
    totalDebt = totalDebt.sub(debtDecay());
    lastDecay = block.number;
  }

  /* ======== VIEW FUNCTIONS ======== */

  /**
   *  @notice determine maximum bond size
   *  @return uint256
   */
  function maxPayout() public view returns (uint256) {
    return IERC20(BLNC).totalSupply().mul(terms.maxPayout).div(100000);
  }

  /**
   *  @notice calculate interest due for new bond
   *  @param _fhmValue uint256 fhm value
   *  @return uint256 usdb value
   */
  function payoutFor(uint256 _fhmValue) public view returns (uint256) {
    return _fhmValue.mul(bondPrice()).mul(1e7);
  }

  /**
   *  @notice calculate current bond premium
   *  @return price_ uint256
   */
  function bondPrice() public view returns (uint256 price_) {
    return _bondPrice();
  }

  /**
   *  @notice calculate current bond price and remove floor if above
   *  @return price_ uint256
   */
  function _bondPrice() internal view returns (uint256 price_) {
    return getBLNCPrice();
  }

  /**
   *  @notice converts bond price to BLNC value
   *  @return price_ uint256
   */
  function bondPriceInBLNC() public view returns (uint256 price_) {
    price_ = bondPrice().mul(10 ** IERC20(BLNC).decimals()).div(100);
  }

  /**
   *  @notice calculate current ratio of debt to FHM supply
   *  @return debtRatio_ uint256
   */
  function debtRatio() public view returns (uint256 debtRatio_) {
    uint256 supply = IERC20(BLNC).totalSupply();
    debtRatio_ = FixedPoint
      .fraction(currentDebt().mul(1e9), supply)
      .decode112with18()
      .div(1e18);
  }

  /**
   *  @notice debt ratio in same terms for reserve or liquidity bonds
   *  @return uint256
   */
  function standardizedDebtRatio() external view returns (uint256) {
    return debtRatio();
  }

  /**
   *  @notice calculate debt factoring in decay
   *  @return uint256
   */
  function currentDebt() public view returns (uint256) {
    return totalDebt.sub(debtDecay());
  }

  /**
   *  @notice amount to decay total debt by
   *  @return decay_ uint256
   */
  function debtDecay() public view returns (uint256 decay_) {
    uint256 blocksSinceLast = block.number.sub(lastDecay);
    decay_ = totalDebt.mul(blocksSinceLast).div(terms.vestingTerm);
    if (decay_ > totalDebt) {
      decay_ = totalDebt;
    }
  }

  /**
   *  @notice calculate how far into vesting a depositor is
   *  @param _depositor address
   *  @return percentVested_ uint256
   */
  function percentVestedFor(
    address _depositor
  ) public view returns (uint256 percentVested_) {
    Bond memory bond = bondInfo[_depositor];
    uint256 blocksSinceLast = block.number.sub(bond.lastBlock);
    uint256 vesting = bond.vesting;

    if (vesting > 0) {
      percentVested_ = blocksSinceLast.mul(10000).div(vesting);
    } else {
      percentVested_ = 10000;
    }
  }

  /**
   *  @notice calculate amount of FHM available for claim by depositor
   *  @param _depositor address
   *  @return pendingPayout_ uint256
   */
  function pendingPayoutFor(
    address _depositor
  ) external view returns (uint256 pendingPayout_) {
    uint256 percentVested = percentVestedFor(_depositor);
    uint256 payout = bondInfo[_depositor].payout;

    if (percentVested >= 10000) {
      pendingPayout_ = payout;
    } else {
      pendingPayout_ = 0;
    }
  }

  /* ======= AUXILLIARY ======= */

  /**
   *  @notice allow anyone to send lost tokens (excluding BLNC or FHM) to the DAO
   *  @return bool
   */
  function recoverLostToken(address _token) external returns (bool) {
    require(_token != FHM);
    require(_token != BLNC);
    IERC20(_token).safeTransfer(DAO, IERC20(_token).balanceOf(address(this)));
    return true;
  }
}