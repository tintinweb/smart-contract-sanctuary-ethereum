/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Query {
    
    function encodeKey (address tokenX, address tokenY, uint256 poolIdx)
        internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenX, tokenY, poolIdx));
        }

    function query (address owner, address base, address quote,
                                   uint256 poolIdx)
        public pure returns (bytes32 poolHash, bytes32 posKey, bytes32 slot) {
        poolHash = encodeKey(base, quote, poolIdx);
        posKey = keccak256(abi.encodePacked(owner, poolHash));
        slot = keccak256(abi.encodePacked(posKey, uint(65550)));
    }
    
    function query (address base, address quote,
                                   uint256 poolIdx) public pure returns (bytes32 key, bytes32 slot, uint256 newSlot) {
        key = encodeKey(base, quote, poolIdx);
        slot = keccak256(abi.encode(key, uint(65551)));
        newSlot = uint256(slot) + 1;
    }
}