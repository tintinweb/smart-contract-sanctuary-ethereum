// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../../interfaces/modules/beforeTransfer/I721BeforeTransfersModule.sol";

contract NonTransferable721Module is I721BeforeTransfersModule {
    /// @notice Disables transfer on non mint & burn token transfers
    function beforeTokenTransfers(
        address, /*sender*/
        address from,
        address to,
        uint256, /*startTokenId*/
        uint256 /*quantity*/
    ) external pure {
        require(from == address(0) || to == address(0), "transfer disabled");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface I721BeforeTransfersModule {
    /// @dev Called by original contract on ERC721A _beforeTokenTransfers hook
    /// @notice if performing storage updates, good practice to check that msg.sender is original contract
    /// Calling conditions:
    /// When from and to are both non-zero, from‘s tokenId will be transferred to to.
    /// When from is zero, tokenId will be minted for to.
    /// When to is zero, tokenId will be burned by from.
    /// from and to are never both zero.
    /// see https://chiru-labs.github.io/ERC721A/#/erc721a?id=_beforetokentransfers
    function beforeTokenTransfers(
        address sender,
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) external;
}