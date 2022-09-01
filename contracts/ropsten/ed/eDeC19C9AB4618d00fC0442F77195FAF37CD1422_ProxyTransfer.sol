/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface NftAddress {
    function safeTransfer(address from, address to, uint256 tokenId) external payable;
}

contract ProxyTransfer {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant PROXY_TRANSFER = keccak256(
        "Transfer(address from,uint256 tokenId,uint256 price)"
    );
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 DOMAIN_SEPARATOR;

    constructor () {
    }

    function hash(address from, uint256 tokenId, uint256 price) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                PROXY_TRANSFER,
                from,
                tokenId,
                price
            ));
    }
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            ));
    }

    function nftTransfer(address transferAddress, address from, address to, uint256 tokenId, uint8 v, bytes32 r, bytes32 s) external payable{
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "Transfer",
            version: '1',
            chainId: 1,
            verifyingContract: transferAddress
        }));
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hash(from, tokenId, msg.value)
            ));
        require(ecrecover(digest, v, r, s) == from, "invalid signer");

        NftAddress(transferAddress).safeTransfer{value:msg.value}(from,to,tokenId);
    }
}