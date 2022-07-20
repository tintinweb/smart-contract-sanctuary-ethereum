/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract BallotTest {
    struct SwapMetaData {
        address seller;
        address erc721;
        address erc20;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endPrice;
        uint256 start;
        uint256 deadline;
    }

    function computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("Fixed Order Market")),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function getKeccak() external view returns (bytes32) {
        return keccak256("Swap(address seller,address erc721,address erc20,uint256 tokenId,uint256 startPrice,uint256 endPrice,uint256 nonce,uint256 start,uint256 deadline)");
    }

    function computeSigner(
        SwapMetaData calldata swap,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual view returns (address signer) {
        
        bytes32 hash = keccak256(
            abi.encode(
                keccak256("Swap(address seller,address erc721,address erc20,uint256 tokenId,uint256 startPrice,uint256 endPrice,uint256 nonce,uint256 start,uint256 deadline)"),
                swap.seller, 
                swap.erc721, 
                swap.erc20,
                swap.tokenId,
                swap.startPrice,
                swap.endPrice,
                nonce,
                swap.start,
                swap.deadline
            )
        );
        
        signer = ecrecover(keccak256(abi.encodePacked("\x19\x01", computeDomainSeparator(), hash)), v, r, s);
    }}