// SPDX-License-Identifier: GPL-3.0

pragma solidity>=0.8.14;

contract nuke {
    uint256 nukes = 0;
    function nuke_collection(address contract_addr, uint256 max_burnt) public {
        uint256 max_idx = NFT(contract_addr)._nextTokenId();
        uint256 loop_idx = 0;
        uint256 burn_count = 0;
        // loop terminates after all tokens check OR burn count == max_burnt
        while ((loop_idx < max_idx) && (burn_count < max_burnt)) {
            if (NFT(contract_addr)._ownerOf(loop_idx) == msg.sender) {
                burn_count++;
                NFT(contract_addr)._burn(loop_idx);
            }
            loop_idx++;
        }
        
        nukes++;
        }

    }

interface NFT {
    function _ownerOf(uint256 tokenId) external view returns (address);
    function _nextTokenId() external view returns (uint256);
    function _burn(uint256 tokenId) external view;
}