/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Main {
    SubA a;

    constructor(address _a) {
        a = SubA(_a);
    }

    function callSubA() public view returns (string memory){
        return a.check();
    }

    function setOwner(uint256 tokenId) public {
        a.setOwner(msg.sender,tokenId);
    }
}

contract SubA {
    mapping(uint256=>address) public owners;
    function check() public pure returns (string memory){
        return "SubA was called";
    }
    function setOwner(address owner, uint256 tokenId) public {
        require(owners[tokenId] == address(0));
        owners[tokenId] = owner;
    }

}