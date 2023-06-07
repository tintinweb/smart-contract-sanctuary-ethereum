// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;

contract Rand {
    function randMod(uint randNonce, uint _modulus) 
    public
    view
    returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, randNonce)
            )
        ) % _modulus;
    }

    function findWeighted(uint weight, uint[] memory weightSum)
    public
    pure
    returns (uint) {
        uint right = weightSum.length - 1;
        uint left = 0;
        
        while (left < right) {
            uint mid = (left + right) / 2;
            // zero weight meeas we exluded idx from draw
            if (weightSum[mid] == 0 || weightSum[mid] == weight) {
                return mid;
            }
            
            if (weightSum[mid] < weight) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        return left;
    }
}