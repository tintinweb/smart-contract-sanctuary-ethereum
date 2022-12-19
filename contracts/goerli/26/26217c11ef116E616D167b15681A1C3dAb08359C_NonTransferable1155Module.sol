// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../../interfaces/modules/beforeTransfer/I1155BeforeTransfersModule.sol";

contract NonTransferable1155Module is I1155BeforeTransfersModule {
    /// @notice Disables transfer on non mint & burn token transfers
    function beforeTokenTransfers(
        address, /*sender*/
        address from,
        address to,
        uint256[] memory, /*tokenIds*/
        uint256[] memory /*tokenAmounts*/
    ) external pure {
        require(from == address(0) || to == address(0), "transfer disabled");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface I1155BeforeTransfersModule {
    /// @dev Called by original contract on ERC1155Upgradable _beforeTokenTransfers hook
    /// @notice if performing storage updates, good practice to check that msg.sender is original contract
    /// Calling conditions:
    /// When from and to are both non-zero, from‘s tokenId will be transferred to to.
    /// When from is zero, tokenId will be minted for to.
    /// When to is zero, tokenId will be burned by from.
    /// from and to are never both zero.
    function beforeTokenTransfers(
        address sender,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory tokenAmounts
    ) external;
}