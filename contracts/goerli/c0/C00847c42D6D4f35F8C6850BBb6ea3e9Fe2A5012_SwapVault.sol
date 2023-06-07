/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address approved, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


contract SwapVault {

    IERC721 public token;
    address public sender;
    address public receiver;
    uint256 public tokenId;
    uint256 public lockingTime;
    uint256 public lockingDuration;
    bytes32 public lockingHash;

    function lock(address _token, uint256 _tokenId, bytes32 _hash, uint256 _duration, address _receiver) external {
        token = IERC721(_token);
        token.transferFrom(msg.sender, address(this), _tokenId);
        sender = msg.sender;
        receiver = _receiver;
        lockingTime = block.timestamp;
        lockingDuration = _duration * 1 minutes;
        lockingHash = _hash;
    }

    function hashUint(uint256 _preImage) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_preImage));
    }

    function unlock(uint256 _secret) external {
        require(hashUint(_secret) == lockingHash, "preimage doesn't work");
        require(block.timestamp < lockingTime + lockingDuration, "unlocking period closed");
        token.transferFrom(address(this), receiver, tokenId);
    }

    function getTokenBack() external {
        require(block.timestamp > lockingTime + lockingDuration, "unlocking period still open");
        token.transferFrom(address(this), sender, tokenId);
    }

}