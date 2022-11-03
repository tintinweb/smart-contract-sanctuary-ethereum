/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.6;

contract Token{
    string public name="Yelo";
    string public symbol="YELO";
    uint16 public decimal=18;
    uint256 public total_supply=1000000000000000000000000;

    mapping(address=>uint256) public balanceof;
    mapping(address=>mapping(address=>uint256)) public allowance;

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(){
        balanceof[msg.sender]=total_supply;

    }

    function transfer(address _to,uint256 _value) external returns(bool success){
      require(balanceof[msg.sender]>=_value);
      balanceof[msg.sender]=balanceof[msg.sender]-(_value);
      balanceof[_to]=balanceof[_to]+(_value);
      emit Transfer(msg.sender,_to,_value);
      return true; 

    }



    function _transfer(address _from,address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceof[_from]=balanceof[_to]+(_value);
        emit Transfer(_from,_to,_value);
    }

    function approve(address _spender,uint256 _value) external returns(bool success){
        require(_spender != address(0));
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function transferfrom(address _from,address _to,uint256 _value) external returns(bool success){
        require(_value<=balanceof[_from]);
        require(_value<=allowance[_from][msg.sender]);
        allowance[_from][msg.sender]=allowance[_from][msg.sender]-(_value);
        _transfer(_from,_to,_value);
        return true;

    }

    function transfer2(address _from,address _to,uint256 _value) external returns(bool success){
      require(balanceof[_from]>=_value);
      balanceof[_from]=balanceof[_from]-(_value);
      balanceof[_to]=balanceof[_to]+(_value);
      emit Transfer(_from,_to,_value);
      return true; 

    }


    
}