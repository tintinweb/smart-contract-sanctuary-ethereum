/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.8;

interface IUniswap{

      function swapTokensForExactETH(uint amountOut, 
      uint amountInMax, 
      address[] calldata path, 
      address to, 
      uint deadline)
      external
      returns (uint[] memory amounts);
      function WETH() external pure returns (address);

}

interface IERC20{
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool); 
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);      
}

contract MyToken{
    IUniswap uniswap;
    string public name;
    string public symbol;
    uint public totalSupply;
    mapping(address => uint) balanceOf;

    constructor(address _uniswap){
        uniswap = IUniswap(_uniswap);
        name = "MyToken";
        symbol = "TSK";
        totalSupply = 1*10**18;

    }

    function swapTokensForExactETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        uint deadline
    )
    external{
        IERC20(token).transferFrom(msg.sender, address(this), amountIn);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        IERC20(token).approve(address(uniswap), amountIn);
        uniswap.swapTokensForExactETH(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            deadline
        );


    }
}