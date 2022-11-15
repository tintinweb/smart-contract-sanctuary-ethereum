//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct ChannelOffer {
    address buyer;
    uint256 price;
}

struct TicketOffer {
    address buyer;
    uint256 price;
    uint256 tokenId;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import { EIP712Domain, ChannelOffer, TicketOffer } from "./ChannelStructs.sol";

contract ChannelVerifiers {
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version, uint256 chainId,address verifyingContract)");
    bytes32 constant CHANNEL_OFFER_TYPEHASH = keccak256("ChannelOffer(address buyer,uint256 price)");
    bytes32 constant TICKET_OFFER_TYPEHASH = keccak256("TICKETOffer(address buyer,uint256 price,uint256 tokenId)");
    bytes32 DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = domain_hash(EIP712Domain({
            name: "Bitsliced Channel",
            version: '1',
            chainId: 5,
            verifyingContract: address(this)
        }));
    }
    function domain_hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function channel_offer_hash(ChannelOffer memory offer) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CHANNEL_OFFER_TYPEHASH,
            offer.buyer,
            offer.price
        ));
    }

    function verifyChannel(ChannelOffer memory offer, uint8 v, bytes32 r, bytes32 s, address signer) public view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            channel_offer_hash(offer)
        ));
        return ecrecover(digest, v, r, s) == signer;
    }

    function ticket_offer_hash(TicketOffer memory offer) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TICKET_OFFER_TYPEHASH,
            offer.buyer,
            offer.price,
            offer.tokenId
        ));
    }

    function verifyTicket(TicketOffer memory offer, uint8 v, bytes32 r, bytes32 s, address signer) public view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            ticket_offer_hash(offer)
        ));
        return ecrecover(digest, v, r, s) == signer;
    }
}