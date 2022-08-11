// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract GemMarketProxy {

    address public constant GEM_EXCHANGE = 0x83C8F28c26bF6aaca652Df1DbBE0e1b56F8baBa2;
    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    function callGem(uint256 ethAmount, uint256 erc721, uint256 tokenId, bytes calldata data) external payable {
        assembly {
            // 0xa4 = 0x4(selector) + 0x20(ethAmount) + 0x20(erc721) + 0x20(tokenId) + 0x20(data.offset) + 0x20(data.length)
            calldatacopy(0, 0xa4, data.length)
            if iszero(call(gas(), GEM_EXCHANGE, ethAmount, 0, data.length, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, caller())
            mstore(0x44, tokenId)

            if iszero(call(gas(), and(erc721, ADDRESS_MASK), 0, 0, 0x64, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}