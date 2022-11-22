// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract MerkleDrop is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    bytes32 immutable public root;
    address immutable public token;
    mapping(bytes32 => bool) public claimed;

    event FeesClaimed(address account, uint amount);

    constructor(bytes32 _merkleroot, address _token) {
        root = _merkleroot;
        token = _token;
    }

    function withdrawFees(address _account, uint256 _amount) external onlyOwner {
        IERC20(token).safeTransfer(_account, _amount);
    }

    function redeemFees(address _account, uint256 _amount, bytes32[] calldata _proof) external nonReentrant {
        bytes32 leaf = _leafEncode(_account, _amount);
        require(_verify(leaf, _proof), "MerkleDrop: Invalid merkle proof");

        require(!claimed[leaf], "MerkleDrop: Already Claimed");
        claimed[leaf] = true;

        IERC20(token).safeTransfer(_account, _amount);

        emit FeesClaimed(_account, _amount);
    }

    function _leafEncode(address _account, uint256 _amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _amount));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, root, _leaf);
    }
}