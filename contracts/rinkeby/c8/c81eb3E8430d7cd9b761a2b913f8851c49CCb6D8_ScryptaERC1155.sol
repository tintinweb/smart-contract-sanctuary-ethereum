// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract ScryptaERC1155 is ERC1155, Ownable {

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    uint256 private _currentTokenId = 0;

    constructor(string memory baseUri) ERC1155(baseUri) {}

    function setCreator(address to, uint256[] memory ids) public onlyOwner {
        require(to != address(0), "ScryptaERC1155: Null address cannot be the creator.");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            creators[id] = to;
        }
    }

    function create(address creator, uint256 supply) public onlyOwner returns (uint256) {
        uint256 _id = _currentTokenId++;
        creators[_id] = creator;
        tokenSupply[_id] = supply;
        _mint(creator, _id, supply, "");
        return _id;
    }
    
    function mint(address to, uint256 id, uint256 amount) public onlyOwner {
        tokenSupply[id] = tokenSupply[id] + amount;
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            tokenSupply[id] = tokenSupply[id] + amount;
        }
        _mintBatch(to, ids, amounts, "");
    }

    function burn(address from, uint256 id, uint256 amount) public onlyOwner {
        require(tokenSupply[id] >= amount, "ScryptaERC1155: Burn amount should be less than token supply.");
        tokenSupply[id] = tokenSupply[id] - amount;
        _burn(from, id, amount);
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            require(tokenSupply[id] >= amount, "ScryptaERC1155: Burn amount should be less than token supply.");
            tokenSupply[id] = tokenSupply[id] - amount;
        }
        _burnBatch(from, ids, amounts);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function safeMultiTransfer(address[] memory from, address[] memory to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        require(from.length == to.length && from.length == ids.length && from.length == amounts.length, "ScryptaERC1155: All array should be of the same length.");
        for (uint256 i = 0; i < from.length; i++) {
            safeTransferFrom(from[i], to[i], ids[i], amounts[i], "");
        }
    }
}