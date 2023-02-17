/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity^0.8.17;

contract GenerateHash {

    function emberHash() public pure returns(bytes32){
        return keccak256("ember");
    }

     function zeroHash() public pure returns(bytes32){
        return 0x0;
    }

    function nodeHash() public pure returns(bytes32){
        return keccak256(abi.encodePacked(zeroHash(),emberHash()));
    }

    function generateHash(string calldata domainName) public pure returns(bytes32){
         return keccak256(
            abi.encodePacked(nodeHash(), keccak256(bytes(domainName)))
        );
    }
}