pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/temple-frax/LockerProxy.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/investments/frax-gauge/temple-frax/IStaxLP.sol";
import "../../../interfaces/investments/frax-gauge/temple-frax/IStaxLPStaking.sol";

import "../../../liquidity-pools/CurveStableSwap.sol";
import "../../../common/CommonEventsAndErrors.sol";

/// @notice Users lock (and optionally stake) LP into STAX.
/// @dev This is a one-way conversion of LP -> xLP, where exit liquidity (xLP->LP) is provided via a curve stable swap market.
/// This LP is locked in gauges to generate time and veFXS boosted yield for users who stake their xLP
contract LockerProxy is Ownable {
    using SafeERC20 for IStaxLP;
    using SafeERC20 for IERC20;
    using CurveStableSwap for CurveStableSwap.Data;

    /// @notice The STAX contract managing the deposited LP
    address public liquidityOps;

    /// @notice The staking token for deposits (ie LP)
    IERC20 public inputToken;

    /// @notice The staking receipt token (ie xLP)
    IStaxLP public staxReceiptToken;

    /// @notice The STAX staking contract
    IStaxLPStaking public staking;

    /// @notice Curve v1 Stable Swap (xLP:LP) is used as the pool for exit liquidity.
    CurveStableSwap.Data public curveStableSwap;

    event Locked(address user, uint256 amountOut);
    event Bought(address user, uint256 amountOut);
    event LiquidityOpsSet(address liquidityOps);

    constructor(
        address _liquidityOps,
        address _inputToken,
        address _staxReceiptToken,
        address _staking,
        address _curveStableSwap
    ) {
        liquidityOps = _liquidityOps;
        inputToken = IERC20(_inputToken);
        staxReceiptToken = IStaxLP(_staxReceiptToken);
        staking = IStaxLPStaking(_staking);

        ICurveStableSwap ccs = ICurveStableSwap(_curveStableSwap);
        curveStableSwap = CurveStableSwap.Data(ccs, IERC20(ccs.coins(0)), IERC20(ccs.coins(1)));
    }

    /// @notice Set the liquidity ops contract used to apply LP to gauges/exit liquidity pools
    function setLiquidityOps(address _liquidityOps) external onlyOwner {
        if (_liquidityOps == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        liquidityOps = _liquidityOps;
        emit LiquidityOpsSet(_liquidityOps);
    }

    /** 
      * @notice Convert inputToken (eg LP) to staxReceiptToken (eg xLP), at 1:1
      * @dev This will mint staxReceiptToken (1:1)
      * @param _inputAmount How much of inputToken to lock (eg LP)
      * @param _stake If true, immediately stake the resulting staxReceiptToken (eg xLP)
      */
    function lock(uint256 _inputAmount, bool _stake) external {
        uint256 bal = inputToken.balanceOf(msg.sender);
        if (_inputAmount > bal) revert CommonEventsAndErrors.InsufficientTokens(address(inputToken), _inputAmount, bal);

        inputToken.safeTransferFrom(msg.sender, liquidityOps, _inputAmount);

        if (_stake) {
            staxReceiptToken.mint(address(this), _inputAmount);
            staxReceiptToken.safeIncreaseAllowance(address(staking), _inputAmount);
            staking.stakeFor(msg.sender, _inputAmount);
        } else {
            staxReceiptToken.mint(msg.sender, _inputAmount);
        }

        emit Locked(msg.sender, _inputAmount);
    }
    
    /** 
      * @notice Get a quote to purchase staxReceiptToken (eg xLP) using inputToken (eg LP) via the AMM.
      * @dev This includes AMM fees + liquidity based slippage.
      * @param _liquidity The amount of inputToken (eg LP)
      * @return _staxReceiptAmount The expected amount of _staxReceiptAmount from the AMM
      */
    function buyFromAmmQuote(uint256 _liquidity) external view returns (uint256 _staxReceiptAmount) {
        return curveStableSwap.exchangeQuote(address(inputToken), _liquidity);
    }

    /** 
      * @notice Purchase stax locker receipt tokens (eg xLP), by buying from the AMM.
      * @dev Use this instead of convert() if the receipt token is trading > 1:1 - eg you can get more xLP buying on the AMM 
      * @param _inputAmount How much of inputToken to lock (eg LP)
      * @param _stake If true, immediately stake the resulting staxReceiptToken (eg xLP)
      * @param _minAmmAmountOut The minimum amount we would expect to receive from the AMM
      */
    function buyFromAmm(uint256 _inputAmount, bool _stake, uint256 _minAmmAmountOut) external {
        uint256 balance = inputToken.balanceOf(msg.sender);
        if (balance < _inputAmount) revert CommonEventsAndErrors.InsufficientTokens(address(inputToken), _inputAmount, balance);

        // Pull input tokens from user.
        inputToken.safeTransferFrom(msg.sender, address(this), _inputAmount);

        uint256 amountOut;
        if (_stake) {
            amountOut = curveStableSwap.exchange(address(inputToken), _inputAmount, _minAmmAmountOut, address(this));
            staxReceiptToken.safeIncreaseAllowance(address(staking), amountOut);
            staking.stakeFor(msg.sender, amountOut);
        } else {
            amountOut = curveStableSwap.exchange(address(inputToken), _inputAmount, _minAmmAmountOut, msg.sender);
        }
        emit Bought(msg.sender, amountOut);
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenTransferred(address(this), _to, address(_token), _amount);
    }

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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/temple-frax/IStaxLP.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaxLP is IERC20 {
    function mint(address to, uint256 amount) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/temple-frax/IStaxLPStaking.sol)

interface IStaxLPStaking {
    function stakeFor(address _for, uint256 _amount) external;
    function notifyRewardAmount(address token, uint256 reward) external;
    function rewardTokensList() external view returns (address[] memory);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (liquidity-pools/CurveStableSwap.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/external/curve/ICurveStableSwap.sol";

import "../common/CommonEventsAndErrors.sol";

/// @notice A wrapper around Curve v1 stable swap
library CurveStableSwap {
    using SafeERC20 for IERC20;

    struct Data {
        ICurveStableSwap pool;
        IERC20 token0;
        IERC20 token1;
    }

    event CoinExchanged(address coinSent, uint256 amountSent, uint256 amountReceived);
    event RemovedLiquidityImbalance(uint256 receivedAmount0, uint256 receivedAmount1, uint256 burnAmount);
    event LiquidityAdded(uint256 sentAmount0, uint256 sentAmount1, uint256 curveTokenAmount);
    event LiquidityRemoved(uint256 receivedAmount0, uint256 receivedAmount1, uint256 curveTokenAmount);

    error InvalidSlippage(uint256 slippage);

    uint256 internal constant CURVE_FEE_DENOMINATOR = 1e10;

    function exchangeQuote(
        Data storage self,
        address _coinIn,
        uint256 _fromAmount
    ) internal view returns (uint256) {
        (, int128 inIndex, int128 outIndex) = _getIndex(self, _coinIn);
        return self.pool.get_dy(inIndex, outIndex, _fromAmount);
    }

    function exchange(
        Data storage self,
        address _coinIn,
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    ) internal returns (uint256 amountOut) {
        (IERC20 tokenIn, int128 inIndex, int128 outIndex) = _getIndex(self, _coinIn);

        uint256 balance = tokenIn.balanceOf(address(this));
        if (balance < _amount) revert CommonEventsAndErrors.InsufficientTokens(address(tokenIn), _amount, balance);
        tokenIn.safeIncreaseAllowance(address(self.pool), _amount);

        amountOut = self.pool.exchange(inIndex, outIndex, _amount, _minAmountOut, _receiver);
        emit CoinExchanged(_coinIn, _amount, amountOut);
    }

    function _getIndex(
        Data storage self,
        address _coinIn
    ) private view returns (IERC20 tokenIn, int128 inIndex, int128 outIndex) {
        if (_coinIn == address(self.token0)) {
            (tokenIn, inIndex, outIndex) = (self.token0, 0, 1);
        } else if (_coinIn == address(self.token1)) {
            (tokenIn, inIndex, outIndex) = (self.token1, 1, 0);
        } else {
            revert CommonEventsAndErrors.InvalidToken(_coinIn);
        }
    }

    function removeLiquidityImbalance(
        Data storage self,
        uint256[2] memory _amounts,
        uint256 _maxBurnAmount
    ) internal returns (uint256 burnAmount) {
        uint256 balance = self.pool.balanceOf(address(this));
        if (balance <= 0) revert CommonEventsAndErrors.InsufficientTokens(address(self.pool), 1, balance);
        burnAmount = self.pool.remove_liquidity_imbalance(_amounts, _maxBurnAmount, address(this));

        emit RemovedLiquidityImbalance(_amounts[0], _amounts[1], burnAmount);
    }

    /** 
      * @notice Add LP/xLP 1:1 into the curve pool
      * @dev Add same amounts of lp and xlp tokens such that the price remains about the same
             - don't apply any peg fixing here. xLP tokens are minted 1:1
      * @param _amount The amount of LP and xLP to add into the pool.
      * @param _minAmountOut The minimum amount of curve liquidity tokens we expect in return.
      */
    function addLiquidity(
        Data storage self,
        uint256 _amount,
        uint256 _minAmountOut
    ) internal returns (uint256 liquidity) {
        uint256[2] memory amounts = [_amount, _amount];
        
        self.token0.safeIncreaseAllowance(address(self.pool), _amount);
        self.token1.safeIncreaseAllowance(address(self.pool), _amount);

        liquidity = self.pool.add_liquidity(amounts, _minAmountOut, address(this));
        emit LiquidityAdded(_amount, _amount, liquidity);
    }

    function removeLiquidity(
        Data storage self,
        uint256 _liquidity,
        uint256 _minAmount0,
        uint256 _minAmount1
    ) internal returns (uint256[2] memory balancesOut) {
        uint256 balance = self.pool.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientTokens(address(self.pool), _liquidity, balance);
        balancesOut = self.pool.remove_liquidity(_liquidity, [_minAmount0, _minAmount1]);
        emit LiquidityRemoved(balancesOut[0], balancesOut[1], _liquidity);
    }

    /** 
      * @notice Calculates the min expected amount of curve liquditity token to receive when depositing the 
      *         current eligable amount to into the curve LP:xLP liquidity pool
      * @dev Takes into account pool liquidity slippage and fees.
      * @param _liquidity The amount of LP to apply
      * @param _modelSlippage Any extra slippage to account for, given curveStableSwap.calc_token_amount() 
               is an approximation. 1e10 precision, so 1% = 1e8.
      * @return minCurveTokenAmount Expected amount of LP tokens received 
      */ 
    function minAmountOut(
        Data storage self,
        uint256 _liquidity,
        uint256 _modelSlippage
    ) internal view returns (uint256 minCurveTokenAmount) {
        uint256 feeAndSlippage = _modelSlippage + self.pool.fee();        if (feeAndSlippage > CURVE_FEE_DENOMINATOR) revert InvalidSlippage(feeAndSlippage);
        
        minCurveTokenAmount = 0;
        if (_liquidity > 0) {
            uint256[2] memory amounts = [_liquidity, _liquidity];
            minCurveTokenAmount = self.pool.calc_token_amount(amounts, true);
            unchecked {
                minCurveTokenAmount -= minCurveTokenAmount * feeAndSlippage / CURVE_FEE_DENOMINATOR;
            }
        }
    }

}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    event TokenTransferred(address indexed from, address indexed to, address indexed token, uint256 amount);

    error InsufficientTokens(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (interfaces/external/curve/ICurveStableSwap.sol)

interface ICurveStableSwap {
    function coins(uint256 j) external view returns (address);
    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external view returns (uint256);
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount, address destination) external returns (uint256);
    function get_dy(int128 _from, int128 _to, uint256 _from_amount) external view returns (uint256);
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function fee() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
}