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

    uint128 updatesCnt;

    update[1500] updateList;

    uint256 n2 = 123;

    function download() public view returns(uint128 cnt, update[1500] memory ups) {
        return (updatesCnt, updateList);
    }

    function upload(update[25] calldata updates) public {
        for (uint i = 0; i < 25; i++) {
            for (uint j = 0; j < updatesCnt; j++) {
                if (stringsEqual(updateList[j].key, updates[i].key) && updateList[j].i == updates[i].i && updateList[j].j == updates[i].j) {
                    updateList[j].gradient = mulMod(updateList[j].gradient, updates[i].gradient);
                    break;
                }
            }
            updateList[updatesCnt] = updates[i];
        }
    }

    function uploadTest(update calldata updates) public {
        updateList[0] = updates;
    }

    function mulMod(uint256 a, uint256 b) public view returns(uint128 result) {
        uint256 res = a * b;
        res = res % n2;
        result = uint128(res);
    }

    function stringsEqual(string memory s1, string memory s2) private pure returns (bool) {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint256 i=0; i<l1; i++) {
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }

    // function addGradient(uint key, uint i, uint j, uint128 gradient) public {
    //     weights[key][i][j] = mulMod(weights[key][i][j], gradient);
    // }

}