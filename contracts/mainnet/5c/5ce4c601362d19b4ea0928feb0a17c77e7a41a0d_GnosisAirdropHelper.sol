// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";

contract GnosisAirdropHelper {
    address constant GnosisSafe = 0xF6BD9Fc094F7aB74a846E5d82a822540EE6c6971;
    ERC721 constant Pixelmon = ERC721(0x32973908FaeE0Bf825A343000fE412ebE56F802A);

    constructor() {
        
    }

    function bulkTransfer(address receiver, uint[] calldata tokenIds) public {
        require(msg.sender == GnosisSafe);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Pixelmon.transferFrom(GnosisSafe, receiver, tokenIds[i]); 
        }
    }

    function specialAirdrop(address[] calldata recipients) public {
        require(msg.sender == GnosisSafe);
        require(recipients.length == 126);
        for (uint256 i = 0; i < recipients.length; i++) {
            Pixelmon.transferFrom(GnosisSafe, recipients[i], 204 + i); 
        }
    }
}