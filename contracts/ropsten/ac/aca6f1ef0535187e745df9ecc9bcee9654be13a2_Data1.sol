/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity ^0.8.13;

contract Data1 {
    int public x;

    function SetX(int i) public {
        x = i;
    }

    function GetX() public view returns(int) {
        return x;
    }
}