/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

pragma solidity 0.4.18;


contract TestAddress {

    function isSameAddress(address a, address b) returns(bool){  //Simply add the two arguments and return
        if (a == b) return true;
        return false;
    }

    function() public {  //If the function signature doesn't check out, return -1
        revert();
    }
}