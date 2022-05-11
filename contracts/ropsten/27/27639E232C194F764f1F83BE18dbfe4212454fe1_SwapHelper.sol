// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IERC20 {
  function transferFrom(
      address sender,
      address recipient,
      uint256 amount
  ) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);


}

interface IPancakeV2Router {
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

}

contract SwapHelper {
  address public SONAR_WALLET = 0xE37C4bADb0ccE83AFEAc9b838724c4B31845Ff2d;
  address public constant PANCAKE_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  address public owner;
  mapping(address => bool) alreadyApproved;
  
  IPancakeV2Router public pancakeV2Router = IPancakeV2Router(PANCAKE_V2_ROUTER);
  IPancakeV2Router public uniswapV2Router = IPancakeV2Router(UNISWAP_V2_ROUTER);

  event SwapExETHForTok(address from, address to, uint amountOutMin, uint deadline, uint fee);
  event SwapExTokForTok(address token, address from, address to, uint swappedAmount, uint amountOutMin, uint deadline, uint fee);

  //constructor
  constructor(address _owner) {
    owner = _owner;
  }

  // admin functions
  function renounceOwnership(address admin) external {
    require(msg.sender == admin);
    owner = admin;
  }
  function changeWallet(address wallet) external {
    require(msg.sender == owner);
    SONAR_WALLET = wallet;
  }

  //mutative functions
  function swapExETHForTok(
    uint amountOutMin, 
    address[] calldata path, 
    address to, 
    uint deadline, 
    uint fee
  ) external payable 
  returns (uint[] memory amounts)
  {
    uint excludeFromFee = msg.value - fee;

    (bool sent1, bytes memory result) = UNISWAP_V2_ROUTER.call{value: excludeFromFee}(
      abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)", amountOutMin, path, to, deadline)
    );
    amounts = abi.decode(result, (uint[]));


    (bool sent2,) = SONAR_WALLET.call{value: fee}("");  // transfer 0.2% to sonar wallet
    require(sent1 && sent2, "Fail on sonar wallet");
    
    emit SwapExETHForTok(msg.sender, to, amountOutMin, deadline, fee);
  }

  function swapExTokForTok(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline,
    uint fee,
    address tokenAddress
  ) external returns (uint[] memory amounts)
  {
    uint excludeFromFee = amountIn - fee;

    // if token is not approved yet to uniswap, approve it 
    if(!alreadyApproved[tokenAddress]) {
      IERC20(tokenAddress).approve(UNISWAP_V2_ROUTER, type(uint256).max );
      alreadyApproved[tokenAddress] = true;
    }

    amounts = uniswapV2Router.swapExactTokensForTokens(excludeFromFee, amountOutMin, path, to, deadline);

    // approval is mandatory first
    IERC20(tokenAddress).transferFrom(msg.sender, SONAR_WALLET, fee); // transfer 0.2% to sonar wallet

    emit SwapExTokForTok(tokenAddress, msg.sender, to, excludeFromFee, amountOutMin, deadline, fee);
  }

  function swapExTokForTokSupportingFeeOnTransferTok(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline,
    uint fee,
    address tokenAddress
  ) external {
    uint excludeFromFee = amountIn - fee;
    
    // if token is not approved yet, approve it 
    if(!alreadyApproved[tokenAddress]) {
      IERC20(tokenAddress).approve(UNISWAP_V2_ROUTER, type(uint256).max );
      alreadyApproved[tokenAddress] = true;
    }
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(excludeFromFee, amountOutMin, path, to, deadline);

    // approval is mandatory first
    IERC20(tokenAddress).transferFrom(msg.sender, SONAR_WALLET, fee); // transfer 0.2% to sonar wallet
    emit SwapExTokForTok(tokenAddress, msg.sender, to, excludeFromFee, amountOutMin, deadline, fee);
  }
}