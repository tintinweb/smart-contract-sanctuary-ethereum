/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// File: tesure/q3.sol


pragma solidity ^0.8.17;
contract Meraz{
    address private owner;
    uint16 private value2;
    string private value1 ;
    
    constructor(){
        owner=msg.sender;
    }
    event Lograise(string statement);
    function meraz(uint256 _input)  public view   returns(string memory){
        require(value2==_input,"incorrect input , please attempt again");
        return value1;
    }

    function setvalue(string memory _value,uint16 input_value) public {
        require(msg.sender==owner);
        value1=_value;
        value2=input_value;

    }

    receive () payable external {
        emit Lograise("called fallback function");
    }


}