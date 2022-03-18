/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract XYZToken{
    string public name = "XYZToken";
    string public symbol ="XZY";
    uint256 public decimals = 18;
    uint256 public totalSupply = 100000000000000000000000;//fixed total supply of 1,000,000 tokens
    uint256 public OneXyz = 0.001 ether; // this is the cost of purchasing one of this token

mapping(address => uint256) public balance;
mapping(address => mapping(address => uint256)) public allowances;

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(){
        balance[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success){
        require(balance[msg.sender] >= _value, "You don't have enough balance");
        balance[msg.sender] = balance[msg.sender] - (_value);
        balance[_to] = balance[_to] + (_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
         }

         function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
            require(_value <= balance[_from]);
        require(_value <= allowances[_from][msg.sender]);
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - (_value);
        emit Transfer(_from, _to, _value);
        return true;
         }

         function approve(address _spender, uint256 _value) public returns (bool success){
            require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
         }

         function allowance(address _owner, address _spender) public view returns (uint256 remaining){
             return allowances[_owner][_spender];
         }

         modifier Func{
             require(msg.value >= 0);
             _;
         }
         function buyToken(address reciever) payable Func public returns(uint){
             uint TokenNum = msg.value / OneXyz;
             balance[reciever]= balance[reciever]+TokenNum;
             uint NEWBALANCE = totalSupply + TokenNum; //Increment of the total supply with the newly bought tokens
             return NEWBALANCE;
         }
}