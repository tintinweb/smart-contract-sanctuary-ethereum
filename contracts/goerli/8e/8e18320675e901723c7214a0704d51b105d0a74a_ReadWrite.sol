/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

pragma solidity ^0.8.4;

contract ReadWrite
{
    string a;

    function writeData(string memory _a) public 
    {
        a=_a;
        
    }
      function readData() public view  returns(string memory)
    {
        return a;
    }
}