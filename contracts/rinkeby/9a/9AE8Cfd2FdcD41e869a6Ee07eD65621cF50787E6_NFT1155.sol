// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract NFT1155 is Ownable, ERC1155 {
    using Strings for uint256;

    uint256 index;

    constructor(string memory name, string memory symbol) ERC1155(name, symbol) {
        index = 1;
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(tx.origin, index, amount, "");
        index++;
    }

    function mintBatch(uint256[] memory amounts) external onlyOwner {
        for(uint256 i; i < amounts.length; i++) {
            _mint(tx.origin, index, amounts[i], "");
            index++;
        }
    }

    function mint(uint256 id, uint256 amount) external onlyOwner {
        _mint(tx.origin, id, amount, "");
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(tx.origin, ids, amounts, "");
    }

    function burn(uint256 id, uint256 amount) external onlyOwner {
        _burn(tx.origin, id, amount);
    }

    function uri(uint256 id) external view override returns (string memory) {
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, id.toString())) : "";
    }

    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }
}