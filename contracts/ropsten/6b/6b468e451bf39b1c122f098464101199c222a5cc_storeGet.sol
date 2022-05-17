/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity 0.8.7;

contract storeGet {
    uint x;

    function storeInBlockchain(uint _x ) public returns(uint) {
        x = _x;
        return x;
        
    }

    function getStoredX() public view returns(uint) {
         return x; 
    }
}