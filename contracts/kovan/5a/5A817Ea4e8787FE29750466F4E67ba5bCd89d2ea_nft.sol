/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract nft {

    function publicSaleMint(uint256 _quantity, bytes32[] memory _discountMerkleProof) external payable returns (uint256, bytes32[] memory) {
        return (_quantity, _discountMerkleProof);
    }

}