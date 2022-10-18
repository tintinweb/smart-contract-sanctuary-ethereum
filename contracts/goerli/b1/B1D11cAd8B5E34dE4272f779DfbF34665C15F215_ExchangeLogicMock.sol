pragma solidity ^0.8.16;

import "../interfaces/IExchangeLogic.sol";
import "../libs/ERC20Decimals.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// import "forge-std/console2.sol";

contract ExchangeLogicMock is IExchangeLogic {
    uint256 public exchangeLoss;
    uint256 public exchangeLossSpecial;

    error ExchangeLogicMockSwapError();

    constructor(uint256 _exchangeLoss) {
        exchangeLoss = _exchangeLoss;
    }

    function setExchangeLoss(uint256 _exchangeLoss) external {
        exchangeLoss = _exchangeLoss;
    }

    function setExchangeLossSpecial(uint256 _exchangeLossSpecial) external {
        exchangeLossSpecial = _exchangeLossSpecial;
    }

    function swapper() external view returns (address) {
        return address(this);
    }

    function abiEncodeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external pure returns (bytes memory) {
        _amountOutMin = 1;

        return
            abi.encodeWithSignature("exchange(address,address,uint256,address)", _tokenIn, _tokenOut, _amountIn, _to);
    }

    function estimateAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view virtual returns (uint256) {
        // _tokenIn = address(0);
        // _tokenOut = address(0);
        return (ERC20Decimals.alignDecimal(_tokenIn, _tokenOut, _amountIn) * exchangeLoss) / 10000;
    }

    function estimateAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin
    ) external view virtual returns (uint256) {
        if (_amountOutMin == 0) return 0;
        // _tokenIn = address(0);
        // _tokenOut = address(0);
        return (ERC20Decimals.alignDecimal(_tokenOut, _tokenIn, _amountOutMin) * 10001) / exchangeLoss;
    }

    function exchange(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) external virtual returns (uint256) {
        uint256 _exchangeLoss = exchangeLoss;
        if (exchangeLossSpecial > 0) _exchangeLoss = exchangeLossSpecial;
        if (IERC20(_tokenIn).allowance(msg.sender, address(this)) < _amountIn) {
            // console2.log("ExchangeLogicMockError: 1");
        }
        if (IERC20(_tokenIn).balanceOf(msg.sender) < _amountIn) {
            // console2.log("ExchangeLogicMockError: 2");
        }
        if (!IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn)) {
            // console2.log("ExchangeLogicMockError: 3");
            revert ExchangeLogicMockSwapError();
        }
        uint256 _amountOut = (ERC20Decimals.alignDecimal(_tokenIn, _tokenOut, _amountIn) * _exchangeLoss) / 10000;
        if (IERC20(_tokenOut).balanceOf(address(this)) < _amountOut) {
            // console2.log("ExchangeLogicMockError: 4");
        }
        if (!IERC20(_tokenOut).transfer(_to, _amountOut)) {
            // console2.log("ExchangeLogicMockError: 5");
            revert ExchangeLogicMockSwapError();
        }
        return _amountOut;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IExchangeLogic
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Exchange Logic.
 **/
interface IExchangeLogic {
    /**
     * @notice get swapper(router) address
     * @return swapper_ swapper address
     */
    function swapper() external returns (address);

    /**
     * @notice get encoded bytes of swapping to call swap by sender address
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountIn amount of input token
     * @param _amountOutMin amount of minimum output token
     * @param _to to address
     * @return abiEncoded returns encoded bytes
     */
    function abiEncodeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external view returns (bytes memory);

    /**
     * @notice estimate being swapped amounts of _tokenOut
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountIn amount of input token
     * @return amountOut_ returns the amount of _tokenOut swapped
     */
    function estimateAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    /**
     * @notice estimate needed amounts of _tokenIn
     * @param _tokenIn address of input token
     * @param _tokenOut address of output token
     * @param _amountOutMin amount of minimum output token
     * @return amountIn_ returns the amount of _tokenIn needed
     */
    function estimateAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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