/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract AuraProposalEncoder {
    function encodeProposalId(uint256 proposalIndex, uint256 choiseIndex) public pure returns(bytes32) {
      return keccak256(abi.encodePacked(proposalIndex, choiseIndex));
    }
}