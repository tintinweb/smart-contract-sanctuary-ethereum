/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract NftBuyer {
    address private creator;

    constructor() {
        creator = msg.sender;
    }

    function sellErc20(address tokenAddr, uint tokens) external returns (bool sent) {
        require(tokens > 0, "Must sell at least 1 token.");
        IERC20(tokenAddr).transferFrom(msg.sender, address(this), tokens);
        (sent, ) = address(msg.sender).call{value: 1}("");
    }

    function sellErc721(address tokenAddr, uint[] memory tokenIds) external returns (bool sent) {
        require(tokenIds.length > 0, "Must sell one or more NFTs.");
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(tokenAddr).transferFrom(msg.sender, address(this), tokenIds[i]);
        }
        (sent, ) = address(msg.sender).call{value: 1}("");
    }

    function sellErc1155(address tokenAddr, uint tokenId, uint amount) external returns (bool sent) {
        require(amount > 0, "Must sell one or more NFTs.");
        IERC1155(tokenAddr).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        (sent, ) = address(msg.sender).call{value: 1}("");
    }

    function withdrawErc20(address addr, uint tokens) external {
        IERC20(addr).transfer(creator, tokens);
    }

    function withdrawErc721(address tokenAddr, uint[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(tokenAddr).transferFrom(address(this), creator, tokenIds[i]);
        }
    }

    function withdrawErc1155(address tokenAddr, uint tokenId, uint amount) external {
        IERC1155(tokenAddr).safeTransferFrom(address(this), creator, tokenId, amount, "");
    }

    receive() external payable {}
}