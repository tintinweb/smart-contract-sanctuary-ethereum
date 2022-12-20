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

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Greeter is IERC721Receiver {
    string greeting;
    address _operator;
    address _from;
    uint256 _tokenId;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function info_greet() public view returns (string memory) {
        return greeting;
    }

    function info_operator() public view returns (address) {
        return _operator;
    }

    function info_from() public view returns (address) {
        return _from;
    }

    function info_tokenId() public view returns (uint256) {
        return _tokenId;
    }

    function setGreeting(string memory _greeting) public virtual {
        greeting = _greeting;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        _operator = operator;
        _from = from;
        _tokenId = tokenId;

        return this.onERC721Received.selector;
    }
}