/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract LooksRareMarketProxy {

    // LooksRare exchange address
    address private constant looks_rare_exchange = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    // 0x64 = 0x4(selector) + 0x20(offset(takerBid)) + 0x20(offset(makerAsk)) + 0x20(takerBid.isOrderAsk)
    uint256 private constant offset_takerBid_taker = 0x64;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    function matchAskWithTakerBidUsingETHAndWETH(TakerOrder calldata takerBid, MakerOrder calldata makerAsk) external payable {
        address recipient = takerBid.taker != address(0) ? takerBid.taker : msg.sender;
        uint256 tokenId = makerAsk.tokenId;
        uint256 payableAmount = makerAsk.price;
        address collection = makerAsk.collection;
        uint256 amount = makerAsk.amount;
        assembly {
            calldatacopy(0, 0, calldatasize())
            mstore(offset_takerBid_taker, address())

            if iszero(call(gas(), looks_rare_exchange, payableAmount, 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, recipient)
            mstore(0x44, tokenId)
            if gt(call(gas(), collection, 0, 0, 0x64, 0, 0), 0) {
                return(0, 0)
            }

            // selector for safeTransferFrom(address,address,uint256,uint256,bytes)
            mstore(0, 0xf242432a00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x64, amount)
            mstore(0x84, 0xa0)
            mstore(0xa4, 0)
            if gt(call(gas(), collection, 0, 0, 0xc4, 0, 0), 0) {
                return(0, 0)
            }

            // revert("LooksRareProxy: transfer nft to taker failed.")
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(0x40, 0x0000002d4c6f6f6b735261726550726f78793a207472616e73666572206e6674)
            mstore(0x60, 0x20746f2074616b6572206661696c65642e000000000000000000000000000000)
            mstore(0x80, 0)
            revert(0, 0x84)
        }
    }
}