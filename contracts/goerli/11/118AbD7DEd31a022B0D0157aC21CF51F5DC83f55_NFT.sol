// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
contract NFT is ERC721A, Ownable, ReentrancyGuard {

    struct Type {
        string name;            // ex. "Super Sluggers Pack"
        uint256 typeId;         // ex. 0, 1, 2, etc.
        uint256 price;          // ex. 50000000000000000000 (50 MATIC)
        uint256 maxSupply;      // ex. 25
        uint256 currentCount;   // ex. 14
    }
    Type[] public types;
    mapping(uint256 => uint256) public token_type;
    mapping(uint256 => uint256) public token_index;

    // Admin mapping
    mapping(address => bool) public isAdmin;
    // Modifier to protect functions that should only be callable by admin or owner
    modifier onlyAdmin() {
        require(isAdmin[_msgSender()] || _msgSender() == owner(), "OnlyAdmin: sender is not admin or owner");
        _;
    }
    
    event minted(address minter, uint256 typeId, uint256 price, uint256 amount);

    constructor (
        string memory _name,    // BallParkPunks
        string memory _symbol,  // BPP
        string memory _uri      // https://ballparkpunks.wl.r.appspot.com/get_metadata?typeId=
    ) 
    ERC721A(_name, _symbol) 
    {
        URI = _uri;

        isAdmin[_msgSender()] = true;
    }

    function mint(uint256 typeId, uint256 amount) external payable nonReentrant {
        require(types[typeId].currentCount + amount <= types[typeId].maxSupply, "NFT: exceeds max supply");
        require(msg.value == getPrice(typeId, amount), "NFT: incorrect amount of ETH sent");

        token_type[totalSupply()] = typeId;
        token_index[totalSupply()] = types[typeId].currentCount;
        
        unchecked {
            types[typeId].currentCount++;
        }
        
        _safeMint(_msgSender(), amount);
        emit minted(_msgSender(), typeId, msg.value, amount);
    }

    function getPrice(uint256 typeId, uint256 amount) public view returns(uint256) {
        return types[typeId].price * amount;
    }

    function ownerMint(uint256 typeId, uint amount, address _recipient) external onlyOwner {
        require(types[typeId].currentCount + amount <= types[typeId].maxSupply, "NFT: exceeds max supply");
        
        unchecked {
            types[typeId].currentCount++;
        }        
        _safeMint(_recipient, amount);
        emit minted(_msgSender(), typeId, 0, amount);
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory typedURI = string(abi.encodePacked(baseURI, _toString(token_type[tokenId])));
        string memory indexedURI = string(abi.encodePacked(typedURI, "&tokenId="));
        string memory tokenUri = string(abi.encodePacked(indexedURI, _toString(token_index[tokenId])));

        return tokenUri;
    }

    function withdraw(uint256 amount, address payable recipient) external onlyOwner {
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Transfer fail");
    }

    function setURI(string memory _uri) external onlyAdmin {
        URI = _uri;
    }

    function setAdmin(address _admin, bool _isAdmin) public onlyOwner {
        isAdmin[_admin] = _isAdmin;
    }

    function setPrice(uint256 typeId, uint256 _price) external onlyAdmin {
        types[typeId].price = _price;
    }

    function increaseMaxSupply(uint256 typeId, uint256 _increaseBy) external onlyAdmin {
        types[typeId].maxSupply += _increaseBy;
    }

    function createType(string calldata _name, uint256 _price, uint256 supply) external onlyAdmin {
        uint256 id = types.length;

        types.push(Type(_name, id, _price, supply, 0));
    }
}