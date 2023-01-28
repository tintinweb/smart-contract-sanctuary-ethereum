// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract BiggiesNFT is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    constructor() ERC1155("") {}

    struct Token {
        uint256 id;
        string name;
        string metadata_url;
        uint256 supply;
    }

    mapping (uint256 => Token) public Tokens;

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 _id) public view returns (string memory) {
        return Tokens[_id].metadata_url;
    }

    function addToken(uint256 id, string memory name, string memory metadata_url, uint256 supply) public onlyOwner {
        require(Tokens[id].id == 0, "Token already exists");
        Tokens[id] = Token(id, name, metadata_url, supply);
    }

    function editToken(uint256 id, string memory name, string memory metadata_url, uint256 supply) public onlyOwner {
        require(Tokens[id].id != 0, "Token doesn't exist");
        Tokens[id] = Token(id, name, metadata_url, supply);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner

    {
        require(Tokens[id].supply - amount >= 0, "Token doesn't exist or not enough supply");
        _mint(account, id, amount, data);
        Tokens[id].supply -= amount;
    }

    // function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    //     public
    //     onlyOwner
    // {
    //     _mintBatch(to, ids, amounts, data);
    // }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}