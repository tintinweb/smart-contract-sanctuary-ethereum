// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IMagician.sol";
import "./interfaces/ICurveMetaPoolLike.sol";
import "./interfaces/ICurvePoolLike128.sol";
import "./interfaces/ICurvePoolLike256.sol";

/// @dev Magician to support liquidations through Curve-XAI pool
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
contract XAICurveMagicianETH is IMagician {
    using SafeERC20 for IERC20;

    // XAI/FRAXBP(FRAX/USDC)
    ICurveMetaPoolLike public constant XAI_FRAXBP_POOL = ICurveMetaPoolLike(0x326290A1B0004eeE78fa6ED4F1d8f4b2523ab669);
    // DAI/USDC/USDT
    ICurvePoolLike128 public constant CRV3_POOL = ICurvePoolLike128(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    // USDT/WETH/WBTC
    ICurvePoolLike256 public constant TRICRYPTO2_POOL = ICurvePoolLike256(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);

    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant XAI = IERC20(0xd7C9F0e536dC865Ae858b0C0453Fe76D13c3bEAc);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @dev Index value for the coin (curve XAI/FRAXBP pool)
    int128 public constant XAI_INDEX_XAIPOOL = 0;
    /// @dev Index value for the underlying coin (curve XAI/FRAXBP pool)
    int128 public constant USDC_INDEX_XAIPOOL = 2;
    /// @dev Index value for the coin (curve DAI/USDC/USDT pool)
    int128 public constant USDC_INDEX_3CRV = 1;
    /// @dev Index value for the coin (curve DAI/USDC/USDT pool)
    int128 public constant USDT_INDEX_3CRV = 2;
    /// @dev Index value for the coin (curve USDT/WETH/WBTC pool)
    uint256 public constant USDT_INDEX_TRICRYPTO = 0;
    /// @dev Index value for the coin (curve USDT/WETH/WBTC pool)
    uint256 public constant WETH_INDEX_TRICRYPTO = 2;

    uint256 public constant WETH_DECIMALS = 18;
    uint256 public constant XAI_DECIMALS = 18;
    uint256 public constant USDT_DECIMALS = 6;
    uint256 public constant USDC_DECIMALS = 6;

    uint256 public constant ONE_WETH = 1e18;
    uint256 public constant ONE_USDC = 1e6;
    uint256 public constant ONE_USDT = 1e6;

    uint256 public constant UNKNOWN_MIN_DY = 1;

    /// @dev Revert if `towardsNative` or `towardsAsset` will be executed for the asset other than XAI
    error InvalidAsset();

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(XAI)) revert InvalidAsset();

        XAI.approve(address(XAI_FRAXBP_POOL), _amount);

        uint256 receivedUSDC = XAI_FRAXBP_POOL.exchange_underlying(
            XAI_INDEX_XAIPOOL,
            USDC_INDEX_XAIPOOL,
            _amount,
            UNKNOWN_MIN_DY
        );

        USDC.approve(address(CRV3_POOL), receivedUSDC);
        uint256 usdtBalanceBefore = USDT.balanceOf(address(this));
        CRV3_POOL.exchange(USDC_INDEX_3CRV, USDT_INDEX_3CRV, receivedUSDC, UNKNOWN_MIN_DY);
        uint256 usdtBalanceAfter = USDT.balanceOf(address(this));
        uint256 receivedUSDT;
        // Balance after exchange can't be less than it was before
        unchecked { receivedUSDT = usdtBalanceAfter - usdtBalanceBefore; }

        USDT.safeApprove(address(TRICRYPTO2_POOL), receivedUSDT);
        uint256 wethBalanceBefore = WETH.balanceOf(address(this));
        TRICRYPTO2_POOL.exchange(USDT_INDEX_TRICRYPTO, WETH_INDEX_TRICRYPTO, receivedUSDT, UNKNOWN_MIN_DY);
        uint256 wethBalanceAfter = WETH.balanceOf(address(this));
        // Balance after exchange can't be less than it was before
        unchecked { amountOut = wethBalanceAfter - wethBalanceBefore; }

        return (address(WETH), amountOut);
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(XAI)) revert InvalidAsset();

        uint256 increasedRequiredAmount;

        // Increasing a little bit value of the required XAI as can't get the expected number of XAI
        // on the last step of the exchange without it.
        // Math is unchecked as we do not expect to work with large numbers during the liquidation
        // to catch an overflow here.
        unchecked { increasedRequiredAmount = _amount + 1e17; }

        // calculate a price
        (uint256 usdcIn, uint256 xaiOut) = _calcRequiredUSDC(increasedRequiredAmount);

        assert(xaiOut >= _amount);

        (uint256 usdtIn, uint256 usdcOut) = _calcRequiredUSDT(usdcIn);
        (uint256 wethIn, uint256 usdtOut) = _calcRequiredWETH(usdtIn);

        // WETH -> USDT
        WETH.approve(address(TRICRYPTO2_POOL), wethIn);
        TRICRYPTO2_POOL.exchange(WETH_INDEX_TRICRYPTO, USDT_INDEX_TRICRYPTO, wethIn, usdtOut);
        // USDT -> USDC
        USDT.safeApprove(address(CRV3_POOL), usdtOut);
        CRV3_POOL.exchange(USDT_INDEX_3CRV, USDC_INDEX_3CRV, usdtOut, usdcOut);
        // USDC -> XAI
        USDC.approve(address(XAI_FRAXBP_POOL), usdcOut);
        XAI_FRAXBP_POOL.exchange_underlying(USDC_INDEX_XAIPOOL, XAI_INDEX_XAIPOOL, usdcOut, _amount);

        return (address(XAI), wethIn);
    }

    /// @param _requiredAmountOut Expected amount of XAI to receive after exhange
    /// It may be a bit more, but not less than the provided value.
    /// @return amountIn Amount of USDC that we should send for exchage
    /// @return amountOut Amount of XAI that we will receive in exchange for `amountIn` USDC
    function _calcRequiredUSDC(uint256 _requiredAmountOut)
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        // We do normalization of the rate as we will recive from the `get_dy_underlying` a value with `_decimalsOut`
        uint256 dy = XAI_FRAXBP_POOL.get_dy_underlying(USDC_INDEX_XAIPOOL, XAI_INDEX_XAIPOOL, ONE_USDC);
        uint256 rate = _normalizeWithDecimals(dy, USDC_DECIMALS, XAI_DECIMALS);
        // Normalize `_requiredAmountOut` to `_decimalsIn` as we will use it
        // for calculation of the `amountIn` value of the `_tokenIn`
        _requiredAmountOut = _normalizeWithDecimals(_requiredAmountOut, USDC_DECIMALS, XAI_DECIMALS);
        uint256 multiplied = ONE_USDC * _requiredAmountOut;
        // Zero value for amountIn is unacceptable.
        assert(multiplied >= rate); // Otherwise, we may get zero.
        // Assertion above make it safe
        unchecked { amountIn = multiplied / rate; }
        // `get_dy_underlying` is an increasing function.
        // It should take ~ 1 - 6 iterations to `amountOut >= _requiredAmountOut`.
        while (true) {
            amountOut = XAI_FRAXBP_POOL.get_dy_underlying(USDC_INDEX_XAIPOOL, XAI_INDEX_XAIPOOL, amountIn);
            uint256 amountOutNormalized = _normalizeWithDecimals(amountOut, USDC_DECIMALS, XAI_DECIMALS);

            if (amountOutNormalized >= _requiredAmountOut) {
                return (amountIn, amountOut);
            }

            amountIn = _calcAmountIn(
                amountIn,
                ONE_USDC,
                rate,
                _requiredAmountOut,
                amountOutNormalized
            );
        }
    }

    /// @param _requiredAmountOut Expected amount of USDC to receive after exhange
    /// It may be a bit more, but not less than the provided value.
    /// @return amountIn Amount of USDT that we should send for exchage
    /// @return amountOut Amount of USDC that we will receive in exchange for `amountIn` USDT
    function _calcRequiredUSDT(uint256 _requiredAmountOut)
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        // We do normalization of the rate as we will recive from the `get_dy` a value with `USDC_DECIMALS`
        uint256 rate = CRV3_POOL.get_dy(USDT_INDEX_3CRV, USDC_INDEX_3CRV, ONE_USDT);
        uint256 multiplied = ONE_USDT * _requiredAmountOut;
        // Zero value for amountIn is unacceptable.
        assert(multiplied >= rate); // Otherwise, we may get zero.
        // Assertion above make it safe
        unchecked { amountIn = multiplied / rate; }
        // `get_dy` is an increasing function.
        // It should take ~ 1 - 6 iterations to `amountOut >= _requiredAmountOut`.
        while (true) {
            amountOut = CRV3_POOL.get_dy(USDT_INDEX_3CRV, USDC_INDEX_3CRV, amountIn);

            if (amountOut >= _requiredAmountOut) {
                return (amountIn, amountOut);
            }

            amountIn = _calcAmountIn(
                amountIn,
                ONE_USDT,
                rate,
                _requiredAmountOut,
                amountOut
            );
        }
    }
    
    /// @param _requiredAmountOut Expected amount of WETH to receive after exhange
    /// It may be a bit more, but not less than the provided value.
    /// @return amountIn Amount of WETH that we should send for exchage
    /// @return amountOut Amount of USDT that we will receive in exchange for `amountIn` WETH
    function _calcRequiredWETH(uint256 _requiredAmountOut)
        internal
        view
        returns (uint256 amountIn, uint256 amountOut)
    {
        // We do normalization of the rate as we will recive from the `get_dy` a value with `USDT_DECIMALS`
        uint256 dy = TRICRYPTO2_POOL.get_dy(WETH_INDEX_TRICRYPTO, USDT_INDEX_TRICRYPTO, ONE_WETH);
        uint256 rate = _normalizeWithDecimals(dy, WETH_DECIMALS, USDT_DECIMALS);
        // Normalize `_requiredAmountOut` to `WETH_DECIMALS` as we will use it
        // for calculation of the `amountIn` value of the `_tokenIn`
        _requiredAmountOut = _normalizeWithDecimals(_requiredAmountOut, WETH_DECIMALS, USDT_DECIMALS);
        uint256 multiplied = ONE_WETH * _requiredAmountOut;
        // Zero value for amountIn is unacceptable.
        assert(multiplied >= rate); // Otherwise, we may get zero.
        // Assertion above make it safe
        unchecked { amountIn = multiplied / rate; }
        // `get_dy` is an increasing function.
        // It should take ~ 1 - 6 iterations to `amountOut >= _requiredAmountOut`.
        while (true) {
            amountOut = TRICRYPTO2_POOL.get_dy(WETH_INDEX_TRICRYPTO, USDT_INDEX_TRICRYPTO, amountIn);
            uint256 amountOutNormalized = _normalizeWithDecimals(amountOut, WETH_DECIMALS, USDT_DECIMALS);

            if (amountOutNormalized >= _requiredAmountOut) {
                return (amountIn, amountOut);
            }

            amountIn = _calcAmountIn(
                amountIn,
                ONE_WETH,
                rate,
                _requiredAmountOut,
                amountOutNormalized
            );
        }
    }

    /// @dev Adjusts the given value to have different decimals
    function _normalizeWithDecimals(
        uint256 _value,
        uint256 _toDecimals,
        uint256 _fromDecimals
    )
        internal
        view
        virtual
        returns (uint256)
    {
        if (_toDecimals == _fromDecimals) {
            return _value;
        } else if (_toDecimals < _fromDecimals) {
            uint256 devideOn;
            // It can be unchecked because of the condition `_toDecimals < _fromDecimals`.
            // We trust to `_fromDecimals` and `_toDecimals` they should not have large numbers.
            unchecked { devideOn = 10 ** (_fromDecimals - _toDecimals); }
            // Zero value after normalization is unacceptable.
            assert(_value >= devideOn); // Otherwise, we may get zero.
            // Assertion above make it safe
            unchecked { return _value / devideOn; }
        } else {
            uint256 decimalsDiff;
            // Because of the condition `_toDecimals < _fromDecimals` above,
            // we are safe as it guarantees that `_toDecimals` is > `_fromDecimals`
            unchecked { decimalsDiff = 10 ** (_toDecimals - _fromDecimals); }

            return _value * decimalsDiff;
        }
    }

    /// @notice Extension for such functions like: `_calcRequiredWETH`, `_calcRequiredUSDC`, and `_calcRequiredUSDT`
    function _calcAmountIn(
        uint256 _amountIn,
        uint256 _one,
        uint256 _rate,
        uint256 _requiredAmountOut,
        uint256 _amountOutNormalized
    )
        private
        pure
        returns (uint256)
    {
        uint256 diff;
        // Because of the condition `amountOutNormalized >= _requiredAmountOut` in a calling function,
        // safe math is not required here.
        unchecked { diff = _requiredAmountOut - _amountOutNormalized; }
        // We may be stuck in a situation where a difference between
        // a `_requiredAmountOut` and `amountOutNormalized`
        // will be small and we will need to perform more steps.
        // This expression helps to escape the almost infinite loop.
        if (diff < 1e3) {
            // If the `amountIn` value is high the `get_dy` function will revert first
            unchecked { _amountIn += 1e3; }
        } else {
            // `one * diff` is safe as `diff` will be lower then the `_requiredAmountOut`
            // for which we have safe math while doing `ONE_... * _requiredAmountOut` in a calling function.
            unchecked { _amountIn += (_one * diff) / _rate; }
        }

        return _amountIn;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity >=0.7.6 <0.9.0;

/// @notice Extension for the Liquidation helper to support such operations as unwrapping
interface IMagician {
    /// @notice Operates to unwrap an `_asset`
    /// @param _asset Asset to be unwrapped
    /// @param _amount Amount of the `_asset`
    /// @return tokenOut A token that the `_asset` has been converted to
    /// @return amountOut Amount of the `tokenOut` that we received
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut);

    /// @notice Performs operation opposit to `towardsNative`
    /// @param _asset Asset to be wrapped
    /// @param _amount Amount of the `_asset`
    /// @return tokenOut A token that the `_asset` has been converted to
    /// @return amountOut Amount of the quote token that we spent to get `_amoun` of the `_asset`
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICurveMetaPoolLike {
    // solhint-disable-next-line func-name-mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external returns (uint256);
    // solhint-disable-next-line func-name-mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICurvePoolLike128 {
    // solhint-disable-next-line func-name-mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;
    // solhint-disable-next-line func-name-mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICurvePoolLike256 {
    // solhint-disable-next-line func-name-mixedcase
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 minDy) external;
    // solhint-disable-next-line func-name-mixedcase
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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