// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract SignatureVerification {
    function recover(bytes32 hash, bytes memory signature) public pure returns (address) {}
}

interface NFT {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool _approved) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(address to, uint256 id) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract ExtendedContract {
    SignatureVerification sigVerify;
    NFT nft;
    mapping(bytes => bool) private signatures;
    constructor(address nftContract )  {
        nft = NFT(nftContract);
        sigVerify = SignatureVerification(0x50e0C6CBA35b1fa1dD3e9d05B3eaFB1b01318717);
    }
    function mintBatch(address _to, uint256[] memory ids) public {
        for (uint256 index = 0; index < ids.length; index++) {
            nft.mint(_to, ids[index]);
        }
    }

    function transferBatch(address from, address to, uint256[] memory ids) public {
        for (uint256 index = 0; index < ids.length; index++) {
            nft.safeTransferFrom(from, to, ids[index]);
        }
    }
    function transferApprovalBatch(address[] memory from, address[] memory to, uint256[] memory tokenIds, bytes32[] memory msgHash, bytes[] memory hashSig) public {
        // require(hasRole(SECONDARY_WHITELISTED_ROLE, _msgSender()), "User not allowed to access");
        require(from.length == to.length && to.length == tokenIds.length && tokenIds.length == msgHash.length && msgHash.length == hashSig.length, "Ids length exceeding the limit");
        for (uint256 index = 0; index < tokenIds.length; index++) {
            require(signatures[hashSig[index]] != true, "signature already used");
            require(sigVerify.recover(msgHash[index], hashSig[index]) == nft.ownerOf(tokenIds[index]),"Approval denied");
            nft.safeTransferFrom(from[index], to[index], tokenIds[index]);
            signatures[hashSig[index]] = true;
        }
    }

}