/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: contracts/NFTHelp.sol



pragma solidity ^0.8.8;


interface IToken {
    function mint(uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function totalSupply() external view returns  (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// NFTHelp for NFT batch mint
contract NFTHelp is IERC721Receiver {
    function mint(address token, uint256 amount) public {
        uint256 startIndex = IToken(token).totalSupply();
        IToken(token).mint(amount);
        for (uint256 i = 0; i < amount; i++) {
            IToken(token).transferFrom(address(this), msg.sender, startIndex + i);
        }
    }
    function mintTo(address token, uint256 amount) public {
        uint256 startIndex = IToken(token).totalSupply();
        IToken(token).mint(msg.sender, amount);
    }

    function mint(address token, address[] memory accounts) public {
        uint256 amount = accounts.length;
        uint256 startIndex = IToken(token).totalSupply();
        IToken(token).mint(amount);
        for (uint256 i = 0; i < amount; i++) {
            IToken(token).transferFrom(address(this), accounts[i], startIndex + i);
        }
    }
    function mintTo(address token, address[] memory accounts) public {
        uint256 amount = accounts.length;
        for (uint256 i = 0; i < amount; i++) {
            IToken(token).mint(accounts[i], 1);
        }
    }

    function baseMint(address base, address token, uint256 amount) public {
        uint256 startIndex = IToken(token).totalSupply();
        IToken(token).mint(amount);
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = startIndex + i;
            address owner = IToken(base).ownerOf(tokenId);
            IToken(token).transferFrom(address(this), owner, tokenId);
        }
    }

    function baseMintTo(address base, address token, uint256 amount) public {
        uint256 startIndex = IToken(token).totalSupply();
        for (uint256 i = 0; i < amount; i++) {
            address owner = IToken(base).ownerOf(startIndex + i);
            IToken(token).mint(owner, 1);
        }
    }

    function transferFrom(address token, address from, address[] memory accounts, uint256[] memory tokenIds) public {
        require(accounts.length == tokenIds.length, "LENGTH");
        for (uint256 i = 0; i < accounts.length; i++) {
            IToken(token).transferFrom(from, accounts[i], tokenIds[i]);
        }
    }

    function transfer(address token, address[] memory accounts, uint256[] memory tokenIds) public {
        transferFrom(token, msg.sender, accounts, tokenIds);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}