// SPDX-License-Identifier: GPL-3.0

// ------------    House Of First   -------------
// --- Metaverse Players - Transfer Contract  ---

import "./Ownable.sol";
import "./IERC721.sol";

pragma solidity ^0.8.10;

contract ERC721MultiTransfer is Ownable {
    address public tokenContractAddress = 0x4819dAB28d11de83c20c75C7Fa2A6EAC9dC948D4;

    function multiTransfer(uint256[] calldata tokenIds, address[] calldata recipients) external onlyOwner {
        require(tokenIds.length == recipients.length, "Invalid tokenIds and recipients (length mismatch)");
        for (uint256 i = 0; i < recipients.length; ++i) {
            IERC721(tokenContractAddress).safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }

    function setTokenContractAddress(address _address) onlyOwner external {
        tokenContractAddress = _address;
    }
}