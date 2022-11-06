/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;


contract Oracle {
    uint8 u1 = 0x88;
    function(uint) external public a;
    uint8 u2 = 0x99;


    function query(function(uint) external callback) internal {
        a = callback;
    }

    function reply() public {
        query(this.oracleResponse);
    }

    function oracleResponse(uint response) external {
    }

    function see() external view returns(uint a1, uint a2, uint a3, uint a4, uint a5, uint a6, uint256 u, uint256 v) {
        assembly {
            a1 := u1.slot
            a2 := u1.offset
            a3 := a.slot
            a4 := a.offset
            a5 := u2.slot
            a6 := u2.offset
            u := sload(0)
        }
        v = u1;
    }

}