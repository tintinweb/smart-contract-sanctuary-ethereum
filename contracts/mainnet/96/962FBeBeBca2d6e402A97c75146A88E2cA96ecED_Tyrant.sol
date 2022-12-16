// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Tyrant is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    // Set variables
    
    uint256 public constant TYRANT_SUPPLY = 750;
    uint256 public constant PRICE = 55000000000000000;
    
    bool private _saleActive = false;
    
    address team = 0x6BD72A62bd476BC7113010CB939EE39fA80D6a19;
    address sens = 0x542EFf118023cfF2821b24156a507a513Fe93539;

    address VB = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    string private _metaBaseUri = "";
    
    // Public Functions
    
    constructor() ERC721("Fable Dragons by Tyrant", "FABLE") {
        _safeMint(VB, 1);
        _mintTokens(25);
    }
    
    
    function mint(uint16 numberOfTokens) public payable {
        require(isSaleActive(), "Tyrant sale not active");
        require(totalSupply().add(numberOfTokens) <= TYRANT_SUPPLY, "Try less");
        require(numberOfTokens<=5, "Max mint per transaction is 5" );
        require(PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");        

        _mintTokens(numberOfTokens);
    }    
   
    
    function isSaleActive() public view returns (bool) {
        return _saleActive;
    }        

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString()));
    }

    
    // Owner Functions

    function setSaleActive(bool active) external onlyOwner {
        _saleActive = active;
    }   
  

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }


   function withdrawAll() external onlyOwner {
        uint256 _50percent = address(this).balance.div(2);
        require(payable(team).send(_50percent));
        require(payable(sens).send(_50percent));      
    }

    // Internal Functions
    
    function _mintTokens(uint16 numberOfTokens) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    
    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
    

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}