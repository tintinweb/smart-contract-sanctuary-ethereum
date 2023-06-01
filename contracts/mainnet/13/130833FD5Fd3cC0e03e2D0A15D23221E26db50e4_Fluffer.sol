/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT License

contract Fluffer {

  ERC20 public token;
  IUniswap private router = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  constructor(address _token) {
    token = ERC20(_token);
    token.approve(address(router), type(uint256).max);
  }

  receive() external payable {}

  /**
   * @notice This function rewards you with 1B 8==D for each Ether sent, but 0.6% of Ether sent will be spent on fees.
  **/
  function fluff() external payable {
    address[] memory path = new address[](2);
    path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    path[1] = address(token);

    uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(0, path, address(this), type(uint256).max);

    path[0] = path[1];
    path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    router.swapExactTokensForETH(amounts[1], 0, path, address(this), type(uint256).max);
    token.transfer(tx.origin, msg.value * 1_000_000_000);
    payable(tx.origin).transfer(address(this).balance);
  }

}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


interface IUniswap {
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
}