// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ProxyPattern/SolidlyImplementation.sol";

interface IBaseV2Factory {
    function allPairsLength() external view returns (uint256);

    function isPair(address pair) external view returns (bool);

    function pairCodeHash() external pure returns (bytes32);

    function getPair(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address);

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair);
}

interface IBaseV2Pair {
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function getAmountOut(uint256, address) external view returns (uint256);

    function token0() external view returns (address);

    function reserve0() external view returns (uint256);

    function reserve1() external view returns (uint256);
}

interface erc20 {
    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function balanceOf(address) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

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

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

/**
 * @dev
 *      Changes:
 *      -   getAmountOut() and getAmountsOut() does not revert if the trade would 
 *          revert due to the reserve being exactly 1. Returns 0 instead.
 */
contract BaseV2Router01 is SolidlyImplementation {
    struct route {
        address from;
        address to;
        bool stable;
    }
    uint256 internal constant MINIMUM_LIQUIDITY = 10**3;

    /**
     * @dev storage slots start here
     */
    address public factory;
    IWETH public weth;
    bytes32 internal pairCodeHash;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "BaseV2Router: EXPIRED");
        _;
    }

    function initialize(address _factory, address _wftm)
        external
        onlyGovernance
        notInitialized
    {
        factory = _factory;
        pairCodeHash = IBaseV2Factory(_factory).pairCodeHash();
        weth = IWETH(_wftm);
    }

    receive() external payable {
        assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    /****************************************
     *        View and Pure Functions
     ****************************************/

    // Kept for backward-compatibility
    function wftm() external view returns (IWETH _wftm) {
        _wftm = weth;
    }

    function sortTokens(address tokenA, address tokenB)
        public
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "BaseV2Router: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "BaseV2Router: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address tokenA,
        address tokenB,
        bool stable
    ) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1, stable)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "BaseV2Router: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "BaseV2Router: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserveB) / reserveA;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IBaseV2Pair(
            pairFor(tokenA, tokenB, stable)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount, bool stable) {
        address pair = pairFor(tokenIn, tokenOut, true);
        uint256 amountStable;
        uint256 amountVolatile;
        if (IBaseV2Factory(factory).isPair(pair)) {
            address _token0 = IBaseV2Pair(pair).token0();
            uint256 toReserve = tokenOut == _token0
                ? IBaseV2Pair(pair).reserve0()
                : IBaseV2Pair(pair).reserve1();
            if (toReserve > 1) {
                amountStable = IBaseV2Pair(pair).getAmountOut(
                    amountIn,
                    tokenIn
                );
            }
        }
        pair = pairFor(tokenIn, tokenOut, false);
        if (IBaseV2Factory(factory).isPair(pair)) {
            address _token0 = IBaseV2Pair(pair).token0();
            uint256 toReserve = tokenOut == _token0
                ? IBaseV2Pair(pair).reserve0()
                : IBaseV2Pair(pair).reserve1();
            if (toReserve > 1) {
                amountVolatile = IBaseV2Pair(pair).getAmountOut(
                    amountIn,
                    tokenIn
                );
            }
        }
        return
            amountStable > amountVolatile
                ? (amountStable, true)
                : (amountVolatile, false);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint256 amountIn, route[] memory routes)
        public
        view
        returns (uint256[] memory amounts)
    {
        require(routes.length >= 1, "BaseV2Router: INVALID_PATH");
        amounts = new uint256[](routes.length + 1);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < routes.length; i++) {
            address pair = pairFor(
                routes[i].from,
                routes[i].to,
                routes[i].stable
            );
            if (IBaseV2Factory(factory).isPair(pair)) {
                address _token0 = IBaseV2Pair(pair).token0();
                uint256 toReserve = routes[i].to == _token0
                    ? IBaseV2Pair(pair).reserve0()
                    : IBaseV2Pair(pair).reserve1();
                if (toReserve > 1) {
                    amounts[i + 1] = IBaseV2Pair(pair).getAmountOut(
                        amounts[i],
                        routes[i].from
                    );
                }
            }
        }
    }

    function isPair(address pair) external view returns (bool) {
        return IBaseV2Factory(factory).isPair(pair);
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        // create the pair if it doesn't exist yet
        address _pair = IBaseV2Factory(factory).getPair(tokenA, tokenB, stable);
        (uint256 reserveA, uint256 reserveB) = (0, 0);
        uint256 _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = erc20(_pair).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {
            uint256 amountBOptimal = quoteLiquidity(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min(
                    (amountA * _totalSupply) / reserveA,
                    (amountB * _totalSupply) / reserveB
                );
            } else {
                uint256 amountAOptimal = quoteLiquidity(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min(
                    (amountA * _totalSupply) / reserveA,
                    (amountB * _totalSupply) / reserveB
                );
            }
        }
    }

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address _pair = IBaseV2Factory(factory).getPair(tokenA, tokenB, stable);

        if (_pair == address(0)) {
            return (0, 0);
        }

        (uint256 reserveA, uint256 reserveB) = getReserves(
            tokenA,
            tokenB,
            stable
        );
        uint256 _totalSupply = erc20(_pair).totalSupply();

        amountA = (liquidity * reserveA) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = (liquidity * reserveB) / _totalSupply; // using balances ensures pro-rata distribution
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        require(amountADesired >= amountAMin);
        require(amountBDesired >= amountBMin);
        // create the pair if it doesn't exist yet
        address _pair = IBaseV2Factory(factory).getPair(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = IBaseV2Factory(factory).createPair(tokenA, tokenB, stable);
        }
        (uint256 reserveA, uint256 reserveB) = getReserves(
            tokenA,
            tokenB,
            stable
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quoteLiquidity(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "BaseV2Router: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quoteLiquidity(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "BaseV2Router: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            stable,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = pairFor(tokenA, tokenB, stable);
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IBaseV2Pair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            address(weth),
            stable,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = pairFor(token, address(weth), stable);
        _safeTransferFrom(token, msg.sender, pair, amountToken);
        weth.deposit{value: amountETH}();
        assert(weth.transfer(pair, amountETH));
        liquidity = IBaseV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH)
            _safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // Equivalent to addLiquidityETH()
    // Kept for backward-compatibility
    function addLiquidityFTM(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountFTMMin,
        address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountFTM,
            uint256 liquidity
        )
    {
        (amountToken, amountFTM) = _addLiquidity(
            token,
            address(weth),
            stable,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountFTMMin
        );
        address pair = pairFor(token, address(weth), stable);
        _safeTransferFrom(token, msg.sender, pair, amountToken);
        weth.deposit{value: amountFTM}();
        assert(weth.transfer(pair, amountFTM));
        liquidity = IBaseV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountFTM)
            _safeTransferETH(msg.sender, msg.value - amountFTM);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        require(IBaseV2Pair(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IBaseV2Pair(pair).burn(to);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "BaseV2Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "BaseV2Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            address(weth),
            stable,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, amountToken);
        weth.withdraw(amountETH);
        _safeTransferETH(to, amountETH);
    }

    // Equivalent to removeLiquidityETH()
    // Kept for backward-compatibility
    function removeLiquidityFTM(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountFTMMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountToken, uint256 amountFTM) {
        (amountToken, amountFTM) = removeLiquidity(
            token,
            address(weth),
            stable,
            liquidity,
            amountTokenMin,
            amountFTMMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, amountToken);
        weth.withdraw(amountFTM);
        _safeTransferETH(to, amountFTM);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        {
            uint256 value = approveMax ? type(uint256).max : liquidity;
            IBaseV2Pair(pair).permit(
                msg.sender,
                address(this),
                value,
                deadline,
                v,
                r,
                s
            );
        }

        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            stable,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH) {
        address pair = pairFor(token, address(weth), stable);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IBaseV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            stable,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // Equivalent to removeLiquidityETHWithPermit()
    // Kept for backward-compatibility
    function removeLiquidityFTMWithPermit(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountFTMMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountFTM) {
        address pair = pairFor(token, address(weth), stable);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IBaseV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountFTM) = removeLiquidityFTM(
            token,
            stable,
            liquidity,
            amountTokenMin,
            amountFTMMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        route[] memory routes,
        address _to
    ) internal virtual {
        for (uint256 i = 0; i < routes.length; i++) {
            (address token0, ) = sortTokens(routes[i].from, routes[i].to);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = routes[i].from == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < routes.length - 1
                ? pairFor(
                    routes[i + 1].from,
                    routes[i + 1].to,
                    routes[i + 1].stable
                )
                : _to;
            IBaseV2Pair(pairFor(routes[i].from, routes[i].to, routes[i].stable))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        route[] memory routes = new route[](1);
        routes[0].from = tokenFrom;
        routes[0].to = tokenTo;
        routes[0].stable = stable;
        amounts = getAmountsOut(amountIn, routes);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "BaseV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _safeTransferFrom(
            routes[0].from,
            msg.sender,
            pairFor(routes[0].from, routes[0].to, routes[0].stable),
            amounts[0]
        );
        _swap(amounts, routes, to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        amounts = getAmountsOut(amountIn, routes);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "BaseV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _safeTransferFrom(
            routes[0].from,
            msg.sender,
            pairFor(routes[0].from, routes[0].to, routes[0].stable),
            amounts[0]
        );
        _swap(amounts, routes, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(routes[0].from == address(weth), "BaseV2Router: INVALID_PATH");
        amounts = getAmountsOut(msg.value, routes);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "BaseV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        weth.deposit{value: amounts[0]}();
        assert(
            weth.transfer(
                pairFor(routes[0].from, routes[0].to, routes[0].stable),
                amounts[0]
            )
        );
        _swap(amounts, routes, to);
    }

    // Equivalent to swapExactETHForTokens()
    // Kept for backward-compatibility
    function swapExactFTMForTokens(
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(routes[0].from == address(weth), "BaseV2Router: INVALID_PATH");
        amounts = getAmountsOut(msg.value, routes);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "BaseV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        weth.deposit{value: amounts[0]}();
        assert(
            weth.transfer(
                pairFor(routes[0].from, routes[0].to, routes[0].stable),
                amounts[0]
            )
        );
        _swap(amounts, routes, to);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(
            routes[routes.length - 1].to == address(weth),
            "BaseV2Router: INVALID_PATH"
        );
        amounts = getAmountsOut(amountIn, routes);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "BaseV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _safeTransferFrom(
            routes[0].from,
            msg.sender,
            pairFor(routes[0].from, routes[0].to, routes[0].stable),
            amounts[0]
        );
        _swap(amounts, routes, address(this));
        weth.withdraw(amounts[amounts.length - 1]);
        _safeTransferETH(to, amounts[amounts.length - 1]);
    }

    // Equivalent to swapExactTokensForETH()
    // Kept for backward-compatibility
    function swapExactTokensForFTM(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(
            routes[routes.length - 1].to == address(weth),
            "BaseV2Router: INVALID_PATH"
        );
        amounts = getAmountsOut(amountIn, routes);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "BaseV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _safeTransferFrom(
            routes[0].from,
            msg.sender,
            pairFor(routes[0].from, routes[0].to, routes[0].stable),
            amounts[0]
        );
        _swap(amounts, routes, address(this));
        weth.withdraw(amounts[amounts.length - 1]);
        _safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function UNSAFE_swapExactTokensForTokens(
        uint256[] memory amounts,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory) {
        _safeTransferFrom(
            routes[0].from,
            msg.sender,
            pairFor(routes[0].from, routes[0].to, routes[0].stable),
            amounts[0]
        );
        _swap(amounts, routes, to);
        return amounts;
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
 * @title Solidly+ Implementation
 * @author Solidly+
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}