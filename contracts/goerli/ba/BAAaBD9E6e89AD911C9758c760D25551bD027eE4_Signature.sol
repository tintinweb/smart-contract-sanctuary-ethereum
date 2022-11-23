//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Signature {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }
    struct OrderMain {
        address seller;
        address buyer;
        uint8   assetType;          // 0 => ERC1155, 1 => ERC721
        uint8   orderType;          // 0 => fixed price sell order, 1 => make offer or place bid
        address baseToken;          // NFT address
        uint256 assetId;            // NFT tokenId
        uint256 fraction;           // NFT fraction : ERC721 or ERC1155 single => 1, ERC1155 multi => any
        uint256 assetAmount;        // ERC1155 single or ERC721 => 1, ERC1155 multi => can be any > 0 
        address quoteToken;         // ETH => address(0), ERC20 address
        uint256 price;              // Fixed price or auction bid price or make offer price
    }
    struct OrderOption {
        uint256 startTime;          // start timestamp [sec]
        uint256 endTime;            // end timestamp   [sec]
        address collectionOwner;    // collection owner address
        uint256 collectionFee;      // collection royalty fee
        address nftCreator;         // nft creator
        uint256 nftFee;             // nft royalty fee
    }
    struct Order {
        OrderMain orderMain;
        OrderOption orderOption;
    }


    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version, uint256 chainId,address verifyingContract)"
    );

    bytes32 constant ORDER_MAIN_TYPEHASH = keccak256(
        "OrderMain(address seller,address buyer,uint8 assetType,uint8 orderType,address baseToken,uint256 assetId,uint256 fraction,uint256 assetAmount,address quoteToken,uint256 price)"
    );

    bytes32 constant ORDER_OPTION_TYPEHASH = keccak256(
        "OrderOption(uint256 startTime,uint256 endTime,address collectionOwner,uint256 collectionFee,address nftCreator,uint256 nftFee)"
    );

    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(OrderMain orderMain,OrderOption orderOption)OrderMain(address seller,address buyer,uint8 assetType,uint8 orderType,address baseToken,uint256 assetId,uint256 fraction,uint256 assetAmount,address quoteToken,uint256 price)OrderOption(uint256 startTime,uint256 endTime,address collectionOwner,uint256 collectionFee,address nftCreator,uint256 nftFee)"
    );

    bytes32 DOMAIN_SEPARATOR;

    constructor () {
        DOMAIN_SEPARATOR = domain_hash(EIP712Domain({
            name: "Bitsliced App",
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

    function order_hash_main(OrderMain memory orderMain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORDER_MAIN_TYPEHASH,
            orderMain.seller,
            orderMain.buyer,
            orderMain.assetType,
            orderMain.orderType,
            orderMain.baseToken,
            orderMain.assetId,
            orderMain.fraction,
            orderMain.assetAmount,
            orderMain.quoteToken,
            orderMain.price
        ));
    }

    function order_hash_option(OrderOption memory orderOption) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORDER_OPTION_TYPEHASH,
            orderOption.startTime,
            orderOption.endTime,
            orderOption.collectionOwner,
            orderOption.collectionFee,
            orderOption.nftCreator,
            orderOption.nftFee
        ));
    }

    function order_hash(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order_hash_main(order.orderMain),
            order_hash_option(order.orderOption)
        ));
    }

    function verify(Order memory order, uint8 v, bytes32 r, bytes32 s, address signer) public view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            order_hash(order)
        ));
        return ecrecover(digest, v, r, s) == signer;
    }
}