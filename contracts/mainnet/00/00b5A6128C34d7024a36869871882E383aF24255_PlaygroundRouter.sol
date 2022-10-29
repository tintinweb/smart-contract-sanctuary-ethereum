//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./utils/interfaces/IPlaygroundRouter.sol";
import "./utils/interfaces/IPlaygroundPair.sol";
import "./utils/interfaces/IPlaygroundFactory.sol";
import "./utils/libs/TransferHelper.sol";
import "./utils/libs/PlaygroundLibrary.sol";
import "./utils/interfaces/IWETH.sol";
import "./utils/interfaces/IERC20.sol";
import "./utils/FeeUtil.sol";

contract PlaygroundRouter is IPlaygroundRouter, FeeUtil {
    address public immutable override WETH;
    address public immutable override factory;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "PlaygroundRouter: EXPIRED");
        _;
    }

    address private USDC;

    constructor(
        address _factory,
        address _WETH,
        uint256 _fee,
        address _feeTo,
        address _USDC
    ) {
        factory = _factory;
        WETH = _WETH;
        USDC = _USDC;
        // Init fee util
        initialize(_factory, _fee, _feeTo);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IPlaygroundFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            if (tokenA == WETH) {
                IPlaygroundFactory(factory).createPair(
                    tokenB,
                    tokenA,
                    address(this)
                );
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenA;
            } else {
                IPlaygroundFactory(factory).createPair(
                    tokenA,
                    tokenB,
                    address(this)
                );
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenB;
            }
        }
        (uint256 reserveA, uint256 reserveB) = PlaygroundLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            if (tokenA == WETH) {
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenA;
            } else if (tokenA == USDC) {
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenA;
            } else {
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenB;
            }
        } else {
            uint256 amountBOptimal = PlaygroundLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "PlaygroundRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = PlaygroundLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "PlaygroundRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

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
        virtual
        override
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
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = PlaygroundLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPlaygroundPair(pair).mint(to);
    }

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
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountETH,
            uint256 amountToken,
            uint256 liquidity
        )
    {
        (amountETH, amountToken) = _addLiquidity(
            WETH,
            token,
            msg.value,
            amountTokenDesired,
            amountETHMin,
            amountTokenMin
        );
        address pair = PlaygroundLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPlaygroundPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = PlaygroundLibrary.pairFor(factory, tokenA, tokenB);
        IPlaygroundPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IPlaygroundPair(pair).burn(to);
        (address token0, ) = PlaygroundLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "PlaygroundRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "PlaygroundRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
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
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = PlaygroundLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IPlaygroundPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

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
    )
        external
        virtual
        override
        returns (uint256 amountToken, uint256 amountETH)
    {
        address pair = PlaygroundLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IPlaygroundPair(pair).permit(
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
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(
            token,
            to,
            IERC20(token).balanceOf(address(this))
        );
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

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
    ) external virtual override returns (uint256 amountETH) {
        address pair = PlaygroundLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IPlaygroundPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PlaygroundLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            (uint256 amount0Fee, uint256 amount1Fee) = _calculateFees(
                input,
                output,
                amounts[i],
                amount0Out,
                amount1Out
            );
            address to = i < path.length - 2
                ? PlaygroundLibrary.pairFor(factory, output, path[i + 2])
                : _to;
            IPlaygroundPair(PlaygroundLibrary.pairFor(factory, input, output)).swap(
                    amount0Out,
                    amount1Out,
                    amount0Fee,
                    amount1Fee,
                    to,
                    new bytes(0)
                );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);

        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        amounts = PlaygroundLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            (amounts[0], appliedFee) = PlaygroundLibrary.applyFee(
                amounts[0],
                fee
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );

            amounts = PlaygroundLibrary.getAmountsOut(factory, amounts[0], path);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        } else {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        }

        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, "PlaygroundRouter: INVALID_PATH");

        uint256 eth = msg.value;
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (eth, appliedFee) = PlaygroundLibrary.applyFee(eth, fee);
            if (address(this) != getFeeTo()) {
                payable(getFeeTo()).transfer(appliedFee);
            }
        }

        amounts = PlaygroundLibrary.getAmountsOut(factory, eth, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pair, amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, "PlaygroundRouter: INVALID_PATH");

        uint256 appliedFee;
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        if (path[0] == pairFeeAddress[pair]) {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            (amounts[0], appliedFee) = PlaygroundLibrary.applyFee(
                amounts[0],
                fee
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
            amounts = PlaygroundLibrary.getAmountsOut(factory, amounts[0], path);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        } else {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        }
        _swap(amounts, path, address(this));

        uint256 amountETHOut = amounts[amounts.length - 1];
        if (path[1] == pairFeeAddress[pair]) {
            (amountETHOut, appliedFee) = PlaygroundLibrary.applyFee(
                amountETHOut,
                fee
            );
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, "PlaygroundRouter: INVALID_PATH");

        uint256 appliedFee;
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        amounts = PlaygroundLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
        _swap(amounts, path, address(this));

        uint256 amountETHOut = amounts[amounts.length - 1];
        if (path[1] == pairFeeAddress[pair]) {
            (amountETHOut, appliedFee) = PlaygroundLibrary.applyFee(
                amountETHOut,
                fee
            );
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, "PlaygroundRouter: INVALID_PATH");

        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);

        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= msg.value,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );

            (amounts[0], appliedFee) = PlaygroundLibrary.applyFee(
                amounts[0],
                fee
            );
            if (address(this) != getFeeTo()) {
                payable(getFeeTo()).transfer(appliedFee);
            }
            amounts = PlaygroundLibrary.getAmountsOut(factory, amounts[0], path);
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(pair, amounts[0]));
        } else {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= msg.value,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(
                IWETH(WETH).transfer(
                    PlaygroundLibrary.pairFor(factory, path[0], path[1]),
                    amounts[0]
                )
            );
        }

        _swap(amounts, path, to);
        // refund dust eth, if any
        uint256 bal = amounts[0] + appliedFee;
        if (msg.value > bal)
            TransferHelper.safeTransferETH(msg.sender, msg.value - bal);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PlaygroundLibrary.sortTokens(input, output);

            (uint256 amountInput, uint256 amountOutput) = _calculateAmounts(
                input,
                output,
                token0
            );
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));

            (uint256 amount0Fee, uint256 amount1Fee) = _calculateFees(
                input,
                output,
                amountInput,
                amount0Out,
                amount1Out
            );

            address to = i < path.length - 2
                ? PlaygroundLibrary.pairFor(factory, output, path[i + 2])
                : _to;

            IPlaygroundPair pair = IPlaygroundPair(
                PlaygroundLibrary.pairFor(factory, input, output)
            );

            pair.swap(
                amount0Out,
                amount1Out,
                amount0Fee,
                amount1Fee,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");

        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amountIn);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (path[1] == pairFeeAddress[pair]) {
            (amountOutMin, appliedFee) = PlaygroundLibrary.applyFee(
                amountOutMin,
                fee
            );
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >=
                amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, "PlaygroundRouter: INVALID_PATH");
        uint256 amountIn = msg.value;

        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            if (address(this) != getFeeTo()) {
                payable(getFeeTo()).transfer(appliedFee);
            }
        }

        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (path[1] == pairFeeAddress[pair]) {
            (amountOutMin, appliedFee) = PlaygroundLibrary.applyFee(
                amountOutMin,
                fee
            );
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >=
                amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, "PlaygroundRouter: INVALID_PATH");
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);

        if (path[0] == pairFeeAddress[pair]) {
            uint256 appliedFee = (amountIn * fee) / (10**3);
            amountIn = amountIn - appliedFee;
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amountIn);
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        amountOutMin;
        if (path[1] == pairFeeAddress[pair]) {
            uint256 appliedFee = (amountOut * fee) / (10**3);
            amountOut = amountOut - appliedFee;
        }
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return PlaygroundLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return
            PlaygroundLibrary.getAmountOut(
                amountIn,
                reserveIn,
                reserveOut,
                0,
                false
            );
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return
            PlaygroundLibrary.getAmountIn(
                amountOut,
                reserveIn,
                reserveOut,
                0,
                false
            );
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return PlaygroundLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
    }

    function _calculateFees(
        address input,
        address output,
        uint256 amountIn,
        uint256 amount0Out,
        uint256 amount1Out
    ) internal view virtual returns (uint256 amount0Fee, uint256 amount1Fee) {
        IPlaygroundPair pair = IPlaygroundPair(
            PlaygroundLibrary.pairFor(factory, input, output)
        );
        (address token0, ) = PlaygroundLibrary.sortTokens(input, output);
        address feeToken = pair.feeToken();
        uint256 totalFee = pair.totalFee();
        amount0Fee = feeToken != token0 ? uint256(0) : input == token0
            ? (amountIn * totalFee) / 10**3
            : (amount0Out * totalFee) / 10**3;
        amount1Fee = feeToken == token0 ? uint256(0) : input != token0
            ? (amountIn * totalFee) / 10**3
            : (amount1Out * totalFee) / 10**3;
    }

    function _calculateAmounts(
        address input,
        address output,
        address token0
    ) internal view returns (uint256 amountInput, uint256 amountOutput) {
        IPlaygroundPair pair = IPlaygroundPair(
            PlaygroundLibrary.pairFor(factory, input, output)
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        bool hasFee = pair.feeToken() != address(0);
        uint256 totalFee = pair.totalFee();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = PlaygroundLibrary.getAmountOut(
            amountInput,
            reserveInput,
            reserveOutput,
            totalFee,
            hasFee
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IPlaygroundRouter {
    function factory() external view returns (address);

    function WETH() external view returns (address);

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IPlaygroundPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function feeToken() external view returns (address);

    function totalFee() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function setFeeToken(address _feeToken) external;

    function setTotalFee(uint256 _totalFee) external returns (bool);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        uint256 amount0Fee,
        uint256 amount1Fee,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        address
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IPlaygroundFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function validPair(address pair) external view returns (bool);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address router
    ) external returns (address pair);

    function setFeeToSetter(address) external;

    function setFeeTo(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        ); // bytes4(keccak256(bytes('approve(address,uint256)')));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TFH::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        ); // bytes4(keccak256(bytes('transfer(address,uint256)')));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TFH::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        ); // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TFH::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TFH::safeTransferETH: ETH transfer failed");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "../interfaces/IPlaygroundPair.sol";

library PlaygroundLibrary {
    uint256 private constant DIVIDER = 1000;
    uint256 private constant FEE_MULTIPLIER = 997;

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 totalFee,
        bool hasFees
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "KLib: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "KLib: INSUFFICIENT_LIQUIDITY"
        );
        uint256 feeOut = hasFees ? DIVIDER - totalFee : FEE_MULTIPLIER;
        uint256 numerator = reserveIn * amountOut * DIVIDER;
        uint256 denominator = (reserveOut - amountOut) * feeOut;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "KLib: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (bool hasFees, uint256 fee) = getBaseAndFee(
                factory,
                path[i - 1],
                path[i]
            );
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                fee,
                hasFees
            );
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 totalFee,
        bool hasFees
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "KLib: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "KLib: INSUFFICIENT_LIQUIDITY"
        );
        uint256 feeIn = hasFees ? DIVIDER - totalFee : FEE_MULTIPLIER;
        uint256 amountInWithFee = amountIn * feeIn;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "KLib: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (bool hasFees, uint256 fee) = getBaseAndFee(
                factory,
                path[i],
                path[i + 1]
            );
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                fee,
                hasFees
            );
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "KLib: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "KLib: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 _data = keccak256(
            abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex"fb7d000825ed574005677f289741002b9869a309e6b61d28755b90eed2139fba" // init code hash
            )
        );

        pair = address(uint160(uint256(_data)));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        IPlaygroundPair pair = IPlaygroundPair(pairFor(factory, tokenA, tokenB));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "KLib: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "KLib: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // fetches and returns the total fee and base token
    function getBaseAndFee(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (bool hasFees, uint256 fee) {
        IPlaygroundPair pair = IPlaygroundPair(pairFor(factory, tokenA, tokenB));
        hasFees = pair.feeToken() != address(0);
        fee = pair.totalFee();

        return (hasFees, fee);
    }

    // given an input amount, return the a new amount with fees applied and the fee amount
    function applyFee(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 appliedFee = (amount * fee) / DIVIDER;
        amount = amount - appliedFee;

        return (amount, appliedFee);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./interfaces/IPlaygroundFactory.sol";
import "./interfaces/IPlaygroundPair.sol";

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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

abstract contract FeeUtil is Ownable {
    uint256 public fee;
    address public feeTo;
    address private factory;
    mapping(address => address) public pairFeeAddress;

    function initialize(
        address _factory,
        uint256 _fee,
        address _feeTo
    ) internal {
        factory = _factory;
        fee = _fee;
        feeTo = _feeTo;
    }

    function setPairFeeAddress(address _pair, address _tokenAddress)
        public
        onlyOwner
    {
        require(
            IPlaygroundFactory(factory).validPair(_pair),
            "Playground::FeeUtil: Invalid pair"
        );
        require(
            IPlaygroundPair(_pair).token0() == _tokenAddress ||
                IPlaygroundPair(_pair).token1() == _tokenAddress,
            "Playground::FeeUtil: token address !valid pair"
        );

        pairFeeAddress[_pair] = _tokenAddress;
    }

    function getFeeTo() public view returns (address) {
        return (feeTo == address(0) ? address(this) : feeTo);
    }

    function setFee(address _feeTo, uint256 _fee) external onlyOwner {
        require(_fee <= 5, "Playground::FeeUtil: Fee exceeds 0.5%");
        feeTo = _feeTo;
        fee = _fee;
    }
}