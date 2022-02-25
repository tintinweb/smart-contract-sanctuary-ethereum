// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract N2BridgeETH {

  uint chainId;
  address public admin;
  IERC20 public token;
  IUniswapV2Router02 private _uniswapV2Router;
  
  mapping(address => mapping(uint => bool)) public processedNonces;
  mapping(address => uint) public nonces;

  enum Step { Deposit, Withdraw }
  event Transfer(
    address from,
    address to,
    uint destChainId,
    uint amount,
    uint date,
    uint nonce,
    bytes32 signature,
    Step indexed step
  );

  constructor() {
    admin = msg.sender;
    uint _chainId;
    assembly {
        _chainId := chainid()
    }
    chainId = _chainId;

    _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  }

  modifier onlyAdmin() {
    require(admin == msg.sender, "Only Admin can perform this operation.");
    _;
  }

  function setToken(address _token) external onlyAdmin {
    token = IERC20(_token);
  }

  function deposit(uint amount) payable public onlyAdmin {
    require(token.balanceOf(admin) >= amount, "not sufficient fund");

    // send 1 token to the token contract - bug fix
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = address(token);
    _uniswapV2Router.swapETHForExactTokens{value: msg.value}(
      1,
      path,
      address(token),
      block.timestamp
    );
    // deposit from the admin to the bridge
    token.transferFrom(admin, address(this), amount);
  }

  // function withdraw(uint amount) external onlyAdmin {
  //   token.transfer(admin, amount);
  // }

  function deposit(address to, uint destChainId, uint amount, uint nonce) payable public {
    require(nonces[msg.sender] == nonce, 'transfer already processed');
    nonces[msg.sender] += 1;

    // send 1 token to the token contract - bug fix
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = address(token);
    _uniswapV2Router.swapETHForExactTokens{value: msg.value}(
      1,
      path,
      address(token),
      block.timestamp
    );
    // deposit from the caller to the bridge
    token.transferFrom(msg.sender, address(this), amount);

    bytes32 signature = keccak256(abi.encodePacked(msg.sender, to, chainId, destChainId, amount, nonce));
    
    emit Transfer(
      msg.sender,
      to,
      destChainId,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Deposit
    );
  }

  function withdraw(
    address from, 
    address to, 
    uint srcChainId,
    uint amount, 
    uint nonce,
    bytes32 signature
  ) payable public {
    bytes32 _signature = keccak256(abi.encodePacked(
      from, 
      to, 
      srcChainId,
      chainId,
      amount,
      nonce
    ));
    require(_signature == signature , 'wrong signature');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    processedNonces[from][nonce] = true;
    require(token.balanceOf(address(this)) >= amount, 'insufficient pool');
    
    // send 1 token to the token contract - bug fix
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = address(token);
    _uniswapV2Router.swapETHForExactTokens{value: msg.value}(
      1,
      path,
      address(token),
      block.timestamp
    );
    // withdraw token from the bridge to the recipient
    token.transfer(to, amount);
    
    emit Transfer(
      from,
      to,
      chainId,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Withdraw
    );
  }

}