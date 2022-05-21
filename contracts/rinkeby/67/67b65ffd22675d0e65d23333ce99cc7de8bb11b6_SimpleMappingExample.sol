/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity >= 0.7.0 < 0.9.0;


contract SimpleMappingExample {
    
    
    mapping(uint => bool) public myMapping;
    mapping(address => bool) public myAddressMapping;
    mapping(uint => mapping(uint => bool)) boolMapping;
    
    function setBoolMapping(uint _index1, uint _index2, bool value) public {
        boolMapping[_index1] [_index2] = true;
    }
    
    function getBoolMapping(uint _index1, uint _index2) public view returns(bool){
        boolMapping[_index1] [_index2];
    }
    
    function setValue(uint _index) public {
        myMapping[_index] = true;
        
    }
    
    function setMyAddress() public {
        myAddressMapping[msg.sender] = true;
    }
}