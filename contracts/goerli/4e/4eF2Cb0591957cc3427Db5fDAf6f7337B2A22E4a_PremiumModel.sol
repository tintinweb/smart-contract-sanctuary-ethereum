// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;
/**
 * @title PremiumModel
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance premium model
 **/
import "../interfaces/IPremiumModel.sol";
import "../libs/ERC20Decimals.sol";

contract PremiumModel is IPremiumModel {
    uint256 private constant MAGIC_SCALE_1E8 = 1e8;
    uint256 public decimalsIn;
    uint256 public decimalsOut;

    constructor(uint256 _decimalsIn, uint256 _decimalsOut) {
        decimalsIn = _decimalsIn;
        decimalsOut = _decimalsOut;
    }

    /// @notice inherit IPremiumModel
    function getFee(
        uint256,
        uint256,
        uint256
    ) external view override returns (uint256) {
        //do something here after updates
    }

    /// @notice inherit IPremiumModel
    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _targetRate,
        uint256 _commissionRate,
        uint256,
        uint256
    ) external view override returns (uint256) {
        _amount = ERC20Decimals.alignDecimal(decimalsIn, decimalsOut, _amount);
        uint256 _commission = (_amount * _commissionRate) / MAGIC_SCALE_1E8;
        return (_amount * _targetRate * _term) / 365 days / MAGIC_SCALE_1E8 + _commission;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPremiumModel
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Premium Model.
 **/
interface IPremiumModel {
    /**
     * FUNCTIONS
     */
    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _term insure's term
     * @param _targetRate target contract's rate
     * @return fee
     */
    function getFee(
        uint256 _amount,
        uint256 _term,
        uint256 _targetRate
    ) external view returns (uint256);

    /**
     * @notice get fee rate for the specified conditions
     * @param _amount premium amount
     * @param _term insure's term
     * @param _targetRate target contract's rate
     * @param _totalLiquidity total liquidity
     * @param _lockedAmount locked amount
     * @return fee
     */
    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _targetRate,
        uint256 _commissionRate,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);
}

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