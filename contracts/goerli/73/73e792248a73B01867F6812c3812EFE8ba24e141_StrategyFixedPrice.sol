// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

contract StrategyFixedPrice is IStrategy {
    // solhint-disable not-rely-on-time
    using OrderTypes for OrderTypes.MakerOrder;

    function canExecuteTakerAsk(
        OrderTypes.MakerOrder calldata makerBid,
        OrderTypes.TakerOrder calldata takerAsk
    )
        external
        view
        override
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        )
    {
        OrderTypes.OrderItem memory item = makerBid.items[takerAsk.itemIdx];
        return (
            (makerBid.startTime <= block.timestamp &&
                makerBid.endTime >= block.timestamp &&
                item.collection == takerAsk.item.collection &&
                item.tokenId == takerAsk.item.tokenId &&
                item.amount == takerAsk.item.amount &&
                item.price == takerAsk.item.price),
            item.tokenId,
            item.amount
        );
    }

    function canExecuteTakerBid(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    )
        external
        view
        override
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        )
    {
        OrderTypes.OrderItem memory item = makerAsk.items[takerBid.itemIdx];
        return (
            (makerAsk.startTime <= block.timestamp &&
                makerAsk.endTime >= block.timestamp &&
                item.collection == takerBid.item.collection &&
                item.tokenId == takerBid.item.tokenId &&
                item.amount == takerBid.item.amount &&
                item.price == takerBid.item.price),
            item.tokenId,
            item.amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderTypes {
    struct OrderItem {
        address collection;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
    }

    struct MakerOrder {
        bool isAsk;
        address signer;
        OrderItem[] items;
        address strategy;
        address currency;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes32 marketplace;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isAsk;
        address taker;
        uint256 itemIdx;
        OrderItem item;
        uint256 minPercentageToAsk;
        bytes32 marketplace;
        bytes params;
    }

    function hash(OrderItem memory orderItem) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "OrderItem(address collection,uint256 tokenId,uint256 amount,uint256 price)"
                    ),
                    orderItem.collection,
                    orderItem.tokenId,
                    orderItem.amount,
                    orderItem.price
                )
            );
    }

    function hash(MakerOrder memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory itemsHash = new bytes32[](makerOrder.items.length);
        for (uint256 i = 0; i < makerOrder.items.length; i++) {
            itemsHash[i] = hash(makerOrder.items[i]);
        }
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "MakerOrder(bool isAsk,address signer,OrderItem[] items,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes32 marketplace,bytes params)OrderItem(address collection,uint256 tokenId,uint256 amount,uint256 price)"
                    ),
                    makerOrder.isAsk,
                    makerOrder.signer,
                    keccak256(abi.encodePacked(itemsHash)),
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    makerOrder.marketplace,
                    keccak256(makerOrder.params)
                )
            );
    }

    function hashOrderItem(MakerOrder memory makerOrder, uint256 idx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    makerOrder.isAsk,
                    makerOrder.signer,
                    makerOrder.items[idx],
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    makerOrder.params
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IStrategy {
    function canExecuteTakerAsk(
        OrderTypes.MakerOrder calldata makerBid,
        OrderTypes.TakerOrder calldata takerAsk
    )
        external
        view
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        );

    function canExecuteTakerBid(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    )
        external
        view
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        );
}