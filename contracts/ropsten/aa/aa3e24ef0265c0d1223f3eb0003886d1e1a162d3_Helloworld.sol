/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

pragma solidity ^0.4.0;

contract Helloworld{
    string Myname = "Monkey";
    function getName() public view returns(string){
        return Myname;
    }
    function changeName(string newName) public{
        Myname = newName;
    }

    function pureTest(string name) pure public returns(string){
        return name;
    }
}