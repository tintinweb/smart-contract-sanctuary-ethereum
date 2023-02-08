/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract TestPaint {
    uint256 public count = 0;

    event PaintingUpdated(
    uint256 indexed tokenId,
    string indexed oldURI,
    string indexed newURI,
    address updated_by
);

    function testUpdatePaint(uint256 _tokenId, string calldata _oldURI, string calldata _newURI) public {
        count += 1;
        emit PaintingUpdated(_tokenId, _oldURI, _newURI, msg.sender);
    }
}