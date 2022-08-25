/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
// Coded by Devko.dev#7286
pragma solidity ^0.8.7;

interface IERC1155 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;
}

contract BatchAirdroperERC1155 {
    constructor() {}

    function transferBulkERC1155(
        address[] memory receivers,
        uint256[] memory ids,
        address contractAddress
    ) external {
        IERC1155 erc1155Contract = IERC1155(contractAddress);
        for (uint256 index = 0; index < receivers.length; index++) {
            erc1155Contract.safeTransferFrom(
                msg.sender,
                receivers[index],
                ids[index],
                1,
                ""
            );
        }
    }
}