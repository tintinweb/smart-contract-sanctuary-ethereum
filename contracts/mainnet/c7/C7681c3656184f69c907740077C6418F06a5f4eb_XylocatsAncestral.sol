// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC721A.sol";
import "ERC721AQueryable.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";

/// @title Xylocats Ancestral NFT Collection
/// @author Xylocats DBA Very Official LLC
/// @notice For more information about the operation of this contract please see the IERC721 specification as well as the documentation for the ERC721A implementation.
contract XylocatsAncestral is ERC721AQueryable, Ownable, ReentrancyGuard {

    /// @dev The maximum number of tokens available for mint. Similar to constant immutable saves gas by not provisioning a storage slot but enables the value to be set unlike constant.
    uint256 private immutable _maxTokens;                         

    /// @dev The mint price hardcoded as 0.1 ETH.
    uint256 private constant _tokenPrice = 100000000000000000;    

    /// @dev The max number of tokens to mint in one request.
    uint256 private constant _maxTokenPurchase = 20;              

    /// @dev The base URI used to generate the token URI. 
    string private _tokenBaseURI;                         

    /// @dev Toggle the sale state to enable or disable it. 
    bool private _saleIsActive = false;

    /// @dev This will be the provenance hash of the images after finalization    
    string private _provenanceHash;

    /// @dev When instantiating the contract set basic metadata and operational values such as name, symbol, max tokens, baseURI, etc. 
    constructor(string memory name, string memory symbol, uint256 maxTokens, string memory baseURI) ERC721A(name, symbol) {
        _maxTokens = maxTokens;
        _tokenBaseURI = baseURI;
    }

    /*** start overrides ***/
    /// @dev Override the baseURI functionality to utilize a private var which can be updated if required.
    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /// @dev Override the start token ID to set the starting index to the human friendly value of 1 instead of 0.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*** start accessor functions ***/
    /// @dev Returns the value of _tokenBaseURI. 
    function getBaseURI() external view returns (string memory) {    
        return _tokenBaseURI;
    }

    /// @dev Returns the value of _startTokenId.
    function getStartTokenId() external pure returns (uint256) {
        return _startTokenId();
    }   

    /// @dev Returns the value of _saleIsActive.
    function getSaleState() external view returns(bool) {
        return _saleIsActive;
    }

    /// @dev Returns the value of _maxTokens. 
    function getMaxTokens() external view returns(uint256) {
        return _maxTokens;
    }

    /// @dev Returns the value of _maxTokens. 
    function getProvenanceHash() external view returns(string memory) {
        return _provenanceHash;
    }

    /*** start mutator functions ***/ 
    /// @dev Allows updating the value of the base URI if required. 
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    /// @dev Set the provenance after it's been calculated
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }

    /*** start operational functions ***/
    /// @dev Returns the value of _tokenBaseURI. 
    function toggleSaleState() external onlyOwner {
        _saleIsActive = !_saleIsActive;
    }
 
    /// @dev This function allows the owner to reserve and provision tokens for stakeholders
    function reserveTokens(address to, uint256 quantity) external onlyOwner {
        require(quantity <= 50, "Cannot reserve more than 50 tokens at a time");
        require((totalSupply()+quantity) <= _maxTokens, "Reservation would exceed max supply of tokens");
        _mint(to, quantity);
    }

    /// @dev This allows the public to mint tokens within the specified quantity, max supply and price.     
    function mint(uint256 quantity) external payable nonReentrant {
        require(_saleIsActive, "Sale must be active to mint token");
        require(quantity > 0, "Must specify a quantity to mint greater than 0");
        require(quantity <= _maxTokenPurchase, "Can only mint 20 tokens at a time");
        require((totalSupply()+quantity) <= _maxTokens, "Purchase would exceed max supply of tokens");
        require((_tokenPrice*quantity) <= msg.value, "Ether value sent is not correct");
        _safeMint(msg.sender, quantity);        
    }

    /// @dev owner only function which allows withdrawal of funds. 
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }   
}