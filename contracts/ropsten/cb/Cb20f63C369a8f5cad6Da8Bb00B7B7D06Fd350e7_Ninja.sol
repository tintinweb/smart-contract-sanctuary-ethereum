// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ITarget {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint(uint8 numTokens) external payable;
}

contract Ninja {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function mint(
        address contractAddr,
        address transferTo,
        uint256 nextTokenId,
        uint256 mints,
        uint256 tokensPerMint
    ) external payable {
        uint256 tokenId = nextTokenId;
        for (uint256 i; i < mints; i++) {
            ITarget(contractAddr).mint(uint8(tokensPerMint));
            for (uint256 j; j < tokensPerMint; j++)
                ITarget(contractAddr).transferFrom(address(this), transferTo, tokenId++);
        }
    }
}