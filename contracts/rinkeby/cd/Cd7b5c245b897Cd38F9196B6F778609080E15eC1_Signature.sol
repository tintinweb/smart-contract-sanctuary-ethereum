// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

struct Identity {
    uint256 userId;
    address wallet;
}
struct Bid {
    uint256 amount;
    Identity bidder;
}

contract Signature {

    string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
    string private constant BID_TYPE = "Bid(uint256 amount,Identity bidder)Identity(uint256 userId,address wallet)";

    uint256 constant chainId = 1;
    address constant verifyingContract = 0x1C56346CD2A2Bf3202F771f50d3D14a367B48070;
    bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
    string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        abi.encode(EIP712_DOMAIN),
        keccak256("My amazing dApp"),
        keccak256("2"),
        chainId,
        verifyingContract,
        salt
    ));

    function hashIdentity(Identity memory identity) public pure returns (bytes32) {
        return keccak256(abi.encode(
            abi.encode(IDENTITY_TYPE),
            identity.userId,
            identity.wallet
        ));
    }

    function hashBid(Bid memory bid) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\\x19\\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                    abi.encode(BID_TYPE),
                    bid.amount,
                    hashIdentity(bid.bidder)
                )
            )
        ));
    }

    function verify(address signer, Bid memory bid, bytes32 sigR, bytes32 sigS, uint8 sigV) public pure returns (bool) {
        return signer == ecrecover(hashBid(bid), sigV, sigR, sigS);
    }
}