/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

contract ERC721PermitEverywhere {
    struct PermitTransferFrom {
        IERC721 token;
        address spender;
        uint256 tokenId;
        bool allowAnyTokenId;
        uint256 deadline;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    bytes32 public immutable DOMAIN_TYPE_HASH;
    bytes32 public immutable TRANSFER_PERMIT_TYPEHASH;

    // Owner -> current nonce.
    mapping (address => uint256) public currentNonce;

    constructor() {
        uint256 chainId;
        assembly { chainId := chainid() }
        DOMAIN_TYPE_HASH = keccak256(abi.encode(
            keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            type(ERC721PermitEverywhere).name,
            '1.0.0',
            chainId,
            address(this)
        ));
        TRANSFER_PERMIT_TYPEHASH =
            keccak256('PermitTransferFrom(address token,address spender,uint256 tokenId,bool allowAnyTokenId,uint256 deadline,uint256 nonce)');
    }

    function executePermitTransferFrom(
        address owner,
        address to,
        uint256 tokenId,
        PermitTransferFrom memory permit,
        Signature memory sig
    )
        external
    {
        _consumePermit(owner, tokenId, permit, sig);
        permit.token.transferFrom(owner, to, tokenId);
    }

    function executePermitSafeTransferFrom(
        address owner,
        address to,
        uint256 tokenId,
        bytes memory data,
        PermitTransferFrom memory permit,
        Signature memory sig
    )
        external
    {
        _consumePermit(owner, tokenId, permit, sig);
        permit.token.safeTransferFrom(owner, to, tokenId, data);
    }

    function hashPermit(PermitTransferFrom memory permit, uint256 nonce)
        public
        view
        returns (bytes32 h)
    {
        bytes32 dh = DOMAIN_TYPE_HASH;
        bytes32 th = TRANSFER_PERMIT_TYPEHASH;
        assembly {
            if lt(permit, 0x20)  {
                invalid()
            }
            let c1 := mload(sub(permit, 0x20))
            let c2 := mload(add(permit, 0xA0))
            mstore(sub(permit, 0x20), th)
            mstore(add(permit, 0xA0), nonce)
            let ph := keccak256(sub(permit, 0x20), 0xE0)
            mstore(sub(permit, 0x20), c1)
            mstore(add(permit, 0xA0), c2)
            let p:= mload(0x40)
            mstore(p, 0x1901000000000000000000000000000000000000000000000000000000000000)
            mstore(add(p, 0x02), dh)
            mstore(add(p, 0x22), ph)
            h := keccak256(p, 0x42)
        }
    }

    function _consumePermit(
        address owner,
        uint256 tokenId,
        PermitTransferFrom memory permit,
        Signature memory sig
    )
        private
    {
        require(permit.spender == address(0) || msg.sender == permit.spender, 'SPENDER_NOT_PERMITTED');
        require(permit.allowAnyTokenId || permit.tokenId == tokenId, 'TOKEN_ID_NOT_PERMITTED');
        require(permit.deadline <= block.timestamp, 'PERMIT_EXPIRED');
        uint256 nonce = currentNonce[owner]++;
        require(owner == getSigner(hashPermit(permit, nonce), sig), 'INVALID_SIGNER');
    }

    function getSigner(bytes32 hash, Signature memory sig) private pure returns (address signer) {
        signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer != address(0), 'INVALID_SIGNATURE');
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address owner, address to, uint256 tokenId) external;
    function safeTransferFrom(address owner, address to, uint256 tokenId, bytes memory data) external;
}