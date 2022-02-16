//SPDX-License-Identifier: MIT
// contracts/ERC721.sol
// upgradeable contract

pragma solidity >=0.8.0;

import "./ERC721Upgradeable.sol";
import "./Counters.sol";


interface beans {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function ownerTokenCfo() external view returns(address);
    function burn(address from, uint256 amount) external;
}


interface goldenEgg {
    function balanceOf(address) external view returns (uint);
    function transfer(address from, address to, uint amount) external returns (bool);
}

contract goldenEggMarketRunMain is ERC721Upgradeable {
    beans be = beans(0x03C617D75d3463592fe9e2A42A5D201D68B54985);
    goldenEgg constant ge = goldenEgg(0x3EF0Fd46C2E142F475c275F0B6f27d39A93dB91E);


    // define Golden struct
    struct GoldenEggRun {
        uint256 tokenId;
        address currentOwner;
        uint256 price;
        bool forSale;
        uint forSalLog;
        uint goldenEggAmount;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // map id to GoldenEgg obj
    mapping(uint256 => GoldenEggRun) public allGoldenEggRun;

    //  implement the IERC721Enumerable which no longer come by default in openzeppelin 4.x
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Royalty
    address private _owner;
    address private _royaltiesAddr; // royality receiver
    uint256 public royaltyPercentage; // royalty based on sales price
    // cost to mint
    uint256 public mintFeeAmount;
    // NFT Meta data
    string public baseURL;

    event setpriceforsale(uint256 tokenId, uint256 newPrice, bool isForSale);

    event BuyToken(uint256 tokenId);    

    function initialize(
        address _contractOwner,
        address _royaltyReceiver,
        uint256 _royaltyPercentage,
        string memory _baseURL
    ) public initializer {
        __ERC721_init("GOLDENEGG", "GOLDENEGG");
        royaltyPercentage = _royaltyPercentage;
        _owner = _contractOwner;
        _royaltiesAddr = _royaltyReceiver;
        baseURL = _baseURL;
    }


    function changeUrl(string memory url) external {
        require(msg.sender == _owner, "Only owner");
        baseURL = url;
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function setPriceForSale(
        uint256 _newPrice,
        uint256 _goldenEgg
        ) external {
        require(_newPrice > 0);
        require(_goldenEgg > 0);
        //Golden Egg Balance Check
        require(_goldenEgg <= ge.balanceOf(msg.sender));
        //
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        //Transfer golden eggs to management
        // ge.transfer(msg.sender, _royaltiesAddr, _goldenEgg); 
        GoldenEggRun memory egg = allGoldenEggRun[newItemId];
        egg.tokenId = newItemId;
        egg.currentOwner = msg.sender;
        egg.price = _newPrice;
        egg.forSale = true;
        egg.forSalLog = block.timestamp;
        egg.goldenEggAmount = _goldenEgg;
        allGoldenEggRun[newItemId] = egg;
        emit setpriceforsale(newItemId, _newPrice, true);
    }

    function cancelTheSale(
        uint256 _tokenId
        ) external {
        require(_exists(_tokenId));
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender);
        GoldenEggRun memory egg = allGoldenEggRun[_tokenId];
        require(egg.forSale == true);
        //Transfer golden eggs to users
        ge.transfer(_royaltiesAddr, msg.sender, egg.goldenEggAmount); 
        egg.forSale = false;
        egg.forSalLog = block.timestamp;
        allGoldenEggRun[_tokenId] = egg;
        emit setpriceforsale(_tokenId, egg.price, false);
    }

    //Change the listing price
    function changeTheListingPrice(        
        uint256 _tokenId,
        uint256 _newPrice
        ) external {
        require(_newPrice > 0);
        require(_exists(_tokenId));
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender);
        GoldenEggRun memory egg = allGoldenEggRun[_tokenId];
        require(egg.forSale == true);
        egg.price = _newPrice;
        egg.forSalLog = block.timestamp;
        allGoldenEggRun[_tokenId] = egg;
        emit setpriceforsale(_tokenId, egg.price, true);
    }

    function getAllSaleTokens() public view returns (uint256[] memory) {
        uint256 _totalSupply = totalSupply();
        uint256[] memory _tokenForSales = new uint256[](_totalSupply);
        uint256 counter = 0;
        for (uint256 i = 1; i <= _totalSupply; i++) {
            if (allGoldenEggRun[i].forSale == true) {
                _tokenForSales[counter] = allGoldenEggRun[i].tokenId;
                counter++;
            }
        }
        return _tokenForSales;
    }


    // by a token by passing in the token's id
    function buyToken(uint256 _tokenId) public {
        // check if the token id of the token being bought exists or not
        require(_exists(_tokenId));
        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);
        // token's owner should not be an zero address account
        // require(tokenOwner != address(0));
        // the one who wants to buy the token should not be the token's owner
        // require(tokenOwner != msg.sender);
        // get that token from all GoldenEggRun mapping and create a memory of it defined as (struct => GoldenEggRun)
        GoldenEggRun memory egg = allGoldenEggRun[_tokenId];
        // token should be for sale
        require(egg.forSale);
        uint256 amount = egg.price;
        uint256 _royaltiesAmount = (amount * royaltyPercentage) / 100;
        uint256 payOwnerAmount = amount - _royaltiesAmount;
        // price sent in to buy should be equal to or more than the token's price
        require(amount >= egg.price);
        //beans deduct royalties
        if (_royaltiesAmount > 0) be.transfer(_royaltiesAddr, _royaltiesAmount);
        //beans to the seller
        if (payOwnerAmount > 0) be.transfer(egg.currentOwner, payOwnerAmount);
        //Manage the transfer of golden eggs to buyers
        // if (egg.goldenEggAmount > 0) ge.transfer(_royaltiesAddr, msg.sender, egg.goldenEggAmount); 

        // _transfer(tokenOwner, msg.sender, _tokenId);
        egg.price = 0;
        egg.forSale = false;
        egg.forSalLog = block.timestamp;
        allGoldenEggRun[_tokenId] = egg;
        emit BuyToken(_tokenId);
    }    

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < balanceOf(owner), "out of bounds");
        return _ownedTokens[owner][index];
    }

    //  URI Storage override functions
    /** Overrides ERC-721's _baseURI function */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURL;
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
        GoldenEggRun memory egg = allGoldenEggRun[tokenId];
        egg.currentOwner = to;
        egg.forSale = false;
        allGoldenEggRun[tokenId] = egg;
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }


}