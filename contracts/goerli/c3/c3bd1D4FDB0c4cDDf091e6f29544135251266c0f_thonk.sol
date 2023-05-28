/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: IMAH FIRIN MAH LAZOR
pragma solidity >=0.8.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface v2factory {
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
    function getPair(address, address) external view returns (address pair);
    }

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

}

interface IFlashLoanRecipient {
 
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

interface IVault {
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);
}

contract thonk is IFlashLoanRecipient, IUniswapV2Callee {

    address public immutable owner;
    v2factory private immutable uniswapv2factory;
    v2factory private immutable sushiswapv2factory;
    address private immutable vault;
    address private immutable uniswapv2;
    address private immutable uniswapv3;
    address private immutable sushiswapv2;

    struct pair {
        address token0;
        address token1;
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
    }

    struct SwapData {
        address token0;
        address token1;
        address pair;
        address midToken;
        uint method;
        address router;
    }

    constructor(address _owner, address _sushiswapv2factory, address _uniswapv2factory, address _vault, address _uniswapv2, address _uniswapv3, address _sushiswapv2) {
        owner = _owner;
        uniswapv2factory = v2factory(_uniswapv2factory);
        sushiswapv2factory = v2factory(_sushiswapv2factory);
        vault = _vault;
        uniswapv2 = _uniswapv2;
        uniswapv3 = _uniswapv3;
        sushiswapv2 = _sushiswapv2;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "fuck off");
        _;
    }

    function kill() external onlyOwner {
        selfdestruct(payable(owner));
    }

    function drainERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "u don't have any lmfao");
        token.transfer(owner, balance);
    }

    function getAllPairsLength(uint8 dex) public view returns (uint) {
        if (dex == 0){
            return uniswapv2factory.allPairsLength();
        }
        else if (dex == 1){
            return sushiswapv2factory.allPairsLength();
        }
        else {
            return 0;
        }
    }

    function getPairById(uint i, uint8 dex) public view returns (address) {
        if (dex == 0){
            return uniswapv2factory.allPairs(i);
        }
        else if (dex == 1){
            return sushiswapv2factory.allPairs(i);
        }
    }

    function getPairByTokens(address tokenA, address tokenB, uint8 dex) public view returns (address) {
        if (dex == 0){
            return uniswapv2factory.getPair(tokenA, tokenB);
        }
        else if (dex == 1){
            return sushiswapv2factory.getPair(tokenA, tokenB);
        }
    }

    function getReserves(address _pool) public view returns (pair memory) {
        IUniswapV2Pair pool = IUniswapV2Pair(_pool);
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pool.getReserves();
        address _token0 = pool.token0();
        address _token1 = pool.token1();
        return pair(_token0, _token1, _reserve0, _reserve1, _blockTimestampLast);
    }
    
    function zestycall(uint start, uint amount, uint8 dex) external view returns (pair[] memory){
        pair[] memory list = new pair[](amount);
        for (uint i = start; i < start + amount; i++) {
            list[i-start] = getReserves(getPairById(i, dex));
        }
        return list;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn*997;
        uint numerator = amountInWithFee*reserveOut;
        uint denominator = reserveIn*1000+amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function v2routerswap(
        uint amountIn,
        uint amountOutMin,
        address tokenIn,
        address tokenOut,
        uint deadline,
        address router
    ) private returns (uint) {

        IUniswapV2Router02 v2router = IUniswapV2Router02(router);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        if (IERC20(tokenIn).allowance(address(this), address(v2router)) < amountIn) {
            IERC20(tokenIn).approve(address(v2router), type(uint256).max);
        }

        uint[] memory amountOut = v2router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );
        return amountOut[1];
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        SwapData memory swapData = abi.decode(data, (SwapData));
        require(msg.sender == swapData.pair, "fuck off");
        if (swapData.method == 0){
            //different exchange arb, router is the second dex
            if (amount1 > amount0){
                //if token 1 was flashloaned, pay back token0
                uint finalAmt = v2routerswap(amount1, 1, swapData.token1, swapData.token0, block.timestamp + 20 seconds, swapData.router);
                pair memory pool = getReserves(swapData.pair);
                uint reserve0 = pool.reserve0;
                uint reserve1 = pool.reserve1;
                uint amountRequired = getAmountIn(amount1, reserve0, reserve1);
                require(finalAmt > amountRequired, "loser");
                IERC20(swapData.token0).transfer(swapData.pair, amountRequired);
                IERC20(swapData.token0).transfer(owner, finalAmt-amountRequired);
            }
            else {
                //if token 0 was flashloaned, pay back token1
                uint finalAmt = v2routerswap(amount0, 1, swapData.token0, swapData.token1, block.timestamp + 20 seconds, swapData.router);
                pair memory pool = getReserves(swapData.pair);
                uint reserve0 = pool.reserve0;
                uint reserve1 = pool.reserve1;
                uint amountRequired = getAmountIn(amount0, reserve1, reserve0);
                require(finalAmt > amountRequired, "loser");
                IERC20(swapData.token1).transfer(swapData.pair, amountRequired);
                IERC20(swapData.token1).transfer(owner, finalAmt-amountRequired);
            }
        }
        else if (swapData.method == 1){
            //triangular on router
            if (amount1 > amount0){
                //if token1 was flashloaned, pay back token0
                uint midAmt = v2routerswap(amount1, 1, swapData.token1, swapData.midToken, block.timestamp + 20 seconds, swapData.router);
                uint finalAmt = v2routerswap(midAmt, 1, swapData.midToken, swapData.token0, block.timestamp + 20 seconds, swapData.router);
                pair memory pool = getReserves(swapData.pair);
                uint reserve0 = pool.reserve0;
                uint reserve1 = pool.reserve1;
                uint amountRequired = getAmountIn(amount1, reserve0, reserve1);
                require(finalAmt > amountRequired, "loser");
                IERC20(swapData.token0).transfer(swapData.pair, amountRequired);
                IERC20(swapData.token0).transfer(owner, finalAmt-amountRequired);
            }
            else {
                //if token0 was flashloaned, pay back token1
                uint midAmt = v2routerswap(amount0, 1, swapData.token0, swapData.midToken, block.timestamp + 20 seconds, swapData.router);
                uint finalAmt = v2routerswap(midAmt, 1, swapData.midToken, swapData.token1, block.timestamp + 20 seconds, swapData.router);
                pair memory pool = getReserves(swapData.pair);
                uint reserve0 = pool.reserve0;
                uint reserve1 = pool.reserve1;
                uint amountRequired = getAmountIn(amount0, reserve1, reserve0);
                require(finalAmt > amountRequired, "loser");
                IERC20(swapData.token1).transfer(swapData.pair, amountRequired);
                IERC20(swapData.token1).transfer(owner, finalAmt-amountRequired);
            }
        }
    }

    function flashswap(uint amountIn0, uint amountIn1, address _pair, address token0, address token1, address midToken, uint method, address router) public onlyOwner {
        bytes memory data = abi.encode(token0, token1, _pair, midToken, method, router);
        if (amountIn1 == 0){
            IERC20(token0).approve(_pair, type(uint256).max);
            pair memory pool = getReserves(_pair);
            uint reserve0 = pool.reserve0;
            uint reserve1 = pool.reserve1;
            uint amount1Out = getAmountOut(amountIn0, reserve0, reserve1);
            IUniswapV2Pair(_pair).swap(0, amount1Out, address(this), data);
        }
        else if (amountIn0 == 0){
            IERC20(token1).approve(_pair, type(uint256).max);
            pair memory pool = getReserves(_pair);
            uint reserve0 = pool.reserve0;
            uint reserve1 = pool.reserve1;
            uint amount0Out = getAmountOut(amountIn1, reserve1, reserve0);
            IUniswapV2Pair(_pair).swap(amount0Out, 0, address(this), data);
        }
    }

    function makeFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        address tokenA,
        address tokenB,
        //initial router for two dex arbitrage, dex for triangular
        address router,
        uint method
    ) public onlyOwner {
        bytes memory userData = abi.encode(tokenA, tokenB, router, method);
        IVault(vault).flashLoan(IFlashLoanRecipient(address(this)), tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == vault, "fuck off");
        (address tokenA, address tokenB, address router, uint method) = abi.decode(userData, (address, address, address, uint));
        uint256 amount = amounts[0];
        IERC20 initialToken = tokens[0];
        IERC20 finalToken = IERC20(tokenB);
        uint256 deadline = block.timestamp + 20 seconds;
        if (method == 0) {
            //triangular on uni, flashloaned to A to B back to flashloaned(initialToken)
            IERC20 midToken = IERC20(tokenA);

            uint amount1 = v2routerswap(amount, 1, address(initialToken), address(midToken), deadline, router);

            uint amount2 = v2routerswap(amount1, 1, address(midToken), address(finalToken), deadline, router);

            uint finalAmt = v2routerswap(amount2, 1, address(finalToken), address(initialToken), deadline, router);

            require(finalAmt > amount, "loser");
            initialToken.transfer(vault, amount);
            initialToken.transfer(owner, finalAmt-amount);
        }
        else if (method == 1) {
            //different dex arb, flashloaned to B back to flashloaned(initialToken), A doesn't matter
            uint amount1 = v2routerswap(amount, 1, address(initialToken), address(finalToken), deadline, router);
            uint finalAmt;
            if (router == uniswapv2){
                finalAmt = v2routerswap(amount1, 1, address(finalToken), address(initialToken), deadline, sushiswapv2);
            }
            else {
                finalAmt = v2routerswap(amount1, 1, address(finalToken), address(initialToken), deadline, uniswapv2);
            }
            require(finalAmt > amount, "loser");
            initialToken.transfer(vault, amount);
            initialToken.transfer(owner, finalAmt-amount);

        }
    }
}