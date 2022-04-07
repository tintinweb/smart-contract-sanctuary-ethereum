/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Verifier {
    uint256 constant chainId = 4;
    bytes32 constant salt = 0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa;
    address verifyingContract = address(this);
    uint256 public number;
    bool public result = false;

    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    // string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
    // string private constant BID_TYPE = "Bid(uint256 amount,Identity bidder)Identity(uint256 userId,address wallet)";
    string private constant Order_TYPE =
    "Order(uint8 order_type,address maker,uint256 maker_nonce,uint64 listing_time,uint64 expiration_time,address nft_contract,uint256 token_id,address payment_token,uint256 base_price,uint256 royalty_rate,address royalty_recipient)";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    // bytes32 private constant IDENTITY_TYPEHASH = keccak256(abi.encodePacked(IDENTITY_TYPE));
    // bytes32 private constant BID_TYPEHASH = keccak256(abi.encodePacked(BID_TYPE));
    bytes32 private constant Order_TYPEHASH = keccak256(abi.encodePacked(Order_TYPE));

    bytes32 private DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("EIP712 DApp"),
            keccak256("1"),
            chainId,
            verifyingContract,
            salt
        ));

    struct Order {
        /* 挂单类型: 0 FixedPrice; 1 EnglishAuction; 2 DutchAuction */
        uint8 order_type;
        /* 签名账号. */
        address maker;
        /* nonce */
        uint256 maker_nonce;
        /* 挂单时间 */
        uint64 listing_time;
        /* 失效时间 */
        uint64 expiration_time;
        /* NFT 地址 */
        address nft_contract;
        /* NFT tokenId  */
        uint256 token_id;
        /* 支付代币地址, 如果用本币支付, 设置为address(0). */
        address payment_token;
        /* 如果order_type是FixedPrice, 即为成交价; 如果是拍卖, 按拍卖方式定义 */
        uint256 base_price;
        /* 版税比例 */
        uint256 royalty_rate;
        /* 版税接收地址 */
        address royalty_recipient;
    }
    /*
        struct Identity {
            uint256 userId;
            address wallet;
        }

        struct Bid {
            uint256 amount;
            Identity bidder;
        }

        function hashIdentity(Identity memory identity) private pure returns (bytes32) {
            return keccak256(abi.encode(
                    IDENTITY_TYPEHASH,
                    identity.userId,
                    identity.wallet
                ));
        }

        function hashBid(Bid memory bid) private view returns (bytes32){
            return keccak256(abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(
                        BID_TYPEHASH,
                        bid.amount,
                        hashIdentity(bid.bidder)
                    ))
                ));
        }
        */

    function hashOrder(Order memory order) private pure returns (bytes32) {
        return keccak256(abi.encode(
                Order_TYPEHASH,
                order.order_type,
                order.maker,
                order.maker_nonce,
                order.listing_time,
                order.expiration_time,
                order.nft_contract,
                order.token_id,
                order.payment_token,
                order.base_price,
                order.royalty_rate,
                order.royalty_recipient
            ));
    }

    function hash(Order memory order) private view returns (bytes32){
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashOrder(order)
            ));
    }

    function verifyTest(uint8 v,bytes32 r, bytes32 s) public {

        Order memory order = Order({
        order_type: 0,
        maker: 0x429ebD9365061DaBb853de89c134F9b79468a952,
        maker_nonce: 123,
        listing_time: 300,
        expiration_time: 1649310064,
        nft_contract: 0xC6Ed094815DDB126e56aE107143B58a3B7d4159D,
        token_id: 1,
        payment_token: 0xC6Ed094815DDB126e56aE107143B58a3B7d4159D,
        base_price: 100,
        royalty_rate: 5,
        royalty_recipient: 0x429ebD9365061DaBb853de89c134F9b79468a952
        });

        if (msg.sender == ecrecover(hash(order), v, r, s)) {
            result = true;
        }
    }

    function setValue(uint256 value) public {
        number = value;
    }
}