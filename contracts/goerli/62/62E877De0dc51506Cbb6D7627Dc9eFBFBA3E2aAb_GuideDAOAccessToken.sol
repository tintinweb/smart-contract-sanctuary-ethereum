//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";

contract GuideDAOAccessToken is IERC721Metadata {
    struct Collection {
        uint256 startIndex;
        uint256 endIndex;
        string title;
    }

    string private _name;
    string private _symbol;
    string private _baseURI;
    uint256 public currentIdToMint;
    uint256 public currentCollectionId;
    Collection[] public _collections;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(address => bool) public admins;

    modifier isMinted(uint256 tokenId) {
        require(_owners[tokenId] != address(0), "Token dosen't exists");
        _;
    }

    modifier isAdmin() {
        require(admins[msg.sender], "You are not an admin");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address firstAdmin,
        string memory firstCollectionName
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        admins[firstAdmin] = true;
        _createCollection(firstCollectionName);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        isMinted(tokenId)
        returns (string memory)
    {
        for (uint256 i = 0; i < _collections.length; i++) {
            if (
                tokenId >= _collections[i].startIndex &&
                tokenId <= _collections[i].endIndex
            ) {
                return
                    string(abi.encodePacked(_baseURI, _collections[i].title));
            }
        }
        return _baseURI;
    }

    function balanceOf(address owner)
        external
        view
        override
        returns (uint256 balance)
    {
        require(owner != address(0), "Owner can't be zero");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        isMinted(tokenId)
        returns (address owner)
    {
        return _owners[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override isAdmin {
        require(to.code.length == 0, "Can't send to contract!");
        transferFrom(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override isAdmin {
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(_owners[tokenId] == from, "From isn't owner!");
        require(_owners[tokenId] != to, "To already owner!");
        require(to != address(0), "It's burn, not transfer!");
        if (from != address(0)) {
            _balances[from]--;
        }
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function setIsAdmin(address admin, bool _isAdmin) public isAdmin {
        admins[admin] = _isAdmin;
    }

    function createCollection(string memory title) external isAdmin {
        _createCollection(title);
    }

    function _createCollection(string memory title) private {
        require(bytes(title).length > 0, "Title can't be empty string!");
        require(
            !_isCollectionExists(title),
            "Collection with such title already exists!"
        );
        if (_collections.length > 0) {
            _collections[currentCollectionId].endIndex =
                currentIdToMint -
                1;
        }
        Collection memory collection = Collection({
            startIndex: currentCollectionId,
            endIndex: 2**256 - 1,
            title: title
        });
        _collections.push(collection);
    }

    function _isCollectionExists(string memory title)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _collections.length; i++) {
            if (
                keccak256(bytes(title)) ==
                keccak256(bytes(_collections[i].title))
            ) {
                return true;
            }
        }
        return false;
    }

    function mintTo(address to) external isAdmin {
        safeTransferFrom(address(0), to, currentIdToMint);
        currentIdToMint++;
    }

    function approve(address to, uint256 tokenId) external override {}

    function setApprovalForAll(address operator, bool _approved)
        external
        override
    {}

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address operator)
    {}

    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {}
}