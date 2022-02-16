/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.8.4;

contract NameContract {

    string public name = "Irish";

/*    function getName() public view returns (string memory) 
    {
        return name;
    }*/

    function setName(string memory newName) public
    {
        name = newName;
    }

}