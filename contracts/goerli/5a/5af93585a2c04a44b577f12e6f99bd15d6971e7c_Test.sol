/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    function mintWl_6a2f45d7c6df(uint256 _amount, uint256 _tokenId, bytes32[] calldata _merkleProof) external payable {
        require(msg.value > 0, "not enough gas sent");
        require(_amount > 0, "amount must be positive");
        require(_tokenId == 1, "wrong tokenId");
    }
}