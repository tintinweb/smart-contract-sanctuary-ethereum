/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract FL {

    struct update {
        uint256 gradient;
        // index
        string key;
        uint128 i;
        uint128 j;
    }

    uint128 updatesCnt;
    update[1500] updateList;
    uint256 n2;

    function setN2(uint256 ns) public {
        n2 = ns;
        updatesCnt = 0;
    }

    function download() public view returns(uint128 cnt, update[1500] memory ups) {
        return (updatesCnt, updateList);
    }

    function upload(update[25] calldata updates) public {
        for (uint i = 0; i < 25; i++) {
            updateList[updatesCnt] = updates[i];
            updatesCnt++;
        }
    }
}