/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC1155 {
    function balanceOf(address owner_, uint256 tokenId_) external view returns (uint256);
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

contract ERC1155VerificationHelper is Ownable {
    // Interface GAS Special
    IERC1155 public GASSpecial = IERC1155(0xB36698c7f5147AAc7F68B58eBbe905381b523C6f);
    function setGASSpecial(address address_) external onlyOwner {
        GASSpecial = IERC1155(address_);
    }

    // Params
    uint256 public iterateTo = 14; // 14 Tokens at Start of Contract
    function setIterateTo(uint256 iterateTo_) external onlyOwner {
        iterateTo = iterateTo_;
    }

    // Now, we have a special helper
    // We return the total ERC1155 holdings balance in a ERC721 way.
    function balanceOf(address owner_) external view returns (uint256) {
        uint256 _balance;

        for (uint256 i; i <= iterateTo;) {
            _balance += GASSpecial.balanceOf(owner_, i);
            unchecked { ++i; }
        }

        return _balance;
    }
}