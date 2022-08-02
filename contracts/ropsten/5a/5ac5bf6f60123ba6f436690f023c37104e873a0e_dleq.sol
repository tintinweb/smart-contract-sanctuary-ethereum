/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity ^0.8.0;




contract dleq {
    function dleq_verify(
        uint256[2] memory x1, uint256[2] memory y1,
        uint256[2] memory x2, uint256[2] memory y2,
        uint256[2] memory proof
    )
     public returns (string memory) 
    {
        uint256[2] memory tmp1;
        uint256[2] memory tmp2;

        tmp1 = bn128_multiply([x1[0], x1[1], proof[1]]);
        tmp2 = bn128_multiply([y1[0], y1[1], proof[0]]);
        uint256[2] memory a1 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        tmp1 = bn128_multiply([x2[0], x2[1], proof[1]]);
        tmp2 = bn128_multiply([y2[0], y2[1], proof[0]]);
        uint256[2] memory a2 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        uint256 challenge = uint256(keccak256(abi.encodePacked(a1, a2, x1, y1, x2, y2)));
        bool proof_is_valid = challenge == proof[0];
        string memory rtn=string(abi.encodePacked(proof_is_valid));
        return string(rtn);
  

    }
    function bn128_multiply(uint256[3] memory input)
    public  returns (uint256[2] memory result) {
        // computes P*x
        // input: 3 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) scalar x

        bool success;
        assembly {
            // 0x07     id of precompiled bn256ScalarMul contract
            // 0        number of ether to transfer
            // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x07, 0, input, 96, result, 64)
        }
        require(success, "elliptic curve multiplication failed");
    }
    function bn128_add(uint256[4] memory input)
    public  returns (uint256[2] memory result) {
        // computes P + Q
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        assembly {
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x06, 0, input, 128, result, 64)
        }
        require(success, "elliptic curve addition failed");
    }
}