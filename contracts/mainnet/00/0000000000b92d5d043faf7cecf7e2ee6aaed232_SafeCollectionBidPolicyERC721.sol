// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Order, AssetType} from "../lib/OrderStructs.sol";
import {IMatchingPolicy} from "../interfaces/IMatchingPolicy.sol";

/**
 * @title SafeCollectionBidPolicyERC721
 * @dev Policy for matching orders where buyer will purchase any NON-SUSPICIOUS token from a collection
 */
contract SafeCollectionBidPolicyERC721 is IMatchingPolicy {
    function canMatchMakerAsk(Order calldata makerAsk, Order calldata takerBid)
        external
        pure
        override
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        )
    {
        revert("Cannot be matched");
    }

    function canMatchMakerBid(Order calldata makerBid, Order calldata takerAsk)
        external
        pure
        override
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        )
    {
        return (
            (makerBid.side != takerAsk.side) &&
            (makerBid.paymentToken == takerAsk.paymentToken) &&
            (makerBid.collection == takerAsk.collection) &&
            (makerBid.extraParams.length > 0 && makerBid.extraParams[0] == "\x01") &&
            (takerAsk.extraParams.length > 0 && takerAsk.extraParams[0] == "\x01") &&
            (makerBid.amount == 1) &&
            (takerAsk.amount == 1) &&
            (makerBid.matchingPolicy == takerAsk.matchingPolicy) &&
            (makerBid.price == takerAsk.price),
            makerBid.price,
            takerAsk.tokenId,
            1,
            AssetType.ERC721
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum Side { Buy, Sell }
enum SignatureVersion { Single, Bulk }
enum AssetType { ERC721, ERC1155 }

struct Fee {
    uint16 rate;
    address payable recipient;
}

struct Order {
    address trader;
    Side side;
    address matchingPolicy;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address paymentToken;
    uint256 price;
    uint256 listingTime;
    /* Order expiration timestamp - 0 for oracle cancellations. */
    uint256 expirationTime;
    Fee[] fees;
    uint256 salt;
    bytes extraParams;
}

struct Input {
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes extraSignature;
    SignatureVersion signatureVersion;
    uint256 blockNumber;
}

struct Execution {
  Input sell;
  Input buy;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Order, AssetType} from "../lib/OrderStructs.sol";

interface IMatchingPolicy {
    function canMatchMakerAsk(Order calldata makerAsk, Order calldata takerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        );

    function canMatchMakerBid(Order calldata makerBid, Order calldata takerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        );
}