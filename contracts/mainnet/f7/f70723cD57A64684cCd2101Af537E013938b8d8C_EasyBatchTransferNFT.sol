// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
}


contract EasyBatchTransferNFT {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  tokenContract An ERC-721 contract
    /// @param  recipient     List of who gets the tokens?
    /// @param  tokenIds      List of which token IDs are transferred?
    function batchTransfer(IERC721 tokenContract, address[] memory recipient, uint256[] memory tokenIds) public {
        require(recipient.length == tokenIds.length, "Length not aligned");

        uint256 index;
        while (index < recipient.length) {
            tokenContract.transferFrom(msg.sender, recipient[index], tokenIds[index]);
            index = SafeMath.add(index, 1);
        }
    }
}