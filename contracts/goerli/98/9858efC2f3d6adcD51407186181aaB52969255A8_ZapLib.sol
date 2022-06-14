// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../../interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../../interfaces/IUniswapV2Pair.sol";
import {SushiRouterWrapper} from "../../VaultsV2/library/SushiRouterWrapper.sol";
import {Babylonian} from "./Babylonian.sol";

library ZapLib {
    using SafeERC20 for IERC20;
    using SushiRouterWrapper for IUniswapV2Router02;

    enum ZapType {
        ZAP_IN,
        ZAP_OUT
    }

    IUniswapV2Factory public constant sushiSwapFactoryAddress =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    IUniswapV2Router02 public constant sushiSwapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address public constant wethTokenAddress =
        0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
     * @param _fromToken The ERC20 token used
     * @param _pair The Sushiswap pair address
     * @param _amount The amount of fromToken to invest
     * @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
     * @param _intermediateToken intermediate token to swap to (must be one of the tokens in `_pair`) if `_fromToken` is not part of a pair token. Can be zero address if swap is not necessary.
     * @return Amount of LP bought
     */
    function ZapIn(
        address _fromToken,
        address _pair,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _intermediateToken
    ) external returns (uint256) {
        _checkZeroAddress(_fromToken);
        _checkZeroAddress(_pair);

        uint256 lpBought = _performZapIn(
            _fromToken,
            _pair,
            _amount,
            _intermediateToken
        );

        if (lpBought < _minPoolTokens) {
            revert HIGH_SLIPPAGE();
        }

        emit Zap(msg.sender, _pair, ZapType.ZAP_IN, lpBought);

        return lpBought;
    }

    /**
     * @notice Removes liquidity from Sushiswap pools and swaps pair tokens to `_tokenOut`.
     * @param _pair The pair token to remove liquidity from
     * @param _tokenOut The ERC20 token to zap out to
     * @param _amount The amount of liquidity to remove
     * @param _minOut Minimum amount of `_tokenOut` whne zapping out
     * @return _tokenOutAmount Amount of zap out token
     */
    function ZapOut(
        address _pair,
        address _tokenOut,
        uint256 _amount,
        uint256 _minOut
    ) public returns (uint256 _tokenOutAmount) {
        _checkZeroAddress(_tokenOut);
        _checkZeroAddress(_pair);

        _tokenOutAmount = _performZapOut(_pair, _tokenOut, _amount);

        if (_tokenOutAmount < _minOut) {
            revert HIGH_SLIPPAGE();
        }

        emit Zap(msg.sender, _pair, ZapType.ZAP_IN, _tokenOutAmount);
    }

    /**
     * @notice Quotes zap in amount for adding liquidity pair from `_inputToken`.
     * @param _inputToken The input token used for zapping in
     * @param _pairAddress The pair address to add liquidity to
     * @param _amount The amount of liquidity to calculate output
     * @param _intermediateToken Intermidate token that will be swapped out
     *
     * Returns estimation of amount of pair tokens that will be available when zapping in.
     */
    function quoteZapIn(
        address _inputToken,
        address _pairAddress,
        uint256 _amount,
        address _intermediateToken
    ) public view returns (uint256) {
        // This function has 4 steps:
        // 1. Set intermediate token
        // 2. Calculate intermediate token amount: `_amount` if swap isn't required, otherwise calculate swap output from swapping `_inputToken` to `_intermediateToken`.
        // 3. Get amount0 and amount1 quote for swapping `_intermediateToken` to `_pairAddress` pair
        // 4. Get quote for liquidity

        uint256 intermediateAmt;
        address intermediateToken;
        (address _tokenA, address _tokenB) = _getPairTokens(_pairAddress);

        // 1. Set intermediate token
        if (_inputToken != _tokenA && _inputToken != _tokenB) {
            _validateIntermediateToken(_intermediateToken, _tokenA, _tokenB);

            // swap is required:
            // 2. Calculate intermediate token amount: `_amount` if swap isn't required, otherwise calculate swap output from swapping `_inputToken` to `_intermediateToken`.
            address[] memory path = _getSushiPath(
                _inputToken,
                _intermediateToken
            );
            intermediateAmt = sushiSwapRouter.getAmountsOut(_amount, path)[
                path.length - 1
            ];
            intermediateToken = _intermediateToken;
        } else {
            intermediateToken = _inputToken;
            intermediateAmt = _amount;
        }

        // 3. Get amount0 and amount1 quote for swapping `_intermediateToken` to `_pairAddress` pair
        (uint256 tokenABought, uint256 tokenBBought) = _quoteSwapIntermediate(
            intermediateToken,
            _tokenA,
            _tokenB,
            intermediateAmt
        );

        // 4. Get quote for liquidity
        return _quoteLiquidity(_tokenA, _tokenB, tokenABought, tokenBBought);
    }

    /**
     * @notice Quotes zap out amount for removing liquidity `_pair`.
     * @param _pair The address of the pair to remove liquidity from.
     * @param _tokenOut The address of the output token to calculate zap out.
     * @param _amount Amount of liquidity to calculate zap out.
     *
     * Returns the estimation of amount of `_tokenOut` that will be available when zapping out.
     */
    function quoteZapOut(
        address _pair,
        address _tokenOut,
        uint256 _amount
    ) public view returns (uint256) {
        (address tokenA, address tokenB) = _getPairTokens(_pair);

        // estimate amounts out from removing liquidity
        (uint256 amount0, uint256 amount1) = _quoteRemoveLiquidity(
            _pair,
            _amount
        );

        // calculate the amount of `_tokenOut` left once we are done with any necessary swaps
        uint256 tokenOutAmount = 0;

        if (tokenA != _tokenOut) {
            tokenOutAmount += _calculateSwapOut(tokenA, _tokenOut, amount0);
        } else {
            tokenOutAmount += amount0;
        }

        if (tokenB != _tokenOut) {
            tokenOutAmount += _calculateSwapOut(tokenB, _tokenOut, amount1);
        } else {
            tokenOutAmount += amount1;
        }
        return tokenOutAmount;
    }

    /**
     * Validates `_intermediateToken` to ensure that it is not address 0 and is equal to one of the token pairs `_tokenA` or `_tokenB`.
     *
     * Note reverts if pair was not found.
     */
    function _validateIntermediateToken(
        address _intermediateToken,
        address _tokenA,
        address _tokenB
    ) private pure {
        if (
            _intermediateToken == address(0) ||
            (_intermediateToken != _tokenA && _intermediateToken != _tokenB)
        ) {
            revert INVALID_INTERMEDIATE_TOKEN();
        }
    }

    /**
     * 1. Swaps `_fromToken` to `_intermediateToken` (if necessary)
     * 2. Swaps portion of `_intermediateToken` to the other token pair.
     * 3. Adds liquidity to pair on SushiSwap.
     */
    function _performZapIn(
        address _fromToken,
        address _pairAddress,
        uint256 _amount,
        address _intermediateToken
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address tokenA, address tokenB) = _getPairTokens(_pairAddress);

        if (_fromToken != tokenA && _fromToken != tokenB) {
            // swap to intermediate
            _validateIntermediateToken(_intermediateToken, tokenA, tokenB);
            intermediateAmt = _token2Token(
                _fromToken,
                _intermediateToken,
                _amount
            );
            intermediateToken = _intermediateToken;
        } else {
            intermediateToken = _fromToken;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 tokenABought, uint256 tokenBBought) = _swapIntermediate(
            intermediateToken,
            tokenA,
            tokenB,
            intermediateAmt
        );

        return _uniDeposit(tokenA, tokenB, tokenABought, tokenBBought);
    }

    /**
     * 1. Removes `_pair` liquidity from SushiSwap.
     * 2. Swaps liquidity pair tokens to `_tokenOut`.
     */
    function _performZapOut(
        address _pair,
        address _tokenOut,
        uint256 _amount
    ) private returns (uint256) {
        (address tokenA, address tokenB) = _getPairTokens(_pair);
        (uint256 amount0, uint256 amount1) = _removeLiquidity(
            _pair,
            tokenA,
            tokenB,
            _amount
        );

        uint256 tokenOutAmount = 0;

        // Swaps token A form liq pair for output token
        if (tokenA != _tokenOut) {
            tokenOutAmount += _token2Token(tokenA, _tokenOut, amount0);
        } else {
            tokenOutAmount += amount0;
        }

        // Swaps token B form liq pair for output token
        if (tokenB != _tokenOut) {
            tokenOutAmount += _token2Token(tokenB, _tokenOut, amount1);
        } else {
            tokenOutAmount += amount1;
        }

        return tokenOutAmount;
    }

    /**
     * Returns the min of the two input numbers.
     */
    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    /**
     * Simulates adding liquidity to `_tokenA`/`_tokenB` pair on SushiSwap.
     *
     * Logic is derived from `_addLiquidity` (`UniswapV2Router02.sol`) and `mint` (`UniswapV2Pair.sol`)
     * to simulate addition of liquidity.
     */
    function _quoteLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) internal view returns (uint256) {
        uint256 amountA;
        uint256 amountB;
        IUniswapV2Pair pair = _getPair(_tokenA, _tokenB);
        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (_amountADesired, _amountBDesired);
        } else {
            uint256 amountBOptimal = sushiSwapRouter.quote(
                _amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= _amountBDesired) {
                (amountA, amountB) = (_amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = sushiSwapRouter.quote(
                    _amountBDesired,
                    reserveB,
                    reserveA
                );
                (amountA, amountB) = (amountAOptimal, _amountBDesired);
            }
        }

        return
            _min(
                (amountA * pair.totalSupply()) / reserveA,
                (amountB * pair.totalSupply()) / reserveB
            );
    }

    /**
     * Simulates removing liquidity from `_pair` for `_amount` on SushiSwap.
     */
    function _quoteRemoveLiquidity(address _pair, uint256 _amount)
        private
        view
        returns (uint256 _amount0, uint256 _amount1)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        address tokenA = pair.token0();
        address tokenB = pair.token1();
        uint256 balance0 = IERC20(tokenA).balanceOf(_pair);
        uint256 balance1 = IERC20(tokenB).balanceOf(_pair);

        uint256 _totalSupply = pair.totalSupply();
        _amount0 = (_amount * balance0) / _totalSupply;
        _amount1 = (_amount * balance1) / _totalSupply;
    }

    /**
     * Returns the addresses of Sushi pair tokens for the given `_pairAddress`.
     */
    function _getPairTokens(address _pairAddress)
        private
        pure
        returns (address, address)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        return (uniPair.token0(), uniPair.token1());
    }

    /**
     * Helper that returns the Sushi pair address for the given pair tokens `_tokenA` and `_tokenB`.
     */
    function _getPair(address _tokenA, address _tokenB)
        private
        view
        returns (IUniswapV2Pair)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(
            sushiSwapFactoryAddress.getPair(_tokenA, _tokenB)
        );
        if (address(pair) == address(0)) {
            revert NON_EXISTANCE_PAIR();
        }
        return pair;
    }

    /**
     * Removes liquidity from Sushi.
     */
    function _removeLiquidity(
        address _pair,
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) private returns (uint256 amountA, uint256 amountB) {
        _approveToken(_pair, address(sushiSwapRouter), _amount);
        return
            sushiSwapRouter.removeLiquidity(
                _tokenA,
                _tokenB,
                _amount,
                1,
                1,
                address(this),
                deadline
            );
    }

    /**
     * Adds liquidity to Sushi.
     */
    function _uniDeposit(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) private returns (uint256) {
        _approveToken(_tokenA, address(sushiSwapRouter), _amountADesired);
        _approveToken(_tokenB, address(sushiSwapRouter), _amountBDesired);

        (, , uint256 lp) = sushiSwapRouter.addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            1, // amountAMin - no need to worry about front-running since we handle that in main Zap
            1, // amountBMin - no need to worry about front-running since we handle that in main Zap
            address(this), // to
            deadline // deadline
        );

        return lp;
    }

    function _approveToken(address _token, address _spender) internal {
        IERC20 token = IERC20(_token);
        if (token.allowance(address(this), _spender) > 0) return;
        else {
            token.safeApprove(_spender, type(uint256).max);
        }
    }

    function _approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    /**
     * Swaps `_inputToken` to pair tokens `_tokenPairA`/`_tokenPairB` for the `_amount`.
     * @return _amount0 the amount of `_tokenPairA` bought.
     * @return _amount1 the amount of `_tokenPairB` bought.
     */
    function _swapIntermediate(
        address _inputToken,
        address _tokenPairA,
        address _tokenPairB,
        uint256 _amount
    ) internal returns (uint256 _amount0, uint256 _amount1) {
        IUniswapV2Pair pair = _getPair(_tokenPairA, _tokenPairB);
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_inputToken == _tokenPairA) {
            uint256 amountToSwap = _calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            _amount1 = _token2Token(_inputToken, _tokenPairB, amountToSwap);
            _amount0 = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = _calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            _amount0 = _token2Token(_inputToken, _tokenPairA, amountToSwap);
            _amount1 = _amount - amountToSwap;
        }
    }

    /**
     * Simulates swap of `_inputToken` to pair tokens `_tokenPairA`/`_tokenPairB` for the `_amount`.
     * @return _amount0 quote amount of `_tokenPairA`
     * @return _amount1 quote amount of `_tokenPairB`
     */
    function _quoteSwapIntermediate(
        address _inputToken,
        address _tokenPairA,
        address _tokenPairB,
        uint256 _amount
    ) internal view returns (uint256 _amount0, uint256 _amount1) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            sushiSwapFactoryAddress.getPair(_tokenPairA, _tokenPairB)
        );
        (uint256 res0, uint256 res1, ) = pair.getReserves();

        if (_inputToken == _tokenPairA) {
            uint256 amountToSwap = _calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            _amount1 = _calculateSwapOut(
                _inputToken,
                _tokenPairB,
                amountToSwap
            );
            _amount0 = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = _calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            _amount0 = _calculateSwapOut(
                _inputToken,
                _tokenPairA,
                amountToSwap
            );
            _amount1 = _amount - amountToSwap;
        }
    }

    /**
     * Calculates the amounts out from swapping `_tokenA` to `_tokenB` for the given `_amount`.
     */
    function _calculateSwapOut(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) private view returns (uint256 _amountOut) {
        address[] memory path = _getSushiPath(_tokenA, _tokenB);
        // `getAmountsOut` will return same size array as path, and we only care about the
        // last element which will give us the swap out amount we are looking for
        uint256[] memory amountsOut = sushiSwapRouter.getAmountsOut(
            _amount,
            path
        );
        return amountsOut[path.length - 1];
    }

    /**
     * Helper that reverts if `_addr` is zero.
     */
    function _checkZeroAddress(address _addr) private pure {
        if (_addr == address(0)) {
            revert ADDRESS_IS_ZERO();
        }
    }

    /**
     * Returns the appropriate swap path for Sushi swap.
     */
    function _getSushiPath(address _fromToken, address _toToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory path;
        if (_fromToken == wethTokenAddress || _toToken == wethTokenAddress) {
            path = new address[](2);
            path[0] = _fromToken;
            path[1] = _toToken;
        } else {
            path = new address[](3);
            path[0] = _fromToken;
            path[1] = wethTokenAddress;
            path[2] = _toToken;
        }
        return path;
    }

    /**
     * Computes the amount of intermediate tokens to swap for adding liquidity.
     */
    function _calculateSwapInAmount(uint256 _reserveIn, uint256 _userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                _reserveIn * ((_userIn * 3988000) + (_reserveIn * 3988009))
            ) - (_reserveIn * 1997)) / 1994;
    }

    /**
     * @notice This function is used to swap ERC20 <> ERC20
     * @param _source The token address to swap from.
     * @param _destination The token address to swap to.
     * @param _amount The amount of tokens to swap
     * @return _tokenBought The quantity of tokens bought
     */
    function _token2Token(
        address _source,
        address _destination,
        uint256 _amount
    ) internal returns (uint256 _tokenBought) {
        if (_source == _destination) {
            return _amount;
        }

        _approveToken(_source, address(sushiSwapRouter), _amount);

        address[] memory path = _getSushiPath(_source, _destination);
        uint256[] memory amountsOut = sushiSwapRouter.swapExactTokensForTokens(
            _amount,
            1,
            path,
            address(this),
            deadline
        );
        _tokenBought = amountsOut[path.length - 1];

        if (_tokenBought == 0) {
            revert ERROR_SWAPPING_TOKENS();
        }
    }

    /* ========== EVENTS ========== */
    /**
     * Emits when zapping in/out.
     * @param _sender sender performing zap action.
     * @param _pool address of the pool pair.
     * @param _type type of action (ie zap in or out).
     * @param _amount output amount after zap (pair amount for Zap In, output token amount for Zap Out)
     */
    event Zap(
        address indexed _sender,
        address indexed _pool,
        ZapType _type,
        uint256 _amount
    );

    /* ========== ERRORS ========== */
    error ERROR_SWAPPING_TOKENS();
    error ADDRESS_IS_ZERO();
    error HIGH_SLIPPAGE();
    error INVALID_INTERMEDIATE_TOKEN();
    error NON_EXISTANCE_PAIR();
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function totalSupply() external pure returns (uint256);

    function balanceOf(address) external pure returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

