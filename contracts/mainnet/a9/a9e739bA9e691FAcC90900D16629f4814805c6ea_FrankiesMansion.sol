//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";

contract FrankiesMansion is ERC721Enumerable, Ownable  {

    using SafeMath for uint256;

    // Token detail
    struct FrankieDetail {
        uint256 creation;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 creation);

    // Token Detail
    mapping(uint256 => FrankieDetail) private _frankieDetails;

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint public MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 8888;

    // Current price.
    uint256 public CURRENT_PRICE = 25000000000000000;

    // Define if sale is active
    bool public saleIsActive = true;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol, string memory _baseUri) ERC721(name, symbol) {
        setBaseURI(_baseUri);
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        PROVENANCE = _provenanceHash;
    }

    /*
    * Set max tokens
    */
    function setMaxTokens(uint256 _maxTokens) public onlyOwner {
        MAX_TOKENS = _maxTokens;
    }

    /*
    * Set max purchase
    */
    function setMaxPurchase(uint256 _maxPurchase) public onlyOwner {
        MAX_PURCHASE = _maxPurchase;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function setSaleState(bool _newState) public onlyOwner {
        saleIsActive = _newState;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 _currentPrice) public onlyOwner {
        CURRENT_PRICE = _currentPrice;
    }

    /**
     * Get the token detail
     */
    function getFrankieDetail(uint256 _tokenId) public view returns(FrankieDetail memory detail) {
        require(_exists(_tokenId), "Token was not minted");

        return _frankieDetails[_tokenId];
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setBaseURI(string memory BaseURI) public onlyOwner {
       baseURI = BaseURI;
    }

     /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Withdraw
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Reserve tokens
     */
    function reserveTokens(uint256 qty) public onlyOwner {
        uint tokenId;
        uint256 creation = block.timestamp;

        for (uint i = 1; i <= qty; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _frankieDetails[tokenId] = FrankieDetail(creation);
                emit TokenMinted(tokenId, msg.sender, creation);
            }
        }
    }

    /**
     * Mint token for owners.
     */
    function mintTokens(address[] memory _owners) public onlyOwner {
        require(totalSupply().add(_owners.length) <= MAX_TOKENS, "Purchase would exceed max supply");
        uint256 creation = block.timestamp;
        uint256 tokenId;
        
        for (uint i = 0; i < _owners.length; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(_owners[i], tokenId);
                _frankieDetails[tokenId] = FrankieDetail(creation);
                emit TokenMinted(tokenId, _owners[i], creation);
            }
        }
    }

    /**
    * Mint tokens
    */
    function mint(uint qty) public payable {
        require(saleIsActive, "Mint is not available right now");
        require(qty <= MAX_PURCHASE, "Can only mint 20 tokens at a time");
        require(totalSupply().add(qty) <= MAX_TOKENS, "Purchase would exceed max supply");
        require(CURRENT_PRICE.mul(qty) <= msg.value, "Value sent is not correct");
        uint256 creation = block.timestamp;
        uint tokenId;
        
        for(uint i = 1; i <= qty; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _frankieDetails[tokenId] = FrankieDetail(creation);
                
                emit TokenMinted(tokenId, msg.sender, creation);
            }
        }
    }

    /**
     * Get tokens owner
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}