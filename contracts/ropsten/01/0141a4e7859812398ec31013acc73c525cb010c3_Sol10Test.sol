/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

pragma solidity ^0.8.10;

contract Sol10Test {
    function testRequire() view public {
        require(1 > 3, "i < 3 !");
    }
    
    function revertTest() public view {
        if (1 < 3) {
                revert("1 < 3........");
        }
    }

    function testAssert() public view {
        assert(1 < 3);
    }
}