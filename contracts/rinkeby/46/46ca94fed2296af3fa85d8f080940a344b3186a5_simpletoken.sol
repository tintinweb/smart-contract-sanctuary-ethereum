/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity ^0.4.20;  //
contract simpletoken{  // 
    //
    mapping(address => uint256) public balanceOf;
    //
    constructor (uint256 initialSupply) {
        //
        balanceOf[msg.sender] = initialSupply;
    }

     //
    function transfer(address _to, uint256 _value) public{
        //
        require(balanceOf[msg.sender] >=_value);
        require(balanceOf[_to] +_value >=balanceOf[_to]); //
        
        balanceOf[msg.sender] -= _value;//
        balanceOf[_to] += _value;//
    }
  
}