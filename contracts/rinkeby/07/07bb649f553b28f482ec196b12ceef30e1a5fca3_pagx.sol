/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// File: contracts/pagx.sol


pragma solidity ^0.8.11;
// pragma experimental "v0.5.0";

contract pagx{
    uint public x;
    function updateX(uint _x) public returns(uint){
        x = _x+1;
        return x;
    
    }
     function viewX() public view returns(uint){
        
        return x;
    
    }


}