/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

pragma solidity ^0.5.13;

contract VariableExamples{
    // variable uint
    //initialyzed with default value 0
    uint256 public myUint;

    function setMyUint(uint _myUint) public{
        myUint = _myUint;
    }


    /* variable bool
    //initialized with default value false
    bool public myBool;

    function setMyBool(bool _myBool) public{
        myBool = _myBool;
    }
    */

    /*increment and decrement
    //be carefull in solidity there is no warning 
    uint8 public myUint8;

    function incrementUint() public{
        myUint8++;
    }

    function decrementUint() public{
        myUint8--;
    }
    */

    /*variable address
    //default value 0x0000000000000000000000000000000000000000
    address public myAddress;

    function setAddress(address _myAddress) public{
        myAddress = _myAddress;
    }

    function getBalanceOfMyAddress() public view returns(uint){
        return myAddress.balance;
    }
    */

    /*variable string
    string public myString = "Hello world!";

    function setMyString(string memory _myString) public{
        myString = _myString;
    }
    */
    
    /*variable mapping
    mapping(uint => bool) public myMapping;
    mapping(address => bool) public myAddressMapping;

    function setValue(uint _index) public{
        myMapping[_index] = true;
    }

    function setMyAddressToTrue() public{
        myAddressMapping[msg.sender] = true;
    }
    */
}