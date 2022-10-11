// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IERC721TokenURI {
    function tokenURI(uint256) external view returns (string memory);
}

contract TokenURIForwarder {
    function tokenURI(IERC721TokenURI token, uint256 tokenID)
        external
        view
        returns (string memory)
    {
        return token.tokenURI(tokenID);
    }

    function benchTokenURI(IERC721TokenURI token, uint256 tokenID)
        external
        view
        returns (uint256)
    {
        uint256 gasStart = gasleft();
        token.tokenURI(tokenID);
        return gasStart - gasleft();
    }

    function benchAndReturnTokenURI(IERC721TokenURI token, uint256 tokenID)
        external
        view
        returns (uint256, string memory)
    {
        uint256 gasStart = gasleft();
        string memory uri = token.tokenURI(tokenID);
        return (gasStart - gasleft(), uri);
    }
}