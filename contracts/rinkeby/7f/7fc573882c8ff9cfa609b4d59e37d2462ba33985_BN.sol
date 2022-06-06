/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BN {

    uint128[32] remainder;

    // multiplication on uint128
    // a(uint128) * b(uint128) = result[2](uint128) where result[0] indicates the right-most bit
    function mul_128(uint128 a, uint128 b) private pure returns(uint128[2] memory result) {
        uint256 c = uint256(a) * uint256(b);
        result = [uint128(c), uint128(c >> 128)];
    }

    // addition on uint128 
    // a(uint128) + b(uint128) = result(uint128) + carry(uint128)
    function add_128(uint128 a, uint128 b) private pure returns(uint128 result, uint128 carry) {
        uint256 c = uint256(a) + uint256(b);
        result = uint128(c);
        carry = (c >= 2 ** 128) ? 1 : 0;
    }

    function returnResults() public view returns(uint128[32] memory res) {
        return remainder;
    }

    // multiplication on BN
    // a(uint128[16]) * b(uint128[16]) = result(uint128[32])
    function mul_BN(uint128[16] calldata a, uint128[16] calldata b) private pure returns(uint128[32] memory results){
        for (uint i = 0; i < 32; i += 1)
            results[i] = 0;
        uint128[2] memory res;
        uint128 carry = 0;
        for (uint i = 0; i < 16; i += 1) { // for each block of b[]
            if (b[i] == 0)
                continue;
            for (uint j = 0; j < 16; j += 1) { // for each block of a[]
                if (a[j] == 0)
                    continue;
                res = mul_128(a[j], b[i]);
                (results[i + j], carry) = add_128(results[i + j], res[0]);
                for (uint k = 1; carry > 0; k += 1) { // handling the carry
                    (results[i + j + k], carry) = add_128(results[i + j + k], carry);
                }

                (results[i + j + 1], carry) = add_128(results[i + j + 1], res[1]);
                for (uint k = 2; carry > 0; k += 1) {
                    (results[i + j + k], carry) = add_128(results[i + j + k], carry);
                }
            }
        }
    }

    function mul_1x16(uint128 a, uint128[16] memory b) private pure returns(uint128[17] memory result){
        for (uint i = 0; i < 17; i += 1)
            result[i] = 0;
        uint128[2] memory res;
        uint128 carry = 0;

        if (a == 0) return result;
        for (uint i = 0; i < 16; i += 1) { // for each block of b[]
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

    // modulo on BN
    // a(uint128[32]) mod b(uint128[16]) = result(uint128[16])
    function mod_BN(uint128[32] memory a, uint128[16] memory b) private {
        uint128[32] memory temp_a;
        for (uint i=0; i<32; i+=1) { temp_a[i] = a[i]; }
        for (uint i=0; i<17; i+=1) { remainder[i] = uint128(0); }
        
        for (uint j=0; j<17; j++) {
            uint cur = 16 - j;
            
            uint128[17] memory from_a;
            from_a[16] = 0;
            if (cur == 16) 
                for (uint i=0; i<16; i++) { from_a[i] = temp_a[cur + i]; }
            else{
                for (uint i=0; i<17; i++) { from_a[i] = temp_a[cur + i]; }
            }

            uint256 min = (uint256(from_a[16]) * uint256(2 ** 128) + uint256(from_a[15])) / uint256(b[15] + 1);
            uint256 max = (uint256(from_a[16]) * uint256(2 ** 128) + uint256(from_a[15])) / uint256(b[15]) + uint256(2);

            uint128[17] memory temp = mul_1x16(uint128(min), b);
            uint128[17] memory old_from_a = from_a;
            from_a = minus_17_17(from_a, temp);
            
            for(uint256 i=min; i<max+10; i++){
                if(is_greater_17_16(from_a, b) == true){
                    old_from_a = from_a;
                    from_a = minus_17_16(from_a, b);
                }
                else{
                    break;
                }
            }
            if (cur == 16) 
                for (uint i=0; i<16; i++) { temp_a[cur + i] = from_a[i]; }
            else
                for (uint i=0; i<17; i++) { temp_a[cur + i] = from_a[i]; }
        }
        remainder = temp_a;

    }
    function minus_17_16(uint128[17] memory a, uint128[16] memory b) private pure returns(uint128[17] memory result) {
        uint128[17] memory res;
        for (uint i=0; i<17; i++) { res[i] = a[i]; }
        for (uint i=0; i<16; i++) {
            if (res[i] > b[i]){
                res[i] = res[i] - b[i];
            }
            else{
                uint cur;
                cur = i+1;
                for(uint j=cur; j<17; j++){
                    if(res[j] == 0){
                        res[j] = 2 ** 128 - 1;
                    }
                    else{
                        cur = j;
                        break;
                    }
                }
                if(res[cur] > 0){
                    res[cur] = res[cur] - 1;
                }
                
                uint256 ans = uint256(res[i]) + 2 ** 128 - b[i];
                res[i] = uint128(ans);
            }
        }
        result = res;
    }

    function minus_17_17(uint128[17] memory a, uint128[17] memory b) private pure returns(uint128[17] memory result) {
        uint128[17] memory res;
        for (uint i=0; i<17; i++) { res[i] = a[i]; }
        for (uint i=0; i<17; i++) {
            if (res[i] >= b[i]){
                res[i] = res[i] - b[i];
            }
            else{
                if(i < 16){
                    uint cur;
                    cur = i+1;
                    for(uint j=cur; j<17; j++){
                        if(res[j] == 0){
                            res[j] = 2 ** 128 - 1;
                        }
                        else{
                            cur = j;
                            break;
                        }
                    }
                    if(res[cur] > 0){
                        res[cur] = res[cur] - 1;
                    }
                    
                    uint256 ans = uint256(res[i]) + uint256(2 ** 128) - uint256(b[i]);
                    res[i] = uint128(ans);
                }
            }
                
        }
        result = res;
    }
    // if a >= b, return true
    // else return false
    function is_greater_17_16(uint128[17] memory a, uint128[16] memory b) private pure returns(bool result) {
        result = true;
        if (a[16] == 0){
            for(uint i=0; i<16; i++) {
                uint cur = 15 - i;
                if(a[cur] == b[cur]) continue;
                else{
                    if(a[cur] < b[cur]) result = false;
                    break;
                }
            }
        }
    }
    function is_greater_17_17(uint128[17] memory a, uint128[17] memory b) private pure returns(bool result) {
        result = true;
        
        for(uint i=0; i<17; i++) {
            uint cur = 16 - i;
            if(a[cur] == b[cur]) continue;
            else{
                if(a[cur] < b[cur]) result = false;
                break;
            }
        }
    }

    function addmod_BN(uint128[16] calldata a, uint128[16] calldata b, uint128[16] calldata n_square) public {
        uint128[32] memory c = mul_BN(a, b);
        mod_BN(c, n_square);
    }
}