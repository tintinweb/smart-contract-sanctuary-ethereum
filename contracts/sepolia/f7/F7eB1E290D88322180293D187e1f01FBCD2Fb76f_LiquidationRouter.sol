// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { LiquidationPair } from "./LiquidationPair.sol";
import { LiquidationPairFactory } from "./LiquidationPairFactory.sol";

/**
 * @title PoolTogether Liquidation Router
 * @author PoolTogether Inc. Team
 * @notice A router to swap tokens via LiquidationPair contracts.
 */
contract LiquidationRouter {
  using SafeERC20 for IERC20;

  /* ============ Events ============ */

  /**
   * @notice Emitted when a LiquidationRouter is created.
   * @param liquidationPairFactory The address of the LiquidationPairFactory.
   */
  event LiquidationRouterCreated(LiquidationPairFactory indexed liquidationPairFactory);

  /* ============ Variables ============ */
  LiquidationPairFactory internal immutable _liquidationPairFactory;

  /* ============ Constructor ============ */

  /**
   * @notice Creates a new LiquidationRouter.
   * @param liquidationPairFactory_ The address of the LiquidationPairFactory.
   */
  constructor(LiquidationPairFactory liquidationPairFactory_) {
    require(address(liquidationPairFactory_) != address(0), "LR/LPF-not-address-zero");
    _liquidationPairFactory = liquidationPairFactory_;

    emit LiquidationRouterCreated(liquidationPairFactory_);
  }

  /* ============ Modifiers ============ */

  /**
   * @notice Checks if the LiquidationPair is deployed via the LiquidationPairFactory.
   * @param _liquidationPair The LiquidationPair to check.
   */
  modifier onlyTrustedLiquidationPair(LiquidationPair _liquidationPair) {
    require(_liquidationPairFactory.deployedPairs(_liquidationPair), "LR/LP-not-from-LPF");
    _;
  }

  /* ============ External Methods ============ */

  /**
   * @notice Swaps an exact amount of token in for a minimum amount of token out.
   * @dev The caller must approve the LiquidationPairRouter to transfer the token in.
   * @param _liquidationPair The LiquidationPair to use.
   * @param _receiver The address to receive the swapped tokens.
   * @param _amountIn The amount of token in to swap in.
   * @param _amountOutMin The minimum amount of token out to receive.
   * @return The amount of token out received.
   */
  function swapExactAmountIn(
    LiquidationPair _liquidationPair,
    address _receiver,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) external onlyTrustedLiquidationPair(_liquidationPair) returns (uint256) {
    IERC20(_liquidationPair.tokenIn()).safeTransferFrom(
      msg.sender,
      _liquidationPair.target(),
      _amountIn
    );

    return _liquidationPair.swapExactAmountIn(_receiver, _amountIn, _amountOutMin);
  }

  /**
   * @notice Swaps a maximum amount of token in for an exact amount of token out.
   * @dev The caller must approve the LiquidationPairRouter to transfer the token in.
   * @param _liquidationPair The LiquidationPair to use.
   * @param _receiver The address to receive the swapped tokens.
   * @param _amountOut The amount of token out to receive.
   * @param _amountInMax  The maximum amount of token in to swap in.
   * @return The amount of token in swapped.
   */
  function swapExactAmountOut(
    LiquidationPair _liquidationPair,
    address _receiver,
    uint256 _amountOut,
    uint256 _amountInMax
  ) external onlyTrustedLiquidationPair(_liquidationPair) returns (uint256) {
    IERC20(_liquidationPair.tokenIn()).safeTransferFrom(
      msg.sender,
      _liquidationPair.target(),
      _liquidationPair.computeExactAmountIn(_amountOut)
    );

    return _liquidationPair.swapExactAmountOut(_receiver, _amountOut, _amountInMax);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./libraries/LiquidatorLib.sol";
import "./libraries/FixedMathLib.sol";
import "./interfaces/ILiquidationSource.sol";
import { Math } from "openzeppelin/utils/math/Math.sol";

/**
 * @title PoolTogether Liquidation Pair
 * @author PoolTogether Inc. Team
 * @notice The LiquidationPair is a UniswapV2-like pair that allows the liquidation of tokens
 *          from an ILiquidationSource. Users can swap tokens in exchange for the tokens available.
 *          The LiquidationPair implements a virtual reserve system that results in the value
 *          tokens available from the ILiquidationSource to decay over time relative to the value
 *          of the token swapped in.
 * @dev Each swap consists of four steps:
 *       1. A virtual buyback of the tokens available from the ILiquidationSource. This ensures
 *          that the value of the tokens available from the ILiquidationSource decays as
 *          tokens accrue.
 *      2. The main swap of tokens the user requested.
 *      3. A virtual swap that is a small multiplier applied to the users swap. This is to
 *          push the value of the tokens being swapped back up towards the market value.
 *      4. A scaling of the virtual reserves. This is to ensure that the virtual reserves
 *          are large enough such that the next swap will have a realistic impact on the virtual
 *          reserves.
 */
contract LiquidationPair {
  /* ============ Variables ============ */

  ILiquidationSource public immutable source;
  address public immutable tokenIn;
  address public immutable tokenOut;
  UFixed32x4 public immutable swapMultiplier;
  UFixed32x4 public immutable liquidityFraction;

  uint128 public virtualReserveIn;
  uint128 public virtualReserveOut;
  uint256 public immutable minK;

  /* ============ Events ============ */

  /**
   * @notice Emitted when the pair is swapped.
   * @param account The account that swapped.
   * @param amountIn The amount of token in swapped.
   * @param amountOut The amount of token out swapped.
   * @param virtualReserveIn The updated virtual reserve of the token in.
   * @param virtualReserveOut The updated virtual reserve of the token out.
   */
  event Swapped(
    address indexed account,
    uint256 amountIn,
    uint256 amountOut,
    uint128 virtualReserveIn,
    uint128 virtualReserveOut
  );

  /* ============ Constructor ============ */

  /**
   * @notice Construct a new LiquidationPair.
   * @param _source The source of yield for the liquidation pair.
   * @param _tokenIn The token to be swapped in.
   * @param _tokenOut The token to be swapped out.
   * @param _swapMultiplier The multiplier for the users swaps.
   * @param _liquidityFraction The liquidity fraction to be applied after swapping.
   * @param _virtualReserveIn The initial virtual reserve of token in.
   * @param _virtualReserveOut The initial virtual reserve of token out.
   * @param _minK The minimum value of k.
   * @dev The swap multiplier and liquidity fraction are represented as UFixed32x4.
   */
  constructor(
    ILiquidationSource _source,
    address _tokenIn,
    address _tokenOut,
    UFixed32x4 _swapMultiplier,
    UFixed32x4 _liquidityFraction,
    uint128 _virtualReserveIn,
    uint128 _virtualReserveOut,
    uint256 _minK
  ) {
    require(
      UFixed32x4.unwrap(_liquidityFraction) > 0,
      "LiquidationPair/liquidity-fraction-greater-than-zero"
    );
    require(
      UFixed32x4.unwrap(_liquidityFraction) > 0,
      "LiquidationPair/liquidity-fraction-greater-than-zero"
    );
    require(
      UFixed32x4.unwrap(_swapMultiplier) <= 1e4,
      "LiquidationPair/swap-multiplier-less-than-one"
    );
    require(
      UFixed32x4.unwrap(_liquidityFraction) <= 1e4,
      "LiquidationPair/liquidity-fraction-less-than-one"
    );
    require(
      uint256(_virtualReserveIn) * _virtualReserveOut >= _minK,
      "LiquidationPair/virtual-reserves-greater-than-min-k"
    );
    require(_minK > 0, "LiquidationPair/min-k-greater-than-zero");
    require(_virtualReserveIn <= type(uint112).max, "LiquidationPair/virtual-reserve-in-too-large");
    require(
      _virtualReserveOut <= type(uint112).max,
      "LiquidationPair/virtual-reserve-out-too-large"
    );

    source = _source;
    tokenIn = _tokenIn;
    tokenOut = _tokenOut;
    swapMultiplier = _swapMultiplier;
    liquidityFraction = _liquidityFraction;
    virtualReserveIn = _virtualReserveIn;
    virtualReserveOut = _virtualReserveOut;
    minK = _minK;
  }

  /* ============ External Methods ============ */
  /* ============ Read Methods ============ */

  /**
   * @notice Get the address that will receive `tokenIn`.
   * @return Address of the target
   */
  function target() external view returns (address) {
    return source.targetOf(tokenIn);
  }

  /**
   * @notice Computes the maximum amount of tokens that can be swapped in given the current state of the liquidation pair.
   * @return The maximum amount of tokens that can be swapped in.
   */
  function maxAmountIn() external view returns (uint256) {
    return
      LiquidatorLib.computeExactAmountIn(
        virtualReserveIn,
        virtualReserveOut,
        _availableReserveOut(),
        _availableReserveOut()
      );
  }

  /**
   * @notice Gets the maximum amount of tokens that can be swapped out from the source.
   * @return The maximum amount of tokens that can be swapped out.
   */
  function maxAmountOut() external view returns (uint256) {
    return _availableReserveOut();
  }

  /**
   * @notice Computes the virtual reserves post virtual buyback of all available liquidity that has accrued.
   * @return The virtual reserve of the token in.
   * @return The virtual reserve of the token out.
   */
  function nextLiquidationState() external view returns (uint128, uint128) {
    return
      LiquidatorLib._virtualBuyback(virtualReserveIn, virtualReserveOut, _availableReserveOut());
  }

  /**
   * @notice Computes the exact amount of tokens to send in for the given amount of tokens to receive out.
   * @param _amountOut The amount of tokens to receive out.
   * @return The amount of tokens to send in.
   */
  function computeExactAmountIn(uint256 _amountOut) external view returns (uint256) {
    return
      LiquidatorLib.computeExactAmountIn(
        virtualReserveIn,
        virtualReserveOut,
        _availableReserveOut(),
        _amountOut
      );
  }

  /**
   * @notice Computes the exact amount of tokens to receive out for the given amount of tokens to send in.
   * @param _amountIn The amount of tokens to send in.
   * @return The amount of tokens to receive out.
   */
  function computeExactAmountOut(uint256 _amountIn) external view returns (uint256) {
    return
      LiquidatorLib.computeExactAmountOut(
        virtualReserveIn,
        virtualReserveOut,
        _availableReserveOut(),
        _amountIn
      );
  }

  /* ============ Write Methods ============ */

  /**
   * @notice Swaps the given amount of tokens in and ensures a minimum amount of tokens are received out.
   * @dev The amount of tokens being swapped in must be sent to the target before calling this function.
   * @param _account The address to send the tokens to.
   * @param _amountIn The amount of tokens sent in.
   * @param _amountOutMin The minimum amount of tokens to receive out.
   * @return The amount of tokens received out.
   */
  function swapExactAmountIn(
    address _account,
    uint256 _amountIn,
    uint256 _amountOutMin
  ) external returns (uint256) {
    uint256 availableBalance = _availableReserveOut();
    (uint128 _virtualReserveIn, uint128 _virtualReserveOut, uint256 amountOut) = LiquidatorLib
      .swapExactAmountIn(
        virtualReserveIn,
        virtualReserveOut,
        availableBalance,
        _amountIn,
        swapMultiplier,
        liquidityFraction,
        minK
      );

    virtualReserveIn = _virtualReserveIn;
    virtualReserveOut = _virtualReserveOut;

    require(amountOut >= _amountOutMin, "LiquidationPair/min-not-guaranteed");
    _swap(_account, amountOut, _amountIn);

    emit Swapped(_account, _amountIn, amountOut, _virtualReserveIn, _virtualReserveOut);

    return amountOut;
  }

  /**
   * @notice Swaps the given amount of tokens out and ensures the amount of tokens in doesn't exceed the given maximum.
   * @dev The amount of tokens being swapped in must be sent to the target before calling this function.
   * @param _account The address to send the tokens to.
   * @param _amountOut The amount of tokens to receive out.
   * @param _amountInMax The maximum amount of tokens to send in.
   * @return The amount of tokens sent in.
   */
  function swapExactAmountOut(
    address _account,
    uint256 _amountOut,
    uint256 _amountInMax
  ) external returns (uint256) {
    uint256 availableBalance = _availableReserveOut();
    (uint128 _virtualReserveIn, uint128 _virtualReserveOut, uint256 amountIn) = LiquidatorLib
      .swapExactAmountOut(
        virtualReserveIn,
        virtualReserveOut,
        availableBalance,
        _amountOut,
        swapMultiplier,
        liquidityFraction,
        minK
      );
    virtualReserveIn = _virtualReserveIn;
    virtualReserveOut = _virtualReserveOut;
    require(amountIn <= _amountInMax, "LiquidationPair/max-not-guaranteed");
    _swap(_account, _amountOut, amountIn);

    emit Swapped(_account, amountIn, _amountOut, _virtualReserveIn, _virtualReserveOut);

    return amountIn;
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Gets the available liquidity that has accrued that users can swap for.
   * @return The available liquidity that users can swap for.
   */
  function _availableReserveOut() internal view returns (uint256) {
    return source.liquidatableBalanceOf(tokenOut);
  }

  /**
   * @notice Sends the provided amounts of tokens to the address given.
   * @param _account The address to send the tokens to.
   * @param _amountOut The amount of tokens to receive out.
   * @param _amountIn The amount of tokens sent in.
   */
  function _swap(address _account, uint256 _amountOut, uint256 _amountIn) internal {
    source.liquidate(_account, tokenIn, _amountIn, tokenOut, _amountOut);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./LiquidationPair.sol";

/**
 * @title PoolTogether Liquidation Pair Factory
 * @author PoolTogether Inc. Team
 * @notice A facotry to deploy LiquidationPair contracts.
 */
contract LiquidationPairFactory {
  /* ============ Events ============ */

  /**
   * @notice Emitted when a LiquidationPair is deployed.
   * @param liquidator The address of the LiquidationPair.
   * @param source The address of the ILiquidationSource.
   * @param tokenIn The address of the tokenIn.
   * @param tokenOut The address of the tokenOut.
   * @param swapMultiplier The swap multiplier.
   * @param liquidityFraction The liquidity fraction.
   * @param virtualReserveIn The initial virtual reserve in.
   * @param virtualReserveOut The initial virtual reserve out.
   * @param minK The minimum K value.
   */
  event PairCreated(
    LiquidationPair indexed liquidator,
    ILiquidationSource indexed source,
    address indexed tokenIn,
    address tokenOut,
    UFixed32x4 swapMultiplier,
    UFixed32x4 liquidityFraction,
    uint128 virtualReserveIn,
    uint128 virtualReserveOut,
    uint256 minK
  );

  /* ============ Variables ============ */
  LiquidationPair[] public allPairs;

  /* ============ Mappings ============ */

  /**
   * @notice Mapping to verify if a LiquidationPair has been deployed via this factory.
   * @dev LiquidationPair address => boolean
   */
  mapping(LiquidationPair => bool) public deployedPairs;

  /* ============ External Functions ============ */

  /**
   * @notice Deploys a new LiquidationPair contract.
   * @param _source The source of yield for hte liquidation pair
   * @param _tokenIn The token to be swapped in.
   * @param _tokenOut The token to be swapped out.
   * @param _swapMultiplier The swap multiplier.
   * @param _liquidityFraction The liquidity fraction to be applied after swapping.
   * @param _virtualReserveIn The initial virtual reserve of token in.
   * @param _virtualReserveOut The initial virtual reserve of token out.
   * @param _mink The minimum K value.
   */
  function createPair(
    ILiquidationSource _source,
    address _tokenIn,
    address _tokenOut,
    UFixed32x4 _swapMultiplier,
    UFixed32x4 _liquidityFraction,
    uint128 _virtualReserveIn,
    uint128 _virtualReserveOut,
    uint256 _mink
  ) external returns (LiquidationPair) {
    LiquidationPair _liquidationPair = new LiquidationPair(
      _source,
      _tokenIn,
      _tokenOut,
      _swapMultiplier,
      _liquidityFraction,
      _virtualReserveIn,
      _virtualReserveOut,
      _mink
    );

    allPairs.push(_liquidationPair);
    deployedPairs[_liquidationPair] = true;

    emit PairCreated(
      _liquidationPair,
      _source,
      _tokenIn,
      _tokenOut,
      _swapMultiplier,
      _liquidityFraction,
      _virtualReserveIn,
      _virtualReserveOut,
      _mink
    );

    return _liquidationPair;
  }

  /**
   * @notice Total number of LiquidationPair deployed by this factory.
   * @return Number of LiquidationPair deployed by this factory.
   */
  function totalPairs() external view returns (uint256) {
    return allPairs.length;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "openzeppelin/token/ERC20/IERC20.sol";

import "./FixedMathLib.sol";

/**
 * @title PoolTogether Liquidator Library
 * @author PoolTogether Inc. Team
 * @notice A library to perform swaps on a UniswapV2-like pair of tokens. Implements logic that
 *          manipulates the token reserve amounts on swap.
 * @dev Each swap consists of four steps:
 *       1. A virtual buyback of the tokens available from the ILiquidationSource. This ensures
 *          that the value of the tokens available from the ILiquidationSource decays as
 *          tokens accrue.
 *      2. The main swap of tokens the user requested.
 *      3. A virtual swap that is a small multiplier applied to the users swap. This is to
 *          push the value of the tokens being swapped back up towards the market value.
 *      4. A scaling of the virtual reserves. This is to ensure that the virtual reserves
 *          are large enough such that the next swap will have a tailored impact on the virtual
 *          reserves.
 * @dev Numbered suffixes are used to identify the underlying token used for the parameter.
 *      For example, `amountIn1` and `reserve1` are the same token where `amountIn0` is different.
 */
library LiquidatorLib {
  /**
   * @notice Computes the amount of tokens that will be received for a given amount of tokens sent.
   * @param amountIn1 The amount of token 1 being sent in
   * @param reserve1 The amount of token 1 in the reserves
   * @param reserve0 The amount of token 0 in the reserves
   * @return amountOut0 The amount of token 0 that will be received given the amount in of token 1
   */
  function getAmountOut(
    uint256 amountIn1,
    uint128 reserve1,
    uint128 reserve0
  ) internal pure returns (uint256 amountOut0) {
    require(reserve0 > 0 && reserve1 > 0, "LiquidatorLib/insufficient-reserve-liquidity-a");
    uint256 numerator = amountIn1 * reserve0;
    uint256 denominator = amountIn1 + reserve1;
    amountOut0 = numerator / denominator;
    return amountOut0;
  }

  /**
   * @notice Computes the amount of tokens required to be sent in to receive a given amount of
   *          tokens.
   * @param amountOut0 The amount of token 0 to receive
   * @param reserve1 The amount of token 1 in the reserves
   * @param reserve0 The amount of token 0 in the reserves
   * @return amountIn1 The amount of token 1 needed to receive the given amount out of token 0
   */
  function getAmountIn(
    uint256 amountOut0,
    uint128 reserve1,
    uint128 reserve0
  ) internal pure returns (uint256 amountIn1) {
    require(amountOut0 < reserve0, "LiquidatorLib/insufficient-reserve-liquidity-c");
    require(reserve0 > 0 && reserve1 > 0, "LiquidatorLib/insufficient-reserve-liquidity-d");
    uint256 numerator = amountOut0 * reserve1;
    uint256 denominator = uint256(reserve0) - amountOut0;
    amountIn1 = (numerator / denominator) + 1;
  }

  /**
   * @notice Performs a swap of all of the available tokens from the ILiquidationSource which
   *          impacts the virtual reserves resulting in price decay as tokens accrue.
   * @param _reserve0 The amount of token 0 in the reserve
   * @param _reserve1 The amount of token 1 in the reserve
   * @param _amountIn1 The amount of token 1 to buy back
   * @return reserve0 The new amount of token 0 in the reserves
   * @return reserve1 The new amount of token 1 in the reserves
   */
  function _virtualBuyback(
    uint128 _reserve0,
    uint128 _reserve1,
    uint256 _amountIn1
  ) internal pure returns (uint128 reserve0, uint128 reserve1) {
    uint256 amountOut0 = getAmountOut(_amountIn1, _reserve1, _reserve0);
    reserve0 = _reserve0 - uint128(amountOut0);
    reserve1 = _reserve1 + uint128(_amountIn1);
  }

  /**
   * @notice Amplifies the users swap by a multiplier and then scales reserves to a configured ratio.
   * @param _reserve0 The amount of token 0 in the reserves
   * @param _reserve1 The amount of token 1 in the reserves
   * @param _amountIn1 The amount of token 1 to swap in
   * @param _amountOut1 The amount of token 1 to swap out
   * @param _swapMultiplier The multiplier to apply to the swap
   * @param _liquidityFraction The fraction relative to the amount of token 1 to scale the reserves to
   * @param _minK The minimum value of K to ensure that the reserves are not scaled too small
   * @return reserve0 The new amount of token 0 in the reserves
   * @return reserve1 The new amount of token 1 in the reserves
   */
  function _virtualSwap(
    uint128 _reserve0,
    uint128 _reserve1,
    uint256 _amountIn1,
    uint256 _amountOut1,
    UFixed32x4 _swapMultiplier,
    UFixed32x4 _liquidityFraction,
    uint256 _minK
  ) internal pure returns (uint128 reserve0, uint128 reserve1) {
    uint256 virtualAmountOut1 = FixedMathLib.mul(_amountOut1, _swapMultiplier);

    uint256 virtualAmountIn0 = 0;
    if (virtualAmountOut1 < _reserve1) {
      // Sufficient reserves to handle the multiplier on the swap
      virtualAmountIn0 = getAmountIn(virtualAmountOut1, _reserve0, _reserve1);
    } else if (virtualAmountOut1 > 0 && _reserve1 > 1) {
      // Insuffucuent reserves in so cap it to max amount
      virtualAmountOut1 = _reserve1 - 1;
      virtualAmountIn0 = getAmountIn(virtualAmountOut1, _reserve0, _reserve1);
    } else {
      // Insufficient reserves
      // _reserve1 is 1, virtualAmountOut1 is 0
      virtualAmountOut1 = 0;
    }

    reserve0 = _reserve0 + uint128(virtualAmountIn0);
    reserve1 = _reserve1 - uint128(virtualAmountOut1);

    (reserve0, reserve1) = _applyLiquidityFraction(
      reserve0,
      reserve1,
      _amountIn1,
      _liquidityFraction,
      _minK
    );
  }

  /**
   * @notice Scales the reserves to a configured ratio.
   * @dev This is to ensure that the virtual reserves are large enough such that the next swap will
   *      have a tailored impact on the virtual reserves.
   * @param _reserve0 The amount of token 0 in the reserves
   * @param _reserve1 The amount of token 1 in the reserves
   * @param _amountIn1 The amount of token 1 swapped in
   * @param _liquidityFraction The fraction relative to the amount in of token 1 to scale the
   *                            reserves to
   * @param _minK The minimum value of K to validate the scaled reserves against
   * @return reserve0 The new amount of token 0 in the reserves
   * @return reserve1 The new amount of token 1 in the reserves
   */
  function _applyLiquidityFraction(
    uint128 _reserve0,
    uint128 _reserve1,
    uint256 _amountIn1,
    UFixed32x4 _liquidityFraction,
    uint256 _minK
  ) internal pure returns (uint128 reserve0, uint128 reserve1) {
    uint256 reserve0_1 = (uint256(_reserve0) * _amountIn1 * FixedMathLib.multiplier) /
      (uint256(_reserve1) * UFixed32x4.unwrap(_liquidityFraction));
    uint256 reserve1_1 = FixedMathLib.div(_amountIn1, _liquidityFraction);

    // Ensure we can fit K into a uint256
    // Ensure new virtual reserves fit into uint112
    if (
      reserve0_1 <= type(uint112).max &&
      reserve1_1 <= type(uint112).max &&
      uint256(reserve1_1) * reserve0_1 > _minK
    ) {
      reserve0 = uint128(reserve0_1);
      reserve1 = uint128(reserve1_1);
    } else {
      reserve0 = _reserve0;
      reserve1 = _reserve1;
    }
  }

  /**
   * @notice Computes the amount of token 1 to swap in to get the provided amount of token 1 out.
   * @param _reserve0 The amount of token 0 in the reserves
   * @param _reserve1 The amount of token 1 in the reserves
   * @param _amountIn1 The amount of token 1 coming in
   * @param _amountOut1 The amount of token 1 to swap out
   * @return The amount of token 0 to swap in to receive the given amount out of token 1
   */
  function computeExactAmountIn(
    uint128 _reserve0,
    uint128 _reserve1,
    uint256 _amountIn1,
    uint256 _amountOut1
  ) internal pure returns (uint256) {
    require(_amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity-a");
    (uint128 reserve0, uint128 reserve1) = _virtualBuyback(_reserve0, _reserve1, _amountIn1);
    return getAmountIn(_amountOut1, reserve0, reserve1);
  }

  /**
   * @notice Computes the amount of token 1 to swap out to get the procided amount of token 1 in.
   * @param _reserve0 The amount of token 0 in the reserves
   * @param _reserve1 The amount of token 1 in the reserves
   * @param _amountIn1 The amount of token 1 coming in
   * @param _amountIn0 The amount of token 0 to swap in
   * @return The amount of token 1 to swap out to receive the given amount in of token 0
   */
  function computeExactAmountOut(
    uint128 _reserve0,
    uint128 _reserve1,
    uint256 _amountIn1,
    uint256 _amountIn0
  ) internal pure returns (uint256) {
    (uint128 reserve0, uint128 reserve1) = _virtualBuyback(_reserve0, _reserve1, _amountIn1);
    uint256 amountOut1 = getAmountOut(_amountIn0, reserve0, reserve1);
    require(amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity-b");
    return amountOut1;
  }

  /**
   * @notice Adjusts the provided reserves based on the amount of token 1 coming in and performs
   *          a swap with the provided amount of token 0 in for token 1 out. Finally, scales the
   *          reserves using the provided liquidity fraction, token 1 coming in and minimum k.
   * @param _reserve0 The amount of token 0 in the reserves
   * @param _reserve1 The amount of token 1 in the reserves
   * @param _amountIn1 The amount of token 1 coming in
   * @param _amountIn0 The amount of token 0 to swap in to receive token 1 out
   * @param _swapMultiplier The multiplier to apply to the swap
   * @param _liquidityFraction The fraction relative to the amount in of token 1 to scale the
   *                           reserves to
   * @param _minK The minimum value of K to validate the scaled reserves against
   * @return reserve0 The new amount of token 0 in the reserves
   * @return reserve1 The new amount of token 1 in the reserves
   * @return amountOut1 The amount of token 1 swapped out
   */
  function swapExactAmountIn(
    uint128 _reserve0,
    uint128 _reserve1,
    uint256 _amountIn1,
    uint256 _amountIn0,
    UFixed32x4 _swapMultiplier,
    UFixed32x4 _liquidityFraction,
    uint256 _minK
  ) internal pure returns (uint128 reserve0, uint128 reserve1, uint256 amountOut1) {
    (reserve0, reserve1) = _virtualBuyback(_reserve0, _reserve1, _amountIn1);

    amountOut1 = getAmountOut(_amountIn0, reserve0, reserve1);
    require(amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity-c");
    reserve0 = reserve0 + uint128(_amountIn0);
    reserve1 = reserve1 - uint128(amountOut1);

    (reserve0, reserve1) = _virtualSwap(
      reserve0,
      reserve1,
      _amountIn1,
      amountOut1,
      _swapMultiplier,
      _liquidityFraction,
      _minK
    );
  }

  /**
   * @notice Adjusts the provided reserves based on the amount of token 1 coming in and performs
   *         a swap with the provided amount of token 1 out for token 0 in. Finally, scales the
   *        reserves using the provided liquidity fraction, token 1 coming in and minimum k.
   * @param _reserve0 The amount of token 0 in the reserves
   * @param _reserve1 The amount of token 1 in the reserves
   * @param _amountIn1 The amount of token 1 coming in
   * @param _amountOut1 The amount of token 1 to swap out to receive token 0 in
   * @param _swapMultiplier The multiplier to apply to the swap
   * @param _liquidityFraction The fraction relative to the amount in of token 1 to scale the
   *                          reserves to
   * @param _minK The minimum value of K to validate the scaled reserves against
   * @return reserve0 The new amount of token 0 in the reserves
   * @return reserve1 The new amount of token 1 in the reserves
   * @return amountIn0 The amount of token 0 swapped in
   */
  function swapExactAmountOut(
    uint128 _reserve0,
    uint128 _reserve1,
    uint256 _amountIn1,
    uint256 _amountOut1,
    UFixed32x4 _swapMultiplier,
    UFixed32x4 _liquidityFraction,
    uint256 _minK
  ) internal pure returns (uint128 reserve0, uint128 reserve1, uint256 amountIn0) {
    require(_amountOut1 <= _amountIn1, "LiquidatorLib/insufficient-balance-liquidity-d");
    (reserve0, reserve1) = _virtualBuyback(_reserve0, _reserve1, _amountIn1);

    // do swap
    amountIn0 = getAmountIn(_amountOut1, reserve0, reserve1);
    reserve0 = reserve0 + uint128(amountIn0);
    reserve1 = reserve1 - uint128(_amountOut1);

    (reserve0, reserve1) = _virtualSwap(
      reserve0,
      reserve1,
      _amountIn1,
      _amountOut1,
      _swapMultiplier,
      _liquidityFraction,
      _minK
    );
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

type UFixed32x4 is uint32;

/**
 * @title FixedMathLib
 * @author PoolTogether Inc. Team
 * @notice A minimal library to do fixed point operations with 4 decimals of precision.
 */
library FixedMathLib {
  uint256 constant multiplier = 1e4;

  /**
   * @notice Multiply a uint256 by a UFixed32x4.
   * @param a The uint256 to multiply.
   * @param b The UFixed32x4 to multiply.
   * @return The product of a and b.
   */
  function mul(uint256 a, UFixed32x4 b) internal pure returns (uint256) {
    require(a <= type(uint224).max, "FixedMathLib/a-less-than-224-bits");
    return (a * UFixed32x4.unwrap(b)) / multiplier;
  }

  /**
   * @notice Divide a uint256 by a UFixed32x4.
   * @param a The uint256 to divide.
   * @param b The UFixed32x4 to divide.
   * @return The quotient of a and b.
   */
  function div(uint256 a, UFixed32x4 b) internal pure returns (uint256) {
    require(UFixed32x4.unwrap(b) > 0, "FixedMathLib/b-greater-than-zero");
    require(a <= type(uint224).max, "FixedMathLib/a-less-than-224-bits");
    return (a * multiplier) / UFixed32x4.unwrap(b);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface ILiquidationSource {
  /**
   * @notice Get the available amount of tokens that can be swapped.
   * @param tokenOut Address of the token to get available balance for
   * @return uint256 Available amount of `token`
   */
  function liquidatableBalanceOf(address tokenOut) external view returns (uint256);

  /**
   * @notice Liquidate `amountIn` of `tokenIn` for `amountOut` of `tokenOut` and transfer to `account`.
   * @param account Address of the account that will receive `tokenOut`
   * @param tokenIn Address of the token being sold
   * @param amountIn Amount of token being sold
   * @param tokenOut Address of the token being bought
   * @param amountOut Amount of token being bought
   * @return bool Return true once the liquidation has been completed
   */
  function liquidate(
    address account,
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amountOut
  ) external returns (bool);

  /**
   * @notice Get the address that will receive `tokenIn`.
   * @param tokenIn Address of the token to get the target address for
   * @return address Address of the target
   */
  function targetOf(address tokenIn) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}