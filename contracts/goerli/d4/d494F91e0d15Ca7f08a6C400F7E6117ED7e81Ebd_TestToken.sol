/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract TestToken is IERC20 {

    uint256 _totalSupply;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply){
        name = _name;
        symbol = _symbol;
        _totalSupply = _initialSupply;

        _balances[msg.sender] = _initialSupply;
    }
    
    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256){
        return _balances[account];
    }

     function decimals() public view virtual returns (uint8) {
        return 0;
    }

    function transfer(address to, uint256 amount) external returns (bool){
        address from = msg.sender;
        uint senderBalance = _balances[from];
        require(senderBalance >= amount, "no tiene saldo");
        _balances[msg.sender] = senderBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool){
        require(_balances[msg.sender] >= amount, "no tiene saldo");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool){
        require(_balances[from] >= amount, "no tiene saldo");
        require(_allowances[from][to] >= amount, "no tiene permitido hacer la transferencia");
        _balances[to] += amount;
        _balances[from] = _balances[from] - amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
}