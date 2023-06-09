/*
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣶⣤⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⠈⢻⣿⠿⠿⣬⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠟⠉⠙⠷⣄⠙⣷⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡄⠀⠀⠀⠀⠀⠀⢀⣾⠃⢀⣄⠀⠀⠈⠻⠟⠋⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣄⠀⠀⠀⠀⢠⣿⡇⠀⠀⠙⠻⢶⣤⣤⣤⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣷⣤⣀⣴⣿⣿⡄⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⠿⠿⠛⠉⠻⣿⣿⣷⣀⡀⠀⠀⠀⠀⠀⠉⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣇⣠⣤⣶⣄⠀⠘⢿⠃⠉⠛⠻⣶⣶⣤⣤⣄⡀⠀⠙⢿⣿⣿⣿⠟⢿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣦⡀⠀⠹⠟⠁⣠⣾⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⢀⣾⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
*/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface discreetInterface {
    function isReclaimable(uint256) external view returns (bool);
    function ownerOf(uint256) external view returns (address);
    function burn(uint256) external;
    function mint(address to, uint256 tokenId) external;
}

contract DiscreetNFTClaimer {
    discreetInterface constant public discreet = discreetInterface(
        0x5C2AFeD4c41B85C36FFB6cC2A235AfA66C5A780D
    );

    function claim(uint256 tokenId, address receipient) public {
        if (discreet.isReclaimable(tokenId)) {            
            discreet.burn(tokenId);
            discreet.mint(receipient, tokenId);
        } else {
            revert("not claimable");
        }
    }
}