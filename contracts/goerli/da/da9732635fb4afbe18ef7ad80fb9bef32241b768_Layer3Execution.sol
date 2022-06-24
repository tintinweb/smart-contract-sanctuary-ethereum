//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./libraries/OrderTypes.sol";

contract Layer3Execution {
    // 200 -> 2%
    uint256 public immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external view returns (bool, uint256) {
        return (
            ((makerAsk.price == takerBid.price) &&
                (makerAsk.tokenId == takerBid.tokenId) &&
                (makerAsk.startTime <= block.timestamp) &&
                (makerAsk.endTime >= block.timestamp)),
            makerAsk.tokenId
        );
    }

    function viewProtocolFee() external view returns (uint256) {
        return PROTOCOL_FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library OrderTypes {
    /// keccak256("MakerOrder(address signer,uint16 layerZeroChainId,bool isCrosschain,address collection,uint256 tokenId,uint256 price,address strategy,uint256 nonce,uint256 startTime,uint256 endTime)")
    bytes32 internal constant MAKER_ORDER_TYPEHASH =
        0xe09dce396fff6febc9afdcf0b5b353a1f16927e05b9887ec8d4d11bd552372e4;

    struct MakerOrder {
        address signer;
        uint16 layerZeroChainId;
        bool isCrosschain;
        address collection;
        uint256 tokenId;
        uint256 price;
        address strategy;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        address taker;
        uint256 price;
        uint256 tokenId;
    }

    function hash(MakerOrder memory order) internal pure returns (bytes32) {
        return (
            keccak256(
                abi.encode(
                    MAKER_ORDER_TYPEHASH,
                    order.signer,
                    order.layerZeroChainId,
                    order.isCrosschain,
                    order.collection,
                    order.tokenId,
                    order.price,
                    order.strategy,
                    order.nonce,
                    order.startTime,
                    order.endTime
                )
            )
        );
    }
}