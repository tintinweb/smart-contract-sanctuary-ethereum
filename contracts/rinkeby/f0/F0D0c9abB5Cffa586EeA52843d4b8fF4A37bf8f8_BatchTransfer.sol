/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC1155Partial {
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external;
}
    // deploy by Lootex
contract BatchTransfer {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  tokenContract An ERC-721 contract
    /// @param  receiver     Who gets the tokens?
    /// @param  tokenIds      Which token IDs are transferred?
    function batchTransfer721(ERC721Partial tokenContract, address[] memory receiver, uint256[] calldata tokenIds) external {
        for(uint256 i= 0; i<receiver.length; i++){
            for (uint256 index; index < tokenIds.length; index++) {
                tokenContract.transferFrom(msg.sender, receiver[i], tokenIds[index]);
            }
        }
    }


    function batchTransfer1155(ERC1155Partial tokenContract, address[] memory receiver, uint256[][] memory tokenIds, uint256[][] memory amount) external {
        for(uint256 i= 0; i< receiver.length; i++){
            uint256[] memory tokenid_arr = tokenIds[i];
            uint256[] memory amount_arr = amount[i];
            tokenContract.safeBatchTransferFrom(msg.sender, receiver[i], tokenid_arr, amount_arr,"");
        }
    }


}