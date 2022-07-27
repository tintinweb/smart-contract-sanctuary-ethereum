// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error InvalidInput(string input);
error PendingSwapAlreadyExists();
error SwapCannotBeRefundedUntilExpired();
error SwapDoesntExist();
error TransferFailed();

contract AtomicSwap {

    struct Swap {
        uint256 amount;
        string dash;
        uint256 expiresAt;
        bytes32 secret;
    }


    // Initiator Address => Swap
    mapping(address => Swap) public _swaps;

    // TODO: Need ETH, ERC20, ERC721, ERC1155


    function initializeETH(string memory dash, uint256 expiresAt, bytes32 secret) external payable {
        address initiator = msg.sender;

        if (_swaps[initiator].expiresAt > 0) {
            revert PendingSwapAlreadyExists();
        }

        if (bytes(dash).length == 0) {
            revert InvalidInput({ input: 'dash' });
        }

        if (expiresAt < block.timestamp) {
            revert InvalidInput({ input: 'expiresAt' });
        }

        if (secret.length == 0) {
            revert InvalidInput({ input: 'secret' });
        }

        _swaps[initiator] = Swap(msg.value, dash, expiresAt, secret);
    }

    function redeem(address initiator, string memory secret) external {
        address participant = msg.sender;
        Swap memory swap = _swaps[initiator];

        delete _swaps[initiator];

        if (swap.expiresAt == 0) {
            revert SwapDoesntExist();
        }

        if (swap.secret != sha256(abi.encodePacked(secret))) {
            revert InvalidInput({ input: 'secret' });
        }

        (bool success, ) = payable(participant).call{value: swap.amount}('');

        if (!success) {
            revert TransferFailed();
        }
    }

    function refund() external {
        address initiator = msg.sender;
        Swap memory swap = _swaps[initiator];

        delete _swaps[initiator];

        if (swap.expiresAt == 0) {
            revert SwapDoesntExist();
        }

        if (swap.expiresAt > block.timestamp) {
            revert SwapCannotBeRefundedUntilExpired();
        }

        (bool success, ) = payable(initiator).call{value: swap.amount}('');

        if (!success) {
            revert TransferFailed();
        }
    }
}