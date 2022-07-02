/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract SushiswapLiquidityRouter {

  event Deposit(address sender, uint amountA, uint amountB);
  event Withdraw(address sender, uint amountA, uint amountB);

  IUniswapV2Router02 immutable router;
  IUniswapV2Pair immutable pair;
  IUniswapV2ERC20 immutable usdc;
  IUniswapV2ERC20 immutable usdt;
  //usdc polygon 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
  //usdt polygon 0xc2132D05D31c914a87C6611C10748AEb04B58e8F
  //router polygon 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
  //pair polygon 0x4B1F1e2435A9C96f7330FAea190Ef6A7C8D70001
  //pair rinkeby 0x8edA82BCC2CCb5B82FA8adcAf9d843247b3C1dA6

  mapping(address => uint256) public userBalance;
  uint256 public totalDeposits;

  constructor(
    address _router,
    address _pair,
    address _usdc,
    address _usdt
  ) {
    router = IUniswapV2Router02(_router);
    pair = IUniswapV2Pair(_pair);
    usdc = IUniswapV2ERC20(_usdc);
    usdt = IUniswapV2ERC20(_usdt);
  }

  //usdc/usdt
  function deposit(
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
  ) public {
    address sender = msg.sender;
    //deadline ставим в значение 30 минут
    uint256 deadline = block.timestamp + 30 minutes;
    //отправляем токены на адрес нашего контракта
    usdc.transferFrom(sender, address(this), amountADesired);
    usdt.transferFrom(sender, address(this), amountBDesired);
    //даем разрешение на использование токенов контрактом роутера свапа
    usdc.approve(address(router), amountADesired);
    usdt.approve(address(router), amountBDesired);
    //добавляем ликвидность
    (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
      address(usdc),
      address(usdt),
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin,
      address(this), // ставим адрес получателя наш контракт потому что
                     // мы не хотим чтобы пользователь мог забрать ликвидность напрямую
                     // иначе мы не сможем отследить это
      deadline
    );
    //добавляем LP к пользователю и в общий баланс
    userBalance[sender] += liquidity;
    totalDeposits += liquidity;
    emit Deposit(sender, amountA, amountB);
  }

  event WithdrawTest(uint test);

  function withdraw(
    uint liquidity,
    uint amountAMin,
    uint amountBMin
  ) public {
    address sender = msg.sender;
    //проверяем достаточно ли LP токенов у пользователя
    require(userBalance[sender] >= liquidity, "Not enough liquidity");
    //deadline ставим в значение 30 минут
    uint256 deadline = block.timestamp + 30 minutes;
    //даем разрешение на использование токенов LP контракту роутера
    pair.approve(address(router), 100000000000000000000000000);
    usdc.approve(address(router), 100000000000000000000000000);
    usdt.approve(address(router), 100000000000000000000000000);
    //удаляем ликвидность и забираем токены
    (uint amountA, uint amountB) = router.removeLiquidity(
        address(usdc),
        address(usdt),
        liquidity,
        amountAMin,
        amountBMin,
        sender,
        deadline
    );
    //вычитаем LP у пользователя и в общего баланса
    userBalance[sender] -= liquidity;
    totalDeposits -= liquidity;
    emit Withdraw(sender, amountA, amountB);
  }

}