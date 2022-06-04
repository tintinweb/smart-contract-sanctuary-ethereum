// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import {OrderTypes} from "../libraries/OrderTypes.sol";
import {IExecutionStrategy} from "../interfaces/IExecutionStrategy.sol";

/**
 * @title StrategyStandardSaleForFixedPrice
 * @notice Strategy that executes an order at a fixed price that
 * can be taken either by a bid or an ask.
 */
contract StrategyStandardSaleForFixedPrice is IExecutionStrategy {
    uint256 public immutable PROTOCOL_FEE;

    /**
     * @notice Constructor
     * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
     */
    constructor(uint256 _protocolFee) {
        PROTOCOL_FEE = _protocolFee;
    }

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
        OrderTypes.MakerRentConfig calldata rentConfig = makerBid.rentConfig;
        return (
            ((rentConfig.pricePerHour == takerAsk.pricePerHour) &&
                (rentConfig.target.tokenId == takerAsk.target.tokenId) &&
                (rentConfig.minHours <= takerAsk.numHours) &&
                (takerAsk.numHours <= rentConfig.maxHours) &&
                (makerBid.startTime <= block.timestamp) &&
                (makerBid.endTime >= block.timestamp)),
            rentConfig.target.tokenId,
            rentConfig.target.amount
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
        OrderTypes.MakerRentConfig calldata rentConfig = makerAsk.rentConfig;
        return (
            ((rentConfig.pricePerHour == takerBid.pricePerHour) &&
                (rentConfig.target.tokenId == takerBid.target.tokenId) &&
                (rentConfig.minHours <= takerBid.numHours) &&
                (takerBid.numHours <= rentConfig.maxHours) &&
                (makerAsk.startTime <= block.timestamp) &&
                (makerAsk.endTime >= block.timestamp)),
            rentConfig.target.tokenId,
            rentConfig.target.amount
        );
    }

    /**
     * @notice Return protocol fee for this strategy
     * @return protocol fee
     */
    function viewProtocolFee() external view override returns (uint256) {
        return PROTOCOL_FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title OrderTypes
 * @notice This library contains order types for the LooksRare exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(MakerRentConfig rentConfig,bool isOrderAsk,address signer,address strategy,uint256 nonce,uint256 startTime,uint256 endTime,bytes strategyParams)MakerRentConfig(Target target,uint256 pricePerHour,uint256 minHours,uint256 maxHours,address currency)Target(address collection,uint256 tokenId,uint256 amount)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x4e302b2c8f7adcd1a1e07ea74e25102fc5735f17be8af269c1d80c73b5c1ea5d;

    // keccak256("MakerRentConfig(Target target,uint256 pricePerHour,uint256 minHours,uint256 maxHours,address currency)Target(address collection,uint256 tokenId,uint256 amount)")
    bytes32 internal constant CONFIG_HASH = 0xe04ed042b6b24b1453a36b66fcc5e2f0c7930f82b7c434fd2422250dc40c9619;

    // keccak256("Target(address collection,uint256 tokenId,uint256 amount)")
    bytes32 internal constant TARGET_HASH = 0x15f44eb90efeface27bb28da8b32aa919f34dff1f16c20569a52be8db39effe7;

    struct Target {
        address collection;
        uint256 tokenId;
        uint256 amount;
    }

    struct MakerRentConfig {
        Target target;
        uint256 pricePerHour;
        uint256 minHours;
        uint256 maxHours;
        address currency;
    }

    struct MakerOrder {
        MakerRentConfig rentConfig;
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        bytes strategyParams; // extra data used for strategy
        bytes signature;
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 pricePerHour; // final price for the purchase
        uint256 numHours; // number of hours to rent
        Target target;
    }

    function hashTarget(Target memory target) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                TARGET_HASH,
                target.collection,
                target.tokenId,
                target.amount
            )
        );
    }

    function hashRentConfig(MakerRentConfig memory rentConfig) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                CONFIG_HASH,
                hashTarget(rentConfig.target),
                rentConfig.pricePerHour,
                rentConfig.minHours,
                rentConfig.maxHours,
                rentConfig.currency
            )
        );
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(
                MAKER_ORDER_HASH,
                hashRentConfig(makerOrder.rentConfig),
                makerOrder.isOrderAsk,
                makerOrder.signer,
                makerOrder.strategy,
                makerOrder.nonce,
                makerOrder.startTime,
                makerOrder.endTime,
                keccak256(makerOrder.strategyParams)
            ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OrderTypes} from "../libraries/OrderTypes.sol";

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

    function viewProtocolFee() external view returns (uint256);
}