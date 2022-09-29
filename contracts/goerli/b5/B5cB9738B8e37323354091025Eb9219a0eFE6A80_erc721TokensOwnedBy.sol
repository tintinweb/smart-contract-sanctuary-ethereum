/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
// File: Owner.sol


pragma solidity ^0.8.7;

interface IERC721 {
    function balanceOf(address from) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint256);
}

contract erc721TokensOwnedBy {
    constructor() {}

    function tokensOwnedBy(address owner, address contractAddress)
        external
        view
        returns (uint256[] memory)
    {
        IERC721 erc721Contract = IERC721(contractAddress);
        uint256[] memory tokensList = new uint256[](
            erc721Contract.balanceOf(owner)
        );
        uint256 currentIndex;
        for (
            uint256 index = 1;
            index <= erc721Contract.totalSupply();
            index++
        ) {
            if (erc721Contract.ownerOf(index) == owner) {
                tokensList[currentIndex++] = uint256(index);
            }
        }
        return tokensList;
    }
}