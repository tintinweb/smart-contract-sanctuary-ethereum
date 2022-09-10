/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// File: contracts/6_ERC721.sol



pragma solidity ^0.8.3;

interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4);
}

contract ERC_721_token {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    string private Name;
    string private Symbol;

    // TokenID -> Owner
    mapping(uint256 => address) private _ownerOf;
    // Address Has No of Tokens
    mapping(address => uint256) private _balanceOf;
    // TokenID -> Approved Address
    mapping(uint256 => address) private _approvals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        Name = _name;
        Symbol = _symbol;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        require(owner != address(0), "Address is 0");
        return _balanceOf[owner];
    }


    function ownerOf(uint256 tokenId) public view returns (address owner) {
        require(_ownerOf[tokenId] != address(0), "Token Doesn;t Exits");
        return _ownerOf[tokenId];
    }

    function name() public view returns (string memory) {
        return Name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return Symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? // ? string(abi.encodePacked(baseURI, tokenId.toString()))
                string(abi.encodePacked(baseURI, tokenId))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function approve(address to, uint256 tokenId) public {
        address owner = this.ownerOf(tokenId);
        require(to != address(0), "Address is O");
        require(to != owner, "ERC721: approval to current owner");
        require(
           owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "You are not the Owner of this TokenID"
        );
        require(to != msg.sender, "You are already owner of this tokenID ");
        
        _approvals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator)
    {
        require(_ownerOf[tokenId] != address(0), "Token Doesn't Exist");
        return _approvals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved) public {
        require(operator != address(0) && msg.sender!= operator , "Address is O");
        // require(balanceOf[msg.sender]>0,"You have No tokens");
        // require(owner != operator, "ERC721: approve to caller");

        _isApprovedForAll[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        require(operator != address(0), "Address is O");
        require(owner != operator, "Already operator of this Token");
        return _isApprovedForAll[owner][operator];
    }

    function _isApprovedOrOwner(
        // address owner,
        address spender,
        uint256 id
    ) internal view returns (bool) {
        address owner = ownerOf(id);
        return (spender == owner ||
            _isApprovedForAll[owner][spender] ||
            spender == _approvals[id]);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(from == _ownerOf[tokenId], "from != owner");
        require(to != address(0), "transfer to zero address");

        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not authorized"
        );


        _balanceOf[from]--;
        _balanceOf[to]++;
        _ownerOf[tokenId] = to;

        delete _approvals[tokenId];

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        transferFrom(from, to, tokenId);
        uint32 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            ERC721TokenReceiver receiver = ERC721TokenReceiver(to);
            require(
                receiver.onERC721Received(msg.sender, from, tokenId, "") ==
                    bytes4(
                        keccak256(
                            "onERC721Received(address,address,uint256,bytes)"
                        )
                    ),
                    "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    // function _mint(tokenID);
    // function _safeMint(tokenID);

    /**
    checks if a token already exist
    @param tokenId - token id
    */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (_ownerOf[tokenId] != address(0));
    }

    /**
    Mint a token with id `tokenId`
    @param tokenId - token id
    */
    function mint(uint256 tokenId) public {
        require(!_exists(tokenId), "tokenId already exist");
        _safeMint(msg.sender, tokenId, "");
    }

    /**
  Mint safely as this function checks whether the receiver has implemented onERC721Received if its a contract
  @param to - to address
  @param tokenId - token id
  @param data - data
   */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "receiver has not implemented ERC721Receiver"
        );
    }

    /**
  Internal function to mint a token `tokenId` to `to`
  @param to - to address
  @param tokenId - token id
   */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "transfering to zero addres");
        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == ERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("receiver has not implemented ERC721Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);


        // Clear approvals
        _approve(address(0), tokenId);

        _balanceOf [owner] -= 1;
        delete _ownerOf[tokenId];

        emit Transfer(owner, address(0), tokenId);


    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _approvals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/7_ERC4907.sol




pragma solidity ^0.8.3;



contract ERC4907 is ERC_721_token {

    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint256 expires
    );

    struct UserInfo {
        address user; // address of user role
        uint256 expires; // unix timestamp, user expires
    }

    mapping(uint256 => UserInfo) internal _users;

    constructor(string memory name_, string memory symbol_)
        ERC_721_token(name_, symbol_)
    {}

    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint256 expires
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC4907: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = uint256(block.timestamp) + expires;
        emit UpdateUser(tokenId, user, expires);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _users[tokenId].expires;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }
}



// #// Addresses for testing
// 1// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4  3
// 2// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2  1
// 3// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db  1
// 4// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB  A
// 1
// 2
// File: contracts/8_NFTmarketplaceUpdated.sol




pragma solidity ^0.8.3;

// NFT marketplace has a core set of functionality:
// 1. Minting and listing an NFT
// 2. Buying and selling an NFT
// 3. Viewing listed NFTs, NFTs you own, and NFTs you are selling

contract ApesNFT is ERC4907 {
    uint256 private _tokenIds;
    address contractAddress;

    constructor(address marketplaceAddress) ERC4907("ApesNft", "DEV") {
        contractAddress = marketplaceAddress;
        _tokenIds = 0;
    }

    function createToken()
        public
        returns (uint256 TokenID)
    {
        _tokenIds++;
        uint256 newItemId = _tokenIds;

        _mint(msg.sender, newItemId);

        setApprovalForAll(contractAddress, true);
        return newItemId;
    }
    function ApproveMarketplaceToSell(uint tokenId)public {
        approve(contractAddress, tokenId);
    }
}

contract NFTMarket {
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    uint256 private _itemIds;
    uint256 private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.025 ether;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price; 
        bool sold;
    }

    // MarketId -> MarketItem
    mapping(uint256 => MarketItem) private idToMarketItem;

    constructor() {
        owner = payable(msg.sender);
        _itemIds = 0;
        _itemsSold = 0;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Places an item for sale on the marketplace */
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        address onwerofToken = ERC4907(nftContract).ownerOf(tokenId);
        require(
            msg.sender == onwerofToken,
            "You are not The owner of this Token"
        );
        // require(onwerofToken!=address(0),"Token you are trying to List Doesn't Exists!");
        _itemIds++; 
        uint256 itemId = _itemIds;

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );


        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function sellNFT(address nftContract, uint256 itemId)
        public
        payable
    {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );


        address payable Seller = idToMarketItem[itemId].seller;
        require(Seller!= msg.sender,"You already own this Article");
        (bool sent, ) = Seller.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        
        ERC4907(nftContract).transferFrom(Seller, msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        idToMarketItem[itemId].seller = payable(address(0));
        _itemsSold++;
        payable(owner).transfer(listingPrice);
    }

    function deleteMyNFT( uint256 itemId)
        public
        payable
    {
        require(
            msg.sender == idToMarketItem[itemId].seller||
            msg.sender == idToMarketItem[itemId].owner,
            "you are not the owner of this account"
        );
        delete idToMarketItem[itemId];

    }
    function UpdateListing(uint256 itemId, bool status) public{
      require(
            msg.sender == idToMarketItem[itemId].seller||
            msg.sender == idToMarketItem[itemId].owner,
            "you are not the owner of this account"
        );
        idToMarketItem[itemId].sold=status;
    }


    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds;
        uint256 unsoldItemCount = _itemIds - _itemsSold;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns onlyl items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has created */
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}



// #// Addresses for testing
// 1// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4  3
// 2// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2  1
// 3// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db  1
// 4// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB  A
// 1
// 2
// Listing Price: 25000000000000000

// 25000000000000000