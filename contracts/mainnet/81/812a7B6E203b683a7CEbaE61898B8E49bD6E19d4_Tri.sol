// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract Uni {
    
    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {}
    
    function swapTokensForExactTokens( 
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external virtual returns (uint[] memory amounts) {}
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual returns (uint[] memory amounts) {}
}

contract Tri {
  constructor() public {
  }

  uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  address constant UNI_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Mainet & Rinkeby

  function approve (address x) public {
    IERC20(x).approve(UNI_ADDRESS,MAX_INT);
  }

  function trade_1 (address x, address y, uint256 dx) public returns(uint256 dz) {
    address[] memory path    = new address[](2);
    path[0] = x;
    path[1] = y;
    uint256[] memory amounts1 = Uni(UNI_ADDRESS).swapExactTokensForTokens(dx,0,path,address(this),2654715875);

    return amounts1[1];
  }

  function trade_3 (address x, address y, address z, uint256 dx) public returns(uint256 dz) {
    address[] memory path    = new address[](2);
    path[0] = x;
    path[1] = y;
    uint256[] memory amounts1 = Uni(UNI_ADDRESS).swapExactTokensForTokens(dx,0,path,address(this),2654715875);

    path[0] = y;
    path[1] = z;
    uint256[] memory amounts2 = Uni(UNI_ADDRESS).swapExactTokensForTokens(amounts1[1],0,path,address(this),2654715875);

    path[0] = z;
    path[1] = x;
    uint256[] memory amounts3 = Uni(UNI_ADDRESS).swapExactTokensForTokens(amounts2[1],0,path,address(this),2654715875);

    return amounts3[1];
  }
  
}