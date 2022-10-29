/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IERC721Upgradable {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // function setApprovalForAll(address operator, bool _approved) external;
}

contract AirdropHelper {

    // token: 0x616F08C77706cF97C2e3BD39BefF1c1eA61F58aE

    function airdrop(address token, address[] calldata airdropAddress, uint[] calldata tokenId) public {
        // IERC721Upgradable(token).setApprovalForAll(address(this), true);
        // approval to be set on frontend by user
        // address _owner = IOwner(token).owner();
        // require(msg.sender == _owner);
        for(uint i = 0; i< airdropAddress.length; i++) {
            IERC721Upgradable(token).safeTransferFrom(msg.sender, airdropAddress[i], tokenId[i]);
        }

    }
    
}