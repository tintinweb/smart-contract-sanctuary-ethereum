/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Verifier {
    uint256 constant chainId = 256;
    bytes32 constant salt = 0xc14d68eb0d0a4df33c3656bc9e67e9cd0af9811668568c61c0c7e98ac830bdfa;
    address verifyingContract = address(this);
    uint256 public number;

    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
    string private constant BID_TYPE = "Bid(uint256 amount,Identity bidder)Identity(uint256 userId,address wallet)";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant IDENTITY_TYPEHASH = keccak256(abi.encodePacked(IDENTITY_TYPE));
    bytes32 private constant BID_TYPEHASH = keccak256(abi.encodePacked(BID_TYPE));
    bytes32 private DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("EIP712 DApp"),
            keccak256("1"),
            chainId,
            verifyingContract,
            salt
        ));

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

    function verify(uint8 v,bytes32 r, bytes32 s) public view returns (bool) {
        Identity memory bidder = Identity({
        userId: 123,
        wallet: 0xF07149221A4C85c26feCC560c5970Ec1415f6735
        });

        Bid memory bid = Bid({
        amount: 100,
        bidder: bidder
        });

        // uint8 v = 27;
        // bytes32 r = 0xb9ed3bc4fad477fe4f66a3d35232a2373fd6ed4d2bacf01ae3e32e62f3e4a791;
        // bytes32 s = 0x07756fb70e584cb0167ca724a4fb5f51e1ba052cb0edb88cef12a7db70504267;

        // address signer = 0x429ebD9365061DaBb853de89c134F9b79468a952;

        return msg.sender == ecrecover(hashBid(bid), v, r, s);
    }

    function setValue(uint256 value) public {
        number = value;
    }

    function show() public view returns(address,address) {
        return (msg.sender, verifyingContract);
    }
}