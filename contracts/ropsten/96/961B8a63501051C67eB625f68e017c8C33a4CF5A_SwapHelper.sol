// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

/*
swapExactETHForTokens
swapExactTokensForTokens
swapExactTokensForTokensSupportingFeeOnTransferTokens
*/
interface IERC20 {
  function transferFrom(
      address sender,
      address recipient,
      uint256 amount
  ) external returns (bool);

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
  address public constant SONAR_WALLET = 0xE37C4bADb0ccE83AFEAc9b838724c4B31845Ff2d;
  address public constant PANCAKE_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  IPancakeV2Router public pancakeV2Router = IPancakeV2Router(PANCAKE_V2_ROUTER);
  IPancakeV2Router public uniswapV2Router = IPancakeV2Router(UNISWAP_V2_ROUTER);

  event SwapExETHForTok(address from, address to, uint amountOutMin, uint deadline, uint fee);
  event SwapExTokForTok(address token, address from, address to, uint amountIn, uint amountOutMin, uint deadline, uint fee);
  event SwapExTokForTokAndFee(address token, address from, address to, uint amountIn, uint amountOutMin, uint deadline, uint fee);

  function swapExETHForTok(uint amountOutMin, address[] calldata path, address to, uint deadline, uint fee)
  external payable 
  returns (uint[] memory amounts)
  {
    uint excludeFromFee = address(this).balance - fee;

    (bool sent1, bytes memory result) = UNISWAP_V2_ROUTER.call{value: excludeFromFee}(
      abi.encodeWithSignature("swapExactETHForTokens(uint,address[],address,uint)", amountOutMin, path, to, deadline)
    );
    amounts = abi.decode(result, (uint[]));

    // amounts = pancakeV2Router.swapExactETHForTokens{ value: excludeFromFee }(amountOutMin, path, to, deadline);
    
    (bool sent2,) = SONAR_WALLET.call{value: fee}("");
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
    (bool sent1, bytes memory result) = UNISWAP_V2_ROUTER.call(
      abi.encodeWithSignature("swapExactTokensForTokens(uint,uint,address[],address,uint)", amountIn, amountOutMin, path, to, deadline)
    );
    amounts = abi.decode(result, (uint[]));
    require(sent1, "Fail on sonar wallet");

    // (bool sent2,) = tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint)", msg.sender, SONAR_WALLET, fee));

    // amounts = pancakeV2Router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    // approval is mandatory first
    IERC20(tokenAddress).transferFrom(msg.sender, SONAR_WALLET, fee);

    emit SwapExTokForTok(tokenAddress, msg.sender, to, amountIn, amountOutMin, deadline, fee);
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
    (bool sent1,) = UNISWAP_V2_ROUTER.call(
      abi.encodeWithSignature("swapExactTokensForTokensSupportingFeeOnTransferTokens(uint,uint,address[],address,uint)", amountIn, amountOutMin, path, to, deadline)
    );
    require(sent1, "Fail on sonar wallet");
    // approval is mandatory first
    IERC20(tokenAddress).transferFrom(msg.sender, SONAR_WALLET, fee);
    emit SwapExTokForTokAndFee(tokenAddress, msg.sender, to, amountIn, amountOutMin, deadline, fee);
  }

}