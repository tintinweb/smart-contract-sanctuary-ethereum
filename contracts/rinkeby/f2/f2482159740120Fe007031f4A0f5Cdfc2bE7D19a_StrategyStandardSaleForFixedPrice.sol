// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "./OrderTypes.sol";
import {IExecutionStrategy} from "./IExecutionStrategy.sol";

/**
 * @title StrategyStandardSaleForFixedPrice
 * @notice Strategy that executes an order at a fixed price that
 * can be taken either by a bid or an ask.
 */
contract StrategyStandardSaleForFixedPrice is IExecutionStrategy {

    constructor() { }

    /**
     * @notice Check whether a taker ask order can be executed against a maker bid
     * @param takerAsk taker ask order
     * @param makerBid maker bid order
     * @return (whether strategy can be executed, tokenId to execute, amount of tokens to execute)
     */
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        bool strategyMatching = false;

        for (uint256 i = 0; i < makerBid.allowedStrategies.length; i++) {
            strategyMatching = strategyMatching || (makerBid.allowedStrategies[i] == takerAsk.strategy);
        }

        return (
            ((makerBid.price == takerAsk.price) &&
                (makerBid.tokenId == takerAsk.tokenId) &&
                (makerBid.startTime <= block.timestamp) &&
                (makerBid.endTime >= block.timestamp) &&
                strategyMatching &&
                takerAsk.endTime >= block.timestamp),
            makerBid.tokenId,
            makerBid.amount
        );
    }

    /**
     * @notice Check whether a taker bid order can be executed against a maker ask
     * @param takerBid taker bid order
     * @param makerAsk maker ask order
     * @return (whether strategy can be executed, tokenId to execute, amount of tokens to execute)
     */
    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        bool strategyMatching = false;

        for (uint256 i = 0; i < makerAsk.allowedStrategies.length; i++) {
            strategyMatching = strategyMatching || (makerAsk.allowedStrategies[i] == takerBid.strategy);
        }

        return (
            ((makerAsk.price == takerBid.price) &&
                (makerAsk.tokenId == takerBid.tokenId) &&
                (makerAsk.startTime <= block.timestamp) &&
                (makerAsk.endTime >= block.timestamp &&
                strategyMatching &&
                takerBid.endTime >= block.timestamp)),
            makerAsk.tokenId,
            makerAsk.amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the marketplace
 */
library OrderTypes {
    bytes32 internal constant MAKER_ORDER_HASH = keccak256("MakerOrder(bool isOrderAsk,address maker,address collection,uint256 price,uint256 tokenId,uint256 amount,address[] allowedStrategies,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk)");
    bytes32 internal constant TAKER_ORDER_HASH = keccak256("TakerOrder(bool isOrderAsk,address taker,uint256 price,uint256 tokenId,address strategy,uint256 endTime,uint256 minPercentageToAsk,uint256 membership)");

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address maker; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address[] allowedStrategies; // allowed strategies for the item
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        address strategy; // stratefy of the taker
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        uint256 membership; // membership defining the fee for the taker.
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.maker,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.allowedStrategies,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk
                )
            );
    }

    function hashTaker(TakerOrder memory takerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TAKER_ORDER_HASH,
                    takerOrder.isOrderAsk,
                    takerOrder.taker,
                    takerOrder.price,
                    takerOrder.tokenId,
                    takerOrder.strategy,
                    takerOrder.endTime,
                    takerOrder.minPercentageToAsk,
                    takerOrder.membership
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "./OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}