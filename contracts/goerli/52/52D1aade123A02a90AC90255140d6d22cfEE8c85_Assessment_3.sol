// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface Isolution5 {
    function solution(bytes32 b, bytes32 ex, bytes32 modulus) external returns (bytes32 result);
}


contract Assessment_3 {

    function rand(uint256 n) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % n;
    }
    

    function callBigModExp(bytes32 base, bytes32 exponent, bytes32 modulus) internal returns (bytes32 result) {
        assembly {
            // free memory pointer
            let memPtr := mload(0x40)

            // length of base, exponent, modulus
            mstore(memPtr, 0x20)
            mstore(add(memPtr, 0x20), 0x20)
            mstore(add(memPtr, 0x40), 0x20)

            // assign base, exponent, modulus
            mstore(add(memPtr, 0x60), base)
            mstore(add(memPtr, 0x80), exponent)
            mstore(add(memPtr, 0xa0), modulus)

            // call the precompiled contract BigModExp (0x05)
            let success := call(gas(), 0x05, 0x0, memPtr, 0xc0, memPtr, 0x20)
            switch success
            case 0 {
                revert(0x0, 0x0)
            } default {
                result := mload(memPtr)
            }
        }
    }

    

    function completeLevel(address studentAddress) public returns(uint8, uint256) {
        (bytes32 base, bytes32 mod, bytes32 ex) = (bytes32(rand(100)), bytes32(rand(10000)), bytes32(rand(10000)));
        bytes32 answer = callBigModExp(base, mod, ex);
        bytes32 solution = Isolution5(studentAddress).solution(base, mod, ex);
        uint256 preGas = gasleft();
        Isolution5(studentAddress).solution(bytes32(uint256(1000)), bytes32(uint256(500)), bytes32(uint256(4)));
        uint256 gas = preGas - gasleft();
        
        if (solution[0] == answer[0] && solution[1] == solution[1]) {
            return (8, gas);
        } else {
            return (1, gas);
        }
    }



}