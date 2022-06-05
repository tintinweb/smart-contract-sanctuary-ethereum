/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;
pragma abicoder v2;

contract Z {

    uint256 public n;
    uint256 public t;
    bytes32 public h0;
    bytes32 public h1;

    struct S {
        uint256 n;
        uint256 t;
        bytes32 h0;
        bytes32 h1;
    }

    S public ss;

    function saveB() public {
        n = block.number;
    }

    function saveBT() public {
        t = block.timestamp;
    }

    function saveBH_0() public {
        h0 = blockhash(block.number);
    }

    function saveBH_1() public {
        h1 = blockhash(block.number - 1);
    }

    function saveAll() public {
        ss = S({
            n: block.number,
            t: block.timestamp,
            h0: blockhash(block.number),
            h1: blockhash(block.number - 1)
        });
    }

}