library SushiRouterWrapper {
    using SafeERC20 for IERC20;

    /**
     * Sells the received tokens for the provided amounts for the last token in the route
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token
     */
    function sellTokens(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokens(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    /**
     * Sells the received tokens for the provided amounts for ETH
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token.
     */
    function sellTokensForEth(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokensForEth(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    /**
     * Sells one token for a given amount of another.
     * @param self the Sushi router used to perform the sale.
     * @param _route route to swap the token.
     * @param _assetAmount output amount of the last token in the route from selling the first.
     * @param _recepient recepient address.
     */
    function sellTokensForExactTokens(
        IUniswapV2Router02 self,
        address[] memory _route,
        uint256 _assetAmount,
        address _recepient,
        address _token
    ) public {
        require(_route.length >= 2, "SRE2");
        uint256 balance = IERC20(_route[0]).balanceOf(_recepient);
        if (balance > 0) {
            uint256 deadline = block.timestamp + 120; // Two minutes
            _sellTokens(
                self,
                IERC20(_token),
                _assetAmount,
                _recepient,
                deadline,
                _route
            );
        }
    }

    function _sellTokensForEth(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForETH(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    function swapTokens(
        IUniswapV2Router02 self,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recepient
    ) external {
        self.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _recepient,
            block.timestamp
        );
    }

    function _sellTokens(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForTokens(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    // ERROR MAPPING:
    // {
    //   "SRE1": "Rewards: token, amount and routes lenght must match",
    //   "SRE2": "Length of route must be at least 2",
    // }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}