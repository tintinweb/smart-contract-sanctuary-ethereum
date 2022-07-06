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
        uint128 shift;
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

    function upload(update[100] calldata updates) public {
        for (uint i = 0; i < 100; i++) {
            updateList[updatesCnt] = updates[i];
            updatesCnt++;
        }
    }

    // function upload(update[25] calldata updates) public {
    //     // bool flag;
    //     for (uint i = 0; i < 25; i++) {
    //         // flag = true;
    //         // for (uint j = 0; j < updatesCnt; j++) {
    //         //     if (stringsEqual(updateList[j].key, updates[i].key) && updateList[j].i == updates[i].i && updateList[j].j == updates[i].j) {
    //         //         // updateList[j].gradient = mulMod(updateList[j].gradient, updates[i].gradient);
    //         //         updateList[j].shift++;
    //         //         flag = false;
    //         //         break;
    //         //     }
    //         // }
    //         // if (flag) {
    //         //     updateList[updatesCnt] = updates[i];
    //         //     updatesCnt++;
    //         // }
    //         updateList[updatesCnt] = updates[i];
    //         updatesCnt++;
    //     }
    // }

    // function mulMod(uint256 a, uint256 b) public view returns(uint256 result) {
    //     result = a * b % n2;
    // }

    // function stringsEqual(string memory s1, string memory s2) private pure returns (bool) {
    //     bytes memory b1 = bytes(s1);
    //     bytes memory b2 = bytes(s2);
    //     uint256 l1 = b1.length;
    //     if (l1 != b2.length) return false;
    //     for (uint256 i=0; i<l1; i++)
    //         if (b1[i] != b2[i]) return false;
    //     return true;
    // }
}