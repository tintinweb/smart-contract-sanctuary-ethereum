/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITubbies {
    function totalSupply() external view returns (uint);
    function startSaleTimestamp() external view returns (uint);
    function mintFromSale(uint tubbiesToMint) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract TubbiesBot is IERC721Receiver {
    address public owner;
    address public tubbies;

    constructor(address _tubbies) {
        owner = msg.sender;
        tubbies = _tubbies;
    }

    function mintFromSale(uint count) public payable {
        uint startSaleTimestamp = ITubbies(tubbies).startSaleTimestamp();
        require(block.timestamp > startSaleTimestamp);
        uint totalSupply = ITubbies(tubbies).totalSupply();
        require(totalSupply < 20000);
        uint left = 20000 - totalSupply;
        uint maxMint = left > count ? count : left;
        uint index = 5;
        for (; index <= maxMint; index += 5) {
            ITubbies(tubbies).mintFromSale { value: 0.5 ether } (5);
            
        }
        uint loose = maxMint + 5 - index;
        if (loose > 0) {
            ITubbies(tubbies).mintFromSale { value: 0.1 ether * loose } (loose);
        }
        if (maxMint < count) {
            payable(msg.sender).transfer(msg.value - maxMint * 0.1 ether);
        }
    }

    function withdrawTubbies(uint[] memory tokenIds) public {
        require(owner == msg.sender);
        for (uint i = 0; i < tokenIds.length; i++) {
            ITubbies(tubbies).safeTransferFrom(address(this), msg.sender, tokenIds[i], '');
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}