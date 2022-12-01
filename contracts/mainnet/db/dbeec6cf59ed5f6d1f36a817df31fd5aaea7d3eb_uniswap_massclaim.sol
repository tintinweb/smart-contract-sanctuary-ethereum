/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

abstract contract MerkleDistributorWithDeadline {
    function isClaimed(uint256 index) public view virtual returns (bool);
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public virtual;
}

contract uniswap_massclaim {

    MerkleDistributorWithDeadline mdwd;

    constructor(address _mdwd) {
        mdwd = MerkleDistributorWithDeadline(_mdwd);
    }

    function massClaim(uint256[] calldata index, address[] calldata account, uint256[] calldata amount, bytes32[] calldata merkleProof) external {
        require(index.length == account.length && account.length == amount.length);
        uint256 mppi = merkleProof.length / index.length;
        require(merkleProof.length % mppi == 0);
        bytes32[] memory _merkleProof = new bytes32[](mppi);
        uint256 i;
        uint256 j;
        for(i = 0;i < index.length;i++) {
            if(!mdwd.isClaimed(index[i])) {
                for(j = 0;j < mppi;j++) {
                    _merkleProof[j] = merkleProof[i*mppi+j];
                }
                mdwd.claim(index[i], account[i], amount[i], _merkleProof);
            }
        }
    }
}