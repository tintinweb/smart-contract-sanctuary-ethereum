/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface discreetInterface {
    function isReclaimable(uint256) external view returns (bool);
    function ownerOf(uint256) external view returns (address);
    function burn(uint256) external;
    function mint(address to, uint256 tokenId) external;
}

contract discreetRestorer {
    discreetInterface constant public discreet = discreetInterface(
        0x5C2AFeD4c41B85C36FFB6cC2A235AfA66C5A780D
    );

    function restore(uint256 tokenId) public {
        if (discreet.isReclaimable(tokenId)) {
            address currentOwner = discreet.ownerOf(tokenId);
            discreet.burn(tokenId);
            discreet.mint(currentOwner, tokenId);
        } else {
            revert("not restorable");
        }
    }
}