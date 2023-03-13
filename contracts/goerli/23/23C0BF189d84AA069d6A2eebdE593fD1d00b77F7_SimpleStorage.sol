/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 < 0.9.0;

contract SimpleStorage {
    uint256 a;
    
    function setter(uint256 _a) public {
        a=_a;
    }
    function getter() public view returns(uint256) {
        return a;
    }
}