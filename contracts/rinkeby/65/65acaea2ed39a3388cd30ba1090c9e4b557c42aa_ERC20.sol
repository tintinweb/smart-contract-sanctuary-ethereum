/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address _account) external view returns (uint);

    function transfer(address _recipient, uint _amount) external returns(bool);

    function allowance(address _owner, address _spender) external view returns (uint);

    function approve(address _spender, uint _amount) external returns (bool);

    function transferFrom(address _sender, address _recipient, uint _amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint indexed amount);

    event Approval(address indexed Owner, address indexed Spender, uint indexed amount);
}

contract ERC20 {
    uint public totalSupply;
    mapping(address => uint) public  balanceOf;
    mapping(address => mapping(address => uint)) public  allowance;
    string public name = "test token";
    string public symbol = "TEST";
    uint8 public decimal = 18;

    event Transfer(address indexed from, address indexed to, uint indexed amount);

    event Approval(address indexed Owner, address indexed Spender, uint indexed amount);

    function transfer(address _recipient, uint _amount) external  returns(bool) {
        balanceOf[msg.sender] -= _amount;
        balanceOf[_recipient] += _amount;
        emit Transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) external  returns (bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint _amount) external  returns (bool) {
        allowance[_sender][msg.sender] -= _amount;
        balanceOf[_sender] -= _amount;
        balanceOf[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
        return true;
    }

    function mint(uint _amount) external {
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(uint _amount) external {
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }

}