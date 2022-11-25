//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";

contract GuideDAOAccessToken is IERC721Metadata {
    struct Collection {
        uint256 startIndex;
        uint256 endIndex;
        string additionalURI;
    }

    string private _name = "GuideDAO Access Token";
    string private _symbol = "GDAT";
    string private _baseURI;
    uint256 public currentIdToMint = 1;
    uint256 public currentCollectionId;
    Collection[] public collections;
    mapping(address => uint256) private _ids;
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

    modifier isFirstToken(address to) {
        require(balanceOf(to) == 0, "Address already have a token");
        _;
    }

    modifier isCollectionNotExists(string memory additionalURI) {
        require(
            !_isCollectionExists(additionalURI),
            "Collection with such additional URI already exists!"
        );
        _;
    }

    constructor(
        string memory baseURI,
        address firstAdmin,
        string memory firstCollectionAdditionalURI,
        uint256 firstCollectionSize
    ) {
        _baseURI = baseURI;
        admins[firstAdmin] = true;
        _createCollection(firstCollectionAdditionalURI, firstCollectionSize);
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
        for (uint256 i = 0; i < collections.length; i++) {
            if (
                tokenId >= collections[i].startIndex &&
                tokenId <= collections[i].endIndex
            ) {
                return
                    string(
                        abi.encodePacked(_baseURI, collections[i].additionalURI)
                    );
            }
        }
        return _baseURI;
    }

    function balanceOf(address owner)
        public
        view
        override
        returns (uint256 balance)
    {
        require(owner != address(0), "Owner can't be zero");
        return _ids[owner] == 0 ? 0 : 1;
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
    ) public override isAdmin isFirstToken(to) {
        require(to != address(0), "It's burn, not transfer!");
        require(to.code.length == 0, "Can't send to contract!");
        _transferFrom(from, to, tokenId);
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
        require(_ids[to] == 0, "To already has a token!");
        if (from != address(0)) {
            _ids[from] = 0;
        }
        _ids[to] = tokenId;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function setIsAdmin(address admin, bool _isAdmin) public isAdmin {
        require(msg.sender != admin, "You can't suicide!");
        admins[admin] = _isAdmin;
    }

    function createCollection(string memory additionalURI, uint256 size)
        external
        isAdmin
    {
        _createCollection(additionalURI, size);
        currentCollectionId++;
    }

    function _createCollection(string memory additionalURI, uint256 size)
        private
        isCollectionNotExists(additionalURI)
    {
        require(
            bytes(additionalURI).length > 0,
            "Additional URI can't be empty string!"
        );
        if (collections.length > 0) {
            collections[currentCollectionId].endIndex = currentIdToMint - 1;
        }
        Collection memory collection = Collection({
            startIndex: currentIdToMint,
            endIndex: currentIdToMint + size - 1,
            additionalURI: additionalURI
        });
        collections.push(collection);
    }

    function _isCollectionExists(string memory additionalURI)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < collections.length; i++) {
            if (
                keccak256(bytes(additionalURI)) ==
                keccak256(bytes(collections[i].additionalURI))
            ) {
                return true;
            }
        }
        return false;
    }

    function mintTo(address to) public isAdmin isFirstToken(to) {
        require(
            currentIdToMint <= collections[currentCollectionId].endIndex,
            "This collection is over. Create new one"
        );
        safeTransferFrom(address(0), to, currentIdToMint);
        currentIdToMint++;
    }

    function mintBatch(address[] memory to) public isAdmin {
        require(
            currentIdToMint + to.length - 1 <=
                collections[currentCollectionId].endIndex,
            "Too many addresses for this collection"
        );
        for (uint256 i = 0; i < to.length; i++) {
            if (balanceOf(to[i]) == 0) {
                mintTo(to[i]);
            }
        }
    }

    function burn(address from, uint256 tokenId) public isAdmin {
        _transferFrom(from, address(0), tokenId);
    }

    function setBaseURI(string memory newURI) public isAdmin {
        _baseURI = newURI;
    }

    function setCollectionURI(uint256 collectionId, string memory newURI)
        public
        isAdmin
        isCollectionNotExists(newURI)
    {
        require(
            collectionId <= currentCollectionId,
            "This collection dosen't exists yet"
        );
        collections[collectionId].additionalURI = newURI;
    }

    function getAddressNFTId(address user) public view returns (uint256) {
        return _ids[user];
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