/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract FL {

    struct update {
        uint128[2] gradient;
        // index
        string key;
        uint128 i;
        uint128 j;
        uint128 shift;
    }

    uint128 updatesCnt;
    update[1500] updateList;
    uint128[2] n2;

    function setN2(uint128[2] calldata ns) public {
        n2 = ns;
        updatesCnt = 0;
    }

    function download() public view returns(uint128 cnt, update[1500] memory ups) {
        return (updatesCnt, updateList);
    }

    function upload(update[25] calldata updates) public {
        bool flag;
        // uint128[4] memory tmp;
        for (uint i = 0; i < 25; i++) {
            flag = true;
            for (uint j = 0; j < updatesCnt; j++) {
                if (stringsEqual(updateList[j].key, updates[i].key) && updateList[j].i == updates[i].i && updateList[j].j == updates[i].j) {
                    updateList[j].gradient = mulMod_BN(updateList[j].gradient, updates[i].gradient, n2);
                    updateList[j].shift++;
                    flag = false;
                    break;  
                }
            }
            if (flag) {
                updateList[updatesCnt] = updates[i];
                updatesCnt++;
            }
        }
    }

    function stringsEqual(string memory s1, string memory s2) private pure returns (bool) {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint i = 0; i < l1; i++)
            if (b1[i] != b2[i]) return false;
        return true;
    }


    // modmulBN

    // a(uint128) * b(uint128[2]) = result(uint128[3])
    function mul_1x2(uint128 a, uint128[2] memory b) public pure returns(uint128[3] memory result){
        uint128[2] memory res;
        uint128 carry;
        if (a == 0) return result;
        for (uint i = 0; i < 2; i += 1) { // for each block of b[]
            if (b[i] == 0)
                continue;
            res = mul_128(a, b[i]);
            (result[i], carry) = add_128(result[i], res[0]);
            for (uint k = 1; carry > 0; k += 1) { // handling the carry
                (result[i + k], carry) = add_128(result[i + k], carry);
            }
            (result[i + 1], carry) = add_128(result[i + 1], res[1]);
            for (uint k = 2; carry > 0; k += 1) {
                (result[i + k], carry) = add_128(result[i + k], carry);
            }
        }
    }

    // a(uint128[3]) - b(uint126[3]) = result(uint128[3])
    function minus_3_3(uint128[3] memory a, uint128[3] memory b) private pure returns(uint128[3] memory result) {
        result = a;
        for (uint i = 0; i < 3; i++)
            if (result[i] >= b[i])
                result[i] = result[i] - b[i];
            else if (i < 2) {
                uint cur = i + 1;
                for (uint j = cur; j < 3; j++)
                    if (result[j] == 0)
                        result[j] = 2 ** 128 - 1;
                    else{
                        cur = j;
                        break;
                    }
                if (result[cur] > 0)
                    result[cur] = result[cur] - 1;
                uint256 ans = uint256(result[i]) + uint256(2 ** 128) - uint256(b[i]);
                result[i] = uint128(ans);
            }
    }

    //return if a > b
    function is_greater_3_3(uint128[3] memory a, uint128[3] memory b) private pure returns(bool result) {
        result = true;
        for (uint i = 2; i >= 0; i--)
            if (a[i] == b[i])
                continue;
            else {
                if (a[i] < b[i]) 
                    result = false;
                break;
            }
    }

    // a(uint128[32]) mod b(uint128[16]) = result(uint128[16])
    function mod_BN(uint128[4] memory a, uint128[2] memory b) public pure returns(uint128[4] memory remainder){
        remainder = a;
        uint256 max;
        uint256 min;
        uint128[3] memory temp;
        uint128[3] memory from_a;
        uint128[3] memory bb;
        uint cur;
        // uint128 tmp;

        for (uint i = 0; i < 2; i++)
            bb[i] = b[i];
        for (uint j = 0; j < 3; j++) {
            cur = 2 - j;
            for (uint i = 0; i < (cur == 2 ? 2 : 3); i++) 
                from_a[i] = remainder[cur + i];
            min = (uint256(from_a[2]) * uint256(2 ** 128) + uint256(from_a[1])) / uint256(b[1] + 1);
            max = (uint256(from_a[2]) * uint256(2 ** 128) + uint256(from_a[1])) / uint256(b[1]) + uint256(2);
            temp = mul_1x2(uint128(min), b);
            from_a = minus_3_3(from_a, temp);
            for (uint256 i = min; i < max + 10; i++)
                if (is_greater_3_3(from_a, bb) == true)
                    from_a = minus_3_3(from_a, bb);
                else
                    break;
            if (cur == 2)
                for (uint i = 0; i < 2; i++)
                    remainder[cur + i] = from_a[i];
            else if (cur == 1) {
                remainder[1] = from_a[0];

                remainder[2] = from_a[1];
                
                remainder[3] = from_a[2];
            }
            else if (cur == 0)
                for (uint i = 0; i < 3; i++)
                    remainder[cur + i] = from_a[i];
            
            // for (uint i = 0; i < (cur == 2 ? 2 : 3); i++)
            //     remainder[cur + i] = from_a[i];
        }
    }

    // return a(uint128) * b(uint128) = result(uint128[2])
    function mul_128(uint128 a, uint128 b) private pure returns(uint128[2] memory result) {
        uint256 c = uint256(a) * uint256(b);
        result = [uint128(c), uint128(c >> 128)];
    }

    // return a(uint128) + b(uint128) = result(uint128) + carry(uint128)
    function add_128(uint128 a, uint128 b) private pure returns(uint128 result, uint128 carry) {
        uint256 c = uint256(a) + uint256(b);
        (result, carry) = (uint128(c), (c >= 2 ** 128 ? 1 : 0));
    }

    // return a(uint128[2]) * b(uint128[2]) = result(uint128[4])
    function mul_BN(uint128[2] memory a, uint128[2] memory b) public pure returns(uint128[4] memory result) {
        uint128[2] memory res;
        uint128 carry;
        for (uint i = 0; i < 2; i += 1) { // for each block of b[]
            if (b[i] == 0)
                continue;
            for (uint j = 0; j < 2; j += 1) { // for each block of a[]
                if (a[j] == 0)
                    continue;
                res = mul_128(a[j], b[i]);
                (result[i + j], carry) = add_128(result[i + j], res[0]);
                for (uint k = 1; carry > 0; k += 1) // handling the carry
                    (result[i + j + k], carry) = add_128(result[i + j + k], carry);
                (result[i + j + 1], carry) = add_128(result[i + j + 1], res[1]);
                for (uint k = 2; carry > 0; k += 1)
                    (result[i + j + k], carry) = add_128(result[i + j + k], carry);
            }
        }
    }

    // return a(string[2]) + b(string[2]) mod n2
    function mulMod_BN(uint128[2] memory a, uint128[2] memory b, uint128[2] memory n2s) public pure returns(uint128[2] memory result) {
        // mod_BN(mul_BN(a, b), n2s);
        uint128[4] memory tmp = mod_BN(mul_BN(a, b), n2s);
        (result[0], result[1]) = (tmp[0], tmp[1]);
    }
}