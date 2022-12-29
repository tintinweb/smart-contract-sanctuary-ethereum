//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";

contract iBallzPE is ERC721Enumerable, Ownable  {

    using SafeMath for uint256;

    // Token detail
    struct IBallzDetail {
        uint256 creation;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 creation);

    // Token Detail
    mapping(uint256 => IBallzDetail) private _iballzDetails;

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint public MAX_PURCHASE = 20;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 7000;

    // Current price.
    uint256 public CURRENT_PRICE = 80000000000000000;

    // Define if sale is active
    bool public saleIsActive = true;

    // Base URI
    string private baseURI;

    address private walletCreator = 0x9e16F7cB8c5d013F627cB7eCB62688914fAf1CcF;
    address private walletDev = 0x5BBfbFc8DF4A8CEfDa2c642505ce23380FcbCBC0;

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
     * Set walletCreator address
     */
    function setWalletCreator(address _walletCreator) public onlyOwner {
        walletCreator = _walletCreator;
    }

    /**
     * Set walletDev address
     */
    function setWalletDev(address _walletDev) public onlyOwner {
        walletDev = _walletDev;
    }

    /**
     * Get the token detail
     */
    function getIBallzDetail(uint256 _tokenId) public view returns(IBallzDetail memory detail) {
        require(_exists(_tokenId), "Token was not minted");

        return _iballzDetails[_tokenId];
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
        require(address(this).balance > 0, "No balance to withdraw");
    
        uint balance = address(this).balance;
        uint wDevShare = balance.mul(25).div(100);
        uint wCreatorShare = balance.mul(75).div(100);

        (bool success, ) = walletDev.call{value: wDevShare}("");
        require(success, "walletDev Withdrawal failed");

        (success, ) = walletCreator.call{value: wCreatorShare}("");
        require(success, "walletCreator Withdrawal failed");
    }

    /**
     * Withdraw
     */
    function withdrawAlt() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Reserve tokens
     */
    function reserveTokens(uint256 qty) public onlyOwner {
        require(totalSupply().add(qty) <= MAX_TOKENS, "Purchase would exceed max supply");
        uint tokenId;
        uint256 creation = block.timestamp;

        for (uint i = 1; i <= qty; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _iballzDetails[tokenId] = IBallzDetail(creation);
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
                _iballzDetails[tokenId] = IBallzDetail(creation);
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
                _iballzDetails[tokenId] = IBallzDetail(creation);
                
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