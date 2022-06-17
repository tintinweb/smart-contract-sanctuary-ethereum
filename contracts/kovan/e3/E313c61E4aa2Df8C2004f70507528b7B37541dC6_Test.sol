pragma solidity >=0.6.0 <0.7.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts); 
}

contract Test{
    address public UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public PUSH_TOKEN_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public _daiAddress = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;


    uint public POOL_FUNDS;
    
    
    function swapADaiForPush(uint _amountOutMin) external{
        // get dai from all aDai
        uint _contractBalance = IERC20(_daiAddress).balanceOf(address(this));
        require(_contractBalance > 0, "EPNSCoreV1::swapADaiForPush: Contract ADai balance is zero");
        
        IERC20(_daiAddress).approve(UNISWAP_V2_ROUTER,_contractBalance);

        address[] memory path = new address[](3);
        path[0] = _daiAddress;
        path[1] = WETH_ADDRESS;
        path[2] = PUSH_TOKEN_ADDRESS;

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _contractBalance,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        
        // Update pool funds
        POOL_FUNDS = IERC20(PUSH_TOKEN_ADDRESS).balanceOf(address(this));
    }

    function onlyApprove() external{
        uint _contractBalance = IERC20(_daiAddress).balanceOf(address(this));
        require(_contractBalance > 0, "EPNSCoreV1::swapADaiForPush: Contract ADai balance is zero");
        IERC20(_daiAddress).approve(UNISWAP_V2_ROUTER,_contractBalance);
    }
}


// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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