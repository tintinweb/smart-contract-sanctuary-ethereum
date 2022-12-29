// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/INomiswapRouter02.sol';
import './libraries/BalancerLibrary.sol';
import './libraries/NomiswapLibrary.sol';
import './interfaces/IWETH.sol';

interface INomiswapStablePairExtended is INomiswapStablePair {
    function token0PrecisionMultiplier() external view returns (uint128);
    function token1PrecisionMultiplier() external view returns (uint128);
}

contract NomiswapRouter04 is INomiswapRouter02 {

    address public immutable override factory;
    address public immutable stableSwapFactory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'NomiswapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _stableSwapFactory, address _WETH) {
        factory = _factory;
        stableSwapFactory = _stableSwapFactory;
        WETH = _WETH;
    }

    receive() external payable {
        require(msg.sender == WETH, 'NomiswapRouter: ONLY_WETH'); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address _factory,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (INomiswapFactory(_factory).getPair(tokenA, tokenB) == address(0)) {
            INomiswapFactory(_factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = NomiswapLibrary.getReserves(_factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = NomiswapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'NomiswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = NomiswapLibrary.quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal <= amountADesired, 'NomiswapRouter: TOO_MUCH_A_AMOUNT');
                require(amountAOptimal >= amountAMin, 'NomiswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function balanceLiquidity(
        address _factory,
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired
    ) public virtual returns (uint[4] memory) {
        (uint reserve0, uint reserve1) = NomiswapLibrary.getReserves(_factory, token0, token1);
        if (reserve0 == 0 && reserve1 == 0) {
            uint[4] memory _result;
            return _result;
        } else {
            uint fee = NomiswapLibrary.getSwapFee(_factory, token0, token1);
            uint[4] memory r = [reserve0, reserve1, amount0Desired, amount1Desired];
            if (_factory == factory) {
                return BalancerLibrary.balanceLiquidityCP(r, 1000 - fee, 1000);
            } else if (_factory == stableSwapFactory) {
                address pair = _getPair(token0, token1);
                uint128 token0PrecisionMultiplier = INomiswapStablePairExtended(pair).token0PrecisionMultiplier();
                uint128 token1PrecisionMultiplier = INomiswapStablePairExtended(pair).token1PrecisionMultiplier();
                r[0] = r[0] * token0PrecisionMultiplier;
                r[1] = r[1] * token1PrecisionMultiplier;
                r[2] = r[2] * token0PrecisionMultiplier;
                r[3] = r[3] * token1PrecisionMultiplier;
                uint a = INomiswapStablePair(pair).getA();
                uint[4] memory result = BalancerLibrary.balanceLiquiditySS(r, 4294967295 - fee, 4294967295, a, 100);
                result[0] = result[0] / token0PrecisionMultiplier;
                result[1] = result[1] / token1PrecisionMultiplier;
                result[2] = result[2] / token0PrecisionMultiplier;
                result[3] = result[3] / token1PrecisionMultiplier;
                return result;
            } else {
                revert('NomiswapRouter: UNEXPECTED_FACTORY_TYPE');
            }
        }
    }

    function _addLiquidityImbalanced(
        address _factory,
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired,
        uint amount0Min,
        uint amount1Min
    ) internal virtual returns (uint[4] memory) {
        // create the pair if it doesn't exist yet
        if (INomiswapFactory(_factory).getPair(token0, token1) == address(0)) {
            INomiswapFactory(_factory).createPair(token0, token1);
        }
        uint[4] memory result = balanceLiquidity(_factory, token0, token1, amount0Desired, amount1Desired);
        require(amount0Desired - result[0] + result[2] >= amount0Min, 'NomiswapRouter: INSUFFICIENT_0_AMOUNT');
        require(amount1Desired - result[1] + result[3] >= amount1Min, 'NomiswapRouter: INSUFFICIENT_1_AMOUNT');
        return result;
    }

    function _getFactory(address tokenA, address tokenB) internal view returns (address _factory) {
        _factory = stableSwapFactory;
        if (INomiswapFactory(_factory).getPair(tokenA, tokenB) == address(0)) {
            _factory = factory;
        }
    }

    function _getPairAndFactory(address tokenA, address tokenB) internal view returns (address, address) {
        address _factory = stableSwapFactory;
        address pair = INomiswapFactory(_factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            _factory = factory;
            pair = NomiswapLibrary.pairFor(_factory, tokenA, tokenB);
        }
        return (pair, _factory);
    }

    function _getPair(address tokenA, address tokenB) internal view returns (address pair) {
        pair = INomiswapFactory(stableSwapFactory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = NomiswapLibrary.pairFor(factory, tokenA, tokenB);
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        address _factory = _getFactory(tokenA, tokenB);
        (amountA, amountB) = _addLiquidity(_factory, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = NomiswapLibrary.pairFor(_factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = INomiswapPair(pair).mint(to);
    }

    function addLiquidityImbalanced(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (address token0, ) = NomiswapLibrary.sortTokens(tokenA, tokenB);
        if (tokenA == token0) {
            liquidity = addLiquidityImbalancedSorted(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        } else {
            liquidity = addLiquidityImbalancedSorted(tokenB, tokenA, amountBDesired, amountADesired, amountBMin, amountAMin, to, deadline);
        }
        amountA = amountADesired;
        amountB = amountBDesired;
    }

    function addLiquidityImbalancedSorted(
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired,
        uint amount0Min,
        uint amount1Min,
        address to,
        uint deadline
    ) internal virtual ensure(deadline) returns (uint liquidity) {
        address _factory = _getFactory(token0, token1);
        uint[4] memory balanceResult = _addLiquidityImbalanced(_factory, token0, token1, amount0Desired, amount1Desired, amount0Min, amount1Min);
        address pair = NomiswapLibrary.pairFor(_factory, token0, token1);
        if (balanceResult[0] > 0) {
            if (token0 != WETH) {
                TransferHelper.safeTransferFrom(token0, msg.sender, pair, balanceResult[0]);
            } else {
                TransferHelper.safeTransfer(WETH, pair, balanceResult[0]);
            }          
        }
        if (balanceResult[1] > 0) {
            if (token1 != WETH) {
                TransferHelper.safeTransferFrom(token1, msg.sender, pair, balanceResult[1]);
            } else {
                TransferHelper.safeTransfer(WETH, pair, balanceResult[1]);
            }          
        }
        if (balanceResult[2] > 0 || balanceResult[3] > 0) {
            INomiswapPair(pair).swap(balanceResult[2], balanceResult[3], address(this), new bytes(0));
        }
        if (balanceResult[2] > 0) {
          TransferHelper.safeTransfer(token0, pair, balanceResult[2]);
        }
        if (balanceResult[3] > 0) {
          TransferHelper.safeTransfer(token1, pair, balanceResult[3]);
        }
        if (token0 != WETH) {
            TransferHelper.safeTransferFrom(token0, msg.sender, pair, amount0Desired - balanceResult[0]);
        } else {
            TransferHelper.safeTransfer(WETH, pair, amount0Desired - balanceResult[0]);
        }
        if (token1 != WETH) {
            TransferHelper.safeTransferFrom(token1, msg.sender, pair, amount1Desired - balanceResult[1]);
        } else {
            TransferHelper.safeTransfer(WETH, pair, amount1Desired - balanceResult[1]);
        }

        liquidity = INomiswapPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            factory,
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = _getPair(token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        require(IWETH(WETH).transfer(pair, amountETH), 'NomiswapRouter: FAILED_TO_TRANSFER');
        liquidity = INomiswapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function addLiquidityETHImbalanced(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        IWETH(WETH).deposit{value: msg.value}();
        require(IWETH(WETH).transfer(address(this), msg.value), 'NomiswapRouter: FAILED_TO_TRANSFER');
        (address token0, ) = NomiswapLibrary.sortTokens(token, WETH);
        if (token == token0) {
            liquidity = addLiquidityImbalancedSorted(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin, to, deadline);
        } else {
            liquidity = addLiquidityImbalancedSorted(WETH, token, msg.value, amountTokenDesired, amountETHMin, amountTokenMin, to, deadline);
        }
        amountToken = amountTokenDesired;
        amountETH = msg.value;
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = _getPair(tokenA, tokenB);
        require(INomiswapPair(pair).transferFrom(msg.sender, pair, liquidity), 'NomiswapRouter: FAILED_TO_TRANSFER'); // send liquidity to pair
        (uint amount0, uint amount1) = INomiswapPair(pair).burn(to);
        (address token0,) = NomiswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'NomiswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'NomiswapRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = _getPair(tokenA, tokenB);
        uint value = approveMax ? type(uint256).max : liquidity;
        INomiswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = _getPair(token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        INomiswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = _getPair(token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        INomiswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = NomiswapLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? _getPair(output, path[i + 2]) : _to;
            address pair = _getPair(input, output);
            INomiswapPair(pair).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = NomiswapLibrary.getAmountsOut(factory, stableSwapFactory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = NomiswapLibrary.getAmountsIn(factory, stableSwapFactory, amountOut, path);
        require(amounts[0] <= amountInMax, 'NomiswapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsOut(factory, stableSwapFactory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(_getPair(path[0], path[1]), amounts[0]), 'NomiswapRouter: FAILED_TO_TRANSFER');
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsIn(factory, stableSwapFactory, amountOut, path);
        require(amounts[0] <= amountInMax, 'NomiswapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsOut(factory, stableSwapFactory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'NomiswapRouter: INVALID_PATH');
        amounts = NomiswapLibrary.getAmountsIn(factory, stableSwapFactory, amountOut, path);
        require(amounts[0] <= msg.value, 'NomiswapRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        require(IWETH(WETH).transfer(_getPair(path[0], path[1]), amounts[0]), 'NomiswapRouter: FAILED_TO_TRANSFER');
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = NomiswapLibrary.sortTokens(input, output);
            (address _pair, address _factory) = _getPairAndFactory(input, output);
            INomiswapPair pair = INomiswapPair(_pair);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;

            if (_factory == stableSwapFactory) {
                amountOutput = INomiswapStablePair(_pair).getAmountOut(input, amountInput);
            } else {
                amountOutput = NomiswapLibrary.getConstantProductAmountOut(amountInput, reserveInput, reserveOutput, pair.swapFee());
            }
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? _getPair(output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'NomiswapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        require(IWETH(WETH).transfer(_getPair(path[0], path[1]), amountIn), 'NomiswapRouter: FAILED_TO_TRANSFER');
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'NomiswapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, _getPair(path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return NomiswapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return NomiswapLibrary.getConstantProductAmountOut(amountIn, reserveIn, reserveOut, swapFee);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return NomiswapLibrary.getConstantProductAmountIn(amountOut, reserveIn, reserveOut, swapFee);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return NomiswapLibrary.getAmountsOut(factory, stableSwapFactory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return NomiswapLibrary.getAmountsIn(factory, stableSwapFactory, amountOut, path);
    }
}

pragma solidity >= 0.8.0;

import '@nominex/stable-swap/contracts/interfaces/INomiswapStablePair.sol';
import '@nominex/stable-swap/contracts/interfaces/INomiswapFactory.sol';

library NomiswapLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'NomiswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'NomiswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        return INomiswapFactory(factory).getPair(tokenA, tokenB);
/*
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'83eb759f5ea0525124f03d4ac741bb4af0bb1c703d5f694bd42a8bd72e495a01' // init code hash
            )))));
*/
    }

    function getSwapFee(address factory, address tokenA, address tokenB) internal view returns (uint swapFee) {
        swapFee = INomiswapPair(pairFor(factory, tokenA, tokenB)).swapFee();
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = INomiswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'NomiswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'NomiswapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getConstantProductAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'NomiswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'NomiswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * (1000 - swapFee);
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getConstantProductAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'NomiswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'NomiswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * (1000 - swapFee);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, address stableSwapFactory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'NomiswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            address pair = INomiswapFactory(stableSwapFactory).getPair(path[i], path[i + 1]);
            if (pair != address(0)) {
                amounts[i + 1] = INomiswapStablePair(pair).getAmountOut(path[i], amounts[i]);
            } else {
                (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
                amounts[i + 1] = getConstantProductAmountOut(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i], path[i + 1]));
            }
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, address stableSwapFactory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'NomiswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            address pair = INomiswapFactory(stableSwapFactory).getPair(path[i - 1], path[i]);
            if (pair != address(0)) {
                amounts[i - 1] = INomiswapStablePair(pair).getAmountIn(path[i - 1], amounts[i]);
            } else {
                (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
                amounts[i - 1] = getConstantProductAmountIn(amounts[i], reserveIn, reserveOut, getSwapFee(factory, path[i - 1], path[i]));
            }
        }
    }
    
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

library BalancerLibrary {
    uint256 private constant MAX_LOOP_LIMIT = 256;
    uint256 private constant DERIVATIVE_MULTIPLIER = 1000000;

    function balanceLiquidityCP(
        uint256[4] memory r,
        uint256 feeNumerator,
        uint256 maxFee
    ) public pure returns (uint256[4] memory) {
        {
            uint256 balanced0 = (r[3] * r[0]) / r[1];
            if (balanced0 == r[2]) {
                uint[4] memory _result;
                return _result;
            } else if (balanced0 > r[2]) {
                return inverse(balanceLiquidityCP(inverse(r), feeNumerator, maxFee));
            }
        }
        uint256[4] memory result;
        result[0] = 0;
        result[3] = getYCP(r[0], r[1], result[0], feeNumerator, maxFee);
        uint256 prevX;
        uint256 yDerivative;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            prevX = result[0];
            yDerivative = getYDerivativeCP(
                r[0],
                r[1],
                result[0],
                result[3],
                feeNumerator,
                maxFee,
                DERIVATIVE_MULTIPLIER
            );
            result[0] = getX(r, result[0], result[3], yDerivative);
            if (result[0] != prevX) {
                result[3] = getYCP(r[0], r[1], result[0], feeNumerator, maxFee);
            }
            if (within1(result[0], prevX)) {
                break;
            }
        }
        return result;
    }

    function balanceLiquiditySS(
        uint256[4] memory r,
        uint256 feeNumerator,
        uint256 maxFee,
        uint256 A,
        uint256 A_PRECISION
    ) public pure returns (uint256[4] memory) {
        {
            uint256 balanced0 = (r[3] * r[0]) / r[1];
            if (balanced0 == r[2]) {
                uint[4] memory _result;
                return _result;
            } else if (balanced0 > r[2]) {
                return inverse(balanceLiquiditySS(inverse(r), feeNumerator, maxFee, A, A_PRECISION));
            }
        }
        uint256[4] memory result;
        uint256 d = getD(r[0], r[1], A, A_PRECISION);
        result[0] = 0;
        result[3] = getYSS(r[0], r[1], result[0], d, feeNumerator, maxFee, A, A_PRECISION);
        uint256 prevX;
        uint256 yDerivative;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            prevX = result[0];
            uint256[5] memory derivativeR = [r[0], r[1], result[0], result[3], d];
            yDerivative = getYDerivativeSS(derivativeR, feeNumerator, maxFee, A, A_PRECISION, DERIVATIVE_MULTIPLIER);
            result[0] = getX(r, result[0], result[3], yDerivative);
            if (result[0] != prevX) {
                result[3] = getYSS(r[0], r[1], result[0], d, feeNumerator, maxFee, A, A_PRECISION);
            }
            if (within1(result[0], prevX)) {
                break;
            }
        }
        return result;
    }

    function inverse(uint256[4] memory values) internal pure returns (uint256[4] memory) {
        uint256 temp = values[0];
        values[0] = values[1];
        values[1] = temp;
        temp = values[2];
        values[2] = values[3];
        values[3] = temp;
        return values;
    }

    function getX(
        uint256[4] memory r,
        uint256 x,
        uint256 y,
        uint256 yDerivative
    ) private pure returns (uint256) {
        int256 numerator = int256((r[2] - x) * (r[1] - y)) - int256((r[3] + y) * (r[0] + x));
        numerator = numerator * int256(DERIVATIVE_MULTIPLIER);
        uint256 denominator = yDerivative * (r[0] + r[2]) + r[1] * DERIVATIVE_MULTIPLIER;
        return uint256(int256(x) + numerator / int256(denominator));
    }

    function getYCP(
        uint256 r0,
        uint256 r1,
        uint256 x,
        uint256 feeNumerator,
        uint256 feeDenominator
    ) private pure returns (uint256) {
        uint256 numerator = r0 * r1 * feeDenominator;
        uint256 denominator = r0 * feeDenominator + x * feeNumerator;
        return (r1 * denominator - numerator) / denominator;
    }

    function getYDerivativeCP(
        uint256 r0,
        uint256 r1,
        uint256 x,
        uint256 y,
        uint256 feeNumerator,
        uint256 feeDenominator,
        uint256 resultMultiplier
    ) private pure returns (uint256) {
        uint256 numerator = (r1 - y) * feeNumerator * resultMultiplier;
        uint256 denominator = r0 * feeDenominator + x * feeNumerator;
        return numerator / denominator;
    }

    function getYSS(
        uint256 r0,
        uint256 r1,
        uint256 x,
        uint256 d,
        uint256 feeNumerator,
        uint256 feeDenominator,
        uint256 A,
        uint256 A_PRECISION
    ) private pure returns (uint256) {
        x = x * feeNumerator / feeDenominator;
        return r1 - getY(r0 + x, d, A, A_PRECISION);
    }

    function getYDerivativeSS(
        uint256[5] memory r, // r0, r1, x, y, d
        uint256 feeNumerator,
        uint256 feeDenominator,
        uint256 A,
        uint256 A_PRECISION,
        uint256 resultMultiplier
    ) private pure returns (uint256) {
        uint256 val1 = (r[0] * feeDenominator + feeNumerator * r[2]) / feeDenominator;
        uint256 val2 = r[1] - r[3];
        uint256 denominator = 4 * A * 16 * val1 * val2;
        uint256 dP = (((A_PRECISION * r[4] * r[4]) / val1) * r[4]) / val2;
        uint256 numerator = (denominator * feeNumerator) / feeDenominator + dP;
        numerator = numerator * resultMultiplier;
        return numerator / denominator;
    }

    function getD(
        uint256 xp0,
        uint256 xp1,
        uint256 A,
        uint256 A_PRECISION
    ) public pure returns (uint256 d) {
        uint256 x = xp0 < xp1 ? xp0 : xp1;
        uint256 y = xp0 < xp1 ? xp1 : xp0;
        uint256 s = x + y;
        if (s == 0) {
            return 0;
        }

        uint256 N_A = 16 * A;
        uint256 numeratorP = N_A * s * y;
        uint256 denominatorP = (N_A - 4 * A_PRECISION) * y;

        uint256 prevD;
        d = s;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            prevD = d;
            uint256 N_D = (A_PRECISION * d * d) / x;
            d = (2 * d * N_D + numeratorP) / (3 * N_D + denominatorP);
            if (within1(d, prevD)) {
                break;
            }
        }
    }

    function getY(
        uint256 x,
        uint256 d,
        uint256 A,
        uint256 A_PRECISION
    ) private pure returns (uint256 y) {
        uint256 yPrev;
        y = d;
        uint256 N_A = A * 4;
        uint256 numeratorP = (((A_PRECISION * d * d) / x) * d) / 4;
        unchecked {
            uint256 denominatorP = N_A * (x - d) + d * A_PRECISION; // underflow is possible and desired

            // @dev Iterative approximation.
            for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
                yPrev = y;
                uint256 N_Y = N_A * y;
                y = divRoundUp(N_Y * y + numeratorP, 2 * N_Y + denominatorP);
                if (within1(y, yPrev)) {
                    break;
                }
            }
        }
    }

    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        if (a > b) {
            return a - b <= 1;
        }
        return b - a <= 1;
    }

    function divRoundUp(uint numerator, uint denumerator) private pure returns (uint) {
        return (numerator + denumerator - 1) / denumerator;
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.6.2;

import './INomiswapRouter01.sol';

interface INomiswapRouter02 is INomiswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface INomiswapRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./INomiswapPair.sol";
pragma experimental ABIEncoderV2;

interface INomiswapStablePair is INomiswapPair {

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
    event StopRampA(uint256 A, uint256 t);

    function devFee() external view returns (uint128);

//    function burnSingle(address tokenOut, address recipient) external returns (uint256 amountOut);

    function getA() external view returns (uint256);

    function setSwapFee(uint32) external;
    function setDevFee(uint128) external;

    function rampA(uint32 _futureA, uint40 _futureTime) external;
    function stopRampA() external;

    function getAmountIn(address tokenIn, uint256 amountOut) external view returns (uint256);
    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./INomiswapERC20.sol";

interface INomiswapPair is INomiswapERC20 {

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface INomiswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function INIT_CODE_HASH() external view returns (bytes32);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface INomiswapERC20 is IERC20Metadata {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}