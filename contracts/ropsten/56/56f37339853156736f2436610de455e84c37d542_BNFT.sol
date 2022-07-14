// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./BRC721Enumerable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract BNFT is BRC721Enumerable, Pausable {
    using Strings for uint256;

    string private baseURI;
    address public owner;

    constructor(
        address admin_,
        address owner_,
        string memory baseURI_,
        string memory name_,
        string memory symbol_
    ) BRC721(admin_, name_, symbol_) {
        baseURI = string(abi.encodePacked(baseURI_, symbol_, "/"));
        owner = owner_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * override tokenURI(uint256), remove restrict for tokenId exist.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setOwner(address owner_) external onlyAdmin {
        owner = owner_;
    }

    function setPause() external onlyAdmin {
        _pause();
    }

    function unsetPause() external onlyAdmin {
        _unpause();
    }

    function changeBaseURI(string memory newBaseURI) external onlyAdmin {
        string memory symbol_ = symbol();
        baseURI = string(abi.encodePacked(newBaseURI, symbol_, "/"));
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "BRC721Pausable: token transfer while paused");
    }
}