/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract FL {

    // struct update {
    //     uint256 gradient;
    //     // index
    //     string key;
    //     uint128 i;
    //     uint128 j;
    //     uint128 shift;
    // }

    uint128 updatesCnt;

    string[1500] keyList; // key
    uint256[1500][4] updateList; // grad, i, j, shift

    uint256 n2;

    function setN2(uint256 ns) public {
        n2 = ns;
        updatesCnt = 0;
    }

    function download() public view returns(uint128 cnt, string[1500] memory key, uint256[1500][4] memory updates) {
        return (updatesCnt, keyList, updateList);
    }

    function upload(uint256[][4] calldata updates, string[] calldata keys) public {
        bool flag;
        for (uint i = 0; i < 25; i++) {
            flag = true;
            for (uint j = 0; j < updatesCnt; j++) {
                if (stringsEqual(keyList[j], keys[i]) && updateList[j][1] == updates[i][1] && updateList[j][2] == updates[i][2]) {
                    updateList[j][0] = mulMod(updateList[j][0], updates[i][0]);
                    updateList[j][3]++;
                    flag = false;
                    break;
                }
            }
            if (flag) {
                updateList[updatesCnt][0] = updates[i][0];
                updateList[updatesCnt][1] = updates[i][1];
                updateList[updatesCnt][2] = updates[i][2];
                updateList[updatesCnt][3] = updates[i][3];
                updatesCnt++;
            }
        }
    }

    function mulMod(uint256 a, uint256 b) public view returns(uint256 result) {
        result = a * b % n2;
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
}