/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract IPFSLink{

    mapping(address => string) internal ipfsLink;

    function setLink(string memory link_) public {
        ipfsLink[msg.sender] = link_;
    }

    function getLink() public view returns (string memory){
        return ipfsLink[msg.sender];
    }

}