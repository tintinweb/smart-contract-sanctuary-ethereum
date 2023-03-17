// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;


// Uniswap Swap ---* Swap a token on Uniswap *--- //

contract UniswapSwap {

    function uniswapExactInputSingle(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address _tokenIn, uint24 poolFee, address _tokenOut) = abi.decode(_data,(address,uint24,address));

        address swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;


        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: _onBehalf,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });


        txData = abi.encodePacked(uint8(0),swapRouter,uint256(0),uint256(268),abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))", params ));

    }

    function uniswapExactInputMultihop(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address token1, uint24 poolFee1, address token2, uint24 poolFee2,address token3) = abi.decode(_data,(address,uint24,address,uint24,address));

        address swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // We are swapping token1 to token2 and then token2 to token3
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(token1, poolFee1, token2, poolFee2, token3),
                recipient: _onBehalf,
                amountIn: _amount,
                amountOutMinimum: 0
            });


        txData = abi.encodePacked(uint8(0),swapRouter,uint256(0),uint256(268),abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256))", params ));

    }

    function uniswapExactOutputSingle(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address _tokenIn, uint24 poolFee, address _tokenOut) = abi.decode(_data,(address,uint24,address));

        address swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

        uint _balance = IERC20(_tokenIn).balanceOf(_onBehalf);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: _onBehalf,
                amountOut: _amount,
                amountInMaximum: _balance,
                sqrtPriceLimitX96: 0
            });


        txData = abi.encodePacked(uint8(0),swapRouter,uint256(0),uint256(268),abi.encodeWithSignature(
            "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint160))", params ));

    }

    function uniswapExactOutputMultihop(
        address _onBehalf, 
        uint _amount,
        uint _leverage,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address token1, uint24 poolFee1, address token2, uint24 poolFee2,address token3) = abi.decode(_data,(address,uint24,address,uint24,address));

        address swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

        uint _balance = IERC20(token3).balanceOf(_onBehalf); // token3 is tokenOut

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // We are swapping token3 to token2 and then token2 to token1
        ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: abi.encodePacked(token1, poolFee1, token2, poolFee2, token3),
                recipient: _onBehalf,
                amountOut: _amount,
                amountInMaximum: _balance
            });


        txData = abi.encodePacked(uint8(0),swapRouter,uint256(0),uint256(268),abi.encodeWithSignature(
            "exactOutput((bytes,address,uint256,uint256))", params ));

    }
}


interface ISwapRouter{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
}

interface IERC20{
    function balanceOf(address _of) external view returns (uint);
}