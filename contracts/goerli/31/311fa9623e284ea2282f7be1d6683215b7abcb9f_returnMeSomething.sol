/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

pragma solidity 0.8.0;

contract returnMeSomething {

    function checkSomething(uint _a) public view returns (bool) {
        if (_a == 10) {
            return true;
        } else {
            return false;
        }
    }
}