/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice ERC1155 minting function.
abstract contract ERC1155Mint {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public payable virtual;
}

/// @dev The ETH transfer has failed.
error ETHTransferFailed();

function safeTransferETH(address to, uint256 amount) {
    /// @solidity memory-safe-assembly
    assembly {
        // Transfer the ETH and check if it succeeded or not.
        if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
            // Store the function selector of `ETHTransferFailed()`.
            mstore(0x00, 0xb12d13eb)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }
    }
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

/// @notice NANI maker facility.
/// @author NANI
contract NaniMaker {
    ERC1155Mint internal constant NANI = ERC1155Mint(0x379569b497eE6fdEb6f6128B9f59EfB49B85e3A2);
    IERC721 internal constant MILADY = IERC721(0x5Af0D9827E0c53E4799BB226655A1de152A425a5);
    IERC721 internal constant REDACT = IERC721(0xD3D9ddd0CF0A5F0BFB8f7fcEAe075DF687eAEBaB);
    IERC721 internal constant YAYO = IERC721(0x09f66a094a0070EBDdeFA192a33fa5d75b59D46b);

    constructor() payable {}

    function join() public payable virtual {
        // 1 ETH = 10k NANI. Decimals via JSON.
        unchecked {
            NANI.mint(msg.sender, 0, msg.value * 10_000, "");
        }
        // Manifest mint. Angelic tithe.
        if (msg.value >= 0.00999 ether) NANI.mint(msg.sender, 1, 1, "");
    }

    function milady() public payable virtual {
        if (MILADY.balanceOf(msg.sender) != 0) {
            // 1 ETH = 10k NANI. Decimals via JSON.
            unchecked {
                NANI.mint(msg.sender, 0, msg.value * 10_000, "");
            }
            // Manifest mint. Super discounted. Tripled.
            NANI.mint(msg.sender, 1, 3, "");
        }
    }

    function reDact() public payable virtual {
        if (REDACT.balanceOf(msg.sender) != 0) {
            // 1 ETH = 10k NANI. Decimals via JSON.
            unchecked {
                NANI.mint(msg.sender, 0, msg.value * 10_000, "");
            }
            // Manifest mint. Super discounted. Doubled.
            NANI.mint(msg.sender, 1, 2, "");
        }
    }

    function yaYo() public payable virtual {
        if (YAYO.balanceOf(msg.sender) != 0) {
            // 1 ETH = 10k NANI. Decimals via JSON.
            unchecked {
                NANI.mint(msg.sender, 0, msg.value * 10_000, "");
            }
            // Manifest mint. Super discounted.
            NANI.mint(msg.sender, 1, 1, "");
        }
    }

    function skim() public payable virtual {
        safeTransferETH(address(NANI), address(this).balance);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public payable virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}