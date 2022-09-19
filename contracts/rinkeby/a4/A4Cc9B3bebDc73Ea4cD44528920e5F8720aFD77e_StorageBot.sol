// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapRouter02 {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveInput,
        uint256 reserveOutput
    ) external pure returns (uint256 amountOut);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    function multicall(uint256 deadline, bytes[] calldata data) external;
}

interface UniswapV2Factory01 {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external;
}

contract StorageBot {
    UniswapV2Factory01 private factory;
    ISwapRouter02 private router;

    IERC20 busdToken;
    address owner_;

    address BUSDAddress;
    address collector;

    struct TransactionData {
        address tokenAddr;
        uint256 amountIn;
        uint256 busdAmount;
    }
    TransactionData[] public transactions;

    constructor(
        address _routerAddr,
        address _factortAddr,
        address _BUSDAddr,
        address ownerAddr
    ) {
        router = ISwapRouter02(_routerAddr);
        owner_ = msg.sender;
        factory = UniswapV2Factory01(_factortAddr);
        BUSDAddress = _BUSDAddr;
        collector = ownerAddr;
        transactions.push(TransactionData(address(0), 0, 0));
        busdToken = IERC20(_BUSDAddr);
        busdToken.approve(address(router), ~uint256(0));
    }

    function setData(
        address _firstToken,
        uint256 amountIn,
        uint256 busdAmount_
    ) internal {
        transactions.push(TransactionData(_firstToken, amountIn, busdAmount_));
    }

    function getArrayLength() external view returns (uint256) {
        return transactions.length;
    }

    function deleteArray() external {
        delete transactions;
        transactions.push(TransactionData(address(0), 0, 0));
    }

    function swapToken(uint256 amountIn, address[] memory path) external {
        bytes[] memory constructorArgs = new bytes[](1);
        constructorArgs[0] = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address)",
            amountIn,
            0,
            path,
            address(this)
        );

        uint256 beforeBal = IERC20(path[1]).balanceOf(address(this));

        router.multicall(block.timestamp + 86400, constructorArgs);

        uint256 afterBal = IERC20(path[1]).balanceOf(address(this));

        setData(path[path.length - 1], afterBal - beforeBal, amountIn);
    }

    function sell(uint256 amountIn, address[] memory path) internal {
        bytes[] memory constructorArgmnts = new bytes[](1);
        constructorArgmnts[0] = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address)",
            amountIn,
            0,
            path,
            collector
        );
        router.multicall(block.timestamp + 86400, constructorArgmnts);
    }

    function action() external {
        uint256 i = transactions.length - 1;
        while (i > 0) {
            address token0;
            address pairAddr;

            TransactionData memory _transaction = transactions[i];
            address input = _transaction.tokenAddr;
            address[] memory path = new address[](2);
            path[0] = input;
            path[1] = BUSDAddress;

            (token0, ) = sortTokens(input, BUSDAddress);
            pairAddr = factory.getPair(input, BUSDAddress);

            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddr)
                .getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = input == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);

            uint256 amountOut = _getAmountOut(
                _transaction.amountIn,
                reserveInput,
                reserveOutput
            );

            if (amountOut > _transaction.busdAmount) {
                IERC20(input).approve(address(router), ~uint256(0));
                sell(_transaction.amountIn, path);
                transactions[i] = transactions[transactions.length - 1];
                transactions.pop();
            }

            i--;
        }
    }

    function _getAmountOut(
        uint256 balance,
        uint256 reserveInput,
        uint256 reserveOutput
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = balance * 997;
        uint256 numerator = amountInWithFee * reserveOutput;
        uint256 denominator = reserveInput * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function getPrice(uint256 amountIn, address input)
        external
        view
        returns (uint256)
    {
        address token0;
        address pairAddr;
        (token0, ) = sortTokens(input, BUSDAddress);
        pairAddr = factory.getPair(input, BUSDAddress);

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddr)
            .getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint256 amountOut = _getAmountOut(
            amountIn,
            reserveInput,
            reserveOutput
        );
        return amountOut;
    }
}