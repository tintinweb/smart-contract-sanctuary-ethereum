/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// File: interfaces/IswapV2Router.sol


pragma solidity ^0.8.0;

interface IswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

interface IswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}
// File: interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: LiquidityRouter.sol


pragma solidity ^0.8.0;



contract Liquidity13Router {
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event Log(string message, uint256 val);

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) external {
        require(_amountA > 0, "Deposit amount can't be zero");
        require(_amountB > 0, "Deposit amount can't be zero");
        require(_tokenA != address(0), "Invalid address!");
        require(_tokenB != address(0), "Invalid address!");

        //Putting both tokens inside this smart contract
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        //Approve uniswap to spend these tokens on our behalf
        IERC20(_tokenA).approve(ROUTER, _amountA);
        IERC20(_tokenB).approve(ROUTER, _amountB);

        //Calling the ROUTER
        //address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline
        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) = IswapV2Router(ROUTER).addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                1,
                1,
                address(this),
                // msg.sender,
                block.timestamp
            );
        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
        emit Log("liquidity", liquidity);
    }

    function removeLiquidity(address _tokenA, address _tokenB) external {
        require(_tokenA != address(0), "Invalid address!");
        require(_tokenB != address(0), "Invalid address!");
        //NOTE: Here UniswapV2Factory is the contract that manages all the tokens and
        //it also manages to mint and burn liquidity tokens.
        address pair = IswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);

        //getting balance of liquidity tokens pair contract holds.
        uint256 liquidity = IERC20(pair).balanceOf(address(this));

        //we are goin to burn all of our liquidity tokens and claim the max amount of
        //tokenA and tokenB and also all of the trading fee
        //So we willapprove ROUTER to spend all of our liquidity tokens
        IERC20(pair).approve(ROUTER, liquidity);

        //removing liquidity
        (uint256 amountA, uint256 amountB) = IswapV2Router(ROUTER)
            .removeLiquidity(
                _tokenA,
                _tokenB,
                liquidity,
                1,
                1,
                address(this),
                // msg.sender,
                block.timestamp
            );
        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
    }

    function getPair(address _tokenA, address _tokenB) external view returns (address pair){
        require(_tokenA != address(0), "Invalid address!");
        require(_tokenB != address(0), "Invalid address!");
      
        pair = IswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
    }

    function allPairs(uint index) external view returns (address pair){
        pair = IswapV2Factory(FACTORY).allPairs(index);
    }

    function allPairsLength() external view returns (uint length){
        length = IswapV2Factory(FACTORY).allPairsLength();
    }

}