// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";

contract ScryptaERC1155 is ERC1155Burnable, ERC1155Pausable, ERC1155Supply, Ownable {

    event ScryptaTransfer(
        address operator, 
        address indexed from, 
        address indexed to, 
        uint256 indexed id, 
        uint256 amount, 
        uint256 timestamp);

    event ScryptaTrade(
        address operator, 
        address indexed from, 
        address indexed to, 
        uint256 indexed id, 
        uint256 amount, 
        uint256 timestamp,
        uint256 currencyTokenId,
        uint256 currencyTokenAmount);

    mapping(uint256 => address) public creators;
    
    mapping(address => bool) public externalAccounts;

    string public name;
    string public symbol;

    uint256 private _currentTokenId = 0;

    constructor(string memory _name, string memory _symbol, string memory _baseUri) ERC1155(_baseUri) {
        name = _name;
        symbol = _symbol;
    }

    function setCreator(address to, uint256[] memory ids) public onlyOwner {
        require(to != address(0), "ScryptaERC1155: Null address cannot be the creator.");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            creators[id] = to;
        }
    }

    function create(address creator, uint256 amount) public onlyOwner returns (uint256) {
        uint256 _id = _currentTokenId++;
        creators[_id] = creator;
        _mint(creator, _id, amount, "");
        return _id;
    }

    function createBatch(address creator, uint256[] memory amounts) public onlyOwner returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            ids[i] = _currentTokenId++;
            creators[ids[i]] = creator;
        }
        _mintBatch(creator, ids, amounts, "");
        return ids;
    }

    function mint(address to, uint256 id, uint256 amount) public onlyOwner {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function setURI(string memory uri) public onlyOwner {
        _setURI(uri);
    }

    function safeTradeFrom(
        address from, address to, 
        uint256 tokenId, uint256 tokenAmount, 
        uint256 currencyTokenId, uint256 currencyTokenAmount,
        address[] memory payees, uint256[] memory shares,
        bytes memory data) 
    public onlyOwner {
        uint256 totalShares = 0;
        // creator is the creator of the currency token that manages the shares
        address creator = creators[currencyTokenId];

        // calculate total shares to pay to the payees
        for (uint256 i = 0; i < shares.length; i++)
            totalShares += shares[i];
            
        require(totalShares <= 100000, "ScryptaERC1155: shares can not be over 100%");
        require(payees.length == shares.length, "ScryptaERC1155: payees and shares length are different.");

        // safe transfer of the token | from --> to
        safeTransferFrom(from, to, tokenId, tokenAmount, data);

        // pay the price of the token - fee with the currency token | to --> from
        safeTransferFrom(to, from, currencyTokenId, currencyTokenAmount - (currencyTokenAmount * totalShares) / 100000, data);

        // pay the total fee for the payees | to --> creator
        safeTransferFrom(to, creator, currencyTokenId, (currencyTokenAmount * totalShares) / 100000, data);

        // pay the shares to the payees | creator --> payees
        for (uint256 i = 0; i < payees.length; i++)
            safeTransferFrom(creator, payees[i], currencyTokenId, (currencyTokenAmount * shares[i]) / 100000, data);

        emit ScryptaTrade(_msgSender(), from, to, tokenId, tokenAmount, block.timestamp, currencyTokenId, currencyTokenAmount);
    }

    function safeBatchTradeFrom(
        address from, address to, 
        uint256[] memory tokenIds, uint256[] memory tokenAmounts, 
        uint256[] memory currencyTokenIds, uint256[] memory currencyTokenAmounts,
        address[] memory payees, uint256[] memory shares,
        bytes memory data) 
    public onlyOwner {
        require(tokenIds.length == currencyTokenIds.length, "ScryptaERC1155: tokenIds and currencyTokenIds length are different.");
        require(tokenIds.length == tokenAmounts.length, "ScryptaERC1155: tokenIds and tokenAmounts length are different.");
        require(currencyTokenIds.length == currencyTokenAmounts.length, "ScryptaERC1155: currencyTokenIds and currencyTokenAmounts length are different.");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTradeFrom(
                from, to, 
                tokenIds[i], tokenAmounts[i], 
                currencyTokenIds[i], currencyTokenAmounts[i], 
                payees, shares, 
                data);
        }
    }

    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
        externalAccounts[_msgSender()] = true;
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return (!externalAccounts[account] && operator == owner()) || ERC1155.isApprovedForAll(account, operator);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override (ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] <= _currentTokenId, "ScryptaERC1155: Token has never been created.");
            emit ScryptaTransfer(operator, from, to, ids[i], amounts[i], block.timestamp);
        }
    }
}