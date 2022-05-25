/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


interface IERC20 {
 
    function totalSupply()external view returns(uint);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract FlyFish is IERC20{
    uint public override totalSupply = 10000000000;
    string public name = "Flyfish";
    string public symbol = "FLyF";
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    uint8 public decimals = 3;
    function transfer(address _to, uint256 _value) public override returns (bool){
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool){
        uint tValue = _value-100;
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= tValue;
        balanceOf[_to] += tValue;
        burn(100);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function mint(uint _amount)external {
        balanceOf[msg.sender] += _amount;
        totalSupply -= _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }
    function burn(uint _amount)public {
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }
}