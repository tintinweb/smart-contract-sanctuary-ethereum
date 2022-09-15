/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract B {

    bool public bb = false;

    function test(address a, bool b, uint256 c) external {
        bb = b;
    }


}