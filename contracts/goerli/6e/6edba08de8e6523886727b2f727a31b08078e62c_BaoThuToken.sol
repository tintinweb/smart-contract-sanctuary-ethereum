/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// File: contracts/BaoThuToken.sol



pragma solidity ^0.8.17;

interface ERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function getOwner() external view returns (address);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address receiver, uint amountTokens) external returns (bool);
    function allowance(address owner, address delegate) external view returns (uint);
    function approve(address delegate, uint amountTokens) external returns (bool);
    function transferFrom(address sender, address receiver, uint amountTokens) external returns (bool);
    
    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BaoThuToken is ERC20 {

    address _owner;
    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    constructor() public {
        _name = "BaoThuTokenExample";
        _symbol = "BTTE";
        _decimals = 0;
        _totalSupply = 1000000;
        _balances[msg.sender] = 1000000;
        _owner = msg.sender;

        emit Transfer(address(0), msg.sender, 1000000);
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    function getOwner() external view returns (address) {
        return _owner;
    }
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Nạp tiền vào ví
    function transfer(address receiver, uint amountTokens) external returns (bool) {
        require(amountTokens <= _balances[msg.sender]);
        _balances[msg.sender] -= amountTokens;
        _balances[receiver] += amountTokens;

        emit Transfer(msg.sender, receiver, amountTokens);
        return true;
    }

    // Set số Token có thể sử dụng cho delegate trên tài khoản của caller
    function approve(address delegate, uint amountTokens) external returns (bool) {
        _allowances[msg.sender][delegate] = amountTokens;
        emit Approval(msg.sender, delegate, amountTokens);
        return true;
    }

    // Lấy ra số Token có thể dùng của delegate trên tài khoản của owner
    function allowance(address owner, address delegate) external view returns (uint) {
        return _allowances[owner][delegate];
    }

    // Chuyển tiền từ sender sang cho receiver
    function transferFrom(address sender, address receiver, uint amountTokens) external returns (bool) {
        require(amountTokens <= _balances[sender]);
        require(amountTokens <= _allowances[sender][msg.sender]);

        _balances[sender] -= amountTokens;
        _allowances[sender][msg.sender] -= amountTokens;
        _balances[receiver] += amountTokens;

        emit Transfer(sender, receiver, amountTokens);
        return true;
    }
}