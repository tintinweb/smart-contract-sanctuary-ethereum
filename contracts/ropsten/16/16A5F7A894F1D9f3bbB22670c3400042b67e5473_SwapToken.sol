/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswap {
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
  function WETH() external pure returns (address);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
}

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
  function transfer(address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract SwapToken {
  IUniswap public uniswapRouter;
  address internal constant UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address internal constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;

  mapping(address => uint256) private userTokenBalance;

  constructor() payable {
    uniswapRouter = IUniswap(UniswapV2Router02);
  }

  function swapDAIForEth(uint tokenAmount) external payable {
    require(IERC20(DAI).transferFrom(msg.sender, address(this), tokenAmount), 'transferFrom failed.');
    require(IERC20(DAI).approve(address(UniswapV2Router02), tokenAmount), 'approve failed.');
    uint256 deadline = block.timestamp + 150;
    address[] memory path = getDAICForEthPath();
    uint256 amountOutMin = uniswapRouter.getAmountsOut(tokenAmount, path)[1];
    uniswapRouter.swapExactTokensForETH(tokenAmount, amountOutMin, path, address(this), deadline);
  }

  function getEthForDAIPath() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = DAI;
    return path;
  }

  function getDAICForEthPath() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = DAI;
    path[1] = uniswapRouter.WETH();
    return path;
  }

  function swapETHForDAI(
  ) internal returns (uint[] memory amount) {
    uint256 deadline = block.timestamp + 150;
    address[] memory path = getEthForDAIPath();
    uint256 amountOutMin = uniswapRouter.getAmountsOut(msg.value, path)[1];
    uint256[] memory swapAmount = uniswapRouter.swapExactETHForTokens{value: msg.value}(amountOutMin, path, address(this), deadline);
    return swapAmount;
  }

  function depositTokensForEth() external payable returns(bool) {
    uint256 depositAmount = swapETHForDAI()[1];
    userTokenBalance[msg.sender] += depositAmount;
    return true;
  }


  function withdrawTokens() external payable returns(bool) {
    uint256 amount = userTokenBalance[msg.sender];
    require(amount > 0, 'You have to deposit tokens first');
    userTokenBalance[msg.sender] = 0;
    IERC20(DAI).transfer(payable(msg.sender), amount);
    return true;
  }

  function getUserVaultAndDAIBalance(address _userAddress) public view returns(uint256[] memory){
    uint256[] memory balances = new uint256[](2);
    balances[0] = userTokenBalance[_userAddress];
    balances[1] = IERC20(DAI).balanceOf(_userAddress);
    return balances;
  }
}