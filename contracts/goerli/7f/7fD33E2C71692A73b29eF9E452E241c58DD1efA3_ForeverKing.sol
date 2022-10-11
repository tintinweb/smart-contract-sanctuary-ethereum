/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract ForeverKing {
    function claimOwnership(address payable _to) public payable {
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send value!");
    }
}