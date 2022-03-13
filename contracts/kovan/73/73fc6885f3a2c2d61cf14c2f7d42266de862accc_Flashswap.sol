// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.6 <0.8.0;

import './IUniswapV2Router.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Factory.sol';
import './IERC20.sol';

// @author Daniel Espendiller - https://github.com/Haehnchen/uniswap-arbitrage-flash-swap - espend.de
//
// e00: out of block
// e01: no profit
// e10: Requested pair is not available
// e11: token0 / token1 does not exist
// e12: src/target router empty
// e13: pancakeCall not enough tokens for buyback
// e14: pancakeCall msg.sender transfer failed
// e15: pancakeCall owner transfer failed
// e16
contract Flashswap {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function start(
        uint _maxBlockNumber,
        address _tokenBorrow, // example BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _tokenPay, // our profit and what we will get; example BNB
        address _sourceRouter,
        address _targetRouter,
        address _pairAddress
    ) external {
        require(block.number <= _maxBlockNumber, 'e00');

        // recheck for stopping and gas usage
        (int256 profit, uint256 _tokenBorrowAmount) = check(_tokenBorrow, _amountTokenPay, _tokenPay, _sourceRouter, _targetRouter);
        require(profit > 0, 'e01');

        require(_pairAddress != address(0), 'e10');

        address token0 = IUniswapV2Pair(_pairAddress).token0();
        address token1 = IUniswapV2Pair(_pairAddress).token1();

        require(token0 != address(0) && token1 != address(0), 'e11');

        IUniswapV2Pair(_pairAddress).swap(
            _tokenBorrow == token0 ? _tokenBorrowAmount : 0,
            _tokenBorrow == token1 ? _tokenBorrowAmount : 0,
            address(this),
            abi.encode(_sourceRouter, _targetRouter)
        );
    }

    function check(
        address _tokenBorrow, // the token with max value
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _tokenPay, // example: BNB
        address _sourceRouter,
        address _targetRouter
    ) public view returns(int256, uint256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _tokenPay;
        path1[1] = path2[0] = _tokenBorrow;

        uint256 amountOut = IUniswapV2Router(_sourceRouter).getAmountsOut(_amountTokenPay, path1)[1];
        uint256 amountRepay = IUniswapV2Router(_targetRouter).getAmountsOut(amountOut, path2)[1];        

        return (
            int256(amountRepay - _amountTokenPay), // our profit or loss; example output: BNB amount
            amountOut // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }

    function checkExternal(
        address _tokenBorrow, // example: BUSD
        uint256 _amountReserveTokenPayDivideBy, // example: BNB => 10 * 1e18
        address _tokenPay, // example: BNB
        address _sourceRouter,
        address _targetRouter
    ) public view returns(address, uint256, int256, uint256) {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _tokenPay;
        path1[1] = path2[0] = _tokenBorrow;

        address pairAddress = IUniswapV2Factory(IUniswapV2Router(getRouterWithLessLiquidity(_sourceRouter,_targetRouter,_tokenPay,_tokenBorrow,_amountReserveTokenPayDivideBy)).factory()).getPair(path1[0], path1[1]);
        uint256 amountTokenPay = getTokenPayAmount(pairAddress, _tokenPay, _amountReserveTokenPayDivideBy);

        uint256 amountOut = IUniswapV2Router(_sourceRouter).getAmountsOut(amountTokenPay, path1)[1];
        uint256 amountRepay = IUniswapV2Router(_targetRouter).getAmountsOut(amountOut, path2)[1];
        
        return (
            pairAddress,
            amountTokenPay,
            int256(amountRepay - amountTokenPay), // our profit or loss; example output: BNB amount
            amountOut // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }

    function getRouterWithLessLiquidity(address _sourceRouter,
        address _targetRouter,
        address _tokenPay,
        address _tokenBorrow,
        uint256 _amountReserveTokenPayDivideBy
        ) internal view returns (address) 
    {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);
        path1[0] = path2[1] = _tokenPay;
        path1[1] = path2[0] = _tokenBorrow;

        address pairAddressSource = IUniswapV2Factory(IUniswapV2Router(_sourceRouter).factory()).getPair(path1[0], path1[1]);
        uint256 amountTokenPaySource = getTokenPayAmount(pairAddressSource, _tokenPay, _amountReserveTokenPayDivideBy);

        address pairAddressTarget = IUniswapV2Factory(IUniswapV2Router(_targetRouter).factory()).getPair(path1[0], path1[1]);
        uint256 amountTokenPayTarget = getTokenPayAmount(pairAddressTarget, _tokenPay, _amountReserveTokenPayDivideBy);

        address router;
        if(amountTokenPaySource < amountTokenPayTarget)
        {
            router = _sourceRouter;
        } 
        else
        {
            router = _targetRouter;
        }

        return router;
    }

    function getTokenPayAmount(address pairAddress, address _tokenPay, uint256 _amountReserveTokenPayDivideBy) internal view returns (uint256) 
    {
        IUniswapV2Pair iUniswapV2Pair = IUniswapV2Pair(pairAddress);

        (uint112 reserve0, uint112 reserve1,) = iUniswapV2Pair.getReserves();

        uint256 reserveAmount = 0;
        
        {
            reserveAmount = _tokenPay == iUniswapV2Pair.token0() ? reserve0 : reserve1;
        }

        uint256 amountTokenPay = reserveAmount;

        {
            amountTokenPay = amountTokenPay/ _amountReserveTokenPayDivideBy; //always use a given fraction of the pool to avoid big price impacts while taking profits
        }

        return amountTokenPay;
    }

    function execute(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) internal {
        // obtain an amount of token that you exchanged
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;

        IUniswapV2Pair iUniswapV2Pair = IUniswapV2Pair(msg.sender);
        address token0 = iUniswapV2Pair.token0();
        address token1 = iUniswapV2Pair.token1();

        // require(token0 != address(0) && token1 != address(0), 'e16');

        // if _amount0 is zero sell token1 for token0
        // else sell token0 for token1 as a result
        address[] memory path1 = new address[](2);
        address[] memory path = new address[](2);
        path[0] = path1[1] = _amount0 == 0 ? token1 : token0; // c&p
        path[1] = path1[0] = _amount0 == 0 ? token0 : token1; // c&p

        (address sourceRouter, address targetRouter) = abi.decode(_data, (address, address));
        require(sourceRouter != address(0) && targetRouter != address(0), 'e12');

        // IERC20 token that we will sell for otherToken
        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        token.approve(targetRouter, amountToken);

        // calculate the amount of token how much input token should be reimbursed
        uint256 amountRequired = IUniswapV2Router(sourceRouter).getAmountsIn(amountToken, path1)[0];

        // swap token and obtain equivalent otherToken amountRequired as a result
        uint256 amountReceived = IUniswapV2Router(targetRouter).swapExactTokensForTokens(
            amountToken,
            amountRequired, // we already now what we need at least for payback; get less is a fail; slippage can be done via - ((amountRequired * 19) / 981) + 1,
            path,
            address(this), // its a foreign call; from router but we need contract address also equal to "_sender"
            block.timestamp + 60
        )[1];

        // fail if we didn't get enough tokens
        require(amountReceived > amountRequired, 'e13');

        //IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);

        // transfer failing already have error message
        IERC20(_amount0 == 0 ? token0 : token1).transfer(msg.sender, amountRequired); // send back borrow
        IERC20(_amount0 == 0 ? token0 : token1).transfer(owner, amountReceived - amountRequired); // our win
    }

    // pancake, pancakeV2, apeswap, kebab
    function pancakeCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    function waultSwapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // mdex
    function swapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // pantherswap
    function pantherCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // jetswap
    function jetswapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // cafeswap
    function cafeCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // @TODO: pending release
    function BiswapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }

    // @TODO: pending release
    function wardenCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        execute(_sender, _amount0, _amount1, _data);
    }
}