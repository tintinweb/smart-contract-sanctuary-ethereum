// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

interface IERC20Decimals {
    function decimals() external view returns (uint256);
}

/**
 * @title ERC20Decimals
 * @author @InsureDAO
 * @notice InsureDAO's ERC20 decimals aligner
 **/
library ERC20Decimals {
    /**
     * @notice align decimal from tokenIn decimal to tokenOut's
     * @param _tokenIn input address
     * @param _tokenOut output address
     * @param _amount amount of _tokenIn's decimal
     * @return _amountOut decimal aligned amount
     */
    function alignDecimal(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external view returns (uint256) {
        return alignDecimal(IERC20Decimals(_tokenIn).decimals(), IERC20Decimals(_tokenOut).decimals(), _amount);
    }

    /**
     * @notice align decimal from tokenIn decimal to tokenOut's by decimal value
     * @param _decimalsIn input decimal
     * @param _decimalsOut output decimal
     * @param _amount amount of _decimalsIn
     * @return _amountOut decimal aligned amount
     */
    function alignDecimal(
        uint256 _decimalsIn,
        uint256 _decimalsOut,
        uint256 _amount
    ) public pure returns (uint256) {
        uint256 _decimals;
        if (_decimalsIn == _decimalsOut) {
            return _amount;
        } else if (_decimalsIn > _decimalsOut) {
            unchecked {
                _decimals = _decimalsIn - _decimalsOut;
            }
            return _amount / (10**_decimals);
        } else {
            unchecked {
                _decimals = _decimalsOut - _decimalsIn;
            }
            return _amount * (10**_decimals);
        }
    }
}