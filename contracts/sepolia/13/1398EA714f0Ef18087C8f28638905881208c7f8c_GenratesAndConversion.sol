/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

contract GenratesAndConversion {
    function random(uint256 _count) public view returns (bytes32) {
        return (
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    // block.prevrandao,
                    msg.sender,
                    _count
                )
            )
        );
    }

    function toBytes(address a) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a));
    }

    function genrateUniqueIDByProductName(string memory _materialname)
        external
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(abi.encodePacked(_materialname));
        return hash;
    }
}