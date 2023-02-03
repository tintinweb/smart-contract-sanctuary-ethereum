/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

interface ITransferCallbackContract {

    function beforeTransferCallback(address from, address to, uint256 tokenId) external;
    function afterTransferCallback(address from, address to, uint256 tokenId) external;

}

contract TransferLockCallback is ITransferCallbackContract {
    function beforeTransferCallback(address from, address to, uint256 tokenId) external {
        require(from == address(0x0));
    }

    function afterTransferCallback(address from, address to, uint256 tokenId) external {
    }
}