/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity >=0.4.22;
contract HelloWorld
{
    string public yourName;
    
    constructor() public 
    {
        yourName = "World";
    }
    
    function set(string memory name) public
    {
        yourName = name;
    }
    
    function hello() view public returns (string memory) 
    {
        return yourName;
    }
    
}