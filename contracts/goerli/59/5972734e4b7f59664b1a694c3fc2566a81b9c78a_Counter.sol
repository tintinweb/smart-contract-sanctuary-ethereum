/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// File: question6.sol

pragma solidity ^0.6.0;
 
 contract Counter{
    uint number;
    
    function StroreNumber() public  {
            number=56;
    }
    function RetriveNumber() public view returns(uint){
        return number;
    } 
}