// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";

contract HabAIbiz is ERC721A, Ownable{
    using Strings for uint256;

    uint256 MAX_SUPPLY = 4900;
    uint256 MAX_FREE_SUPPLY = 900;

    uint256 public mintRate_Public = 0.005 ether;
    uint256 public mintAmount_Public = 20;

    bool public isRevealed = false; 
    bool public paused = true;

    string public baseURI = "";  //change
    string public unrevealedBaseURI = "ipfs://QmdLDZopqg9msHfLJJWjWfMdx5RfmYmU5GawoWtrr7BVhM"; // change


    constructor() ERC721A("HabAIbiz", "HAB"){
    }

    modifier callerIsUser(){
        require(tx.origin == _msgSender(), "Only users can interact with this contract!");
        _;
    }


    function publicMint(uint256 quantity) external payable callerIsUser{
        require(!paused);
        require(quantity + _numberMinted(_msgSender()) <= mintAmount_Public, "Exceeded max mints");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");

        if(totalSupply() + quantity <= MAX_FREE_SUPPLY){
            _safeMint(_msgSender(), quantity);
            return;
        }
        require(msg.value >= (mintRate_Public * quantity), "Not enough ether sent");
        _safeMint(_msgSender(), quantity);
    }

    function ownerMint(uint256 quantity) external onlyOwner{
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Tokens");
        _safeMint(_msgSender(), quantity);
    }


    function withdraw() public onlyOwner{
        (bool payer, ) = payable(owner()).call{value: (address(this).balance)}("");
        require(payer, "Nope");
    }

    function _baseURI() internal view virtual override returns(string memory){
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(_exists(tokenId), "Non-existant token URI Query");
        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return unrevealedBaseURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, trueId.toString(), ".json")) : "";
    }

    function reveal(bool shouldReveal) public onlyOwner{
        isRevealed = shouldReveal;
    }
    
    function pause(bool shouldPause) public onlyOwner{
        paused = shouldPause;
    }

    function burnToken(uint256 tokenId) public onlyOwner{
        _burn(tokenId);
    }
}