// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IStrategy {
    function viewProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import {IStrategy} from "./IStrategy.sol";
import {Orders} from "../libraries/Orders.sol";

interface ISynchronousStrategy is IStrategy {
    function canExecuteTakerAsk(Orders.TakerOrder calldata takerAsk, Orders.MakerOrder calldata makerBid)
        external
        view
        returns (
            /** canExecute ask */
            bool,
            /** tokenId which the taker will receive */
            uint256,
            /** amountOfTokens which the taker will receive */
            uint256,
            /** total amount to pay in sum for all received tokens */
            uint256
        );

    function canExecuteTakerBid(Orders.TakerOrder calldata takerBid, Orders.MakerOrder calldata makerAsk)
        external
        view
        returns (
            /** canExecute bid */
            bool,
            /** tokenId which the taker will receive */
            uint256,
            /** amountOfTokens which the taker will receive */
            uint256,
            /** total amount to pay in sum for all received tokens */
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

/**
 * Wording:
 *
 * MakerAsk (Sell Offer): OWNER whishes to SELL             <───────┐
 * MakerBid (Buy Offer): USER whishes to AQUIRE NFT          <───┐  │
 * TakerAsk (Accept Buy Offer): Counterpart of MakerBid      <───┘  │
 * TakerBid (Accept Sell Offer): Counterpart of MakerAsk    <───────┘
 */

library Orders {
    // keccak256("MakerOrder(bool isAsk,address signer,address collection,uint256 tokenId,uint256 amount,address currency,address strategy,bytes strategyParams,uint256 validFrom,uint256 validUntil,uint256 nonce,BrokerFee brokerFee,uint256 minPercentageToAsk)BrokerFee(uint256 fee,address receiver)")
    bytes32 internal constant MAKERORDER_TYPEHASH = 0xcac9e486395ffa4a33075176e6d3b42b568c59b6ee7e1743b5b2fd57db665ab4; // 0x8b6250d885c360e8aff79a8fc6a832b7f8b96a2b521b242df8ec79229bf32874;
    bytes32 internal constant BROKER_FEE_TYPEHASH = 0xc03efd31a241a3c6cdcc9afe195d45e9812d92c01d0cf464937aac1bb9bc590c;

    struct BrokerFee {
        uint256 fee; // 200 --> 2%
        address receiver; // wallet to receiver broker fee
    }

    struct MakerOrder {
        bool isAsk; // true --> MakerAsk; false --> MakerBid
        address signer; // acting wallet
        address collection; // nft collection address
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (always 1 for ERC721)
        address currency; // ERC20 token for payment; 0x for native token
        address strategy; // strategy to use (FixedPrice, EnglishAuction, DutchAuction)
        bytes strategyParams; // additional params for strategy
        uint256 validFrom; // unix timestamp in seconds
        uint256 validUntil; // unix timestamp in seconds
        uint256 nonce; // order nonce (must be unique unless new maker order is overriding existing one)
        // ATTENTION: Overriding an order by using the same nonce, does not invalidate the previous order.
        // Always cancel an order if you want to increase the desired sell price (MakerAsk) or want to reduce your offer (MakerBid)
        BrokerFee brokerFee; // struct of fee and receiving address of broker
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes signature; // Signature of MakerOrder.hash() by signer
    }

    struct TakerOrder {
        bool isAsk; // true --> TakerAsk; false --> TakerBid
        address taker; // acting wallet
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (always 1 for ERC721)
        bytes strategyParams; // additional params for strategy
        BrokerFee brokerFee; // struct of fee and receiving address of broker
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKERORDER_TYPEHASH,
                    makerOrder.isAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.currency,
                    makerOrder.strategy,
                    keccak256(makerOrder.strategyParams),
                    makerOrder.validFrom,
                    makerOrder.validUntil,
                    makerOrder.nonce,
                    hash(makerOrder.brokerFee),
                    makerOrder.minPercentageToAsk
                )
            );
    }

    function hash(BrokerFee memory brokerFee) internal pure returns (bytes32) {
        return keccak256(abi.encode(BROKER_FEE_TYPEHASH, brokerFee.fee, brokerFee.receiver));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

import {Orders} from "../../libraries/Orders.sol";
import {ISynchronousStrategy} from "../../interfaces/ISynchronousStrategy.sol";

contract StrategyAnyItemFromCollectionForFixedPrice is ISynchronousStrategy {
    uint256 public immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerAsk(Orders.TakerOrder calldata takerAsk, Orders.MakerOrder calldata makerBid)
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 bidPrice = abi.decode(makerBid.strategyParams, (uint256));
        uint256 askPrice = abi.decode(takerAsk.strategyParams, (uint256));
        return (
            (bidPrice == askPrice && makerBid.validFrom <= block.timestamp && makerBid.validUntil >= block.timestamp),
            takerAsk.tokenId,
            takerAsk.amount,
            askPrice * takerAsk.amount
        );
    }

    function canExecuteTakerBid(Orders.TakerOrder calldata, Orders.MakerOrder calldata)
        external
        pure
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        return (false, 0, 0, 0);
    }

    function viewProtocolFee() external view override returns (uint256) {
        return PROTOCOL_FEE;
    }
}