// SPDX-License-Identifier: Unlisenced
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


pragma solidity ^0.8.0;

interface Target {
    function devMint(uint256) external;
}

contract Interaction is IERC721Receiver
{
    function getCount() external{
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);
        Target(0xFE402d0Ab1A72ef1977e6Af7ADA7adC1eDB023D0).devMint(5);

    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4)
    {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}