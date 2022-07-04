/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router01 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
}

interface IUniswapV2Factory {
    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function decimals() external view returns (uint8);
    
    event Transfer( address indexed from, address indexed to, uint256 value );
    event Approval( address indexed owner, address indexed spender, uint256 value );
}
interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract TokenSwapperImproved{
    
    IUniswapV2Router02 constant public ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory immutable public factory = IUniswapV2Factory(ROUTER.factory());
    address immutable public weth = ROUTER.WETH();

    mapping(address=>bool) public approved;
    receive() external payable {}

    //Approve spending for contract
    function approveThis(IERC20 _token) external{
        approved[address(_token)] = _token.approve(address(ROUTER), _token.totalSupply());
    }


    //Buying interface
    function swapExactETHForTokensSupportingFee(address _token) external payable {
        address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = _token;
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, msg.sender, block.timestamp);
    }

    function swapETHForExactTokens(address _token) external payable returns (uint[] memory amounts) {
        uint maxtx = IERC20(_token).totalSupply() / 200;
        address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = _token;
        amounts = ROUTER.swapETHForExactTokens{value: msg.value}(maxtx, path, msg.sender, block.timestamp);
        if(address(this).balance > 0) payable(msg.sender).transfer(address(this).balance);
    }



    //combined interface
    function swapExactTokensForTokensSupportingFee(IERC20 send_token, address receive_token, uint _amountIn) external {
        //address token to send, address token to receive, amount of send w/o decimals
        require(approved[address(send_token)], "Approve send token");
        //uint amount = _amountIn * 10 ** (send_token.decimals());
        //msg.sender need to approve address(this) contract
        bool success = send_token.transferFrom(msg.sender, address(this), _amountIn);
        require(success, "FAILED transfer to this");
        address[] memory path = new address[](3);
            path[0] = address(send_token);
            path[1] = weth;
            path[2] = receive_token;
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amountIn, 0, path, msg.sender, block.timestamp);
    }
        
    //SELLING FEE TOKENS ISSUE
    //-problem is you need to send tokens to CA to sell it for fee tokens you pay fee 2 times
    // 1 time when you transfer token to CA
    // 2 time when you selling tokens from CA
    // 3 Send token ammount < token.balanceOf(address(this)) so swap gives an error;
    //USELESS for swapping Fee tokens 
    
        function swapExactTokensForETHSupportingFee(IERC20 send_token, uint _amountIn) external{
        require(approved[address(send_token)], "Approve send token");
        uint i_amount = _amountIn * 10 ** (send_token.decimals());
        //msg.sender need to approve address(this) contract
        bool success = send_token.transferFrom(msg.sender, address(this), i_amount);
        require(success, "FAILED transfer to this");
        address[] memory path = new address[](2);
            path[0] = address(send_token);
            path[1] = weth; 
        uint amount = send_token.balanceOf(address(this));
        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, msg.sender, block.timestamp);
    }
}