// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IWETH9Like.sol";
import "./_common/STETHBaseMagician.sol";

/// @dev stETH Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
contract STETHMagician is STETHBaseMagician {
    error InvalidAsset();

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != address(STETH)) {
            revert InvalidAsset();
        }

        IERC20(STETH).approve(address(CURVE_POOL), _amount);

        tokenOut = WETH;
        uint256 minAmountOut = 1;
        amountOut = CURVE_POOL.exchange(STETH_INDEX, ETH_INDEX, _amount, minAmountOut);

        // Wrap ETH
        IWETH9Like(WETH).deposit{value: amountOut}();
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut) {
        if (_asset != STETH) {
            revert InvalidAsset();
        }

        // calculate a price stETH -> ETH 
        (uint256 requiredETH, uint256 expectedStEthAmount) = _calcRequiredETH(_amount);

        // Un wrap required amount of ETH (WETH -> ETH)
        IWETH9Like(WETH).withdraw(requiredETH);

        // exchange ETH -> stETH
        CURVE_POOL.exchange{value: requiredETH}(
            ETH_INDEX,
            STETH_INDEX,
            requiredETH,
            expectedStEthAmount
        );

        return (STETH, requiredETH);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev A simplified version of the WETH
interface IWETH9Like {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IWstETHLike.sol";
import "../interfaces/IMagician.sol";
import "../interfaces/ICurvePoolLike.sol";

/// @dev stETH Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
abstract contract STETHBaseMagician is IMagician {
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWstETHLike public constant WSTETH = IWstETHLike(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    ICurvePoolLike public constant CURVE_POOL = ICurvePoolLike(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    /// @dev Index value for the coin to send (curve stETh/ETH pool)
    // solhint-disable-next-line use-forbidden-name
    int128 public constant STETH_INDEX = 1; // stETH
    /// @dev Index value of the coin to recieve
    // solhint-disable-next-line use-forbidden-name
    int128 public constant ETH_INDEX = 0; // ETH

    /// @notice Calculate the required ETH amount to get the expected number of stETH from the Curve pool.
    /// @dev Present a precision error up to 2e11 (0.002$ if ETH price is 10 000$) in favor of `requiredETH`,
    /// so we will buy a little bit more stETH than needed. Which is fine.
    /// @param _stETHAmountRequired A number of the stETH that we want to get from the Curve pool
    /// @return requiredETH A number of the ETH to buy `_stETHAmountRequired`
    function _calcRequiredETH(uint256 _stETHAmountRequired)
        internal
        view
        returns (uint256 requiredETH, uint256 stETHOutput)
    {
        uint256 one = 1e18; // One coin stETH or ETH, has 18 decimals
        uint256 rate = CURVE_POOL.get_dy(ETH_INDEX, STETH_INDEX, one);
        uint256 multiplied = one * _stETHAmountRequired;
        
        // We have safe math while doing `one * _stETHAmountRequired`. Division should be fine.
        unchecked { requiredETH = multiplied / rate; }

        // `get_dy` is an increasing function.
        // It should take ~ 1 - 6 iterations to `stETHOutput >= _stETHAmountRequired`.
        while (true) {
            stETHOutput = CURVE_POOL.get_dy(ETH_INDEX, STETH_INDEX, requiredETH);

            if (stETHOutput >= _stETHAmountRequired) {
                return (requiredETH, stETHOutput);
            }

            uint256 diff;
            // Because of the condition `stETHOutput >= _stETHAmountRequired`, safe math is not required here.
            unchecked { diff = _stETHAmountRequired - stETHOutput; }
            
            // We may be stuck with a situation where a difference between a `_stETHAmountRequired` and `stETHOutput`
            // will be small and we will need to perform more steps.
            // This expression helps to escape the almost infinite loop.
            if (diff < 1e3) {
                // if `requiredETH` value will be high the `get_dy` function will revert first
                unchecked { requiredETH += 1e3; }
                continue;
            }

            // `one * diff` is safe as `diff` will be lower
            // than `_stETHAmountRequired` for which we have safe math while doing `one * _stETHAmountRequired`.
            unchecked { requiredETH += (one * diff) / rate; }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWstETHLike {
    function unwrap(uint256 _wstETHAmount) external returns (uint256 stETHAmount);
    function wrap(uint256 _stETHAmount) external returns (uint256 wstETHAmount);
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev A simplified version of the Curve Pool interface with methods
/// that are required for the SETH Magician.
interface ICurvePoolLike {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external payable returns (uint256);
    function coins(uint256 i) external view returns (address);
    // solhint-disable-next-line func-name-mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}