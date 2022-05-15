/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity ^0.8.0;
contract Hello {

    string public name;

    constructor() public {
        name = "HelloWorld!";
    }

    function setName(string memory _name) public {
        name = _name;
    }
    
}