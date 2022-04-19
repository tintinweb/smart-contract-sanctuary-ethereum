/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
}

interface IERC1155 {
    function balanceOf(address address_, uint256 tokenId_) external view 
    returns (uint256);
}

contract ERC721OwnershipProxy {
    // Address Based Global Proxy

    address public tokenContract;
    constructor(address contract_) { tokenContract = contract_; }
    IERC721 public Token = IERC721(tokenContract);

    mapping(address => address) internal hwToSw;
    mapping(address => address) internal swToHw;

    function linkSwToHw(address sw_) external {
        // First, clear the past record
        address _previousLink = hwToSw[msg.sender];
        
        if (_previousLink != address(0)) {
            swToHw[_previousLink] = address(0);
        }

        // Next, set the new data;
        hwToSw[msg.sender] = sw_;
        swToHw[sw_] = msg.sender;
    }

    function ownerOf(uint256 tokenId_) external view returns (address) {
        return hwToSw[Token.ownerOf(tokenId_)] == address(0) ?
            Token.ownerOf(tokenId_) :
            hwToSw[Token.ownerOf(tokenId_)];
    }

    function balanceOf(address address_) external view returns (uint256) {
        // return swToHw[address_] == address(0) ?
        //     Token.balanceOf(address_) :
        //     Token.balanceOf(swToHw[address_]);
        return 1;
    }
}

contract ownershipProxyFactory {
    function createERC721OwnershipProxy(address address_) external {
        new ERC721OwnershipProxy(address_);
    }
}