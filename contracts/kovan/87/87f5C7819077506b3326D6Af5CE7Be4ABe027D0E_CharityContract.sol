// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IUniswap2.sol";

contract CharityContract {

  uint tAmount = 1 ;
  address payable Owner;
  address payable Dev;
  address private MyToken;
  IERC20 private Standard;
  IUniswapV2Router02 private uniswapRouter;
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;


  constructor(address _MyToken, address _Owner, address _Dev) {

    Owner = payable(_Owner);
    Dev = payable(_Dev);
    MyToken = _MyToken;
    Standard = IERC20(_MyToken);
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

  }

  modifier onlyOwner() {
      require(msg.sender == Owner, "Not owner");
      _;
  }


  // function >>>>>>>>>>>>>>>>>>>>>>>>>

  receive() payable external {}
  fallback() external payable {}

  function _getTokenAmount(uint256 _Amount) public view returns (uint256) {
    return ( tAmount * _Amount );
  }

  function buyToken() public payable {

    uint _TAmount = _getTokenAmount(msg.value);
    uint _TLiquidity = _TAmount * 99 / 100;
    uint _TMsgSender = _TAmount * 1 / 100;

    Standard.transfer( msg.sender, _TMsgSender );

    uint T_ETH = msg.value;
    uint Owner_ETH = T_ETH * 97 / 100;
    uint Dev_ETH = T_ETH * 2 / 100;
    uint Liq_ETH = T_ETH * 1 / 100;

    Owner.transfer(Owner_ETH);
    Dev.transfer(Dev_ETH);

    addLiquidity( _TLiquidity, Liq_ETH );
  }

  function addLiquidity( uint256 amountTokenDesired, uint msgValue ) internal {
      
    Standard.approve( UNISWAP_ROUTER_ADDRESS, amountTokenDesired );
    uniswapRouter.addLiquidityETH{value: msgValue}(
        MyToken,
        amountTokenDesired,
        0,
        0,
        address(this),
        block.timestamp
    );
      
  }

  function convertEthToToken(uint _tAmount) public payable {
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    uniswapRouter.swapETHForExactTokens{ value: msg.value }(_tAmount, getPathForETHtoToken(), address(this), deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  function getEstimatedETHforToken(uint _tAmount) public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(_tAmount, getPathForETHtoToken());
  }

  function getPathForETHtoToken() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = MyToken;
    
    return path;
  }

  // onlyOwner function >>>>>>>>>>>>>>>>>>>>>>>

  function setTAmount(uint _tAmount) public onlyOwner {
    tAmount = _tAmount;
  }
  
  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswap1.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}