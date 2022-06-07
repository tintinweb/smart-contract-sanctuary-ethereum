/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract BabyOwnable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }
    event OwnershipTransferred(address owner);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract mGIZA is BabyOwnable, IERC20, ReentrancyGuard {
    using SafeMath for uint256;

    address public WETH = 0x000000000000000000000000000000000000dEaD;
    address public GIZA = 0x000000000000000000000000000000000000dEaD;
    IERC20 public giza = IERC20(GIZA);

    string constant _name = "Mummified GIZA";
    string constant _symbol = "mGIZA";
    uint8 constant _decimals = 9;

    uint256 public _totalSupply = 21000000 * (10 ** _decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    bool public canMigrate = true;
    bool public migrated = false;
    bool public enabled = false;

    constructor(address _WETH, address _GIZA) BabyOwnable(msg.sender) {
        WETH = _WETH;
        GIZA = _GIZA;
        giza = IERC20(GIZA);
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function stake(uint256 _amount) external nonReentrant {
        require(!migrated && enabled);
        require(giza.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(giza.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        require(_totalSupply >= _amount, "Invalid amount");
        bool _transfer = giza.transferFrom(msg.sender, address(this), _amount);
        require(_transfer, "Transfer failed");
        _transferFrom(address(this), msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        require(!migrated && enabled);
        require(_balances[msg.sender] >= _amount, "Insufficient balance");
        require(_allowances[msg.sender][address(this)] >= _amount, "Insufficient allowance");
        require(giza.balanceOf(address(this)) >= _amount, "Invalid amount");
        bool _transfer = _transferFrom(msg.sender, address(this), _amount);
        require(_transfer, "Transfer failed");
        giza.transfer(msg.sender, _amount);
    }

    function blockMigration() external onlyOwner {
        require(!migrated);
        canMigrate = false;
    }

    function migrate() external onlyOwner {
        require(!migrated && canMigrate);
        giza.transfer(msg.sender, giza.balanceOf(address(this)));
        migrated = true;
    }

    function enable() external onlyOwner {
        require(!enabled);
        enabled = true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient allowance");
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferGas() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function transferToken(address _address) external onlyOwner {
        require(_address != GIZA && _address != address(this));
        IERC20 _token = IERC20(_address);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}