/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

pragma solidity 0.4.24;

contract Test{
    
    string public name;
    
    constructor() public {
        name = "lucy";
    }
    
    function getName() public view returns (string) {
        return name;
    }
    
    function setName(string _name) public {
        name = _name;
    }
}