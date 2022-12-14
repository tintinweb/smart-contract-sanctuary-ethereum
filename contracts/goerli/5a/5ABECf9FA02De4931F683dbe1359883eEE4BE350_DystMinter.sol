// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../lib/Math.sol";
import "../../lib/SafeERC20.sol";
import "../../interface/IUnderlying.sol";
import "../../interface/IVoter.sol";
import "../../interface/IVe.sol";
import "../../interface/IVeDist.sol";
import "../../interface/IMinter.sol";
import "../../interface/IERC20.sol";
import "../../interface/IController.sol";

/// @title Codifies the minting rules as per ve(3,3),
///        abstracted from the token to support any token that allows minting
contract DystMinter is IMinter {
  using SafeERC20 for IERC20;

  /// @dev Allows minting once per week (reset every Thursday 00:00 UTC)
  uint internal constant _WEEK = 86400 * 7;
  uint internal constant _LOCK_PERIOD = 86400 * 7 * 52 * 4;

  /// @dev Decrease base weekly emission by 2%
  uint internal constant _WEEKLY_EMISSION_DECREASE = 98;
  uint internal constant _WEEKLY_EMISSION_DECREASE_DENOMINATOR = 100;


  /// @dev Weekly emission threshold for the end game. 1% of circulation supply.
  uint internal constant _TAIL_EMISSION = 1;
  uint internal constant _TAIL_EMISSION_DENOMINATOR = 100;

  /// @dev Decrease weekly rewards for ve holders. 10% of the full amount.
  uint internal constant _GROWTH_DIVIDER = 10;

  /// @dev Decrease initialStubCirculationSupply by 1% per week.
  ///      Decreasing only if circulation supply lower that the stub circulation
  uint internal constant _INITIAL_CIRCULATION_DECREASE = 99;
  uint internal constant _INITIAL_CIRCULATION_DECREASE_DENOMINATOR = 100;

  /// @dev Stubbed initial circulating supply to avoid first weeks gaps of locked amounts.
  ///      Should be equal expected unlocked token percent.
  uint internal constant _STUB_CIRCULATION = 10;
  uint internal constant _STUB_CIRCULATION_DENOMINATOR = 100;

  /// @dev The core parameter for determinate the whole emission dynamic.
  ///       Will be decreased every week.
  uint internal constant _START_BASE_WEEKLY_EMISSION = 20_000_000e18;


  IUnderlying public immutable token;
  IVe public immutable ve;
  address public immutable controller;
  uint public baseWeeklyEmission = _START_BASE_WEEKLY_EMISSION;
  uint public initialStubCirculation;
  uint public activePeriod;

  address internal initializer;

  event Mint(
    address indexed sender,
    uint weekly,
    uint growth,
    uint circulatingSupply,
    uint circulatingEmission
  );

  constructor(
    address ve_, // the ve(3,3) system that will be locked into
    address controller_, // controller with veDist and voter addresses
    uint warmingUpPeriod // 2 by default
  ) {
    initializer = msg.sender;
    token = IUnderlying(IVe(ve_).token());
    ve = IVe(ve_);
    controller = controller_;
    activePeriod = (block.timestamp + (warmingUpPeriod * _WEEK)) / _WEEK * _WEEK;
  }

  /// @dev Mint initial supply to holders and lock it to ve token.
  function initialize(
    address[] memory claimants,
    uint[] memory amounts,
    uint totalAmount
  ) external {
    require(initializer == msg.sender, "Not initializer");
    token.mint(address(this), totalAmount);
    initialStubCirculation = totalAmount * _STUB_CIRCULATION / _STUB_CIRCULATION_DENOMINATOR;
    token.approve(address(ve), type(uint).max);
    uint sum;
    for (uint i = 0; i < claimants.length; i++) {
      ve.createLockFor(amounts[i], _LOCK_PERIOD, claimants[i]);
      sum += amounts[i];
    }
    require(sum == totalAmount, "Wrong totalAmount");
    initializer = address(0);
    activePeriod = (block.timestamp + _WEEK) / _WEEK * _WEEK;
  }

  function _veDist() internal view returns (IVeDist) {
    return IVeDist(IController(controller).veDist());
  }

  function _voter() internal view returns (IVoter) {
    return IVoter(IController(controller).voter());
  }

  /// @dev Calculate circulating supply as total token supply - locked supply - veDist balance - minter balance
  function circulatingSupply() external view returns (uint) {
    return _circulatingSupply();
  }

  function _circulatingSupply() internal view returns (uint) {
    return token.totalSupply() - IUnderlying(address(ve)).totalSupply()
    // exclude veDist token balance from circulation - users unable to claim them without lock
    // late claim will lead to wrong circulation supply calculation
    - token.balanceOf(address(_veDist()))
    // exclude balance on minter, it is obviously locked
    - token.balanceOf(address(this));
  }

  function _circulatingSupplyAdjusted() internal view returns (uint) {
    // we need a stub supply for cover initial gap when huge amount of tokens was distributed and locked
    return Math.max(_circulatingSupply(), initialStubCirculation);
  }

  /// @dev Emission calculation is 2% of available supply to mint adjusted by circulating / total supply
  function calculateEmission() external view returns (uint) {
    return _calculateEmission();
  }

  function _calculateEmission() internal view returns (uint) {
    // use adjusted circulation supply for avoid first weeks gaps
    // baseWeeklyEmission should be decrease every week
    return baseWeeklyEmission * _circulatingSupplyAdjusted() / token.totalSupply();
  }

  /// @dev Weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
  function weeklyEmission() external view returns (uint) {
    return _weeklyEmission();
  }

  function _weeklyEmission() internal view returns (uint) {
    return Math.max(_calculateEmission(), _circulatingEmission());
  }

  /// @dev Calculates tail end (infinity) emissions as 0.2% of total supply
  function circulatingEmission() external view returns (uint) {
    return _circulatingEmission();
  }

  function _circulatingEmission() internal view returns (uint) {
    return _circulatingSupply() * _TAIL_EMISSION / _TAIL_EMISSION_DENOMINATOR;
  }

  /// @dev Calculate inflation and adjust ve balances accordingly
  function calculateGrowth(uint _minted) external view returns (uint) {
    return _calculateGrowth(_minted);
  }

  function _calculateGrowth(uint _minted) internal view returns (uint) {
    return IUnderlying(address(ve)).totalSupply() * _minted / token.totalSupply() / _GROWTH_DIVIDER;
  }

  /// @dev Update period can only be called once per cycle (1 week)
  function updatePeriod() external override returns (uint) {
    uint _period = activePeriod;
    // only trigger if new week
    if (block.timestamp >= _period + _WEEK && initializer == address(0)) {
      _period = block.timestamp / _WEEK * _WEEK;
      activePeriod = _period;
      uint _weekly = _weeklyEmission();
      // slightly decrease weekly emission
      baseWeeklyEmission = baseWeeklyEmission
      * _WEEKLY_EMISSION_DECREASE
      / _WEEKLY_EMISSION_DECREASE_DENOMINATOR;
      // decrease stub supply every week if it higher than the real circulation
      if (initialStubCirculation > _circulatingEmission()) {
        initialStubCirculation = initialStubCirculation
        * _INITIAL_CIRCULATION_DECREASE
        / _INITIAL_CIRCULATION_DECREASE_DENOMINATOR;
      }

      uint _growth = _calculateGrowth(_weekly);
      uint _required = _growth + _weekly;
      uint _balanceOf = token.balanceOf(address(this));
      if (_balanceOf < _required) {
        token.mint(address(this), _required - _balanceOf);
      }

      IERC20(address(token)).safeTransfer(address(_veDist()), _growth);
      // checkpoint token balance that was just minted in veDist
      _veDist().checkpointToken();
      // checkpoint supply
      _veDist().checkpointTotalSupply();

      token.approve(address(_voter()), _weekly);
      _voter().notifyRewardAmount(_weekly);

      emit Mint(msg.sender, _weekly, _growth, _circulatingSupply(), _circulatingEmission());
    }
    return _period;
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

pragma solidity ^0.8.13;

interface IUnderlying {
  function approve(address spender, uint value) external returns (bool);

  function mint(address, uint) external;

  function totalSupply() external view returns (uint);

  function balanceOf(address) external view returns (uint);

  function transfer(address, uint) external returns (bool);

  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoter {

  function ve() external view returns (address);

  function attachTokenToGauge(uint _tokenId, address account) external;

  function detachTokenFromGauge(uint _tokenId, address account) external;

  function emitDeposit(uint _tokenId, address account, uint amount) external;

  function emitWithdraw(uint _tokenId, address account, uint amount) external;

  function distribute(address _gauge) external;

  function notifyRewardAmount(uint amount) external;

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

pragma solidity ^0.8.13;

interface IVeDist {

  function checkpointToken() external;

  function checkpointTotalSupply() external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMinter {

  function updatePeriod() external returns (uint);

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

interface IController {

  function veDist() external view returns (address);

  function voter() external view returns (address);

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