// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../lib/Math.sol";
import "../../interface/IERC20.sol";
import "../../interface/IVeDist.sol";
import "../../interface/IVe.sol";
import "../../lib/SafeERC20.sol";

contract VeDist is IVeDist {
  using SafeERC20 for IERC20;

  event CheckpointToken(
    uint time,
    uint tokens
  );

  event Claimed(
    uint tokenId,
    uint amount,
    uint claimEpoch,
    uint maxEpoch
  );

  struct ClaimCalculationResult {
    uint toDistribute;
    uint userEpoch;
    uint weekCursor;
    uint maxUserEpoch;
    bool success;
  }


  uint constant WEEK = 7 * 86400;

  uint public startTime;
  uint public timeCursor;
  mapping(uint => uint) public timeCursorOf;
  mapping(uint => uint) public userEpochOf;

  uint public lastTokenTime;
  uint[1000000000000000] public tokensPerWeek;

  address public votingEscrow;
  address public token;
  uint public tokenLastBalance;

  uint[1000000000000000] public veSupply;

  address public depositor;

  constructor(address _votingEscrow) {
    uint _t = block.timestamp / WEEK * WEEK;
    startTime = _t;
    lastTokenTime = _t;
    timeCursor = _t;
    address _token = IVe(_votingEscrow).token();
    token = _token;
    votingEscrow = _votingEscrow;
    depositor = msg.sender;
    IERC20(_token).safeIncreaseAllowance(_votingEscrow, type(uint).max);
  }

  function timestamp() external view returns (uint) {
    return block.timestamp / WEEK * WEEK;
  }

  function _checkpointToken() internal {
    uint tokenBalance = IERC20(token).balanceOf(address(this));
    uint toDistribute = tokenBalance - tokenLastBalance;
    tokenLastBalance = tokenBalance;

    uint t = lastTokenTime;
    uint sinceLast = block.timestamp - t;
    lastTokenTime = block.timestamp;
    uint thisWeek = t / WEEK * WEEK;
    uint nextWeek = 0;

    for (uint i = 0; i < 20; i++) {
      nextWeek = thisWeek + WEEK;
      if (block.timestamp < nextWeek) {
        tokensPerWeek[thisWeek] += _adjustToDistribute(toDistribute, block.timestamp, t, sinceLast);
        break;
      } else {
        tokensPerWeek[thisWeek] += _adjustToDistribute(toDistribute, nextWeek, t, sinceLast);
      }
      t = nextWeek;
      thisWeek = nextWeek;
    }
    emit CheckpointToken(block.timestamp, toDistribute);
  }

  /// @dev For testing purposes.
  function adjustToDistribute(
    uint toDistribute,
    uint t0,
    uint t1,
    uint sinceLastCall
  ) external pure returns (uint) {
    return _adjustToDistribute(
      toDistribute,
      t0,
      t1,
      sinceLastCall
    );
  }

  function _adjustToDistribute(
    uint toDistribute,
    uint t0,
    uint t1,
    uint sinceLast
  ) internal pure returns (uint) {
    if (t0 <= t1 || t0 - t1 == 0 || sinceLast == 0) {
      return toDistribute;
    }
    return toDistribute * (t0 - t1) / sinceLast;
  }

  function checkpointToken() external override {
    require(msg.sender == depositor, "!depositor");
    _checkpointToken();
  }

  function _findTimestampEpoch(address ve, uint _timestamp) internal view returns (uint) {
    uint _min = 0;
    uint _max = IVe(ve).epoch();
    for (uint i = 0; i < 128; i++) {
      if (_min >= _max) break;
      uint _mid = (_min + _max + 2) / 2;
      IVe.Point memory pt = IVe(ve).pointHistory(_mid);
      if (pt.ts <= _timestamp) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  function findTimestampUserEpoch(address ve, uint tokenId, uint _timestamp, uint maxUserEpoch) external view returns (uint) {
    return _findTimestampUserEpoch(ve, tokenId, _timestamp, maxUserEpoch);
  }

  function _findTimestampUserEpoch(address ve, uint tokenId, uint _timestamp, uint maxUserEpoch) internal view returns (uint) {
    uint _min = 0;
    uint _max = maxUserEpoch;
    for (uint i = 0; i < 128; i++) {
      if (_min >= _max) break;
      uint _mid = (_min + _max + 2) / 2;
      IVe.Point memory pt = IVe(ve).userPointHistory(tokenId, _mid);
      if (pt.ts <= _timestamp) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  function veForAt(uint _tokenId, uint _timestamp) external view returns (uint) {
    address ve = votingEscrow;
    uint maxUserEpoch = IVe(ve).userPointEpoch(_tokenId);
    uint epoch = _findTimestampUserEpoch(ve, _tokenId, _timestamp, maxUserEpoch);
    IVe.Point memory pt = IVe(ve).userPointHistory(_tokenId, epoch);
    return uint(int256(Math.positiveInt128(pt.bias - pt.slope * (int128(int256(_timestamp - pt.ts))))));
  }

  function _checkpointTotalSupply() internal {
    address ve = votingEscrow;
    uint t = timeCursor;
    uint roundedTimestamp = block.timestamp / WEEK * WEEK;
    IVe(ve).checkpoint();

    // assume will be called more frequently than 20 weeks
    for (uint i = 0; i < 20; i++) {
      if (t > roundedTimestamp) {
        break;
      } else {
        uint epoch = _findTimestampEpoch(ve, t);
        IVe.Point memory pt = IVe(ve).pointHistory(epoch);
        veSupply[t] = _adjustVeSupply(t, pt.ts, pt.bias, pt.slope);
      }
      t += WEEK;
    }
    timeCursor = t;
  }

  function adjustVeSupply(uint t, uint ptTs, int128 ptBias, int128 ptSlope) external pure returns (uint) {
    return _adjustVeSupply(t, ptTs, ptBias, ptSlope);
  }

  function _adjustVeSupply(uint t, uint ptTs, int128 ptBias, int128 ptSlope) internal pure returns (uint) {
    if (t < ptTs) {
      return 0;
    }
    int128 dt = int128(int256(t - ptTs));
    if (ptBias < ptSlope * dt) {
      return 0;
    }
    return uint(int256(Math.positiveInt128(ptBias - ptSlope * dt)));
  }

  function checkpointTotalSupply() external override {
    _checkpointTotalSupply();
  }

  function _claim(uint _tokenId, address ve, uint _lastTokenTime) internal returns (uint) {
    ClaimCalculationResult memory result = _calculateClaim(_tokenId, ve, _lastTokenTime);
    if (result.success) {
      userEpochOf[_tokenId] = result.userEpoch;
      timeCursorOf[_tokenId] = result.weekCursor;
      emit Claimed(_tokenId, result.toDistribute, result.userEpoch, result.maxUserEpoch);
    }
    return result.toDistribute;
  }

  function _calculateClaim(uint _tokenId, address ve, uint _lastTokenTime) internal view returns (ClaimCalculationResult memory) {
    uint userEpoch;
    uint toDistribute;
    uint maxUserEpoch = IVe(ve).userPointEpoch(_tokenId);
    uint _startTime = startTime;

    if (maxUserEpoch == 0) {
      return ClaimCalculationResult(0, 0, 0, 0, false);
    }

    uint weekCursor = timeCursorOf[_tokenId];

    if (weekCursor == 0) {
      userEpoch = _findTimestampUserEpoch(ve, _tokenId, _startTime, maxUserEpoch);
    } else {
      userEpoch = userEpochOf[_tokenId];
    }

    if (userEpoch == 0) userEpoch = 1;

    IVe.Point memory userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
    if (weekCursor == 0) {
      weekCursor = (userPoint.ts + WEEK - 1) / WEEK * WEEK;
    }
    if (weekCursor >= lastTokenTime) {
      return ClaimCalculationResult(0, 0, 0, 0, false);
    }
    if (weekCursor < _startTime) {
      weekCursor = _startTime;
    }

    IVe.Point memory oldUserPoint;
    {
      for (uint i = 0; i < 50; i++) {
        if (weekCursor >= _lastTokenTime) {
          break;
        }
        if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
          userEpoch += 1;
          oldUserPoint = userPoint;
          if (userEpoch > maxUserEpoch) {
            userPoint = IVe.Point(0, 0, 0, 0);
          } else {
            userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
          }
        } else {
          int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
          uint balanceOf = uint(int256(Math.positiveInt128(oldUserPoint.bias - dt * oldUserPoint.slope)));
          if (balanceOf == 0 && userEpoch > maxUserEpoch) {
            break;
          }
          toDistribute += balanceOf * tokensPerWeek[weekCursor] / veSupply[weekCursor];
          weekCursor += WEEK;
        }
      }
    }
    return ClaimCalculationResult(
      toDistribute,
      Math.min(maxUserEpoch, userEpoch - 1),
      weekCursor,
      maxUserEpoch,
      true
    );
  }

  function claimable(uint _tokenId) external view returns (uint) {
    uint _lastTokenTime = lastTokenTime / WEEK * WEEK;
    ClaimCalculationResult memory result = _calculateClaim(_tokenId, votingEscrow, _lastTokenTime);
    return result.toDistribute;
  }

  function claim(uint _tokenId) external returns (uint) {
    if (block.timestamp >= timeCursor) _checkpointTotalSupply();
    uint _lastTokenTime = lastTokenTime;
    _lastTokenTime = _lastTokenTime / WEEK * WEEK;
    uint amount = _claim(_tokenId, votingEscrow, _lastTokenTime);
    if (amount != 0) {
      IVe(votingEscrow).depositFor(_tokenId, amount);
      tokenLastBalance -= amount;
    }
    return amount;
  }

  function claimMany(uint[] memory _tokenIds) external returns (bool) {
    if (block.timestamp >= timeCursor) _checkpointTotalSupply();
    uint _lastTokenTime = lastTokenTime;
    _lastTokenTime = _lastTokenTime / WEEK * WEEK;
    address _votingEscrow = votingEscrow;
    uint total = 0;

    for (uint i = 0; i < _tokenIds.length; i++) {
      uint _tokenId = _tokenIds[i];
      if (_tokenId == 0) break;
      uint amount = _claim(_tokenId, _votingEscrow, _lastTokenTime);
      if (amount != 0) {
        IVe(_votingEscrow).depositFor(_tokenId, amount);
        total += amount;
      }
    }
    if (total != 0) {
      tokenLastBalance -= total;
    }

    return true;
  }

  // Once off event on contract initialize
  function setDepositor(address _depositor) external {
    require(msg.sender == depositor, "!depositor");
    depositor = _depositor;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library Math {

  function max(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function positiveInt128(int128 value) internal pure returns (int128) {
    return value < 0 ? int128(0) : value;
  }

  function closeTo(uint a, uint b, uint target) internal pure returns (bool) {
    if (a > b) {
      if (a - b <= target) {
        return true;
      }
    } else {
      if (b - a <= target) {
        return true;
      }
    }
    return false;
  }

  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
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

pragma solidity ^0.8.13;

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

pragma solidity ^0.8.13;

interface IVeDist {

  function checkpointToken() external;

  function checkpointTotalSupply() external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVe {

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  struct LockedBalance {
    int128 amount;
    uint end;
  }

  function token() external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(uint, uint, address) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function depositFor(uint tokenId, uint value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.13;

import "../interface/IERC20.sol";
import "./Address.sol";

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
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
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
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.13;

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

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call(data);
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