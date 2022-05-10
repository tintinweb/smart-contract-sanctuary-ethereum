// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

error InvalidTokenId();

interface ISmolBirb {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract EthBridge is IERC721Receiver {
    ISmolBirb public smolBirb =
        ISmolBirb(0xF45aF344e0a31ffC270B61CDF1DEDAF63107ba54);
    mapping(uint256 => address) public tokenIdDepositor;

    event Deposit(address depositor, uint256[] tokenIds);
    event Withdraw(address withdrawer, uint256[] tokenIds);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function deposit(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ) {
            if (tokenIds[i] > 10000 || tokenIds[i] == 0)
                revert InvalidTokenId();
            tokenIdDepositor[tokenIds[i]] = msg.sender;
            smolBirb.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        emit Deposit(msg.sender, tokenIds);
    }

    function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ) {
            if (tokenIds[i] > 10000 || tokenIds[i] == 0)
                revert InvalidTokenId();
            smolBirb.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        emit Withdraw(msg.sender, tokenIds);
    }
}