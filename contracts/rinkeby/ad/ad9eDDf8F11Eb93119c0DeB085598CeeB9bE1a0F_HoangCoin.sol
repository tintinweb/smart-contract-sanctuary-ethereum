// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfers(address indexed from, address indexed to, uint amount);
    
    event Approval(address indexed owner, address indexed sender, uint amount);

}


contract HoangCoin is IERC20 {
    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    string public _name;
    string public _symbol;
    uint public _decimals;

    constructor() {
    _name = "Hoang Coin";
    _symbol = "HHC";
    _decimals = 18;
    totalSupply = 30000000000000000000000000;
    balanceOf[msg.sender] = totalSupply;

    emit Transfers(address(0), msg.sender, totalSupply);
  }

    function transfer(address recipient, uint amount) external returns (bool)
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfers(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool)
    {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfers(sender, recipient, amount);
        return true;
    }
    
    function balancesSender(address sender, uint amount) external returns(bool)
    {
        balanceOf[sender] += amount;
        return true;
    }

    function mint(uint amount) external
    {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfers(address(0), msg.sender, amount);
    }

    function burn(uint amount) external
    {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfers(address(0), msg.sender, amount);
    }
}