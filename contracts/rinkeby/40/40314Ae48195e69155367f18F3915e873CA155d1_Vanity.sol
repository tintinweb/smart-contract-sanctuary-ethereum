// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Vanity {

    mapping(address => string) private vanityName;
    

    constructor() {
        vanityName[0x88951e18fEd6D792d619B4A472d5C0D2E5B9b5F0] = "talhayusuf";
    }

    function getVanityByAddress(address userAccount) public view returns (string memory){
        return vanityName[userAccount];
    }

}