/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BatchAirdroper {
    constructor() {}

    function transferBatch(
        address[] calldata receivers,
        uint256[] calldata ids,
        address contractAddress
    ) external {
        IERC721 erc721Contract = IERC721(contractAddress);

        for (uint256 index = 0; index < receivers.length; index++) {
            erc721Contract.transferFrom(
                msg.sender,
                receivers[index],
                ids[index]
            );
        }
    }
}