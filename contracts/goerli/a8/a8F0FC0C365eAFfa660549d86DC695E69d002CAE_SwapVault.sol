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

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}



contract SwapVault {

    IERC1155 public token;
    address public sender;
    address public receiver;
    uint256 public tokenId;
    uint256 public lockingTime;
    uint256 public lockingDuration;
    bytes32 public lockingHash;

    function lock(address _token, uint256 _tokenId, bytes32 _hash, uint256 _duration, address _receiver) external {
        token = IERC1155(_token);
        token.safeTransferFrom(msg.sender, address(this), _tokenId, 1, bytes(""));
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
        token.safeTransferFrom(address(this), receiver, tokenId, 1, bytes(""));
    }

    function getTokenBack() external {
        require(block.timestamp > lockingTime + lockingDuration, "unlocking period still open");
        token.safeTransferFrom(address(this), sender, tokenId, 1, bytes(""));
    }

}