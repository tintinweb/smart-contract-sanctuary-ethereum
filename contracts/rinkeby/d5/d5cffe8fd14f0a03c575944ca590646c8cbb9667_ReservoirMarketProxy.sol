/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract ReservoirMarketProxy {

    address public constant RESERVOIR_EXCHANGE = 0x9EbFB53Fa8526906738856848A27cB11b0285C3f;

    struct Pair721 {
        uint256 token;
        uint256 tokenId;
    }

    function call(uint256 ethAmount, Pair721[] calldata pairs, bytes calldata data) external payable {
        assembly {
            calldatacopy(0, data.offset, data.length)
            if iszero(call(gas(), RESERVOIR_EXCHANGE, ethAmount, 0, data.length, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, caller())

            let someSuccess

            // 0x4(selector) + 0x20(ethAmount) + 0x20(pairs.offset) + 0x20(data.offset) + 0x20(pairs.length) + ?(pairs.data) + 0x20(data.length) + ?(data.data)
            let pairsEndOffset := sub(data.offset, 0x20)
            for { let offset := pairs.offset } lt(offset, pairsEndOffset) { offset := add(offset, 0x40) } {
                mstore(0x44, calldataload(add(offset, 0x20))) // tokenID
                if call(gas(), calldataload(offset), 0, 0, 0x64, 0, 0) {
                    someSuccess := 1
                }
            }

            if iszero(someSuccess) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
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