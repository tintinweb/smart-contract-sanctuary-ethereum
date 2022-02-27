/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721 {
      function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}

contract ERC721BatchTransfer {
    function batchTransfer(address _contract, address[] calldata _tos, uint256[] calldata _tokenIds) external {
        require(_tos.length == _tokenIds.length, "array length mismatch");
        for(uint256 i = 0; i < _tokenIds.length; i ++) {
            IERC721(_contract).transferFrom(msg.sender, _tos[i], _tokenIds[i]);
        }
    }
}