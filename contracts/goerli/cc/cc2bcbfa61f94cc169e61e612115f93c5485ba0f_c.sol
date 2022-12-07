/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity 0.8.17;
contract c{
    
    string public name;
    uint public marks;
    string public result;
    constructor ( string memory Name,uint Marks){
        name=Name;
        marks=Marks;
        if (marks>=55)
        result ="pass";
        else {
            result = "fail";
        }
    }
}