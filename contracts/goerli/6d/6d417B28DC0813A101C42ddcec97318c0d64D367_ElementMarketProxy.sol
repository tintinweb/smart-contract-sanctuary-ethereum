/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract ElementMarketProxy {

    address public constant ELEMENT_EXCHANGE = 0x7Fed7eD540c0731088190fed191FCF854ed65Efa;

    struct Pair721 {
        uint256 token;
        uint256 tokenId;
    }

    function callElement(uint256 ethAmount, Pair721[] calldata pairs, bytes calldata data) external payable {
        assembly {
            // 0x4(selector) + 0x20(ethAmount) + 0x20(pairs.offset) + 0x20(data.offset) + 0x20(pairs.length) + ?(pairs.data) + 0x20(data.length) + ?(data.data)
            calldatacopy(0, data.offset, data.length)
            if iszero(call(gas(), ELEMENT_EXCHANGE, ethAmount, 0, data.length, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, caller())

            let pairsEndOffset := sub(data.offset, 0x20)
            for { let offset := pairs.offset } lt(offset, pairsEndOffset) { offset := add(offset, 0x40) } {
                mstore(0x44, calldataload(add(offset, 0x20))) // tokenID
                if iszero(call(gas(), calldataload(offset), 0, 0, 0x64, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }
}