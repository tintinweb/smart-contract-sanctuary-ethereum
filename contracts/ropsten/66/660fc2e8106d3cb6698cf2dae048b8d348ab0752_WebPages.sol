/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract WebPages {
    constructor() {}

    function renderTokenFromContract(address contractAddress, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        IERC721 tokenContract = IERC721(contractAddress);

        return tokenContract.tokenURI(tokenId);
    }
}