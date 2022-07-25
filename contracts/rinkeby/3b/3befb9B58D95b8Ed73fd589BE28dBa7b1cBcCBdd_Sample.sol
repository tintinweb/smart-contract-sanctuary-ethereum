// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract Sample is IERC20 {
    uint256 private _totalSupply;
    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allowance;

    constructor(){
        _balance[msg.sender] = 10000000;
        _totalSupply = 100000000;
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256){
        return _balance[account];
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        require(amount <= _balance[msg.sender]);
        _balance[msg.sender] -= amount;
        _balance[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner,address spender) public view override returns (uint256){
        return _allowance[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
  
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public override returns (bool) {
        require(amount <= _balance[sender]);
        require(amount <= _allowance[sender][msg.sender]);
        _allowance[sender][msg.sender] -= amount;
        _balance[sender] -= amount;
        _balance[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}

pragma solidity ^0.8.4;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}