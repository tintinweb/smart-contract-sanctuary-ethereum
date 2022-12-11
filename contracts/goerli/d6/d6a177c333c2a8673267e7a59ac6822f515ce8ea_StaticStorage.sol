/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13.0;

contract StaticStorage {
    event Result(uint256 res);
    mapping(uint256=>uint256) private counterStorage;

    function count() public view returns(uint256 ctr) {
        uint256 g;
        for(uint256 i;;i++) {
            g = gasleft();
            require(counterStorage[i]==0);
            if (g-gasleft() > 2000)
                return i;
        }
    }

    function countAndRevert(bool rev) external view {
        for (uint i = 0; i < 10; i++)
            count();
        require(!rev);
    }

    function testCounter(bool rev) public {
        try this.countAndRevert(rev) {} catch {}
        for (uint i = 0; i < 10; i++)
            emit Result(count());
    }
}