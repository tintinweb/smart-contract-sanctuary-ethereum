// SPDX-License-Identifier: Unlicense
 
pragma solidity ^0.8.0;
 
// import "./Ownable.sol"; 
// import "./ScryptaERC1155.sol";
// import "./ScryptaERC20.sol";

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Supply.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";

contract ScryptaTokenRegistry is Ownable {

    ScryptaERC1155[] public collections;
    ScryptaERC20[] public coins;

    constructor(
        ScryptaERC1155[] memory _collections,
        ScryptaERC20[] memory _coins
    ) {
        collections = _collections;
        coins = _coins;
    }
 
    function createCollection(
        string memory name,
        string memory symbol,
        string memory uri
    ) public onlyOwner returns (uint256) {
        ScryptaERC1155 collection = new ScryptaERC1155(name, symbol, uri);
        collection.transferOwnership(_msgSender());
        collections.push(collection);
        return collections.length-1;
    }
 
    function createCoin(
        string memory name,
        string memory symbol
    ) public onlyOwner returns (uint256) {
        ScryptaERC20 coin = new ScryptaERC20(name, symbol);
        coin.transferOwnership(_msgSender());
        coins.push(coin);
        return coins.length-1;
    }
 
}
 
contract ScryptaERC1155 is Ownable, ERC1155Burnable, ERC1155Pausable, ERC1155Supply {

    string public name;
    string public symbol;
 
    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _uri
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }
 
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyOwner {
        _mint(to, id, amount, data);
    }
 
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
 
    function pause() public virtual onlyOwner {
        _pause();
    }
 
    function unpause() public virtual onlyOwner {
        _unpause();
    }
 
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
 
}
 
contract ScryptaERC20 is Ownable, ERC20Burnable, ERC20Pausable {
 
    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC20(_name, _symbol) {}
 
    function mint(
        address to, 
        uint256 amount
    ) public virtual onlyOwner {
        _mint(to, amount);
    }
 
    function pause() public virtual onlyOwner {
        _pause();
    }
 
    function unpause() public virtual onlyOwner {
        _unpause();
    }
 
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
 
}