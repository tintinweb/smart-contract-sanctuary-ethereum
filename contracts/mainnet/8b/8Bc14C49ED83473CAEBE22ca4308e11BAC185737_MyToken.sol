/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyToken is IERC20 {
    string public name = "xAiGPTMuskDOGE";
    string public symbol = "XMUSK";
    uint8 public decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 426_930_130_500 * 10**decimals;      
    
    uint256 public buyTaxRate;
    uint256 public sellTaxRate;
    address public taxReceiver;
    address private admin;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        admin = msg.sender;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function setTaxRate(uint256 _buyTaxRate, uint256 _sellTaxRate) public onlyAdmin {
        require(_buyTaxRate <= 100 && _sellTaxRate <= 100, "Tax rate must be less than or equal to 100");
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyAdmin {
        require(_taxReceiver != address(0), "Invalid tax receiver address");
        taxReceiver = _taxReceiver;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 transferAmount = amount;
        uint256 taxAmount = 0;
        
        if (recipient == address(this)) {
            taxAmount = amount * sellTaxRate / 100;
            _balances[taxReceiver] += taxAmount;
            transferAmount -= taxAmount;
            emit Transfer(sender, taxReceiver, taxAmount);
        } else if (sender != address(this)) {
            taxAmount = amount * buyTaxRate / 100;
            _balances[taxReceiver] += taxAmount;
            transferAmount -= taxAmount;
            emit Transfer(sender, taxReceiver, taxAmount);
        }
        
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        emit Transfer(sender, recipient, transferAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function renounceOwnership() public onlyAdmin {
        admin = address(0);
    }
    
    function getAdmin() public view returns (address) {
        return admin;
    }
}