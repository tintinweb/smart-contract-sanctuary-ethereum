// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from './IERC20.sol';
import {IERC721} from './IERC721.sol';

error TransferFailed();

contract BatchTransfer {

    // Requires 'approve' before transfer
    function transferERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            bool success = token.transferFrom(msg.sender, recipients[i], values[i]);

            if (!success) {
                revert TransferFailed();
            }
        }
    }

    // Requires 'setApprovalForAll' before transfer
    function transferERC721(IERC721 collection, address recipient, uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            collection.safeTransferFrom(msg.sender, recipient, tokenIds[i]);
        }
    }

    function transferEther(address[] calldata recipients, uint256[] calldata values) external payable {
        uint256 refund = msg.value;

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool success, ) = payable(recipients[i]).call{value: values[i]}('');

            if (!success) {
                revert TransferFailed();
            }

            refund -= values[i];
        }

        // Refund remaining ETH
        if (refund > 0) {
            (bool success, ) = payable(msg.sender).call{value: refund}('');

            if (!success) {
                revert TransferFailed();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}