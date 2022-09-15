// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";


interface IUniswapV2Router02 {

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);  
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) 
        external 
        returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline)
        external 
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface ISushiRouter{
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline) 
        external 
        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path)external view returns (uint[] memory amounts);
}


contract Arbitrage{

    address private constant UNISWAP_V2_ROUTER=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private constant sushirouter=0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    function check_swap(address _tokenA,address _tokenB,uint _amount) external view returns(uint){
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        uint[] memory OutTokenBValue=IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(_amount,path);
        address [] memory new_path = new address[](2);
        new_path[0] = _tokenB;
        new_path[1] = _tokenA;
        uint[] memory OutTokenAValue=ISushiRouter(sushirouter).getAmountsOut(OutTokenBValue[1], new_path);
        return OutTokenAValue[1];
    }

    function arbitrage_swap(address _tokenA,address _tokenB,uint _tokanAvalue) external{

        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        uint[] memory OutTokenBValue=IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(_tokanAvalue,path);

        address [] memory new_path = new address[](2);
        new_path[0] = _tokenB;
        new_path[1] = _tokenA;

        uint[] memory OutTokenAValue=ISushiRouter(sushirouter).getAmountsOut(OutTokenBValue[1], new_path);
        require(OutTokenAValue[1] > _tokanAvalue,'your trade revert');
    
        IERC20 tokenA = IERC20(_tokenA);
        IERC20 tokenB = IERC20(_tokenB);
        
        tokenA.transferFrom(msg.sender,address(this),_tokanAvalue);
        tokenA.approve(UNISWAP_V2_ROUTER,_tokanAvalue);

        uint[] memory amount=IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_tokanAvalue,OutTokenBValue[1],path,msg.sender,block.timestamp+300);
        
        tokenB.transferFrom(msg.sender,address(this),amount[1]); 
        tokenB.approve(sushirouter,amount[1]);

        ISushiRouter(sushirouter).swapExactTokensForTokens(amount[1],OutTokenAValue[1], new_path,msg.sender,block.timestamp+300);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}