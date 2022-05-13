// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.1;

contract Traits {

    constructor() {

    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return "fix";  
    }   
    function selectTrait(uint16 seed, uint8 traitType) external view returns(uint8) {
        return 1;
    }
}