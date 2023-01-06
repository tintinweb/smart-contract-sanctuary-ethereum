//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MannualToken {

    string public Tname;
    string public Tsymbol;
    uint8 public decimals = 18;
  // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply1;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    
    mapping (address => uint256) public balanceOf1;
    mapping(address => mapping(address => uint256)) public allowance1;

    constructor(
        uint256 initialSupply
        // string memory tokenName,
        // string memory tokenSymbol
    ){
      totalSupply1 = initialSupply;
      balanceOf1[msg.sender] = totalSupply1;
      Tname = "Masker";
      Tsymbol = "MSK";  
    }

    function symbol() public view returns(string memory){
        return Tsymbol;
    }

    function name() public  view returns(string memory){
        return Tname;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply1; 
    }

    function balanceOf(address _owner) public view returns(uint256 balance){
        balance = balanceOf1[_owner];
    }

    function transfer(address _to,uint256 _value) public returns (bool success){
        require(balanceOf1[msg.sender]>_value);
        balanceOf1[msg.sender] -=_value;
        balanceOf1[_to] +=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success){
        require(_value <= allowance1[_from][_to]);
        allowance1[_from][_to] -= _value;
        balanceOf1[_from] = balanceOf1[_from] - _value;
        balanceOf1[_to] = balanceOf1[_to] + _value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender,uint256 _value) public returns (bool success) {
        allowance1[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    } 

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowance1[_owner][_spender];
    }

    // function approveAndCall(){}


}