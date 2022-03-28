pragma solidity ^0.4.19;

import "./ItemERC721.sol";

// solium-disable-next-line no-empty-blocks
contract ItemCore is ItemERC721 {
    struct Item {
        uint256 itemInfo;
        uint256 bornAt;
    }

    Item[] items;

    event ItemSpawned(
        uint256 indexed _itemId,
        address indexed _owner,
        uint256 _genes
    );
    event ItemCreateds(
        uint256 indexed _itemIdMin,
        uint256 indexed _itemIdMax,
        address indexed _owner,
        uint256 _genes
    );
    event ItemRebirthed(uint256 indexed _itemId, uint256 _genes);
    event ItemRetired(uint256 indexed _itemId);
    event ItemEvolved(
        uint256 indexed _itemId,
        uint256 _oldGenes,
        uint256 _newGenes
    );
    constructor() public {
        items.push(Item(0, now)); // The void Item
        whitelistedSpawner[msg.sender] = true;
        whitelistedMarketplace[msg.sender] = true;
        createItems(0, msg.sender, 3);
    }

    function getItemsAll()
        public
        view
        returns (
            uint256[] tokenId,
            uint256[] itemInfo, /* _genes */
            uint256[] bornAt, /* _bornAt */
            address[] tokenOwner
        )
    {
        tokenId = new uint256[](_totalTokens);
        itemInfo = new uint256[](_totalTokens);
        bornAt = new uint256[](_totalTokens);
        tokenOwner = new address[](_totalTokens);
        for (uint256 _index; _index < _totalTokens; _index++) {
            tokenId[_index] = _overallTokenId[_index];
            itemInfo[_index] = items[_overallTokenId[_index]].itemInfo;
            bornAt[_index] = items[_overallTokenId[_index]].bornAt;
            tokenOwner[_index] = _tokenOwner[_overallTokenId[_index]];
        }
    }

    function getItems(address _owner)
        public
        view
        returns (
            uint256[] tokenId,
            uint256[] itemInfo, /* _genes */
            uint256[] bornAt /* _bornAt */
        )
    {
        require(_owner != address(0));
        tokenId = new uint256[](_ownedTokens[_owner].length);
        itemInfo = new uint256[](_ownedTokens[_owner].length);
        bornAt = new uint256[](_ownedTokens[_owner].length);
        for (uint256 _index; _index < _ownedTokens[_owner].length; _index++) {
            tokenId[_index] = _ownedTokens[_owner][_index];
            itemInfo[_index] = items[_ownedTokens[_owner][_index]].itemInfo;
            bornAt[_index] = items[_ownedTokens[_owner][_index]].bornAt;
        }
    }

    function getItem(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (
            uint256 itemInfo, /* _genes */
            uint256 bornAt, /* _bornAt */
            address tokenOwner
        )
    {
        Item storage _item = items[_tokenId];
        itemInfo = _item.itemInfo;
        bornAt = _item.bornAt;
        tokenOwner = _tokenOwner[_tokenId];
    }

    function createItems(
        uint256 _genes,
        address _owner,
        uint256 _count
    )
        public
        onlySpawner
        returns (uint256 _tokenIdMin, uint256 _tokenIdMax)
    {
        _tokenIdMin = _spawnItem2(_genes, _owner);
        for (uint256 _index = 1; _index < _count - 1; _index++) {
            _spawnItem2(_genes, _owner);
        }
        _tokenIdMax = _spawnItem2(_genes, _owner);
        emit ItemCreateds(_tokenIdMin, _tokenIdMax, _owner, _genes);
    }

    function spawnItem(uint256 _genes, address _owner)
        external
        onlySpawner
        returns (uint256)
    {
        return _spawnItem(_genes, _owner);
    }

    function rebirthItem(uint256 _itemId, uint256 _genes)
        external
        onlySpawner
        mustBeValidToken(_itemId)
    {
        Item storage _item = items[_itemId];
        _item.itemInfo = _genes;
        _item.bornAt = now;
        emit ItemRebirthed(_itemId, _genes);
    }

    function retireItem(uint256 _itemId, bool _rip) external onlySpawner {
        _burn(_itemId);

        if (_rip) {
            delete items[_itemId];
        }

        emit ItemRetired(_itemId);
    }

    function evolveItem(uint256 _itemId, uint256 _newGenes)
        external
        onlySpawner
        mustBeValidToken(_itemId)
    {
        uint256 _oldGenes = items[_itemId].itemInfo;
        items[_itemId].itemInfo = _newGenes;
        emit ItemEvolved(_itemId, _oldGenes, _newGenes);
    }

    function _spawnItem(uint256 _genes, address _owner)
        private
        returns (uint256 _itemId)
    {
        Item memory _item = Item(_genes, now);
        _itemId = items.push(_item) - 1;
        _mint(_owner, _itemId);
        emit ItemSpawned(_itemId, _owner, _genes);
    }

    function _spawnItem2(uint256 _genes, address _owner)
        private
        returns (uint256 _itemId)
    {
        Item memory _item = Item(_genes, now);
        _itemId = items.push(_item) - 1;
        _mint2(_owner, _itemId);
    }
}