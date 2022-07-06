/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;




contract zz {

    function val_15() external pure returns(uint8) {
        return 15;
    }
}

contract Box is zz {
    uint256 public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint256 _val) external {
        val = _val;
    }
}