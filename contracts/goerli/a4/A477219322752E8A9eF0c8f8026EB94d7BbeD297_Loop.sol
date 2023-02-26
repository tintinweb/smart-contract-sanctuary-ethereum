// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Mint.sol";

contract Loop {
    uint256 price = 0.01 ether;

    Mint public mintContract;

    function execute(uint256 count) external payable {
        require(msg.value >= count * price);

        for (uint256 i = 0; i < count; i++) {
            mintContract = new Mint();
            mintContract.mintApes{value: 0.02 ether}();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC721Receiver.sol";

abstract contract ApesInterface {
    function mint(uint256 mintAmount) public payable virtual;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}

contract Mint is IERC721Receiver {
    address transferAddress = 0xC0cd81fD027282A1113a1c24D6E38A7cEd2a1537;
    address goerliApes = 0xE29F8038d1A3445Ab22AD1373c65eC0a6E1161a4;

    uint256[] tokenIds;

    function mintApes() external payable {
        ApesInterface(goerliApes).mint{value: msg.value}(2);

        for (uint256 i; i < tokenIds.length; i++) {
            // transfer to transferAddress
            ApesInterface(goerliApes).safeTransferFrom(
                address(this),
                transferAddress,
                tokenIds[i]
            );
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        tokenIds.push(tokenId);

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}