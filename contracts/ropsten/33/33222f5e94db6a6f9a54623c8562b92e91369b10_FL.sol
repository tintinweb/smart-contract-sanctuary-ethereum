/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract FL {

    struct update {
        uint128 gradient;
        // index
        string key;
        uint128 i;
        uint128 j;
    }

    update[250] updateList;

    function download() public view returns(update[250] memory ups) {
        return updateList;
    }

    function upload(uint128 num_client, update[25] calldata updates) public {
        for (uint i = 0; i < 25; i++)
            updateList[i + num_client * 25] = updates[i];
    }

    function uploadTest(update calldata updates) public {
        updateList[0] = updates;
    }
}