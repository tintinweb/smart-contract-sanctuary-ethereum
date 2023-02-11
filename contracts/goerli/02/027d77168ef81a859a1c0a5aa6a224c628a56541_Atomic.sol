/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Atomic {

    struct Swap {
        address sender;
        address receiver;
        uint amount;
        uint deadline;
        bool exists;
    }

    error SwapExists(Swap swap);
    error ZeroValue();
    error SwapDoesNotExist(bytes32 hash);
    error OnlySenderCanReclaim(Swap swap);
    error NoReclaimBeforeDeadline(Swap swap);
    error OnlyReceiverCanClaim(Swap swap);
    error NoClaimAfterDeadline(Swap swap);

    mapping(bytes32 hash => Swap) public swaps;
    mapping(bytes32 hash => bytes32) public secrets;

    function swap(bytes32 _hash, address _receiver, uint _deadline) external payable {
        Swap storage _swap = swaps[_hash];

        if (_swap.exists) {
            revert SwapExists(_swap);
        }
        if (msg.value == 0) {
            revert ZeroValue();
        }

        _swap.sender   = msg.sender;
        _swap.receiver = _receiver;
        _swap.amount   = msg.value;
        _swap.deadline = _deadline;
        _swap.exists   = true;
    }

    function reclaim(bytes32 _hash) external {
        Swap storage _swap = swaps[_hash];

        if (!_swap.exists) {
            revert SwapDoesNotExist(_hash);
        }
        if (_swap.sender != msg.sender) {
            revert OnlySenderCanReclaim(_swap);
        }
        if (_swap.deadline > block.timestamp) {
            revert NoReclaimBeforeDeadline(_swap);
        }

        uint _amount = _swap.amount;
        delete swaps[_hash];
        payable(msg.sender).transfer(_amount);
    }

    function claim(bytes32 _secret) external {
        bytes32 _hash = sha256(abi.encodePacked(_secret));
        Swap storage _swap = swaps[_hash];

        if (!_swap.exists) {
            revert SwapDoesNotExist(_hash);
        }
        if (_swap.receiver != msg.sender) {
            revert OnlyReceiverCanClaim(_swap);
        }
        if (_swap.deadline <= block.timestamp) {
            revert NoClaimAfterDeadline(_swap);
        }

        uint _amount = _swap.amount;
        delete swaps[_hash];
        payable(msg.sender).transfer(_amount);
        secrets[_hash] = _secret;
    }
}